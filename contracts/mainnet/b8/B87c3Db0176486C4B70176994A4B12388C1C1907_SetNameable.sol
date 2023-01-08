// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
struct NameableData {
    string name;
    string symbol;
}
library SetNameable {
    function getName(NameableData storage self) public view returns (string memory) {
        return self.name;
    }
    function getSymbol(NameableData storage self) public view returns (string memory) {
        return self.symbol;
    }    
    function setName(NameableData storage self, string calldata named) public {
        self.name = named;
    }
    function setSymbol(NameableData storage self, string calldata symbol) public {
        self.symbol = symbol;
    }    
    function setNamed(NameableData storage self, string memory named, string memory symbol) public {
        self.name = named;
        self.symbol = symbol;
    }

}