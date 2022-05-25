// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../testVesting.sol";

contract PublicLockedVestingMock is KeeperCompatibleInterface, ReentrancyGuard {
  /*==================================================== State Variables ====================================================*/
  VestingMock vesting;

  /*==================================================== Constructor ========================================================*/
  constructor(address _vesting) {
    vesting = VestingMock(_vesting);
  }

  /*==================================================== FUNCTIONS ==========================================================*/
  /*==================================================== Read Functions ======================================================*/
  function checkUpkeep(
    bytes calldata /* checkData */
  ) external view override returns (bool upkeepNeeded, bytes memory performData) {
    address[] memory _users = vesting.getUsers(6);
    bool outBreak = false;
    for (uint256 i = 0; i < _users.length; i++) {
      uint256[] memory _indexes = vesting.getInvestorIndexes(_users[i], 6);
      for (uint256 k = 0; k < _indexes.length; k++) {
        uint256 withdrawableAmount = vesting.withdrawableTokens(_users[i],vesting.intToEnum(6),_indexes[k]);
        if (upkeepNeeded = withdrawableAmount > 0) {
          performData = abi.encode(_users[i],_indexes[k]);
          break;
        } 
      }
      if (outBreak) break;
    }
    outBreak = false;
  }

  /*==================================================== External Functions ==================================================*/

  function performUpkeep(bytes calldata performData) external override nonReentrant {
    (address _user,  uint256 _index) = abi.decode(performData, (address,  uint256));
    vesting.withdrawTokensAutomatically(_user, vesting.intToEnum(6), _index);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IBEP20.sol";

contract VestingMock is ReentrancyGuard {
  /**
   * The vesting time is given in terms of the selected vesting type.
   *     _vType
   *  --------------
   * | 0 = 1   days |
   * | 1 = 7   days |
   * | 2 = 30  days |
   * | 3 = 90  days |
   * | 4 = 180 days |
   * | 5 = 360 days |
   *  --------------
   */

  /*==================================================== Events =============================================================*/
  event InvestorAdded(address indexed investor, address caller, uint256 allocation, uint256 endTime, uint256 indexed softCapValue, bool indexed sofCapStatus);
  event Withdrawn(address indexed investor, uint256 value);
  event InvestorRemoved(address indexed investor);
  event RecoverToken(address indexed token, uint256 indexed amount);
  /*==================================================== Modifiers ==========================================================*/
  /*
   *Throws error when caller is not registered investor
   */
  modifier onlyInvestor(VestingCategory _vCat, uint256 _index) {
    require(investorsInfo[msg.sender][_vCat][_index].exists, "Only investors allowed");
    _;
  }
  /*
   * Throws error when caller is not registered as an authorized contract.
   *Needed for withdrawFundsAutomatically for keeper mini vesting contracts.
   */
  modifier onlyContracts() {
    require(authorizedContracts[msg.sender], "Only authorized contracts allowed");
    _;
  }
  /*
   *Throws error when caller is not the Admin
   */
  modifier onlyAdmin() {
    require(msg.sender == admin, "Only Admin");
    _;
  }
  /*==================================================== State Variables ====================================================*/
  //============================================================================

  //Vesting types
  enum VestingType {
    DAILY,
    WEEKLY,
    MONTHLY,
    QUARTERLY,
    HALFYEARLY,
    YEARLY
  }

  // Vesting categories
  enum VestingCategory {
    TA,
    MARKETING,
    ECOSYSTEM,
    STRATEGIC_SEED,
    STRATEGIC_PRIVATE,
    PUBLIC_UNLOCKED,
    PUBLIC_LOCKED,
    SPORTS
  }
  //============================================================================
  //Needed for Stack Too Deep eroor in the _addInvestor function. Its parameters were reduced into One using this Struct.
  struct AddInvestor {
    address investor;
    uint256 tokensAllotment;
    uint256 initialUnlockAmount;
    uint256 recurrence;
    uint256 afterCliffUnlockAmount;
    uint256 cliffDays;
    VestingCategory vCat;
    VestingType vType;
    string purchaseId;
  }

  // Struct for Investor data
  struct Investor {
    bool exists;
    uint256 withdrawnTokens;
    uint256 tokensAllotment;
    uint256 startTimestamp;
    uint256 endTime;
    uint256 lastReceivedTime;
    Schedules schedules;
  }

  // Data of vesting categories
  struct Schedules {
    uint256 afterCliffUnlockAmount;
    uint256 initialUnlockAmount;
    uint256 recurrence;
    uint256 cliffDays;
    uint256 multiplier;
    VestingType vType;
  }

  //============================================================================
  //Total Allocated Token Amount To Investors
  uint256 public totalAllocatedAmount;
  //Total sold publicly unlocked token amount
  uint256 public soldPublicUnlocked;
  //Total sold publicly locked token amount
  uint256 public soldPublicLocked;
  //Investors vesting default start time
  uint256 public globalTime;
  // Holds Current value of the softcap pool
  uint256 public softCap;


  uint256 private constant SOFTCAP_LIMIT = 120 * 10**11;
  uint256 private constant DIVIDING = 1000;
  uint256 private constant LOCKEDPRICE = 5 * 10**6;
  uint256 private constant UNLOCKEDPRICE = 6 * 10**6;
  uint256 private constant UNIT = 10**18;

  //The Array of the investors addresses
  address[] public investors;
  //Address of the admin
  address public admin;
  //Address of the Soccer
  IBEP20 public SoCo;
  //Controller for SoCo set
  bool public isTokenSet;
  // Checks whether globalTime set before
  bool private isGlobalSetBefore;

  //============================================================================
  //Stores Investors Vesting Data
  mapping(address => mapping(VestingCategory => mapping(uint256 => Investor))) public investorsInfo;
  //Stores investors vesting indexes per vesting category
  mapping(address => mapping(VestingCategory => uint256[])) private investorIndexes;

  //Stores all investors addresses for the specific Vesting Category
  mapping(VestingCategory => address[]) private allInvestors;

  //To read investors easily from Mini Kepeer-Mini Vesting Type contracts
  mapping(uint256 => VestingCategory) public intToEnum;
/*   mapping(VestingCategory => uint256) private enumToInt; */

  //Returns schedule data
  mapping(VestingCategory => Schedules) public scheduleInfo;
  //Returns period data
  mapping(VestingType => uint256) public periods;

  //Returns whitelisted contracts
  mapping(address => bool) public authorizedContracts;
  //Stores expired purchase Ids to prevent the same purchase happenning again
  mapping(string => bool) public expiredPurchaseIds;

  /*==================================================== Constructor ========================================================*/
  /*
   *@param _admin : address of the admin
   *@param _globaltime: default start time
   */
  constructor(address _admin, uint256 _globalTime) {
    admin = _admin;
    globalTime = _globalTime;
    //============================================================================
    periods[VestingType.DAILY] = 1; // in minutes for test
    periods[VestingType.WEEKLY] = 7; // in minutes for test
    periods[VestingType.MONTHLY] = 30; // in minutes for test
    periods[VestingType.QUARTERLY] = 90; // in minutes for test
    periods[VestingType.HALFYEARLY] = 180; // in minutes for test
    periods[VestingType.YEARLY] = 360; // in minutes for test
    //============================================================================
    intToEnum[0] = VestingCategory.TA;
    intToEnum[1] = VestingCategory.MARKETING;
    intToEnum[2] = VestingCategory.ECOSYSTEM;
    intToEnum[3] = VestingCategory.STRATEGIC_SEED;
    intToEnum[4] = VestingCategory.STRATEGIC_PRIVATE;
    intToEnum[5] = VestingCategory.PUBLIC_UNLOCKED;
    intToEnum[6] = VestingCategory.PUBLIC_LOCKED;
    intToEnum[7] = VestingCategory.SPORTS;
    //============================================================================
/*     enumToInt[VestingCategory.TA] = 0;
    enumToInt[VestingCategory.MARKETING] = 1;
    enumToInt[VestingCategory.ECOSYSTEM] = 2;
    enumToInt[VestingCategory.STRATEGIC_SEED] = 3;
    enumToInt[VestingCategory.STRATEGIC_PRIVATE] = 4;
    enumToInt[VestingCategory.PUBLIC_UNLOCKED] = 5;
    enumToInt[VestingCategory.PUBLIC_LOCKED] = 6; */

    //============================================================================
    scheduleInfo[VestingCategory.TA].vType = VestingType.HALFYEARLY;
    scheduleInfo[VestingCategory.TA].afterCliffUnlockAmount = 0;
    scheduleInfo[VestingCategory.TA].recurrence = 6;
    scheduleInfo[VestingCategory.TA].cliffDays = 18; // in minutes for test
    scheduleInfo[VestingCategory.TA].multiplier = 100;
    //============================================================================
    scheduleInfo[VestingCategory.MARKETING].vType = VestingType.MONTHLY;
    scheduleInfo[VestingCategory.MARKETING].afterCliffUnlockAmount = 0;
    scheduleInfo[VestingCategory.MARKETING].multiplier = 200;
    scheduleInfo[VestingCategory.MARKETING].recurrence = 16;
    scheduleInfo[VestingCategory.MARKETING].cliffDays = 0;
    //============================================================================
    scheduleInfo[VestingCategory.ECOSYSTEM].vType = VestingType.QUARTERLY;
    scheduleInfo[VestingCategory.ECOSYSTEM].afterCliffUnlockAmount = 0;
    scheduleInfo[VestingCategory.ECOSYSTEM].multiplier = 200;
    scheduleInfo[VestingCategory.ECOSYSTEM].recurrence = 8;
    scheduleInfo[VestingCategory.ECOSYSTEM].cliffDays = 0;
    //============================================================================
    scheduleInfo[VestingCategory.STRATEGIC_SEED].vType = VestingType.QUARTERLY;
    scheduleInfo[VestingCategory.STRATEGIC_SEED].afterCliffUnlockAmount = 0;
    scheduleInfo[VestingCategory.STRATEGIC_SEED].multiplier = 300;
    scheduleInfo[VestingCategory.STRATEGIC_SEED].recurrence = 7;
    scheduleInfo[VestingCategory.STRATEGIC_SEED].cliffDays = 36; // in minutes for test
    //============================================================================
    scheduleInfo[VestingCategory.STRATEGIC_PRIVATE].vType = VestingType.QUARTERLY;
    scheduleInfo[VestingCategory.STRATEGIC_PRIVATE].afterCliffUnlockAmount = 0;
    scheduleInfo[VestingCategory.STRATEGIC_PRIVATE].multiplier = 75;
    scheduleInfo[VestingCategory.STRATEGIC_PRIVATE].recurrence = 6;
    scheduleInfo[VestingCategory.STRATEGIC_PRIVATE].cliffDays = 0;
    //============================================================================
    scheduleInfo[VestingCategory.PUBLIC_LOCKED].vType = VestingType.MONTHLY;
    scheduleInfo[VestingCategory.PUBLIC_LOCKED].afterCliffUnlockAmount = 0;
    scheduleInfo[VestingCategory.PUBLIC_LOCKED].multiplier = 100;
    scheduleInfo[VestingCategory.PUBLIC_LOCKED].recurrence = 9;
    scheduleInfo[VestingCategory.PUBLIC_LOCKED].cliffDays = 0;
    //============================================================================
    scheduleInfo[VestingCategory.PUBLIC_UNLOCKED].vType = VestingType.DAILY;
    scheduleInfo[VestingCategory.PUBLIC_UNLOCKED].afterCliffUnlockAmount = 0;
    scheduleInfo[VestingCategory.PUBLIC_UNLOCKED].multiplier = 1000;
    scheduleInfo[VestingCategory.PUBLIC_UNLOCKED].recurrence = 0;
    scheduleInfo[VestingCategory.PUBLIC_UNLOCKED].cliffDays = 0;
    //============================================================================
    scheduleInfo[VestingCategory.SPORTS].vType = VestingType.DAILY;
    scheduleInfo[VestingCategory.SPORTS].afterCliffUnlockAmount = 0;
    scheduleInfo[VestingCategory.SPORTS].multiplier = 1000;
    scheduleInfo[VestingCategory.SPORTS].recurrence = 0;
    scheduleInfo[VestingCategory.SPORTS].cliffDays = 73; // in minutes for test
  }

  /*==================================================== FUNCTIONS ==========================================================*/
  /*==================================================== Read Functions ======================================================*/

  /** 
  ///@return _users : all investors addresses for the given category 
  ///@param _vCat: Between values 0-7, returns investors addresses for that vesting category
  */
  function getUsers(uint256 _vCat) external view returns (address[] memory _users) {
    VestingCategory _vest = intToEnum[_vCat];
    return allInvestors[_vest];
  }

  /*
   *@returns Investor data as a struct
   *@param _investor : The address of the investor
   *@param _vCat : vesting category (e.g 0 for TA, 1 for Marketing)
   *@param _index : the index of the users purchase for the same category
   */
  function getInvestorInfo(
    address _investor,
    uint256 _vCat,
    uint256 _index
  ) external view returns (Investor memory) {
    VestingCategory _vest = intToEnum[_vCat];
    return investorsInfo[_investor][_vest][_index];
  }

  /**
    @return _indexes : the indexes of the given user for the given category
    @param _investor: The address of the Investor
    @param _vCat: Category parameter,integers between 0-7
  */
  function getInvestorIndexes(address _investor, uint256 _vCat) external view returns (uint256[] memory _indexes) {
    VestingCategory _vest = intToEnum[_vCat];
    _indexes = investorIndexes[_investor][_vest];
  }

  /*
  ///@dev withdrawable tokens for an address
  *@returns Available tokens amount for the given user data  
  *@param _investor : The address of the investor
  *@param _vCat : vesting category (e.g 0 for TA, 1 for Marketing)
  *@param _index : the index of the users purchase for the same category 
  */
  function withdrawableTokens(
    address _investor,
    VestingCategory _vCat,
    uint256 _index
  ) public view returns (uint256 tokensAvailable) {
    Investor storage investor = investorsInfo[_investor][_vCat][_index];

    uint256 totalUnlockedTokens = calculateUnlockedTokens(_investor, _vCat, _index);
    uint256 tokensWithdrawable = totalUnlockedTokens - investor.withdrawnTokens;
    return tokensWithdrawable;
  }

  /*
   *@returns the end time of the vesting for the given user data
   *@param _investor : The address of the investor
   *@param _vCat : vesting category (e.g 0 for TA, 1 for Marketing)
   *@param _index : the index of the users purchase for the same category
   */
  function getInvestorEndTime(
    address _investor,
    VestingCategory _vCat,
    uint256 _index
  ) external view returns (uint256) {
    return investorsInfo[_investor][_vCat][_index].endTime;
  }

  /**
  @return availableTokens : Total unlocked amou t for the given investor data
  @param _investor: Address of the investor
  @param _vCat: Vesting Category 
  @param _index: the index of the users purchase for the same category 
   */
  function calculateUnlockedTokens(
    address _investor,
    VestingCategory _vCat,
    uint256 _index
  ) public view returns (uint256 availableTokens) {
    //Investor storage investor = investorsInfo[_investor];
    Investor storage investor = investorsInfo[_investor][_vCat][_index];
    uint256 period = periods[investor.schedules.vType];
    uint256 startTimeStamp = investor.startTimestamp;

    if (startTimeStamp == 0) startTimeStamp = globalTime;

    uint256 cliffTimestamp = startTimeStamp + (investor.schedules.cliffDays * 60);

    uint256 vestingTimestamp = cliffTimestamp + (investor.schedules.recurrence * period * 60);

    uint256 initialDistroAmount = investor.schedules.initialUnlockAmount;

    uint256 currentTimeStamp = block.timestamp;

    if (currentTimeStamp > startTimeStamp) {
      if (currentTimeStamp <= cliffTimestamp) {
        return initialDistroAmount;
      } else if (currentTimeStamp > cliffTimestamp && currentTimeStamp < vestingTimestamp) {
        uint256 vestingDistroAmount = investor.tokensAllotment - (initialDistroAmount + investor.schedules.afterCliffUnlockAmount);

        // uint256 diffDays = ((currentTimeStamp - cliffTimestamp) / 1 days);

        // uint256 vestingUnlockedAmount = (vestingDistroAmount * (diffDays)) / (investor.schedules.recurrence * period);

        uint256 diffDays = ((currentTimeStamp - cliffTimestamp) / (period * 60));

        uint256 vestingUnlockedAmount = (vestingDistroAmount * (diffDays)) / (investor.schedules.recurrence);

        return initialDistroAmount + vestingUnlockedAmount + investor.schedules.afterCliffUnlockAmount;
      } else {
        return investor.tokensAllotment;
      }
    } else {
      return 0;
    }
  }

  /*==================================================== External Functions ==================================================*/
  /// @dev Adds investors. This function doesn't limit max gas consumption,
  // so adding too many investors can cause it to reach the out-of-gas error.
  /**
  @param _investors: Investor addresses
  @param _tokensAllotments: Token Allotment of the Users
  @param _categories:  Vesting Categories
  @param _purchaseIds: Purchase Ids
   */
  function addInvestorBatch(
    address[] calldata _investors,
    uint256[] calldata _tokensAllotments,
    VestingCategory[] calldata _categories,
    string[] calldata _purchaseIds
  ) external onlyAdmin nonReentrant {
    require(_tokensAllotments.length == _categories.length, "addInvestorBatch: array lengths should be the same");

    for (uint256 i = 0; i < _investors.length; i++) {
      Schedules memory _schedulesInfo = scheduleInfo[_categories[i]];
      if (_categories[i] == VestingCategory.TA || _categories[i] == VestingCategory.STRATEGIC_SEED || _categories[i] == VestingCategory.SPORTS) {
        _schedulesInfo.afterCliffUnlockAmount = (_tokensAllotments[i] * _schedulesInfo.multiplier) / DIVIDING;
      } else {
        _schedulesInfo.initialUnlockAmount = (_tokensAllotments[i] * _schedulesInfo.multiplier) / DIVIDING;
      }
      AddInvestor memory investor = AddInvestor(
        _investors[i],
        _tokensAllotments[i],
        _schedulesInfo.initialUnlockAmount,
        _schedulesInfo.recurrence,
        _schedulesInfo.afterCliffUnlockAmount,
        _schedulesInfo.cliffDays,
        _categories[i],
        _schedulesInfo.vType,
        _purchaseIds[i]
      );
      _addInvestor(investor);
    }
  }

  /**
  @param _investor: Investor address
  @param _tokensAllotment: Token Allotment of the User
  @param _category:  Vesting Category
  @param _purchaseId: Purchase Id
  */
  function addInvestor(
    address _investor,
    uint256 _tokensAllotment,
    string calldata _purchaseId,
    VestingCategory _category
  ) external onlyAdmin nonReentrant {
    Schedules memory _schedulesInfo = scheduleInfo[_category];
    if (_category == VestingCategory.TA || _category == VestingCategory.STRATEGIC_SEED || _category == VestingCategory.SPORTS) {
      _schedulesInfo.afterCliffUnlockAmount = (_tokensAllotment * _schedulesInfo.multiplier) / DIVIDING;
    } else {
      _schedulesInfo.initialUnlockAmount = (_tokensAllotment * _schedulesInfo.multiplier) / DIVIDING;
    }
    AddInvestor memory investor = AddInvestor(
      _investor,
      _tokensAllotment,
      _schedulesInfo.initialUnlockAmount,
      _schedulesInfo.recurrence,
      _schedulesInfo.afterCliffUnlockAmount,
      _schedulesInfo.cliffDays,
      _category,
      _schedulesInfo.vType,
      _purchaseId
    );

    _addInvestor(investor);
  }

  /*
  This function can only be called by the Mini-Keeper Vesting Type Contracts that is registered.
  */
  function withdrawTokensAutomatically(
    address _user,
    VestingCategory _vCat,
    uint256 _index
  ) external onlyContracts {
/*     VestingCategory _vest = intToEnum[_vCat]; */
    Investor storage investor = investorsInfo[_user][_vCat][_index];

    uint256 tokensAvailable = withdrawableTokens(_user, _vCat, _index);
    require(tokensAvailable > 0, "withdrawTokens: no tokens available for withdrawal");

    require(investor.tokensAllotment >= tokensAvailable, "You can't take withdraw more than allocation");

    investor.withdrawnTokens = investor.withdrawnTokens + tokensAvailable;

    SoCo.transfer(_user, tokensAvailable);

    investorsInfo[_user][_vCat][_index].lastReceivedTime = block.timestamp;
    emit Withdrawn(_user, tokensAvailable);
  }

  /*

  * User can withdraw his/her unlocked tokens via this function
  *@param _vCat : Vesting category (e.g 0 for TA, 1 for Marketing)
  *@param _index : The index of the users purchase for the same category 
  */
  function withdrawTokens(VestingCategory _vCat, uint256 _index) external onlyInvestor(_vCat, _index) nonReentrant {
    Investor storage investor = investorsInfo[msg.sender][_vCat][_index];

    uint256 tokensAvailable = withdrawableTokens(msg.sender, _vCat, _index);
    require(tokensAvailable > 0, "withdrawTokens: no tokens available for withdrawal");

    require(investor.tokensAllotment >= tokensAvailable, "You can't take withdraw more than allocation");

    investor.withdrawnTokens = investor.withdrawnTokens + tokensAvailable;

    investorsInfo[msg.sender][_vCat][_index].lastReceivedTime = block.timestamp;
    SoCo.transfer(msg.sender, tokensAvailable);

    emit Withdrawn(msg.sender, tokensAvailable);
  }


  /**
    Users who have Sports category tokens, can withdraw any amount they want after fully unlocked.
    *@param _vCat: Should be 7 (VestingCategory.SPORTS).
    *@param _index: The index of the users purchase for the same category.
    *@param _amount: The amount of the tokens that users want to withdraw. Can't be greater than withdrawable tokens amount.
   */
  function withdrawSportsTokens(VestingCategory _vCat, uint256 _index, uint256 _amount) external onlyInvestor(_vCat, _index) {
    require(_vCat == VestingCategory.SPORTS,"This function enable to SPORTS category!");
    Investor storage investor = investorsInfo[msg.sender][_vCat][_index];

    uint256 tokensAvailable = withdrawableTokens(msg.sender, _vCat, _index);
    require(tokensAvailable > 0, "withdrawTokens: no tokens available for withdrawal");
    require(_amount <= tokensAvailable, "You can't take withdraw more than your available tokens");

    investor.withdrawnTokens += _amount;
    investorsInfo[msg.sender][_vCat][_index].lastReceivedTime = block.timestamp;
    SoCo.transfer(msg.sender, _amount);

    emit Withdrawn(msg.sender, _amount);
  }

  /*
   *The admin can remove investor with this function
   *@param _investor : The address of the investor
   *@param _vCat : Vesting category (e.g 0 for TA, 1 for Marketing)
   *@param _index : The index of the users purchase for the same category
   */
  function removeInvestor(
    address _investor,
    VestingCategory _vCat,
    uint256 _index
  ) external onlyAdmin {
    delete investorsInfo[_investor][_vCat][_index];
    emit InvestorRemoved(_investor);
  }

  /**
    Admin can recover tokens in the contract
  */
  function recoverToken(address _token, uint256 amount) external onlyAdmin {
    require(uint160(_token) != uint160(address(SoCo)),"token can't be SoCo!");
    IBEP20(_token).transfer(msg.sender, amount);
    emit RecoverToken(_token, amount);
  }

  /**
    After reaching Soft Cap, this function is called and set to a new start time for the investors.
  */
  function setGlobalTime(uint256 _globalTime) external onlyAdmin {
    globalTime = _globalTime;
  }

  /**
    Sets Authorization status of the Keeper Vesting Contracts.
   */
  function setVestingContracts(address[] memory _authContracts) external onlyAdmin {
    for (uint16 i = 0; i < _authContracts.length; i++) {
      authorizedContracts[_authContracts[i]] = true;
    }
  }

  /*
   * The admin can set a token which will be distributed
   *@param _token : The address of the token
   */
  function setToken(address _token) external onlyAdmin {
    require(!isTokenSet,"Token Already Set!");
    SoCo = IBEP20(_token);
    isTokenSet = true;
  }

  /*==================================================== Internal Functions ==================================================*/
  /**
    Adds investors data to contract
   */
  function _addInvestor(AddInvestor memory investor) internal {
    require(!expiredPurchaseIds[investor.purchaseId], "Purchase ID already used");
    expiredPurchaseIds[investor.purchaseId] = true;
    require(investor.investor != address(0), "addInvestor: invalid address");
    require(investor.tokensAllotment > 0, "addInvestor: the investor allocation must be more than 0");
    uint256 _index = investorIndexes[investor.investor][investor.vCat].length;

    if (_index == 0) allInvestors[investor.vCat].push(investor.investor);

    investorIndexes[investor.investor][investor.vCat].push(_index);

    Investor storage investor_ = investorsInfo[investor.investor][investor.vCat][_index];

    if (investor.vCat == VestingCategory.PUBLIC_LOCKED) soldPublicLocked += investor.tokensAllotment;
    if (investor.vCat == VestingCategory.PUBLIC_UNLOCKED) soldPublicUnlocked += investor.tokensAllotment;

    (bool _softCapStatus, uint256 _softCapValue) = _computeSoftCap(soldPublicLocked, soldPublicUnlocked);
    uint256 _startTime;

    _softCapStatus ? _startTime = block.timestamp : _startTime = 0;

    investor_.tokensAllotment = investor.tokensAllotment;
    investor_.exists = true;
    investor_.schedules.initialUnlockAmount = investor.initialUnlockAmount;
    investor_.schedules.vType = VestingType(investor.vType);
    investor_.schedules.cliffDays = investor.cliffDays;
    investor_.schedules.recurrence = investor.recurrence;
    investor_.schedules.afterCliffUnlockAmount = investor.afterCliffUnlockAmount;
    investor_.startTimestamp = _startTime;
    investor_.lastReceivedTime = _startTime;

    investor_.endTime = (investor.recurrence * periods[VestingType(investor.vType)]) + investor.cliffDays;

    investors.push(investor.investor);
    totalAllocatedAmount = totalAllocatedAmount + investor.tokensAllotment;

    emit InvestorAdded(investor.investor, msg.sender, investor.tokensAllotment, investor_.endTime, _softCapValue, _softCapStatus);
  }

  /**
    Computes the soft cap amount for the vesting
   */
  function _computeSoftCap(uint256 _soldLocked, uint256 _soldUnlocked) internal returns (bool _status, uint256 _value) {
    _value = ((_soldLocked * LOCKEDPRICE) / UNIT) + ((_soldUnlocked * UNLOCKEDPRICE) / UNIT);
    softCap = _value;
    _value > SOFTCAP_LIMIT ? _status = true : _status = false;
    if(!isGlobalSetBefore && _status){
      globalTime = block.timestamp;
      isGlobalSetBefore = true;
    } 
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
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}