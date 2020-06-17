# Ruby On Rails: Setting Cucumber Cookies

Setting cookie manually does not work in cucumber because it is running on a headless browser.
Set the cookie from the capybara session instead to set the cookie to the right value

```
Given /^I have a "([^\"]+)" cookie set to "([^\"]+)"$/ do |key, value|
  headers = {}
  Rack::Utils.set_cookie_header!(headers, key, value)
  cookie_string = headers['Set-Cookie']

  Capybara.current_session.driver.browser.set_cookie(cookie_string)
end
```
