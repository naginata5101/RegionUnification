function[img, label] = img_unify(img_file)
  if ~ischar(img_file); img_file=sprintf('data/%d.jpg', img_file); end;
  img = imread(img_file);

  img_size = [30 40];
  if size(img,1) > size(img,2); img_size = fliplr(img_size); end;
  img = imresize(img, img_size);

  [img, label] = region_unification_parfor(img, 7.5);
end
