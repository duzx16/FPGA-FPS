
# coding: utf-8

# In[5]:


from PIL import Image
import struct


# In[6]:


im = Image.open('/Users/ligen/Desktop/WechatIMG1654.pic')
pix = im.load()
width = im.size[0]
height = im.size[1]

im2 = Image.open('/Users/ligen/Desktop/WechatIMG1651.jpeg')
pix2 = im2.load()

im3 = Image.open('/Users/ligen/Desktop/WechatIMG1652.jpeg')
pix3 = im3.load()

im4 = Image.open('/Users/ligen/Desktop/gun2.bmp')
pix4 = im4.load()

enemy = Image.open('/Users/ligen/Desktop/WechatIMG1655.jpeg')
pix5 = enemy.load()

enemy_fire = Image.open('/Users/ligen/Desktop/图层 1.png')
pix6 = enemy_fire.load()

start = Image.open('/Users/ligen/Desktop/p.bmp')
pix7 = start.load()

win = Image.open('/Users/ligen/Desktop/win.bmp')
pix8 = win.load()

fail = Image.open('/Users/ligen/Desktop/lose.bmp')
pix9 = fail.load()


# In[7]:


def getbin(val, length):
    s = bin(val)[2:]
    return '0' * (length - len(s)) + s


# In[8]:


with open("/Users/ligen/Desktop/pic2bin_final.bin","wb") as f:
    for y in range(height):
        for x in range(0, width, 2):
            r1 = pix[x, y][0] // 32
            g1 = pix[x, y][1] // 32
            b1 = pix[x, y][2] // 32

            r2 = pix[x + 1, y][0] // 32
            g2 = pix[x + 1, y][1] // 32
            b2 = pix[x + 1, y][2] // 32

            s1 = getbin(r1, 3) + getbin(g1, 3) + getbin(b1, 3) + "0000000" # getbin(t1, 1) + "000000"
            s2 = getbin(r2, 3) + getbin(g2, 3) + getbin(b2, 3) + "0000000" # getbin(t2, 1) + "000000"
            s = s1 + s2
            f.write(struct.pack('B', int(s[24:], 2)))
            f.write(struct.pack('B', int(s[16:24], 2)))
            f.write(struct.pack('B', int(s[8:16], 2)))
            f.write(struct.pack('B', int(s[:8], 2)))
    for y in range(im2.size[1]):
        for x in range(0, im2.size[0], 2):
            r1 = pix2[x, y][0] // 32
            g1 = pix2[x, y][1] // 32
            b1 = pix2[x, y][2] // 32

            r2 = pix2[x + 1, y][0] // 32
            g2 = pix2[x + 1, y][1] // 32
            b2 = pix2[x + 1, y][2] // 32

            s1 = getbin(r1, 3) + getbin(g1, 3) + getbin(b1, 3) + "0000000" # getbin(t1, 1) + "000000"
            s2 = getbin(r2, 3) + getbin(g2, 3) + getbin(b2, 3) + "0000000" # getbin(t2, 1) + "000000"
            s = s1 + s2
            f.write(struct.pack('B', int(s[24:], 2)))
            f.write(struct.pack('B', int(s[16:24], 2)))
            f.write(struct.pack('B', int(s[8:16], 2)))
            f.write(struct.pack('B', int(s[:8], 2)))
            
    for y in range(im3.size[1]):
        for x in range(0, im3.size[0], 2):
            r1 = pix3[x, y][0] // 32
            g1 = pix3[x, y][1] // 32
            b1 = pix3[x, y][2] // 32

            r2 = pix3[x + 1, y][0] // 32
            g2 = pix3[x + 1, y][1] // 32
            b2 = pix3[x + 1, y][2] // 32

            s1 = getbin(r1, 3) + getbin(g1, 3) + getbin(b1, 3) + "0000000" # getbin(t1, 1) + "000000"
            s2 = getbin(r2, 3) + getbin(g2, 3) + getbin(b2, 3) + "0000000" # getbin(t2, 1) + "000000"
            s = s1 + s2
            f.write(struct.pack('B', int(s[24:], 2)))
            f.write(struct.pack('B', int(s[16:24], 2)))
            f.write(struct.pack('B', int(s[8:16], 2)))
            f.write(struct.pack('B', int(s[:8], 2)))
    
    for y in range(im4.size[1]):
        for x in range(0, im4.size[0], 2):
            r1 = pix4[x, y][0] // 32
            g1 = pix4[x, y][1] // 32
            b1 = pix4[x, y][2] // 32

            r2 = pix4[x + 1, y][0] // 32
            g2 = pix4[x + 1, y][1] // 32
            b2 = pix4[x + 1, y][2] // 32

            s1 = getbin(r1, 3) + getbin(g1, 3) + getbin(b1, 3) + "0000000" # getbin(t1, 1) + "000000"
            s2 = getbin(r2, 3) + getbin(g2, 3) + getbin(b2, 3) + "0000000" # getbin(t2, 1) + "000000"
            s = s1 + s2
            f.write(struct.pack('B', int(s[24:], 2)))
            f.write(struct.pack('B', int(s[16:24], 2)))
            f.write(struct.pack('B', int(s[8:16], 2)))
            f.write(struct.pack('B', int(s[:8], 2)))
            
    for y in range(enemy.size[1]):
        for x in range(0, enemy.size[0], 2):
            r1 = pix5[x, y][0] // 32
            g1 = pix5[x, y][1] // 32
            b1 = pix5[x, y][2] // 32

            r2 = pix5[x + 1, y][0] // 32
            g2 = pix5[x + 1, y][1] // 32
            b2 = pix5[x + 1, y][2] // 32

            s1 = getbin(r1, 3) + getbin(g1, 3) + getbin(b1, 3) + "0000000" # getbin(t1, 1) + "000000"
            s2 = getbin(r2, 3) + getbin(g2, 3) + getbin(b2, 3) + "0000000" # getbin(t2, 1) + "000000"
            s = s1 + s2
            f.write(struct.pack('B', int(s[24:], 2)))
            f.write(struct.pack('B', int(s[16:24], 2)))
            f.write(struct.pack('B', int(s[8:16], 2)))
            f.write(struct.pack('B', int(s[:8], 2)))
            
    for y in range(enemy_fire.size[1]):
        for x in range(0, enemy_fire.size[0], 2):
            r1 = pix6[x, y][0] // 32
            g1 = pix6[x, y][1] // 32
            b1 = pix6[x, y][2] // 32

            r2 = pix6[x + 1, y][0] // 32
            g2 = pix6[x + 1, y][1] // 32
            b2 = pix6[x + 1, y][2] // 32

            s1 = getbin(r1, 3) + getbin(g1, 3) + getbin(b1, 3) + "0000000" # getbin(t1, 1) + "000000"
            s2 = getbin(r2, 3) + getbin(g2, 3) + getbin(b2, 3) + "0000000" # getbin(t2, 1) + "000000"
            s = s1 + s2
            f.write(struct.pack('B', int(s[24:], 2)))
            f.write(struct.pack('B', int(s[16:24], 2)))
            f.write(struct.pack('B', int(s[8:16], 2)))
            f.write(struct.pack('B', int(s[:8], 2)))
    
    for y in range(16):
        for x in range(0, 16, 2):
            s1 = "111000000" + "0000000" # getbin(t1, 1) + "000000"
            s2 = "111000000" + "0000000" # getbin(t2, 1) + "000000"
            s = s1 + s2
            f.write(struct.pack('B', int(s[24:], 2)))
            f.write(struct.pack('B', int(s[16:24], 2)))
            f.write(struct.pack('B', int(s[8:16], 2)))
            f.write(struct.pack('B', int(s[:8], 2)))
    
    for y in range(start.size[1]):
        for x in range(0, start.size[0], 2):
            r1 = pix7[x, y][0] // 32
            g1 = pix7[x, y][1] // 32
            b1 = pix7[x, y][2] // 32

            r2 = pix7[x + 1, y][0] // 32
            g2 = pix7[x + 1, y][1] // 32
            b2 = pix7[x + 1, y][2] // 32

            s1 = getbin(r1, 3) + getbin(g1, 3) + getbin(b1, 3) + "0000000" # getbin(t1, 1) + "000000"
            s2 = getbin(r2, 3) + getbin(g2, 3) + getbin(b2, 3) + "0000000" # getbin(t2, 1) + "000000"
            s = s1 + s2
            f.write(struct.pack('B', int(s[24:], 2)))
            f.write(struct.pack('B', int(s[16:24], 2)))
            f.write(struct.pack('B', int(s[8:16], 2)))
            f.write(struct.pack('B', int(s[:8], 2)))
    
    for y in range(win.size[1]):
        for x in range(0, win.size[0], 2):
            r1 = pix8[x, y][0] // 32
            g1 = pix8[x, y][1] // 32
            b1 = pix8[x, y][2] // 32

            r2 = pix8[x + 1, y][0] // 32
            g2 = pix8[x + 1, y][1] // 32
            b2 = pix8[x + 1, y][2] // 32

            s1 = getbin(r1, 3) + getbin(g1, 3) + getbin(b1, 3) + "0000000" # getbin(t1, 1) + "000000"
            s2 = getbin(r2, 3) + getbin(g2, 3) + getbin(b2, 3) + "0000000" # getbin(t2, 1) + "000000"
            s = s1 + s2
            f.write(struct.pack('B', int(s[24:], 2)))
            f.write(struct.pack('B', int(s[16:24], 2)))
            f.write(struct.pack('B', int(s[8:16], 2)))
            f.write(struct.pack('B', int(s[:8], 2)))
    
    for y in range(fail.size[1]):
        for x in range(0, fail.size[0], 2):
            r1 = pix9[x, y][0] // 32
            g1 = pix9[x, y][1] // 32
            b1 = pix9[x, y][2] // 32

            r2 = pix9[x + 1, y][0] // 32
            g2 = pix9[x + 1, y][1] // 32
            b2 = pix9[x + 1, y][2] // 32

            s1 = getbin(r1, 3) + getbin(g1, 3) + getbin(b1, 3) + "0000000" # getbin(t1, 1) + "000000"
            s2 = getbin(r2, 3) + getbin(g2, 3) + getbin(b2, 3) + "0000000" # getbin(t2, 1) + "000000"
            s = s1 + s2
            f.write(struct.pack('B', int(s[24:], 2)))
            f.write(struct.pack('B', int(s[16:24], 2)))
            f.write(struct.pack('B', int(s[8:16], 2)))
            f.write(struct.pack('B', int(s[:8], 2)))
            
    
f.close()


# In[7]:


l = Image.open('/Users/ligen/Desktop/吃鸡/未命名文件夹/menotshooting.png')
p = l.resize((160, 160), Image.ANTIALIAS)
p.save('me.bmp')

