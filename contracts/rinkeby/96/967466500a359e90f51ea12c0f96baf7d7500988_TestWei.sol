/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.1;

    contract TestWei {

        function setWei() public payable {
        }

        function withdrawETH(address payable _receiver) external {
        _receiver.transfer(address(this).balance);
        }

        function withdrawETHValue(address payable _receiver, uint _value) external {
        _receiver.transfer(_value);
        }

        function getBalance() public view returns(uint){
            return address(this).balance;
        }
    }