/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _manager;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _manager = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function manager() internal view virtual returns (address) {
        return _manager;
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ITreasury {
    function mintSoftLaunch(uint256 _amount) external;

    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (bool);

    function valueOf(address _token, uint256 _amount) external view returns (uint256 value_);
}


interface IERC20Mutable {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 amount_) external;

    function burnFrom(address account_, uint256 amount_) external;
}

contract SoftLaunch is Ownable {
    using SafeMath for uint256;

    // ==== STRUCTS ====

    struct UserInfo {
        uint256 purchased; // CST
        uint256 vesting; // time left to be vested
        uint256 lastTime;
    }

    struct AddManagerRequest {
        uint transactionId;
        uint timestamp;
        address candidate;
        bytes32 requesthash;
        uint status; //0-not allowed, 1-pendig, 2-approved
    }

    struct RemoveManagerRequest {
        uint transactionId;
        uint timestamp;
        address candidate;
        bytes32 requesthash;
        uint status; //0-not allowed, 1-pendig, 2-approved
    }

    struct WithdrawRequest {
        uint transactionId;
        uint timestamp;
        address withdraw;
        uint256 amount;
        bytes32 requesthash;
        uint status; //0-not allowed, 1-pendig, 2-approved
    }

    
    // ==== CONSTANTS ====

    uint256 private constant MAX_PER_ADDR = 1000e18; // max 1k

    uint256 private constant MAX_FOR_SALE = 50000e18; // 50k

    uint256 public VESTING_TERM = 2 days; //Original 14days

    uint256 public  EXCHANGE_RATE = 32; // $3.2/ CST

    uint256 public spendingAmount = 400 * 10 ** 18; //BUSD $400, 18 is BUSD decimal
    // ==== STORAGES ====

    uint256 public startVesting;

    IERC20 public BUSD;
    IERC20 public CST;

    // staking contract
    address public staking;

    // treasury contract
    address public treasury;

    // router address
    address public router;

    // factory address
    address public factory;

    // backingTreasuryWallet address
    address public backingTreasuryWallet;

    // finalized status
    bool public finalized;

    // total asset purchased;
    uint256 public totalPurchased;

    // backing treasury portion
    uint public backingTreasuryPortion = 40; //40%, 60% reserve amount

    // white list for private sale
    mapping(address => bool) public whitelisted;
    mapping(address => UserInfo) public userInfo;
    uint public totalWhiteListCount;
    uint public currentWhitelistCount;

    //manager list for withdraw
    address[] managerList;
    mapping(address => AddManagerRequest) public addManagerRequest;
    mapping(address => mapping(address => uint)) public approvedbyManager;//0- Not allowed, 1-approved

    mapping(address => RemoveManagerRequest) public removeManagerRequest;
    mapping(address => mapping(address => uint)) public removedbyManager;//0- Not allowed, 1-approved
    
    mapping(address => WithdrawRequest) public withdrawRequest;

    // ==== EVENTS ====

    event Deposited(address indexed depositor, uint256 indexed amount);
    event Redeemed(address indexed recipient, uint256 payout, uint256 remaining);
    event WhitelistUpdated(address indexed depositor, bool indexed value);
    event AddManagerApproval(address indexed candidate, uint transactionId, uint timestamp, uint status );
    event ManagerAdded(address indexed candidate);

    event RemoveManagerApproval(address indexed candidate, uint transactionId, uint timestamp, uint status );
    event ManagerRemoved(address indexed candidate);

    event ReqeustWithdraw(bytes32 requesthash, address indexed owner, address indexed withdraw, uint transactionId, uint timestamp, uint amount);
    event Withdrawn(address indexed withdraw, uint256 amount);

    // ==== MODIFIERS ====

    modifier onlyWhitelisted(address _depositor) {
        require(whitelisted[_depositor], "only whitelisted");
        _;
    }

    modifier onlyManager(address _address) {
        bool ret = false;
        for(uint i = 0; i < managerList.length; i++) {
            if (_address == managerList[i] || _address == owner())
                ret = true;
        }

        require(ret, "only manager");
        _;
    }


    // ==== CONSTRUCTOR ====

    constructor(IERC20 _BUSD, uint256 _startVesting) {
        BUSD = _BUSD;
        startVesting = _startVesting;
        totalWhiteListCount = 500;
        currentWhitelistCount = 0;
        managerList.push(msg.sender); //owner is default manager
    }

    // ==== VIEW FUNCTIONS ====

    function availableFor(address _depositor) public view returns (uint256 amount_) {
        amount_ = 0;

        if (whitelisted[_depositor]) {
            UserInfo memory user = userInfo[_depositor];
            uint256 totalAvailable = MAX_FOR_SALE.sub(totalPurchased);
            uint256 assetPurchased = user.purchased.mul(EXCHANGE_RATE).mul(1e9).div(10);
            uint256 depositorAvailable = MAX_PER_ADDR.sub(assetPurchased);
            amount_ = totalAvailable > depositorAvailable ? depositorAvailable : totalAvailable;
        }
    }

    function payFor(uint256 _amount) public view returns (uint256 CSTAmount_) {
        // CST decimals: 9
        // asset decimals: 18
        CSTAmount_ = _amount.mul(1e9).mul(10).div(EXCHANGE_RATE).div(1e18);
    }

    function percentVestedFor(address _depositor) public view returns (uint256 percentVested_) {
        UserInfo memory user = userInfo[_depositor];

        if (block.timestamp < user.lastTime) return 0;

        uint256 timeSinceLast = block.timestamp.sub(user.lastTime);
        uint256 vesting = user.vesting;

        if (vesting > 0) {
            percentVested_ = timeSinceLast.mul(10000).div(vesting);
        } else {
            percentVested_ = 0;
        }
    }

    function pendingPayoutFor(address _depositor) external view returns (uint256 pendingPayout_) {
        uint256 percentVested = percentVestedFor(_depositor);
        uint256 payout = userInfo[_depositor].purchased;

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul(percentVested).div(10000);
        }
    }

    // ==== EXTERNAL FUNCTIONS ====

    function proposeAddManager(address _candidate, uint _transactionId) external onlyManager(msg.sender) {
        AddManagerRequest storage newRequest = addManagerRequest[_candidate];

        require(newRequest.status == 0, "alrady approved or pending staus. please check again");

        newRequest.transactionId = _transactionId;
        newRequest.timestamp = block.timestamp;
        newRequest.candidate = _candidate;
        newRequest.status = 1; //pending status
        newRequest.requesthash = keccak256(abi.encode(newRequest.candidate, newRequest.transactionId, newRequest.timestamp));

        emit AddManagerApproval(newRequest.candidate, newRequest.transactionId, newRequest.timestamp, newRequest.status);
    }

    function approveAddManager(address _candidate, uint _transactionId, uint _timestamp) external onlyManager(msg.sender) {
        bytes32 receivedHash = keccak256(abi.encode(_candidate, _transactionId, _timestamp));

        AddManagerRequest storage newRequest = addManagerRequest[_candidate];
        require(receivedHash == newRequest.requesthash, "Wrong args received");
        require(newRequest.status == 1 /* it must be pending status */, "Already approved");
        approvedbyManager[msg.sender][_candidate] = 1;

        bool allApprove = true;
        for(uint i = 0; i < managerList.length; i++) {
            if (approvedbyManager[managerList[i]][_candidate] == 0) {
                allApprove = false;
                break;
            }
        }

        if (allApprove) {
            newRequest.status = 2; //approved;
            managerList.push(_candidate);
            RemoveManagerRequest storage removeRequest = removeManagerRequest[_candidate];
            removeRequest.status = 0;
            for(uint i = 0; i < managerList.length; i++) {
                approvedbyManager[managerList[i]][_candidate] = 0; // remove apporve sign
            }
            emit ManagerAdded(_candidate);
        }   
    }

    function proposeRemoveManager(address _candidate, uint _transactionId) external onlyManager(msg.sender) {
        RemoveManagerRequest storage newRequest = removeManagerRequest[_candidate];

        require(newRequest.status == 0, "alrady approved or pending staus. please check again");

        newRequest.transactionId = _transactionId;
        newRequest.timestamp = block.timestamp;
        newRequest.candidate = msg.sender;
        newRequest.status = 1; //pending status
        newRequest.requesthash = keccak256(abi.encode(newRequest.candidate, newRequest.transactionId, newRequest.timestamp));

        emit RemoveManagerApproval(newRequest.candidate, newRequest.transactionId, newRequest.timestamp, newRequest.status);
    }


    function approveRemoveManager(address _candidate, uint _transactionId, uint _timestamp) external onlyManager(msg.sender) {
        bytes32 receivedHash = keccak256(abi.encode(_candidate, _transactionId, _timestamp));

        RemoveManagerRequest storage newRequest = removeManagerRequest[_candidate];
        require(receivedHash == newRequest.requesthash, "Wrong args received");
        require(newRequest.status == 1 /* it must be pending status */, "Already approved");
        removedbyManager[msg.sender][_candidate] = 1;

        bool allApprove = true;
        uint removeIndex = 0;

        for(uint i = 0; i < managerList.length; i++) {
            if (removedbyManager[managerList[i]][_candidate] == 0 && managerList[i] != _candidate) {
                allApprove = false;
                break;
            }
            else if(managerList[i] == _candidate )
                removeIndex = i;
        }

        if (allApprove) {
            newRequest.status = 2; //approved;
            managerList.push(_candidate);
            managerList[removeIndex] = managerList[managerList.length - 1];
            managerList.pop();

            AddManagerRequest storage addRequest = addManagerRequest[_candidate];
            addRequest.status = 0;

            for(uint i = 0; i < managerList.length; i++) {
                removedbyManager[managerList[i]][_candidate] = 0; //remove approve sign 
            }
            emit ManagerRemoved(_candidate);
        }   
    }

    function requestWithdraw(bytes32 _hash, address _withdraw, uint _transactionId, uint256 _amount) external onlyManager(msg.sender) {
        WithdrawRequest storage newRequest = withdrawRequest[msg.sender];

        newRequest.transactionId = _transactionId;
        newRequest.timestamp = block.timestamp;
        newRequest.withdraw = _withdraw;
        newRequest.amount = _amount;
        newRequest.status = 1; //pending status
        newRequest.requesthash = keccak256(abi.encode(newRequest.withdraw, newRequest.transactionId, newRequest.timestamp, newRequest.amount));

        if (msg.sender != owner()) 
            require(_hash == newRequest.requesthash, "Wrong args received");

        emit ReqeustWithdraw(newRequest.requesthash, msg.sender, _withdraw, newRequest.transactionId, newRequest.timestamp, newRequest.amount);
    }

    
    function emergencyWithdraw(address _withdraw, uint256 _amount) external onlyOwner {

        bool allApprove = true;
        for(uint i = 0; i < managerList.length; i++) {
            WithdrawRequest storage request = withdrawRequest[managerList[i]];
            if (request.status != 1) {
                allApprove = false;
                break;
            }
        }

        require( allApprove, "All manager should approve");
        
        for(uint i = 0; i < managerList.length; i++) {
            WithdrawRequest storage request = withdrawRequest[managerList[i]];
            request.status = 0;
        }

        BUSD.transfer(_withdraw, _amount);
        
        emit Withdrawn(_withdraw, _amount);
    }

    function deposit(uint256 _amount) external onlyWhitelisted(msg.sender) {
        require(!finalized, "already finalized");

        require(_amount == spendingAmount, "deposit amount is not Spending Amount");
        uint256 available = availableFor(msg.sender);
        require(_amount <= available, "exceed limit");

        totalPurchased = totalPurchased.add(_amount);

        UserInfo storage user = userInfo[msg.sender];
        user.purchased = user.purchased.add(payFor(_amount));
        user.vesting = VESTING_TERM;
        user.lastTime = startVesting;

        BUSD.transferFrom(msg.sender, address(this), _amount);

        emit Deposited(msg.sender, _amount);
    }

    function isClaimable(address _depositor) public view returns (bool enable_) {
        
        UserInfo memory user = userInfo[_depositor];
        enable_ = block.timestamp > user.lastTime + user.vesting;
    }

    function redeem() external {
        require(finalized, "not finalized yet");

        UserInfo memory user = userInfo[msg.sender];
        require(block.timestamp > user.lastTime + user.vesting, "vesting period is not finished");
 
        delete userInfo[msg.sender]; // delete user info
        emit Redeemed(msg.sender, user.purchased, 0); // emit bond data

        _sendCST(msg.sender, user.purchased); // pay user everything due
 
    }

    // ==== INTERNAL FUNCTIONS ====

    function _sendCST(
        address _recipient,
        uint256 _amount
    ) internal {
        CST.transfer(_recipient, _amount); // send payout
    }

    // ==== RESTRICT FUNCTIONS ====

    function setVestingTerm(uint _vestingTerm) external onlyOwner {
      VESTING_TERM = _vestingTerm * 1 days;
    }

    function setCSTPrice(uint _price) external onlyOwner {
        EXCHANGE_RATE = _price;
    }

    function setSpendingAmount(uint256 _spendingAmount) external onlyOwner {
        spendingAmount = _spendingAmount;
    }
  
    function setWhitelist(address _depositor, bool _value) external onlyOwner {
        
        require(currentWhitelistCount + 1 < totalWhiteListCount, "exceed limit" );
        currentWhitelistCount += 1;
        whitelisted[_depositor] = _value;

        emit WhitelistUpdated(_depositor, _value);
    }
    
    function addWhitelist(address[] memory _depositors) external onlyOwner {
        require(currentWhitelistCount + _depositors.length < totalWhiteListCount, "exceed limit" );
        currentWhitelistCount += _depositors.length;
        for (uint256 i = 0; i < _depositors.length; i++) {
            whitelisted[_depositors[i]] = true;
            emit WhitelistUpdated(_depositors[i], whitelisted[_depositors[i]]);
        }
    }

    function removeWhitelist(address[] memory _depositors) external onlyOwner {

        if(currentWhitelistCount > _depositors.length)
            currentWhitelistCount -= _depositors.length;
        else
            currentWhitelistCount -= 0;
        for (uint256 i = 0; i < _depositors.length; i++) {
            whitelisted[_depositors[i]] = false;
            emit WhitelistUpdated(_depositors[i], whitelisted[_depositors[i]]);
        }
    }

    function setupContracts(
        IERC20 _CST,
        address _backingTreasuryWallet
    ) external onlyOwner {
        CST = _CST;
        backingTreasuryWallet = _backingTreasuryWallet;
    }

    // finalize the sale, init liquidity and deposit treasury
    // 100% public goes to LP pool and goes to treasury as liquidity asset
    // 100% private goes to treasury as stable asset
    function finalize() external onlyOwner {
        require(!finalized, "already finalized");
        require(address(CST) != address(0), "0 addr: CST");
        require(address(backingTreasuryWallet) != address(0), "0 addr: backing treasurry wallet");

        uint256 backingTreasuryAmount = totalPurchased.mul(backingTreasuryPortion).div(100); // 40%
        // uint256 reserveAmount = totalPurchased.sub(backingTreasuryAmount);
        uint256 mintForSoftLaunch = totalPurchased.mul(10).div(EXCHANGE_RATE).div(1e9);

        require(mintForSoftLaunch != 0, "total purchased amount is 0");
        IERC20Mutable(address(CST)).mint(address(this), mintForSoftLaunch);
        //move backingTreasuryWallet
        BUSD.transfer(backingTreasuryWallet, backingTreasuryAmount);

        finalized = true;
    }

    function withdrawFund(address _token, uint256 _amount) external onlyOwner {
        if (_token == address(0)) {
            payable(owner()).transfer(address(this).balance);
        } else {
            IERC20(_token).transfer(owner(), _amount);
        }
    }

    receive() external payable {

    }

    fallback() external payable { 
    }
}