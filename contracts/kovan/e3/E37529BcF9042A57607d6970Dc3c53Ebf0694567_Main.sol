pragma solidity ^0.8.0;

import {Child} from "./Child.sol";

contract Main {
    constructor() {}

    struct ChildContractLookup {
        address _address;
        string _name;
    }

    ChildContractLookup[] public childContractLookup;

    function addNewChildContract(string memory _name) public {
        Child _newChildContract = new Child(_name);

        childContractLookup.push(
            ChildContractLookup(address(_newChildContract), _name)
        );
    }
}

pragma solidity ^0.8.0;

contract Child {
    string public name;

    constructor(string memory _name) {
        name = _name;
    }
}