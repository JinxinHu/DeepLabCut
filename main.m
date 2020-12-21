%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                               code_starter.m
%                             READ BEFORE CODING
% 
% 
%     - DO NOT MODIFY ANY PART OF THE GIVEN CODE !
% 
%     In this part of the practical, you will code an algorithm that will
%     detect 'episodes'. To simplify, we will define an episode as whenever a
%     mouse does a full 360� turn.
%     If you finish early, we'll also have a look at the total distance
%     moved.
% 
%     If you're interested in how the given code works, do not hesitate to
%     have a peek. However, do not lose too much time doing so: the important
%     part is what YOU will code!
% 
%     N.B: We're giving you a code structure in the interest of time. It is
%     only one of many ways of doing the given task. You may have other,
%     just as good ideas to do it: in that case, and if you feel confident in
%     your Matlab skills, go ahead and try to write your own code. Have fun !
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
close all
clc

%% Clearing the workspace, choosing threshold - DO NOT MODIFY THIS SECTION
%Clearing 
clearvars
clf

%Threshold for DLC's likelihood. (For each point, DLC gives a likelihood of
%being correct: we won't consider points with confidence < 90%).
thresh=0.9;

%% Getting filename from user input - DO NOT MODIFY THIS SECTION
% This will open an explorer window asking the user to select the data.
% This makes it easier to switch between experiments.


% import filename = "a" and output type = numeric matrix
[fname, pname]=uigetfile('*.csv');

%Create fully-formed filename as a string
filename = fullfile(pname, fname);
id = find(fname == '.', 1, 'last');

%% Loading the file as 'a', an array - DO NOT MODIFY THIS SECTION

A = readtable(filename,'HeaderLines',4);

a = table2array(A);

%% Cleaning the data - DO NOT MODIFY THIS SECTION
%   This part deletes data that is obviously wrong ( (x,y) coordinates
%   outside of the arena) and data under our likelihood threshold (0.9), 
%   and replaces them with an average of the next points, 
%           e.g. x[n] = x[n-1]+x[n+1])/2

for i=1:size(a,1)
    
    if a(i,2)<120 || a(i,2)>550 || a(i,3)>400
        a(i,2:3)=NaN;
    end
    if a(i,5)>550
        a(i,5:6)=NaN;
    end
        
    if (a(i,4)<thresh) %change for new likelihood collum for nose

		a(i,2:3)=NaN; % index for new collums of coordinate for nose
    end	
	
	if (a(i,7)<thresh) %change for likelhood of neck
		a(i,5:6)=NaN; % change for index for neck coordinates
	end
end

 for i=1:size(a,2)
        a(:,i) = FillNaNgaps(a(:,i));%replace NaN with average close numbers
 end
 
b = a(:,[2,3,5,6]); %add other coordinate collums 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   N.B: At the end of these steps, use b as your data. b is a n by 4 matrix,
%   with n the number of frames for the experiment. The columns are the nose
%   and neck (x,y) coordinates.
%
%   e.g:
%
%           x_nose      y_nose      x_neck      y_neck
%   Frame 1 267.75      335.13      270.26      345.14   
%   Frame 2 267.11      333.41      270.67      344.14
%   ...     ...         ...         ...         ...
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Compute mouse's head (neck to nose line) angle.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Hint: Use atand to compute the angles (type "help atand" in the command
%         window if needed).
%   We want the angle between the head and a reference line (e.g.
%   horizontal line).
%   At the end of this step, you want your angles to be between 0 and 360
%   degrees (use degrees for homogeneity).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   IMPORTANT : name your angles vector "angles" !
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

angles=1:size(b,1);
angles=angles';
T=angles;
for i=1:size(angles)
   T(i)=(b(i,2)-b(i,4))/(b(i,1)-b(i,3));
end


for i=1:size(angles)
   if b(i,1)-b(i,3)>0 && b(i,2)-b(i,4)>=0
       angles(i)= abs(atand(T(i)));
   end
   if b(i,1)-b(i,3)<=0 && b(i,2)-b(i,4)>0
       angles(i)=180-abs(atand(T(i)));
   end
   if b(i,1)-b(i,3)<=0 && b(i,2)-b(i,4)<0
       angles(i)=180+abs(atand(T(i)));
   end
   if b(i,1)-b(i,3)>=0 && b(i,2)-b(i,4)<0
       angles(i)=360-abs(atand(T(i)));
   end
end


% Is your angles vector named "angles" ?

%% Downsampling to smoothe out the curve. - DO NOT MODIFY THIS SECTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   We downsample to 2000 frames total. This step might not seem important
%   for now, but it significantly reduces jitter in the data, which will 
%   help us quite a lot later on.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
j=1;
for i=2:length(angles)
temp=angles(j);

 if (min(abs(angles(i)-temp),360-abs(angles(i)-temp))>100)
     %Error Routine
     angles(i)=NaN;
 else
     j=i;
 end
end
angles = FillNaNgaps(angles);
     

ds_ratio = floor(length(angles)/2000);
angles = downsample(angles,ds_ratio);


%% Calculating the difference in angles between each consecutive frame - DO NOT MODIFY THIS SECTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   We are computing a_d, the difference in consecutive angles. e.g if:
%   angles(i) = 4� and angles(i+1) = 18�, a_d(i) = 18-4 = 14�.
%   This difference in angle is what we'll use later to figure out rotations
%   of the mouse.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


a_d = zeros(length(angles),1);

for i=1:length(angles)-1
    a_d(i,1)=angles(i+1,1)-angles(i,1);
end


%% Correcting outliers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Uncomment the following lines (select lines, then CTRL+T).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

a_d1= a_d;
for i=1:length(angles)-1
    if a_d1(i,1) > 180
        a_d1(i,1) = a_d1(i,1) - 360;
    end
    if a_d1(i,1) < -180
        a_d1(i,1) = 360 + a_d1(i,1);
    end
end
ad=a_d1;
figure(1)
hist(a_d1,180);
xlabel("Difference in angles between consecutive frames, in degrees")
ylabel("Difference in angles between consecutive frames, in degrees")
% title("Distribution of the Difference in angles between consecutive frames")

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Take a look at the histogram. What do you think of the angle
%   differences that are close to +- 360� ? (Remember: between two frames,
%   about half a second passes so that's almost a full turn in 0.5s).
%
%   Why do you think these angle differences appear? Keep in mind our
%   angles are contained between 0 and 360�. What happens when calculating
%   an angle difference between angles on both sides of the 0<->360�
%   border?
%
%   Now, figure out a way to bring these angle differences back to their
%   real value.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Count positive rotations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   For this part, try to figure out a way to obtain two arrays:
%           - start_frame_pos
%           - end_frame_pos
%   These arrays contain the begining and end frames of the positive 360�
%   turns.
%   e.g, if you get 3 positive turns at frames 300->305, 2430->2435 and
%   7898->7903, you should have:
%   start_frame_pos = [300, 2430, 7898]
%   end_frame_pos   = [305, 2435, 7903]
%
%
%       Recommended code structure :
%   - Use sum_ang as a running sum of angle differences.
%
%       IMPORTANT: angle differences are stored in a_d, not angles!
%
%   - If you reach +360� in sum_ang, add the start and end frames
%   of the running sum to start_frame_pos and end_frame_pos, and substract
%   360� from sum_ang.
%   - If at one point, you encounter an angle difference that is inferior
%   to 0, start counting from 0 again.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sum_ang=0;
k=0; %counter for number of frames in this rotation
start_frame_pos = [];
end_frame_pos = [];

for i=1:length(a_d1)
    if a_d1(i)>0
        sum_ang=sum_ang+a_d1(i);
        k=k+1;
        
            if sum_ang > 360
                sum_ang = sum_ang-360;
                disp(sum_ang)
                start_frame_pos = [start_frame_pos, i-k+1];
                end_frame_pos = [end_frame_pos, i];
                k=0;
            end
            
    else
        k=0;
        sum_ang=0;
    end
end

pos_count=length(start_frame_pos);
start_frame_pos=start_frame_pos';
end_frame_pos=end_frame_pos';
%% Count negative rotations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   cf. previous section: do the same, but with negative angle differences.
%   This time, we want to obtain:
%           - start_frame_neg
%           - end_frame_neg
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sum_ang=0;
k=0; %counter nb frames in this rotation
start_frame_neg = [];
end_frame_neg = [];

for i=1:length(a_d1)
    if a_d1(i)<0
        sum_ang=sum_ang+a_d1(i);
        k=k+1;
        
        if sum_ang<-360
            disp(sum_ang)
            sum_ang = sum_ang+360;
            start_frame_neg = [start_frame_neg, i-k+1];
            end_frame_neg = [end_frame_neg, i];
            k=0;
        end
    
    else
        sum_ang=0;
        k=0;
    end
end

neg_count=length(start_frame_neg);
start_frame_neg=start_frame_neg.';
end_frame_neg=end_frame_neg.';

%% Plotting results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Now that we've got our start and end frames for positive and negative
%   rotations, we'd like to show those on graphs.
%   Which graphs do you think would illustrate best what we want to point
%   out in the data? Think about it, and once you've got some ideas, ask a
%   tp-person for confirmation.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(2)
plot(angles,'Color','k');
cmap=colormap(autumn);
for alpha=1:pos_count
    hold on
    plot(start_frame_pos(alpha):end_frame_pos(alpha),angles(start_frame_pos(alpha):end_frame_pos(alpha)),'Color',cmap(floor((length(cmap)/pos_count)*alpha),:))
end

cmap = colormap(winter);
for alpha=1:neg_count
    hold on
    plot(start_frame_neg(alpha):end_frame_neg(alpha),angles(start_frame_neg(alpha):end_frame_neg(alpha)),'Color',cmap(floor((length(cmap)/neg_count)*alpha),:))
end
xlabel("Frame Number(time)")
ylabel("Angles(degree)")

figure(3)
lw=1;
plot(cumsum(a_d1),'Color','k','LineWidth',lw);
cmap=colormap(autumn);
for alpha=1:pos_count
    hold on;
    plot(start_frame_pos(alpha):end_frame_pos(alpha),sum(a_d1(1:start_frame_pos(alpha)-1))+cumsum(a_d1(start_frame_pos(alpha):end_frame_pos(alpha))),'Color',cmap(floor((length(cmap)/pos_count)*alpha),:),'LineWidth',lw)
end
cmap= colormap(winter);
for alpha=1:neg_count
    hold on;
    plot(start_frame_neg(alpha):end_frame_neg(alpha),sum(a_d1(1:start_frame_neg(alpha)-1))+cumsum(a_d1(start_frame_neg(alpha):end_frame_neg(alpha))),'Color',cmap(floor((length(cmap)/neg_count)*alpha),:),'LineWidth',lw)
end
xlabel("Frame Number(time)")
ylabel("Degrees Turned Accumulated(degree)")

figure(4)
plot(b(:,3),b(:,4),'Color','k')
cmap=colormap(autumn);
for alpha=1:pos_count
    hold on;
    plot(b(start_frame_pos(alpha):end_frame_pos(alpha),3),b(start_frame_pos(alpha):end_frame_pos(alpha),4),'Color',cmap(floor((length(cmap)/pos_count)*alpha),:))
end
cmap= colormap(winter);
for alpha=1:neg_count
    hold on;
    plot(b(start_frame_neg(alpha):end_frame_neg(alpha),3),b(start_frame_neg(alpha):end_frame_neg(alpha),4),'Color',cmap(floor((length(cmap)/neg_count)*alpha),:))
end
xlabel("Position X")
ylabel("Position Y")

figure(5)
binned_turn = zeros(length(a_d1),1);
for i=1:neg_count
    binned_turn(start_frame_neg(i):end_frame_neg(i))=-1;
end
for i=1:pos_count
    binned_turn(start_frame_pos(i):end_frame_pos(i))=+1;
end
plot(binned_turn)


%% The end?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% nega=0;
% posi=0;
% 
% for i=1:length(angles)-1
%     if a_d(i,1)>=0 && a_d(i,1)<180
%         posi=posi+1;
%     end
%     if a_d(i,1)<=0 && a_d(i,1)>-180
%         nega=nega+1;
%     end
%     if a_d(i,1)>=180
%         nega=nega+1;
%     end
%     if a_d(i,1)<=-180
%         posi=posi+1;
%     end
% end
% 
% nega
% posi
% p_nega=nega/(nega+posi);
% p_posi=posi/(nega+posi);
% figure(6)
% pie(p_posi)
% figure();
% subplot(1,2,1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%