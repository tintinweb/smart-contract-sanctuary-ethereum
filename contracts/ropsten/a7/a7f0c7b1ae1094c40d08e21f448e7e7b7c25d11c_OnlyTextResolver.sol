//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract OnlyTextResolver {
    mapping(bytes32 => mapping(string => string)) public texts;
    mapping(bytes32 => string) public names;

    event TextChanged(bytes32 indexed node, string key);

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == 0x59d1d43c || interfaceID == 0x01ffc9a7 || interfaceID == 0x691f3431;
    }

    function text(bytes32 node, string calldata key) external view returns (string memory) {
      return texts[node][key];
    }

    function name (bytes32 node) external view returns (string memory) {
      return names[node];
    }

    /// @dev purposefully unauthorised
    function setText(bytes32 node, string calldata key, string calldata value) external {
        texts[node][key] = value;
        emit TextChanged(node, key);
    }

    /// @dev purposefully unauthorised
    function setName(bytes32 node, string calldata value) external {
      names[node] = value;
    }
}