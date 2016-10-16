
function[img,label] = region_unification2(image, min_distance, islog, label)
  function[] = save_log()
    imwrite(label_show, sprintf('log/label_%04d.png',count));
    imwrite(img_show,   sprintf('log/img_%04d.png',count));
    print(gcf, '-dpng', sprintf('log/log_%04d.png',count));
  end

  function[] = show_img(islog)
    [~,~,gz] = meshgrid([1:IMG_W], [1:IMG_H], [1:3]);

    label_row = arrayfun(@(x,c) clrmp(x,c), repmat(label,1,1,3), gz);
    img_row = uint8(img);

    if islog
      label_show = arrayfun(@(x,y,z) label_row(ceil(y/LOG_S), ceil(x/LOG_S), z), ...
        gx_log, gy_log, gz_log);
      img_show = arrayfun(@(x,y,z) img_row(ceil(y/LOG_S), ceil(x/LOG_S), z), ...
        gx_log, gy_log, gz_log);
    else
      label_show = label_row;
      img_show = img_row;
    end
  end


  DIFF_X = [0 1 0 -1]; DIFF_Y = [-1 0 1 0];
  IMG_W = size(image,2); IMG_H = size(image,1); IMG_D = size(image,3);
  LOG_S = 15;
  if nargin < 3; islog = false; end;
  if nargin < 4; label = reshape([1:IMG_H*IMG_W], IMG_W, IMG_H)'; end;
  if islog; mkdir('log/'); end;

  img = double(image);
  isportrait = IMG_W < IMG_H;
  clrmp = flipud(parula(IMG_W * IMG_H));

  PAR_N = 4;
  PAR_W = IMG_W /PAR_N;
  if isportrait; PAR_W = IMG_H /PAR_N; end;

  [GX,GY] = meshgrid([1:IMG_W], [1:IMG_H]);
  if isportrait
    gx=reshape(GX, PAR_W, IMG_W, PAR_N);
    gy=reshape(GY, PAR_W, IMG_W, PAR_N);
    dist_val_par = zeros(PAR_W, IMG_W, PAR_N);
  else
    gx=reshape(GX, IMG_H, PAR_W, PAR_N);
    gy=reshape(GY, IMG_H, PAR_W, PAR_N);
    dist_val_par = zeros(IMG_H, PAR_W, PAR_N);
  end
  dist_ind_par = dist_val_par;
  [gx_log, gy_log, gz_log] = meshgrid([1:IMG_W*LOG_S], [1:IMG_H*LOG_S], [1:IMG_D]);
  global label_show; global img_show;

  count = 1;

  while true
    imgc   = mat2cell(img,  IMG_H,IMG_W,IMG_D);
    labelc = mat2cell(label,IMG_H,IMG_W);
    parfor n = 1:PAR_N
      if isportrait
        [dist_val_par(:,:,n), dist_ind_par(:,:,n)] = ...
          arrayfun(@neighbor_dist, ...
          repmat(imgc,   PAR_W,IMG_W), ...
          repmat(labelc, PAR_W,IMG_W), ...
          gx(:,:,n), gy(:,:,n))
      else
        [dist_val_par(:,:,n), dist_ind_par(:,:,n)] = ...
          arrayfun(@neighbor_dist, ...
          repmat(imgc,   IMG_H,PAR_W), ...
          repmat(labelc, IMG_H,PAR_W), ...
          gx(:,:,n), gy(:,:,n))
%{
        [dist_val, dist_ind] = ...
          arrayfun(@neighbor_dist, ...
          repmat(mat2cell(img  ,IMG_W,PAR_W,IMG_D), IMG_H,PAR_W), ...
          repmat(mat2cell(label,IMG_W,PAR_W),       IMG_H,PAR_W), ...
          gx(:, ((n-1)*PAR_W+1):n*PAR_W), gy(:, ((n-1)*PAR_W+1):n*PAR_W));
%}
      end
    end
    dist_val = reshape(dist_val_par, IMG_H, IMG_W);
    dist_ind = reshape(dist_ind_par, IMG_H, IMG_W);

    [~,min_x] = min(min(dist_val));
    [~,min_y] = min(dist_val(:,min_x));
    min_ind = dist_ind(min_y, min_x);
    last_x = min_x + DIFF_X(min_ind);
    last_y = min_y + DIFF_Y(min_ind);

    disp(sprintf('<%04d> x:%3d, y:%3d, img:%3d, dist:%.3f',...
      count, min_x, min_y, img(min_y,min_x), dist_val(min_y,min_x)))

    if dist_val(min_y,min_x) > min_distance; break; end;

    unifying = label(min_y + DIFF_Y(min_ind), min_x + DIFF_X(min_ind));
    imgr = img(:,:,1); imgg = img(:,:,2); imgb = img(:,:,3);
    imgr (label==unifying) = img(min_y, min_x,1);
    imgg (label==unifying) = img(min_y, min_x,2);
    imgb (label==unifying) = img(min_y, min_x,3);
    img = cat(3,imgr,imgg,imgb);
    label(label==unifying) = label(min_y, min_x);

    if ~rem(count,25)
      show_img(islog);

      if isportrait; subplot(1,2,1); else; subplot(2,1,1); end;
      imshow(label_show);
      if isportrait; subplot(1,2,2); else; subplot(2,1,2); end;
      imshow(img_show);
      drawnow;

      if islog; save_log(); end;
    end
    count = count + 1;
  end

  show_img(islog);
  if islog; save_log(); end;
  img=uint8(img);
end


function[value, index] = neighbor_dist(IMG, LABEL, x, y)
  global img;   img   = cell2mat(IMG);
  global label; label = cell2mat(LABEL);
  DIFF_X = [0 1 0 -1]; DIFF_Y = [-1 0 1 0];

  function[distance] = eval_dist(tx, ty, nx, ny)
    distance = double(intmax('uint8')) +1;
    if nx > 0 & ny > 0 & nx <= size(img,2) & ny <= size(img,1)   & label(ty,tx) ~= label(ny,nx)
      % sprintf('img_h:%4d, img_w:%4d, tx:%4d, ty:%4d, nx:%4d, ny:%4d\n', size(img,2), size(img,1), tx,ty, nx,ny)
      distance = mean(abs(img(ty, tx, :) - img(ny, nx, :)));
    end
  end

  distance = arrayfun(@eval_dist, repmat(x,1,4), repmat(y,1,4), x+DIFF_X, y+DIFF_Y);
  [value, index] = min(distance);
end

%{
for n=[1:22]
[img,label] = region_unification_parfor(imread(sprintf('data/%02d.JPG',n)), 0);
for m=[25 50 75]
tic; [img,label] = region_unification_parfor(imread(sprintf('data/%02d.JPG',n)), m*.1, label); toc;
imwrite(sprintf('result/%02d_%02d.png',n,m));
end
end
%}
