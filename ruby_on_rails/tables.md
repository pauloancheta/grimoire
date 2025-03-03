# Tables

Very annoying to create tables all the time so I've created a table partial that works with any resource

`app/views/shared/_table.html.erb`
```erb
<% actions = local_assigns[:actions] %>
<% show = local_assigns[:show] %>

<table>
  <thead>
    <% headers.each do |header| %>
      <th><%= header.to_s.split(/\.|_/).map(&:capitalize).join(" ") %></th>
    <% end %>

    <% if actions %>
      <th></th>
    <% end %>
  </thead>
  <tbody>
    <% resources.each do |resource| %>
      <tr>
        <% headers.each do |header| %>
          <td>
            <% value = header.to_s.split(".").inject(resource) { |memo, method| memo.send(method.to_sym) } %>
            <% if header == show[:header] %>
              <%= link_to value, show[:path] %>
            <% else %>
              <%= value.is_a?(Time) ? value.strftime("%b %d, %Y %H:%M") : value %>
            <% end %>
          </td>
        <% end %>

        <% if actions %>
          <td>
            <div class="flex gap-1">
              <% actions.each do |label, options| %>
                <% if options[:method] == :delete %>
                  <%= button_to(options.fetch("label", label.to_s.capitalize),
                                options.fetch(:path).call(resource),
                                method: :delete,
                                class: options.fetch("class", "btn btn-default")) %>
                <% else %>
                  <%= link_to(options.fetch("label", label.to_s.capitalize),
                              options.fetch(:path).call(resource),
                              class: options.fetch("class", "btn btn-default")) %>
                <% end %>
              <% end %>
            </div>
          </td>
        <% end %>
      </tr>
    <% end %>
  </tbody>
</table>
```

## Usage
```erb
  <%= render partial: "shared/table",
    locals: {
      resources: @current_appointments,
      headers: [:"service.name", :"employee.full_name", :start_time, :end_time],
      actions: {
        edit: { path: ->(resource) { edit_appointment_path(resource) } },
        destroy: { path: ->(resource) { appointment_path(resource) }, method: :delete }
      },
      show: { header: :"service.name", path: nil }
    }
  %>
```

