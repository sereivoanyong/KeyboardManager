# KeyboardManager

For this lightweight library to work correctly on any iOS version, there're limitations on the usage:
- Text field/view must be in a scroll view embedded in view controller's root view
- Text view isn't fully supported
- Nested scroll views with `isScrollEnabled` `true` might behave unexpectedly
- Doesn't support orientation change
- The manager is always enabled after first access.
