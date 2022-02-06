//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IQontroller.sol";
import "./interfaces/IFixedRateMarket.sol";
import "./libraries/Initializable.sol";
import "./QParams.sol";

contract Qontroller is Initializable, IQontroller {

  /// @notice Contract storing all global Qoda parameters
  QParams private _qParams;
    
  /// @notice The single instance of `QollateralManager` will be instantiated
  /// by `Qontroller`'s constructor. Store its address here.
  address private _qollateralManagerAddress;

  /// @notice All enabled Assets
  /// tokenAddress => Asset
  mapping(address => QTypes.Asset) private _assets;

  /// @notice Get the `FixedRateMarket` contract address for any given
  /// token and maturity time
  /// tokenAddress => maturity => fixedRateMarket
  mapping(address => mapping(uint => address)) private _fixedRateMarkets;

  /// @notice Mapping to determine whether a `fixedRateMarket` address
  /// is enabled or not
  /// fixedRateMarket => bool
  mapping(address => bool) private _enabledMarkets;

  /// @notice Emitted when a new FixedRateMarket is deployed
  event CreateFixedRateMarket(address marketAddress, address tokenAddress, uint maturity);

  /// @notice Emitted when a new Asset is added
  event AddAsset(address tokenAddress, address oracleFeed, uint collateralFactor, uint marketFactor);

  /// @notice Emitted when setting `collateralFactor`
  event SetCollateralFactor(address tokenAddress, uint collateralFactor);

  /// @notice Emitted when setting `marketFactor`
  event SetMarketFactor(address tokenAddress, uint marketFactor);

  function initialize(address qParamsAddress_) public initializer {
    // Set the admin of the contract
    _qParams = QParams(qParamsAddress_);
  }

    /** ADMIN/RESTRICTED FUNCTIONS **/

  function _initializeQollateralManager(address qollateralManagerAddress_) public {

    // Only `admin` may call this function
    require(msg.sender == _qParams.admin(), "unauthorized");

    // Initialize the value
    _qollateralManagerAddress = qollateralManagerAddress_;
  }

  /// @notice Admin function for adding new Assets. An Asset must be added before it
  /// can be used as collateral or borrowed. Note: We can create functionality for
  /// allowing borrows of a token but not using it as collateral by setting
  /// `collateralFactor` to zero.
  /// @param tokenAddress Address of the token corresponding to the Asset
  /// @param oracleFeed Chainlink price feed address
  /// @param collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @param marketFactor 0.0 to 1.0 (scaled to 1e8) for premium on risky borrows
  function _addAsset(
                      address tokenAddress,
                      address oracleFeed,
                      uint collateralFactor,
                      uint marketFactor
                      ) external {

    // Only `admin` may call this function
    require(msg.sender == _qParams.admin(), "unauthorized");

    // Cannot add the same asset twice
    require(!_assets[tokenAddress].isEnabled, "asset already exists");

    // `collateralFactor` must be between 0 and 1 (scaled to 1e8)
    require(collateralFactor <= _qParams.MAX_COLLATERAL_FACTOR(), "invalid collateral factor");

    // `marketFactor` must be between 0 and  1 (scaled to 1e8)
    require(marketFactor <= _qParams.MAX_MARKET_FACTOR(), "invalid market factor");
    
    // Initialize the Asset with the given parameters, and no enabled maturities
    // to begin with
    uint[] memory maturities;
    QTypes.Asset memory asset = QTypes.Asset(
                                             true,
                                             oracleFeed,
                                             collateralFactor,
                                             marketFactor,
                                             maturities
                                             );
    _assets[tokenAddress] = asset;

    // Emit the event
    emit AddAsset(tokenAddress, oracleFeed, collateralFactor, marketFactor);
  }

  /// @notice Update the `collateralFactor` for a given `Asset`
  /// @param tokenAddress Address of the token corresponding to the Asset
  /// @param collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _setCollateralFactor(address tokenAddress, uint collateralFactor) external {

    // Only `admin` may call this function
    require(msg.sender == _qParams.admin(), "unauthorized");

    // Asset must already be enabled
    require(_assets[tokenAddress].isEnabled, "asset not enabled");

    // `collateralFactor` must be between 0 and 1 (scaled to 1e8)
    require(collateralFactor <= _qParams.MAX_COLLATERAL_FACTOR(), "invalid collateral factor");

    // Look up the corresponding asset
    QTypes.Asset storage asset = _assets[tokenAddress];

    // Set `collateralFactor`
    asset.collateralFactor = collateralFactor;

    // Emit the event
    emit SetCollateralFactor(tokenAddress, collateralFactor);
  }

  /// @notice Update the `marketFactor` for a given `Asset`
  /// @param tokenAddress Address of the token corresponding to the Asset
  /// @param marketFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _setMarketFactor(address tokenAddress, uint marketFactor) external {

    // Only `admin` may call this function
    require(msg.sender == _qParams.admin(), "unauthorized");

    // Asset must already be enabled
    require(_assets[tokenAddress].isEnabled, "asset not enabled");

    // `marketFactor` must be between 0 and 1 (scaled to 1e8)
    require(marketFactor <= _qParams.MAX_MARKET_FACTOR(), "invalid asset factor");

    // Look up the corresponding asset
    QTypes.Asset storage asset = _assets[tokenAddress];

    // Set `marketFactor`
    asset.marketFactor = marketFactor;

    // Emit the event
    emit SetMarketFactor(tokenAddress, marketFactor);
  }

  function _addFixedRateMarket(address fixedRateMarketAddress) external {

    // Only `admin` may call this function
    require(msg.sender == _qParams.admin(), "unauthorized");

    // Get the values from the corresponding `FixedRateMarket` contract
    IFixedRateMarket market = IFixedRateMarket(fixedRateMarketAddress);
    uint maturity = market.maturity();
    address tokenAddress = market.tokenAddress();

    // Don't allow zero address
    require(tokenAddress != address(0), "invalid token address");

    // Only allow `Markets` where the corresponding `Asset` is enabled
    require(_assets[tokenAddress].isEnabled, "unsupported asset");

    // Check that this market hasn't already been instantiated before
    require(
            _fixedRateMarkets[tokenAddress][maturity] == address(0),
            "market already exists"
            );

    // Add the maturity as enabled to the corresponding Asset
    QTypes.Asset storage asset = _assets[tokenAddress];
    asset.maturities.push(maturity);
    
    // Add newly-created `FixedRateMarket` to the lookup list
    _fixedRateMarkets[tokenAddress][maturity] = fixedRateMarketAddress;

    // Enable newly-created `FixedRateMarket`
    _enabledMarkets[fixedRateMarketAddress] = true;

    // Emit the event
    emit CreateFixedRateMarket(
                               fixedRateMarketAddress,
                               tokenAddress,
                               maturity
                               );    
  }

  /** PUBLIC INTERFACE **/

  /// @notice Get the address of current administrator
  function admin() external view returns(address){
    return _qParams.admin();
  }
  
  /// @notice Get the address of the `QollateralManager` contract
  function qollateralManagerAddress() external view returns(address) {
    return _qollateralManagerAddress;
  }
  
  /// @notice Gets the `Asset` mapped to the address of a ERC20 token
  /// @param tokenAddress Address of ERC20 token
  /// @return QTypes.Asset Associated `Asset`
  function assets(address tokenAddress) external view returns(QTypes.Asset memory) {
    return _assets[tokenAddress];
  }

  /// @notice Gets the address of the `FixedRateMarket` contract
  /// @param tokenAddress Address of ERC20 token
  /// @param maturity UNIX timestamp of the maturity date
  /// @return address Address of `FixedRateMarket` contract
  function fixedRateMarkets(
                            address tokenAddress,
                            uint maturity
                            ) external view returns(address){
    return _fixedRateMarkets[tokenAddress][maturity];
  }

  /// @notice Check whether an address is a valid FixedRateMarket address.
  /// Can be used for checks for inter-contract admin/restricted function call.
  /// @param fixedRateMarketAddress Address of `FixedRateMarket` contract
  /// @return bool True if valid false otherwise
  function isMarketEnabled(address fixedRateMarketAddress) external view returns(bool){
    return _enabledMarkets[fixedRateMarketAddress];
  }  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libraries/QTypes.sol";

interface IQontroller {

  /// @notice Get the address of current administrator
  function admin() external view returns(address);
  
  /// @notice Get the address of the `QollateralManager` contract
  function qollateralManagerAddress() external view returns(address);
  
  /// @notice Gets the `Asset` mapped to the address of a ERC20 token
  /// @param tokenAddress Address of ERC20 token
  /// @return QTypes.Asset Associated `Asset`
  function assets(address tokenAddress) external view returns(QTypes.Asset memory);

  /// @notice Gets the address of the `FixedRateMarket` contract
  /// @param tokenAddress Address of ERC20 token
  /// @param maturity UNIX timestamp of the maturity date
  /// @return address Address of `FixedRateMarket` contract
  function fixedRateMarkets(
                            address tokenAddress,
                            uint maturity
                            ) external view returns(address);

  /// @notice Check whether an address is a valid FixedRateMarket address.
  /// Can be used for checks for inter-contract admin/restricted function call.
  /// @param fixedRateMarketAddress Address of `FixedRateMarket` contract
  /// @return bool True if valid false otherwise
  function isMarketEnabled(address fixedRateMarketAddress) external view returns(bool);
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

interface IFixedRateMarket is IERC20, IERC20Metadata {

  /** VIEW FUNCTIONS **/

  /// @notice Get the address of current administrator
  function admin() external view returns(address);
  
  /// @notice Get the address of the `QollateralManager`
  /// @return address
  function qollateralManagerAddress() external view returns(address);

  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return address
  function tokenAddress() external view returns(address);

  /// @notice Get the UNIX timestamp (in seconds) when the market matures
  /// @return uint
  function maturity() external view returns(uint);
  
  /// @notice True if a nonce for a Quote is voided, false otherwise.
  /// Used for checking if a Quote is a duplicated.
  /// @param account Account to query
  /// @param nonce Nonce to query
  /// @return bool True if used, false otherwise
  function isNonceVoid(address account, uint nonce) external view returns(bool);

  /// @notice Get the total balance of borrows by user
  /// @param account Account to query
  /// @return uint Borrows
  function accountBorrows(address account) external view returns(uint);

  /// @notice Get the current total partial fill for a Quote
  /// @param signature Quote signature to query
  /// @return uint Partial fill
  function quoteFill(bytes memory signature) external view returns(uint);
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./libraries/Initializable.sol";

contract QParams is Initializable {

  /// @notice Current admin of the protocol. Only admin may perform admin functions
  address private _admin;

  /// @notice Pending admin of the protocol
  address private _pendingAdmin;

  /// @notice Emitted when `_admin` is changed
  event NewAdmin(address oldAdmin, address newAdmin);

  /// @notice Emitted when `_pendingAdmin` is changed
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
  
  function initialize(address admin_) public initializer {
    // Set the admin the protocol
    _admin = admin_;
  }

  /** ADMIN FUNCTIONS **/

  /// @notice Begins transfer of admin rights. The newPendingAdmin must call
  /// `_acceptAdmin` to finalize the transfer.
  /// @param newPendingAdmin New pending admin
  function _setPendingAdmin(address newPendingAdmin) external {

    // Only `admin` may call this function
    require(msg.sender == _admin, "unauthorized");
    
    // Save current value, if any, for inclusion in log
    address oldPendingAdmin = _pendingAdmin;
    
    // Store `_pendingAdmin` with value `newPendingAdmin`
    _pendingAdmin = newPendingAdmin;
    
    // Emit the event
    emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
  }
  
  /// @notice Accepts transfer of admin rights. msg.sender must be `_pendingAdmin`
  function _acceptAdmin() external {
    
    // Check caller is `_pendingAdmin`
    require(msg.sender == _pendingAdmin && msg.sender != address(0), "unauthorized");
    
    // Save current values for inclusion in log
    address oldAdmin = _admin;
    address oldPendingAdmin = _pendingAdmin;
    
    // Store `_admin` with value `_pendingAdmin`
    _admin = _pendingAdmin;
    
    // Clear the pending value
    _pendingAdmin = address(0);
    
    // Emit the events
    emit NewAdmin(oldAdmin, _admin);
    emit NewPendingAdmin(oldPendingAdmin, _pendingAdmin);
  }
  
  /** VIEW FUNCTIONS **/
  
  function admin() external view returns(address){
    return _admin;
  }

  /// @notice 2**256 - 1
  function UINT_MAX() external pure returns(uint){
    return type(uint).max;
  }

  /// @notice Generic mantissa corresponding to ETH decimals
  function MANTISSA_DEFAULT() external pure returns(uint){
    return 1e18;
  }

  /// @notice Mantissa for stablecoins
  function MANTISSA_STABLECOIN() external pure returns(uint){
    return 1e6;
  }
  
  /// @notice Mantissa for liquidity ratio
  function MANTISSA_LIQUIDITY_RATIO() external pure returns(uint){
    return 1e8;
  }

  /// @notice `assetFactor` and `marketFactor` have up to 8 decimal places precision
  function MANTISSA_FACTORS() external pure returns(uint){
    return 1e8;
  }

  /// @notice `APR` has 4 decimal place precision
  function MANTISSA_APR() external pure returns(uint){
    return 1e4;
  }

  /// @notice `collateralFactor` cannot be above 1.0
  function MAX_COLLATERAL_FACTOR() external pure returns(uint){
    return 1e8;
  }

  /// @notice `marketFactor` cannot be above 1.0
  function MAX_MARKET_FACTOR() external pure returns(uint){
    return 1e8;
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QTypes {

  /// @notice Contains all the details of an Asset. Assets  must be defined
  /// before they can be used as collateral.
  /// @member isEnabled True if a asset is defined, false otherwise
  /// @member oracleFeed Address of the corresponding chainlink oracle feed
  /// @member collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @member marketFactor 0.0 1.0 for premium on risky borrows
  /// @member maturities Iterable storage for all enabled maturities
  struct Asset {
    bool isEnabled;
    address oracleFeed;
    uint collateralFactor;
    uint marketFactor;
    uint[] maturities;
  }

  /// @notice Contains all the fields of a FixedRateLoan agreement
  /// @member startTime Starting timestamp  when the loan is instantiated
  /// @member maturity Ending timestamp when the loan terminates
  /// @member principal Size of the loan
  /// @member principalPlusInterest Final amount that must be paid by borrower
  /// @member amountRepaid Current total amount repaid so far by borrower
  /// @member lender Account of the lender
  /// @member borrower Account of the borrower
  struct FixedRateLoan {
    uint startTime;
    uint maturity;
    uint principal;
    uint principalPlusInterest;
    uint amountRepaid;
    address lender;
    address borrower;
  }

  /// @notice Contains all the fields of a published Quote
  /// @param marketAddress Address of `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param nonce For uniqueness of signature
  /// @param signature Signed hash of the Quote message
  struct Quote {
    address marketAddress;
    address quoter;
    uint8 quoteType;
    uint8 side;
    uint64 quoteExpiryTime; //if 0, then quote never expires
    uint64 APR;
    uint cashflow;
    uint nonce;
    bytes signature;
  }
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
pragma solidity ^0.8.0;

import "./IERC20.sol";

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
pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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