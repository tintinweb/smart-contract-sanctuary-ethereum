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
import "./IRegistrar.sol";
import "./RegistrarInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract RegistrarFacet is IDiamondFacet, IRegistrar {

    function getFacetName()
      external pure override returns (string memory) {
        return "registrar";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "2.1.1";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](15);
        pi[ 0] = "initializeRegistrar(address,address,string,string,address,address)";
        pi[ 1] = "getDeedRegistry()";
        pi[ 2] = "getCatalog()";
        pi[ 3] = "getRegistrarName()";
        pi[ 4] = "setRegistrarName(string)";
        pi[ 5] = "getRegistrarURI()";
        pi[ 6] = "setRegistrarURI(string)";
        pi[ 7] = "getContractKeys()";
        pi[ 8] = "getContract(string)";
        pi[ 9] = "setContract(string,address)";
        pi[10] = "getNrOfRegisterees()";
        pi[11] = "getRegistereeInfo(uint256)";
        pi[12] = "setRegistereeName(uitn256,string)";
        pi[13] = "setRegistereeTags(uitn256,string[])";
        pi[14] = "register(string,string,string,string,uint256,address,address,address[][4],uint256[4],address[3],uint256)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](6);
        pi[ 0] = "setRegistrarName(string)";
        pi[ 1] = "setRegistrarURI(string)";
        pi[ 2] = "setContract(string,address)";
        pi[ 3] = "setRegistereeName(uitn256,string)";
        pi[ 4] = "setRegistereeTags(uitn256,string[])";
        pi[ 5] = "register(string,string,string,string,uint256,address,address,address[][4],uint256[4],address[3],uint256)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return
            interfaceId == type(IDiamondFacet).interfaceId ||
            interfaceId == type(ICatalog).interfaceId;
    }

    function initializeRegistrar(
        address deedRegistry,
        address catalog,
        string memory registrarName,
        string memory registrarURI,
        address defaultTaskManager,
        address defaultAuthzSource
    ) external override {
        RegistrarInternal._initialize(
            deedRegistry,
            catalog,
            registrarName,
            registrarURI,
            defaultTaskManager,
            defaultAuthzSource
        );
    }

    function getDeedRegistry() external view override returns (address) {
        return RegistrarInternal._getDeedRegistry();
    }

    function getCatalog() external view override returns (address) {
        return RegistrarInternal._getCatalog();
    }

    function getRegistrarName() external view returns (string memory) {
        return RegistrarInternal._getRegistrarName();
    }

    function setRegistrarName(string memory name) external {
        RegistrarInternal._setRegistrarName(name);
    }

    function getRegistrarURI() external view returns (string memory) {
        return RegistrarInternal._getRegistrarURI();
    }

    function setRegistrarURI(string memory uri) external {
        RegistrarInternal._setRegistrarURI(uri);
    }

    function getContractKeys() external view returns (string[] memory) {
        return RegistrarInternal._getContractKeys();
    }

    function getContract(string memory key) external view returns (address) {
        return RegistrarInternal._getContract(key);
    }

    function setContract(string memory key, address contractAddr) external {
        RegistrarInternal._setContract(key, contractAddr);
    }

    function getNrOfRegisterees() external view returns (uint256) {
        return RegistrarInternal._getNrOfRegisterees();
    }

    function getRegistereeInfo(
        uint256 registereeId
    ) external view returns (
        string memory, // name of the registeree
        address, // address of the GrantToken contract
        address, // address of the Council contract
        string[] memory // tags attached to this instance of registeree
    ) {
        return RegistrarInternal._getRegistereeInfo(registereeId);
    }

    function setRegistereeName(
        uint256 registereeId,
        string memory name
    ) external {
        RegistrarInternal._setRegistereeName(registereeId, name);
    }

    function setRegistereeTags(
        uint256 registereeId,
        string[] memory tags
    ) external {
        RegistrarInternal._setRegistereeTags(registereeId, tags);
    }

    function register(
        string memory name,
        string memory deedURI,
        string memory grantTokenName,
        string memory grantTokenSymbol,
        uint256 grantTokenTotalSupply,
        address feeCollectionAccount,
        address icoCollectionAccount,
        address[][4] memory councilBodies,
        uint256[4] memory pricesMicroUSD,
        address[3] memory payAddresses,
        uint256 maxNegativeSlippage
    ) external {
        RegistrarInternal._register(
            RegistrarInternal.RegisterParams(
                name,
                deedURI,
                grantTokenName,
                grantTokenSymbol,
                grantTokenTotalSupply,
                feeCollectionAccount,
                icoCollectionAccount,
                councilBodies,
                pricesMicroUSD,
                payAddresses,
                maxNegativeSlippage
            )
        );
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
interface IRegistrar {

    function initializeRegistrar(
        address deedRegistry,
        address catalog,
        string memory registrarName,
        string memory registrarURI,
        address defaultTaskManager,
        address defaultAuthzSource
    ) external;

    function getDeedRegistry() external view returns (address);

    function getCatalog() external view returns (address);
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

import "../DiamondHelper.sol";
import "../deed-registry/IDeedRegistry.sol";
import "../catalog/ICatalog.sol";
import "../grant-token/IGrantTokenInitializer.sol";
import "../council/ICouncil.sol";
import "../board/IBoard.sol";
import "../fiat-handler/IFiatHandler.sol";
import "./RegistrarStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RegistrarInternal {

    // TODO(kam): deploy treasury and trader

    event Registration(
        uint256 indexed registereeId
    );
    event RegistereeUpdate(
        uint256 indexed registereeId
    );
    event RegistrarUpdate();

    function _initialize(
        address deedRegistry,
        address catalog,
        string memory registrarName,
        string memory registrarURI,
        address defaultTaskManager,
        address defaultAuthzSource
    ) internal {
        require(!__s().initialized, "RI:AI");
        __s().deedRegistry = deedRegistry;
        __s().catalog = catalog;
        __s().registrarName = registrarName;
        __s().registrarURI = registrarURI;
        _setContract("task-manager", defaultTaskManager);
        _setContract("authz-source", defaultAuthzSource);
        __s().initialized = true;
        emit RegistrarUpdate();
    }

    function _getDeedRegistry() internal view returns (address) {
        return __s().deedRegistry;
    }

    function _getCatalog() internal view returns (address) {
        return __s().catalog;
    }

    function _getRegistrarName() internal view returns (string memory) {
        return __s().registrarName;
    }

    function _setRegistrarName(string memory name) internal {
        __s().registrarName = name;
        emit RegistrarUpdate();
    }

    function _getRegistrarURI() internal view returns (string memory) {
        return __s().registrarURI;
    }

    function _setRegistrarURI(string memory uri) internal {
        __s().registrarURI = uri;
        emit RegistrarUpdate();
    }

    function _getContractKeys() internal view returns (string[] memory) {
        return __s().contractKeys;
    }

    function _getContract(string memory key) internal view returns (address) {
        return __getContract(key);
    }

    function _setContract(string memory key, address contractAddr) internal {
        __addContractKey(key);
        __s().contracts[key] = contractAddr;
    }

    function _getNrOfRegisterees() internal view returns (uint256) {
        return __s().registereeIdCounter;
    }

    function _getRegistereeInfo(
        uint256 registereeId
    ) internal view returns (
        string memory, // name of the registeree
        address, // address of the GrantToken contract
        address, // address of the Council contract
        string[] memory // tags attached to this instance of registeree
    ) {
        require(registereeId > 0 && registereeId <= __s().registereeIdCounter, "RI:RNF");
        RegistrarStorage.Registeree storage registeree = __s().registerees[registereeId];
        return (
            registeree.name,
            registeree.grantToken,
            registeree.council,
            registeree.tags
        );
    }

    function _setRegistereeName(
        uint256 registereeId,
        string memory name
    ) internal {
        require(registereeId > 0 && registereeId <= __s().registereeIdCounter, "RI:RNF");
        RegistrarStorage.Registeree storage registeree = __s().registerees[registereeId];
        registeree.name = name;
        emit RegistereeUpdate(registereeId);
    }

    function _setRegistereeTags(
        uint256 registereeId,
        string[] memory tags
    ) internal {
        require(registereeId > 0 && registereeId <= __s().registereeIdCounter, "RI:RNF");
        RegistrarStorage.Registeree storage registeree = __s().registerees[registereeId];
        registeree.tags = tags;
        emit RegistereeUpdate(registereeId);
    }

    struct RegisterParams {
        string name;
        string deedURI;
        string grantTokenName;
        string grantTokenSymbol;
        uint256 nrOfGrantTokens;
        address feeCollectionAccount;
        address icoCollectionAccount;
        address[][4] councilBodies;
        uint256[4] pricesMicroUSD;
        address[3] payAddresses;
        uint256 maxNegativeSlippage;
    }
    function _register(
        RegisterParams memory params
    ) internal {
        require(__s().initialized, "RI:NI");
        require(params.councilBodies[0].length >= 3, "RI:NEA");
        require(params.councilBodies[1].length >= 1, "RI:NEC");
        require(params.councilBodies[2].length >= 1, "RI:NEE");
        uint256 registereeId = __s().registereeIdCounter + 1;
        __s().registereeIdCounter += 1;
        RegistrarStorage.Registeree storage registeree = __s().registerees[registereeId];
        registeree.name = params.name;
        // deploy the contracts
        registeree.grantToken = __createGrantToken(params.name);
        registeree.council = __createCouncil(params.name);
        // initialize the grant token contract
        IGrantTokenInitializer(registeree.grantToken).initializeGrantToken(
            registereeId,
            registeree.council,
            params.feeCollectionAccount,
            params.grantTokenName,
            params.grantTokenSymbol,
            params.nrOfGrantTokens
        );
        // initialize the council contract
        IBoard(registeree.council).initializeBoard(
            params.councilBodies[0], // admins
            params.councilBodies[1], // creators
            params.councilBodies[2], // executors
            params.councilBodies[3]  // finalizers
        );
        ICouncil(registeree.council).initializeCouncil(
            registereeId,
            registeree.grantToken,
            params.feeCollectionAccount,
            params.icoCollectionAccount,
            params.pricesMicroUSD[0], // proposal creation fee
            params.pricesMicroUSD[1], // admin proposal creation fee
            params.pricesMicroUSD[2], // ico price
            params.pricesMicroUSD[3]  // ico fee
        );
        IFiatHandler(registeree.grantToken).initializeFiatHandler(
            params.payAddresses[0],
            params.payAddresses[1],
            params.payAddresses[2],
            params.maxNegativeSlippage
        );
        IFiatHandler(registeree.council).initializeFiatHandler(
            params.payAddresses[0], // uniswap-v2 factory contract
            params.payAddresses[1], // WETH ERC-20 contract
            params.payAddresses[2], // microUSD (USDT for example) ERC-20 contract
            params.maxNegativeSlippage
        );
        // mint the Deed NFT
        IDeedRegistry(__s().deedRegistry).mintDeed(registereeId, params.deedURI);
        // add new entry in catalog
        ICatalog(__s().catalog).addDeed(
            registereeId, registeree.grantToken, registeree.council);
        emit Registration(registereeId);
        emit RegistereeUpdate(registereeId);
    }

    function __addContractKey(string memory key) private {
        if (__s().contractKeysIndex[key] == 0) {
            __s().contractKeys.push(key);
            __s().contractKeysIndex[key] = __s().contractKeys.length;
        }
    }

    function __getContract(string memory key) private view returns (address) {
        address c = __s().contracts[key];
        require(c != address(0), string(abi.encodePacked("RII:ZA-", key)));
        return c;
    }

    function __createGrantToken(
        string memory name
    ) private returns (address) {
        return DiamondHelper._createDiamond(
            __getContract("diamond-factory"),
            __getContract("task-manager"),
            __getContract("authz-source"),
            string(abi.encodePacked(name, "-grant-token")),
            DiamondHelper._threeItemsAddressArray(
                __getContract("grant-token-facet"),
                __getContract("fiat-handler-facet"),
                __getContract("rbac-facet")
            )
        );
    }

    function __createCouncil(
        string memory name
    ) private returns (address) {
        return DiamondHelper._createDiamond(
            __getContract("diamond-factory"),
            __getContract("task-manager"),
            __getContract("authz-source"),
            string(abi.encodePacked(name, "-council")),
            DiamondHelper._fiveItemsAddressArray(
                __getContract("board-facet"),
                __getContract("council-facet"),
                __getContract("council-pm-facet"),
                __getContract("fiat-handler-facet"),
                __getContract("rbac-facet")
            )
        );
    }

    function __s() private pure returns (RegistrarStorage.Layout storage) {
        return RegistrarStorage.layout();
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

import "../../diamond/IDiamondFactory.sol";
import "../../diamond/IDiamondInitializer.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library DiamondHelper {

    function _singleItemAddressArray(address addr) internal pure returns (address[] memory) {
        address[] memory arr = new address[](1);
        arr[0] = addr;
        return arr;
    }

    function _twoItemsAddressArray(
        address addr1,
        address addr2
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](2);
        arr[0] = addr1;
        arr[1] = addr2;
        return arr;
    }

    function _threeItemsAddressArray(
        address addr1,
        address addr2,
        address addr3
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](3);
        arr[0] = addr1;
        arr[1] = addr2;
        arr[2] = addr3;
        return arr;
    }

    function _fourItemsAddressArray(
        address addr1,
        address addr2,
        address addr3,
        address addr4
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](4);
        arr[0] = addr1;
        arr[1] = addr2;
        arr[2] = addr3;
        arr[3] = addr4;
        return arr;
    }

    function _fiveItemsAddressArray(
        address addr1,
        address addr2,
        address addr3,
        address addr4,
        address addr5
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](5);
        arr[0] = addr1;
        arr[1] = addr2;
        arr[2] = addr3;
        arr[3] = addr4;
        arr[4] = addr5;
        return arr;
    }

    function _createDiamond(
        address diamondFactory,
        address taskManager,
        address authzSource,
        string memory name,
        address[] memory defaultFacets
    ) internal returns (address) {
        address diamond = IDiamondFactory(diamondFactory).createDiamond(
            __emptySupporintgInterfaceIds(),
            address(this)
        );
        // intialize the diamond
        IDiamondInitializer(diamond).initialize(
            name,
            taskManager,
            address(0), // app-registry
            authzSource,
            "diamonds",
            __emptyApps(),
            defaultFacets,
            __emptyFuncSigsToProtectOrUnprotect(),
            __emptyFacetsToFreeze(),
            __noLockNoFreeze()
        );
        return diamond;
    }

    function __emptySupporintgInterfaceIds() private pure returns (bytes4[] memory) {
        return new bytes4[](0);
    }

    function __emptyApps() private pure returns (string[][2] memory) {
        string[][2] memory apps;
        apps[0] = new string[](0);
        apps[1] = new string[](0);
        return apps;
    }

    function __emptyFuncSigsToProtectOrUnprotect() private pure returns (string[][2] memory) {
        string[][2] memory funcSigsToProtectOrUnprotect;
        funcSigsToProtectOrUnprotect[0] = new string[](0);
        funcSigsToProtectOrUnprotect[1] = new string[](0);
        return funcSigsToProtectOrUnprotect;
    }

    function __emptyFacetsToFreeze() private pure returns (address[] memory) {
        return new address[](0);
    }

    function __noLockNoFreeze() private pure returns (bool[3] memory) {
        return [ false, false, false ];
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
/// @notice Use at your own risk
interface IDeedRegistry {

    function initializeDeedRegistry(
        address registrar,
        address catalog,
        string memory name,
        string memory symbol
    ) external;

    function mintDeed(
        uint256 registereeId,
        string memory deedURI
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

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface ICatalog {

    function initializeCatalog(
        address registrar,
        address deedRegistry
    ) external;

    function addDeed(
        uint256 registreeId,
        address grantToken,
        address council
    ) external;

    function submitTransfer(
        uint256 registereeId,
        address from,
        address to,
        uint256 amount
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

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IGrantTokenInitializer {

    function initializeGrantToken(
        uint256 registereeId,
        address council,
        address feeCollectionAccount,
        string memory grantTokenName,
        string memory grantTokenSymbol,
        uint256 nrOfGrantTokens
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

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface ICouncil {

    function initializeCouncil(
        uint256 registereeId,
        address grantToken,
        address feeCollectionAccount,
        address icoCollectionAccount,
        uint256 proposalCreationFeeMicroUSD,
        uint256 adminProposalCreationFeeMicroUSD,
        uint256 icoTokenPriceMicroUSD,
        uint256 icoFeeMicroUSD
    ) external;

    function getAccountProposals(
        address account,
        bool onlyPending
    ) external view returns (uint256[] memory);

    function executeProposal(
        address executor,
        uint256 proposalId
    ) external;

    function executeAdminProposal(
        address executor,
        uint256 adminProposalId
    ) external;

    function icoTransferTokensFromCouncil(
        address payErc20,
        address payer,
        address to,
        uint256 nrOfTokens
    ) external payable;
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

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IFiatHandler {

    function initializeFiatHandler(
        address uniswapV2Factory,
        address wethAddress,
        address microUSDAddress,
        uint256 maxNegativeSlippage
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

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library RegistrarStorage {

    struct Registeree {
        // name of the registeree
        string name;
        // address of the GrantToken contract
        address grantToken;
        // address of the Council contract
        address council;
        // tags attached to this instance of registeree
        string[] tags;
        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    struct Layout {
        bool initialized;

        string registrarName;
        string registrarURI;

        address deedRegistry;
        address catalog;

        string[] contractKeys;
        mapping(string => uint256) contractKeysIndex;
        mapping(string => address) contracts;

        uint256 registereeIdCounter;
        mapping(uint256 => Registeree) registerees;

        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.txn.registrar.storage");

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

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IDiamondFactory {

    function getDiamondVersion()
    external view returns (string memory);

    function createDiamond(
        bytes4[] memory defaultSupportingInterfceIds,
        address initializer
    ) external returns (address);
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
interface IDiamondInitializer {

    function initialize(
        string memory name,
        address taskManager,
        address appRegistry,
        address authzSource,
        string memory authzDomain,
        string[][2] memory defaultApps, // [0] > names, [1] > versions
        address[] memory defaultFacets,
        string[][2] memory defaultFuncSigsToProtectOrUnprotect, // [0] > protect, [1] > unprotect
        address[] memory defaultFacetsToFreeze,
        bool[3] memory instantLockAndFreezes // [0] > lock, [1] > freeze-authz, [2] > freeze-diamond
    ) external;
}