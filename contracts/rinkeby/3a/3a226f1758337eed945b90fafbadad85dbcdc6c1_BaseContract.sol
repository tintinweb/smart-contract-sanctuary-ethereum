/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract BaseContract {

        uint public count;

        function increment(uint256 amount) public {
            count = amount; 
        }

        function getBalance() public view returns(uint){
            return address(this).balance;
        }

        function getCount() public view returns(uint) {
            return count; 
        }


}