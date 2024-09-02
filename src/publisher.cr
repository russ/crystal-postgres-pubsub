require "./job"

class Publisher
  def initialize(@db : DB::Database)
  end

  def enqueue(task : String, params : JSON::Any)
    job = Job.new(id: UUID.random.to_s, task: task, params: params, status: Job::Status::Ready)
    @db.exec("INSERT INTO jobs (id, payload, status) VALUES ($1, $2, $3)", job.id, job.to_json, job.status.to_i)
    @db.exec("NOTIFY jobs_status_channel, '#{job.id}'")
  end
end
