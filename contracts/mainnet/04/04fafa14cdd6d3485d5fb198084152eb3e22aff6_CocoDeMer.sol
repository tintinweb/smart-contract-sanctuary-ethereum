// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20FixedSupply.sol";

contract CocoDeMer is ERC20FixedSupply {
    constructor() ERC20FixedSupply(
        "Coco de Mer",
        "SYC",
        10000000000 *10 ** 18,
        msg.sender 
    ) {}
}