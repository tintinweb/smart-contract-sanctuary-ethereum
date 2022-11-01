// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

import "../lib/EIP712.sol";
import {AbstractConditionOracle} from "./AbstractConditionOracle.sol";

contract OneTimeOffchainTickets is AbstractConditionOracle {
    using EIP712 for address;

    struct Rewarded {
        uint256 claimedAmount;
        uint32 currentNonce;
    }

    struct DecodedTicket {
        address user;
        uint256 amount;
        uint256 claimedAmount;
        uint32 nonce;
        bytes callData;
        bytes rawTicket;
    }

    /// @dev Value returned by a call to `isValidSignature` if the check
    /// was successful. The value is defined as:
    /// bytes4(keccak256("isAllowed(address,uint256,uint256,uint32,bytes)"))
    bytes4 private constant MAGICVALUE = 0x834943e8;

    /// @dev The EIP-712 domain type hash used for computing the domain
    /// separator.
    bytes32 internal constant DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @dev The EIP-712 domain name used for computing the domain separator.
    bytes32 internal constant DOMAIN_NAME = keccak256("ValidTicket");

    /// @dev The EIP-712 domain version used for computing the domain separator.
    bytes32 internal constant DOMAIN_VERSION = keccak256("v1");

    /// @dev The domain separator used for signing orders that gets mixed in
    /// making signatures for different domains incompatible. This domain
    /// separator is computed following the EIP-712 standard and has replay
    /// protection mixed in so that signed orders are only valid for specific
    /// contracts.
    bytes32 public immutable DOMAIN_SEPARATOR;

    mapping(address => Rewarded) internal claimedRewards;
    address public validator;

    event NewValidator(address owner, address indexed newValidator);
    event UsedTicket(
        address indexed account,
        bytes32 indexed ticket,
        uint32 indexed nonce,
        uint256 totalClaimedAmount,
        uint256 amount
    );

    /**
     * @dev Constructor allows setting and initial settings and consumer contract.
     *
     * @param _claimInterface interface used to distribute reward tokens, usually mint or transfer.
     * @param _rewardToken ERC20 or ERC1155 reward token contract address.
     * @param _rewardTokenId ERC1155 token id used for reward, pass 0 for ERC20 reward token.
     * @param _defaultConsumer address of contract which is authorized to call `consumeClaim`.
     */
    constructor(bytes4 _claimInterface, address _rewardToken, uint256 _rewardTokenId, address _defaultConsumer) {
        _changeSettings(_claimInterface, _rewardToken, _rewardTokenId);
        if (_defaultConsumer != address(0)) {
            canConsumeClaims[_defaultConsumer] = true;
            emit ConsumerAdded(_defaultConsumer);
        }
        
        // NOTE: Currently, the only way to get the chain ID in solidity is
        // using assembly.
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                DOMAIN_NAME,
                DOMAIN_VERSION,
                chainId,
                address(this)
            )
        );

        validator = owner();
        emit NewValidator(msg.sender, msg.sender);
    }

    /**
     * @dev Expose configuration API for reward engine for ticket rewards to owner address.
     *
     * @param _rewardToken ERC20 or ERC1155 reward token contract address.
     * @param _rewardTokenId ERC1155 token id used for reward, pass 0 for ERC20 reward token.
     * @param _claimInterface interface used to distribute reward tokens, usually mint or transfer.
     */
    function adminChangeSettings(
      bytes4 _claimInterface,
      address _rewardToken,
      uint256 _rewardTokenId
    ) external onlyOwner {
        _changeSettings(_claimInterface, _rewardToken, _rewardTokenId);
    }

    /**
     * @dev Owner can change validator wallet which signs tickets.
     *
     * @param _newValidator Address of a new validator wallet.
     */
    function adminChangeValidator(address _newValidator) external onlyOwner {
        validator = _newValidator;
        emit NewValidator(msg.sender, _newValidator);
    }

    /**
     * @dev Check if specific account has a valid claim.
     *
     * @param _account Address which owns the ticket.
     * @param _claim Encoded claim with integrity hash and ticket data.
     * @return true if claim is valid.
     */
    function hasClaim(address _account, bytes calldata _claim) public view returns (bool) {
        DecodedTicket memory _ticketData = _decodeClaim(_claim);
        if (_account != _ticketData.user) return false;
        if (_ticketData.nonce <= claimedRewards[_account].currentNonce) return false;
        if (!_isTicketValid(_ticketData)) return false;
        if (_ticketData.amount > 0 && _ticketData.claimedAmount == claimedRewards[_account].claimedAmount) return true;
        return false;
    }

    /**
     * @dev Consume claim by authorized consumer to get reward amount for the claim.
     *
     * @param _account Address which owns the ticket.
     * @param _claim Encoded claim with integrity hash and ticket data.
     * @return reward amount.
     */
    function consumeClaim(address _account, bytes calldata _claim) external returns (uint256) {
        require(canConsumeClaims[msg.sender], "not a consumer");
        DecodedTicket memory _ticketData = _decodeClaim(_claim);
        require(_account == _ticketData.user, "invalid account");
        require(_ticketData.nonce > claimedRewards[_account].currentNonce, "expired ticket");
        uint256 _currentClaimedAmount = claimedRewards[_account].claimedAmount;
        require(_ticketData.amount > 0 && _ticketData.claimedAmount == _currentClaimedAmount, "invalid amount");
        require(_isTicketValid(_ticketData), "invalid ticket");
        bytes32 _ticket = keccak256(_ticketData.rawTicket);
        claimedRewards[_account].currentNonce = _ticketData.nonce;
        uint256 _newClaimedAmount = _currentClaimedAmount + _ticketData.amount;
        claimedRewards[_account].claimedAmount = _newClaimedAmount;
        emit ConsumedClaim(_account, _claim);
        emit UsedTicket(_account, _ticket, _ticketData.nonce, _newClaimedAmount, _ticketData.amount);
        return _ticketData.amount;
    }

    /**
     * @dev Get domain separator in scope of EIP-712.
     *
     * @return EIP-712 domain.
     */
    function getDomainSeparator() public virtual view returns(bytes32) {
        return DOMAIN_SEPARATOR;
    }

    /**
     * @dev Get next valid nonce for the user.
     *
     * @param _account address which will get the next reward.
     * @return next valid nonce.
     */
    function nextNonce(address _account) public view returns(uint32) {
        return claimedRewards[_account].currentNonce + 1;
    }

    /**
     * @dev Get all currently claimed rewards for the address.
     *
     * @param _account rewarded address.
     * @return all claimed rewards by the address.
     */
    function claimedAmount(address _account) public view returns(uint256) {
        return claimedRewards[_account].claimedAmount;
    }

    /**
     * @dev Checks if ticket has a valid issuer.
     *
     * @param _user Address to check for verification.
     * @param _amount Reward for ticket.
     * @param _claimedAmount Total amount already claimed by user.
     * @param _nonce Ticket index.
     * @param _callData Verification signature.
     * @return MAGICVALUE for success 0x00000000 for failure.
     */
    function isAllowed(
        address _user,
        uint256 _amount,
        uint256 _claimedAmount,
        uint32 _nonce,
        bytes memory _callData
    ) public view returns (bytes4) {
        return EIP712._isValidEIP712Signature(
            validator,
            MAGICVALUE,
            abi.encode(DOMAIN_SEPARATOR, _user, _amount, _claimedAmount, _nonce),
            _callData
        );
    }

    /**
     * @dev Wrapper for ticket validation with DecodedTicket structure.
     *
     * @param _ticketData DecodedTicket structure with ticket data to validate.
     * @return true if ticket is valid.
     */
    function _isTicketValid(DecodedTicket memory _ticketData) internal view returns (bool) {
        return isAllowed(
            _ticketData.user,
            _ticketData.amount,
            _ticketData.claimedAmount,
            _ticketData.nonce,
            _ticketData.callData
        ) == MAGICVALUE;
    }

    /**
     * @dev Helper to easily decode claim with integrity hash and ticket data into DecodedTicket structure.
     *
     * @param _claim DecodedTicket structure with ticket data to validate.
     * @return DecodedTicket with decoded ticket data.
     */
    function _decodeClaim(bytes calldata _claim) internal view returns (DecodedTicket memory) {
        (bytes32 _integrity, bytes memory _encodedTicket) = abi.decode(_claim, (bytes32, bytes));
        require(_integrity == integrityHash, "invalid claim");

        (
            address _user,
            uint256 _amount,
            uint256 _claimedAmount,
            uint32 _nonce,
            bytes memory _callData
        ) = abi.decode(_encodedTicket, (address, uint256, uint256, uint32, bytes));

        return DecodedTicket(_user, _amount, _claimedAmount, _nonce, _callData, _encodedTicket);
    }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

library EIP712 {
    /**
     * @dev Check if milestone release was pre-approved.
     *
     * @param _validator Address of opposite party which approval is needed.
     * @param _success bytes4 hash of called function, returned as success result.
     * @param _encodedChallenge abi encoded string of variables to proof.
     * @param _signature Digest of challenge.
     * @return _success for success 0x00000000 for failure.
     */
    function _isValidEIP712Signature(
        address _validator,
        bytes4 _success,
        bytes memory _encodedChallenge,
        bytes memory _signature
    ) internal pure returns (bytes4) {
        uint8 _v;
        bytes32 _r;
        bytes32 _s;
        (_v, _r, _s) = abi.decode(_signature, (uint8, bytes32, bytes32));
        bytes32 _hash = keccak256(_encodedChallenge);
        address _signer =
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
                ),
                _v,
                _r,
                _s
            );

        if (_validator == _signer) {
            return _success;
        } else {
            return bytes4(0);
        }
    }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IConditionOracle} from "../interfaces/IConditionOracle.sol";

abstract contract AbstractConditionOracle is IConditionOracle, Ownable {
    using ERC165Checker for address;

    bytes4 private constant IERC1155_INTERFACE = 0xd9b67a26;
    bytes4 private constant IERC1155_MINT_INTERFACE = 0x731133e9;
    bytes4 private constant IERC20_MINT_INTERFACE = 0x40c10f19;
    bytes4 private constant IERC20_INTERFACE = 0xffffffff;

    bytes32 public integrityHash;
    mapping(address => bool) public override canConsumeClaims;

    event SettingsChanged(
        bytes4 claimInterface,
        address indexed rewardToken,
        uint256 indexed rewardTokenId,
        bytes32 indexed integrityHash
    );

    /**
     * @dev Authorize consumer contract to invalidate claims.
     *
     * @param _consumer Reward amount in rewardToken.
     * @param _allow true to authorize, false to revoke authorization.
     */
    function adminSwitchConsumer(address _consumer, bool _allow) external onlyOwner {
        if (_allow) {
            canConsumeClaims[_consumer] = true;
            emit ConsumerAdded(_consumer);
        } else {
            canConsumeClaims[_consumer] = false;
            emit ConsumerRemoved(_consumer);
        }
    }

    /**
     * @dev Configure reward engine.
     *
     * @param _rewardToken ERC20 or ERC1155 reward token contract address.
     * @param _rewardTokenId ERC1155 token id used for reward, pass 0 for ERC20 reward token.
     * @param _claimInterface interface used to distribute reward tokens, usually mint or transfer.
     */
    function _changeSettings(bytes4 _claimInterface, address _rewardToken, uint256 _rewardTokenId) internal {
        require(
            _claimInterface == IERC20_INTERFACE
            || _claimInterface == IERC20_MINT_INTERFACE
            || _claimInterface == IERC1155_MINT_INTERFACE
            || _rewardToken.supportsInterface(_claimInterface),
            "ConditionalDistributor: Invalid interface"
        );
        bytes32 _hash = keccak256(abi.encodePacked(_rewardToken, _rewardTokenId, _claimInterface));
        integrityHash = _hash;
        emit SettingsChanged(_claimInterface, _rewardToken, _rewardTokenId, _hash);
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
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

// Allows anyone to claim a token if they exist in a merkle root.
interface IConditionOracle {
    function canConsumeClaims(address _consumer) external view returns (bool);
    // Returns true if provided claim is valid and more than 0.
    function hasClaim(address _account, bytes calldata _claim) external view returns (bool);
    // Returns amount of reward for specific claim.
    function consumeClaim(address _account, bytes calldata _claim) external returns (uint256);

    // This event is triggered whenever a claim is consumed
    event ConsumedClaim(
        address indexed account,
        bytes claim
    );

    // New consumer added
    event ConsumerAdded(
        address indexed consumer
    );

    // Old consumer removed
    event ConsumerRemoved(
        address indexed consumer
    );
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