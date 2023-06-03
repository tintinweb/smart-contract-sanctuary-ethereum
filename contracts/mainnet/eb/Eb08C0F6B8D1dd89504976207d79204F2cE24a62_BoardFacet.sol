/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../../diamond/IDiamondFacet.sol";
import "./IBoard.sol";
import "./BoardInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract BoardFacet is IDiamondFacet, IBoard {

    function getFacetName()
      external pure override returns (string memory) {
        return "board";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "1.0.0";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](5);
        pi[ 0] = "initializeBoard(address[],address[],address[],address[])";
        pi[ 1] = "isOperator(uint256,address)";
        pi[ 2] = "getOperators(uint256)";
        pi[ 3] = "addOperator(uint256,uint256,address)";
        pi[ 4] = "removeOperator(uint256,uint256,address)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](0);
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return
            interfaceId == type(IDiamondFacet).interfaceId ||
            interfaceId == type(IBoard).interfaceId;
    }

    function initializeBoard(
        address[] memory admins,
        address[] memory creators,
        address[] memory executors,
        address[] memory finalizers
    ) external override {
        BoardInternal._initialize(
            admins,
            creators,
            executors,
            finalizers
        );
    }

    function isOperator(
        uint256 operatorType,
        address account
    ) external view returns (bool) {
        return BoardInternal._isOperator(operatorType, account);
    }

    function getOperators(
        uint256 operatorType
    ) external view returns (address[] memory) {
        return BoardInternal._getOperators(operatorType);
    }

    function addOperator(
        uint256 adminProposalId,
        uint256 operatorType,
        address account
    ) external {
        BoardInternal._addOperator(adminProposalId, operatorType, account);
    }

    function removeOperator(
        uint256 adminProposalId,
        uint256 operatorType,
        address account
    ) external {
        BoardInternal._removeOperator(adminProposalId, operatorType, account);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IDiamondFacet is IERC165 {

    // NOTE: The override MUST remain 'pure'.
    function getFacetName() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetVersion() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetPI() external pure returns (string[] memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetProtectedPI() external pure returns (string[] memory);
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IBoard {

    function initializeBoard(
        address[] memory admins,
        address[] memory creators,
        address[] memory executors,
        address[] memory finalizers
    ) external;
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../../lib/AddressSet.sol";
import "../council/CouncilLib.sol";
import "../Constants.sol";
import "./BoardStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library BoardInternal {

    event AdminAdd(address indexed account);
    event CreatorAdd(address indexed account);
    event ExecutorAdd(address indexed account);
    event FinalizerAdd(address indexed account);
    event AdminRemove(address indexed account);
    event CreatorRemove(address indexed account);
    event ExecutorRemove(address indexed account);
    event FinalizerRemove(address indexed account);

    modifier mustBeInitialized() {
        require(__s().initialized, "BI:NI");
        _;
    }

    function _initialize(
        address[] memory admins,
        address[] memory creators,
        address[] memory executors,
        address[] memory finalizers
    ) internal {
        require(!__s().initialized, "BI:AI");
        require(admins.length >= 3, "BI:NEA");
        require(creators.length >= 1, "BI:NEC");
        require(executors.length >= 1, "BI:NEE");
        for (uint256 i = 0; i < admins.length; i++) {
            address account = admins[i];
            if (AddressSetLib._addItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.ADMIN_SET_ID, account)) {
                emit AdminAdd(account);
            }
        }
        for (uint256 i = 0; i < creators.length; i++) {
            address account = creators[i];
            if (AddressSetLib._addItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.CREATOR_SET_ID, account)) {
                emit CreatorAdd(account);
            }
        }
        for (uint256 i = 0; i < executors.length; i++) {
            address account = executors[i];
            if (AddressSetLib._addItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.EXECUTOR_SET_ID, account)) {
                emit ExecutorAdd(account);
            }
        }
        for (uint256 i = 0; i < finalizers.length; i++) {
            address account = finalizers[i];
            if (AddressSetLib._addItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.FINALIZER_SET_ID, account)) {
                emit FinalizerAdd(account);
            }
        }
        __s().initialized = true;
    }

    function _isOperator(uint256 operatorType, address account) internal view returns (bool) {
        require(__isOperatorTypeValid(operatorType), "BI:INVOT");
        if (operatorType == ConstantsLib.OPERATOR_TYPE_ADMIN) {
            return AddressSetLib._hasItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.ADMIN_SET_ID, account);
        } else if (operatorType == ConstantsLib.OPERATOR_TYPE_CREATOR) {
            return AddressSetLib._hasItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.CREATOR_SET_ID, account);
        } else if (operatorType == ConstantsLib.OPERATOR_TYPE_EXECUTOR) {
            return AddressSetLib._hasItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.EXECUTOR_SET_ID, account);
        } else if (operatorType == ConstantsLib.OPERATOR_TYPE_FINALIZER) {
            return AddressSetLib._hasItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.FINALIZER_SET_ID, account);
        }
        return false;
    }

    function _getOperators(uint256 operatorType) internal view returns (address[] memory) {
        require(__isOperatorTypeValid(operatorType), "BI:INVOT");
        if (operatorType == ConstantsLib.OPERATOR_TYPE_ADMIN) {
            return AddressSetLib._getItems(ConstantsLib.SET_ZONE_ID, ConstantsLib.ADMIN_SET_ID);
        } else if (operatorType == ConstantsLib.OPERATOR_TYPE_CREATOR) {
            return AddressSetLib._getItems(ConstantsLib.SET_ZONE_ID, ConstantsLib.CREATOR_SET_ID);
        } else if (operatorType == ConstantsLib.OPERATOR_TYPE_EXECUTOR) {
            return AddressSetLib._getItems(ConstantsLib.SET_ZONE_ID, ConstantsLib.EXECUTOR_SET_ID);
        } else if (operatorType == ConstantsLib.OPERATOR_TYPE_FINALIZER) {
            return AddressSetLib._getItems(ConstantsLib.SET_ZONE_ID, ConstantsLib.FINALIZER_SET_ID);
        }
        return new address[](0);
    }

    function _addOperator(
        uint256 adminProposalId,
        uint256 operatorType,
        address account
    ) internal mustBeInitialized {
        require(__isOperatorTypeValid(operatorType), "BI:INVOT");
        CouncilLib._executeAdminProposal(address(this), msg.sender, adminProposalId);
        if (operatorType == ConstantsLib.OPERATOR_TYPE_ADMIN) {
            if (AddressSetLib._addItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.ADMIN_SET_ID, account)) {
                emit AdminAdd(account);
            }
        } else if (operatorType == ConstantsLib.OPERATOR_TYPE_CREATOR) {
            if (AddressSetLib._addItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.CREATOR_SET_ID, account)) {
                emit CreatorAdd(account);
            }
        } else if (operatorType == ConstantsLib.OPERATOR_TYPE_EXECUTOR) {
            if (AddressSetLib._addItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.EXECUTOR_SET_ID, account)) {
                emit ExecutorAdd(account);
            }
        } else if (operatorType == ConstantsLib.OPERATOR_TYPE_FINALIZER) {
            if (AddressSetLib._addItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.FINALIZER_SET_ID, account)) {
                emit FinalizerAdd(account);
            }
        }
    }

    function _removeOperator(
        uint256 adminProposalId,
        uint256 operatorType,
        address account
    ) internal mustBeInitialized {
        require(__isOperatorTypeValid(operatorType), "BI:INVOT");
        CouncilLib._executeAdminProposal(address(this), msg.sender, adminProposalId);
        if (operatorType == ConstantsLib.OPERATOR_TYPE_ADMIN) {
            if (AddressSetLib._removeItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.ADMIN_SET_ID, account)) {
                emit AdminRemove(account);
            }
        } else if (operatorType == ConstantsLib.OPERATOR_TYPE_CREATOR) {
            if (AddressSetLib._removeItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.CREATOR_SET_ID, account)) {
                emit CreatorRemove(account);
            }
        } else if (operatorType == ConstantsLib.OPERATOR_TYPE_EXECUTOR) {
            if (AddressSetLib._removeItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.EXECUTOR_SET_ID, account)) {
                emit ExecutorRemove(account);
            }
        } else if (operatorType == ConstantsLib.OPERATOR_TYPE_FINALIZER) {
            if (AddressSetLib._removeItem(
                ConstantsLib.SET_ZONE_ID, ConstantsLib.FINALIZER_SET_ID, account)) {
                emit FinalizerRemove(account);
            }
        }
    }

    function _makeFinalizer(address account) internal mustBeInitialized {
        // add the grant-token contract as a finalizer by default
        if (AddressSetLib._addItem(
            ConstantsLib.SET_ZONE_ID, ConstantsLib.FINALIZER_SET_ID, account)) {
            emit FinalizerAdd(account);
        }
    }

    function __isOperatorTypeValid(uint256 operatorType) private pure returns (bool) {
        return operatorType >= 1 && operatorType <= 4;
    }

    function __s() private pure returns (BoardStorage.Layout storage) {
        return BoardStorage.layout();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         setIdea from: https://github.com/solsetIdstate-network/solsetIdstate-solsetIdity
library AddressSetStorage {

    struct AddressSet {
        // list of address items
        address[] items;
        // address > index in the items array
        mapping(address => uint256) itemsIndex;
        // address > true if removed
        mapping(address => bool) removedItems;
    }

    struct Zone {
        // set ID > set object
        mapping(bytes32 => AddressSet) sets;
    }

    struct Layout {
        // zone ID > zone object
        mapping(bytes32 => Zone) zones;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.lib.address-set.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

library AddressSetLib {

    function _hasItem(
        bytes32 zoneId,
        bytes32 setId,
        address item
    ) internal view returns (bool) {
        return __s2(zoneId, setId).itemsIndex[item] > 0 &&
            !__s2(zoneId, setId).removedItems[item];
    }

    function _getItemsCount(
        bytes32 zoneId,
        bytes32 setId
    ) internal view returns (uint256) {
        return __s2(zoneId, setId).items.length;
    }

    function _getItems(
        bytes32 zoneId,
        bytes32 setId
    ) internal view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < __s2(zoneId, setId).items.length; i++) {
            address item = __s2(zoneId, setId).items[i];
            if (!__s2(zoneId, setId).removedItems[item]) {
                count++;
            }
        }
        address[] memory results = new address[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < __s2(zoneId, setId).items.length; i++) {
            address item = __s2(zoneId, setId).items[i];
            if (!__s2(zoneId, setId).removedItems[item]) {
                results[j] = item;
                j += 1;
            }
        }
        return results;
    }

    function _addItem(
        bytes32 zoneId,
        bytes32 setId,
        address item
    ) internal returns (bool) {
        if (__s2(zoneId, setId).itemsIndex[item] == 0) {
            __s2(zoneId, setId).items.push(item);
            __s2(zoneId, setId).itemsIndex[item] = __s2(zoneId, setId).items.length;
            return true;
        } else if (__s2(zoneId, setId).removedItems[item]) {
            __s2(zoneId, setId).removedItems[item] = false;
            return true;
        }
        return false;
    }

    function _removeItem(
        bytes32 zoneId,
        bytes32 setId,
        address item
    ) internal returns (bool) {
        if (
            __s2(zoneId, setId).itemsIndex[item] > 0 &&
            !__s2(zoneId, setId).removedItems[item]
         ) {
            __s2(zoneId, setId).removedItems[item] = true;
            return true;
        }
        return false;
    }

    function __s2(
        bytes32 zoneId,
        bytes32 setId
    ) private view returns (AddressSetStorage.AddressSet storage) {
        return __s().zones[zoneId].sets[setId];
    }

    function __s() private pure returns (AddressSetStorage.Layout storage) {
        return AddressSetStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./CouncilInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library CouncilLib {

    function _executeAdminProposal(
        address caller,
        address executor,
        uint256 adminProposalId
    ) internal {
        CouncilInternal._executeAdminProposal(
            caller, executor, adminProposalId);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

library ConstantsLib {

    uint256 constant public GRANT_TOKEN_ADMIN_ROLE =
        uint256(keccak256(bytes("GRANT_TOKEN_ADMIN_ROLE")));
    uint256 constant public FAST_TRANSFER_ELIGIBLE_ROLE =
        uint256(keccak256(bytes("FAST_TRANSFER_ELIGIBLE_ROLE")));
    bytes4 constant public GRANT_TOKEN_INTERFACE_ID = 0x8fd617ec;

    bytes32 public constant SET_ZONE_ID = bytes32(uint256(1));

    bytes32 public constant ADMIN_SET_ID = bytes32(uint256(1));
    bytes32 public constant CREATOR_SET_ID = bytes32(uint256(2));
    bytes32 public constant EXECUTOR_SET_ID = bytes32(uint256(3));
    bytes32 public constant FINALIZER_SET_ID = bytes32(uint256(4));

    uint256 public constant OPERATOR_TYPE_ADMIN = 1;
    uint256 public constant OPERATOR_TYPE_CREATOR = 2;
    uint256 public constant OPERATOR_TYPE_EXECUTOR = 3;
    uint256 public constant OPERATOR_TYPE_FINALIZER = 4;
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library BoardStorage {

    struct Layout {

        bool initialized;

        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.txn.board.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../lib/AddressSet.sol";
import "../../hasher/HasherLib.sol";
import "../fiat-handler/FiatHandlerLib.sol";
import "../board/BoardLib.sol";
import "../Constants.sol";
import "./CouncilStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library CouncilInternal {

    event NewProposal(uint256 indexed proposalId);
    event ProposalUpdate(uint256 indexed proposalId);
    event ProposalFinalized(uint256 indexed proposalId);
    event ProposalExecuted(uint256 indexed proposalId);

    modifier mustBeInitialized() {
        require(__s().initialized, "CI:NI");
        _;
    }

    function _initialize(
        uint256 registereeId,
        address grantToken,
        address feeCollectionAccount,
        address icoCollectionAccount,
        uint256 proposalCreationFeeMicroUSD,
        uint256 adminProposalCreationFeeMicroUSD,
        uint256 icoTokenPriceMicroUSD,
        uint256 icoFeeMicroUSD
    ) internal {
        require(!__s().initialized, "CI:AI");
        require(grantToken != address(0), "CI:ZSTA");
        require(feeCollectionAccount != address(0), "CI:ZFCA");
        require(registereeId > 0, "CI:INVREGID");
        __s().registrar = msg.sender;
        __s().registereeId = registereeId;
        __s().grantToken = grantToken;
        __s().feeCollectionAccount = feeCollectionAccount;
        __s().icoCollectionAccount = icoCollectionAccount;
        __s().defaultHolderEligibilityThreshold = 0;
        __s().defaultProposalPassThreshold = 50; // more than 50% approval is needed
        __s().proposalCreationFeeMicroUSD = proposalCreationFeeMicroUSD;
        __s().adminProposalCreationFeeMicroUSD = adminProposalCreationFeeMicroUSD;
        if (icoTokenPriceMicroUSD > 0) {
            __s().icoPhase = true;
            __s().icoTokenPriceMicroUSD = icoTokenPriceMicroUSD;
        }
        __s().icoFeeMicroUSD = icoFeeMicroUSD;
        BoardLib._makeFinalizer(grantToken);
        // exclude council's balance from vote counting
        __s().possibleVotingExcluded.push(address(this));
        __s().votingExcludedMap[address(this)] = true;
        __s().initialized = true;
    }

    function _getCouncilSettings() internal view returns (
        address, // registrar
        uint256, // registereeId
        address, // grantToken
        uint256, // defaultHolderEligibilityThreshold
        uint256, // defaultProposalPassThreshold
        address, // feeCollectionAccount
        address, // icoCollectionAccount
        uint256, // proposalCreationFeeMicroUSD
        uint256, // adminProposalCreationFeeMicroUSD
        bool,    // icoPhase
        uint256, // icoTokenPriceMicroUSD,
        uint256  // icoFeeMicroUSD
    ) {
        return (
            __s().registrar,
            __s().registereeId,
            __s().grantToken,
            __s().defaultHolderEligibilityThreshold,
            __s().defaultProposalPassThreshold,
            __s().feeCollectionAccount,
            __s().icoCollectionAccount,
            __s().proposalCreationFeeMicroUSD,
            __s().adminProposalCreationFeeMicroUSD,
            __s().icoPhase,
            __s().icoTokenPriceMicroUSD,
            __s().icoFeeMicroUSD
        );
    }

    function _setCouncilSettings(
        address feeCollectionAccount,
        address icoCollectionAccount,
        uint256 proposalCreationFeeMicroUSD,
        uint256 adminProposalCreationFeeMicroUSD,
        bool icoPhase,
        uint256 icoTokenPriceMicroUSD,
        uint256 icoFeeMicroUSD
    ) internal mustBeInitialized {
        require(feeCollectionAccount != address(0), "CI:ZWFA");
        __s().feeCollectionAccount = feeCollectionAccount;
        __s().icoCollectionAccount = icoCollectionAccount;
        __s().proposalCreationFeeMicroUSD = proposalCreationFeeMicroUSD;
        __s().adminProposalCreationFeeMicroUSD = adminProposalCreationFeeMicroUSD;
        __s().icoPhase = icoPhase;
        __s().icoTokenPriceMicroUSD = icoTokenPriceMicroUSD;
        __s().icoFeeMicroUSD = icoFeeMicroUSD;
    }

    function _setDefaultHolderEligibilityThreshold(
        uint256 adminProposalId,
        uint256 newValue
    ) internal mustBeInitialized {
        require(newValue >= 0 && newValue <= 100, "CI:INVHET");
        __s().defaultHolderEligibilityThreshold = newValue;
        _executeAdminProposal(address(this), msg.sender, adminProposalId);
    }

    function _setDefaultProposalPassThreshold(
        uint256 adminProposalId,
        uint256 newValue
    ) internal mustBeInitialized {
        require(newValue >= 0 && newValue <= 100, "CI:INVPT");
        __s().defaultProposalPassThreshold = newValue;
        _executeAdminProposal(address(this), msg.sender, adminProposalId);
    }

    function _isVotingBlacklisted(address account) internal view returns (bool) {
        return __s().votingBlacklistMap[account];
    }

    function _blacklistVoting(
        uint256 adminProposalId,
        address account,
        bool blacklist
    ) internal {
        __s().possibleVotingBlacklist.push(account);
        __s().votingBlacklistMap[account] = blacklist;
        _executeAdminProposal(address(this), msg.sender, adminProposalId);
    }

    function _isVotingExcluded(address account) internal view returns (bool) {
        return __s().votingExcludedMap[account];
    }

    function _excludeVoting(
        uint256 adminProposalId,
        address account,
        bool excluded
    ) internal {
        __s().possibleVotingExcluded.push(account);
        __s().votingExcludedMap[account] = excluded;
        _executeAdminProposal(address(this), msg.sender, adminProposalId);
    }

    function _getNrOfProposals() internal view returns (uint256) {
        return __s().proposalIdCounter;
    }

    function _getProposalInfo(
        uint256 proposalId
    ) internal view returns (
        string memory, /* proposalURI */
        uint256, /* startTs */
        uint256, /* expireTs */
        string[] memory, /* tags */
        uint256, /* referenceProposalId */
        bool, /* true if an admin proposal */
        bool, /* true if executed */
        bool, /* true if finalized */
        uint256, /* finalizedTs */
        uint256, /* holderEligibilityThreshold */
        uint256  /* passThreshold */
    ) {
        CouncilStorage.Proposal storage proposal = __getProposal(proposalId);
        return (
            proposal.uri,
            proposal.startTs,
            proposal.expireTs,
            proposal.tags,
            proposal.referenceProposalId,
            proposal.admin,
            proposal.executed,
            proposal.finalized,
            proposal.finalizedTs,
            proposal.holderEligibilityThreshold,
            proposal.passThreshold
        );
    }

    function _getAdminProposalStats(
        uint256 adminProposalId
    ) internal view returns (
        // number of admins
        uint256,
        // list of admins approving the proposal
        address[] memory,
        // true if the proposal is passed
        bool
    ) {
        CouncilStorage.Proposal storage proposal = __getProposal(adminProposalId);
        require(proposal.admin, "CI:NAP");
        uint256 nrOfAdmins = AddressSetLib._getItemsCount(
            ConstantsLib.SET_ZONE_ID, ConstantsLib.ADMIN_SET_ID);
        bytes32 adminApprovalSetId = __getProposalSetId(adminProposalId, "ADMIN_APPROVAL");
        address[] memory approvingAdmins =
            AddressSetLib._getItems(ConstantsLib.SET_ZONE_ID, adminApprovalSetId);
        bool passed = approvingAdmins.length > (nrOfAdmins / 2);
        return (
            nrOfAdmins,
            approvingAdmins,
            passed
        );
    }

    function _getProposalStats(
        uint256 proposalId
    ) internal view returns (
        // list of accounts approved the proposal
        address[] memory,
        // list of the used balances one-to-one mapped to the approvers list
        uint256[] memory,
        // sum of the balances of approving accounts (balance of the grant tokens)
        uint256,
        // list of accounts rejected the proposal
        address[] memory,
        // list of the used balances one-to-one mapped to the rejectors list
        uint256[] memory,
        // sum of the balances of rejecting accounts (balance of the grant tokens)
        uint256,
        // true if the proposal is passed (or "passed so far" for non-expired
        // and non-finalized proposals)
        bool
    ) {
        CouncilStorage.Proposal storage proposal = __getProposal(proposalId);
        address[] memory approvers =
            AddressSetLib._getItems(
                ConstantsLib.SET_ZONE_ID, __getProposalSetId(proposalId, "APPROVAL"));
        uint256[] memory approverBalances = new uint256[](approvers.length);
        uint256 approvalsBalanceSum = 0;
        for (uint256 i = 0; i < approvers.length; i++) {
            if (proposal.finalized) {
                approverBalances[i] = proposal.fixatedBalances[approvers[i]];
                approvalsBalanceSum += approverBalances[i];
            } else {
                if (!__s().votingBlacklistMap[approvers[i]]) {
                    approverBalances[i] = IERC20(__s().grantToken).balanceOf(approvers[i]);
                    approvalsBalanceSum += approverBalances[i];
                }
            }
        }
        address[] memory rejectors =
            AddressSetLib._getItems(
                ConstantsLib.SET_ZONE_ID, __getProposalSetId(proposalId, "REJECTION"));
        uint256[] memory rejectorBalances = new uint256[](rejectors.length);
        uint256 rejectorsBalanceSum = 0;
        for (uint256 i = 0; i < rejectors.length; i++) {
            if (proposal.finalized) {
                rejectorBalances[i] = proposal.fixatedBalances[rejectors[i]];
                rejectorsBalanceSum += rejectorBalances[i];
            } else {
                if (!__s().votingBlacklistMap[rejectors[i]]) {
                    rejectorBalances[i] = IERC20(__s().grantToken).balanceOf(rejectors[i]);
                    rejectorsBalanceSum += rejectorBalances[i];
                }
            }
        }
        uint256 nrOfCirculatingTokens = __getNrOfCirculatingTokens();
        require(nrOfCirculatingTokens > 0, "CI:ZNRCT");
        require(approvalsBalanceSum <= nrOfCirculatingTokens, "CI:GABS");
        uint256 ratio = (100 * approvalsBalanceSum) / nrOfCirculatingTokens;
        return (
            approvers,
            approverBalances,
            approvalsBalanceSum,
            rejectors,
            rejectorBalances,
            rejectorsBalanceSum,
            ratio == 100 || ratio > proposal.passThreshold
        );
    }

    function _getPendingProposals() internal view returns (uint256[] memory) {
        uint256 counter = 0;
        {
            for (uint256 proposalId = 1; proposalId <= __s().proposalIdCounter; proposalId++) {
                CouncilStorage.Proposal storage proposal = __s().proposals[proposalId];
                if (!proposal.finalized) {
                    counter += 1;
                }
            }
        }
        uint256[] memory proposals = new uint256[](counter);
        uint256 j = 0;
        {
            for (uint256 proposalId = 1; proposalId <= __s().proposalIdCounter; proposalId++) {
                CouncilStorage.Proposal storage proposal = __s().proposals[proposalId];
                if (!proposal.finalized) {
                    proposals[j] = proposalId;
                    j += 1;
                }
            }
        }
        return proposals;
    }

    function _getAccountProposals(
        address account,
        bool onlyPending
    ) internal view returns (uint256[] memory) {
        uint256 counter = 0;
        {
            for (uint256 proposalId = 1; proposalId <= __s().proposalIdCounter; proposalId++) {
                CouncilStorage.Proposal storage proposal = __s().proposals[proposalId];
                bytes32 approvalSetId = __getProposalSetId(proposalId, "APPROVAL");
                bytes32 rejectionSetId = __getProposalSetId(proposalId, "REJECTION");
                if (
                    !proposal.admin &&
                    (!onlyPending || !proposal.finalized) &&
                    (
                        AddressSetLib._hasItem(ConstantsLib.SET_ZONE_ID, approvalSetId, account) ||
                        AddressSetLib._hasItem(ConstantsLib.SET_ZONE_ID, rejectionSetId, account)
                    )
                ) {
                    counter += 1;
                }
            }
        }
        uint256[] memory proposals = new uint256[](counter);
        uint256 j = 0;
        {
            for (uint256 proposalId = 1; proposalId <= __s().proposalIdCounter; proposalId++) {
                CouncilStorage.Proposal storage proposal = __s().proposals[proposalId];
                bytes32 approvalSetId = __getProposalSetId(proposalId, "APPROVAL");
                bytes32 rejectionSetId = __getProposalSetId(proposalId, "REJECTION");
                if (
                    !proposal.admin &&
                    (!onlyPending || !proposal.finalized) &&
                    (
                        AddressSetLib._hasItem(ConstantsLib.SET_ZONE_ID, approvalSetId, account) ||
                        AddressSetLib._hasItem(ConstantsLib.SET_ZONE_ID, rejectionSetId, account)
                    )
                ) {
                    proposals[j] = proposalId;
                    j += 1;
                }
            }
        }
        return proposals;
    }

    function _getAccountProposalStats(
        uint256 proposalId,
        address account
    ) internal view returns (
        // true if approved
        bool,
        // true if rejected
        bool,
        // used balance to approve or reject
        uint256
    ) {
        CouncilStorage.Proposal storage proposal = __getProposal(proposalId);
        bytes32 approvalSetId = __getProposalSetId(proposalId, "APPROVAL");
        bytes32 rejectionSetId = __getProposalSetId(proposalId, "REJECTION");
        bool isApprover = AddressSetLib._hasItem(ConstantsLib.SET_ZONE_ID, approvalSetId, account);
        bool isRejector = AddressSetLib._hasItem(ConstantsLib.SET_ZONE_ID, rejectionSetId, account);
        uint256 balance = 0;
        if (isApprover || isRejector) {
            if (proposal.finalized) {
                balance = proposal.fixatedBalances[account];
            } else {
                balance = IERC20(__s().grantToken).balanceOf(account);
            }
        }
        return (isApprover, isRejector, balance);
    }

    function _createProposal(
        bool admin,
        string memory proposalURI,
        uint256 startTs,
        uint256 expireTs,
        string[] memory tags,
        uint256 referenceProposalId,
        int256 holderEligibilityThreshold,
        int256 passThreshold,
        address payErc20,
        address payer
    ) internal mustBeInitialized {
        if (admin) {
            __mustBeAdmin(msg.sender);
            FiatHandlerLib._pay(FiatHandlerInternal.PayParams(
                payErc20,
                payer,
                __s().feeCollectionAccount,
                __s().adminProposalCreationFeeMicroUSD,
                msg.value,
                true, // return the remainder
                true  // consider discount
            ));
        } else {
            __mustBeCreator(msg.sender);
            FiatHandlerLib._pay(FiatHandlerInternal.PayParams(
                payErc20,
                payer,
                __s().feeCollectionAccount,
                __s().proposalCreationFeeMicroUSD,
                msg.value,
                true, // return the remainder
                true  // consider discount
            ));
        }
        uint256 proposalId = __s().proposalIdCounter + 1;
        __s().proposalIdCounter += 1;
        CouncilStorage.Proposal storage proposal = __s().proposals[proposalId];
        proposal.uri = proposalURI;
        proposal.startTs = startTs;
        proposal.expireTs = expireTs;
        proposal.tags = tags;
        proposal.referenceProposalId = referenceProposalId;
        proposal.admin = admin;
        if (!admin) {
            proposal.holderEligibilityThreshold = __s().defaultHolderEligibilityThreshold;
            if (holderEligibilityThreshold > 0) {
                proposal.holderEligibilityThreshold = uint256(holderEligibilityThreshold);
            }
            proposal.passThreshold = __s().defaultProposalPassThreshold;
            if (passThreshold > 0) {
                proposal.passThreshold = uint256(passThreshold);
            }
        }
        emit NewProposal(proposalId);
    }

    function _updateProposal(
        uint256 proposalId,
        string memory proposalURI,
        uint256 startTs,
        uint256 expireTs,
        string[] memory tags,
        uint256 referenceProposalId
    ) internal mustBeInitialized {
        __mustBeAdmin(msg.sender);
        CouncilStorage.Proposal storage proposal = __getProposal(proposalId);
        require(!proposal.finalized, "CI:FNLZED");
        proposal.uri = proposalURI;
        proposal.startTs = startTs;
        proposal.expireTs = expireTs;
        proposal.tags = tags;
        proposal.referenceProposalId = referenceProposalId;
        emit ProposalUpdate(proposalId);
    }

    function _updateHolderEligibilityThreshold(
        uint256 proposalId,
        uint256 newValue
    ) internal mustBeInitialized {
        __mustBeAdmin(msg.sender);
        CouncilStorage.Proposal storage proposal = __getProposal(proposalId);
        require(!proposal.finalized, "CI:FNLZED");
         // we don't have such a threshold for admin proposals
        require(!proposal.admin, "CI:ADMNP");
        bytes32 approvalSetId = __getProposalSetId(proposalId, "APPROVAL");
        bytes32 rejectionSetId = __getProposalSetId(proposalId, "REJECTION");
        require(AddressSetLib._getItemsCount(
            ConstantsLib.SET_ZONE_ID, approvalSetId) == 0, "CI:NZA");
        require(AddressSetLib._getItemsCount(
            ConstantsLib.SET_ZONE_ID, rejectionSetId) == 0, "CI:NZR");
        proposal.holderEligibilityThreshold = newValue;
        emit ProposalUpdate(proposalId);
    }

    function _updatePassThreshold(
        uint256 proposalId,
        uint256 newValue
    ) internal mustBeInitialized {
        __mustBeAdmin(msg.sender);
        CouncilStorage.Proposal storage proposal = __getProposal(proposalId);
        require(!proposal.finalized, "CI:FNLZED");
         // we don't have such a threshold for admin proposals
        require(!proposal.admin, "CI:ADMNP");
        proposal.passThreshold = newValue;
        emit ProposalUpdate(proposalId);
    }

    function _approveProposal(
        uint256 proposalId
    ) internal mustBeInitialized {
        CouncilStorage.Proposal storage proposal = __getProposal(proposalId);
        /* solhint-disable not-rely-on-time */
        require(block.timestamp < proposal.expireTs, "CI:EXPRD");
        /* solhint-enable not-rely-on-time */
        require(!proposal.finalized, "CI:FNLZED");
        if (proposal.admin) {
            __mustBeAdmin(msg.sender);
            bytes32 adminApprovalSetId = __getProposalSetId(proposalId, "ADMIN_APPROVAL");
            if (AddressSetLib._addItem(ConstantsLib.SET_ZONE_ID, adminApprovalSetId, msg.sender)) {
                emit ProposalUpdate(proposalId);
            }
        } else {
            __mustBeEligibleHolder(proposalId, msg.sender);
            require(!__s().votingBlacklistMap[msg.sender], "CI:BLCK");
            bool updated = false;
            bytes32 approvalSetId = __getProposalSetId(proposalId, "APPROVAL");
            bytes32 rejectionSetId = __getProposalSetId(proposalId, "REJECTION");
            if (AddressSetLib._removeItem(ConstantsLib.SET_ZONE_ID, rejectionSetId, msg.sender)) {
                updated = true;
            }
            if (AddressSetLib._addItem(ConstantsLib.SET_ZONE_ID, approvalSetId, msg.sender)) {
                updated = true;
            }
            if (updated) {
                emit ProposalUpdate(proposalId);
            }
        }
    }

    function _withdrawProposalApproval(
        uint256 proposalId
    ) internal mustBeInitialized {
        CouncilStorage.Proposal storage proposal = __getProposal(proposalId);
        /* solhint-disable not-rely-on-time */
        require(block.timestamp < proposal.expireTs, "CI:EXPRD");
        /* solhint-enable not-rely-on-time */
        require(!proposal.finalized, "CI:FNLZED");
        if (proposal.admin) {
            __mustBeAdmin(msg.sender);
            bytes32 adminApprovalSetId = __getProposalSetId(proposalId, "ADMIN_APPROVAL");
            if (AddressSetLib._removeItem(ConstantsLib.SET_ZONE_ID, adminApprovalSetId, msg.sender)) {
                emit ProposalUpdate(proposalId);
            }
        } else {
            // NOTE: we dissallow any grant-token transfer when there is an approval or
            //       rejection for a non-finalized proposal. Therefore, the following
            //       condition MUST hold.
            __mustBeEligibleHolder(proposalId, msg.sender);
            bytes32 approvalSetId = __getProposalSetId(proposalId, "APPROVAL");
            if (AddressSetLib._removeItem(ConstantsLib.SET_ZONE_ID, approvalSetId, msg.sender)) {
                emit ProposalUpdate(proposalId);
            }
        }
    }

    function _rejectProposal(
        uint256 proposalId
    ) internal mustBeInitialized {
        CouncilStorage.Proposal storage proposal = __getProposal(proposalId);
        /* solhint-disable not-rely-on-time */
        require(block.timestamp < proposal.expireTs, "CI:EXPRD");
        /* solhint-enable not-rely-on-time */
        require(!proposal.finalized, "CI:FNLZED");
        require(!proposal.admin, "CI:ADMINP");
        __mustBeEligibleHolder(proposalId, msg.sender);
        require(!__s().votingBlacklistMap[msg.sender], "CI:BLCK");
        bytes32 approvalSetId = __getProposalSetId(proposalId, "APPROVAL");
        bytes32 rejectionSetId = __getProposalSetId(proposalId, "REJECTION");
        bool updated = false;
        if (AddressSetLib._removeItem(ConstantsLib.SET_ZONE_ID, approvalSetId, msg.sender)) {
            updated = true;
        }
        if (AddressSetLib._addItem(ConstantsLib.SET_ZONE_ID, rejectionSetId, msg.sender)) {
            updated = true;
        }
        if (updated) {
            emit ProposalUpdate(proposalId);
        }
    }

    function _withdrawProposalRejection(
        uint256 proposalId
    ) internal mustBeInitialized {
        CouncilStorage.Proposal storage proposal = __getProposal(proposalId);
        /* solhint-disable not-rely-on-time */
        require(block.timestamp < proposal.expireTs, "CI:EXPRD");
        /* solhint-enable not-rely-on-time */
        require(!proposal.finalized, "CI:FNLZED");
        require(!proposal.admin, "CI:ADMINP");
        // NOTE: we dissallow any grant-token transfer when there is an approval or
        //       rejection for a non-finalized proposal. Therefore, the following
        //       condition MUST hold.
        __mustBeEligibleHolder(proposalId, msg.sender);
        bytes32 rejectionSetId = __getProposalSetId(proposalId, "REJECTION");
        if (AddressSetLib._removeItem(ConstantsLib.SET_ZONE_ID, rejectionSetId, msg.sender)) {
            emit ProposalUpdate(proposalId);
        }
    }

    function _finalizeProposal(
        uint256 proposalId
    ) internal mustBeInitialized {
        __mustBeAdmin(msg.sender);
        CouncilStorage.Proposal storage proposal = __getProposal(proposalId);
        require(!proposal.finalized, "CI:FNLZED");
        __finalize(proposalId);
    }

    function _executeAdminProposal(
        address caller,
        address executor,
        uint256 adminProposalId
    ) internal mustBeInitialized {
        __mustBeFinalizer(caller);
        __mustBeAdmin(executor);
        CouncilStorage.Proposal storage proposal = __getProposal(adminProposalId);
        require(proposal.admin, "CI:NADMNP");
        require(!proposal.finalized, "CI:FNLZED");
        require(!proposal.executed, "CI:EXECED");
        __finalize(adminProposalId);
        uint256 nrOfAdmins = AddressSetLib._getItemsCount(
            ConstantsLib.SET_ZONE_ID, ConstantsLib.ADMIN_SET_ID);
        bytes32 adminApprovalSetId = __getProposalSetId(adminProposalId, "ADMIN_APPROVAL");
        address[] memory approvingAdmins =
            AddressSetLib._getItems(ConstantsLib.SET_ZONE_ID, adminApprovalSetId);
        bool passed = approvingAdmins.length > (nrOfAdmins / 2);
        require(passed, "CI:NPASSED");
        proposal.executed = true;
        emit ProposalExecuted(adminProposalId);
    }

    function _executeProposal(
        address caller,
        address executor,
        uint256 proposalId
    ) internal mustBeInitialized {
        __mustBeFinalizer(caller);
        __mustBeExecutor(executor);
        CouncilStorage.Proposal storage proposal = __getProposal(proposalId);
        require(!proposal.admin, "CI:ADMNP");
        require(!proposal.finalized, "CI:FNLZED");
        require(!proposal.executed, "CI:EXECED");
        __finalize(proposalId);
        bytes32 approvalSetId = __getProposalSetId(proposalId, "APPROVAL");
        address[] memory approvers = AddressSetLib._getItems(
            ConstantsLib.SET_ZONE_ID, approvalSetId);
        uint256 approvalsBalanceSum = 0;
        for (uint256 i = 0; i < approvers.length; i++) {
            if (!__s().votingBlacklistMap[approvers[i]]) {
                approvalsBalanceSum += proposal.fixatedBalances[approvers[i]];
            }
        }
        uint256 nrOfCirculatingTokens = __getNrOfCirculatingTokens();
        require(nrOfCirculatingTokens > 0, "CI:ZNRCT");
        require(approvalsBalanceSum <= nrOfCirculatingTokens, "CI:GABS");
        uint256 ratio = (100 * approvalsBalanceSum) / nrOfCirculatingTokens;
        bool passed = ratio == 100 || ratio > proposal.passThreshold;
        require(passed, "CI:NPASSED");
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    function _transferTokensFromCouncil(
        uint256 adminProposalId,
        address to,
        uint256 amount
    ) internal mustBeInitialized {
        IERC20(__s().grantToken).transferFrom(address(this), to, amount);
        _executeAdminProposal(address(this), msg.sender, adminProposalId);
    }

    function _icoTransferTokensFromCouncil(
        address payErc20,
        address payer,
        address to,
        uint256 nrOfTokens
    ) internal mustBeInitialized {
        require(__s().icoPhase, "CI:NICO");
        require(__s().icoTokenPriceMicroUSD > 0, "CI:NICOP");
        IERC20(__s().grantToken).transferFrom(address(this), to, nrOfTokens);
        uint256 spentWei = FiatHandlerLib._pay(FiatHandlerInternal.PayParams(
            payErc20,
            payer,
            __s().feeCollectionAccount,
            __s().icoFeeMicroUSD,
            msg.value,
            false, // do not return the remainder
            false  // do not consider discount
        ));
        FiatHandlerLib._pay(FiatHandlerInternal.PayParams(
            payErc20,
            payer,
            __s().icoCollectionAccount,
            nrOfTokens * __s().icoTokenPriceMicroUSD,
            msg.value - spentWei,
            true, // return the remainder
            true  // consider discount
        ));
    }

    function __mustBeAdmin(address account) private view {
        require(BoardLib._isOperator(ConstantsLib.OPERATOR_TYPE_ADMIN, account), "CI:NA");
    }

    function __mustBeCreator(address account) private view {
        require(BoardLib._isOperator(ConstantsLib.OPERATOR_TYPE_CREATOR, account), "CI:NC");
    }

    function __mustBeExecutor(address account) private view {
        require(BoardLib._isOperator(ConstantsLib.OPERATOR_TYPE_EXECUTOR, account), "CI:NE");
    }

    function __mustBeFinalizer(address account) private view {
        require(
            account == address(this) ||
                BoardLib._isOperator(ConstantsLib.OPERATOR_TYPE_FINALIZER, account)
            , "CI:NF"
        );
    }

    function __mustBeEligibleHolder(uint256 proposalId, address account) private view {
        uint256 accountBalance = IERC20(__s().grantToken).balanceOf(account);
        uint256 ratio = (100 * accountBalance) / IERC20(__s().grantToken).totalSupply();
        require(ratio >= __s().proposals[proposalId].holderEligibilityThreshold, "CI:NELGH");
    }

    function __getProposal(
        uint256 proposalId
    ) private view returns (CouncilStorage.Proposal storage) {
        require(proposalId > 0 && proposalId <= __s().proposalIdCounter, "CI:PNF");
        return __s().proposals[proposalId];
    }

    function __getProposalSetId(
        uint256 proposalId,
        string memory voteCategory
    ) private pure returns (bytes32) {
        for(uint256 i = 1; i <= 10; i++) {
            bytes32 hash = HasherLib._mixHash4(
                HasherLib._hashStr("PROPOSAL_ID"),
                HasherLib._hashInt(proposalId),
                HasherLib._hashStr(voteCategory),
                HasherLib._hashInt(i)
            );
            if (uint256(hash) > 100) {
              return hash;
            }
        }
        revert("CI:SWW");
    }

    function __finalize(uint256 proposalId) private {
        CouncilStorage.Proposal storage proposal = __getProposal(proposalId);
        if (!proposal.admin) {
            bytes32 approvalSetId = __getProposalSetId(proposalId, "APPROVAL");
            bytes32 rejectionSetId = __getProposalSetId(proposalId, "REJECTION");
            address[] memory approvers = AddressSetLib._getItems(
                ConstantsLib.SET_ZONE_ID, approvalSetId);
            for (uint256 i = 0; i < approvers.length; i++) {
                address account = approvers[i];
                proposal.fixatedBalances[account] =
                    IERC20(__s().grantToken).balanceOf(account);
            }
            address[] memory rejectors = AddressSetLib._getItems(
                ConstantsLib.SET_ZONE_ID, rejectionSetId);
            for (uint256 i = 0; i < rejectors.length; i++) {
                address account = rejectors[i];
                proposal.fixatedBalances[account] =
                    IERC20(__s().grantToken).balanceOf(account);
            }
        }
        proposal.finalized = true;
        /* solhint-disable not-rely-on-time */
        proposal.finalizedTs = block.timestamp;
        /* solhint-enable not-rely-on-time */
        emit ProposalFinalized(proposalId);
    }

    function __getNrOfCirculatingTokens() private view returns (uint256) {
        IERC20 grantToken = IERC20(__s().grantToken);
        uint256 nrOfTokens = grantToken.totalSupply();
        for (uint256 i = 0; nrOfTokens > 0 && i < __s().possibleVotingExcluded.length; i++) {
            address account = __s().possibleVotingExcluded[i];
            if (__s().votingExcludedMap[account]) {
                uint256 balance = grantToken.balanceOf(account);
                require(balance <= nrOfTokens, "CI:GB");
                nrOfTokens -= balance;
            }
        }
        return nrOfTokens;
    }

    function __s() private pure returns (CouncilStorage.Layout storage) {
        return CouncilStorage.layout();
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

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

library HasherLib {

    function _hashAddress(address addr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr));
    }

    function _hashStr(string memory str) internal pure returns (bytes32) {
        return keccak256(bytes(str));
    }

    function _hashInt(uint256 num) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("INT", num));
    }

    function _hashAccount(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("ACCOUNT", account));
    }

    function _hashVault(address vault) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("VAULT", vault));
    }

    function _hashReserveId(uint256 reserveId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("RESERVEID", reserveId));
    }

    function _hashContract(address contractAddr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("CONTRACT", contractAddr));
    }

    function _hashTokenId(uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("TOKENID", tokenId));
    }

    function _hashRole(string memory roleName) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("ROLE", roleName));
    }

    function _hashLedgerId(uint256 ledgerId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("LEDGERID", ledgerId));
    }

    function _mixHash2(
        bytes32 d1,
        bytes32 d2
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("MIX2_", d1, d2));
    }

    function _mixHash3(
        bytes32 d1,
        bytes32 d2,
        bytes32 d3
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("MIX3_", d1, d2, d3));
    }

    function _mixHash4(
        bytes32 d1,
        bytes32 d2,
        bytes32 d3,
        bytes32 d4
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("MIX4_", d1, d2, d3, d4));
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./FiatHandlerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library FiatHandlerLib {

    function _pay(
        FiatHandlerInternal.PayParams memory params
    ) internal returns (uint256) {
        return FiatHandlerInternal._pay(params);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./BoardInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library BoardLib {

    function _isOperator(uint256 operatorType, address account) internal view returns (bool) {
        return BoardInternal._isOperator(operatorType, account);
    }

    function _makeFinalizer(address account) internal {
        BoardInternal._makeFinalizer(account);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library CouncilStorage {

    struct Proposal {

        bool admin;
        string uri;
        string[] tags;

        uint256 startTs;
        uint256 expireTs;
        uint256 finalizedTs;

        uint256 referenceProposalId;

        bool executed;
        bool finalized;

        // vvv used only in non-admin proposals vvv

        // percentage of the holder ownership to
        // the total number of grant tokens
        uint256 holderEligibilityThreshold;
        // percentage of the approved total balance to
        // the total number of grant tokens
        uint256 passThreshold;

        // the mapping of balances at the time of finalization
        mapping(address => uint256) fixatedBalances;

        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    struct Layout {

        bool initialized;

        address registrar;
        uint256 registereeId;
        address grantToken;

        uint256 proposalIdCounter;
        mapping(uint256 => Proposal) proposals;

        // percentage of the holder ownership to
        // the total number of grant tokens
        uint256 defaultHolderEligibilityThreshold;
        // percentage of the approved total balance to
        // the total number of grant tokens
        uint256 defaultProposalPassThreshold;

        // ETH fee to be collected for each proposal creation
        uint256 proposalCreationFeeMicroUSD;

        // ETH fee to be collected for each admin proposal creation
        uint256 adminProposalCreationFeeMicroUSD;

        address feeCollectionAccount;
        address icoCollectionAccount;

        bool icoPhase;
        uint256 icoTokenPriceMicroUSD;
        uint256 icoFeeMicroUSD;

        address[] possibleVotingBlacklist;
        mapping(address => bool) votingBlacklistMap;

        address[] possibleVotingExcluded;
        mapping(address => bool) votingExcludedMap;

        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.txn.council.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FiatHandlerStorage.sol";
import "../../../uniswap-v2/interfaces/IUniswapV2Factory.sol";
import "../../../uniswap-v2/interfaces/IUniswapV2Pair.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library FiatHandlerInternal {

    event WeiDiscount(
        uint256 indexed payId,
        address indexed payer,
        uint256 totalMicroUSDAmountBeforeDiscount,
        uint256 totalWeiBeforeDiscount,
        uint256 discountWei
    );
    event WeiPay(
        uint256 indexed payId,
        address indexed payer,
        address indexed dest,
        uint256 totalMicroUSDAmountBeforeDiscount,
        uint256 totalWeiAfterDiscount
    );
    event Erc20Discount(
        uint256 indexed payId,
        address indexed payer,
        uint256 totalMicroUSDAmountBeforeDiscount,
        address indexed erc20,
        uint256 totalTokensBeforeDiscount,
        uint256 discountTokens
    );
    event Erc20Pay(
        uint256 indexed payId,
        address indexed payer,
        address indexed dest,
        uint256 totalMicroUSDAmountBeforeDiscount,
        address erc20,
        uint256 totalTokensAfterDiscount
    );
    event TransferWeiTo(
        address indexed to,
        uint256 indexed amount
    );
    event TransferErc20To(
        address indexed erc20,
        address indexed to,
        uint256 amount
    );

    modifier mustBeInitialized() {
        require(__s().initialized, "FHI:NI");
        _;
    }

    function _initialize(
        address uniswapV2Factory,
        address wethAddress,
        address microUSDAddress,
        uint256 maxNegativeSlippage
    ) internal {
        require(!__s().initialized, "CI:AI");
        require(uniswapV2Factory != address(0), "FHI:ZFA");
        require(wethAddress != address(0), "FHI:ZWA");
        require(microUSDAddress != address(0), "FHI:ZMUSDA");
        require(maxNegativeSlippage >= 0 && maxNegativeSlippage <= 10, "FHI:WMNS");
        __s().uniswapV2Factory = uniswapV2Factory;
        __s().wethAddress = wethAddress;
        __s().microUSDAddress = microUSDAddress;
        __s().maxNegativeSlippage = maxNegativeSlippage;
        __s().payIdCounter = 1000;
        // by default allow WETH and USDT
        _setErc20Allowed(wethAddress, true);
        _setErc20Allowed(microUSDAddress, true);
        __s().initialized = true;
    }

    function _getFiatHandlerSettings()
    internal view returns (
        address, // uniswapV2Factory
        address, // wethAddress
        address, // microUSDAddress
        uint256  // maxNegativeSlippage
    ) {
        return (
            __s().uniswapV2Factory,
            __s().wethAddress,
            __s().microUSDAddress,
            __s().maxNegativeSlippage
        );
    }

    function _setFiatHandlerSettings(
        address uniswapV2Factory,
        address wethAddress,
        address microUSDAddress,
        uint256 maxNegativeSlippage
    ) internal mustBeInitialized {
        require(uniswapV2Factory != address(0), "FHI:ZFA");
        require(wethAddress != address(0), "FHI:ZWA");
        require(microUSDAddress != address(0), "FHI:ZMUSDA");
        require(maxNegativeSlippage >= 0 && maxNegativeSlippage <= 10, "FHI:WMNS");
        __s().wethAddress = wethAddress;
        __s().microUSDAddress = microUSDAddress;
        __s().maxNegativeSlippage = maxNegativeSlippage;
        __s().maxNegativeSlippage = maxNegativeSlippage;
    }

    function _getDiscount(address erc20) internal view returns (bool, bool, uint256, uint256) {
        FiatHandlerStorage.Discount storage discount;
        if (erc20 == address(0)) {
            discount = __s().weiDiscount;
        } else {
            discount = __s().erc20Discounts[erc20];
        }
        return (
            discount.enabled,
            discount.useFixed,
            discount.discountF,
            discount.discountP
        );
    }

    function _setDiscount(
        address erc20,
        bool enabled,
        bool useFixed,
        uint256 discountF,
        uint256 discountP
    ) internal {
        require(discountP >= 0 && discountP <= 100, "FHI:WDP");
        FiatHandlerStorage.Discount storage discount;
        if (erc20 == address(0)) {
            discount = __s().weiDiscount;
        } else {
            discount = __s().erc20Discounts[erc20];
        }
        discount.enabled = enabled;
        discount.useFixed = useFixed;
        discount.discountF = discountF;
        discount.discountP = discountP;
    }

    function _getListOfErc20s() internal view returns (address[] memory) {
        return __s().erc20sList;
    }

    function _isErc20Allowed(address erc20) internal view returns (bool) {
        return __s().allowedErc20s[erc20];
    }

    function _setErc20Allowed(address erc20, bool allowed) internal {
        __s().allowedErc20s[erc20] = allowed;
        if (__s().erc20sListIndex[erc20] == 0) {
            __s().erc20sList.push(erc20);
            __s().erc20sListIndex[erc20] = __s().erc20sList.length;
        }
    }

    function _transferTo(
        address erc20,
        address to,
        uint256 amount,
        string memory /* data */
    ) internal {
        require(to != address(0), "FHI:TTZ");
        require(amount > 0, "FHI:ZAM");
        if (erc20 == address(0)) {
            require(amount <= address(this).balance, "FHI:MTB");
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = to.call{value: amount}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "FHI:TF");
            emit TransferWeiTo(to, amount);
        } else {
            require(amount <= IERC20(erc20).balanceOf(address(this)), "FHI:MTB");
            bool success = IERC20(erc20).transfer(to, amount);
            require(success, "FHI:TF2");
            emit TransferErc20To(erc20, to, amount);
        }
    }

    struct PayParams {
        address erc20;
        address payer;
        address payout;
        uint256 microUSDAmount;
        uint256 availableValue;
        bool returnRemainder;
        bool considerDiscount;
    }
    function _pay(
        PayParams memory params
    ) internal mustBeInitialized returns (uint256) {
        require(params.payer != address(0), "FHI:ZP");
        if (params.microUSDAmount == 0) {
            return 0;
        }
        if (params.erc20 != address(0)) {
            require(__s().allowedErc20s[params.erc20], "FHI:CNA");
        }
        uint256 payId = __s().payIdCounter + 1;
        __s().payIdCounter += 1;
        address dest = address(this);
        if (params.payout != address(0)) {
            dest = params.payout;
        }
        if (params.erc20 == address(0)) {
            uint256 weiAmount = _convertMicroUSDToWei(params.microUSDAmount);
            uint256 discount = 0;
            if (params.considerDiscount) {
                discount = _calcDiscount(address(0), weiAmount);
            }
            if (discount > 0) {
                emit WeiDiscount(
                    payId, params.payer, params.microUSDAmount, weiAmount, discount);
                weiAmount -= discount;
            }
            if (params.availableValue < weiAmount) {
                uint256 diff = weiAmount - params.availableValue;
                uint256 slippage = (diff * 100) / weiAmount;
                require(slippage < __s().maxNegativeSlippage, "FHI:XMNS");
                return 0;
            }
            if (dest != address(this) && weiAmount > 0) {
                /* solhint-disable avoid-low-level-calls */
                (bool success,) = dest.call{value: weiAmount}(new bytes(0));
                /* solhint-enable avoid-low-level-calls */
                require(success, "FHI:TRF");
            }
            emit WeiPay(payId, params.payer, dest, params.microUSDAmount, weiAmount);
            if (params.returnRemainder && params.availableValue >= weiAmount) {
                uint256 remainder = params.availableValue - weiAmount;
                if (remainder > 0) {
                    /* solhint-disable avoid-low-level-calls */
                    (bool success2, ) = params.payer.call{value: remainder}(new bytes(0));
                    /* solhint-enable avoid-low-level-calls */
                    require(success2, "FHI:TRF2");
                }
            }
            return weiAmount;
        } else {
            uint256 tokensAmount = _convertMicroUSDToERC20(params.erc20, params.microUSDAmount);
            uint256 discount = 0;
            if (params.considerDiscount) {
                discount = _calcDiscount(params.erc20, tokensAmount);
            }
            if (discount > 0) {
                emit Erc20Discount(
                    payId, params.payer, params.microUSDAmount, params.erc20, tokensAmount, discount);
                tokensAmount -= discount;
            }
            require(tokensAmount <=
                    IERC20(params.erc20).balanceOf(params.payer), "FHI:NEB");
            require(tokensAmount <=
                    IERC20(params.erc20).allowance(params.payer, address(this)), "FHI:NEA");
            if (tokensAmount > 0) {
                IERC20(params.erc20).transferFrom(params.payer, dest, tokensAmount);
            }
            emit Erc20Pay(
                payId, params.payer, dest, params.microUSDAmount, params.erc20, tokensAmount);
            return 0;
        }
    }

    function _convertMicroUSDToWei(uint256 microUSDAmount) internal view returns (uint256) {
        require(__s().wethAddress != address(0), "FHI:ZWA");
        require(__s().microUSDAddress != address(0), "FHI:ZMUSDA");
        (bool pairFound, uint256 wethReserve, uint256 microUSDReserve) =
            __getReserves(__s().wethAddress, __s().microUSDAddress);
        require(pairFound && microUSDReserve > 0, "FHI:NPF");
        return (microUSDAmount * wethReserve) / microUSDReserve;
    }

    function _convertWeiToMicroUSD(uint256 weiAmount) internal view returns (uint256) {
        require(__s().wethAddress != address(0), "FHI:ZWA");
        require(__s().microUSDAddress != address(0), "FHI:ZMUSDA");
        (bool pairFound, uint256 wethReserve, uint256 microUSDReserve) =
            __getReserves(__s().wethAddress, __s().microUSDAddress);
        require(pairFound && wethReserve > 0, "FHI:NPF");
        return (weiAmount * microUSDReserve) / wethReserve;
    }

    function _convertMicroUSDToERC20(
        address erc20,
        uint256 microUSDAmount
    ) internal view returns (uint256) {
        require(__s().microUSDAddress != address(0), "FHI:ZMUSDA");
        if (erc20 == __s().microUSDAddress) {
            return microUSDAmount;
        }
        (bool microUSDPairFound, uint256 microUSDReserve, uint256 tokensReserve) =
            __getReserves(__s().microUSDAddress, erc20);
        if (microUSDPairFound && microUSDReserve > 0) {
            return (microUSDAmount * tokensReserve) / microUSDReserve;
        } else {
            require(__s().wethAddress != address(0), "FHI:ZWA");
            (bool pairFound, uint256 wethReserve, uint256 microUSDReserve2) =
                __getReserves(__s().wethAddress, __s().microUSDAddress);
            require(pairFound && microUSDReserve2 > 0, "FHI:NPF");
            uint256 weiAmount = (microUSDAmount * wethReserve) / microUSDReserve2;
            (bool wethPairFound, uint256 wethReserve2, uint256 tokensReserve2) =
                __getReserves(__s().wethAddress, erc20);
            require(wethPairFound && wethReserve2 > 0, "FHI:NPF2");
            return (weiAmount * tokensReserve2) / wethReserve2;
        }
    }

    function _convertERC20ToMicroUSD(
        address erc20,
        uint256 tokensAmount
    ) internal view returns (uint256) {
        require(__s().microUSDAddress != address(0), "FHI:ZMUSDA");
        if (erc20 == __s().microUSDAddress) {
            return tokensAmount;
        }
        (bool microUSDPairFound, uint256 microUSDReserve, uint256 tokensReserve) =
            __getReserves(__s().microUSDAddress, erc20);
        if (microUSDPairFound && tokensReserve > 0) {
            return (tokensAmount * microUSDReserve) / tokensReserve;
        } else {
            require(__s().wethAddress != address(0), "FHI:ZWA");
            (bool wethPairFound, uint256 wethReserve, uint256 tokensReserve2) =
                __getReserves(__s().wethAddress, erc20);
            require(wethPairFound && wethReserve > 0, "FHI:NPF");
            uint256 weiAmount = (tokensAmount * wethReserve) / tokensReserve2;
            (bool pairFound, uint256 wethReserve2, uint256 microUSDReserve2) =
                __getReserves(__s().wethAddress, __s().microUSDAddress);
            require(pairFound && wethReserve2 > 0, "FHI:NPF2");
            return (weiAmount * microUSDReserve2) / wethReserve2;
        }
    }

    function _calcDiscount(
        address erc20,
        uint256 amount
    ) internal view returns (uint256) {
        FiatHandlerStorage.Discount storage discount;
        if (erc20 == address(0)) {
            discount = __s().weiDiscount;
        } else {
            discount = __s().erc20Discounts[erc20];
        }
        if (!discount.enabled) {
            return 0;
        }
        if (discount.useFixed) {
            if (amount < discount.discountF) {
                return amount;
            }
            return discount.discountF;
        }
        return (amount * discount.discountP) / 100;
    }

    function __getReserves(
        address erc200,
        address erc201
    ) private view returns (bool, uint256, uint256) {
        address pair = IUniswapV2Factory(
            __s().uniswapV2Factory).getPair(erc200, erc201);
        if (pair == address(0)) {
            return (false, 0, 0);
        }
        address token1 = IUniswapV2Pair(pair).token1();
        (uint112 amount0, uint112 amount1,) = IUniswapV2Pair(pair).getReserves();
        uint256 reserve0 = amount0;
        uint256 reserve1 = amount1;
        if (token1 == erc200) {
            reserve0 = amount1;
            reserve1 = amount0;
        }
        return (true, reserve0, reserve1);
    }

    function __s() private pure returns (FiatHandlerStorage.Layout storage) {
        return FiatHandlerStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library FiatHandlerStorage {

    struct Discount {
        bool enabled;
        bool useFixed;
        uint256 discountF;
        uint256 discountP;
        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    struct Layout {
        bool initialized;

        // UniswapV2Factory contract address:
        //  On mainnet: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        address uniswapV2Factory;
        // WETH ERC-20 contract address:
        //   On mainnet: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        address wethAddress;
        // USDT ERC-20 contract address:
        //   On Mainnet: 0xdAC17F958D2ee523a2206206994597C13D831ec7
        address microUSDAddress;

        uint256 payIdCounter;
        uint256 maxNegativeSlippage;

        Discount weiDiscount;
        mapping(address => Discount) erc20Discounts;

        address[] erc20sList;
        mapping(address => uint256) erc20sListIndex;
        mapping(address => bool) allowedErc20s;

        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.txn.fiat-handler.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}