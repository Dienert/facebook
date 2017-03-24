require_relative 'utils'
require_relative 'friend'
require 'json'
require 'uri'

MUTUAL = 3
ALL = 2

ENCERRAR_PROGRAMA = 0
CONTINUAR_PROGRAMA = 1

def get_friends friends_node_page, controle

  # Pegando a div que contém todas as informações do amigo e iterando para cada um
  friends_node_page.xpath(".//div[@data-pnref='all']").each do |div_friends|

    # Pegando id do profile do amigo
    profile_id = div_friends.xpath('.//button[contains(@data-flloc, "profile_browser")]/@data-profileid')

    # Pegando o profile do amigo
    profile = div_friends.xpath('.//div[@class="uiProfileBlockContent"]//a')[0]
    profile = profile.attr("href").to_s
    begin
      profile = profile[profile.index('.com/')+5..profile.length]
    rescue => detail
      # Não faz nada (perfis desabilitados não possuem links)
    end
    if !profile.include? "profile"
      profile = profile[0..profile.index("?")-1] if profile.include? "?"
    else
      profile = profile[0..profile.index("&")-1] if profile.include? "&"
    end

    # Pegando o link para a imagem do amigo
    img = div_friends.xpath('.//img/@src')

    # Pegando todos os links dentro dessa div
    links = div_friends.xpath('.//a')
    n_links = links.size
    # Pegando o nome
    if n_links == 4
      nome = links[2].xpath('text()').to_s
    else
      nome = links[1].xpath('text()').to_s
    end

    controle['counter'] += 1
    friend = Friend.new controle['counter'], profile, profile_id, nome, img

    # Adicionando amigo na lista de ids
    controle['friends_ids']["#{profile_id}"] = friend

    # Salvando em arquivo
    Utils.friends_file.write(",\n") if controle['counter'] > 1
    Utils.friends_file.write("\t\t\t{\"counter\": \"#{controle['counter']}\", \"name\": \"#{nome}\", \"userName\": \"#{profile}\", \"id\": \"#{profile_id}\", \"image\": \"#{img}\"}")

    # Parando o programa ao coletar a quantidade de amigos desejada
    if controle['counter'] == NUMERO_MAXIMO_AMIGOS
      Utils.friends_file.puts '
    ],'
      get_links controle
      return ENCERRAR_PROGRAMA
    end
  end
  return CONTINUAR_PROGRAMA
end

def is_mutual_friend_collected friends_node_page, controle
  friends_node_page.xpath(".//div[@data-pnref='mutual']").each do |div_friends|

    # Pegando id do perfil do amigo mútuo
    profile_id = div_friends.xpath('.//button[contains(@data-flloc, "profile_browser")]/@data-profileid')

    if !controle['friends_ids']["#{profile_id}"].nil?
      puts "#{controle['friends_ids'][controle['friend_profile_id']].name} é amigo de #{controle['friends_ids']["#{profile_id}"].name}"
      controle['links'] += 1
      Utils.friends_file.write(",\n") if controle['links'] > 1
      Utils.friends_file.write "\t\t\t{\"source\":\"#{controle['friend_profile_id']}\",\"target\":\"#{profile_id}\"}"
    else
      next
    end
  end
end


def get_friends_pagination controle

  # Requisição Ajax para coleções de amigos parametrizada
  request = "https://www.facebook.com/ajax/pagelet/generic.php/AllFriendsAppCollectionPagelet?dpr=1.5&data=%7B%22collection_token%22%3A%22#{controle['friend_profile_id']}%3A#{controle['collection_wrapper']}%3A#{controle['colecao']}%22%2C%22cursor%22%3A%22#{controle['cursor']}%22%2C%22tab_key%22%3A%22friends%22%2C%22profile_id%22%3A#{controle['friend_profile_id']}%2C%22q%22%3A%22#{controle['friend_profile']}%22%2C%22overview%22%3Afalse%2C%22ftid%22%3Anull%2C%22order%22%3Anull%2C%22sk%22%3A%22friends%22%2C%22importer_state%22%3Anull%7D&__user=#{controle['my_profile_id']}&__a=1&__dyn=&__af=o&__req=9&__be=-1&__pc=EXP1%3ADEFAULT&__rev=2652207&__srp_t=1477778296"

  controle['requests'] = controle['requests'] + 1


  if controle['requests'] > NUMERO_MAXIMO_REQUISICOES
    puts "Máximo de requisições atingidas #{NUMERO_MAXIMO_REQUISICOES}"
    return ENCERRAR_PROGRAMA
  end

  sleep(SEGUNDOS_ENTRE_REQUISICOES)
#  puts "Enviando Requisição #{controle['requests']}"
  friends_page = Utils.agent.get(request)

  # Buscando a chave para a próxima página de amigos
  index = friends_page.content.to_s.index("MDpub3Rfc3R")
  if !index.nil?
    cursor = friends_page.content.to_s[index..index+100]
    fim = cursor.index("\"") - 1
    controle['cursor'] = cursor[0..fim]
  else
    controle['cursor'] = nil
  end

  # Apagando o 'for (;;);' do começo da página
  # Decodificando entidades HTML ex.: &quot; &amp;
  # Fazendo o parsing do JSON
  json = JSON.parse(URI.unescape(friends_page.content.to_s[9..friends_page.content.to_s.length]))

  # Pegando o elemento dentro do JSON que contém a página
  friends_node_page = Nokogiri::HTML(json["payload"])

  # Analisando a próxima página
  if controle['colecao'] == ALL
    return get_friends friends_node_page, controle
  else
    is_mutual_friend_collected friends_node_page, controle
    return CONTINUAR_PROGRAMA
  end
end

def get_links controle

  Utils.friends_file.puts "\t\t\"links\": ["
  controle["links"] = 0
  controle['friends_ids'].each do |profile_id, friend|

    puts "\n\n#{friend.counter}) #{friend.name}"
    controle['friend_profile_id'] = profile_id
    controle['collection_wrapper'] = Utils.collection_wrapper
    controle['colecao'] = MUTUAL
    controle['cursor']
    controle['friend_profile']
    controle['my_profile_id'] = Utils.profile_id

    result = CONTINUAR_PROGRAMA
    begin
      result = get_friends_pagination controle
    end while (result != ENCERRAR_PROGRAMA && !controle['cursor'].nil?)
    break if result == ENCERRAR_PROGRAMA
  end

  Utils.friends_file.puts "\n]}"
  controle['linksColected'] = true
end

startTime = Time.now

Utils.initialize
controle = Hash.new
controle["counter"] = 0
controle['friend_profile_id'] = Utils.profile_id
controle['collection_wrapper'] = Utils.collection_wrapper
controle['colecao'] = ALL
controle['cursor']
controle['friend_profile']
controle['my_profile_id'] = Utils.profile_id
controle['friends_ids'] = Hash.new
controle['requests'] = 0
puts "Coletando amigos de #{Utils.name}"
begin
  result = get_friends_pagination controle
end while (result != ENCERRAR_PROGRAMA && !controle['cursor'].nil?)

if controle['linksColected'] != true
  Utils.friends_file.puts '
  ],'
  get_links controle
end

finalTime = Time.now

duration = finalTime - startTime
puts 'Tempo total: ' + Utils.duration_from_seconds(duration.to_i)
