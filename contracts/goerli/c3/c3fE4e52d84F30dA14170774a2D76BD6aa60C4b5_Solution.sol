/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;


contract Solution{

     uint256 public totalTicketNumber;
     uint256 public totalEligbleForThisDraw;


     struct Ranges{
         uint256 start;
         uint256 end;
     }

     mapping(address => Ranges) public userRanges;

        //End Range  => user Mapping
     mapping(uint256 => address) public rangesToUser;

    //     //start Range  => user Mapping
    //  mapping(uint256 => address) public rangesToUser;

     address[] public users;

     Ranges[] public emptyRanges;

     

    function set(address[] memory _users ) external{
            for(uint i=0;i<_users.length;i++){
                users.push(_users[i]);
            }
    }

    function fetch(address _userName,uint256 index) public view returns(uint256){
         return index*20;
    }

    function testSettingUser() public {
        address[] memory usersList=users;

        for(uint256 i=0;i<1000;i++){
            uint256 startPoint=totalTicketNumber++;
            uint256 totalTwab=fetch(usersList[i],i);
            userRanges[usersList[i]]=Ranges({
                start:startPoint,
                end:startPoint+totalTwab
            });
            rangesToUser[startPoint+totalTwab]=usersList[i];
        }
    }

    
}