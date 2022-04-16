/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    constructor() {
        _owner = _msgSender();
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_msgSender() == owner(), "Ownable: caller is not the owner");
        _;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract SSSBModel is Context, Ownable {
    using SafeMath for uint256;

    string public name;
    address public middleman;
    address public buyer;
    address public seller;
    uint256 internal orderAmount;
    uint256 public taxAmount;
    uint256 public depositAmount;

    uint8 private decimals;

    address public allowWithdrawAddr;
    uint256 internal balanceReceived;

    enum State {CREATED, DEPOSIT, HOLD, SHIPPING, SHIPPED, COMPLETEPAYMENT,
                CANWITHDRAW, WITHDRAWN, NONPAYMENT, RETURNED, MWITHDRAWN}
    State private currentState;

    struct OrderStatus {
        uint256 timestamp;
        string status;
    }

    mapping (uint8 => OrderStatus) public orderStatus;
    uint8 public nextlogId = 0;

    struct PaymentHistory {
        address from;
        uint256 amount;
        uint256 timestamp;
    }
    mapping(uint8 => PaymentHistory) public paymentHistories;
    uint8 private nextPayment = 0;

    event ValueReceived(address from, uint256 amount, uint256 timestamp);

    modifier onlyBuyer() {
        require(_msgSender() == buyer);
        _;
    }

    constructor(string memory _name,
                address _buyer,
                address _seller,
                uint256 _orderAmount,
                uint256 _depositAmount,
                uint256 _taxAmount) {
        name = _name;
        middleman = _msgSender();
        buyer = _buyer;
        seller = _seller;
        orderAmount = _orderAmount;
        depositAmount = _depositAmount;
        taxAmount = _taxAmount;
        
        decimals = 18;

        changeStatus(State.CREATED);

        allowWithdrawAddr = _msgSender();
    }

    // only receive money from Buyer
    receive() external payable onlyBuyer {
        require(msg.value <= orderAmount, "The amount transferred exceeds the order value");
        balanceReceived += msg.value;
        if (balanceReceived < depositAmount) {
            changeStatus(State.DEPOSIT);
        }
        if (balanceReceived == depositAmount) {
            changeStatus(State.HOLD);
        }
        if ((balanceReceived > depositAmount) && (balanceReceived < orderAmount) && (currentState == State.DEPOSIT)) {
            changeStatus(State.HOLD);
        }
        if (balanceReceived == orderAmount) {
            changeStatus(State.COMPLETEPAYMENT);
        }
        emit ValueReceived(_msgSender(), msg.value, block.timestamp);
        PaymentHistory memory newPayment = PaymentHistory(_msgSender(), msg.value, block.timestamp);
        paymentHistories[nextPayment] = newPayment;
        nextPayment++;
    }

    // order is being shipped
    function shipping() external onlyOwner {
        require(currentState == State.HOLD, "Deposit has not been paid");
        changeStatus(State.SHIPPING);
    }

    // order has arrived
    function shipped() external onlyOwner {
        require(currentState == State.SHIPPING, "Order has not been shipped");
        changeStatus(State.SHIPPED);
    }

    // allow seller to withdraw money
    function allowSellerWithdraw() external onlyOwner {
        require(((currentState == State.COMPLETEPAYMENT) || (currentState == State.NONPAYMENT)), "Buyer has not paid full");
        allowWithdrawAddr = seller;
        changeStatus(State.CANWITHDRAW);
    }

    // order has arrived but buyer does not pay
    function nonPayment() external onlyOwner {
        require(currentState == State.SHIPPED, "Order has not been shipped");
        allowWithdrawAddr = seller;
        changeStatus(State.NONPAYMENT);
    }
    
    // seller withdraw money
    function sellerWithdraw() public {
        require(allowWithdrawAddr == _msgSender(), "Not permission to withdraw");
        if (currentState == State.CANWITHDRAW) {
            uint256 amountWithdraw = getBalance().sub(taxAmount);
            _msgSender().transfer(amountWithdraw); // fee: shipping out
            PaymentHistory memory newPayment = PaymentHistory(_msgSender(), amountWithdraw, block.timestamp);
            paymentHistories[nextPayment] = newPayment;
            nextPayment++;
            changeStatus(State.WITHDRAWN);
        }
        else if (currentState == State.NONPAYMENT) {
            uint256 amountWithdraw = getBalance().sub(taxAmount.mul(2));  // double fee: shipping out and shipping back
            _msgSender().transfer(amountWithdraw);
            PaymentHistory memory newPayment = PaymentHistory(_msgSender(), amountWithdraw, block.timestamp);
            paymentHistories[nextPayment] = newPayment;
            nextPayment++;
            changeStatus(State.RETURNED);
        } else {
            revert('Cannot withdraw');
        }
    }

    // middleman withdraw tax fee
    function middlemanWithdraw() external onlyOwner {
        require(((currentState == State.WITHDRAWN) || currentState == State.RETURNED), "Seller has not withdrawn"); 
        _msgSender().transfer(getBalance());
        changeStatus(State.MWITHDRAWN);
    }

    // get balance of this smart contract
    function getBalance() public view virtual returns(uint256) {
        return address(this).balance;
    }

    // get order amount with decimals
    function getOrderAmount() public view virtual returns(uint256 _orderAmount, uint8 _decimals) {
        return (orderAmount, decimals);
    }

    // log status of order
    function changeStatus(State _state) private {
        currentState = _state;
        OrderStatus memory newStatus = OrderStatus(block.timestamp, stateToStr(_state));
        orderStatus[nextlogId] = newStatus;
        nextlogId++;
    }

    // support function: convert state to string
    function stateToStr(State state) internal pure returns (string memory) {
        string memory str;
        if (state == State.CREATED) {
            str = "The order has been created";
        } else if (state == State.DEPOSIT) {
            str = "Receiving deposit";
        } else if (state == State.HOLD) {
            str = "The full deposit has been received. Deposit is being hold in smart contract";
        } else if (state == State.SHIPPING) {
            str = "The order is shipping";
        } else if (state == State.SHIPPED) {
            str = "The order has arrived";
        } else if (state == State.COMPLETEPAYMENT) {
            str = "The full payment received. Buyer is allowed to receive";
        } else if (state == State.CANWITHDRAW) {
            str = "The seller is allowed to withdraw from the smart contract";
        } else if (state == State.WITHDRAWN) {
            str = "The seller has withdrawn successfully";
        } else if (state == State.NONPAYMENT) {
            str = "The buyer is not paying";
        } else if (state == State.RETURNED) {
            str = "The order is being returned";
        } else if (state == State.MWITHDRAWN) {
            str = "The middleman has withdrawn successfully";
        }
        return str;
    }

    // manual change status
    function manualChangeStatus(State _state) external onlyOwner {
        changeStatus(_state);
    }

    // get the name of enum State
    function currentStatus() public view virtual returns(string memory _currentState) {
        return stateToStr(currentState);
    }
}