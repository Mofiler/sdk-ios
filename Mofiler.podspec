
Pod::Spec.new do |s|
          #1.
          s.name               = "Mofiler"
          #2.
          s.version            = "1.1.7"
          #3.  
          s.summary         = "Mofiler: Data Monetization framework"
          #4.
          s.homepage        = "http://mofiler.io"
          #5.
          s.license              = "MIT"
          #6.
          s.author               = "bryan@mofiler.com"
          s.social_media_url   = "http://twitter.com/mofiler"
          #7.
          s.platform            = :ios, "10.0"
          #8.
          s.source              = { :git => "https://github.com/Mofiler/sdk-ios.git", :tag => "1.1.7" }
          #9.
          s.source_files     = "Mofiler", "Mofiler/**/*.{h,m,swift}"
    end



