require File.join(File.dirname(__FILE__), 'abstract_unit')

if ActiveRecord::Base.connection.supports_migrations? 
  class Thing < ActiveRecord::Base
    attr_accessor :version
    acts_as_versioned
  end
  
  class Gadget < ActiveRecord::Base
    def self.add_acts_as_versioned
      self.acts_as_versioned
    end
  end
  
  class GadgetVersion < ActiveRecord::Base
  end

  class MigrationTest < Test::Unit::TestCase
    self.use_transactional_fixtures = false

    def setup
      begin
        ActiveRecord::Migrator.down(File.dirname(__FILE__) + '/fixtures/migrations/',0)
      rescue
        nil
      end
    end
        
    def test_versioned_migration
      assert_raises(ActiveRecord::StatementInvalid) { Thing.create :title => 'blah blah' }
      # take 'er up
      ActiveRecord::Migrator.up(File.dirname(__FILE__) + '/fixtures/migrations/',1)
      t = Thing.create :title => 'blah blah', :price => 123.45, :type => 'Thing'
      assert_equal 1, t.versions.size
      
      # make sure the versioned_at, version_expired_at columns were created and are datetime
      assert_equal :datetime, Thing::Version.columns.find{|c| c.name == "versioned_at"}.type
      assert_equal :datetime, Thing::Version.columns.find{|c| c.name == "version_expired_at"}.type
      
      # check that the price column has remembered its value correctly
      assert_equal t.price,  t.versions.first.price
      assert_equal t.title,  t.versions.first.title
      assert_equal t[:type], t.versions.first[:type]
      
      # make sure that the precision of the price column has been preserved
      assert_equal 7, Thing::Version.columns.find{|c| c.name == "price"}.precision
      assert_equal 2, Thing::Version.columns.find{|c| c.name == "price"}.scale
      
      # now lets take 'er back down
      ActiveRecord::Migrator.down(File.dirname(__FILE__) + '/fixtures/migrations/')
      assert_raises(ActiveRecord::StatementInvalid) { Thing.create :title => 'blah blah' }
    end
    
    def test_migrate_data_to_version_table
      # Create an unversioned record
      ActiveRecord::Migrator.up(File.dirname(__FILE__) + '/fixtures/migrations/',2)
      g = Gadget.create! :title => "The first gadget!"
      assert_raises(NoMethodError) {g.version}

      # Change it to versioned
      Gadget.add_acts_as_versioned
      Gadget.drop_versioned_table rescue nil
      Gadget.create_versioned_table
      g.reload
      assert_nothing_raised {g.version}
      assert_equal 0, g.versions.size

      # Create versioned data for it
      Gadget.populate_versioned_table
      g.reload()
      assert_equal 1, g.versions.size
      
      # Make sure the version is updated on the object
      assert_equal g.versions.last.id, g.version
    end
  end
end
