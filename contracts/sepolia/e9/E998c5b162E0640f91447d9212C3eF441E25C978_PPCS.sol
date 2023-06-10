// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library ContractCloner {
    function clone(address target) internal returns (address) {
        bytes20 targetBytes = bytes20(target);
        address cloneContract;

        bytes memory initCode = hex"608060405234801561001057600080fd5b50600080546001600160a01b03191633179055610230806100326000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c806313af4035146100465780638da5cb5b1461005b578063e3fcee391461008a575b600080fd5b6100596100543660046101ca565b610092565b005b60005461006e906001600160a01b031681565b6040516001600160a01b03909116815260200160405180910390f35b61005961012c565b6000546001600160a01b0316331461010a5760405162461bcd60e51b815260206004820152603160248201527f5365756c206c652070726f707269657461697265207065757420617070656c65604482015270391031b2ba3a32903337b731ba34b7b71760791b606482015260840160405180910390fd5b600080546001600160a01b0319166001600160a01b0392909216919091179055565b600061013730610196565b6040516313af403560e01b81523360048201529091506001600160a01b038216906313af403590602401600060405180830381600087803b15801561017b57600080fd5b505af115801561018f573d6000803e3d6000fd5b5050505050565b6000808260601b905060006040516f602d600c6000396000f3006000357c0160781b8152826020826000f595945050505050565b6000602082840312156101dc57600080fd5b81356001600160a01b03811681146101f357600080fd5b939250505056fea264697066735822122064d3ed5695d7f012f5dec5030f9d98cd7ea2e230ec474b6cb3e1a5ba4643006e64736f6c63430008120033"; // Votre code d'initialisation complet ici

        assembly {
            let cloneCode := mload(0x40) // Charger le prochain emplacement mémoire disponible pour le code du clone

            // Définir la longueur du code d'initialisation
            let initCodeLength := mload(initCode)
            mstore(cloneCode, initCodeLength)

            // Copier chaque partie du code d'initialisation dans la mémoire du clone
            let offset := 0x20
            for { let i := 0 } lt(i, initCodeLength) { i := add(i, 0x20) } {
                mstore(add(cloneCode, offset), mload(add(add(initCode, i), 0x20)))
                offset := add(offset, 0x20)
            }

            // Déployer le contrat clone
            cloneContract := create2(0, cloneCode, initCodeLength, targetBytes)
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