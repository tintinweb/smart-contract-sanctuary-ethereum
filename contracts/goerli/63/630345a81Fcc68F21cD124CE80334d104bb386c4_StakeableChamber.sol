// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract StakeableChamber {

    constructor() {
        stakeholders.push();
    }
   
    struct Stake{
        address user;
        uint256 amount;
        uint256 since;
        uint256 claimable;
    }
    
    struct Stakeholder{
        address user;
        Stake[] address_stakes;        
    }

    struct LeaderBoard{
        address user;
        uint256 amount;
        uint256 claim;   
        uint256 total;     
    }

    struct StakingSummary{
        uint256 total_amount;
        uint256 total_claim;
        Stake[] stakes;
    }

    Stakeholder[] internal stakeholders;
          
    mapping(address => uint256) internal stakes;
    
    event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

    uint256 internal rewardPerDay = 100;

    function _addStakeholder(address staker) internal returns (uint256){
        
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex; 
        
    }

    function _stake(uint256 _amount) internal{
        
        require(_amount > 0, "Cannot stake nothing");
        uint256 index = stakes[msg.sender];
        uint256 timestamp = block.timestamp;
        if(index == 0){
            index = _addStakeholder(msg.sender);
        }
        stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp, 0));
        emit Staked(msg.sender, _amount, index,timestamp);

    }

    function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256){

        return (((block.timestamp - _current_stake.since) / 1 days) * _current_stake.amount) / rewardPerDay;

    }

    function hasStake(address _staker) public view returns(StakingSummary memory){
        
        uint256 totalStakeAmount; 
        uint256 totalStakeClaim; 
        StakingSummary memory summary = StakingSummary(0, 0, stakeholders[stakes[_staker]].address_stakes);
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].claimable = availableReward;
            totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
            totalStakeClaim = totalStakeClaim+summary.stakes[s].claimable;
        }
        summary.total_amount = totalStakeAmount;
        summary.total_claim = totalStakeClaim;
        return summary;

    }

    function getStakers() public view returns(address[] memory){
        address[] memory buffer = new address[](stakeholders.length-1);
        for(uint256 i = 1; i < stakeholders.length; i+=1){
            buffer[i-1] = stakeholders[i].user;
        }
        return buffer;
    }   

    function getLeaderBoard() public view returns (LeaderBoard[] memory){

        StakingSummary memory buffer;
        LeaderBoard[] memory LeaderBoards = new LeaderBoard[](stakeholders.length-1);
        for(uint256 s = 1; s < stakeholders.length; s+= 1){
            LeaderBoards[s-1].user = stakeholders[s].user;
            buffer = hasStake(stakeholders[s].user);
            LeaderBoards[s-1].amount = buffer.total_amount;
            LeaderBoards[s-1].claim = buffer.total_claim;
            LeaderBoards[s-1].total = buffer.total_claim + buffer.total_amount;
        }
        
        return LeaderBoards;
    }        

    // function quickSort(LeaderBoard[] memory LeaderBoards, int left, int right) internal {
    //     int i = left;
    //     int j = right;
    //     if(i==j) return ;
    //     LeaderBoard memory changeBuffer;
    //     uint pivot = LeaderBoards[uint(left + (right - left) / 2)].total;
    //     while (i <= j) {
    //         while (LeaderBoards[uint(i)].total < pivot) i++;
    //         while (pivot < LeaderBoards[uint(j)].total) j--;
    //         if (i <= j) {
    //             changeBuffer = LeaderBoards[uint(i)];
    //             LeaderBoards[uint(i)] = LeaderBoards[uint(j)];
    //             LeaderBoards[uint(j)] = LeaderBoards[uint(i)];
    //             i++;
    //             j--;
    //         }
    //     }
    //     if (left < j)
    //         quickSort(LeaderBoards, left, j);
    //     if (i < right)
    //         quickSort(LeaderBoards, i, right);
        
    // }
    
}