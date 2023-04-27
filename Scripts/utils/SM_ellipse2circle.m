
function [x, y] = SM_ellipse2circle(x0, y0, ellipse_params)


    x0 = x0 - ellipse_params.X0_in;
    y0 = y0 - ellipse_params.Y0_in;
    
    % ccw phi rotation
    x = x0*cos(ellipse_params.phi) - y0*sin(ellipse_params.phi);
    y = x0*sin(ellipse_params.phi) + y0*cos(ellipse_params.phi);
    
    % shift (0, b) to (0,0)
    y = y - ellipse_params.b;
    
    % pull along -y so that (0,-2b) goes to (0, -2a)
    y = y * (ellipse_params.a/ellipse_params.b);
    
    % scale to a = 50 cm
    x = x/ellipse_params.a*0.5;
    y = y/ellipse_params.a*0.5;

    % vertically shift y by 0.5
    y = y + 0.5;

    
