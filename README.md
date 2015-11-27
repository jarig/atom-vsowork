# VSO Work Item

Package to search for Visual Studio Online Work Items in Atom

![Demo](https://raw.githubusercontent.com/jarig/atom-vsowork/master/demo/vsowork-demo.gif)

# Usage

1. In package settings Set up VSO Collection url<br>
  URL should be something like: https://[username].visualstudio.com/DefaultCollection

2. Set project name, ex: MyProject

3. Set query path, ex: My Queries/Assigned to me

  Default query "Assigned to Me" won't work unfortunately, you will need create one either under My Queries or any other query folder you have.<br>
  NOTE: Query should be of **Flat** type (default).

4. Press cmd-shift-v (or ctrl-shift-v) to open search box

5. Type to filter items by title

6. Select an item and its ID will be copied to the clipboard
