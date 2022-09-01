// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

// token can mint any time by any one
contract KCP is ERC20 {
    constructor() ERC20("KCP", "KCP") {}

    function mintToken(address to, uint256 _quantity) public {
        _mint(to, _quantity);
    }
}