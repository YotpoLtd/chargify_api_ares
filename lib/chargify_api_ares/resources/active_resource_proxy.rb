module Chargify
  class ActiveResourceProxy < ActiveResource::Base

    class << self
      alias_method :old_find, :find

      def find(*arguments)
        begin
          return old_find(*arguments)
        rescue ActiveResource::ClientError => exception
          raise Exception.new(exception) unless exception.respond_to?(:response) and exception.response.respond_to?(:code) and exception.response.code == '429'

          # We don't want to initialize anything before the first trial, it's a waste of time.
          retry_count ||= 0
          sleep_in_seconds ||= rand(10) + 1
          max_retries ||= 5

          sleep sleep_in_seconds if retry_count < max_retries

          sleep_in_seconds *= 2
          retry_count += 1
        end while retry_count <= max_retries
        raise Exception.new(exception)

      end
    end
  end
end
