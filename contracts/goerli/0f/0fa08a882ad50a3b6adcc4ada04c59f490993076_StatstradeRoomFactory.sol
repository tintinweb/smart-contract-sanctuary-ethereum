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

contract StatstradeRoomFactory {
  enum RoomStatus { Undefined, Active, Arbitration, Closed }
  
  enum RoomAccountStatus { Undefined, Active, Locked, Closed }
  
  enum RequestStatus { 
    Undefined, 
    Pending, 
    Confirmed, 
    RejectedSite, 
    Rejected, 
    Approved, 
    Completed
   }
  
  address public g__SiteAuthority;
  
  mapping(address => bool) public g__SiteSupport;
  
  uint16 public g__SiteTaxRate;
  
  uint16 public g__SiteArbitrationThreshold;
  
  struct WithdrawRequest{
    uint amount;
    RequestStatus status;
  }
  
  struct Room{
    string name;
    RoomStatus status;
    uint total_pool;
    uint total_requested;
    uint16 total_players;
    uint16 total_arbitration;
    address room_owner;
    address room_erc20;
    uint16 room_tax_rate;
    uint room_withdraw_min;
    uint room_withdraw_max;
  }
  
  struct RoomAccount{
    RoomAccountStatus status;
    bool arbitration;
    string last_withdraw_id;
    uint last_withdraw_time;
  }
  
  event RoomEvent(string event_type,string event_id,address sender,uint value);
  
  uint16 public g__RoomCount;
  
  mapping(string => Room) public g__RoomLookup;
  
  mapping(string => mapping(address => RoomAccount)) public g__RoomAccounts;
  
  mapping(
    string => mapping(address => mapping(string => WithdrawRequest))
  ) public g__RoomWithdrawals;
  
  constructor(uint16 site_tax,uint16 site_arbitration_threshold) {
    g__SiteAuthority = msg.sender;
    g__SiteTaxRate = site_tax;
    g__SiteArbitrationThreshold = site_arbitration_threshold;
  }
  
  function ut__assert_admin(address user_address) internal view {
    require(
      (user_address == g__SiteAuthority) || g__SiteSupport[user_address],
      "Site admin only."
    );
  }
  
  function ut__assert_owner(string memory room_id,address user_address) internal view {
    require(
      g__RoomLookup[room_id].room_owner == user_address,
      "Room owner only."
    );
    require(
      g__RoomLookup[room_id].status != RoomStatus.Arbitration,
      "Room in arbitration."
    );
  }
  
  function ut__assert_management(string memory room_id,address user_address) internal view {
    require(
      (g__RoomLookup[room_id].room_owner == user_address) || (user_address == g__SiteAuthority) || g__SiteSupport[user_address],
      "Room management only."
    );
  }
  
  function ut__get_account(string memory room_id,address user_address) internal view returns(RoomAccount memory) {
    RoomAccount memory account = g__RoomAccounts[room_id][user_address];
    require(
      account.status != RoomAccountStatus.Undefined,
      "User not found."
    );
    return account;
  }
  
  function ut__get_withdraw(string memory room_id,address user_address,string memory withdraw_id) internal view returns(WithdrawRequest memory) {
    WithdrawRequest memory request = g__RoomWithdrawals[room_id][user_address][withdraw_id];
    require(
      request.status != RequestStatus.Undefined,
      "Request not found."
    );
    return request;
  }
  
  function site__add_support(address user) external {
    require(msg.sender == g__SiteAuthority,"Site authority only.");
    g__SiteSupport[user] = true;
  }
  
  function site__remove_support(address user) external {
    ut__assert_admin(msg.sender);
    delete g__SiteSupport[user];
  }
  
  function site__room_create(string memory room_id,string memory name,address room_owner,address room_erc20,uint16 room_tax_rate,uint room_withdraw_min,uint room_withdraw_max) external {
    ut__assert_admin(msg.sender);
    require(
      RoomStatus.Undefined == g__RoomLookup[room_id].status,
      "Room already exists."
    );
    Room memory room = Room({
      room_tax_rate: room_tax_rate,
      total_requested: 0,
      room_withdraw_max: room_withdraw_max,
      total_pool: 0,
      name: name,
      room_owner: room_owner,
      total_arbitration: 0,
      room_erc20: room_erc20,
      room_withdraw_min: room_withdraw_min,
      status: RoomStatus.Active,
      total_players: 0
    });
    ++g__RoomCount;
    g__RoomLookup[room_id] = room;
    emit RoomEvent("room_create",room_id,room_owner,0);
  }
  
  function site__account_open(string memory room_id,address user_address) external {
    ut__assert_admin(msg.sender);
    require(
      g__RoomLookup[room_id].status == RoomStatus.Active,
      "Room incorrect status"
    );
    require(
      g__RoomAccounts[room_id][user_address].status == RoomAccountStatus.Undefined,
      "Account already registered."
    );
    RoomAccount memory account = RoomAccount(RoomAccountStatus.Active,false,"",0);
    uint16 total_players = ++g__RoomLookup[room_id].total_players;
    g__RoomAccounts[room_id][user_address] = account;
    emit RoomEvent("account_open",room_id,user_address,total_players);
  }
  
  function site__account_close(string memory room_id,address user_address) external {
    ut__assert_admin(msg.sender);
    RoomAccount memory account = ut__get_account(room_id,user_address);
    require(
      account.status == RoomAccountStatus.Active,
      "Account incorrect status."
    );
    delete g__RoomAccounts[room_id][user_address];
    uint16 total_players = --g__RoomLookup[room_id].total_players;
    emit RoomEvent("account_close",room_id,user_address,total_players);
  }
  
  function room__account_lock(string memory room_id,address user_address) external {
    ut__assert_management(room_id,msg.sender);
    RoomAccount memory account = ut__get_account(room_id,user_address);
    require(
      account.status == RoomAccountStatus.Active,
      "Account incorrect status."
    );
    g__RoomAccounts[room_id][user_address].status = RoomAccountStatus.Locked;
    emit RoomEvent("account_lock",room_id,user_address,0);
  }
  
  function room__account_unlock(string memory room_id,address user_address) external {
    ut__assert_owner(room_id,msg.sender);
    RoomAccount memory account = ut__get_account(room_id,user_address);
    require(
      account.status == RoomAccountStatus.Locked,
      "Account not banned."
    );
    g__RoomAccounts[room_id][user_address].status = RoomAccountStatus.Active;
    emit RoomEvent("account_unlock",room_id,user_address,0);
  }
  
  function user__arbitration_vote(string memory room_id) external {
    RoomAccount memory account = ut__get_account(room_id,msg.sender);
    require(!account.arbitration,"Account arbitration voted.");
    g__RoomAccounts[room_id][msg.sender].arbitration = true;
    uint16 total_arbitration = ++g__RoomLookup[room_id].total_arbitration;
    uint16 total_players = g__RoomLookup[room_id].total_players;
    if((total_arbitration > 4) && (total_arbitration > ((g__SiteArbitrationThreshold * total_players) / 100))){
      g__RoomLookup[room_id].status = RoomStatus.Arbitration;
    }
    emit RoomEvent("arbitration_vote",room_id,msg.sender,total_arbitration);
  }
  
  function user__arbitration_unvote(string memory room_id) external {
    require(
      g__RoomLookup[room_id].status != RoomStatus.Arbitration,
      "Room in arbitration."
    );
    RoomAccount memory account = ut__get_account(room_id,msg.sender);
    require(account.arbitration,"Account not voted.");
    delete g__RoomAccounts[room_id][msg.sender].arbitration;
    uint16 total_arbitration = --g__RoomLookup[room_id].total_arbitration;
    emit RoomEvent("arbitration_unvote",room_id,msg.sender,total_arbitration);
  }
  
  function user__withdraw_request(string memory room_id,string memory withdraw_id,uint amount) external {
    RoomAccount memory account = g__RoomAccounts[room_id][msg.sender];
    Room memory room = g__RoomLookup[room_id];
    require(
      (account.status == RoomAccountStatus.Active) || (room.status == RoomStatus.Arbitration),
      "Withdraw not allowed."
    );
    require(
      g__RoomWithdrawals[room_id][msg.sender][withdraw_id].status == RequestStatus.Undefined,
      "Withdraw already requested."
    );
    require(
      amount >= room.room_withdraw_min,
      "Withdraw amount below minimum."
    );
    require(
      amount <= room.room_withdraw_max,
      "Withdraw amount above maximum"
    );
    uint new_total_requested = amount;
    require(
      g__RoomLookup[room_id].total_pool >= new_total_requested,
      "Withdraw over pool limit."
    );
    g__RoomWithdrawals[room_id][msg.sender][withdraw_id] = WithdrawRequest(amount,RequestStatus.Pending);
    g__RoomLookup[room_id].total_requested = new_total_requested;
    emit RoomEvent("withdraw_request",withdraw_id,msg.sender,amount);
  }
  
  function site__withdraw_confirm(string memory room_id,address user_address,string memory withdraw_id,uint amount) external {
    ut__assert_admin(msg.sender);
    WithdrawRequest memory request = ut__get_withdraw(room_id,user_address,withdraw_id);
    require(
      request.status == RequestStatus.Pending,
      "Withdraw not pending"
    );
    require(request.amount == amount,"Withdraw amount incorrect");
    g__RoomWithdrawals[room_id][user_address][withdraw_id].status = RequestStatus.Confirmed;
    emit RoomEvent("withdraw_confirm_site",withdraw_id,user_address,amount);
  }
  
  function site__withdraw_reject(string memory room_id,address user_address,string memory withdraw_id) external {
    ut__assert_admin(msg.sender);
    WithdrawRequest memory request = ut__get_withdraw(room_id,user_address,withdraw_id);
    require(
      request.status == RequestStatus.Pending,
      "Withdraw not pending"
    );
    g__RoomWithdrawals[room_id][user_address][withdraw_id].status = RequestStatus.RejectedSite;
    g__RoomLookup[room_id].total_requested -= request.amount;
    emit RoomEvent("withdraw_reject_site",withdraw_id,user_address,request.amount);
  }
  
  function ut__withdraw_transfer(string memory room_id,address user_address,string memory withdraw_id,WithdrawRequest memory request,bool arbitrated) internal {
    uint site_tax = ((request.amount * g__SiteTaxRate) / 10000);
    uint room_tax = ((request.amount * g__RoomLookup[room_id].room_tax_rate) / 10000);
    IERC20 erc20 = IERC20(g__RoomLookup[room_id].room_erc20);
    if(arbitrated){
      erc20.transfer(g__SiteAuthority,site_tax + room_tax);
    }
    else{
      erc20.transfer(g__SiteAuthority,site_tax);
      erc20.transfer(g__RoomLookup[room_id].room_owner,room_tax);
    }
    erc20.transfer(user_address,request.amount - site_tax - room_tax);
    g__RoomWithdrawals[room_id][msg.sender][withdraw_id].status = RequestStatus.Completed;
    g__RoomLookup[room_id].total_pool -= request.amount;
    g__RoomLookup[room_id].total_requested -= request.amount;
    emit RoomEvent("withdraw_transfer",withdraw_id,user_address,request.amount);
  }
  
  function room__withdraw_approve(string memory room_id,address user_address,string memory withdraw_id,uint amount) external {
    ut__assert_owner(room_id,msg.sender);
    WithdrawRequest memory request = g__RoomWithdrawals[room_id][user_address][withdraw_id];
    require(
      request.status == RequestStatus.Confirmed,
      "Withdraw not confirmed"
    );
    require(request.amount == amount,"Withdraw amount incorrect");
    ut__withdraw_transfer(room_id,user_address,withdraw_id,request,false);
  }
  
  function room__withdraw_reject(string memory room_id,address user_address,string memory withdraw_id) external {
    ut__assert_owner(room_id,msg.sender);
    WithdrawRequest memory request = g__RoomWithdrawals[room_id][user_address][withdraw_id];
    require(
      request.status == RequestStatus.Confirmed,
      "Withdraw not confirmed"
    );
    g__RoomWithdrawals[room_id][user_address][withdraw_id].status = RequestStatus.Rejected;
    g__RoomLookup[room_id].total_requested -= request.amount;
    emit RoomEvent("withdraw_reject",withdraw_id,user_address,request.amount);
  }
  
  function user__withdraw_arbitration(string memory room_id,string memory withdraw_id) external {
    require(
      g__RoomLookup[room_id].status == RoomStatus.Arbitration,
      "Room not in arbitration."
    );
    WithdrawRequest memory request = g__RoomWithdrawals[room_id][msg.sender][withdraw_id];
    require(
      request.status == RequestStatus.Confirmed,
      "Withdraw not confirmed"
    );
    ut__withdraw_transfer(room_id,msg.sender,withdraw_id,request,true);
  }
  
  function user__account_add(string memory room_id,uint amount) external {
    RoomAccount memory account = ut__get_account(room_id,msg.sender);
    g__RoomLookup[room_id].total_pool += amount;
    IERC20 erc20 = IERC20(g__RoomLookup[room_id].room_erc20);
    erc20.transferFrom(msg.sender,address(this),amount);
    emit RoomEvent("account_add",room_id,msg.sender,amount);
  }
}