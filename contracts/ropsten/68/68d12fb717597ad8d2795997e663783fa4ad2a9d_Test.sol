/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test {

  
   
    uint256 public testNo = 1;
    address public Owner;
     constructor (address _owner) {
         Owner = _owner;
     }

    function Errortest() public pure {
        revert("This_is_Error");
    }
    
    function changeNumber(uint256 newNo) public {
   require(msg.sender == Owner, "You are Not Owner");
   testNo = newNo;

    }
    

}