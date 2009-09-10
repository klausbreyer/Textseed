class AddEditedByAndEditedAtToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :edited_by, :integer
    add_column :projects, :edited_at, :datetime
  end

  def self.down
    remove_column :projects, :edited_by
    remove_column :projects, :edited_at
  end
end
