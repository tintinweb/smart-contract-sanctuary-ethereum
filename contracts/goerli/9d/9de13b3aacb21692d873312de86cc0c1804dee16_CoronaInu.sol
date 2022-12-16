/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

//Ownable library clone
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }


  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }


  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}


interface IERC20 {
    function symbol() external view returns (string memory);
    
    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external;


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IAirdrop {
    function airdrop(address recipient, uint256 amount) external;
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _symbol;
    string private _name;
    uint256 private _totalSupply;
    address private _owner;

    constructor(string memory name_, string memory symbol_){
        _name = name_;
        _symbol = symbol_;
        _owner = _msgSender();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override{
        _transfer(_msgSender(), recipient, amount);
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override{
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);

        
        _balances[account] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual{
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
contract CommonUtil{
    struct LockItem {       
        uint256 tgeAmount;
        uint256 tgeTime;
        uint256 releaseTime;
        uint256 lockedAmount;
        uint256 amountInPeriod;
        
    }

    struct Transaction {
        uint256 id;
        address from;
        address to;
        uint256 value;
        bool isExecuted;
        bool canExecuted;
        uint256 numConfirmations;
        uint256[] lockParams;
        address[] signers;
    }

    struct TradingPool {
        address poolAddr;
        // can be 0,1. default 0. 0: no tax, 1: tax
        uint8 takeFee;
        uint256 buyTaxFee;
        uint256 totalTax;
    }

    uint256 public periodInSecond = 900;  // 1 months

    event SubmitTransaction(address indexed _signer, uint256 indexed txIndex, address indexed to, uint256 value);
    event ConfirmTransaction(address indexed _signer, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed _signer, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed _signer, uint256 indexed txIndex);
    event CheckExecuteTransaction(address _from, address _to, uint256 _available, uint256 _value, bool _execute);

    event ChangeTaxWalletAddress(address indexed _oldAddress, address indexed _newAddress);
    event ReceivedEther(address indexed _sender, uint256 _amount);
    event LogSender(address _sender, address _from, address _receiver, address _pool, uint8 _isSell, uint256 _value);
    event FeeGetting(address indexed _from, address indexed _to, uint256 _value);

    event event_lockSystemWallet(address _sender, address _wallet, uint256 _lockedAmount, uint256 _releaseTime, uint256 _numOfPeriod);
    event event_lockWallet(address _sender, address _wallet, uint256 _lockedAmount, uint256 _releaseTime, uint256 _numOfPeriod);

    function _getLockItem(uint256 _amount, uint256 _nextReleaseTime, uint256 _numOfPeriod, uint256 _tgeTime, uint256 _tgeAmount) 
    internal pure returns (LockItem memory){
        uint256 _lockedAmount = _amount - _tgeAmount;
        return LockItem({
            tgeTime: _tgeTime,
            tgeAmount: _tgeAmount,
            releaseTime: _nextReleaseTime, 
            lockedAmount: _lockedAmount, 
            amountInPeriod: (_lockedAmount/_numOfPeriod)
            });
    }
    
    function _getTradingPool(address _addr, uint8 _takeFee, uint256 _buyTaxFee) internal pure returns (TradingPool memory){
        return TradingPool({
            poolAddr: _addr,
            takeFee: _takeFee,
            buyTaxFee: _buyTaxFee,
            totalTax: 0
            });
    }
}

contract CoronaInu is ERC20, Ownable, CommonUtil {
  using SafeMath for uint256;
  // ------------------------ DECLARATION ------------------------
  uint256 private _txIndex = 1;

  address private taxWallet;
  uint16 public numOfSigners = 0;
  uint16 public leastSignerConfirm = 1;
  uint8 public constant decimals = 8;

  uint8 private takeFee = 0;
  uint256 private feeTransfer=0;

  // 1 if in whitelist, 2 if in blacklist`
  mapping(address => uint8) internal _specialList;
  // 1 if signer, 2 if admin
  mapping(address => uint8) internal roles;
  // address system wallet
  mapping(address => bool) internal isSystem;
  // address -> lockItem
  mapping (address => LockItem) internal lockeds;
  // address -> tradingPool
  mapping(address => TradingPool) internal tradingPools;
  // check locked
  mapping(address => bool) isLocked;

  //txId -> transactions
  mapping(uint256 => Transaction) internal mapTransactions;
  // txId -> address signer -> bool(confirmed)
  mapping(uint256 => mapping(address => bool)) private confirms;

  constructor(address _taxAddress, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
      taxWallet = _taxAddress;
      roles[_msgSender()] = 2;
  }

  function mint(uint256 _totalSupply, uint256 _releaseDate, address[] memory _wallets, uint256[] memory _percents, address[] memory _signers,
    uint256[] memory _tgePercents, uint256[] memory _numOfPeriods, uint256[] memory _cliffs) external onlyOwner {
        _totalSupply = _totalSupply * 10 ** uint256(decimals);

        for (uint256 i = 0; i < _wallets.length; i++) {
            require(roles[_wallets[i]] != 1, "Address that was signer cannot be system");
            require(!isSystem[_wallets[i]], "Must mint to address that has not been system yet");

            uint256 _amount = _totalSupply  * _percents[i]/100;
            uint256 _tgeAmount = _amount * _tgePercents[i]/100;
            uint256 _nextReleaseTime = _releaseDate + (_cliffs[i] * periodInSecond);
            _mint(_wallets[i], _amount); 

            LockItem memory item = _getLockItem(_amount, _nextReleaseTime, _numOfPeriods[i], _releaseDate, _tgeAmount);
            lockeds[_wallets[i]] = item;
            isLocked[_wallets[i]] = true;
            isSystem[_wallets[i]] = true; 
            emit event_lockSystemWallet(owner, _wallets[i], item.lockedAmount, item.releaseTime, _numOfPeriods[i]);
        }
        for (uint256 i = 0; i < _signers.length; i++) {
            require(!isSystem[_signers[i]], "Address that was system cannot be signer");
            if(roles[_signers[i]] != 1) ++numOfSigners;
            roles[_signers[i]] = 1; 
        }
  }

  function burn(address _address, uint256 _totalBurn) public onlyOwner{
      uint256 _amount = _totalBurn * 10 ** decimals;
      _burn(_address, _amount);
  }
  
  function withdraw(address _tokenContract, address _receiveAddress, uint256 amount) external onlyOwner {
      require(_receiveAddress != address(0), "require receive address");
      if(_tokenContract == address(0)){
          uint256 value = address(this).balance;
          require(value >= amount, "current balance must be than withdraw amount");
          payable(_receiveAddress).transfer(amount);
      }else{
          IERC20 token = IERC20(_tokenContract);
          uint256 value = token.balanceOf(address(this));
          require(value >= amount, "current balance must be than withdraw amount");
          token.transfer(_receiveAddress, amount);
      }
  }

  function initTradingPool(address _poolAddress, uint8 takeFee_, uint256 _buyTaxFee) external onlyOwner {
        require(!isPoolWallet(_poolAddress), "Pool had exist");
        TradingPool memory _pool = _getTradingPool(_poolAddress, takeFee_,_buyTaxFee);
        tradingPools[_poolAddress] = _pool;
  }

  function removeTradingPool(address _addr) external onlyOwner {
        delete tradingPools[_addr];
  }

  function editTradingPool(address _poolAddress, uint8 takeFee_, uint256 _buyTaxFee)  external onlyOwner {
      require(isPoolWallet(_poolAddress), "Pool not exist");
      TradingPool storage pool = tradingPools[_poolAddress];
      pool.takeFee = takeFee_;
      pool.buyTaxFee = _buyTaxFee;
  }

  function roleAdd(address[] memory _addresses, uint8[] memory _roles) external onlyOwner{
      for (uint256 i = 0; i < _addresses.length; i++) {
          if(_roles[i]==1 && roles[_addresses[i]] != 1){   // signer
            ++numOfSigners;
          }
          if(_roles[i] == 2){ //if address is admin => add to whilelist
             _specialList[_addresses[i]] = 1;
          }
          roles[_addresses[i]] = _roles[i];
      }
  }

  function roleRemove(address[] memory _addresses) external onlyOwner{
    for (uint256 i = 0; i < _addresses.length; i++) {
        address _add = _addresses[i];           
        require(roles[_add] > 0 , "Address is not admin or signer");
      
        if(roles[_add] == 1) {
          --numOfSigners;
        }else if(roles[_add] == 2){ //if address is admin => remove from whilelist
          _specialList[_addresses[i]] = 0;
        }
        roles[_add] = 0;
    }
  }

  function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        roles[owner] = 0;
        roles[newOwner] = 2;
        owner = newOwner;
  }

  function specialAdd(address[] memory _addresses, uint8[] memory _types) public onlyOwner{
        for (uint256 i = 0; i < _addresses.length; i++) {              
            _specialList[_addresses[i]] = _types[i];
        }
  }

  function specialRemove(address _address) public onlyOwner{
        delete _specialList[_address];
  }

  function setTransferFee(uint8 _takeFee, uint256 _feeTransfer) external onlyOwner(){
        takeFee = _takeFee;
        feeTransfer = _feeTransfer;
  }

  function getTransferFee() external view returns(uint8, uint256){
        return (takeFee, feeTransfer);
  }

  function setLeastSignerConfirm(uint8 _leastSigner) external onlyAdmin {
      require(_leastSigner <=  numOfSigners, "Least of signer confirm must be less than num of signer");
      leastSignerConfirm = _leastSigner;
  }

  function setTaxWallet(address _taxWallet) external onlyAdmin {
    require(_taxWallet != address(0), "Tax wallet address cannot be zero address");
    emit ChangeTaxWalletAddress(taxWallet, _taxWallet);
    taxWallet = _taxWallet;
  }

  function getLockeds(address _address) external view 
  onlyAdmin 
  requireSystem 
  returns(LockItem memory) {
      return lockeds[_address];
  }

  function getTaxWallet() external view onlyAdmin returns(address) {
      return taxWallet;
  }

  function getRoles(address _address) external view onlyAdmin returns(uint) {
    return roles[_address];
  }

  function getSpecialList(address _address) external view onlyAdmin returns(uint8){
      return _specialList[_address];
  }

  function getTradingPool(address _address) external view onlyAdmin returns(TradingPool memory) {
      require(isPoolWallet(_address), "Pool not exist");
      return tradingPools[_address];
  }

  function getSystem(address _address) public view onlyAdmin returns(bool) {
      return isSystem[_address];
  }

// ------------------------MODIFIERs ------------------------
  modifier onlyAdmin() {
    require(roles[_msgSender()]== 2 || _msgSender() == owner , "Caller must to owner or admin");
    _;
  }

  modifier requireSigner() {
    require(roles[_msgSender()] == 1, "Access denied. Required signer Role");
    _;
  }

  modifier requireSystem() {
    require(isSystem[_msgSender()] == true, "Access denied. Required system wallet");
    _;
  }

  modifier requiredTransfer(address _sender, address _from, address _receiver, uint256 _amount) {
      require(_specialList[_sender] != 2, "sender in black list");
      require(_specialList[_from] != 2, "from address in black list");
      require(_from != _receiver && _receiver != address(0), "invalid address");
      require(_amount > 0 && _amount <= _availableBalance(_from), "not enough funds to transfer");
      _;
  }
  
  modifier onlyWhitelist(){
    require(_specialList[msg.sender] == 1, "Access denied. Required whitelist Role");
    _;
  }
  
// ------------------------FOR SIGNER AND SYSTEM WALLET ------------------------
  function _validateTransaction(uint256 _txId) internal view returns (bool){
      Transaction memory _transaction = mapTransactions[_txId];
      require(mapTransactions[_txId].to != address(0), "tx does not exist");
      require(!_transaction.isExecuted, "tx already executed");
      return true;
  }

  function getTransactions() public view  returns (Transaction[] memory) {
       require(_txIndex > 1, "Not submit any transaction yet");
       uint256 _currentId = _txIndex - 1;
       Transaction[] memory _transactions = new Transaction[](_currentId);
       for (uint256 i = 0; i < _currentId; i++) {
          Transaction storage _transaction = mapTransactions[i+1];
          _transactions[i] = _transaction;
       }
       return _transactions;
  }

  function getTransaction(uint256 _txId) public view returns (Transaction memory){
      return mapTransactions[_txId];
  }

  function getSignerOfTransaction(uint256 _txId) public view 
  returns (address[] memory) {
      require(isSystem[_msgSender()] || roles[_msgSender()]>0 || _msgSender() == owner, "Caller must to owner, admin or system");
      return mapTransactions[_txId].signers;
  }

  function transactionSubmit(address _receiver, uint256 _value, uint256[] memory _lockParams) public 
  requireSystem returns (bool){
      Transaction memory item = Transaction(
          { 
              id: _txIndex,
              from: _msgSender(), 
              to: _receiver, 
              value: _value, 
              isExecuted: false, 
              canExecuted: false,
              numConfirmations: 0, 
              lockParams: _lockParams,
              signers: new address[](0)
          });
      mapTransactions[_txIndex] = item;
      emit SubmitTransaction( _msgSender(), _txIndex, _receiver, _value);
      _txIndex += 1;
      return true;
  }

  function transactionConfirm(uint256 _txId) public 
  requireSigner
  returns (bool){
      require(!confirms[_txId][_msgSender()], "tx already confirmed");
      _validateTransaction(_txId);

      Transaction storage _transaction = mapTransactions[_txId];
      _transaction.numConfirmations += 1;
      _transaction.signers.push(_msgSender());
      confirms[_txId][_msgSender()] = true;

      if (_transaction.numConfirmations == leastSignerConfirm){
          _transaction.canExecuted = true;
          transactionExecuted(_txId);
      }
      return true;
  }

  function transactionRevoke(uint256 _txId) public 
  requireSigner
  returns (bool){
      require(confirms[_txId][_msgSender()], "tx unconfirmed");
      _validateTransaction(_txId);

      Transaction storage _transaction = mapTransactions[_txId];
      _transaction.numConfirmations -= 1;
      bool existed;
      uint256 index;
      (existed, index) = _indexOf(_transaction.signers, _msgSender());
      if(existed) {
          _transaction.signers[index] = _transaction.signers[_transaction.signers.length - 1];
          _transaction.signers.pop();
      }
      confirms[_txId][_msgSender()] = false;
      return true;
  }

  function transactionExecuted(uint256 _txId) public 
  requireSigner
  returns (bool){
      _validateTransaction(_txId);

      Transaction storage _transaction = mapTransactions[_txId];
      require(_availableBalance(_transaction.from) >=  _transaction.value, "from address not enough balance");
      require(_transaction.canExecuted == true, "tx not enough signers confirm");

      _transfer(_transaction.from, _transaction.to, _transaction.value);
      uint256[] memory _params = _transaction.lockParams;
      if(_params.length >0  && _params[0] > 0){
          LockItem memory item = _getLockItem(_transaction.value, _params[0], _params[1], 0, 0);
          lockeds[_transaction.to]= item;
          isLocked[_transaction.to] = true;
          emit event_lockWallet(_transaction.from, _transaction.to, item.lockedAmount, item.releaseTime, _params[1]);
      }
      _transaction.isExecuted = true;
      emit ExecuteTransaction(_msgSender(), _txId);
      return true;
  }

  function _availableBalance(address lockedAddress) internal returns(uint256) {
      uint256 bal = balanceOf(lockedAddress);
      uint256 locked = _getLockedAmount(lockedAddress);
      if(locked == 0) {
          isLocked[lockedAddress] = false;
      }
      return bal-locked;
	}

  function _indexOf(address[] memory addresses, address seach) internal pure returns(bool, uint256){
    for(uint256 i =0; i< addresses.length; ++i){
      if (addresses[i] == seach){
        return (true,i);
      }
    }
    return (false,0);
  }  

  // ------------------------FOR TOKEN ------------------------
  
  function getAvailableBalance(address lockedAddress) public view returns(uint256) {
      uint256 bal = balanceOf(lockedAddress);
      uint256 locked = _getLockedAmount(lockedAddress);
      return bal-locked;
    }

  function _getLockedAmount(address lockedAddress) internal view returns(uint256) {
      if(isLocked[lockedAddress] == false) return 0;    
      LockItem memory item = lockeds[lockedAddress];
      if(item.tgeAmount > 0 && block.timestamp >= item.tgeTime){
          item.tgeAmount = 0;
      }
      if(item.lockedAmount > 0){
          while(block.timestamp >= item.releaseTime){
              if(item.lockedAmount > item.amountInPeriod){
                  item.lockedAmount = item.lockedAmount - item.amountInPeriod;
              }else{
                  item.lockedAmount = 0;
              }
              item.releaseTime = item.releaseTime + periodInSecond;
          }
      }
      return item.lockedAmount + item.tgeAmount;
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
      require(!isSystem[_msgSender()], "System has to use transaction submit");
      _approve(_msgSender(), spender, amount);
      return true;
  }

  function transfer(address _receiver, uint256 _amount) public override{
        require(!isSystem[_msgSender()], "System has to use transaction submit");
        _doTransfer(_msgSender(), _msgSender(), _receiver, _amount);
  }
	
  function transferFrom(address _from, address _receiver, uint256 _amount)  public override {
        require(!isSystem[_msgSender()], "System has to use transaction submit");
        require(!isSystem[_from], "Cannot transfer from system wallet!");

        _doTransfer(_msgSender(), _from, _receiver, _amount);
        
        uint256 currentAllowance = ERC20.allowance(_from, _msgSender());
        require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(_from, _msgSender(), currentAllowance - _amount);
        }
  }

  function _doTransfer(address _sender, address _from, address _receiver, uint256 _amount) internal 
  requiredTransfer(_sender, _from, _receiver, _amount) returns (bool){
        require(_specialList[_sender] != 2, 'blacklist block');
        //calc taxFee // only supprt 0.0x percent
        uint256 _taxFee = 0; 
        if(isPoolWallet(_from)){
            uint256 _feePercent = _getFeeFromPool(_from);
            _taxFee = _amount.mul(_feePercent).div(10**4); 
        }else if(takeFee > 0){
            _taxFee = _amount.mul(feeTransfer).div(10**4);
        }
        // if in whitelist or sell case (pool) or no _takeFee 
        if(_taxFee == 0 || _specialList[_receiver] == 1 || isPoolWallet(_receiver)){
            _transfer(_from, _receiver, _amount);
            return true;
        }

        if(isPoolWallet(_from)){
            tradingPools[_from].totalTax = tradingPools[_from].totalTax.add(_taxFee);
        }
        _transfer(_from, _receiver, _amount.sub(_taxFee));
        _balances[taxWallet] = _balances[taxWallet].add(_taxFee);
        _balances[_from] =_balances[_from].sub(_taxFee);
        emit FeeGetting(_from, taxWallet, _taxFee);
        return true;
  }

  function _getFeeFromPool(address _add) internal view returns (uint256){
      TradingPool memory _pool = tradingPools[_add];
      if(_pool.takeFee == 0){
          return 0;
      }
      return _pool.buyTaxFee;
  }


  function isPoolWallet(address _address) private view returns(bool){
      return tradingPools[_address].poolAddr != address(0);
  }

  receive() external payable {
      emit ReceivedEther(msg.sender, msg.value);
  }
}