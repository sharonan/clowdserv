class S3Logger
  def self.log(collection, name, error)
    AwsS3.log_to_bucket('clowdserv-logger', "#{collection}/#{name}: #{Time.now.to_s}", error)
  end
end
class AwsS3
  def self.log_to_bucket(bucket_name,file_name,text)
    s3 = AWS::S3.new(
        :access_key_id => 'AKIAJ5H7P7PQYCDLJKYQ',
        :secret_access_key => '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',
        :region => 'us-west-2',
        )
    s3.buckets["#{bucket_name}"].objects[file_name].write(text,:content_type=> 'text/plain')
  end

end