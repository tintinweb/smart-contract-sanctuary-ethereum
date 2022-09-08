// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IDRS} from "../interfaces/IDRS.sol";
import {PNFTResolver} from "./PNFTResolver.sol";

/// @title Dopamine Resolver
contract DopamineResolver is PNFTResolver {

    // IDRS public immutable registry;

    // constructor(address _registry) {
    //     registry = IDRS(_registry);
    // }

    function supportsInterface(bytes4 id)
        public 
        view 
        override(PNFTResolver) 
        returns (bool) 
    {
        return super.supportsInterface(id);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IDRSEventsAndErrors} from "./IDRSEventsAndErrors.sol";

/// @title Dopamine Reality Service Interface
interface IDRS is IDRSEventsAndErrors {

    struct Record {
        address owner;
        address resolver;
    }

    function setRecord(
        bytes32 chip,
        address owner,
        address resolver
    ) external;

    function setResolver(
        bytes32 chip,
        address resolver
    ) external;

    function setOwner(
        bytes32 chip,
        address owner
    ) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IPNFTResolver} from "../interfaces/IPNFTResolver.sol";

/// @title PNFT Resolver
contract PNFTResolver is IPNFTResolver {

    mapping(bytes32 => address[]) bundles;

    function setPNFTs(bytes32 chip, address[] memory bundle) external {
        bundles[chip] = bundle;
    }

    function getPNFTs(bytes32 chip) external returns (address[] memory) {
        return bundles[chip];
    }

    function addPNFT(bytes32 chip, address pnft) external {
        address[] memory bundle = bundles[chip];
        for (uint256 i = 0; i < bundle.length; i++) { 
            if (bundle[i] == pnft) {
                revert PNFTAlreadyExists();
            }
        }
        bundles[chip].push(pnft);
    }

    function supportsInterface(bytes4 id)
        public 
        view 
        virtual
        returns (bool) 
    {
        id == type(IPNFTResolver).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title DRS Events & Errors Interface
interface IDRSEventsAndErrors {

    /// @notice Emits when a new owner is set for a chip record.
    event OwnerSet(bytes32 chip, address owner);

    /// @notice Emits when a new resolver is set for a chip record.
    event ResolverSet(bytes32 chip, address resolver);

    /// @notice Function callable only by the owner.
    error OwnerOnly();

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IPNFTResolverEventsAndErrors} from "./IPNFTResolverEventsAndErrors.sol";

/// @title Dopamine PNFT Resolver Interface
interface IPNFTResolver is IPNFTResolverEventsAndErrors {

    function setPNFTs(bytes32 chip, address[] memory bundle) external;

    function getPNFTs(bytes32 chip) external returns (address[] memory);

    function addPNFT(bytes32 chip, address pnft) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title PNFT Resolver Events & Errors Interface
interface IPNFTResolverEventsAndErrors {

    error PNFTAlreadyExists();
}