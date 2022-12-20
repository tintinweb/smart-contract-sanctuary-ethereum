// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ERC20.sol";

contract GT is ERC20{

    uint public lastMint;

    constructor() {
        name = "Game Token";
        symbol = "GT";
        decimals = 18;
        lastMint = block.timestamp;
    }

    function mint() external returns(bool) {
        uint amount = bounty();
        lastMint = block.timestamp;
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        emit Transfer(address(0), msg.sender, amount);
        return true;
    }

    function bounty() public view returns(uint){
        return (1*1e18 + totalSupply/1e9) * (block.timestamp - lastMint);
    }
}