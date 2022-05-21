// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./abstract/ContractMetadata.sol";

contract sContract is ContractMetadata {
    constructor() ContractMetadata("nameTest", "sTest") {

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

abstract contract ContractMetadata {
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function contractAddr() public view returns(address) {
        return address(this);
    }
}