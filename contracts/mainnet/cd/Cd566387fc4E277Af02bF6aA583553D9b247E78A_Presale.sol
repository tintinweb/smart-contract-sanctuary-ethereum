/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./MactivasICO.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract Presale is Pausable, Ownable {
    string public name = "Presale";
    MactivasICO public mact;
    uint256 public rate = 25000;
    address private _owner;
    bool private _paused;

    event Buy(
        address account,
        address mact,
        uint256 amount,
        uint256 rate
    );

    constructor(MactivasICO _mact) {
        mact = _mact;
        _owner = msg.sender;
        _paused = false;
    }

    function buy() public payable {
        uint256 mactAmount = msg.value * rate;
        require(mact.balanceOf(address(this)) >= mactAmount);
        mact.transfer(msg.sender, mactAmount);  
        emit Buy(msg.sender, address(mact), mactAmount, rate);    
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