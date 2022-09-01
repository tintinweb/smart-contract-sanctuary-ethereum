// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { L2ERC721Registry } from "./L2ERC721Registry.sol";
import {
    CrossDomainEnabled
} from "@eth-optimism/contracts/libraries/bridge/CrossDomainEnabled.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title L1OwnershipVerifier
 * @notice Allows the owner of an L1 ERC721 to claim ownership of the ERC721's L2 representation in
 *         the L2ERC721Registry. Note that this contract only works with the Ownable interface. In
 *         other words, the L1 ERC721 contract must return the address of the owner when called with
 *         the `owner()` function.
 */
contract L1OwnershipVerifier is CrossDomainEnabled, Initializable {
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
     * @notice Minimum gas limit for the cross-domain message on L2.
     */
    uint32 public minGasLimit;

    /**
     * @param _l1Messenger Address of the L1CrossDomainMessenger.
     */
    constructor(address _l1Messenger) CrossDomainEnabled(_l1Messenger) {}

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
        sendCrossDomainMessage(l2ERC721Registry, minGasLimit, message);

        emit L1ERC721OwnershipClaimed(msg.sender, _l1ERC721, _l2Owner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {
    CrossDomainEnabled
} from "@eth-optimism/contracts/libraries/bridge/CrossDomainEnabled.sol";
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
contract L2ERC721Registry is CrossDomainEnabled, TwoStepOwnableUpgradeable {
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
     * @notice In general, it's discouraged to use a constructor inside of an upgradeable
     *         implementation contract. However, we must use one to initialize CrossDomainEnabled.
     *         This is fine because we do not assign variables within the constructor, except
     *         for `messenger`, which is immediately re-assigned in the initialize function. This
     *         same pattern has been used in Optimism's legacy L1StandardBridge.
     */
    constructor() CrossDomainEnabled(address(0)) {
        _disableInitializers();
    }

    /**
     * @notice Initializer. Only callable once.
     *
     * @param _l1OwnershipVerifier Address of the L1OwnershipVerifier contract.
     * @param _messenger           Address of the L2CrossDomainMessenger.
     */
    function initialize(address _l1OwnershipVerifier, address _messenger) external initializer {
        l1OwnershipVerifier = _l1OwnershipVerifier;
        messenger = _messenger;

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
        onlyFromCrossDomainAccount(l1OwnershipVerifier)
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
pragma solidity >0.5.0 <0.9.0;

/* Interface Imports */
import { ICrossDomainMessenger } from "./ICrossDomainMessenger.sol";

/**
 * @title CrossDomainEnabled
 * @dev Helper contract for contracts performing cross-domain communications
 *
 * Compiler used: defined by inheriting contract
 */
contract CrossDomainEnabled {
    /*************
     * Variables *
     *************/

    // Messenger contract used to send and recieve messages from the other domain.
    address public messenger;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _messenger Address of the CrossDomainMessenger on the current layer.
     */
    constructor(address _messenger) {
        messenger = _messenger;
    }

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Enforces that the modified function is only callable by a specific cross-domain account.
     * @param _sourceDomainAccount The only account on the originating domain which is
     *  authenticated to call this function.
     */
    modifier onlyFromCrossDomainAccount(address _sourceDomainAccount) {
        require(
            msg.sender == address(getCrossDomainMessenger()),
            "OVM_XCHAIN: messenger contract unauthenticated"
        );

        require(
            getCrossDomainMessenger().xDomainMessageSender() == _sourceDomainAccount,
            "OVM_XCHAIN: wrong sender of cross-domain message"
        );

        _;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Gets the messenger, usually from storage. This function is exposed in case a child contract
     * needs to override.
     * @return The address of the cross-domain messenger contract which should be used.
     */
    function getCrossDomainMessenger() internal virtual returns (ICrossDomainMessenger) {
        return ICrossDomainMessenger(messenger);
    }

    /**q
     * Sends a message to an account on another domain
     * @param _crossDomainTarget The intended recipient on the destination domain
     * @param _message The data to send to the target (usually calldata to a function with
     *  `onlyFromCrossDomainAccount()`)
     * @param _gasLimit The gasLimit for the receipt of the message on the target domain.
     */
    function sendCrossDomainMessage(
        address _crossDomainTarget,
        uint32 _gasLimit,
        bytes memory _message
    ) internal {
        // slither-disable-next-line reentrancy-events, reentrancy-benign
        getCrossDomainMessenger().sendMessage(_crossDomainTarget, _message, _gasLimit);
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
            "TwoStepOwnable: caller is not the owner"
        );
    }

    /**
     * @notice Reverts if the sender is not the potential owner.
     */
    function _checkPotentialOwner() internal view virtual {
        require(
            potentialOwner() == _msgSender(),
            "TwoStepOwnable: caller is not the potential owner"
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
            "TwoStepOwnable: new owner is the zero address"
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
        require(potentialOwner() != address(0), "TwoStepOwnable: no existing potential owner to cancel");
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
pragma solidity >0.5.0 <0.9.0;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
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