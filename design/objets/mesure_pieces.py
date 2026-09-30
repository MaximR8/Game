# Deux mesures sur le tas : l'écart ENTRE pièces (la luminosité lissée à la taille d'une pièce) et le
# relief DANS les pièces (ce qui reste quand on retire ce lissé) — le « HD ».
import sys
import numpy as np
from PIL import Image, ImageFilter
img = Image.open(sys.argv[1]).convert('RGB')
w, h = img.size
zone = img.crop((int(w * 0.06), int(h * 0.36), int(w * 0.94), int(h * 0.585)))
a = np.asarray(zone).astype(np.float64) / 255.0
l = a @ np.array([0.299, 0.587, 0.114])
lisse = np.asarray(Image.fromarray((l * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(9))).astype(np.float64) / 255.0
piece = (a[..., 0] > 0.18) & (a[..., 0] > a[..., 2] * 1.25)
macro = lisse[piece]
micro = np.abs(l - lisse)[piece]
print("%-28s entre pièces (5-95 %%) %.2f · relief moyen %.3f · relief fort (90 %%) %.3f · médiane %.2f" % (
    sys.argv[1].split('/')[0], np.percentile(macro, 95) - np.percentile(macro, 5), micro.mean(), np.percentile(micro, 90), np.median(l[piece])))
