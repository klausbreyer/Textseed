class AddEchoeToUnit < ActiveRecord::Migration
  def self.up
    add_column :units, :echoe, :text
  end

  def self.down
    remove_column :units, :echoe
  end
end
