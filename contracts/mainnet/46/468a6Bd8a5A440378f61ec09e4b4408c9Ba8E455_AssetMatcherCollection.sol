// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../interfaces/IAssetMatcher.sol";
import "../librairies/LibERC721LazyMint.sol";
import "../librairies/LibERC1155LazyMint.sol";

contract AssetMatcherCollection is IAssetMatcher {
    bytes internal constant EMPTY = "";

    function matchAssets(
        LibAsset.AssetType memory leftAssetType,
        LibAsset.AssetType memory rightAssetType
    ) external pure override returns (LibAsset.AssetType memory) {
        if (
            (rightAssetType.assetClass == LibAsset.ERC721_ASSET_CLASS) ||
            (rightAssetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) ||
            (rightAssetType.assetClass == LibERC721LazyMint.ERC721_LAZY_ASSET_CLASS) ||
            (rightAssetType.assetClass == LibERC1155LazyMint.ERC1155_LAZY_ASSET_CLASS) ||
            (rightAssetType.assetClass == LibAsset.CRYPTO_PUNKS)
        ) {
            address leftToken = abi.decode(leftAssetType.data, (address));
            (address rightToken, ) = abi.decode(rightAssetType.data, (address, uint));
            if (leftToken == rightToken) {
                return LibAsset.AssetType(rightAssetType.assetClass, rightAssetType.data);
            }
        }
        return LibAsset.AssetType(0, EMPTY);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../librairies/LibAsset.sol";

interface IAssetMatcher {
    function matchAssets(
        LibAsset.AssetType memory leftAssetType,
        LibAsset.AssetType memory rightAssetType
    ) external view returns (LibAsset.AssetType memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library LibAsset {
    bytes4 public constant ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 public constant ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
    bytes4 public constant ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 public constant ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));
    bytes4 public constant COLLECTION = bytes4(keccak256("COLLECTION"));
    bytes4 public constant CRYPTO_PUNKS = bytes4(keccak256("CRYPTO_PUNKS"));

    bytes32 public constant ASSET_TYPE_TYPEHASH = keccak256("AssetType(bytes4 assetClass,bytes data)");

    bytes32 public constant ASSET_TYPEHASH =
        keccak256("Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)");

    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }

    struct Asset {
        AssetType assetType;
        uint256 value;
    }

    function hash(AssetType memory assetType) internal pure returns (bytes32) {
        return keccak256(abi.encode(ASSET_TYPE_TYPEHASH, assetType.assetClass, keccak256(assetType.data)));
    }

    function hash(Asset memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(ASSET_TYPEHASH, hash(asset.assetType), asset.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./LibPart.sol";

library LibERC1155LazyMint {
    bytes4 public constant ERC1155_LAZY_ASSET_CLASS = bytes4(keccak256("ERC1155_LAZY"));

    struct Mint1155Data {
        uint tokenId;
        string tokenURI;
        uint amount;
        address minter;
        LibPart.Part[] royalties;
        bytes signature;
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH =
        keccak256(
            "Mint1155(uint256 tokenId,string tokenURI,uint256 amount,address minter,Part[] royalties)Part(address recipient,uint256 value)"
        );

    function hash(Mint1155Data memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);
        uint length = data.royalties.length;
        for (uint i; i < length; ++i) {
            royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
        }
        return
            keccak256(
                abi.encode(
                    MINT_AND_TRANSFER_TYPEHASH,
                    data.tokenId,
                    keccak256(bytes(data.tokenURI)),
                    data.amount,
                    data.minter,
                    keccak256(abi.encodePacked(royaltiesBytes))
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./LibPart.sol";

library LibERC721LazyMint {
    bytes4 public constant ERC721_LAZY_ASSET_CLASS = bytes4(keccak256("ERC721_LAZY"));

    struct Mint721Data {
        uint tokenId;
        string tokenURI;
        address minter;
        LibPart.Part[] royalties;
        bytes signature;
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH =
        keccak256(
            "Mint721(uint256 tokenId,string tokenURI,address minter,Part[] royalties)Part(address recipient,uint256 value)"
        );

    function hash(Mint721Data memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);
        uint length = data.royalties.length;
        for (uint i; i < length; ++i) {
            royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
        }
        return
            keccak256(
                abi.encode(
                    MINT_AND_TRANSFER_TYPEHASH,
                    data.tokenId,
                    keccak256(bytes(data.tokenURI)),
                    data.minter,
                    keccak256(abi.encodePacked(royaltiesBytes))
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}