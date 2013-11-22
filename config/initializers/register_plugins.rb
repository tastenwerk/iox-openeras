# add plugins to iox-cms
Rails.configuration.iox.plugins ||= []


Rails.configuration.iox.plugins << Iox::Plugin.new( name: 'openeras_projects',
                                                    roles: [],
                                                    icon: 'icon-sitemap',
                                                    path: '/openeras/projects' )

Rails.configuration.iox.plugins << Iox::Plugin.new( name: 'venues',
                                                    roles: [],
                                                    icon: 'icon-map-marker',
                                                    path: '/openeras/venues' )