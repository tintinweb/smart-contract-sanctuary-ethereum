/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
    bytes32 constant ASSET_TYPE_TYPEHASH = keccak256(
        "AssetType(bytes4 assetClass,bytes data)"
    );
contract Raritest {
        function hash(bytes memory data) public pure returns (bytes32) {
        return keccak256(abi.encode(
                ASSET_TYPE_TYPEHASH,
                bytes4(keccak256("ERC1155_LAZY")),
                keccak256(data)
            ));
    }
            function hashEth(bytes memory data) public pure returns (bytes32) {
        return keccak256(abi.encode(
                ASSET_TYPE_TYPEHASH,
                bytes4(keccak256("ETH")),
                keccak256(data)
            ));
    }
             function keccak256Data(bytes memory data) public pure returns (bytes32) {
        return keccak256(data);
    }

      function eth() public pure returns (bytes4) {
        return bytes4(keccak256("ETH"));
    }

        function hashOrder(address maker, bytes32 assetType, bytes32 assetSecond, uint salt, bytes memory data) public pure returns  (bytes32) {
        return keccak256(abi.encode(
                maker,
                    assetType,
                    assetSecond,
                    salt,
                    data
            ));
    }
}