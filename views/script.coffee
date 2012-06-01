CHECK_SIZE_MULTIPLIER = 1.2
DAYS_PER_WEEK = 7


# Create a style node to contain the dynamic check mark size.
style_node = document.createElement "style"
document.head.appendChild(style_node);


# Cache the NodeList, since it never changes.
months = document.getElementsByClassName "month"


# Update the style of each month, to make the days square and it's overall
# height occupy at least one screen. This is an optional enhancement.
updateMonthSize = ->
  for month in months

    num_weeks = month.getAttribute("data-weeks")
    day_width = (month.offsetWidth / DAYS_PER_WEEK)
    month.style.height = (day_width * num_weeks) + "px"

    header = month.previousElementSibling
    spacing = window.innerHeight - (month.offsetHeight + header.offsetHeight)
    month.style.marginBottom = if (spacing > 0) then spacing else 0


# Update the size of the check marks to (roughly) fill the day.
updateCheckSize = ->
  font_size = (months[0].offsetWidth / DAYS_PER_WEEK) * CHECK_SIZE_MULTIPLIER
  css_rule = "span.check { font-size: " + font_size + "px; }"
  style_node.innerHTML = css_rule


# Scroll the last (i.e. most recent) month into view.
jumpToLastMonth = ->
  last_index = months.length - 1
  header = months[last_index].previousElementSibling
  location.hash = header.id


resizeHandler =->
  updateMonthSize()
  updateCheckSize()


try
  resizeHandler()
  jumpToLastMonth() unless location.hash
  window.addEventListener "resize", resizeHandler, false

catch error
