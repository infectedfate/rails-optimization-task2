require 'set'

class ReportGenerator

  SESSION = 'session'.freeze
  SPACE = ' '.freeze
  USER = 'user'.freeze
  COMMA = ','.freeze
  IE = 'INTERNET EXPLORER'.freeze
  CHROME = 'CHROME'.freeze

  def initialize
    @total_users = 0
    @total_sessions = 0
    @all_browsers = Set.new
  end

  User = Struct.new(:id, :first_name, :last_name,
                    :total_sessions,  :total_time,
                    :longest_session, :browsers, :once_use_ie,
                    :only_use_chrome, :dates)
  
  def work(gc_disable: false)
    GC.disable if gc_disable
    
    File.open('result.json', 'w') do |f|
    f.write('{"usersStats":{')
    
      file_lines = File.readlines('data_large.txt')
      file_lines.each do |line|
        if line.start_with?(USER)
          cols = line.strip.split(COMMA)[1..3]
          id = cols[0]
          unless id == @user&.id
            if @user&.id
              save_user_stats(f, @total_users, @user)
            end
          end
          @total_users += 1
          @user = User.new(cols[0], cols[1], cols[2], 0, 0, 0, Set.new, false, false, '')
        else
          @total_sessions += 1
          cols = line.strip.split(COMMA)[3..5]
          browser = cols[0].upcase
          time = cols[1].to_i
          date = cols[2]
          @all_browsers << browser
          @user.tap do |user|
            user.browsers << browser
            user.total_sessions += 1
            user.total_time += time
            user.longest_session = time if time > user.longest_session
            user.once_use_ie = true if user.browsers.any? { |b| b.start_with?(IE)}
            user.only_use_chrome = true if user.browsers.all? { |b| b.start_with?(CHROME) }
            user.dates << SPACE + date + COMMA
          end
        end
      end
    save_common_stats(f, @total_users, @all_browsers, @total_sessions)
    end
    memery_usage = `ps -o rss= -p #{Process.pid}`.to_i / 1024
    puts "MEMORY USAGE: %d MB" % memery_usage
  end

  private

  def save_common_stats(f, total_users, all_browsers, total_sessions)
    common_stats = '},'
    common_stats << "\"totalUsers\":#{total_users},"
    common_stats << "\"uniqueBrowsersCount\":#{all_browsers.size},"
    common_stats << "\"totalSessions\":#{total_sessions},"

    browsers = all_browsers.map(&:upcase).sort.uniq.join(',')
    common_stats << "\"allBrowsers\":\"#{browsers}\"}"

    f.write(common_stats)
  end

  def save_user_stats(f, total_users, user)
    f.write(',') if total_users > 1
    f.write("\"#{user.first_name} #{user.last_name}\":{")
    str = "\"sessionsCount\":#{user.total_sessions},"
    str << "\"totalTime\":\"#{user.total_time}\","
    str << "\"longestSession\":\"#{user.longest_session}\","
    browser_string = ''
    user.browsers.each { |e| browser_string << SPACE + e + COMMA }
    str << "\"browsers\":\"#{browser_string}\","
    str << "\"usedIE\":#{user.once_use_ie},"
    str << "\"alwaysUsedChrome\":#{user.only_use_chrome},"
    str << "\"dates\":#{user.dates.split(COMMA).sort!.reverse!}}"
    f.write(str)
  end
end

ReportGenerator.new.work

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