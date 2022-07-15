// SPDX-License-Identifier: MIT

/// @title Outsiders metadata
/// @author patrick piemonte

// ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓
// ▓ ▒                           ▓ ▒
// ▒          ████  ████           ▓
// ▓        ██  ████  ████         ▒
// ▒      ███    ███████████       ▓
// ▓      ████  ████████ ███       ▒
// ▒        ██████████ ███         ▓
// ▓          ██████ ███           ▒
// ▒            ███ ██             ▓
// ▓              ██               ▒
// ▒ ▓                           ▒ ▓
// ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒

pragma solidity >=0.8.10 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOutsidersMetadata} from "./interfaces/IOutsidersMetadata.sol";
import {IOutsidersDNA} from "./interfaces/IOutsidersDNA.sol";

contract OutsidersMetadata is IOutsidersMetadata, Ownable {
    IOutsidersDNA public dnaContract;

    /**
     * @notice Set the DNA contract.
     * @dev Only callable by the owner.
     */
    function setDnaContract(address dnaAdress) public onlyOwner {
        dnaContract = IOutsidersDNA(dnaAdress);
    }

    constructor(address outsiderDNAContractAddress) {
        dnaContract = IOutsidersDNA(outsiderDNAContractAddress);
    }

    /**
     * @notice Returns the name of the token.
     * @param tokenId - id of the token
     */
    function getName(uint256 tokenId)
        external
        pure
        override
        returns (string memory)
    {
        return string(abi.encodePacked(bytes("Outsider #"), tokenId));
    }

    /**
     * @notice Returns the description of the token.
     * @param tokenId - id of the token
     */
    function getDescription(uint256 tokenId)
        external
        pure
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    bytes(
                        "Connect with friends, discover new places, and share the fun as a member of our vibrant community of IRL explorers."
                    )
                )
            );
    }

    /**
     * @notice Returns the trait attributes of the token.
     * @param tokenId - id of the token
     */
    function getAttributes(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        IOutsidersDNA.OutsiderTraits memory traits = dnaContract
            .getOutsiderTraits(tokenId);

        string memory traitAttributes = string(
            abi.encodePacked(
                unicode'{"trait_type": "🔰 Order", "value": "',
                bytes(traits.order),
                unicode'"}, {"trait_type": "🧬 Species", "value": "',
                bytes(traits.species)
            )
        );
        if (bytes(traits.outsiderType).length > 0) {
            traitAttributes = string(
                abi.encodePacked(
                    traitAttributes,
                    unicode'"}, {"trait_type": "⚡️ Type", "value": "',
                    bytes(traits.outsiderType)
                )
            );
        }
        traitAttributes = string(
            abi.encodePacked(
                traitAttributes,
                unicode'"}, {"trait_type": "😈 Personality", "value": "',
                bytes(traits.personality),
                unicode'"}, {"trait_type": "🎽 Fit", "value": "',
                bytes(traits.fit),
                unicode'"}, {"trait_type": "🧢 Lid", "value": "',
                bytes(traits.lid),
                unicode'"}, {"trait_type": "😎 Face", "value": "',
                bytes(traits.face),
                unicode'"}, {"trait_type": "🟧 Background", "value": "',
                bytes(traits.background),
                unicode'"}, {"trait_type": "🔭 Astrological Sign", "value": "',
                bytes(traits.zodiac)
            )
        );
        if (bytes(traits.phenomena).length > 0) {
            traitAttributes = string(
                abi.encodePacked(
                    traitAttributes,
                    unicode'"}, {"trait_type": "🌀 Phenomena", "value": "',
                    bytes(traits.phenomena)
                )
            );
        }
        if (bytes(traits.spy).length > 0) {
            traitAttributes = string(
                abi.encodePacked(
                    traitAttributes,
                    unicode'"}, {"trait_type": "🥸", "value": "',
                    bytes(traits.spy)
                )
            );
        }
        if (bytes(traits.inimitable).length > 0) {
            traitAttributes = string(
                abi.encodePacked(
                    traitAttributes,
                    unicode'"}, {"trait_type": "💎", "value": "',
                    bytes(traits.inimitable)
                )
            );
        }
        if (bytes(traits.airdrop).length > 0) {
            traitAttributes = string(
                abi.encodePacked(
                    traitAttributes,
                    unicode'"}, {"trait_type": "🎁", "value": "',
                    bytes(traits.airdrop)
                )
            );
        }
        traitAttributes = string(
            abi.encodePacked(traitAttributes, unicode'"}')
        );
        return traitAttributes;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

/// @title Outsiders metadata interface
/// @author patrick piemonte

//  ███████████████████████████████
// ██░░░░░     ░░░░░░░░░     ░░░░░██
// ██░░░░░░░░░░░░███░░░░░░░░░░░░░░██
// ██████████████░░░░░░█████████████
//          ██░░░░   ░░░░██
//          ██░░░░   ░░░░██
//  ████████░░░░░░███░░░░░░████████
// ██░░░   ░░░░░██░░░██░░░░░   ░░░██
// ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
// ██  ░░███░░  ░░███░░  ░░███░░  ██
// ██░░██   ██░░██   ██░░██   ██░░██
//  █████   ██████   ██████   █████

pragma solidity >=0.8.10 <0.9.0;

interface IOutsidersMetadata {
    function getName(uint256 tokenId) external view returns (string memory);

    function getDescription(uint256 tokenId)
        external
        view
        returns (string memory);

    function getAttributes(uint256 tokenId)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT

/// @title Outsiders DNA interface
/// @author patrick piemonte

// ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓
// ▓ ▒                           ▓ ▒
// ▒          ████  ████           ▓
// ▓        ██  ████  ████         ▒
// ▒      ███    ███████████       ▓
// ▓      ████  ████████ ███       ▒
// ▒        ██████████ ███         ▓
// ▓          ██████ ███           ▒
// ▒            ███ ██             ▓
// ▓              ██               ▒
// ▒ ▓                           ▒ ▓
// ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒

pragma solidity >=0.8.10 <0.9.0;

interface IOutsidersDNA {
    struct OutsiderTraits {
        string order;
        string species;
        string personality;
        string fit;
        string lid;
        string face;
        string background;
        string outsiderType;
        string phenomena;
        string spy;
        string inimitable;
        string zodiac;
        string airdrop;
    }

    function getOutsiderTraits(uint256 tokenId)
        external
        view
        returns (OutsiderTraits memory);

    function getOutsiderLayers(uint256 tokenId)
        external
        view
        returns (uint16[] memory layers);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}