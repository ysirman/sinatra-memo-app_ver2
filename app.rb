require "sinatra"
require "sinatra/reloader"
require "json"
require "rack-flash"

enable :sessions
use Rack::Flash

FILE_PATH = "memos.json"

# ファイルの読み込み
def get_data(file_path)
  unless File.exist?(file_path)
    open(file_path, "w") do |io|
      JSON.dump({}, io)
    end
  end
  open(file_path) do |io|
    JSON.load(io)
  end
end

# ファイルへ出力
def write_data(file_path, memo_datas)
  open(file_path, "w") do |io|
    JSON.dump(memo_datas, io)
  end
end


["/memos/:id", "/delete/:id", "/edit/:id"].each do |path|
  before path do
    @memo_datas = get_data(FILE_PATH)
    if @memo_datas[params[:id]].nil?
      not_found
    end
  end
end

get "/" do
  @flash = flash[:notice]
  @memo_datas = get_data(FILE_PATH)
  @memo_datas = @memo_datas.sort.reverse.to_h
  erb :index
end

get "/new" do
  erb :new
end

post "/new" do
  @memo_datas = get_data(FILE_PATH)
  # id取得
  if @memo_datas.empty?
    new_id = "1"
  else
    new_id = (@memo_datas.keys.map(&:to_i).sort.last + 1).to_s
  end
  # 改行を変換してから出力
  memo = params[:memo].gsub(/\r\n|\r|\n/, "<br />")
  @memo_datas.store(new_id, "memo" => memo)
  write_data(FILE_PATH, @memo_datas)
  # トップページへ遷移
  flash[:notice] = "メモを作成しました。"
  redirect "/"
end

get "/memos/:id" do
  @memo_data = @memo_datas[params[:id]]
  @id = params[:id]
  erb :show
end

delete "/delete/:id" do
  @memo_datas.delete("#{params[:id]}")
  write_data(FILE_PATH, @memo_datas)
  flash[:notice] = "メモを削除しました。"
  redirect "/"
end

get "/edit/:id" do
  @memo_data = @memo_datas[params[:id]]
  @memo_data = @memo_data["memo"].gsub("<br />", "\r")
  @id = params[:id]
  erb :edit
end

patch "/edit/:id" do
  memo = params[:memo].gsub(/\r\n|\r|\n/, "<br />")
  @memo_datas[params[:id]]["memo"] = memo
  write_data(FILE_PATH, @memo_datas)
  flash[:notice] = "メモが変更されました。"
  redirect "/"
end

not_found do
  @not_found_path = request.path_info
  erb :"404"
end
