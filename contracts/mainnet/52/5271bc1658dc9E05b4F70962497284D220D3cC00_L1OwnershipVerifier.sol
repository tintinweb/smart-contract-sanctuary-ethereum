// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { L2ERC721Registry } from "./L2ERC721Registry.sol";
import {
    CrossDomainMessenger
} from "@eth-optimism/contracts-bedrock/contracts/universal/CrossDomainMessenger.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title L1OwnershipVerifier
 * @notice Allows the owner of an L1 ERC721 to claim ownership of the ERC721's L2 representation in
 *         the L2ERC721Registry. Note that this contract only works with the Ownable interface. In
 *         other words, the L1 ERC721 contract must return the address of the owner when called with
 *         the `owner()` function.
 */
contract L1OwnershipVerifier is Initializable {
    /**
     * @notice Emitted when ownership is claimed for an L1 ERC721.
     *
     * @param l1Owner   Address of the L1 ERC721's owner that called this function.
     * @param l1ERC721  Address of the L1 ERC721.
     * @param l2Owner   Address that will have ownership of the L1 ERC721 in the L2ERC721Registry.
     */
    event L1ERC721OwnershipClaimed(
        address indexed l1Owner,
        address indexed l1ERC721,
        address indexed l2Owner
    );

    /**
     * Address of the L2ERC721Registry.
     */
    address public l2ERC721Registry;

    /**
     * @notice L1CrossDomainMessenger contract.
     */
    CrossDomainMessenger public l1Messenger;

    /**
     * @notice Minimum gas limit for the cross-domain message on L2.
     */
    uint32 public minGasLimit;

    /**
     * @param _l1Messenger Address of the L1CrossDomainMessenger.
     */
    constructor(address _l1Messenger) {
        l1Messenger = CrossDomainMessenger(_l1Messenger);
    }

    /**
     * @notice Initializer. Can only be called once. We initialize these variables outside of the
     *         constrcutor because the L2ERC721Registry doesn't exist yet when this contract is
     *         deployed.
     *
     * @param _l2ERC721Registry Address of the L2ERC721Registry.
     * @param _minGasLimit      Minimum gas limit for the cross-domain message on L2.
     */
    function initialize(address _l2ERC721Registry, uint32 _minGasLimit) external initializer {
        l2ERC721Registry = _l2ERC721Registry;
        minGasLimit = _minGasLimit;
    }

    /**
     * @notice Allows the owner of an L1 ERC721 to claim ownership of the ERC721's L2 representation
     *         in the L2ERC721Registry. The L1 ERC721 must implement the `Ownable` interface.
     *
     * @param _l1ERC721 Address of the L1 ERC721.
     * @param _l2Owner  Address that will have ownership of the L1 ERC721 in the L2ERC721Registry.
     */
    function claimL1ERC721Ownership(address _l1ERC721, address _l2Owner) external {
        require(_l2Owner != address(0), "L1OwnershipVerifier: l2 owner cannot be address(0)");
        require(
            Ownable(_l1ERC721).owner() == msg.sender,
            "L1OwnershipVerifier: caller is not the l1 erc721 owner"
        );

        // Construct calldata for L2ERC721Registry.claimL1ERC721Ownership(owner, l1ERC721)
        bytes memory message = abi.encodeCall(
            L2ERC721Registry.claimL1ERC721Ownership,
            (_l2Owner, _l1ERC721)
        );

        // Send calldata into L2
        l1Messenger.sendMessage(l2ERC721Registry, message, minGasLimit);

        emit L1ERC721OwnershipClaimed(msg.sender, _l1ERC721, _l2Owner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {
    CrossDomainMessenger
} from "@eth-optimism/contracts-bedrock/contracts/universal/CrossDomainMessenger.sol";
import {
    IOptimismMintableERC721
} from "@eth-optimism/contracts-periphery/contracts/universal/op-erc721/IOptimismMintableERC721.sol";
import { TwoStepOwnableUpgradeable } from "../access/TwoStepOwnableUpgradeable.sol";

/**
 * @title L2ERC721Registry
 * @notice An upgradeable registry of L2 ERC721 contracts that are recognized as legitimate L2
 *         representations of L1 ERC721 contracts. For each L1 contract, there is a single default
 *         L2 contract as well as a list of approved L2 contracts (which includes the default
 *         contract). The default L2 contract is recognized as the canonical L2 representation of
 *         the L1 ERC721, and the list of approved L2 contracts are also recognized as legitimate.
 */
contract L2ERC721Registry is TwoStepOwnableUpgradeable {
    /**
     * @notice Emitted when an L2 ERC721 is set to be the default contract for an L1 ERC721.
     *
     * @param l1ERC721 Address of the L1 ERC721.
     * @param l2ERC721 Address of the default L2 ERC721.
     * @param caller   Address of the caller.
     */
    event DefaultL2ERC721Set(
        address indexed l1ERC721,
        address indexed l2ERC721,
        address indexed caller
    );

    /**
     * @notice Emitted when an L2 ERC721 is set to be an approved contract for an L1 ERC721.
     *
     * @param l1ERC721 Address of the L1 ERC721.
     * @param l2ERC721 Address of the approved L2 ERC721.
     * @param caller   Address of the caller.
     */
    event L2ERC721Approved(
        address indexed l1ERC721,
        address indexed l2ERC721,
        address indexed caller
    );

    /**
     * @notice Emitted when an L2 ERC721 has its approval removed.
     *
     * @param l1ERC721 Address of the L1 ERC721 that corresponds to this L2 ERC721.
     * @param l2ERC721 Address of the approved L2 ERC721.
     * @param caller   Address of the caller.
     */
    event L2ERC721ApprovalRemoved(
        address indexed l1ERC721,
        address indexed l2ERC721,
        address indexed caller
    );

    /**
     * @notice Emitted when ownership is claimed for an L1 ERC721.
     *
     * @param owner    Address of the L1 ERC721's owner.
     * @param l1ERC721 Address of the L1 ERC721.
     */
    event L1ERC721OwnershipClaimed(address indexed owner, address indexed l1ERC721);

    /**
     * @notice Emitted when a new L1OwnershipVerifier address is set.
     *
     * @param newVerifier Address of the new L1OwnershipVerifier contract.
     */
    event L1OwnershipVerifierSet(address indexed newVerifier);

    /**
     * @notice Address of the L1OwnershipVerifier contract.
     */
    address public l1OwnershipVerifier;

    /**
     * @notice L2CrossDomainMessenger contract.
     */
    CrossDomainMessenger public l2Messenger;

    /**
     * @notice Maps an owner's address to the L1 ERC721 address that it owns. Note that this mapping
     *         may be outdated if an L1 ERC721 contract changes owners.
     */
    mapping(address => address) public l1ERC721Owners;

    /**
     * @notice Maps an L1 ERC721 address to its default L2 ERC721 address.
     */
    mapping(address => address) internal defaultL2ERC721s;

    /**
     * @notice Maps an L1 ERC721 to an array of approved L2 ERC721 addresses. The array includes the
     *         default L2 contract for the L1 ERC721, if it exists.
     */
    mapping(address => address[]) internal approvedL2ERC721s;

    /**
     * @notice Maps an approved L2 ERC721 address to its index in the `approvedL2ERC721s` mapping.
     */
    mapping(address => uint256) internal l2Indexes;

    /**
     * @notice Modifier that allows only the owner of this contract or the owner of the specified L1
     *         ERC721 to call a function.
     *
     * @param _l1ERC721 Address of the L1 ERC721.
     */
    modifier onlyRegistryOwnerOrL1ERC721Owner(address _l1ERC721) {
        require(
            msg.sender == owner() || l1ERC721Owners[msg.sender] == _l1ERC721,
            "L2ERC721Registry: caller is not registry owner or l1 erc721 owner"
        );
        _;
    }

    /**
     * @notice Ensures that the caller is a cross-chain message from the L1OwnershipVerifier.
     */
    modifier onlyL1OwnershipVerifier() {
        require(
            msg.sender == address(l2Messenger) &&
                l2Messenger.xDomainMessageSender() == l1OwnershipVerifier,
            "L2ERC721Registry: function can only be called from the l1 ownership verifier"
        );
        _;
    }

    /**
     * @notice Initializer. Only callable once.
     *
     * @param _l1OwnershipVerifier Address of the L1OwnershipVerifier contract.
     * @param _l2Messenger         Address of the L2CrossDomainMessenger.
     */
    function initialize(address _l1OwnershipVerifier, address _l2Messenger) external initializer {
        l1OwnershipVerifier = _l1OwnershipVerifier;
        l2Messenger = CrossDomainMessenger(_l2Messenger);

        // Initialize inherited contract
        __TwoStepOwnable_init();
    }

    /**
     * @notice Sets the default L2 ERC721 for the given L1 ERC721. This adds the L2 ERC721 to the
     *         list of approved L2 contracts for the given L1 contract if it is not already in the
     *         list, so there is no need to call `approveL2ERC721` in addition to this function for
     *         newly added contracts. Only callable by the owner of this contract or the owner of
     *         the L1 ERC721 contract. Note that the L2 ERC721 must implement
     *         IOptimismMintableERC721, since the interface is required to interact with the L2
     *         Bridge.
     *
     * @param _l1ERC721 Address of the L1 ERC721 that corresponds to the L2 ERC721.
     * @param _l2ERC721 Address of the L2 ERC721 to set as the default contract for the L1 ERC721.
     */
    function setDefaultL2ERC721(address _l1ERC721, address _l2ERC721)
        external
        onlyRegistryOwnerOrL1ERC721Owner(_l1ERC721)
    {
        require(_l1ERC721 != address(0), "L2ERC721Registry: l1 erc721 cannot be address(0)");
        require(_l2ERC721 != address(0), "L2ERC721Registry: l2 erc721 cannot be address(0)");
        require(
            getL1ERC721(_l2ERC721) == _l1ERC721,
            "L2ERC721Registry: l1 erc721 is not the remote address of the l2 erc721"
        );
        require(
            defaultL2ERC721s[_l1ERC721] != _l2ERC721,
            "L2ERC721Registry: l2 erc721 is already the default contract"
        );

        defaultL2ERC721s[_l1ERC721] = _l2ERC721;

        // Add the L2 ERC721 to the approved list if it is not already present.
        if (!isApprovedL2ERC721(_l1ERC721, _l2ERC721)) {
            _approveL2ERC721(_l1ERC721, _l2ERC721);
        }

        emit DefaultL2ERC721Set(_l1ERC721, _l2ERC721, msg.sender);
    }

    /**
     * @notice Adds a given L2 ERC721 to the list of approved contracts for the given L1 ERC721.
     *         Only callable by the owner of this contract or the owner of the L1 ERC721 contract.
     *         Note that this does not set the L2 ERC721 to be the default contract for the L1
     *         ERC721. That can be done by calling `setDefaultL2ERC721`. Also note that the L2
     *         ERC721 must implement IOptimismMintableERC721, since this interface is required to
     *         interact with the L2 Bridge.
     *
     * @param _l1ERC721 Address of the L1 ERC721 that corresponds to the L2 ERC721.
     * @param _l2ERC721 Address of the L2 ERC721 to approve.
     */
    function approveL2ERC721(address _l1ERC721, address _l2ERC721)
        external
        onlyRegistryOwnerOrL1ERC721Owner(_l1ERC721)
    {
        require(_l1ERC721 != address(0), "L2ERC721Registry: l1 erc721 cannot be address(0)");
        require(_l2ERC721 != address(0), "L2ERC721Registry: l2 erc721 cannot be address(0)");
        require(
            getL1ERC721(_l2ERC721) == _l1ERC721,
            "L2ERC721Registry: l1 erc721 is not the remote address of the l2 erc721"
        );
        require(
            !isApprovedL2ERC721(_l1ERC721, _l2ERC721),
            "L2ERC721Registry: l2 erc721 is already approved for the l1 erc721"
        );

        _approveL2ERC721(_l1ERC721, _l2ERC721);

        emit L2ERC721Approved(_l1ERC721, _l2ERC721, msg.sender);
    }

    /**
     * @notice Removes a given L2 ERC721 from the list of approved contracts for the given L1
     *         ERC721. If the L2 ERC721 to remove is the default contract for the L1 ERC721, this
     *         status will be removed as well. Only callable by the owner of this contract or the
     *         owner of the L1 ERC721 contract.
     *
     * @param _l1ERC721 Address of the L1 ERC721 that corresponds to the L2 ERC721.
     * @param _l2ERC721 Address of the L2 ERC721 to remove.
     */
    function removeL2ERC721Approval(address _l1ERC721, address _l2ERC721)
        external
        onlyRegistryOwnerOrL1ERC721Owner(_l1ERC721)
    {
        require(
            isApprovedL2ERC721(_l1ERC721, _l2ERC721),
            "L2ERC721Registry: l2 erc721 is not an approved contract for the l1 erc721"
        );

        // If the L2 ERC721 is the default L2 contract for this L1 ERC721, then remove its status as
        // the default contract.
        if (_l2ERC721 == defaultL2ERC721s[_l1ERC721]) {
            defaultL2ERC721s[_l1ERC721] = address(0);
        }

        // Get the array of approved L2 ERC721s for this L1 ERC721.
        address[] storage approved = approvedL2ERC721s[_l1ERC721];

        // To prevent a gap in the array, we store the last address in the index of the address to
        // delete, and then delete the last slot (swap and pop).

        uint256 lastIndex = approved.length - 1;
        uint256 targetIndex = l2Indexes[_l2ERC721];

        // If the address to delete is the last element in the list, the swap operation is
        // unnecessary.
        if (targetIndex != lastIndex) {
            address lastL2ERC721 = approved[lastIndex];

            // Move the last element to the slot of the address to delete
            approved[targetIndex] = lastL2ERC721;
            // Update the indexes mapping to reflect this change
            l2Indexes[lastL2ERC721] = targetIndex;
        }

        // Delete the contents at the last position of the array
        approved.pop();
        // Updates the indexes mapping to reflect the deletion
        delete l2Indexes[_l2ERC721];

        emit L2ERC721ApprovalRemoved(_l1ERC721, _l2ERC721, msg.sender);
    }

    /**
     * @notice Returns true if the L2 ERC721 is an approved contract, or the default contract, for
     *         the given L1 ERC721.
     *
     * @param _l1ERC721 Address of the L1 ERC721 that corresponds to the L2 ERC721.
     * @param _l2ERC721 Address of the L2 ERC721.
     *
     * @return True if the L2 ERC721 is in the approved list for the L1 ERC721.
     */
    function isApprovedL2ERC721(address _l1ERC721, address _l2ERC721) public view returns (bool) {
        address[] storage approved = approvedL2ERC721s[_l1ERC721];
        if (approved.length == 0) {
            return false;
        }
        return _l2ERC721 == approved[l2Indexes[_l2ERC721]];
    }

    /**
     * @notice Get the address of the default L2 ERC721 for the given L1 ERC721. The default L2
     *         contract is recognized as the single canonical L2 representation for the L1 ERC721.
     *         Note that this returns address(0) if there is no default L2 contract assigned to the
     *         given L1 contract. This also returns address(0) if the given L2 ERC721 is in the list
     *         of approved L2 contracts for the L1 ERC721, but is not the default contract.
     *
     * @param _l1ERC721 Address of the L1 ERC721.
     *
     * @return Address of the default L2 ERC721 for the L1 ERC721. Address(0) if it does not exist.
     */
    function getDefaultL2ERC721(address _l1ERC721) external view returns (address) {
        return defaultL2ERC721s[_l1ERC721];
    }

    /**
     * @notice Get the list of approved L2 ERC721s for a given L1 ERC721. Note that this list
     *         includes the default L2 contract for the given L1 contract.
     *
     * @param _l1ERC721 Address of the L1 ERC721 contract.
     *
     * @return Array of approved L2 ERC721s for the L1 ERC721. Returns an empty array if the L1
     *         contract has no approved L2 contracts.
     */
    function getApprovedL2ERC721s(address _l1ERC721) external view returns (address[] memory) {
        return approvedL2ERC721s[_l1ERC721];
    }

    /**
     * @notice Returns the L1 ERC721 address for the given L2 ERC721. This reverts if the L2 ERC721
     *         does not have a `remoteToken` function.
     *
     * @param _l2ERC721 Address of the L2 ERC721.
     *
     * @return Address of the L1 representation of the L2 ERC721.
     */
    function getL1ERC721(address _l2ERC721) public view returns (address) {
        return IOptimismMintableERC721(_l2ERC721).remoteToken();
    }

    /**
     * @notice Allows the owner of an L1 ERC721 to claim ownership rights over the L1 contract and
     *         its L2 representations in this registry. This allows the owner to set the default L2
     *         address and the list of approved L2 addresses for their L1 ERC721 in this contract.
     *         Must be called via the L1OwnershipVerifier contract on L1.
     *
     * @param owner_    Address of the new owner for the L1 ERC721.
     * @param _l1ERC721 Address of the L1 ERC721 being claimed.
     */
    function claimL1ERC721Ownership(address owner_, address _l1ERC721)
        external
        onlyL1OwnershipVerifier
    {
        l1ERC721Owners[owner_] = _l1ERC721;

        emit L1ERC721OwnershipClaimed(owner_, _l1ERC721);
    }

    /**
     * @notice Allows the owner of this contract to set a new L1OwnershipVerifier contract.
     *
     * @param _l1OwnershipVerifier Address of the new L1OwnershipVerifier.
     */
    function setL1OwnershipVerifier(address _l1OwnershipVerifier) external onlyOwner {
        l1OwnershipVerifier = _l1OwnershipVerifier;

        emit L1OwnershipVerifierSet(_l1OwnershipVerifier);
    }

    /**
     * @notice Approves an L2 ERC721 for a given L1 ERC721 by adding it to an array. Skips contracts
     *         that have already been added to the list.
     *
     * @param _l1ERC721 Address of the L1 ERC721 that corresponds to the L2 ERC721.
     * @param _l2ERC721 Address of the L2 ERC721 to approve.
     */
    function _approveL2ERC721(address _l1ERC721, address _l2ERC721) internal {
        address[] storage approved = approvedL2ERC721s[_l1ERC721];
        l2Indexes[_l2ERC721] = approved.length;
        approved.push(_l2ERC721);
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
pragma solidity 0.8.15;

import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeCall } from "../libraries/SafeCall.sol";
import { Hashing } from "../libraries/Hashing.sol";
import { Encoding } from "../libraries/Encoding.sol";

/**
 * @title CrossDomainMessenger
 * @notice CrossDomainMessenger is a base contract that provides the core logic for the L1 and L2
 *         cross-chain messenger contracts. It's designed to be a universal interface that only
 *         needs to be extended slightly to provide low-level message passing functionality on each
 *         chain it's deployed on. Currently only designed for message passing between two paired
 *         chains and does not support one-to-many interactions.
 */
abstract contract CrossDomainMessenger is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     * @notice Current message version identifier.
     */
    uint16 public constant MESSAGE_VERSION = 1;

    /**
     * @notice Constant overhead added to the base gas for a message.
     */
    uint32 public constant MIN_GAS_CONSTANT_OVERHEAD = 200_000;

    /**
     * @notice Numerator for dynamic overhead added to the base gas for a message.
     */
    uint32 public constant MIN_GAS_DYNAMIC_OVERHEAD_NUMERATOR = 1016;

    /**
     * @notice Denominator for dynamic overhead added to the base gas for a message.
     */
    uint32 public constant MIN_GAS_DYNAMIC_OVERHEAD_DENOMINATOR = 1000;

    /**
     * @notice Extra gas added to base gas for each byte of calldata in a message.
     */
    uint32 public constant MIN_GAS_CALLDATA_OVERHEAD = 16;

    /**
     * @notice Minimum amount of gas required to relay a message.
     */
    uint256 internal constant RELAY_GAS_REQUIRED = 45_000;

    /**
     * @notice Amount of gas held in reserve to guarantee that relay execution completes.
     */
    uint256 internal constant RELAY_GAS_BUFFER = RELAY_GAS_REQUIRED - 5000;

    /**
     * @notice Initial value for the xDomainMsgSender variable. We set this to a non-zero value
     *         because performing an SSTORE on a non-zero value is significantly cheaper than on a
     *         zero value.
     */
    address internal constant DEFAULT_XDOMAIN_SENDER = 0x000000000000000000000000000000000000dEaD;

    /**
     * @notice Mapping of message hashes to boolean receipt values. Note that a message will only
     *         be present in this mapping if it failed to be relayed on this chain at least once.
     *         If a message is successfully relayed on the first attempt, then it will only be
     *         present within the successfulMessages mapping.
     */
    mapping(bytes32 => bool) public successfulMessages;

    /**
     * @notice Address of the sender of the currently executing message on the other chain. If the
     *         value of this variable is the default value (0x00000000...dead) then no message is
     *         currently being executed. Use the xDomainMessageSender getter which will throw an
     *         error if this is the case.
     */
    address internal xDomainMsgSender;

    /**
     * @notice Nonce for the next message to be sent, without the message version applied. Use the
     *         messageNonce getter which will insert the message version into the nonce to give you
     *         the actual nonce to be used for the message.
     */
    uint240 internal msgNonce;

    /**
     * @notice Address of the paired CrossDomainMessenger contract on the other chain.
     */
    address public otherMessenger;

    /**
     * @notice Mapping of message hashes to boolean receipt values. Note that a message will only
     *         be present in this mapping if it failed to be relayed on this chain at least once.
     *         If a message is successfully relayed on the first attempt, then it will only be
     *         present within the successfulMessages mapping.
     */
    mapping(bytes32 => bool) public receivedMessages;

    /**
     * @notice Mapping of blocked system addresses. Note that this is NOT a mapping of blocked user
     *         addresses and cannot be used to prevent users from sending or receiving messages.
     *         This is ONLY used to prevent the execution of messages to specific system addresses
     *         that could cause security issues, e.g., having the CrossDomainMessenger send
     *         messages to itself.
     */
    mapping(address => bool) public blockedSystemAddresses;

    /**
     * @notice Emitted whenever a message is sent to the other chain.
     *
     * @param target       Address of the recipient of the message.
     * @param sender       Address of the sender of the message.
     * @param message      Message to trigger the recipient address with.
     * @param messageNonce Unique nonce attached to the message.
     * @param gasLimit     Minimum gas limit that the message can be executed with.
     */
    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );

    /**
     * @notice Additional event data to emit, required as of Bedrock. Cannot be merged with the
     *         SentMessage event without breaking the ABI of this contract, this is good enough.
     *
     * @param sender Address of the sender of the message.
     * @param value  ETH value sent along with the message to the recipient.
     */
    event SentMessageExtension1(address indexed sender, uint256 value);

    /**
     * @notice Emitted whenever a message is successfully relayed on this chain.
     *
     * @param msgHash Hash of the message that was relayed.
     */
    event RelayedMessage(bytes32 indexed msgHash);

    /**
     * @notice Emitted whenever a message fails to be relayed on this chain.
     *
     * @param msgHash Hash of the message that failed to be relayed.
     */
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /**
     * @notice Allows the owner of this contract to temporarily pause message relaying. Backup
     *         security mechanism just in case. Owner should be the same as the upgrade wallet to
     *         maintain the security model of the system as a whole.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Allows the owner of this contract to resume message relaying once paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Sends a message to some target address on the other chain.
     *
     * @param _target      Target contract or wallet address.
     * @param _message     Message to trigger the target address with.
     * @param _minGasLimit Minimum gas limit that the message can be executed with.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _minGasLimit
    ) external payable {
        // Triggers a message to the other messenger. Note that the amount of gas provided to the
        // message is the amount of gas requested by the user PLUS the base gas value. We want to
        // guarantee the property that the call to the target contract will always have at least
        // the minimum gas limit specified by the user.
        _sendMessage(
            otherMessenger,
            baseGas(_message, _minGasLimit),
            msg.value,
            abi.encodeWithSelector(
                this.relayMessage.selector,
                messageNonce(),
                msg.sender,
                _target,
                msg.value,
                _minGasLimit,
                _message
            )
        );

        emit SentMessage(_target, msg.sender, _message, messageNonce(), _minGasLimit);
        emit SentMessageExtension1(msg.sender, msg.value);

        unchecked {
            ++msgNonce;
        }
    }

    /**
     * @notice Relays a message that was sent by the other CrossDomainMessenger contract. Can only
     *         be executed via cross-chain call from the other messenger OR if the message was
     *         already received once and is currently being replayed.
     *
     * @param _nonce       Nonce of the message being relayed.
     * @param _sender      Address of the user who sent the message.
     * @param _target      Address that the message is targeted at.
     * @param _value       ETH value to send with the message.
     * @param _minGasLimit Minimum amount of gas that the message can be executed with.
     * @param _message     Message to send to the target.
     */
    function relayMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _minGasLimit,
        bytes calldata _message
    ) external payable nonReentrant whenNotPaused {
        bytes32 versionedHash = Hashing.hashCrossDomainMessage(
            _nonce,
            _sender,
            _target,
            _value,
            _minGasLimit,
            _message
        );

        if (_isOtherMessenger()) {
            // Should never happen.
            require(msg.value == _value, "CrossDomainMessenger: mismatched message value");
        } else {
            require(
                msg.value == 0,
                "CrossDomainMessenger: value must be zero unless message is from a system address"
            );

            require(
                receivedMessages[versionedHash],
                "CrossDomainMessenger: message cannot be replayed"
            );
        }

        require(
            blockedSystemAddresses[_target] == false,
            "CrossDomainMessenger: cannot send message to blocked system address"
        );

        require(
            successfulMessages[versionedHash] == false,
            "CrossDomainMessenger: message has already been relayed"
        );

        require(
            gasleft() >= _minGasLimit + RELAY_GAS_REQUIRED,
            "CrossDomainMessenger: insufficient gas to relay message"
        );

        xDomainMsgSender = _sender;
        bool success = SafeCall.call(_target, gasleft() - RELAY_GAS_BUFFER, _value, _message);
        xDomainMsgSender = DEFAULT_XDOMAIN_SENDER;

        if (success == true) {
            successfulMessages[versionedHash] = true;
            emit RelayedMessage(versionedHash);
        } else {
            receivedMessages[versionedHash] = true;
            emit FailedRelayedMessage(versionedHash);
        }
    }

    /**
     * @notice Retrieves the address of the contract or wallet that initiated the currently
     *         executing message on the other chain. Will throw an error if there is no message
     *         currently being executed. Allows the recipient of a call to see who triggered it.
     *
     * @return Address of the sender of the currently executing message on the other chain.
     */
    function xDomainMessageSender() external view returns (address) {
        require(
            xDomainMsgSender != DEFAULT_XDOMAIN_SENDER,
            "CrossDomainMessenger: xDomainMessageSender is not set"
        );

        return xDomainMsgSender;
    }

    /**
     * @notice Retrieves the next message nonce. Message version will be added to the upper two
     *         bytes of the message nonce. Message version allows us to treat messages as having
     *         different structures.
     *
     * @return Nonce of the next message to be sent, with added message version.
     */
    function messageNonce() public view returns (uint256) {
        return Encoding.encodeVersionedNonce(msgNonce, MESSAGE_VERSION);
    }

    /**
     * @notice Computes the amount of gas required to guarantee that a given message will be
     *         received on the other chain without running out of gas. Guaranteeing that a message
     *         will not run out of gas is important because this ensures that a message can always
     *         be replayed on the other chain if it fails to execute completely.
     *
     * @param _message     Message to compute the amount of required gas for.
     * @param _minGasLimit Minimum desired gas limit when message goes to target.
     *
     * @return Amount of gas required to guarantee message receipt.
     */
    function baseGas(bytes calldata _message, uint32 _minGasLimit) public pure returns (uint32) {
        return
            // Dynamic overhead
            ((_minGasLimit * MIN_GAS_DYNAMIC_OVERHEAD_NUMERATOR) /
                MIN_GAS_DYNAMIC_OVERHEAD_DENOMINATOR) +
            // Calldata overhead
            (uint32(_message.length) * MIN_GAS_CALLDATA_OVERHEAD) +
            // Constant overhead
            MIN_GAS_CONSTANT_OVERHEAD;
    }

    /**
     * @notice Intializer.
     *
     * @param _otherMessenger         Address of the CrossDomainMessenger on the paired chain.
     * @param _blockedSystemAddresses List of system addresses that need to be blocked to prevent
     *                                certain security issues. Exact list depends on the network
     *                                where this contract is deployed. See note attached to the
     *                                blockedSystemAddresses variable in this contract for more
     *                                detailed information about what this block list can and
     *                                cannot be used for.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __CrossDomainMessenger_init(
        address _otherMessenger,
        address[] memory _blockedSystemAddresses
    ) internal onlyInitializing {
        xDomainMsgSender = DEFAULT_XDOMAIN_SENDER;
        otherMessenger = _otherMessenger;
        for (uint256 i = 0; i < _blockedSystemAddresses.length; i++) {
            blockedSystemAddresses[_blockedSystemAddresses[i]] = true;
        }

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    /**
     * @notice Sends a low-level message to the other messenger. Needs to be implemented by child
     *         contracts because the logic for this depends on the network where the messenger is
     *         being deployed.
     */
    function _sendMessage(
        address _to,
        uint64 _gasLimit,
        uint256 _value,
        bytes memory _data
    ) internal virtual;

    /**
     * @notice Checks whether the message is coming from the other messenger. Implemented by child
     *         contracts because the logic for this depends on the network where the messenger is
     *         being deployed.
     */
    function _isOtherMessenger() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title TwoStepOwnableUpgradeable
 * @notice This contract is a slightly modified version of OpenZeppelin's `OwnableUpgradeable` contract with the
 *         caveat that ownership transfer occurs in two phases. First, the current owner initiates the transfer,
 *         and then the new owner accepts it. Ownership isn't actually transferred until both steps have been
 *         completed. The purpose of this is to ensure that ownership isn't accidentally transferred to the
 *         incorrect address. Note that the initial owner account is the contract deployer by default. Also
 *         note that this contract can only be used through inheritance.
 */
abstract contract TwoStepOwnableUpgradeable is
    Initializable,
    ContextUpgradeable
{
    address private _owner;

    // A potential owner is specified by the owner when the transfer is initiated. A potential owner
    // does not have any ownership privileges until it accepts the transfer.
    address private _potentialOwner;

    /**
     * @notice Emitted when ownership transfer is initiated.
     *
     * @param owner          The current owner.
     * @param potentialOwner The address that the owner specifies as the new owner.
     */
    event OwnershipTransferInitiated(
        address indexed owner,
        address indexed potentialOwner
    );

    /**
     * @notice Emitted when ownership transfer is finalized.
     *
     * @param previousOwner The previous owner.
     * @param newOwner      The new owner.
     */
    event OwnershipTransferFinalized(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice Emitted when ownership transfer is cancelled.
     *
     * @param owner                   The current owner.
     * @param cancelledPotentialOwner The previous potential owner that can no longer accept ownership.
     */
    event OwnershipTransferCancelled(
        address indexed owner,
        address indexed cancelledPotentialOwner
    );

    /**
     * @notice Initializes the contract, setting the deployer as the initial owner.
     */
    function __TwoStepOwnable_init() internal onlyInitializing {
        __TwoStepOwnable_init_unchained();
    }

    function __TwoStepOwnable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @notice Reverts if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @notice Reverts if called by any account other than the potential owner.
     */
    modifier onlyPotentialOwner() {
        _checkPotentialOwner();
        _;
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Returns the address of the potential owner.
     */
    function potentialOwner() public view virtual returns (address) {
        return _potentialOwner;
    }

    /**
     * @notice Reverts if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(
            owner() == _msgSender(),
            "TwoStepOwnableUpgradeable: caller is not the owner"
        );
    }

    /**
     * @notice Reverts if the sender is not the potential owner.
     */
    function _checkPotentialOwner() internal view virtual {
        require(
            potentialOwner() == _msgSender(),
            "TwoStepOwnableUpgradeable: caller is not the potential owner"
        );
    }

    /**
     * @notice Initiates ownership transfer of the contract to a new account. Can only be called by
     *         the current owner.
     * @param newOwner The address that the owner specifies as the new owner.
     */
    // slither-disable-next-line external-function
    function initiateOwnershipTransfer(address newOwner)
        external
        virtual
        onlyOwner
    {
        require(
            newOwner != address(0),
            "TwoStepOwnableUpgradeable: new owner is the zero address"
        );
        _potentialOwner = newOwner;
        emit OwnershipTransferInitiated(owner(), newOwner);
    }

    /**
     * @notice Finalizes ownership transfer of the contract to a new account. Can only be called by
     *         the account that is accepting the ownership transfer.
     */
    // slither-disable-next-line external-function
    function acceptOwnershipTransfer() public virtual onlyPotentialOwner {
        _transferOwnership(msg.sender);
    }

    /**
     * @notice Cancels the ownership transfer to the new account, keeping the current owner as is. The current
     *         owner should call this function if the transfer is initiated to the wrong address. Can only be
     *         called by the current owner.
     */
    // slither-disable-next-line external-function
    function cancelOwnershipTransfer() public virtual onlyOwner {
        require(potentialOwner() != address(0), "TwoStepOwnableUpgradeable: no existing potential owner to cancel");
        address previousPotentialOwner = _potentialOwner;
        _potentialOwner = address(0);
        emit OwnershipTransferCancelled(owner(), previousPotentialOwner);
    }

    /**
     * @notice Leaves the contract without an owner. This makes it impossible to perform any ownership
     *         functionality, including calling `onlyOwner` functions. Can only be called by the current owner.
     *         Note that renouncing ownership is a single step process.
     */
    // slither-disable-next-line external-function
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice Transfers ownership of the contract to a new account.
     *
     * @param newOwner The new owner of the contract.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        _potentialOwner = address(0);
        emit OwnershipTransferFinalized(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    IERC721Enumerable
} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title IOptimismMintableERC721
 * @notice Interface for contracts that are compatible with the OptimismMintableERC721 standard.
 *         Tokens that follow this standard can be easily transferred across the ERC721 bridge.
 */
interface IOptimismMintableERC721 is IERC721Enumerable {
    /**
     * @notice Emitted when a token is minted.
     *
     * @param account Address of the account the token was minted to.
     * @param tokenId Token ID of the minted token.
     */
    event Mint(address indexed account, uint256 tokenId);

    /**
     * @notice Emitted when a token is burned.
     *
     * @param account Address of the account the token was burned from.
     * @param tokenId Token ID of the burned token.
     */
    event Burn(address indexed account, uint256 tokenId);

    /**
     * @notice Chain ID of the chain where the remote token is deployed.
     */
    function remoteChainId() external view returns (uint256);

    /**
     * @notice Address of the token on the remote domain.
     */
    function remoteToken() external view returns (address);

    /**
     * @notice Address of the ERC721 bridge on this network.
     */
    function bridge() external view returns (address);

    /**
     * @notice Mints some token ID for a user.
     *
     * @param _to      Address of the user to mint the token for.
     * @param _tokenId Token ID to mint.
     */
    function mint(address _to, uint256 _tokenId) external;

    /**
     * @notice Burns a token ID from a user.
     *
     * @param _from    Address of the user to burn the token from.
     * @param _tokenId Token ID to burn.
     */
    function burn(address _from, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Types } from "./Types.sol";
import { Encoding } from "./Encoding.sol";

/**
 * @title Hashing
 * @notice Hashing handles Optimism's various different hashing schemes.
 */
library Hashing {
    /**
     * @notice Computes the hash of the RLP encoded L2 transaction that would be generated when a
     *         given deposit is sent to the L2 system. Useful for searching for a deposit in the L2
     *         system.
     *
     * @param _tx User deposit transaction to hash.
     *
     * @return Hash of the RLP encoded L2 deposit transaction.
     */
    function hashDepositTransaction(Types.UserDepositTransaction memory _tx)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(Encoding.encodeDepositTransaction(_tx));
    }

    /**
     * @notice Computes the deposit transaction's "source hash", a value that guarantees the hash
     *         of the L2 transaction that corresponds to a deposit is unique and is
     *         deterministically generated from L1 transaction data.
     *
     * @param _l1BlockHash Hash of the L1 block where the deposit was included.
     * @param _logIndex    The index of the log that created the deposit transaction.
     *
     * @return Hash of the deposit transaction's "source hash".
     */
    function hashDepositSource(bytes32 _l1BlockHash, uint256 _logIndex)
        internal
        pure
        returns (bytes32)
    {
        bytes32 depositId = keccak256(abi.encode(_l1BlockHash, _logIndex));
        return keccak256(abi.encode(bytes32(0), depositId));
    }

    /**
     * @notice Hashes the cross domain message based on the version that is encoded into the
     *         message nonce.
     *
     * @param _nonce    Message nonce with version encoded into the first two bytes.
     * @param _sender   Address of the sender of the message.
     * @param _target   Address of the target of the message.
     * @param _value    ETH value to send to the target.
     * @param _gasLimit Gas limit to use for the message.
     * @param _data     Data to send with the message.
     *
     * @return Hashed cross domain message.
     */
    function hashCrossDomainMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) internal pure returns (bytes32) {
        (, uint16 version) = Encoding.decodeVersionedNonce(_nonce);
        if (version == 0) {
            return hashCrossDomainMessageV0(_target, _sender, _data, _nonce);
        } else if (version == 1) {
            return hashCrossDomainMessageV1(_nonce, _sender, _target, _value, _gasLimit, _data);
        } else {
            revert("Hashing: unknown cross domain message version");
        }
    }

    /**
     * @notice Hashes a cross domain message based on the V0 (legacy) encoding.
     *
     * @param _target Address of the target of the message.
     * @param _sender Address of the sender of the message.
     * @param _data   Data to send with the message.
     * @param _nonce  Message nonce.
     *
     * @return Hashed cross domain message.
     */
    function hashCrossDomainMessageV0(
        address _target,
        address _sender,
        bytes memory _data,
        uint256 _nonce
    ) internal pure returns (bytes32) {
        return keccak256(Encoding.encodeCrossDomainMessageV0(_target, _sender, _data, _nonce));
    }

    /**
     * @notice Hashes a cross domain message based on the V1 (current) encoding.
     *
     * @param _nonce    Message nonce.
     * @param _sender   Address of the sender of the message.
     * @param _target   Address of the target of the message.
     * @param _value    ETH value to send to the target.
     * @param _gasLimit Gas limit to use for the message.
     * @param _data     Data to send with the message.
     *
     * @return Hashed cross domain message.
     */
    function hashCrossDomainMessageV1(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) internal pure returns (bytes32) {
        return
            keccak256(
                Encoding.encodeCrossDomainMessageV1(
                    _nonce,
                    _sender,
                    _target,
                    _value,
                    _gasLimit,
                    _data
                )
            );
    }

    /**
     * @notice Derives the withdrawal hash according to the encoding in the L2 Withdrawer contract
     *
     * @param _tx Withdrawal transaction to hash.
     *
     * @return Hashed withdrawal transaction.
     */
    function hashWithdrawal(Types.WithdrawalTransaction memory _tx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(_tx.nonce, _tx.sender, _tx.target, _tx.value, _tx.gasLimit, _tx.data)
            );
    }

    /**
     * @notice Hashes the various elements of an output root proof into an output root hash which
     *         can be used to check if the proof is valid.
     *
     * @param _outputRootProof Output root proof which should hash to an output root.
     *
     * @return Hashed output root proof.
     */
    function hashOutputRootProof(Types.OutputRootProof memory _outputRootProof)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _outputRootProof.version,
                    _outputRootProof.stateRoot,
                    _outputRootProof.withdrawerStorageRoot,
                    _outputRootProof.latestBlockhash
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Types } from "./Types.sol";
import { Hashing } from "./Hashing.sol";
import { RLPWriter } from "./rlp/RLPWriter.sol";

/**
 * @title Encoding
 * @notice Encoding handles Optimism's various different encoding schemes.
 */
library Encoding {
    /**
     * @notice RLP encodes the L2 transaction that would be generated when a given deposit is sent
     *         to the L2 system. Useful for searching for a deposit in the L2 system.
     *         This currently only supports user deposits and not system
     *         transactions.
     *
     * @param _tx User deposit transaction to encode.
     *
     * @return RLP encoded L2 deposit transaction.
     */
    function encodeDepositTransaction(Types.UserDepositTransaction memory _tx)
        internal
        pure
        returns (bytes memory)
    {
        bytes32 source = Hashing.hashDepositSource(_tx.l1BlockHash, _tx.logIndex);
        bytes[] memory raw = new bytes[](8);
        raw[0] = RLPWriter.writeBytes(abi.encodePacked(source));
        raw[1] = RLPWriter.writeAddress(_tx.from);
        raw[2] = _tx.isCreation ? RLPWriter.writeBytes("") : RLPWriter.writeAddress(_tx.to);
        raw[3] = RLPWriter.writeUint(_tx.mint);
        raw[4] = RLPWriter.writeUint(_tx.value);
        raw[5] = RLPWriter.writeUint(uint256(_tx.gasLimit));
        raw[6] = RLPWriter.writeBool(false);
        raw[7] = RLPWriter.writeBytes(_tx.data);
        return abi.encodePacked(uint8(0x7e), RLPWriter.writeList(raw));
    }

    /**
     * @notice Encodes the cross domain message based on the version that is encoded into the
     *         message nonce.
     *
     * @param _nonce    Message nonce with version encoded into the first two bytes.
     * @param _sender   Address of the sender of the message.
     * @param _target   Address of the target of the message.
     * @param _value    ETH value to send to the target.
     * @param _gasLimit Gas limit to use for the message.
     * @param _data     Data to send with the message.
     *
     * @return Encoded cross domain message.
     */
    function encodeCrossDomainMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) internal pure returns (bytes memory) {
        (, uint16 version) = decodeVersionedNonce(_nonce);
        if (version == 0) {
            return encodeCrossDomainMessageV0(_target, _sender, _data, _nonce);
        } else if (version == 1) {
            return encodeCrossDomainMessageV1(_nonce, _sender, _target, _value, _gasLimit, _data);
        } else {
            revert("Encoding: unknown cross domain message version");
        }
    }

    /**
     * @notice Encodes a cross domain message based on the V0 (legacy) encoding.
     *
     * @param _target Address of the target of the message.
     * @param _sender Address of the sender of the message.
     * @param _data   Data to send with the message.
     * @param _nonce  Message nonce.
     *
     * @return Encoded cross domain message.
     */
    function encodeCrossDomainMessageV0(
        address _target,
        address _sender,
        bytes memory _data,
        uint256 _nonce
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "relayMessage(address,address,bytes,uint256)",
                _target,
                _sender,
                _data,
                _nonce
            );
    }

    /**
     * @notice Encodes a cross domain message based on the V1 (current) encoding.
     *
     * @param _nonce    Message nonce.
     * @param _sender   Address of the sender of the message.
     * @param _target   Address of the target of the message.
     * @param _value    ETH value to send to the target.
     * @param _gasLimit Gas limit to use for the message.
     * @param _data     Data to send with the message.
     *
     * @return Encoded cross domain message.
     */
    function encodeCrossDomainMessageV1(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "relayMessage(uint256,address,address,uint256,uint256,bytes)",
                _nonce,
                _sender,
                _target,
                _value,
                _gasLimit,
                _data
            );
    }

    /**
     * @notice Adds a version number into the first two bytes of a message nonce.
     *
     * @param _nonce   Message nonce to encode into.
     * @param _version Version number to encode into the message nonce.
     *
     * @return Message nonce with version encoded into the first two bytes.
     */
    function encodeVersionedNonce(uint240 _nonce, uint16 _version) internal pure returns (uint256) {
        uint256 nonce;
        assembly {
            nonce := or(shl(240, _version), _nonce)
        }
        return nonce;
    }

    /**
     * @notice Pulls the version out of a version-encoded nonce.
     *
     * @param _nonce Message nonce with version encoded into the first two bytes.
     *
     * @return Nonce without encoded version.
     * @return Version of the message.
     */
    function decodeVersionedNonce(uint256 _nonce) internal pure returns (uint240, uint16) {
        uint240 nonce;
        uint16 version;
        assembly {
            nonce := and(_nonce, 0x0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            version := shr(240, _nonce)
        }
        return (nonce, version);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @title SafeCall
 * @notice Perform low level safe calls
 */
library SafeCall {
    /**
     * @notice Perform a low level call without copying any returndata
     *
     * @param _target   Address to call
     * @param _gas      Amount of gas to pass to the call
     * @param _value    Amount of value to pass to the call
     * @param _calldata Calldata to pass to the call
     */
    function call(
        address _target,
        uint256 _gas,
        uint256 _value,
        bytes memory _calldata
    ) internal returns (bool) {
        bool _success;
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                _value, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
        }
        return _success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Types
 * @notice Contains various types used throughout the Optimism contract system.
 */
library Types {
    /**
     * @notice OutputProposal represents a commitment to the L2 state. The timestamp is the L1
     *         timestamp that the output root is posted. This timestamp is used to verify that the
     *         finalization period has passed since the output root was submitted.
     */
    struct OutputProposal {
        bytes32 outputRoot;
        uint256 timestamp;
    }

    /**
     * @notice Struct representing the elements that are hashed together to generate an output root
     *         which itself represents a snapshot of the L2 state.
     */
    struct OutputRootProof {
        bytes32 version;
        bytes32 stateRoot;
        bytes32 withdrawerStorageRoot;
        bytes32 latestBlockhash;
    }

    /**
     * @notice Struct representing a deposit transaction (L1 => L2 transaction) created by an end
     *         user (as opposed to a system deposit transaction generated by the system).
     */
    struct UserDepositTransaction {
        address from;
        address to;
        bool isCreation;
        uint256 value;
        uint256 mint;
        uint64 gasLimit;
        bytes data;
        bytes32 l1BlockHash;
        uint256 logIndex;
    }

    /**
     * @notice Struct representing a withdrawal transaction.
     */
    struct WithdrawalTransaction {
        uint256 nonce;
        address sender;
        address target;
        uint256 value;
        uint256 gasLimit;
        bytes data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @custom:attribution https://github.com/bakaoh/solidity-rlp-encode
 * @title RLPWriter
 * @author RLPWriter is a library for encoding Solidity types to RLP bytes. Adapted from Bakaoh's
 *         RLPEncode library (https://github.com/bakaoh/solidity-rlp-encode) with minor
 *         modifications to improve legibility.
 */
library RLPWriter {
    /**
     * @notice RLP encodes a byte string.
     *
     * @param _in The byte string to encode.
     *
     * @return The RLP encoded string in bytes.
     */
    function writeBytes(bytes memory _in) internal pure returns (bytes memory) {
        bytes memory encoded;

        if (_in.length == 1 && uint8(_in[0]) < 128) {
            encoded = _in;
        } else {
            encoded = abi.encodePacked(_writeLength(_in.length, 128), _in);
        }

        return encoded;
    }

    /**
     * @notice RLP encodes a list of RLP encoded byte byte strings.
     *
     * @param _in The list of RLP encoded byte strings.
     *
     * @return The RLP encoded list of items in bytes.
     */
    function writeList(bytes[] memory _in) internal pure returns (bytes memory) {
        bytes memory list = _flatten(_in);
        return abi.encodePacked(_writeLength(list.length, 192), list);
    }

    /**
     * @notice RLP encodes a string.
     *
     * @param _in The string to encode.
     *
     * @return The RLP encoded string in bytes.
     */
    function writeString(string memory _in) internal pure returns (bytes memory) {
        return writeBytes(bytes(_in));
    }

    /**
     * @notice RLP encodes an address.
     *
     * @param _in The address to encode.
     *
     * @return The RLP encoded address in bytes.
     */
    function writeAddress(address _in) internal pure returns (bytes memory) {
        return writeBytes(abi.encodePacked(_in));
    }

    /**
     * @notice RLP encodes a uint.
     *
     * @param _in The uint256 to encode.
     *
     * @return The RLP encoded uint256 in bytes.
     */
    function writeUint(uint256 _in) internal pure returns (bytes memory) {
        return writeBytes(_toBinary(_in));
    }

    /**
     * @notice RLP encodes a bool.
     *
     * @param _in The bool to encode.
     *
     * @return The RLP encoded bool in bytes.
     */
    function writeBool(bool _in) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = (_in ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }

    /**
     * @notice Encode the first byte and then the `len` in binary form if `length` is more than 55.
     *
     * @param _len    The length of the string or the payload.
     * @param _offset 128 if item is string, 192 if item is list.
     *
     * @return RLP encoded bytes.
     */
    function _writeLength(uint256 _len, uint256 _offset) private pure returns (bytes memory) {
        bytes memory encoded;

        if (_len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes1(uint8(_len) + uint8(_offset));
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (_len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes1(uint8(lenLen) + uint8(_offset) + 55);
            for (i = 1; i <= lenLen; i++) {
                encoded[i] = bytes1(uint8((_len / (256**(lenLen - i))) % 256));
            }
        }

        return encoded;
    }

    /**
     * @notice Encode integer in big endian binary form with no leading zeroes.
     *
     * @param _x The integer to encode.
     *
     * @return RLP encoded bytes.
     */
    function _toBinary(uint256 _x) private pure returns (bytes memory) {
        bytes memory b = abi.encodePacked(_x);

        uint256 i = 0;
        for (; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }

        bytes memory res = new bytes(32 - i);
        for (uint256 j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }

        return res;
    }

    /**
     * @custom:attribution https://github.com/Arachnid/solidity-stringutils
     * @notice Copies a piece of memory to another location.
     *
     * @param _dest Destination location.
     * @param _src  Source location.
     * @param _len  Length of memory to copy.
     */
    function _memcpy(
        uint256 _dest,
        uint256 _src,
        uint256 _len
    ) private pure {
        uint256 dest = _dest;
        uint256 src = _src;
        uint256 len = _len;

        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint256 mask;
        unchecked {
            mask = 256**(32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * @custom:attribution https://github.com/sammayo/solidity-rlp-encoder
     * @notice Flattens a list of byte strings into one byte string.
     *
     * @param _list List of byte strings to flatten.
     *
     * @return The flattened byte string.
     */
    function _flatten(bytes[] memory _list) private pure returns (bytes memory) {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i = 0;
        for (; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly {
            flattenedPtr := add(flattened, 0x20)
        }

        for (i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly {
                listPtr := add(item, 0x20)
            }

            _memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

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