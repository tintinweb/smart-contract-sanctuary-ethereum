// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { AdminAgent } from "./access/AdminAgent.sol";
import { IRegistrarClient } from "./RegistrarClient.sol";
import { VYToken } from "./token/VYToken.sol";

contract Registrar is AdminAgent {

  bytes32 private constant ECOSYSTEM_ID = keccak256(bytes("VY_ETH"));

  address[] private _contracts;
  address[] private _prevContracts;
  bool private _finalized;

  event SetContracts(address[] addresses);
  event SetContractByIndex(uint8 index, address contractAddressTo);
  event Finalize(address registrarAddress);

  enum Contract {
    VYToken,
    VETHYieldRateTreasury,
    VETHP2P,
    VETHRevenueCycleTreasury,
    VETHGovernance,
    VETHReverseStakingTreasury
  }

  /**
   * @dev Constructor that setup the owner of this contract.
   */
  constructor(address[] memory adminAgents) AdminAgent(adminAgents) {
    _prevContracts = new address[](_numbersOfContracts());
  }

  modifier onlyUnfinalized() {
    require(_finalized == false, "Registrar already finalized");
    _;
  }

  modifier onlyValidContractIndex(uint256 index) {
    require(index < _numbersOfContracts(), "Invalid index");
    _;
  }

  function getEcosystemId() external pure virtual returns (bytes32) {
    return ECOSYSTEM_ID;
  }

  function getContracts() external view returns (address[] memory) {
    return _contracts;
  }

  function getContractByIndex(
    uint256 index
  ) external view onlyValidContractIndex(index) returns (address) {
    return _contracts[index];
  }

  function getPrevContractByIndex(
    uint256 index
  ) external view onlyValidContractIndex(index) returns (address) {
    return _prevContracts[index];
  }

  function setContracts(address[] calldata _addresses) external onlyAdminAgents onlyUnfinalized {
    require(_validContractsLength(_addresses.length), "Invalid number of addresses");

    // Loop through and update _prevContracts entries only if those addresses are new.
    // For example, assume _prevContracts[0] = 0xABC and contracts[i] = 0xF00
    // If _addresses[i] = 0xF00 and we didn't perform the check below, then we would overwrite the old
    // 0xABC with 0xF00, thereby losing whatever actual previous contract address that was.
    for (uint i = 0; i < _contracts.length; i++) {
      if (_addresses[i] != _contracts[i]) {
        _prevContracts[i] = _contracts[i];
      }
    }

    _contracts = _addresses;

    emit SetContracts(_addresses);
  }

  function setContractByIndex(uint8 _index, address _address) external onlyAdminAgents onlyUnfinalized {
    if (_address != _contracts[_index]) {
      _prevContracts[_index] = _contracts[_index];
    }

    _contracts[_index] = _address;

    emit SetContractByIndex(_index, _address);
  }

  function updateAllClients() external onlyAdminAgents onlyUnfinalized {
    VYToken(this.getVYToken()).setMinter();
    IRegistrarClient(this.getVETHP2P()).updateAddresses();
    IRegistrarClient(this.getVETHRevenueCycleTreasury()).updateAddresses();
    IRegistrarClient(this.getVETHReverseStakingTreasury()).updateAddresses();
    IRegistrarClient(this.getVETHYieldRateTreasury()).updateAddresses();
    IRegistrarClient(this.getVETHGovernance()).updateAddresses();
  }

  function getVYToken() external view returns (address) {
    return _contracts[uint(Contract.VYToken)];
  }

  function getVETHYieldRateTreasury() external view returns (address) {
    return _contracts[uint(Contract.VETHYieldRateTreasury)];
  }

  function getVETHP2P() external view returns (address) {
    return _contracts[uint(Contract.VETHP2P)];
  }

  function getVETHRevenueCycleTreasury() external view returns (address) {
    return _contracts[uint(Contract.VETHRevenueCycleTreasury)];
  }

  function getVETHGovernance() external view returns (address) {
    return _contracts[uint(Contract.VETHGovernance)];
  }

  function getVETHReverseStakingTreasury() external view returns (address) {
    return _contracts[uint(Contract.VETHReverseStakingTreasury)];
  }

  function finalize() external onlyAdminAgents onlyUnfinalized {
    _finalized = true;
    emit Finalize(address(this));
  }

  function isFinalized() external view returns (bool) {
    return _finalized;
  }

  function _numbersOfContracts() private pure returns (uint256) {
    return uint(Contract.VETHReverseStakingTreasury) + 1;
  }

  function _validContractsLength(uint256 contractsLength) private pure returns (bool) {
    return contractsLength == _numbersOfContracts();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Context } from "./lib/utils/Context.sol";
import { Registrar } from "./Registrar.sol";

interface IRegistrarClient {
  function updateAddresses() external;
}

abstract contract RegistrarClient is Context, IRegistrarClient {

  Registrar internal _registrar;

  constructor(address registrarAddress) {
    require(registrarAddress != address(0), "Invalid address");
    _registrar = Registrar(registrarAddress);
  }

  modifier onlyRegistrar() {
    require(_msgSender() == address(_registrar), "Unauthorized, registrar only");
    _;
  }

  function getRegistrar() external view returns(address) {
    return address(_registrar);
  }

  // All subclasses must implement this function
  function updateAddresses() external override virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Registrar } from "./Registrar.sol";
import { AdminAgent } from "./access/AdminAgent.sol";
import { VYToken } from "./token/VYToken.sol";

abstract contract RegistrarMigrator is AdminAgent {

  Registrar private _registrar;
  uint256 private _contractIndex;

  constructor(
    address registrarAddress,
    uint256 contractIndex,
    address[] memory adminAgents
  ) AdminAgent(adminAgents) {
    require(registrarAddress != address(0), "Invalid address");

    _registrar = Registrar(registrarAddress);
    _contractIndex = contractIndex;
  }

  modifier onlyUnfinalized() {
    require(_registrar.isFinalized() == false, "Registrar already finalized");
    _;
  }

  function registrarMigrateTokens() external onlyAdminAgents onlyUnfinalized {
    VYToken vyToken = VYToken(_registrar.getVYToken());
    vyToken.registrarMigrateTokens(_registrar.getEcosystemId(), _contractIndex);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { OwnableUpgradeable } from "./lib/openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "./lib/openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "./lib/openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Router is Initializable, OwnableUpgradeable, UUPSUpgradeable {

  address private _primaryStakeholder;

  event Route(address indexed receiver, uint256 amount);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address primaryStakeholder_) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
    _primaryStakeholder = primaryStakeholder_;
  }

  function route() external payable {
    _routePrimaryStakeholder(msg.value);
  }

  function _routePrimaryStakeholder(uint256 amount) private {
    (bool sent,) = _primaryStakeholder.call{value: amount}("");
    require(sent, "Failed to send Ether");

    emit Route(_primaryStakeholder, amount);
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
  {}

  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { BackendAgent } from "./access/BackendAgent.sol";
import { VYToken } from "./token/VYToken.sol";
import { VETHP2P } from "./exchange/VETHP2P.sol";
import { VETHRevenueCycleTreasury } from "./exchange/VETHRevenueCycleTreasury.sol";
import { VETHYieldRateTreasury } from "./treasury/VETHYieldRateTreasury.sol";
import { RegistrarClient } from "./RegistrarClient.sol";
import { AdminGovernanceAgent } from "./access/AdminGovernanceAgent.sol";
import { Governable } from "./governance/Governable.sol";
import { RegistrarMigrator } from "./RegistrarMigrator.sol";
import { Registrar } from "./Registrar.sol";
import { Router } from "./Router.sol";

contract VETHReverseStakingTreasury is BackendAgent, RegistrarClient, RegistrarMigrator, AdminGovernanceAgent, Governable {

  uint256 private constant MINIMUM_REVERSE_STAKE_AUTOCLOSE = 100000000; // 0.1 gwei
  uint256 private constant MULTIPLIER = 10**18;
  uint256 private constant DAY_IN_SECONDS = 86400;
  bytes private constant ROUTE_SELECTOR = abi.encode(bytes4(keccak256("route()")));

  // We use this to get around stack too deep errors.
  struct TradeOfferVars {
    uint256 maxInput;
    uint256 ethFee;
    uint256 vyFee;
    uint256 vyOut;
  }

  struct CalcOfferRepayment {
    uint256 effectiveETHPaidOff;
    uint256 excessETH;
    uint256 excessStakedVY;
    uint256 vyToBurn;
    bool isPaidOff;
  }

  struct RestakeVars {
    uint256 newReverseStakeVY;
    uint256 newReverseStakeClaimedYieldETH;
    uint256 newReverseStakeId;
    uint256 startAt;
    uint256 endAt;
    uint256 vyToBurn;
    uint256 processingFeeETH;
    uint256 yieldPayout;
    uint256[] reverseStakeIds;
    uint256 vyYieldRate;
  }

  struct MigrateReverseStakeVars {
    address borrowerAddress;
    uint256 stakedVY;
    uint256 originalClaimedYieldETH;
    uint256 currentClaimedYieldETH;
    uint256 yieldRate;
    uint256 startAt;
    uint256 endAt;
    uint256 lastPaidAt;
    uint256 previousReverseStakeId;
    uint256 termId;
  }

  uint256 public constant ETH_FEE = 20000000000000000;
  uint256 public constant VY_FEE = 20000000000000000;
  /// @dev 1.020409; Buffer to account for fee
  uint256 public constant OFFER_PRICE_YR_RATIO = 1020409000000000000;
  /// @dev 0.98; 2% left over to account for burn rate over lifespan of offer
  uint256 public constant OFFER_NET_STAKE_RATIO = 980000000000000000;
  uint256 public constant EXPIRES_IN = 30 days;
  uint256 public constant MINIMUM_OFFER_AUTOCLOSE_IN_ETH = 500000000000000; // 0.0005 ETH
  uint256 public constant MAX_RESTAKE_REVERSE_STAKES = 20;

  enum DataTypes {
    VY,
    PERCENTAGE
  }

  VETHP2P private _vethP2P;
  VETHRevenueCycleTreasury private _vethRevenueCycleTreasury;
  VYToken private _vyToken;
  VETHYieldRateTreasury private _vethYRT;
  Router private _ethComptroller;
  address private _migration;
  uint256 private _reverseStakeTermsNonce = 0;
  uint256 private _reverseStakesNonce = 0;
  uint256 private _totalClaimedYieldETH = 0;
  uint256 private _maxReverseStakes = 20;
  bool private _reverseStakeExtendable = true;

  // This contains the mutable reverse stake terms
  struct ReverseStakeTerm {
    uint256 dailyBurnRate;
    uint256 durationInDays;
    uint256 minimumReverseStakeETH;
    uint256 processingFeePercentage;
    uint256 extensionMinimumRemainingStake;
    DataTypes extensionMinimumRemainingStakeType;
    uint256 restakeMinimumPayout;
  }

  // This contains reverseStake info per user
  struct ReverseStake {
    uint256 termId;
    uint256 stakedVY;
    uint256 originalClaimedYieldETH;
    uint256 currentClaimedYieldETH;
    uint256 yieldRate;
    uint256 startAt;
    uint256 endAt;
    uint256 lastPaidAt;
  }

  struct Offer {
    uint256 unfilledQuantity;
    uint256 price;
    uint256 maxClaimedYieldETH;  // ClaimedYield at the time offer is created
    uint256 maxQuantity;      // Max quantity at the time offer is created
    uint256 expiresAt;
    bool isOpen;
  }

  mapping(uint256 => ReverseStakeTerm) private _reverseStakeTerms;
  mapping(address => mapping(uint256 => ReverseStake)) private _reverseStakes;
  mapping(address => uint256) private _openReverseStakes;
  mapping(address => mapping(uint256 => Offer)) private _offers;

  event CreateReverseStakeTerm(
    uint256 termId,
    uint256 dailyBurnRate,
    uint256 durationInDays,
    uint256 minimumReverseStakeETH,
    uint256 processingFeePercentage,
    uint256 extensionMinimumRemainingStake,
    DataTypes extensionMinimumRemainingStakeType,
    uint256 restakeMinimumPayout);
  event CreateReverseStake(
    address borrower,
    uint256 reverseStakeId,
    uint256 termId,
    uint256 stakedVY,
    uint256 originalClaimedYieldETH,
    uint256 currentClaimedYieldETH,
    uint256 yieldRate,
    uint256 startAt,
    uint256 endAt);

  event ReturnETHToUnstake(
    address borrower,
    uint256 reverseStakeId,
    uint256 ethAmount,
    uint256 currentClaimedYieldETH,
    uint256 stakedVY,
    uint256 stakedVYReturned,
    uint256 burnRatePaid,
    uint256 paidAt
  );
  event MigrateReverseStake(
    address borrower,
    uint256 reverseStakeId,
    uint256 termId,
    uint256 stakedVY,
    uint256 originalClaimedYieldETH,
    uint256 currentClaimedYieldETH,
    uint256 yieldRate,
    uint256 startAt,
    uint256 endAt,
    uint256 previousReverseStakeId
  );
  event ExtendReverseStake(address borrower, uint256 reverseStakeId, uint256 endAt, uint256 burnRatePaid);
  event CloseReverseStake(address borrower, uint256 reverseStakeId, uint256 stakeTransferred);
  event CreateOffer(address borrower, uint256 reverseStakeId, uint256 quantity, uint256 price, uint256 expiresAt, uint256 timestamp);
  event TradeOffer(
    address borrower,
    uint256 reverseStakeId,
    address buyer,
    uint256 sellerQuantity,
    uint256 buyerQuantity,
    uint256 unfilledQuantity,
    uint256 excessETH,
    uint256 timestamp
  );
  event CloseOffer(address borrower, uint256 reverseStakeId, uint256 timestamp);
  event Restake(
    address borrower,
    uint256 reverseStakeId,
    uint256 termId,
    uint256 stakedVY,
    uint256 originalClaimedYieldETH,
    uint256 currentClaimedYieldETH,
    uint256 yieldRate,
    uint256 startAt,
    uint256 endAt,
    uint256 yieldPayout,
    uint256[] previousReverseStakeIds,
    uint256 burnRatePaid
  );

  constructor(
    address registrarAddress,
    address ethComptrollerAddress_,
    address[] memory adminGovAgents,
    address[] memory backendAdminAgents,
    address[] memory backendAgents,
    address[] memory adminAgents
  ) RegistrarClient(registrarAddress)
    RegistrarMigrator(registrarAddress, uint(Registrar.Contract.VETHReverseStakingTreasury), adminAgents)
    AdminGovernanceAgent(adminGovAgents) {
    require(ethComptrollerAddress_ != address(0), "Invalid address");

    _ethComptroller = Router(payable(ethComptrollerAddress_));
    _setBackendAdminAgents(backendAdminAgents);
    _setBackendAgents(backendAgents);
  }

  modifier onlyActiveReverseStake(address borrower, uint256 reverseStakeId) {
    _checkValidReverseStake(_reverseStakes[borrower][reverseStakeId].startAt > 0);
    _checkActiveReverseStake(isReverseStakeActive(borrower, reverseStakeId));
    _;
  }

  modifier onlyActiveOffer(address borrower, uint256 reverseStakeId) {
    require(_offers[borrower][reverseStakeId].isOpen && _offers[borrower][reverseStakeId].expiresAt > block.timestamp, "Invalid offer");
    _;
  }

  modifier onlyOpenOffer(uint256 id, address borrower) {
    require(_offers[borrower][id].isOpen, "Offer must be open in order to close");
    _;
  }

  function setupInitialReverseStakeTerm(
    uint256 dailyBurnRate,
    uint256 durationInDays,
    uint256 minimumReverseStakeETH,
    uint256 processingFeePercentage,
    uint256 extensionMinimumRemainingStake,
    DataTypes extensionMinimumRemainingStakeType,
    uint256 restakeMinimumPayout
  ) external onlyBackendAdminAgents {
    require(_reverseStakeTermsNonce == 0, "Reverse stake terms already set up");
    _createNewReverseStakeTerm(
      dailyBurnRate,
      durationInDays,
      minimumReverseStakeETH,
      processingFeePercentage,
      extensionMinimumRemainingStake,
      extensionMinimumRemainingStakeType,
      restakeMinimumPayout
    );
  }

  function createNewReverseStakeTerm(
    uint256 dailyBurnRate,
    uint256 durationInDays,
    uint256 minimumReverseStakeETH,
    uint256 processingFeePercentage,
    uint256 extensionMinimumRemainingStake,
    DataTypes extensionMinimumRemainingStakeType,
    uint256 restakeMinimumPayout
  ) external onlyBackendAdminAgents {
    _createNewReverseStakeTerm(
      dailyBurnRate,
      durationInDays,
      minimumReverseStakeETH,
      processingFeePercentage,
      extensionMinimumRemainingStake,
      extensionMinimumRemainingStakeType,
      restakeMinimumPayout
    );
  }

  /**
   * @dev Returns total claimed yield in ETH
   */
  function getTotalClaimedYield() external view returns (uint256) {
    return _totalClaimedYieldETH;
  }

  function getReverseStake(address borrower, uint256 reverseStakeId) external view returns (ReverseStake memory) {
    return _reverseStakes[borrower][reverseStakeId];
  }

  function isReverseStakeActive(address borrower, uint256 reverseStakeId) public view returns (bool) {
    return !_isReverseStakeExpired(borrower, reverseStakeId) && _reverseStakes[borrower][reverseStakeId].currentClaimedYieldETH > 0;
  }

  function getReverseStakeTerm(uint256 termId) external view returns (ReverseStakeTerm memory) {
    return _reverseStakeTerms[termId];
  }

  function getCurrentReverseStakeTerm() external view returns (ReverseStakeTerm memory) {
    return _reverseStakeTerms[_reverseStakeTermsNonce];
  }

  function getCurrentReverseStakeTermId() external view returns (uint256) {
    return _reverseStakeTermsNonce;
  }

  function ethToBurn(address borrower, uint256 reverseStakeId) external view returns (uint256) {
    return _ethToBurn(borrower, reverseStakeId);
  }

  function vyToBurn(address borrower, uint256 reverseStakeId) external view returns (uint256) {
    return _vyToBurn(borrower, reverseStakeId);
  }

  function getStakedVYForReverseStakeETH(uint256 ethAmount) external view returns (uint256) {
    return _getStakedVYForReverseStakeETH(ethAmount);
  }

  function getMaxReverseStakes() external view returns (uint256) {
    return _maxReverseStakes;
  }

  function getReverseStakesNonce() external view returns (uint256) {
    return _reverseStakesNonce;
  }

  function setMaxReverseStakes(uint256 maxReverseStakes_) external onlyBackendAdminAgents {
    _maxReverseStakes = maxReverseStakes_;
  }

  function isReverseStakeExtendable() external view returns (bool) {
    return _reverseStakeExtendable;
  }

  function toggleReverseStakeExtension(bool enabled) external onlyAdminGovAgents {
    _reverseStakeExtendable = enabled;
  }

  function getMigration() external view returns (address) {
    return _migration;
  }

  function setMigration(address destination) external onlyGovernance {
    _migration = destination;
  }

  function transferMigration(uint256 amount) external onlyAdminGovAgents {
    require(_migration != address(0), "Migration not set");
    _checkSufficientBalance(_vyToken.balanceOf(address(this)) >= amount);
    _transferVY(_migration, amount);
  }

  function createReverseStake(uint256 termId, uint256 ethAmount, uint256 vyAmount) external {
    require(_vyToken.allowance(_msgSender(), address(this)) >= vyAmount, "Insufficient allowance");
    require(_vyToken.balanceOf(_msgSender()) >= vyAmount, "Insufficient balance");
    uint256 minStake = _createReverseStakePrerequisite(termId, ethAmount, vyAmount);

    _createReverseStake(ethAmount, minStake);
  }

  function createReverseStake(uint256 termId, uint256 ethAmount, uint256 vyAmount, uint8 v, bytes32 r, bytes32 s) external {
    uint256 minStake = _createReverseStakePrerequisite(termId, ethAmount, vyAmount);

    // Call approval
    _vyToken.permit(_msgSender(), address(this), vyAmount, v, r, s);
    _createReverseStake(ethAmount, minStake);
  }

  function _createReverseStake(uint256 ethAmount, uint256 stakedVY) private {
    ReverseStakeTerm memory reverseStakeTerm = _reverseStakeTerms[_reverseStakeTermsNonce];
    require(ethAmount >= reverseStakeTerm.minimumReverseStakeETH, "Minimum reverse stake ETH not met");

    uint256 reverseStakeId = ++_reverseStakesNonce;
    uint256 ethComptrollerReceives = ethAmount * reverseStakeTerm.processingFeePercentage / MULTIPLIER;
    uint256 borrowerReceives = ethAmount - ethComptrollerReceives;
    uint256 startAt = block.timestamp;
    uint256 endAt = startAt + reverseStakeTerm.durationInDays * DAY_IN_SECONDS;
    uint256 vyYieldRate = _vethRevenueCycleTreasury.getYieldRate();

    _reverseStakes[_msgSender()][reverseStakeId] = ReverseStake(_reverseStakeTermsNonce, stakedVY, ethAmount, ethAmount, vyYieldRate, startAt, endAt, 0);
    _openReverseStakes[_msgSender()]++;

    _totalClaimedYieldETH += ethAmount;
    _vyToken.transferFrom(_msgSender(), address(this), stakedVY);
    _vethYRT.reverseStakingTransfer(_msgSender(), borrowerReceives);
    _vethYRT.reverseStakingRoute(address(_ethComptroller), ethComptrollerReceives, ROUTE_SELECTOR);

    emit CreateReverseStake(_msgSender(), reverseStakeId, _reverseStakeTermsNonce, stakedVY, ethAmount, ethAmount, vyYieldRate, startAt, endAt);
  }

  function returnETHToUnstake(uint256 reverseStakeId) external payable onlyActiveReverseStake(_msgSender(), reverseStakeId) {
    require(msg.value > 0, "Zero ETH amount sent");
    _checkActiveOffer(_offers[_msgSender()][reverseStakeId].isOpen);

    ReverseStake storage reverseStake = _reverseStakes[_msgSender()][reverseStakeId];
    uint256 vyToBurn_ = _vyToBurn(_msgSender(), reverseStakeId);
    require(reverseStake.stakedVY >= vyToBurn_, "Not enough staked VY to burn");
    reverseStake.stakedVY -= vyToBurn_;

    uint256 excessETH = 0;
    uint256 stakedVYReturned = 0;
    uint256 ethAmount = msg.value;

    if (ethAmount > reverseStake.currentClaimedYieldETH) {
      excessETH = ethAmount - reverseStake.currentClaimedYieldETH;
      ethAmount = reverseStake.currentClaimedYieldETH;
    }

    if (reverseStake.currentClaimedYieldETH == ethAmount) {
      stakedVYReturned = reverseStake.stakedVY;
      _decrementOpenReverseStakesAndCloseOffer(_msgSender(), reverseStakeId, 0);
    } else {
      stakedVYReturned = reverseStake.stakedVY * ethAmount / reverseStake.currentClaimedYieldETH;
    }

    reverseStake.currentClaimedYieldETH -= ethAmount;
    reverseStake.stakedVY -= stakedVYReturned;
    reverseStake.lastPaidAt = block.timestamp;

    _totalClaimedYieldETH -= ethAmount;
    _transferToRevenueCycleTreasury(vyToBurn_);
    _transferVY(_msgSender(), stakedVYReturned);

    _transfer(address(_vethYRT), ethAmount);

    if (excessETH > 0) {
      _transfer(_msgSender(), excessETH);
    }

    emit ReturnETHToUnstake(
      _msgSender(),
      reverseStakeId,
      ethAmount,
      reverseStake.currentClaimedYieldETH,
      reverseStake.stakedVY,
      stakedVYReturned,
      vyToBurn_,
      reverseStake.lastPaidAt
    );
  }

  function extendReverseStake(uint256 reverseStakeId) external payable onlyActiveReverseStake(_msgSender(), reverseStakeId) {
    require(_reverseStakeExtendable, "Extend reverse stakes disabled");
    ReverseStake storage reverseStake = _reverseStakes[_msgSender()][reverseStakeId];
    ReverseStakeTerm memory reverseStakeTerm = _reverseStakeTerms[reverseStake.termId];

    uint256 vyToBurn_ = _vyToBurn(_msgSender(), reverseStakeId);
    require(reverseStake.stakedVY >= vyToBurn_, "Not enough staked VY to burn");
    reverseStake.stakedVY -= vyToBurn_;
    uint256 originalStakedVY = reverseStake.originalClaimedYieldETH * reverseStake.yieldRate / MULTIPLIER;
    require(reverseStake.stakedVY >= _getRemainingStakedVYExtensionLimit(reverseStake.termId, originalStakedVY), "Staked VY too low to extend");
    uint256 processingFee = reverseStake.currentClaimedYieldETH * reverseStakeTerm.processingFeePercentage / MULTIPLIER;
    require(msg.value == processingFee, "Invalid ETH amount sent");

    reverseStake.lastPaidAt = block.timestamp;
    reverseStake.endAt = block.timestamp + reverseStakeTerm.durationInDays * DAY_IN_SECONDS;

    _ethComptroller.route{ value: processingFee }();
    _transferToRevenueCycleTreasury(vyToBurn_);

    emit ExtendReverseStake(_msgSender(), reverseStakeId, reverseStake.endAt, vyToBurn_);
  }

  function restake(uint256[] memory reverseStakeIds) external {
    address borrower = _msgSender();
    require(reverseStakeIds.length > 0 && reverseStakeIds.length <= MAX_RESTAKE_REVERSE_STAKES, "Invalid number of reverseStakes");

    uint256 firstReverseStakeTermId;
    uint256 totalCurrentClaimedYieldETH;
    RestakeVars memory reverseStakeData = RestakeVars(0, 0, 0, 0, 0, 0, 0, 0, new uint256[](reverseStakeIds.length), 0);

    // Sum all VYs to burn and principals + close reverseStakes
    for (uint i = 0; i < reverseStakeIds.length; i++) {
      uint256 reverseStakeId = reverseStakeIds[i];
      reverseStakeData.reverseStakeIds[i] = reverseStakeId;

      // Requirements
      _checkValidReverseStake(_reverseStakes[borrower][reverseStakeId].startAt > 0);
      _checkActiveReverseStake(isReverseStakeActive(borrower, reverseStakeId));
      _checkActiveOffer(_offers[borrower][reverseStakeId].isOpen);

      ReverseStake storage reverseStake = _reverseStakes[borrower][reverseStakeId];

      // Check for the same reverse stake term
      if (i == 0) {
        firstReverseStakeTermId = reverseStake.termId;
      } else {
        require(reverseStake.termId == firstReverseStakeTermId, "Reverse stakes must have same reverse stake term");
      }

      // Sum VY to burn
      uint256 vyToBurn_ = _vyToBurn(borrower, reverseStakeId); // Calculate VY to burn
      reverseStakeData.vyToBurn += vyToBurn_;

      // Sum principal after VY to burn
      require(reverseStake.stakedVY >= vyToBurn_, "Not enough staked VY to burn");
      uint256 newReverseStakeVY = reverseStake.stakedVY - vyToBurn_;
      reverseStakeData.newReverseStakeVY += newReverseStakeVY;

      // Close reverseStake
      totalCurrentClaimedYieldETH += reverseStake.currentClaimedYieldETH;
      reverseStake.stakedVY = 0;
      reverseStake.currentClaimedYieldETH = 0;
      if (_openReverseStakes[borrower] > 0) {
        _openReverseStakes[borrower]--;
      }
    }

    // Create new reverseStake
    reverseStakeData.vyYieldRate = _vethRevenueCycleTreasury.getYieldRate();
    reverseStakeData.newReverseStakeClaimedYieldETH = reverseStakeData.newReverseStakeVY * MULTIPLIER / reverseStakeData.vyYieldRate; // Calculate new reverseStake principal
    reverseStakeData.newReverseStakeId = ++_reverseStakesNonce;
    reverseStakeData.startAt = block.timestamp;
    reverseStakeData.endAt = reverseStakeData.startAt + _reverseStakeTerms[firstReverseStakeTermId].durationInDays * DAY_IN_SECONDS;
    _reverseStakes[borrower][reverseStakeData.newReverseStakeId] = ReverseStake(
      firstReverseStakeTermId,                            // termId
      reverseStakeData.newReverseStakeVY,                 // stakedVY
      reverseStakeData.newReverseStakeClaimedYieldETH,    // originalClaimedYieldETH
      reverseStakeData.newReverseStakeClaimedYieldETH,    // currentClaimedYieldETH
      reverseStakeData.vyYieldRate,                       // yieldRate
      reverseStakeData.startAt,                           // startAt
      reverseStakeData.endAt,                             // endAt
      0);                                                 // lastPaidAt
    _openReverseStakes[borrower]++;

    // Update totalClaimedYield
    require(reverseStakeData.newReverseStakeClaimedYieldETH >= totalCurrentClaimedYieldETH, "Restaked reverseStakes must increase in value");
    reverseStakeData.yieldPayout = reverseStakeData.newReverseStakeClaimedYieldETH - totalCurrentClaimedYieldETH;
    _totalClaimedYieldETH += reverseStakeData.yieldPayout;

    // Processing fee
    reverseStakeData.processingFeeETH = reverseStakeData.yieldPayout * _reverseStakeTerms[firstReverseStakeTermId].processingFeePercentage / MULTIPLIER;

    // Yield payout
    require(reverseStakeData.yieldPayout >= _reverseStakeTerms[firstReverseStakeTermId].restakeMinimumPayout, "Minimum yield payout not met");
    reverseStakeData.yieldPayout -= reverseStakeData.processingFeeETH;

    // Transfers
    _vethYRT.reverseStakingTransfer(borrower, reverseStakeData.yieldPayout);
    _vethYRT.reverseStakingRoute(address(_ethComptroller), reverseStakeData.processingFeeETH, ROUTE_SELECTOR);
    _transferToRevenueCycleTreasury(reverseStakeData.vyToBurn);

    emit Restake(
      borrower,                                           // borrower
      reverseStakeData.newReverseStakeId,                 // reverseStakeId
      _reverseStakeTermsNonce,                            // termId
      reverseStakeData.newReverseStakeVY,                 // stakedVY
      reverseStakeData.newReverseStakeClaimedYieldETH,    // originalClaimedYieldETH
      reverseStakeData.newReverseStakeClaimedYieldETH,    // currentClaimedYieldETH
      reverseStakeData.vyYieldRate,                       // yieldRate
      reverseStakeData.startAt,                           // startAt
      reverseStakeData.endAt,                             // endAt
      reverseStakeData.yieldPayout,                       // yieldPayout
      reverseStakeData.reverseStakeIds,                   // previousReverseStakeIds
      reverseStakeData.vyToBurn                           // burnRatePaid
    );
  }

  // for manually closing out expired reverseStakes (defaulted) and taking out the remaining staked VY
  function closeReverseStake(address borrower, uint256 reverseStakeId) external onlyBackendAgents {
    ReverseStake storage reverseStake = _reverseStakes[borrower][reverseStakeId];
    _checkValidReverseStake(reverseStake.startAt > 0);
    require(!isReverseStakeActive(borrower, reverseStakeId), "ReverseStake is still active");
    require(reverseStake.stakedVY > 0 && reverseStake.currentClaimedYieldETH > 0, "ReverseStake is already closed");

    uint256 stakedVY = reverseStake.stakedVY;
    uint256 currentClaimedYieldETH = reverseStake.currentClaimedYieldETH;

    // Update reverseStake and offer (if any)
    _decrementOpenReverseStakesAndCloseOffer(borrower, reverseStakeId, stakedVY);
    reverseStake.stakedVY = 0;
    reverseStake.currentClaimedYieldETH = 0;

    // Update total claimed yield
    _totalClaimedYieldETH -= currentClaimedYieldETH;

    // Transfer an remaining staked VY to revenueCycleTreasury
    // updating circulation and supply
    _transferToRevenueCycleTreasury(stakedVY);
  }

  function createOffer(uint256 reverseStakeId, uint256 quantity, uint256 price) external onlyActiveReverseStake(_msgSender(), reverseStakeId) {
    _checkValidQuantity(quantity);
    require(!_offers[_msgSender()][reverseStakeId].isOpen, "Limit one offer per reverseStake");

    ReverseStake memory reverseStake = _reverseStakes[_msgSender()][reverseStakeId];

    // OFFER_NET_STAKE_RATIO
    uint256 vyToBurn_ = _vyToBurn(_msgSender(), reverseStakeId);
    require(reverseStake.stakedVY >= vyToBurn_, "Not enough staked VY");
    uint256 maximumQuantity = (reverseStake.stakedVY - vyToBurn_) * OFFER_NET_STAKE_RATIO / MULTIPLIER;
    require(quantity <= maximumQuantity, "Quantity exceeds limit");

    // We're creating a [VY_ETH] offer:
    // min price = (current claimed yield / (remaining staked VY after burned VY * 0.98)) * 1.020409
    uint256 minPrice = reverseStake.currentClaimedYieldETH * OFFER_PRICE_YR_RATIO / maximumQuantity;
    _checkMinPrice(price >= minPrice);

    // As yieldRate gets lower, actual "price" gets higher due to inversion
    // adjustedYieldRate = yield rate / 1.020409
    uint256 adjustedYieldRate = _vethRevenueCycleTreasury.getYieldRate() * MULTIPLIER / OFFER_PRICE_YR_RATIO;
    require((MULTIPLIER * MULTIPLIER / price) <= adjustedYieldRate, "Price too low");

    // Cannot open an offer if reverseStake is to expire before end
    // of offer (currently 30 days)
    uint256 expiresAt = block.timestamp + EXPIRES_IN;
    require(reverseStake.endAt > expiresAt, "ReverseStake is about to expire");

    // Create offer
    _offers[_msgSender()][reverseStakeId] = Offer(quantity, price, reverseStake.currentClaimedYieldETH, maximumQuantity, expiresAt, true);

    emit CreateOffer(_msgSender(), reverseStakeId, quantity, price, expiresAt, block.timestamp);
  }

  /**
   * @dev This is for other members to trade on the offer the borrower created
   */
  function tradeOffer(address borrower, uint256 reverseStakeId) external payable onlyActiveOffer(borrower, reverseStakeId) {
    _checkValidQuantity(msg.value);

    Offer storage offer = _offers[borrower][reverseStakeId];
    ReverseStake storage reverseStake = _reverseStakes[borrower][reverseStakeId];

    TradeOfferVars memory info;
    info.maxInput = offer.unfilledQuantity * offer.price / MULTIPLIER;
    _checkEnoughAmountToSell(msg.value <= info.maxInput);

    info.ethFee = msg.value * ETH_FEE / MULTIPLIER;
    info.vyFee = msg.value * VY_FEE / offer.price;

    info.vyOut = msg.value * MULTIPLIER / offer.price;

    // Calculate and update reverseStake
    CalcOfferRepayment memory calc = _payReverseStakeVY(
      borrower,
      reverseStakeId,
      info.vyOut,
      offer.maxClaimedYieldETH,
      offer.maxQuantity,
      msg.value - info.ethFee
    );

    // Update offer
    if (!calc.isPaidOff) {
      if (info.vyOut > offer.unfilledQuantity) {
        info.vyOut = offer.unfilledQuantity;
      }
      offer.unfilledQuantity -= info.vyOut;

      // If remaining quantity is low enough, close it out
      // VY_ETH market - converted selling amount in VY to ETH < MINIMUM_OFFER_AUTOCLOSE_IN_ETH
      bool takerCloseout = (offer.unfilledQuantity * offer.price / MULTIPLIER) < MINIMUM_OFFER_AUTOCLOSE_IN_ETH;

      // console.log("unfilledQuantity: %s, takerCloseout: %s, amount: %s", offer.unfilledQuantity, takerCloseout, offer.unfilledQuantity * offer.price / MULTIPLIER);

      if (takerCloseout) {
        // Auto-close when selling amount in ETH < MINIMUM_OFFER_AUTOCLOSE_IN_ETH
        // No need to return VY from offer, since it was reserving
        // the VY directly from borrower's stakedVY pool.
        _closeOffer(borrower, reverseStakeId);
      }
    }

    _totalClaimedYieldETH -= calc.effectiveETHPaidOff;

    // Send out VY fee + VY to burn.
    // Note that we have 2% VY buffer in the staked VY, as
    // the offer can only be created with 98% of staked VY max.
    _transferToRevenueCycleTreasury(info.vyFee + calc.vyToBurn);

    // Send out VY to buyer
    _transferVY(_msgSender(), info.vyOut - info.vyFee);

    // Send out ETH fee
    _ethComptroller.route{ value: info.ethFee }();

    // Send out to VETHYieldRateTreasury
    _transfer(address(_vethYRT), msg.value - calc.excessETH - info.ethFee);
    if (calc.excessETH > 0) {
      // Send excess to borrower
      _transfer(borrower, calc.excessETH);
    }

    if (calc.excessStakedVY > 0) {
      // Return excess VY to borrower (if any) once reverseStake is repaid in full
      _transferVY(borrower, calc.excessStakedVY);
    }

    emit TradeOffer(borrower, reverseStakeId, _msgSender(), info.vyOut, msg.value, offer.unfilledQuantity, calc.excessETH, reverseStake.lastPaidAt);
    emit ReturnETHToUnstake(
      borrower,
      reverseStakeId,
      calc.effectiveETHPaidOff,
      reverseStake.currentClaimedYieldETH,
      reverseStake.stakedVY,
      0,
      calc.vyToBurn,
      reverseStake.lastPaidAt
    );
  }

  /**
   * @dev This is for the borrower to sell their staked VY to other users
   */
  function tradeStakedVY(uint256 reverseStakeId, uint256 offerId, address seller, uint256 amountVY) external onlyActiveReverseStake(_msgSender(), reverseStakeId) {
    _tradeStakedVYPrerequisite(reverseStakeId, amountVY);

    ReverseStake storage reverseStake = _reverseStakes[_msgSender()][reverseStakeId];
    // We are trading on a member's [ETH_VY] offer, so their price will be VY/ETH.
    VETHP2P.Offer memory offer = _vethP2P.getOffer(offerId, seller);
    require(offer.isOpen == true && offer.quantity > 0, "Offer is closed or has zero quantity");

    uint256 vyToBurn_ = _vyToBurn(_msgSender(), reverseStakeId);

    // min price formula = (current claimed yield / remaining staked VY after burned VY) * 1.020409
    // In this case it's actually max price due to inversion.
    uint256 maxPrice = reverseStake.currentClaimedYieldETH * OFFER_PRICE_YR_RATIO / (reverseStake.stakedVY - vyToBurn_);
    maxPrice = MULTIPLIER * MULTIPLIER / maxPrice;
    _checkMinPrice(offer.price <= maxPrice);

    _vyToken.approve(address(_vethP2P), amountVY);

    // Calculate (estimate) and update state first
    VETHP2P.TradeOfferCalcInfo memory calc = _vethP2P.estimateTradeOffer(offerId, seller, amountVY);
    CalcOfferRepayment memory reverseStakeCalcs = _payReverseStakeVY(
      _msgSender(),
      reverseStakeId,
      amountVY,
      reverseStake.currentClaimedYieldETH,
      reverseStake.stakedVY - vyToBurn_,
      calc.amountOut - calc.takerFee
    );

    // This needs to be updated last (but before transfers)
    // as this affects the yield rate.
    _totalClaimedYieldETH -= reverseStakeCalcs.effectiveETHPaidOff;

    // Execute actual swap
    VETHP2P.TradeOfferCalcInfo memory realCalc = _vethP2P.tradeOffer(offerId, seller, amountVY);
    require(calc.amountOut == realCalc.amountOut, "amountOut does not match");

    // Send out funds post-swap
    _transferToRevenueCycleTreasury(reverseStakeCalcs.vyToBurn);

    _transfer(address(_vethYRT), realCalc.amountOut - reverseStakeCalcs.excessETH - realCalc.takerFee);
    if (reverseStakeCalcs.excessETH > 0) {
      // Send excess to borrower
      _transfer(_msgSender(), reverseStakeCalcs.excessETH);
    }

    if (reverseStakeCalcs.excessStakedVY > 0) {
      // Return excess VY to borrower (if any) once reverseStake is repaid in full
      _transferVY(_msgSender(), reverseStakeCalcs.excessStakedVY);
    }

    emit ReturnETHToUnstake(
      _msgSender(),
      reverseStakeId,
      reverseStakeCalcs.effectiveETHPaidOff,
      reverseStake.currentClaimedYieldETH,
      reverseStake.stakedVY,
      0,
      reverseStakeCalcs.vyToBurn,
      reverseStake.lastPaidAt
    );
  }

  function closeOffer(uint256 reverseStakeId) external onlyOpenOffer(reverseStakeId, _msgSender()) {
    _closeOffer(_msgSender(), reverseStakeId);
  }

  function closeOffer(address borrower, uint256 reverseStakeId) external onlyOpenOffer(reverseStakeId, borrower) onlyBackendAgents {
    _closeOffer(borrower, reverseStakeId);
  }

  function getOffer(address borrower, uint256 reverseStakeId) external view returns (Offer memory) {
    return _offers[borrower][reverseStakeId];
  }

  function updateAddresses() external override onlyRegistrar {
    _vethP2P = VETHP2P(_registrar.getVETHP2P());
    _vethRevenueCycleTreasury = VETHRevenueCycleTreasury(_registrar.getVETHRevenueCycleTreasury());
    _vyToken = VYToken(_registrar.getVYToken());
    _vethYRT = VETHYieldRateTreasury(payable(_registrar.getVETHYieldRateTreasury()));
    _updateGovernable(_registrar);
  }

  function _migrateReverseStake(
    address borrowerAddress,
    uint256 stakedVY,
    uint256 originalClaimedYieldETH,
    uint256 currentClaimedYieldETH,
    uint256 yieldRate,
    uint256 startAt,
    uint256 endAt,
    uint256 lastPaidAt,
    uint256 previousReverseStakeId,
    uint256 termId
  ) private {
    require(startAt > 0, "Previous reverseStake invalid");

    uint256 reverseStakeId = ++_reverseStakesNonce;
    _reverseStakes[borrowerAddress][reverseStakeId] = ReverseStake(termId, stakedVY, originalClaimedYieldETH, currentClaimedYieldETH, yieldRate, startAt, endAt, lastPaidAt);
    _openReverseStakes[borrowerAddress]++;
    _totalClaimedYieldETH += currentClaimedYieldETH;

    emit MigrateReverseStake(borrowerAddress, reverseStakeId, termId, stakedVY, originalClaimedYieldETH, currentClaimedYieldETH, yieldRate, startAt, endAt, previousReverseStakeId);
  }

  function migrateReverseStakes(
    MigrateReverseStakeVars[] calldata reverseStakeDataArray
  ) external onlyBackendAgents onlyUnfinalized {
    for (uint i = 0; i < reverseStakeDataArray.length; i++) {
      _migrateReverseStake(
        reverseStakeDataArray[i].borrowerAddress,
        reverseStakeDataArray[i].stakedVY,
        reverseStakeDataArray[i].originalClaimedYieldETH,
        reverseStakeDataArray[i].currentClaimedYieldETH,
        reverseStakeDataArray[i].yieldRate,
        reverseStakeDataArray[i].startAt,
        reverseStakeDataArray[i].endAt,
        reverseStakeDataArray[i].lastPaidAt,
        reverseStakeDataArray[i].previousReverseStakeId,
        reverseStakeDataArray[i].termId
      );
    }
  }

  function _createNewReverseStakeTerm(
    uint256 dailyBurnRate,
    uint256 durationInDays,
    uint256 minimumReverseStakeETH,
    uint256 processingFeePercentage,
    uint256 extensionMinimumRemainingStake,
    DataTypes extensionMinimumRemainingStakeType,
    uint256 restakeMinimumPayout
  ) private {
    require(extensionMinimumRemainingStakeType == DataTypes.PERCENTAGE || extensionMinimumRemainingStakeType == DataTypes.VY, "Invalid type");

    _reverseStakeTerms[++_reverseStakeTermsNonce] = ReverseStakeTerm(
      dailyBurnRate,
      durationInDays,
      minimumReverseStakeETH,
      processingFeePercentage,
      extensionMinimumRemainingStake,
      extensionMinimumRemainingStakeType,
      restakeMinimumPayout
    );

    emit CreateReverseStakeTerm(
      _reverseStakeTermsNonce,
      dailyBurnRate,
      durationInDays,
      minimumReverseStakeETH,
      processingFeePercentage,
      extensionMinimumRemainingStake,
      extensionMinimumRemainingStakeType,
      restakeMinimumPayout
    );
  }

  function _getStakedVYForReverseStakeETH(uint256 ethAmount) private view returns (uint256) {
    uint256 vyYieldRate = _vethRevenueCycleTreasury.getYieldRate();
    return vyYieldRate * ethAmount / MULTIPLIER;
  }

  function _isReverseStakeExpired(address borrower, uint256 reverseStakeId) private view returns (bool) {
    return _reverseStakes[borrower][reverseStakeId].endAt < block.timestamp;
  }

  // rounding down basis, meaning for 11.6 days borrower will burn VY for 11 days
  // we have to account for the case where borrower might pay at 11.6 days and another payment at 20.4 days
  // because 20.4-11.6 = 8.8 days we cannot calculate directly otherwise 11+8 = 19 days of burn rate instead of 20
  // therefore we have to look at the number of days in total minus the number of days borrower has paid
  function _daysElapsed(uint256 startAt, uint256 lastPaidAt) private view returns (uint256) {
    uint256 currentTime = block.timestamp;
    if (lastPaidAt > 0) {
      uint256 daysTotal = (currentTime - startAt) / DAY_IN_SECONDS;
      uint256 daysPaid = (lastPaidAt - startAt) / DAY_IN_SECONDS;
      return daysTotal - daysPaid;
    } else {
      return (currentTime - startAt) / DAY_IN_SECONDS;
    }
  }

  function _getRemainingStakedVYExtensionLimit(uint256 termId, uint256 originalStakedVY) private view returns (uint256) {
    ReverseStakeTerm memory reverseStakeTerm = _reverseStakeTerms[termId];
    if (reverseStakeTerm.extensionMinimumRemainingStakeType == DataTypes.VY) {
      return reverseStakeTerm.extensionMinimumRemainingStake;
    } else if (reverseStakeTerm.extensionMinimumRemainingStakeType == DataTypes.PERCENTAGE) {
      return originalStakedVY * reverseStakeTerm.extensionMinimumRemainingStake / MULTIPLIER;
    } else {
      return 0;
    }
  }

  function _ethToBurn(address borrower, uint256 reverseStakeId) private view returns (uint256) {
    ReverseStake memory reverseStake = _reverseStakes[borrower][reverseStakeId];
    ReverseStakeTerm memory reverseStakeTerm = _reverseStakeTerms[reverseStake.termId];
    uint256 daysElapsed = _daysElapsed(reverseStake.startAt, reverseStake.lastPaidAt);

    return reverseStake.currentClaimedYieldETH * reverseStakeTerm.dailyBurnRate * daysElapsed / MULTIPLIER;
  }

  function _vyToBurn(address borrower, uint256 reverseStakeId) private view returns (uint256) {
    uint256 ethToBurn_ = _ethToBurn(borrower, reverseStakeId);
    uint256 vyYieldRate = _vethRevenueCycleTreasury.getYieldRate();

    return ethToBurn_ * vyYieldRate / MULTIPLIER;
  }

  /**
   * @dev Pay off reverseStake by selling staked VY
   */
  function _payReverseStakeVY(address borrower, uint256 reverseStakeId, uint256 vyToTrade, uint256 maxClaimedYieldETH, uint256 maxVY, uint256 amountETH) private returns (CalcOfferRepayment memory) {
    ReverseStake storage reverseStake = _reverseStakes[borrower][reverseStakeId];

    CalcOfferRepayment memory calc;

    // uint256 percentagePaidOff = vyToTrade * MULTIPLIER / maxVY;
    // calc.effectiveETHPaidOff = percentagePaidOff * maxClaimedYieldETH / MULTIPLIER;
    calc.effectiveETHPaidOff = vyToTrade * maxClaimedYieldETH / maxVY;
    if (amountETH > calc.effectiveETHPaidOff) {
      calc.excessETH = amountETH - calc.effectiveETHPaidOff;
    }
    calc.vyToBurn = _vyToBurn(borrower, reverseStakeId);

    // console.log("vyToTrade: %s\npercentagePaidOff: %s\neffectiveETHPaidOff: %s", vyToTrade, percentagePaidOff, calc.effectiveETHPaidOff);
    // console.log("excessETH: %s\nvyToBurn: %s\nstake: %s", calc.excessETH, calc.vyToBurn, reverseStake.stakedVY);
    // console.log("amountETH: %s", amountETH);

    // Update reverseStake
    require(reverseStake.stakedVY >= vyToTrade + calc.vyToBurn, "Not enough staked VY");
    reverseStake.stakedVY -= vyToTrade + calc.vyToBurn;

    // Handle possible precision issues
    if (calc.effectiveETHPaidOff > reverseStake.currentClaimedYieldETH) {
      calc.effectiveETHPaidOff = reverseStake.currentClaimedYieldETH;
    }
    if (reverseStake.currentClaimedYieldETH > calc.effectiveETHPaidOff &&
      (reverseStake.currentClaimedYieldETH - calc.effectiveETHPaidOff <= MINIMUM_REVERSE_STAKE_AUTOCLOSE)) {
      calc.effectiveETHPaidOff = reverseStake.currentClaimedYieldETH;
    }

    // ReverseStake paid off?
    if (calc.effectiveETHPaidOff == reverseStake.currentClaimedYieldETH) {
      calc.isPaidOff = true;
      _decrementOpenReverseStakesAndCloseOffer(borrower, reverseStakeId, 0);

      // If there is any remaining staked VY, record that
      // so we can later return it to borrower.
      if (reverseStake.stakedVY > 0) {
        calc.excessStakedVY = reverseStake.stakedVY;
        reverseStake.stakedVY = 0;
      }
    }

    // Update rest of reverseStake
    reverseStake.currentClaimedYieldETH -= calc.effectiveETHPaidOff;
    reverseStake.lastPaidAt = block.timestamp;

    // console.log("currentClaimedYieldETH: %s, excessStakedVY: %s", reverseStake.currentClaimedYieldETH, calc.excessStakedVY);
    // console.log("stakedVY: %s", reverseStake.stakedVY);

    return calc;
  }

  function _createReverseStakePrerequisite(uint256 termId, uint256 ethAmount, uint256 vyAmount) private view returns (uint256) {
    require(termId == _reverseStakeTermsNonce, "Invalid reverse stake term specified");
    require(_openReverseStakes[_msgSender()] < _maxReverseStakes, "Maximum reverse stakes reached");
    uint256 minStake = _getStakedVYForReverseStakeETH(ethAmount);
    require(vyAmount >= minStake, "vyAmount too low based on yield rate");

    return minStake;
  }

  function _tradeStakedVYPrerequisite(uint256 reverseStakeId, uint256 amountVY) private view {
    _checkValidQuantity(amountVY);
    Offer memory offer = _offers[_msgSender()][reverseStakeId];
    _checkActiveOffer(offer.isOpen);
    ReverseStake memory reverseStake = _reverseStakes[_msgSender()][reverseStakeId];
    uint256 vyToBurn_ = _vyToBurn(_msgSender(), reverseStakeId);
    require(reverseStake.stakedVY >= vyToBurn_, "Not enough staked VY");
    uint256 remainingStake = reverseStake.stakedVY - vyToBurn_;
    _checkEnoughAmountToSell(amountVY <= remainingStake);
  }

  function _transferToRevenueCycleTreasury(uint256 amount) private {
    _transferVY(address(_vethRevenueCycleTreasury), amount);
  }

  function _decrementOpenReverseStakesAndCloseOffer(address borrower, uint256 reverseStakeId, uint256 stakeTransferred) internal {
    if (_openReverseStakes[borrower] > 0) {
      _openReverseStakes[borrower]--;
    }
    if (_offers[borrower][reverseStakeId].isOpen) {
      _closeOffer(borrower, reverseStakeId);
    }
    emit CloseReverseStake(borrower, reverseStakeId, stakeTransferred);
  }

  function _closeOffer(address borrower, uint256 reverseStakeId) internal {
    delete _offers[borrower][reverseStakeId];
    emit CloseOffer(borrower, reverseStakeId, block.timestamp);
  }

  function _transferVY(address recipient, uint256 amount) private {
    if (amount > 0) {
      _vyToken.transfer(recipient, amount);
    }
  }

  function _checkActiveOffer(bool isOpen) private pure {
    require(!isOpen, "Active offer found");
  }

  function _checkMinPrice(bool minPriceMet) private pure {
    require(minPriceMet, "Minimum price not met");
  }

  function _checkValidQuantity(uint256 amount) private pure {
    require(amount > 0, "Invalid quantity");
  }

  function _checkEnoughAmountToSell(bool isEnough) private pure {
    require(isEnough, "Not enough to sell");
  }

  function _checkSufficientBalance(bool isufficient) private pure {
    require(isufficient, "Insufficient balance");
  }

  function _checkValidReverseStake(bool isValid) private pure {
    require(isValid, "Invalid reverseStake");
  }

  function _checkActiveReverseStake(bool isActive) private pure {
    require(isActive, "ReverseStake is not active");
  }

  function _transfer(address recipient, uint256 amount) private {
    (bool sent,) = recipient.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Context } from "../lib/utils/Context.sol";

contract AdminAgent is Context {

  mapping(address => bool) private _adminAgents;

  constructor(address[] memory adminAgents_) {
    for (uint i = 0; i < adminAgents_.length; i++) {
      require(adminAgents_[i] != address(0), "Invalid address");
      _adminAgents[adminAgents_[i]] = true;
    }
  }

  modifier onlyAdminAgents() {
    require(_adminAgents[_msgSender()], "Unauthorized");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Context } from "../lib/utils/Context.sol";

contract AdminGovernanceAgent is Context {

  mapping(address => bool) private _adminGovAgents;

  constructor(address[] memory adminGovAgents_) {
    for (uint i = 0; i < adminGovAgents_.length; i++) {
      require(adminGovAgents_[i] != address(0), "Invalid address");
      _adminGovAgents[adminGovAgents_[i]] = true;
    }
  }

  modifier onlyAdminGovAgents() {
    require(_adminGovAgents[_msgSender()], "Unauthorized");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Context } from "../lib/utils/Context.sol";

contract BackendAgent is Context {

  mapping(address => bool) private _backendAdminAgents;
  mapping(address => bool) private _backendAgents;

  event SetBackendAgent(address agent);
  event RevokeBackendAgent(address agent);

  modifier onlyBackendAdminAgents() {
    require(_backendAdminAgents[_msgSender()], "Unauthorized");
    _;
  }

  modifier onlyBackendAgents() {
    require(_backendAgents[_msgSender()], "Unauthorized");
    _;
  }

  function _setBackendAgents(address[] memory backendAgents) internal {
    for (uint i = 0; i < backendAgents.length; i++) {
      require(backendAgents[i] != address(0), "Invalid address");
      _backendAgents[backendAgents[i]] = true;
    }
  }

  function _setBackendAdminAgents(address[] memory backendAdminAgents) internal {
    for (uint i = 0; i < backendAdminAgents.length; i++) {
      require(backendAdminAgents[i] != address(0), "Invalid address");
      _backendAdminAgents[backendAdminAgents[i]] = true;
    }
  }

  function setBackendAgent(address _agent) external onlyBackendAdminAgents {
    require(_agent != address(0), "Invalid address");
    _backendAgents[_agent] = true;
    emit SetBackendAgent(_agent);
  }

  function revokeBackendAgent(address _agent) external onlyBackendAdminAgents {
    _backendAgents[_agent] = false;
    emit RevokeBackendAgent(_agent);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { VETHRevenueCycleTreasury } from "./VETHRevenueCycleTreasury.sol";
import { ERC20 } from "../lib/token/ERC20/ERC20.sol";
import { VYToken } from "../token/VYToken.sol";
import { BackendAgent } from "../access/BackendAgent.sol";
import { RegistrarClient } from "../RegistrarClient.sol";
import { Router } from "../Router.sol";

contract VETHP2P is BackendAgent, RegistrarClient {

  uint256 private constant MULTIPLIER = 10**18;

  struct TradeOfferCalcInfo {
    uint256 amountOut;
    uint256 takerReceives;
    uint256 takerFee;
    uint256 makerReceives;
    uint256 makerFee;
  }

  uint256 public constant EXPIRES_IN = 30 days;
  uint256 public constant MINIMUM_AUTOCLOSE_IN_ETH = 500000000000000; // 0.0005 ETH
  uint256 public constant ETH_FEE = 20000000000000000;
  uint256 public constant VY_FEE = 20000000000000000;

  Router private _ethComptroller;
  VETHRevenueCycleTreasury private _vethRevenueCycleTreasury;
  uint256 private _nonce = 1;

  enum TradingPairs {
    VY_ETH,
    ETH_VY
  }

  struct Offer {
    uint256 id;
    TradingPairs tradingPair;
    uint256 quantity;
    uint256 price;
    uint256 expiresAt;
    bool isOpen;
  }

  struct TradingPair {
    address makerAssetAddress;
    address takerAssetAddress;
    address makerTreasuryAddress;
    address takerTreasuryAddress;
    uint256 makerFeeRate;
    uint256 takerFeeRate;
  }

  mapping(address => mapping(uint256 => Offer)) private _offers;
  mapping(TradingPairs => TradingPair) private _tradingPairs;

  event CreateOffer(uint256 id, address seller, TradingPairs tradingPair, uint256 quantity, uint256 price, uint256 expiresAt, uint256 timestamp);
  event TradeOffer(uint256 id, address buyer, uint256 sellerQuantity, uint256 buyerQuantity, uint256 unfilledQuantity, uint256 timestamp);
  event CloseOffer(uint256 id, uint256 timestamp);

  constructor(
    address registrarAddress,
    address ethComptrollerAddress_,
    address[] memory backendAdminAgents,
    address[] memory backendAgents
  ) RegistrarClient(registrarAddress) {
    require(ethComptrollerAddress_ != address(0), "Invalid address");

    _ethComptroller = Router(payable(ethComptrollerAddress_));
    _setBackendAdminAgents(backendAdminAgents);
    _setBackendAgents(backendAgents);
  }

  modifier onlyValidCreateOffer(TradingPairs tradingPair, uint256 quantity, uint256 price) {
    require(_pairExist(tradingPair), "Invalid pair");
    require(quantity > 0, "Invalid quantity");
    require(price > 0, "Invalid price");

    if (tradingPair == TradingPairs.ETH_VY) {
      require(msg.value == quantity, "Invalid ETH amount sent");
    } else {
      require(msg.value == 0, "Invalid ETH amount sent");
    }
    _;
  }

  modifier onlyValidTradeOffer(uint256 id, address seller, uint256 quantity) {
    require(_isOfferActive(id, seller), "Invalid offer");
    require(quantity > 0, "Invalid quantity");
    _;
  }

  modifier onlyOpenOffer(uint256 id, address seller) {
    require(_offers[seller][id].isOpen, "Offer must be open in order to close");
    _;
  }

  function getNonce() external view returns (uint256) {
    return _nonce;
  }

  function getOffer(uint256 id, address seller) external view returns (Offer memory) {
    return _offers[seller][id];
  }

  function createOffer(TradingPairs tradingPair, uint256 quantity, uint256 price)
    external
    payable
    onlyValidCreateOffer(tradingPair, quantity, price)
  {
    _createOffer(tradingPair, quantity, price);
  }

  function createOffer(TradingPairs tradingPair, uint256 quantity, uint256 price, uint8 v, bytes32 r, bytes32 s)
    external
    payable
    onlyValidCreateOffer(tradingPair, quantity, price)
  {
    // Verify maker asset must be VY
    require(_tradingPairs[tradingPair].makerAssetAddress == _tradingPairs[TradingPairs.VY_ETH].makerAssetAddress, "Must be [VY_ETH]");
    VYToken makerAsset = VYToken(_tradingPairs[tradingPair].makerAssetAddress);
    // Call approval
    makerAsset.permit(_msgSender(), address(this), quantity, v, r, s);
    _createOffer(tradingPair, quantity, price);
  }

  function _createOffer(TradingPairs tradingPair, uint256 quantity, uint256 price) private {
    uint256 yieldRate = _vethRevenueCycleTreasury.getYieldRate();
    if (tradingPair == TradingPairs.ETH_VY) {
      require(price <= yieldRate, "Price must be <= yieldRate");
    } else if (tradingPair == TradingPairs.VY_ETH) {
      require((MULTIPLIER * MULTIPLIER / price) <= yieldRate, "Price reciprocal must be <= yieldRate");
    } else {
      revert("Unsupported pair");
    }

    // Create offer
    uint256 expiresAt = block.timestamp + EXPIRES_IN;
    uint256 id = _nonce++;
    _offers[_msgSender()][id] = Offer(id, tradingPair, quantity, price, expiresAt, true);

    // Transfer VY to the contract
    if (tradingPair == TradingPairs.VY_ETH) {
      ERC20 token = _getSpendingTokenAndCheck(_tradingPairs[tradingPair].makerAssetAddress, quantity);
      token.transferFrom(_msgSender(), address(this), quantity);
    }

    emit CreateOffer(id, _msgSender(), tradingPair, quantity, price, expiresAt, block.timestamp);
  }

  function tradeOffer(uint256 id, address seller, uint256 quantity)
    external
    payable
    onlyValidTradeOffer(id, seller, quantity)
    returns (TradeOfferCalcInfo memory)
  {
    _validateTradeOfferETHAmount(id, seller, quantity);

    return _tradeOffer(id, seller, quantity);
  }

  function tradeOffer(uint256 id, address seller, uint256 quantity, uint8 v, bytes32 r, bytes32 s)
    external
    payable
    onlyValidTradeOffer(id, seller, quantity)
    returns (TradeOfferCalcInfo memory)
  {
    _validateTradeOfferETHAmount(id, seller, quantity);

    // Verify taker asset must be VY
    TradingPair memory tradingPair = _tradingPairs[_offers[seller][id].tradingPair];
    require(tradingPair.takerAssetAddress == _tradingPairs[TradingPairs.ETH_VY].takerAssetAddress, "Must be [ETH_VY]");

    VYToken takerAsset = VYToken(tradingPair.takerAssetAddress);
    // Call approval
    takerAsset.permit(_msgSender(), address(this), quantity, v, r, s);

    return _tradeOffer(id, seller, quantity);
  }

  function estimateTradeOffer(uint256 id, address seller, uint256 quantity) external view onlyValidTradeOffer(id, seller, quantity) returns (TradeOfferCalcInfo memory) {
    TradingPair memory tradingPair = _tradingPairs[_offers[seller][id].tradingPair];
    uint256 maxInput = _offers[seller][id].quantity * _offers[seller][id].price / MULTIPLIER;
    require(quantity <= maxInput, "Not enough to sell");

    return _calcTradeOffer(tradingPair, quantity, _offers[seller][id].price);
  }

  function _tradeOffer(uint256 id, address seller, uint256 quantity) private returns (TradeOfferCalcInfo memory) {
    TradingPair memory tradingPair = _tradingPairs[_offers[seller][id].tradingPair];
    uint256 maxInput = _offers[seller][id].quantity * _offers[seller][id].price / MULTIPLIER;
    require(quantity <= maxInput, "Not enough to sell");

    /// @dev returns maker quantity fulfilled by this trade
    TradeOfferCalcInfo memory calc = _calcTradeOffer(tradingPair, quantity, _offers[seller][id].price);

    // Update offer quantity
    require(_offers[seller][id].quantity >= calc.amountOut, "Bad calculations");
    _offers[seller][id].quantity -= calc.amountOut;

    // VY_ETH trade
    if (tradingPair.takerAssetAddress == address(0)) {
      ERC20 makerAsset = ERC20(tradingPair.makerAssetAddress);

      // Transfer taker ETH
      _transfer(seller, calc.makerReceives);
      _ethComptroller.route{ value: calc.makerFee }();

      // Transfer maker VY
      makerAsset.transfer(_msgSender(), calc.takerReceives);
      makerAsset.transfer(tradingPair.makerTreasuryAddress, calc.takerFee);
    } else { // ETH_VY trade
      ERC20 takerAsset = _getSpendingTokenAndCheck(tradingPair.takerAssetAddress, quantity);

      /**
       * Transfer taker VY
       *
       * @dev the code below transfers makerReceives from taker to contract, then from contract to maker
       * instead of transferring makerReceives directly from taker to maker, is to avoid user transfer fee
       * being applied to (See ticket-296 for more info)
       */
      takerAsset.transferFrom(_msgSender(), address(this), calc.makerReceives);
      takerAsset.transfer(seller, calc.makerReceives);
      takerAsset.transferFrom(_msgSender(), tradingPair.takerTreasuryAddress, calc.makerFee);

      // Transfer maker ETH
      _transfer(_msgSender(), calc.takerReceives);
      _ethComptroller.route{ value: calc.takerFee }();
    }

    // ETH_VY market - selling amount in ETH < MINIMUM_AUTOCLOSE_IN_ETH
    bool makerCloseout = (tradingPair.makerAssetAddress == address(0) && _offers[seller][id].quantity < MINIMUM_AUTOCLOSE_IN_ETH);
    // VY_ETH market - converted selling amount in VY to ETH < MINIMUM_AUTOCLOSE_IN_ETH
    bool takerCloseout = (tradingPair.takerAssetAddress == address(0) && _offers[seller][id].quantity * _offers[seller][id].price / MULTIPLIER < MINIMUM_AUTOCLOSE_IN_ETH);

    if (makerCloseout || takerCloseout) {
      _closeOffer(id, seller); // Auto-close when selling amount in ETH < MINIMUM_AUTOCLOSE_IN_ETH
    }

    emit TradeOffer(id, _msgSender(), calc.amountOut, quantity, _offers[seller][id].quantity, block.timestamp);

    return calc;
  }

  function closeOffer(uint256 id) external onlyOpenOffer(id, _msgSender()) {
    _closeOffer(id, _msgSender());
  }

  function closeOffer(address seller, uint256 id) external onlyOpenOffer(id, seller) onlyBackendAgents {
    _closeOffer(id, seller);
  }

  function _pairExist(TradingPairs tradingPair) private view returns (bool) {
    return _tradingPairs[tradingPair].makerAssetAddress != address(0) || _tradingPairs[tradingPair].takerAssetAddress != address(0);
  }

  function _isOfferActive(uint256 id, address seller) private view returns (bool) {
    return _offers[seller][id].isOpen && _offers[seller][id].expiresAt > block.timestamp;
  }

  function _getSpendingTokenAndCheck(address assetAddress, uint256 quantity) private view returns (ERC20) {
    ERC20 token = ERC20(assetAddress);
    require(token.allowance(_msgSender(), address(this)) >= quantity, "Insufficient allowance");
    require(token.balanceOf(_msgSender()) >= quantity, "Insufficient balance");
    return token;
  }

  function _calcTradeOffer(TradingPair memory tradingPair, uint256 quantity, uint256 price) private pure returns (TradeOfferCalcInfo memory) {
    // Offer is 1,000 VY at 10.0 ETH each (10,000 ETH in total)
    // Taker want to swap 100 ETH for 10 VY
    // buyQuantity should be 100 ETH * (10^18 / 10^19) = 10 VY
    uint256 buyQuantity = quantity * MULTIPLIER / price;

    TradeOfferCalcInfo memory calc;
    calc.amountOut = buyQuantity;
    calc.makerFee = quantity * tradingPair.makerFeeRate / MULTIPLIER;
    calc.takerFee = buyQuantity * tradingPair.takerFeeRate / MULTIPLIER;
    calc.makerReceives = quantity - calc.makerFee;
    calc.takerReceives = buyQuantity - calc.takerFee;

    return calc;
  }

  function _closeOffer(uint256 id, address seller) private {
    uint256 remainingQuantity = _offers[seller][id].quantity;
    _offers[seller][id].isOpen = false;
    if (remainingQuantity > 0) {
      _offers[seller][id].quantity = 0;

      address makerAssetAddress = _tradingPairs[_offers[seller][id].tradingPair].makerAssetAddress;
      if (makerAssetAddress == address(0)) {
        _transfer(seller, remainingQuantity);
      } else {
        ERC20 token = ERC20(makerAssetAddress);
        token.transfer(seller, remainingQuantity);
      }
    }
    emit CloseOffer(id, block.timestamp);
  }

  function updateAddresses() external override onlyRegistrar {
    _vethRevenueCycleTreasury = VETHRevenueCycleTreasury(_registrar.getVETHRevenueCycleTreasury());
    _initTradingPairs();
  }

  function _initTradingPairs() internal {
    address vethRevenueCycleTreasury = _registrar.getVETHRevenueCycleTreasury();
    address vyToken = _registrar.getVYToken();
    _tradingPairs[TradingPairs.VY_ETH] = TradingPair(vyToken, address(0), vethRevenueCycleTreasury, address(_ethComptroller), VY_FEE, ETH_FEE);
    _tradingPairs[TradingPairs.ETH_VY] = TradingPair(address(0), vyToken, address(_ethComptroller), vethRevenueCycleTreasury, ETH_FEE, VY_FEE);
  }

  function _transfer(address recipient, uint256 amount) private {
    (bool sent,) = recipient.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }

  function _validateTradeOfferETHAmount(uint256 id, address seller, uint256 quantity) private {
    if (_offers[seller][id].tradingPair == TradingPairs.VY_ETH) {
      require(msg.value == quantity, "Invalid ETH amount sent");
    } else {
      require(msg.value == 0, "Invalid ETH amount sent");
    }
  }
}

// SPDX-License-Identifier: MIT
//
// VETHRevenueCycleTreasury [VY_ETH]
//

pragma solidity 0.8.18;

import { BackendAgent } from "../access/BackendAgent.sol";
import { VYToken } from "../token/VYToken.sol";
import { RegistrarClient } from "../RegistrarClient.sol";
import { RegistrarMigrator } from "../RegistrarMigrator.sol";
import { AdminGovernanceAgent } from "../access/AdminGovernanceAgent.sol";
import { Governable } from "../governance/Governable.sol";
import { VETHYieldRateTreasury } from "../treasury/VETHYieldRateTreasury.sol";
import { VYRevenueCycleCirculationTracker } from "./VYRevenueCycleCirculationTracker.sol";
import { Registrar } from "../Registrar.sol";
import { Router } from "../Router.sol";

contract VETHRevenueCycleTreasury is BackendAgent, RegistrarClient, RegistrarMigrator, AdminGovernanceAgent, Governable, VYRevenueCycleCirculationTracker {

  uint256 private constant MULTIPLIER = 10**18;

  uint256 public constant ETH_FEE = 20000000000000000;
  uint256 public constant VY_FEE = 20000000000000000;
  uint256 public constant CREATE_PRICE_FACTOR = 2000000000000000000; // 2 multiplier
  uint256 public constant YIELD_RATE_FACTOR = 1030000000000000000; // 1.03 multiplier

  VYToken internal _vyToken;
  VETHYieldRateTreasury private _vethYRT;
  Router private _ethComptroller;
  address private _migration;
  uint256 private _nonce = 0;
  uint256 private _vyAllocatedInOffer = 0;
  uint256 internal _initialYieldRate = 0;

  struct Offer {
    uint256 id;
    uint256 quantity;
    uint256 price;
    bool isOpen;
  }

  mapping(uint256 => Offer) private _offers;

  event CreateOffer(uint256 id, uint256 quantity, uint256 price, uint256 timestamp);
  event TradeOffer(uint256 id, address buyer, uint256 sellerQuantity, uint256 buyerQuantity, uint256 unfilledQuantity, uint256 timestamp);
  event CloseOffer(uint256 id, uint256 timestamp);

  constructor(
    address registrarAddress,
    address ethComptrollerAddress_,
    address[] memory adminAgents,
    address[] memory backendAdminAgents,
    address[] memory backendAgents,
    address[] memory adminGovAgents,
    uint256 initialYieldRate_,
    uint256 initialCirculation
  ) RegistrarClient(registrarAddress)
    RegistrarMigrator(registrarAddress, uint(Registrar.Contract.VETHRevenueCycleTreasury), adminAgents)
    AdminGovernanceAgent(adminGovAgents)
    VYRevenueCycleCirculationTracker(initialCirculation) {
    require(ethComptrollerAddress_ != address(0), "Invalid address");

    _ethComptroller = Router(payable(ethComptrollerAddress_));
    _setBackendAdminAgents(backendAdminAgents);
    _setBackendAgents(backendAgents);
    _initialYieldRate = initialYieldRate_;
  }

  function getNonce() external view returns (uint256) {
    return _nonce;
  }

  function getVYAllocatedInOffer() external view returns (uint256) {
    return _vyAllocatedInOffer;
  }

  function getOffer(uint256 id) external view returns (Offer memory) {
    return _offers[id];
  }

  function getMigration() external view returns (address) {
    return _migration;
  }

  function getInitialYieldRate() external view returns (uint256) {
    return _initialYieldRate;
  }

  function getYieldRate() external view returns (uint256) {
    return _getYieldRate();
  }

  function getVETHCirculation() public view returns (uint256) {
    return _getRevenueCycleCirculation();
  }

  function setMigration(address destination) external onlyGovernance {
    _migration = destination;
  }

  function transferMigration(uint256 amount) external onlyAdminGovAgents {
    require(_migration != address(0), "Migration not set");
    require(_vyToken.balanceOf(address(this)) >= amount, "Insufficient balance");
    _vyToken.transfer(_migration, amount);
  }

  function createOffer(uint256 quantity) external onlyBackendAgents {
    require(quantity > 0, "Invalid quantity");

    uint256 yieldRate = _getYieldRate();
    require(yieldRate > 0, "Yield rate must be greater than zero");
    uint256 price = CREATE_PRICE_FACTOR * MULTIPLIER / yieldRate;

    Offer memory offer = _offers[_nonce];
    if (offer.isOpen) {
      _closeOffer(_nonce);
    }

    uint256 _vyBalance = _vyToken.balanceOf(address(this));
    uint256 _desiredTotalVY = _vyAllocatedInOffer + quantity;

    uint256 id = ++_nonce;
    _offers[id] = Offer(id, quantity, price, true);
    _vyAllocatedInOffer += quantity;

    if (_desiredTotalVY > _vyBalance) {
      uint256 amountToMint = _desiredTotalVY - _vyBalance;
      _vyToken.mint(amountToMint);
    }

    emit CreateOffer(id, quantity, price, block.timestamp);
  }

  function tradeOffer(uint256 id) external payable {
    require(msg.value > 0, "Invalid quantity");
    require(_isOfferActive(id), "Invalid offer");

    uint256 price = _offers[id].price;
    uint256 maxInput = _offers[id].quantity * price / MULTIPLIER;
    require(msg.value <= maxInput, "Not enough to sell");

    /// @dev returns maker quantity fulfilled by this trade
    uint256 buyQuantity = msg.value * MULTIPLIER / price;
    require(_vyToken.balanceOf(address(this)) >= buyQuantity, "Not enough to sell");

    // Add yield rate > 0 check to avoid error dividing by 0 yield rate from the following cases:
    // 1. VETHYieldRateTreasury contract swap making treasuryValue 0
    // 2. Stake supply = 0 and initial yield rate = 0
    uint256 yieldRate = _getYieldRate();
    if (yieldRate > 0) {
      uint256 limitYieldRate = YIELD_RATE_FACTOR * MULTIPLIER / yieldRate;
      // Ensure offer price is still above yield rate to enforce rising yield rate rule
      require(price >= limitYieldRate, "Price must be >= limitYieldRate");
    }

    // Update offer quantity and total VY allocated
    require(_offers[id].quantity >= buyQuantity, "Bad calculations");
    _offers[id].quantity -= buyQuantity;
    _vyAllocatedInOffer -= buyQuantity;

    uint256 makerFee = msg.value * VY_FEE / MULTIPLIER;
    uint256 takerFee = buyQuantity * ETH_FEE / MULTIPLIER;

    uint256 makerReceives = msg.value - makerFee;
    uint256 takerReceives = buyQuantity - takerFee;

    _transfer(address(_vethYRT), makerReceives);
    _ethComptroller.route{ value: makerFee }();
    _vyToken.transfer(_msgSender(), takerReceives);

    emit TradeOffer(id, _msgSender(), buyQuantity, msg.value, _offers[id].quantity, block.timestamp);
  }

  function closeOffer(uint256 id) external onlyBackendAgents {
    require(_isOfferActive(id), "Invalid offer");
    _closeOffer(id);
  }

  function updateAddresses() external override onlyRegistrar {
    _vyToken = VYToken(_registrar.getVYToken());
    _vethYRT = VETHYieldRateTreasury(payable(_registrar.getVETHYieldRateTreasury()));
    _updateGovernable(_registrar);
    _updateVYCirculationHelper(_registrar);
  }

  function _isOfferActive(uint256 id) private view returns (bool) {
    return _offers[id].isOpen;
  }

  function _getYieldRate() private view returns (uint256) {
    uint256 circulation = getVETHCirculation();
    uint256 treasuryValue = _vethYRT.getYieldRateTreasuryValue();

    if (treasuryValue == 0) {
      return 0;
    }

    if (circulation > 0) {
      return MULTIPLIER * circulation / treasuryValue;
    } else {
      return _initialYieldRate;
    }
  }

  function _transfer(address recipient, uint256 amount) private {
    (bool sent,) = recipient.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }

  function _closeOffer(uint256 id) private {
    _vyAllocatedInOffer -= _offers[id].quantity;
    _offers[id].isOpen = false;
    _offers[id].quantity = 0;
    emit CloseOffer(id, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { Registrar } from "../Registrar.sol";
import { Context } from "../lib/utils/Context.sol";

contract VYRevenueCycleCirculationTracker is Context {

  uint256 private _revenueCycleCirculation;
  address private _vyTokenAddress;

  constructor(uint256 initialCirculation) {
    _revenueCycleCirculation = initialCirculation;
  }

  modifier onlyVYToken() {
    require(_msgSender() == _vyTokenAddress, "Caller must be VYToken");
    _;
  }

  function increaseRevenueCycleCirculation(uint256 amount) external onlyVYToken {
    _revenueCycleCirculation += amount;
  }

  function decreaseRevenueCycleCirculation(uint256 amount) external onlyVYToken {
    if (amount > _revenueCycleCirculation) {
        _revenueCycleCirculation = 0;
    } else {
        _revenueCycleCirculation -= amount;
    }
  }

  function _updateVYCirculationHelper(Registrar registrar) internal {
    _vyTokenAddress = registrar.getVYToken();
  }

  function _getRevenueCycleCirculation() internal view returns (uint256) {
    return _revenueCycleCirculation;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Context } from "../lib/utils/Context.sol";
import { Registrar } from "../Registrar.sol";

contract Governable is Context {

  address internal _governanceAddress;

  constructor() {}

  modifier onlyGovernance() {
    require(_governanceAddress == _msgSender(), "Unauthorized");
    _;
  }

  function _updateGovernable(Registrar registrar) internal {
    _governanceAddress = registrar.getVETHGovernance();
  }

  function getGovernanceAddress() external view returns (address) {
    return _governanceAddress;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { AdminAgent } from "../access/AdminAgent.sol";
import { VETHYieldRateTreasury } from "../treasury/VETHYieldRateTreasury.sol";
import { VYToken } from "../token/VYToken.sol";
import { VETHRevenueCycleTreasury } from "../exchange/VETHRevenueCycleTreasury.sol";
import { VETHReverseStakingTreasury } from "../VETHReverseStakingTreasury.sol";
import { RegistrarClient } from "../RegistrarClient.sol";

contract VETHGovernance is AdminAgent, RegistrarClient {

  enum VoteOptions {
    YES,
    NO
  }

  enum ProposalType {
    Migration,
    Registrar
  }

  struct MigrationProposal {
    address yieldRateTreasuryDestination;
    address revenueCycleTreasuryDestination;
    address reverseStakingTreasuryDestination;
  }

  struct RegistrarProposal {
    address registrar; // Registrar to add
  }

  struct Proposal {
    ProposalType proposalType;
    uint256 endsAt;
    bool approved;
    MigrationProposal migration;
    RegistrarProposal registrar;
  }

  event StartMigrationProposal(
    uint256 proposalId,
    address yieldRateTreasuryDestination,
    address revenueCycleTreasuryDestination,
    address reverseStakingTreasuryDestination,
    uint256 endsAt
  );
  event StartRegistrarProposal(uint256 proposalId, address registrar, uint256 endsAt);

  VYToken private _vyToken;
  VETHYieldRateTreasury private _vethYRT;
  VETHRevenueCycleTreasury private _vethRevenueCycleTreasury;
  VETHReverseStakingTreasury private _vethReverseStakingTreasury;
  mapping(uint256 => mapping(address => uint256)) private _deposits;
  mapping(uint256 => mapping(VoteOptions => uint256)) private _voteCount;
  mapping(uint256 => Proposal) private _proposals;
  uint256 public votingPeriod;  // In seconds
  uint256 private _proposalNonce = 0;

  event Vote(address account, VoteOptions voteOption, uint256 quantity);

  constructor(
    address registrarAddress,
    uint256 votingPeriod_,
    address[] memory adminAgents
  ) AdminAgent(adminAgents) RegistrarClient(registrarAddress) {
    votingPeriod = votingPeriod_;
  }

  modifier hasMigrationAddresses() {
    require(address(_vethYRT) != address(0), "ETH Treasury address not set");
    require(address(_vethRevenueCycleTreasury) != address(0), "VETHRevenueCycleTreasury address not set");
    require(address(_vethReverseStakingTreasury) != address(0), "VETHReverseStakingTreasury address not set");
    _;
  }

  modifier hasProposal() {
    require(_proposals[_proposalNonce].endsAt > 0, "No proposal");
    _;
  }

  modifier hasProposalById(uint256 proposalId) {
    require(_proposals[proposalId].endsAt > 0, "No proposal");
    _;
  }

  function getCurrentProposal() external view returns (Proposal memory) {
    return _proposals[_proposalNonce];
  }

  function getProposalById(uint256 proposalId) external view returns (Proposal memory) {
    return _proposals[proposalId];
  }

  function getCurrentProposalId() external view returns (uint256) {
    return _proposalNonce;
  }

  function getCurrentYesVotes() external view returns (uint256) {
    return _voteCount[_proposalNonce][VoteOptions.YES];
  }

  function getCurrentNoVotes() external view returns (uint256) {
    return _voteCount[_proposalNonce][VoteOptions.NO];
  }

  function getYesVotesById(uint256 proposalId) external view returns (uint256) {
    return _voteCount[proposalId][VoteOptions.YES];
  }

  function getNoVotesById(uint256 proposalId) external view returns (uint256) {
    return _voteCount[proposalId][VoteOptions.NO];
  }

  function getCurrentDepositedVY(address voter) external view returns (uint256) {
    return _deposits[_proposalNonce][voter];
  }

  function getDepositedVYById(uint256 proposalId, address voter) external view returns (uint256) {
    return _deposits[proposalId][voter];
  }

  function hasCurrentProposalEnded() public view hasProposal returns (bool) {
    return block.timestamp > _proposals[_proposalNonce].endsAt;
  }

  function hasProposalEndedById(uint256 proposalId) external view hasProposalById(proposalId) returns (bool) {
    return block.timestamp > _proposals[proposalId].endsAt;
  }

  function voteYes(uint256 quantity) external {
    _vote(VoteOptions.YES, quantity);
  }

  function voteNo(uint256 quantity) external {
    _vote(VoteOptions.NO, quantity);
  }

  function _vote(VoteOptions voteOption, uint256 quantity) private hasProposal {
    require(block.timestamp < _proposals[_proposalNonce].endsAt, "Proposal already ended");
    require(_deposits[_proposalNonce][_msgSender()] == 0, "Already voted");
    require(_vyToken.allowance(_msgSender(), address(this)) >= quantity, "Insufficient VY allowance");
    require(_vyToken.balanceOf(_msgSender()) >= quantity, "Insufficient VY balance");

    _deposits[_proposalNonce][_msgSender()] += quantity;
    _voteCount[_proposalNonce][voteOption] += quantity;
    _vyToken.transferFrom(_msgSender(), address(this), quantity);

    emit Vote(_msgSender(), voteOption, quantity);
  }

  function startMigrationProposal(
    address yieldRateTreasuryDestination,
    address revenueCycleTreasuryDestination,
    address reverseStakingTreasuryDestination
  ) external onlyAdminAgents {
    // Prevent funds locked up in zero address
    require(
      yieldRateTreasuryDestination != address(0) &&
        revenueCycleTreasuryDestination != address(0) &&
        reverseStakingTreasuryDestination != address(0),
      "Invalid address"
    );

    // Should only allow starting new proposal after current one is expired
    // Note: starting first proposal where _proposalNonce is 0 should not require expiration condition
    require(block.timestamp > _proposals[_proposalNonce].endsAt || _proposalNonce == 0, "Proposal still ongoing");

    uint256 endsAt = block.timestamp + votingPeriod;

    // Create new proposal and increment nounce
    _proposals[++_proposalNonce] = Proposal(
      ProposalType.Migration,
      endsAt,
      false,
      MigrationProposal(yieldRateTreasuryDestination, revenueCycleTreasuryDestination, reverseStakingTreasuryDestination),
      RegistrarProposal(address(0))
    );

    // Emit event
    emit StartMigrationProposal(
      _proposalNonce,
      yieldRateTreasuryDestination,
      revenueCycleTreasuryDestination,
      reverseStakingTreasuryDestination,
      endsAt
    );
  }

  function executeMigrationProposal() external hasMigrationAddresses hasProposal onlyAdminAgents {
    require(hasCurrentProposalEnded(), "Proposal still ongoing");
    require(_proposals[_proposalNonce].proposalType == ProposalType.Migration, "Invalid proposal");
    require(_voteCount[_proposalNonce][VoteOptions.YES] >= _voteCount[_proposalNonce][VoteOptions.NO], "Proposal not passed");

    _proposals[_proposalNonce].approved = true;

    // execute VETHYieldRateTreasury migration
    _vethYRT.setMigration(_proposals[_proposalNonce].migration.yieldRateTreasuryDestination);

    // execute VETHRevenueCycleTreasury migration
    _vethRevenueCycleTreasury.setMigration(_proposals[_proposalNonce].migration.revenueCycleTreasuryDestination);

    // execute VETHReverseStakingTreasury migration
    _vethReverseStakingTreasury.setMigration(_proposals[_proposalNonce].migration.reverseStakingTreasuryDestination);
  }

  function startRegistrarProposal(address registrar) external onlyAdminAgents {
    // Prevent funds locked up in zero address
    require(registrar != address(0), "Invalid address");

    // Should only allow starting new proposal after current one is expired
    // Note: starting first proposal where _proposalNonce is 0 should not require expiration condition
    require(block.timestamp > _proposals[_proposalNonce].endsAt || _proposalNonce == 0, "Proposal still ongoing");

    uint256 endsAt = block.timestamp + votingPeriod;

    _proposals[++_proposalNonce] = Proposal(
      ProposalType.Registrar,
      endsAt,
      false,
      MigrationProposal(address(0), address(0), address(0)),
      RegistrarProposal(registrar)
    );

    // Emit event
    emit StartRegistrarProposal(
      _proposalNonce,
      registrar,
      endsAt
    );
  }

  function executeRegistrarProposal() external hasProposal onlyAdminAgents {
    require(hasCurrentProposalEnded(), "Proposal still ongoing");
    require(_proposals[_proposalNonce].proposalType == ProposalType.Registrar, "Invalid proposal");
    require(_voteCount[_proposalNonce][VoteOptions.YES] >= _voteCount[_proposalNonce][VoteOptions.NO], "Proposal not passed");

    _proposals[_proposalNonce].approved = true;

    // Register new Registrar with VYToken
    _vyToken.setRegistrar(_registrar.getEcosystemId(), _proposalNonce);
  }

  // Withdraw from current proposal
  function withdrawDepositedVY() external {
    _withdraw(_proposalNonce);
  }

  // Withdraw by proposal id
  function withdrawDepositedVYById(uint256 proposalId) external {
    _withdraw(proposalId);
  }

  // Withdraw from all proposals
  function withdrawAllDepositedVY() external hasProposal {
    // Check if current proposal is still ongoing - to continue current proposal has to end first
    require(hasCurrentProposalEnded(), "Proposal still ongoing");

    // When _withdraw is called this variable will be false
    bool nothingToWithdraw = true;

    // Loop to withdraw proposals that have deposits
    for (uint proposalId = 1; proposalId <= _proposalNonce; proposalId++) {
      if (_deposits[proposalId][_msgSender()] > 0) { // Check if there is anything to withdraw
        nothingToWithdraw = false;
        _withdraw(proposalId);
      }
    }

    // If nothing to withdraw then warn the user
    require(!nothingToWithdraw, "Nothing to withdraw");
  }

  function _withdraw(uint256 proposalId) private hasProposalById(proposalId) {
    require(block.timestamp > _proposals[proposalId].endsAt, "Proposal still ongoing");
    require(_deposits[proposalId][_msgSender()] > 0, "Nothing to withdraw");
    uint256 quantity = _deposits[proposalId][_msgSender()];
    _deposits[proposalId][_msgSender()] = 0;
    _vyToken.transfer(_msgSender(), quantity);
  }

  function updateAddresses() external override onlyRegistrar {
    _vyToken = VYToken(_registrar.getVYToken());
    _vethYRT = VETHYieldRateTreasury(payable(_registrar.getVETHYieldRateTreasury()));
    _vethRevenueCycleTreasury = VETHRevenueCycleTreasury(_registrar.getVETHRevenueCycleTreasury());
    _vethReverseStakingTreasury = VETHReverseStakingTreasury(payable(_registrar.getVETHReverseStakingTreasury()));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
library StorageSlotUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { AccessControl } from "../lib/access/AccessControl.sol";
import { ERC20 } from "../lib/token/ERC20/ERC20.sol";
import { AdminAgent } from "../access/AdminAgent.sol";
import { BackendAgent } from "../access/BackendAgent.sol";
import { VYRevenueCycleCirculationTracker } from "../exchange/VYRevenueCycleCirculationTracker.sol";
import { Registrar } from "../Registrar.sol";
import { VETHGovernance } from "../governance/VETHGovernance.sol";

contract VYToken is ERC20, AdminAgent, BackendAgent, AccessControl {

  uint256 private constant MULTIPLIER = 10**18;

  // EIP712 Precomputed hashes:
  // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
  bytes32 private constant EIP712DOMAINTYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

  // keccak256("VYToken")
  bytes32 private constant NAME_HASH = 0xc8992ef634b020d3849cb749bb94cf703a7071d02872a417a811fadacc5fdcbb;

  // keccak256("1")
  bytes32 private constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

  // keccak256("VYPermit(address owner,address spender,uint256 amount,uint256 nonce)");
  bytes32 private constant TXTYPE_HASH = 0x085abc97e2d328b3816b8248b9e8aa0e35bb8f414343c830d2d375b0d9b3c98f;

  // solhint-disable-next-line var-name-mixedcase
  bytes32 public DOMAIN_SEPARATOR;
  mapping(address => uint) public nonces;

  bytes32 public constant MAIN_ECOSYSTEM_ID = keccak256(bytes("VY_ETH"));
  bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 private constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");

  uint256 public constant MAX_SUPPLY = 7000000000000000000000000000; // 7 billion hard cap

  mapping(address => bool) private _agents;
  mapping(address => bool) private _minters;
  mapping(bytes32 => address) private _registrars; // Ecosystems
  uint256 private _vyCirculation = 0;
  uint256 private _transferFee = 0; // user transfer fee in %

  event AgentWhitelisted(address recipient);
  event AgentWhitelistRevoked(address recipient);
  event SetRegistrar(address registrar, bytes32 ecosystemId);

  /**
   * @dev Constructor that setup all the role admins.
   */
  constructor(
    string memory name,
    string memory symbol,
    address registrarAddress,
    address[] memory adminAgents,
    address[] memory backendAdminAgents,
    address[] memory backendAgents,
    uint256 transferFee_,
    uint256 initialCirculation
  ) ERC20(name, symbol) AdminAgent(adminAgents) {
    // make OWNER_ROLE the admin role for each role (only people with the role of an admin role can manage that role)
    _setRoleAdmin(WHITELISTER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    // setup deployer to be part of OWNER_ROLE which allow deployer to manage all roles
    _setupRole(OWNER_ROLE, _msgSender());

    // Setup backend
    _setBackendAdminAgents(backendAdminAgents);
    _setBackendAgents(backendAgents);

    // Setup registrar
    _setRegistrar(registrarAddress);

    // Setup EIP712
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        EIP712DOMAINTYPE_HASH,
        NAME_HASH,
        VERSION_HASH,
        block.chainid,
        address(this)
      )
    );

    _transferFee = transferFee_;
    _vyCirculation = initialCirculation;
  }

  function getVYCirculation() external view returns (uint256) {
    return _vyCirculation;
  }

  function getRegistrarById(bytes32 id) external view returns(address) {
    return _registrars[id];
  }

  function isMinter(address _address) external view returns (bool) {
    return _minters[_address];
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    // Check if fee is not zero then it's user to user transfer - send fee to vethRevenueCycleTreasury
    uint256 fee = _calculateTransferFee(_msgSender(), recipient, amount);

    if (fee != 0) {
      address mainRevenueCycleTreasury = _getMainEcosystemRegistrar().getVETHRevenueCycleTreasury();
      _updateCirculationAndSupply(_msgSender(), mainRevenueCycleTreasury, fee);

      super.transfer(recipient, amount - fee); // transfers amount - fee to recipient
      return super.transfer(mainRevenueCycleTreasury, fee); // transfers fee to vethRevenueCycleTreasury
    }

    _updateCirculationAndSupply(_msgSender(), recipient, amount);
    return super.transfer(recipient, amount);
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    // Check if fee is not zero then it's user to user transfer - send fee to vethRevenueCycleTreasury
    uint256 fee = _calculateTransferFee(sender, recipient, amount);

    if (fee != 0) {
      address mainRevenueCycleTreasury = _getMainEcosystemRegistrar().getVETHRevenueCycleTreasury();
      _updateCirculationAndSupply(sender, mainRevenueCycleTreasury, fee);

      super.transferFrom(sender, recipient, amount - fee); // transfers amount - fee to recipient
      return super.transferFrom(sender, mainRevenueCycleTreasury, fee); // transfers fee to vethRevenueCycleTreasury
    }

    _updateCirculationAndSupply(sender, recipient, amount);
    return super.transferFrom(sender, recipient, amount);
  }

  function getTransferFee() external view returns (uint256) {
    return _transferFee;
  }

  function setTransferFee(uint256 fee) external onlyAdminAgents {
    _transferFee = fee;
  }

  /*
   * Register a new ecosystem Registrar with us
   *
   * @dev can only be called by VETHGovernance
   */
  function setRegistrar(bytes32 originEcosystemId, uint proposalNonce) external {
    address registrarAddress = _registrars[originEcosystemId];
    require(registrarAddress != address(0), "Invalid originEcosystemId");

    // Only VETHGovernance of applicable Registrar may call this function
    Registrar registrar = Registrar(registrarAddress);
    VETHGovernance governance = VETHGovernance(registrar.getVETHGovernance());
    require(_msgSender() == address(governance), "Caller must be VETHGovernance");

    VETHGovernance.Proposal memory proposal = governance.getProposalById(proposalNonce);

    // Must be valid proposal
    require(proposal.approved == true && proposal.proposalType == VETHGovernance.ProposalType.Registrar, "Invalid proposal");

    _setRegistrar(proposal.registrar.registrar);
    _setMinter(Registrar(proposal.registrar.registrar));
  }

  /**
   * @dev 1) Must be called by the outgoing contract (contract to be swapped out) as
   * the _msgSender must initiate the transfer.
   * 2) Since the registrar now saves the previous contract, registrarMigrateTokens
   * can be called post-swap
   * 3) Registrar must be not finalized
   */
  function registrarMigrateTokens(bytes32 registrarId, uint256 contractIndex) external {
    // The reason we need this function is to transfer tokens due to a registrar contract
    // swap without modifying the circulation and supply.

    // Require valid registrar id
    address registrarAddress = _registrars[registrarId];
    require(registrarAddress != address(0), "Invalid registar id");

    // Require that this registrar is not finalized
    Registrar registrar = Registrar(registrarAddress);
    _requireRegistrarIsUnfinalized(registrar);

    address prevContract = registrar.getPrevContractByIndex(contractIndex);
    address newContract = registrar.getContractByIndex(contractIndex);

    // Require that _msgSender is prevContract
    require(_msgSender() == prevContract, "Caller must be prevContract");

    // Require newContract should not be the zero address
    require(newContract != address(0), "newContract is the zero address");

    super.transfer(newContract, balanceOf(prevContract));
  }

  function _setRegistrar(address registrar) private {
    require(registrar != address(0), "Invalid address");
    bytes32 ecosystemId = Registrar(registrar).getEcosystemId();
    _registrars[ecosystemId] = registrar;

    emit SetRegistrar(registrar, ecosystemId);
  }

  /**
   * @dev Only whitelisted minters may call this function
   */
  function mint(uint256 amount) public returns (bool) {
    require(_minters[_msgSender()], "Caller is not an allowed minter");
    require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");

    super._mint(_msgSender(), amount);

    return true;
  }

  /**
   * @dev Can only be called by Registrar, in the case of registrar contract swap update.
   * Registrar must not be finalized.
   */
  function setMinter() external {
    Registrar registrar = Registrar(_msgSender());
    require(_registrars[registrar.getEcosystemId()] == _msgSender(), "Invalid registar");
    _requireRegistrarIsUnfinalized(registrar);

    _setMinter(registrar);
  }

  function _setMinter(Registrar registrar) private {
    // Unset previous revenueCycleTreasury
    address prevRevenueCycleTreasury = registrar.getPrevContractByIndex(uint(Registrar.Contract.VETHRevenueCycleTreasury));
    _minters[prevRevenueCycleTreasury] = false;

    // Set current revenueCycleTreasury
    address revenueCycleTreasury = registrar.getVETHRevenueCycleTreasury();
    _minters[revenueCycleTreasury] = true;
  }

  /**
   * @dev Airdrop tokens to holders in case VYToken is migrated.
   * Can only be done if main ecosystem's registrar is not finalized.
   */
  function airdropTokens(address[] calldata _addresses, uint[] calldata _amounts) external onlyBackendAgents {
    require(_addresses.length == _amounts.length, "Argument array length mismatch");
    _requireRegistrarIsUnfinalized(_getMainEcosystemRegistrar()); // Check main ecosystem

    for (uint i = 0; i < _addresses.length; i++) {
      super._mint(_addresses[i], _amounts[i]);
    }
  }

  function grantOwnerRole(address _address) external onlyRole(OWNER_ROLE) {
    grantRole(OWNER_ROLE, _address);
  }

  function grantWhitelisterRole(address _address) external onlyRole(OWNER_ROLE) {
    grantRole(WHITELISTER_ROLE, _address);
  }

  function revokeOwnerRole(address _address) external onlyRole(OWNER_ROLE) {
    revokeRole(OWNER_ROLE, _address);
  }

  function revokeWhitelisterRole(address _address) external onlyRole(OWNER_ROLE) {
    revokeRole(WHITELISTER_ROLE, _address);
  }

  function isWhitelistedAgent(address _address) external view returns (bool) {
    return _agents[_address];
  }

  function whitelistAgent(address _address) external onlyRole(WHITELISTER_ROLE) {
    require(_agents[_address] == false, "Already whitelisted");
    _agents[_address] = true;
    emit AgentWhitelisted(_address);
  }

  function revokeWhitelistedAgent(address _address) external onlyRole(WHITELISTER_ROLE) {
    require(_agents[_address] == true, "Not whitelisted");
    delete _agents[_address];
    emit AgentWhitelistRevoked(_address);
  }

  function permit(address owner, address spender, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
    // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
    bytes32 txInputHash = keccak256(abi.encode(TXTYPE_HASH, owner, spender, amount, nonces[owner]));
    bytes32 totalHash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash));

    address recoveredAddress = ecrecover(totalHash, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, "VYToken: INVALID_SIGNATURE");

    nonces[owner] = nonces[owner] + 1;
    _approve(owner, spender, amount);
  }

  function _getMainEcosystemRegistrar() private view returns (Registrar) {
    address registrarAddress = _registrars[MAIN_ECOSYSTEM_ID];

    return Registrar(registrarAddress);
  }

  function _updateCirculationAndSupply(address from, address to, uint256 amount) private {
    if (_minters[to]) {
      _decreaseCirculationAndSupply(amount, to);
    } else if (_minters[from]) {
      _increaseCirculationAndSupply(amount, from);
    }
  }

  function _increaseCirculationAndSupply(uint256 amount, address minter) internal {
    _vyCirculation += amount;

    VYRevenueCycleCirculationTracker(minter).increaseRevenueCycleCirculation(amount);
  }

  function _decreaseCirculationAndSupply(uint256 amount, address minter) internal {
    if (amount > _vyCirculation) {
      _vyCirculation = 0;
    } else {
      _vyCirculation -= amount;
    }

    VYRevenueCycleCirculationTracker(minter).decreaseRevenueCycleCirculation(amount);
  }

  function _calculateTransferFee(address from, address to, uint256 amount) private view returns (uint256) {
    // Check for user to user transfer
    if (!_agents[from] && !_agents[to]) {
      uint256 transferFee = amount * _transferFee / MULTIPLIER;
      return transferFee;
    }

    return 0;
  }

  function _requireRegistrarIsUnfinalized(Registrar registrar) private view {
    require(!registrar.isFinalized(), "Registrar already finalized");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { AdminGovernanceAgent } from "../access/AdminGovernanceAgent.sol";
import { Governable } from "../governance/Governable.sol";
import { VETHReverseStakingTreasury } from "../VETHReverseStakingTreasury.sol";
import { RegistrarClient } from "../RegistrarClient.sol";

contract VETHYieldRateTreasury is AdminGovernanceAgent, Governable, RegistrarClient {

  address private _migration;
  VETHReverseStakingTreasury private _vethReverseStakingTreasury;

  event ReverseStakingTransfer(address recipient, uint256 amount);

  constructor(
    address registrarAddress,
    address[] memory adminGovAgents
  ) AdminGovernanceAgent(adminGovAgents)
    RegistrarClient(registrarAddress) {
  }

  modifier onlyReverseStakingTreasury() {
    require(address(_vethReverseStakingTreasury) == _msgSender(), "Unauthorized");
    _;
  }

  function getYieldRateTreasuryValue() external view returns (uint256) {
    return address(this).balance + _vethReverseStakingTreasury.getTotalClaimedYield();
  }

  function getMigration() external view returns (address) {
    return _migration;
  }

  function setMigration(address destination) external onlyGovernance {
    _migration = destination;
  }

  function transferMigration(uint256 amount) external onlyAdminGovAgents {
    require(_migration != address(0), "Migration not set");
    _transfer(_migration, amount, "");
  }

  function reverseStakingTransfer(address recipient, uint256 amount) external onlyReverseStakingTreasury {
    _transfer(recipient, amount, "");
    emit ReverseStakingTransfer(recipient, amount);
  }

  function reverseStakingRoute(address recipient, uint256 amount, bytes memory selector) external onlyReverseStakingTreasury {
    _transfer(recipient, amount, selector);
    emit ReverseStakingTransfer(recipient, amount);
  }

  function updateAddresses() external override onlyRegistrar {
    _vethReverseStakingTreasury = VETHReverseStakingTreasury(payable(_registrar.getVETHReverseStakingTreasury()));
    _updateGovernable(_registrar);
  }

  function _transfer(address recipient, uint256 amount, bytes memory payload) private {
    require(address(this).balance >= amount, "Insufficient balance");
    (bool sent,) = recipient.call{value: amount}(payload);
    require(sent, "Failed to send Ether");
  }

  receive() external payable {}
}