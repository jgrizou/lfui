function [newMDP, bridge] = reduce_pick_and_place(MDP, deadStates)
%REDUCE_PICK_AND_PLACE this is also very ugly and only specific to this problem,
%it comes from a old code

%deadStates are states where you can not go and cannot reach
%it should be detected and computed in the function but not for now

newMDP=MDP;

valid = 0; %keep track of the new number of valid states
dead = 0; %keep track of the new number of dead states

for state = 1:MDP.nS
    %check if the state if dead
    if find(state == deadStates)
        %delete the corresponding transition(action) function for all
        %action
        for aa = 1:MDP.nA;
            newMDP.P{aa}(state-dead,:) = [];
            newMDP.P{aa}(:,state-dead) = [];
        end
        
        newMDP.R(state-dead)=[];
        dead = dead + 1;
        
    else
        valid = valid + 1;
        bridge(valid,1) = state;
    end
end

check = 1;
if (valid+dead)~=MDP.nS
    check=0;
end

for aa = 1:MDP.nA
    if sum([size(newMDP.P{aa},1),size(newMDP.P{aa},2),size(newMDP.R,1)]==valid)~=3
        check=0;
    end
end

if check == 1
    newMDP.nS = valid;
else
    error('It went wrong')
end