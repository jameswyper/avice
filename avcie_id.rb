require 'sqlite3'

def get_id(db, table, num = 1)

db.execute('create table if not exists xx_id (name text, id int)')

r = db.execute('select id from xx_id where name  = ?', table)

if  (r.size == 0)
	db.execute('insert into xx_id values (?,?)',table,num)
	return 1
else
	db.execute('update xx_id set id = ? where name = ?', r[0][0] + num, table)
	return (r[0][0] + 1)
end

end