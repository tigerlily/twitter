require 'helper'

describe Twitter::API do
  before do
    @keys = Twitter::Configuration::VALID_OPTIONS_KEYS
  end

  context "with module configuration" do

    before do
      Twitter.configure do |config|
        @keys.each do |key|
          config.send("#{key}=", key)
        end
      end
    end

    after do
      Twitter.reset
    end

    it "should inherit module configuration" do
      api = Twitter::API.new
      @keys.each do |key|
        api.send(key).should == key
      end
    end

    context "with class configuration" do

      before do
        @configuration = {
          :consumer_key => 'CK',
          :consumer_secret => 'CS',
          :oauth_token => 'OT',
          :oauth_token_secret => 'OS',
          :adapter => :typhoeus,
          :endpoint => 'http://tumblr.com/',
          :gateway => 'apigee-1111.apigee.com',
          :format => :xml,
          :proxy => 'http://erik:sekret@proxy.example.com:8080',
          :search_endpoint => 'http://google.com/',
          :user_agent => 'Custom User Agent',
        }
      end

      context "during initialization"

        it "should override module configuration" do
          api = Twitter::API.new(@configuration)
          @keys.each do |key|
            api.send(key).should == @configuration[key]
          end
        end

      context "after initilization" do

        it "should override module configuration after initialization" do
          api = Twitter::API.new
          @configuration.each do |key, value|
            api.send("#{key}=", value)
          end
          @keys.each do |key|
            api.send(key).should == @configuration[key]
          end
        end
      end
    end
  end

  %w(api api_identified).each do |api_class|
    context "with requests in API class '#{api_class}'" do
      before do
        @client = Twitter::Client.new
        stub_request(:get, "https://api.twitter.com/statuses/user_timeline.json").
            with(:query => {:screen_name => 'sferik'}).
            to_return(:status => 200, :headers => {
              "Date"                  => "Sat, 18 Jun 2011 13:55:08 GMT",
              "x-ratelimit-limit"     => "350",
              "x-ratelimit-remaining" => "22",
              "x-ratelimit-class"     => api_class,
              "x-ratelimit-reset"     => "1308302676",
              'x-bogus-header'        => 'anything'
            })
      end

      it "should report API rate limits from headers" do
        @client.get('/statuses/user_timeline', {:screen_name => 'sferik'})
        @client.ratelimit_status[api_class].tap do |rl|
          rl.updated_at.should eql(Time.parse("2011-06-18 15:55:08 +0200"))
          rl.remaining.should eql 22
          rl.limit.should eql 350
          rl.reset.should eql 1308302676
        end
      end
    end
  end

end
