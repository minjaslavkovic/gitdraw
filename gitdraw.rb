require 'git'
require 'logger'
require 'optparse'

def get_repo_commit_dates(repo_dir)
  g = Git.open(repo_dir, :log => Logger.new(STDOUT))
  dates = g.log(count = 1000000).since('1 year ago').map do |l|
    full_time = l.date
    Time.utc(full_time.year, full_time.month, full_time.day, 8, 0, 0)
  end
  return dates.uniq.sort
end

def calendar_to_dates(cal_str)
  calendar_matrix = cal_str.split("\n").map do |day_str|
    day_str.chars.map { |c| (c == '1') }
  end

  today = Time.now
  today = Time.utc(today.year, today.month, today.day, 8, 0, 0)

  r = today.wday
  c = 52
  date_array = []
  365.times do
    if calendar_matrix[r][c] == true
      date_array << today
    end
    today = today - 24 * 60 * 60
    r -= 1
    if r < 0
      r = 6
      c -= 1
    end
  end
  return date_array.uniq.sort
end

def dates_to_calendar(date_array)
  calendar_matrix = [] * 7
  for day in 0..6 do
    calendar_matrix[day] = [false] * 53
  end

  today = Time.now
  today = Time.utc(today.year, today.month, today.day, 8, 0, 0)
  date_array.each do |d|
    # Fake today is the same weekday as d, just in the current week.
    fake_today = today
    while fake_today.wday < d.wday do
      fake_today = fake_today + 60 * 60 * 24  # add a day
    end
    while fake_today.wday > d.wday do
      fake_today = fake_today - 60 * 60 * 24  # remove a day
    end
    diff_sec = fake_today - d
    diff_weeks = (diff_sec/60/60/24/7).floor
    calendar_matrix[d.wday][52 - diff_weeks] = true
  end

  cal_str = ""
  calendar_matrix.each do |day_array|
    cal_str = cal_str + day_array.map { |b| b ? 1 : 0 }.join("")
    cal_str = cal_str + "\n"
  end
  return cal_str
end

def generate_commits(repo_dir, date_array)
  g = Git.open(repo_dir, :log => Logger.new(STDOUT))
  gitdraw_dir = File.join(repo_dir, "gitdraw")
  unless Dir.exist?(gitdraw_dir)
    Dir.mkdir(File.join(repo_dir, "gitdraw"), 0774)
  end
  date_array.each do |d|
    file_path = File.join(gitdraw_dir, "#{d.strftime("%F")}.txt")
    file_content = "Dummy file for #{d.strftime("%F")}\n"
    File.open(file_path, "w") { |f| f.write(file_content) }
    g.add(file_path)
    commit_date = d.strftime("%FT%T%:z")
    ENV["GIT_AUTHOR_DATE"] = commit_date
    ENV["GIT_COMMITTER_DATE"] = commit_date
    g.commit("Dummy commit for #{d.strftime("%F")}")
    ENV.delete("GIT_AUTHOR_DATE")
    ENV.delete("GIT_COMMITTER_DATE")
  end
end

unless ARGV.size == 3
  abort("ARGV must have 3 elements, repo dir, cal file and operation (fetch, commit).")
end

repo_dir = ARGV[0]
cal_file = ARGV[1]
op = ARGV[2]  # fetch, commit

puts "repo_dir: #{repo_dir}"
puts "cal_file: #{cal_file}"
puts "op: #{op}"

unless Dir.exist?(repo_dir)
  abort("invalid repo_dir: #{repo_dir}")
end

case op
when "fetch"
  dates = get_repo_commit_dates(repo_dir)
  cal_str = dates_to_calendar(dates)
  File.open(cal_file, "w") { |f| f.write(cal_str) }
when "commit"
  cal_str =  File.read(cal_file)
  dates = calendar_to_dates(cal_str)
  generate_commits(repo_dir, dates)
else
  abort("invalid op: #{op}")
end
