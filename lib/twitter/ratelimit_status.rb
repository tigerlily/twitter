require "hashie"
require "time"

module Twitter
  # Reports the rate limit status from response HTTP headers
  module RatelimitStatus
    
    def ratelimit_status
      @ratelimit_status ||= Hashie::Mash.new { |hash, api_class| hash[api_class] = Hashie::Mash.new }
    end

    def update_ratelimit_status(response)
      headers = response.headers.select {|k, v| k.include? 'x-ratelimit' }
      limit_class = headers['x-ratelimit-class']
      
      status = ratelimit_status[limit_class]
      response_date = Time.httpdate(response.headers['Date'])
      return if status.updated_at && status.updated_at > response_date
      
      status['updated_at'] = response_date
      headers.each_pair { |k, v| status[k.gsub 'x-ratelimit-', ''] = v.to_i }
      ratelimit_status[limit_class] = status
    end
    
  end
end