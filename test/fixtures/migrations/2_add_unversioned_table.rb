class AddUnversionedTable < ActiveRecord::Migration
  def self.up
    create_table("gadgets") do |t|
      t.column :title, :text
    end
  end
  
  def self.down
    drop_table "gadgets" rescue nil
  end
end
