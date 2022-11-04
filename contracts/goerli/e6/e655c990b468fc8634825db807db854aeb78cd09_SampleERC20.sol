/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract VersionedContract {
  uint[] internal VERSIONS = [1];

  function getVersion() public view virtual returns (uint[] memory) {
      return VERSIONS;
  }
}

abstract contract DSTokenInterface is VersionedContract {
  constructor() {
    VERSIONS.push(1);
  }

  string internal constant CAP = "cap";
  string internal constant TOTAL_ISSUED = "totalIssued";
  string internal constant TOTAL_SUPPLY = "totalSupply";
  string internal constant BALANCES = "balances";
  string internal constant INVESTORS = "investors";
  string internal constant WALLET_LIST = "walletList";
  string internal constant WALLET_COUNT = "walletCount";
  string internal constant WALLET_TO_INDEX = "walletToIndex";
  string internal constant PAUSED = "paused";

  event Issue(address indexed to, uint256 value, uint256 valueLocked);
  event Burn(address indexed burner, uint256 value, string reason);
  event Seize(address indexed from, address indexed to, uint256 value, string reason);

  event WalletAdded(address wallet);
  event WalletRemoved(address wallet);

  /******************************
       CONFIGURATION
   *******************************/

  /**
  * @dev Sets the total issuance cap
  * Note: The cap is compared to the total number of issued token, not the total number of tokens available,
  * So if a token is burned, it is not removed from the "total number of issued".
  * This call cannot be called again after it was called once.
  * @param _cap address The address which is going to receive the newly issued tokens
  */
  function setCap(uint256 _cap) public virtual /*onlyMaster*/;

  /******************************
       TOKEN ISSUANCE (MINTING)
   *******************************/

  /**
  * @dev Issues unlocked tokens
  * @param _to address The address which is going to receive the newly issued tokens
  * @param _value uint256 the value of tokens to issue
  * @return true if successful
  */
  function issueTokens(address _to, uint256 _value) /*onlyIssuerOrAbove*/ public virtual returns (bool);

  /**
  * @dev Issuing tokens from the fund
  * @param _to address The address which is going to receive the newly issued tokens
  * @param _value uint256 the value of tokens to issue
  * @param _valueLocked uint256 value of tokens, from those issued, to lock immediately.
  * @param _reason reason for token locking
  * @param _releaseTime timestamp to release the lock (or 0 for locks which can only released by an unlockTokens call)
  * @return true if successful
  */
  function issueTokensCustom(address _to, uint256 _value, uint256 _issuanceTime, uint256 _valueLocked, string memory _reason, uint64 _releaseTime) /*onlyIssuerOrAbove*/ public virtual returns (bool);

  function totalIssued() public virtual view returns (uint);

  //*********************
  // TOKEN BURNING
  //*********************

  function burn(address _who, uint256 _value, string memory _reason) /*onlyIssuerOrAbove*/ public virtual;

  //*********************
  // TOKEN SIEZING
  //*********************

  function seize(address _from, address _to, uint256 _value, string memory _reason) /*onlyIssuerOrAbove*/ public virtual;

  //*********************
  // WALLET ENUMERATION
  //*********************

  function getWalletAt(uint256 _index) public view virtual returns (address);

  function walletCount() public view virtual returns (uint256);

  //**************************************
  // MISCELLANEOUS FUNCTIONS
  //**************************************
  function isPaused() view public virtual returns (bool);

  function balanceOfInvestor(string memory _id) view public virtual returns (uint256);

  function updateInvestorBalance(address _wallet, uint _value, bool _increase) internal virtual returns (bool);

  function preTransferCheck(address _from, address _to, uint _value) view public virtual returns (uint code, string memory reason);
}

contract AdminControl {

    address private adminAddr;
    bool public paused = false;
    mapping(address => bool) public approvedWorker;

    event AdminIsSet(address newAdmin);
    event WorkerIsApproved(address approvedWorker);
    event Paused();
    event Unpaused();

    constructor() {
        adminAddr = msg.sender;
        emit AdminIsSet(adminAddr);

        approvedWorker[adminAddr] = true;
        emit WorkerIsApproved(adminAddr);
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddr,
        "adminControl: access denied"
        );
        _;
    }

    modifier onlyWorker() {
        require(approvedWorker[msg.sender] == true,
        "adminControl: access denied"
        );
        _;
    }

    modifier whenPaused() {
        require(paused,
        "adminControl: MUST BE PAUSED"
        );
        _;
    }

    modifier whenNotPaused() {
        require(!paused,
        "adminControl: MUST BE UN-PAUSED"
        );
        _;
    }

    function approveWorker(address _newWorker) 
        public
        onlyAdmin
    {
        approvedWorker[_newWorker] = true;
    }

    function setNewAdmin(address _newAdmin)
        public
        onlyAdmin
    {
        adminAddr = _newAdmin;
        emit AdminIsSet(adminAddr);
    }

    function pause()
        external
        onlyWorker
        whenNotPaused
    {
        paused = true;
        emit Paused();
    }

    function unpause()
        external
        onlyWorker
        whenPaused
    {
        paused = false;
        emit Unpaused();
    }
}

contract SampleERC20 is DSTokenInterface, AdminControl, Context, IERC20, IERC20Metadata {
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_, string memory _id) {
        _name = name_;
        _symbol = symbol_;
        assignInvestorId("0", address(this));
        assignInvestorId(_id, msg.sender);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function destroyTokens(address _targetAddr, uint256 _amount)
        external
        //onlyWorker
    {
        _burn(_targetAddr, _amount);
    }


    function _mint(address account, uint256 amount) internal virtual returns(bool mintSucceeds){
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);

        mintSucceeds = true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /*
        *********************
        DS PROTOCOL IMPLEMENTATION
        *********************
    */

    mapping(address => string[]) customIssueReasonString;
    mapping(address => string[]) burnReasonString;
    mapping(address => string[]) seizeReasonString;

    mapping(string => address) placeholderInvestorId;

    struct CustomIssuance {
        uint256 _issuanceTime;
        uint256 _valueLocked;
        string _reason;
        uint64 _releaseTime;
    }

    mapping(address => CustomIssuance) customIssuanceDetails;

    function issueTokens(address _to, uint256 _value)
        public
        //onlyWorker
        override
        returns(bool mintSucceeds)
    {
        mintSucceeds = _mint(_to, _value);
    }

    function issueTokensCustom(address _to, uint256 _value, uint256 _issuanceTime, uint256 _valueLocked, string memory _reason, uint64 _releaseTime) 
        /*onlyIssuerOrAbove*/
        public
        override
        returns(bool mintSucceeds)
    {   
        //This is the same as issueTokens for testing purposes
        //We can overload _mint to support a custom issuance later on down the line
        mintSucceeds = _mint(_to, _value);
        customIssueReasonString[_to].push(_reason);

        //track custom issuance details
        CustomIssuance memory _customIssuanceDetails = CustomIssuance(
            _issuanceTime,
            _valueLocked,
            _reason,
            _releaseTime
        );
        customIssuanceDetails[_to] = _customIssuanceDetails;

        //increase balance
        updateInvestorBalance(_to,_value,true);
    }

    function setCap(uint256 _cap) 
        onlyWorker
        public
        override
    {
        _totalSupply = _cap;
    }

    function totalIssued()
        public
        view
        override
        returns(uint)
    {
        return _totalSupply;
    }

    function burn(address _who, uint256 _value, string memory _reason)
        /*onlyIssuerOrAbove*/
        public
        override
    {
        _burn(_who, _value);
        burnReasonString[_who].push(_reason);

        //decrease balance

        /*
            require(_balances[_who]>0,
                "NO BALANCE"
            );
            updateInvestorBalance(_who,_value,false);
        */
    }

    function seize(address _from, address _to, uint256 _value, string memory _reason) 
        /*onlyIssuerOrAbove*/
        public
        override
    {
        
        //This may require a DSLockManager Intgration..?
        
        _transfer(_from, address(this), _value);
        seizeReasonString[_from].push(_reason);

        //decrease balance
        /*
            require(_balances[_from]>0,
                "NO BALANCE"
            );
            updateInvestorBalance(_to,_value,false);
        */
    }

    function getWalletAt(uint256 _index) 
        public
        view
        override
        returns(address)
    {

        //This may require a DSWalletManager Intgration..?

        //placeholder impl
        return (address(0x0));
    }

    function walletCount()
        public
        view
        override
        returns(uint256)
    {
                
        //This may require a DSWalletManager Intgration..?

        //placeholder impl
        return (0);
    }

    function isPaused()
        view
        public
        override
        returns(bool)
    {
        return paused;
    }

    function balanceOfInvestor(string memory _id)
        view
        public
        override
        returns(uint256)
    {
                
        //This may require a DSIssuanceInformation Intgration..?
        
        return _balances[placeholderInvestorId[_id]];
    }

    function updateInvestorBalance(address _wallet, uint _value, bool _increase) 
        internal
        override
        returns(bool updateSuccessful)
    {
        if(_increase) {
            _balances[_wallet] += _value;
        } else {
            _balances[_wallet] -= _value;
        }
        
        updateSuccessful = true;
    }

    function preTransferCheck(address _from, address _to, uint _value)
        view
        public
        override
        returns(uint code, string memory reason)
    {
        return (0, "");
    }


    //SUPPORTER FUNCTIONS TO ENABLE PLACEHOLDER IMPL
    function assignInvestorId(string memory _id, address _investorWallet)
        public
    {
        require(placeholderInvestorId[_id] == address(0x0),
            "ID ALREADY IN USE"
        );
        placeholderInvestorId[_id] = _investorWallet;
    }

}