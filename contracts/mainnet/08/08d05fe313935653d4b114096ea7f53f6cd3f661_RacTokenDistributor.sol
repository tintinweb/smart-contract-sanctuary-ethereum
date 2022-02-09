/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}

/// @title Rac Token Distributor smart contract
/// @author coinvise
/**  @notice This contract allows active RAC patreon subscribers to claim tokens based on subscription type per month
when a user who has been whitelisted to claim for a month does not claim, that user looses the access to claim till whitelisted again 
*/
contract RacTokenDistributor {
  // subscribe() will take in a uint for any of this
  // 1 will represent Basic
  // 2 will represent Premium
  // 3 will represent VIP and so on as set by the admin

  /** @notice maps and address to a subsription type, subscription types are represented with number
   */
  mapping(address => uint256) public subscriptionType;

  /** @notice maps a subscription type(which is a uint) to amount of claimable tokens
   */
  mapping(uint256 => uint256) public claimableTokensPerSubType;

  /** @notice maps an address to a bool value if user has claimed or not till whitelisted again
   */
  mapping(address => bool) public hasClaimedForTheMonth;

  /** @notice maps an address to the time last whitelised, this helps to check if its past one month a user was lastwhitelised,
      if so, user won't be able to claim till whitelisted again
   */
  mapping(address => uint256) public lastTimeWhiteListed;

  /// @notice max number of valid subscription type
  uint256 public numOfValidSubTypes;

  /// @notice Emitted when user is whitelisted
  /// @param user The address of user
  /// @param subType subscripton type for user
  event Whitelisted(address indexed user, uint256 indexed subType);

  /// @notice Emitted when user claims
  /// @param user The address of user
  /// @param amountClaimed amount claimed
  event Claimed(address indexed user, uint256 amountClaimed);

  /// @notice instantiates Rac token
  IERC20 racInstance = IERC20(0xc22B30E4cce6b78aaaADae91E44E73593929a3e9);

  /// @notice admin address
  address public admin = 0xD4B8DBAaa4FeFE1f033CfB1e77e2315EB6df8CFB;

  modifier onlyAdmin() {
    require(msg.sender == admin, "only admin can do this");
    _;
  }

  /// @notice batch whiteList addresses
  /// @param _users arrays of users
  /// @param _subscriptionType arrays of subscription types which users will be mapped to respectively
  /// @dev this function is callable by only admin

  function batchWhitelist(
    address[] memory _users,
    uint256[] memory _subscriptionType
  ) public onlyAdmin {
    require(
      _users.length == _subscriptionType.length,
      "users and subscriptionType length mismatch"
    );
    for (uint256 i = 0; i < _users.length; i++) {
      require(
        _subscriptionType[i] <= numOfValidSubTypes && _subscriptionType[i] != 0,
        "number passed not within subscription range"
      );
      subscriptionType[_users[i]] = _subscriptionType[i];
      hasClaimedForTheMonth[_users[i]] = false;
      lastTimeWhiteListed[_users[i]] = block.timestamp;
      emit Whitelisted(_users[i], _subscriptionType[i]);
    }
  }

  /// @notice batch set claimable tokens per sub type
  /// @dev this function checks the subtypes passed and increments the numOfValidSubTypes if sub types doesnt yet exists
  /// @param _subType arrays of subscription types
  /// @param _amountClaimable arrays of claimable amount per sub types
  /// @return returns bool when function runs successfully

  function batchSetClaimableTokensPerSub(
    uint256[] memory _subType,
    uint256[] memory _amountClaimable
  ) public onlyAdmin returns (bool) {
    require(
      _subType.length == _amountClaimable.length,
      "subtype length should be equal to claimable amount length"
    );

    for (uint256 i = 0; i < _subType.length; i++) {
      claimableTokensPerSubType[_subType[i]] = _amountClaimable[i];

      if (_subType[i] > numOfValidSubTypes) {
        numOfValidSubTypes = numOfValidSubTypes + 1;
      }
    }

    return true;
  }

  // withdraws contract rac token balance only by admin

  function withdrawContractBalance(address _address) public onlyAdmin {
    uint256 bal = racInstance.balanceOf(address(this));
    racInstance.transfer(_address, bal);
  }

  /**
         @notice users call this function to claim rac token- the contracts sends the matched claimable tokens per thier respective subscription type
         this function checks users subscription type, checked if they have claimed within the set time(mostly a month) and finally checks if they are attempting
         claim within the specified time(mostly a month)
      */

  function claimRacForTheMonth() public {
    require(
      subscriptionType[msg.sender] <= numOfValidSubTypes &&
        subscriptionType[msg.sender] != 0,
      "You do not have a valid subscription on this platform"
    );
    require(
      hasClaimedForTheMonth[msg.sender] == false,
      "you have claimed already, kindly wait to be whiteListed for another round"
    );
    require(
      block.timestamp - (lastTimeWhiteListed[msg.sender]) <= 60 * 60 * 24 * 31,
      "you don't seem whitelisted to claim for this month"
    );

    //check user sub type to determine how much token to claimable
    uint256 userSubType = subscriptionType[msg.sender];

    // change mapping to true that address has claimedDateInterval
    hasClaimedForTheMonth[msg.sender] = true;

    // change subscription type to 0
    subscriptionType[msg.sender] = 0;

    // use userSubType to check how much claimableTokensPerSub token
    racInstance.transfer(msg.sender, claimableTokensPerSubType[userSubType]);

    emit Claimed(msg.sender, claimableTokensPerSubType[userSubType]);
  }
}