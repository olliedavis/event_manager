require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

$hours_arr = Array.new

lib = "/home/ollie/event_manager/"
contents = CSV.open "../event_attendees.csv", headers: true, header_converters: :symbol
#template_letter = File.read "#{lib}/form_letter.erb"
#erb_template = ERB.new template_letter

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_number(number)
  number = number.delete("^0-9").to_s
  if number.length == 11 and number[0] == "1"
    number.to_s[0..9]
  elsif number.length != 10
    number = ""
  end
end

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

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist? "output"
  filename = "output/thanks_#{id}.html"
  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

contents.each do |row|
  id = row[0]
  name = row[:first_Name]
  time = row[:regdate]
  hours = DateTime.strptime(time, '%m/%d/%y %H:%M').hour
  $hours_arr.push(hours)
  phone = clean_number(row[:homephone])
  #zipcode = clean_zipcode(row[:zipcode])
  #legislators = legislators_by_zipcode(zipcode)
  #form_letter = erb_template.result(binding)
  #save_thank_you_letter(id, form_letter)
end

# returns the mode average of the hour of signups
def average_sign_up_time(hours)
  mode_hash = Hash.new(0)
  $hours_arr.each do |int|
    mode_hash[int] += 1
  end
  puts mode_hash.key(mode_hash.values.max)
end

average_sign_up_time($hours_arr)
