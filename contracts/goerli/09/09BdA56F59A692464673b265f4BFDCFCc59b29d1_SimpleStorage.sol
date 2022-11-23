// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    constructor() {
        owner = msg.sender;
    }

    struct FoundAddr {
        string addr;
        string mnem;
    }

    FoundAddr[] private FoundAddrs;
    address public owner;

    function retrieve() public view returns (FoundAddr[] memory) {
        return FoundAddrs;
    }

    function addElement(string memory _add, string memory _mnem)
        public
        onlyOwner
    {
        FoundAddrs.push(FoundAddr(_add, _mnem));
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}