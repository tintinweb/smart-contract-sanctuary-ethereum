// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library HelloStorage {
    bytes32 public constant STORAGE_SLOT = keccak256("hello.storage");

    struct Layout {
        string content;
    }

    function layout() internal pure returns (Layout storage lay) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            lay.slot := slot
        }
    }
}

contract Hello {
    function __Hello_init(string memory content_) external {
        HelloStorage.layout().content = content_;
    }

    function say() external view returns (string memory) {
        return HelloStorage.layout().content;
    }
}