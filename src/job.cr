class Job
  include JSON::Serializable

  enum Status
    Ready
    Processing
    Complete
    Failed
  end

  property id : String
  property task : String
  property params : JSON::Any
  property status : Status

  def initialize(@id, @task, @status, @params)
  end
end
