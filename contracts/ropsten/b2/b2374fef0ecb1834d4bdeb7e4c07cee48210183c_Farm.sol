// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract Farm is Ownable {

    /**
     * @dev Enum variable type
     */
    enum OperationStatus{ CREATED, ACTIVE, PENDING, CANCELED, FINISHED }

    /**
     * @dev Struct variable type
     */
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
        uint256 pairId;
        OperationStatus status; 
    }

    struct Withdrawal {
        uint256 depositId;
        uint256 amount;
        uint256 date;
        OperationStatus status;
    }

    struct ProfitWithdrawal {
        uint256 depositId;
        uint256 amount;
        uint256 date;
        OperationStatus status;
    }

    struct User {
        address referral;
        bool isBlocked;
        uint256 depositCount;
        uint256 withdrawCount;
        uint256 profitWithdrawCount;
        uint256 affiliateBalance;
        mapping(uint256 => Deposit) deposits;
        mapping(uint256 => Withdrawal) withdrawals;
        mapping(uint256 => ProfitWithdrawal) profitWithdrawals;
    }

    /**
     * @dev Mapping data for quick access by index or address.
     */
    mapping(uint256 => FarmService) public farmServices;
    mapping(uint256 => Pair) public pairs;
    mapping(address => User) public users;

    address[] public usersList;

    /**
     * @dev Counters for mapped data. Used to store the length of the data.
     */
    uint256 public usersCount;
    uint256 public pairsCount;
    uint256 public farmServicesCount;

    /**
     * @dev All events. Used to track changes in the contract
     */
    event AdminIsAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event MINTVLUpdated(uint256 value);
    event CAPYUpdated(uint256 value);
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
    event DepositStatusChanged(address indexed user, uint256 depositId, OperationStatus status);
    event WithdrawStatusChanged(address indexed user, uint256 withdrawId, OperationStatus status);
    event ProfitWithdrawStatusChanged(address indexed user, uint256 profitWithdrawId, OperationStatus status);
    event FarmToFarmMovingStart(uint256 time);
    event FarmToFarmMovingEnd(uint256 time);

    /**
     * @dev Admins data
     */
    mapping(address => bool) public isAdmin;
    address[] public adminsList;
    uint256 public adminsCount;

    /**
     * @dev Core data
     */
    bool public serviceDisabled;
    uint256 public MINTVL;
    uint256 public CAPY;
    uint256 public servicePercent;
    uint256 public affiliatePercent;
    bool public isFarmToFarmMoving;

    address public vaultAddress;
    IERC20 public farmToken;

    // constructor(address _vaultAddress, IERC20 _farmToken) {
    //     vaultAddress = _vaultAddress;
    //     farmToken = _farmToken;

    //     addAdmin(_msgSender());
    // }

    /**
     * @dev Throws if called when variable (`serviceDisabled`) is equals (`true`).
     */
    modifier onlyWhenServiceEnabled() {
        require(serviceDisabled == false, "FarmContract: Currently service is disabled. Try again later.");
        _;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "Access denied!");
        _;
    }

    /**
     * @dev Start moving farm to farm.
     *
     * NOTE: Can only be called by the current owner.
     */
    function startFarmToFarm() public onlyWhenServiceEnabled onlyOwner {
        isFarmToFarmMoving = true;
        emit FarmToFarmMovingStart(block.timestamp);
    }

    /**
     * @dev End moving farm to farm.
     *
     * NOTE: Can only be called by the current owner.
     */
    function endFarmToFarm() public onlyWhenServiceEnabled onlyOwner {
        isFarmToFarmMoving = true;
        emit FarmToFarmMovingEnd(block.timestamp);
    }

    /**
     * @dev Gives administrator rights to the address.
     *
     * NOTE: Can only be called by the current owner.
     */
    function addAdmin(address _address) public onlyWhenServiceEnabled onlyOwner {
        adminsList.push(_address);
        isAdmin[_address] = true;
        adminsCount++;
        emit AdminIsAdded(_address);
    }

    /**
     * @dev Removes administrator rights from the address.
     *
     * NOTE: Can only be called by the current owner.
     */
    function removeAdmin(address _address, uint256 _index) public onlyWhenServiceEnabled onlyOwner {
        isAdmin[_address] = false;
        adminsList[_index] = adminsList[adminsList.length - 1];
        adminsList.pop();
        adminsCount--;
        emit AdminRemoved(_address);
    }

    /**
     * @dev Block user by address.
     *
     * NOTE: Can only be called by the admin address.
     */
    function blockUser(address _address) public onlyWhenServiceEnabled onlyAdmin {
        users[_address].isBlocked = true;
        emit UserBlocked(_address);
    }

    /**
     * @dev Unblock user by address.
     *
     * NOTE: Can only be called by the admin address.
     */
    function unblockUser(address _address) public onlyWhenServiceEnabled onlyAdmin {
        users[_address].isBlocked = false;
        emit UserUnblocked(_address);
    }

    /**
     * @dev Disable all callable methods of service except (`enableService()`).
     *
     * NOTE: Can only be called by the admin address.
     */
    function disableService() public onlyWhenServiceEnabled onlyAdmin {
        serviceDisabled = true;
        emit ServiceDisabled();
    }

    /**
     * @dev Enable all callable methods of service.
     *
     * NOTE: Can only be called by the admin address.
     */
    function enableService() public onlyAdmin {
        serviceDisabled = false;
        emit ServiceEnabled();
    }

    /**
     * @dev Sets new value for (`MINTVL`) variable.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setMINTVL(uint256 _value) public onlyWhenServiceEnabled onlyAdmin {
        MINTVL = _value;
        emit MINTVLUpdated(_value);
    }

    /**
     * @dev Sets new value for (`CAPY`) variable.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setCAPY(uint256 _value) public onlyWhenServiceEnabled onlyAdmin {
        CAPY = _value;
        emit CAPYUpdated(_value);
    }

    /**
     * @dev Adds or update (`FarmService`) object.
     *
     * NOTE: Can only be called by the admin address.
     */
    function addFarmService(
        uint256 _id,
        string memory _name,
        bool _isActive,
        string memory _network,
        address _contractAddress,
        IERC20 _farmToken
    ) public onlyWhenServiceEnabled onlyAdmin {

        farmServices[_id] = FarmService(_name, _isActive, _contractAddress, _network, IERC20(_farmToken));
        farmServicesCount++;

        emit NewFarmService(_name, _contractAddress);
    } 

    /**
     * @dev Adds or update (`Pair`) object.
     *
     * NOTE: Can only be called by the admin address.
     */
    function addPair(
        uint256 _id,
        string memory _name,
        bool _isActive,
        address _contractAddress,
        uint _TVL,
        uint _APY,
        uint256 _maxPoolAmount
    ) public onlyWhenServiceEnabled onlyAdmin {

        pairs[_id] = Pair(_name, _isActive, IERC20(_contractAddress), _TVL, _APY, _maxPoolAmount);
        pairsCount++;

        emit NewPair(_name, _contractAddress);
    }

    /**
     * @dev Create new (`User`) object by address.
     *
     * Emits a {NewUser} event.
     *
     * NOTE: Only internal call.
     */
    function createNewUser(address _referral) private {
        users[_msgSender()].referral = _referral;
        users[_msgSender()].isBlocked = false;
        users[_msgSender()].depositCount = 0;
        users[_msgSender()].withdrawCount = 0;
        users[_msgSender()].profitWithdrawCount = 0;

        usersList.push(_msgSender());
        usersCount++;

        emit NewUser(_msgSender(), _referral);
    }

    /**
     * @dev To call this method, certain conditions are required, as described below:
     * 
     * Checks if user isn't blocked;
     * Checks if (`_amount`) is greater than zero;
     * Checks if farm service exists and has active status;
     * Checks if token exists and has active status;
     * Checks if contact has required amount of token for transfer from current caller;
     *
     * Transfers the amount of tokens to the current contract.
     * 
     * If its called by new address then new user will be created.
     * 
     * Creates new object of (`Deposit`) struct.
     *
     * Emits a {NewDeposit} event.
     */
    function deposit(
        uint256 _amount,
        address _referral,
        uint256 _farmService,
        uint256 _pair
    ) public onlyWhenServiceEnabled {

        require(users[_msgSender()].isBlocked == false, "FarmContract: User blocked");

        IERC20 token = pairs[_pair].contractAddress;

        require(_amount > 0, "FarmContract: Zero amount");

        require(farmServices[_farmService].isActive, "FarmContract: No active farm service");

        require(pairs[_pair].isActive, "FarmContract: No active pairs");

        uint256 allowance = token.allowance(_msgSender(), address(this));

        require(allowance >= _amount, "FarmContract: Recheck the token allowance");

        (bool sent) = token.transferFrom(_msgSender(), address(this), _amount);
        
        require(sent, "FarmContract: Failed to send tokens");
        
        if (users[_msgSender()].depositCount <= 0) {
            createNewUser(_referral);
        }

        uint256 newDepositId = users[_msgSender()].depositCount;

        users[_msgSender()].deposits[newDepositId] = Deposit(_amount, 0, block.timestamp, _pair, OperationStatus.CREATED);
        users[_msgSender()].depositCount += 1;

        emit NewDeposit(_msgSender(), _amount);
    }

    /**
     * @dev To call this method, certain conditions are required, as described below:
     * 
     * Checks if user isn't blocked;
     * Checks if user (`Deposit`) has ACTIVE status;
     * Checks if requested amount is less or equal deposit balance;
     *
     * Creates new object of (`Withdrawal`) struct with status CREATED.
     *
     * Emits a {NewDeposit} event.
     */
    function withdraw(
        uint256 _depositId
    ) public onlyWhenServiceEnabled {

        User storage user = users[_msgSender()];

        require(user.isBlocked == false, "FarmContract: User blocked");

        Deposit storage userDeposit = user.deposits[_depositId];

        require(userDeposit.status == OperationStatus.ACTIVE, "FarmContract: Deposit has not active status");
        
        uint256 newWithdrawalId = user.withdrawCount;
        
        users[_msgSender()].withdrawals[newWithdrawalId] = Withdrawal(_depositId, userDeposit.amount, block.timestamp, OperationStatus.CREATED);
        users[_msgSender()].withdrawCount += 1;
        users[_msgSender()].deposits[_depositId].status = OperationStatus.PENDING;

        emit NewWithdraw(_msgSender(), userDeposit.amount);
    }

    /**
     * @dev To call this method, certain conditions are required, as described below:
     * 
     * Checks if user isn't blocked;
     * Checks if user (`Deposit`) has ACTIVE status;
     * Checks if requested amount is less or equal profit balance;
     *
     * Creates new object of (`ProfitWithdrawal`) struct with status CREATED.
     *
     * Emits a {ProfitWithdrawal} event.
     */
    function profitWithdraw(
        uint256 _depositId,
        uint256 _amount
    ) public onlyWhenServiceEnabled {
        User storage user = users[_msgSender()];

        require(user.isBlocked == false, "FarmContract: User blocked");

        Deposit storage userDeposit = user.deposits[_depositId];

        require(userDeposit.status == OperationStatus.ACTIVE, "FarmContract: Deposit has not active status");

        uint256 requestedAmount = _amount;

        for (uint256 i = 0; i <= user.profitWithdrawCount; i++) {
            requestedAmount += user.profitWithdrawals[i].amount;
        }
        
        require(requestedAmount <= userDeposit.profit, "FarmContract: Amount is biggest then balance");

        uint256 newProfitWithdrawId = user.profitWithdrawCount;
        
        users[_msgSender()].profitWithdrawals[newProfitWithdrawId] = ProfitWithdrawal(_depositId, _amount, block.timestamp, OperationStatus.CREATED);
        users[_msgSender()].profitWithdrawCount += 1;

        emit NewProfitWithdraw(_msgSender(), _amount);
    }

    /**
     * @dev To call this method, certain conditions are required, as described below:
     * 
     * Checks if user isn't blocked;
     * Checks if requested amount is less or equal affiliate balance;
     *
     */
    function affiliateBalanceWithdraw(
        uint256 _amount
    ) public onlyWhenServiceEnabled {
        User storage user = users[_msgSender()];

        require(user.isBlocked == false, "FarmContract: User blocked");

        require(_amount <= user.affiliateBalance, "FarmContract: Amount is biggest then balance");

        users[_msgSender()].affiliateBalance -= _amount;
    }

    /**
     * @dev Changes user (`Deposit`) status variable.
     *
     * Emits a {DepositStatusChanged} event.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setUserDepositStatus(
        address _userAddress,
        uint256 _depositId,
        OperationStatus _status
    ) public onlyWhenServiceEnabled onlyAdmin {

        users[_userAddress].deposits[_depositId].status = _status;

        emit DepositStatusChanged(_userAddress, _depositId, _status);
    }

    /**
     * @dev Changes user (`Withdraw`) status variable.
     *
     * Emits a {WithdrawStatusChanged} event.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setUserWithdrawStatus(
        address _userAddress,
        uint256 _withdrawId,
        OperationStatus _status
    ) public onlyWhenServiceEnabled onlyAdmin {

        users[_userAddress].withdrawals[_withdrawId].status = _status;

        emit WithdrawStatusChanged(_userAddress, _withdrawId, _status);
    }

    /**
     * @dev Changes user (`ProfitWithdraw`) status variable.
     *
     * Emits a {ProfitWithdrawStatusChanged} event.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setUserProfitWithdrawStatus(
        address _userAddress,
        uint256 _profitWithdrawId,
        OperationStatus _status
    ) public onlyWhenServiceEnabled onlyAdmin {

        users[_userAddress].profitWithdrawals[_profitWithdrawId].status = _status;

        emit ProfitWithdrawStatusChanged(_userAddress, _profitWithdrawId, _status);
    }

    /**
     * @dev Syncs user (`Deposit`) profit variable.
     *
     * NOTE: Can only be called by the admin address.
     */
    function syncUserDepositProfit(
        address _userAddress,
        uint256 _depositId,
        uint256 _amount
    ) public onlyWhenServiceEnabled onlyAdmin {

       users[_userAddress].deposits[_depositId].profit = _amount;
    }

    /**
     * @dev Accrue affiliate amount to user balance.
     *
     * NOTE: Can only be called by the admin address.
     */
    function accrueUserAffiliate(
        address _userAddress,
        uint256 _amount
    ) public onlyWhenServiceEnabled onlyAdmin {

        users[_userAddress].affiliateBalance = _amount;
    }

    /**
     * @dev Returns the user (`Deposit`) object.
     */
    function getUserDeposit(
        address _userAddress,
        uint256 _depositId
    ) public view returns (Deposit memory) {

        return users[_userAddress].deposits[_depositId];
    }

    /**
     * @dev Returns the user (`Withdrawal`) object.
     */
    function getUserWithdraw(
        address _userAddress,
        uint256 _withdrawId
    ) public view returns (Withdrawal memory) {

        return users[_userAddress].withdrawals[_withdrawId];
    }

    /**
     * @dev Returns the user (`ProfitWithdrawal`) object.
     */
    function getUserProfitWithdraw(
        address _userAddress,
        uint256 _profitWithdrawId
    ) public view returns (ProfitWithdrawal memory) {

        return users[_userAddress].profitWithdrawals[_profitWithdrawId];
    }

    /**
     * @dev Transfer tokens to vault.
     *
     * NOTE: Can only be called by the current owner.
     * 
     */
    function transferTokens(
        uint256 _pairId,
        uint256 _amount
    ) public onlyOwner {

        IERC20 token = pairs[_pairId].contractAddress;

        uint256 balance = token.balanceOf(address(this));

        require(_amount <= balance, "FarmContract: Amount is bigger than balance!");

        token.transfer(vaultAddress, _amount);
    }
}