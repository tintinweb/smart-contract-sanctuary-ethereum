// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

// Zhou Zhuang Coin (Symbol: ZZB) is a coin which you can burn to employ Sichen Li.
// With 100 ZZB, you can employ Sichen Li for 1 hour
contract ZZB is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Zhou Zhuang Coin", "ZZB") {
        _mint(msg.sender, 10000 * 10**uint(decimals()));
    }

    event sichen(
        uint256 timeInSecond,
        address employee
    );

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
    function withdraw(address payable to, uint amount) public onlyOwner {
        require(address(this).balance >= amount);
        to.transfer(amount);
    }

    function buy() public payable{
        require(msg.value > 0);
        payable(address(this)).transfer(msg.value);
        _mint(msg.sender, msg.value * 1000);
    }

    function employSichen(uint amount) public{
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        emit sichen(amount * 3600 / 10**uint(decimals()), msg.sender);
    }

    receive () external payable {}
}