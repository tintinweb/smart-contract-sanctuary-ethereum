// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

library LibAsset {
    bytes4 public constant ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 public constant ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
    bytes4 public constant ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 public constant ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));
    bytes4 public constant COLLECTION = bytes4(keccak256("COLLECTION"));
    bytes4 public constant CRYPTO_PUNK = bytes4(keccak256("CRYPTO_PUNK"));

    bytes32 public constant ASSET_TYPE_TYPEHASH =
        keccak256("AssetType(bytes4 assetClass,bytes data)");

    bytes32 constant ASSET_TYPEHASH =
        keccak256(
            "Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
        );

    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }

    struct Asset {
        AssetType assetType;
        uint256 value;
    }

    function kecc(bytes memory data0) public pure returns (bytes32) {
        return keccak256(data0);
    }

    function hash(AssetType memory assetType) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ASSET_TYPE_TYPEHASH,
                    assetType.assetClass,
                    keccak256(assetType.data)
                )
            );
    }

    function hash(Asset memory asset) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(ASSET_TYPEHASH, hash(asset.assetType), asset.value)
            );
    }
}