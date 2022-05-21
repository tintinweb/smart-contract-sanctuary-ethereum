// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./abstract/ContractMetadata.sol";

contract sContract is ContractMetadata {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor() ContractMetadata("nameTest", "sTest") {

    }

    function mint() public payable returns(address) {
        return msg.sender;
    }

    function m(address  toAddr) external payable returns(uint256) {
        emit Transfer(toAddr, contractAddr(), 1);

        return toAddr.balance;
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