/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

pragma solidity 0.8.13;
// SPDX-License-Identifier: MIT

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity 0.8.13;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity 0.8.13;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity 0.8.13;

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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function burn(uint256 amount) external;

    function mint(address account, uint256 amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title SafeERC20
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

pragma solidity 0.8.13;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/// @title C98 Dollar Mint Burn for exchange cUSD by C98 or other Tokens
/// @notice Any user can exchange if meet requirements
contract Coin98DollarMintBurn is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256[] public MINTER;
    uint256[] public BURNER;
    uint256 private BASE_DECIMALS = 10**18;
    uint256 private Percent = 10000;

    /// @notice Limit time reset total per day for each minter
    uint256 private LIMIT_TIME = 24;

    IERC20 public CUSD_TOKEN;

    constructor(address _cusd) {
        CUSD_TOKEN = IERC20(_cusd);
    }

    /// @notice Token minter couple needed for create cUSD
    /// `isActive` Active or Deactive minter.
    /// `pair` couple tokens required for mint cUSD.
    /// `decimals` Each decimals matching with token index.
    /// `percents` Each percent required for mint cUSD matching with token index.
    /// `priceFeed` Price feed Oracle provided by ChainLink matching with token index
    /// `systemFee` System fee pay for each minted cUSD
    /// `totalSystemFee` Total cUSD fee pay for each exchange
    /// `totalMinted` Total cUSD amount minted
    /// `totalSupply` Maximum amount cUSD can be minted for this minter
    /// `totalSupplyPerDay` Maximum amount cUSD can be minted in one day for this minter
    /// `totalPerDay` Total amount cUSD minted in limit time (default one day)
    /// `lastExchange` Last exchange time used this minter to mint cUSD
    struct TokenMinter {
        bool isActive;
        address[] pairs;
        uint256[] decimals;
        uint256[] percents;
        address[] priceFeed;
        uint256 systemFee;
        uint256 totalSystemFee;
        uint256 totalMinted;
        uint256 totalSupply;
        uint256 totalSupplyPerDay;
        uint256 totalPerDay;
        uint256 lastExchange;
    }

    /// @notice Token burner for burn cUSD
    /// `isActive` Active or Deactive burner.
    /// `token` Tokens required for burn cUSD and mint.
    /// `decimals` Tokens decimals matching with token.
    /// `priceFeed` Price feed Oracle provided by ChainLink
    /// `systemFee` System fee pay for each burned cUSD
    /// `totalSystemFee` Total cUSD fee pay for each exchange
    /// `totalBurned` Total cUSD amount burned
    /// `totalSupply` Maximum amount cUSD can be burned for this burner
    /// `totalSupplyPerDay` Maximum amount cUSD can be burned in one day for this burner
    /// `totalPerDay` Total amount cUSD burned in limit time (default one day)
    /// `lastExchange` Last exchange time of this burner which is used to burn cUSD
    struct TokenBurner {
        bool isActive;
        address token;
        uint256 decimals;
        address priceFeed;
        uint256 systemFee;
        uint256 totalSystemFee;
        uint256 totalBurned;
        uint256 totalSupply;
        uint256 totalSupplyPerDay;
        uint256 totalPerDay;
        uint256 lastExchange;
    }

    /// @notice Mapping ID for each minter
    mapping(uint256 => TokenMinter) public TokenMinters;

    /// @notice Mapping ID for each burner
    mapping(uint256 => TokenBurner) public TokenBurners;

    /// @notice Withdraw token from Coin98 Dollar MintBurn
    event WithdrawToken(address[] token);

    event Mint(
        uint256 minter,
        address sender,
        uint256[] amountBurn,
        uint256 amountMint,
        uint256 exchangeFee,
        uint256 remainingToday
    );

    event Burn(
        uint256 burner,
        address sender,
        uint256 amountBurn,
        uint256 amountMint,
        uint256 exchangeFee,
        uint256 remainingToday
    );

    event UpdateMinter(
        uint256 id,
        address[] pairs,
        uint256[] decimals,
        uint256[] percents,
        address[] priceFeed,
        uint256 systemFee
    );

    event UpdateBurner(
        uint256 id,
        address token,
        uint256 decimals,
        address priceFeed,
        uint256 systemFee
    );

    event UpdateMinterSupply(
        uint256 id,
        uint256 totalSupply,
        uint256 totalSupplyPerDay
    );

    event UpdateBurnerSupply(
        uint256 id,
        uint256 totalSupply,
        uint256 totalSupplyPerDay
    );

    event UpdateMinterFee(uint256 id, uint256 systemFee);
    event UpdateBurnerFee(uint256 id, uint256 systemFee);

    event UpdateLimitTime(uint256 limitTime);

    /// @notice Check existed minter
    modifier onlyActiveMinter(uint256 _id) {
        require(
            TokenMinters[_id].isActive && TokenMinters[_id].totalSupply > 0,
            "Coin98DollarMintBurn: Minter not existed"
        );
        _;
    }

    /// @notice Check existed burner
    modifier onlyActiveBurner(uint256 _id) {
        require(
            TokenBurners[_id].isActive && TokenBurners[_id].totalSupply > 0,
            "Coin98DollarMintBurn: Burner not existed"
        );
        _;
    }

    /// @notice Get latest price from ChainLink
    /// @return Latest price from Price Feed
    function getLatestPrice(address priceFeed)
        public
        view
        returns (uint256, uint256)
    {
        if (priceFeed == address(0)) return (1 ether, 18);
        uint256 decimals = AggregatorV3Interface(priceFeed).decimals();
        (, uint256 price, , , ) = AggregatorV3Interface(priceFeed)
            .latestRoundData();
        return (price, decimals);
    }

    /// @notice Update Limit Time reset per day for each minter
    /// @param _limitTime The amount of exchange fee
    function setLimitTime(uint256 _limitTime) external onlyOwner {
        require(
            _limitTime > 0,
            "Coin98DollarMintBurn: Limit time must be a positive number and greater than zero"
        );
        LIMIT_TIME = _limitTime;

        emit UpdateLimitTime(_limitTime);
    }

    /// @notice Update System Fee of minter
    /// @param _systemFee The amount of exchange fee
    function setExchangeFee(uint256 _id, uint256 _systemFee)
        external
        onlyOwner
        onlyActiveMinter(_id)
    {
        require(
            _systemFee >= 0,
            "Coin98DollarMintBurn: Fee must be a positive number and greater than zero"
        );
        TokenMinters[_id].systemFee = _systemFee;

        emit UpdateMinterFee(_id, _systemFee);
    }

    /// @notice Update System Fee for burner
    /// @param _systemFee The amount of exchange fee
    function setExchangeFeeBurner(uint256 _id, uint256 _systemFee)
        external
        onlyOwner
        onlyActiveBurner(_id)
    {
        require(
            _systemFee >= 0,
            "Coin98DollarMintBurn: Fee must be a positive number and greater than zero"
        );
        TokenBurners[_id].systemFee = _systemFee;

        emit UpdateBurnerFee(_id, _systemFee);
    }

    /// @notice Set Minter for create cUSD
    function setMinter(
        uint256 _id,
        bool _isActive,
        address[] calldata _pairs,
        uint256[] calldata _decimals,
        uint256[] calldata _percents,
        address[] calldata _priceFeed,
        uint256 _systemFee
    ) external onlyOwner {
        uint256 sizePair = _pairs.length;
        TokenMinter storage minter = TokenMinters[_id];
        // Deactive current minter, no need to check anything here
        if (!_isActive) {
            require(
                minter.isActive,
                "Coin98DollarMintBurn: Minter already deactive"
            );
            minter.isActive = false;
        } else {
            require(
                sizePair > 0 &&
                    sizePair == _decimals.length &&
                    sizePair == _percents.length &&
                    sizePair == _priceFeed.length,
                "Coin98DollarMintBurn: Invalid input lengths"
            );

            require(
                _systemFee >= 0,
                "Coin98DollarMintBurn: Invalid input amount"
            );

            uint256 totalPercent = 0;

            // Double check minter is valid token address
            for (uint256 i = 0; i < sizePair; i++) {
                address token = _pairs[i];

                totalPercent = totalPercent.add(_percents[i]);

                uint256 tokenCode;
                assembly {
                    tokenCode := extcodesize(token)
                }
                require(
                    tokenCode > 0,
                    "Coin98DollarMintBurn: Invalid token address"
                );
                require(
                    token != address(0),
                    "Coin98DollarMintBurn: Minter is zero address"
                );
            }

            require(
                totalPercent == Percent,
                "Coin98DollarMintBurn: Invalid percent value"
            );

            // Push Minter to list if first time added
            if (minter.pairs.length == 0) {
                MINTER.push(_id);
            }

            // Update information minter
            minter.isActive = true;
            minter.pairs = _pairs;
            minter.decimals = _decimals;
            minter.percents = _percents;
            minter.priceFeed = _priceFeed;
            minter.systemFee = _systemFee;

            emit UpdateMinter(
                _id,
                _pairs,
                _decimals,
                _percents,
                _priceFeed,
                _systemFee
            );
        }
    }

    /// @notice Set Burner for burn cUSD
    function setBurner(
        uint256 _id,
        bool _isActive,
        address _token,
        uint256 _decimals,
        address _priceFeed,
        uint256 _systemFee
    ) external onlyOwner {
        require(
            _token != address(0),
            "Coin98DollarMintBurn: Burner is zero address"
        );

        TokenBurner storage burner = TokenBurners[_id];
        // Deactive current burner so no need to check anything here
        if (!_isActive) {
            require(
                burner.isActive,
                "Coin98DollarMintBurn: Burner already deactive"
            );
            burner.isActive = false;
        } else {
            require(
                _systemFee >= 0,
                "Coin98DollarMintBurn: Invalid input amount"
            );

            // Double check burner is valid token address
            uint256 tokenCode;
            assembly {
                tokenCode := extcodesize(_token)
            }
            require(
                tokenCode > 0,
                "Coin98DollarMintBurn: Invalid token address"
            );

            // Push Minter to list if first time added
            if (burner.token == address(0)) {
                BURNER.push(_id);
            }

            // Update information minter
            burner.isActive = true;
            burner.token = _token;
            burner.decimals = _decimals;
            burner.priceFeed = _priceFeed;
            burner.systemFee = _systemFee;

            emit UpdateBurner(_id, _token, _decimals, _priceFeed, _systemFee);
        }
    }

    /// @notice Set Minter supply and supply per day
    function setMinterSupply(
        uint256 _id,
        uint256 _totalSupply,
        uint256 _totalSupplyPerDay
    ) external onlyOwner {
        TokenMinter storage minter = TokenMinters[_id];
        require(minter.isActive, "Coin98DollarMintBurn: Minter not existed");

        require(
            _totalSupply > 0 &&
                _totalSupplyPerDay > 0 &&
                _totalSupplyPerDay <= _totalSupply,
            "Coin98DollarMintBurn: Invalid input amount"
        );
        minter.totalSupply = _totalSupply;
        minter.totalSupplyPerDay = _totalSupplyPerDay;
        emit UpdateMinterSupply(_id, _totalSupply, _totalSupplyPerDay);
    }

    /// @notice Set Burner supply and supply per day
    function setBurnerSupply(
        uint256 _id,
        uint256 _totalSupply,
        uint256 _totalSupplyPerDay
    ) external onlyOwner {
        TokenBurner storage burner = TokenBurners[_id];
        require(burner.isActive, "Coin98DollarMintBurn: Burner not existed");

        require(
            _totalSupply > 0 &&
                _totalSupplyPerDay > 0 &&
                _totalSupplyPerDay <= _totalSupply,
            "Coin98DollarMintBurn: Invalid input amount"
        );
        burner.totalSupply = _totalSupply;
        burner.totalSupplyPerDay = _totalSupplyPerDay;
        emit UpdateBurnerSupply(_id, _totalSupply, _totalSupplyPerDay);
    }

    /// @notice Check total supply and total supply per day of minter
    function checkTotalMinted(TokenMinter storage minter, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 diffHours = (block.timestamp - minter.lastExchange) / 60 / 60;
        bool isOverTime = diffHours >= LIMIT_TIME;
        uint256 currentTotalMinted = minter.totalMinted.add(amount);
        uint256 currentTotalMintedToday = isOverTime ? 0 : minter.totalPerDay;
        currentTotalMintedToday = currentTotalMintedToday.add(amount);

        require(
            currentTotalMintedToday <= minter.totalSupplyPerDay &&
                currentTotalMinted <= minter.totalSupply,
            "Coin98DollarMintBurn: Amount must be less than total supply and total per day"
        );

        // Update tracking information
        minter.totalMinted = currentTotalMinted;
        minter.totalPerDay = currentTotalMintedToday;
        if (isOverTime) {
            minter.lastExchange = block.timestamp;
        }
        return currentTotalMintedToday;
    }

    /// @notice Check total supply and total supply per day of burner
    function checkTotalBurned(TokenBurner storage burner, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 diffHours = (block.timestamp - burner.lastExchange) / 60 / 60;
        bool isOverTime = diffHours >= LIMIT_TIME;

        uint256 currentTotalBurned = burner.totalBurned.add(amount);
        uint256 currentTotalBurnedToday = isOverTime ? 0 : burner.totalPerDay;
        currentTotalBurnedToday = currentTotalBurnedToday.add(amount);

        require(
            currentTotalBurnedToday <= burner.totalSupplyPerDay &&
                currentTotalBurned <= burner.totalSupply,
            "Coin98DollarMintBurn: Amount must be less than total supply and total per day"
        );

        // Update tracking information
        burner.totalBurned = currentTotalBurned;
        burner.totalPerDay = currentTotalBurnedToday;
        if (isOverTime) {
            burner.lastExchange = block.timestamp;
        }
        return currentTotalBurnedToday;
    }

    /// @notice Burn cUSD and mint another token, based on the amount token wanted to mint
    /// Total burned cUSD must NOT greater than total supply and total supply per day condition
    /// @param _id Bunrer ID to burn with.
    /// @param amount Amount to burn CUSD Token.
    function burn(uint256 _id, uint256 amount) external onlyActiveBurner(_id) {
        require(
            amount > 0,
            "Coin98DollarMintBurn: Amount must be a positive number and greater than zero"
        );
        TokenBurner storage burner = TokenBurners[_id];

        (uint256 price, uint256 priceDecimals) = getLatestPrice(
            burner.priceFeed
        );

        uint256 amountToBurn = amount
            .mul(price)
            .mul(BASE_DECIMALS)
            .div(10**priceDecimals)
            .div(10**burner.decimals);

        require(amountToBurn > 0, "Coin98DollarMintBurn: Amount must be a positive number and greater than zero");

        uint256 currentTotalBurnedToday = checkTotalBurned(
            burner,
            amountToBurn
        );

        // Transfer money first before do anything effects
        CUSD_TOKEN.safeTransferFrom(msg.sender, address(this), amountToBurn);
        CUSD_TOKEN.burn(amountToBurn);

        // Update tracking information
        uint256 systemFee = amount.mul(burner.systemFee).div(Percent);
        burner.totalSystemFee = burner.totalSystemFee.add(systemFee);

        IERC20 tokenMint = IERC20(burner.token);
        uint256 amountToMint = amount.sub(systemFee);

        require(
            amountToMint > 0 &&
                tokenMint.balanceOf(address(this)) >= amountToMint,
            "Coin98DollarMintBurn: Not enough balance to mint or invalid amount"
        );

        tokenMint.safeTransfer(msg.sender, amountToMint);

        emit Burn(
            _id,
            msg.sender,
            amountToBurn,
            amountToMint,
            systemFee,
            currentTotalBurnedToday
        );
    }

    /// @notice Mint cUSD with amount of cUSD wanted to mint. Amount will be splited based on percent in couple tokens of minter (default amount is 18 decimals)
    /// Current platform not accepted main wrapped token like WETH, WBNB
    /// Total minted cUSD must NOT greater than total supply and total supply per day condition
    /// @param _id Minter ID to mint with.
    /// @param amount Amount to mint with CUSD Token.
    function mint(uint256 _id, uint256 amount) public onlyActiveMinter(_id) {
        require(
            amount > 0,
            "Coin98DollarMintBurn: Amount must be a positive number and greater than zero"
        );
        TokenMinter storage minter = TokenMinters[_id];

        uint256 currentTotalMintedToday = checkTotalMinted(minter, amount);

        uint256[] memory amountToTransfer = new uint256[](minter.pairs.length);

        for (uint256 i = 0; i < minter.pairs.length; i++) {
            uint256 tokenDecimals = minter.decimals[i];

            // Feed the latest price by ChainLink
            (uint256 price, uint256 priceDecimals) = getLatestPrice(
                minter.priceFeed[i]
            );

            uint256 mulValue = amount
                .mul(minter.percents[i])
                .mul(10**tokenDecimals)
                .mul(10**priceDecimals);

            uint256 amountToBurn = mulValue
                .div(Percent)
                .div(price)
                .div(BASE_DECIMALS);

            require(amountToBurn > 0, "Coin98DollarMintBurn: Amount must be a positive number and greater than zero");

            // Transfer money first before do anything effects
            IERC20(minter.pairs[i]).safeTransferFrom(
                msg.sender,
                address(this),
                amountToBurn
            );
            amountToTransfer[i] = amountToBurn;
        }

        uint256 systemFee = amount.mul(minter.systemFee).div(Percent);
        // Update tracking information
        minter.totalSystemFee = minter.totalSystemFee.add(systemFee);

        // Claim system fee for each exchange cUSD
        amount = amount.sub(systemFee);

        require(
            amount > 0,
            "Coin98DollarMintBurn: Total Mint must be a positive number and greater than zero"
        );

        // Mint CUSD Token to .sender
        CUSD_TOKEN.mint(msg.sender, amount);

        emit Mint(
            _id,
            msg.sender,
            amountToTransfer,
            amount,
            systemFee,
            currentTotalMintedToday
        );
    }

    /// @notice Withdraw all token and main token
    /// @param tokens The token contract that want to withdraw
    function withdrawMultiple(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == address(0)) {
                payable(msg.sender).transfer(address(this).balance);
            } else {
                IERC20 token = IERC20(tokens[i]);

                uint256 tokenBalance = token.balanceOf(address(this));
                if (tokenBalance > 0) {
                    token.safeTransfer(msg.sender, tokenBalance);
                }
            }
        }
        emit WithdrawToken(tokens);
    }
}