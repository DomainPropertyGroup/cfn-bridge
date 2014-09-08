require 'cloud_formation/bridge/exception_notifier'
require 'cloud_formation/bridge/names'
require 'cloud_formation/bridge/resources/subscribe_queue_to_topic'
require 'cloud_formation/bridge/resources/cloud_formation_outputs'
require 'cloud_formation/bridge/resources/create_redis_replication'

module CloudFormation
  module Bridge
    class Executor

      include CloudFormation::Bridge::Names

      DEFAULT_REGISTRY = {
        "Custom::SubscribeSQSQueueToSNSTopic" =>
          CloudFormation::Bridge::Resources::SubscribeQueueToTopic.new,
        "Custom::CloudFormationOutputs" =>
          CloudFormation::Bridge::Resources::CloudFormationOutputs.new,
        "Custom::CreateRedisReplication" =>
          CloudFormation::Bridge::Resources::CreateRedisReplication.new,
      }

      attr_reader :registry

      def initialize(registry = DEFAULT_REGISTRY)
        @registry = registry
      end

      def execute(request)

        begin
          if resource = registry[request.resource_type]
            response = if request.create?
              resource.create(request)
            elsif request.update?
              resource.update(request)
            else
              resource.delete(request)
            end

            request.succeed!(response)
          else
            request.fail!("Don't know what to do with resource #{request.resource_type}")
          end
        rescue Exception => ex
          ExceptionNotifier.report_exception(ex, request.request)
          request.fail!(ex.message)
        end

      end

    end
  end
end