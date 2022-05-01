// SPDX-License-Identifier: MIT
//pragma solidity >=0.4.22 <0.9.0;
pragma solidity ^0.8.13;

import "./ERC20.sol";


contract HappyToken is ERC20 {

    constructor(uint256 _supply) ERC20("HappyToken","HAPPY")
    {
        _mint(msg.sender, _supply * (10**decimals()));
        
    }


}