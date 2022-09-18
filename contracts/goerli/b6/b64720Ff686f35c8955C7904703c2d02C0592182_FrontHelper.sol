// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../tools/tokens/IERC20Details.sol';
import '../interfaces/IProxyFactory.sol';
import '../interfaces/IInsuredPool.sol';
import '../interfaces/IInsurerPool.sol';
import '../interfaces/IPremiumActuary.sol';
import '../interfaces/IPremiumSource.sol';
import '../interfaces/IManagedCollateralCurrency.sol';
import '../funds/interfaces/ICollateralFund.sol';
import '../premium/interfaces/IPremiumFund.sol';
import '../access/AccessHelper.sol';
import '../governance/interfaces/IApprovalCatalog.sol';

contract FrontHelper is AccessHelper {
  constructor(IAccessController acl) AccessHelper(acl) {}

  struct CollateralFundInfo {
    address fund;
    address collateral;
    address yieldDistributor;
    address[] assets;
  }

  struct InsurerInfo {
    address pool;
    address collateral;
    address premiumFund;
    bool chartered;
  }

  // slither-disable-next-line calls-loop
  function getAddresses()
    external
    view
    returns (
      address accessController,
      address proxyCatalog,
      address approvalCatalog,
      address priceRouter,
      CollateralFundInfo[] memory collateralFunds,
      InsurerInfo[] memory insurers
    )
  {
    IAccessController ac = remoteAcl();
    accessController = address(ac);

    proxyCatalog = ac.getAddress(AccessFlags.PROXY_FACTORY);
    approvalCatalog = ac.getAddress(AccessFlags.APPROVAL_CATALOG);
    priceRouter = ac.getAddress(AccessFlags.PRICE_ROUTER);

    address[] memory list = ac.roleHolders(AccessFlags.COLLATERAL_FUND_LISTING);

    collateralFunds = new CollateralFundInfo[](list.length);
    for (uint256 i = list.length; i > 0; ) {
      i--;
      ICollateralFund fund = ICollateralFund(collateralFunds[i].fund = list[i]);
      address cc = fund.collateral();
      collateralFunds[i].collateral = cc;
      collateralFunds[i].assets = fund.assets();
      collateralFunds[i].yieldDistributor = IManagedCollateralCurrency(cc).borrowManager();
    }

    list = ac.roleHolders(AccessFlags.INSURER_POOL_LISTING);

    insurers = new InsurerInfo[](list.length);
    for (uint256 i = list.length; i > 0; ) {
      i--;
      IInsurerPool insurer = IInsurerPool(insurers[i].pool = list[i]);
      insurers[i].collateral = insurer.collateral();
      insurers[i].chartered = insurer.charteredDemand();
      insurers[i].premiumFund = IPremiumActuary(address(insurer)).premiumDistributor();
    }
  }

  struct PremiumFundInfo {
    address fund;
    PremiumTokenInfo[] knownTokens;
  }

  struct PremiumTokenInfo {
    address token;
    PremiumActuaryInfo[] actuaries;
  }

  struct PremiumActuaryInfo {
    address actuary;
    address[] activeSources;
  }

  function getPremiumFundInfo(address[] calldata premiumFunds) external view returns (PremiumFundInfo[] memory funds) {
    funds = new PremiumFundInfo[](premiumFunds.length);
    for (uint256 i = premiumFunds.length; i > 0; ) {
      i--;
      funds[i] = _getPremiumFundInfo(IPremiumFund(premiumFunds[i]));
    }
  }

  // slither-disable-next-line calls-loop
  function _getPremiumFundInfo(IPremiumFund fund) private view returns (PremiumFundInfo memory info) {
    info.fund = address(fund);

    address[] memory knownTokens = fund.knownTokens();

    if (knownTokens.length > 0) {
      info.knownTokens = new PremiumTokenInfo[](knownTokens.length);

      for (uint256 i = knownTokens.length; i > 0; ) {
        i--;
        info.knownTokens[i] = _getDistributorTokenInfo(fund, knownTokens[i]);
      }
    }
  }

  // slither-disable-next-line calls-loop
  function _getDistributorTokenInfo(IPremiumFund fund, address token) private view returns (PremiumTokenInfo memory info) {
    info.token = token;

    address[] memory actuaries = fund.actuariesOfToken(token);

    if (actuaries.length > 0) {
      info.actuaries = new PremiumActuaryInfo[](actuaries.length);

      for (uint256 i = actuaries.length; i > 0; ) {
        i--;
        address[] memory sources = fund.activeSourcesOf(actuaries[i], token);
        info.actuaries[i] = PremiumActuaryInfo({actuary: actuaries[i], activeSources: sources});
      }
    }
  }

  // slither-disable-next-line calls-loop
  function batchBalanceOf(address[] calldata users, address[] calldata tokens) external view returns (uint256[] memory balances) {
    balances = new uint256[](users.length * tokens.length);

    for (uint256 i = 0; i < users.length; i++) {
      for (uint256 j = 0; j < tokens.length; j++) {
        balances[i * tokens.length + j] = IERC20(tokens[j]).balanceOf(users[i]);
      }
    }
  }

  struct TokenDetails {
    string symbol;
    string name;
    uint8 decimals;
  }

  // slither-disable-next-line calls-loop
  function batchTokenDetails(address[] calldata tokens) external view returns (TokenDetails[] memory details) {
    details = new TokenDetails[](tokens.length);

    for (uint256 j = 0; j < tokens.length; j++) {
      IERC20Details token = IERC20Details(tokens[j]);
      details[j] = TokenDetails({symbol: token.symbol(), name: token.name(), decimals: token.decimals()});
    }
  }

  function batchStatusOfInsured(address insured, address[] calldata insurers) external view returns (MemberStatus[] memory) {
    MemberStatus[] memory result = new MemberStatus[](insurers.length);
    for (uint256 i = insurers.length; i > 0; ) {
      i--;
      // slither-disable-next-line calls-loop
      result[i] = IInsurerPool(insurers[i]).statusOf(insured);
    }
    return result;
  }

  function batchBalancesOf(address account, address[] calldata insurers)
    external
    view
    returns (
      uint256[] memory values,
      uint256[] memory balances,
      uint256[] memory swappables
    )
  {
    values = new uint256[](insurers.length);
    balances = new uint256[](insurers.length);
    swappables = new uint256[](insurers.length);
    for (uint256 i = insurers.length; i > 0; ) {
      i--;
      // slither-disable-next-line calls-loop
      (values[i], balances[i], swappables[i]) = IInsurerPool(insurers[i]).balancesOf(account);
    }
  }

  function getInsuredReconcileInfo(address[] calldata insureds)
    external
    view
    returns (
      address[] memory premiumTokens,
      address[][] memory chartered,
      ReceivableByReconcile[][] memory receivables
    )
  {
    premiumTokens = new address[](insureds.length);
    chartered = new address[][](insureds.length);
    receivables = new ReceivableByReconcile[][](insureds.length);

    for (uint256 i = insureds.length; i > 0; ) {
      i--;
      address insured = insureds[i];
      // slither-disable-next-line calls-loop
      premiumTokens[i] = IPremiumSource(insured).premiumToken();

      // slither-disable-next-line calls-loop
      (, chartered[i]) = IInsuredPool(insured).getInsurers();

      address[] memory insurers = chartered[i];
      ReceivableByReconcile[] memory c = receivables[i] = new ReceivableByReconcile[](insurers.length);

      for (uint256 j = insurers.length; j > 0; ) {
        j--;
        // slither-disable-next-line calls-loop
        c[j] = IReconcilableInsuredPool(insured).receivableByReconcileWithInsurer(insurers[j]);
      }
    }
  }

  function getSwapInfo(
    address premiumFund,
    address actuary,
    address[] calldata assets
  ) external view returns (IPremiumFund.AssetBalanceInfo[] memory balances) {
    balances = new IPremiumFund.AssetBalanceInfo[](assets.length);
    for (uint256 i = assets.length; i > 0; ) {
      i--;
      // slither-disable-next-line calls-loop
      balances[i] = IPremiumFund(premiumFund).assetBalance(actuary, assets[i]);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';

library Errors {
  function illegalState(bool ok) internal pure {
    if (!ok) {
      revert IllegalState();
    }
  }

  function illegalValue(bool ok) internal pure {
    if (!ok) {
      revert IllegalValue();
    }
  }

  function accessDenied(bool ok) internal pure {
    if (!ok) {
      revert AccessDenied();
    }
  }

  function panic(uint256 code) internal pure {
    // solhint-disable no-inline-assembly
    assembly {
      mstore(0x00, 0x4e487b71)
      mstore(0x20, code)
      revert(0x1C, 0x24)
    }
  }

  function overflow() internal pure {
    // solhint-disable no-inline-assembly
    assembly {
      mstore(0x00, 0x4e487b71)
      mstore(0x20, 0x11)
      revert(0x1C, 0x24)
    }
  }

  function _mutable() private returns (bool) {}

  function notImplemented() internal {
    if (!_mutable()) {
      revert NotImplemented();
    }
  }

  error OperationPaused();
  error IllegalState();
  error Impossible();
  error IllegalValue();
  error NotSupported();
  error NotImplemented();
  error AccessDenied();

  error ExpiredPermit();
  error WrongPermitSignature();

  error ExcessiveVolatility();
  error ExcessiveVolatilityLock(uint256 mask);

  error CallerNotProxyOwner();
  error CallerNotEmergencyAdmin();
  error CallerNotSweepAdmin();
  error CallerNotOracleAdmin();

  error CollateralTransferFailed();

  error ContractRequired();
  error ImplementationRequired();

  error UnknownPriceAsset(address asset);
  error PriceExpired(address asset);
}

library Sanity {
  // slither-disable-next-line shadowing-builtin
  function require(bool ok) internal pure {
    // This code should be commented out on release
    if (!ok) {
      revert Errors.Impossible();
    }
  }
}

library State {
  // slither-disable-next-line shadowing-builtin
  function require(bool ok) internal pure {
    if (!ok) {
      revert Errors.IllegalState();
    }
  }
}

library Value {
  // slither-disable-next-line shadowing-builtin
  function require(bool ok) internal pure {
    if (!ok) {
      revert Errors.IllegalValue();
    }
  }

  function requireContract(address a) internal view {
    if (!Address.isContract(a)) {
      revert Errors.ContractRequired();
    }
  }
}

library Access {
  // slither-disable-next-line shadowing-builtin
  function require(bool ok) internal pure {
    if (!ok) {
      revert Errors.AccessDenied();
    }
  }
}

library Arithmetic {
  // slither-disable-next-line shadowing-builtin
  function require(bool ok) internal pure {
    if (!ok) {
      Errors.overflow();
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IERC20Details {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IProxyFactory {
  function isAuthenticProxy(address proxy) external view returns (bool);

  function createProxy(
    address adminAddress,
    bytes32 implName,
    address context,
    bytes calldata params
  ) external returns (address);

  function createProxyWithImpl(
    address adminAddress,
    bytes32 implName,
    address impl,
    bytes calldata params
  ) external returns (address);

  function upgradeProxy(address proxyAddress, bytes calldata params) external returns (bool);

  function upgradeProxyWithImpl(
    address proxyAddress,
    address newImpl,
    bool checkRevision,
    bytes calldata params
  ) external returns (bool);

  event ProxyCreated(address indexed proxy, address indexed impl, string typ, bytes params, address indexed admin);
  event ProxyUpdated(address indexed proxy, address indexed impl, string typ, bytes params);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';

interface IInsuredPool is ICollateralized {
  /// @notice Called by insurer during or after requestJoin() to inform this insured if it was accepted or not
  /// @param accepted true if accepted by the insurer
  function joinProcessed(bool accepted) external;

  /// @notice Invoked by chartered pools to request more coverage demand
  /// @param amount a hint on demand amount, 0 means default
  /// @param loopLimit a max number of iterations
  function pullCoverageDemand(uint256 amount, uint256 loopLimit) external returns (bool);

  /// @notice Get this insured params
  /// @return The insured params
  function insuredParams() external view returns (InsuredParams memory);

  /// @notice Directly offer coverage to the insured
  /// @param offeredAmount The amount of coverage being offered
  /// @return acceptedAmount The amount of coverage accepted by the insured
  /// @return rate The rate that the insured is paying for the coverage
  function offerCoverage(uint256 offeredAmount) external returns (uint256 acceptedAmount, uint256 rate);

  function rateBands() external view returns (InsuredRateBand[] memory bands, uint256 maxBands);

  function getInsurers() external view returns (address[] memory, address[] memory);
}

interface IReconcilableInsuredPool is IInsuredPool {
  function receivableByReconcileWithInsurer(address insurer) external view returns (ReceivableByReconcile memory);
}

struct ReceivableByReconcile {
  uint256 receivableCoverage;
  uint256 demandedCoverage;
  uint256 providedCoverage;
  uint256 rate;
  uint256 accumulated;
}

struct InsuredParams {
  uint128 minPerInsurer;
}

struct InsuredRateBand {
  uint64 premiumRate;
  uint96 coverageDemand;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/tokens/IERC20.sol';
import './ICoverageDistributor.sol';
import '../insurer/Rounds.sol';

interface IInsurerPoolBase is ICollateralized, ICharterable {
  /// @dev returns ratio of $IC to $CC, this starts as 1 (RAY)
  function exchangeRate() external view returns (uint256);
}

interface IPerpetualInsurerPool is IInsurerPoolBase {
  /// @notice The interest of the account is their earned premium amount
  /// @param account The account to query
  /// @return rate The current interest rate of the account
  /// @return accumulated The current earned premium of the account
  function interestOf(address account) external view returns (uint256 rate, uint256 accumulated);

  /// @notice Withdrawable amount of this account
  /// @param account The account to query
  /// @return amount The amount withdrawable
  function withdrawable(address account) external view returns (uint256 amount);

  /// @notice Attempt to withdraw all of a user's coverage
  /// @return The amount withdrawn
  function withdrawAll() external returns (uint256);
}

interface IInsurerPool is IERC20, IInsurerPoolBase, ICoverageDistributor {
  function statusOf(address) external view returns (MemberStatus);

  /// @dev returns balances of a user
  /// @return value The value of the pool share tokens (and provided coverage)
  /// @return balance The number of the pool share tokens
  /// @return swappable The amount of user's value which can be swapped to tokens (e.g. premium earned)
  function balancesOf(address account)
    external
    view
    returns (
      uint256 value,
      uint256 balance,
      uint256 swappable
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';

interface IPremiumActuary is ICollateralized {
  function premiumDistributor() external view returns (address);

  function collectDrawdownPremium() external returns (uint256 maxDrawdownValue, uint256 availableDrawdownValue);

  function burnPremium(
    address account,
    uint256 value,
    address drawdownRecepient
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';

interface IPremiumSource {
  function premiumToken() external view returns (address);

  function collectPremium(
    address actuary,
    address token,
    uint256 amount,
    uint256 value
  ) external;
}

interface IPremiumSourceDelegate {
  function collectPremium(
    address actuary,
    address token,
    uint256 amount,
    uint256 value,
    address recipient
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/tokens/IERC20.sol';

interface IManagedCollateralCurrency is IERC20 {
  /// @dev regular mint
  function mint(address account, uint256 amount) external;

  /// @dev an optimized combo, equivalent of mint(onBehalf, mintAmount) and then transfers (mintAmount + balanceAmount) from onBehalf to recipient
  /// @dev balanceAmount can be uint256.max to take whole balance
  function mintAndTransfer(
    address onBehalf,
    address recepient,
    uint256 mintAmount,
    uint256 balanceAmount
  ) external;

  function transferOnBehalf(
    address onBehalf,
    address recipient,
    uint256 amount
  ) external;

  function burn(address account, uint256 amount) external;

  function isLiquidityProvider(address account) external view returns (bool);

  function isRegistered(address account) external view returns (bool);

  function borrowManager() external view returns (address); // ICollateralStakeManager
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/ICollateralized.sol';

interface ICollateralFund is ICollateralized {
  function setApprovalsFor(
    address operator,
    uint256 access,
    bool approved
  ) external;

  function setAllApprovalsFor(address operator, uint256 access) external;

  function getAllApprovalsFor(address account, address operator) external view returns (uint256);

  function isApprovedFor(
    address account,
    address operator,
    uint256 access
  ) external view returns (bool);

  function deposit(
    address account,
    address token,
    uint256 tokenAmount
  ) external returns (uint256);

  function invest(
    address account,
    address token,
    uint256 tokenAmount,
    address investTo
  ) external returns (uint256);

  function investIncludingDeposit(
    address account,
    uint256 depositValue,
    address token,
    uint256 tokenAmount,
    address investTo
  ) external returns (uint256);

  function withdraw(
    address account,
    address to,
    address token,
    uint256 amount
  ) external returns (uint256);

  function assets() external view returns (address[] memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../../interfaces/ICollateralized.sol';

interface IPremiumFund is ICollateralized {
  // function priceOf(address token) external view returns (uint256);

  function syncAsset(
    address actuary,
    uint256 sourceLimit,
    address targetToken
  ) external;

  function syncAssets(
    address actuary,
    uint256 sourceLimit,
    address[] calldata targetTokens
  ) external returns (uint256);

  function swapAsset(
    address actuary,
    address account,
    address recipient,
    uint256 valueToSwap,
    address targetToken,
    uint256 minAmount
  ) external returns (uint256 tokenAmount);

  struct SwapInstruction {
    uint256 valueToSwap;
    address targetToken;
    uint256 minAmount;
    address recipient;
  }

  function swapAssets(
    address actuary,
    address account,
    SwapInstruction[] calldata instructions
  ) external returns (uint256[] memory tokenAmounts);

  function knownTokens() external view returns (address[] memory);

  function actuariesOfToken(address token) external view returns (address[] memory);

  function actuaries() external view returns (address[] memory);

  function activeSourcesOf(address actuary, address token) external view returns (address[] memory);

  struct AssetBalanceInfo {
    uint256 amount;
    uint256 stravation;
    uint256 price;
    uint256 feeFactor;
    uint256 valueRate;
    uint32 since;
  }

  function assetBalance(address actuary, address asset) external view returns (AssetBalanceInfo memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../interfaces/IProxyFactory.sol';
import './interfaces/IAccessController.sol';
import './AccessLib.sol';
import './AccessFlags.sol';

abstract contract AccessHelper {
  using AccessLib for IAccessController;

  IAccessController private immutable _remoteAcl;

  constructor(IAccessController acl) {
    _remoteAcl = acl;
  }

  function remoteAcl() internal view virtual returns (IAccessController) {
    return _remoteAcl;
  }

  function hasRemoteAcl() internal view returns (bool) {
    return address(remoteAcl()) != address(0);
  }

  function isAdmin(address addr) internal view virtual returns (bool) {
    IAccessController acl = remoteAcl();
    return (address(acl) != address(0)) && acl.isAdmin(addr);
  }

  function owner() public view returns (address) {
    IAccessController acl = remoteAcl();
    return address(acl) != address(0) ? acl.owner() : address(0);
  }

  function _onlyAdmin() private view {
    Access.require(isAdmin(msg.sender));
  }

  modifier onlyAdmin() {
    _onlyAdmin();
    _;
  }

  function hasAnyAcl(address subject, uint256 flags) internal view virtual returns (bool) {
    return remoteAcl().hasAnyOf(subject, flags);
  }

  function hasAllAcl(address subject, uint256 flags) internal view virtual returns (bool) {
    return remoteAcl().hasAllOf(subject, flags);
  }

  function _requireAnyFor(address subject, uint256 flags) private view {
    Access.require(hasAnyAcl(subject, flags));
  }

  function _requireAllFor(address subject, uint256 flags) private view {
    Access.require(hasAllAcl(subject, flags));
  }

  modifier aclHas(uint256 flags) {
    _requireAnyFor(msg.sender, flags);
    _;
  }

  modifier aclHasAny(uint256 flags) {
    _requireAnyFor(msg.sender, flags);
    _;
  }

  modifier aclHasAll(uint256 flags) {
    _requireAllFor(msg.sender, flags);
    _;
  }

  modifier aclHasAnyFor(address subject, uint256 flags) {
    _requireAnyFor(subject, flags);
    _;
  }

  modifier aclHasAllFor(address subject, uint256 flags) {
    _requireAllFor(subject, flags);
    _;
  }

  function _onlyEmergencyAdmin() private view {
    if (!hasAnyAcl(msg.sender, AccessFlags.EMERGENCY_ADMIN)) {
      revert Errors.CallerNotEmergencyAdmin();
    }
  }

  modifier onlyEmergencyAdmin() {
    _onlyEmergencyAdmin();
    _;
  }

  function _onlySweepAdmin() private view {
    if (!hasAnyAcl(msg.sender, AccessFlags.SWEEP_ADMIN)) {
      revert Errors.CallerNotSweepAdmin();
    }
  }

  modifier onlySweepAdmin() {
    _onlySweepAdmin();
    _;
  }

  function getProxyFactory() internal view returns (IProxyFactory) {
    return IProxyFactory(getAclAddress(AccessFlags.PROXY_FACTORY));
  }

  function getAclAddress(uint256 t) internal view returns (address) {
    IAccessController acl = remoteAcl();
    return address(acl) == address(0) ? address(0) : acl.getAddress(t);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IApprovalCatalog {
  struct ApprovedPolicy {
    bytes32 requestCid;
    bytes32 approvalCid;
    address insured;
    uint16 riskLevel;
    uint80 basePremiumRate;
    string policyName;
    string policySymbol;
    address premiumToken;
    uint96 minPrepayValue;
    uint32 rollingAdvanceWindow;
    uint32 expiresAt;
    bool applied;
  }

  struct ApprovedPolicyForInsurer {
    uint16 riskLevel;
    uint80 basePremiumRate;
    address premiumToken;
  }

  function hasApprovedApplication(address insured) external view returns (bool);

  function getApprovedApplication(address insured) external view returns (ApprovedPolicy memory);

  function applyApprovedApplication() external returns (ApprovedPolicy memory);

  function getAppliedApplicationForInsurer(address insured) external view returns (bool valid, ApprovedPolicyForInsurer memory data);

  struct ApprovedClaim {
    bytes32 requestCid;
    bytes32 approvalCid;
    uint16 payoutRatio;
    uint32 since;
  }

  function hasApprovedClaim(address insured) external view returns (bool);

  function getApprovedClaim(address insured) external view returns (ApprovedClaim memory);

  function applyApprovedClaim(address insured) external returns (ApprovedClaim memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface ICollateralized {
  /// @dev address of the collateral fund and coverage token ($CC)
  function collateral() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP excluding events to avoid linearization issues.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';
import './ICharterable.sol';

interface IDemandableCoverage {
  /// @dev size of collateral allocation chunk made by this pool
  function coverageUnitSize() external view returns (uint256);

  /// @notice Add demand for coverage
  /// @dev can only be called by an accepted insured pool
  /// @param unitCount Number of *units* of coverage demand to add
  /// @param premiumRate The rate paid on the coverage
  /// @param hasMore Whether the insured has more demand it would like to request after this
  /// @return addedCount Number of units of demand that were actually added
  function addCoverageDemand(
    uint256 unitCount,
    uint256 premiumRate,
    bool hasMore,
    uint256 loopLimit
  ) external returns (uint256 addedCount);

  /// @notice Cancel coverage that has been demanded, but not filled yet
  /// @dev can only be called by an accepted insured pool
  /// @param unitCount The number of units that wishes to be cancelled
  /// @return cancelledUnits The amount of units that were cancelled
  /// @return rateBands Distribution of cancelled uints by rate-bands, each aeeay value has higher 40 bits as rate, and the rest as number of units
  function cancelCoverageDemand(
    address insured,
    uint256 unitCount,
    uint256 loopLimit
  ) external returns (uint256 cancelledUnits, uint256[] memory rateBands);
}

interface ICancellableCoverage {
  /// @dev size of collateral allocation chunk made by this pool
  function coverageUnitSize() external view returns (uint256);

  /// @notice Cancel coverage for the sender
  /// @dev Called by insureds
  /// @param payoutRatio The RAY ratio of how much of provided coverage should be paid out
  /// @dev e.g payoutRatio = 5e26 means 50% of coverage is paid
  /// @return payoutValue The amount of coverage paid out to the insured
  function cancelCoverage(address insured, uint256 payoutRatio) external returns (uint256 payoutValue);
}

interface IReceivableCoverage is ICancellableCoverage {
  ///@notice Get the amount of coverage demanded and filled, and the total premium rate and premium charged
  ///@param insured The insured pool
  ///@return availableCoverage The amount coverage in terms of $CC
  ///@return coverage All the details relating to the coverage, demand and premium
  function receivableDemandedCoverage(address insured, uint256 loopLimit)
    external
    view
    returns (uint256 availableCoverage, DemandedCoverage memory coverage);

  /// @notice Transfer the amount of coverage that been filled to the insured since last called
  /// @dev Only should be called when charteredDemand is true
  /// @dev No use in calling this after coverage demand is fully fulfilled
  /// @param insured The insured to be updated
  /// @return receivedCoverage amount of coverage the Insured received
  /// @return receivedCollateral amount of collateral sent to the Insured
  /// @return coverage Up to date information for this insured
  function receiveDemandedCoverage(address insured, uint256 loopLimit)
    external
    returns (
      uint256 receivedCoverage,
      uint256 receivedCollateral,
      DemandedCoverage memory
    );
}

interface ICoverageDistributor is IDemandableCoverage, IReceivableCoverage {
  function coverageUnitSize() external view override(ICancellableCoverage, IDemandableCoverage) returns (uint256);
}

struct DemandedCoverage {
  uint256 totalDemand; // total demand added to insurer
  uint256 totalCovered; // total coverage allocated by insurer (can not exceed total demand)
  uint256 pendingCovered; // coverage that is allocated, but can not be given yet (should reach unit size)
  uint256 premiumRate; // total premium rate accumulated accross all units filled-in with coverage
  uint256 totalPremium; // time-cumulated of premiumRate
  uint32 premiumUpdatedAt;
  uint32 premiumRateUpdatedAt;
}

struct TotalCoverage {
  uint256 totalCoverable; // total demand that can be covered now (already balanced) - this value is not provided per-insured
  uint88 usableRounds;
  uint88 openRounds;
  uint64 batchCount;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

/*

UnitPremiumRate per sec * 365 days <= 1 WAD (i.e. 1 WAD = 100% of coverage p.a.)
=>> UnitPremiumRate is uint40
=>> timestamp ~80y

=>> RoundPremiumRate = UnitPremiumRate (40) * unitPerRound (16) = 56

=>> InsuredPremiumRate = UnitPremiumRate (40) * avgUnits (24) = 64
=>> AccumulatedInsuredPremiumRate = InsuredPremiumRate (64) * timestamp (32) = 96

=>> PoolPremiumRate = UnitPremiumRate (40) * maxUnits (64) = 104
=>> PoolAccumulatedPremiumRate = PoolPremiumRate (104) * timestamp (32) = 140

*/

library Rounds {
  /// @dev must be equal to bit size of Demand.premiumRate
  uint8 internal constant DEMAND_RATE_BITS = 40;

  /// @dev demand log entry, related to a single insurd pool
  struct Demand {
    /// @dev first batch that includes this demand
    uint64 startBatchNo;
    /// @dev premiumRate for this demand. See DEMAND_RATE_BITS
    uint40 premiumRate;
    /// @dev number of rounds accross all batches where this demand was added
    uint24 rounds;
    /// @dev number of units added to each round by this demand
    uint16 unitPerRound;
  }

  struct InsuredParams {
    /// @dev a minimum number of units to be allocated for an insured in a single batch. Best effort, but may be ignored.
    uint24 minUnits;
    /// @dev a maximum % of units this insured can have per round. This is a hard limit.
    uint16 maxShare;
    /// @dev a minimum premium rate to accept new coverage demand
    uint40 minPremiumRate;
  }

  struct InsuredEntry {
    /// @dev batch number to add next demand (if it will be open) otherwise it will start with the earliest open batch
    uint64 nextBatchNo;
    /// @dev total number of units demanded by this insured pool
    uint64 demandedUnits;
    /// @dev see InsuredParams
    PackedInsuredParams params;
    /// @dev status of the insured pool
    MemberStatus status;
  }

  struct Coverage {
    /// @dev total number of units covered for this insured pool
    uint64 coveredUnits;
    /// @dev index of Demand entry that is covered partially or will be covered next
    uint64 lastUpdateIndex;
    /// @dev Batch that is a part of the partially covered Demand
    uint64 lastUpdateBatchNo;
    /// @dev number of rounds within the Demand (lastUpdateIndex) starting from Demand's startBatchNo till lastUpdateBatchNo
    uint24 lastUpdateRounds;
    /// @dev number of rounds of a partial batch included into coveredUnits
    uint24 lastPartialRoundNo;
  }

  struct CoveragePremium {
    /// @dev total premium collected till lastUpdatedAt
    uint96 coveragePremium;
    /// @dev premium collection rate at lastUpdatedAt
    uint64 coveragePremiumRate;
    // uint64
    /// @dev time of the last updated applied
    uint32 lastUpdatedAt;
  }

  /// @dev Draft round can NOT receive coverage, more units can be added, always unbalanced
  /// @dev ReadyMin is a Ready round where more units can be added, may be unbalanced
  /// @dev Ready round can receive coverage, more units can NOT be added, balanced
  /// @dev Full round can NOT receive coverage, more units can NOT be added - full rounds are summed up and ignored further
  enum State {
    Draft,
    ReadyMin,
    Ready,
    Full
  }

  struct Batch {
    /// @dev sum of premium rates provided by all units (from different insured pools), per round
    uint56 roundPremiumRateSum;
    /// @dev next batch number (one-way linked list)
    uint64 nextBatchNo;
    /// @dev total number of units befor this batch, this value may not be exact for non-ready batches
    uint80 totalUnitsBeforeBatch;
    /// @dev number of rounds within the batch, can only be zero for an empty (not initialized batch)
    uint24 rounds;
    /// @dev number of units for each round of this batch
    uint16 unitPerRound;
    /// @dev state of this batch
    State state;
  }

  function isFull(Batch memory b) internal pure returns (bool) {
    return isFull(b.state);
  }

  function isOpen(Batch memory b) internal pure returns (bool) {
    return isOpen(b.state);
  }

  function isReady(Batch memory b) internal pure returns (bool) {
    return isReady(b.state);
  }

  function isDraft(State state) internal pure returns (bool) {
    return state == State.Draft;
  }

  function isFull(State state) internal pure returns (bool) {
    return state == State.Full;
  }

  function isOpen(State state) internal pure returns (bool) {
    return state <= State.ReadyMin;
  }

  function isReady(State state) internal pure returns (bool) {
    return state >= State.ReadyMin && state <= State.Ready;
  }

  type PackedInsuredParams is uint80;

  function packInsuredParams(
    uint24 minUnits_,
    uint16 maxShare_,
    uint40 minPremiumRate_
  ) internal pure returns (PackedInsuredParams) {
    return PackedInsuredParams.wrap(uint80((uint256(minPremiumRate_) << 40) | (uint256(maxShare_) << 24) | minUnits_));
  }

  function unpackInsuredParams(PackedInsuredParams v) internal pure returns (InsuredParams memory p) {
    p.minUnits = minUnits(v);
    p.maxShare = maxShare(v);
    p.minPremiumRate = minPremiumRate(v);
  }

  function minUnits(PackedInsuredParams v) internal pure returns (uint24) {
    return uint24(PackedInsuredParams.unwrap(v));
  }

  function maxShare(PackedInsuredParams v) internal pure returns (uint16) {
    return uint16(PackedInsuredParams.unwrap(v) >> 24);
  }

  function minPremiumRate(PackedInsuredParams v) internal pure returns (uint40) {
    return uint40(PackedInsuredParams.unwrap(v) >> 40);
  }
}

enum MemberStatus {
  Unknown,
  JoinCancelled,
  JoinRejected,
  JoinFailed,
  Declined,
  Joining,
  Accepted,
  Banned,
  NotApplicable
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface ICharterable {
  /// @dev indicates how the demand from insured pools is handled:
  /// * Chartered demand will be allocated without calling IInsuredPool, coverage units can be partially filled in.
  /// * Non-chartered (potential) demand can only be allocated after calling IInsuredPool.tryAddCoverage first, units can only be allocated in full.
  function charteredDemand() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './IRemoteAccessBitmask.sol';
import '../../tools/upgradeability/IProxy.sol';

/// @dev Main registry of permissions and addresses
interface IAccessController is IRemoteAccessBitmask {
  function getAddress(uint256 id) external view returns (address);

  function isAdmin(address) external view returns (bool);

  function owner() external view returns (address);

  function roleHolders(uint256 id) external view returns (address[] memory addrList);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './interfaces/IRemoteAccessBitmask.sol';

library AccessLib {
  function getAcl(IRemoteAccessBitmask remote, address subject) internal view returns (uint256) {
    return remote.queryAccessControlMask(subject, type(uint256).max);
  }

  function queryAcl(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 filterMask
  ) internal view returns (uint256) {
    return address(remote) != address(0) ? remote.queryAccessControlMask(subject, filterMask) : 0;
  }

  function hasAnyOf(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 flags
  ) internal view returns (bool) {
    return queryAcl(remote, subject, flags) & flags != 0;
  }

  function hasAllOf(
    IRemoteAccessBitmask remote,
    address subject,
    uint256 flags
  ) internal view returns (bool) {
    return flags != 0 && queryAcl(remote, subject, flags) & flags == flags;
  }

  function hasAny(IRemoteAccessBitmask remote, address subject) internal view returns (bool) {
    return address(remote) != address(0) && remote.queryAccessControlMask(subject, 0) != 0;
  }

  function hasNone(IRemoteAccessBitmask remote, address subject) internal view returns (bool) {
    return address(remote) != address(0) && remote.queryAccessControlMask(subject, 0) == 0;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library AccessFlags {
  // roles that can be assigned to multiple addresses - use range [0..15]
  uint256 public constant EMERGENCY_ADMIN = 1 << 0;
  uint256 public constant TREASURY_ADMIN = 1 << 1;
  uint256 public constant COLLATERAL_FUND_ADMIN = 1 << 2;
  uint256 public constant INSURER_ADMIN = 1 << 3;
  uint256 public constant INSURER_OPS = 1 << 4;

  uint256 public constant PREMIUM_FUND_ADMIN = 1 << 5;

  uint256 public constant SWEEP_ADMIN = 1 << 6;
  uint256 public constant PRICE_ROUTER_ADMIN = 1 << 7;

  uint256 public constant UNDERWRITER_POLICY = 1 << 8;
  uint256 public constant UNDERWRITER_CLAIM = 1 << 9;

  uint256 public constant LP_DEPLOY = 1 << 10;
  uint256 public constant LP_ADMIN = 1 << 11;

  uint256 public constant INSURED_ADMIN = 1 << 12;
  uint256 public constant INSURED_OPS = 1 << 13;
  uint256 public constant BORROWER_ADMIN = 1 << 14;
  uint256 public constant LIQUIDITY_BORROWER = 1 << 15;

  uint256 public constant ROLES = (uint256(1) << 16) - 1;

  // singletons - use range [16..64] - can ONLY be assigned to a single address
  uint256 public constant SINGLETS = ((uint256(1) << 64) - 1) & ~ROLES;

  // protected singletons - use for proxies
  uint256 public constant APPROVAL_CATALOG = 1 << 16;
  uint256 public constant TREASURY = 1 << 17;
  // uint256 public constant COLLATERAL_CURRENCY = 1 << 18;
  uint256 public constant PRICE_ROUTER = 1 << 19;

  uint256 public constant PROTECTED_SINGLETS = ((uint256(1) << 26) - 1) & ~ROLES;

  // non-proxied singletons, numbered down from 31 (as JS has problems with bitmasks over 31 bits)
  uint256 public constant PROXY_FACTORY = 1 << 26;

  uint256 public constant DATA_HELPER = 1 << 28;

  // any other roles - use range [64..]
  // these roles can be assigned to multiple addresses
  uint256 public constant COLLATERAL_FUND_LISTING = 1 << 64; // an ephemeral role - just to keep a list of collateral funds
  uint256 public constant INSURER_POOL_LISTING = 1 << 65; // an ephemeral role - just to keep a list of insurer funds

  uint256 public constant ROLES_EXT = uint256(0x3) << 64;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IRemoteAccessBitmask {
  /**
   * @dev Returns access flags granted to the given address and limited by the filterMask. filterMask == 0 has a special meaning.
   * @param addr an to get access perfmissions for
   * @param filterMask limits a subset of flags to be checked.
   * NB! When filterMask == 0 then zero is returned no flags granted, or an unspecified non-zero value otherwise.
   * @return Access flags currently granted
   */
  function queryAccessControlMask(address addr, uint256 filterMask) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IProxy {
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}