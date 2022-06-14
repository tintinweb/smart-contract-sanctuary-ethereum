// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBVeNft.sol';
import './interfaces/IJBVeNftDeployer.sol';

/**
  @notice
  Allows a project owner to deploy a veNFT contract.
*/
contract JBVeNftDeployer is IJBVeNftDeployer, JBOperatable {
  /**
    @notice
    Mints ERC-721's that represent project ownership.
  */
  IJBProjects public immutable override projects;

  //*********************************************************************//
  // ---------------------------- constructor -------------------------- //
  //*********************************************************************//

  /**
    @param _projects A contract which mints ERC-721's that represent project ownership and transfers.
    @param _operatorStore A contract storing operator assignments.
  */
  constructor(IJBProjects _projects, IJBOperatorStore _operatorStore) JBOperatable(_operatorStore) {
    projects = _projects;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Allows anyone to deploy a new project payer contract.

    @param _projectId The ID of the project.
    @param _name Nft name.
    @param _symbol Nft symbol.
    @param _uriResolver Token uri resolver instance.
    @param _tokenStore The JBTokenStore where unclaimed tokens are accounted for.
    @param _lockDurationOptions The lock options, in seconds, for lock durations.
    @param _owner The address that will own the staking contract.

    @return veNft The ve NFT contract that was deployed.
  */
  function deployVeNFT(
    uint256 _projectId,
    string memory _name,
    string memory _symbol,
    IJBVeTokenUriResolver _uriResolver,
    IJBTokenStore _tokenStore,
    IJBOperatorStore _operatorStore,
    uint256[] memory _lockDurationOptions,
    address _owner
  )
    external
    override
    // requirePermission(projects.ownerOf(_projectId), _projectId, JBStakingOperations.DEPLOY_VE_NFT)
    returns (IJBVeNft veNft)
  {
    // Deploy the ve nft contract.
    veNft = new JBVeNft(
      _projectId,
      _name,
      _symbol,
      _uriResolver,
      _tokenStore,
      _operatorStore,
      _lockDurationOptions,
      _owner
    );

    emit DeployVeNft(
      _projectId,
      _name,
      _symbol,
      _uriResolver,
      _tokenStore,
      _operatorStore,
      _lockDurationOptions,
      _owner,
      msg.sender
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@jbx-protocol/contracts-v2/contracts/abstract/JBOperatable.sol';

import './veERC721.sol';
import './interfaces/IJBVeNft.sol';
import './interfaces/IJBVeTokenUriResolver.sol';
import './libraries/JBStakingOperations.sol';
import './libraries/JBErrors.sol';

/**
  @notice
  Allows any JBToken holders to stake their tokens and receive a Banny based on their stake and lock in period.

  @dev 
  Bannies are transferrable, will be burnt when the stake is claimed before or after the lock-in period ends.
  The Token URI will be determined by SVG for each banny category.
  Inherits from:
  ERC721Votes - for ERC721 and governance support.
  Ownable - for access control.
  ReentrancyGuard - for protection against external calls.
*/
contract JBVeNft is IJBVeNft, veERC721, Ownable, ReentrancyGuard, JBOperatable {
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error INVALID_ACCOUNT();
  error NON_EXISTENT_TOKEN();
  error INSUFFICIENT_ALLOWANCE();
  error LOCK_PERIOD_NOT_OVER();
  error TOKEN_MISMATCH();
  error INVALID_PUBLIC_EXTENSION_FLAG_VALUE();
  error INVALID_LOCK_EXTENSION();
  error EXCEEDS_MAX_LOCK_DURATION();

  event Lock(
    uint256 indexed tokenId,
    address indexed account,
    uint256 amount,
    uint256 duration,
    address beneficiary,
    uint256 lockedUntil,
    address caller
  );

  event Unlock(uint256 indexed tokenId, address beneficiary, uint256 amount, address caller);

  event ExtendLock(
    uint256 indexed oldTokenID,
    uint256 indexed newTokenID,
    uint256 updatedDuration,
    uint256 updatedLockedUntil,
    address caller
  );

  event SetAllowPublicExtension(uint256 indexed tokenId, bool allowPublicExtension, address caller);

  event Redeem(
    uint256 indexed tokenId,
    address holder,
    address beneficiary,
    uint256 tokenCount,
    uint256 claimedAmount,
    string memo,
    address caller
  );

  event SetUriResolver(IJBVeTokenUriResolver indexed resolver, address caller);

  //*********************************************************************//
  // --------------------- private stored properties ------------------- //
  //*********************************************************************//

  /** 
    @notice 
    The options for lock durations.
  */
  uint256[] private _lockDurationOptions;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /** 
    @notice 
    JBProject id.
  */
  uint256 public immutable override projectId;

  /** 
    @notice 
    The JBTokenStore where unclaimed tokens are accounted for.
  */
  IJBTokenStore public immutable override tokenStore;

  /** 
    @notice 
    Token URI Resolver Instance
  */
  IJBVeTokenUriResolver public override uriResolver;

  /** 
    @notice 
    Banny id counter
  */
  uint256 public override count;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
    @notice
    The lock duration options

    @return An array of lock duration options, in seconds.
  */
  function lockDurationOptions() external view override returns (uint256[] memory) {
    return _lockDurationOptions;
  }

  /**
    @notice
    provides the metadata for the storefront
  */
  function contractURI() public view override returns (string memory) {
    return uriResolver.contractURI();
  }

  /**
    @notice 
    Computes the metadata url based on the id.

    @param _tokenId TokenId of the Banny

    @return dynamic uri based on the svg logic for that particular banny
  */
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    // If there isn't a token resolver, return an empty string.
    if (uriResolver == IJBVeTokenUriResolver(address(0))) return '';

    (uint256 _amount, uint256 _duration, uint256 _lockedUntil, , ) = getSpecs(_tokenId);
    return uriResolver.tokenURI(_tokenId, _amount, _duration, _lockedUntil, _lockDurationOptions);
  }

  /**
    @dev Requires override. Calls super.
  */
  function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
    return super.supportsInterface(_interfaceId);
  }

  /**
    @notice
    Unpacks the packed specs of each banny based on token id.

    @param _tokenId Banny Id.

    @return amount Locked token count.
    @return duration Locked duration.
    @return lockedUntil Locked until this timestamp.
    @return useJbToken If the locked tokens are JBTokens. 
    @return allowPublicExtension If the locked position can be extended by anyone. 
  */
  function getSpecs(uint256 _tokenId)
    public
    view
    override
    returns (
      uint256 amount,
      uint256 duration,
      uint256 lockedUntil,
      bool useJbToken,
      bool allowPublicExtension
    )
  {
    LockedBalance memory _lock = locked[_tokenId];
    if (_lock.end == 0) revert NON_EXISTENT_TOKEN();

    amount = uint256(uint128(_lock.amount));
    lockedUntil = _lock.end;
    useJbToken = _lock.useJbToken;
    allowPublicExtension = _lock.allowPublicExtension;
    duration = _lock.duration;
  }

  //*********************************************************************//
  // ---------------------------- constructor -------------------------- //
  //*********************************************************************//

  /**
    @param _projectId The ID of the project.
    @param _name Nft name.
    @param _symbol Nft symbol.
    @param _uriResolver Token uri resolver instance.
    @param _tokenStore The JBTokenStore where unclaimed tokens are accounted for.
    @param _operatorStore A contract storing operator assignments.
    @param __lockDurationOptions The lock options, in seconds, for lock durations.
    @param _owner The address that'll own this contract.
  */
  constructor(
    uint256 _projectId,
    string memory _name,
    string memory _symbol,
    IJBVeTokenUriResolver _uriResolver,
    IJBTokenStore _tokenStore,
    IJBOperatorStore _operatorStore,
    uint256[] memory __lockDurationOptions,
    address _owner
  ) JBOperatable(_operatorStore) veERC721(_name, _symbol) {
    token = address(_tokenStore.tokenOf(_projectId));
    projectId = _projectId;
    uriResolver = _uriResolver;
    tokenStore = _tokenStore;
    _lockDurationOptions = __lockDurationOptions;

    // Make sure no durationOption is longer than the max time
    uint256 _maxTime = uint256(uint128(MAXTIME));
    for (uint256 _i; _i < _lockDurationOptions.length; _i++)
      if (_lockDurationOptions[_i] > _maxTime) revert EXCEEDS_MAX_LOCK_DURATION();

    _transferOwnership(_owner);
  }

  //*********************************************************************//
  // --------------------- external transactions ----------------------- //
  //*********************************************************************//

  /**
    @notice
    Allows token holder to lock in their tokens in exchange for a banny.

    @dev
    Only an account or a designated operator can lock its tokens.
    
    @param _account JBToken Holder.
    @param _amount Lock Amount.
    @param _duration Lock time in seconds.
    @param _beneficiary Address to mint the banny.
    @param _useJbToken A flag indicating if JBtokens are being locked. If false, unclaimed project tokens from the JBTokenStore will be locked.
    @param _allowPublicExtension A flag indicating if the locked position can be extended by anyone.

    @return tokenId The tokenId for the new ve position.
  */
  function lock(
    address _account,
    uint256 _amount,
    uint256 _duration,
    address _beneficiary,
    bool _useJbToken,
    bool _allowPublicExtension
  )
    external
    override
    nonReentrant
    requirePermission(_account, projectId, JBStakingOperations.LOCK)
    returns (uint256 tokenId)
  {
    if (_useJbToken) {
      // If a token wasn't set when this contract was deployed but is set now, set it.
      if (token == address(0) && tokenStore.tokenOf(projectId) != IJBToken(address(0))) {
        token = address(tokenStore.tokenOf(projectId));
        // The project's token must not have changed since this token was originally set.
      } else if (address(tokenStore.tokenOf(projectId)) != token) revert TOKEN_MISMATCH();
    }

    // Duration must match.
    if (!_isLockDurationAcceptable(_duration)) revert JBErrors.INVALID_LOCK_DURATION();

    // Increment the number of ve positions that have been minted.
    // Has to start at 1, since 0 is the id for non-token global checkpoints
    tokenId = ++count;

    // Calculate the time when this lock will end (in seconds).
    uint256 _lockedUntil = block.timestamp + _duration;
    _newLock(
      tokenId,
      LockedBalance(
        int128(int256(_amount)),
        block.timestamp + _duration,
        _duration,
        _useJbToken,
        _allowPublicExtension
      )
    );

    // Mint the position for the beneficiary.
    _safeMint(_beneficiary, tokenId);

    // Enable the voting power if the user is minting for themselves
    // otherwise the `_beneficiary` has to enable it manually afterwards
    // TODO: make optional to allow the user to save some gas?
    if (msg.sender == _beneficiary) {
      _activateVotingPower(tokenId, _beneficiary, true, true);
    }

    if (_useJbToken)
      // Transfer the token to this contract where they'll be locked.
      // Will revert if not enough allowance.
      IJBToken(token).transferFrom(projectId, msg.sender, address(this), _amount);
      // Transfer the token to this contract where they'll be locked.
      // Will revert if this contract isn't an opperator.
    else tokenStore.transferFrom(msg.sender, projectId, address(this), _amount);

    // Emit event.
    emit Lock(tokenId, _account, _amount, _duration, _beneficiary, _lockedUntil, msg.sender);
  }

  /**
    @notice
    Allows banny holders to burn their banny and get back the locked in amount.

    @dev
    Only an account or a designated operator can unlock its tokens.

    @param _unlockData An array of banny tokens to be burnt in exchange of the locked tokens.
  */
  function unlock(JBUnlockData[] calldata _unlockData) external override nonReentrant {
    for (uint256 _i; _i < _unlockData.length; _i++) {
      // Verify that the sender has permission to unlock this tokenId
      _requirePermission(ownerOf(_unlockData[_i].tokenId), projectId, JBStakingOperations.UNLOCK);

      // Get the specs for the token ID.
      LockedBalance memory _lock = locked[_unlockData[_i].tokenId];
      uint256 _amount = uint128(_lock.amount);

      // The lock must have expired.
      if (block.timestamp <= _lock.end) revert LOCK_PERIOD_NOT_OVER();

      // Burn the token.
      _burn(_unlockData[_i].tokenId);

      if (_lock.useJbToken)
        // Transfer the amount of locked tokens to beneficiary.
        IJBToken(token).transfer(projectId, _unlockData[_i].beneficiary, _amount);
        // Transfer the tokens from this contract.
      else tokenStore.transferFrom(_unlockData[_i].beneficiary, projectId, address(this), _amount);

      // Emit event.
      emit Unlock(_unlockData[_i].tokenId, _unlockData[_i].beneficiary, _amount, msg.sender);
    }
  }

  /**
    @notice
    Allows banny holders to extend their token lock-in durations.

    @dev
    If the position being extended isn't set to allow public extension, only an operator account or a designated operator can extend the lock of its tokens.

    @param _lockExtensionData An array of locks to extend.

    @return newTokenIds An array of the new token ids (in the same order as _lockExtensionData)
  */
  function extendLock(JBLockExtensionData[] calldata _lockExtensionData)
    external
    override
    nonReentrant
    returns (uint256[] memory newTokenIds)
  {
    newTokenIds = new uint256[](_lockExtensionData.length);

    for (uint256 _i; _i < _lockExtensionData.length; _i++) {
      // Get a reference to the extension being iterated.
      JBLockExtensionData memory _data = _lockExtensionData[_i];

      // Duration must match.
      if (!_isLockDurationAcceptable(_data.updatedDuration))
        revert JBErrors.INVALID_LOCK_DURATION();

      // Get the current owner
      address _ownerOf = ownerOf(_data.tokenId);

      // Get the specs for the token ID.
      LockedBalance memory _lock = locked[_data.tokenId];

      if (!_lock.allowPublicExtension)
        // If the operation isn't allowed publicly, check if the msg.sender is either the position owner or is an operator.
        _requirePermission(_ownerOf, projectId, JBStakingOperations.EXTEND_LOCK);

      // Calculate the new unlock date
      uint256 _newEndDate = (block.timestamp + _data.updatedDuration);
      if (_newEndDate < _lock.end) revert INVALID_LOCK_EXTENSION();

      // TODO: Add back in the changing tokenId, temporarily removed to improve gas usage
      _extendLock(_data.tokenId, _data.updatedDuration, _newEndDate);
      newTokenIds[_i] = _data.tokenId;

      emit ExtendLock(_data.tokenId, _data.tokenId, _data.updatedDuration, _newEndDate, msg.sender);
    }
  }

  /**
    @notice
    Allows banny holders to set whether or not anyone in the public can extend their locked position.

    @dev
    Only an owner account or a designated operator can extend the lock of its tokens.

    @param _allowPublicExtensionData An array of locks to extend.
  */
  function setAllowPublicExtension(JBAllowPublicExtensionData[] calldata _allowPublicExtensionData)
    external
    override
    nonReentrant
  {
    for (uint256 _i; _i < _allowPublicExtensionData.length; _i++) {
      // Get a reference to the extension being iterated.
      JBAllowPublicExtensionData memory _data = _allowPublicExtensionData[_i];

      if (!_data.allowPublicExtension) {
        revert INVALID_PUBLIC_EXTENSION_FLAG_VALUE();
      }

      // Check if the msg.sender is either the position owner or is an operator.
      _requirePermission(
        ownerOf(_data.tokenId),
        projectId,
        JBStakingOperations.SET_PUBLIC_EXTENSION_FLAG
      );

      // Update the allowPublicExtension (checkpoint is not needed)
      locked[_data.tokenId].allowPublicExtension = _data.allowPublicExtension;

      emit SetAllowPublicExtension(_data.tokenId, _data.allowPublicExtension, msg.sender);
    }
  }

  /**
    @notice
    Unlock the position and redeem the locked tokens.

    @dev
    Only an account or a designated operator can unlock its tokens.

    @param _redeemData An array of NFTs to redeem.
  */
  function redeem(JBRedeemData[] calldata _redeemData) external override nonReentrant {
    for (uint256 _i; _i < _redeemData.length; _i++) {
      // Get a reference to the redeemItem being iterated.
      JBRedeemData memory _data = _redeemData[_i];
      // Get a reference to the owner of the position.
      address _owner = ownerOf(_data.tokenId);
      // Check if the msg.sender is either the position owner or is an operator.
      _requirePermission(_owner, projectId, JBStakingOperations.REDEEM);

      // Get the specs for the token ID.
      LockedBalance memory _lock = locked[_data.tokenId];

      // The lock must have expired.
      if (block.timestamp <= _lock.end) revert LOCK_PERIOD_NOT_OVER();

      // Burn the token.
      _burn(_data.tokenId);

      // Redeem the locked tokens to reclaim treasury funds.
      uint256 _reclaimedAmount = _data.terminal.redeemTokensOf(
        address(this),
        projectId,
        uint256(uint128(_lock.amount)),
        _data.token,
        _data.minReturnedTokens,
        _data.beneficiary,
        _data.memo,
        _data.metadata
      );

      // Emit event.
      emit Redeem(
        _data.tokenId,
        _owner,
        _data.beneficiary,
        uint256(uint128(_lock.amount)),
        _reclaimedAmount,
        _data.memo,
        msg.sender
      );
    }
  }

  /**
     @notice 
     Allows the owner to set the uri resolver.

     @param _resolver The new URI resolver.
  */
  function setUriResolver(IJBVeTokenUriResolver _resolver) external override onlyOwner {
    uriResolver = _resolver;
    emit SetUriResolver(_resolver, msg.sender);
  }

  //*********************************************************************//
  // --------------------- private helper functions -------------------- //
  //*********************************************************************//

  /**
    @notice
    Returns a flag indicating if the provided duration is one of the lock duration options.

    @param _duration The duration to evaluate.

    @return A flag.
  */
  function _isLockDurationAcceptable(uint256 _duration) private view returns (bool) {
    for (uint256 _i; _i < _lockDurationOptions.length; _i++)
      if (_lockDurationOptions[_i] == _duration) return true;
    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBProjects.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBTokenStore.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBOperatorStore.sol';
import './IJBVeTokenUriResolver.sol';
import './IJBVeNft.sol';

interface IJBVeNftDeployer {
  event DeployVeNft(
    uint256 indexed projectId,
    string name,
    string symbol,
    IJBVeTokenUriResolver uriResolver,
    IJBTokenStore tokenStore,
    IJBOperatorStore operatorStore,
    uint256[] lockDurationOptions,
    address owner,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function deployVeNFT(
    uint256 _projectId,
    string memory _name,
    string memory _symbol,
    IJBVeTokenUriResolver _uriResolver,
    IJBTokenStore _tokenStore,
    IJBOperatorStore _operatorStore,
    uint256[] memory _lockDurationOptions,
    address _owner
  ) external returns (IJBVeNft veNft);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBOperatable.sol';

/** 
  @notice
  Modifiers to allow access to functions based on the message sender's operator status.

  @dev
  Adheres to -
  IJBOperatable: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
*/
abstract contract JBOperatable is IJBOperatable {
  //*********************************************************************//
  // --------------------------- custom errors -------------------------- //
  //*********************************************************************//
  error UNAUTHORIZED();

  //*********************************************************************//
  // ---------------------------- modifiers ---------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Only allows the speficied account or an operator of the account to proceed. 

    @param _account The account to check for.
    @param _domain The domain namespace to look for an operator within. 
    @param _permissionIndex The index of the permission to check for. 
  */
  modifier requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) {
    _requirePermission(_account, _domain, _permissionIndex);
    _;
  }

  /** 
    @notice
    Only allows the speficied account, an operator of the account to proceed, or a truthy override flag. 

    @param _account The account to check for.
    @param _domain The domain namespace to look for an operator within. 
    @param _permissionIndex The index of the permission to check for. 
    @param _override A condition to force allowance for.
  */
  modifier requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) {
    _requirePermissionAllowingOverride(_account, _domain, _permissionIndex, _override);
    _;
  }

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /** 
    @notice 
    A contract storing operator assignments.
  */
  IJBOperatorStore public immutable override operatorStore;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _operatorStore A contract storing operator assignments.
  */
  constructor(IJBOperatorStore _operatorStore) {
    operatorStore = _operatorStore;
  }

  //*********************************************************************//
  // -------------------------- internal views ------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Require the message sender is either the account or has the specified permission.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _permissionIndex The permission index that an operator must have within the specified domain to be allowed.
  */
  function _requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) internal view {
    if (
      msg.sender != _account &&
      !operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) &&
      !operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex)
    ) revert UNAUTHORIZED();
  }

  /** 
    @notice
    Require the message sender is either the account, has the specified permission, or the override condition is true.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _domain The permission index that an operator must have within the specified domain to be allowed.
    @param _override The override condition to allow.
  */
  function _requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) internal view {
    if (
      !_override &&
      msg.sender != _account &&
      !operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) &&
      !operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex)
    ) revert UNAUTHORIZED();
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Solidity and NFT version of Curve Finance - VotingEscrow
// (https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy)
pragma solidity 0.8.6;

// Converted into solidity by:
// Primary Author(s)
//  Travis Moore: https://github.com/FortisFortuna
// Reviewer(s) / Contributor(s)
//  Jason Huan: https://github.com/jasonhuan
//  Sam Kazemian: https://github.com/samkazemian
//  Frax Finance - https://github.com/FraxFinance
// Original idea and credit:
//  Curve Finance's veCRV
//  https://resources.curve.fi/faq/vote-locking-boost
//  https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy
//  This is a Solidity version converted from Vyper by the Frax team
//  Almost all of the logic / algorithms are the Curve team's

//@notice Votes have a weight depending on time, so that users are
//        committed to the future of (whatever they are voting for)
//@dev Vote weight decays linearly over time. Lock time cannot be
//     more than `MAXTIME` (3 years).

// Voting escrow to have time-weighted votes
// Votes have a weight depending on time, so that users are committed
// to the future of (whatever they are voting for).
// The weight in this implementation is linear, and lock cannot be more than maxtime:
// w ^
// 1 +        /
//   |      /
//   |    /
//   |  /
//   |/
// 0 +--------+------> time
//       maxtime (3 years?)

import '@openzeppelin/contracts/governance/utils/IVotes.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

abstract contract veERC721 is ERC721Enumerable, IVotes {
  /* ========== CUSTOM ERRORS ========== */
  error DELEGATION_NOT_SUPPORTED();
  error INVALID_BLOCK();
  error NOT_OWNER();
  error LOCK_DURATION_NOT_OVER();
  error VOTING_POWER_ALREADY_ENABLED();

  /* ========== STATE VARIABLES ========== */
  /** 
    @notice 
    jbx token address
  */
  address public token;
  // The owners of a specific tokenId ordered by Time (old to new)
  mapping(uint256 => HistoricVotingPower[]) internal _historicVotingPower;
  // All the tokens an address has received voting power from at some point in time
  mapping(address => uint256[]) internal _receivedVotingPower;

  uint256 public epoch;
  mapping(uint256 => LockedBalance) public locked;
  Point[100000000000000000000000000000] public pointHistory; // epoch -> unsigned point
  mapping(uint256 => Point[1000000000]) public tokenPointHistory;
  mapping(uint256 => uint256) public tokenPointEpoch;
  mapping(uint256 => int128) public slopeChanges; // time -> signed slope change

  uint256 public constant WEEK = 7 * 86400; // all future times are rounded by week
  int128 public constant MAXTIME = 3 * 365 * 86400; // 3 years
  uint256 public constant MULTIPLIER = 10**18;

  // We cannot really do block numbers per se b/c slope is per time, not per block
  // and per block could be fairly bad b/c Ethereum changes blocktimes.
  // What we can do is to extrapolate ***At functions
  struct Point {
    int128 bias;
    int128 slope; // dweight / dt
    uint256 ts;
    uint256 blk; // block
  }

  struct LockedBalance {
    int128 amount;
    uint256 end;
    uint256 duration;
    bool useJbToken;
    bool allowPublicExtension;
  }

  struct HistoricVotingPower {
    uint256 receivedAtBlock;
    address account;
  }

  /* ========== CONSTRUCTOR ========== */
  /**
   * @notice Contract constructor
   * @param _name Nft name.
   * @param _symbol Nft symbol.
   */
  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    pointHistory[0].blk = block.number;
    pointHistory[0].ts = block.timestamp;
  }

  /* ========== VIEWS ========== */

  /**
    @notice Calculate the current voting power of an address
    @param _account account to calculate
  */
  function getVotes(address _account) public view override returns (uint256 votingPower) {
    return getPastVotes(_account, block.number);
  }

  /**
    @notice Calculate the voting power of an address at a specific block
    @param _account account to calculate
    @param _block Block to calculate the voting power at
  */
  function getPastVotes(address _account, uint256 _block)
    public
    view
    virtual
    override
    returns (uint256 votingPower)
  {
    for (uint256 _i; _i < _receivedVotingPower[_account].length; _i++) {
      uint256 _tokenId = _receivedVotingPower[_account][_i];
      uint256 _count = _historicVotingPower[_tokenId].length;

      // Should never happen, but just in case
      if (_count == 0) {
        continue;
      }

      // Use binary search to find the element
      uint256 _min = 0;
      uint256 _max = _count - 1;
      for (uint256 i = 0; i < 128; i++) {
        if (_min >= _max) {
          break;
        }
        uint256 _mid = (_min + _max + 1) / 2;
        if (_historicVotingPower[_tokenId][_mid].receivedAtBlock <= _block) {
          _min = _mid;
        } else {
          _max = _mid - 1;
        }
      }

      // Check if `_account` owned the token at `_block`, if so calculate the voting power
      HistoricVotingPower storage _voting_power = _historicVotingPower[_tokenId][_min];
      if (_voting_power.receivedAtBlock <= _block && _voting_power.account == _account) {
        votingPower += tokenVotingPowerAt(_tokenId, _block);
      }
    }
  }

  /**
   * @notice Measure voting power of `addr` at block height `_block`
   * @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
   * @param _tokenId The token ID
   * @param _block Block to calculate the voting power at
   * @return Voting power
   */
  function tokenVotingPowerAt(uint256 _tokenId, uint256 _block) public view returns (uint256) {
    // Copying and pasting totalSupply code because Vyper cannot pass by
    // reference yet
    if (_block > block.number) {
      revert INVALID_BLOCK();
    }

    // Binary search
    uint256 _min = 0;
    uint256 _max = tokenPointEpoch[_tokenId];

    // Will be always enough for 128-bit numbers
    for (uint256 i = 0; i < 128; i++) {
      if (_min >= _max) {
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      if (tokenPointHistory[_tokenId][_mid].blk <= _block) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }

    Point memory upoint = tokenPointHistory[_tokenId][_min];

    uint256 max_epoch = epoch;
    uint256 _epoch = _findBlockEpoch(_block, max_epoch);
    Point memory point_0 = pointHistory[_epoch];
    uint256 d_block = 0;
    uint256 d_t = 0;

    if (_epoch < max_epoch) {
      Point memory point_1 = pointHistory[_epoch + 1];
      d_block = point_1.blk - point_0.blk;
      d_t = point_1.ts - point_0.ts;
    } else {
      d_block = block.number - point_0.blk;
      d_t = block.timestamp - point_0.ts;
    }

    uint256 block_time = point_0.ts;
    if (d_block != 0) {
      block_time += (d_t * (_block - point_0.blk)) / d_block;
    }

    upoint.bias -= upoint.slope * (int128(int256(block_time)) - int128(int256(upoint.ts)));
    if (upoint.bias >= 0) {
      return uint256(uint128(upoint.bias));
    } else {
      return 0;
    }
  }

  /**
    @notice Calculate total voting power at some point in the past
    @param _block Block to calculate the total voting power at
    @return Total voting power at `_block`
  */
  function getPastTotalSupply(uint256 _block) external view override returns (uint256) {
    if (_block > block.number) {
      revert INVALID_BLOCK();
    }
    uint256 _epoch = epoch;
    uint256 target_epoch = _findBlockEpoch(_block, _epoch);

    Point memory point = pointHistory[target_epoch];
    uint256 dt = 0;

    if (target_epoch < _epoch) {
      Point memory point_next = pointHistory[target_epoch + 1];
      if (point.blk != point_next.blk) {
        dt = ((_block - point.blk) * (point_next.ts - point.ts)) / (point_next.blk - point.blk);
      }
    } else {
      if (point.blk != block.number) {
        dt = ((_block - point.blk) * (block.timestamp - point.ts)) / (block.number - point.blk);
      }
    }

    // Now dt contains info on how far are we beyond point
    return _supplyAt(point, point.ts + dt);
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
    @dev Requires override. Calls super.
  */
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override {
    // Make sure this is not a mint
    if (_from != address(0)) {
      // This is a transfer, disable voting power (if active)
      uint256 _historyLength = _historicVotingPower[_tokenId].length;
      if (_historyLength > 0) {
        // Get the latest assignment of the voting power
        HistoricVotingPower memory _latestVotingPower = _historicVotingPower[_tokenId][
          _historyLength - 1
        ];
        // Check if the voting power is already disabled, otherwise disable it now
        if (_latestVotingPower.account != address(0)) {
          _historicVotingPower[_tokenId].push(HistoricVotingPower(block.number, address(0)));
        }
      }
    }

    // Register/unregister in ERC721Enumerable
    return super._beforeTokenTransfer(_from, _to, _tokenId);
  }

  /**
   * @notice Record global and per-token data to checkpoint
   * @param _tokenId The token ID. No token checkpoint if 0
   * @param old_locked Previous locked amount / end lock time for the user
   * @param new_locked New locked amount / end lock time for the user
   */
  function _checkpoint(
    uint256 _tokenId,
    LockedBalance memory old_locked,
    LockedBalance memory new_locked
  ) internal {
    Point memory u_old = _newEmptyPoint();
    Point memory u_new = _newEmptyPoint();
    int128 old_dslope = 0;
    int128 new_dslope = 0;
    uint256 _epoch = epoch;

    if (_tokenId != 0) {
      // Calculate slopes and biases
      // Kept at zero when they have to
      if ((old_locked.end > block.timestamp) && (old_locked.amount > 0)) {
        u_old.slope = old_locked.amount / MAXTIME;
        u_old.bias =
          u_old.slope *
          (int128(int256(old_locked.end)) - int128(int256(block.timestamp)));
      }

      if ((new_locked.end > block.timestamp) && (new_locked.amount > 0)) {
        u_new.slope = new_locked.amount / MAXTIME;
        u_new.bias =
          u_new.slope *
          (int128(int256(new_locked.end)) - int128(int256(block.timestamp)));
      }

      // Read values of scheduled changes in the slope
      // old_locked.end can be in the past and in the future
      // new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
      old_dslope = slopeChanges[old_locked.end];
      if (new_locked.end != 0) {
        if (new_locked.end == old_locked.end) {
          new_dslope = old_dslope;
        } else {
          new_dslope = slopeChanges[new_locked.end];
        }
      }
    }

    Point memory last_point = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
    if (_epoch > 0) {
      last_point = pointHistory[_epoch];
    }
    uint256 last_checkpoint = last_point.ts;

    // initial_last_point is used for extrapolation to calculate block number
    // (approximately, for *At methods) and save them
    // as we cannot figure that out exactly from inside the contract
    Point memory initial_last_point = last_point;
    uint256 block_slope = 0; // dblock/dt
    if (block.timestamp > last_point.ts) {
      block_slope =
        (MULTIPLIER * (block.number - last_point.blk)) /
        (block.timestamp - last_point.ts);
    }

    // If last point is already recorded in this block, slope=0
    // But that's ok b/c we know the block in such case

    // Go over weeks to fill history and calculate what the current point is
    uint256 t_i = (last_checkpoint / WEEK) * WEEK;
    for (uint256 i = 0; i < 255; i++) {
      // Hopefully it won't happen that this won't get used in 4 years!
      // If it does, users will be able to withdraw but vote weight will be broken
      t_i += WEEK;
      int128 d_slope = 0;
      if (t_i > block.timestamp) {
        t_i = block.timestamp;
      } else {
        d_slope = slopeChanges[t_i];
      }
      last_point.bias -= last_point.slope * (int128(int256(t_i)) - int128(int256(last_checkpoint)));
      last_point.slope += d_slope;
      if (last_point.bias < 0) {
        last_point.bias = 0; // This can happen
      }
      if (last_point.slope < 0) {
        last_point.slope = 0; // This cannot happen - just in case
      }
      last_checkpoint = t_i;
      last_point.ts = t_i;
      last_point.blk =
        initial_last_point.blk +
        (block_slope * (t_i - initial_last_point.ts)) /
        MULTIPLIER;
      _epoch += 1;
      if (t_i == block.timestamp) {
        last_point.blk = block.number;
        break;
      } else {
        pointHistory[_epoch] = last_point;
      }
    }

    epoch = _epoch;
    // Now pointHistory is filled until t=now

    if (_tokenId != 0) {
      // If last point was in this block, the slope change has been applied already
      // But in such case we have 0 slope(s)
      last_point.slope += (u_new.slope - u_old.slope);
      last_point.bias += (u_new.bias - u_old.bias);
      if (last_point.slope < 0) {
        last_point.slope = 0;
      }
      if (last_point.bias < 0) {
        last_point.bias = 0;
      }
    }

    // Record the changed point into history
    pointHistory[_epoch] = last_point;

    if (_tokenId != 0) {
      // Schedule the slope changes (slope is going down)
      // We subtract new_user_slope from [new_locked.end]
      // and add old_user_slope to [old_locked.end]
      if (old_locked.end > block.timestamp) {
        // old_dslope was <something> - u_old.slope, so we cancel that
        old_dslope += u_old.slope;
        if (new_locked.end == old_locked.end) {
          old_dslope -= u_new.slope; // It was a new deposit, not extension
        }
        slopeChanges[old_locked.end] = old_dslope;
      }

      if (new_locked.end > block.timestamp) {
        if (new_locked.end > old_locked.end) {
          new_dslope -= u_new.slope; // old slope disappeared at this point
          slopeChanges[new_locked.end] = new_dslope;
        }
        // else: we recorded it already in old_dslope
      }

      // Now handle user history
      // Second function needed for 'stack too deep' issues
      _checkpointPartTwo(_tokenId, u_new.bias, u_new.slope);
    }
  }

  /**
   * @notice Needed for 'stack too deep' issues in _checkpoint()
   * @param _tokenId User's wallet address. No token checkpoint if 0
   * @param _bias from unew
   * @param _slope from unew
   */
  function _checkpointPartTwo(
    uint256 _tokenId,
    int128 _bias,
    int128 _slope
  ) internal {
    uint256 token_epoch = tokenPointEpoch[_tokenId] + 1;

    tokenPointEpoch[_tokenId] = token_epoch;
    tokenPointHistory[_tokenId][token_epoch] = Point({
      bias: _bias,
      slope: _slope,
      ts: block.timestamp,
      blk: block.number
    });
  }

  /**
    @notice extends an existing lock
    @param _tokenId The tokenID to lock for
    @param _duration the duration of the lock (for the UI and uriresolver, not actually used)
    @param _end the new end time
  */
  function _extendLock(
    uint256 _tokenId,
    uint256 _duration,
    uint256 _end
  ) internal {
    // Round end date down to week
    _end = (_end / WEEK) * WEEK;
    // Get the current lock info
    LockedBalance memory _currentLock = locked[_tokenId];
    // Make sure the end date does not become earlier than the current one
    if (_end <= _currentLock.end) {
      revert LOCK_DURATION_NOT_OVER();
    }
    // Update the duration for the UI and uriresolver
    _currentLock.duration = _duration;
    // Checkpoint the lock and calculate new slope and bias
    _modifyLock(_tokenId, 0, _end, _currentLock);
  }

  /**
    @notice modifies an existing lock
    @dev modified implementation of `_deposit_for` that does not perform the token transfer
    @param _tokenId The tokenID to lock for
    @param _value Amount to deposit
    @param unlock_time New time when to unlock the tokens, or 0 if unchanged
    @param locked_balance Previous locked amount / timestamp
  */
  function _modifyLock(
    uint256 _tokenId,
    uint256 _value,
    uint256 unlock_time,
    LockedBalance memory locked_balance
  ) private {
    LockedBalance memory _locked = locked_balance;
    LockedBalance memory old_locked = _locked;
    // Adding to existing lock, or if a lock is expired - creating a new one
    _locked.amount += int128(int256(_value));
    if (unlock_time != 0) {
      _locked.end = unlock_time;
    }
    locked[_tokenId] = _locked;

    // Possibilities:
    // Both old_locked.end could be current or expired (>/< block.timestamp)
    // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
    // _locked.end > block.timestamp (always)
    _checkpoint(_tokenId, old_locked, _locked);
  }

  // Constant structs not allowed yet, so this will have to do
  function _newEmptyPoint() internal pure returns (Point memory) {
    return Point({bias: 0, slope: 0, ts: 0, blk: 0});
  }

  // Constant structs not allowed yet, so this will have to do
  function _newEmptyLockedBalance() internal pure returns (LockedBalance memory) {
    return
      LockedBalance({
        amount: 0,
        end: 0,
        duration: 0,
        useJbToken: false,
        allowPublicExtension: false
      });
  }

  function _newLock(uint256 _tokenId, LockedBalance memory _lock) internal {
    // round end date to nearest week
    _lock.end = (_lock.end / WEEK) * WEEK;

    // Should be a zeroed struct,
    // but if it (somehow) exists checkpoint will update the lock
    LockedBalance memory _old_lock = locked[_tokenId];
    locked[_tokenId] = _lock;

    _checkpoint(_tokenId, _old_lock, _lock);
  }

  /**
    @dev burns the token and checkpoints the changes in locked balances
   */
  function _burn(uint256 _tokenId) internal virtual override {
    LockedBalance memory _locked = locked[_tokenId];
    LockedBalance memory old_locked = _locked;
    _locked.end = 0;
    _locked.amount = 0;
    locked[_tokenId] = _locked;

    // old_locked can have either expired <= timestamp or zero end
    // _locked has only 0 end
    // Both can have >= 0 amount
    _checkpoint(_tokenId, old_locked, _locked);

    super._burn(_tokenId);
  }

  // The following ERC20/minime-compatible methods are not real balanceOf and supply!
  // They measure the weights for the purpose of voting, so they don't represent
  // real coins.
  /**
   * @notice Binary search to estimate timestamp for block number
   * @param _block Block to find
   * @param max_epoch Don't go beyond this epoch
   * @return Approximate timestamp for block
   */
  function _findBlockEpoch(uint256 _block, uint256 max_epoch) internal view returns (uint256) {
    // Binary search
    uint256 _min = 0;
    uint256 _max = max_epoch;

    // Will be always enough for 128-bit numbers
    for (uint256 i = 0; i < 128; i++) {
      if (_min >= _max) {
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      if (pointHistory[_mid].blk <= _block) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }

    return _min;
  }

  /**
   * @notice Calculate total voting power at some point in the past
   * @param point The point (bias/slope) to start search from
   * @param t Time to calculate the total voting power at
   * @return Total voting power at that time
   */
  function _supplyAt(Point memory point, uint256 t) internal view returns (uint256) {
    Point memory last_point = point;
    uint256 t_i = (last_point.ts / WEEK) * WEEK;

    for (uint256 i = 0; i < 255; i++) {
      t_i += WEEK;
      int128 d_slope = 0;
      if (t_i > t) {
        t_i = t;
      } else {
        d_slope = slopeChanges[t_i];
      }
      last_point.bias -= last_point.slope * (int128(int256(t_i)) - int128(int256(last_point.ts)));
      if (t_i == t) {
        break;
      }
      last_point.slope += d_slope;
      last_point.ts = t_i;
    }

    if (last_point.bias < 0) {
      last_point.bias = 0;
    }
    return uint256(uint128(last_point.bias));
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Activates the voting power of a token
   * @dev Voting power gets disabled when a token is transferred, this prevents a gas DOS attack
   * @param _tokenId The token to activate
   */
  function activateVotingPower(uint256 _tokenId) external {
    if (msg.sender != ownerOf(_tokenId)) {
      revert NOT_OWNER();
    }
    _activateVotingPower(_tokenId, msg.sender, false, false);
  }

  function _activateVotingPower(
    uint256 _tokenId,
    address _account,
    bool _forceRegister,
    bool _forceHistoryAddition
  ) internal {
    // We track all the tokens a user has received voting power over at some point
    // To lower gas usage we check if this token has already been owned by the user at some point
    bool _alreadyRegistered;
    if (!_forceRegister) {
      for (uint256 _i; _i < _receivedVotingPower[msg.sender].length; _i++) {
        uint256 _currentTokenId = _receivedVotingPower[_account][_i];
        if (_tokenId == _currentTokenId) {
          _alreadyRegistered = true;
          break;
        }
      }
    }

    // If the token has not been registerd for this user, register it
    if (_forceRegister || !_alreadyRegistered) {
      _receivedVotingPower[_account].push(_tokenId);
    }

    // Prevent multiple activations of the same token in 1 block
    // and the user activating voting power of a token that is already activated for them
    bool _alreadyActivated;
    if (!_forceHistoryAddition) {
      uint256 _historicVotingPowerLength = _historicVotingPower[_tokenId].length;
      if (_historicVotingPowerLength > 0) {
        // Get the latest change in voting power assignment for this token
        HistoricVotingPower memory _latestVotingPower = _historicVotingPower[_tokenId][
          _historicVotingPowerLength - 1
        ];
        // Prevents multiple activations of the same token in 1 block
        if (_latestVotingPower.receivedAtBlock >= block.number) {
          revert VOTING_POWER_ALREADY_ENABLED();
        }
        // Check if the current activated user is the
        if (_latestVotingPower.account != _account) {
          _alreadyActivated = true;
        }
      }
    }

    if (_forceHistoryAddition || !_alreadyActivated) {
      // Activate the voting power
      _historicVotingPower[_tokenId].push(HistoricVotingPower(block.number, _account));
    }
  }

  /**
   * @notice Record global data to checkpoint
   */
  function checkpoint() external {
    _checkpoint(0, _newEmptyLockedBalance(), _newEmptyLockedBalance());
  }

  /**
   * @dev Not supported by this contract, required for interface
   */
  function delegates(address) external pure override returns (address) {
    revert DELEGATION_NOT_SUPPORTED();
  }

  /**
   * @dev Not supported by this contract, required for interface
   */
  function delegate(address) external pure override {
    revert DELEGATION_NOT_SUPPORTED();
  }

  /**
   * @dev Not supported by this contract, required for interface
   */
  function delegateBySig(
    address,
    uint256,
    uint256,
    uint8,
    bytes32,
    bytes32
  ) external pure override {
    revert DELEGATION_NOT_SUPPORTED();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBTokenStore.sol';
import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBOperatorStore.sol';
import './IJBVeTokenUriResolver.sol';
import './../structs/JBAllowPublicExtensionData.sol';
import './../structs/JBLockExtensionData.sol';
import './../structs/JBRedeemData.sol';
import './../structs/JBUnlockData.sol';

interface IJBVeNft {
  function projectId() external view returns (uint256);

  function tokenStore() external view returns (IJBTokenStore);

  function count() external view returns (uint256);

  function lockDurationOptions() external view returns (uint256[] memory);

  function contractURI() external view returns (string memory);

  function uriResolver() external view returns (IJBVeTokenUriResolver);

  function getSpecs(uint256 _tokenId)
    external
    view
    returns (
      uint256 amount,
      uint256 duration,
      uint256 lockedUntil,
      bool useJbToken,
      bool allowPublicExtension
    );

  function lock(
    address _account,
    uint256 _amount,
    uint256 _duration,
    address _beneficiary,
    bool _useJbToken,
    bool _allowPublicExtension
  ) external returns (uint256 tokenId);

  function unlock(JBUnlockData[] calldata _unlockData) external;

  function extendLock(JBLockExtensionData[] calldata _lockExtensionData)
    external
    returns (uint256[] memory newTokenIds);

  function setAllowPublicExtension(JBAllowPublicExtensionData[] calldata _allowPublicExtensionData)
    external;

  function redeem(JBRedeemData[] calldata _redeemData) external;

  function setUriResolver(IJBVeTokenUriResolver _resolver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBVeTokenUriResolver {
  /**
    @notice
    provides the metadata for the storefront
  */
  function contractURI() external view returns (string memory);

  /**
    @notice 
    Computes the metadata url.
    @param _tokenId TokenId of the Banny
    @param _amount Lock Amount.
    @param _duration Lock time in seconds.
    @param _lockedUntil Total lock-in period.
    @param _lockDurationOptions The options that the duration can be.

    @return The metadata url.
  */
  function tokenURI(
    uint256 _tokenId,
    uint256 _amount,
    uint256 _duration,
    uint256 _lockedUntil,
    uint256[] memory _lockDurationOptions
  ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBStakingOperations {
  uint256 public constant DEPLOY_VE_NFT = 20;
  uint256 public constant LOCK = 21;
  uint256 public constant UNLOCK = 22;
  uint256 public constant EXTEND_LOCK = 23;
  uint256 public constant REDEEM = 24;
  uint256 public constant SET_PUBLIC_EXTENSION_FLAG = 25;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBErrors {
  // common errors
  error INVALID_LOCK_DURATION();
  error INSUFFICIENT_BALANCE();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBTokenUriResolver.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    JBProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, JBProjectMetadata metadata, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver indexed resolver, address caller);

  function count() external view returns (uint256);

  function metadataContentOf(uint256 _projectId, uint256 _domain)
    external
    view
    returns (string memory);

  function tokenUriResolver() external view returns (IJBTokenUriResolver);

  function createFor(address _owner, JBProjectMetadata calldata _metadata)
    external
    returns (uint256 projectId);

  function setMetadataOf(uint256 _projectId, JBProjectMetadata calldata _metadata) external;

  function setTokenUriResolver(IJBTokenUriResolver _newResolver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBProjects.sol';
import './IJBToken.sol';

interface IJBTokenStore {
  event Issue(
    uint256 indexed projectId,
    IJBToken indexed token,
    string name,
    string symbol,
    address caller
  );

  event Mint(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    bool tokensWereClaimed,
    bool preferClaimedTokens,
    address caller
  );

  event Burn(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    uint256 initialUnclaimedBalance,
    uint256 initialClaimedBalance,
    bool preferClaimedTokens,
    address caller
  );

  event Claim(
    address indexed holder,
    uint256 indexed projectId,
    uint256 initialUnclaimedBalance,
    uint256 amount,
    address caller
  );

  event ShouldRequireClaim(uint256 indexed projectId, bool indexed flag, address caller);

  event Change(
    uint256 indexed projectId,
    IJBToken indexed newToken,
    IJBToken indexed oldToken,
    address owner,
    address caller
  );

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 _projectId) external view returns (IJBToken);

  function projectOf(IJBToken _token) external view returns (uint256);

  function projects() external view returns (IJBProjects);

  function unclaimedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function unclaimedTotalSupplyOf(uint256 _projectId) external view returns (uint256);

  function totalSupplyOf(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _holder, uint256 _projectId) external view returns (uint256 _result);

  function requireClaimFor(uint256 _projectId) external view returns (bool);

  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function changeFor(
    uint256 _projectId,
    IJBToken _token,
    address _newOwner
  ) external returns (IJBToken oldToken);

  function burnFrom(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function mintFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function shouldRequireClaimingFor(uint256 _projectId, bool _flag) external;

  function claimFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;

  function transferFrom(
    address _holder,
    uint256 _projectId,
    address _recipient,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBOperatorData.sol';

interface IJBOperatorStore {
  event SetOperator(
    address indexed operator,
    address indexed account,
    uint256 indexed domain,
    uint256[] permissionIndexes,
    uint256 packed
  );

  function permissionsOf(
    address _operator,
    address _account,
    uint256 _domain
  ) external view returns (uint256);

  function hasPermission(
    address _operator,
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) external view returns (bool);

  function hasPermissions(
    address _operator,
    address _account,
    uint256 _domain,
    uint256[] calldata _permissionIndexes
  ) external view returns (bool);

  function setOperator(JBOperatorData calldata _operatorData) external;

  function setOperators(JBOperatorData[] calldata _operatorData) external;
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
pragma solidity 0.8.6;

import './IJBOperatorStore.sol';

interface IJBOperatable {
  function operatorStore() external view returns (IJBOperatorStore);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0-rc.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/** 
  @member tokenId The ID of the position.
  @member allowPublicExtension A flag indicating whether or not the lock can be extended publicly by anyone.
*/
struct JBAllowPublicExtensionData {
  uint256 tokenId;
  bool allowPublicExtension;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/** 
  @member tokenId The ID of the position.
  @member updatedDuration The updated duration of the lock.
*/
struct JBLockExtensionData {
  uint256 tokenId;
  uint256 updatedDuration;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol/contracts-v2/contracts/interfaces/IJBPayoutRedemptionPaymentTerminal.sol';

/** 
  @member tokenId Banny Id.
  @member token The token to be reclaimed from the redemption.
  @member minReturnedTokens The minimum amount of terminal tokens expected in return, as a fixed point number with the same amount of decimals as the terminal.
  @member beneficiary The address to send the terminal tokens to.
  @member memo A memo to pass along to the emitted event.
  @member metadata Bytes to send along to the data source and delegate, if provided.
*/
struct JBRedeemData {
  uint256 tokenId;
  address token;
  uint256 minReturnedTokens;
  address payable beneficiary;
  string memo;
  bytes metadata;
  IJBRedemptionTerminal terminal;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/** 
  @member tokenId The ID of the position.
  @member beneficiary Address to transfer the locked amount to.
*/
struct JBUnlockData {
  uint256 tokenId;
  address beneficiary;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBToken {
  function decimals() external view returns (uint8);

  function totalSupply(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _account, uint256 _projectId) external view returns (uint256);

  function mint(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function burn(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function approve(
    uint256,
    address _spender,
    uint256 _amount
  ) external;

  function transfer(
    uint256 _projectId,
    address _to,
    uint256 _amount
  ) external;

  function transferFrom(
    uint256 _projectId,
    address _from,
    address _to,
    uint256 _amount
  ) external;

  function transferOwnership(uint256 _projectId, address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/** 
  @member operator The address of the operator.
  @member domain The domain within which the operator is being given permissions. A domain of 0 is a wildcard domain, which gives an operator access to all domains.
  @member permissionIndexes The indexes of the permissions the operator is being given.
*/
struct JBOperatorData {
  address operator;
  uint256 domain;
  uint256[] permissionIndexes;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0-rc.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0-rc.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './../structs/JBFee.sol';
import './IJBAllowanceTerminal.sol';
import './IJBDirectory.sol';
import './IJBFeeGauge.sol';
import './IJBPayoutTerminal.sol';
import './IJBProjects.sol';
import './IJBPayDelegate.sol';
import './IJBPaymentTerminal.sol';
import './IJBPrices.sol';
import './IJBRedemptionDelegate.sol';
import './IJBRedemptionTerminal.sol';
import './IJBSingleTokenPaymentTerminal.sol';
import './IJBSingleTokenPaymentTerminalStore.sol';
import './IJBSplitsStore.sol';

interface IJBPayoutRedemptionPaymentTerminal is
  IJBPaymentTerminal,
  IJBPayoutTerminal,
  IJBAllowanceTerminal,
  IJBRedemptionTerminal
{
  event AddToBalance(
    uint256 indexed projectId,
    uint256 amount,
    uint256 refundedFees,
    string memo,
    bytes metadata,
    address caller
  );

  event Migrate(
    uint256 indexed projectId,
    IJBPaymentTerminal indexed to,
    uint256 amount,
    address caller
  );

  event DistributePayouts(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 amount,
    uint256 distributedAmount,
    uint256 fee,
    uint256 beneficiaryDistributionAmount,
    string memo,
    address caller
  );

  event UseAllowance(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 amount,
    uint256 distributedAmount,
    uint256 netDistributedamount,
    string memo,
    address caller
  );

  event HoldFee(
    uint256 indexed projectId,
    uint256 indexed amount,
    uint256 indexed fee,
    uint256 feeDiscount,
    address beneficiary,
    address caller
  );

  event ProcessFee(
    uint256 indexed projectId,
    uint256 indexed amount,
    bool indexed wasHeld,
    address beneficiary,
    address caller
  );

  event RefundHeldFees(
    uint256 indexed projectId,
    uint256 indexed amount,
    uint256 indexed refundedFees,
    uint256 leftoverAmount,
    address caller
  );

  event Pay(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address payer,
    address beneficiary,
    uint256 amount,
    uint256 beneficiaryTokenCount,
    string memo,
    bytes metadata,
    address caller
  );

  event DelegateDidPay(IJBPayDelegate indexed delegate, JBDidPayData data, address caller);

  event RedeemTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address holder,
    address beneficiary,
    uint256 tokenCount,
    uint256 reclaimedAmount,
    string memo,
    bytes metadata,
    address caller
  );

  event DelegateDidRedeem(
    IJBRedemptionDelegate indexed delegate,
    JBDidRedeemData data,
    address caller
  );

  event DistributeToPayoutSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 amount,
    address caller
  );

  event SetFee(uint256 fee, address caller);

  event SetFeeGauge(IJBFeeGauge indexed feeGauge, address caller);

  event SetFeelessTerminal(IJBPaymentTerminal indexed terminal, bool indexed flag, address caller);

  function projects() external view returns (IJBProjects);

  function splitsStore() external view returns (IJBSplitsStore);

  function directory() external view returns (IJBDirectory);

  function prices() external view returns (IJBPrices);

  function store() external view returns (IJBSingleTokenPaymentTerminalStore);

  function baseWeightCurrency() external view returns (uint256);

  function payoutSplitsGroup() external view returns (uint256);

  function heldFeesOf(uint256 _projectId) external view returns (JBFee[] memory);

  function fee() external view returns (uint256);

  function feeGauge() external view returns (IJBFeeGauge);

  function isFeelessTerminal(IJBPaymentTerminal _terminal) external view returns (bool);

  function migrate(uint256 _projectId, IJBPaymentTerminal _to) external returns (uint256 balance);

  function processFees(uint256 _projectId) external;

  function setFee(uint256 _fee) external;

  function setFeeGauge(IJBFeeGauge _feeGauge) external;

  function setFeelessTerminal(IJBPaymentTerminal _terminal, bool _flag) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0-rc.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/** 
  @member amount The total amount the fee was taken from, as a fixed point number with the same number of decimals as the terminal in which this struct was created.
  @member fee The percent of the fee, out of MAX_FEE.
  @member feeDiscount The discount of the fee.
  @member beneficiary The address that will receive the tokens that are minted as a result of the fee payment.
*/
struct JBFee {
  uint256 amount;
  uint32 fee;
  uint32 feeDiscount;
  address beneficiary;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBAllowanceTerminal {
  function useAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    address _token,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string calldata _memo
  ) external returns (uint256 netDistributedAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleStore.sol';
import './IJBPaymentTerminal.sol';
import './IJBProjects.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, address indexed controller, address caller);

  event AddTerminal(uint256 indexed projectId, IJBPaymentTerminal indexed terminal, address caller);

  event SetTerminals(uint256 indexed projectId, IJBPaymentTerminal[] terminals, address caller);

  event SetPrimaryTerminal(
    uint256 indexed projectId,
    address indexed token,
    IJBPaymentTerminal indexed terminal,
    address caller
  );

  event SetIsAllowedToSetFirstController(address indexed addr, bool indexed flag, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function controllerOf(uint256 _projectId) external view returns (address);

  function isAllowedToSetFirstController(address _address) external view returns (bool);

  function terminalsOf(uint256 _projectId) external view returns (IJBPaymentTerminal[] memory);

  function isTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal)
    external
    view
    returns (bool);

  function primaryTerminalOf(uint256 _projectId, address _token)
    external
    view
    returns (IJBPaymentTerminal);

  function setControllerOf(uint256 _projectId, address _controller) external;

  function setTerminalsOf(uint256 _projectId, IJBPaymentTerminal[] calldata _terminals) external;

  function setPrimaryTerminalOf(
    uint256 _projectId,
    address _token,
    IJBPaymentTerminal _terminal
  ) external;

  function setIsAllowedToSetFirstController(address _address, bool _flag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBFeeGauge {
  function currentDiscountFor(uint256 _projectId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBPayoutTerminal {
  function distributePayoutsOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    address _token,
    uint256 _minReturnedTokens,
    string calldata _memo
  ) external returns (uint256 netLeftoverDistributionAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBDidPayData.sol';

interface IJBPayDelegate is IERC165 {
  function didPay(JBDidPayData calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IJBPaymentTerminal is IERC165 {
  function acceptsToken(address _token) external view returns (bool);

  function currencyForToken(address _token) external view returns (uint256);

  function decimalsForToken(address _token) external view returns (uint256);

  // Return value must be a fixed point number with 18 decimals.
  function currentEthOverflowOf(uint256 _projectId) external view returns (uint256);

  function pay(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable returns (uint256 beneficiaryTokenCount);

  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBPriceFeed.sol';

interface IJBPrices {
  event AddFeed(uint256 indexed currency, uint256 indexed base, IJBPriceFeed feed);

  function feedFor(uint256 _currency, uint256 _base) external view returns (IJBPriceFeed);

  function priceFor(
    uint256 _currency,
    uint256 _base,
    uint256 _decimals
  ) external view returns (uint256);

  function addFeedFor(
    uint256 _currency,
    uint256 _base,
    IJBPriceFeed _priceFeed
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBDidRedeemData.sol';

interface IJBRedemptionDelegate is IERC165 {
  function didRedeem(JBDidRedeemData calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBRedemptionTerminal {
  function redeemTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _count,
    address _token,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string calldata _memo,
    bytes calldata _metadata
  ) external returns (uint256 reclaimAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBPaymentTerminal.sol';

interface IJBSingleTokenPaymentTerminal is IJBPaymentTerminal {
  function token() external view returns (address);

  function currency() external view returns (uint256);

  function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBFundingCycle.sol';
import './../structs/JBTokenAmount.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBPayDelegate.sol';
import './IJBPrices.sol';
import './IJBRedemptionDelegate.sol';
import './IJBSingleTokenPaymentTerminal.sol';

interface IJBSingleTokenPaymentTerminalStore {
  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function directory() external view returns (IJBDirectory);

  function prices() external view returns (IJBPrices);

  function balanceOf(IJBSingleTokenPaymentTerminal _terminal, uint256 _projectId)
    external
    view
    returns (uint256);

  function usedDistributionLimitOf(
    IJBSingleTokenPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _fundingCycleNumber
  ) external view returns (uint256);

  function usedOverflowAllowanceOf(
    IJBSingleTokenPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _fundingCycleConfiguration
  ) external view returns (uint256);

  function currentOverflowOf(IJBSingleTokenPaymentTerminal _terminal, uint256 _projectId)
    external
    view
    returns (uint256);

  function currentTotalOverflowOf(
    uint256 _projectId,
    uint256 _decimals,
    uint256 _currency
  ) external view returns (uint256);

  function currentReclaimableOverflowOf(
    IJBSingleTokenPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _tokenCount,
    bool _useTotalOverflow
  ) external view returns (uint256);

  function currentReclaimableOverflowOf(
    uint256 _projectId,
    uint256 _tokenCount,
    uint256 _totalSupply,
    uint256 _overflow
  ) external view returns (uint256);

  function recordPaymentFrom(
    address _payer,
    JBTokenAmount memory _amount,
    uint256 _projectId,
    uint256 _baseWeightCurrency,
    string calldata _memo,
    bytes calldata _metadata
  )
    external
    returns (
      JBFundingCycle memory fundingCycle,
      uint256 tokenCount,
      IJBPayDelegate delegate,
      string memory memo
    );

  function recordRedemptionFor(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bytes calldata _metadata
  )
    external
    returns (
      JBFundingCycle memory fundingCycle,
      uint256 reclaimAmount,
      IJBRedemptionDelegate delegate,
      string memory memo
    );

  function recordDistributionFor(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency
  ) external returns (JBFundingCycle memory fundingCycle, uint256 distributedAmount);

  function recordUsedAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency
  ) external returns (JBFundingCycle memory fundingCycle, uint256 withdrawnAmount);

  function recordAddedBalanceFor(uint256 _projectId, uint256 _amount) external;

  function recordMigration(uint256 _projectId) external returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../structs/JBSplit.sol';
import './IJBDirectory.sol';
import './IJBProjects.sol';

interface IJBSplitsStore {
  event SetSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function directory() external view returns (IJBDirectory);

  function splitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group
  ) external view returns (JBSplit[] memory);

  function set(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group,
    JBSplit[] memory _splits
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../enums/JBBallotState.sol';
import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed configuration,
    uint256 indexed projectId,
    JBFundingCycleData data,
    uint256 metadata,
    uint256 mustStartAtOrAfter,
    address caller
  );

  event Init(uint256 indexed configuration, uint256 indexed projectId, uint256 indexed basedOn);

  function latestConfigurationOf(uint256 _projectId) external view returns (uint256);

  function get(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory);

  function latestConfiguredOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBBallotState ballotState);

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _mustStartAtOrAfter
  ) external returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBTokenAmount.sol';

/** 
  @member payer The address from which the payment originated.
  @member projectId The ID of the project for which the payment was made.
  @member amount The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member projectTokenCount The number of project tokens minted for the beneficiary.
  @member beneficiary The address to which the tokens were minted.
  @member memo The memo that is being emitted alongside the payment.
  @member metadata Extra data to send to the delegate.
*/
struct JBDidPayData {
  address payer;
  uint256 projectId;
  JBTokenAmount amount;
  uint256 projectTokenCount;
  address beneficiary;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IJBPriceFeed {
  function currentPrice(uint256 _targetDecimals) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBTokenAmount.sol';

/** 
  @member holder The holder of the tokens being redeemed.
  @member projectId The ID of the project with which the redeemed tokens are associated.
  @member projectTokenCount The number of project tokens being redeemed.
  @member reclaimedAmount The amount reclaimed from the treasury. Includes the token being reclaimed, the value, the number of decimals included, and the currency of the amount.
  @member beneficiary The address to which the reclaimed amount will be sent.
  @member memo The memo that is being emitted alongside the redemption.
  @member metadata Extra data to send to the delegate.
*/
struct JBDidRedeemData {
  address holder;
  uint256 projectId;
  uint256 projectTokenCount;
  JBTokenAmount reclaimedAmount;
  address payable beneficiary;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member number The funding cycle number for the cycle's project. Each funding cycle has a number that is an increment of the cycle that directly preceded it. Each project's first funding cycle has a number of 1.
  @member configuration The timestamp when the parameters for this funding cycle were configured. This value will stay the same for subsequent funding cycles that roll over from an originally configured cycle.
  @member basedOn The `configuration` of the funding cycle that was active when this cycle was created.
  @member start The timestamp marking the moment from which the funding cycle is considered active. It is a unix timestamp measured in seconds.
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
  @member metadata Extra data that can be associated with a funding cycle.
*/
struct JBFundingCycle {
  uint256 number;
  uint256 configuration;
  uint256 basedOn;
  uint256 start;
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/* 
  @member token The token the payment was made in.
  @member value The amount of tokens that was paid, as a fixed point number.
  @member decimals The number of decimals included in the value fixed point number.
  @member currency The expected currency of the value.
**/
struct JBTokenAmount {
  address token;
  uint256 value;
  uint256 decimals;
  uint256 currency;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBSplitAllocator.sol';

/** 
  @member preferClaimed A flag that only has effect if a projectId is also specified, and the project has a token contract attached. If so, this flag indicates if the tokens that result from making a payment to the project should be delivered claimed into the beneficiary's wallet, or unclaimed to save gas.
  @member preferAddToBalance A flag indicating if a distribution to a project should prefer triggering it's addToBalance function instead of its pay function.
  @member percent The percent of the whole group that this split occupies. This number is out of `JBConstants.SPLITS_TOTAL_PERCENT`.
  @member projectId The ID of a project. If an allocator is not set but a projectId is set, funds will be sent to the protocol treasury belonging to the project who's ID is specified. Resulting tokens will be routed to the beneficiary with the claimed token preference respected.
  @member beneficiary An address. The role the of the beneficary depends on whether or not projectId is specified, and whether or not an allocator is specified. If allocator is set, the beneficiary will be forwarded to the allocator for it to use. If allocator is not set but projectId is set, the beneficiary is the address to which the project's tokens will be sent that result from a payment to it. If neither allocator or projectId are set, the beneficiary is where the funds from the split will be sent.
  @member lockedUntil Specifies if the split should be unchangeable until the specified time, with the exception of extending the locked period.
  @member allocator If an allocator is specified, funds will be sent to the allocator contract along with all properties of this split.
*/
struct JBSplit {
  bool preferClaimed;
  bool preferAddToBalance;
  uint256 percent;
  uint256 projectId;
  address payable beneficiary;
  uint256 lockedUntil;
  IJBSplitAllocator allocator;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

enum JBBallotState {
  Active,
  Approved,
  Failed
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
*/
struct JBFundingCycleData {
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../enums/JBBallotState.sol';
import './IJBFundingCycleStore.sol';

interface IJBFundingCycleBallot is IERC165 {
  function duration() external view returns (uint256);

  function stateOf(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _start
  ) external view returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '../structs/JBSplitAllocationData.sol';

interface IJBSplitAllocator is IERC165 {
  function allocate(JBSplitAllocationData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './JBSplit.sol';

/** 
  @member token The token being sent to the split allocator.
  @member amount The amount being sent to the split allocator, as a fixed point number.
  @member decimals The number of decimals in the amount.
  @member projectId The project to which the split belongs.
  @member group The group to which the split belongs.
  @member split The split that caused the allocation.
*/
struct JBSplitAllocationData {
  address token;
  uint256 amount;
  uint256 decimals;
  uint256 projectId;
  uint256 group;
  JBSplit split;
}