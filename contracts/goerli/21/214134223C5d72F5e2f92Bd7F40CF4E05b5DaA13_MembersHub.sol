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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IPublicLockV10.sol";
/**
 * @title MembersHub
 * @dev Broadcast memberships via tags
 * @author Danni Thomx
 */

 // Todo
 // Make adding tag payable and charge small fee
 // Make MembersHub upgradable(Still contemplating)
 // Add withdrawal (if adding tags is now payable)
 // [Contemplating - needs research] Make tags NFTs 

contract MembersHub is Ownable {
    string[] public tags;

    event NewTag(string tag, address indexed creator);
    event BroadcastMembership(address indexed membershipAddress, address creator, string[] relatedTags);
    event RemoveTag(address creator, string tag);

    struct Membership {
        address membershipAddress;
        address creator;
        string[] relatedTags;
    }
    
    uint256 public maxTagsPerMembershp = 5;
    mapping(address => Membership) membershipsData;
    mapping(address => bool) allBroadcasts;
    mapping(address => mapping(string => bool)) public tagsByUser;
    
    constructor() { }

    // /**
    //  * @dev check if tag already exists 
    //  * @param string to check
    //  */
    function doesTagExist( string memory _stringToSearch) public view returns(bool){
       string[] memory arr = tags;
       for(uint256 i =0; i < arr.length; i++){
           if(keccak256(abi.encodePacked(arr[i])) == keccak256(abi.encodePacked(_stringToSearch))){
               return true;
           }
       }
        return false;
    }

    // /**
    //  * @dev add new tag 
    //  * @param string to add
    //  */
    function addTag(string memory _newTag) public returns(string[] memory tag) {
        require(keccak256(abi.encodePacked(_newTag)) != keccak256(abi.encodePacked("")), "Invalid tag");
        require(doesTagExist(_newTag) == false, "tag exists" );
        tags.push(_newTag);
        tagsByUser[msg.sender][_newTag] = true;
        emit NewTag(_newTag, msg.sender);
        return tags;
    }

    // /**
    //  * @dev remove tag 
    //  * @param string to remove
    //  */
    function removeTag(string memory _tag) public {
       uint256 tagToRemoveIndex;
       require(doesTagExist(_tag) == true, "Nonexistent tag" );
       require(tagsByUser[msg.sender][_tag] == true, "Not creator");
       for(uint256 i =0; i < tags.length; i++){
           if(keccak256(abi.encodePacked(tags[i])) == keccak256(abi.encodePacked(_tag))){
               tagToRemoveIndex = i;
               tags[tagToRemoveIndex] = tags[tags.length - 1];
               tags.pop();
               tagsByUser[msg.sender][_tag] = false;
               emit RemoveTag(msg.sender, _tag);
           }
       }
    }

    // /**
    //  * @dev get all tags 
    //  */
    function getTags() public view returns (string[] memory){
        return tags;
    }

    // @dev set membershipData
    function _setMembershipData(address _membershipAddr, string[] memory _relatedTags) private {
        membershipsData[_membershipAddr] = Membership(_membershipAddr, msg.sender, _relatedTags);
    }

    // @dev set max tags per membership
    function setMaxTagsPerMembership(uint256 _maxTags) public onlyOwner {
        require(_maxTags > 0, "Less than 1");
        maxTagsPerMembershp = _maxTags;
    }

    function _isLockManager (IPublicLock _publicLock) private view returns(bool) {
        IPublicLock pubLock = _publicLock;
        bool isManager = pubLock.isLockManager(msg.sender);
        return isManager;
    }

    // /**
    //  * @dev broadcast membership 
    //  * @param list of related tags
    //  * @param membership lock address
    //  */
    function broadcastMembership(
        string[] calldata _relTags,
        IPublicLock _publicLock
    ) external returns (string[] memory) {
        uint256 tagsCount = _relTags.length;
        address _membershipAddress = address(_publicLock);
        require(tagsCount <= maxTagsPerMembershp, "Too many tags"); //check related tags are not more than max tags per membership
        require(_relTags.length >= 1, "Empty tags");// check that related tags is not empty
        require(_isLockManager(_publicLock), "Not Manager");// check that caller is a lock manager
        require(allBroadcasts[_membershipAddress] == false, "Membership exist");// check that membership is not already broadcasted
        for(uint i = 0; i < _relTags.length; i++) {
            require(doesTagExist(_relTags[i]) == true, "Nonexistent Tag");// check that related tags are in the tags array
        }
        Membership memory s; //New membership struct
        s.membershipAddress = _membershipAddress;
        s.creator = msg.sender;
        s.relatedTags = _relTags;
        membershipsData[_membershipAddress] = s;
        allBroadcasts[_membershipAddress] = true;
        emit BroadcastMembership(_membershipAddress, msg.sender, _relTags);
        return _relTags;
    }

    function getBroadcastData(address _membershipAddr)external view returns (Membership memory) {
        Membership memory membership = membershipsData[_membershipAddr];
        return membership;
    }
 
    // function broadcastMembership(
    //     string[] calldata _relTags,
    //     address _membershipAdr
    // ) external returns (string[] memory) {
    //     require(allBroadcasts[_membershipAdr] == false, "Membership exist");
    //     for(uint i = 0; i < _relTags.length; i++) {
    //         require(doesTagExist(_relTags[i]) == true, "Nonexistent Tag");
    //     }
    //     Membership memory s;
    //     s.membershipAddress = _membershipAdr;
    //     s.creator = msg.sender;
    //     s.relatedTags = _relTags;
    //     membershipsData[_membershipAdr] = s;
    //     allBroadcasts[_membershipAdr] = true;
    //     emit BroadcastMembership(_membershipAdr, msg.sender, _relTags);
    //     return _relTags;
    // }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



interface IPublicLock
{

// See indentationissue description here:
// https://github.com/duaraghav8/Ethlint/issues/268
// solium-disable indentation

  /// Functions
  function initialize(
    address _lockCreator,
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string calldata _lockName
  ) external;

  /**
   * @notice Allow the contract to accept tips in ETH sent directly to the contract.
   * @dev This is okay to use even if the lock is priced in ERC-20 tokens
   */
  receive() external payable;

  // roles
  function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);
  function KEY_GRANTER_ROLE() external pure returns (bytes32);
  function LOCK_MANAGER_ROLE() external pure returns (bytes32);

  /**
  * @notice The version number of the current implementation on this network.
  * @return The current version number.
  */
  function publicLockVersion() external pure returns (uint16);

  /**
   * @dev Called by a lock manager or beneficiary to withdraw all funds from the lock and send them to the `beneficiary`.
   * @dev Throws if called by other than a lock manager or beneficiary
   * @param _tokenAddress specifies the token address to withdraw or 0 for ETH. This is usually
   * the same as `tokenAddress` in MixinFunds.
   * @param _amount specifies the max amount to withdraw, which may be reduced when
   * considering the available balance. Set to 0 or MAX_UINT to withdraw everything.
   *  -- however be wary of draining funds as it breaks the `cancelAndRefund` and `expireAndRefundFor`
   * use cases.
   */
  function withdraw(
    address _tokenAddress,
    uint _amount
  ) external;

  /**
   * @notice An ERC-20 style approval, allowing the spender to transfer funds directly from this lock.
   */
  function approveBeneficiary(
    address _spender,
    uint _amount
  ) external
    returns (bool);

  /**
   * A function which lets a Lock manager of the lock to change the price for future purchases.
   * @dev Throws if called by other than a Lock manager
   * @dev Throws if lock has been disabled
   * @dev Throws if _tokenAddress is not a valid token
   * @param _keyPrice The new price to set for keys
   * @param _tokenAddress The address of the erc20 token to use for pricing the keys,
   * or 0 to use ETH
   */
  function updateKeyPricing( uint _keyPrice, address _tokenAddress ) external;

  /**
   * A function to change the default duration of each key in the lock
   * @notice keys previously bought are unaffected by this change (i.e.
   * existing keys timestamps are not recalculated/updated)
   * @param _newExpirationDuration the new amount of time for each key purchased 
   * or type(uint).max for a non-expiring key
   */
  function setExpirationDuration(uint _newExpirationDuration) external;

  /**
   * A function which lets a Lock manager update the beneficiary account,
   * which receives funds on withdrawal.
   * @dev Throws if called by other than a Lock manager or beneficiary
   * @dev Throws if _beneficiary is address(0)
   * @param _beneficiary The new address to set as the beneficiary
   */
  function updateBeneficiary( address _beneficiary ) external;

  /**
   * Checks if the user has a non-expired key.
   * @param _user The address of the key owner
   */
  function getHasValidKey(
    address _user
  ) external view returns (bool);

  /**
  * @dev Returns the key's ExpirationTimestamp field for a given owner.
  * @param _tokenId the id of the key
  * @dev Returns 0 if the owner has never owned a key for this lock
  */
  function keyExpirationTimestampFor(
    uint _tokenId
  ) external view returns (uint timestamp);
  
  /**
   * Public function which returns the total number of unique owners (both expired
   * and valid).  This may be larger than totalSupply.
   */
  function numberOfOwners() external view returns (uint);

  /**
   * Allows a Lock manager to assign a descriptive name for this Lock.
   * @param _lockName The new name for the lock
   * @dev Throws if called by other than a Lock manager
   */
  function updateLockName(
    string calldata _lockName
  ) external;

  /**
   * Allows a Lock manager to assign a Symbol for this Lock.
   * @param _lockSymbol The new Symbol for the lock
   * @dev Throws if called by other than a Lock manager
   */
  function updateLockSymbol(
    string calldata _lockSymbol
  ) external;

  /**
    * @dev Gets the token symbol
    * @return string representing the token symbol
    */
  function symbol()
    external view
    returns(string memory);

    /**
   * Allows a Lock manager to update the baseTokenURI for this Lock.
   * @dev Throws if called by other than a Lock manager
   * @param _baseTokenURI String representing the base of the URI for this lock.
   */
  function setBaseTokenURI(
    string calldata _baseTokenURI
  ) external;

  /**  @notice A distinct Uniform Resource Identifier (URI) for a given asset.
   * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
   *  3986. The URI may point to a JSON file that conforms to the "ERC721
   *  Metadata JSON Schema".
   * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
   * @param _tokenId The tokenID we're inquiring about
   * @return String representing the URI for the requested token
   */
  function tokenURI(
    uint256 _tokenId
  ) external view returns(string memory);

  /**
   * @notice Allows a Lock manager to add or remove an event hook
   */
  function setEventHooks(
    address _onKeyPurchaseHook,
    address _onKeyCancelHook,
    address _onValidKeyHook,
    address _onTokenURIHook
  ) external;

  /**
   * Allows a Lock manager to give a collection of users a key with no charge.
   * Each key may be assigned a different expiration date.
   * @dev Throws if called by other than a Lock manager
   * @param _recipients An array of receiving addresses
   * @param _expirationTimestamps An array of expiration Timestamps for the keys being granted
   */
  function grantKeys(
    address[] calldata _recipients,
    uint[] calldata _expirationTimestamps,
    address[] calldata _keyManagers
  ) external;

  /**
  * @dev Purchase function
  * @param _values array of tokens amount to pay for this purchase >= the current keyPrice - any applicable discount
  * (_values is ignored when using ETH)
  * @param _recipients array of addresses of the recipients of the purchased key
  * @param _referrers array of addresses of the users making the referral
  * @param _keyManagers optional array of addresses to grant managing rights to a specific address on creation
  * @param _data array of arbitrary data populated by the front-end which initiated the sale
  * @notice when called for an existing and non-expired key, the `_keyManager` param will be ignored 
  * @dev Setting _value to keyPrice exactly doubles as a security feature. That way if the lock owner increases the
  * price while my transaction is pending I can't be charged more than I expected (only applicable to ERC-20 when more
  * than keyPrice is approved for spending).
  */
  function purchase(
    uint256[] calldata _values,
    address[] calldata _recipients,
    address[] calldata _referrers,
    address[] calldata _keyManagers,
    bytes[] calldata _data
  ) external payable;
  
  /**
  * @dev Extend function
  * @param _value the number of tokens to pay for this purchase >= the current keyPrice - any applicable discount
  * (_value is ignored when using ETH)
  * @param _tokenId the id of the key to extend
  * @param _referrer address of the user making the referral
  * @param _data arbitrary data populated by the front-end which initiated the sale
  * @dev Throws if lock is disabled or key does not exist for _recipient. Throws if _recipient == address(0).
  */
  function extend(
    uint _value,
    uint _tokenId,
    address _referrer,
    bytes calldata _data
  ) external payable;


  /**
   * Deactivate an existing key
   * @param _tokenId the id of token to burn
   * @notice the key will be expired and ownership records will be destroyed
   */
  function burn(uint _tokenId) external;

  /**
  * @param _gasRefundValue price in wei or token in smallest price unit
  * @dev Set the value to be refunded to the sender on purchase
  */
  function setGasRefundValue(uint256 _gasRefundValue) external;
  
  /**
  * _gasRefundValue price in wei or token in smallest price unit
  * @dev Returns the value/rpice to be refunded to the sender on purchase
  */
  function gasRefundValue() external view returns (uint256 _gasRefundValue);

 

  /**
   * Allow a Lock manager to change the transfer fee.
   * @dev Throws if called by other than a Lock manager
   * @param _transferFeeBasisPoints The new transfer fee in basis-points(bps).
   * Ex: 200 bps = 2%
   */
  function updateTransferFee(
    uint _transferFeeBasisPoints
  ) external;

  /**
   * Determines how much of a fee would need to be paid in order to
   * transfer to another account.  This is pro-rated so the fee goes 
   * down overtime.
   * @dev Throws if _tokenId does not have a valid key
   * @param _tokenId The id of the key check the transfer fee for.
   * @param _time The amount of time to calculate the fee for.
   * @return The transfer fee in seconds.
   */
  function getTransferFee(
    uint _tokenId,
    uint _time
  ) external view returns (uint);

  /**
   * @dev Invoked by a Lock manager to expire the user's key 
   * and perform a refund and cancellation of the key
   * @param _tokenId The key id we wish to refund to
   * @param _amount The amount to refund to the key-owner
   * @dev Throws if called by other than a Lock manager
   * @dev Throws if _keyOwner does not have a valid key
   */
  function expireAndRefundFor(
    uint _tokenId,
    uint _amount
  ) external;

   /**
   * @dev allows the key manager to expire a given tokenId
   * and send a refund to the keyOwner based on the amount of time remaining.
   * @param _tokenId The id of the key to cancel.
   */
  function cancelAndRefund(uint _tokenId) external;

  /**
   * @dev Determines how much of a refund a key owner would receive if they issued
   * @param _keyOwner The key owner to get the refund value for.
   * a cancelAndRefund block.timestamp.
   * Note that due to the time required to mine a tx, the actual refund amount will be lower
   * than what the user reads from this call.
   */
  function getCancelAndRefundValue(
    address _keyOwner
  ) external view returns (uint refund);

  function addKeyGranter(address account) external;

  function addLockManager(address account) external;

  function isKeyGranter(address account) external view returns (bool);

  function isLockManager(address account) external view returns (bool);

  function onKeyPurchaseHook() external view returns(address);

  function onKeyCancelHook() external view returns(address);
  
  function onValidKeyHook() external view returns(bool);

  function onTokenURIHook() external view returns(string memory);

  function revokeKeyGranter(address _granter) external;

  function renounceLockManager() external;

  /**
   * @dev Change the maximum number of keys the lock can edit
   * @param _maxNumberOfKeys uint the maximum number of keys
   */
  function setMaxNumberOfKeys (uint _maxNumberOfKeys) external;

   /**
   * Set the maximum number of keys a specific address can use
   * @param _maxKeysPerAddress the maximum amount of key a user can own
   */
  function setMaxKeysPerAddress (uint _maxKeysPerAddress) external;

  /**
   * @return the maximum number of key allowed for a single address
   */
  function maxKeysPerAddress() external view returns (uint);


  ///===================================================================
  /// Auto-generated getter functions from public state variables

  function beneficiary() external view returns (address );

  function expirationDuration() external view returns (uint256 );

  function freeTrialLength() external view returns (uint256 );

  function keyPrice() external view returns (uint256 );

  function maxNumberOfKeys() external view returns (uint256 );

  function refundPenaltyBasisPoints() external view returns (uint256 );

  function tokenAddress() external view returns (address );

  function transferFeeBasisPoints() external view returns (uint256 );

  function unlockProtocol() external view returns (address );

  function keyManagerOf(uint) external view returns (address );

  ///===================================================================

  /**
  * @notice Update transfer and cancel rights for a given key
  * @param _tokenId The id of the key to assign rights for
  * @param _keyManager The address to assign the rights to for the given key
  */
  function setKeyManagerOf(
    uint _tokenId,
    address _keyManager
  ) external;
  
  /**
  * Check if a certain key is valid
  * @param _tokenId the id of the key to check validity
  * @notice this makes use of the onValidKeyHook if it is set
  */
  function isValidKey(
    uint _tokenId
  )
    external
    view
    returns (bool);
  
  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() external view returns (string memory _name);
  ///===================================================================

  /// From ERC165.sol
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  ///===================================================================

  /// From ERC-721
  /**
    * @dev Returns the number of NFTs in `owner`'s account.
    */
  function balanceOf(address _owner) external view returns (uint256 balance);

  /**
    * @dev Returns the owner of the NFT specified by `tokenId`.
    */
  function ownerOf(uint256 tokenId) external view returns (address _owner);

  /**
    * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
    * another (`to`).
    *
    * Requirements:
    * - `from`, `to` cannot be zero.
    * - `tokenId` must be owned by `from`.
    * - If the caller is not `from`, it must be have been allowed to move this
    * NFT by either {approve} or {setApprovalForAll}.
    */
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  
  /**
    * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
    * another (`to`).
    *
    * Requirements:
    * - If the caller is not `from`, it must be approved to move this NFT by
    * either {approve} or {setApprovalForAll}.
    */
  function transferFrom(address from, address to, uint256 tokenId) external;
  function approve(address to, uint256 tokenId) external;

  /**
    * @notice Get the approved address for a single NFT
    * @dev Throws if `_tokenId` is not a valid NFT.
    * @param _tokenId The NFT to find the approved address for
    * @return operator The approved address for this NFT, or the zero address if there is none
    */
  function getApproved(uint256 _tokenId) external view returns (address operator);

   /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _operator operator address to set the approval
   * @param _approved representing the status of the approval to be set
   * @notice disabled when transfers are disabled
   */
  function setApprovalForAll(address _operator, bool _approved) external;

   /**
   * @dev Tells whether an operator is approved by a given keyManager
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

  function totalSupply() external view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns (uint256 tokenId);

  function tokenByIndex(uint256 index) external view returns (uint256);

  /**
    * Innherited from Open Zeppelin AccessControl.sol
    */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);
  function grantRole(bytes32 role, address account) external;
  function revokeRole(bytes32 role, address account) external;
  function renounceRole(bytes32 role, address account) external;
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
    * @notice An ERC-20 style transfer.
    * @param _value sends a token with _value * expirationDuration (the amount of time remaining on a standard purchase).
    * @dev The typical use case would be to call this with _value 1, which is on par with calling `transferFrom`. If the user
    * has more than `expirationDuration` time remaining this may use the `shareKey` function to send some but not all of the token.
    */
  function transfer(
    address _to,
    uint _value
  ) external
    returns (bool success);

  /** `owner()` is provided as an helper to mimick the `Ownable` contract ABI.
    * The `Ownable` logic is used by many 3rd party services to determine
    * contract ownership - e.g. who is allowed to edit metadata on Opensea.
    * 
    * @notice This logic is NOT used internally by the Unlock Protocol and is made 
    * available only as a convenience helper.
    */
  function owner() external view returns (address);
  function setOwner(address account) external;
  function isOwner(address account) external returns (bool);


  /**
  * Returns the version number of the data schema currently used by the lock
  * @notice if this is different from `publicLockVersion`, then the ability to purchase, grant
  * or extend keys is disabled.
  * @dev will return 0 if no ;igration has ever been run
  */
  function schemaVersion() external view returns (uint);

  /**
   * Set the schema version to the latest
   * @notice only lock manager call call this
   */
  function updateSchemaVersion() external;

    /**
  * Renew a given token
  * @notice only works for non-free, expiring, ERC20 locks
  * @param _tokenId the ID fo the token to renew
  * @param _referrer the address of the person to be granted UDT
  */
  function renewMembershipFor(
    uint _tokenId,
    address _referrer
  ) external;
}