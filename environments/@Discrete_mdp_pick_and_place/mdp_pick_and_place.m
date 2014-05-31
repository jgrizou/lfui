function infoStruct = mdp_pick_and_place()
% this is an ugly one, I put here together many stuff from old work

%      2     3
%       
%   1     r     4


%two object can be stacked on top on one other
%The goal of the robot is to create a particular arangement of object

% the robotb have 4 possible actions : turn clockwise,turn conter-clockwise, grsp, ungrasp

%if in position 3 and the robot conter-clockwise it end up in state 2 ...
%however if the robot is in position 4 it cannot go to postion 1 by one
%clock wise rotation

%if the robot use the grasp action, it either fail if there is not object
%in his current position, or grasp the object on top

%if the robot use the ungrasp action if either fail if it is not currently
%grasping, or release the bloc in the current robot position, on top of the
%previous one, if there is already two stacked object, it fail.

%if the robot move while grasping the object on top of the stack move with
%it

%failing mean remaining in the same state


%1 robot
%m cells 
%l objects
m=4;
l=3;

%nb of states
ns = 2 * m * (2*m+1)^l; 
% 2 + m are the possible state of the robot (m position, with two states grasping or not)
% (2*m+1) are the posible position of the object (m position on two levels) + 1 position when an object is grasped 
%^l because l object

dim = [2 m 2*m+1 2*m+1 2*m+1]; %meaning full representation of the problem

%state spam from 1 to ns but it is easier to represent it in this vector form
% [grasp/nograps robot_position object_position_1 object_position_2 object_position_3]


% 1 for non grasping , 2 for grasping
% robot positon 1 to 4
% object postion 1 to 4 if lower level and 5 to 8 for second level and 9 if
% grasped

%to convert statenb into vect representation :
%[a,b,c,d,e] = ind2sub(dim,statenb)
%reverse :
%ind = sub2ind(dim,a,b,c,d,e)

%actions
na = 4; % move + grasp + ungrasp
% 1 for clockwise
% 2 for conter-clockwise
% 3 for grasping
% 4 for ungrapsing
for aa = 1:na
    T{aa} = sparse(zeros(ns,ns));
end

dead_states = [];

for grasp = 1:dim(1) 
    for robot = 1:dim(2)
        for obj1=1:dim(3)
            for obj2=1:dim(4)
                for obj3=1:dim(5)
                    
                    oldstate = sub2ind(dim,grasp,robot,obj1,obj2,obj3);

                    %check if the state if possible
                    possible = 1;       
                    %objects can not be on the same position
                    if ~(sum([obj1,obj2,obj3]==obj1)==1) || ~(sum([obj1,obj2,obj3]==obj2)==1) || ~(sum([obj1,obj2,obj3]==obj3)==1)
                        possible = 0;    
                    end  
                    %with object position
                    if obj1 > m && obj1 < dim(3) %then the object is on the second level, it should have an object under
                        if ~((obj2==obj1-m) || (obj3==obj1-m))
                            possible = 0;                            
                        end
                    end
                    if obj2 > m && obj2 < dim(4) %then the object is on the second level, it should have an object under
                        if ~((obj1==obj2-m) || (obj3==obj2-m))
                            possible = 0;                            
                        end
                    end
                    if obj3 > m && obj3 < dim(5) %then the object is on the second level, it should have an object under
                        if ~((obj1==obj3-m) || (obj2==obj3-m))
                            possible = 0;                            
                        end
                    end
                    %with grasping option
                    if grasp == dim(1) %then the robot is grasping, an object should be in the grasped state
                       if ~(obj1==dim(3) || obj2==dim(4) || obj3==dim(5))
                           possible = 0;
                       end
                    end
                    
                    %with grasping option
                    if grasp == 1 %then the robot is not grasping, no object should be in the grasped state
                       if obj1==dim(3) || obj2==dim(4) || obj3==dim(5)
                           possible = 0;
                       end
                    end
                    
                    if possible == 1
                    %if state possible : several case are possible
                        for aa = 1:na
                            clear newstate %important
                            % 1 for clockwise
                            if aa == 1
                                if robot == 4 % the robot can not go further
                                    newstate = sub2ind(dim,grasp,robot,obj1,obj2,obj3);
                                else 
                                    newstate = sub2ind(dim,grasp,robot+1,obj1,obj2,obj3);
                                end
                            % 2 for conter-clockwise
                            elseif aa == 2
                                if robot == 1 % the robot can not go further
                                    newstate = sub2ind(dim,grasp,robot,obj1,obj2,obj3);
                                else 
                                    newstate = sub2ind(dim,grasp,robot-1,obj1,obj2,obj3);
                                end                              
                            % 3 for grasping
                            elseif aa == 3
                                level1 = [obj1,obj2,obj3];
                                level2 = [obj1-m,obj2-m,obj3-m];
                                %check if the robot is not yet grasping and
                                %if there is at least one object at its
                                %location
                                if grasp == 1 && sum(level1==robot)==1
                                    if sum(level2==robot)==0 %object is only on the level 1
                                        if level1(1)==robot
                                            newstate = sub2ind(dim,dim(1),robot,dim(3),obj2,obj3);
                                        elseif level1(2)==robot
                                            newstate = sub2ind(dim,dim(1),robot,obj1,dim(4),obj3);
                                        elseif level1(3)==robot
                                            newstate = sub2ind(dim,dim(1),robot,obj1,obj2,dim(5));
                                        end
                                    elseif sum(level2==robot)==1 %object are stacked so one inthe level 2
                                        if level2(1)==robot
                                            newstate = sub2ind(dim,dim(1),robot,dim(3),obj2,obj3);
                                        elseif level2(2)==robot
                                            newstate = sub2ind(dim,dim(1),robot,obj1,dim(4),obj3);
                                        elseif level2(3)==robot
                                            newstate = sub2ind(dim,dim(1),robot,obj1,obj2,dim(5));
                                        end                                        
                                    end
                                elseif grasp == 2 || sum(level1==robot)==0
                                %else stay in the same state
                                    newstate = oldstate;
                                end
                            % 4 for ungrapsing                            
                            elseif aa == 4
                                level1 = [obj1,obj2,obj3];
                                level2 = [obj1-m,obj2-m,obj3-m];
                                %check if the robot is grasping and
                                %if there is at least an empty space at level2
                                if grasp == 2 && sum(level2==robot)==0
                                    if sum(level1==robot)==0 %empty space at level 1
                                        if obj1==dim(3)
                                            newstate = sub2ind(dim,1,robot,robot,obj2,obj3);
                                        elseif obj2==dim(4)
                                            newstate = sub2ind(dim,1,robot,obj1,robot,obj3);
                                        elseif obj3==dim(5)
                                            newstate = sub2ind(dim,1,robot,obj1,obj2,robot);
                                        end
                                    elseif sum(level1==robot)==1 %object should be stacked at the level 2
                                        if obj1==dim(3)
                                            newstate = sub2ind(dim,1,robot,robot+m,obj2,obj3);
                                        elseif obj2==dim(4)
                                            newstate = sub2ind(dim,1,robot,obj1,robot+m,obj3);
                                        elseif obj3==dim(5)
                                            newstate = sub2ind(dim,1,robot,obj1,obj2,robot+m);
                                        end                                        
                                    end
                                elseif grasp == 1 || sum(level2==robot)==1
                                %else already two stacked blocks!
                                    newstate = oldstate;
                                end
                            end
                            
                            T{aa}(oldstate,newstate) = 1;                                 
                        end
                    else
                    %else the state is not possible then for every action it only can
                    %stay in the same state
                        dead_states = [dead_states oldstate];
                        for aa = 1:na
                            T{aa}(oldstate,oldstate) = 1;
                        end
                    end
                    
                end
            end
        end
    end
end

R = zeros(ns,1);
infoStruct = struct('nS', ns, 'nA', na, 'P', {T}, 'R', R, 'sub2indDim', dim, 'deadStates', dead_states);