// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "./SungToken.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract SungSale is Pausable, Ownable {
    string public name = "Sungsale";
    SungToken public sung;
    uint256 public rate = 250;
    address private _owner;
    bool private _paused;

    event Buy(
        address account,
        address sung,
        uint256 amount,
        uint256 rate
    );

    constructor(SungToken _sung) {
        sung = _sung;
        _owner = msg.sender;
        _paused = false;
    }


    function buy() public payable {
        uint256 sungAmount = msg.value * rate;
        require(sung.balanceOf(address(this)) >= sungAmount);
        sung.transfer(msg.sender, sungAmount);  
        emit Buy(msg.sender, address(sung), sungAmount, rate);    
    }

    function withdraw(address payable _to) public onlyOwner {
        require(_owner == msg.sender, "You cannot call this function.");
        _to.transfer(address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}