Pod::Spec.new do |s|
 	s.name					= 'HBAutoComplete'
 	s.version          		= '1.0.4'
 	s.summary          		= 'iOS Autocomplete framework'
 	s.swift_version    		= '5'
 	s.platform				    = :ios, '9.0'
 	s.homepage         		= 'https://github.com/HugoBoscDucros/HBAutocomplete'
 	s.license          		= {
	  							          :type => 'MIT',
								            :file => 'LICENSE'
							          }
 	s.author           		= { 'Hugo Bosc-Ducros' 	=> 'hugo.boscducros@gmail.com' }
  s.source           	  = {
	  							          :git 	=> 'https://github.com/HugoBoscDucros/HBAutocomplete.git',
								            :tag 	=> s.version.to_s,
							          }
  s.source_files 			  = ['Sources/**/*.{h,m,swift,strings}','Supporting files/*.{h,m,swift,strings}']
	# s.exclude_files			  = 'HBADutoComplete/*'
	# s.resource_bundle 		= { 'HBAutoComplete' => ['**/*.lproj/*.strings'] }
 	s.description      		= 'HBAutocomplete is a litle library to help developers making responsive autocompletion in any kind of textField from any king of data source (static, webService...)'
end
