%% create_si_position_controller 
% Returns a controller ($u: \mathbf{R}^{2 \times N} \times \mathbf{R}^{2 \times N} \to \mathbf{R}^{2 \times N}$) 
% for a single-integrator system with biased rendzvous algorithm
% Created by Wenhao Luo (whluo12@gmail.com)

%% Detailed Description 
% * XVelocityGain - affects the horizontal velocity of the
% single integrator
% * YVelocityGain - affects the vertical velocity of the single integrator
%% Example Usage 
%   si_position_controller = create_si_rendzvous_controller('XVelocityGain',
%   1, 'YVelocityGain', 1);
%% Implementation
function [si_position_controller] = create_si_circle_controller(varargin)
    
    parser = inputParser;
    addOptional(parser, 'XVelocityGain', 1);
    addOptional(parser, 'YVelocityGain', 1);
    addOptional(parser, 'VelocityMagnitudeLimit', 0.08); % 0.08
    
    parse(parser, varargin{:});
    
    x_vel_gain = parser.Results.XVelocityGain;
    y_vel_gain = parser.Results.YVelocityGain;
    velocity_magnitude_limit = parser.Results.VelocityMagnitudeLimit;
    gains = diag([x_vel_gain ; y_vel_gain]);
    
    si_position_controller = @position_si;
    

    function [ dx ] = position_si(lap_matrix, states, targets)
    %POSITIONINT Position controller via single integrator dynamics
        % targets: 2 x N (specify the target position to follow)
        % poses:  
        % for circle formation
        
        
    
        % Error checking
    
        [M, N] = size(states);
        [M_poses, N_poses] = size(states); 
        
        poses = zeros(M, N);
        k_gain = 1;
        
        radius_circle = 0.05;
        theta_vec = 1/N*2*pi*[1:N];
        
        x_poses = radius_circle*cos(theta_vec);
        y_poses = radius_circle*sin(theta_vec);
        poses = [x_poses;y_poses];
        
        assert(M == 2, 'Row size of states (%i) must be 2', M); 
        assert(M_poses==2, 'Row size of SI poses (%i) must be 2', M_poses);
        assert(N==N_poses, 'Column size of states (%i) must be the same as poses (%i)', N, N_poses);
        
        dx = zeros(2, N);
        mean_states = mean(states,2)*ones(1,N);
        dx_trans = -k_gain*lap_matrix./diag(lap_matrix)*(states'-poses')+(targets'-mean_states'); % circle formation control and target following
        
%         dx_trans = -lap_matrix*states'-(states'-poses'); % biased rendzevous, prefer to rendzevous than target
%         dx_trans = -lap_matrix./diag(lap_matrix)*states'-(states'-poses'); % biased rendzevous, works best
        
%         dx_trans = -lap_matrix./diag(lap_matrix)*states'+(poses'-1/N*(states*ones(N,1)*ones(1,N))');

%         dx_trans = -lap_matrix*(states'-poses'); % for formation control
        
        dx = gains*dx_trans';
        
%         for i = 1:N   
%            dx(:, i) = gains*(poses(:, i) - states(:, i));
%         end   
        
        % Normalize velocities to magnitude
        norms = arrayfun(@(idx) norm(dx(:, idx)), 1:N);
        to_normalize = norms > velocity_magnitude_limit;
        if(~isempty(norms(to_normalize)))                        
            dx(:, to_normalize) = velocity_magnitude_limit*dx(:, to_normalize)./norms(to_normalize);
        end
    end
end

