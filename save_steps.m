function[img, label] = save_steps(img_file, out_num)
  IMG_SHORT = 300; IMG_LONG = 400;

  if ~ischar(img_file); img_file=sprintf('data/%d.jpg', img_file); end;
  if nargin < 2; out_num = 0; end;
  img = imread([img_file]);
  isportrait = size(img,1) > size(img,2);

  % img_size = [300 400];
  img_size = [IMG_SHORT IMG_LONG];
  if isportrait; img_size = fliplr(img_size); end;
  img = imresize(img, img_size);

  color_map = flipud(parula(IMG_LONG * IMG_SHORT));
  gz = cat(3, 1*ones(img_size), 2*ones(img_size), 3*ones(img_size));


  [img, label] = region_unification(img, 0, false);
  mkdir(sprintf('result/save_steps/%d/',out_num));

  for level = [5:5:150]
    [img, label] = region_unification(img, .1*level, false, label);

    if isportrait; subplot(1,2,1); else subplot(2,1,1); end;
    imshow(arrayfun(@(x,c) color_map(x,c), repmat(label,1,1,3), gz));
    if isportrait; subplot(1,2,2); else subplot(2,1,2); end;
    imshow(img);

    print(gcf,'-dpng',sprintf('result/save_steps/%d/%03d.png', out_num, level));
  end

end
