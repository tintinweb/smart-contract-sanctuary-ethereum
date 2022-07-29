// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Crud {
    uint256 private age;
    string public name = "";
    address creator;

    function createForm(
        uint256 _age,
        string memory _name,
        address
    ) public {
        age = _age;
        name = _name;
        creator = msg.sender;
    }

    function deleteForm() public {
        delete age;
        delete name;
    }

    function getForm()
        public
        view
        returns (
            uint256,
            string memory,
            address
        )
    {
        return (age, name, creator);
    }
}