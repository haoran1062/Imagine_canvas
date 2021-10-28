import os, cv2, numpy as np

if __name__ == '__main__':
    
    img = np.zeros((320, 320, 3), dtype=np.uint8)
    # img[:, :, :] = 255
    cv2.imwrite('assets/canvas.jpg', img)

    img = np.zeros((32, 32, 3), dtype=np.uint8)
    # img[:, :, :] = 255
    cv2.imwrite('assets/origin.jpg', img)