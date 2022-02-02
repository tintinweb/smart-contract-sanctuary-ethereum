/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


// 
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)
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

// 
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// 
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)
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

// 
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)
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

// 
interface IHiVHub {
    struct RegisteredObject {
        string key;
        string comment;
        uint256 warrantID;
        address value;
        bool status;
    }
    function registerWarrant(uint256 warrantID, address warrant) external;
    function getWarrant(uint256 warrantID) external returns(address);
    function register(uint256 warrantID, string memory key, string memory comment, address warrant, bool status) external returns(uint256);
    function getRegister(uint256 dealID) external returns(IHiVHub.RegisteredObject memory);
    function registerAddress(uint256 warrantID, string memory key, address object) external;
    function getRegisteredAddress(uint256 warrantID, string memory key) view external returns (address);
    function isWithdrawAllowed(uint256 warrantID, uint256 dealID) view external returns (bool);
    function setWithdrawAllowed(uint256 warrantID, uint256 dealID, bool allow) external;
}

// 
interface IWarrant {
    event CreateSettings(address indexed warrant, address indexed sender, uint256 settingsID);

    enum DEAL_STATE {Created, Accepted, Working, WaitingPayout, Completed, Canceled}
    enum SIDE {Maker, Taker}
    enum POSITION {Short, Long}

    struct BasicSettings {
        string deliveryType;
        uint256[] basePointsList;
        bool isStepL;
        bool isStepS;
        bool hasProfitCurveL;
        bool hasProfitCurveS;
    }

    struct Settings {
        string underlyingAsset; // not used
        string coinUnderlyingAssetAxis; // not used
        string coinOfContract; // not used
        string coinDepositL;
        string coinDepositS;
        string coinPaymentL;
        string coinPaymentS;
        uint256 period;
        uint256 periodDeliverySideL;
        uint256 periodDeliverySideS;
    }

    struct DealBasicSettings {
        uint256 price;
        uint256 count;
        uint256 depositLPercent; // 100% = 1e18
        uint256 depositSPercent;
        uint256 periodOrderExpiration;
        POSITION makerPosition;
        bool isStandard;
    }

    struct FullDealInfo {
        uint256 warrantID;
        uint256 warrantSettingsID;
        uint256 dealID;
        DealBasicSettings dealSettings;
        address makerAddress;
        address takerAddress;
        DEAL_STATE status;

        uint256 oracleAmount;
        uint256 depositLAmount;
        uint256 depositSAmount;
        uint256 depositMax;
        bool isSymmetrical;
        uint256 dateOrderCreation;
        uint256 dateOrderExpiration;
        uint256 dateTake;
        uint256 dateStart;
        uint256 dateExpiration;
        uint256 dateOracle;
        uint256 dateDeliveryExpirationSideL;
        uint256 dateDeliveryExpirationSideS;
        uint256 payoutL;
        uint256 payoutS;
        uint256 resultL;
        uint256 resultS;
    }

    struct HistoryRecord {
        address sender;
        uint256 timestamp;
        string coin;
        uint256 amount;
    }

    struct DepositRecord {
        string coin;
        uint256 amount;
    }

    struct CollectedHistory {
        IWarrant.DepositRecord depositLong;
        IWarrant.DepositRecord depositShort;
        IWarrant.DepositRecord paymentLong;
        IWarrant.DepositRecord paymentShort;
        address addressLong;
        address addressShort;
    }

    function getWarrantSettings(uint256 warrantSettingsID) view external returns (IWarrant.Settings memory);

    function newDeal(address sender, uint256 warrantSettingsID, DealBasicSettings memory sealSettings, uint256 amount) external returns(uint256);

    function takeDeal(address sender, uint256 dealID, uint256 amount) external;

    function getDealInfo(uint256 dealID) view external returns (IWarrant.FullDealInfo memory);

    function setWarrantID(uint256 warrantID) external;

    function profitCurveL(uint256 x) view external returns (uint256 y);

    function profitCurveS(uint256 x) view external returns (uint256 y);

    function processing(uint256 dealID) external;

    function addDepositHistory(uint256 dealID, address sender, uint256 timestamp, string memory coin, uint256 amount) external;

    function cancelDeal(address sender, uint256 dealID) external;
}

// 
interface IDeposit {
    event DepositEvent(address indexed sender, uint256 amount);
    event DealDepositEvent(address indexed sender, uint256 warrantID, uint256 dealID, uint256 amount, bytes32 key);
    event DealCancelEvent(address indexed sender, uint256 warrantID, uint256 dealID, uint256 amount, bytes32 key);

    function getTokenAddress() view external returns (address);
    function depositToMakeDeal(uint256 warrantID, uint256 warrantSettingsID, IWarrant.DealBasicSettings memory dealSettings, uint256 amount) external payable;
    function depositToTakeDeal(uint256 warrantID, uint256 dealID, uint256 amount) external payable;
    function deposit(uint256 amount) external payable;
    function withdraw(uint256 warrantID, uint256 dealID) external;
    function updateBalance(uint256 warrantID, uint256 dealID, address addr1, uint256 amount1, address addr2, uint256 amount2) external;
    function getBalanceByDeal(uint256 warrantID, uint256 dealID, address sender) view external returns (uint256);
    function getBalanceByUser(address sender) view external returns (uint256);
}

// 
abstract contract Deposit is IDeposit, Ownable {
    using SafeMath for uint256;

    // warrantID => dealID => callerAddress => amount
    //mapping(address => mapping(uint256 => mapping(address => uint256))) _pool;
    mapping(bytes32 => uint256) internal _pool;
    uint256 internal totalFee;
    // callerAddress => amount
    mapping(address => uint256) internal _balances;

    IHiVHub internal hub;
    string public name;

    constructor(address hive) {
        hub = IHiVHub(hive);
    }

    function setHub(address _hub) external {
        require(msg.sender == address(hub), "Deposit: Wrong sender");
        require(_hub != address(0), "Deposit: Hub can not be empty");

        hub = IHiVHub(_hub);
    }

    function getTokenAddress() view external virtual returns (address);

    function calcFee(uint256 amount) internal virtual returns (uint256);

    function calculateAmounts(uint256 warrantID, uint256 amount) internal virtual returns(uint256, IWarrant);

    function doTransfer(address sender, uint256 amount) internal virtual returns(bool);

    function depositToMakeDeal(uint256 warrantID, uint256 warrantSettingsID, IWarrant.DealBasicSettings memory dealSettings, uint256 amount) external payable {
        IWarrant warrant;
        (amount, warrant) = calculateAmounts(warrantID, amount);
        try warrant.newDeal(msg.sender, warrantSettingsID, dealSettings, amount) returns (uint256 dealID) {
            bytes32 key = keccak256(abi.encode(warrantID, dealID, msg.sender));
            _pool[key] = _pool[key].add(amount);
            emit DealDepositEvent(msg.sender, warrantID, dealID, amount, key);
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    function depositToTakeDeal(uint256 warrantID, uint256 dealID, uint256 amount) external payable {
        IWarrant warrant;
        (amount, warrant) = calculateAmounts(warrantID, amount);
        try warrant.takeDeal(msg.sender, dealID, amount) {
            bytes32 key = keccak256(abi.encode(warrantID, dealID, msg.sender));
            _pool[key] = _pool[key].add(amount);
            emit DealDepositEvent(msg.sender, warrantID, dealID, amount, key);
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    function depositToDeal(uint256 warrantID, uint256 dealID, uint256 amount) external payable {
        IWarrant warrant;
        (amount, warrant) = calculateAmounts(warrantID, amount);
        try warrant.addDepositHistory(dealID, msg.sender, block.timestamp, name, amount) {
            bytes32 key = keccak256(abi.encode(warrantID, dealID, msg.sender));
            _pool[key] = _pool[key].add(amount);
            emit DealDepositEvent(msg.sender, warrantID, dealID, amount, key);
        } catch Error(string memory reason) {
            revert(reason);
        }
    }

    function deposit(uint256 amount) external payable {
        require(amount == msg.value, "Deposit: make sure the deposited amount is correct");

        _balances[msg.sender] = _balances[msg.sender].add(amount);
        emit DepositEvent(msg.sender, amount);
    }

    function withdraw(uint256 warrantID, uint256 dealID) external {
        //TODO re entrance guard?
        require(hub.isWithdrawAllowed(warrantID, dealID), "Deposit: Withdrawal is not allowed");
        bytes32 key = keccak256(abi.encode(warrantID, dealID, msg.sender));
        uint256 amount = _pool[key];
        require(amount > 0, "Deposit: Your balance is empty");
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _pool[key] = 0;
        emit DealDepositEvent(msg.sender, warrantID, dealID, amount, key);

        require(doTransfer(msg.sender, amount), "Deposit: Failed to send Ethereum");
    }

    function updateBalance(uint256 warrantID, uint256 dealID, address addr1, uint256 amount1, address addr2, uint256 amount2) external {
        require(hub.getWarrant(warrantID) == msg.sender, "Deposit: Wrong sender");
        bytes32 key1 = keccak256(abi.encode(warrantID, dealID, addr1));
        bytes32 key2 = keccak256(abi.encode(warrantID, dealID, addr2));
        require(_pool[key1] + _pool[key2] == amount1 + amount2, "Deposit: Wrong total amount");

        if (_pool[key1] > amount1) { // less than was before
            _balances[addr1] = _balances[addr1].sub(_pool[key1].sub(amount1));
        } else { // more than was before
            _balances[addr1] = _balances[addr1].add(amount1.sub(_pool[key1]));
        }
        if (_pool[key2] > amount2) { // less than was before
            _balances[addr2] = _balances[addr2].sub(_pool[key2].sub(amount2));
        } else { // more than was before
            _balances[addr2] = _balances[addr2].add(amount2.sub(_pool[key2]));
        }

        _pool[key1] = amount1;
        _pool[key2] = amount2;

        emit DealDepositEvent(addr1, warrantID, dealID, amount1, key1);
        emit DealDepositEvent(addr2, warrantID, dealID, amount2, key2);
    }

    function getBalanceByDeal(uint256 warrantID, uint256 dealID, address sender) view external returns (uint256) {
        bytes32 key = keccak256(abi.encode(warrantID, dealID, sender));
        return _pool[key];
    }

    function getBalanceByUser(address sender) view external returns (uint256) {
        return _balances[sender];
    }

    function getFeeBalance() view external onlyOwner returns (uint256) {
        return totalFee;
    }

    function withdrawFee() external onlyOwner {
        require(doTransfer(msg.sender, totalFee), "Deposit: Failed to send Ethereum");

        totalFee = 0;
    }

    function cancelDeal(uint256 warrantID, uint256 dealID) external {
        address temp = hub.getWarrant(warrantID);
        require(temp != address(0), "Deposit: Wrong warrantID");
        IWarrant warrant = IWarrant(temp);

        try warrant.cancelDeal(msg.sender, dealID) {
            bytes32 key = keccak256(abi.encode(warrantID, dealID, msg.sender));
            uint256 amount = _pool[key];
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            _pool[key] = 0;
            emit DealCancelEvent(msg.sender, warrantID, dealID, amount, key);

            require(doTransfer(msg.sender, amount), "Deposit: Failed to send Ethereum");
        } catch Error(string memory reason) {
            revert(reason);
        }
    }
}

// 
contract DepositIERC20 is Deposit {
    using SafeMath for uint256;

    IERC20 mainToken;

    constructor(string memory _name, address hive, address token) Deposit(hive) {
        require(token != address(0), "Wrong token address");
        name = _name;
        // name = token.call{value: 0, gas: 0}(abi.encodeWithSignature("name()"));
        mainToken = IERC20(token);
    }

    function getTokenAddress() view external override returns (address) {
        return address(mainToken);
    }

    function calcFee(uint256 /*amount*/) internal pure override returns (uint256) {
        //todo
        return 0;
    }

    function calculateAmounts(uint256 warrantID, uint256 amount) internal override returns(uint256, IWarrant) {
        require(msg.value == 0, "This contract accepts only IERC20 tokens");
        uint256 allowed = mainToken.allowance(msg.sender, address(this));
        require(amount <= allowed, "Wrong amount or allowance");
        bool success = mainToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Failed to send tokens");
        uint256 fee = calcFee(amount);
        totalFee = totalFee.add(fee);
        amount = amount.sub(fee);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        address temp = hub.getWarrant(warrantID);
        require(temp != address(0), "Wrong warrantID");
        IWarrant warrant = IWarrant(temp);
        return (amount, warrant);
    }

    function doTransfer(address recipient, uint256 amount) internal override returns(bool) {
        return mainToken.transfer(recipient, amount);
    }
}