// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;


import "./SungToken.sol";
import "./Ownable.sol";


contract SungSale {
    string public name = "Sungsale";
    SungToken public sung;
    uint256 public rate = 250;
    address private _owner;

    event Buy(
        address account,
        address sung,
        uint256 amount,
        uint256 rate
    );

    constructor(SungToken _sung) {
        sung = _sung;
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function buy() public payable {
        // Calculate the number of tokens to buy
        uint256 sungAmount = msg.value * rate;
        require(sung.balanceOf(address(this)) >= sungAmount);
        sung.transfer(msg.sender, sungAmount);
        
        emit Buy(msg.sender, address(sung), sungAmount, rate);    
    }


    // withdraw eth
    function withdraw(address payable _to) public {
        require(_owner == msg.sender, "You cannot call this function.");
        _to.transfer(address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
    }

}