// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Owned} from "solmate/auth/Owned.sol";
import {IAuthoriser} from "./IAuthoriser.sol";
import {IRulesEngine} from "./IRulesEngine.sol";

/// @title Lightweight ERC-721 interface
/// @author charchar.eth
/// @notice Only a limited set of functions is needed for NftAuthoriser
interface IERC721 {
    /// @notice Get the owner of given token ID
    /// @param id Token ID
    /// @return owner Address of the owner
    function ownerOf(uint256 id) external view returns (address owner);
}

/// @title Authoriser using an NFT
/// @author charchar.eth
/// @notice Determine if a node can be registered or edited using holders of an NFT
contract NftAuthoriser is IAuthoriser, IRulesEngine, Owned(msg.sender) {
    /// @notice The NFT that is providing ownership details
    IERC721 public nft;

    /// @notice The current profile resolver
    address resolver;

    constructor(address _nft, address _resolver) {
        nft = IERC721(_nft);
        resolver = _resolver;
    }

    /// @inheritdoc IAuthoriser
    function canRegister(
        bytes32 node,
        address registrant,
        bytes memory authData
    ) external view returns (bool) {
        (uint256 tokenId) = abi.decode(authData, (uint256));
        require(tokenId > 0, "Token ID must be above 0");

        return nft.ownerOf(tokenId) == registrant;
    }

    /// @inheritdoc IAuthoriser
    function canEdit(
        bytes32 node,
        address registrant,
        bytes memory authData
    ) external view returns (bool) {
        return this.canRegister(node, registrant, authData);
    }

    /// @notice Make sure label is at least four characters long, emojis supported
    /// @param node Unused in this implementation
    /// @inheritdoc IRulesEngine
    function isLabelValid(bytes32 node, string memory label)
        external
        pure
        returns (bool isValid)
    {
        uint256 minLength = 3;
        uint256 len;
        uint256 i = 0;
        uint256 byteLength = bytes(label).length;
        isValid = false;

        for(len = 0; i < byteLength; len++) {
          if (len == minLength) {
            isValid = true;
            break;
          }

          bytes1 b = bytes(label)[i];
          if(b < 0x80) {
            i += 1;
          } else if (b < 0xE0) {
            i += 2;
          } else if (b < 0xF0) {
            i += 3;
          } else if (b < 0xF8) {
            i += 4;
          } else if (b < 0xFC) {
            i += 5;
          } else {
            i += 6;
          }
        }

        return isValid;
    }

    /// @inheritdoc IRulesEngine
    /// @dev The registrant is always the owner
    function subnodeOwner(address registrant) external view returns (address) {
        return registrant;
    }

    /// @inheritdoc IRulesEngine
    function profileResolver(
        bytes32 node,
        string memory label,
        address registrant
    ) external view returns (address) {
        return address(0x0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

/// @title Authoriser interface
/// @author charchar.eth
/// @notice Defines the API which a valid Authorising contract must meet
/// @custom:docs-example iauthoriser.md
interface IAuthoriser {
    /// @notice Determine if a node can be registered by a sender
    /// @dev See example for authData packing
    /// @param node Fully qualified, namehashed ENS name
    /// @param registrant Address of the user who is attempting to register
    /// @param authData Additional data used for authorising the request
    /// @return True if the sender can register, false otherwise
    /// @custom:docs-example authdata.md
    function canRegister(
        bytes32 node,
        address registrant,
        bytes memory authData
    ) external view returns (bool);

    /// @notice Determine if a node can be edited by sender
    /// @dev See example for authData packing
    /// @param node Fully qualified, namehashed ENS name
    /// @param registrant Address of the user who is attempting to register
    /// @param authData Additional data used for authorising the request
    /// @return True if the sender can edit, false otherwise
    /// @custom:docs-example authdata.md
    function canEdit(
        bytes32 node,
        address registrant,
        bytes memory authData
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

/// @title Rules Engine Interface
/// @author charchar.eth
/// @notice Functions that a RulesEngine contract should support
interface IRulesEngine {
    /// @notice Determine if a label meets a projects minimum requirements
    /// @param node Fully qualified, namehashed ENS name
    /// @param label The 'best' in 'best.bob.eth'
    /// @return True if label is valid, false otherwise
    function isLabelValid(bytes32 node, string memory label)
        external
        view
        returns (bool);

    /// @notice Determine who should own the subnode
    /// @param registrant The address that is registereing a subnode
    /// @return The address that should own the subnode
    function subnodeOwner(address registrant) external view returns (address);

    /// @notice Determine the resolver contract to use for project profiles
    /// @dev If this returns address(0x0), the Registrar will use its default resolver
    /// @param node Fully qualified, namehashed ENS name
    /// @param label The 'best' in 'best.bob.eth'
    /// @param registrant The address that is registereing a subnode
    /// @return The address of the resolver
    function profileResolver(
        bytes32 node,
        string memory label,
        address registrant
    ) external view returns (address);
}