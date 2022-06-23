// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

import "./NFT1155.sol";
import "./Context.sol";

contract Factory is Context {
    event Deploy(address indexed collection, address owner);
    event Mint(address indexed collection, uint256 indexed tokenId, address minter);

    function createCollection(string memory name, string memory symbol) external {
        bytes32 salt = keccak256(abi.encodePacked(name, symbol, _msgSender()));
        bytes memory bytecode = getCreationBytecode(name, symbol);
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deploy(addr, msg.sender);
    }

    function getCreationBytecode(string memory name, string memory symbol) internal pure returns (bytes memory) {
        bytes memory bytecode = type(NFT1155).creationCode;

        return abi.encodePacked(bytecode, abi.encode(name, symbol));
    }
}