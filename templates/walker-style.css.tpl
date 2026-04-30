#window {
  background: alpha(#${base}, 0.92);
  border-radius: 12px;
  border: 1px solid alpha(#${surface1}, 0.6);
}

#box {
  background: transparent;
}

#search {
  background: transparent;
}

#input {
  background: #${surface0};
  color: #${text};
  border-radius: 8px;
  padding: 8px 12px;
  border: 1px solid #${surface1};
  font-family: "JetBrainsMono Nerd Font";
  font-size: 14px;
  caret-color: #${blue};
}

#input:focus {
  border-color: #${blue};
}

#input placeholder {
  color: #${overlay0};
}

#list {
  background: transparent;
}

#item {
  color: #${text};
  border-radius: 8px;
  transition: all 200ms ease;
}

#item:selected {
  background: alpha(#${blue}, 0.08);
  color: #${text};
}

#item:hover {
  background: alpha(#${surface1}, 0.4);
}

#text {
  font-family: "JetBrainsMono Nerd Font";
  font-size: 14px;
}

#sub {
  color: #${overlay0};
  font-size: 12px;
}

#activationlabel {
  color: #${surface1};
}

#spinner {
  color: #${blue};
}
