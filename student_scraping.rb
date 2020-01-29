require "./to_something.rb"
require "selenium-webdriver"
require "faraday"

# chrome の起動設定
options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--start-maximized')           # 最大化にする
options.add_argument('--disable-notifications')     # 通知をオフにする
options.add_argument('--ignore-certificate-errors') # 証明書エラー無視する

# 画面なしなら true 画面ありならfalse
if true then
  options.add_argument('--headless')                # ヘッドレスモード
  options.add_argument('--disable-gpu')             # gpuオフ
end

# Chromeが起動する
driver = Selenium::WebDriver.for :chrome, options: options

puts "\e[2A"
puts "                                                                                                                                       "
puts "\e[4A"
puts "                                                                                                                                       "
print "\e[1A"

# timeoutオプションは秒数を指定している。この場合は100秒
wait = Selenium::WebDriver::Wait.new(:timeout => 100)

# Studentにアクセスする
driver.navigate.to "https://student.fun.ac.jp/up/faces/login/Com00501A.jsp"

puts "Access https://student.fun.ac.jp/up/faces/login/Com00501A.jsp"

# IDのインプットボックスを探す
wait.until {
  driver.find_element(:name, 'form1:htmlUserId').displayed?
}

# IDのインプットボックスを探し、IDのインプットボックスにIDを送る
element = driver.find_element(:name, 'form1:htmlUserId')
element.send_keys(ENV["STUDENTID"])

# Passwordのインプットボックスを探し、PasswordのインプットボックスにPasswordを送る
element = driver.find_element(:name, 'form1:htmlPassword')
element.send_keys(ENV["STUDENTPASS"])

# loginボタンをクリック
driver.find_element(:xpath, '//*[@id="form1:login"]').click

puts "Login"

# 休講・補講・試験情報の件数を探す
wait.until {
  driver.find_element(:xpath, '//*[@id="form1:Poa00201A:htmlParentTable:1:htmlDisplayOfAll:0:htmlCountCol21702"]').displayed?
}

# 休講・補講・試験情報の件数を取得
num = driver.find_element(:xpath, '//*[@id="form1:Poa00201A:htmlParentTable:1:htmlDisplayOfAll:0:htmlCountCol21702"]').text.delete("^0-9").to_i

if (num > 0) and (num < 5) then # 件数が 0 < num < 5 (ホームでは4件しか表示されないため)の場合
  path = ['//*[@id="form1:Poa00201A:htmlParentTable:1:htmlDetailTbl:', ':htmlTitleCol1"]']

elsif num >= 5 then             # 件数が 5 以上の場合
  path = ['//*[@id="form1:Poa00201A:htmlParentTable:0:htmlDetailTbl2:', ':htmlTitleCol3"]']

  # 全て表示するをクリック
  driver.find_element(:xpath, '//*[@id="form1:Poa00201A:htmlParentTable:1:htmlDisplayOfAll:0:htmlCountCol217"]').click

  # 今月がいつか探す
  wait.until {
    driver.find_element(:xpath, '//*[@id="form1:Poa00101A:htmlDate_month"]').displayed?
  }
end

# 今月がいつか取得
month = driver.find_element(:xpath, '//*[@id="form1:Poa00101A:htmlDate_month"]').text

data = ""
for cnt in 0..num-1 do #上から件名をチェック
  check = driver.find_element(:xpath, path[0]+cnt.to_s+path[1]).text

  # 先頭に "休" と "分】" が含まれていて、先月じゃない場合 例：休講・補講情報【12月以降分】11/6更新
  if check =~ (/^休/ && /分】/) && check.include?("【"+Date.today.prev_month(1).month.to_s+"月") == false then
    # 遷移前のウィンドウ情報を取得
    cash = driver.window_handles.last

    # 休講情報を開く
    driver.find_element(:xpath, path[0]+cnt.to_s+path[1]).click

    # ウィンドウの遷移先で休講する講義のリストを得る を出来るまで繰り返す
    begin
      driver.switch_to.window(driver.window_handles.last)
      data = data + driver.find_element(:xpath, '//*[@id="form1:htmlMain"]').text + "\n\n"
    rescue
      retry
    end

    # 遷移先のウィンドウを閉じる
    driver.close

    # 遷移元のウィンドウに遷移先のウィンドウ情報を移す
    driver.switch_to.window(cash)
  end
end

driver.quit

unless data.empty? then
  puts "Get data"

  datas = Array.new

  # 配列に 行から補講情報を削り、全角数字を半角数字にし、全角／を半角/にし、全角，を半角,にし、全角空白と半角空白を消し、全角括弧を半角括弧にし、先頭の休講の文字を消し、限を半角空白に置き換え、半角括弧を半角空白に置き換えた ものを入れる
  # 例：休講 １１／29(木)4限　オープン技術特論（奥野）M1, 2 補講有 11/1(木)3限 エレクトロニクス工房
  data.each_line do |temp|
    if temp =~ /^休/ then # 先頭に休がある行のとき
      datas << temp.split("補講")[0].tr("０-９", "0-9").gsub("／", "/").gsub("，", ",").gsub(/　| /, "").gsub("（", "(").gsub("）", ")").gsub(/^(休講)/, "").gsub(/限/, " ").gsub(/\(/, " ").gsub(/\)/, " ").gsub(/M1,2/, "M1,M2")
    end
  end
a
  to_something = ToSomething.new

  puts "Start post json"

  to_something.to_associative_array(to_something.to_nillecture_type(datas)).each do |temp|
    begin
      response = Faraday.post "http://localhost:3000/lecture", JSON.generate(temp), content_type: "application/json"
      case response.status
        when 100..199 # リクエストは受け取られた。処理は継続される。
          puts "Informational: " + "#{response.status}"
        when 200..299 # リクエストは受け取られ、理解され、受理された。
          puts "Success: " + "#{response.status}"
        when 300..399 # リクエストを完了させるために、追加的な処理が必要。
          puts "Redirection: " + "#{response.status}"
        when 400..499 # クライアントからのリクエストに誤りがあった。
          puts "Client Error: " + "#{response.status}"
        when 500..599 # サーバがリクエストの処理に失敗した。
          puts "Server Error: " + "#{response.status}"
      end
    rescue Faraday::Error::TimeoutError => e
      puts "Timeout Error: " + "#{e.message}"
    rescue Faraday::Error::ConnectionFailed => e
      puts "ConnectionFailed: " + "#{e.message}"
    rescue # 予期せぬエラーが発生しました。
      puts "Error: an unexpected error has occurred."
    end
  end

  File.open("Lecture_Cancellations_Info.json","w+") do |temp|
    temp.puts(JSON.pretty_generate(to_something.to_associative_array(to_something.to_nillecture_type(datas))))
  end

  puts "Successful!"

else
  puts "Error: variable named 'data' is empty."
end
