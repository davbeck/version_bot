class CreateVersions < ActiveRecord::Migration
  def change
    create_table :versions do |t|
      t.string :identifier
      t.string :short_version
      t.integer :build, default: 0
      
      t.timestamps
    end
    
    add_index :versions, :identifier
  end
end
