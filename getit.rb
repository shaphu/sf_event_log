
require 'restforce'
require 'net/http'
require 'uri'
require 'fileutils'
require './file_zipper'

# fill in the credentials 
client = Restforce.new(username: '',
                       password: '',
                       client_id: '',
                       client_secret: '',
                       api_version: '41.0')

#update to the appropiate date range                       
accounts = client.query('select Id, EventType, Logdate from EventLogFile where LogDate = Last_n_Days:2')

#get the token from the client object
client.options[:oauth_token]

#Create the directory to place the logs 
directory_name = "BoxStaging"
Dir.mkdir(directory_name) unless File.exists?(directory_name)


#iterate through the ID's in the loop and write to file
accounts.each do |i|
    dates ||= [] #declaring an empty array to store all the dates of the log files
    puts "---------------Downloading for #{i.Id} -------------------------------------------------------"
    puts "File name: #{i.EventType}"
    puts "Logdate : #{i.LogDate}"

    fulldate = "#{i.LogDate}"
    date = fulldate[0..9]
    dates.push(date)
    uri = URI.parse("#{client.options[:instance_url]}/services/data/v41.0/sobjects/EventLogFile/#{i.Id}/LogFile")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{client.options[:oauth_token]}"
    request["X-Prettyprint"] = "1"
    
    req_options = {
      use_ssl: uri.scheme == "https",
    }
    
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    File.open("#{directory_name}/#{date}-#{i.EventType}.csv", 'w') { |file| file.write(response.body)}
end

p uniq_date = dates.uniq #get only the unique dates array

#create folders for each date
uniq_date.each do |folder|
    Dir.mkdir("#{directory_name}/#{folder}") unless File.exists?("#{directory_name}/#{folder}")
    Dir.glob("#{directory_name}/*.csv") do |log_file|
        FileUtils.mv(log_file, "#{directory_name}/#{folder}") if log_file.include?(folder)
    end
    # create zip file for each date
    compress("#{directory_name}/#{folder}")
end


