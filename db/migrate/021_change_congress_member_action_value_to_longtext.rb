class ChangeCongressMemberActionValueToLongtext < ActiveRecord::Migration
  def self.up
    change_column :congress_member_actions, :value, :text, limit: 4294967295
  end

  def self.down
    change_column :congress_member_actions, :value, :string, limit: 511
  end
end
