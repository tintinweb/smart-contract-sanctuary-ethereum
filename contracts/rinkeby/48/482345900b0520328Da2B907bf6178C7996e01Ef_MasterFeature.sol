// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../storage/LibAggregatorStorage.sol";
import "../../storage/LibFeatureStorage.sol";
import "../../libs/Ownable.sol";


contract MasterFeature is Ownable {

    struct Method {
        bytes4 methodID;
        string methodName;
    }

    struct Feature {
        address feature;
        string name;
        Method[] methods;
    }

    function getMethodIDs() external view returns (uint256 count, bytes4[] memory methodIDs) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        return (stor.methodIDs.length, stor.methodIDs);
    }

    function getFeature(address featureAddr) public view returns (Feature memory feature) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();

        // Calculate feature.methods.length
        uint256 methodsLength = 0;
        for (uint256 i = 0; i < stor.methodIDs.length; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            if (featureAddr == stor.featureImpls[methodID]) {
                ++methodsLength;
            }
        }

        // Set methodIs
        uint256 j = 0;
        Method[] memory methods = new Method[](methodsLength);
        for (uint256 i = 0; i < stor.methodIDs.length && j < methodsLength; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            if (featureAddr == stor.featureImpls[methodID]) {
                methods[j] = Method(methodID, stor.methodNames[methodID]);
                ++j;
            }
        }

        feature.feature = featureAddr;
        feature.name = stor.featureNames[featureAddr];
        feature.methods = methods;
        return feature;
    }

    function getFeatureByMethodID(bytes4 methodID) external view returns (Feature memory feature) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        address featureAddr = stor.featureImpls[methodID];
        return getFeature(featureAddr);
    }

    function getFeatures() external view returns (Feature[] memory features) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        (uint256 featuresLength, uint256[] memory methodsLength) = _calcFeaturesLengthAndMethodsLength();

        uint256 featuresCount;
        uint256[] memory methodsCount = new uint256[](featuresLength);
        features = new Feature[](featuresLength);

        for (uint256 i = 0; i < stor.methodIDs.length; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            address impl = stor.featureImpls[methodID];

            uint256 j = 0;
            while (j < featuresCount && impl != features[j].feature) {
                ++j;
            }

            if (j == featuresCount) {
                features[j] = Feature(impl, stor.featureNames[impl], new Method[](methodsLength[j]));
                ++featuresCount;
            }

            features[j].methods[methodsCount[j]] = Method(methodID, stor.methodNames[methodID]);
            ++methodsCount[j];
        }
        return features;
    }

    function getFeaturesSummary() external view returns (
        uint256 featuresCount,
        address[] memory features,
        string[] memory names,
        uint256[] memory featureMethodsCount
    ) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        uint256[] memory methodsCount = new uint256[](stor.methodIDs.length);
        address[] memory addrs = new address[](stor.methodIDs.length);

        for (uint256 i = 0; i < stor.methodIDs.length; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            address impl = stor.featureImpls[methodID];

            uint256 j = 0;
            while (j < featuresCount && impl != addrs[j]) {
                ++j;
            }
            if (j == featuresCount) {
                addrs[j] = impl;
                ++featuresCount;
            }

            ++methodsCount[j];
        }

        features = new address[](featuresCount);
        names = new string[](featuresCount);
        featureMethodsCount = new uint256[](featuresCount);
        for (uint256 i = 0; i < featuresCount; ++i) {
            features[i] = addrs[i];
            names[i] = stor.featureNames[addrs[i]];
            featureMethodsCount[i] = methodsCount[i];
        }
        return (featuresCount, features, names, featureMethodsCount);
    }

    function _calcFeaturesLengthAndMethodsLength() internal view returns(uint256, uint256[] memory) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();

        uint256 featuresCount;
        uint256[] memory methodsCount = new uint256[](stor.methodIDs.length);
        address[] memory addrs = new address[](stor.methodIDs.length);

        for (uint256 i = 0; i < stor.methodIDs.length; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            address impl = stor.featureImpls[methodID];

            uint256 j = 0;
            while (j < featuresCount && impl != addrs[j]) {
                ++j;
            }

            if (j == featuresCount) {
                addrs[j] = impl;
                ++featuresCount;
            }

            ++methodsCount[j];
        }

        return (featuresCount, methodsCount);
    }

    function getMarkets() external view returns (
        uint256 marketsCount,
        address[] memory proxies,
        bool[] memory isLibrary,
        bool[] memory isActive
    ) {
        LibAggregatorStorage.Market[] storage markets = LibAggregatorStorage.getStorage().markets;
        proxies = new address[](markets.length);
        isLibrary = new bool[](markets.length);
        isActive = new bool[](markets.length);
        for (uint256 i = 0; i < markets.length; i++) {
            proxies[i] = markets[i].proxy;
            isLibrary[i] = markets[i].isLibrary;
            isActive[i] = markets[i].isActive;
        }
        return (markets.length, proxies, isLibrary, isActive);
    }

    function addMarket(address proxy, bool isLibrary) external onlyOwner {
        LibAggregatorStorage.getStorage().markets.push(
            LibAggregatorStorage.Market(proxy, isLibrary, true)
        );
    }

    function setMarketProxy(uint256 marketId, address newProxy, bool isLibrary) external onlyOwner {
        LibAggregatorStorage.Market storage market = LibAggregatorStorage.getStorage().markets[marketId];
        market.proxy = newProxy;
        market.isLibrary = isLibrary;
    }

    function setMarketActive(uint256 marketId, bool isActive) external onlyOwner {
        LibAggregatorStorage.Market storage market = LibAggregatorStorage.getStorage().markets[marketId];
        market.isActive = isActive;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library LibAggregatorStorage {

    uint256 constant STORAGE_ID_AGGREGATOR = 0;

    struct Market {
        address proxy;
        bool isLibrary;
        bool isActive;
    }

    struct Storage {
        Market[] markets;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_AGGREGATOR }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library LibFeatureStorage {

    uint256 constant STORAGE_ID_FEATURE = 1 << 128;

    struct Storage {
        // Mapping of methodID -> feature implementation
        mapping(bytes4 => address) featureImpls;
        // Mapping of feature implementation -> feature name
        mapping(address => string) featureNames;
        // Record methodIDs
        bytes4[] methodIDs;
        // Mapping of methodID -> method name
        mapping(bytes4 => string) methodNames;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor.slot := STORAGE_ID_FEATURE }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../storage/LibOwnableStorage.sol";


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
abstract contract Ownable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        if (owner() == address(0)) {
            _transferOwnership(msg.sender);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return LibOwnableStorage.getStorage().owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) private {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        address oldOwner = stor.owner;
        stor.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library LibOwnableStorage {

    uint256 constant STORAGE_ID_OWNABLE = 2 << 128;

    struct Storage {
        uint256 reentrancyStatus;
        address owner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_OWNABLE }
    }
}