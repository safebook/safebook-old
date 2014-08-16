module Commons
  def app
    Sinatra::Application
  end

  def public_url(user)
    "/users/#{user["pseudo"]}"
  end

  def private_url(user)
    "/users/#{user["pseudo"]}?token=#{user["token"]}"
  end

  def part_1(user)
    user.select do |key,value|
      ["pseudo","email","token"].include?(key)
    end
  end

  def part_2(user)
    user.select do |key,value|
      ["pubkey","data"].include?(key)
    end
  end

  def user1
    {
      "pseudo" => "user1",
      "email"  => "user1@safebook.fr",
      "token" => "secret1",
      "pubkey" => "ppppppppp",
      "data" => "dddddd"
    }
  end

  def user2
    {
      "pseudo" => "user2",
      "email"  => "user2@safebook.fr",
      "token" => "secret2",
      "pubkey" => "ppppppppp",
      "data" => "dddddd"
    }
  end

  def circle
    { "name" => "name", "data" => "data" }
  end

  def circle2 
    { "name" => "name2", "data" => "data2" }
  end

  def auth 
    { "data" => "datadata" }
  end
end

def store_response(content)
  File.open 'response.html', 'w' do |f|
    f.write content
  end
end
