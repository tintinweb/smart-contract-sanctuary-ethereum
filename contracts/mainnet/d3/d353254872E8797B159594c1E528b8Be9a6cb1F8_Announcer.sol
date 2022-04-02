// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "./ControllableV2.sol";
import "./ControllerStorage.sol";
import "../interface/IAnnouncer.sol";

/// @title Contract for holding scheduling for time-lock actions
/// @dev Use with TetuProxy
/// @author belbix
contract Announcer is ControllableV2, IAnnouncer {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract is changed
  string public constant VERSION = "1.2.0";
  bytes32 internal constant _TIME_LOCK_SLOT = 0x244FE7C39AF244D294615908664E79A2F65DD3F4D5C387AF1D52197F465D1C2E;

  /// @dev Hold schedule for time-locked operations
  mapping(bytes32 => uint256) public override timeLockSchedule;
  /// @dev Hold values for upgrade
  TimeLockInfo[] private _timeLockInfos;
  /// @dev Hold indexes for upgrade info
  mapping(TimeLockOpCodes => uint256) public timeLockIndexes;
  /// @dev Hold indexes for upgrade info by address
  mapping(TimeLockOpCodes => mapping(address => uint256)) public multiTimeLockIndexes;
  /// @dev Deprecated, don't remove for keep slot ordering
  mapping(TimeLockOpCodes => bool) public multiOpCodes;

  /// @notice Address change was announced
  event AddressChangeAnnounce(TimeLockOpCodes opCode, address newAddress);
  /// @notice Uint256 change was announced
  event UintChangeAnnounce(TimeLockOpCodes opCode, uint256 newValue);
  /// @notice Ratio change was announced
  event RatioChangeAnnounced(TimeLockOpCodes opCode, uint256 numerator, uint256 denominator);
  /// @notice Token movement was announced
  event TokenMoveAnnounced(TimeLockOpCodes opCode, address target, address token, uint256 amount);
  /// @notice Proxy Upgrade was announced
  event ProxyUpgradeAnnounced(address _contract, address _implementation);
  /// @notice Mint was announced
  event MintAnnounced(uint256 totalAmount, address _distributor, address _otherNetworkFund);
  /// @notice Announce was closed
  event AnnounceClosed(bytes32 opHash);
  /// @notice Strategy Upgrade was announced
  event StrategyUpgradeAnnounced(address _contract, address _implementation);
  /// @notice Vault stop action announced
  event VaultStop(address _contract);

  constructor() {
    require(_TIME_LOCK_SLOT == bytes32(uint256(keccak256("eip1967.announcer.timeLock")) - 1), "wrong timeLock");
  }

  /// @notice Initialize contract after setup it as proxy implementation
  /// @dev Use it only once after first logic setup
  /// @param _controller Controller address
  /// @param _timeLock TimeLock period
  function initialize(address _controller, uint256 _timeLock) external initializer {
    ControllableV2.initializeControllable(_controller);

    // fill timeLock
    bytes32 slot = _TIME_LOCK_SLOT;
    assembly {
      sstore(slot, _timeLock)
    }

    // placeholder for index 0
    _timeLockInfos.push(TimeLockInfo(TimeLockOpCodes.ZeroPlaceholder, 0, address(0), new address[](0), new uint256[](0)));
  }

  /// @dev Operations allowed only for Governance address
  modifier onlyGovernance() {
    require(_isGovernance(msg.sender), "not governance");
    _;
  }

  /// @dev Operations allowed for Governance or Dao addresses
  modifier onlyGovernanceOrDao() {
    require(_isGovernance(msg.sender)
      || IController(_controller()).isDao(msg.sender), "not governance or dao");
    _;
  }

  /// @dev Operations allowed for Governance or Dao addresses
  modifier onlyControlMembers() {
    require(
      _isGovernance(msg.sender)
      || _isController(msg.sender)
      || IController(_controller()).isDao(msg.sender)
      || IController(_controller()).vaultController() == msg.sender
    , "not control member");
    _;
  }

  // ************** VIEW ********************

  /// @notice Return time-lock period (in seconds) saved in the contract slot
  /// @return result TimeLock period
  function timeLock() public view returns (uint256 result) {
    bytes32 slot = _TIME_LOCK_SLOT;
    assembly {
      result := sload(slot)
    }
  }

  /// @notice Length of the the array of all undone announced actions
  /// @return Array length
  function timeLockInfosLength() external view returns (uint256) {
    return _timeLockInfos.length;
  }

  /// @notice Return information about announced time-locks for given index
  /// @param idx Index of time lock info
  /// @return TimeLock information
  function timeLockInfo(uint256 idx) external override view returns (TimeLockInfo memory) {
    return _timeLockInfos[idx];
  }

  // ************** ANNOUNCES **************

  /// @notice Only Governance can do it.
  ///         Announce address change. You will be able to setup new address after Time-lock period
  /// @param opCode Operation code from the list
  ///                 0 - Governance
  ///                 1 - Dao
  ///                 2 - FeeRewardForwarder
  ///                 3 - Bookkeeper
  ///                 4 - MintHelper
  ///                 5 - RewardToken
  ///                 6 - FundToken
  ///                 7 - PsVault
  ///                 8 - Fund
  ///                 19 - VaultController
  /// @param newAddress New address
  function announceAddressChange(TimeLockOpCodes opCode, address newAddress) external onlyGovernance {
    require(timeLockIndexes[opCode] == 0, "already announced");
    require(newAddress != address(0), "zero address");
    bytes32 opHash = keccak256(abi.encode(opCode, newAddress));
    timeLockSchedule[opHash] = block.timestamp + timeLock();

    address[] memory values = new address[](1);
    values[0] = newAddress;
    _timeLockInfos.push(TimeLockInfo(opCode, opHash, _controller(), values, new uint256[](0)));
    timeLockIndexes[opCode] = (_timeLockInfos.length - 1);

    emit AddressChangeAnnounce(opCode, newAddress);
  }

  /// @notice Only Governance can do it.
  ///         Announce some single uint256 change. You will be able to setup new value after Time-lock period
  /// @param opCode Operation code from the list
  ///                 20 - RewardBoostDuration
  ///                 21 - RewardRatioWithoutBoost
  /// @param newValue New value
  function announceUintChange(TimeLockOpCodes opCode, uint256 newValue) external onlyGovernance {
    require(timeLockIndexes[opCode] == 0, "already announced");
    bytes32 opHash = keccak256(abi.encode(opCode, newValue));
    timeLockSchedule[opHash] = block.timestamp + timeLock();

    uint256[] memory values = new uint256[](1);
    values[0] = newValue;
    _timeLockInfos.push(TimeLockInfo(opCode, opHash, address(0), new address[](0), values));
    timeLockIndexes[opCode] = (_timeLockInfos.length - 1);

    emit UintChangeAnnounce(opCode, newValue);
  }

  /// @notice Only Governance or DAO can do it.
  ///         Announce ratio change. You will be able to setup new ratio after Time-lock period
  /// @param opCode Operation code from the list
  ///                 9 - PsRatio
  ///                 10 - FundRatio
  /// @param numerator New numerator
  /// @param denominator New denominator
  function announceRatioChange(TimeLockOpCodes opCode, uint256 numerator, uint256 denominator) external override onlyGovernanceOrDao {
    require(timeLockIndexes[opCode] == 0, "already announced");
    require(numerator <= denominator, "invalid values");
    require(denominator != 0, "cannot divide by 0");
    bytes32 opHash = keccak256(abi.encode(opCode, numerator, denominator));
    timeLockSchedule[opHash] = block.timestamp + timeLock();

    uint256[] memory values = new uint256[](2);
    values[0] = numerator;
    values[1] = denominator;
    _timeLockInfos.push(TimeLockInfo(opCode, opHash, _controller(), new address[](0), values));
    timeLockIndexes[opCode] = (_timeLockInfos.length - 1);

    emit RatioChangeAnnounced(opCode, numerator, denominator);
  }

  /// @notice Only Governance can do it. Announce token movement. You will be able to transfer after Time-lock period
  /// @param opCode Operation code from the list
  ///                 11 - ControllerTokenMove
  ///                 12 - StrategyTokenMove
  ///                 13 - FundTokenMove
  /// @param target Destination of the transfer
  /// @param token Token the user wants to move.
  /// @param amount Amount that you want to move
  function announceTokenMove(TimeLockOpCodes opCode, address target, address token, uint256 amount)
  external onlyGovernance {
    require(timeLockIndexes[opCode] == 0, "already announced");
    require(target != address(0), "zero target");
    require(token != address(0), "zero token");
    require(amount != 0, "zero amount");
    bytes32 opHash = keccak256(abi.encode(opCode, target, token, amount));
    timeLockSchedule[opHash] = block.timestamp + timeLock();

    address[] memory adrValues = new address[](1);
    adrValues[0] = token;
    uint256[] memory intValues = new uint256[](1);
    intValues[0] = amount;
    _timeLockInfos.push(TimeLockInfo(opCode, opHash, target, adrValues, intValues));
    timeLockIndexes[opCode] = (_timeLockInfos.length - 1);

    emit TokenMoveAnnounced(opCode, target, token, amount);
  }

  /// @notice Only Governance can do it. Announce weekly mint. You will able to mint after Time-lock period
  /// @param totalAmount Total amount to mint.
  ///                    33% will go to current network, 67% to FundKeeper for other networks
  /// @param _distributor Distributor address, usually NotifyHelper
  /// @param _otherNetworkFund Fund address, usually FundKeeper
  function announceMint(
    uint256 totalAmount,
    address _distributor,
    address _otherNetworkFund,
    bool mintAllAvailable
  ) external onlyGovernance {
    TimeLockOpCodes opCode = TimeLockOpCodes.Mint;

    require(timeLockIndexes[opCode] == 0, "already announced");
    require(totalAmount != 0 || mintAllAvailable, "zero amount");
    require(_distributor != address(0), "zero distributor");
    require(_otherNetworkFund != address(0), "zero fund");

    bytes32 opHash = keccak256(abi.encode(opCode, totalAmount, _distributor, _otherNetworkFund, mintAllAvailable));
    timeLockSchedule[opHash] = block.timestamp + timeLock();

    address[] memory adrValues = new address[](2);
    adrValues[0] = _distributor;
    adrValues[1] = _otherNetworkFund;
    uint256[] memory intValues = new uint256[](1);
    intValues[0] = totalAmount;

    address mintHelper = IController(_controller()).mintHelper();

    _timeLockInfos.push(TimeLockInfo(opCode, opHash, mintHelper, adrValues, intValues));
    timeLockIndexes[opCode] = _timeLockInfos.length - 1;

    emit MintAnnounced(totalAmount, _distributor, _otherNetworkFund);
  }

  /// @notice Only Governance can do it. Announce Batch Proxy upgrade
  /// @param _contracts Array of Proxy contract addresses for upgrade
  /// @param _implementations Array of New implementation addresses
  function announceTetuProxyUpgradeBatch(address[] calldata _contracts, address[] calldata _implementations)
  external onlyGovernance {
    require(_contracts.length == _implementations.length, "wrong arrays");
    for (uint256 i = 0; i < _contracts.length; i++) {
      announceTetuProxyUpgrade(_contracts[i], _implementations[i]);
    }
  }

  /// @notice Only Governance can do it. Announce Proxy upgrade. You will able to mint after Time-lock period
  /// @param _contract Proxy contract address for upgrade
  /// @param _implementation New implementation address
  function announceTetuProxyUpgrade(address _contract, address _implementation) public onlyGovernance {
    TimeLockOpCodes opCode = TimeLockOpCodes.TetuProxyUpdate;

    require(multiTimeLockIndexes[opCode][_contract] == 0, "already announced");
    require(_contract != address(0), "zero contract");
    require(_implementation != address(0), "zero implementation");

    bytes32 opHash = keccak256(abi.encode(opCode, _contract, _implementation));
    timeLockSchedule[opHash] = block.timestamp + timeLock();

    address[] memory values = new address[](1);
    values[0] = _implementation;
    _timeLockInfos.push(TimeLockInfo(opCode, opHash, _contract, values, new uint256[](0)));
    multiTimeLockIndexes[opCode][_contract] = (_timeLockInfos.length - 1);

    emit ProxyUpgradeAnnounced(_contract, _implementation);
  }

  /// @notice Only Governance can do it. Announce strategy update for given vaults
  /// @param _targets Vault addresses
  /// @param _strategies Strategy addresses
  function announceStrategyUpgrades(address[] calldata _targets, address[] calldata _strategies) external onlyGovernance {
    TimeLockOpCodes opCode = TimeLockOpCodes.StrategyUpgrade;
    require(_targets.length == _strategies.length, "wrong arrays");
    for (uint256 i = 0; i < _targets.length; i++) {
      require(multiTimeLockIndexes[opCode][_targets[i]] == 0, "already announced");
      bytes32 opHash = keccak256(abi.encode(opCode, _targets[i], _strategies[i]));
      timeLockSchedule[opHash] = block.timestamp + timeLock();

      address[] memory values = new address[](1);
      values[0] = _strategies[i];
      _timeLockInfos.push(TimeLockInfo(opCode, opHash, _targets[i], values, new uint256[](0)));
      multiTimeLockIndexes[opCode][_targets[i]] = (_timeLockInfos.length - 1);

      emit StrategyUpgradeAnnounced(_targets[i], _strategies[i]);
    }
  }

  /// @notice Only Governance can do it. Announce the stop vault action
  /// @param _vaults Vault addresses
  function announceVaultStopBatch(address[] calldata _vaults) external onlyGovernance {
    TimeLockOpCodes opCode = TimeLockOpCodes.VaultStop;
    for (uint256 i = 0; i < _vaults.length; i++) {
      require(multiTimeLockIndexes[opCode][_vaults[i]] == 0, "already announced");
      bytes32 opHash = keccak256(abi.encode(opCode, _vaults[i]));
      timeLockSchedule[opHash] = block.timestamp + timeLock();

      _timeLockInfos.push(TimeLockInfo(opCode, opHash, _vaults[i], new address[](0), new uint256[](0)));
      multiTimeLockIndexes[opCode][_vaults[i]] = (_timeLockInfos.length - 1);

      emit VaultStop(_vaults[i]);
    }
  }

  /// @notice Close any announce. Use in emergency case.
  /// @param opCode TimeLockOpCodes uint8 value
  /// @param opHash keccak256(abi.encode()) code with attributes.
  /// @param target Address for multi time lock. Set zero address if not required.
  function closeAnnounce(TimeLockOpCodes opCode, bytes32 opHash, address target) external onlyGovernance {
    clearAnnounce(opHash, opCode, target);
    emit AnnounceClosed(opHash);
  }

  /// @notice Only controller can use it. Clear announce after successful call time-locked function
  /// @param opHash Generated keccak256 opHash
  /// @param opCode TimeLockOpCodes uint8 value
  function clearAnnounce(bytes32 opHash, TimeLockOpCodes opCode, address target) public override onlyControlMembers {
    timeLockSchedule[opHash] = 0;
    if (multiTimeLockIndexes[opCode][target] != 0) {
      multiTimeLockIndexes[opCode][target] = 0;
    } else {
      timeLockIndexes[opCode] = 0;
    }
  }

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../../openzeppelin/Initializable.sol";
import "../interface/IControllable.sol";
import "../interface/IControllableExtended.sol";
import "../interface/IController.sol";

/// @title Implement basic functionality for any contract that require strict control
///        V2 is optimised version for less gas consumption
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract ControllableV2 is Initializable, IControllable, IControllableExtended {

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param __controller Controller address
  function initializeControllable(address __controller) public initializer {
    _setController(__controller);
    _setCreated(block.timestamp);
    _setCreatedBlock(block.number);
    emit ContractInitialized(__controller, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) external override view returns (bool) {
    return _isController(_value);
  }

  function _isController(address _value) internal view returns (bool) {
    return _value == _controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) external override view returns (bool) {
    return _isGovernance(_value);
  }

  function _isGovernance(address _value) internal view returns (bool) {
    return IController(_controller()).governance() == _value;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() external view override returns (address) {
    return _controller();
  }

  function _controller() internal view returns (address result) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  function _setController(address _newController) private {
    require(_newController != address(0));
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view override returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _value block.timestamp
  function _setCreated(uint256 _value) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _value)
    }
  }

  /// @notice Return creation block number
  /// @return ts Creation block number
  function createdBlock() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_BLOCK_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _value block.number
  function _setCreatedBlock(uint256 _value) private {
    bytes32 slot = _CREATED_BLOCK_SLOT;
    assembly {
      sstore(slot, _value)
    }
  }

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../interface/IController.sol";
import "../../openzeppelin/Initializable.sol";

/// @title Eternal storage + getters and setters pattern
/// @dev If a key value is changed it will be required to setup it again.
/// @author belbix
abstract contract ControllerStorage is Initializable, IController {

  // don't change names or ordering!
  mapping(bytes32 => uint256) private uintStorage;
  mapping(bytes32 => address) private addressStorage;

  /// @notice Address changed the variable with `name`
  event UpdatedAddressSlot(string indexed name, address oldValue, address newValue);
  /// @notice Value changed the variable with `name`
  event UpdatedUint256Slot(string indexed name, uint256 oldValue, uint256 newValue);

  /// @notice Initialize contract after setup it as proxy implementation
  /// @dev Use it only once after first logic setup
  /// @param __governance Governance address
  function initializeControllerStorage(
    address __governance
  ) public initializer {
    _setGovernance(__governance);
  }

  // ******************* SETTERS AND GETTERS **********************

  // ----------- ADDRESSES ----------
  function _setGovernance(address _address) internal {
    emit UpdatedAddressSlot("governance", _governance(), _address);
    setAddress("governance", _address);
  }

  /// @notice Return governance address
  /// @return Governance address
  function governance() external override view returns (address) {
    return _governance();
  }

  function _governance() internal view returns (address) {
    return getAddress("governance");
  }

  function _setDao(address _address) internal {
    emit UpdatedAddressSlot("dao", _dao(), _address);
    setAddress("dao", _address);
  }

  /// @notice Return DAO address
  /// @return DAO address
  function dao() external override view returns (address) {
    return _dao();
  }

  function _dao() internal view returns (address) {
    return getAddress("dao");
  }

  function _setFeeRewardForwarder(address _address) internal {
    emit UpdatedAddressSlot("feeRewardForwarder", feeRewardForwarder(), _address);
    setAddress("feeRewardForwarder", _address);
  }

  /// @notice Return FeeRewardForwarder address
  /// @return FeeRewardForwarder address
  function feeRewardForwarder() public override view returns (address) {
    return getAddress("feeRewardForwarder");
  }

  function _setBookkeeper(address _address) internal {
    emit UpdatedAddressSlot("bookkeeper", _bookkeeper(), _address);
    setAddress("bookkeeper", _address);
  }

  /// @notice Return Bookkeeper address
  /// @return Bookkeeper address
  function bookkeeper() external override view returns (address) {
    return _bookkeeper();
  }

  function _bookkeeper() internal view returns (address) {
    return getAddress("bookkeeper");
  }

  function _setMintHelper(address _address) internal {
    emit UpdatedAddressSlot("mintHelper", mintHelper(), _address);
    setAddress("mintHelper", _address);
  }

  /// @notice Return MintHelper address
  /// @return MintHelper address
  function mintHelper() public override view returns (address) {
    return getAddress("mintHelper");
  }

  function _setRewardToken(address _address) internal {
    emit UpdatedAddressSlot("rewardToken", rewardToken(), _address);
    setAddress("rewardToken", _address);
  }

  /// @notice Return TETU address
  /// @return TETU address
  function rewardToken() public override view returns (address) {
    return getAddress("rewardToken");
  }

  function _setFundToken(address _address) internal {
    emit UpdatedAddressSlot("fundToken", fundToken(), _address);
    setAddress("fundToken", _address);
  }

  /// @notice Return a token address used for FundKeeper
  /// @return FundKeeper's main token address
  function fundToken() public override view returns (address) {
    return getAddress("fundToken");
  }

  function _setPsVault(address _address) internal {
    emit UpdatedAddressSlot("psVault", psVault(), _address);
    setAddress("psVault", _address);
  }

  /// @notice Return Profit Sharing pool address
  /// @return Profit Sharing pool address
  function psVault() public override view returns (address) {
    return getAddress("psVault");
  }

  function _setFund(address _address) internal {
    emit UpdatedAddressSlot("fund", fund(), _address);
    setAddress("fund", _address);
  }

  /// @notice Return FundKeeper address
  /// @return FundKeeper address
  function fund() public override view returns (address) {
    return getAddress("fund");
  }

  function _setDistributor(address _address) internal {
    emit UpdatedAddressSlot("distributor", distributor(), _address);
    setAddress("distributor", _address);
  }

  /// @notice Return Reward distributor address
  /// @return Distributor address
  function distributor() public override view returns (address) {
    return getAddress("distributor");
  }

  function _setAnnouncer(address _address) internal {
    emit UpdatedAddressSlot("announcer", _announcer(), _address);
    setAddress("announcer", _address);
  }

  /// @notice Return Announcer address
  /// @return Announcer address
  function announcer() external override view returns (address) {
    return _announcer();
  }

  function _announcer() internal view returns (address) {
    return getAddress("announcer");
  }

  function _setVaultController(address _address) internal {
    emit UpdatedAddressSlot("vaultController", vaultController(), _address);
    setAddress("vaultController", _address);
  }

  /// @notice Return FundKeeper address
  /// @return FundKeeper address
  function vaultController() public override view returns (address) {
    return getAddress("vaultController");
  }

  // ----------- INTEGERS ----------
  function _setPsNumerator(uint256 _value) internal {
    emit UpdatedUint256Slot("psNumerator", psNumerator(), _value);
    setUint256("psNumerator", _value);
  }

  /// @notice Return Profit Sharing pool ratio's numerator
  /// @return Profit Sharing pool ratio numerator
  function psNumerator() public view override returns (uint256) {
    return getUint256("psNumerator");
  }

  function _setPsDenominator(uint256 _value) internal {
    emit UpdatedUint256Slot("psDenominator", psDenominator(), _value);
    setUint256("psDenominator", _value);
  }

  /// @notice Return Profit Sharing pool ratio's denominator
  /// @return Profit Sharing pool ratio denominator
  function psDenominator() public view override returns (uint256) {
    return getUint256("psDenominator");
  }

  function _setFundNumerator(uint256 _value) internal {
    emit UpdatedUint256Slot("fundNumerator", fundNumerator(), _value);
    setUint256("fundNumerator", _value);
  }

  /// @notice Return FundKeeper ratio's numerator
  /// @return FundKeeper ratio numerator
  function fundNumerator() public view override returns (uint256) {
    return getUint256("fundNumerator");
  }

  function _setFundDenominator(uint256 _value) internal {
    emit UpdatedUint256Slot("fundDenominator", fundDenominator(), _value);
    setUint256("fundDenominator", _value);
  }

  /// @notice Return FundKeeper ratio's denominator
  /// @return FundKeeper ratio denominator
  function fundDenominator() public view override returns (uint256) {
    return getUint256("fundDenominator");
  }

  // ******************** STORAGE INTERNAL FUNCTIONS ********************

  function setAddress(string memory key, address _address) private {
    addressStorage[keccak256(abi.encodePacked(key))] = _address;
  }

  function getAddress(string memory key) private view returns (address) {
    return addressStorage[keccak256(abi.encodePacked(key))];
  }

  function setUint256(string memory key, uint256 _value) private {
    uintStorage[keccak256(abi.encodePacked(key))] = _value;
  }

  function getUint256(string memory key) private view returns (uint256) {
    return uintStorage[keccak256(abi.encodePacked(key))];
  }

  //slither-disable-next-line unused-state
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IAnnouncer {

  /// @dev Time lock operation codes
  enum TimeLockOpCodes {
    // TimeLockedAddresses
    Governance, // 0
    Dao, // 1
    FeeRewardForwarder, // 2
    Bookkeeper, // 3
    MintHelper, // 4
    RewardToken, // 5
    FundToken, // 6
    PsVault, // 7
    Fund, // 8
    // TimeLockedRatios
    PsRatio, // 9
    FundRatio, // 10
    // TimeLockedTokenMoves
    ControllerTokenMove, // 11
    StrategyTokenMove, // 12
    FundTokenMove, // 13
    // Other
    TetuProxyUpdate, // 14
    StrategyUpgrade, // 15
    Mint, // 16
    Announcer, // 17
    ZeroPlaceholder, //18
    VaultController, //19
    RewardBoostDuration, //20
    RewardRatioWithoutBoost, //21
    VaultStop //22
  }

  /// @dev Holder for human readable info
  struct TimeLockInfo {
    TimeLockOpCodes opCode;
    bytes32 opHash;
    address target;
    address[] adrValues;
    uint256[] numValues;
  }

  function clearAnnounce(bytes32 opHash, TimeLockOpCodes opCode, address target) external;

  function timeLockSchedule(bytes32 opHash) external returns (uint256);

  function timeLockInfo(uint256 idx) external returns (TimeLockInfo memory);

  // ************ DAO ACTIONS *************
  function announceRatioChange(TimeLockOpCodes opCode, uint256 numerator, uint256 denominator) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    require(_initializing || !_initialized, "Initializable: contract is already initialized");

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @dev This interface contains additional functions for Controllable class
///      Don't extend the exist Controllable for the reason of huge coherence
interface IControllableExtended {

  function created() external view returns (uint256 ts);

  function controller() external view returns (address adr);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IController {

  function addVaultsAndStrategies(address[] memory _vaults, address[] memory _strategies) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function dao() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function fundToken() external view returns (address);

  function psVault() external view returns (address);

  function fund() external view returns (address);

  function distributor() external view returns (address);

  function announcer() external view returns (address);

  function vaultController() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function fundNumerator() external view returns (uint256);

  function fundDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  function rebalance(address _strategy) external;

  // ************ DAO ACTIONS *************
  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function changeWhiteListStatus(address[] calldata _targets, bool status) external;
}