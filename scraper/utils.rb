require 'mechanize'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG = 1

NUMERO_MAXIMO_REQUISICOES = 1000000
NUMERO_MAXIMO_AMIGOS = 2000
SEGUNDOS_ENTRE_REQUISICOES = 0.0005

class Utils
  @@agent
  @@test_result_page = File.open("test_page.html", "w")
  @@appUrl = 'https://www.facebook.com/'
  @@profile_id
  @@profile
  @@name
  @@collection_wrapper

  def self.collection_wrapper
    @@collection_wrapper
  end

  def self.name
    @@name
  end

  def self.profile_id
    @@profile_id
  end

  def self.profile
    @@profile
  end

  def self.agent
    @@agent
  end

  def self.appUrl
    @@appUrl
  end

  def self.save_result_page(page)
    @@test_result_page.write(page.to_s)
  end

  def self.test_result_page
    @@test_result_page
  end

  def self.friends_file
    @@friends_file
  end

  def self.initialize

    @@agent = Mechanize.new { |a|
      a.user_agent_alias = 'Mac Safari'
      a.idle_timeout = 1
      a.read_timeout = 300
    }

    @@test_result_page = File.open("test_page.html", "w")

    login
  end

  def self.handlePage page
    doc = Nokogiri::HTML(page.content.to_s)

    doc.xpath('.//code').each do |code|
        html = code.to_s
        inicio = html.index("<!-- ")+5
        fim = html.index(" -->")
        code.inner_html = html[inicio..fim]
        code.name = "div"
    end
    doc
  end

  def self.login
    file = File.open("access", "r")
    email = file.gets.gsub(%r{\s$}, "")
    pass = file.gets.gsub(%r{\s$}, "")

    #email = `read -p "Login: " uid; echo $uid`.chomp
    #pass = `read -s -p "Senha: " password; echo $password`.chomp

    # Efetuando Login
    request = @@appUrl
    login_page = @@agent.get(request)
    form = login_page.form_with(:id => 'login_form')
    form.email = email
    form.pass = pass
    result = form.submit
    home_doc = Nokogiri::HTML(result.content.to_s)
    login = home_doc.xpath('.//form[@id="login_form"]')
    if login.to_s != ''
      puts "Falha no Login"
      exit
    else
      puts "Login efetuado com sucesso"
    end

    # Pegando o id do profile Ex.: 1000010919726
    comeco = result.content.to_s.index('viewerid') + 10
    id = result.content.to_s[comeco..comeco+20]
    id = id[0..id.index("\"")-1]
    @@profile_id = id

    # Pegando o perfil Ex.: fulano.beltrano12
    fim = result.content.to_s.index("\" title=\"Perfil\"")
    fim = result.content.to_s.index("\" title=\"Profile\"") if fim.nil?
    profile = result.content.to_s[fim-100..fim-1]
    antes_perfil = "facebook.com/"
    profile = profile[profile.index(antes_perfil)+antes_perfil.length..profile.length]
    @@profile = profile

    # Pegando o id da coleção de amigos
    user_page = @@agent.get("http://www.facebook.com/#{@@profile}")

    user_page_doc = handlePage(user_page)

    friends_page_url = user_page_doc.xpath(".//a[@data-tab-key='friends']/@href")
    friends_page = @@agent.get(friends_page_url)
    collec_wrap_str = "collection_wrapper_"
    friends_page = friends_page.content.to_s
    comeco = friends_page.index(collec_wrap_str)
    @@collection_wrapper = friends_page[comeco..comeco+100]
    comeco = "collection_wrapper_".length
    fim = @@collection_wrapper.index('" class') - 1
    @@collection_wrapper = @@collection_wrapper[comeco..fim]
    puts @string

    # Pegando o nome do perfil
    friends_page_doc = Nokogiri::HTML(friends_page)
    @@name = friends_page_doc.xpath(".//title/text()")

    # Criando arquivo json para o perfil
    @@friends_file = File.open("../interface/#{@@name}.#{NUMERO_MAXIMO_AMIGOS}.json", "w")
    @@friends_file.puts "{\"userId\":\"#{@@profile_id}\",\"userName\":\"#{@@profile}\",\"name\":\"#{@@name}\",
    \"nodes\": ["


  end

  def self.duration_from_seconds(seconds)
      secs = "0"
      min = "0"
      hours = "0"
      seconds = seconds.to_i
      minInt = (seconds / 60).to_i
      secsInt = seconds % 60
      secs = secsInt.to_s
      hoursInt = (minInt / 60).to_i
      minInt = minInt % 60
      min = minInt.to_s
      dias = (hoursInt / 24).to_i.to_s
      hoursInt = hoursInt % 24
      hours = hoursInt.to_s
      return dias + ":" + hours + ":" + min + ":" + secs
  end

end
