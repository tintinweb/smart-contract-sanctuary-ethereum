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
import "./TestPhonebookInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
contract TestPhonebookFacet is IDiamondFacet {

    function getFacetName() external pure override returns (string memory) {
        return "test-phonebook";
    }

    function getFacetVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function getFacetPI() external pure override returns (string[] memory) {
        string[] memory pi = new string[](4);
        pi[0] = "init()";
        pi[1] = "getNrOfEntries()";
        pi[2] = "getEntry(uint256)";
        pi[3] = "addEntry(string,string,string)";
        return pi;
    }

    function getFacetProtectedPI() external pure override returns (string[] memory) {
        string[] memory pi = new string[](2);
        pi[0] = "init()";
        pi[1] = "addEntry(string,string,string)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId ||
               interfaceId == 0xaabbccdd;
    }

    function init() external {
        TestPhonebookInternal._init();
    }

    function getNrOfEntries() external view returns (uint256) {
        return TestPhonebookInternal._getNrOfEntries();
    }

    function getEntry(uint256 id)
      external view returns (string memory, string memory, string memory) {
        return TestPhonebookInternal._getEntry(id);
    }

    function addEntry(
        string memory name,
        string memory family,
        string memory phone
    ) external {
        TestPhonebookInternal._addEntry(name, family, phone);
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

import "./TestPhonebookStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library TestPhonebookInternal {

    event EntryAdd(uint256 id, string name, string family, string phone);

    function _init() internal {
        __s().entryIdCounter = 1;
    }

    function _getNrOfEntries() internal view returns (uint256) {
        return __s().entryIdCounter - 1;
    }

    function _getEntry(uint256 id) internal view returns (string memory, string memory, string memory) {
        require(id < __s().entryIdCounter, "TSI: entry does not exist");
        TestPhonebookStorage.PhonebookEntry memory entry = __s().entries[id];
        return (entry.name, entry.family, entry.phone);
    }

    function _addEntry(
        string memory name,
        string memory family,
        string memory phone
    ) internal {
        uint256 id = __s().entryIdCounter;
        __s().entryIdCounter += 1;
        TestPhonebookStorage.PhonebookEntry memory entry =
            TestPhonebookStorage.PhonebookEntry(id, name, family, phone);
        __s().entries[id] = entry;
        emit EntryAdd(id, name, family, phone);
    }

    function __s() private pure returns (TestPhonebookStorage.Layout storage) {
        return TestPhonebookStorage.layout();
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
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library TestPhonebookStorage {

    struct PhonebookEntry {
        uint256 id;
        string name;
        string family;
        string phone;
    }

    struct Layout {
        uint256 entryIdCounter;
        mapping(uint256 => PhonebookEntry) entries;
    }

    // Storage Slot: 72b891ce12c406bdebbb99a78c6573faf4d53c1a4d8ff48fc445eb7dd5b9d4ab
    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.test-phonebook-facet.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}