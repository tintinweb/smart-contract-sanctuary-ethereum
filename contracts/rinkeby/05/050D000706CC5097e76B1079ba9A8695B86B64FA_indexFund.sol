// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract indexFund {
    
    struct IndexInfo {
        string name;
        address[] tokens;
        uint[] percentages;
    }
    IndexInfo public indexinfo;

    function Indexview() public view returns (IndexInfo memory) {
        return indexinfo;
    }

    function ownerview() public view returns (address) {
        return owner;
    }

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function udpateindex(
        string memory _name,
        uint[] memory _percentages,
        address[] memory _tokens
    ) external onlyOwner {
        indexinfo.name = _name;
        indexinfo.tokens = _tokens;
        indexinfo.percentages = _percentages;
    }

    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}