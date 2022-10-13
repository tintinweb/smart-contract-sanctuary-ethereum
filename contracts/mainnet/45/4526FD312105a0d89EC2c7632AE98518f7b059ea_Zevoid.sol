/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: MIT

/**
ZVOID Team

Website: https://www.zevoid.io/
Telegram: https://t.me/ZeVoidPortal
Twitter: https://twitter.com/ZeVoidOfficial


Dr_0x1
Head of development
*/



pragma solidity >=0.4.22 <0.9.0;



interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// implementation: https://etherscan.io/address/0x48d118c9185e4dbafe7f3813f8f29ec8a6248359#code
// proxy: https://etherscan.io/address/0x48d118c9185e4dbafe7f3813f8f29ec8a6248359#code
interface ItrustSwap {
    function lockToken(
        address _tokenAddress,
        address _withdrawalAddress,
        uint256 _amount,
        uint256 _unlockTime,
        bool _mintNFT
    )external payable returns (uint256 _id);

    function transferLocks(uint256 _id, address _receiverAddress) external;
    function addTokenToFreeList(address token) external;
    function extendLockDuration(uint256 _id, uint256 _unlockTime) external;
    function getFeesInETH(address _tokenAddress) external view returns (uint256);
    function withdrawTokens(uint256 _id, uint256 _amount) external;

    function getDepositDetails(uint256 _id)view external returns (
        address _tokenAddress, 
        address _withdrawalAddress, 
        uint256 _tokenAmount, 
        uint256 _unlockTime, 
        bool _withdrawn, 
        uint256 _tokenId,
        bool _isNFT,
        uint256 _migratedLockDepositId,
        bool _isNFTMinted);
}

interface IPair {
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);    
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ); 

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        decimals = 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {}

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }


}



contract Zevoid is ERC20 {

  struct Taxes { 
    uint256 lp_tax;
    uint256 devMarketing_tax; 
    uint256 ETH_gasfee_tax; 
    uint256 team_tax; 
    uint256 total; 
    //ecosystem 
    uint256 early_sell_tax; 
    uint256 deadblock_tax; 
    uint256 blacklist_tax; 
  }
  struct EarlyBuySellTracker {
    uint256 buy_blockNumber;
    uint256 sell_blockNumber;
  }

  mapping(address => EarlyBuySellTracker) first_actions_map;
  uint256 ebst_treshold = 60*60*24; //24h
  mapping(address => uint256) private team_members;
  
  struct Shares{
    uint256 share_team;
    uint256 share_developmentMarketing;
    uint256 share_Fees;
    uint256 share_LP;
  }
  Shares private shareObj;

  address[] private team_member_list;  
  address[] whitelist; 
  address[] blacklist; 
  address[] holders;

  uint256 private end_blockNr = 0;
  uint256 _unlockTime_in_UTC = 210 days; //7months
  uint256 public unlockTime_in_UTC_local;
  bool public trading_enabled = false;

  uint256 public lp_eth_balance;
  
  Taxes public buy_taxes = Taxes({
    lp_tax: 250, 
    devMarketing_tax: 240, 
    ETH_gasfee_tax: 10, 
    team_tax: 200, 
    total: (250 + 240 + 10 + 200),
    //
    early_sell_tax: 0, 
    deadblock_tax: 7300, 
    blacklist_tax: 7000 
  });

  Taxes public sell_taxes = Taxes({
    lp_tax: 250,
    devMarketing_tax: 240,
    ETH_gasfee_tax: 10,
    team_tax: 200,
    total: (250 + 240 + 10 + 200),
    //
    early_sell_tax: 1200, 
    deadblock_tax: 700, 
    blacklist_tax: 7000
  });


uint256 totalTokenAmount = 7 * (10 ** 6) * (10 ** 18);
uint256 initialSupply;
uint256 BASISPOINT = 10000;

uint256 public _maxWallet = (totalTokenAmount / 100); // 1%
uint256 public _maxTx = (totalTokenAmount * 50) / BASISPOINT; //0.5%

IRouter uniswapV2Router;
IPair public uniswapV2Pair;
ItrustSwap externLocker;
uint256[] locks_ids;
address public owner;
address public zeOracle_address;
address private developmentMarketing_address; 


constructor(
  address owner_0,
  address router_v2_address, 
  address externLocker_address,
  address developmentMarketing_address_,
  address zeOracle_address_ 
  ) 
  ERC20("ZeVoid", "ZVOID") 
  {
    //owner: multisig  
    owner = owner_0;
    
    initialSupply = ((totalTokenAmount * 80) / 100);
    
    _mint(address(this), initialSupply); //80%
    _mint(owner, (totalTokenAmount - initialSupply)); //20% for CEX

    zeOracle_address = zeOracle_address_;
    developmentMarketing_address = developmentMarketing_address_;

    uniswapV2Router = IRouter(router_v2_address); 
    address _pair = IFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

    uniswapV2Pair = IPair(_pair);
    externLocker = ItrustSwap(externLocker_address);
        
    whitelist.push(address(this));
    whitelist.push(owner);
    whitelist.push(zeOracle_address);
    //
    whitelist.push(router_v2_address);
    whitelist.push(_pair);
    whitelist.push(externLocker_address);


    //team members
    //
    team_member_list.push(0x13D47263B1B770AbD441AEAb67e5e00EDA11B1C5);    
    team_members[0x13D47263B1B770AbD441AEAb67e5e00EDA11B1C5] = 2000; 
    //
    team_member_list.push(0xA795a19fB3797466517FDC7804fdB9E87DAeDfd4);    
    team_members[0xA795a19fB3797466517FDC7804fdB9E87DAeDfd4] = 2000; 
    //
    team_member_list.push(0x11F184dFA987973933A5150531e5BeA2882b0687);    
    team_members[0x11F184dFA987973933A5150531e5BeA2882b0687] = 2000; 
    //
    team_member_list.push(0x9A22519df3fac8b3829f8F3150ae2D6C3A6b809D);    
    team_members[0x9A22519df3fac8b3829f8F3150ae2D6C3A6b809D] = 2000; 
    //
    team_member_list.push(0xDeE2DE3F2532791B5F58c5Ff0EE834586930cf99);    
    team_members[0xDeE2DE3F2532791B5F58c5Ff0EE834586930cf99] = 2000; 
    //


    //
    shareObj = Shares({
        share_team: 3000,
        share_developmentMarketing: 3400,
        share_Fees: 100,
        share_LP: 3500
    });
}



function plock(uint256 ethAmount) payable external onlyOwner {

  if((msg.value <= externLocker.getFeesInETH(address(uniswapV2Pair))))revert('Not enough liql!');

  (bool sent,) = payable(address(this)).call{value: ethAmount}("");
  if(sent == true){

    if(initialSupply > 0 && ethAmount > 0){
      addLiquidity(address(this), initialSupply, ethAmount);
      lock_LP_Tokens();
    }
  }else{
    revert('sending ETH in plock: fail');
  }
}

modifier onlyOwner(){
  require(owner == msg.sender, 'Only Owner!');
  _;
}

modifier onlyOwnerZeOracle(){
  require(zeOracle_address == msg.sender || owner == msg.sender, 'Only owner or zeOracle!');
  _;
}

modifier tradingAutoDisabled(){
  bool before_trading_enabled = trading_enabled; 
  trading_enabled = false;
  _;
  trading_enabled = before_trading_enabled;
}


function set_deadblock_tax(uint256 new_deadblock_buy_tax, uint256 new_deadblock_sell_tax) onlyOwner external{
  buy_taxes.deadblock_tax = new_deadblock_buy_tax;
  sell_taxes.deadblock_tax = new_deadblock_sell_tax;
}


function set_unlockTime_in_UTC(uint256 new_unlockTime_in_UTC) onlyOwner external{
  _unlockTime_in_UTC = new_unlockTime_in_UTC;
}

function set_early_sell_tax(uint256 new_early_sell_tax) onlyOwner external{
  sell_taxes.early_sell_tax = new_early_sell_tax;
}


function set_blacklist_tax(uint256 new_blacklist_buy_tax, uint256 new_blacklist_sell_tax) onlyOwner external{
  buy_taxes.blacklist_tax = new_blacklist_buy_tax;
  sell_taxes.blacklist_tax = new_blacklist_sell_tax;
}


function set_buy_taxes(
  uint256 new_lp_tax, 
  uint256 new_devMarketing_tax,
  uint256 new_ETH_gasfee_tax,
  uint256 new_team_tax
  ) onlyOwner external{
  buy_taxes.lp_tax = new_lp_tax;
  buy_taxes.devMarketing_tax = new_devMarketing_tax;
  buy_taxes.ETH_gasfee_tax = new_ETH_gasfee_tax;
  buy_taxes.team_tax = new_team_tax;
  buy_taxes.total = buy_taxes.lp_tax + buy_taxes.devMarketing_tax + buy_taxes.ETH_gasfee_tax + buy_taxes.team_tax;
}


function set_sell_taxes(  
  uint256 new_lp_tax, 
  uint256 new_devMarketing_tax,
  uint256 new_ETH_gasfee_tax,
  uint256 new_team_tax
) onlyOwner external{
  sell_taxes.lp_tax = new_lp_tax;
  sell_taxes.devMarketing_tax = new_devMarketing_tax;
  sell_taxes.ETH_gasfee_tax = new_ETH_gasfee_tax;
  sell_taxes.team_tax = new_team_tax;
  sell_taxes.total = sell_taxes.lp_tax + sell_taxes.devMarketing_tax + sell_taxes.ETH_gasfee_tax + sell_taxes.team_tax;
}





function set_owner(address new_owner) onlyOwner external{
  add_whitelist(new_owner);
  owner = new_owner;
}

function set_zeOracle_address(address new_zeOracle_address) onlyOwner external{
  zeOracle_address = new_zeOracle_address;
}


function set_maxTx_maxWallet(uint256 new_maxWallet_in_ZVOID, uint256 new__maxTx_in_ZVOID) onlyOwner external{  
  _maxWallet = new_maxWallet_in_ZVOID; 
  _maxTx = new__maxTx_in_ZVOID; 
}


function set_ebst_treshold(uint256 new_ebst_treshold) onlyOwner external{
  ebst_treshold = new_ebst_treshold;
}

function set_trading_enabled(bool new_trading_enabled, uint256 nBlock) onlyOwner external{
  trading_enabled = new_trading_enabled;
  if(end_blockNr == 0) end_blockNr = (block.number + nBlock); 
}

function is_team_member(address team_member) public view returns(bool, uint256) {
    for(uint256 i=0; i < team_member_list.length; i++){
        if(team_member_list[i] == team_member){
            return (true, i);
        }
    }
    return (false, 0);
}

function team_shares_correct() view private returns(bool) {
    uint256 total_shares = 0;
    for(uint256 i=0; i < team_member_list.length; i++){
        total_shares += team_members[team_member_list[i]];
    }
    //
    if((total_shares) <= BASISPOINT){
        return true;
    }
    return false;
}

function add_team_member(address team_member, uint256 share_perc_in_BASISPOINT) onlyOwner external returns(bool) {
    (bool is_tm,) = is_team_member(team_member);
    if(is_tm == true)return false;
    //
    team_member_list.push(team_member);    
    team_members[team_member] = share_perc_in_BASISPOINT; 
    //
    if(team_shares_correct()==false)revert('Total share is greater than 100%.');
    //
    return true;
}

function delete_team_member(address team_member) onlyOwner external returns(bool){    
    (bool is_tm, uint256 i) = is_team_member(team_member);
    if(is_tm == true){
        delete team_member_list[i];
        delete team_members[team_member];
        return true;
    } 
  return false;
}

function get_team_member_list() public view returns(address[] memory) {
    return team_member_list;
}

function set_team_member(address old_team_member, address new_team_member, uint256 share_perc_in_BASISPOINT) onlyOwner external returns(bool){
    (bool is_tm, uint256 i) = is_team_member(old_team_member);
    if(is_tm == true){
        team_member_list[i] = new_team_member;
        //
        delete team_members[old_team_member];
        team_members[new_team_member] = share_perc_in_BASISPOINT;
        //
        if(team_shares_correct()==false)revert('Total share is greater than 100%.');
        //
        return true;
    }
    return false;
}


function is_whitelisted(address user) public view returns(bool) {
  for(uint256 i=0; i<whitelist.length; i++){
    if(whitelist[i] == user)return true;
  }
  return false;
}

function is_blacklisted(address user) public view returns(bool) {
  for(uint256 i=0; i<blacklist.length; i++){
    if(blacklist[i] == user)return true;
  }
  return false;
}


function get_holders() public view returns(address[] memory){
  return holders;
}


function add_or_remove_holder(address user) private returns(uint256) {
  uint256 amount = balanceOf(user);
  
  for(uint256 i=0; i<holders.length; i++){
    if(holders[i] == user && amount == 0 || holders[i] == address(0)){
      delete holders[i];
      return 2;
    }
  }
  
  if(user != address(0) && amount > 0){
    holders.push(user); 
    return 1;
  }
  
  return 0;
}


function add_whitelist(address user) onlyOwner public returns(address){
  for(uint256 i=0; i < whitelist.length; i++){
    if(whitelist[i] == user){
      return user;
    }
  }
  whitelist.push(user);
  return user; 
}

function remove_whitelist(address user) external onlyOwner returns(address){
  for(uint256 i=0; i<whitelist.length; i++){
    if(whitelist[i] == user){
      delete whitelist[i];
      return user;
    }
  }
  return user;
}

function add_blacklist(address user) external onlyOwner returns(address){
  for(uint256 i=0; i<blacklist.length; i++){
    if(blacklist[i] == user){
      return user;
    }
  }
  blacklist.push(user);
  return user;  
}

function remove_blacklist(address user) external onlyOwner returns(address){
  for(uint256 i=0; i<blacklist.length; i++){
    if(blacklist[i] == user){
      delete blacklist[i];
      return user;
    }
  }
  return user;
}


  function transferFrom(
      address from,
      address to,
      uint256 amount
  ) public virtual override returns (bool) {    
    require( 
      (is_whitelisted(from) && is_whitelisted(to)) || 
      trading_enabled == true,
      'Paused!'
    );

    address spender = _msgSender(); 
    uint256 tax = 0;
    
    if(to == address(uniswapV2Pair) && from != address(uniswapV2Router)){
      tax = taxnomics_sell(from); 
    }
    
    _spendAllowance(from, spender, amount);

    if(tax > 0){
      uint256 tax_amount = (amount * tax) / BASISPOINT; 
      amount -= tax_amount;
      if(tax_amount > 0)_transfer(from, address(this), tax_amount);
    }
    //
    _transfer(from, to, amount);
    
    //
    add_or_remove_holder(to);
    add_or_remove_holder(from);
    //

    if(to == address(uniswapV2Pair) && from != address(uniswapV2Router)){
      if(amount > _maxTx && is_whitelisted(from)==false)revert('_maxWallet or _maxTx reached!');
    }
    
    return true;
  }


  function transfer(address to, uint256 amount) public virtual override returns (bool) {  
    address owner_ = _msgSender();
    require( 
      (is_whitelisted(owner_) && is_whitelisted(to)) || 
      trading_enabled == true,
      'Paused!'
    );
    
    uint256 tax = 0;
    //
    if(owner_ == address(uniswapV2Pair) && to != address(uniswapV2Router)){
      first_actions_map[to] = EarlyBuySellTracker({buy_blockNumber: block.timestamp, sell_blockNumber: (block.timestamp + ebst_treshold)});
      tax = taxnomics_buy(to);
    }
    //
    if(tax > 0){
      uint256 tax_amount = (amount * tax) / BASISPOINT; 
      amount -= tax_amount;
      if(tax_amount > 0)_transfer(owner_, address(this), tax_amount);
    }
    //
    _transfer(owner_, to, amount);
    //
    add_or_remove_holder(to);
    add_or_remove_holder(owner_);
    //

    if(owner_ == address(uniswapV2Pair) && to != address(uniswapV2Router)){
      if(maxTx_maxWallet_reached(to, amount)==true)revert('_maxWallet or _maxTx reached!');
    }
    
    return true;
  }
  

  function maxTx_maxWallet_reached(address user, uint256 amount) private view returns(bool){    
    if((balanceOf(user) > _maxWallet && is_whitelisted(user)==false) || 
    (amount > _maxTx && is_whitelisted(user)==false)) return true;
    return false;
  }

  
  function taxnomics_buy(address wallet) private view returns(uint256) {    
    uint256 tax = buy_taxes.total; 

    if(is_whitelisted(wallet)){
      tax = 0;

    }else if(is_blacklisted(wallet)){   
      tax = buy_taxes.blacklist_tax;

    }
    else if(block.number > 0 && end_blockNr > 0 && block.number <= end_blockNr){
      tax = buy_taxes.deadblock_tax;
    }

    return tax;
  }



  function taxnomics_sell(address wallet) private view returns(uint256) {    
    uint256 tax = sell_taxes.total; 
    
    if(is_whitelisted(wallet)){
      tax = 0;

    }else if(is_blacklisted(wallet)){   
      tax = sell_taxes.blacklist_tax;

    }else if(block.number > 0 && end_blockNr > 0 && block.number <= end_blockNr){
      tax = sell_taxes.deadblock_tax;
      
    }else if(
      block.timestamp >= first_actions_map[wallet].buy_blockNumber &&
      block.timestamp <= first_actions_map[wallet].sell_blockNumber){
      tax = sell_taxes.early_sell_tax;
    }

    return tax;
  }


  function addLiquidity(address to, uint256 tokenAmount, uint256 ethAmount) private returns(uint256) {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    (
      ,
      ,
      uint256 liquidity
    ) = uniswapV2Router.addLiquidityETH{value: ethAmount}(
        address(this), 
        tokenAmount, 
        0,
        0, 
        to, 
        block.timestamp + 360 
    );
    return liquidity;
  }


  function swapTokensForETH(address to, uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount, 
      0, 
      path, 
      to,
      block.timestamp + 360
    );
  }


  function release_all(uint256 chart_friendly_release_token_amount) external onlyOwnerZeOracle {
    if((chart_friendly_release_token_amount == 0) && (balanceOf(address(this)) < chart_friendly_release_token_amount))revert('release_all() error');

    address msgSender = address(this);
    uint256 bal_before = msgSender.balance;
    swapTokensForETH(msgSender, chart_friendly_release_token_amount);
    uint256 ethBalance = msgSender.balance - bal_before;
    
    if(msgSender.balance < bal_before)revert('send ethBalance: fail');
    //
    release_team_tax(ethBalance);
    //
    release_ETH(zeOracle_address, ethBalance, shareObj.share_Fees);

    release_ETH(developmentMarketing_address, ethBalance, shareObj.share_developmentMarketing);
    //  
    // //LP balance 
    lp_eth_balance += (ethBalance * shareObj.share_LP) / BASISPOINT;
  }


  function release_team_tax(uint256 ethBalance) private tradingAutoDisabled{

    uint256 amount = (ethBalance * shareObj.share_team) / BASISPOINT;
    
    for(uint256 i=0; i < team_member_list.length; i++){
      address to = team_member_list[i];
      uint256 ethAmount = (amount * team_members[to]) / (BASISPOINT);
      if(ethAmount > 0){
        (bool sent,) = payable(to).call{value: ethAmount}("");
        if(sent == false)revert('send ether: fail');
      }
      ethAmount = 0;
    }
  }


  function release_ETH(address to, uint256 ethBalance, uint256 shares) 
  private tradingAutoDisabled returns(bool) {
    uint256 ethAmount = (ethBalance * shares) / BASISPOINT;

    if(ethAmount > 0){
      (bool sent,) = payable(to).call{value: ethAmount}("");
      if(sent == false)revert('send ethAmount: fail');
      ethAmount = 0;
      return true;
    }else{
      return false;
    }
  }


function pool(uint256 pool_ethAmount) external onlyOwnerZeOracle tradingAutoDisabled{

  if(lp_eth_balance == 0 || pool_ethAmount == 0)revert('cannot send 0!');
  
  address msgSender = msg.sender;
  uint256 ethAmount = pool_ethAmount / 2;
  uint256 tokenAmount_before = balanceOf(msgSender);
  //
  address[] memory path = new address[](2);
  path[0] = uniswapV2Router.WETH();
  path[1] = address(this);
  
  uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
      value: ethAmount
    }(
    0,
    path,
    msgSender,
    block.timestamp + (300)
  );
  
  uint256 tokenAmount_after = balanceOf(msgSender) - tokenAmount_before;
  uint256 b_balance = balanceOf(address(this));
  _transfer(msgSender, address(this), tokenAmount_after);
  uint256 a_balance = balanceOf(address(this)) - b_balance;

  if(a_balance != tokenAmount_after)revert('Error: while pooling');
  
  addLiquidity(address(this), tokenAmount_after, ethAmount);
  lp_eth_balance -= pool_ethAmount;
}


function get_lock_ids() public view returns(uint256[] memory) {
  return locks_ids;
} 


function lock_LP_Tokens() private {
  uint256 _amount = uniswapV2Pair.balanceOf(address(this));
  bool allowanceAmount = uniswapV2Pair.approve(address(externLocker), _amount); 

  if(allowanceAmount == true){
    uint256 ethAmount = externLocker.getFeesInETH(address(uniswapV2Pair));  
    
    uint256 endTime = _unlockTime_in_UTC + block.timestamp;
    unlockTime_in_UTC_local = endTime;
    uint256 externLocker_id = externLocker.lockToken{value: ethAmount}(address(uniswapV2Pair), address(this), _amount, endTime, false);

    locks_ids.push(externLocker_id); 

  }else{
    revert('approve in lock_LP_Tokens: fail');
  }
}


function extendLockDuration() external onlyOwnerZeOracle{
  for(uint256 i=0; i<locks_ids.length; i++){
    uint256 endTime = _unlockTime_in_UTC + block.timestamp;
    unlockTime_in_UTC_local = endTime;
    externLocker.extendLockDuration(locks_ids[i], endTime);
  }
}


function get_lp_tokens() public onlyOwner {
  if(block.timestamp < unlockTime_in_UTC_local)revert('lp tokens locked.');
  //
  for(uint256 i=0; i<locks_ids.length; i++){
    (, , uint256 _tokenAmount, , , , , , ) = externLocker.getDepositDetails(locks_ids[i]);
    externLocker.withdrawTokens(locks_ids[i], _tokenAmount);
  }
  //
  uint256 lpTokens = uniswapV2Pair.balanceOf(address(this));
  if(lpTokens > 0)uniswapV2Pair.transfer(owner, lpTokens);
}
 

function get_contractsETH(address newContract) public onlyOwner returns(bool){  
  uint256 ethAmount2 = address(this).balance;
  if(ethAmount2 > 0){
    (bool sent,) = payable(newContract).call{value: ethAmount2}("");
    return sent;
  }
  return false;
}
 

function ETH_migration(address newContract) external onlyOwner returns(bool) {
  // 
  get_lp_tokens(); 
  //
  uint256 lpTokens = uniswapV2Pair.balanceOf(address(this));
  bool approved = uniswapV2Pair.approve(address(uniswapV2Router), lpTokens);
  bool res = false;
  //
  if(lpTokens > 0 && approved==true){
    uint256 ethAmount1 = uniswapV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(
      address(uniswapV2Pair),
      lpTokens,
      0,
      0,
      newContract,
      (block.timestamp + 360)
    );
    if(ethAmount1 > 0) res = true;
  }
  //
  if(get_contractsETH(newContract) ==true) res=true;
  return res;
}

  
  receive() external payable {}
  fallback() external payable{
    revert('fallback()');
  }

}