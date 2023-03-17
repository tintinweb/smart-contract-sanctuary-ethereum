// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.11;

contract MockERC1155Emitter {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event URI(string value, uint256 indexed id);

    mapping(uint256 id => string) public uri;

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
      return interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
             interfaceID == 0x4e2312e0 ||    // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
             interfaceID == 0x0e89341c;      // ERC-1155 metadata support
    }

    function emitTransferSingle(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value
    ) external {
        emit TransferSingle(operator, from, to, id, value);
    }

    function emitTransferBatch(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external {
        emit TransferBatch(operator, from, to, ids, values);
    }

    function setURI(
        uint256 id,
        string memory value
    ) external {
        uri[id] = value;
        emit URI(value, id);
    }
}