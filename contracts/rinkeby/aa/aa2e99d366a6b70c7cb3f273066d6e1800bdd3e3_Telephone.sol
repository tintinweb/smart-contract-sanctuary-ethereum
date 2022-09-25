// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./telephoneorigins.sol";

contract Telephone {
    address public owner;

    function setVars(address _contract, address _newAddress) public payable {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("delegation(address)", _newAddress)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephoneorigins {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function delegation(address _own) public {
        owner = _own;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}