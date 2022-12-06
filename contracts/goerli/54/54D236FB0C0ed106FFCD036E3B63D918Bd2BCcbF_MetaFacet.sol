// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import "../libraries/LibStorage.sol";
import {AccountMetadata, IAccountMeta} from "../interfaces/IAccountMeta.sol";

/**
 * @title Metadata contract
 * @notice A lens contract to view account information
 * @author Achthar
 */
contract MetaFacet is WithStorage, IAccountMeta {
    modifier onlyOwner() {
        LibStorage.enforceAccountOwner();
        _;
    }

    function fetchAccountMetadata() external view override returns (AccountMetadata memory accountMeta) {
        accountMeta.accountName = us().accountName;
        accountMeta.accountOwner = us().accountOwner;
        accountMeta.creationTimestamp = us().creationTimestamp;
        accountMeta.accountAddress = address(this);
    }

    function renameAccount(string memory _newName) external onlyOwner {
        us().accountName = _newName;
    }

    function accountFactory() external view returns (address) {
        return gs().factory;
    }

    function previousOwner() external view returns (address) {
        return us().previousAccountOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

// We do not use an array of stucts to avoid pointer conflicts

// Management storage that stores the different DAO roles
struct MarginSwapStorage {
    uint256 test;
}

struct GeneralStorage {
    address factory;
}

struct UserAccountStorage {
    address previousAccountOwner;
    address accountOwner;
    mapping(address => bool) managers;
    string accountName;
    uint256 creationTimestamp;
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
    bytes32 constant DATA_PROVIDER_STORAGE = keccak256("1DeltaAccount.storage.dataProvider");
    bytes32 constant MARGIN_SWAP_STORAGE = keccak256("1DeltaAccount.storage.marginSwap");
    bytes32 constant GENERAL_STORAGE = keccak256("1DeltaAccount.storage.general");
    bytes32 constant USER_ACCOUNT_STORAGE = keccak256("1DeltaAccount.storage.user");
    bytes32 constant UNISWAP_STORAGE = keccak256("1DeltaAccount.storage.uniswap");

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

struct AccountMetadata {
    address accountAddress;
    address accountOwner;
    string accountName;
    uint256 creationTimestamp;
}

interface IAccountMeta {
    function fetchAccountMetadata() external view returns (AccountMetadata memory);
}