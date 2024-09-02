require "kemal"
require "pg"
require "json"
require "uuid"
require "./publisher"

DB_URL = "postgres://postgres:password@localhost/workers"

db = DB.open(DB_URL)
db.exec("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"")
db.exec("CREATE TABLE IF NOT EXISTS jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  payload JSONB NOT NULL,
  status INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  failed_at TIMESTAMP WITH TIME ZONE
)")

publisher = Publisher.new(db)

post "/jobs/:job_name" do |env|
  publisher.enqueue(env.params.url["job_name"], JSON.parse(env.params.json.to_json))
  {"success": true}.to_json
end

Kemal.run
