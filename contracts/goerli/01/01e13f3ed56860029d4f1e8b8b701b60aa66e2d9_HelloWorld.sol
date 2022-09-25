/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    string private text;
    address[] public owners;

    constructor() {
        text = "Hello World";
        owners = [msg.sender];
    }

    function checkIfExists(address[] storage tab, address someAddress) internal view returns (bool, int) {
        for (uint i = 0; i < tab.length; i++) {
            if (tab[i] == someAddress) {
            return (true, int(i));
            }
        }
        return (false, int(-1));
    }

    function removeElementFromOwnersArray(uint index) internal {
        require(index < owners.length, "index out of bound");
        for (uint i = index; i < owners.length - 1; i++) {
            owners[i] = owners[i+1];
            owners.pop();
        }
    }

    function helloWorld() public view returns (string memory) {
        return text;
    }

    function setText(string calldata newText) public onlyOwners {
        text = newText;
    }

    function addOwner(address newOwner) public onlyOwners {
        bool exists;
        (exists, ) = checkIfExists(owners, newOwner);
        require(!exists, "This address is already a owner");
        owners.push(newOwner);
    }

    function revokeOwner(address oldOwner) public onlyOwners {
        bool exists;
        int index;
        (exists, index) = checkIfExists(owners, oldOwner);
        require(exists, "Caller is not part of the owners");
        removeElementFromOwnersArray(uint(index));
    }

    modifier onlyOwners()
    {
        bool exists;
        (exists, ) = checkIfExists(owners, msg.sender);
        require(exists, "Caller is not part of the owners");
        _;
    }
}