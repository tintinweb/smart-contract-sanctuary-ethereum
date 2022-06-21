/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TipJarz {

    uint GoldenRation = 1618; // just the first 3 digits of the golden ratio

    event Tipped(address, uint);
    event Taken(address, uint);

    modifier greedCheck(uint256 _amount) {
        uint256 contract_balance = address(this).balance;
        uint256 gr = (contract_balance * GoldenRation) / 1000;
        uint256 a = gr - contract_balance;
        uint256 b = contract_balance - a;
        require(_amount < b, "why so greedy ?!");
        _;
    }
    
    receive() external payable {
        emit Tipped(msg.sender, msg.value);
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMaxBorrowAmount() public view returns (uint256) {
        uint contract_balance = address(this).balance;
        uint gr = (contract_balance * GoldenRation) / 1000;
        uint a = gr - contract_balance;
        uint b = contract_balance - a;
        return b;
    }

    function takeOut(uint256 _amount) public payable greedCheck(_amount) {
        (bool os, ) = payable(msg.sender).call{value: _amount}("");
        require(os, "");
        emit Taken(msg.sender, _amount);
    }
}