require 'sinatra'
require "sinatra/json"
require 'open3'
require 'pp'
require 'json'
require 'csv'
require 'base64'

set :protection, except: [ :json_csrf ]

port = ENV['PORT'] || 8080
puts "STARTING SINATRA on port #{port}"
set :port, port
set :bind, '0.0.0.0'

get '/' do
  File.read(File.join('public', 'index.html'))
end

post '/usl' do
	begin
	  	tableArgs = params[:data] 
		eval_usl(tableArgs)
	rescue => error
		pp error.message
    	halt 500  , error.message
	end
end	

def eval_usl(table)
	model = IO.read("./models/usl-calculator.r")

	model = model
		.gsub("\t", "")	
		.gsub("TAB_SPEC_NX", table)	

	error = ""

	Open3.popen3("Rscript -e '#{model}'") do |stdin, stdout, stderr, wait_thr|
	  error = stderr.read
	  pp stdout.read
	end

	if error.nil? || error.empty?
		return Base64.encode64(IO.read("/tmp/rplot-file.jpg"))
	else
		raise error
	end
end

post '/review' do
	content_type :json

	begin
	  	tableArgs = params[:data] 
		data = eval_data(tableArgs)
		data.to_json
	rescue => error
		pp error.message
    	halt 500  , error.message
	end
end	

def eval_data(table)

	result = []
	rawData = CSV.parse(table, headers: true)

	x0 = 0;

	rawData.each_with_index do |row, idx|
		#pp idx
		#pp row

		n = row["N"].to_i
		x = row["X"].to_f

		if idx == 0
			x0 = x;
		end	

		cn = (x/(x0.to_f)).round(2)
		cdivn = (cn/(n.to_f)).round(2)
		ndivc = ((n.to_f)/cn).round(2)
		
		liniarity = n -1;
		deviation = (((n.to_f)/cn)-1).round(2)

		result << {
			:n => n,
			:x => x,
			:cn => cn,
			:cdivn => cdivn,
			:ndivc => ndivc,
			:liniarity => liniarity,
			:deviation => deviation
		}
	end	

	result
end
