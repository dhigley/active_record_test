#!/usr/bin/env ruby
require 'active_record'
require 'sqlite3'

# establish a connnection to hw05.db
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'hw05.db')

# create Active Record objects for HOST, ADMIN, and MANAGER
# express many-to-many relationships between HOSTS and ADMINS
# express one-to-many relationships between MANAGERS and ADMINS
class Manager < ActiveRecord::Base
  has_many :admins
  validates :telephone, format: { with: /\d{3}-\d{3}-\d{4}/, message: "bad format" }
end

class Admin < ActiveRecord::Base
  has_and_belongs_to_many :hosts
  belongs_to :manager
  validates :telephone, format: { with: /\d{3}-\d{3}-\d{4}/, message: "bad format" }
end

class Host < ActiveRecord::Base
  has_and_belongs_to_many :admins
end

class Manager_Admin < ActiveRecord::Base
  self.table_name = 'Managers_Admins' # overrides defaults
  # create implied FK constraints
  belongs_to :manager
  validates :manager, presence: true
  belongs_to :admin
  validates :admin, presence: true
end

class Host_Admin < ActiveRecord::Base
  self.table_name = 'Hosts_Admins' # overrides defaults
  # enforce the FK constraint from SQLite schema
  belongs_to :host
  validates :host, presence: true
  belongs_to :admin
  validates :admin, presence: true
end

# Use ActiveRecord to find the admins that are associated with any one hosts
puts "#{'#'*3} Admins administer Host #{'#'*3}"
rubystart = Time.now
Host.all.each do |h|
  Host_Admin.all.each do |ha|
    Admin.all.each do |a|
      if ha.host_id == h.id && ha.admin_id == a.id
        puts "#{a.first_name} #{a.last_name} administers the host at: #{h.domain_name}"
      end
    end
  end
end
rubyend = Time.now
puts "Ruby took: #{rubyend - rubystart} seconds"
puts

sqlstart = Time.now
sql = "SELECT a.first_name, a.last_name, h.domain_name
        FROM admins a, hosts h, hosts_admins ha
        WHERE a.id = ha.admin_id AND h.id = ha.host_id"
results = ActiveRecord::Base.connection.execute(sql)

results.each do |r|
  puts "#{r['first_name']} #{r['last_name']} administers the host at: #{r['domain_name']}"
end
sqlend = Time.now
puts "SQL took: #{sqlend - sqlstart} seconds"
puts

# Use ActiveRecord to generate three ad hoc queries on HOSTS, ADMINS, or MANAGERS
puts "Admins who's last names end with 'Vader':"
adm = Admin.select(:first_name, :last_name).where("last_name = ?", 'Vader')
adm.each do |a|
  puts "#{a.last_name}, #{a.first_name}"
end
puts

puts "Hosts that have domains ending in '.com':"
hst = Host.where("domain_name LIKE ?", '%.com')
hst.each do |h|
  puts "#{h.host_name} => #{h.domain_name}"
end
puts

puts "Evil managers who's last names are not 'Sidious':"
mgr = Manager.where.not("last_name = ?", 'Sidious')
mgr.each do |m|
  puts "#{m.last_name}, #{m.first_name} - #{m.telephone}"
end
