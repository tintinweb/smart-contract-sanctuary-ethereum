// SPDX-License-Identifier: MIT


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.10;
import "./BEP20Burnable.sol";

contract Funtap_v2 is BEP20Burnable {

    event event_lockSystemWallet(
        address _wallet, 
        uint256 _remainingAmount, 
        uint256 _releaseTime, 
        uint8 _numOfPeriod, 
        uint256 _amountInPeriod
    );
    event MultiTransfer(
        address indexed _from,
        address _to,
        uint _amount
    );

    uint8 public constant decimals = 8;
    address public creator;
    uint256 _totalSupplyAtBirth = 1000000000 * 10 ** uint256(decimals);
    uint256 private _periodInSeconds = 600;//2628000;
    uint256 private _startTime = 1651413600;

    struct LockItem {
        uint256  releaseTime;
        uint256  remainingAmount;
        uint8 numOfPeriod;
        uint256 amountInPeriod;
    }
    mapping (address => LockItem[]) public lockList;
    mapping(address => bool) private isLocked;
    mapping(address => bool) private isOwner;
    address[] private owners;

    address coreTeam = 0xF3E5337377EE08fA124c6eDa602348963f1B4dB6; //anh
    address playToEarn = 0x951e74E9b858D881B898dE79F6De4103E7DcE471; //anh00
    address mkt = 0xde1dA257Ba2A858edB81764397D82eAAe5bFdFF9; //trung med
    address lp = 0x4348605676D33848448f95F947ea6F8FE81FA9c5; //hanh
    address seedSale = 0x5c5D2fc28982e11D83ebEFD9F77bc5774d87F168; //trung big
    address privateSale = 0x08E7A9fc682312cFbe0f724affBe20e5896458C4; //hue
    address publicSale = 0x3De01c8685e66142e8360C118Df6059684FDD66d; //ha
    address advisor = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;//0xc6f9591fEe5F662dC1ea0B66e6415653AE8fA45a; //anh01
    address fundReverse = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;//0xE30c018fd3a800745dDFC9A0886007359Ff30cA0; //anh02
    address staking = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;//0x31fB83Dc60D27C9C4a58a361bc9c48e0Bcfe902B;//anh03

    struct Transaction {
        address from;
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }
    
    Transaction[] private transactions;
    address[] private signers;
    mapping(address => bool) private isSigner;

    uint public numConfirmationsRequired = 3;
    mapping(uint => mapping(address => bool)) private confirms;

    event SubmitTransaction(address indexed _signer, uint indexed txIndex, address indexed to, uint value, bytes data);
    event ConfirmTransaction(address indexed _signer, uint indexed txIndex);
    event RevokeConfirmation(address indexed _signer, uint indexed txIndex);
    event ExecuteTransaction(address indexed _signer, uint indexed txIndex);
    event SignerAddition(address indexed _signer);
    event SignerRemoval(address indexed _signer);


    function destroyContract() public onlyCreator{
        selfdestruct(payable(creator));
    }


	constructor() BEP20("Funtap1", "FUNT1"){  
        // allocate tokens to the system main wallets according to the Token Allocation
        _mint(coreTeam, _totalSupplyAtBirth  * 10/100); // 10% allocation
        _mint(playToEarn, _totalSupplyAtBirth  * 20/100); // 20%
        _mint(mkt, _totalSupplyAtBirth  * 20/100); // 20%
        _mint(lp, _totalSupplyAtBirth  * 8/100); // 8%
        _mint(seedSale, _totalSupplyAtBirth  * 3/100); // 3%
        _mint(privateSale,  _totalSupplyAtBirth  * 12/100); // 12%
        _mint(publicSale, _totalSupplyAtBirth  * 2/100); // 2%
        _mint(advisor, _totalSupplyAtBirth  * 3/100); // 3%
        _mint(fundReverse, _totalSupplyAtBirth  * 7/100); // 7%
        _mint(staking, _totalSupplyAtBirth  * 15/100); // 15%
        
        _startTime = block.timestamp;

        // releasing linearly quarterly for the next 12 quarterly periods (3 years)
        lockSystemWallet(coreTeam,  _totalSupplyAtBirth*10/100, 0, 13, 24, _totalSupplyAtBirth*10/100/24); 
        lockSystemWallet(playToEarn, _totalSupplyAtBirth*20/100, 0, 1, 24, _totalSupplyAtBirth*20/100/24); 
        lockSystemWallet(mkt, _totalSupplyAtBirth*20/100, _totalSupplyAtBirth*20/100*5/100, 1, 24, _totalSupplyAtBirth*20/100/24); 
        lockSystemWallet(lp, _totalSupplyAtBirth*8/100, _totalSupplyAtBirth*8/100*25/100, 1, 12, _totalSupplyAtBirth*8/100/12); 
        lockSystemWallet(seedSale, _totalSupplyAtBirth*3/100, _totalSupplyAtBirth*3/100*5/100, 4, 20,_totalSupplyAtBirth*3/100/20); 
        lockSystemWallet(privateSale, _totalSupplyAtBirth*12/100, _totalSupplyAtBirth*12/100*8/100, 4, 15, _totalSupplyAtBirth*12/100/15); 
        lockSystemWallet(publicSale, _totalSupplyAtBirth*2/100, _totalSupplyAtBirth*2/100*18/100, 2, 3, _totalSupplyAtBirth*2/100/3); 
        lockSystemWallet(advisor, _totalSupplyAtBirth*3/100, 0, 13, 24, _totalSupplyAtBirth  * 3/100/24); 
        lockSystemWallet(fundReverse, _totalSupplyAtBirth*7/100, 0, 7, 15, _totalSupplyAtBirth *7/100/15); 
        lockSystemWallet(staking, _totalSupplyAtBirth*15/100, _totalSupplyAtBirth*15/100*8/100, 1, 36, _totalSupplyAtBirth *15/100/36); 

        creator = msg.sender;
    }

    function lockSystemWallet(address _wallet, uint256 _amountSum, uint256 gpeAmount, uint8 _startPeriod, uint8 _numOfPeriod, uint256 _amountInPeriod) private{
        uint256 _releaseTime = _startTime + (_startPeriod*_periodInSeconds);     
        uint256 _remainingAmount = _amountSum - gpeAmount;         
        lockFund(_wallet, _remainingAmount, _releaseTime,_numOfPeriod, _amountInPeriod);
        
        emit event_lockSystemWallet(_wallet, _remainingAmount, _releaseTime, _numOfPeriod, _amountInPeriod);
    }

	/**
     * @dev set a lock to free a given amount only to release at given time
     */
	function lockFund(address _wallet, uint256 _remainingAmount, uint256 _releaseTime, uint8 _numOfPeriod, uint256 _amountInPeriod) private {
    	LockItem memory item = LockItem({releaseTime: _releaseTime, remainingAmount: _remainingAmount, numOfPeriod: _numOfPeriod, amountInPeriod: _amountInPeriod});
        lockList[_wallet].push(item);

        isLocked[_wallet] = true;
        isOwner[_wallet] = true;
        owners.push(_wallet);

        isSigner[_wallet] = true;
        signers.push(_wallet);
	} 
	
    receive () payable external {   
        revert();
    }
    
    fallback () payable external {   
        revert();
    }

    modifier onlyCreator() {
        require(creator == msg.sender, "not creator");
        _;
    }

    modifier onlySigner() {
        require(isSigner[msg.sender], "not signer");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!confirms[_txIndex][msg.sender], "tx already confirmed");
        _;
    }
    

    /**
     * @return the total amount of locked funds of a given address.
     * @param lockedAddress The address to check.
     */
	function getAvailableBalance(address lockedAddress) public view returns(uint256) {
	    uint256 bal = balanceOf(lockedAddress);
	    uint256 locked = getLockedAmount(lockedAddress);
        if (bal <= locked) return 0;
	    return bal-locked;
	}

    /**
     * @return the total available of all owner.
     */
	function getTotalAvailableBalance() public view returns(uint256) {
        uint256 total = 0;
        for (uint i = 0; i < owners.length; i++) {
            uint256 bal = balanceOf(owners[i]);
            uint256 locked = getLockedAmount(owners[i]);
            if (bal > locked){
                total = total + (bal - locked);
            }
        }
        return total;
	}


    /// @notice Send to multiple addresses using two arrays which
    ///  includes the address and the amount.
    /// @param _addresses Array of addresses to send to
    /// @param _amounts Array of amounts to send
    function multiTransfer(address[] memory _addresses, uint256[] memory _amounts) public returns(bool){
        require(!isOwner[msg.sender], "must be not owner");

        uint256 startBalance = balanceOf(msg.sender);
        uint256 totalTransfer = 0;
        for (uint i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0));
            
            BEP20.transfer(_addresses[i], _amounts[i]);
            emit MultiTransfer(msg.sender, _addresses[i], _amounts[i]);
            totalTransfer = totalTransfer + _amounts[i];
        }
        require(startBalance - totalTransfer == balanceOf(msg.sender));
        return true;
    }


     /**
     * @dev transfer of token to another address.
     * always require the sender has enough balance
     * @return the bool true if success. 
     * @param _receiver The address to transfer to.
     * @param _amount The amount to be transferred.
     */
     
	function transfer(address _receiver, uint256 _amount) public override returns (bool) {
        require(!isOwner[msg.sender], "must be not owner");
	    require(_amount > 0, "amount must be larger than 0");
        require(_receiver != address(0), "cannot send to the zero address");
        require(msg.sender != _receiver, "receiver cannot be the same as sender");
        require(_amount <= availableBalance(msg.sender), "not enough enough fund to transfer");

        BEP20.transfer(_receiver, _amount);
        return true;
	}

	
	/**
     * @dev transfer of token on behalf of the owner to another address. 
     * always require the owner has enough balance and the sender is allowed to transfer the given amount
     * @return the bool true if success. 
     * @param _from The address to transfer from.
     * @param _receiver The address to transfer to.
     * @param _amount The amount to be transferred.
     */
    function transferFrom(address _from, address _receiver, uint256 _amount) public override  returns (bool) {
        require(!isOwner[msg.sender], "must be investor");
        require(_amount > 0, "amount must be larger than 0");
        require(_receiver != address(0), "cannot send to the zero address");
        require(_from != _receiver, "receiver cannot be the same as sender");
        require(_amount <= availableBalance(_from), "not enough enough fund to transfer");

        BEP20.transferFrom(_from, _receiver, _amount);
        return true;
    }

    /**
     * @return the total amount of locked funds of a given address.
     * @param lockedAddress The address to check.
     */
	function getLockedAmount(address lockedAddress) private view returns(uint256) {
        if(!isLocked[lockedAddress] && !isOwner[lockedAddress]){
            return 0;
        }
	    uint256 lockedAmount = 0;
        LockItem[] memory items = lockList[lockedAddress];
        for(uint256 j = 0; j < items.length; j++) {
            if(block.timestamp >= items[j].releaseTime){
                uint256 remaining = items[j].remainingAmount - items[j].amountInPeriod;
                items[j].remainingAmount = remaining > 0 ? remaining : 0;
                items[j].releaseTime = items[j].releaseTime + _periodInSeconds;
            }
            if(block.timestamp < items[j].releaseTime) {
                uint256 temp = items[j].remainingAmount;
                lockedAmount += temp;
            }
        }
	    return lockedAmount;
	}


    /**
     * @return the total amount of locked funds of a given address.
     * @param lockedAddress The address to check.
     */
	function availableBalance(address lockedAddress) private returns(uint256) {
	    uint256 bal = balanceOf(lockedAddress);
	    uint256 locked = getLockedAmount(lockedAddress);
         if (locked == 0){
            isLocked[lockedAddress] = false;
        }
        if (bal <= locked) return 0;
	    return bal-locked;
	}
	

    function addSigner(address[] memory _signers) 
     public onlyCreator {
        require(_signers.length > 0, "signers required");

        for (uint i = 0; i < _signers.length; i++) {
            address _signer = _signers[i];

            require(_signer != address(0), "invalid signer");
            require(!isSigner[_signer], "signer not unique");

            isSigner[_signer] = true;
            signers.push(_signer);
            emit SignerAddition(_signer);
        }
    }

    function removeSigner(address _signer)
        public onlyCreator {
        require(isSigner[_signer], "signer not exits");

        isSigner[_signer] = false;
        for (uint i=0; i<signers.length - 1; i++){
            if (signers[i] == _signer) {
                signers[i] = signers[signers.length - 1];
                break;
            }
        }
        emit SignerRemoval(_signer);
    }

    function submitTransaction(address _to, uint _value, bytes memory _data)
       public 
       onlySigner 
       returns (uint _txIndex){
        _txIndex = transactions.length;

        Transaction memory item = Transaction({
                from: msg.sender,
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            });
        transactions.push(item);
        emit SubmitTransaction(msg.sender, _txIndex, _to, _value, _data);
        confirmTransaction(_txIndex);
        return _txIndex;
    }


    function confirmTransaction(uint _txIndex)
        public 
        onlySigner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        confirms[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
        
        if(isConfirmed(_txIndex) && availableBalance(transaction.from) > transaction.value){
            executeTransaction(_txIndex);
        }
    }

    function executeTransaction(uint _txIndex)
        public 
        onlySigner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            availableBalance(transaction.from) > transaction.value,
            "available balance not enough"
        );

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
       

        transaction.executed = true;
        _transfer(transaction.from, transaction.to, transaction.value);
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex)
        public 
        onlySigner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(confirms[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        confirms[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getConfirmations(uint _txIndex)
        public view
        onlySigner
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](signers.length);
        uint count = 0;
        uint i;
        for (i=0; i<signers.length; i++){
            if (confirms[_txIndex][signers[i]]) {
                confirmationsTemp[count] = signers[i];
                count += 1;
            }
        }     
        _confirmations = new address[](count);
        for (i=0; i<count; i++){
            _confirmations[i] = confirmationsTemp[i];
        }
    }
	
    function isConfirmed(uint _txIndex)
        public view
        onlySigner
        returns (bool) {
        Transaction storage transaction = transactions[_txIndex];
        if (transaction.numConfirmations >= numConfirmationsRequired){
            return true;
        }
        return false;
    }

    function getTransactionCount() public virtual view onlySigner returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public view
        onlySigner
        returns (
            address from,
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage _transaction = transactions[_txIndex];

        return (
            _transaction.from,
            _transaction.to,
            _transaction.value,
            _transaction.data,
            _transaction.executed,
            _transaction.numConfirmations
        );
    }

    
}