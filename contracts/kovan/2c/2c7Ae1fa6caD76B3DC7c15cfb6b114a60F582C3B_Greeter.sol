//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;
contract Greeter {
   
    address private treasuryAddress;
    address private teamAddress;

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
}