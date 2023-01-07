// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract SimpleUnity {
    string name;
    uint age;
    struct Address {
        string name;
        uint age;
        string designation;
    }
    Address addr;

    function setString(string memory val) public {
        name = val;
    }

    function getString() public view returns (string memory) {
        return name;
    }

    function setInt(uint val) public {
        age = val;
    }

    function getInt() public view returns (uint) {
        return age;
    }

    function setStruct(
        string memory nameval,
        uint ageval,
        string memory designation
    ) public {
        addr = Address(nameval, ageval, designation);
    }

    function getStruct()
        public
        view
        returns (string memory, uint, string memory)
    {
        return (addr.name, addr.age, addr.designation);
    }
}