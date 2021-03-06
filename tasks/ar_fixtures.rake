require 'fileutils'

def env_or_raise(var_name, human_name)
  if ENV[var_name].blank?
    raise "No #{var_name} value given. Set #{var_name}=#{human_name}"
  else
    return ENV[var_name]
  end  
end

def model_or_raise
  return env_or_raise('MODEL', 'ModelName')
end

def set_or_raise
  return env_or_raise('SET', 'fixture_set')
end

def limit_or_nil_string
  ENV['LIMIT'].blank? ? 'nil' : ENV['LIMIT']
end

def skip_tables
  if ENV['SKIP_TABLES'].blank?
    return skip_tables = ["schema_migrations"]
  else
    return ENV['SKIP_TABLES'].split(',')
  end
end

namespace :db do
  namespace :fixtures do
    desc "Dump data to the test/fixtures/ directory. Use MODEL=ModelName and LIMIT (optional)"
    task :dump => :environment do
      eval "#{model_or_raise}.to_fixture(#{limit_or_nil_string})"
    end

    desc 'Dump a fixture set to the test/fixtures/#{SET} directory.  Use SET=fixture_set, SKIP_TABLES=schema_migrations,... (optional)'
    task :dump_set => :environment do
      FileUtils.mkdir_p "#{RAILS_ROOT}/test/fixtures/#{set_or_raise}"      
      ActiveRecord::Base.establish_connection
      (ActiveRecord::Base.connection.tables - skip_tables).each do |table_name|
        eval "#{table_name.classify}.to_fixture(nil, nil, {}, '#{RAILS_ROOT}/test/fixtures/#{set_or_raise}/#{table_name}.yml')"
      end
    end

    desc 'Load a fixture set from the test/fixtures/#{SET} directory.'
    task :load_set => :environment do
      Dir["#{RAILS_ROOT}/test/fixtures/#{set_or_raise}/*.yml"].each {|fn|
        puts fn
        File.basename(fn,".yml").classify.constantize.load_from_file(fn)
      }
    end
  end
    
  namespace :data do
    desc "Dump data to the db/ directory. Use MODEL=ModelName and LIMIT (optional)"
    task :dump_model => :environment do
      eval "#{model_or_raise}.dump_to_file(nil, #{limit_or_nil_string})"
      puts "#{model_or_raise} has been dumped to the db folder."
    end

    desc "Load data from the db/ directory. Use MODEL=ModelName"
    task :load_model => :environment do
      eval "#{model_or_raise}.load_from_file"
    end
  end
end
