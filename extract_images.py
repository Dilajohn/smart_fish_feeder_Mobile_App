from pathlib import Path
import zipfile
from PIL import Image
import io

pptx_path = Path(r'C:/Users/USER/Downloads/Smart_Fish_Feeder_Proposal_Group21.pptx')
out_dir = Path('assets/readme_images')
out_dir.mkdir(parents=True, exist_ok=True)

with zipfile.ZipFile(pptx_path) as z:
    names = [n for n in z.namelist() if n.startswith('ppt/media/image')]
    print(f'images {len(names)}')
    for i, name in enumerate(names, 1):
        data = z.read(name)
        img = Image.open(io.BytesIO(data)).convert('RGB')
        output = out_dir / f'image_{i}.jpg'
        img.save(output, 'JPEG', quality=95)
        print(output)
