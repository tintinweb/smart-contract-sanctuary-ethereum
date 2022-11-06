// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../../libraries/LibStorage.sol";

/**
 * @title Delegator contract
 * @notice Allows users to name managers. These have rights over managing the account.
 * Managers cannot withdraw funds from the account, but open and close trading positions
 * @author Achthar
 */
contract DelegatorFacetGoerli is WithStorage {
    modifier onlyOwner() {
        LibStorage.enforceAccountOwner();
        _;
    }

    function addManager(address _newManager) external onlyOwner {
        us().managers[_newManager] = true;
    }

    function removeManager(address _manager) external onlyOwner {
        us().managers[_manager] = false;
    }

    function isManager(address _manager) external view returns (bool) {
        return us().managers[_manager];
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