#!/usr/bin/env python
#encoding:utf-8

import os, re, random
import os.path as p

def crop_shots(image_path, output_dir):
    name = p.basename(image_path).split('.jpg')[0]
    command = 'exiftool -imagesize %s'%(image_path)
    size = [int(x) for x in re.split(r'\s*:\s*', os.popen(command).read())[-1].split('x')]
    for x in range(0, size[0] - 1920, 500):
        for y in range(0, size[1] - 1080, 500):
            dst_image_path = '%s/%s_%d_%d.jpg'%(output_dir, name, x, y)
            if p.exists(dst_image_path):
                continue
            command = 'convert %s -crop 1920x1080+%d+%d %s'%(image_path, x, y, dst_image_path)
            os.system('bash -xc "%s"'%command)
            command = 'convert %s -crop 1440x1080+240+0 -resize 160x120 %s'%(dst_image_path, re.sub(r'\.jpg$', '.thm', dst_image_path))
            os.system('bash -xc "%s"'%command)

def crop_icons(image_path, output_dir):
    name = p.basename(image_path).split('.jpg')[0]

    platte_image_path = '%s/platte.jpg'%(output_dir)
    command = 'convert %s -resize 25%% %s'%(image_path, platte_image_path)
    os.system('bash -xc "%s"'%command)

    command = 'exiftool -imagesize %s'%(platte_image_path)
    size = [int(x) for x in re.split(r'\s*:\s*', os.popen(command).read())[-1].split('x')]
    for x in range(0, size[0] - 160, 50):
        for y in range(0, size[1] - 120, 50):
            thm_path = '%s/%s_%d_%d.thm'%(output_dir, name, x, y)
            if p.exists(thm_path):
                continue
            command = 'convert %s -crop 160x120+%d+%d %s'%(platte_image_path, x, y, thm_path)
            os.system('bash -xc "%s"'%command)
    os.remove(platte_image_path)

def random_image_names(base_dir):
    name_list = []
    for file_name in os.listdir(base_dir):
        if not re.search(r'\.thm$', file_name):
            continue
        file_name = re.sub(r'\.thm$', '', file_name)
        name_list.append(file_name)
    random.shuffle(name_list)
    random.shuffle(name_list)
    for n in range(len(name_list)):
        id = '%03d'%(n)
        command = 'mv -fv %s.thm %s.thm'%(p.join(base_dir, name_list[n]), p.join(base_dir, id))
        os.system(command)
        if p.exists(p.join(base_dir, name_list[n])):
            command = 'mv -fv %s.jpg %s.jpg'%(p.join(base_dir, name_list[n]), p.join(base_dir, id))
            os.system(command)

def main():
    root_dir = '/Library/Server/Web/Data/Sites/cloud.larryhou.com/camera/'
    # for file_name in os.listdir(root_dir):
    #     if not re.search(r'\.jpg$', file_name):
    #         continue
    #     crop_shots(p.join(root_dir, file_name), p.join(root_dir, 'images'))
    # random_image_names(p.join(root_dir, 'images'))
    crop_icons(p.join(root_dir, '1.jpg'), p.join(root_dir, 'videos'))
    random_image_names(p.join(root_dir, 'videos'))
if __name__ == '__main__':
    main()