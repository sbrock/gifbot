require 'cgi'
require 'uri'
require 'open-uri'
require 'cinch'
require 'nokogiri'
require 'gifbot/cli'
require 'gifbot/version'

module GifBot
  GIFBIN_URL = 'http://www.gifbin.com'
  
  def self.connect(options={})
    bot = Cinch::Bot.new do
      configure do |c|
        c.server   = options[:server]
        c.nick     = options[:nick]
        c.channels = options[:channels]
      end
      
      helpers do
        def search(query)
          query   = CGI.escape(query)
          gifs    = []
          results = Nokogiri::HTML( open("#{GIFBIN_URL}/search/#{query}/") )
          
          results.xpath('//div[@class="thumbs"]//a').each do |a|
            gifs << a['href'].sub(/^\//, '')
          end
          
          if gifs.empty?
            "damn, no gif for \"#{query}\""
          else
            id = gifs[rand(gifs.length)]
            page = Nokogiri::HTML( open("#{GIFBIN_URL}/#{id}") )

            image_url_from_page(page,1)
          end
        end
        
        def random
          page = Nokogiri::HTML(open("#{GIFBIN_URL}/random"))
          
          image_url_from_page(page,1)
        end
        
        def image_url_from_page(page,count)
          result_count = page.xpath('//*[@id="gif"]').count
          print "result count #{result_count}\n"
          puts page.xpath('//*[@id="gif"]').first['src']
          urls = URI.escape(page.xpath('//*[@id="gif"]').shift['src'])
          for i in 1..(count-1)
            print "i: #{i}\n"
            urls = "#{urls}\n" +URI.escape(page.xpath('//*[@id="gif"]').shift['src'])
          end
          urls
        end

        def topfive(query)

          query   = CGI.escape(query)
          gifs    = []
          urls    = ""
          results = Nokogiri::HTML( open("#{GIFBIN_URL}/search/#{query}/") )

          results.xpath('//div[@class="thumbs"]//a').each do |a|
            gifs << a['href'].sub(/^\//, '')
          end

          if gifs.empty?
            "damn, no gif for \"#{query}\""
          else
            ids = gifs.sample(5)
            for i in 1..5
              id = ids[i]
              page = Nokogiri::HTML( open("#{GIFBIN_URL}/#{id}") )
              url = image_url_from_page(page,1)
              urls << "\n"+image_url_from_page(page,1)

            end
          end
	  urls
        end
      end
      
      on :message, /^?randomgif/ do |m|
        m.reply random
      end
      
      on :message, /^?gifme (.+)/ do  |m, query|
        m.reply search(query)
      end

      on :message, /^?topfive (.+)/ do |m, query|
        m.reply topfive(query)
      end
      
    end
    
    bot.start
  end
end
