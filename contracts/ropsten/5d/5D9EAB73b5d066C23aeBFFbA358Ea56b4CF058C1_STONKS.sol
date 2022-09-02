pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) } //solium-disable-line security/no-inline-assembly
        return size > 0;
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

}

contract Ownable {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}


contract STONKS is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    IERC20 public TLC;
    address public feeAddress;
    address[] public tokens;
    mapping (address => uint256) public stakes;

    mapping (address => uint256) public _tokens;
    mapping (address => mapping (address => uint256)) private _balances;
    mapping (address => mapping (address => uint256)) private _stakes;

    event Deposit(address indexed user, uint256 indexed tokenId, uint256 indexed amount, uint256 stake, uint256 gas, uint256 hashrate, uint256 orderId);
    event Withdraw(address indexed user, uint256 indexed tokenId, uint256 indexed amount, uint256 stake, uint256 gas, uint256 orderId);

    constructor(address tlcAddress) public {
        TLC = IERC20(tlcAddress);
        feeAddress = msg.sender;
    }

    function deposit(address tokenAddress, uint256 tokenId, uint256 amount, uint256 stake, uint256 gas, uint256 hashrate, uint256 orderId) public payable {
        require(amount > 0, "LightsLightMinterV2: amount must be greater than zero");
        require(stake > 0, "LightsLightMinterV2: stake must be greater than zero");
        require(msg.value >= gas, "LightsLightMinterV2: value must be greater than gas");

        if (tokenAddress == address(0)) {
            require(msg.value >= amount.add(gas), "LightsLightMinterV2: value must be greater than amoutn + gas");
        } else {
            require(_tokens[tokenAddress] > 0, "LightsLightMinterV2: token is not supported");
            require(tokenAddress.isContract(), "LightsLightMinterV2: tokenAddress is not contract");

            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        }
        
        TLC.safeTransferFrom(msg.sender, address(this), stake);
        if (gas > 0) feeAddress.toPayable().transfer(gas);

        stakes[msg.sender] = stakes[msg.sender].add(stake);
        _stakes[msg.sender][tokenAddress] = _stakes[msg.sender][tokenAddress].add(stake);
        _balances[msg.sender][tokenAddress] = _balances[msg.sender][tokenAddress].add(amount);

        emit Deposit(msg.sender, tokenId, amount, stake, gas, hashrate, orderId);
    }

    function withdraw(address tokenAddress, uint256 tokenId, uint256 amount, uint256 gas, uint256 orderId) public payable {
        require(amount > 0, "LightsLightMinterV2: amount must be greater than zero");
        require(msg.value >= gas, "LightsLightMinterV2: value must be greater than gas");

        uint256 balance = _balances[msg.sender][tokenAddress];
        require(balance >= amount, "LightsLightMinterV2: insufficient balance");
        _balances[msg.sender][tokenAddress] = _balances[msg.sender][tokenAddress].sub(amount);

        uint256 _stake = _stakes[msg.sender][tokenAddress];
        uint256 stake = _stake.mul(amount).div(balance);
        if (_stake < stake) stake = _stake;
        require(stake > 0, "LightsLightMinterV2: insufficient stake");
        stakes[msg.sender] = stakes[msg.sender].sub(stake);
        _stakes[msg.sender][tokenAddress] = _stakes[msg.sender][tokenAddress].sub(stake);

        if (tokenAddress == address(0)) {
            msg.sender.transfer(amount);
        } else {
            require(_tokens[tokenAddress] > 0, "LightsLightMinterV2: token is not supported");
            require(tokenAddress.isContract(), "LightsLightMinterV2: tokenAddress is not contract");

            IERC20(tokenAddress).safeTransfer(msg.sender, amount);
        }
        
        TLC.safeTransfer(msg.sender, stake);
        if (gas > 0) feeAddress.toPayable().transfer(gas);

        emit Withdraw(msg.sender, tokenId, amount, stake, gas, orderId);
    }

    function getBalance(address user, address token) public view returns (uint256) {
        return _balances[user][token];
    }

    function addToken(address token) public onlyOwner {
        require(token != address(0), "LightsLightMinterV2: token the zero address");
        require(token.isContract(), "LightsLightMinterV2: token is not contract");
        if (_tokens[token] == 0) _tokens[token] = tokens.push(token);
    }

    function removeToken(address token) public onlyOwner {
        require(token != address(0), "LightsLightMinterV2: token the zero address");

        if (_tokens[token] == 0) return;
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance == 0, "LightsLightMinterV2: token balance must be equal to zero");

        delete tokens[_tokens[token].sub(1)];
        delete _tokens[token];
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        require(_feeAddress != address(0), "LightsLightMinterV2: new feeAddress the zero address");
        feeAddress = _feeAddress;
    }

    function() external payable {
        revert("LightsLightMinterV2: does not accept payments");
    }

}