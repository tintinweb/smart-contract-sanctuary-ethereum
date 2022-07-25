// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ContractB.sol";

contract ContractAB is ContractB {

    function initializer() external {
        storageStruct.owner = msg.sender;
        _owner = msg.sender;
    }

    function getValue() external view returns (uint256) {
        return storageStruct.value;
    }

    modifier nonReentrant() {
        require(storageStruct.status == 0);
        _;
    }

    function setValue(uint256 _value) external onlyOperatorsOrAdmin() nonReentrant() {
        storageStruct.status = 1;
        storageStruct.value += _value;
        storageStruct.status = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./StorageAB.sol";

contract ContractB is StorageAB {
    StorageStruct storageStruct;

    mapping(address => bool) operators;
    address _owner;

    modifier onlyOperatorsOrAdmin() {
        require(
            msg.sender == _owner ||
                operators[msg.sender]
        );
        _;
    }

    function addOperator(address _operator) external onlyOperatorsOrAdmin() {
        operators[_operator] = true;
    }

    function removeOperator(address _operator) external onlyOperatorsOrAdmin() {
        operators[_operator] = false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract StorageAB {
    struct StorageStruct {
        uint256 value;
        address owner;
        uint256 status;
    }
}