// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Kushin is ERC20 {
    constructor() ERC20("kushin", "KS") {
        _mint(msg.sender, 100 * 10 ** decimals());
    }
    
    string private message;


    function setMessage(string memory mes) public {
        message = mes;
    }
    
    function getMessage() view public returns(string memory) {
        return message;
    }
}