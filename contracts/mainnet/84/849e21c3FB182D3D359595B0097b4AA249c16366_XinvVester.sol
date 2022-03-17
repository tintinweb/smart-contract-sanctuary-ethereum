/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

pragma solidity ^0.5.16;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
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
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
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
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface Ixinv {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function syncDelegate(address user) external;
    function exchangeRateStored() external view returns (uint);
}

interface Iinv {
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
    function delegate(address delegatee) external;
    function approve(address spender, uint rawAmount) external returns (bool);
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool);
}

contract XinvVesterFactory {

    address public governance;
    Iinv public inv;
    Ixinv public xinv;
    XinvVester[] public vesters;

    constructor (Ixinv _xinv, Iinv _inv, address _governance) public {
        governance = _governance;
        inv = _inv;
        xinv = _xinv;
    }

    function deployVester(address _recipient, uint _invAmount, uint _vestingStartTimestamp, uint _vestingDurationSeconds, bool _isCancellable) public {
        require(msg.sender == governance, "ONLY GOVERNANCE");
        XinvVester vester = new XinvVester(xinv, inv, governance, _recipient, _vestingStartTimestamp, _vestingDurationSeconds, _isCancellable);
        inv.transferFrom(governance, address(vester), _invAmount);
        vester.initialize();
        vesters.push(vester);
    }
}

// Should only be deployed via factory
// Assumes xINV withdrawal delay is permanently set to 0
contract XinvVester {
    using SafeMath for uint;

    address public governance;
    address public factory;
    address public recipient;
    Iinv public inv;
    Ixinv public xinv;

    uint public vestingXinvAmount;
    uint public vestingBegin;
    uint public vestingEnd;
    bool public isCancellable;
    bool public isCancelled;
    uint public lastUpdate;

    constructor(Ixinv _xinv, Iinv _inv, address _governance, address _recipient, uint _vestingStartTimestamp, uint _vestingDurationSeconds, bool _isCancellable) public {
        require(_vestingDurationSeconds > 0, "DURATION IS 0");
        inv = _inv;
        xinv = _xinv;
        vestingBegin = _vestingStartTimestamp;
        vestingEnd = vestingBegin + _vestingDurationSeconds;
        recipient = _recipient;
        isCancellable = _isCancellable;
        governance = _governance;
        factory = msg.sender;

        lastUpdate = _vestingStartTimestamp;

        inv.delegate(_recipient);
        xinv.syncDelegate(address(this));
    }

    function initialize() public {
        uint _invAmount = inv.balanceOf(address(this));
        require(_invAmount > 0, "INV AMOUNT IS 0");
        require(msg.sender == factory, "ONLY FACTORY");
        inv.approve(address(xinv), _invAmount);
        require(xinv.mint(_invAmount) == 0, "MINT FAILED");
        vestingXinvAmount = xinv.balanceOf(address(this));
    }

    function delegate(address delegate_) public {
        require(msg.sender == recipient, 'ONLY RECIPIENT');
        inv.delegate(delegate_);
        xinv.syncDelegate(address(this));
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, 'ONLY RECIPIENT');
        recipient = recipient_;
    }

    function claimableXINV() public view returns (uint xinvAmount) {
        if (isCancelled) return 0;
        if (block.timestamp >= vestingEnd) {
            xinvAmount = xinv.balanceOf(address(this));
        } else {
            xinvAmount = vestingXinvAmount.mul(block.timestamp - lastUpdate).div(vestingEnd - vestingBegin);
        }
    }

    function claimableINV() public view returns (uint invAmount) {
        return claimableXINV().mul(xinv.exchangeRateStored()).div(1 ether);
    }

    function claim() public {
        require(msg.sender == recipient, "ONLY RECIPIENT");
        _claim();
    }

    function _claim() private {
        require(xinv.redeem(claimableXINV()) == 0, "REDEEM FAILED");
        inv.transfer(recipient, inv.balanceOf(address(this)));
        lastUpdate = block.timestamp;
    }

    function cancel() public {
        require(msg.sender == governance || msg.sender == recipient, "ONLY GOVERNANCE OR RECIPIENT");
        require(isCancellable || msg.sender == recipient, "NOT CANCELLABLE");
        require(!isCancelled, "ALREADY CANCELLED");
        _claim();
        require(xinv.redeem(xinv.balanceOf(address(this))) == 0, "REDEEM FAILED");
        inv.transfer(governance, inv.balanceOf(address(this)));
        isCancelled = true;
    }

}