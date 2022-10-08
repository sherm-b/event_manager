require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
    if phone_number.length == 10
        phone_number
    elsif phone_number.length == 11 && phone_number[0] == 1
        phone_number[1..10]
    else
        phone_number = '0000000000'
        phone_number
    end
end

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        legislators = civic_info.representative_info_by_address(
            address: zip,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
            'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exists?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

def save_signup_times(regdate, name)
    Dir.mkdir('signup-times') unless Dir.exists?('signup-times')
    regdate_strip = DateTime.strptime(regdate, '%m/%d/%Y %H:%M')
    regdate_date = regdate_strip.to_date.wday
    regdate_str = regdate_strip.strftime("#{name} signed up at %H:%M on a #{Date::DAYNAMES[regdate_date]}\n")
    times_file = File.open('signup-times/signup-times.txt', 'a')
    times_file.write("#{regdate_str}")
    times_file.close
end





puts 'Event Manager Initialized!'

contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol,
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter


contents.each do |row|

    id = row[0]
    name = row[:first_name]
    time = row[:regdate]

    save_signup_times(time, name)

    zipcode = clean_zipcode(row[:zipcode])

    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)
    
    save_thank_you_letter(id, form_letter)

end