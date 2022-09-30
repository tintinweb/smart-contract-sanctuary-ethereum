/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: GPL-3.0
// -- For windows enable 0.7.1 and ABIEncoderV2 --
// pragma solidity 0.7.1;
// pragma experimental ABIEncoderV2;

// -- For Unix, enable 0.8.0
pragma solidity 0.8.0;

contract AssetSubscription {
    struct Asset {
        uint256 assetId;
        uint256 listedValue;
        bool callable;
        uint256 assetClassId;
        uint256 interestRate;
        uint256 couponFrequency;
        uint256 issueDate;
        uint256 maturityDate;
        uint256 ownerId;
    }

    mapping(uint256 => Asset) assetList;

    struct Subscription {
        uint256 subscriberID;
        uint256 assetID;
        uint256 amount;
        uint256 debtTokensIssued;
        uint256 subscriptionDate;
    }

    mapping(uint256 => Subscription) subscriptionList;
    uint256 public subscriptionCount;

    event addAssetEvent(
        uint256 assetId,
        uint256 listedValue,
        bool callable,
        uint256 assetclassId,
        uint256 interestRate,
        uint256 couponFrequency,
        uint256 issueDate,
        uint256 maturityDate,
        uint256 ownerId
    );

    event addUserSubscriptionEvent(
        uint256 userId,
        uint256 asset_id,
        uint256 amount,
        uint256 debtTokensIssued,
        uint256 subscriptionDate
    );

    // Function for Creating properties
    function addAsset(
        uint256 assetId,
        uint256 listedValue,
        bool callable,
        uint256 assetclass,
        uint256 interestRate,
        uint256 couponFrequency,
        uint256 issueDate,
        uint256 maturityDate,
        uint256 ownerId
    ) public {
        assetList[assetId].assetId = assetId;
        assetList[assetId].listedValue = listedValue;
        assetList[assetId].callable = callable;
        assetList[assetId].assetClassId = assetclass;
        assetList[assetId].issueDate = issueDate;
        assetList[assetId].maturityDate = maturityDate;
        assetList[assetId].ownerId = ownerId;

        emit addAssetEvent(
            assetId,
            listedValue,
            callable,
            assetclass,
            interestRate,
            couponFrequency,
            issueDate,
            maturityDate,
            ownerId
        );
    }

    function addUserSubscription(
        uint256 userId,
        uint256 asset_id,
        uint256 amount,
        uint256 tokensIssued,
        uint256 subscriptionDate
    ) public {
        subscriptionList[subscriptionCount].assetID = asset_id;
        subscriptionList[subscriptionCount].subscriberID = userId;
        subscriptionList[subscriptionCount].amount = amount;
        subscriptionList[subscriptionCount].debtTokensIssued = tokensIssued;
        subscriptionList[subscriptionCount].subscriptionDate = subscriptionDate;
        subscriptionCount++;

        emit addUserSubscriptionEvent(
            userId,
            asset_id,
            amount,
            tokensIssued,
            subscriptionDate
        );
    }

    function getSubscriptionsByUserId(uint256 userId)
    public
    view
    returns (Subscription[] memory filteredSubscribers)
    {
        Subscription[] memory subsTemp = new Subscription[](subscriptionCount);
        uint256 count;
        for (uint256 i = 0; i < subscriptionCount; i++) {
            if (subscriptionList[i].subscriberID == userId) {
                subsTemp[count] = subscriptionList[i];
                count += 1;
            }
        }
        filteredSubscribers = new Subscription[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredSubscribers[i] = subsTemp[i];
        }
    }

    function getSubscriptionsByAssetId(uint256 assetId)
    public
    view
    returns (Subscription[] memory filteredAssets)
    {
        Subscription[] memory assetsTemp = new Subscription[](subscriptionCount);
        uint256 count;
        for (uint256 i = 0; i < subscriptionCount; i++) {
            if (subscriptionList[i].assetID == assetId) {
                assetsTemp[count] = subscriptionList[i];
                count += 1;
            }
        }
        filteredAssets = new Subscription[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredAssets[i] = assetsTemp[i];
        }
    }
}