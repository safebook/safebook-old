require "test/unit"
require "capybara-webkit"
require 'capybara/dsl'

Capybara.app_host = 'http://0.0.0.0:5555'
Capybara.run_server = false
#Capybara.current_driver = :selenium
Capybara.current_driver = :webkit

class HomeTest < Test::Unit::TestCase
  include Capybara::DSL

  def assert_model_state(users, keys, messages)
    sleep 0.5
    assert(page.all("#users .user").count == users)
    assert(page.all("#keys .key").count == keys)
    assert(page.all("#messages .message").count == messages)
  end

  def test_case
    @pseudo = (0...8).map { (65 + rand(26)).chr }.join

    p 'Signup'
    visit '/'
    page.fill_in "pseudo_input", with: @pseudo
    page.click_on("signup_btn")
    assert_model_state(0, 0, 0)

    p 'Send a key to ourself'
    page.click_on("Add a key")
    assert_model_state(0, 1, 0)

    p 'Send a message to ourself'
    page.fill_in "message_input", with: "Some message"
    page.click_on("message_btn")
    assert_model_state(0, 1, 1)

    p 'Signin'
    visit '/'
    page.fill_in "pseudo_input", with: @pseudo
    page.click_on("signin_btn")
    assert_model_state(0, 1, 1)
  end

  def test_case2
    @pseudo1 = (0...8).map { (65 + rand(26)).chr }.join
    @pseudo2 = (0...8).map { (65 + rand(26)).chr }.join

    p ''
    p 'Signup1'
    visit('/')
    page.fill_in "pseudo_input", with: @pseudo1
    page.click_on "signup_btn"
    assert_model_state(0, 0, 0)

    p 'Signup2'
    visit('/')
    page.fill_in "pseudo_input", with: @pseudo2
    page.click_on "signup_btn"
    assert_model_state(0, 0, 0)

    p 'Add user1'
    page.fill_in "user_input", with: @pseudo1
    page.click_on "user_btn"
    assert_model_state(1, 0, 0)

    p 'Send a key to user1'
    page.click_on("Add a key")
    assert_model_state(1, 1, 0)

    p 'Send a message to user1'
    page.fill_in "message_input", with: "Some message 1"
    page.click_on("message_btn")
    assert_model_state(1, 1, 1)

    p 'Signin1'
    visit('/')
    page.fill_in "pseudo_input", with: @pseudo1
    page.click_on("signin_btn")
    assert_model_state(1, 1, 1)

    p 'Send a message to user2'
    page.fill_in "message_input", with: "Some message 2"
    page.click_on("message_btn")
    assert_model_state(1, 1, 2)

    p 'Signin2'
    visit('/')
    page.fill_in "pseudo_input", with: @pseudo2
    page.click_on("signin_btn")
    assert_model_state(1, 1, 2)
  end
end

#HomeTest.new.login
