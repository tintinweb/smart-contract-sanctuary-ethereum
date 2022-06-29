/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/interfaces/IMaintainersRegistry.sol

pragma solidity 0.6.12;

/**
 * IMaintainersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
interface IMaintainersRegistry {
    function isMaintainer(address _address) external view returns (bool);
}


// File contracts/system/HordUpgradable.sol

pragma solidity 0.6.12;

/**
 * HordUpgradables contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
contract HordUpgradable {

    address public hordCongress;
    IMaintainersRegistry public maintainersRegistry;

    event MaintainersRegistrySet(address maintainersRegistry);
    event CongressAndMaintainersSet(address hordCongress, address maintainersRegistry);

    // Only maintainer modifier
    modifier onlyMaintainer {
        require(maintainersRegistry.isMaintainer(msg.sender), "Hord: Restricted only to Maintainer");
        _;
    }

    // Only chainport congress modifier
    modifier onlyHordCongress {
        require(msg.sender == hordCongress, "Hord: Restricted only to HordCongress");
        _;
    }

    modifier onlyHordCongressOrMaintainer {
        require(msg.sender == hordCongress || maintainersRegistry.isMaintainer(msg.sender),
            "Hord: Only Congress or Maintainer."
        );
        _;
    }

    function setCongressAndMaintainers(
        address _hordCongress,
        address _maintainersRegistry
    )
    internal
    {
        require(_hordCongress != address(0), "HordCongress can not be 0x0 address");
        require(_maintainersRegistry != address(0), "MaintainersRegistry can not be 0x0 address");

        hordCongress = _hordCongress;
        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);

        emit CongressAndMaintainersSet(hordCongress, address(maintainersRegistry));
    }

}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]


// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File contracts/libraries/SafeMath.sol

pragma solidity 0.6.12;


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File contracts/configurations/HordConfiguration.sol

pragma solidity 0.6.12;



/**
 * HordConfiguration contract.
 * @author Nikola Madjarevic
 * Date created: 4.8.21.
 * Github: madjarevicn
 */
contract HordConfiguration is HordUpgradable, Initializable {
    using SafeMath for *;

    // Representing HORD token address
    address public hordToken;
    // Stating minimal champion stake in USD in order to launch pool
    uint256 public minChampStake;
    // Minimal ETH stake followers should reach together, in USD
    uint256 public minFollowerUSDStake;
    // Maximal ETH stake followers should reach together, in USD
    uint256 public maxFollowerUSDStake;
    // Percent for covering gas fees for hPool operations
    uint256 public gasUtilizationRatio;
    // Representing decimals precision for %, defaults to 100
    uint256 public percentPrecision;
    // Representing maximal USD allocation per ticket
    uint256 public maxUSDAllocationPerTicket;
    // Total supply for HPoolToken
    uint256 public totalSupplyHPoolTokens;
    // End time for TICKET_SALE phase
    uint256 public ticketSaleDurationSecs;
    // End time for PRIVATE_SUBSCRIPTION phase
    uint256 public privateSubscriptionDurationSecs;
    // End time for PUBLIC_SUBSCRIPTION phase
    uint256 public publicSubscriptionDurationSecs;
    // Representing % of burnt hord tokens in public subscription phase
    uint256 public percentBurntFromPublicSubscription;
    // Representing % of champion fee
    uint256 public championFeePercent;
    // Representing % of protocolFee
    uint256 public protocolFeePercent;
    // Representing % of tradingFeePercent
    uint256 public tradingFeePercent;
    // Representing max value for duration variables
    uint256 public maxDurationValue;
    // Minimal time to stake in order to be eligible for claiming NFT
    uint256 public minTimeToStake;
    // Minimal amount to stake in order to be eligible for claiming NFT
    uint256 public minAmountToStake;
    // Minimal ratio of HORD in hPool
    uint256 public platformStakeRatio;

    event ConfigurationChanged(string parameter, uint256 newValue);
    event AddressChanged(string parameter, address newValue);

    modifier onlyIfDurationIsValid(uint256 durationTime) {
        require(durationTime <= maxDurationValue, "Duration time is not valid.");
        _;
    }

    /**
     * @notice          Initializer function
     */
    function initialize(
        address[] memory addresses,
        uint256[] memory configValues
    ) external initializer {
        // Set hord congress and maintainers registry
        setCongressAndMaintainers(addresses[0], addresses[1]);

        hordToken = addresses[2];

        minChampStake = configValues[0];
        minFollowerUSDStake = configValues[1];
        maxFollowerUSDStake = configValues[2];
        gasUtilizationRatio = configValues[3];
        maxUSDAllocationPerTicket = configValues[4];
        totalSupplyHPoolTokens = configValues[5];
        ticketSaleDurationSecs = configValues[6];
        privateSubscriptionDurationSecs = configValues[7];
        publicSubscriptionDurationSecs = configValues[8];
        percentBurntFromPublicSubscription = configValues[9];
        championFeePercent = configValues[10];
        protocolFeePercent = configValues[11];
        tradingFeePercent = configValues[12];
        maxDurationValue = configValues[13];
        minTimeToStake = configValues[14];
        minAmountToStake = configValues[15];
        platformStakeRatio = configValues[16];

        percentPrecision = 1000000;
    }

    // Setter Functions
    // _hordToken setter function
    function setHordTokenAddress(
        address _hordToken
    )
    external
    onlyHordCongress
    {
        require(_hordToken != address(0), "Address can not be 0x0.");
        hordToken = _hordToken;
        emit AddressChanged("hordToken", hordToken);
    }

    // minChampStake setter function
    function setMinChampStake(
        uint256 _minChampStake
    )
    external
    onlyHordCongress
    {
        minChampStake = _minChampStake;
        emit ConfigurationChanged("minChampStake", minChampStake);
    }

    // minFollowerUSDStake setter function
    function setMinFollowerUSDStake(
        uint256 _minFollowerUSDStake
    )
    external
    onlyHordCongress
    {
        minFollowerUSDStake = _minFollowerUSDStake;
        emit ConfigurationChanged("minFollowerUSDStake", minFollowerUSDStake);
    }

    // maxFollowerUSDStake setter function
    function setMaxFollowerUSDStake(
        uint256 _maxFollowerUSDStake
    )
    external
    onlyHordCongress
    {
        maxFollowerUSDStake = _maxFollowerUSDStake;
        emit ConfigurationChanged("maxFollowerUSDStake", maxFollowerUSDStake);
    }

    // gasUtilizationRatio setter function
    function setGasUtilizationRatio(
        uint256 _gasUtilizationRatio
    )
    external
    onlyHordCongress
    {
        gasUtilizationRatio = _gasUtilizationRatio;
        emit ConfigurationChanged("gasUtilizationRatio", gasUtilizationRatio);
    }

    // Set percent precision
    function setPercentPrecision(
        uint256 _percentPrecision,
        uint256 _championFeePercent,
        uint256 _protocolFeePercent,
        uint256 _percentBurntFromPublicSubscription,
        uint256 _gasUtilizationRatio
    )
    external
    onlyHordCongress
    {
        require(_percentPrecision > 100 && _percentPrecision < 10000000, "Precision is not within the permitted range.");
        require(_championFeePercent <= _percentPrecision, "value is smaller than percentPrecision");
        require(_protocolFeePercent <= _percentPrecision, "value is smaller than percentPrecision");
        require(_percentBurntFromPublicSubscription <= _percentPrecision, "value is smaller than percentPrecision");
        require(_gasUtilizationRatio <= _percentPrecision, "value is smaller than percentPrecision");

        percentPrecision = _percentPrecision;
        championFeePercent = _championFeePercent;
        protocolFeePercent = _protocolFeePercent;
        percentBurntFromPublicSubscription = _percentBurntFromPublicSubscription;
        gasUtilizationRatio = _gasUtilizationRatio;

        emit ConfigurationChanged("percentPrecision", percentPrecision);

    }

    // set max usd allocation per ticket
    function setMaxUSDAllocationPerTicket(
        uint256 _maxUSDAllocationPerTicket
    )
    external
    onlyHordCongress
    {
        maxUSDAllocationPerTicket = _maxUSDAllocationPerTicket;
        emit ConfigurationChanged(
            "maxUSDAllocationPerTicket",
            maxUSDAllocationPerTicket
        );
    }

    //totalSupplyHPoolTokens setter function
    function setTotalSupplyHPoolTokens(
        uint256 _totalSupplyHPoolTokens
    )
    external
    onlyHordCongress
    {
        totalSupplyHPoolTokens = _totalSupplyHPoolTokens;
        emit ConfigurationChanged("totalSupplyHPoolTokens", totalSupplyHPoolTokens);
    }

    //endTimeTicketSale setter function
    function setEndTimeTicketSale(
        uint256 _endTimeTicketSale
    )
    external
    onlyIfDurationIsValid(_endTimeTicketSale)
    onlyHordCongress
    {
        ticketSaleDurationSecs = _endTimeTicketSale;
        emit ConfigurationChanged("endTimeTicketSale", ticketSaleDurationSecs);
    }

    //endTimePrivateSubscription setter function
    function setEndTimePrivateSubscription(
        uint256 _endTimePrivateSubscription
    )
    onlyIfDurationIsValid(_endTimePrivateSubscription)
    external
    onlyHordCongress
    {
        privateSubscriptionDurationSecs = _endTimePrivateSubscription;
        emit ConfigurationChanged("endTimePrivateSubscription", privateSubscriptionDurationSecs);
    }

    //endTimePublicSubscription setter function
    function setEndTimePublicSubscription(
        uint256 _endTimePublicSubscription
    )
    onlyIfDurationIsValid(_endTimePublicSubscription)
    external
    onlyHordCongress
    {
        publicSubscriptionDurationSecs = _endTimePublicSubscription;
        emit ConfigurationChanged("endTimePublicSubscription", publicSubscriptionDurationSecs);
    }

    //percentBurntFromPublicSubscription
    function setPercentBurntFromPublicSubscription(
        uint256 _percentBurntFromPublicSubscription
    )
    external
    onlyHordCongress
    {
        percentBurntFromPublicSubscription = _percentBurntFromPublicSubscription;
        emit ConfigurationChanged("percentBurntFromPublicSubscription", percentBurntFromPublicSubscription);
    }

    //championFeePercent
    function setChampionFeePercent(
        uint256 _championFeePercent
    )
    external
    onlyHordCongress
    {
        championFeePercent = _championFeePercent;
        emit ConfigurationChanged("championFeePercent", championFeePercent);
    }

    //protocolFeePercent
    function setProtocolFeePercent(
        uint256 _protocolFeePercent
    )
    external
    onlyHordCongress
    {
        protocolFeePercent = _protocolFeePercent;
        emit ConfigurationChanged("protocolFeePercent", protocolFeePercent);
    }

    //tradingFeePercent
    function setTradingFeePercent(
        uint256 _tradingFeePercent
    )
    external
    onlyHordCongress
    {
        tradingFeePercent = _tradingFeePercent;
        emit ConfigurationChanged("tradingFeePercent", tradingFeePercent);
    }

    //maxDurationValue
    function setMaxDurationValue(
        uint256 _maxDurationValue
    )
    external
    onlyHordCongress
    {
        maxDurationValue = _maxDurationValue;
        emit ConfigurationChanged("maxDurationValue", maxDurationValue);
    }

    //minTimeToStake
    function setMinTimeToStake(
        uint256 _minTimeToStake
    )
    external
    onlyIfDurationIsValid(_minTimeToStake)
    onlyHordCongress
    {
        minTimeToStake = _minTimeToStake;
        emit ConfigurationChanged("minTimeToStake", minTimeToStake);
    }

    //minAmountToStake
    function setMinAmountToStake(
        uint256 _minAmountToStake
    )
    external
    onlyHordCongress
    {
        minAmountToStake = _minAmountToStake;
        emit ConfigurationChanged("minAmountToStake", minAmountToStake);
    }

    //platformStakeRatio
    function setPlatformStakeRatio(
        uint256 _platformStakeRatio
    )
    external
    onlyHordCongress
    {
        platformStakeRatio = _platformStakeRatio;
        emit ConfigurationChanged("platformStakeRatio", platformStakeRatio);
    }

    // exitFeeAmount getter function
    function exitFeeAmount(uint256 usdAmountWei)
    external
    pure
    returns (uint256)
    {
        return sqrt(usdAmountWei).mul(10**9).div(5);
    }

    function calculateTradingFee(
        uint256 amount
    )
    external
    view
    returns (uint256)
    {
        return amount.mul(tradingFeePercent).div(percentPrecision);
    }


    /**
    * @notice Function to compute square root of a number
    */
    function sqrt(
        uint256 x
    )
    internal
    pure
    returns (uint256 y)
    {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

}