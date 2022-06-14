/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract SendEth {

    event Log(string message);

    function viatransfer(address payable _to) external payable {
        _to.transfer(111);
    }

    function viasend(address payable _to) external payable {
        bool success = _to.send(111);
        require(success);
    }

    function viacall(address payable _to) external payable {
        (bool success, ) = _to.call{value: 111, gas: 100}("");
        require(success);
    }

    function getBalance() external view returns (uint){
        return address(this).balance;
    }

    fallback() external payable{
        emit Log("fallback be called");
    }
}