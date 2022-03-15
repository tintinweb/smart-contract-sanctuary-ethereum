pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract Farm is Ownable {

    enum DepositStatus{ ACTIVE, REQUESTED, WITHDRAWN }
    enum WithdrawalStatus{ CREATED, WITHDRAWN, FAILED }

    struct FarmService {
        string name;
        bool isActive;
        address contractAddress;
        string network;
        IERC20 farmToken;
    }

    struct Pair {
        string name;
        bool isActive;
        IERC20 contractAddress;
        uint256 TVL;
        uint256 APY;
        uint maxPoolAmount;
    }

    struct Deposit {
        uint256 amount;
        uint256 profit;
        uint256 startTime;
        DepositStatus status; 
    }

    struct Withdrawal {
        uint256 depositId;
        uint256 amount;
        WithdrawalStatus status;
    }

    struct ProfitWithdrawal {
        uint256 depositId;
        uint256 amount;
        WithdrawalStatus status;
    }

    struct User {
        address referral;
        bool isBlocked;
        uint256 depositCount;
        uint256 withdrawCount;
        uint256 profitWithdrawCount;
        mapping(uint256 => Deposit) deposits;
        mapping(uint256 => Withdrawal) withdrawals;
        mapping(uint256 => ProfitWithdrawal) profitWithdrawals;
    }

    mapping(uint256 => FarmService) public farmServices;
    mapping(uint256 => Pair) public pairs;
    mapping(address => User) public users;

    event AdminIsAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event ServiceDisabled();
    event ServiceEnabled();
    event NewFarmService(string name , address indexed contractAddress);
    event NewPair(string name , address indexed contractAddress);
    event NewDeposit(address indexed user, uint256 amount);
    event NewWithdraw(address indexed user, uint256 amount);
    event NewProfitWithdraw(address indexed user, uint256 amount);
    event UserBlocked(address indexed user);
    event UserUnblocked(address indexed user);
    event NewUser(address indexed user, address indexed referral);

    // Core data
    bool public serviceDisabled = false;
    mapping(address => bool) public isAdmin;

    uint256 public MINTVL = 0;
    uint256 public CAPY = 0;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "Access denied!");
        _;
    }

    function addAdmin(address _address) public onlyOwner {
        isAdmin[_address] = true;
        emit AdminIsAdded(_address);
    }

    function removeAdmin(address _address) public onlyOwner {
        isAdmin[_address] = false;
        emit AdminRemoved(_address);
    }

    function blockUser(address _address) public onlyAdmin {
        users[_address].isBlocked = true;
        emit UserBlocked(_address);
    }

    function unblockUser(address _address) public onlyAdmin {
        users[_address].isBlocked = false;
        emit UserUnblocked(_address);
    }

    function disableService() public onlyAdmin {
        serviceDisabled = true;
        emit ServiceDisabled();
    }

    function enableService() public onlyAdmin {
        serviceDisabled = false;
        emit ServiceEnabled();
    }

    function addFarmService(
        uint256 _id,
        string memory _name,
        bool _isActive,
        string memory _network,
        address _contractAddress,
        IERC20 _farmToken
    ) public onlyAdmin {

        farmServices[_id] = FarmService(_name, _isActive, _contractAddress, _network, IERC20(_farmToken));

        emit NewFarmService(_name, _contractAddress);
    } 

    function addPair(
        uint256 _id,
        string memory _name,
        bool _isActive,
        address _contractAddress,
        uint _TVL,
        uint _APY,
        uint256 _maxPoolAmount
    ) public onlyAdmin {

        pairs[_id] = Pair(_name, _isActive, IERC20(_contractAddress), _TVL, _APY, _maxPoolAmount);

        emit NewPair(_name, _contractAddress);
    }

    function createNewUser(address _referral) private {
        users[_msgSender()].referral = _referral;
        users[_msgSender()].isBlocked = false;
        users[_msgSender()].depositCount = 0;
        users[_msgSender()].withdrawCount = 0;
        users[_msgSender()].profitWithdrawCount = 0;

        emit NewUser(_msgSender(), _referral);
    }

    function deposit(
        uint256 _amount,
        address _referral,
        uint256 _farmService,
        uint256 _pair
    ) public {

        require(users[_msgSender()].isBlocked == false, "FarmContract: User blocked");

        IERC20 token = pairs[_pair].contractAddress;

        require(_amount > 0, "FarmContract: Zero amount");

        require(farmServices[_farmService].isActive, "FarmContract: No active farm service");

        require(pairs[_pair].isActive, "FarmContract: No active pairs");

        uint256 allowance = token.allowance(_msgSender(), address(this));

        require(allowance >= _amount, "FarmContract: Recheck the token allowance");

        // Transfer deposit tokens to owner
        (bool sent) = token.transferFrom(_msgSender(), address(this), _amount);
        
        require(sent, "FarmContract: Failed to send tokens");

        uint256 newDepositId = 0;
        
        // Check for exist user
        if (users[_msgSender()].depositCount <= 0) {
            createNewUser(_referral);
        } else {
            newDepositId = users[_msgSender()].depositCount + 1;
        }

        // Create new deposit
        users[_msgSender()].deposits[newDepositId] = Deposit(_amount, 0, block.timestamp, DepositStatus.ACTIVE);
        users[_msgSender()].depositCount += 1;

        emit NewDeposit(_msgSender(), _amount);
    }

    function withdraw(
        uint256 _depositId,
        uint256 _amount
    ) public {

        User storage user = users[_msgSender()];

        require(user.isBlocked == false, "FarmContract: User blocked");

        Deposit storage userDeposit = user.deposits[_depositId];

        require(userDeposit.status == DepositStatus.ACTIVE, "FarmContract: Deposit has not active status");

        uint256 requestedAmount = _amount;

        for (uint256 i = 0; i <= user.withdrawCount; i++) {
            requestedAmount += user.withdrawals[i].amount;
        }
        
        require(requestedAmount <= userDeposit.amount, "FarmContract: Amount is biggest then balance");

        users[_msgSender()].withdrawals[user.withdrawCount + 1] = Withdrawal(_depositId, _amount, WithdrawalStatus.CREATED);
        users[_msgSender()].withdrawCount += 1;
    }

    function profitWithdraw(
        uint256 _depositId,
        uint256 _amount
    ) public {
        User storage user = users[_msgSender()];

        require(user.isBlocked == false, "FarmContract: User blocked");

        Deposit storage userDeposit = user.deposits[_depositId];

        require(userDeposit.status == DepositStatus.ACTIVE, "FarmContract: Deposit has not active status");

        uint256 requestedAmount = _amount;

        for (uint256 i = 0; i <= user.profitWithdrawCount; i++) {
            requestedAmount += user.profitWithdrawals[i].amount;
        }
        
        require(requestedAmount <= userDeposit.profit, "FarmContract: Amount is biggest then balance");

        users[_msgSender()].profitWithdrawals[user.profitWithdrawCount + 1] = ProfitWithdrawal(_depositId, _amount, WithdrawalStatus.CREATED);
        users[_msgSender()].profitWithdrawCount += 1;
    }

}