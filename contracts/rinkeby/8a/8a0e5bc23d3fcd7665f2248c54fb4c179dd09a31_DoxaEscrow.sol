/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// File: all-code/doxa/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: all-code/doxa/Context.sol


// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

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
// File: all-code/doxa/Ownable.sol


// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
}
// File: all-code/doxa/IERC20.sol



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

// File: all-code/doxa/doxa-escrow.sol


pragma solidity ^0.8.0;





interface Wallet {
    function withdraw(address, string memory, uint) external;
    function walletBalanceOf(address) external view returns(uint);
    function getApproval(uint) external;
}

contract DoxaEscrow is Ownable {
    using SafeMath for uint256;

    IERC20 token;
    address adminAddress;

    IERC20 usdt;

    Wallet wallet;
    address walletAddress;

    struct EscrowInfo {
        string id;
        address buyer;
        address seller;
        uint paymentType;
        uint amount;
        bool isDisputed;
        bool isReleased;
    }


    mapping(string => EscrowInfo) public EscrowRecords;
   // mapping(string => address) public eventHostRecords;


    event Received(address indexed sender, uint indexed amount);
    event DoxaEscrowPayment(address indexed sender, string userId, EscrowInfo escrow);
    event ETHEscrowPayment(address indexed sender, string userId, EscrowInfo escrow);
    event AppWalletEscrowPayment(address indexed sender, string userId, EscrowInfo escrow);
    event Refund(address indexed account, string userId, EscrowInfo escrow);
    event USDTEscrowPayment(address indexed sender, string userId, EscrowInfo escrow);
    event EscrowPaymentRelease(EscrowInfo escrow, string userId);
    
    constructor(address admin, address _token, address _usdt, address _wallet) {
        token = IERC20(_token);
        usdt = IERC20(_usdt);
        adminAddress = admin;
        walletAddress = _wallet;
        wallet = Wallet(walletAddress);
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }


    function setTokenAddress(address _addr) public onlyOwner {
        token = IERC20(address(_addr));
    }

    function setUsdtAddress(address _addr) public onlyOwner {
        usdt = IERC20(address(_addr));
    }


    function walletBalanceOf(address _addr) public view returns(uint) {
        return wallet.walletBalanceOf(_addr);
    }

    function setWalletInstance(address _addr) public onlyOwner {
        wallet = Wallet(_addr);
    }

    function contractETHBalance() public view returns(uint) {
        return address(this).balance;
    }


    modifier notDisputed(string memory id) {
        require(!EscrowRecords[id].isDisputed, "Escrow in dispute state!");
        _;
    }

    function escrowPayETH(string memory id, address seller, string memory userId) public payable {
        escrowPayment(msg.sender, seller, msg.value, id, userId, 0);
    }

    function escrowPayment(address _buyer, address _seller, uint _amount, string memory id, string memory userId, uint paymentType) public {
        require(_amount > 0, "Amount should be greated than 0");
        require(!isExist(id), "Escrow for the given ID already exist");
        EscrowInfo memory escrow;

        escrow.id = id;
        escrow.buyer = _buyer;
        escrow.seller = _seller;
        escrow.paymentType = paymentType;
        escrow.isReleased = false;
        escrow.amount = _amount;

        EscrowRecords[id] = escrow;

        if(paymentType == 0) {
            emit ETHEscrowPayment(msg.sender, userId, escrow);
            return;
        }

        if(paymentType == 1) {
            require(token.balanceOf(_buyer) > _amount, "Insufficient Balance");
            token.transferFrom(_buyer, address(this), _amount);
            emit DoxaEscrowPayment(_buyer, userId, escrow);
            return;
        }

        if(paymentType == 2) {
            wallet.getApproval(_amount);
            wallet.withdraw(_buyer, id, _amount);
            token.transferFrom(walletAddress, address(this), _amount);
            emit AppWalletEscrowPayment(_buyer, userId, escrow);
            return;
        }

        if(paymentType == 3) {
            uint amount = _amount.div(10 ** 12, "div error");
            EscrowRecords[id].amount = amount;
            require(usdt.balanceOf(_buyer) > amount, "Insufficient Balance");
            usdt.transferFrom(_buyer, address(this), amount);
            emit USDTEscrowPayment(_buyer, userId, escrow);
            return;
        }

        return;
    }


    function releaseEscrowPayment(string memory id, uint releaseTo, string memory userId) public {
        EscrowInfo memory escrow = EscrowRecords[id];
        require(!escrow.isReleased, "Escrow amount already released!");
        if(msg.sender != adminAddress) {
            require(msg.sender == escrow.buyer, "Only buyer can release payment");
        }
        EscrowRecords[id].isReleased = true;

        uint paymentType = escrow.paymentType;
        address activeAddress;
        if(releaseTo == 1) {
            activeAddress = escrow.buyer;
        } else {
            activeAddress = escrow.seller;
        }

        require(msg.sender != activeAddress, "Operation not allowed");

        uint feeAmount = escrow.amount.mul(2).div(100);
        uint feeDeductedAmount = escrow.amount.sub(feeAmount);
        if(paymentType == 0) {
            payable(activeAddress).transfer(feeDeductedAmount);
            payable(adminAddress).transfer(feeAmount);
            emit EscrowPaymentRelease(escrow, userId);
            return;
        }

        if(paymentType == 1 || paymentType == 2) {
            token.transfer(activeAddress, feeDeductedAmount);
            token.transfer(adminAddress, feeAmount);
            emit EscrowPaymentRelease(escrow, userId);
            return;
        }

        if(paymentType == 3) {
            usdt.transfer(activeAddress, feeDeductedAmount);
            usdt.transfer(adminAddress, feeAmount);
            emit EscrowPaymentRelease(escrow, userId);
            return;
        }

    }

    function isExist(string memory id) public view returns(bool) {
        return EscrowRecords[id].amount > 0;
    }

    // function raiseDispute(string memory id) public {
    //     EscrowInfo memory escrow = EscrowRecords[id];
    //     require(isExist(id), "The escorw with the given is doesn't exist");
    //     require(!escrow.isReleased, "Payment already released");
    //     require(msg.sender == escrow.buyer || msg.sender == escrow.seller, "Not a seller or buyer");
    //     EscrowRecords[id].isDisputed = true;
    // }

    function releaseDisputePayment(string memory id, uint releaseTo, string memory userId) public onlyOwner {
        //require(EscrowRecords[id].isDisputed, "Escrow not in disputed state");
        // EscrowRecords[id].isDisputed = false;
        releaseEscrowPayment(id, releaseTo, userId);
    }

    function getUsdtBalance(address _addr) public view returns(uint) {
        return usdt.balanceOf(_addr);
    }
}