/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract learn{
    address payable[] _addrs;
    uint256[] _percents;
    uint _length;
    address payable _master;

    constructor() payable{
        _master = payable(0x554b9302eb50332519A2134361A3eae51aFE6e30);
        
    }

    receive() external payable{}

    function updateAllocation(address payable[] memory addrs, uint256[] memory percents) public {
        require(addrs.length == percents.length, "the addrs size must equal to percents' size");
        _length = addrs.length;
        for(uint i = 0; i < _length; ++i){
            _addrs.push(addrs[i]);
            _percents.push(percents[i]);
        }
    }

    function checkBalance() public view returns(uint256){
        return address(this).balance / 1e18;
    }


    function Allocate() public payable {
        require(address(this).balance > 1e17, "the contract doesn't have any balance");
        _master.transfer(1e16);
        uint256 _balance = address(this).balance;

        for(uint i = 0; i < _length; ++i){
            _addrs[i].transfer(_balance * _percents[i] / 100);
        }
    }
}