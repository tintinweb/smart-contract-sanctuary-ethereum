// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";

contract Jannahcoin is ERC20, Ownable {
    constructor() ERC20("Jannahcoin", "JNC"){}
    

    function initialAmount() public onlyOwner{
        _mint(msg.sender, 3000000000*10**18);
    }

    function issueTokens(uint256 amount) public onlyOwner{
        _mint(msg.sender, amount *10**18);
    }

    function burnTokens(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount *10**18);
    }

}