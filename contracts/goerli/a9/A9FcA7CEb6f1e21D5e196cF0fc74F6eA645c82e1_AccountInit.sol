// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDelegatedDiamond} from "../libraries/LibDelegatedDiamond.sol";
import {
    LibStorage, 
    WithStorage, 
    GeneralStorage, 
    MarginSwapStorage, 
    UserAccountStorage, 
    DataProviderStorage
    } from "../libraries/LibStorage.sol";
import {IAccountInit} from "../interfaces/IAccountInit.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract AccountInit is WithStorage, IAccountInit {
    // factory is set in the constructor
    constructor() {
        LibDelegatedDiamond.DelegatedDiamondStorage storage gs = LibDelegatedDiamond.diamondStorage();
        gs.factory = msg.sender;
    }

    // the initializer only initializes the facet provider, data provider and owner
    // the facets are provided by views in this facet provider contract
    // the diamond cut facet is not existing in this contract, it is implemented in the provider
    function init(address _dataProvider, address _owner) external override {
        require(LibDelegatedDiamond.diamondStorage().factory == msg.sender, "Only factory can in itialize");
        // here the account data is initialized
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface

        DataProviderStorage storage ps = LibStorage.dataProviderStorage();
        ps.dataProvider = _dataProvider;

        UserAccountStorage storage us = LibStorage.userAccountStorage();
        us.accountOwner = _owner;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// We do not use an array of stucts to avoid pointer conflicts

// Management storage that stores the different DAO roles
struct MarginSwapStorage {
    uint256 test;
}

struct GeneralStorage {
    address factory;
}

struct UserAccountStorage {
    address accountOwner;
    mapping(address => bool) allowedPools;
    mapping(address => bool) managers;
}

struct DataProviderStorage {
    address dataProvider;
}

struct UniswapStorage {
    uint256 amountInCached;
    address swapRouter;
}

library LibStorage {
    // Storage are structs where the data gets updated throughout the lifespan of the project
    bytes32 constant DATA_PROVIDER_STORAGE = keccak256("account.storage.dataProvider");
    bytes32 constant MARGIN_SWAP_STORAGE = keccak256("account.storage.marginSwap");
    bytes32 constant GENERAL_STORAGE = keccak256("account.storage.general");
    bytes32 constant USER_ACCOUNT_STORAGE = keccak256("account.storage.user");
    bytes32 constant UNISWAP_STORAGE = keccak256("account.storage.uniswap");

    function dataProviderStorage() internal pure returns (DataProviderStorage storage ps) {
        bytes32 position = DATA_PROVIDER_STORAGE;
        assembly {
            ps.slot := position
        }
    }

    function marginSwapStorage() internal pure returns (MarginSwapStorage storage ms) {
        bytes32 position = MARGIN_SWAP_STORAGE;
        assembly {
            ms.slot := position
        }
    }

    function generalStorage() internal pure returns (GeneralStorage storage gs) {
        bytes32 position = GENERAL_STORAGE;
        assembly {
            gs.slot := position
        }
    }

    function userAccountStorage() internal pure returns (UserAccountStorage storage us) {
        bytes32 position = USER_ACCOUNT_STORAGE;
        assembly {
            us.slot := position
        }
    }

    function uniswapStorge() internal pure returns (UniswapStorage storage ss) {
        bytes32 position = UNISWAP_STORAGE;
        assembly {
            ss.slot := position
        }
    }

    function enforceManager() internal view {
        require(userAccountStorage().managers[msg.sender], "Only manager can interact.");
    }

    function enforceAccountOwner() internal view {
        require(msg.sender == userAccountStorage().accountOwner, "Only the account owner can interact.");
    }
}

/**
 * The `WithStorage` contract provides a base contract for Facet contracts to inherit.
 *
 * It mainly provides internal helpers to access the storage structs, which reduces
 * calls like `LibStorage.treasuryStorage()` to just `ts()`.
 *
 * To understand why the storage stucts must be accessed using a function instead of a
 * state variable, please refer to the documentation above `LibStorage` in this file.
 */
abstract contract WithStorage {
    function ps() internal pure returns (DataProviderStorage storage) {
        return LibStorage.dataProviderStorage();
    }

    function ms() internal pure returns (MarginSwapStorage storage) {
        return LibStorage.marginSwapStorage();
    }

    function gs() internal pure returns (GeneralStorage storage) {
        return LibStorage.generalStorage();
    }

    function us() internal pure returns (UserAccountStorage storage) {
        return LibStorage.userAccountStorage();
    }

    function ss() internal pure returns (UniswapStorage storage) {
        return LibStorage.uniswapStorge();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IAccountInit {
    function init(address _dataProvider, address _owner) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// THis diamond variant only
library LibDelegatedDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DelegatedDiamondStorage {
        address facetProvider;
        address factory;
    }

    function diamondStorage() internal pure returns (DelegatedDiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}