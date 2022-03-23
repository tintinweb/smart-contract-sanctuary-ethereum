/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-22
*/

/**
 *Submitted for verification at snowtrace.io on 2022-02-18
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.6.12;


contract SwapAdmin {
    address public admin;
    address public candidate;

    constructor(address _admin) public {
        require(_admin != address(0), "admin address cannot be 0");
        admin = _admin;
        emit AdminChanged(address(0), _admin);
    }

    function setCandidate(address _candidate) external onlyAdmin {
        address old = candidate;
        candidate = _candidate;
        emit candidateChanged( old, candidate);
    }

    function becomeAdmin( ) external {
        require( msg.sender == candidate, "Only candidate can become admin");
        address old = admin;
        admin = candidate;
        emit AdminChanged( old, admin ); 
    }

    modifier onlyAdmin {
        require( (msg.sender == admin), "Only the contract admin can perform this action");
        _;
    }

    event candidateChanged(address oldCandidate, address newCandidate );
    event AdminChanged(address oldAdmin, address newAdmin);
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract SwapTokenLocker is SwapAdmin, Context {
    using SafeMath for uint;
    struct LockInfo {
        uint128 amount;
        uint128 claimedAmount;
        uint64 lockTimestamp; 
        uint64 lastUpdated;
        uint32 lockHours;
    }
    address immutable token;
    address public companyWallet;
    uint256 public feesInETH;
    mapping (address => LockInfo) public lockData;
    constructor(address _admin, address _token, uint256 _feesInETH, address _companyWallet) public SwapAdmin(_admin) {
        token = _token;
        feesInETH = _feesInETH;
        companyWallet = _companyWallet;
    }
    function getToken() external view returns(address) {
        return token;
    }
    function emergencyWithdraw(address _tokenAddress) external onlyAdmin {
        require(_tokenAddress != address(0), "Token address is invalid");
        IERC20(_tokenAddress).transfer(msg.sender, IERC20(_tokenAddress).balanceOf(address(this)));
    }
	function getLockData(address _user) external view returns(uint128, uint128, uint64, uint64, uint32) {
        require(_user != address(0), "User address is invalid");
        LockInfo storage _lockInfo = lockData[_user];
		return (
		    _lockInfo.amount, 
		    _lockInfo.claimedAmount, 
		    _lockInfo.lockTimestamp, 
		    _lockInfo.lastUpdated, 
		    _lockInfo.lockHours);
	}
    function sendLockTokenMany(
        address[] calldata _users, 
        uint128[] calldata _amounts, 
        uint32[] calldata _lockHours,
        uint256 _sendAmount
    ) public payable onlyAdmin {
        require(_users.length == _amounts.length, "array length not eq");
        require(_users.length == _lockHours.length, "array length not eq");
        require(_sendAmount > 0 , "Amount is invalid");
        if (feesInETH > 0) {
            if (companyWallet != address(0)) {
                uint256 minAmount = feesInETH;
                require(msg.value >= minAmount, "Low fee amount");
                uint256 feeDiff = msg.value - minAmount;
                (bool success,) = companyWallet.call{value: minAmount}("");
                require(success, "Fee transfer failed");
                /* refund difference. */
                if (feeDiff > 0) {
                    (bool refundSuccess,) = _msgSender().call{value: feeDiff}("");
                    require(refundSuccess, "Fee refund failed");
                }
            } else {
                (bool refundSuccess,) = _msgSender().call{value: msg.value}("");
                require(refundSuccess, "Fee refund failed");
            }
        }
        IERC20(token).transferFrom(msg.sender, address(this), _sendAmount);
        for (uint256 j = 0; j < _users.length; j++) {
            sendLockToken(_users[j], _amounts[j], uint64(block.timestamp), _lockHours[j]);
        }
    }
    function sendLockToken(
        address _user, 
        uint128 _amount, 
        uint64 _lockTimestamp, 
        uint32 _lockHours
    ) internal {
        require(_amount > 0, "amount can not zero");
        require(_lockHours > 0, "lock hours need more than zero");
        require(_lockTimestamp > 0, "lock timestamp need more than zero");
        require(lockData[_user].amount == 0, "this address has already locked");
        LockInfo memory lockinfo = LockInfo({
            amount: _amount,
            lockTimestamp: _lockTimestamp,
            lockHours: _lockHours,
            lastUpdated: uint64(block.timestamp),
            claimedAmount: 0
        });
        lockData[_user] = lockinfo;
    }
    function claimToken(uint128 _amount) external returns (uint256) {
        require(_amount > 0, "Invalid parameter amount");
        address _user = msg.sender;
        LockInfo storage _lockInfo = lockData[_user];
        require(_lockInfo.lockTimestamp <= block.timestamp, "Vesting time is not started");
        require(_lockInfo.amount > 0, "No lock token to claim");
        uint256 passhours = block.timestamp.sub(_lockInfo.lockTimestamp).div(1 hours);
        require(passhours > 0, "need wait for one hour at least");
        require((block.timestamp - _lockInfo.lastUpdated) > 1 hours, "You have to wait at least an hour to claim");
        uint256 available = 0;
        if (passhours >= _lockInfo.lockHours) {
            available = _lockInfo.amount;
        } else {
            available = uint256(_lockInfo.amount).div(_lockInfo.lockHours).mul(passhours);
        }
        available = available.sub(_lockInfo.claimedAmount);
        require(available > 0, "not available claim");
        uint256 claim = _amount;
        if (_amount > available) { // claim as much as possible
            claim = available;
        }
        _lockInfo.claimedAmount = uint128(uint256(_lockInfo.claimedAmount).add(claim));
        IERC20(token).transfer(_user, claim);
        _lockInfo.lastUpdated = uint64(block.timestamp);
        return claim;
    }
}

contract SwapTokenLockerFactory is Ownable {
    event SwapTokenLockerCreated(address admin, address locker);
    mapping(address => address[]) private deployedContracts;
    address[] private allLockers;
    /*
    * Fee vars
    */
    uint256 public feesInETH = 1 * 10 ** 17;
    address payable public companyWallet;

    constructor() public {
        companyWallet = payable(msg.sender);
    }

    function getLastDeployed(address owner) external view returns(address locker) {
        uint256 length = deployedContracts[owner].length;
        return deployedContracts[owner][length - 1];
    }

    function getAllContracts() external view returns (address[] memory) {
        return allLockers;
    }

    function getDeployed(address owner) external view returns(address[] memory) {
        return deployedContracts[owner];
    }

    function createTokenLocker(address token) external returns (address locker) {
        SwapTokenLocker lockerContract = new SwapTokenLocker(msg.sender, token, feesInETH, companyWallet);
        locker = address(lockerContract);
        deployedContracts[msg.sender].push(locker);
        allLockers.push(locker);
        emit SwapTokenLockerCreated(msg.sender, locker);
    }

    function setFeesInETH(uint256 _feesInETH) external onlyOwner() {
        feesInETH = _feesInETH;
    }
    
    function setCompanyWallet(address payable _companyWallet) external onlyOwner() {
        require(_companyWallet != address(0), "Invalid wallet address");
        companyWallet = _companyWallet;
    }
}