// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import '../tools/Errors.sol';
import '../tools/tokens/IERC20Details.sol';
import '../interfaces/IProxyFactory.sol';
import '../interfaces/IInsurerPool.sol';
import '../interfaces/IPremiumActuary.sol';
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

import '../tools/tokens/IERC20.sol';
import './ICoverageDistributor.sol';

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

interface IInsurerPool is IERC20, IInsurerPoolBase, ICoverageDistributor {}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import './ICollateralized.sol';

interface IPremiumActuary is ICollateralized {
  function premiumDistributor() external view returns (address);

  function collectDrawdownPremium() external returns (uint256 availablePremiumValue);

  function burnPremium(
    address account,
    uint256 value,
    address drawdownRecepient
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
    address defaultRecepient,
    SwapInstruction[] calldata instructions
  ) external returns (uint256[] memory tokenAmounts);

  function knownTokens() external view returns (address[] memory);

  function actuariesOfToken(address token) external view returns (address[] memory);

  function actuaries() external view returns (address[] memory);

  function activeSourcesOf(address actuary, address token) external view returns (address[] memory);
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

interface ICancellableCoverage {
  /// @notice Cancel coverage for the sender
  /// @dev Called by insureds
  /// @param payoutRatio The RAY ratio of how much of provided coverage should be paid out
  /// @dev e.g payoutRatio = 5e26 means 50% of coverage is paid
  /// @return payoutValue The amount of coverage paid out to the insured
  function cancelCoverage(address insured, uint256 payoutRatio) external returns (uint256 payoutValue);
}

interface ICancellableCoverageDemand is ICancellableCoverage {
  /// @dev size of collateral allocation chunk made by this pool
  function coverageUnitSize() external view returns (uint256);

  /// @notice Cancel coverage that has been demanded, but not filled yet
  /// @dev can only be called by an accepted insured pool
  /// @param unitCount The number of units that wishes to be cancelled
  /// @return cancelledUnits The amount of units that were cancelled
  function cancelCoverageDemand(
    address insured,
    uint256 unitCount,
    uint256 loopLimit
  ) external returns (uint256 cancelledUnits);
}

interface ICoverageDistributor is ICancellableCoverageDemand {
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
pragma solidity ^0.8.4;

interface ICollateralized {
  /// @dev address of the collateral fund and coverage token ($CC)
  function collateral() external view returns (address);
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