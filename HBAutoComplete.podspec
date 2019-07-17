Pod::Spec.new do |s|
 	s.name					      = 'HBAutoComplete'
 	s.version          		= '0.0.1'
 	s.summary          		= 'iOS Autocomplete framework'
 	s.swift_version    		= '4.2'
 	s.platform				    = :ios, '9.0'
 	s.homepage         		= 'https://www.padam-mobility.com/'
 	s.license          		= {
	  							          :type => 'Private',
								            :file => 'LICENSE'
							          }
 	s.author           		= { 'Hugo Bosc-Ducros' 	=> 'hugo@padam.io' }
  s.source           	  = {
	  							          :git 	=> 'https://github.com/HugoBoscDucros/HBAutocomplete.git',
								            :tag 	=> s.version.to_s,
							          }
  s.source_files 			  = 'HBAutoComplete/*.{h,m,swift,strings}'
	# s.exclude_files			  = 'HBADutoComplete/*'
	# s.resource_bundle 		= { 'HBAutoComplete' => ['**/*.lproj/*.strings'] }
 	s.description      		= 'We make public transport more efficient and shared mobility more relevant thanks to an AI powered Microtransit SaaS.'
end
