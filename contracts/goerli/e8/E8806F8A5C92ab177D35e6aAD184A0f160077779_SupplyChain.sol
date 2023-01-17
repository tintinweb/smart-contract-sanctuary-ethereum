// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "./Struct.sol";

contract Mapping is Struct {
    mapping(address => mapping(string => bool)) userAssetsMap; //used to track if a product exists for a particular user
    //mapping(address => string[]) userassets; // used to store product ids for a user
    mapping(string => Asset) assetMap;
    mapping(string => TraceInfo[]) supplyChain;
    mapping(string => string[]) packageMap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

contract Struct {
    struct FunctionAsset {
        string Id;
        string MetaData;
    }

    struct Asset {
        string Id;
        string MetaData;
        string ParentId; //Reference id of package, carton, container. At the time of creation, it will be an empty string.
        address Owner;
        address OutwardedTo;
        State state;
    }

    string[] assetIdList;

    struct FunctionTraceInfo {
        address owner; //If not provided at creation, msg.sender will be set as default owner.
        string location;
        string comment;
    }

    struct TraceInfo {
        address holderAddress;
        uint256 time;
        string invoiceHash; //At the time of creation it will be empty string.
        string invoiceNum; //At the time of creation it will be empty string.
        string location;
        string comment;
    }

    enum State {
        MANUFACTURED,
        INTRANSIT,
        STORAGE,
        ENDUSER,
        DISCARDED,
        REPACKAGED
    }

    enum Type {
        UNIT,
        PACKAGE
    }

    enum FunctionType {
        OUTWARD,
        INWARD,
        SOLD
    }

    struct TypeList {
        Type _type;
        string[] IdList;
    }

    struct FunctionChaneOwnershipArgs {
        FunctionType functionType;
        TypeList type_list;
        address receiverAdd;
        address logisticAdd; //It should set be address(0) by default for SOLD method.
        string invoiceHash;
        string invoiceNum;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "./Mapping.sol";

contract SupplyChain is Mapping {
    event OwnershipChanged(
        string assetID,
        address currentOwner,
        address newOwner
    );

    //This method is used to save product information into the blockchain.
    function createAsset(
        FunctionAsset calldata functionAsset,
        FunctionTraceInfo calldata functionTraceInfo
    ) external {
        address Owner = functionTraceInfo.owner;

        if (Owner == address(0)) Owner = msg.sender;

        //Saving product information in a "asset" struct and pushing it into an "assets" array.
        Asset memory asset = Asset(
            functionAsset.Id,
            functionAsset.MetaData,
            "",
            Owner,
            address(0),
            State.MANUFACTURED
        );

        require(
            !userAssetsMap[Owner][asset.Id],
            "Asset already exists for the user."
        );
        assetIdList.push(asset.Id);

        //Mapping each asset information with asset Id.
        assetMap[asset.Id] = asset;

        //Setting asset Id for each user to true and saving the Ids into an array mapped with user address.
        userAssetsMap[Owner][asset.Id] = true;

        //Saving current package state in "packDetails" struct and saving it into an array mapped with asset Id.
        TraceInfo memory packageDetails = TraceInfo(
            Owner,
            block.timestamp,
            "",
            "",
            functionTraceInfo.location,
            functionTraceInfo.comment
        );
        supplyChain[asset.Id].push(packageDetails);
    }

    // This method is used to package the list of products together.
    function createPackage(
        string calldata packageId,
        string[] calldata productIdList
    ) external {
        for (uint256 i = 0; i < productIdList.length; i++) {
            string memory assetId = productIdList[i];
            //Default "Asset.Owner" value of empty asset is "0x0000000000000000000000000000000000000000".
            require(
                assetMap[assetId].Owner != address(0),
                "Asset doesn't exist."
            );
            assetMap[assetId].ParentId = packageId;
            packageMap[packageId].push(assetId);
        }
    }

    // This method is used to depackage.
    function dePackage(string calldata packageId) external {
        //Fetching product list of given package id.
        string[] memory assetList = packageMap[packageId];
        //Iterating through the product list.
        for (uint256 i = 0; i < assetList.length; i++) {
            string memory assetId = assetList[i];
            //Default "Asset.Owner" value of empty asset is "0x0000000000000000000000000000000000000000".
            if (assetMap[assetId].Owner != address(0)) {
                assetMap[assetId].ParentId = "";
            }
        }
        //Deleting the package mapping.
        delete packageMap[packageId];
    }

    // This is a common method for outward/inward/sold.
    //Outward is called by seller who needs to provide logistic as well as buyer address along with other required arguments.
    //Inward is called by the buyer to accept delivery of the poduct from the logistics. The buyer will also provide logistic and his own address(receiverAdd) along with other required arguments.
    //Sold is called by buyer or end user. Buyer or end user will only provide end user's address as Receiver address along with other required arguments. No logistic address is required (set address(0)).

    function changeOwnership(
        FunctionChaneOwnershipArgs memory changeOwnershipArgs,
        FunctionTraceInfo memory functionTraceInfo
    ) external {
        address Owner = address(0);
        address newOwner = address(0);
        if (changeOwnershipArgs.type_list._type == Type.UNIT) {
            for (
                uint256 i = 0;
                i < changeOwnershipArgs.type_list.IdList.length;
                i++
            ) {
                string memory assetId = changeOwnershipArgs.type_list.IdList[i];

                if (changeOwnershipArgs.functionType == FunctionType.OUTWARD) {
                    //Seller is the current owner.
                    Owner = functionTraceInfo.owner;
                    //Logistic provider is the new owner.
                    newOwner = changeOwnershipArgs.logisticAdd;

                    if (Owner == address(0)) Owner = msg.sender;
                    require(
                        userAssetsMap[Owner][assetId],
                        "You are not the owner"
                    );

                    //Changing the state of product.
                    assetMap[assetId].state = State.INTRANSIT;

                    //Changing the ownership of the product to logistic provider's address.
                    assetMap[assetId].Owner = newOwner;

                    //Updating Buyer Address for each product.
                    assetMap[assetId].OutwardedTo = changeOwnershipArgs
                        .receiverAdd;
                } else if (
                    changeOwnershipArgs.functionType == FunctionType.INWARD
                ) {
                    //Logistic provider is the current owner.
                    Owner = changeOwnershipArgs.logisticAdd;

                    //Buyer is the new owner.
                    newOwner = functionTraceInfo.owner;

                    if (functionTraceInfo.owner == address(0))
                        newOwner = msg.sender;

                    require(
                        assetMap[assetId].OutwardedTo == newOwner &&
                            changeOwnershipArgs.receiverAdd == newOwner &&
                            userAssetsMap[Owner][assetId]
                    );

                    //Changing the ownership of the product to buyer's address.
                    assetMap[assetId].Owner = newOwner;

                    assetMap[assetId].state = State.STORAGE;
                } else if (
                    changeOwnershipArgs.functionType == FunctionType.SOLD
                ) {
                    //Buyer is the current owner.
                    //If end user calls the method he will provide buyer address.
                    Owner = functionTraceInfo.owner;

                    //Customer is the new owner.
                    newOwner = changeOwnershipArgs.receiverAdd;

                    //Buyer is the caller of the method.
                    if (Owner == address(0)) Owner = msg.sender;
                    require(
                        userAssetsMap[Owner][assetId],
                        "You are not the owner"
                    );

                    //Changing the ownership of the product to end user's address.
                    assetMap[assetId].Owner = newOwner;
                    //Changing the state of product.
                    assetMap[assetId].state = State.ENDUSER;
                }

                //Updating package details and adding it to supplyChain.
                TraceInfo memory packageDetails = TraceInfo(
                    newOwner,
                    block.timestamp,
                    changeOwnershipArgs.invoiceHash,
                    changeOwnershipArgs.invoiceNum,
                    functionTraceInfo.location,
                    functionTraceInfo.comment
                );
                supplyChain[assetId].push(packageDetails);

                //Deleting the product for current owner(seller).
                userAssetsMap[Owner][assetId] = false;

                //Updating the product for new owner(logistic provider).
                userAssetsMap[newOwner][assetId] = true;

                emit OwnershipChanged(assetId, Owner, assetMap[assetId].Owner);
            }
        } else {
            if (changeOwnershipArgs.type_list._type == Type.PACKAGE) {
                for (
                    uint256 i = 0;
                    i < changeOwnershipArgs.type_list.IdList.length;
                    i++
                ) {
                    string memory packageId = changeOwnershipArgs
                        .type_list
                        .IdList[i];

                    //Fetching product list of given package id.
                    string[] memory assetList = packageMap[packageId];

                    //Iterating through the product list.
                    for (uint256 j = 0; j < assetList.length; j++) {
                        string memory assetId = assetList[j];

                        if (
                            changeOwnershipArgs.functionType ==
                            FunctionType.OUTWARD
                        ) {
                            //Seller is the current owner.
                            Owner = functionTraceInfo.owner;

                            //Logistic provider is the new owner.
                            newOwner = changeOwnershipArgs.logisticAdd;

                            if (Owner == address(0)) Owner = msg.sender;
                            require(
                                userAssetsMap[Owner][assetId],
                                "You are not the owner"
                            );



                            //Changing the state of product.
                            assetMap[assetId].state = State.INTRANSIT;

                            //Changing the ownership of the product to logistic provider's address.
                            assetMap[assetId].Owner = newOwner;

                            //Updating Buyer Address for each product.
                            assetMap[assetId].OutwardedTo = changeOwnershipArgs
                                .receiverAdd;
                        } else if (
                            changeOwnershipArgs.functionType ==
                            FunctionType.INWARD
                        ) {
                            //Logistic provider is the current owner.
                            Owner = changeOwnershipArgs.logisticAdd;

                            //Buyer is the new owner.
                            newOwner = functionTraceInfo.owner;

                            if (functionTraceInfo.owner == address(0))
                                newOwner = msg.sender;

                            require(
                                assetMap[assetId].OutwardedTo == newOwner &&
                                    changeOwnershipArgs.receiverAdd ==
                                    newOwner &&
                                    userAssetsMap[Owner][assetId]
                            );

                            //Changing the ownership of the product to buyer's address.
                            assetMap[assetId].Owner = newOwner;

                            assetMap[assetId].state = State.STORAGE;
                        } else if (
                            changeOwnershipArgs.functionType ==
                            FunctionType.SOLD
                        ) {
                            //Buyer is the current owner.
                            //If end user calls the method he will provide buyer address.
                            Owner = functionTraceInfo.owner;

                            //Customer is the new user.
                            newOwner = changeOwnershipArgs.receiverAdd;
                            //Buyer is the caller of the method.
                            if (Owner == address(0)) Owner = msg.sender;
                            require(
                                userAssetsMap[Owner][assetId],
                                "You are not the owner"
                            );

                            //Changing the ownership of the product to end user's address.
                            assetMap[assetId].Owner = newOwner;
                            //Changing the state of product.
                            assetMap[assetId].state = State.ENDUSER;
                        }

                        //Updating package details and adding it to supplyChain.
                        TraceInfo memory packageDetails = TraceInfo(
                            newOwner,
                            block.timestamp,
                            changeOwnershipArgs.invoiceHash,
                            changeOwnershipArgs.invoiceNum,
                            functionTraceInfo.location,
                            functionTraceInfo.comment
                        );
                        supplyChain[assetId].push(packageDetails);

                        //Deleting the product for current owner(seller).
                        userAssetsMap[Owner][assetId] = false;

                        //Updating the product for new owner(logistic provider).
                        userAssetsMap[newOwner][assetId] = true;

                        emit OwnershipChanged(
                            assetId,
                            Owner,
                            assetMap[assetId].Owner
                        );
         
                    }
                }
            }
        }
    }

    // This method returns product information for provided product id.
    function getAssetDetailsById(string memory id)
        external
        view
        returns (Asset memory)
    {
        return assetMap[id];
    }

    // This method is used to trace package based on id.
    function productTraceById(string memory id)
        external
        view
        returns (TraceInfo[] memory)
    {
        return supplyChain[id];
    }

    //This method is used to check if an asset exists for a particular user.
    function assetExistsByUserAddress(
        address userAddress,
        string memory assetId
    ) external view returns (bool) {
        return userAssetsMap[userAddress][assetId];
    }

    // This method returns list of all the product ids saved in the blockchain.
    function getAllAssets() external view returns (string[] memory) {
        return assetIdList;
    }

    //This method returns list of product ids mapped with the given package id.
    function getAllProductByPackageId(string memory packageId)
        external
        view
        returns (string[] memory)
    {
        return packageMap[packageId];
    }
}