/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;
contract Greeter {
   
    address private treasuryAddress;
    address private teamAddress;
    address private rewardAddress;

    function setTeamAddress(address _teamAddress) external {
        teamAddress = _teamAddress;
    }
    
    function getTeamAddress() external view  returns (address){
        return teamAddress;
    }
   

    function setTreasuryAddress(address _treasuryAddress) external {
        treasuryAddress = _treasuryAddress;
    }

    function getTreasuryAddress() external view  returns (address){
        return treasuryAddress;
    }

    function setRewardAddress(address _rewardAddress) external {
        rewardAddress = _rewardAddress;
    }

    function getRewardAddress() external view  returns (address){
        return rewardAddress;
    }
}