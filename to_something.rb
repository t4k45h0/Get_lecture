require "json"
require "date"

class NilLecture
  # 講義名
  def setLectureName(lname)
    @lname = lname
  end

  def getLectureName
    return @lname
  end

  # 教授名
  def setProfName(pname)
    @pname = pname
  end

  def getProfName
    return @pname
  end

  # 受講クラス
  def setClassName(cname)
    @cname = cname
  end

  def getClassName
    return @cname
  end

  # 時限
  def setPeriod(period)
    @period = period
  end

  def getPeriod
    return @period
  end

  # 休講日
  def setDate(date)
    @date = date
  end

  def getDate
    return @date
  end

  # 休講日の曜日
  def setWeekName(wname)
    @wname = wname
  end

  def getWeekName
    return @wname
  end
end

class ToSomething
  # MM/DD を YYYY-MM-DD にする 引数は文字型 引数例：temp = "10/15"
  def to_date_type(temp)
    m = temp.split("/")[0].to_i     # m: 休講するmount
    d = temp.split("/")[1].to_i     # d: 休講するday

    if m.between?(1, 3) & Date.today.month.between?(4, 12) then # 1月から3月の間なら来年を入れる
      y = Date.today.year.to_i + 1
    else                                                        # それ以外なら今年を入れる
      y = Date.today.year.to_i
    end

    return Date.new(y, m, d)
  end

  # 配列 を NilLecture型in配列 にする 引数は配列 引数例：temp = ["10/15 月 2 プロジェクトマネージメント 奥野 3-ABCDEF", "...]
  def to_nillecture_type(temp)
    temps = Array.new(temp.length){NilLecture.new}

    for cnt in 0...temp.length do
      temps[cnt].setDate( to_date_type( temp[cnt].split(" ")[0])) # 例：temp[cnt].split(" ")[0]) = 10/15
      temps[cnt].setWeekName(           temp[cnt].split(" ")[1])  # 例：temp[cnt].split(" ")[1]) = 月
      temps[cnt].setPeriod(             temp[cnt].split(" ")[2])  # 例：temp[cnt].split(" ")[2]) = 2
      temps[cnt].setLectureName(        temp[cnt].split(" ")[3])  # 例：temp[cnt].split(" ")[3]) = プロジェクトマネージメント
      temps[cnt].setProfName(           temp[cnt].split(" ")[4])  # 例：temp[cnt].split(" ")[4]) = 奥野
      temps[cnt].setClassName(          temp[cnt].split(" ")[5])  # 例：temp[cnt].split(" ")[5]) = 3-ABCDEF
    end

    return temps
  end

  # NilLecture型in配列 を associative array(連想配列=ハッシュ)in配列 にする
  def to_associative_array(temp) 
    hash = Array.new

    for cnt in 0...temp.length do
      begin
        hash << {:lectureName=>"#{temp[cnt].getLectureName}", :profName=>temp[cnt].getProfName.split(","), :class=>temp[cnt].getClassName.split(","), :period=>temp[cnt].getPeriod.split(",").map!(&:to_i), :date=>temp[cnt].getDate, :weekName=>"#{temp[cnt].getWeekName}"}

      # 実例: 休講 12/17(月)3限 インタラクティブシステム特論Ⅱ（美馬義）　補講未定
      # →受講クラスの情報が抜けているので、:class=>temp[cnt].getClassName.split(",") で nil を split するので error になる。
      # 例: 休講 10/15(月)2限 プロジェクトマネージメント（奥野）3-ABCDEF 補講有 11/26(月)1限 大講義室
      # →見てのように受講クラス以外の情報が抜けることは考えずらいので、受講クラスがない場合だけ対処する
      rescue
        hash << {:lectureName=>"#{temp[cnt].getLectureName}", :profName=>temp[cnt].getProfName.split(","), :class=>["NULL"], :period=>temp[cnt].getPeriod.split(",").map!(&:to_i), :date=>temp[cnt].getDate, :weekName=>"#{temp[cnt].getWeekName}"}
      end
    end

    return hash.select { |v| v[:date] >= Date.today }.sort_by! { |v| [v[:date].to_s, v[:period]] }
  end
end
