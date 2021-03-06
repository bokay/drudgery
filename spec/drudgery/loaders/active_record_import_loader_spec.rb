require 'spec_helper'

class Record < ActiveRecord::Base; end

module Drudgery
  module Loaders
    describe ActiveRecordImportLoader do
      before do
        ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
        ActiveRecord::Base.connection.create_table(:records) do |t|
          t.integer :a
          t.integer :b
        end

        @loader = ActiveRecordImportLoader.new(Record)
      end

      after do
        ActiveRecord::Base.clear_active_connections!
      end

      describe '#name' do
        it 'returns active_record_import:<model name>' do
          @loader.name.must_equal 'active_record_import:Record'
        end
      end

      describe '#load' do
        it 'writes records using model.import' do
          record1 = { :a => 1, :b => 2 }
          record2 = { :a => 3, :b => 4 }

          @loader.load([record1, record2])

          records = Record.all.map(&:attributes)
          records.must_equal([
            { 'id' => 1, 'a' => 1, 'b' => 2 },
            { 'id' => 2, 'a' => 3, 'b' => 4 }
          ])
        end
      end
    end
  end
end
