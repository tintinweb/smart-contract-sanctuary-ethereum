// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library ContractCloner {
    function clone(address target) internal returns (address) {
        bytes20 targetBytes = bytes20(target);
        address cloneContract;

        assembly {
            let cloneCode := mload(0x40) // Load the next available memory slot as the clone code
            mstore(
                cloneCode,
                0x602d600c6000396000f3006000357c01000000000000000000000000000000
            ) // Clone initialization code

            // Deploy the clone contract
            cloneContract := create2(0, cloneCode, 32, targetBytes)
        }

        return cloneContract;
    }
}

contract PPCS {
    using ContractCloner for address;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function cloneContract() public {
        // Cloner le contrat
        address newContract = address(this).clone();
        PPCS(newContract).setOwner(msg.sender);
    }

    function setOwner(address newOwner) public {
        require(
            msg.sender == owner,
            "Seul le proprietaire peut appeler cette fonction."
        );
        owner = newOwner;
    }
}