// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IMarketWrapper.sol";
import "../721/AuctionHouse721.sol";

contract Wrapper is IMarketWrapper{

    AuctionHouse721 internal immutable auction;

    constructor(address _auction) {
        auction = AuctionHouse721(_auction);
    }

    function auctionIdMatchesToken(
        uint256 auctionId,
        address nftContract,
        uint256 tokenId
    ) external override view returns (bool){
        return auctionId == auction. getAuctionByToken(nftContract, tokenId);
    }

    function getMinimumBid(uint256 auctionId) external override view returns (uint256){
        return auction.getMinimalNextBid(auctionId);
    }

    function getCurrentHighestBidder(uint256 auctionId)
        external
        override
        view
        returns (address){
            return auction.getCurrentBuyer(auctionId);
        }

    function bid(uint256 auctionId, uint256 bidAmount) external override{
        (bool success, bytes memory returnData) =
            address(auction).call{value: bidAmount}(
                abi.encodeWithSignature("putBidWrapper(uint256)", auctionId)
            );
        require(success, string(returnData));
    }

    function isFinalized(uint256 auctionId) external override view returns (bool){
        return !auction.checkAuctionExistence(auctionId);
    }

    function finalize(uint256 auctionId) external override{
        auction.finishAuction(auctionId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library LibTransfer {
    function transferEth(address to, uint value) internal {
        (bool success,) = to.call{ value: value }("");
        require(success, "transfer failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@rarible/lib-asset/contracts/LibAsset.sol";

library LibFeeSide {

    enum FeeSide {NONE, LEFT, RIGHT}

    function getFeeSide(bytes4 leftClass, bytes4 rightClass) internal pure returns (FeeSide) {
        if (leftClass == LibAsset.ETH_ASSET_CLASS) {
            return FeeSide.LEFT;
        }
        if (rightClass == LibAsset.ETH_ASSET_CLASS) {
            return FeeSide.RIGHT;
        }
        if (leftClass == LibAsset.ERC20_ASSET_CLASS) {
            return FeeSide.LEFT;
        }
        if (rightClass == LibAsset.ERC20_ASSET_CLASS) {
            return FeeSide.RIGHT;
        }
        if (leftClass == LibAsset.ERC1155_ASSET_CLASS) {
            return FeeSide.LEFT;
        }
        if (rightClass == LibAsset.ERC1155_ASSET_CLASS) {
            return FeeSide.RIGHT;
        }
        return FeeSide.NONE;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@rarible/lib-part/contracts/LibPart.sol";
import "@rarible/lib-asset/contracts/LibAsset.sol";
import "./LibFeeSide.sol";

library LibDeal {
    struct DealSide {
        LibAsset.Asset asset;
        LibPart.Part[] payouts;
        LibPart.Part[] originFees;
        address proxy;
        address from;
    }

    struct DealData {
        uint maxFeesBasePoint;
        LibFeeSide.FeeSide feeSide;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../lib/LibDeal.sol";
import "./ITransferExecutor.sol";

abstract contract ITransferManager is ITransferExecutor {

    function doTransfers(
        LibDeal.DealSide memory left,
        LibDeal.DealSide memory right,
        LibDeal.DealData memory dealData
    ) internal virtual returns (uint totalMakeValue, uint totalTakeValue);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@rarible/lib-asset/contracts/LibAsset.sol";

abstract contract ITransferExecutor {
    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to,
        address proxy
    ) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@rarible/exchange-interfaces/contracts/ITransferProxy.sol";
import "@rarible/exchange-interfaces/contracts/INftTransferProxy.sol";
import "@rarible/exchange-interfaces/contracts/IERC20TransferProxy.sol";
import "./interfaces/ITransferExecutor.sol";

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./lib/LibTransfer.sol";

abstract contract TransferExecutor is Initializable, OwnableUpgradeable, ITransferExecutor {
    using LibTransfer for address;

    mapping (bytes4 => address) proxies;

    event ProxyChange(bytes4 indexed assetType, address proxy);

    function __TransferExecutor_init_unchained(address transferProxy, address erc20TransferProxy) internal { 
        proxies[LibAsset.ERC20_ASSET_CLASS] = address(erc20TransferProxy);
        proxies[LibAsset.ERC721_ASSET_CLASS] = address(transferProxy);
        proxies[LibAsset.ERC1155_ASSET_CLASS] = address(transferProxy);
    }

    function setTransferProxy(bytes4 assetType, address proxy) external onlyOwner {
        proxies[assetType] = proxy;
        emit ProxyChange(assetType, proxy);
    }

    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to,
        address proxy
    ) internal override {
        if (asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            //not using transfer proxy when transfering from this contract
            (address token, uint tokenId) = abi.decode(asset.assetType.data, (address, uint256));
            require(asset.value == 1, "erc721 value error");
            if (from == address(this)){
                IERC721Upgradeable(token).safeTransferFrom(address(this), to, tokenId);
            } else {
                INftTransferProxy(proxy).erc721safeTransferFrom(IERC721Upgradeable(token), from, to, tokenId);
            }
        } else if (asset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
            //not using transfer proxy when transfering from this contract
            (address token) = abi.decode(asset.assetType.data, (address));
            if (from == address(this)){
                require(IERC20Upgradeable(token).transfer(to, asset.value), "erc20 transfer failed");
            } else {
                IERC20TransferProxy(proxy).erc20safeTransferFrom(IERC20Upgradeable(token), from, to, asset.value);
            }
        } else if (asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
            //not using transfer proxy when transfering from this contract
            (address token, uint tokenId) = abi.decode(asset.assetType.data, (address, uint256));
            if (from == address(this)){
                IERC1155Upgradeable(token).safeTransferFrom(address(this), to, tokenId, asset.value, "");
            } else {
                INftTransferProxy(proxy).erc1155safeTransferFrom(IERC1155Upgradeable(token), from, to, tokenId, asset.value, "");  
            }
        } else if (asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
            if (to != address(this)) {
                to.transferEth(asset.value);
            }
        } else {
            ITransferProxy(proxy).transfer(asset, from, to);
        }
    }
    
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@rarible/lazy-mint/contracts/erc-721/LibERC721LazyMint.sol";
import "@rarible/lazy-mint/contracts/erc-1155/LibERC1155LazyMint.sol";

import "@rarible/exchange-interfaces/contracts/IRoyaltiesProvider.sol";

import "@rarible/lib-bp/contracts/BpLibrary.sol";

import "./interfaces/ITransferManager.sol";

abstract contract RaribleTransferManager is OwnableUpgradeable, ITransferManager {
    using BpLibrary for uint;
    using SafeMathUpgradeable for uint;

    // @notice protocolFee is deprecated 
    uint private protocolFee;
    IRoyaltiesProvider public royaltiesRegistry;

    // deprecated: no need without protocolFee
    address private defaultFeeReceiver;
    // deprecated: no need without protocolFee 
    mapping(address => address) private feeReceivers;

    function __RaribleTransferManager_init_unchained(
        uint newProtocolFee,
        address newDefaultFeeReceiver,
        IRoyaltiesProvider newRoyaltiesProvider
    ) internal initializer {
        protocolFee = newProtocolFee;
        defaultFeeReceiver = newDefaultFeeReceiver;
        royaltiesRegistry = newRoyaltiesProvider;
    }

    function setRoyaltiesRegistry(IRoyaltiesProvider newRoyaltiesRegistry) external onlyOwner {
        royaltiesRegistry = newRoyaltiesRegistry;
    }

    /**
        @notice executes transfers for 2 matched orders
        @param left DealSide from the left order (see LibDeal.sol)
        @param right DealSide from the right order (see LibDeal.sol)
        @param dealData DealData of the match (see LibDeal.sol)
        @return totalLeftValue - total amount for the left order
        @return totalRightValue - total amout for the right order
    */
    function doTransfers(
        LibDeal.DealSide memory left,
        LibDeal.DealSide memory right,
        LibDeal.DealData memory dealData
    ) override internal returns (uint totalLeftValue, uint totalRightValue) {
        totalLeftValue = left.asset.value;
        totalRightValue = right.asset.value;

        if (dealData.feeSide == LibFeeSide.FeeSide.LEFT) {
            totalLeftValue = doTransfersWithFees(left, right, dealData.maxFeesBasePoint);
            transferPayouts(right.asset.assetType, right.asset.value, right.from, left.payouts, right.proxy);
        } else if (dealData.feeSide == LibFeeSide.FeeSide.RIGHT) {
            totalRightValue = doTransfersWithFees(right, left, dealData.maxFeesBasePoint);
            transferPayouts(left.asset.assetType, left.asset.value, left.from, right.payouts, left.proxy);
        } else {
            transferPayouts(left.asset.assetType, left.asset.value, left.from, right.payouts, left.proxy);
            transferPayouts(right.asset.assetType, right.asset.value, right.from, left.payouts, right.proxy);
        }
    }

    /**
        @notice executes the fee-side transfers (payment + fees)
        @param paymentSide DealSide of the fee-side order
        @param nftSide  DealSide of the nft-side order
        @param maxFeesBasePoint max fee for the sell-order (used and is > 0 for V3 orders only)
        @return totalAmount of fee-side asset
    */
    function doTransfersWithFees(
        LibDeal.DealSide memory paymentSide,
        LibDeal.DealSide memory nftSide,
        uint maxFeesBasePoint
    ) internal returns (uint totalAmount) {
        totalAmount = calculateTotalAmount(paymentSide.asset.value, paymentSide.originFees, maxFeesBasePoint);
        uint rest = totalAmount;

        rest = transferRoyalties(paymentSide.asset.assetType, nftSide.asset.assetType, nftSide.payouts, rest, paymentSide.asset.value, paymentSide.from, paymentSide.proxy);
        if (
            paymentSide.originFees.length  == 1 &&
            nftSide.originFees.length  == 1 &&
            nftSide.originFees[0].account == paymentSide.originFees[0].account
        ) { 
            LibPart.Part[] memory origin = new  LibPart.Part[](1);
            origin[0].account = nftSide.originFees[0].account;
            origin[0].value = nftSide.originFees[0].value + paymentSide.originFees[0].value;
            (rest,) = transferFees(paymentSide.asset.assetType, rest, paymentSide.asset.value, origin, paymentSide.from, paymentSide.proxy);
        } else {
            (rest,) = transferFees(paymentSide.asset.assetType, rest, paymentSide.asset.value, paymentSide.originFees, paymentSide.from, paymentSide.proxy);
            (rest,) = transferFees(paymentSide.asset.assetType, rest, paymentSide.asset.value, nftSide.originFees, paymentSide.from, paymentSide.proxy);
        }
        transferPayouts(paymentSide.asset.assetType, rest, paymentSide.from, nftSide.payouts, paymentSide.proxy);
    }

    /**
        @notice Transfer royalties. If there is only one royalties receiver and one address in payouts and they match,
           nothing is transferred in this function
        @param paymentAssetType Asset Type which represents payment
        @param nftAssetType Asset Type which represents NFT to pay royalties for
        @param payouts Payouts to be made
        @param rest How much of the amount left after previous transfers
        @param from owner of the Asset to transfer
        @param proxy Transfer proxy to use
        @return How much left after transferring royalties
    */
    function transferRoyalties(
        LibAsset.AssetType memory paymentAssetType,
        LibAsset.AssetType memory nftAssetType,
        LibPart.Part[] memory payouts,
        uint rest,
        uint amount,
        address from,
        address proxy
    ) internal returns (uint) {
        LibPart.Part[] memory royalties = getRoyaltiesByAssetType(nftAssetType);
        if (
            royalties.length == 1 &&
            payouts.length == 1 &&
            royalties[0].account == payouts[0].account
        ) {
            require(royalties[0].value <= 5000, "Royalties are too high (>50%)");
            return rest;
        }
        (uint result, uint totalRoyalties) = transferFees(paymentAssetType, rest, amount, royalties, from, proxy);
        require(totalRoyalties <= 5000, "Royalties are too high (>50%)");
        return result;
    }

    /**
        @notice calculates royalties by asset type. If it's a lazy NFT, then royalties are extracted from asset. otherwise using royaltiesRegistry
        @param nftAssetType NFT Asset Type to calculate royalties for
        @return calculated royalties (Array of LibPart.Part)
    */
    function getRoyaltiesByAssetType(LibAsset.AssetType memory nftAssetType) internal returns (LibPart.Part[] memory) {
        if (nftAssetType.assetClass == LibAsset.ERC1155_ASSET_CLASS || nftAssetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            (address token, uint tokenId) = abi.decode(nftAssetType.data, (address, uint));
            return royaltiesRegistry.getRoyalties(token, tokenId);
        } else if (nftAssetType.assetClass == LibERC1155LazyMint.ERC1155_LAZY_ASSET_CLASS) {
            (, LibERC1155LazyMint.Mint1155Data memory data) = abi.decode(nftAssetType.data, (address, LibERC1155LazyMint.Mint1155Data));
            return data.royalties;
        } else if (nftAssetType.assetClass == LibERC721LazyMint.ERC721_LAZY_ASSET_CLASS) {
            (, LibERC721LazyMint.Mint721Data memory data) = abi.decode(nftAssetType.data, (address, LibERC721LazyMint.Mint721Data));
            return data.royalties;
        }
        LibPart.Part[] memory empty;
        return empty;
    }

    /**
        @notice Transfer fees
        @param assetType Asset Type to transfer
        @param rest How much of the amount left after previous transfers
        @param amount Total amount of the Asset. Used as a base to calculate part from (100%)
        @param fees Array of LibPart.Part which represents fees to pay
        @param from owner of the Asset to transfer
        @param proxy Transfer proxy to use
        @return newRest how much left after transferring fees
        @return totalFees total number of fees in bp
    */
    function transferFees(
        LibAsset.AssetType memory assetType,
        uint rest,
        uint amount,
        LibPart.Part[] memory fees,
        address from,
        address proxy
    ) internal returns (uint newRest, uint totalFees) {
        totalFees = 0;
        newRest = rest;
        for (uint256 i = 0; i < fees.length; i++) {
            totalFees = totalFees.add(fees[i].value);
            uint feeValue;
            (newRest, feeValue) = subFeeInBp(newRest, amount, fees[i].value);
            if (feeValue > 0) {
                transfer(LibAsset.Asset(assetType, feeValue), from, fees[i].account, proxy);
            }
        }
    }

    /**
        @notice transfers main part of the asset (payout)
        @param assetType Asset Type to transfer
        @param amount Amount of the asset to transfer
        @param from Current owner of the asset
        @param payouts List of payouts - receivers of the Asset
        @param proxy Transfer Proxy to use
    */
    function transferPayouts(
        LibAsset.AssetType memory assetType,
        uint amount,
        address from,
        LibPart.Part[] memory payouts,
        address proxy
    ) internal {
        require(payouts.length > 0, "transferPayouts: nothing to transfer");
        uint sumBps = 0;
        uint rest = amount;
        for (uint256 i = 0; i < payouts.length - 1; i++) {
            uint currentAmount = amount.bp(payouts[i].value);
            sumBps = sumBps.add(payouts[i].value);
            if (currentAmount > 0) {
                rest = rest.sub(currentAmount);
                transfer(LibAsset.Asset(assetType, currentAmount), from, payouts[i].account, proxy);
            }
        }
        LibPart.Part memory lastPayout = payouts[payouts.length - 1];
        sumBps = sumBps.add(lastPayout.value);
        require(sumBps == 10000, "Sum payouts Bps not equal 100%");
        if (rest > 0) {
            transfer(LibAsset.Asset(assetType, rest), from, lastPayout.account, proxy);
        }
    }
    
    /**
        @notice calculates total amount of fee-side asset that is going to be used in match
        @param amount fee-side order value
        @param orderOriginFees fee-side order's origin fee (it adds on top of the amount)
        @param maxFeesBasePoint max fee for the sell-order (used and is > 0 for V3 orders only)
        @return total amount of fee-side asset
    */
    function calculateTotalAmount(
        uint amount,
        LibPart.Part[] memory orderOriginFees,
        uint maxFeesBasePoint
    ) internal pure returns (uint) {
        if (maxFeesBasePoint > 0) {
            return amount;
        }
        uint total = amount;
        for (uint256 i = 0; i < orderOriginFees.length; i++) {
            total = total.add(amount.bp(orderOriginFees[i].value));
        }
        return total;
    }

    function subFeeInBp(uint value, uint total, uint feeInBp) internal pure returns (uint newValue, uint realFee) {
        return subFee(value, total.bp(feeInBp));
    }

    function subFee(uint value, uint fee) internal pure returns (uint newValue, uint realFee) {
        if (value > fee) {
            newValue = value.sub(fee);
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }

    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

library BpLibrary {
    using SafeMathUpgradeable for uint;

    function bp(uint value, uint bpValue) internal pure returns (uint) {
        return value.mul(bpValue).div(10000);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library LibAsset {
    bytes4 constant public ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 constant public ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
    bytes4 constant public ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 constant public ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));
    bytes4 constant public COLLECTION = bytes4(keccak256("COLLECTION"));
    bytes4 constant public CRYPTO_PUNKS = bytes4(keccak256("CRYPTO_PUNKS"));

    bytes32 constant ASSET_TYPE_TYPEHASH = keccak256(
        "AssetType(bytes4 assetClass,bytes data)"
    );

    bytes32 constant ASSET_TYPEHASH = keccak256(
        "Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
    );

    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }

    struct Asset {
        AssetType assetType;
        uint value;
    }

    function hash(AssetType memory assetType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                ASSET_TYPE_TYPEHASH,
                assetType.assetClass,
                keccak256(assetType.data)
            ));
    }

    function hash(Asset memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                ASSET_TYPEHASH,
                hash(asset.assetType),
                asset.value
            ));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "@rarible/lib-part/contracts/LibPart.sol";

library LibERC721LazyMint {
    bytes4 constant public ERC721_LAZY_ASSET_CLASS = bytes4(keccak256("ERC721_LAZY"));
    bytes4 constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x8486f69f;

    struct Mint721Data {
        uint tokenId;
        string tokenURI;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
        bytes[] signatures;
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH = keccak256("Mint721(uint256 tokenId,string tokenURI,Part[] creators,Part[] royalties)Part(address account,uint96 value)");

    function hash(Mint721Data memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);
        for (uint i = 0; i < data.royalties.length; i++) {
            royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
        }
        bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);
        for (uint i = 0; i < data.creators.length; i++) {
            creatorsBytes[i] = LibPart.hash(data.creators[i]);
        }
        return keccak256(abi.encode(
                MINT_AND_TRANSFER_TYPEHASH,
                data.tokenId,
                keccak256(bytes(data.tokenURI)),
                keccak256(abi.encodePacked(creatorsBytes)),
                keccak256(abi.encodePacked(royaltiesBytes))
            ));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "@rarible/lib-part/contracts/LibPart.sol";

library LibERC1155LazyMint {
    bytes4 constant public ERC1155_LAZY_ASSET_CLASS = bytes4(keccak256("ERC1155_LAZY"));
    bytes4 constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x6db15a0f;

    struct Mint1155Data {
        uint tokenId;
        string tokenURI;
        uint supply;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
        bytes[] signatures;
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH = keccak256("Mint1155(uint256 tokenId,uint256 supply,string tokenURI,Part[] creators,Part[] royalties)Part(address account,uint96 value)");

    function hash(Mint1155Data memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);
        for (uint i = 0; i < data.royalties.length; i++) {
            royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
        }
        bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);
        for (uint i = 0; i < data.creators.length; i++) {
            creatorsBytes[i] = LibPart.hash(data.creators[i]);
        }
        return keccak256(abi.encode(
                MINT_AND_TRANSFER_TYPEHASH,
                data.tokenId,
                data.supply,
                keccak256(bytes(data.tokenURI)),
                keccak256(abi.encodePacked(creatorsBytes)),
                keccak256(abi.encodePacked(royaltiesBytes))
            ));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

import "@rarible/lib-asset/contracts/LibAsset.sol";

interface ITransferProxy {
    function transfer(LibAsset.Asset calldata asset, address from, address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "@rarible/lib-part/contracts/LibPart.sol";

interface IRoyaltiesProvider {
    function getRoyalties(address token, uint tokenId) external returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface INftTransferProxy {
    function erc721safeTransferFrom(IERC721Upgradeable token, address from, address to, uint256 tokenId) external;

    function erc1155safeTransferFrom(IERC1155Upgradeable token, address from, address to, uint256 id, uint256 value, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20TransferProxy {
    function erc20safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @dev contract to add tokenToAuctionId functionality to auctionHouse
contract TokenToAuction {
    /// @dev mapping to store auction ids for token address + token id (only stores erc-721 tokens)
    mapping(address => mapping(uint256 => uint256)) private tokenToAuctionId;

    /// @dev returns auction id by token address and token id
    function getAuctionByToken(address _collection, uint tokenId) external view returns(uint) {
        return tokenToAuctionId[_collection][tokenId];
    }

    /// @dev sets auction id for token address and token id
    function setAuctionForToken(address token, uint tokenId, uint auctionId) internal {
        tokenToAuctionId[token][tokenId] = auctionId;
    }

    /// @dev deletes auctionId from tokenToAuctionId
    function deleteAuctionForToken(address token, uint tokenId) internal {
        delete tokenToAuctionId[token][tokenId];
    }
    
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
 * @title IMarketWrapper
 * @author Anna Carroll
 * @notice IMarketWrapper provides a common interface for
 * interacting with NFT auction markets.
 * Contracts can abstract their interactions with
 * different NFT markets using IMarketWrapper.
 * NFT markets can become compatible with any contract
 * using IMarketWrapper by deploying a MarketWrapper contract
 * that implements this interface using the logic of their Market.
 *
 * WARNING: MarketWrapper contracts should NEVER write to storage!
 * When implementing a MarketWrapper, exercise caution; a poorly implemented
 * MarketWrapper contract could permanently lose access to the NFT or user funds.
 */
interface IMarketWrapper {
    /**
     * @notice Given the auctionId, nftContract, and tokenId, check that:
     * 1. the auction ID matches the token
     * referred to by tokenId + nftContract
     * 2. the auctionId refers to an *ACTIVE* auction
     * (e.g. an auction that will accept bids)
     * within this market contract
     * 3. any additional validation to ensure that
     * a PartyBid can bid on this auction
     * (ex: if the market allows arbitrary bidding currencies,
     * check that the auction currency is ETH)
     * Note: This function probably should have been named "isValidAuction"
     * @dev Called in PartyBid.sol in `initialize` at line 174
     * @return TRUE if the auction is valid
     */
    function auctionIdMatchesToken(
        uint256 auctionId,
        address nftContract,
        uint256 tokenId
    ) external view returns (bool);

    /**
     * @notice Calculate the minimum next bid for this auction.
     * PartyBid contracts always submit the minimum possible
     * bid that will be accepted by the Market contract.
     * usually, this is either the reserve price (if there are no bids)
     * or a certain percentage increase above the current highest bid
     * @dev Called in PartyBid.sol in `bid` at line 251
     * @return minimum bid amount
     */
    function getMinimumBid(uint256 auctionId) external view returns (uint256);

    /**
     * @notice Query the current highest bidder for this auction
     * It is assumed that there is always 1 winning highest bidder for an auction
     * This is used to ensure that PartyBid cannot outbid itself if it is already winning
     * @dev Called in PartyBid.sol in `bid` at line 241
     * @return highest bidder
     */
    function getCurrentHighestBidder(uint256 auctionId)
        external
        view
        returns (address);

    /**
     * @notice Submit bid to Market contract
     * @dev Called in PartyBid.sol in `bid` at line 259
     */
    function bid(uint256 auctionId, uint256 bidAmount) external;

    /**
     * @notice Determine whether the auction has been finalized
     * Used to check if it is still possible to bid
     * And to determine whether the PartyBid should finalize the auction
     * @dev Called in PartyBid.sol in `bid` at line 247
     * @dev and in `finalize` at line 288
     * @return TRUE if the auction has been finalized
     */
    function isFinalized(uint256 auctionId) external view returns (bool);

    /**
     * @notice Finalize the results of the auction
     * on the Market contract
     * It is assumed  that this operation is performed once for each auction,
     * that after it is done the auction is over and the NFT has been
     * transferred to the auction winner.
     * @dev Called in PartyBid.sol in `finalize` at line 289
     */
    function finalize(uint256 auctionId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable96 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint96 a, uint96 b) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

/// @dev library that works with data field of Bid struct
library LibBidDataV1 {
    bytes4 constant public V1 = bytes4(keccak256("V1"));

    /// @dev struct of Bid data field, version 1
    struct DataV1 {
        // auction originFees
        uint originFee;
    }

    /// @dev returns parsed data field of a Bid (so returns DataV1 struct)
    function parse(bytes memory data, bytes4 dataType) internal pure returns (DataV1 memory aucData) {
        if (dataType == V1) {
            if (data.length > 0){
                aucData = abi.decode(data, (DataV1));
            }  
        } else {
            revert("wrong bid dataType");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

/// @dev library that works with data field of Auction struct
library LibAucDataV1 {
    bytes4 constant public V1 = bytes4(keccak256("V1"));

    /// @dev struct of Auction data field, version 1
    struct DataV1 {
        // auction originFees
        uint originFee;
        // auction duration
        uint96 duration;
        // auction startTime
        uint96 startTime;
        // auction buyout price
        uint96 buyOutPrice;
    }

    /// @dev returns parsed data field of an Auction (so returns DataV1 struct)
    function parse(bytes memory data, bytes4 dataType) internal pure returns (DataV1 memory aucData) {
        if (dataType == V1) {
            if (data.length > 0){
                aucData = abi.decode(data, (DataV1));
            }
        } else {
            revert("wrong auction dataType");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./libs/LibAucDataV1.sol";
import "./libs/LibBidDataV1.sol";
import "./libs/SafeMathUpgradeable96.sol";

import "@rarible/transfer-manager/contracts/RaribleTransferManager.sol";
import "@rarible/transfer-manager/contracts/TransferExecutor.sol";

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

abstract contract AuctionHouseBase is OwnableUpgradeable,  ReentrancyGuardUpgradeable, RaribleTransferManager, TransferExecutor {
    using LibTransfer for address;
    using SafeMathUpgradeable for uint;
    using BpLibrary for uint;

    /// @dev default minimal auction duration and also the time for that auction is extended when it's about to end (endTime - now < EXTENSION_DURATION)
    uint96 internal constant EXTENSION_DURATION = 15 minutes;

    /// @dev maximum auction duration
    uint128 internal constant MAX_DURATION = 1000 days;

    /// @dev maximum fee base point
    uint internal constant MAX_FEE_BASE_POINT = 1000;

    /// @dev mapping to store eth amount that is ready to be withdrawn (used for faulty eth-bids)
    mapping(address => uint) readyToWithdraw;

    /// @dev latest auctionId
    uint256 public auctionId;

    /// @dev minimal auction duration
    uint96 public minimalDuration;

    /// @dev minimal bid increase in base points
    uint96 public minimalStepBasePoint;

    /// @dev bid struct
    struct Bid {
        // the amount 
        uint amount;
        // version of Bid to correctly decode data field
        bytes4 dataType;
        // field to store additional information for Bid, can be seen in "LibBidDataV1.sol"
        bytes data;
    }

    /// @dev event that emits when auction is created
    event AuctionCreated(uint indexed auctionId, address seller);
    /// @dev event that emits when bid is placed
    event BidPlaced(uint indexed auctionId, address buyer, uint endTime);
    /// @dev event that emits when auction is finished
    event AuctionFinished(uint indexed auctionId);
    /// @dev event that emits when auction is canceled
    event AuctionCancelled(uint indexed auctionId);
    /// @dev event that emits when auction is bought out
    event AuctionBuyOut(uint indexed auctionId, address buyer);

    /// @dev event that's emitted when user can withdraw ETH from the AuctionHouse
    event AvailableToWithdraw(address indexed owner, uint added, uint total);
    /// @dev event that's emitted when minimal auction duration changes
    event MinimalDurationChanged(uint oldValue, uint newValue);

    event MinimalStepChanged(uint oldValue, uint newValue);

    function __AuctionHouseBase_init_unchained(
        uint96 _minimalStepBasePoint
    ) internal initializer {
        auctionId = 1;
        minimalDuration = EXTENSION_DURATION;
        minimalStepBasePoint = _minimalStepBasePoint;
    }

    /// @dev increments auctionId and returns new value
    function getNextAndIncrementAuctionId() internal returns (uint256) {
        return auctionId++;
    }

    function changeMinimalDuration(uint96 newValue) external onlyOwner {
        emit MinimalDurationChanged(minimalDuration, newValue);
        minimalDuration = newValue;
    }

    function changeMinimalStep(uint96 newValue) external onlyOwner {
        emit MinimalStepChanged(minimalStepBasePoint, newValue);
        minimalStepBasePoint = newValue;
    }

    function transferNFT (
        address token,
        uint tokenId,
        uint value,
        bytes4 assetClass,
        address from,
        address to
    ) internal {
        transfer(
            getSellAsset(
                token,
                tokenId,
                value,
                assetClass
            ),
            from,
            to,
            proxies[assetClass]
        );
    }

    function transferBid(
        uint value,
        address token,
        address from,
        address to,
        address proxy
    ) internal {
        transfer(
            getBuyAsset(
                token,
                value
            ),
            from,
            to,
            proxy
        );
    }

    function getSellAsset(address token, uint tokenId, uint value, bytes4 assetClass) internal pure returns(LibAsset.Asset memory asset) {
        asset.value = value;
        asset.assetType.assetClass = assetClass;
        asset.assetType.data = abi.encode(token, tokenId);
    }

    function getBuyAsset(address token, uint value) internal pure returns(LibAsset.Asset memory asset) {
        asset.value = value;

        if (token == address(0)){
            asset.assetType.assetClass = LibAsset.ETH_ASSET_CLASS;
        } else {
            asset.assetType.assetClass = LibAsset.ERC20_ASSET_CLASS;
            asset.assetType.data = abi.encode(token);
        }
    }

    function getPayouts(address maker) internal pure returns(LibPart.Part[] memory) {
        LibPart.Part[] memory payout = new LibPart.Part[](1);
        payout[0].account = payable(maker);
        payout[0].value = 10000;
        return payout;
    }

    function getOriginFee(uint data) internal pure returns(LibPart.Part[] memory) {
        LibPart.Part[] memory originFee = new LibPart.Part[](1);
        originFee[0].account = payable(address(data));
        originFee[0].value = uint96(getValueFromData(data));
        return originFee;
    }

    function _checkAuctionRangeTime(uint endTime, uint startTime) internal view returns (bool){
        uint currentTime = block.timestamp;
        if (startTime > 0 && startTime > currentTime) {
            return false;
        }
        if (endTime > 0 && endTime <= currentTime){
            return false;
        }

        return true;
    }

    /// @dev returns true if newAmount is enough for buyOut
    function buyOutVerify(LibAucDataV1.DataV1 memory aucData, uint newAmount) internal pure returns (bool) {
        if (aucData.buyOutPrice > 0 && aucData.buyOutPrice <= newAmount) {
            return true;
        }
        return false;
    }

    /// @dev returns true if auction exists, false otherwise
    function _checkAuctionExistence(address seller) internal pure returns (bool){
        return seller != address(0);
    }

    /// @dev Used to withdraw faulty bids (bids that failed to return after out-bidding)
    function withdrawFaultyBid(address _to) external {
        address sender = _msgSender();
        uint amount = readyToWithdraw[sender];
        require( amount > 0, "nothing to withdraw");
        readyToWithdraw[sender] = 0;
        _to.transferEth(amount);
    }

    function _returnBid(
        Bid memory oldBid,
        address buyAsset,
        address oldBuyer,
        address proxy
    ) internal {
        // nothing to return
        if (oldBuyer == address(0)) {
            return;
        }
        if (buyAsset == address(0)) {
            (bool success,) = oldBuyer.call{ value: oldBid.amount }("");
            if (!success) {
                uint currentValueToWithdraw = readyToWithdraw[oldBuyer];
                uint newValueToWithdraw = oldBid.amount.add(currentValueToWithdraw);
                readyToWithdraw[oldBuyer] = newValueToWithdraw;
                emit AvailableToWithdraw(oldBuyer, oldBid.amount, newValueToWithdraw);
            }
        } else {
            transferBid(
                oldBid.amount,
                buyAsset,
                address(this),
                oldBuyer,
                proxy
            );
        }
    }

    function _getProxy(address buyAsset) internal view returns(address){
        address proxy;
        if (buyAsset != address(0)){
            proxy = proxies[LibAsset.ERC20_ASSET_CLASS];
        }
        return proxy;
    }

    /// @dev check that msg.value more than bid amount with fees and return change
    function checkEthReturnChange(uint totalAmount, address buyer) internal {
        uint msgValue = msg.value;
        require(msgValue >= totalAmount, "not enough ETH");
        uint256 change = msgValue.sub(totalAmount);
        if (change > 0) {
            buyer.transferEth(change);
        }
    }

    /// @dev returns true if auction in progress, false otherwise
    function checkAuctionInProgress(address seller, uint endTime, uint startTime) internal view{
        require(_checkAuctionExistence(seller) && _checkAuctionRangeTime(endTime, startTime), "auction is inactive");
    }

    /// @dev reserves new bid and returns the last one if it exists
    function reserveBid(
        address buyAsset,
        address oldBuyer,
        address newBuyer,
        Bid memory oldBid,
        address proxy,
        uint newTotalAmount
    ) internal {
        // return old bid if theres any
        _returnBid(
            oldBid,
            buyAsset,
            oldBuyer,
            proxy
        );
        
        //lock new bid
        transferBid(
            newTotalAmount,
            buyAsset,
            newBuyer,
            address(this),
            proxy
        );
    }

    /// @dev returns the minimal amount of the next bid (without fees)
    function _getMinimalNextBid(address buyer, uint96 minimalPrice, uint amount) internal view returns (uint minBid){
        if (buyer == address(0x0)) {
            minBid = minimalPrice;
        } else {
            minBid = amount.add(amount.bp(minimalStepBasePoint));
        }
    }

    function getValueFromData(uint data) internal pure returns(uint) {
        return (data >> 160);
    }

    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../AuctionHouseBase.sol";

abstract contract AuctionHouseBase721 is AuctionHouseBase {

    /// @dev mapping to store data of auctions for auctionId
    mapping(uint => Auction) auctions;

    /// @dev auction struct
    struct Auction {
        // asset that is being sold at auction
        address sellToken;
        uint sellTokenId;
        // asset type that bids are taken in
        address buyAsset;
        // the time when auction ends
        uint96 endTime;
        // information about the current highest bid
        Bid lastBid;
        // seller address
        address payable seller;
        // the minimal amount of the first bid
        uint96 minimalPrice;
        // buyer address
        address payable buyer;
        // protocolFee at the time of the purchase
        uint64 protocolFee;
        // version of Auction to correctly decode data field
        bytes4 dataType;
        // field to store additional information for Auction, can be seen in "LibAucDataV1.sol"
        bytes data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./AuctionHouseBase721.sol";
import "../wrapper/TokenToAuction.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721HolderUpgradeable.sol";

/// @dev contract to create and interact with auctions
contract AuctionHouse721 is ERC721HolderUpgradeable, TokenToAuction, AuctionHouseBase721 {
    using SafeMathUpgradeable96 for uint96;
    using SafeMathUpgradeable for uint;

    function __AuctionHouse721_init(
        address newDefaultFeeReceiver,
        IRoyaltiesProvider newRoyaltiesProvider,
        address _transferProxy,
        address _erc20TransferProxy,
        uint64 newProtocolFee,
        uint96 _minimalStepBasePoint
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC721Holder_init_unchained();
        __ReentrancyGuard_init_unchained();
        __AuctionHouseBase_init_unchained(_minimalStepBasePoint);
        __TransferExecutor_init_unchained(_transferProxy, _erc20TransferProxy);
        __RaribleTransferManager_init_unchained(newProtocolFee, newDefaultFeeReceiver, newRoyaltiesProvider);          
        __AuctionHouse721_init_unchained();
    }

    function __AuctionHouse721_init_unchained() internal initializer {  
    }

    /// @dev creates an auction and locks sell asset
    function startAuction(
        address _sellToken,
        uint _sellTokenId,
        address _buyAsset,
        uint96 minimalPrice,
        bytes4 dataType,
        bytes memory data
    ) external {
        //todo: check if token contract supports ERC721 interface?

        uint _protocolFee;
        LibAucDataV1.DataV1 memory aucData = LibAucDataV1.parse(data, dataType);
        require(aucData.duration >= minimalDuration && aucData.duration <= MAX_DURATION, "incorrect duration");
        require(getValueFromData(aucData.originFee) + _protocolFee <= MAX_FEE_BASE_POINT, "wrong fees");

        uint currentAuctionId = getNextAndIncrementAuctionId();
        address payable sender = _msgSender();
        Auction memory auc = Auction(
            _sellToken,
            _sellTokenId,
            _buyAsset,
            0,
            Bid(0, "", ""),
            sender,
            minimalPrice,
            payable(address(0)),
            uint64(_protocolFee),
            dataType,
            data
        );
        auctions[currentAuctionId] = auc;
        transferNFT(
            _sellToken, 
            _sellTokenId, 
            1, 
            LibAsset.ERC721_ASSET_CLASS,
            sender,
            address(this)
        );
        setAuctionForToken(_sellToken, _sellTokenId, currentAuctionId);
        
        emit AuctionCreated(currentAuctionId, sender);
    }

    /// @dev put a bid and return locked assets for the last bid
    function putBid(uint _auctionId, Bid memory bid) payable public nonReentrant {
        address payable newBuyer = _msgSender();
        uint newAmount = bid.amount;
        Auction memory currentAuction = auctions[_auctionId];
        uint96 endTime = currentAuction.endTime;
        LibAucDataV1.DataV1 memory aucData = LibAucDataV1.parse(currentAuction.data, currentAuction.dataType);
        uint bidOriginFee = LibBidDataV1.parse(bid.data, bid.dataType).originFee;
        require(getValueFromData(aucData.originFee) + getValueFromData(bidOriginFee) + currentAuction.protocolFee <= MAX_FEE_BASE_POINT, "wrong fees");

        if (currentAuction.buyAsset == address(0)) {
            checkEthReturnChange(bid.amount, newBuyer);
        }
        checkAuctionInProgress(currentAuction.seller, currentAuction.endTime, aucData.startTime);
        if (buyOutVerify(aucData, newAmount)) {
            _buyOut(
                currentAuction,
                bid,
                aucData,
                _auctionId,
                bidOriginFee,
                newBuyer
            );
            return;
        }
        
        uint96 currentTime = uint96(block.timestamp);
        //start action if minimal price is met
        if (currentAuction.buyer == address(0x0)) {//no bid at all
            // set endTime
            endTime = currentTime.add(aucData.duration);
            auctions[_auctionId].endTime = endTime;
            require(newAmount >= currentAuction.minimalPrice, "bid too small");
        } else {//there is bid in auction
            require(currentAuction.buyer != newBuyer, "already winning bid");
            uint256 minAmount = _getMinimalNextBid(currentAuction.buyer, currentAuction.minimalPrice, currentAuction.lastBid.amount);
            require(newAmount >= minAmount, "bid too low");
        }

        address proxy = _getProxy(currentAuction.buyAsset);
        reserveBid(
            currentAuction.buyAsset,
            currentAuction.buyer,
            newBuyer,
            currentAuction.lastBid,
            proxy,
            bid.amount
        );
        auctions[_auctionId].lastBid = bid;
        auctions[_auctionId].buyer = newBuyer;

        // auction is extended for EXTENSION_DURATION or minimalDuration if (minimalDuration < EXTENSION_DURATION)
        uint96 minDur = minimalDuration;
        uint96 extension = (minDur < EXTENSION_DURATION) ? minDur : EXTENSION_DURATION;

        // extends auction time if it's about to end
        if (endTime.sub(currentTime) < extension) {
            endTime = currentTime.add(extension);
            auctions[_auctionId].endTime = endTime;
        }
        emit BidPlaced(_auctionId, newBuyer, endTime);
    }

    /// @dev returns the minimal amount of the next bid (without fees)
    function getMinimalNextBid(uint _auctionId) external view returns (uint minBid){
        Auction memory currentAuction = auctions[_auctionId];
        return _getMinimalNextBid(currentAuction.buyer, currentAuction.minimalPrice, currentAuction.lastBid.amount);
    }

    /// @dev returns true if auction exists, false otherwise
    function checkAuctionExistence(uint _auctionId) external view returns (bool){
        return _checkAuctionExistence(auctions[_auctionId].seller);
    }

    /// @dev finishes, deletes and transfers all assets for an auction if it's ended (it exists, it has at least one bid, now > endTme)
    function finishAuction(uint _auctionId) external nonReentrant {
        Auction memory currentAuction = auctions[_auctionId];
        require(_checkAuctionExistence(currentAuction.seller), "there is no auction with this id");
        LibAucDataV1.DataV1 memory aucData = LibAucDataV1.parse(currentAuction.data, currentAuction.dataType);
        require(
            !_checkAuctionRangeTime(currentAuction.endTime, aucData.startTime) &&
            currentAuction.buyer != address(0),
            "only ended auction with bid can be finished"
        );
        uint bidOriginFee = LibBidDataV1.parse(currentAuction.lastBid.data, currentAuction.lastBid.dataType).originFee;

        doTransfers(
            LibDeal.DealSide(
                getSellAsset(
                    currentAuction.sellToken, 
                    currentAuction.sellTokenId,
                    1,
                    LibAsset.ERC721_ASSET_CLASS
                ),
                getPayouts(currentAuction.seller),
                getOriginFee(aucData.originFee),
                proxies[LibAsset.ERC721_ASSET_CLASS],
                address(this)
            ), 
            LibDeal.DealSide(
                getBuyAsset(
                    currentAuction.buyAsset,
                    currentAuction.lastBid.amount
                ),
                getPayouts(currentAuction.buyer),
                getOriginFee(bidOriginFee),
                _getProxy(currentAuction.buyAsset),
                address(this)
            ), 
            LibDeal.DealData(
                MAX_FEE_BASE_POINT,
                LibFeeSide.FeeSide.RIGHT
            )
        );
        deactivateAuction(_auctionId, currentAuction.sellToken, currentAuction.sellTokenId);
    }

    /// @dev returns true if auction started and hasn't finished yet, false otherwise
    function checkAuctionRangeTime(uint _auctionId) external view returns (bool){
        return _checkAuctionRangeTime(auctions[_auctionId].endTime, LibAucDataV1.parse(auctions[_auctionId].data, auctions[_auctionId].dataType).startTime);
    }

    /// @dev deletes auction after finalizing
    function deactivateAuction(uint _auctionId, address token, uint tokenId) internal {
        emit AuctionFinished(_auctionId);
        deleteAuctionForToken(token, tokenId);
        delete auctions[_auctionId];
    }

    /// @dev cancels existing auction without bid
    function cancel(uint _auctionId) external nonReentrant {
        Auction memory currentAuction = auctions[_auctionId];
        address seller = currentAuction.seller;
        require(_checkAuctionExistence(seller), "there is no auction with this id");
        require(seller == _msgSender(), "auction owner not detected");
        require(currentAuction.buyer == address(0), "can't cancel auction with bid");
        transferNFT(
            currentAuction.sellToken, 
            currentAuction.sellTokenId, 
            1, 
            LibAsset.ERC721_ASSET_CLASS,
            address(this),
            seller
        );
        deactivateAuction(_auctionId, currentAuction.sellToken, currentAuction.sellTokenId);
        emit AuctionCancelled(_auctionId);
    }

    // todo will there be a problem if buyer is last bidder?
    /// @dev buyout auction if bid satisfies buyout condition
    function buyOut(uint _auctionId, Bid memory bid) external payable nonReentrant {
        Auction memory currentAuction = auctions[_auctionId];
        LibAucDataV1.DataV1 memory aucData = LibAucDataV1.parse(currentAuction.data, currentAuction.dataType);
        checkAuctionInProgress(currentAuction.seller, currentAuction.endTime, aucData.startTime);
        uint bidOriginFee = LibBidDataV1.parse(bid.data, bid.dataType).originFee;

        require(buyOutVerify(aucData, bid.amount), "not enough for buyout");
        require(getValueFromData(aucData.originFee) + getValueFromData(bidOriginFee) + currentAuction.protocolFee <= MAX_FEE_BASE_POINT, "wrong fees");
        
        address sender = _msgSender();
        if (currentAuction.buyAsset == address(0)) {
            checkEthReturnChange(bid.amount, sender);
        }
        _buyOut(
            currentAuction,
            bid,
            aucData,
            _auctionId,
            bidOriginFee,
            sender
        );
    }

    function _buyOut(
        Auction memory currentAuction,
        Bid memory bid,
        LibAucDataV1.DataV1 memory aucData,
        uint _auctionId,
        uint newBidOriginFee,
        address sender
    ) internal {
        address proxy = _getProxy(currentAuction.buyAsset);

        _returnBid(
            currentAuction.lastBid,
            currentAuction.buyAsset,
            currentAuction.buyer,
            proxy
        );

        address from;
        if (currentAuction.buyAsset == address(0)) {
            // if buyAsset = ETH
            from = address(this);
        } else {
            // if buyAsset = ERC20
            from = sender;
        }

        doTransfers(
            LibDeal.DealSide(
                getSellAsset(
                    currentAuction.sellToken, 
                    currentAuction.sellTokenId,
                    1,
                    LibAsset.ERC721_ASSET_CLASS
                ),
                getPayouts(currentAuction.seller),
                getOriginFee(aucData.originFee),
                proxies[LibAsset.ERC721_ASSET_CLASS],
                address(this)
            ), 
            LibDeal.DealSide(
                getBuyAsset(
                    currentAuction.buyAsset,
                    bid.amount
                ),
                getPayouts(sender),
                getOriginFee(newBidOriginFee),
                proxy,
                from
            ), 
            LibDeal.DealData(
                MAX_FEE_BASE_POINT,
                LibFeeSide.FeeSide.RIGHT
            )
        );

        deactivateAuction(_auctionId, currentAuction.sellToken, currentAuction.sellTokenId);
        emit AuctionBuyOut(auctionId, sender);
    }

    /// @dev returns current highest bidder for an auction
    function getCurrentBuyer(uint _auctionId) external view returns(address) {
        return auctions[_auctionId].buyer;
    }

    /// @dev function to call from wrapper to put bid
    function putBidWrapper(uint256 _auctionId) external payable {
        require(auctions[_auctionId].buyAsset == address(0), "only ETH bids allowed");
        putBid(_auctionId, Bid(msg.value, LibBidDataV1.V1, ""));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721ReceiverUpgradeable.sol";
import "../../proxy/Initializable.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}