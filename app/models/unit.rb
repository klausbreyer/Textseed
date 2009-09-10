class Unit < ActiveRecord::Base
  belongs_to :project
  belongs_to :user


  validates_length_of       :content,    :maximum => 10000
  serialize :echoe



  def render 
    text = ""
    if echoe
     


      #settings for replacements
      wholeline = {
        "h1." => ["<br /><span class=\"h1\">", "</span>"],
        "h2." => ["<br /><span class=\"h2\">", "</span>"],
        "h3." => ["<br /><span class=\"h3\">", "</span>"],
        "h4." => ["<br /><span class=\"h4\">", "</span>"],
        "h5." => ["<br /><span class=\"h5\">", "</span>"],
        "h6." => ["<br /><span class=\"h6\">", "</span>"],
        "p." => ["<p>", "</p>"],

        "bq." => ["<blockquote>", "</blockquote>"],
        "pre." => ["<pre>", "</pre>"],
        "*" => ["&nbsp;&bull;&nbsp;", ""],
        "**" => ["&nbsp; &nbsp;&bull;&nbsp;", ""]
      }
      inline = {
        "**" => ["<b>", "</b>"],
        "*" => ["<strong>", "</strong"],
        "_" => ["<em>", "</em>"],
        "__" => ["<i>", "</i>"],
        "??" => ["<cite>", "</cite>"],
        "\"" => ["“", "”"],
        "'" => ["‘", "’"]
      }
      after_replacements = {
        "-" => "–",
        "--" => "—",
        "(r)" => "®",
        "(c)" => "©",
        "(tm)" => "™"
      }

      #possibilities for links missing.

     
      # replacements die davor gemacht werden #########################################

      wholeline_entity = ""
      wholeline_content  = ""
      inline_key = ""
      inline_i = ""
      is_inlist = false #flag ob der parser im aktuellen block gerade eine ul abhandelt
      is_instar = false #flag ob der parser in der aktuellen zeile gerade eine li abhandelt
      max = echoe.length
      i = 0

      while echoe && i <= max

        if wholeline_entity != "" && echoe[i]
          wholeline_content += echoe[i][0]
        end
        #markup whats defined for one whole line
        wholeline.each do |key, value|
          if echoe[i] && echoe[i][0] == key && (i==0 || echoe[i-1][0] == "[br]")
            ##check thats the start of the line or start of the text
            echoe[i][0] = value[0]
            echoe[i][2] = 9
            wholeline_entity = value[1]
          end
        end if wholeline_entity == ""
        #clear at the end of the line or end of the document
        if i == max || (echoe[i][0] == "[br]" && wholeline_entity != "")
          echoe.insert(i, [wholeline_entity, 0, 9])   #really 9 ?
          max += 1 if i != max #or for ever loop
          wholeline_entity = ""
          #for the directory
        end

        #markup for lists here
        #makrup for unordered lists
        if wholeline_entity == ""  #wenn gerade keine normale entity abgearbeitet wird wie ne überschrift.
          if echoe[i][0] == "*" && (i==0 || echoe[i-1][0] == "[br]" || echoe[i-1][0] == "</li>"|| echoe[i-1][2] == -1 )  #anfang der zeile oder nach gelöschtem wort (todo: nicht so optimal)
            echoe[i][0] = "<li>"
            echoe[i][2] = 9
            if !is_inlist
              echoe.insert(i, ["<ul>", 0, 9])   #really 9 ?
              max += 1
            end
            is_inlist = true
            is_instar = true
          end
          if (i == max || echoe[i][0] == "[br]") && is_inlist && is_instar  #ende der zeile
            echoe[i] = ["</li>", 0, 9]   #really 9 ? ersetzen und nicht einfügen weil sonst ein br am ende zu viel da ist.
            is_instar = false
            if echoe[i+1] && echoe[i+1][0] == "*"
              is_inlist = true
            else
              is_inlist = false
            end
            if !is_inlist
              echoe.insert(i, ["</ul>", 0, 9])   #really 9 ?
              max += 1 if i != max #or for ever loop
            end
          end
        end
        #check the sentence-markup
        if wholeline_entity == ""
          inline.each do |key, value|
            if (echoe[i][0][0,1] == key || echoe[i][0][0,2] == key) && echoe[i][0].length > 1
              inline_i = i
              inline_key = key
            end
            #is ready if the end is in the same word!
            if (echoe[i][0][-1,1] == key || echoe[i][0][-2,2] == key) && inline_key == key && i != max
              #cut the signs
              if echoe[i][0][-1,1] == key
                echoe[inline_i][0] = echoe[inline_i][0][1..-1]
                echoe[i][0] = echoe[i][0][0..-2]

              end
              #insert the markup
              echoe.insert(i+1, [value[1], 0, 9])   #really 9 ?
              echoe.insert(inline_i, [value[0], 0, 9])   #really 9 ?
              inline_i = 0
              inline_key = ""
              max+= 2
            end
          end
        end
        i+=1
      end




      # rendering ####################################################
      temptext = ""
      i  = 0
      while echoe && i < echoe.length
        if echoe[i][1] == "x"
          echoe[i][1] = 1
        end

        if echoe[i][0] == "[br]"
          text += "<br />\n"

        elsif echoe[i][2] == 9
          text += echoe[i][0]
        elsif echoe[i][2] == -1
          temptext += h echoe[i][0] + " "
          if !echoe[i+1] || echoe[i][1] != echoe[i+1][1] || echoe[i][2] != echoe[i+1][2] || echoe[i+1][0] == "[br]"
            if temptext.length > 1
              temptext = temptext[0,(temptext.length-1)]
            end
            #text += "&nbsp;"
            text += "<span style=\"background:#eee; border: 2px solid #{Unit.id_to_color(echoe[i][1], project.id)};\" title=\"" + temptext + "\" onmouseover=\"this.innerHTML=this.title; this.title='Deleted Text'\" onmouseout=\"this.title=this.innerHTML; this.innerHTML='&nbsp;'\">&nbsp;</span>&nbsp;"
            temptext = ""
          end
        elsif echoe[i][2] == 1
          temptext += h echoe[i][0] + " "
          if !echoe[i+1] || echoe[i][1] != echoe[i+1][1] || echoe[i][2] != echoe[i+1][2] || echoe[i+1][0] == "[br]"
            if temptext.length > 1
              temptext = temptext[0,(temptext.length-1)]
            end
            # text += "<span style=\"background: #{id_to_color(echoe[i][1], @project.id)};border: 2px solid #{id_to_color(echoe[i][1], @project.id)};\"><img src=\"/images/icons/add.png\"  title=\"added\" alt=\"added\" /> " + temptext + "</span>&nbsp;"
            text += "<span style=\"background: #{Unit.id_to_color(echoe[i][1], project.id)};border: 2px solid black;\">" + temptext + "</span>&nbsp;"
            temptext = ""
          end
        else
          temptext += h echoe[i][0] + " "
          if !echoe[i+1] || echoe[i][1] != echoe[i+1][1] || echoe[i][2] != echoe[i+1][2] || echoe[i+1][0] == "[br]"
            if temptext.length > 1
              temptext = temptext[0,(temptext.length-1)]
            end
            text += "<span style=\"background: #{Unit.id_to_color(echoe[i][1], project.id)};\">" + temptext + "</span>&nbsp;"
            temptext = ""

          end
        end
        i+= 1
      end



      # nachbearbeitung #######################################################
      after_replacements.each do |key, value|
        text = text.gsub(key, value)
      end
 

    end
    text
  end


  def self.id_to_color i, project_id
    @userremember = [] unless @userremember
    return '#ffffff' if i == 0
    return @userremember[i] if @userremember[i]
    r = g= b = 55


    srand i*project_id+i+project_id*i*project_id+i+project_id+i*project_id+i+project_id*i*project_id+i+project_id*i*project_id+i+project_id+i*project_id+i+project_id

    #endlosschleife
    while leuchtkraft(r,g,b) < 180.0 #|| leuchtkraft(r,g,b) > 230
      r = rand 255
      g = rand 255
      b = rand 255
    end


    erg = convback(r,g,b)

    @userremember[i] = erg
    #puts "#{i.to_s}: " + leuchtkraft(r,g,b).to_s + " erg: #{erg}"
    erg
  end
  private
  def self.leuchtkraft r, g, b #http://home.arcor.de/ulile/node52.html
    0.3*r+0.59*g+0.11*b
  end
  def self.convback r,g,b
    ergs = [r.to_i.to_s(16), g.to_i.to_s(16), b.to_i.to_s(16)]
    i=0
    while i < ergs.length
      ergs[i] = "0" + ergs[i] if ergs[i].length == 1
      i+=1
    end
    "#" + ergs[0] + ergs[1] + ergs[2]
  end
end
