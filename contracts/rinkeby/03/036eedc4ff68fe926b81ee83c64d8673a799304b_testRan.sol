/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

//SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

contract testRan {
    // this will be a value that cant be changed
    uint counter;
    uint musicId;
    uint public x;
    uint setMe;
    mapping (address=> uint) ownerMusicId;
    mapping (uint => uint) viewCounts;
    
    function setMusicOwner(address _ownerOfMusic, uint _musicId ) public {
        ownerMusicId[_ownerOfMusic] = _musicId;
    }

    function propertyView(uint _musicId) public returns (uint){
        viewCounts[_musicId]++;
        return viewCounts[_musicId];

    }
    function setMeFunction(uint setNumber) external{
        setMe = setNumber;
    }

    


}