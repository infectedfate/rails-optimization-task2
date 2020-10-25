require 'set'

class User
  attr_accessor :id, :first_name, :last_name,
                :sessions, :total_sessions, :total_time,
                :longest_session, :browsers, :once_use_ie,
                :only_use_chrome, :dates
  def initialize(id, first_name, last_name)
    @id = id
    @first_name = first_name
    @last_name = last_name
    @sessions = []
    @total_sessions = 0
    @total_time = 0
    @longest_session = 0
    @browsers = Set.new
    @once_use_ie = false
    @only_use_chrome = false
    @dates = ''
  end
end

class Session
  attr_accessor :user_id, :id, :browser, :time, :date

  def initialize(browser, time, date)
    @browser = browser
    @time = time
    @date = date
  end
end

class ReportGenerator

  SESSION = 'session'.freeze
  SPACE = ' '.freeze
  USER = 'user'.freeze
  COMMA = ','.freeze

  def initialize
    @total_users = 0
    @total_sessions = 0
    @all_browsers = Set.new
  end
  
  def work(gc_disable: false)
    GC.disable if gc_disable
    
    File.open('result.json', 'w') do |f|
    f.write('{"usersStats":{')
    
      file_lines = File.readlines('data200.txt')
      file_lines.each do |line|
        if line.start_with?(USER)
          cols = line.strip.split(COMMA)[1..3]
          id = cols[0]
          unless id == @user&.id
            save_user_stats(f, @total_users, @user_stats) if @user&.id
          end
          @total_users += 1
          @user = User.new(cols[0], cols[1], cols[2])
        else
          @total_sessions += 1
          cols = line.strip.split(COMMA)[3..5]
          browser = cols[0].upcase
          time = cols[1].to_i
          date = cols[2]
          @all_browsers << browser
          @user.tap do |user|
            user.browsers << browser
            user.sessions << Session.new(cols[3], cols[4], cols[5])
            user.total_sessions += 1
            user.total_time += time
            user.longest_session = time if time > user.longest_session
            user.once_use_ie = true if user.browsers.any? { |b| b =~ /INTERNET EXPLORER/ }
            user.only_use_chrome = true if user.browsers.all? { |b| b =~ /CHROME/ }
            user.dates << SPACE + date + COMMA
          end
        end
        @user_stats = {
            first_name: @user.first_name,
            last_name: @user.last_name,
            sessions_count: @user.total_sessions,
            total_time: @user.total_time,
            longest_session: @user.longest_session,
            browsers: @user.browsers,
            once_use_ie: @user.once_use_ie,
            only_use_chrome: @user.only_use_chrome,
            dates: @user.dates
        }
      end
    common_stats = {
        total_users: @total_users,
        all_browsers: @all_browsers,
        total_sessions: @total_sessions
    }
    save_common_stats(f, common_stats)
    end
    memery_usage = `ps -o rss= -p #{Process.pid}`.to_i / 1024
    puts "MEMORY USAGE: %d MB" % memery_usage
  end

  private

  def save_common_stats(f, **args)
    common_stats = '},'
    common_stats << "\"totalUsers\":#{args[:total_users]},"
    common_stats << "\"uniqueBrowsersCount\":#{args[:all_browsers].size},"
    common_stats << "\"totalSessions\":#{args[:total_sessions]},"

    browsers = args[:all_browsers].map(&:upcase).sort.uniq.join(',')
    common_stats << "\"allBrowsers\":\"#{browsers}\"}"

    f.write(common_stats)
  end

  def save_user_stats(f, total_users, **args)
    f.write(',') if total_users > 1
    f.write("\"#{args[:first_name]} #{args[:last_name]}\":{")
    str = "\"sessionsCount\":#{args[:sessions_count]},"
    str << "\"totalTime\":\"#{args[:total_time]}\","
    str << "\"longestSession\":\"#{args[:longest_session]}\","
    browser_string = ''
    args[:browsers].each { |e| browser_string << SPACE + e + COMMA }
    str << "\"browsers\":\"#{browser_string}\","
    str << "\"usedIE\":#{args[:once_use_ie]},"
    str << "\"alwaysUsedChrome\":#{args[:only_use_chrome]},"
    str << "\"dates\":#{args[:dates].split(COMMA).sort!.reverse!}}"
    f.write(str)
  end
end

# ReportGenerator.new.work
  # Отчёт в json
  #   - Сколько всего юзеров +
  #   - Сколько всего уникальных браузеров +
  #   - Сколько всего сессий +
  #   - Перечислить уникальные браузеры в алфавитном порядке через запятую и капсом +
  #
  #   - По каждому пользователю
  #     - сколько всего сессий +
  #     - сколько всего времени +
  #     - самая длинная сессия +
  #     - браузеры через запятую +
  #     - Хоть раз использовал IE? +
  #     - Всегда использовал только Хром? +
  #     - даты сессий в порядке убывания через запятую +