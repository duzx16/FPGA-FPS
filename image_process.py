
# coding: utf-8

# In[4]:


from PIL import Image
import struct


# In[5]:


im = Image.open('/Users/ligen/Desktop/b1.bmp')
pix = im.load()
width = im.size[0]
height = im.size[1]


# In[6]:


def getbin(val, length):
    s = bin(val)[2:]
    return '0' * (length - len(s)) + s


# In[8]:


with open("/Users/ligen/Desktop/background.bin","wb") as f:
    for y in range(height):
        for x in range(0, width, 2):
            r1 = pix[x, y][0] // 32
            g1 = pix[x, y][1] // 32
            b1 = pix[x, y][2] // 32
            #t1 = pix[x, y][3] // 255
            r2 = pix[x + 1, y][0] // 32
            g2 = pix[x + 1, y][1] // 32
            b2 = pix[x + 1, y][2] // 32
            #t2 = pix[x + 1, y][3] // 255
            s1 = getbin(r1, 3) + getbin(g1, 3) + getbin(b1, 3) + "0000000" # getbin(t1, 1) + "000000"
            s2 = getbin(r2, 3) + getbin(g2, 3) + getbin(b2, 3) + "0000000" # getbin(t2, 1) + "000000"
            s = s1 + s2
            f.write(struct.pack('B', int(s[24:], 2)))
            f.write(struct.pack('B', int(s[16:24], 2)))
            f.write(struct.pack('B', int(s[8:16], 2)))
            f.write(struct.pack('B', int(s[:8], 2)))
f.close()

