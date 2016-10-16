function[img, label, flag] = snap_unify(cam)
  function[img, label] = unify(~,~)
    if ~flag; return; end;
    flag = false;
  end

  if nargin < 1; cam = webcam('UVC Camera (046d:0805)'); end;

  FPS = 30;
  FRAME_F = 5; FRAME_W = 300; FRAME_H = 400;
  FRAME_L = 250; FRAME_R = FRAME_L + FRAME_W;
  FRAME_U = 100; FRAME_D = FRAME_U + FRAME_H;
  FRAME_C = uint8(cat(3, 0.8*intmax('uint8'), 0, 0));

  figure('WindowButtonDownFcn',@unify);
  flag = true;

  while flag
    img = imresize(snapshot(cam), [600 800]);

    img([FRAME_U:(FRAME_U+FRAME_F-1), (FRAME_D-FRAME_F):FRAME_D-1], ...
     FRAME_L:(FRAME_R-1), :) = ...
      repmat(FRAME_C, (FRAME_F)*2, FRAME_W, 1);
    img(FRAME_U:(FRAME_D-1), ...
     [FRAME_L:(FRAME_L+FRAME_F-1), (FRAME_R-FRAME_F):FRAME_R-1], :) = ...
      repmat(FRAME_C, FRAME_H, (FRAME_F)*2, 1);

    imshow(uint8(img));

    % pause(1/FPS);
  end
  
  close; figure('Position', get(0,'ScreenSize'));
  img = imresize(snapshot(cam), [600 800]);
  img = img(FRAME_U:FRAME_D-1, FRAME_L:FRAME_R-1, :);
  imshow(img); drawnow;
  tic;[img, label] = region_unification(imresize(img, [40 30]), 5, true);toc;
end
