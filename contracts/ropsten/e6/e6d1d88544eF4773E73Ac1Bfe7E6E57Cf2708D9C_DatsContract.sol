/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

contract DatsContract{

    struct DDos {
        uint256 id;
        address user;
        bool isApprove;
        uint8 trafficScale;
    }

    address public owner;

    mapping(address => DDos) public ddoses;
    address[] public ddosLength;

    event DDosSaved(uint256 _id, address indexed _consumer);

    constructor(){
        owner = msg.sender;
    }

    function getAllUserDDosSettings() public view returns(DDos[] memory){
        require(owner == msg.sender, "You are not authorized.");
        DDos[] memory allDDoses = new DDos[](ddosLength.length);

        for(uint i = 0; i < ddosLength.length; i++){
            allDDoses[i] = ddoses[ddosLength[i]];
        }

        return allDDoses;
    }

    function saveDDos(bool _isApprove, uint8 _trafficScale) external {

        DDos memory ddos = DDos({
            id: ddosLength.length + 1,
            user: msg.sender,
            isApprove: _isApprove,
            trafficScale: _trafficScale
        });

        if(ddoses[msg.sender].id == 0)
            ddosLength.push(msg.sender);

        ddoses[msg.sender] = ddos;  

        emit DDosSaved(ddosLength.length + 1, msg.sender);
        
    }

    function getDDos() external view returns (DDos memory) {
        return ddoses[msg.sender];
    }

    function getDDosByUser(address _user) external view returns (DDos memory){
        return ddoses[_user];
    }

    function getDDosCount() external view returns(uint256) {
        return ddosLength.length;
    }

}