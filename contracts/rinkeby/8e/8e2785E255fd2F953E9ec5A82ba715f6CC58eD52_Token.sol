// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {UUPS} from "../lib/proxy/UUPS.sol";
import {Ownable} from "../lib/utils/Ownable.sol";
import {ReentrancyGuard} from "../lib/utils/ReentrancyGuard.sol";
import {ERC721Votes} from "../lib/token/ERC721Votes.sol";
import {ERC721} from "../lib/token/ERC721.sol";

import {TokenStorageV1} from "./storage/TokenStorageV1.sol";
import {IBaseMetadata} from "./metadata/interfaces/IBaseMetadata.sol";
import {IManager} from "../manager/IManager.sol";
import {IToken} from "./IToken.sol";

/// @title Token
/// @author Rohan Kulkarni
/// @notice DAO governance token
contract Token is IToken, UUPS, ReentrancyGuard, ERC721Votes, TokenStorageV1 {
    ///                                                          ///
    ///                         IMMUTABLES                       ///
    ///                                                          ///

    /// @notice The contract upgrade manager
    IManager private immutable manager;

    ///                                                          ///
    ///                         CONSTRUCTOR                      ///
    ///                                                          ///

    /// @param _manager The address of the contract upgrade manager
    constructor(address _manager) payable initializer {
        manager = IManager(_manager);
    }

    ///                                                          ///
    ///                         INITIALIZER                      ///
    ///                                                          ///

    /// @notice Initializes a DAO's ERC-721 token
    /// @param _founders The founding members to receive vesting allocations
    /// @param _initStrings The encoded token and metadata initialization strings
    /// @param _metadataRenderer The token's metadata renderer
    /// @param _auction The token's auction house
    function initialize(
        IManager.FounderParams[] calldata _founders,
        bytes calldata _initStrings,
        address _metadataRenderer,
        address _auction
    ) external initializer {
        if (msg.sender != address(manager)) revert ONLY_MANAGER();

        // Initialize the reentrancy guard
        __ReentrancyGuard_init();

        // Store the vesting schedules of each founder
        _addFounders(_founders);

        // Decode the token name and symbol
        (string memory _name, string memory _symbol, , , ) = abi.decode(_initStrings, (string, string, string, string, string));

        // Initialize the ERC-721 token
        __ERC721_init(_name, _symbol);

        // Store the token's auction house and metadata renderer
        settings.auction = _auction;
        settings.metadataRenderer = IBaseMetadata(_metadataRenderer);
    }

    ///                                                          ///
    ///                             MINT                         ///
    ///                                                          ///

    /// @notice Mints tokens to the auction house for bidding and handles founder vesting
    function mint() public nonReentrant returns (uint256 tokenId) {
        // Cache the auction address
        address minter = settings.auction;

        // Ensure the caller is the auction
        if (msg.sender != minter) revert ONLY_AUCTION();

        // Cannot realistically overflow
        unchecked {
            do {
                // Get the next available token id
                tokenId = settings.totalSupply++;

                // While the current token is for a founder
            } while (_isToFounder(tokenId));
        }

        // Mint the next token to the auction house for bidding
        _mint(minter, tokenId);
    }

    /// @dev Overrides _mint to include attribute generation
    /// @param _to The token recipient
    /// @param _tokenId The ERC-721 token id
    function _mint(address _to, uint256 _tokenId) internal override {
        // Mint the token
        super._mint(_to, _tokenId);

        // Generate the token attributes
        if (!settings.metadataRenderer.onMinted(_tokenId)) revert NO_METADATA_GENERATED();
    }

    ///                                                          ///
    ///                             BURN                         ///
    ///                                                          ///

    /// @notice Burns a token that did not see any bids
    /// @param _tokenId The ERC-721 token id
    function burn(uint256 _tokenId) public {
        // Ensure the caller is the auction house
        if (msg.sender != settings.auction) revert ONLY_AUCTION();

        // Burn the token
        _burn(_tokenId);
    }

    ///                                                          ///
    ///                           METADATA                       ///
    ///                                                          ///

    /// @notice The URI for a token
    /// @param _tokenId The ERC-721 token id
    function tokenURI(uint256 _tokenId) public view override(IToken, ERC721) returns (string memory) {
        return settings.metadataRenderer.tokenURI(_tokenId);
    }

    /// @notice The URI for the contract
    function contractURI() public view override(IToken, ERC721) returns (string memory) {
        return settings.metadataRenderer.contractURI();
    }

    ///                                                          ///
    ///                           FOUNDERS                       ///
    ///                                                          ///
    /// @notice One of the DAO founders
    /// @param _index The array index of founder
    function getFounder(uint256 _index) external view returns (Founder memory) {
        return founders[_index];
    }

    /// @notice All of the DAO founders
    function getFounders() external view returns (Founder[] memory) {
        return founders;
    }

    /// @dev Checks if a token is elgible to vest to a founder, and mints accordingly if so
    /// @param _tokenId The ERC-721 token id
    /// NOTE: This implementation handles vesting schedule overlaps simply by minting the token to the first eligible founder
    /// - Pros: simple token initialization (ie just store the )
    /// - Cons: runtime gas
    /// TODO storing as mapping with numFounders maeks it easy to reorder
    function _isToFounder(uint256 _tokenId) private returns (bool) {
        // Cache the number of founders
        uint256 numFounders = founders.length;

        // Cannot realistically overflow
        unchecked {
            // For each founder:
            for (uint256 i; i < numFounders; ++i) {
                // Get their vesting details
                Founder memory founder = founders[i];

                // If the token id fits their vesting schedule:
                if (_tokenId % founder.allocationFrequency == 0 && block.timestamp < founder.vestingEnd) {
                    // Mint the token to the founder
                    _mint(founder.wallet, _tokenId);

                    return true;
                }
            }

            return false;
        }
    }

    /// @dev Called upon initialization to store the founders and their vesting schedules
    /// @param _founders The list of DAO founders
    function _addFounders(IManager.FounderParams[] calldata _founders) internal {
        // Cache the number of founders
        uint256 numFounders = _founders.length;

        // Cannot realistically overflow
        unchecked {
            // For each founder:
            for (uint256 i; i < numFounders; ++i) {
                // Allocate storage space
                founders.push();

                // Get their storage location
                Founder storage founder = founders[i];

                // Store their vesting schedule and wallet address
                founder.allocationFrequency = uint32(_founders[i].allocationFrequency);
                founder.vestingEnd = uint64(_founders[i].vestingEnd);
                founder.wallet = _founders[i].wallet;
            }
        }
    }

    ///                                                          ///
    ///                           SETTINGS                       ///
    ///                                                          ///

    /// @notice The total supply of tokens
    function totalSupply() external view returns (uint256) {
        return settings.totalSupply;
    }

    /// @notice The address of the auction house
    function auction() external view returns (address) {
        return settings.auction;
    }

    /// @notice The address of the metadata renderer
    function metadataRenderer() external view returns (address) {
        return address(settings.metadataRenderer);
    }

    /// @notice The address of the owner
    function owner() public view returns (address) {
        return settings.metadataRenderer.owner();
    }

    ///                                                          ///
    ///                         TOKEN UPGRADE                    ///
    ///                                                          ///

    /// @notice Ensures the caller is authorized to upgrade the contract and that the new implementation is valid
    /// @dev This function is called in `upgradeTo` & `upgradeToAndCall`
    /// @param _newImpl The new implementation address
    function _authorizeUpgrade(address _newImpl) internal view override {
        // Ensure the caller is the shared owner of the token and metadata renderer
        if (msg.sender != owner()) revert ONLY_OWNER();

        // Ensure the implementation is valid
        if (!manager.isRegisteredUpgrade(_getImplementation(), _newImpl)) revert INVALID_UPGRADE(_newImpl);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IUUPS } from "../interfaces/IUUPS.sol";
import { ERC1967Upgrade } from "./ERC1967Upgrade.sol";

/// @title UUPS
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/utils/UUPSUpgradeable.sol)
/// - Uses custom errors declared in IUUPS
/// - Inherits a modified ERC1967Upgrade
abstract contract UUPS is IUUPS, ERC1967Upgrade {
    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    /// @dev The address of the implementation
    address private immutable __self = address(this);

    ///                                                          ///
    ///                           MODIFIERS                      ///
    ///                                                          ///

    /// @dev Ensures that execution is via proxy delegatecall with the same implementation
    modifier onlyProxy() {
        if (address(this) == __self) revert ONLY_DELEGATECALL();
        if (_getImplementation() != __self) revert ONLY_PROXY();
        _;
    }

    /// @dev Ensures that execution is via direct call
    modifier notDelegated() {
        if (address(this) != __self) revert CANNOT_DELEGATECALL();
        _;
    }

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Hook to authorize an implementation upgrade
    /// @param _newImpl The new implementation address
    function _authorizeUpgrade(address _newImpl) internal virtual;

    /// @notice Upgrades to an implementation
    /// @param _newImpl The new implementation address
    function upgradeTo(address _newImpl) external onlyProxy {
        _authorizeUpgrade(_newImpl);
        _upgradeToAndCallUUPS(_newImpl, "", false);
    }

    /// @notice Upgrades to an implementation with an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function upgradeToAndCall(address _newImpl, bytes memory _data) external payable onlyProxy {
        _authorizeUpgrade(_newImpl);
        _upgradeToAndCallUUPS(_newImpl, _data, true);
    }

    /// @notice The storage slot of the implementation address
    function proxiableUUID() external view notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IOwnable } from "../interfaces/IOwnable.sol";
import { Initializable } from "../utils/Initializable.sol";

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (access/OwnableUpgradeable.sol)
/// - Uses custom errors declared in IOwnable
/// - Adds optional two-step ownership transfer (`safeTransferOwnership` + `acceptOwnership`)
abstract contract Ownable is IOwnable, Initializable {
    ///                                                          ///
    ///                            STORAGE                       ///
    ///                                                          ///

    /// @dev The address of the owner
    address internal _owner;

    /// @dev The address of the pending owner
    address internal _pendingOwner;

    ///                                                          ///
    ///                           MODIFIERS                      ///
    ///                                                          ///

    /// @dev Ensures the caller is the owner
    modifier onlyOwner() {
        if (msg.sender != _owner) revert ONLY_OWNER();
        _;
    }

    /// @dev Ensures the caller is the pending owner
    modifier onlyPendingOwner() {
        if (msg.sender != _pendingOwner) revert ONLY_PENDING_OWNER();
        _;
    }

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Initializes contract ownership
    /// @param _initialOwner The initial owner address
    function __Ownable_init(address _initialOwner) internal onlyInitializing {
        _owner = _initialOwner;

        emit OwnerUpdated(address(0), _initialOwner);
    }

    /// @notice The address of the owner
    function owner() public view returns (address) {
        return _owner;
    }

    /// @notice The address of the pending owner
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /// @notice Forces an ownership transfer
    /// @param _newOwner The new owner address
    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnerUpdated(_owner, _newOwner);

        _owner = _newOwner;
    }

    /// @notice Initiates a two-step ownership transfer
    /// @param _newOwner The new owner address
    function safeTransferOwnership(address _newOwner) public onlyOwner {
        _pendingOwner = _newOwner;

        emit OwnerPending(_owner, _newOwner);
    }

    /// @notice Accepts an ownership transfer
    function acceptOwnership() public onlyPendingOwner {
        emit OwnerUpdated(_owner, msg.sender);

        _owner = _pendingOwner;

        delete _pendingOwner;
    }

    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() public onlyOwner {
        emit OwnerCanceled(_owner, _pendingOwner);

        delete _pendingOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Initializable } from "../utils/Initializable.sol";

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (security/ReentrancyGuardUpgradeable.sol)
/// - Uses custom error `REENTRANCY()`
abstract contract ReentrancyGuard is Initializable {
    ///                                                          ///
    ///                            STORAGE                       ///
    ///                                                          ///

    /// @dev Indicates that a function has not been entered
    uint256 internal constant _NOT_ENTERED = 1;

    /// @dev Indicates that a function has been entered
    uint256 internal constant _ENTERED = 2;

    /// @notice The reentrancy status of a function
    uint256 internal _status;

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if attempted reentrancy
    error REENTRANCY();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Initializes the reentrancy guard
    function __ReentrancyGuard_init() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /// @dev Ensures a function cannot be reentered
    modifier nonReentrant() {
        if (_status == _ENTERED) revert REENTRANCY();

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC721Votes } from "../interfaces/IERC721Votes.sol";
import { ERC721 } from "../token/ERC721.sol";
import { EIP712 } from "../utils/EIP712.sol";

/// @title ERC721Votes
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (token/ERC721/extensions/draft-ERC721Votes.sol)
/// - Uses custom errors defined in IERC721Votes
/// - Checkpoints use timestamps instead of block numbers
/// - Tokens are self-delegated by default
/// - Total number of votes isn't tracked, as that's the token supply itself (1 NFT = 1 Vote)
abstract contract ERC721Votes is IERC721Votes, EIP712, ERC721 {
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    /// @dev The EIP-712 typehash to delegate with a signature
    bytes32 internal constant DELEGATION_TYPEHASH = keccak256("Delegation(address from,address to,uint256 nonce,uint256 deadline)");

    ///                                                          ///
    ///                           STORAGE                        ///
    ///                                                          ///

    /// @notice The delegate for an account
    /// @notice Account => Delegate
    mapping(address => address) internal delegation;

    /// @notice The number of checkpoints for an account
    /// @dev Account => Num Checkpoints
    mapping(address => uint256) internal numCheckpoints;

    /// @notice The checkpoint for an account
    /// @dev Account => Checkpoint Id => Checkpoint
    mapping(address => mapping(uint256 => Checkpoint)) internal checkpoints;

    ///                                                          ///
    ///                        VOTING WEIGHT                     ///
    ///                                                          ///

    /// @notice The current number of votes for an account
    /// @param _account The account address
    function getVotes(address _account) public view returns (uint256) {
        // Get the account's number of checkpoints
        uint256 nCheckpoints = numCheckpoints[_account];

        // Cannot underflow as `nCheckpoints` is ensured to be greater than 0 if reached
        unchecked {
            // Return the number of votes at the latest checkpoint if applicable
            return nCheckpoints != 0 ? checkpoints[_account][nCheckpoints - 1].votes : 0;
        }
    }

    /// @notice The number of votes for an account at a past timestamp
    /// @param _account The account address
    /// @param _timestamp The past timestamp
    function getPastVotes(address _account, uint256 _timestamp) public view returns (uint256) {
        // Ensure the given timestamp is in the past
        if (_timestamp >= block.timestamp) revert INVALID_TIMESTAMP();

        // Get the account's number of checkpoints
        uint256 nCheckpoints = numCheckpoints[_account];

        // If there are none return 0
        if (nCheckpoints == 0) return 0;

        // Get the account's checkpoints
        mapping(uint256 => Checkpoint) storage accountCheckpoints = checkpoints[_account];

        unchecked {
            // Get the latest checkpoint id
            // Cannot underflow as `nCheckpoints` is ensured to be greater than 0
            uint256 lastCheckpoint = nCheckpoints - 1;

            // If the latest checkpoint has a valid timestamp, return its number of votes
            if (accountCheckpoints[lastCheckpoint].timestamp <= _timestamp) return accountCheckpoints[lastCheckpoint].votes;

            // On the flip, if the first checkpoint doesn't have a valid timestamp, return 0
            if (accountCheckpoints[0].timestamp > _timestamp) return 0;

            // Otherwise, find a checkpoint with a valid timestamp
            // Use the latest id as the initial upper bound
            uint256 high = lastCheckpoint;
            uint256 low;
            uint256 middle;

            // Used to temporarily store a checkpoint
            Checkpoint memory cp;

            // While a valid checkpoint is to be found:
            while (high > low) {
                // Find the id of the middle checkpoint
                middle = high - (high - low) / 2;

                // Get the middle checkpoint
                cp = accountCheckpoints[middle];

                // If the timestamp is a match:
                if (cp.timestamp == _timestamp) {
                    // Return the voting weight
                    return cp.votes;

                    // Else if the timestamp is before the one looking for:
                } else if (cp.timestamp < _timestamp) {
                    // Update the lower bound
                    low = middle;

                    // Else update the upper bound
                } else {
                    high = middle - 1;
                }
            }

            return accountCheckpoints[low].votes;
        }
    }

    ///                                                          ///
    ///                          DELEGATION                      ///
    ///                                                          ///

    /// @notice The delegate for an account
    /// @param _account The account address
    function delegates(address _account) external view returns (address) {
        address current = delegation[_account];
        return current == address(0) ? _account : current;
    }

    /// @notice Delegates votes to an account
    /// @param _to The address delegating votes to
    function delegate(address _to) external {
        _delegate(msg.sender, _to);
    }

    /// @notice Delegates votes from a signer to an account
    /// @param _from The address delegating votes from
    /// @param _to The address delegating votes to
    /// @param _deadline The signature deadline
    /// @param _v The 129th byte and chain id of the signature
    /// @param _r The first 64 bytes of the signature
    /// @param _s Bytes 64-128 of the signature
    function delegateBySig(
        address _from,
        address _to,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        // Ensure the signature has not expired
        if (block.timestamp > _deadline) revert EXPIRED_SIGNATURE();

        // Used to store the message hash
        bytes32 digest;

        // Cannot realistically overflow
        unchecked {
            // Compute the signed message hash
            digest = keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), keccak256(abi.encode(DELEGATION_TYPEHASH, _from, _to, nonces[_from]++, _deadline)))
            );
        }

        // Recover the message signer
        address recoveredAddress = ecrecover(digest, _v, _r, _s);

        // Ensure the recovered signer is the voter
        if (recoveredAddress == address(0) || recoveredAddress != _from) revert INVALID_SIGNER();

        // Update the delegate
        _delegate(_from, _to);
    }

    /// @dev Updates delegate addresses
    /// @param _from The address delegating votes from
    /// @param _to The address delegating votes to
    function _delegate(address _from, address _to) internal {
        // Get the previous delegate
        address prevDelegate = delegation[_from];

        // Store the new delegate
        delegation[_from] = _to;

        emit DelegateChanged(_from, prevDelegate, _to);

        // Transfer voting weight from the previous delegate to the new delegate
        _moveDelegateVotes(prevDelegate, _to, balanceOf(_from));
    }

    /// @dev Transfers voting weight
    /// @param _from The address delegating votes from
    /// @param _to The address delegating votes to
    /// @param _amount The number of votes delegating
    function _moveDelegateVotes(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        unchecked {
            // If voting weight is being transferred:
            if (_from != _to && _amount > 0) {
                // If this isn't a mint:
                if (_from != address(0)) {
                    // Get the sender's number of checkpoints
                    uint256 nCheckpoints = numCheckpoints[_from]++;

                    // Used to store the sender's previous voting weight
                    uint256 prevTotalVotes;

                    // If this isn't the sender's first checkpoint: Get their previous voting weight
                    if (nCheckpoints != 0) prevTotalVotes = checkpoints[_from][nCheckpoints - 1].votes;

                    // Update their voting weight
                    _writeCheckpoint(_from, nCheckpoints, prevTotalVotes, prevTotalVotes - _amount);
                }

                // If this isn't a burn:
                if (_to != address(0)) {
                    // Get the receiver's number of checkpoints
                    uint256 nCheckpoints = numCheckpoints[_to]++;

                    // Used to store the receiver's previous voting weight
                    uint256 prevTotalVotes;

                    // If this isn't the recipient's first checkpoint: Get their previous voting weight
                    if (nCheckpoints != 0) prevTotalVotes = checkpoints[_to][nCheckpoints - 1].votes;

                    // Update their voting weight
                    _writeCheckpoint(_to, nCheckpoints, prevTotalVotes, prevTotalVotes + _amount);
                }
            }
        }
    }

    /// @dev Records a checkpoint
    /// @param _account The account address
    /// @param _id The checkpoint id
    /// @param _prevTotalVotes The account's previous voting weight
    /// @param _newTotalVotes The account's new voting weight
    function _writeCheckpoint(
        address _account,
        uint256 _id,
        uint256 _prevTotalVotes,
        uint256 _newTotalVotes
    ) private {
        // Get the location to write the checkpoint
        Checkpoint storage checkpoint = checkpoints[_account][_id];

        // Store the new voting total and current time
        checkpoint.votes = uint192(_newTotalVotes);
        checkpoint.timestamp = uint64(block.timestamp);

        emit DelegateVotesChanged(_account, _prevTotalVotes, _newTotalVotes);
    }

    /// @dev Enables each NFT to equal 1 vote
    /// @param _from The token sender
    /// @param _to The token recipient
    /// @param _tokenId The ERC-721 token id
    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        // Transfer 1 vote from the sender to the recipient
        _moveDelegateVotes(_from, _to, 1);

        super._afterTokenTransfer(_from, _to, _tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC721 } from "../interfaces/IERC721.sol";
import { Initializable } from "../utils/Initializable.sol";
import { ERC721TokenReceiver } from "../utils/TokenReceiver.sol";
import { Address } from "../utils/Address.sol";

/// @title ERC721
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (token/ERC721/ERC721Upgradeable.sol)
/// - Uses custom errors declared in IERC721
abstract contract ERC721 is IERC721, Initializable {
    ///                                                          ///
    ///                            STORAGE                       ///
    ///                                                          ///

    /// @notice The token name
    string public name;

    /// @notice The token symbol
    string public symbol;

    /// @notice The token owners
    /// @dev ERC-721 token id => Owner
    mapping(uint256 => address) internal owners;

    /// @notice The owner balances
    /// @dev Owner => Balance
    mapping(address => uint256) internal balances;

    /// @notice The token approvals
    /// @dev ERC-721 token id => Manager
    mapping(uint256 => address) internal tokenApprovals;

    /// @notice The balance approvals
    /// @dev Owner => Operator => Approved
    mapping(address => mapping(address => bool)) internal operatorApprovals;

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Initializes an ERC-721 token
    /// @param _name The ERC-721 token name
    /// @param _symbol The ERC-721 token symbol
    function __ERC721_init(string memory _name, string memory _symbol) internal onlyInitializing {
        name = _name;
        symbol = _symbol;
    }

    /// @notice The Uniform Resource Identifier (URI) for a token
    /// @param _tokenId The ERC-721 token id
    function tokenURI(uint256 _tokenId) public view virtual returns (string memory) {}

    /// @notice The Uniform Resource Identifier (URI) for a contract
    function contractURI() public view virtual returns (string memory) {}

    /// @notice If the contract implements an interface
    /// @param _interfaceId The interface id
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return
            _interfaceId == 0x01ffc9a7 || // ERC165 Interface ID
            _interfaceId == 0x80ac58cd || // ERC721 Interface ID
            _interfaceId == 0x5b5e139f; // ERC721Metadata Interface ID
    }

    /// @notice The account approved to manage a token
    /// @param _tokenId The ERC-721 token id
    function getApproved(uint256 _tokenId) external view returns (address) {
        return tokenApprovals[_tokenId];
    }

    /// @notice If an operator is authorized to manage all of an owner's tokens
    /// @param _owner The owner address
    /// @param _operator The operator address
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    /// @notice The number of tokens owned
    /// @param _owner The owner address
    function balanceOf(address _owner) public view returns (uint256) {
        if (_owner == address(0)) revert ADDRESS_ZERO();

        return balances[_owner];
    }

    /// @notice The owner of a token
    /// @param _tokenId The ERC-721 token id
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = owners[_tokenId];

        if (owner == address(0)) revert INVALID_OWNER();

        return owner;
    }

    /// @notice Authorizes an account to manage a token
    /// @param _to The account address
    /// @param _tokenId The ERC-721 token id
    function approve(address _to, uint256 _tokenId) external {
        address owner = owners[_tokenId];

        if (msg.sender != owner && !operatorApprovals[owner][msg.sender]) revert INVALID_APPROVAL();

        tokenApprovals[_tokenId] = _to;

        emit Approval(owner, _to, _tokenId);
    }

    /// @notice Authorizes an account to manage all tokens
    /// @param _operator The account address
    /// @param _approved If permission is being given or removed
    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApprovals[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Transfers a token from sender to recipient
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        if (_from != owners[_tokenId]) revert INVALID_OWNER();

        if (_to == address(0)) revert ADDRESS_ZERO();

        if (msg.sender != _from && !operatorApprovals[_from][msg.sender] && msg.sender != tokenApprovals[_tokenId]) revert INVALID_APPROVAL();

        _beforeTokenTransfer(_from, _to, _tokenId);

        unchecked {
            --balances[_from];

            ++balances[_to];
        }

        owners[_tokenId] = _to;

        delete tokenApprovals[_tokenId];

        emit Transfer(_from, _to, _tokenId);

        _afterTokenTransfer(_from, _to, _tokenId);
    }

    /// @notice Safe transfers a token from sender to recipient
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        transferFrom(_from, _to, _tokenId);

        if (
            Address.isContract(_to) &&
            ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "") != ERC721TokenReceiver.onERC721Received.selector
        ) revert INVALID_RECIPIENT();
    }

    /// @notice Safe transfers a token from sender to recipient with additional data
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external {
        transferFrom(_from, _to, _tokenId);

        if (
            Address.isContract(_to) &&
            ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) != ERC721TokenReceiver.onERC721Received.selector
        ) revert INVALID_RECIPIENT();
    }

    /// @dev Mints a token to a recipient
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function _mint(address _to, uint256 _tokenId) internal virtual {
        if (_to == address(0)) revert ADDRESS_ZERO();

        if (owners[_tokenId] != address(0)) revert ALREADY_MINTED();

        _beforeTokenTransfer(address(0), _to, _tokenId);

        unchecked {
            ++balances[_to];
        }

        owners[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);

        _afterTokenTransfer(address(0), _to, _tokenId);
    }

    /// @dev Burns a token to a recipient
    /// @param _tokenId The ERC-721 token id
    function _burn(uint256 _tokenId) internal virtual {
        address owner = owners[_tokenId];

        if (owner == address(0)) revert NOT_MINTED();

        _beforeTokenTransfer(owner, address(0), _tokenId);

        unchecked {
            --balances[owner];
        }

        delete owners[_tokenId];

        delete tokenApprovals[_tokenId];

        emit Transfer(owner, address(0), _tokenId);

        _afterTokenTransfer(owner, address(0), _tokenId);
    }

    /// @dev Hook called before a token transfer
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}

    /// @dev Hook called after a token transfer
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { TokenTypesV1 } from "../types/TokenTypesV1.sol";

/// @title TokenStorageV1
/// @author Rohan Kulkarni
/// @notice The Token storage contract
contract TokenStorageV1 is TokenTypesV1 {
    /// @notice The token settings
    Settings internal settings;

    /// @notice The DAO founders
    Founder[] internal founders;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IUUPS } from "../../../lib/interfaces/IUUPS.sol";
import { IOwnable } from "../../../lib/utils/Ownable.sol";

/// @title IBaseMetadata
/// @author Rohan Kulkarni
/// @notice The external Base Metadata errors and functions
interface IBaseMetadata is IUUPS, IOwnable {
    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if the caller was not the contract manager
    error ONLY_MANAGER();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice Initializes a DAO's token metadata renderer
    /// @param initStrings The encoded token and metadata initialization strings
    /// @param token The associated ERC-721 token address
    /// @param founder The founder address responsible for adding
    /// @param treasury The DAO treasury where ownership will be transferred
    function initialize(
        bytes calldata initStrings,
        address token,
        address founder,
        address treasury
    ) external;

    function onMinted(uint256 tokenId) external returns (bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function contractURI() external view returns (string memory);

    function token() external view returns (address);

    function treasury() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IUUPS } from "../lib/interfaces/IUUPS.sol";
import { IOwnable } from "../lib/interfaces/IOwnable.sol";

/// @title IManager
/// @author Rohan Kulkarni
/// @notice The external Manager events, errors, structs and functions
interface IManager is IUUPS, IOwnable {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when a DAO is deployed
    /// @param token The ERC-721 token address
    /// @param metadata The metadata renderer address
    /// @param auction The auction address
    /// @param treasury The treasury address
    /// @param governor The governor address
    event DAODeployed(address token, address metadata, address auction, address treasury, address governor);

    /// @notice Emitted when an upgrade is registered by the Builder DAO
    /// @param baseImpl The base implementation address
    /// @param upgradeImpl The upgrade implementation address
    event UpgradeRegistered(address baseImpl, address upgradeImpl);

    /// @notice Emitted when an upgrade is unregistered by the Builder DAO
    /// @param baseImpl The base implementation address
    /// @param upgradeImpl The upgrade implementation address
    event UpgradeUnregistered(address baseImpl, address upgradeImpl);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if at least one founder is not provided upon deploy
    error FOUNDER_REQUIRED();

    ///                                                          ///
    ///                            STRUCTS                       ///
    ///                                                          ///

    /// @notice The founder parameters
    /// @param wallet The wallet address
    /// @param allocationFrequency The frequency of tokens to vest them (eg. Every 10 tokens to Nounders)
    /// @param vestingEnd The timestamp that their vesting will end
    struct FounderParams {
        address wallet;
        uint256 allocationFrequency;
        uint256 vestingEnd;
    }

    /// @notice The ERC-721 token parameters
    /// @param initStrings The encoded token name, symbol, description, contract image, renderer base
    struct TokenParams {
        bytes initStrings;
    }

    /// @notice The auction parameters
    /// @param reservePrice The reserve price of each auction
    /// @param duration The duration of each auction
    struct AuctionParams {
        uint256 reservePrice;
        uint256 duration;
    }

    /// @notice The governance parameters
    /// @param timelockDelay The amount of time a queued proposal is delayed until execution
    /// @param votingDelay The amount of time after a submitted proposal until voting begins
    /// @param votingPeriod The amount of time voting takes place for an active proposal
    /// @param proposalThresholdBps The minimum votes (in basis points of the total supply) required to submit a proposal
    /// @param quorumThresholdBps The minimum votes (in basis points of total supply) required to reach quorum
    struct GovParams {
        uint256 timelockDelay;
        uint256 votingDelay;
        uint256 votingPeriod;
        uint256 proposalThresholdBps;
        uint256 quorumThresholdBps;
    }

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The token implementation address
    function tokenImpl() external view returns (address);

    /// @notice The metadata renderer implementation address
    function metadataImpl() external view returns (address);

    /// @notice The auction house implementation address
    function auctionImpl() external view returns (address);

    /// @notice The treasury implementation address
    function treasuryImpl() external view returns (address);

    /// @notice The governor implementation address
    function governorImpl() external view returns (address);

    /// @notice Deploys a DAO with custom token, auction, and governance settings
    /// @param founderParams The DAO founder(s)
    /// @param tokenParams The ERC-721 token settings
    /// @param auctionParams The auction settings
    /// @param govParams The governance settings
    function deploy(
        FounderParams[] calldata founderParams,
        TokenParams calldata tokenParams,
        AuctionParams calldata auctionParams,
        GovParams calldata govParams
    )
        external
        returns (
            address token,
            address metadataRenderer,
            address auction,
            address treasury,
            address governor
        );

    /// @notice A DAO's remaining contract addresses from its token address
    /// @param token The ERC-721 token address
    function getAddresses(address token)
        external
        returns (
            address metadataRenderer,
            address auction,
            address treasury,
            address governor
        );

    /// @notice If an implementation is registered by the Builder DAO as an optional upgrade
    /// @param baseImpl The base implementation address
    /// @param upgradeImpl The upgrade implementation address
    function isRegisteredUpgrade(address baseImpl, address upgradeImpl) external view returns (bool);

    /// @notice Called by the Builder DAO to offer opt-in implementation upgrades for all other DAOs
    /// @param baseImpl The base implementation address
    /// @param upgradeImpl The upgrade implementation address
    function registerUpgrade(address baseImpl, address upgradeImpl) external;

    /// @notice Called by the Builder DAO to remove an upgrade
    /// @param baseImpl The base implementation address
    /// @param upgradeImpl The upgrade implementation address
    function unregisterUpgrade(address baseImpl, address upgradeImpl) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IUUPS } from "../lib/interfaces/IUUPS.sol";
import { IERC721Votes } from "../lib/interfaces/IERC721Votes.sol";
import { IManager } from "../manager/IManager.sol";
import { TokenTypesV1 } from "./types/TokenTypesV1.sol";

/// @title IToken
/// @author Rohan Kulkarni
/// @notice The external Token errors and functions
interface IToken is IUUPS, IERC721Votes, TokenTypesV1 {
    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if the caller was not the contract owner
    error ONLY_OWNER();

    /// @dev Reverts if the caller was not the auction contract
    error ONLY_AUCTION();

    /// @dev Reverts if no metadata was generated upon mint
    error NO_METADATA_GENERATED();

    /// @dev Reverts if the caller was not the contract manager
    error ONLY_MANAGER();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice Initializes a DAO's ERC-721 token
    /// @param founders The founding members to receive vesting allocations
    /// @param initStrings The encoded token and metadata initialization strings
    /// @param metadataRenderer The token's metadata renderer
    /// @param auction The token's auction house
    function initialize(
        IManager.FounderParams[] calldata founders,
        bytes calldata initStrings,
        address metadataRenderer,
        address auction
    ) external;

    /// @notice Mints tokens to the auction house for bidding and handles founder vesting
    function mint() external returns (uint256 tokenId);

    /// @notice Burns a token that did not see any bids
    /// @param tokenId The ERC-721 token id
    function burn(uint256 tokenId) external;

    /// @notice The URI for a token
    /// @param tokenId The ERC-721 token id
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /// @notice The URI for the contract
    function contractURI() external view returns (string memory);

    /// @notice One of the DAO founders
    /// @param index The array index of founder
    function getFounder(uint256 index) external view returns (Founder memory);

    /// @notice All of the DAO founders
    function getFounders() external view returns (Founder[] memory);

    /// @notice The total supply of tokens
    function totalSupply() external view returns (uint256);

    /// @notice The token's auction house
    function auction() external view returns (address);

    /// @notice The token's metadata renderer
    function metadataRenderer() external view returns (address);

    /// @notice The owner of the token and metadata renderer
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC1822Proxiable } from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import { IERC1967Upgrade } from "./IERC1967Upgrade.sol";

/// @title IUUPS
/// @author Rohan Kulkarni
/// @notice The external UUPS errors and functions
interface IUUPS is IERC1967Upgrade, IERC1822Proxiable {
    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if not called directly
    error CANNOT_DELEGATECALL();

    /// @dev Reverts if not called via delegatecall
    error ONLY_DELEGATECALL();

    /// @dev Reverts if not called via proxy
    error ONLY_PROXY();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice Upgrades to an implementation
    /// @param newImpl The new implementation address
    function upgradeTo(address newImpl) external;

    /// @notice Upgrades to an implementation with an additional function call
    /// @param newImpl The new implementation address
    /// @param data The encoded function call
    function upgradeToAndCall(address newImpl, bytes memory data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC1822Proxiable } from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";

import { IERC1967Upgrade } from "../interfaces/IERC1967Upgrade.sol";
import { Address } from "../utils/Address.sol";

/// @title ERC1967Upgrade
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/ERC1967/ERC1967Upgrade.sol)
/// - Uses custom errors declared in IERC1967Upgrade
/// - Removes ERC1967 admin and beacon support
abstract contract ERC1967Upgrade is IERC1967Upgrade {
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    /// @dev bytes32(uint256(keccak256('eip1967.proxy.rollback')) - 1)
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /// @dev bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @dev Upgrades to an implementation with security checks for UUPS proxies and an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function _upgradeToAndCallUUPS(
        address _newImpl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(_newImpl);
        } else {
            try IERC1822Proxiable(_newImpl).proxiableUUID() returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT) revert UNSUPPORTED_UUID();
            } catch {
                revert ONLY_UUPS();
            }

            _upgradeToAndCall(_newImpl, _data, _forceCall);
        }
    }

    /// @dev Upgrades to an implementation with an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function _upgradeToAndCall(
        address _newImpl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        _upgradeTo(_newImpl);

        if (_data.length > 0 || _forceCall) {
            Address.functionDelegateCall(_newImpl, _data);
        }
    }

    /// @dev Performs an implementation upgrade
    /// @param _newImpl The new implementation address
    function _upgradeTo(address _newImpl) internal {
        _setImplementation(_newImpl);

        emit Upgraded(_newImpl);
    }

    /// @dev Stores the address of an implementation
    /// @param _impl The implementation address
    function _setImplementation(address _impl) private {
        if (!Address.isContract(_impl)) revert INVALID_UPGRADE(_impl);

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _impl;
    }

    /// @dev The address of the current implementation
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IERC1967Upgrade
/// @author Rohan Kulkarni
/// @notice The external ERC1967Upgrade events and errors
interface IERC1967Upgrade {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when the implementation is upgraded
    /// @param impl The address of the implementation
    event Upgraded(address impl);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if an implementation is an invalid upgrade
    /// @param impl The address of the invalid implementation
    error INVALID_UPGRADE(address impl);

    /// @dev Reverts if an implementation upgrade is not stored at the storage slot of the original
    error UNSUPPORTED_UUID();

    /// @dev Reverts if an implementation does not support ERC1822 proxiableUUID()
    error ONLY_UUPS();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (utils/Address.sol)
/// - Uses custom errors
/// - Adds toBytes32() util
library Address {
    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if the target of a delegatecall is not a contract
    error INVALID_TARGET();

    /// @dev Reverts if a delegatecall has failed
    error DELEGATE_CALL_FAILED();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Converts an address to bytes32
    function toBytes32(address _account) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_account)) << 96);
    }

    /// @dev If an address is a contract
    function isContract(address _account) internal view returns (bool rv) {
        assembly {
            rv := gt(extcodesize(_account), 0)
        }
    }

    /// @dev Performs a delegatecall on an address
    function functionDelegateCall(address _target, bytes memory _data) internal returns (bytes memory) {
        if (!isContract(_target)) revert INVALID_TARGET();

        (bool success, bytes memory returndata) = _target.delegatecall(_data);

        return verifyCallResult(success, returndata);
    }

    /// @dev Verifies a delegatecall was successful
    function verifyCallResult(bool _success, bytes memory _returndata) internal pure returns (bytes memory) {
        if (_success) {
            return _returndata;
        } else {
            if (_returndata.length > 0) {
                assembly {
                    let returndata_size := mload(_returndata)

                    revert(add(32, _returndata), returndata_size)
                }
            } else {
                revert DELEGATE_CALL_FAILED();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IOwnable
/// @author Rohan Kulkarni
/// @notice The external Ownable events, errors, and functions
interface IOwnable {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when ownership has been updated
    /// @param prevOwner The previous owner address
    /// @param newOwner The new owner address
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    /// @notice Emitted when an ownership transfer is pending
    /// @param owner The current owner address
    /// @param pendingOwner The pending new owner address
    event OwnerPending(address indexed owner, address indexed pendingOwner);

    /// @notice Emitted when a pending ownership transfer has been canceled
    /// @param owner The current owner address
    /// @param canceledOwner The canceled owner address
    event OwnerCanceled(address indexed owner, address indexed canceledOwner);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if an unauthorized user calls an owner function
    error ONLY_OWNER();

    /// @dev Reverts if an unauthorized user calls a pending owner function
    error ONLY_PENDING_OWNER();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The address of the owner
    function owner() external view returns (address);

    /// @notice The address of the pending owner
    function pendingOwner() external view returns (address);

    /// @notice Forces an ownership transfer
    /// @param newOwner The new owner address
    function transferOwnership(address newOwner) external;

    /// @notice Initiates a two-step ownership transfer
    /// @param newOwner The new owner address
    function safeTransferOwnership(address newOwner) external;

    /// @notice Accepts an ownership transfer
    function acceptOwnership() external;

    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IInitializable } from "../interfaces/IInitializable.sol";
import { Address } from "../utils/Address.sol";

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/utils/Initializable.sol)
/// - Uses custom errors declared in IInitializable
abstract contract Initializable is IInitializable {
    ///                                                          ///
    ///                           STORAGE                        ///
    ///                                                          ///

    /// @dev Indicates the contract has been initialized
    uint8 internal _initialized;

    /// @dev Indicates the contract is being initialized
    bool internal _initializing;

    ///                                                          ///
    ///                          MODIFIERS                       ///
    ///                                                          ///

    /// @dev Ensures an initialization function is only called within an `initializer` or `reinitializer` function
    modifier onlyInitializing() {
        if (!_initializing) revert NOT_INITIALIZING();
        _;
    }

    /// @dev Enables initializing upgradeable contracts
    modifier initializer() {
        bool isTopLevelCall = !_initializing;

        if ((!isTopLevelCall || _initialized != 0) && (Address.isContract(address(this)) || _initialized != 1)) revert ALREADY_INITIALIZED();

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

    /// @dev Enables initializer versioning
    /// @param _version The version to set
    modifier reinitializer(uint8 _version) {
        if (_initializing || _initialized >= _version) revert ALREADY_INITIALIZED();

        _initialized = _version;

        _initializing = true;

        _;

        _initializing = false;

        emit Initialized(_version);
    }

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @dev Prevents future initialization
    function _disableInitializers() internal virtual {
        if (_initializing) revert INITIALIZING();

        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;

            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IInitializable
/// @author Rohan Kulkarni
/// @notice The external Initializable events and errors
interface IInitializable {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when the contract has been initialized or reinitialized
    event Initialized(uint256 version);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if address(0) is incorrectly passed
    error ADDRESS_ZERO();

    /// @dev Reverts if attempting to disable initializers during initialization
    error INITIALIZING();

    /// @dev Reverts if calling an initialization function outside of initialization
    error NOT_INITIALIZING();

    /// @dev Reverts if attempting to reinitialize incorrectly
    error ALREADY_INITIALIZED();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC721 } from "./IERC721.sol";
import { IEIP712 } from "./IEIP712.sol";

/// @title IERC721Votes
/// @author Rohan Kulkarni
/// @notice The external ERC721Votes events, errors, and functions
interface IERC721Votes is IERC721, IEIP712 {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when an account changes their delegate
    event DelegateChanged(address indexed delegator, address indexed from, address indexed to);

    /// @notice Emitted when a delegate's number of votes is updated
    event DelegateVotesChanged(address indexed delegate, uint256 prevTotalVotes, uint256 newTotalVotes);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if the provided timestamp is not in the past
    error INVALID_TIMESTAMP();

    ///                                                          ///
    ///                            STRUCTS                       ///
    ///                                                          ///

    /// @notice The checkpoint data type
    /// @param timestamp The recorded timestamp
    /// @param votes The voting weight
    struct Checkpoint {
        uint64 timestamp;
        uint192 votes;
    }

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The current number of votes for an account
    /// @param account The account address
    function getVotes(address account) external view returns (uint256);

    /// @notice The number of votes for an account at a past timestamp
    /// @param account The account address
    /// @param timestamp The past timestamp
    function getPastVotes(address account, uint256 timestamp) external view returns (uint256);

    /// @notice The delegate for an account
    /// @param account The account address
    function delegates(address account) external view returns (address);

    /// @notice Delegates votes to an account
    /// @param to The address delegating votes to
    function delegate(address to) external;

    /// @notice Delegates votes from a signer to an account
    /// @param from The address delegating votes from
    /// @param to The address delegating votes to
    /// @param deadline The signature deadline
    /// @param v The 129th byte and chain id of the signature
    /// @param r The first 64 bytes of the signature
    /// @param s Bytes 64-128 of the signature
    function delegateBySig(
        address from,
        address to,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IEIP712 } from "../interfaces/IEIP712.sol";
import { Initializable } from "../utils/Initializable.sol";

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (utils/cryptography/draft-EIP712Upgradeable.sol)
/// - Uses custom errors declared in IEIP712
/// - Adds `nonces` mapping
/// - Caches `INITIAL_CHAIN_ID` and `INITIAL_DOMAIN_SEPARATOR` upon initialization
abstract contract EIP712 is IEIP712, Initializable {
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    /// @dev The EIP-712 domain typehash
    bytes32 internal constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    ///                                                          ///
    ///                           STORAGE                        ///
    ///                                                          ///

    /// @notice The hash of the EIP-712 domain name
    bytes32 internal HASHED_NAME;

    /// @notice The hash of the EIP-712 domain version
    bytes32 internal HASHED_VERSION;

    /// @notice The domain separator computed upon initialization
    bytes32 internal INITIAL_DOMAIN_SEPARATOR;

    /// @notice The chain id upon initialization
    uint256 internal INITIAL_CHAIN_ID;

    /// @notice The account nonces
    /// @dev Account => Nonce
    mapping(address => uint256) internal nonces;

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Initializes EIP-712 support
    /// @param _name The EIP-712 domain name
    /// @param _version The EIP-712 domain version
    function __EIP712_init(string memory _name, string memory _version) internal onlyInitializing {
        HASHED_NAME = keccak256(bytes(_name));
        HASHED_VERSION = keccak256(bytes(_version));

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /// @notice The current nonce for an account
    /// @param _account The account address
    function nonce(address _account) external view returns (uint256) {
        return nonces[_account];
    }

    /// @notice The EIP-712 domain separator
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    /// @dev Computes the EIP-712 domain separator
    function _computeDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, HASHED_NAME, HASHED_VERSION, block.chainid, address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IERC721
/// @author Rohan Kulkarni
/// @notice The ERC721 external events, errors, and functions
interface IERC721 {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when a token is transferred from sender to recipient
    /// @param from The sender address
    /// @param to The recipient address
    /// @param tokenId The ERC-721 token id
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @notice Emitted when an owner approves an account to manage a token
    /// @param owner The owner address
    /// @param approved The account address
    /// @param tokenId The ERC-721 token id
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// @notice Emitted when an owner sets an approval for a spender to manage all tokens
    /// @param owner The owner address
    /// @param operator The spender address
    /// @param approved If the approval is being set or removed
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if a caller is not authorized to approve or transfer a token
    error INVALID_APPROVAL();

    /// @dev Reverts if a transfer is called with the incorrect token owner
    error INVALID_OWNER();

    /// @dev Reverts if a transfer is attempted to address(0)
    error INVALID_RECIPIENT();

    /// @dev Reverts if an existing token is called to be minted
    error ALREADY_MINTED();

    /// @dev Reverts if a non-existent token is called to be burned
    error NOT_MINTED();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The number of tokens owned
    /// @param owner The owner address
    function balanceOf(address owner) external view returns (uint256);

    /// @notice The owner of a token
    /// @param tokenId The ERC-721 token id
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice The account approved to manage a token
    /// @param tokenId The ERC-721 token id
    function getApproved(uint256 tokenId) external view returns (address);

    /// @notice If an operator is authorized to manage all of an owner's tokens
    /// @param owner The owner address
    /// @param operator The operator address
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Authorizes an account to manage a token
    /// @param to The account address
    /// @param tokenId The ERC-721 token id
    function approve(address to, uint256 tokenId) external;

    /// @notice Authorizes an account to manage all tokens
    /// @param operator The account address
    /// @param approved If permission is being given or removed
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Safe transfers a token from sender to recipient with additional data
    /// @param from The sender address
    /// @param to The recipient address
    /// @param tokenId The ERC-721 token id
    /// @param data The additional data sent in the call to the recipient
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /// @notice Safe transfers a token from sender to recipient
    /// @param from The sender address
    /// @param to The recipient address
    /// @param tokenId The ERC-721 token id
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /// @notice Transfers a token from sender to recipient
    /// @param from The sender address
    /// @param to The recipient address
    /// @param tokenId The ERC-721 token id
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IEIP712
/// @author Rohan Kulkarni
/// @notice The external EIP712 errors and functions
interface IEIP712 {
    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if the deadline has passed to submit a signature
    error EXPIRED_SIGNATURE();

    /// @dev Reverts if the recovered signature is invalid
    error INVALID_SIGNER();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The sig nonce for an account
    /// @param account The account address
    function nonce(address account) external view returns (uint256);

    /// @notice The EIP-712 domain separator
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (token/ERC721/utils/ERC721Holder.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (token/ERC1155/utils/ERC1155Holder.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IBaseMetadata } from "../metadata/interfaces/IBaseMetadata.sol";

/// @title TokenTypesV1
/// @author Rohan Kulkarni
/// @notice The Token custom data types
interface TokenTypesV1 {
    /// @notice The settings type
    /// @param totalSupply The number of tokens minted
    /// @param auction The DAO auction house
    /// @param metadatarenderer The token metadata renderer
    struct Settings {
        uint96 totalSupply;
        address auction;
        IBaseMetadata metadataRenderer;
    }

    /// @notice The founder type
    /// @param allocationFrequency The number of tokens between vests (eg Every 10 nouns to nounders)
    /// @param vestingEnd The timestamp when vesting ends
    /// @param wallet The address where tokens are sent
    struct Founder {
        uint32 allocationFrequency;
        uint64 vestingEnd;
        address wallet;
    }
}