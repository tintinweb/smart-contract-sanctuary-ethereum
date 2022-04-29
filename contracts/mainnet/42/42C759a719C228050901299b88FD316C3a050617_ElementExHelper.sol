// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../zero-ex/src/features/libs/LibNFTOrder.sol";
import "../zero-ex/src/features/libs/LibSignature.sol";

interface IERC721OrdersFeature {
    function validateERC721SellOrderSignature(LibNFTOrder.NFTSellOrder calldata order, LibSignature.Signature calldata signature) external view;
    function validateERC721BuyOrderSignature(LibNFTOrder.NFTBuyOrder calldata order, LibSignature.Signature calldata signature) external view;
    function getERC721SellOrderHash(LibNFTOrder.NFTSellOrder calldata order) external view returns (bytes32);
    function getERC721BuyOrderHash(LibNFTOrder.NFTBuyOrder calldata order) external view returns (bytes32);
    function getERC721OrderStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
    function getHashNonce(address maker) external view returns (uint256);
}

interface IERC1155OrdersFeature {
    function validateERC1155SellOrderSignature(LibNFTOrder.ERC1155SellOrder calldata order, LibSignature.Signature calldata signature) external view;
    function validateERC1155BuyOrderSignature(LibNFTOrder.ERC1155BuyOrder calldata order, LibSignature.Signature calldata signature) external view;
    function getERC1155SellOrderInfo(LibNFTOrder.ERC1155SellOrder calldata order) external view returns (LibNFTOrder.OrderInfo memory orderInfo);
    function getERC1155BuyOrderInfo(LibNFTOrder.ERC1155BuyOrder calldata order) external view returns (LibNFTOrder.OrderInfo memory orderInfo);
    function getERC1155OrderNonceStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
}

contract ElementExHelper {

    struct ERC20CheckInfo {
        uint256 balance;
        uint256 allowance;
        bool balanceCheck;          // check `balance >= erc20TotalAmount`
        bool allowanceCheck;        // check `allowance >= erc20TotalAmount`
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    struct ERC721CheckInfo {
        bool ecr721TokenIdCheck;
        bool erc721OwnerCheck;
        bool erc721ApprovedCheck;
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    struct ERC721SellOrderCheckInfo {
        bool success;
        uint256 hashNonce;
        bytes32 orderHash;
        bool makerCheck;
        bool takerCheck;
        bool listingTimeCheck;
        bool expireTimeCheck;
        bool extraCheck;
        bool nonceCheck;
        bool feesCheck;
        bool erc20AddressCheck;
        bool erc721AddressCheck;
        bool erc721OwnerCheck;
        bool erc721ApprovedCheck;
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
    }

    struct ERC721BuyOrderCheckInfo {
        bool success;
        uint256 hashNonce;
        bytes32 orderHash;
        bool makerCheck;
        bool takerCheck;
        bool listingTimeCheck;
        bool expireTimeCheck;
        bool nonceCheck;
        bool feesCheck;
        bool propertiesCheck;
        bool erc20AddressCheck;
        bool erc721AddressCheck;
        uint256 erc20TotalAmount;
        uint256 erc20Balance;
        uint256 erc20Allowance;
        bool erc20BalanceCheck;
        bool erc20AllowanceCheck;
    }

    struct ERC1155SellOrderCheckInfo {
        bool success;
        uint256 hashNonce;
        bytes32 orderHash;
        uint256 erc1155RemainingAmount;
        uint256 erc1155Balance;     // erc1155.balanceOf(order.maker, order.erc1155TokenId)
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool extraCheck;
        bool nonceCheck;
        bool remainingAmountCheck;
        bool feesCheck;
        bool erc20AddressCheck;
        bool erc1155AddressCheck;
        bool erc1155BalanceCheck;   // check `erc1155Balance >= order.erc1155TokenAmount
        bool erc1155ApprovedCheck;  // check `erc1155.isApprovedForAll(order.maker, elementEx)`
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
    }

    struct ERC1155SellOrderTakerCheckInfo {
        uint256 erc20Balance;
        uint256 erc20Allowance;
        uint256 erc20WillPayAmount;
        bool balanceCheck;          // check `erc20Balance >= erc20WillPayAmount
        bool allowanceCheck;        // check `erc20Allowance >= erc20WillPayAmount
        bool buyAmountCheck;        // check `erc1155BuyAmount <= erc1155RemainingAmount`
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    struct ERC1155BuyOrderCheckInfo {
        bool success;
        uint256 hashNonce;
        bytes32 orderHash;
        uint256 erc1155RemainingAmount;
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool nonceCheck;
        bool remainingAmountCheck;  // check `erc1155RemainingAmount > 0`
        bool feesCheck;
        bool propertiesCheck;
        bool erc20AddressCheck;
        bool erc1155AddressCheck;
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
        uint256 erc20Balance;
        uint256 erc20Allowance;
        bool erc20BalanceCheck;     // check `erc20Balance >= erc20TotalAmount`
        bool erc20AllowanceCheck;   // check `erc20AllowanceCheck >= erc20TotalAmount`
    }

    struct ERC1155BuyOrderTakerCheckInfo {
        uint256 erc1155Balance;     // erc1155.balanceOf(taker, erc1155TokenId)
        bool ecr1155TokenIdCheck;
        bool erc1155BalanceCheck;   // check `erc1155SellAmount <= erc1155Balance`
        bool erc1155ApprovedCheck;  // check `erc1155.isApprovedForAll(taker, elementEx)`
        bool sellAmountCheck;       // check `erc1155SellAmount <= erc1155RemainingAmount`
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    using Address for address;

    address constant internal NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable ELEMENT_EX;
    address public immutable WETH;

    constructor(address elementEx, address weth) {
        ELEMENT_EX = elementEx;
        WETH = weth;
    }

    function checkERC721SellOrder(LibNFTOrder.NFTSellOrder calldata order, address taker)
        public
        view
        returns (ERC721SellOrderCheckInfo memory info, ERC20CheckInfo memory takerCheckInfo)
    {
        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = getERC721SellOrderHash(order);
        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.extraCheck = checkExtra(order.expiry);
        info.nonceCheck = !isERC721OrderNonceFilled(order.maker, order.nonce);
        info.feesCheck = checkFees(order.fees);
        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);
        info.erc721OwnerCheck = checkERC721Owner(order.nft, order.nftId, order.maker);
        info.erc721ApprovedCheck = checkERC721Approved(order.nft, order.nftId, order.maker);
        info.erc20AddressCheck = checkERC20Address(true, address(order.erc20Token));
        info.erc721AddressCheck = checkERC721Address(order.nft);
        info.success = _isERC721SellOrderSuccess(info);

        if (taker != address(0)) {
            takerCheckInfo.listingTimeCheck = (block.timestamp >= ((order.expiry >> 32) & 0xffffffff));
            takerCheckInfo.takerCheck = (order.taker == taker || order.taker == address(0));
            (takerCheckInfo.balanceCheck, takerCheckInfo.balance) =
                checkERC20Balance(true, taker, address(order.erc20Token), info.erc20TotalAmount);
            (takerCheckInfo.allowanceCheck, takerCheckInfo.allowance) =
                checkERC20Allowance(true, taker, address(order.erc20Token), info.erc20TotalAmount);
        }
        return (info, takerCheckInfo);
    }

    function checkERC721SellOrderEx(
        LibNFTOrder.NFTSellOrder calldata order,
        address taker,
        LibSignature.Signature calldata signature
    )
        public
        view
        returns (ERC721SellOrderCheckInfo memory info, ERC20CheckInfo memory takerCheckInfo, bool validSignature)
    {
        (info, takerCheckInfo) = checkERC721SellOrder(order, taker);
        validSignature = validateERC721SellOrderSignature(order, signature);
        return (info, takerCheckInfo, validSignature);
    }

    function checkERC721BuyOrder(LibNFTOrder.NFTBuyOrder calldata order, address taker, uint256 erc721TokenId)
        public
        view
        returns (ERC721BuyOrderCheckInfo memory info, ERC721CheckInfo memory takerCheckInfo)
    {
        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = getERC721BuyOrderHash(order);
        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.nonceCheck = !isERC721OrderNonceFilled(order.maker, order.nonce);
        info.feesCheck = checkFees(order.fees);
        info.propertiesCheck = checkProperties(order.nftProperties, order.nftId);
        info.erc20AddressCheck = checkERC20Address(false, address(order.erc20Token));
        info.erc721AddressCheck = checkERC721Address(order.nft);

        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);
        (info.erc20BalanceCheck, info.erc20Balance) =
            checkERC20Balance(false, order.maker, address(order.erc20Token), info.erc20TotalAmount);
        (info.erc20AllowanceCheck, info.erc20Allowance) =
            checkERC20Allowance(false, order.maker, address(order.erc20Token), info.erc20TotalAmount);
        info.success = _isERC721BuyOrderSuccess(info);

        if (taker != address(0)) {
            takerCheckInfo.listingTimeCheck = (block.timestamp >= ((order.expiry >> 32) & 0xffffffff));
            takerCheckInfo.takerCheck = (order.taker == taker || order.taker == address(0));
            takerCheckInfo.ecr721TokenIdCheck = checkNftIdIsMatched(order.nftProperties, order.nft, order.nftId, erc721TokenId);
            takerCheckInfo.erc721OwnerCheck = checkERC721Owner(order.nft, erc721TokenId, taker);
            takerCheckInfo.erc721ApprovedCheck = checkERC721Approved(order.nft, erc721TokenId, taker);
        }
        return (info, takerCheckInfo);
    }

    function checkERC721BuyOrderEx(
        LibNFTOrder.NFTBuyOrder calldata order,
        address taker,
        uint256 erc721TokenId,
        LibSignature.Signature calldata signature
    )
        public
        view
        returns (ERC721BuyOrderCheckInfo memory info, ERC721CheckInfo memory takerCheckInfo, bool validSignature)
    {
        (info, takerCheckInfo) = checkERC721BuyOrder(order, taker, erc721TokenId);
        validSignature = validateERC721BuyOrderSignature(order, signature);
        return (info, takerCheckInfo, validSignature);
    }

    function checkERC1155SellOrder(LibNFTOrder.ERC1155SellOrder calldata order, address taker, uint128 erc1155BuyAmount)
        public
        view
        returns (ERC1155SellOrderCheckInfo memory info, ERC1155SellOrderTakerCheckInfo memory takerCheckInfo)
    {
        LibNFTOrder.OrderInfo memory orderInfo = getERC1155SellOrderInfo(order);
        (uint256 balance, bool isApprovedForAll) = getERC1155Info(order.erc1155Token, order.erc1155TokenId, order.maker, ELEMENT_EX);

        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = orderInfo.orderHash;
        info.erc1155RemainingAmount = orderInfo.remainingAmount;
        info.erc1155Balance = balance;
        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.extraCheck = checkExtra(order.expiry);
        info.nonceCheck = !isERC1155OrderNonceCancelled(order.maker, order.nonce);
        info.remainingAmountCheck = (info.erc1155RemainingAmount > 0);
        info.feesCheck = checkFees(order.fees);
        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);
        info.erc1155BalanceCheck = (balance >= order.erc1155TokenAmount);
        info.erc1155ApprovedCheck = isApprovedForAll;
        info.erc20AddressCheck = checkERC20Address(true, address(order.erc20Token));
        info.erc1155AddressCheck = checkERC1155Address(order.erc1155Token);
        info.success = _isERC1155SellOrderSuccess(info);

        if (taker != address(0)) {
            if (order.erc1155TokenAmount > 0) {
                takerCheckInfo.erc20WillPayAmount = _ceilDiv(order.erc20TokenAmount * erc1155BuyAmount, order.erc1155TokenAmount);
                for (uint256 i = 0; i < order.fees.length; i++) {
                    takerCheckInfo.erc20WillPayAmount += order.fees[i].amount * erc1155BuyAmount / order.erc1155TokenAmount;
                }
            } else {
                takerCheckInfo.erc20WillPayAmount = type(uint128).max;
            }
            (takerCheckInfo.balanceCheck, takerCheckInfo.erc20Balance) = checkERC20Balance(true, taker, address(order.erc20Token), takerCheckInfo.erc20WillPayAmount);
            (takerCheckInfo.allowanceCheck, takerCheckInfo.erc20Allowance) = checkERC20Allowance(true, taker, address(order.erc20Token), takerCheckInfo.erc20WillPayAmount);
            takerCheckInfo.buyAmountCheck = (erc1155BuyAmount <= info.erc1155RemainingAmount);
            takerCheckInfo.listingTimeCheck = (block.timestamp >= ((order.expiry >> 32) & 0xffffffff));
            takerCheckInfo.takerCheck = (order.taker == taker || order.taker == address(0));
        }
        return (info, takerCheckInfo);
    }

    function checkERC1155SellOrderEx(
        LibNFTOrder.ERC1155SellOrder calldata order,
        address taker,
        uint128 erc1155BuyAmount,
        LibSignature.Signature calldata signature
    )
        public
        view
        returns (ERC1155SellOrderCheckInfo memory info, ERC1155SellOrderTakerCheckInfo memory takerCheckInfo, bool validSignature)
    {
        (info, takerCheckInfo) = checkERC1155SellOrder(order, taker, erc1155BuyAmount);
        validSignature = validateERC1155SellOrderSignature(order, signature);
        return (info, takerCheckInfo, validSignature);
    }

    function checkERC1155BuyOrder(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount
    )
        public
        view
        returns (ERC1155BuyOrderCheckInfo memory info, ERC1155BuyOrderTakerCheckInfo memory takerCheckInfo)
    {
        LibNFTOrder.OrderInfo memory orderInfo = getERC1155BuyOrderInfo(order);
        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = orderInfo.orderHash;
        info.erc1155RemainingAmount = orderInfo.remainingAmount;
        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.nonceCheck = !isERC1155OrderNonceCancelled(order.maker, order.nonce);
        info.remainingAmountCheck = (info.erc1155RemainingAmount > 0);
        info.feesCheck = checkFees(order.fees);
        info.propertiesCheck = checkProperties(order.erc1155TokenProperties, order.erc1155TokenId);
        info.erc20AddressCheck = checkERC20Address(false, address(order.erc20Token));
        info.erc1155AddressCheck = checkERC1155Address(order.erc1155Token);
        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);
        (info.erc20BalanceCheck, info.erc20Balance) = checkERC20Balance(false, order.maker, address(order.erc20Token), info.erc20TotalAmount);
        (info.erc20AllowanceCheck, info.erc20Allowance) = checkERC20Allowance(false, order.maker, address(order.erc20Token), info.erc20TotalAmount);
        info.success = _isERC1155BuyOrderSuccess(info);

        if (taker != address(0)) {
            takerCheckInfo.ecr1155TokenIdCheck = checkNftIdIsMatched(order.erc1155TokenProperties, order.erc1155Token, order.erc1155TokenId, erc1155TokenId);
            (takerCheckInfo.erc1155Balance, takerCheckInfo.erc1155ApprovedCheck) = getERC1155Info(order.erc1155Token, erc1155TokenId, taker, ELEMENT_EX);
            takerCheckInfo.erc1155BalanceCheck = (erc1155SellAmount <= takerCheckInfo.erc1155Balance);
            takerCheckInfo.sellAmountCheck = (erc1155SellAmount <= info.erc1155RemainingAmount);
            takerCheckInfo.listingTimeCheck = (block.timestamp >= ((order.expiry >> 32) & 0xffffffff));
            takerCheckInfo.takerCheck = (order.taker == taker || order.taker == address(0));
        }
        return (info, takerCheckInfo);
    }

    function checkERC1155BuyOrderEx(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        LibSignature.Signature calldata signature
    )
        public
        view
        returns (ERC1155BuyOrderCheckInfo memory info, ERC1155BuyOrderTakerCheckInfo memory takerCheckInfo, bool validSignature)
    {
        (info, takerCheckInfo) = checkERC1155BuyOrder(order, taker, erc1155TokenId, erc1155SellAmount);
        validSignature = validateERC1155BuyOrderSignature(order, signature);
        return (info, takerCheckInfo, validSignature);
    }

    function getERC20Info(address erc20, address account, address allowanceAddress)
        public
        view
        returns (uint256 balance, uint256 allowance)
    {
        if (erc20 == address(0) || erc20 == NATIVE_TOKEN_ADDRESS) {
            balance = address(account).balance;
        } else {
            try IERC20(erc20).balanceOf(account) returns (uint256 _balance) {
                balance = _balance;
            } catch {}
            try IERC20(erc20).allowance(account, allowanceAddress) returns (uint256 _allowance) {
                allowance = _allowance;
            } catch {}
        }
        return (balance, allowance);
    }

    function getERC721Info(address erc721, uint256 tokenId, address account, address approvedAddress)
        public
        view
        returns (address owner, bool isApprovedForAll, address approvedAccount)
    {
        try IERC721(erc721).ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {}
        try IERC721(erc721).isApprovedForAll(account, approvedAddress) returns (bool _isApprovedForAll) {
            isApprovedForAll = _isApprovedForAll;
        } catch {}
        try IERC721(erc721).getApproved(tokenId) returns (address _account) {
            approvedAccount = _account;
        } catch {}
        return (owner, isApprovedForAll, approvedAccount);
    }

    function getERC1155Info(address erc1155, uint256 tokenId, address account, address approvedAddress)
        public
        view
        returns (uint256 balance, bool isApprovedForAll)
    {
        try IERC1155(erc1155).balanceOf(account, tokenId) returns (uint256 _balance) {
            balance = _balance;
        } catch {}
        try IERC1155(erc1155).isApprovedForAll(account, approvedAddress) returns (bool _isApprovedForAll) {
            isApprovedForAll = _isApprovedForAll;
        } catch {}
        return (balance, isApprovedForAll);
    }

    function validateERC721SellOrderSignature(LibNFTOrder.NFTSellOrder calldata order, LibSignature.Signature calldata signature)
        public
        view
        returns (bool valid)
    {
        try IERC721OrdersFeature(ELEMENT_EX).validateERC721SellOrderSignature(order, signature) {
            return true;
        } catch {}
        return false;
    }

    function validateERC721BuyOrderSignature(LibNFTOrder.NFTBuyOrder calldata order, LibSignature.Signature calldata signature)
        public
        view
        returns (bool valid)
    {
        try IERC721OrdersFeature(ELEMENT_EX).validateERC721BuyOrderSignature(order, signature) {
            return true;
        } catch {}
        return false;
    }

    function getERC721SellOrderHash(LibNFTOrder.NFTSellOrder calldata order) public view returns (bytes32) {
        try IERC721OrdersFeature(ELEMENT_EX).getERC721SellOrderHash(order) returns (bytes32 orderHash) {
            return orderHash;
        } catch {}
        return bytes32("");
    }

    function getERC721BuyOrderHash(LibNFTOrder.NFTBuyOrder calldata order) public view returns (bytes32) {
        try IERC721OrdersFeature(ELEMENT_EX).getERC721BuyOrderHash(order) returns (bytes32 orderHash) {
            return orderHash;
        } catch {}
        return bytes32("");
    }

    function isERC721OrderNonceFilled(address account, uint256 nonce) public view returns (bool filled) {
        uint256 bitVector = IERC721OrdersFeature(ELEMENT_EX).getERC721OrderStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) != 0;
    }

    function isERC1155OrderNonceCancelled(address account, uint256 nonce) public view returns (bool filled) {
        uint256 bitVector = IERC1155OrdersFeature(ELEMENT_EX).getERC1155OrderNonceStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) != 0;
    }

    function getHashNonce(address maker) public view returns (uint256) {
        return IERC721OrdersFeature(ELEMENT_EX).getHashNonce(maker);
    }

    function getERC1155SellOrderInfo(LibNFTOrder.ERC1155SellOrder calldata order)
        public
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo)
    {
        try IERC1155OrdersFeature(ELEMENT_EX).getERC1155SellOrderInfo(order) returns (LibNFTOrder.OrderInfo memory _orderInfo) {
            orderInfo = _orderInfo;
        } catch {}
        return orderInfo;
    }

    function getERC1155BuyOrderInfo(LibNFTOrder.ERC1155BuyOrder calldata order)
        public
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo)
    {
        try IERC1155OrdersFeature(ELEMENT_EX).getERC1155BuyOrderInfo(order) returns (LibNFTOrder.OrderInfo memory _orderInfo) {
            orderInfo = _orderInfo;
        } catch {}
        return orderInfo;
    }

    function validateERC1155SellOrderSignature(LibNFTOrder.ERC1155SellOrder calldata order, LibSignature.Signature calldata signature)
        public
        view
        returns (bool valid)
    {
        try IERC1155OrdersFeature(ELEMENT_EX).validateERC1155SellOrderSignature(order, signature) {
            return true;
        } catch {}
        return false;
    }

    function validateERC1155BuyOrderSignature(LibNFTOrder.ERC1155BuyOrder calldata order, LibSignature.Signature calldata signature)
        public
        view
        returns (bool valid)
    {
        try IERC1155OrdersFeature(ELEMENT_EX).validateERC1155BuyOrderSignature(order, signature) {
            return true;
        } catch {}
        return false;
    }

    function _isERC721SellOrderSuccess(ERC721SellOrderCheckInfo memory info) private pure returns (bool successAll) {
        return info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.extraCheck &&
            info.nonceCheck &&
            info.feesCheck &&
            info.erc721OwnerCheck &&
            info.erc721ApprovedCheck &&
            info.erc20AddressCheck &&
            info.erc721AddressCheck;
    }

    function _isERC721BuyOrderSuccess(ERC721BuyOrderCheckInfo memory info) private pure returns (bool successAll) {
        return info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.nonceCheck &&
            info.feesCheck &&
            info.propertiesCheck &&
            info.erc20BalanceCheck &&
            info.erc20AllowanceCheck &&
            info.erc20AddressCheck &&
            info.erc721AddressCheck;
    }

    function _isERC1155SellOrderSuccess(ERC1155SellOrderCheckInfo memory info) private pure returns (bool successAll) {
        return info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.extraCheck &&
            info.nonceCheck &&
            info.remainingAmountCheck &&
            info.feesCheck &&
            info.erc20AddressCheck &&
            info.erc1155AddressCheck &&
            info.erc1155BalanceCheck &&
            info.erc1155ApprovedCheck;
    }

    function _isERC1155BuyOrderSuccess(ERC1155BuyOrderCheckInfo memory info) private pure returns (bool successAll) {
        return info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.nonceCheck &&
            info.remainingAmountCheck &&
            info.feesCheck &&
            info.propertiesCheck &&
            info.erc20AddressCheck &&
            info.erc1155AddressCheck &&
            info.erc20BalanceCheck &&
            info.erc20AllowanceCheck;
    }

    function checkListingTime(uint256 expiry) internal pure returns (bool success) {
        uint256 listingTime = (expiry >> 32) & 0xffffffff;
        uint256 expiryTime = expiry & 0xffffffff;
        return listingTime < expiryTime;
    }

    function checkExpiryTime(uint256 expiry) internal view returns (bool success) {
        uint256 expiryTime = expiry & 0xffffffff;
        return expiryTime > block.timestamp;
    }

    function checkExtra(uint256 expiry) internal pure returns (bool success) {
        if (expiry >> 252 == 1) {
            uint256 extra = (expiry >> 64) & 0xffffffff;
            return (extra <= 100000000);
        }
        return true;
    }

    function checkERC721Owner(address nft, uint256 nftId, address owner) internal view returns (bool success) {
        try IERC721(nft).ownerOf(nftId) returns (address _owner) {
            success = (owner == _owner);
        } catch {
            success = false;
        }
        return success;
    }

    function checkERC721Approved(address nft, uint256 nftId, address owner) internal view returns (bool) {
        try IERC721(nft).isApprovedForAll(owner, ELEMENT_EX) returns (bool approved) {
            if (approved) {
                return true;
            }
        } catch {
        }
        try IERC721(nft).getApproved(nftId) returns (address account) {
            return (account == ELEMENT_EX);
        } catch {
        }
        return false;
    }

    function checkERC20Balance(bool buyNft, address buyer, address erc20, uint256 erc20TotalAmount)
        internal
        view
        returns
        (bool success, uint256 balance)
    {
        if (erc20 == address(0)) {
            return (false, 0);
        }
        if (erc20 == NATIVE_TOKEN_ADDRESS) {
            if (buyNft) {
                balance = buyer.balance;
                success = (balance >= erc20TotalAmount);
                return (success, balance);
            } else {
                return (false, 0);
            }
        }

        try IERC20(erc20).balanceOf(buyer) returns (uint256 _balance) {
            balance = _balance;
            success = (balance >= erc20TotalAmount);
        } catch {
            success = false;
            balance = 0;
        }
        return (success, balance);
    }

    function checkERC20Allowance(bool buyNft, address buyer, address erc20, uint256 erc20TotalAmount)
        internal
        view
        returns
        (bool success, uint256 allowance)
    {
        if (erc20 == address(0)) {
            return (false, 0);
        }
        if (erc20 == NATIVE_TOKEN_ADDRESS) {
            return (buyNft, 0);
        }

        try IERC20(erc20).allowance(buyer, ELEMENT_EX) returns (uint256 _allowance) {
            allowance = _allowance;
            success = (allowance >= erc20TotalAmount);
        } catch {
            success = false;
            allowance = 0;
        }
        return (success, allowance);
    }

    function checkERC20Address(bool sellOrder, address erc20) internal view returns (bool) {
        if (erc20 == address(0)) {
            return false;
        }
        if (erc20 == NATIVE_TOKEN_ADDRESS) {
            return sellOrder;
        }
        return erc20.isContract();
    }

    function checkERC721Address(address erc721) internal view returns (bool) {
        if (erc721 == address(0) || erc721 == NATIVE_TOKEN_ADDRESS) {
            return false;
        }

        try IERC165(erc721).supportsInterface(type(IERC721).interfaceId) returns (bool support) {
            return support;
        } catch {}
        return false;
    }

    function checkERC1155Address(address erc1155) internal view returns (bool) {
        if (erc1155 == address(0) || erc1155 == NATIVE_TOKEN_ADDRESS) {
            return false;
        }

        try IERC165(erc1155).supportsInterface(type(IERC1155).interfaceId) returns (bool support) {
            return support;
        } catch {}
        return false;
    }

    function checkFees(LibNFTOrder.Fee[] calldata fees) internal view returns (bool success) {
        for (uint256 i = 0; i < fees.length; i++) {
            if (fees[i].recipient == ELEMENT_EX) {
                return false;
            }
            if (fees[i].feeData.length > 0 && !fees[i].recipient.isContract()) {
                return false;
            }
        }
        return true;
    }

    function checkProperties(LibNFTOrder.Property[] calldata properties, uint256 nftId) internal view returns (bool success) {
        if (properties.length > 0) {
            if (nftId != 0) {
                return false;
            }
            for (uint256 i = 0; i < properties.length; i++) {
                address propertyValidator = address(properties[i].propertyValidator);
                if (propertyValidator != address(0) && !propertyValidator.isContract()) {
                    return false;
                }
            }
        }
        return true;
    }

    function checkNftIdIsMatched(LibNFTOrder.Property[] calldata properties, address nft, uint256 orderNftId, uint256 nftId)
        internal
        view
        returns (bool isMatched)
    {
        if (properties.length == 0) {
            return orderNftId == nftId;
        }
        for (uint256 i = 0; i < properties.length; i++) {
            LibNFTOrder.Property memory property = properties[i];
            if (address(property.propertyValidator) != address(0)) {
                try property.propertyValidator.validateProperty(nft, nftId, property.propertyData) {
                } catch {
                    return false;
                }
            }
        }
        return true;
    }

    function calcERC20TotalAmount(uint256 erc20TokenAmount, LibNFTOrder.Fee[] calldata fees) internal pure returns (uint256) {
        uint256 sum = erc20TokenAmount;
        for (uint256 i = 0; i < fees.length; i++) {
            sum += fees[i].amount;
        }
        return sum;
    }

    function _ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // ceil(a / b) = floor((a + b - 1) / b)
        return (a + b - 1) / b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../vendor/IPropertyValidator.sol";


/// @dev A library for common NFT order operations.
library LibNFTOrder {

    enum OrderStatus {
        INVALID,
        FILLABLE,
        UNFILLABLE,
        EXPIRED
    }

    struct Property {
        IPropertyValidator propertyValidator;
        bytes propertyData;
    }

    struct Fee {
        address recipient;
        uint256 amount;
        bytes feeData;
    }

    struct NFTSellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
    }

    // All fields except `nftProperties` align
    // with those of NFTSellOrder
    struct NFTBuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
        Property[] nftProperties;
    }

    // All fields except `erc1155TokenAmount` align
    // with those of NFTSellOrder
    struct ERC1155SellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    // All fields except `erc1155TokenAmount` align
    // with those of NFTBuyOrder
    struct ERC1155BuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        Property[] erc1155TokenProperties;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    struct OrderInfo {
        bytes32 orderHash;
        OrderStatus status;
        // `orderAmount` is 1 for all ERC721Orders, and
        // `erc1155TokenAmount` for ERC1155Orders.
        uint128 orderAmount;
        // The remaining amount of the ERC721/ERC1155 asset
        // that can be filled for the order.
        uint128 remainingAmount;
    }

    // The type hash for sell orders, which is:
    // keccak256(abi.encodePacked(
    //    "NFTSellOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address nft,",
    //        "uint256 nftId,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")"
    // ))
    uint256 private constant _NFT_SELL_ORDER_TYPE_HASH = 0xed676c7f3e8232a311454799b1cf26e75b4abc90c9bf06c9f7e8e79fcc7fe14d;

    // The type hash for buy orders, which is:
    // keccak256(abi.encodePacked(
    //    "NFTBuyOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address nft,",
    //        "uint256 nftId,",
    //        "Property[] nftProperties,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")",
    //    "Property(",
    //        "address propertyValidator,",
    //        "bytes propertyData",
    //    ")"
    // ))
    uint256 private constant _NFT_BUY_ORDER_TYPE_HASH = 0xa525d336300f566329800fcbe82fd263226dc27d6c109f060d9a4a364281521c;

    // The type hash for ERC1155 sell orders, which is:
    // keccak256(abi.encodePacked(
    //    "ERC1155SellOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address erc1155Token,",
    //        "uint256 erc1155TokenId,",
    //        "uint128 erc1155TokenAmount,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")"
    // ))
    uint256 private constant _ERC_1155_SELL_ORDER_TYPE_HASH = 0x3529b5920cc48ecbceb24e9c51dccb50fefd8db2cf05d36e356aeb1754e19eda;

    // The type hash for ERC1155 buy orders, which is:
    // keccak256(abi.encodePacked(
    //    "ERC1155BuyOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 expiry,",
    //        "uint256 nonce,",
    //        "address erc20Token,",
    //        "uint256 erc20TokenAmount,",
    //        "Fee[] fees,",
    //        "address erc1155Token,",
    //        "uint256 erc1155TokenId,",
    //        "Property[] erc1155TokenProperties,",
    //        "uint128 erc1155TokenAmount,",
    //        "uint256 hashNonce",
    //    ")",
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")",
    //    "Property(",
    //        "address propertyValidator,",
    //        "bytes propertyData",
    //    ")"
    // ))
    uint256 private constant _ERC_1155_BUY_ORDER_TYPE_HASH = 0x1a6eaae1fbed341e0974212ec17f035a9d419cadc3bf5154841cbf7fd605ba48;

    // keccak256(abi.encodePacked(
    //    "Fee(",
    //        "address recipient,",
    //        "uint256 amount,",
    //        "bytes feeData",
    //    ")"
    // ))
    uint256 private constant _FEE_TYPE_HASH = 0xe68c29f1b4e8cce0bbcac76eb1334bdc1dc1f293a517c90e9e532340e1e94115;

    // keccak256(abi.encodePacked(
    //    "Property(",
    //        "address propertyValidator,",
    //        "bytes propertyData",
    //    ")"
    // ))
    uint256 private constant _PROPERTY_TYPE_HASH = 0x6292cf854241cb36887e639065eca63b3af9f7f70270cebeda4c29b6d3bc65e8;

    // keccak256("");
    bytes32 private constant _EMPTY_ARRAY_KECCAK256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // keccak256(abi.encodePacked(keccak256(abi.encode(
    //    _PROPERTY_TYPE_HASH,
    //    address(0),
    //    keccak256("")
    // ))));
    bytes32 private constant _NULL_PROPERTY_STRUCT_HASH = 0x720ee400a9024f6a49768142c339bf09d2dd9056ab52d20fbe7165faba6e142d;

    uint256 private constant ADDRESS_MASK = (1 << 160) - 1;

    function asNFTSellOrder(NFTBuyOrder memory nftBuyOrder) internal pure returns (NFTSellOrder memory order) {
        assembly { order := nftBuyOrder }
    }

    function asNFTSellOrder(ERC1155SellOrder memory erc1155SellOrder) internal pure returns (NFTSellOrder memory order) {
        assembly { order := erc1155SellOrder }
    }

    function asNFTBuyOrder(ERC1155BuyOrder memory erc1155BuyOrder) internal pure returns (NFTBuyOrder memory order) {
        assembly { order := erc1155BuyOrder }
    }

    function asERC1155SellOrder(NFTSellOrder memory nftSellOrder) internal pure returns (ERC1155SellOrder memory order) {
        assembly { order := nftSellOrder }
    }

    function asERC1155BuyOrder(NFTBuyOrder memory nftBuyOrder) internal pure returns (ERC1155BuyOrder memory order) {
        assembly { order := nftBuyOrder }
    }

    // @dev Get the struct hash of an sell order.
    /// @param order The sell order.
    /// @return structHash The struct hash of the order.
    function getNFTSellOrderStructHash(NFTSellOrder memory order, uint256 hashNonce) internal pure returns (bytes32 structHash) {
        bytes32 feesHash = _feesHash(order.fees);

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _NFT_SELL_ORDER_TYPE_HASH,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.nft,
        //     order.nftId,
        //     hashNonce
        // ));
        assembly {
            if lt(order, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 192) // order + (32 * 6)
            let hashNoncePos := add(order, 288) // order + (32 * 9)

            let typeHashMemBefore := mload(typeHashPos)
            let feeHashMemBefore := mload(feesHashPos)
            let hashNonceMemBefore := mload(hashNoncePos)

            mstore(typeHashPos, _NFT_SELL_ORDER_TYPE_HASH)
            mstore(feesHashPos, feesHash)
            mstore(hashNoncePos, hashNonce)
            structHash := keccak256(typeHashPos, 352 /* 32 * 11 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feeHashMemBefore)
            mstore(hashNoncePos, hashNonceMemBefore)
        }
        return structHash;
    }

    /// @dev Get the struct hash of an buy order.
    /// @param order The buy order.
    /// @return structHash The struct hash of the order.
    function getNFTBuyOrderStructHash(NFTBuyOrder memory order, uint256 hashNonce) internal pure returns (bytes32 structHash) {
        bytes32 propertiesHash = _propertiesHash(order.nftProperties);
        bytes32 feesHash = _feesHash(order.fees);

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _NFT_BUY_ORDER_TYPE_HASH,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.nft,
        //     order.nftId,
        //     propertiesHash,
        //     hashNonce
        // ));
        assembly {
            if lt(order, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 192) // order + (32 * 6)
            let propertiesHashPos := add(order, 288) // order + (32 * 9)
            let hashNoncePos := add(order, 320) // order + (32 * 10)

            let typeHashMemBefore := mload(typeHashPos)
            let feeHashMemBefore := mload(feesHashPos)
            let propertiesHashMemBefore := mload(propertiesHashPos)
            let hashNonceMemBefore := mload(hashNoncePos)

            mstore(typeHashPos, _NFT_BUY_ORDER_TYPE_HASH)
            mstore(feesHashPos, feesHash)
            mstore(propertiesHashPos, propertiesHash)
            mstore(hashNoncePos, hashNonce)
            structHash := keccak256(typeHashPos, 384 /* 32 * 12 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feeHashMemBefore)
            mstore(propertiesHashPos, propertiesHashMemBefore)
            mstore(hashNoncePos, hashNonceMemBefore)
        }
        return structHash;
    }

    /// @dev Get the struct hash of an ERC1155 sell order.
    /// @param order The ERC1155 sell order.
    /// @return structHash The struct hash of the order.
    function getERC1155SellOrderStructHash(ERC1155SellOrder memory order, uint256 hashNonce) internal pure returns (bytes32 structHash) {
        bytes32 feesHash = _feesHash(order.fees);

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _ERC_1155_SELL_ORDER_TYPE_HASH,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.erc1155Token,
        //     order.erc1155TokenId,
        //     order.erc1155TokenAmount,
        //     hashNonce
        // ));
        assembly {
            if lt(order, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 192) // order + (32 * 6)
            let hashNoncePos := add(order, 320) // order + (32 * 10)

            let typeHashMemBefore := mload(typeHashPos)
            let feesHashMemBefore := mload(feesHashPos)
            let hashNonceMemBefore := mload(hashNoncePos)

            mstore(typeHashPos, _ERC_1155_SELL_ORDER_TYPE_HASH)
            mstore(feesHashPos, feesHash)
            mstore(hashNoncePos, hashNonce)
            structHash := keccak256(typeHashPos, 384 /* 32 * 12 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feesHashMemBefore)
            mstore(hashNoncePos, hashNonceMemBefore)
        }
        return structHash;
    }

    /// @dev Get the struct hash of an ERC1155 buy order.
    /// @param order The ERC1155 buy order.
    /// @return structHash The struct hash of the order.
    function getERC1155BuyOrderStructHash(ERC1155BuyOrder memory order, uint256 hashNonce) internal pure returns (bytes32 structHash) {
        bytes32 propertiesHash = _propertiesHash(order.erc1155TokenProperties);
        bytes32 feesHash = _feesHash(order.fees);

        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _ERC_1155_BUY_ORDER_TYPE_HASH,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.erc1155Token,
        //     order.erc1155TokenId,
        //     propertiesHash,
        //     order.erc1155TokenAmount,
        //     hashNonce
        // ));
        assembly {
            if lt(order, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let feesHashPos := add(order, 192) // order + (32 * 6)
            let propertiesHashPos := add(order, 288) // order + (32 * 9)
            let hashNoncePos := add(order, 352) // order + (32 * 11)

            let typeHashMemBefore := mload(typeHashPos)
            let feesHashMemBefore := mload(feesHashPos)
            let propertiesHashMemBefore := mload(propertiesHashPos)
            let hashNonceMemBefore := mload(hashNoncePos)

            mstore(typeHashPos, _ERC_1155_BUY_ORDER_TYPE_HASH)
            mstore(feesHashPos, feesHash)
            mstore(propertiesHashPos, propertiesHash)
            mstore(hashNoncePos, hashNonce)
            structHash := keccak256(typeHashPos, 416 /* 32 * 13 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feesHashMemBefore)
            mstore(propertiesHashPos, propertiesHashMemBefore)
            mstore(hashNoncePos, hashNonceMemBefore)
        }
        return structHash;
    }

    // Hashes the `properties` array as part of computing the
    // EIP-712 hash of an `ERC721Order` or `ERC1155Order`.
    function _propertiesHash(Property[] memory properties) private pure returns (bytes32 propertiesHash) {
        uint256 numProperties = properties.length;
        // We give `properties.length == 0` and `properties.length == 1`
        // special treatment because we expect these to be the most common.
        if (numProperties == 0) {
            propertiesHash = _EMPTY_ARRAY_KECCAK256;
        } else if (numProperties == 1) {
            Property memory property = properties[0];
            if (address(property.propertyValidator) == address(0) && property.propertyData.length == 0) {
                propertiesHash = _NULL_PROPERTY_STRUCT_HASH;
            } else {
                // propertiesHash = keccak256(abi.encodePacked(keccak256(abi.encode(
                //     _PROPERTY_TYPE_HASH,
                //     properties[0].propertyValidator,
                //     keccak256(properties[0].propertyData)
                // ))));
                bytes32 dataHash = keccak256(property.propertyData);
                assembly {
                    // Load free memory pointer
                    let mem := mload(64)
                    mstore(mem, _PROPERTY_TYPE_HASH)
                    // property.propertyValidator
                    mstore(add(mem, 32), and(ADDRESS_MASK, mload(property)))
                    // keccak256(property.propertyData)
                    mstore(add(mem, 64), dataHash)
                    mstore(mem, keccak256(mem, 96))
                    propertiesHash := keccak256(mem, 32)
                }
            }
        } else {
            bytes32[] memory propertyStructHashArray = new bytes32[](numProperties);
            for (uint256 i = 0; i < numProperties; i++) {
                propertyStructHashArray[i] = keccak256(abi.encode(
                        _PROPERTY_TYPE_HASH, properties[i].propertyValidator, keccak256(properties[i].propertyData)));
            }
            assembly {
                propertiesHash := keccak256(add(propertyStructHashArray, 32), mul(numProperties, 32))
            }
        }
    }

    // Hashes the `fees` array as part of computing the
    // EIP-712 hash of an `ERC721Order` or `ERC1155Order`.
    function _feesHash(Fee[] memory fees) private pure returns (bytes32 feesHash) {
        uint256 numFees = fees.length;
        // We give `fees.length == 0` and `fees.length == 1`
        // special treatment because we expect these to be the most common.
        if (numFees == 0) {
            feesHash = _EMPTY_ARRAY_KECCAK256;
        } else if (numFees == 1) {
            // feesHash = keccak256(abi.encodePacked(keccak256(abi.encode(
            //     _FEE_TYPE_HASH,
            //     fees[0].recipient,
            //     fees[0].amount,
            //     keccak256(fees[0].feeData)
            // ))));
            Fee memory fee = fees[0];
            bytes32 dataHash = keccak256(fee.feeData);
            assembly {
                // Load free memory pointer
                let mem := mload(64)
                mstore(mem, _FEE_TYPE_HASH)
                // fee.recipient
                mstore(add(mem, 32), and(ADDRESS_MASK, mload(fee)))
                // fee.amount
                mstore(add(mem, 64), mload(add(fee, 32)))
                // keccak256(fee.feeData)
                mstore(add(mem, 96), dataHash)
                mstore(mem, keccak256(mem, 128))
                feesHash := keccak256(mem, 32)
            }
        } else {
            bytes32[] memory feeStructHashArray = new bytes32[](numFees);
            for (uint256 i = 0; i < numFees; i++) {
                feeStructHashArray[i] = keccak256(abi.encode(_FEE_TYPE_HASH, fees[i].recipient, fees[i].amount, keccak256(fees[i].feeData)));
            }
            assembly {
                feesHash := keccak256(add(feeStructHashArray, 32), mul(numFees, 32))
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

/// @dev A library for validating signatures.
library LibSignature {

    /// @dev Allowed signature types.
    enum SignatureType {
        EIP712,
        PRESIGNED
    }

    /// @dev Encoded EC signature.
    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;


interface IPropertyValidator {

    /// @dev Checks that the given ERC721/ERC1155 asset satisfies the properties encoded in `propertyData`.
    ///      Should revert if the asset does not satisfy the specified properties.
    /// @param tokenAddress The ERC721/ERC1155 token contract address.
    /// @param tokenId The ERC721/ERC1155 tokenId of the asset to check.
    /// @param propertyData Encoded properties or auxiliary data needed to perform the check.
    function validateProperty(address tokenAddress, uint256 tokenId, bytes calldata propertyData) external view;
}