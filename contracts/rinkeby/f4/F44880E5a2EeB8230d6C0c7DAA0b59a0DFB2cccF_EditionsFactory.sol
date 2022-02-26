// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Ownable} from "../../lib/Ownable.sol";
import {Clones} from "../../lib/Clones.sol";
import {IEditionsFactory, IEditionsFactoryEvents} from "./interface/IEditionsFactory.sol";
import {IEditions} from "./interface/IEditions.sol";

interface ITributaryRegistry {
    function registerTributary(address producer, address tributary) external;
}

/**
 * @title EditionsFactory
 * @notice The EditionsFactory contract is used to deploy edition clones.
 * @author MirrorXYZ
 */
contract EditionsFactory is Ownable, IEditionsFactoryEvents, IEditionsFactory {
    /// @notice Address that holds the implementation for Crowdfunds
    address public implementation;

    /// @notice Mirror tributary registry
    address public tributaryRegistry;

    constructor(
        address owner_,
        address implementation_,
        address tributaryRegistry_
    ) Ownable(owner_) {
        implementation = implementation_;
        tributaryRegistry = tributaryRegistry_;
    }

    // ======== Admin function =========
    function setImplementation(address implementation_)
        external
        override
        onlyOwner
    {
        require(implementation_ != address(0), "must set implementation");

        emit ImplementationSet(implementation, implementation_);

        implementation = implementation_;
    }

    function setTributaryRegistry(address tributaryRegistry_)
        external
        override
        onlyOwner
    {
        require(
            tributaryRegistry_ != address(0),
            "must set tributary registry"
        );

        emit TributaryRegistrySet(tributaryRegistry, tributaryRegistry_);

        tributaryRegistry = tributaryRegistry_;
    }

    // ======== Deploy function =========

    /// @notice Deploys a new edition (ERC721) clone, and register tributary.
    /// @param owner_ the clone owner
    /// @param tributary the tributary receive tokens in behalf of the clone fees
    /// @param name_ the name for the edition clone
    /// @param symbol_ the symbol for the edition clone
    /// @param description_ the description for the edition clone
    /// @param contentURI_ the contentURI for the edition clone
    /// @param animationURI_ the animationURI for the edition clone
    /// @param contractURI_ the contractURI for the edition clone
    /// @param edition_ the parameters for the edition sale
    /// @param nonce additional entropy for the clone salt parameter
    /// @param paused_ the pause state for the edition sale
    function create(
        address owner_,
        address tributary,
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory contentURI_,
        string memory animationURI_,
        string memory contractURI_,
        IEditions.Edition memory edition_,
        uint256 nonce,
        bool paused_
    ) external override returns (address clone) {
        clone = Clones.cloneDeterministic(
            implementation,
            keccak256(abi.encode(owner_, name_, symbol_, nonce))
        );

        IEditions(clone).initialize(
            owner_,
            name_,
            symbol_,
            description_,
            contentURI_,
            animationURI_,
            contractURI_,
            edition_,
            paused_
        );

        emit EditionsDeployed(owner_, clone, implementation);

        if (tributaryRegistry != address(0)) {
            ITributaryRegistry(tributaryRegistry).registerTributary(
                clone,
                tributary
            );
        }
    }

    function predictDeterministicAddress(address implementation_, bytes32 salt)
        external
        view
        override
        returns (address)
    {
        return
            Clones.predictDeterministicAddress(
                implementation_,
                salt,
                address(this)
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IOwnableEvents {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

contract Ownable is IOwnableEvents {
    address public owner;
    address private nextOwner;

    // modifiers

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    /**
     * @dev Initialize contract by setting transaction submitter as initial owner.
     */
    constructor(address owner_) {
        owner = owner_;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Initiate ownership transfer by setting nextOwner.
     */
    function transferOwnership(address nextOwner_) external onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");

        nextOwner = nextOwner_;
    }

    /**
     * @dev Cancel ownership transfer by deleting nextOwner.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        delete nextOwner;
    }

    /**
     * @dev Accepts ownership transfer by setting owner.
     */
    function acceptOwnership() external onlyNextOwner {
        delete nextOwner;

        owner = msg.sender;

        emit OwnershipTransferred(owner, msg.sender);
    }

    /**
     * @dev Renounce ownership by setting owner to zero address.
     */
    function renounceOwnership() external onlyOwner {
        _renounceOwnership();
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /**
     * @dev Returns true if the caller is the next owner.
     */
    function isNextOwner() public view returns (bool) {
        return msg.sender == nextOwner;
    }

    function _setOwner(address previousOwner, address newOwner) internal {
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, owner);
    }

    function _renounceOwnership() internal {
        emit OwnershipTransferred(owner, address(0));

        owner = address(0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev Copy of OpenZeppelin's Clones contract
 * https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IEditions} from "./IEditions.sol";

interface IEditionsFactoryEvents {
    event EditionsDeployed(
        address indexed owner,
        address indexed clone,
        address indexed implementation
    );

    event TributaryRegistrySet(
        address indexed oldTributaryRegistry,
        address indexed newTributaryRegistry
    );

    event ImplementationSet(
        address indexed oldImplementation,
        address indexed newImplementation
    );
}

interface IEditionsFactory {
    function setImplementation(address implementation_) external;

    function setTributaryRegistry(address tributaryRegistry_) external;

    function create(
        address owner,
        address tributary,
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory contentURI_,
        string memory animationURI_,
        string memory contractURI_,
        IEditions.Edition memory edition_,
        uint256 nonce,
        bool paused_
    ) external returns (address clone);

    function predictDeterministicAddress(address implementation_, bytes32 salt)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IEditionsEvents {
    event EditionPurchased(
        uint256 indexed tokenId,
        address indexed nftRecipient,
        uint256 amountPaid
    );

    event RoyaltyChange(
        address indexed oldRoyaltyRecipient,
        uint256 oldRoyaltyBPS,
        address indexed newRoyaltyRecipient,
        uint256 newRoyaltyBPS
    );

    event RendererSet(address indexed renderer);

    event EditionLimitSet(uint256 oldLimit, uint256 newLimit);

    event Withdrawal(address indexed recipient, uint256 amount, uint256 fee);

    event FundingRecipientSet(
        address indexed oldFundingRecipient,
        address indexed newFundingRecipient
    );

    event PriceSet(uint256 price);
}

interface IEditions {
    struct Edition {
        // Edition price
        uint256 price;
        // Edition supply limit
        uint256 limit;
    }

    // ============ Authorization ============

    function factory() external returns (address);

    // ============ Fee Configuration ============

    function feeConfig() external returns (address);

    function treasuryConfig() external returns (address);

    // ============ Edition Data ============

    function description() external view returns (string memory);

    function price() external returns (uint256);

    function limit() external returns (uint256);

    // ============ Royalty Info (ERC2981) ============

    function royaltyRecipient() external returns (address);

    function royaltyBPS() external returns (uint256);

    // ============ Rendering ============

    function renderer() external view returns (address);

    // ============ Initializing ============

    function initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory contentURI_,
        string memory animationURI_,
        string memory contractURI_,
        Edition memory edition_,
        bool paused_
    ) external;

    // ============ Pause Methods ============

    function unpause() external;

    function pause() external;

    // ============ Allocation ============

    function allocate(address recipient, uint256 count) external;

    // ============ Purchase ============

    function purchase(address recipient)
        external
        payable
        returns (uint256 tokenId);

    // ============ Minting ============

    function mint(address recipient) external returns (uint256 tokenId);

    function setLimit(uint256 limit_) external;

    // ============ ERC2981 Methods ============

    function setRoyaltyInfo(
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_
    ) external;

    // ============ Rendering Methods ============

    function setRenderer(address renderer_) external;

    function contractURI() external view returns (string memory);

    // ============ Withdrawal ============

    function setPrice(uint256 price_) external;

    function withdraw(uint16 feeBPS, address fundingRecipient) external;
}