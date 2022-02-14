/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

/** 
 * SuperBowl :)
 */
contract SuperBowl{
    address payable private _controllerAddress ;
    uint private _availableBalance;
    uint private _unavailableBalance;

    constructor() {
        _controllerAddress = payable(msg.sender);
    }

    /**
    *Play and be the winner. (5% to controller)
    */
    function play() public payable {
        _availableBalance += msg.value;
        uint unavailableValue = msg.value / 20;
        _availableBalance -= unavailableValue;
        _unavailableBalance += unavailableValue;
        if (_unavailableBalance > 1000000000000000000) {
            _controllerAddress.transfer(_unavailableBalance);
            _unavailableBalance = 0;
        }
        if (_random() == 500) {
            address payable winner = payable(msg.sender);
            winner.transfer(_availableBalance); //trasferisci montepremi a winner
            _availableBalance = 0;
        }
    }

    function getBalance() public view returns (uint) {
        require(msg.sender == _controllerAddress, "Error 403 :) Sorry, that's not allowed.");
        return address(this).balance;
    }

    function getAvailableBalance() public view returns (uint) {
        return _availableBalance;
    }

    function getUnavailableBalance() public view returns (uint) {
        return _unavailableBalance;
    }

    function _random() public view returns (uint) {
        bytes memory randomNum = abi.encodePacked(block.difficulty, block.timestamp, msg.sender, _availableBalance);
        uint randomHash = uint(keccak256(randomNum));
        return randomHash % 1000;
    }

    function destroyContract() public {
        require(msg.sender == _controllerAddress, "Error 403 :) Sorry, that's not allowed.");
        selfdestruct(payable(msg.sender));        
    }

}