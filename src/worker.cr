require "pg"
require "json"
require "uuid"
require "./job"

class Worker
  DB_URL = "postgres://postgres:password@localhost/workers"

  SQL = <<-SQL
    UPDATE jobs SET status = 1
    WHERE id = (
      SELECT id
      FROM jobs
      WHERE status = 0
      ORDER BY id
      FOR UPDATE SKIP LOCKED
      LIMIT 1
    )
    RETURNING *;
  SQL

  def initialize
    @listen_conn = PG.connect_listen(DB_URL, "jobs_status_channel", blocking: false) do |n|
      puts "Got job with payload: #{n.payload} on #{n.channel}"
      claim_job(n.payload)
    end
  end

  def stop
    @listen_conn.close
  end

  private def claim_job(job_id)
    DB.open(DB_URL) do |db|
      db.query(SQL) do |rs|
        pp! rs.column_count
        rs.each do
          id = rs.read(UUID)
          payload = rs.read(JSON::Any)
          status = Job::Status.new(rs.read(Int32))
          created_at = rs.read(Time?)
          completed_at = rs.read(Time?)
          failed_at = rs.read(Time?)

          job = Job.from_json(payload.to_json)
          job.status = status

          puts "Claimed job: #{id}"
          puts "Task: #{job.task}"
          puts "Params: #{job.params}"
          puts "Status: #{status}"
          puts "Created at: #{created_at}"

          process_job(job)
        end
      end
    end
  end

  private def process_job(job)
    puts "Processing job: #{job.id}"

    DB.open(DB_URL) do |db|
      db.exec("UPDATE jobs SET status = $1, completed_at = NOW() WHERE id = $2",
        Job::Status::Complete.value, job.id)
    end

    puts "Job #{job.id} completed"
  end
end

Worker.new

sleep
