// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

contract TextFacet {
    bytes32 internal constant NAMESPACE = keccak256("text.facet");

    struct Storage {
        string text;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function setText(string calldata _txt) external {
        Storage storage s = getStorage();
        s.text = _txt;
    }
    
    function getText() external view returns (string memory) {
        return getStorage().text;
    }
}