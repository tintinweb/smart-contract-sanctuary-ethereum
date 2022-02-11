// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../ERC20.sol";

contract Verdad is ERC20{
    address public admin;
    constructor() ERC20("TRUTH", "VERDAD"){
        _mint(msg.sender, 1000000000000000*10**18);
        admin = msg.sender;
    }
    function mint(address to, uint amount) external{
        require(msg.sender == admin, "Only admin");
        _mint(to, amount);
    }
    function burn(uint amount) external{
        require(msg.sender == admin, "Only admin");
        _burn(msg.sender, amount);
    }
}