// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./JaxToken.sol";

contract JAXUD is JaxToken {

  constructor() JaxToken("Jax Dollar", "JAX DOLLAR", 18){}  
  
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./lib/BEP20.sol";
import "./JaxAdmin.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


interface IJaxPlanet {

  struct Colony {
    uint128 level;
    uint128 transaction_tax;
    bytes32 _policy_hash;
    string _policy_link;
  }

  function ubi_tax_wallet() external view returns (address);
  function ubi_tax() external view returns (uint);
  function jaxcorp_dao_wallet() external view returns (address);
  function getMotherColonyAddress(address) external view returns(address);
  function getColony(address addr) external view returns(Colony memory);
  function getUserColonyAddress(address user) external view returns(address);
}

interface IJaxAdmin {
  
  function userIsAdmin (address _user) external view returns (bool);

  function jaxSwap() external view returns (address);
  function jaxPlanet() external view returns (address);

  function system_status() external view returns (uint);

  function blacklist(address _user) external view returns (bool);
  function fee_freelist(address _user) external view returns (bool);
} 

/**
* @title JaxToken
* @dev Implementation of the JaxToken. Extension of {BEP20} that adds a fee transaction behaviour.
*/
contract JaxToken is BEP20 {
  
  IJaxAdmin public jaxAdmin;

  // transaction fee
  uint public transaction_fee = 0;
  uint public transaction_fee_cap = 0;

  // transaction fee wallet
  uint public referral_fee = 0;
  uint public referrer_amount_threshold = 0;
  uint public cashback = 0; // 8 decimals
  // transaction fee decimal 
  // uint public constant _fee_decimal = 8;

  struct Colony {
    uint128 level;
    uint128 transaction_tax;
    bytes32 _policy_hash;
    string _policy_link;
  }

  address public tx_fee_wallet;
  
  mapping (address => address) public referrers;

  event Set_Jax_Admin(address jax_admin);
  event Set_Transaction_Fee(uint transaction_fee, uint trasnaction_fee_cap, address transaction_fee_wallet);
  event Set_Referral_Fee(uint referral_fee, uint referral_amount_threshold);
  event Set_Cashback(uint cashback_percent);

  /**
    * @dev Sets the value of the `cap`. This value is immutable, it can only be
    * set once during construction.
    */
    
  constructor (
      string memory name,
      string memory symbol,
      uint8 decimals
  )
      BEP20(name, symbol)
  {
      _setupDecimals(decimals);
      tx_fee_wallet = msg.sender;
  }

  modifier onlyJaxAdmin() {
    require(msg.sender == address(jaxAdmin), "Only JaxAdmin Contract");
    _;
  }

  modifier onlyJaxSwap() {
  require(msg.sender == jaxAdmin.jaxSwap(), "Only JaxSwap can perform this operation.");
    _;
  }

  modifier notFrozen() {
    require(jaxAdmin.system_status() > 0, "Transactions have been frozen.");
    _;
  }

  function setJaxAdmin(address _jaxAdmin) external onlyOwner {
    jaxAdmin = IJaxAdmin(_jaxAdmin);  
    require(jaxAdmin.system_status() >= 0, "Invalid jax admin");
    emit Set_Jax_Admin(_jaxAdmin);
  }

  function setTransactionFee(uint tx_fee, uint tx_fee_cap, address wallet) external onlyJaxAdmin {
      require(tx_fee <= 1e8 * 3 / 100 , "Tx Fee percent can't be more than 3.");
      require(wallet != address(0x0), "Only non-zero address");
      transaction_fee = tx_fee;
      transaction_fee_cap = tx_fee_cap;
      tx_fee_wallet = wallet;
      emit Set_Transaction_Fee(tx_fee, tx_fee_cap, wallet);
  }

  /**
    * @dev Set referral fee and minimum amount that can set sender as referrer
    */
  function setReferralFee(uint _referral_fee, uint _referrer_amount_threshold) external onlyJaxAdmin {
      require(_referral_fee <= 1e8 * 50 / 100 , "Referral Fee percent can't be more than 50.");
      referral_fee = _referral_fee;
      referrer_amount_threshold = _referrer_amount_threshold;
      emit Set_Referral_Fee(_referral_fee, _referrer_amount_threshold);
  }

  /**
    * @dev Set cashback
    */
  function setCashback(uint cashback_percent) external onlyJaxAdmin {
      require(cashback_percent <= 1e8 * 30 / 100 , "Cashback percent can't be more than 30.");
      cashback = cashback_percent; // 8 decimals
      emit Set_Cashback(cashback_percent);
  }

  function transfer(address recipient, uint amount) public override(BEP20) notFrozen returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  } 

  function transferFrom(address sender, address recipient, uint amount) public override(BEP20) notFrozen returns (bool) {
    _transfer(sender, recipient, amount);
    uint currentAllowance = allowance(sender, msg.sender);
    require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
    _approve(sender, msg.sender, currentAllowance - amount);
    return true;
  } 

  function _transfer(address sender, address recipient, uint amount) internal override(BEP20) {
    require(!jaxAdmin.blacklist(sender), "sender is blacklisted");
    require(!jaxAdmin.blacklist(recipient), "recipient is blacklisted");
    if(amount == 0) return;
    if(jaxAdmin.fee_freelist(msg.sender) == true || jaxAdmin.fee_freelist(recipient) == true) {
        return super._transfer(sender, recipient, amount);
    }
    if(referrers[sender] == address(0)) {
        referrers[sender] = address(0xdEaD);
    }

    // Calculate transaction fee
    uint tx_fee_amount = amount * transaction_fee / 1e8;

    if(tx_fee_amount > transaction_fee_cap) {
        tx_fee_amount = transaction_fee_cap;
    }
    
    address referrer = referrers[recipient];
    uint totalreferral_fees = 0;
    uint maxreferral_fee = tx_fee_amount * referral_fee;

    IJaxPlanet jaxPlanet = IJaxPlanet(jaxAdmin.jaxPlanet());
    
    //Transfer of UBI Tax        
    uint ubi_tax_amount = amount * jaxPlanet.ubi_tax() / 1e8;

    address colony_address = jaxPlanet.getUserColonyAddress(recipient);

    if(colony_address == address(0)) {
        colony_address = jaxPlanet.getMotherColonyAddress(recipient);
    }
    
    // Transfer transaction tax to colonies.
    // immediate colony will get 50% of transaction tax, mother of that colony will get 25% ... mother of 4th colony will get 3.125%
    // 3.125% of transaction tax will go to JaxCorp Dao public key address.
    uint tx_tax_amount = amount * jaxPlanet.getColony(colony_address).transaction_tax / 1e8;     // Calculate transaction tax amount
   
    // Transfer tokens to recipient. recipient will pay the fees.
    require( amount > (tx_fee_amount + ubi_tax_amount + tx_tax_amount), "Total fee is greater than the transfer amount");
    super._transfer(sender, recipient, amount - tx_fee_amount - ubi_tax_amount - tx_tax_amount);

    // Transfer transaction fee to transaction fee wallet
    // Sender will get cashback.
    if( tx_fee_amount > 0){
        uint cashback_amount = (tx_fee_amount * cashback / 1e8);
        if(cashback_amount > 0)
          super._transfer(sender, sender, cashback_amount);
        
        // Transfer referral fees to referrers (70% to first referrer, each 10% to other referrers)
        if( maxreferral_fee > 0 && referrer != address(0xdEaD) && referrer != address(0)){

            super._transfer(sender, referrer, 70 * maxreferral_fee / 1e8 / 100);
            referrer = referrers[referrer];
            totalreferral_fees += 70 * maxreferral_fee / 1e8 / 100;
            if( referrer != address(0xdEaD) && referrer != address(0)){
                super._transfer(sender, referrer, 10 * maxreferral_fee / 1e8 / 100);
                referrer = referrers[referrer];
                totalreferral_fees += 10 * maxreferral_fee / 1e8 / 100;
                if( referrer != address(0xdEaD) && referrer != address(0)){
                    super._transfer(sender, referrer, 10 * maxreferral_fee / 1e8 / 100);
                    referrer = referrers[referrer];
                    totalreferral_fees += 10 * maxreferral_fee / 1e8 / 100;
                    if( referrer != address(0xdEaD) && referrer != address(0)){
                        super._transfer(sender, referrer, 10 * maxreferral_fee / 1e8 / 100);
                        referrer = referrers[referrer];
                        totalreferral_fees += 10 * maxreferral_fee / 1e8 / 100;
                    }
                }
            }
        }
        super._transfer(sender, tx_fee_wallet, tx_fee_amount - totalreferral_fees - cashback_amount); //1e8
    }
    
    if(ubi_tax_amount > 0){
        super._transfer(sender, jaxPlanet.ubi_tax_wallet(), ubi_tax_amount);  // ubi tax
    }
     
    // transferTransactionTax(mother_colony_addresses[recipient], tx_tax_amount, 1);          // Transfer tax to colonies and jaxCorp Dao
    // Optimize transferTransactionTax by using loop instead of recursive function

    if( tx_tax_amount > 0 ){
        uint level = 1;
        uint tx_tax_temp = tx_tax_amount;
        
        // Level is limited to 5
        while( colony_address != address(0) && level++ <= 5 ){
            super._transfer(sender, colony_address, tx_tax_temp / 2);
            colony_address = jaxPlanet.getMotherColonyAddress(colony_address);
            tx_tax_temp = tx_tax_temp / 2;            
        }

        // transfer remain tx_tax to jaxcorpDao
        super._transfer(sender, jaxPlanet.jaxcorp_dao_wallet(), tx_tax_temp);
    }


    // set referrers as first sender when transferred amount exceeds the certain limit.
    // recipient mustn't be sender's referrer, recipient couldn't be referrer itself
    if( recipient != sender  && amount >= referrer_amount_threshold  && referrers[recipient] == address(0)) {
        referrers[recipient] = sender;

    }
  }

  function mint(address account, uint amount) public notFrozen onlyJaxSwap {
      require(!jaxAdmin.blacklist(account), "account is blacklisted");
      _mint(account, amount);
  }

  function burnFrom(address account, uint amount) public override(BEP20) notFrozen onlyJaxSwap {
    require(!jaxAdmin.blacklist(account), "account is blacklisted");
    super.burnFrom(account, amount);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IBEP20.sol";

contract BEP20 is Ownable, IBEP20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

   constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

   function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

   function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

   function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

   function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
      uint256 currentAllowance = allowance(account, _msgSender());
      require(currentAllowance >= amount, "BEP20: burn amount exceeds allowance");
      _approve(account, _msgSender(), currentAllowance - amount);
      _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

   function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interface/IPancakeRouter.sol";
import "./interface/IERC20.sol";
import "./JaxOwnable.sol";
import "./JaxLibrary.sol";
import "./JaxProtection.sol";

interface IJaxSwap {
  function setTokenAddresses(address _busd, address _wjxn, address _wjax, address _vrp, address _jusd) external;
}

interface IJaxToken {
  function setTransactionFee(uint tx_fee, uint tx_fee_cap, address wallet) external;
  function setReferralFee(uint _referral_fee, uint _referrer_amount_threshold) external;
  function setCashback(uint cashback_percent) external;
}

contract JaxAdmin is Initializable, JaxOwnable, JaxProtection {

  using JaxLibrary for JaxAdmin;

  address public admin;
  address public new_admin;
  uint public new_admin_locktime;

  address public ajaxPrime;
  address public new_ajaxPrime;
  uint public new_ajaxPrime_locktime;

  address public newGovernor;
  address public governor;
  address public new_governor_by_ajaxprime;

  address public jaxSwap;
  address public jaxPlanet;

  uint governorStartDate;

  uint public system_status;

  string public readme_hash;
  string public readme_link;
  string public system_policy_hash;
  string public system_policy_link;
  string public governor_policy_hash;
  string public governor_policy_link;

  event Set_Blacklist(address[] accounts, bool flag);
  event Set_Fee_Freelist(address[] accounts, bool flag);

  mapping (address => bool) public blacklist;
  mapping (address => bool) public fee_freelist;

  uint public priceImpactLimit;

  // ------ JaxSwap Control Parameters -------
  IPancakeRouter01 public router;

  IERC20 public wjxn;
  IERC20 public busd;
  IERC20 public wjax;
  IERC20 public vrp; 
  IERC20 public jusd;

  uint public wjax_usd_ratio;
  uint public use_wjax_usd_dex_pair;

  uint public wjxn_usd_ratio;
  uint public use_wjxn_usd_dex_pair;

  uint public wjax_jusd_markup_fee;    
  address public wjax_jusd_markup_fee_wallet;

  uint public wjxn_wjax_collateralization_ratio;
  uint public wjax_collateralization_ratio;
  uint public freeze_vrp_wjxn_swap;
  
  struct JToken{
    uint jusd_ratio;
    uint markup_fee;
    address markup_fee_wallet;
    string name;
  }

  mapping (address => JToken) public jtokens;
  address[] public jtoken_addresses;

  address[] public operators;

  mapping(address => bytes4[]) function_call_whitelist;
  mapping(uint => uint) last_call_timestamps;


  event Set_Admin(address newAdmin, uint newAdminLocktime);
  event Update_Admin(address newAdmin);
  event Set_AjaxPrime(address ajaxPrime, uint newAjaxPrimeLocktime);
  event Update_AjaxPrime(address newAjaxPrime);
  event Set_Governor(address governor);
  event Accept_Governor(address governor);
  event Set_Operators(address[] operator);
  event Set_Jax_Swap(address jaxSwap);
  event Set_Jax_Planet(address jaxPlanet);
  event Elect_Governor(address governor);
  event Update_Governor(address old_governor, address new_governor_by_ajaxprime);
  event Set_System_Status(uint flag);
  event Set_System_Policy(string policy_hash, string policy_link);
  event Set_Readme(string readme_hash, string readme_link);
  event Set_Governor_Policy(string governor_policy_hash, string governor_policy_link);

  event Set_Price_Impact_Limit(uint limit);
  event Set_Token_Addresses(address busd, address wjxn, address wjax, address vrp, address jusd);
  event Add_JToken(address token, string name, uint jusd_ratio, uint markup_fee, address markup_fee_wallet);
  event Freeze_Vrp_Wjxn_Swap(uint flag);
  event Set_Wjxn_Wjax_Collateralization_Ratio(uint wjxn_wjax_collateralization_ratio);
  event Set_Wjax_Collateralization_Ratio(uint wjax_collateralization_ratio);
  event Set_Wjxn_Usd_Ratio(uint ratio);
  event Set_Wjax_Usd_Ratio(uint ratio);
  event Set_Use_Wjxn_Usd_Dex_Pair(uint flag);
  event Set_Use_Wjax_Usd_Dex_Pair(uint flag);
  event Set_Wjax_Jusd_Markup_Fee(uint wjax_jusd_markup_fee, address wallet);
  event Set_Jusd_Jtoken_Ratio(address jtoken, uint old_ratio, uint new_ratio);
  event Set_Whitelist_For_Operator(address operator, bytes4[] functions);
  event Delete_JToken(address jtoken);

  modifier checkZeroAddress(address account) {
    require(account != address(0x0), "Only non-zero address");
    _;
  }

  function userIsAdmin (address _user) public view returns (bool) {
    return admin == _user;
  }

  function userIsGovernor (address _user) public view returns (bool) {
    return governor == _user;
  }

  function userIsAjaxPrime (address _user) public view returns (bool) {
    return ajaxPrime == _user;
  }

  function userIsOperator (address _user) public view returns (bool) {
    uint index = 0;
    uint j = 0;
    uint operatorCnt = operators.length;
    bytes4[] memory functions_whitelisted;
    for(index; index < operatorCnt; index += 1) {
      if(operators[index] == _user){
        functions_whitelisted = function_call_whitelist[_user];
        for(j = 0; j < functions_whitelisted.length; j+=1) {
          if(functions_whitelisted[j] == msg.sig)
            return true;
        }
        return false;
      }
    }
    return false;
  }

  modifier onlyAdmin() {
    require(userIsAdmin(msg.sender) || msg.sender == owner, "Only Admin can perform this operation");
    _;
  }

  modifier onlyGovernor() {
    require(userIsGovernor(msg.sender), "Only Governor can perform this operation");
    _;
  }

  modifier onlyAjaxPrime() {
    require(userIsAjaxPrime(msg.sender) || msg.sender == owner, "Only AjaxPrime can perform this operation");
    _;
  }

  modifier onlyOperator() {
    require(userIsOperator(msg.sender) || userIsGovernor(msg.sender), "Only operators can perform this operation");
    _;
  }

  modifier callLimit(uint key, uint period) {
    require(last_call_timestamps[key] + period <= block.timestamp, "Not cool down yet");
    _;
    last_call_timestamps[key] = block.timestamp;
  }

  function setSystemStatus(uint status) external onlyGovernor {
    system_status = status;
    emit Set_System_Status(status);
  }

  function setAdmin (address _admin ) external onlyAdmin {
    if(_admin == address(0x0)){
      admin = _admin;
      new_admin = address(0x0);
      emit Update_Admin(_admin);
      return;
    }
    else {
      new_admin = _admin;
      new_admin_locktime = block.timestamp + 2 days;
    }
    emit Set_Admin(_admin, new_admin_locktime);
  }

  function updateAdmin () external {
    require(msg.sender == new_admin, "Only new admin");
    require(block.timestamp >= new_admin_locktime, "New admin is not unlocked yet");
    admin = new_admin;
    new_admin = address(0x0);
    emit Update_Admin(admin);
  }

  function setGovernor (address _governor) external checkZeroAddress(_governor) onlyAjaxPrime runProtection {
    new_governor_by_ajaxprime = _governor;
    emit Set_Governor(_governor);
  }

  function acceptGovernorship () external {
    require(msg.sender == new_governor_by_ajaxprime, "Only new governor");
    governor = new_governor_by_ajaxprime;
    new_governor_by_ajaxprime = address(0x0);
    emit Accept_Governor(governor);
  }

  function setOperators (address[] calldata _operators) external onlyGovernor {
    uint operatorsCnt = _operators.length;
    delete operators;
    for(uint index = 0; index < operatorsCnt; index += 1 ) {
      operators.push(_operators[index]);
    }
    emit Set_Operators(_operators);
  }

  function setWhitelistForOperator(address operator, bytes4[] calldata functions) external onlyGovernor {
    bytes4[] storage whitelist = function_call_whitelist[operator];
    uint length = whitelist.length;
    uint i = 0;
    for(; i < length; i+=1 ) {
      whitelist.pop();
    }
    for(i = 0; i < functions.length; i+=1) {
      whitelist.push(functions[i]);
    }
    emit Set_Whitelist_For_Operator(operator, functions);
  }

  function electGovernor (address _governor) external {
    require(msg.sender == address(vrp), "Only VRP contract can perform this operation.");
    newGovernor = _governor;
    governorStartDate = block.timestamp + 7 days;
    emit Elect_Governor(_governor);
  }

  function setAjaxPrime (address _ajaxPrime) external onlyAjaxPrime {
    if(_ajaxPrime == address(0x0)) {
      ajaxPrime = _ajaxPrime;
      new_ajaxPrime = address(0x0);
      emit Update_AjaxPrime(_ajaxPrime);
      return;
    }
    new_ajaxPrime = _ajaxPrime;
    new_ajaxPrime_locktime = block.timestamp + 2 days;
    emit Set_AjaxPrime(_ajaxPrime, new_ajaxPrime_locktime);
  }

  function updateAjaxPrime () external {
    require(msg.sender == new_ajaxPrime, "Only new ajax prime");
    require(block.timestamp >= new_ajaxPrime_locktime, "New ajax prime is not unlocked yet");
    ajaxPrime = new_ajaxPrime;
    new_ajaxPrime = address(0x0);
    emit Update_AjaxPrime(ajaxPrime);
  }

  function updateGovernor () external {
    require(newGovernor != governor && newGovernor != address(0x0), "New governor hasn't been elected");
    require(governorStartDate <= block.timestamp, "New governor is not ready");
    require(msg.sender == newGovernor, "You are not nominated as potential governor");
    address old_governor = governor;
    governor = newGovernor;
    newGovernor = address(0x0);
    emit Update_Governor(old_governor, newGovernor);
  }

  function set_system_policy(string memory _policy_hash, string memory _policy_link) public onlyAdmin runProtection {
    system_policy_hash = _policy_hash;
    system_policy_link = _policy_link;
    emit Set_System_Policy(_policy_hash, _policy_link);
  }

  function set_readme(string memory _readme_hash, string memory _readme_link) external onlyGovernor {
    readme_hash = _readme_hash;
    readme_link = _readme_link;
    emit Set_Readme(_readme_hash, _readme_link);
  }
  
  function set_governor_policy(string memory _hash, string memory _link) external onlyGovernor {
    governor_policy_hash = _hash;
    governor_policy_link = _link;
    emit Set_Governor_Policy(_hash, _link);
  }


  function set_fee_freelist(address[] calldata accounts, bool flag) external onlyAjaxPrime runProtection {
      uint length = accounts.length;
      for(uint i = 0; i < length; i++) {
          fee_freelist[accounts[i]] = flag;
      }
    emit Set_Fee_Freelist(accounts, flag);
  }

  function set_blacklist(address[] calldata accounts, bool flag) external onlyGovernor {
    uint length = accounts.length;
    for(uint i = 0; i < length; i++) {
      blacklist[accounts[i]] = flag;
    }
    emit Set_Blacklist(accounts, flag);
  }

  function setTransactionFee(address token, uint tx_fee, uint tx_fee_cap, address wallet) external onlyGovernor {
      IJaxToken(token).setTransactionFee(tx_fee, tx_fee_cap, wallet);
  }

  function setReferralFee(address token, uint _referral_fee, uint _referrer_amount_threshold) public onlyGovernor {
      IJaxToken(token).setReferralFee(_referral_fee, _referrer_amount_threshold);
  }

  function setCashback(address token, uint cashback_percent) public onlyGovernor {
      IJaxToken(token).setCashback(cashback_percent);
  }

  // ------ jaxSwap -----
  function setJaxSwap(address _jaxSwap) public checkZeroAddress(_jaxSwap) onlyAdmin runProtection {
    jaxSwap = _jaxSwap;
    emit Set_Jax_Swap(_jaxSwap);
  }

  // ------ jaxPlanet -----
  function setJaxPlanet(address _jaxPlanet) public checkZeroAddress(_jaxPlanet) onlyAdmin runProtection {
    jaxPlanet = _jaxPlanet;
    emit Set_Jax_Planet(_jaxPlanet);
  }

  function setTokenAddresses(address _busd, address _wjxn, address _wjax, address _vrp, address _jusd) public onlyAdmin 
     checkZeroAddress(_busd) checkZeroAddress(_wjxn) checkZeroAddress(_wjax) checkZeroAddress(_vrp) checkZeroAddress(_jusd)
     runProtection
  {
    busd = IERC20(_busd);
    wjxn = IERC20(_wjxn);
    wjax = IERC20(_wjax);
    vrp = IERC20(_vrp);
    jusd = IERC20(_jusd);
    IJaxSwap(jaxSwap).setTokenAddresses(_busd, _wjxn, _wjax, _vrp, _jusd);
    emit Set_Token_Addresses(_busd, _wjxn, _wjax, _vrp, _jusd);
  }

  function add_jtoken(address token, string calldata name, uint jusd_ratio, uint markup_fee, address markup_fee_wallet) external onlyAjaxPrime runProtection {
    require(markup_fee <= 25 * 1e5, "markup fee cannot over 2.5%");
    require(jusd_ratio > 0, "JUSD-JToken ratio should not be zero");

    JToken storage newtoken = jtokens[token];
    require(newtoken.jusd_ratio == 0, "Already added");
    jtoken_addresses.push(token);

    newtoken.name = name;
    newtoken.jusd_ratio = jusd_ratio;
    newtoken.markup_fee = markup_fee;
    newtoken.markup_fee_wallet = markup_fee_wallet;
    emit Add_JToken(token, name, jusd_ratio, markup_fee, markup_fee_wallet);
  }

  function delete_jtoken(address token) external onlyAjaxPrime runProtection {
    JToken storage jtoken = jtokens[token];
    jtoken.jusd_ratio = 0;
    uint jtoken_index = 0;
    uint jtoken_count = jtoken_addresses.length;
    for(jtoken_index; jtoken_index < jtoken_count; jtoken_index += 1){
      if(jtoken_addresses[jtoken_index] == token)
      {
        if(jtoken_count > 1)
          jtoken_addresses[jtoken_index] = jtoken_addresses[jtoken_count-1];
        jtoken_addresses.pop();
        break;
      }
    }
    require(jtoken_index != jtoken_count, "Invalid JToken Address");
    emit Delete_JToken(token);
  }

  function check_price_bound(uint oldPrice, uint newPrice, uint percent) internal pure returns(bool) {
    return newPrice <= oldPrice * (100 + percent) / 100 
           && newPrice >= oldPrice * (100 - percent) / 100;
  }

  function set_jusd_jtoken_ratio(address token, uint jusd_ratio) external onlyOperator callLimit(uint(uint160(token)), 1 hours) {
    JToken storage jtoken = jtokens[token];
    uint old_ratio = jtoken.jusd_ratio;
    require(check_price_bound(old_ratio, jusd_ratio, 3), "Out of 3% ratio change");
    jtoken.jusd_ratio = jusd_ratio;
    emit Set_Jusd_Jtoken_Ratio(token, old_ratio, jusd_ratio);
  }

  function set_use_wjxn_usd_dex_pair(uint flag) external onlyGovernor {
    use_wjxn_usd_dex_pair = flag;
    emit Set_Use_Wjxn_Usd_Dex_Pair(flag);
  }

  function set_use_wjax_usd_dex_pair(uint flag) external onlyGovernor {
    use_wjax_usd_dex_pair = flag;
    emit Set_Use_Wjax_Usd_Dex_Pair(flag);
  }

  function set_wjxn_usd_ratio(uint ratio) external onlyOperator callLimit(0x1, 1 hours){
    require(wjxn_usd_ratio == 0 || check_price_bound(wjxn_usd_ratio, ratio, 10),
        "Out of 10% ratio change");
    wjxn_usd_ratio = ratio;
    emit Set_Wjxn_Usd_Ratio(ratio);
  }

  function set_wjax_usd_ratio(uint ratio) external onlyOperator callLimit(0x2, 1 hours) {
    require(wjax_usd_ratio == 0 || check_price_bound(wjax_usd_ratio, ratio, 5), 
      "Out of 5% ratio change");
    wjax_usd_ratio = ratio;
    emit Set_Wjax_Usd_Ratio(ratio);
  }

  function get_wjxn_wjax_ratio(uint withdrawal_amount) public view returns (uint) {
    if( wjax.balanceOf(jaxSwap) == 0 ) return 1e8;
    if( wjxn.balanceOf(jaxSwap) == 0 ) return 0;
    return 1e8 * ((10 ** wjax.decimals()) * (wjxn.balanceOf(jaxSwap) - withdrawal_amount) 
        * get_wjxn_usd_ratio()) / (wjax.balanceOf(jaxSwap) * get_wjax_usd_ratio() * (10 ** wjxn.decimals()));
  }
  
  function get_wjxn_usd_ratio() public view returns (uint){
    
    // Using manual ratio.
    if( use_wjxn_usd_dex_pair == 0 ) {
      return wjxn_usd_ratio;
    }

    return getPrice(address(wjxn), address(busd)); // return amount of token0 needed to buy token1
  }

  function get_wjxn_vrp_ratio() public view returns (uint wjxn_vrp_ratio) {
    if( vrp.totalSupply() == 0){
      wjxn_vrp_ratio = 1e8;
    }
    else if(wjxn.balanceOf(jaxSwap) == 0) {
      wjxn_vrp_ratio = 0;
    }
    else {
      wjxn_vrp_ratio = 1e8 * vrp.totalSupply() * (10 ** wjxn.decimals()) / wjxn.balanceOf(jaxSwap) / (10 ** vrp.decimals());
    }
  }
  
  function get_vrp_wjxn_ratio() public view returns (uint) {
    uint vrp_wjxn_ratio = 0;
    if(wjxn.balanceOf(jaxSwap) == 0 || vrp.totalSupply() == 0) {
        vrp_wjxn_ratio = 0;
    }
    else {
        vrp_wjxn_ratio = 1e8 * wjxn.balanceOf(jaxSwap) * (10 ** vrp.decimals()) / vrp.totalSupply() / (10 ** wjxn.decimals());
    }
    return (vrp_wjxn_ratio);
  }

  function get_wjax_usd_ratio() public view returns (uint){
    // Using manual ratio.
    if( use_wjax_usd_dex_pair == 0 ) {
        return wjax_usd_ratio;
    }

    return getPrice(address(wjax), address(busd));
  }

  function get_usd_wjax_ratio() public view returns (uint){
    return 1e8 * 1e8 / get_wjax_usd_ratio();
  }

  function set_freeze_vrp_wjxn_swap(uint flag) external onlyGovernor {
    freeze_vrp_wjxn_swap = flag;
    emit Freeze_Vrp_Wjxn_Swap(flag);
  }

  function set_wjxn_wjax_collateralization_ratio(uint ratio) external onlyGovernor {
    require(ratio >= 1e7 && ratio <= 2e8, "Ratio must be 10% - 200%");
    wjxn_wjax_collateralization_ratio = ratio;
    emit Set_Wjxn_Wjax_Collateralization_Ratio(ratio);
  }

  function set_wjax_collateralization_ratio(uint ratio) external onlyGovernor {
    require(ratio >= 5e7 && ratio <= 1e8, "Ratio must be 50% - 100%");
    wjax_collateralization_ratio = ratio;
    emit Set_Wjax_Collateralization_Ratio(ratio);
  }

  function set_wjax_jusd_markup_fee(uint _wjax_jusd_markup_fee, address _wallet) external checkZeroAddress(_wallet) onlyGovernor {
    require(_wjax_jusd_markup_fee <= 25 * 1e5, "Markup fee must be less than 2.5%");
    wjax_jusd_markup_fee = _wjax_jusd_markup_fee;
    wjax_jusd_markup_fee_wallet = _wallet;
    emit Set_Wjax_Jusd_Markup_Fee(_wjax_jusd_markup_fee, _wallet);
  }

  function setPriceImpactLimit(uint limit) external onlyGovernor {
    require(limit <= 3e6, "price impact cannot be over 3%");
    priceImpactLimit = limit;
    emit Set_Price_Impact_Limit(limit);
  }

  // wjax_usd_value: decimal 8, lsc_usd_value decimal: 18
  function show_reserves() public view returns(uint, uint, uint){
    uint wjax_reserves = wjax.balanceOf(jaxSwap);

    uint wjax_usd_value = wjax_reserves * get_wjax_usd_ratio() * (10 ** jusd.decimals()) / 1e8 / (10 ** wjax.decimals());
    uint lsc_usd_value = jusd.totalSupply();

    uint jtoken_count = jtoken_addresses.length;
    for(uint i = 0; i < jtoken_count; i++) {
      address addr = jtoken_addresses[i];
      lsc_usd_value += IERC20(addr).totalSupply() * 1e8 / jtokens[addr].jusd_ratio;
    }
    uint wjax_lsc_ratio = 1;
    if( lsc_usd_value > 0 ){
      wjax_lsc_ratio = wjax_usd_value * 1e8 / lsc_usd_value;
    }
    return (wjax_lsc_ratio, wjax_usd_value, lsc_usd_value);
  }
  // ------ end jaxSwap ------

  function getPrice(address token0, address token1) internal view returns(uint) {
    IPancakePair pair = IPancakePair(IPancakeFactory(router.factory()).getPair(token0, token1));
    (uint res0, uint res1,) = pair.getReserves();
    res0 *= 10 ** (18 - IERC20(pair.token0()).decimals());
    res1 *= 10 ** (18 - IERC20(pair.token1()).decimals());
    if(pair.token0() == token1) {
        if(res1 > 0)
            return 1e8 * res0 / res1;
    } 
    else {
        if(res0 > 0)
            return 1e8 * res1 / res0;
    }
    return 0;
  }
  
  function initialize(address pancakeRouter) public initializer {
    admin = msg.sender;
    governor = msg.sender;
    ajaxPrime = msg.sender;
    // System state
    system_status = 2;
    owner = msg.sender;
    router = IPancakeRouter01(pancakeRouter);
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @dev Interface of the BEP standard.
 */
interface IBEP20 {

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}


interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeRouter01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @dev Interface of the BEP standard.
 */
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getOwner() external view returns (address);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract JaxOwnable {

  address public owner;
  address public new_owner;
  uint public new_owner_locktime;
  
  event Set_New_Owner(address newOwner, uint newOwnerLocktime);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
      require(owner == msg.sender, "JaxOwnable: caller is not the owner");
      _;
  }

  function setNewOwner(address newOwner) external onlyOwner {
    require(newOwner != address(0x0), "New owner cannot be zero address");
    new_owner = newOwner;
    new_owner_locktime = block.timestamp + 2 days;
    emit Set_New_Owner(newOwner, new_owner_locktime);
  }

  function updateOwner() external {
    require(msg.sender == new_owner, "Only new owner");
    require(block.timestamp >= new_owner_locktime, "New admin is not unlocked yet");
    _transferOwnership(new_owner);
    new_owner = address(0x0);
  }

  function renounceOwnership() external onlyOwner {
    _transferOwnership(address(0));
  }

  /**
  * @dev Transfers ownership of the contract to a new account (`newOwner`).
  * Internal function without access restriction.
  */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.11;

import "./interface/IPancakeRouter.sol";

library JaxLibrary {

  function swapWithPriceImpactLimit(address router, uint amountIn, uint limit, address[] memory path, address to) internal returns(uint[] memory) {
    IPancakeRouter01 pancakeRouter = IPancakeRouter01(router);
    
    IPancakePair pair = IPancakePair(IPancakeFactory(pancakeRouter.factory()).getPair(path[0], path[1]));
    (uint res0, uint res1, ) = pair.getReserves();
    uint reserveIn;
    uint reserveOut;
    if(pair.token0() == path[0]) {
      reserveIn = res0;
      reserveOut = res1;
    } else {
      reserveIn = res1;
      reserveOut = res0;
    }
    uint amountOut = pancakeRouter.getAmountOut(amountIn, reserveIn, reserveOut);
    require(reserveOut * 1e36 * (1e8 - limit) / 1e8 / reserveIn <= amountOut * 1e36 / amountIn, "Price Impact too high");
    return pancakeRouter.swapExactTokensForTokens(amountIn, 0, path, to, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract JaxProtection {

    struct RunProtection {
        bytes32 data_hash;
        uint64 request_timestamp;
        address sender;
        bool executed;
    }

    mapping(bytes4 => RunProtection) run_protection_info;

    event Request_Update(bytes4 sig, bytes data);

    modifier runProtection() {
        RunProtection storage protection = run_protection_info[msg.sig];
        bytes32 data_hash = keccak256(msg.data);
        if(data_hash != protection.data_hash || protection.sender != msg.sender) {
        protection.sender = msg.sender;
        protection.data_hash = keccak256(msg.data);
            protection.request_timestamp = uint64(block.timestamp);
            protection.executed = false;
            emit Request_Update(msg.sig, msg.data);
            return;
        }
        require(protection.executed == false, "Already executed");
        require(block.timestamp >= uint(protection.request_timestamp) + 2 days, "Running is Locked");
        _;
        protection.executed = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}