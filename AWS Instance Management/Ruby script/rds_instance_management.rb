#Requiring needed gems
require 'aws-sdk-rds'
require 'aws-sdk-s3'
require 'json'

#Loading aws secrets
aws_credentials = JSON.load(File.read('secrets.json'))
puts aws_credentials

#connecting to AWS using secrets
Aws.config.update({
  credentials: Aws::Credentials.new(aws_credentials['AccessKeyId'], aws_credentials['SecretAccessKey'])
})

#Listing DB Instances
rds = Aws::RDS::Resource.new(region: 'us-west-1')

#Empty Array to hold active RDS instances details
active_instances = []

#Printing both status and names of the instances
rds.db_instances.each do |i|
  puts "Name (ID)     : #{i.id}"
  puts "Status        : #{i.db_instance_status}"
  puts "DB Identifier : #{i.db_instance_identifier}"
  puts "DB snapshot   : #{i.db_snapshot_identifier}"
  active_instances.append([i.db_instance_identifier, i.db_snapshot_identifier]) if i.db_instance_status == "available"
end

if active_instances.nil?
  puts "No Active Instances Found."
  exit
else
  active_instances.each do |instance|
    resp = rds.stop_db_instance({
      db_instance_identifier: instance[0], # required
      db_snapshot_identifier: instance[1]
    })
  end
  puts "Successfully stopped all RDS Active Instances"
end

#Sleeping for 100 seconds
sleep 100

#Starting RDS instances after 100 seconds
active_instances.each do |instance|
  resp = rds.start_db_instance({
    db_instance_identifier: instance[0], # required
  })
end

#References:-
  #https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_StopDBInstance.html
  #https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/RDS/Client.html#stop_db_instance-instance_method


