/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


contract AssetRegister {

    /* Notes:
    - sharePrice is in wei.
    */

    struct Asset {
        address creator;
        string assetName;
        uint totalShares;
        uint sharePrice;
    }

    Asset[] public assets;
    mapping (string => uint) assetNameExists;
    address[] public users;
    mapping (address => uint) userExists;

    // assetId => owner's address => number of shares
    mapping (uint => mapping (address => uint)) shareOwnership;
    // assetId => list of owners of the asset.
    mapping (uint => address[]) assetOwners;

    mapping(address => uint) public balances;

    event AssetCreated(uint assetId, address creator, string assetName, uint totalShares, uint sharePrice);
    event SharesPurchased(uint assetId, address buyer, uint sharesPurchased);

    error PurchaseBlocked();
    error InsufficientSharesAvailable(uint availableShares, uint requestedShares);
    error InsufficientValueReceived(uint requiredValue, uint receivedValue);

    receive() external payable {
        address user = msg.sender;
        uint receivedValue = msg.value;
        registerUser(user);
        balances[user] += receivedValue;
    }

    function registerUser(address user) private {
        if (userExists[user] == 0) {
            userExists[user] = 1;
            users.push(user);
        }
    }

    function createAsset(string memory assetName, uint totalShares, uint sharePrice) public {
        address creator = msg.sender;
        require (assetNameExists[assetName] == 0, "Asset name already exists.");
        registerUser(creator);
        assets.push(Asset(
            creator,
            assetName,
            totalShares,
            sharePrice
        ));
        assetNameExists[assetName] = 1;
        uint assetId = assets.length - 1;
        assetOwners[assetId].push(creator);
        shareOwnership[assetId][creator] = totalShares;
        emit AssetCreated(assetId, creator, assetName, totalShares, sharePrice);
    }

    function totalAssets() public view returns (uint value) {
        return assets.length;
    }

    function totalUsers() public view returns (uint value) {
        return users.length;
    }

    function getAssetOwners(uint assetId) public view returns (address[] memory owners) {
        owners = assetOwners[assetId];
        return owners;
    }

    function getAssetOwnerShares(uint assetId, address owner) public view returns (uint shares) {
        shares = shareOwnership[assetId][owner];
        return shares;
    }

    function purchaseShares(uint assetId, uint requestedShares) public payable {
        address user = msg.sender;
        Asset storage x = assets[assetId];
        address creator = x.creator;
        // Block creator from purchasing shares from themselves. (This just loses them money.)
        if (user == creator) {
            revert PurchaseBlocked();
        }
        uint availableShares = shareOwnership[assetId][creator];
        if (requestedShares > availableShares) {
            revert InsufficientSharesAvailable(availableShares, requestedShares);
        }
        uint receivedValue = msg.value;
        uint requiredValue = requestedShares * x.sharePrice;
        if (receivedValue < requiredValue) {
            revert InsufficientValueReceived(requiredValue, receivedValue);
        }
        // Register the user and execute the transfer.
        registerUser(user);
        assetOwners[assetId].push(user);
        shareOwnership[assetId][creator] -= requestedShares;
        shareOwnership[assetId][user] += requestedShares;
        balances[creator] += receivedValue;
        // If the user sent too much money, assign the remainder to their balance.
        if (receivedValue > requiredValue) {
            balances[user] += receivedValue - requiredValue;
        }
        emit SharesPurchased({assetId: assetId, buyer: user, sharesPurchased: requestedShares});
    }

}