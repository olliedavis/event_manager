require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

$hours_arr = Array.new
$days_arr = Array.new

contents = CSV.open "../event_attendees.csv", headers: true, header_converters: :symbol
template_letter = File.read "../form_letter.erb"
erb_template = ERB.new template_letter

# if the zipcode is less than 5 numbers, 0's are added to the beginning until does. 
# if the zipcode is more than 5 numbers, it returns on the first 5 digits.
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

# strips non-integers from the number and checks to see if it's a valid number
def clean_number(number)
  number = number.delete("^0-9").to_s
  if number.length == 11 and number[0] == "1"
    number.to_s[0..9]
  elsif number.length != 10
    number = ""
  end
end

##  pulls the representative info and matches them to each user by zipcode
def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
        address: zip,
        levels: 'country',
        roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
      "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

# creates a directory in the project folder, creates a HTML files, opens it, and then puts the ERB template inside
def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist? "output"
  filename = "output/thanks_#{id}.html"
  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

# iterates through the CSV file, assigning each required column a variable.
contents.each do |row|

  id = row[0]
  name = row[:first_name]
  time = row[:regdate]
  date = DateTime.strptime(time, '%m/%d/%y %H:%M')


  $hours_arr.push(date.hour)
  $days_arr.push(date.wday)
  phone = clean_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
  puts "Thank you letter created for #{name}"
  
end

# returns the mode average of the hour of signups
def average_sign_up_time(hours_arr)
  mode_hours_hash = Hash.new(0)
  $hours_arr.each do |int|
    mode_hours_hash[int] += 1
  end
  mode_hours_hash.key(mode_hours_hash.values.max)
end

#returns the the mode average day of sign ups
def average_sign_up_days(days_arr)
  mode_days_hash = Hash.new(0)
  $days_arr.each do |int|
    mode_days_hash[int] += 1
  end
  mode_days_hash.key(mode_days_hash.values.max)
end


def average_day_and_time
  time = average_sign_up_time($hours_arr)
  day = average_sign_up_days($days_arr)
  weekday =  Date::DAYNAMES[day]
  puts "The most common day to sign up is on #{weekday}"
  puts "The most common time of the day to sign up is #{time}:00"
end
  
average_day_and_time
