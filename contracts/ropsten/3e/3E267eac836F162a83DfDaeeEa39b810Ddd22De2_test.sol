/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

pragma solidity ^0.8.14;

contract test {
    struct RewardsInfo { 
        uint rType;
        uint rTime;
        uint256 rValue;
    }

    uint LEVELV1 = 1;
    uint LEVELV2 = 2;
    uint LEVELV3 = 3;
    uint LEVELV4 = 4;
    uint INVITERTYPE = 5;
    uint DYNAMICTYPE = 6;
  
    mapping(address => RewardsInfo[]) private rewardsInfoList;

    function add() public {
        //RewardsInfo memory rec = RewardsInfo(LEVELV1, block.timestamp, 1e18);
        rewardsInfoList[msg.sender].push(RewardsInfo(LEVELV1, block.timestamp, 1e18));
    }

    function get(address account) public view returns (RewardsInfo[] memory) {
        return rewardsInfoList[account];
    }
}