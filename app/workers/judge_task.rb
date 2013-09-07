class JudgeTask
  @queue = :judge

  def self.perform(id)
    submission = Submission.find(id)
    code = submission.code

    compile_output = `gcc #{submission.source_path} -o #{submission.exec_path} #{Settings.compiler_options} 2>&1`
    if $?.success?
      problem = submission.problem
      exec_output = `#{Settings.sandbox_path} -t #{problem.time_limit} -m #{problem.mem_limit} -i #{problem.input_path} #{submission.exec_path}`.split("\n")
      FileUtils.rm_f(submission.exec_path)
      msg = exec_output.pop
      case msg
      when /(\d+) (\d+) (\d+)/
        submission.time_cost = $2.to_i
        submission.status = self.output_eql?(exec_output, problem.ans_path) ? :ac : :wa;
      when 'Program Killed'
        submission.status = :re
      when 'Time Limit Exceeded'
        submission.status = :tle
        submission.msg = msg
      when 'Memory Limit Exceeded'
        submission.status = :re
        submission.msg = msg
      when 'Program Killed'
        submission.status = :re
        submission.msg = msg
      end
    else
      submission.status = :ce
      submission.msg = compile_output
    end

    submission.save
  end

  private

  def self.output_eql?(exec_out, ans_path)
    a = exec_out.map { |s| s.strip }
    a.pop if a[-1].empty?
    b = IO.readlines(ans_path).map { |s| s.strip }
    b.pop if b[-1].empty?
    a == b
  end

end