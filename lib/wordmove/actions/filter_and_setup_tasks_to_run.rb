module Wordmove
  module Actions
    class FilterAndSetupTasksToRun
      extend ::LightService::Action
      include Wordmove::Actions::Helpers
      include Wordmove::Actions::Ssh::Helpers
      include WordpressDirectory::RemoteHelperMethods
      expects :guardian,
              :cli_options
      promises :folder_tasks,
               :database_task,
               :wordpress_task

      executed do |context|
        all_taks = Wordmove::CLI.wordpress_options

        required_tasks = all_taks.select do |task|
          context.cli_options[task] ||
            (context.cli_options["all"] && context.cli_options[task] != false)
        end

        allowed_tasks = required_tasks.select { |task| context.guardian.allows task }

        # Since we `promises` the following valiables, we cannot set them as `nil`
        context.database_task = allowed_tasks.delete(:db) || false
        context.wordpress_task = allowed_tasks.delete(:wordpress) || false
        context.folder_tasks = allowed_tasks # :db and :wordpress were just removed, so we consider
                                             # the reminders as folder tasks. It's a weak assumption
                                             # though.
      end
    end
  end
end