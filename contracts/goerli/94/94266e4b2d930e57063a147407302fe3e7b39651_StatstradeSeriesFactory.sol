/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
  function transfer(address to,uint value) external returns(bool);
  function balanceOf(address owner) external view returns(uint);
  function transferFrom(address from,address receiver,uint amount) external ;
}

contract StatstradeSeriesFactory {
  enum SeriesStatus { Undefined, Active, Locked, Finalise, Completed, Expired }
  
  enum SeriesAccountStatus { Undefined, Paid, Active, Rejected, Refunded, Winning }
  
  struct Series{
    string name;
    SeriesStatus status;
    address series_owner;
    address series_erc20;
    uint series_buy_in;
    uint series_expiry;
    uint total_pool;
    uint total_bonus;
    uint16 total_players;
    uint16 [] winning_rates;
    address [] winning_players;
  }
  
  struct SeriesAccount{
    SeriesAccountStatus status;
    uint8 placement;
    uint payout;
  }
  
  event SeriesEvent(string event_type,string event_id,address sender,uint value);
  
  address public g__SiteAuthority;
  
  mapping(address => bool) public g__SiteSupport;
  
  uint16 public g__SiteTaxRate;
  
  uint16 public g__SeriesCount;
  
  mapping(string => Series) public g__SeriesLookup;
  
  mapping(string => mapping(address => SeriesAccount)) public g__SeriesAccounts;
  
  constructor(uint16 site_tax) {
    g__SiteAuthority = msg.sender;
    g__SiteTaxRate = site_tax;
  }
  
  function ut__assert_admin(address user_address) internal view {
    require(
      (user_address == g__SiteAuthority) || g__SiteSupport[user_address],
      "Site admin only."
    );
  }
  
  function ut__assert_owner(string memory series_id,address user_address) internal view {
    require(
      g__SeriesLookup[series_id].series_owner == user_address,
      "Series owner only."
    );
  }
  
  function ut__assert_not_expired(string memory series_id) internal view {
    require(
      block.timestamp < g__SeriesLookup[series_id].series_expiry,
      "Series has expired"
    );
  }
  
  function ut__set_expiry(string memory series_id,uint series_expiry) internal {
    g__SeriesLookup[series_id].series_expiry = series_expiry;
  }
  
  function ut__get_winning_rates(string memory series_id) external view returns(uint16 [] memory) {
    return g__SeriesLookup[series_id].winning_rates;
  }
  
  function ut__get_winning_players(string memory series_id) external view returns(address [] memory) {
    return g__SeriesLookup[series_id].winning_players;
  }
  
  function ut__contract_in(string memory series_id,address from_address,uint amount) internal {
    IERC20 erc20 = IERC20(g__SeriesLookup[series_id].series_erc20);
    erc20.transferFrom(from_address,address(this),amount);
  }
  
  function ut__contract_out(string memory series_id,address to_address,uint amount) internal {
    IERC20 erc20 = IERC20(g__SeriesLookup[series_id].series_erc20);
    erc20.transfer(to_address,amount);
  }
  
  function site__add_support(address user) external {
    require(msg.sender == g__SiteAuthority,"Authority Only");
    g__SiteSupport[user] = true;
  }
  
  function site__remove_support(address user) external {
    ut__assert_admin(msg.sender);
    delete g__SiteSupport[user];
  }
  
  function site__series_create(string memory series_id,string memory name,address series_owner,address series_erc20,uint series_buy_in,uint series_expiry,uint16 [] memory winning_rates) external payable {
    ut__assert_admin(msg.sender);
    require(
      g__SeriesLookup[series_id].status == SeriesStatus.Undefined,
      "Series already exists"
    );
    require(
      series_expiry > (block.timestamp + 1 days),
      "Series time expiration too early"
    );
    require(winning_rates.length <= 16,"Winning rates too long");
    uint16 sum_rates = 0;
    for(uint i = 0; i < winning_rates.length; ++i){
      sum_rates = (sum_rates + winning_rates[i]);
    }
    require(
      (sum_rates + g__SiteTaxRate) <= 10000,
      "Prize rates are too high"
    );
    require(sum_rates > 7999,"Prize rates are too low");
    ++g__SeriesCount;
    g__SeriesLookup[series_id] = Series({
      total_pool: 0,
      name: name,
      winning_rates: winning_rates,
      winning_players: new address [](winning_rates.length),
      total_bonus: 0,
      series_erc20: series_erc20,
      series_buy_in: series_buy_in,
      status: SeriesStatus.Active,
      series_owner: series_owner,
      series_expiry: series_expiry,
      total_players: 0
    });
    emit SeriesEvent("create",series_id,series_owner,0);
  }
  
  function user__buy_in_request(string memory series_id,uint amount) external {
    ut__assert_not_expired(series_id);
    require(
      g__SeriesLookup[series_id].status == SeriesStatus.Active,
      "Series is not active"
    );
    require(
      g__SeriesAccounts[series_id][msg.sender].status == SeriesAccountStatus.Undefined,
      "Buy in exists."
    );
    require(
      g__SeriesLookup[series_id].series_buy_in == amount,
      "Buy in amount incorrect."
    );
    ut__contract_in(series_id,msg.sender,amount);
    g__SeriesAccounts[series_id][msg.sender] = SeriesAccount(SeriesAccountStatus.Paid,0,0);
    emit SeriesEvent("buy_in_request",series_id,msg.sender,amount);
  }
  
  function site__buy_in_accept(string memory series_id,address user_address) external {
    require(
      g__SeriesAccounts[series_id][user_address].status == SeriesAccountStatus.Paid,
      "Buy in status is not paid"
    );
    uint amount = g__SeriesLookup[series_id].series_buy_in;
    g__SeriesLookup[series_id].total_pool += amount;
    ++g__SeriesLookup[series_id].total_players;
    g__SeriesAccounts[series_id][user_address].status = SeriesAccountStatus.Active;
    emit SeriesEvent("buy_in_accept",series_id,user_address,amount);
  }
  
  function site__buy_in_reject(string memory series_id,address user_address) external {
    require(
      g__SeriesAccounts[series_id][user_address].status == SeriesAccountStatus.Paid,
      "Buy in status is not paid"
    );
    g__SeriesAccounts[series_id][user_address].status = SeriesAccountStatus.Rejected;
    emit SeriesEvent(
      "buy_in_reject",
      series_id,
      user_address,
      g__SeriesLookup[series_id].series_buy_in
    );
  }
  
  function room__series_add_bonus(string memory series_id,uint amount) external {
    ut__assert_owner(series_id,msg.sender);
    ut__assert_not_expired(series_id);
    require(
      (g__SeriesLookup[series_id].status == SeriesStatus.Active) || (g__SeriesLookup[series_id].status == SeriesStatus.Locked),
      "Series invalid status"
    );
    ut__contract_in(series_id,msg.sender,amount);
    g__SeriesLookup[series_id].total_pool += amount;
    g__SeriesLookup[series_id].total_bonus += amount;
    emit SeriesEvent("add_bonus",series_id,msg.sender,amount);
  }
  
  function room__series_lock(string memory series_id) external {
    ut__assert_owner(series_id,msg.sender);
    ut__assert_not_expired(series_id);
    require(
      g__SeriesLookup[series_id].status == SeriesStatus.Active,
      "Series not Active"
    );
    g__SeriesLookup[series_id].status = SeriesStatus.Locked;
    emit SeriesEvent("lock",series_id,msg.sender,0);
  }
  
  function room__series_finalise(string memory series_id) external {
    ut__assert_owner(series_id,msg.sender);
    ut__assert_not_expired(series_id);
    SeriesStatus status = g__SeriesLookup[series_id].status;
    require(
      (status == SeriesStatus.Active) || (status == SeriesStatus.Locked),
      "Series invalid status"
    );
    g__SeriesLookup[series_id].status = SeriesStatus.Finalise;
    emit SeriesEvent("finalise",series_id,msg.sender,0);
  }
  
  function user__trigger_expiry(string memory series_id) external {
    require(
      g__SeriesLookup[series_id].series_expiry < block.timestamp,
      "Series not expired."
    );
    SeriesStatus status = g__SeriesLookup[series_id].status;
    require(
      (status == SeriesStatus.Active) || (status == SeriesStatus.Locked),
      "Series invalid status"
    );
    g__SeriesLookup[series_id].status = SeriesStatus.Expired;
    emit SeriesEvent("expire",series_id,msg.sender,0);
  }
  
  function user__refund_rejected_buy_in(string memory series_id) external {
    SeriesAccountStatus status = g__SeriesAccounts[series_id][msg.sender].status;
    require(
      (status == SeriesAccountStatus.Rejected),
      "Buy in not refundable"
    );
    uint amount = g__SeriesLookup[series_id].series_buy_in;
    uint site_tax = ((amount * g__SiteTaxRate) / 10000);
    ut__contract_out(series_id,msg.sender,amount - site_tax);
    ut__contract_out(series_id,g__SiteAuthority,site_tax);
    g__SeriesAccounts[series_id][msg.sender].status = SeriesAccountStatus.Refunded;
    emit SeriesEvent("refund_rejected",series_id,msg.sender,amount);
  }
  
  function user__refund_expired_buy_in(string memory series_id) external {
    require(
      (g__SeriesAccounts[series_id][msg.sender].status == SeriesAccountStatus.Active) && (g__SeriesLookup[series_id].status == SeriesStatus.Expired),
      "Buy in not refundable"
    );
    uint amount = g__SeriesLookup[series_id].series_buy_in;
    ut__contract_out(series_id,msg.sender,amount);
    g__SeriesAccounts[series_id][msg.sender].status = SeriesAccountStatus.Refunded;
    g__SeriesLookup[series_id].total_pool -= amount;
    emit SeriesEvent("refund_expired",series_id,msg.sender,amount);
  }
  
  function room__refund_bonus(string memory series_id) external {
    ut__assert_owner(series_id,msg.sender);
    require(
      g__SeriesLookup[series_id].status == SeriesStatus.Expired,
      "Bonus not refundable"
    );
    uint total_bonus = g__SeriesLookup[series_id].total_bonus;
    require(total_bonus > 0,"Bonus balance is zero");
    ut__contract_out(series_id,msg.sender,total_bonus);
    g__SeriesLookup[series_id].total_pool -= total_bonus;
    g__SeriesLookup[series_id].total_bonus = 0;
    emit SeriesEvent("refund_bonus",series_id,msg.sender,total_bonus);
  }
  
  function site__series_complete(string memory series_id,address [] memory winning_players) external payable {
    ut__assert_admin(msg.sender);
    Series memory series = g__SeriesLookup[series_id];
    require(series.status != SeriesStatus.Undefined,"Series not found.");
    require(
      series.winning_rates.length == winning_players.length,
      "Winning arrays not same length"
    );
    for(uint i = 0; i < winning_players.length; ++i){
      require(
        g__SeriesAccounts[series_id][winning_players[i]].status == SeriesAccountStatus.Active,
        "Player status incorrect"
      );
      g__SeriesAccounts[series_id][winning_players[i]].status = SeriesAccountStatus.Winning;
    }
    IERC20 erc20 = IERC20(g__SeriesLookup[series_id].series_erc20);
    uint site_tax = ((series.total_pool * g__SiteTaxRate) / 10000);
    erc20.transfer(g__SiteAuthority,site_tax);
    uint series_profit = (series.total_pool - site_tax);
    for(uint i = 0; i < winning_players.length; ++i){
      address user_address = winning_players[i];
      uint user_payout = ((series.winning_rates[i] * series.total_pool) / 10000);
      erc20.transfer(winning_players[i],user_payout);
      g__SeriesAccounts[series_id][user_address].payout = user_payout;
      series_profit -= user_payout;
    }
    erc20.transfer(series.series_owner,series_profit);
    g__SeriesLookup[series_id].winning_players = winning_players;
    g__SeriesLookup[series_id].status = SeriesStatus.Completed;
    emit SeriesEvent("complete",series_id,series.series_owner,series.total_pool);
  }
}