// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Storage.sol";
// 0xD5fFE9915e97cd53fc85fAa9120236D77B0252dd
// 0x8B47D8fc9bdb50d3BEC1c0230D2a96d5aDc32877
// 0x8DCFb8273bbF07210A4ED924F08423ce6Eea3a64
contract ContractA is Storage {
    StorageStruct storageStruct;

    modifier onlyOwner() {
        require(msg.sender == storageStruct.owner);
        _;
    }

    modifier nonReentrant() {
        require(storageStruct.status == 0);
        _;
    }

    function getOwner() external view returns(address) {
        return storageStruct.owner;
    }

    function initializer() external {
        storageStruct = StorageStruct(0, msg.sender, 0);
    }

    function getValue() external view returns (uint256) {
        return storageStruct.value;
    }

    function setValue(uint256 _value) external onlyOwner nonReentrant {
        storageStruct.status = 1;
        storageStruct.value += _value;
        storageStruct.status = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Storage {
    struct StorageStruct {
        uint256 value;
        address owner;
        uint256 status;
    }
}