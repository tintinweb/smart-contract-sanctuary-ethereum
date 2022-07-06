/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface ERC20Interface {

    function decimals() external pure returns (uint8);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function burn(uint256 _amount, address _burner) external returns (bool);
    function mint(uint256 _amount) external;
}

contract Vault {
    uint256 private constant fiveMinutes = 5 * 60;

    uint256 public administratorsCount;

    /**
     * Can be changed to [external] to optimize GAS USED
     */
    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping(address => bool) private administrators;

    /**
     * @dev percentage defined by administrators up to 50% for gains withdraw
     * Percentage is set to 10% by default.
     */
    uint256 public percentageToWithdraw = 10;

    /**
     * @dev maximum amount of ethers for withdraw per admin
     */
    uint256 public maxWithdraw;

    /**
     * @dev amount of ethers withdrwan by admin
     */
    mapping(address => uint256) private withdrawals;

    /**
     * @dev address of the TokenContract
     */
    ERC20Interface private tokenContract;

    /**
     * @dev address of the FarmContract
     */
    address private farmAddress;

    /**
     * @dev Max amount of tokens bought/sold per transaction
     */
    uint256 private maxTokenAmount;

    /**
     * @dev structure to represent request withdraw details.
     * [initialized]: is used represent if the structure is being use or not
     */
    struct RequestWithdrawDetails {
        uint256 amountPerAdmin;
        address requestAddress; // Address who request withdraw
        bool initialized;
    }

    struct MultiSignature {
        address sender;
        uint256 timestamp;
        uint256 amount;
    }

    MultiSignature public _mint;

    /**
     * @dev structure to hold request withdraw details.
     */
    RequestWithdrawDetails public _requestWithdrawDetails;

    event Sell(address indexed _address, uint256 _value, uint256 _price);
    event Buy(address indexed _address, uint256 _value, uint256 _price);
    event Burn(address indexed _burner, uint256 _value);

    modifier onlyAdmin() {
        require(administrators[msg.sender], 'User must be administrator to perform this operation');
        _;
    }

    modifier isValidAddress(address _address) {
        require(_address != address(0) && _address != address(this), 'The provided address is not valid');
        _;
    }

    modifier isValidTokenContractAddress() {
        require(address(tokenContract) != address(0) && address(tokenContract) != address(this), 'The TokenContract address is not valid');
        _;
    }

    modifier contractIsReady() {
        require(maxTokenAmount > 0, 'Contract not ready: maxTokenAmount is 0');
        require(sellPrice > 0, 'Contract not ready: sellPrice is 0');
        require(buyPrice > 0, 'Contract not ready: buyPrice is 0');
        require(address(tokenContract) != address(0), 'Contract not ready: tokenContract is 0');
        require(address(farmAddress) != address(0), 'Contract not ready: farmAddress is 0');
        _;
    }

    constructor() payable {
        administratorsCount = 1;
        administrators[msg.sender] = true;
    }

    function setTransferAccount(address _tokenContractAddress) external onlyAdmin isValidAddress(_tokenContractAddress) {
        require(isContract(_tokenContractAddress), 'The provided address is not a contract');
        tokenContract = ERC20Interface(_tokenContractAddress);
    }

    function setFarmAddress(address _farmAddress) external onlyAdmin isValidAddress(_farmAddress) {
        farmAddress = _farmAddress;
    }

    function isAdmin(address _admin) external view returns (bool) {
        return administrators[_admin];
    }

    function addAdmin(address _admin) external onlyAdmin isValidAddress(_admin) {
        require(!this.isAdmin(_admin), 'Account is already an admin');
        administratorsCount += 1;
        administrators[_admin] = true;
        withdrawals[_admin] = maxWithdraw; // This line does not allow a new admin to make any withdraw
    }

    function removeAdmin(address _admin) external onlyAdmin isValidAddress(_admin) {
        require(this.isAdmin(_admin), 'Account is not an admin');
        require(administratorsCount > 1, 'There must be at least one admin');
        administratorsCount -= 1;
        delete administrators[_admin];
        delete withdrawals[_admin]; // To return GAS
    }

    function setSellPrice(uint256 _newSellPrice) external onlyAdmin {
        require(_newSellPrice > 0, 'Sell price must be greater than 0');
        require(_newSellPrice > buyPrice, 'Sell price must be greater than buy price');
        sellPrice = _newSellPrice;
    }

    function setBuyPrice(uint256 _newBuyPrice) external onlyAdmin {
        require(_newBuyPrice > 0, 'Buy price must be greater than 0');
        require(sellPrice > 0, 'Sell price must be set first');
        require(_newBuyPrice < sellPrice, 'Buy price must be lower than sell price');
        buyPrice = _newBuyPrice;
    }

    function burn(uint256 _amount) external isValidTokenContractAddress {
        require(!isContract(msg.sender), 'This function cannot be called by a contract');
        require(_amount > 0, 'Amount must be greater than 0');

        uint256 ethersToSend = buyPrice * _amount / (2 * (10 ** tokenContract.decimals()));
        bool enoughEthers = ethersToSend <= address(this).balance;
        require(enoughEthers, 'The amount of ethers to send must be lower or equal than the Vault balance');

        bool _success = tokenContract.burn(_amount,msg.sender);
        if (_success == true) {            
            payable(msg.sender).transfer(ethersToSend);
        }
        emit Burn(msg.sender, _amount);
    }

    /**
     * @dev This method is used to set the maximum percentage that could be withdrawn by a group of administrators
     * @param _maxPercentage must be an unsigned int between 0 and 50
     */
    function setMaxPercentage(uint8 _maxPercentage) external onlyAdmin {
        require(_maxPercentage <= 50, 'Withdraw percentage must be lower or equals than 50%');
        require(_maxPercentage > 0, 'Withdraw percentage must be greater than 0%');

        percentageToWithdraw = _maxPercentage;
    }

    /**
     * @dev An amount of ETH is requested to be withdrawn by the actual amount of administrators.
     * @ prerequisits:
     * 1. No previous request withdraws may exists.
     * 2. Number of administrators must be 2 or more.
     * 3. The amount must be less or equals than the percentage to withdrawn set of the current contract ETH balance.
     * 4. The contract ETH balance must be greater or equals than the amount requested.
     */
    function requestWithdraw(uint256 _amount) external onlyAdmin {
        require(!_requestWithdrawDetails.initialized, 'Already exists a pending withdraw request');
        require(administratorsCount >= 2, 'Cannot initiate a request withdraw with less than 2 administrators');

        uint256 _contractBalance = address(this).balance;

        require(_contractBalance >= _amount, 'There are insufficient funds to withdraw');

        require(checkMaximumAmountToWithdraw(_amount), 'Amount exceeds maximum percentage');

        uint256 _amountPerAdmin = _amount / administratorsCount;

        _requestWithdrawDetails.initialized = true;
        _requestWithdrawDetails.amountPerAdmin = _amountPerAdmin;
        _requestWithdrawDetails.requestAddress = msg.sender;
    }

    /**
     * @dev this method validates if the amount requested to withdraw is less or equals than
     * the contract balance * maximumPercentage allowed.
     *
     * Example:
     * - contract balance: 100 ETH
     * - maximum percentage: 10%
     * - administratorsCounts: 2
     * @param _requestedAmount cannot be greater than 10 ETH (maxWithdraw [5] * administratorsCounts [2])
     *
     * note: if administrators are added/removed, the algorithm will be restrictive in terms of allowance.
     * This means that the maximum amount to withdraw will be favorable to the contract:
     *
     * 1. requestWithdraw(10) => maxAmountToWithdraw = 10 ETH.
     * 2. apporveWithdraw()
     * 3. addAdministrator(admin_1) => administratorsCounts: 3
     * 4. requestWithdraw(9) => maxAmountToWithdraw = 8.5 ETH
     *      => (contractBalance [100] - (maxWithdraw [5] * administratorsCounts [3])) * 10% = 8.5 ETH
     */
    function checkMaximumAmountToWithdraw(uint256 _requestedAmount) public view returns (bool) {
        uint256 _allowedBalance = address(this).balance - (maxWithdraw * administratorsCount);
        uint256 _maximumAmountToWithdraw = (_allowedBalance * percentageToWithdraw) / 100;
        return _requestedAmount <= _maximumAmountToWithdraw;
    }

    function approveWithdraw() external onlyAdmin {
        require(_requestWithdrawDetails.initialized, 'There is no pending withdraw request for approve');
        require(administratorsCount >= 2, 'Cannot approve a withdraw with less than 2 administrators');
        require(msg.sender != _requestWithdrawDetails.requestAddress, 'Approval administrator must be different from admin who requested it');

        maxWithdraw += _requestWithdrawDetails.amountPerAdmin;

        clearRequestWithdrawDetails();
    }

    function rejectWithdraw() external onlyAdmin {
        require(_requestWithdrawDetails.initialized, 'There is no pending withdraw request for reject');
        require(msg.sender != _requestWithdrawDetails.requestAddress, 'Rejector administrator must be different from admin who requested it');

        clearRequestWithdrawDetails();
    }

    /**
     * @dev Reset struct informaton.
     * THIS WONT NEVER RELEASE MEMORY SLOT
     */
    function clearRequestWithdrawDetails() private {
        _requestWithdrawDetails.initialized = false;
        _requestWithdrawDetails.amountPerAdmin = 0;
        _requestWithdrawDetails.requestAddress = address(0);
    }

    /**
     * @dev The withdraw is the difference between (maxWithdraw) and (withdrawals[msg.sender]).
     * Amount already withdrawn is hold in withdrawals[] array.
     * This structure is initialized whenever an admin is added with (maxWithdraw) value.
     */
    function withdraw() external onlyAdmin {
        uint256 withdrawAmount = maxWithdraw - withdrawals[msg.sender];
        withdrawals[msg.sender] += withdrawAmount;
        payable(msg.sender).transfer(withdrawAmount);
    }

    function withdrawnAmount() external view onlyAdmin returns (uint256) {
        return withdrawals[msg.sender];
    }

    /**
     * @dev The maximum amount is the max amount an address can buy per transaction
     */
    function setMaxAmountToTransfer(uint256 _maxAmount) external onlyAdmin {
        require(_maxAmount > 0, 'The amount must be greater than 0');
        maxTokenAmount = _maxAmount;
    }

    /**
     * @dev Sell tokens to the contract
     */
    function exchangeEther(uint256 _tokensAmount) external contractIsReady {
        require(_tokensAmount > 0, 'The amount must be greater than 0');
        require(tokenContract.balanceOf(msg.sender) >= _tokensAmount, "The amount must be lower than the sender's balance");
        require(tokenContract.allowance(msg.sender, address(this)) >= _tokensAmount, 'Not enought allowance');
        require(maxTokenAmount >= _tokensAmount, 'Contract cannot buy more than the maximum amount');

        uint256 ethersToSend = _tokensAmount * buyPrice / (10 ** tokenContract.decimals());
        require(address(this).balance >= ethersToSend, 'Not enought liquidity');

        tokenContract.transferFrom(msg.sender, address(this), _tokensAmount);
        payable(msg.sender).transfer(ethersToSend);
        emit Buy(msg.sender, _tokensAmount, buyPrice);
    }

    function setAPR(uint8 _value) external onlyAdmin {
        require(_value <= 100, 'APR value is invalid');

        bytes memory  methodToCall = abi.encodeWithSignature('setAPR(uint8)', _value);
        (bool success,) = farmAddress.call(methodToCall);
        require(success, 'Could not set Farm APR');
    }

    /**
     * @dev Buy tokens from the contract
     */
    receive() external payable contractIsReady {
        uint256 maxAmount = msg.value / sellPrice;
        require(maxTokenAmount >= maxAmount, 'Contract cannot sell more than the maximum amount');

        uint256 tokensToSell;
        uint256 ethersToReturn;
        uint256 contractBalance = tokenContract.balanceOf(address(this));
        if (maxAmount > contractBalance) {
            tokensToSell = contractBalance;
            ethersToReturn = (maxAmount - contractBalance) * sellPrice;
        } else {
            tokensToSell = maxAmount;
        }

        tokenContract.transfer(msg.sender, tokensToSell);
        if (ethersToReturn > 0) {
            payable(msg.sender).transfer(ethersToReturn);
        }
        emit Sell(msg.sender, tokensToSell, sellPrice);
    }

    /**
     * @dev Checks whether an address corresponds to a contract or not
     */
    function isContract(address addr) private view returns (bool) {
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(addr)
        }

        return (codeHash != accountHash && codeHash != 0x0);
    }

    function mint(uint256 _amount) external onlyAdmin isValidTokenContractAddress {
        if (_mint.sender == address(0)){
            _mint.sender = msg.sender;
            _mint.timestamp = block.timestamp;
            _mint.amount = _amount;
            return;
        } 
        
        if ((block.timestamp - _mint.timestamp) > fiveMinutes) {
            // Previous request expired, create a new one
            _mint.sender = msg.sender;
            _mint.timestamp = block.timestamp;
            _mint.amount = _amount;
            return;
        }

        require(_mint.sender != msg.sender, 'Signer must be different.');
        require(_mint.amount == _amount, 'Amount is not the same.');
        _mint.sender = address(0);
        tokenContract.mint(_amount);
    }
}