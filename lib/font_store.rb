class FontStore
  @textures = nil
  @call_lists = []

  def self.generate_textures
    if @textures.nil?
      @textures = glGenTextures(256-32)
      texture_data = []
      width = 8
      height = 13

      num = 0
      for i in 0..(height-1)
        for j in 0..(width-1)
          texture_data[i*width*4+j*4+0] = 255;
          texture_data[i*width*4+j*4+1] = 0;
          texture_data[i*width*4+j*4+2] = 0;
          texture_data[i*width*4+j*4+3] = 255;
        end
      end

      texture_data = texture_data.pack("C*")

      @textures.each do |t|
        glBindTexture(GL_TEXTURE_2D, t)
#    glTexParameter(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
#    glTexParameter(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)
#    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL)
#    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE)
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 8, 13, 0, GL_RGBA, GL_UNSIGNED_BYTE, texture_data)

        glBindTexture(GL_TEXTURE_2D, 0)
      end

    end
  end

  def self.generate_font
    self.generate_textures

    glViewport(0, 0, 8, 15)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()

    glOrtho(0, 8, 13, 0, -1.0, 1.0)

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    glTranslate(0, 0, 0)

    glMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, ( [1.0, 1.0, 1.0, 1.0]  ) )
    32.upto(255) do |c|
      glClearColor(0.0, 0.0, 0.0, 1.0)
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

      glRasterPos(0,0)
      begin
        glutBitmapCharacter(GLUT_BITMAP_8_BY_13, c)
      rescue RangeError
        glutBitmapCharacterX(c)
      end

      glBindTexture(GL_TEXTURE_2D, @textures[c-32])
      glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 13, 8, 13, 0)
      glBindTexture(GL_TEXTURE_2D, 0)
    end

    glClearColor(0.0, 0.0, 0.0, 1.0)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    glPopMatrix

  end

  def self.get_texture(c)
    @textures[c-32]
  end

  def self.render_char(c)
    glBindTexture(GL_TEXTURE_2D, FontStore.get_texture(c))
      char_size = 8.0 / ($WINDOW_WIDTH / 2.0)
      glBegin(GL_QUADS)
        glTexCoord2f(0,0)
        glVertex3f(0, 0, 0.0)

        glTexCoord2f(1,0)
        glVertex3f(char_size, 0.0, 0.0)

        glTexCoord2f(1,1)
       glVertex3f(char_size, $LINE_SIZE, 0.0)

        glTexCoord2f(0,1)
        glVertex3f(0, $LINE_SIZE, 0.0)
      glEnd
      glTranslate(char_size, 0, 0)
  end

  def self.render_string(txt)
    glPushMatrix
    glEnable(GL_BLEND)
    glBlendFunc(GL_ONE, GL_ONE)

    unless BlobStore.has(txt)
      list = glGenLists(1)
      glNewList(list, GL_COMPILE)
      txt.each_byte do |c|
        self.render_char(c)
      end
      glEndList()
      BlobStore.put(txt, list)
      glCallList(list)
    else
      glCallList(BlobStore.get(txt))
    end
    glBindTexture(GL_TEXTURE_2D, 0)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glDisable(GL_BLEND)
    glPopMatrix
  end

end
