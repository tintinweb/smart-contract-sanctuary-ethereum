/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Opensea_GoldenTicket_Extension {

   address[] public goldenTicket_holders;
   uint256 private claimPerc = 10;

   address private owner;
   mapping(address=>bool) private projects;

  uint256 denominator = 1000;
  bool private all_liql_sent = false;
  bool private allow_claim = true;





  struct Incentive {
    uint256 startTime;
  }
  
  uint256 private time_treshold = 30 days * 6; //every 6. month holders can claim
  mapping(address=> Incentive) public incentives;
  mapping(address=> uint256) public rewards;


  

  constructor() {
    owner = msg.sender;
  }


  
  /*
  user can claim 10% of the liquidity every 6 month since the day they bought the Golden Ticket
  - user buy a gt
  - user has the right to get an incentive
  - after 6 month he can get his reward for investing in gt
  */

  function setTime_treshold(uint256 time_treshold_) external ownerOnly{
    time_treshold = time_treshold_;
  }

  function setClaimPerc(uint256 perc) external ownerOnly{
    claimPerc = perc;
  }  
  function getClaimPerc() external view ownerOnly returns(uint256){
    return claimPerc;
  }


  function claim() public {
    if(allow_claim == false)revert('"Claim" paused!');
    (uint256 amount_individuel, uint256 stakeNr) = calculate_reward(msg.sender);

    require(amount_individuel > 0, 'After 6 months you can claim.');
    require(incentives[msg.sender].startTime > 0, 'You need to buy a golden ticket first.');

    incentives[msg.sender].startTime = incentives[msg.sender].startTime + (stakeNr * time_treshold);
    rewards[msg.sender] += amount_individuel;
  }

  function getMyCurrentRewards() public view returns(uint256) {
    return rewards[msg.sender];
  }

  function withdraw() external {
    require(rewards[msg.sender] > 0, 'You cannot withdraw "0" eth.');
    uint256 value = rewards[msg.sender];
    rewards[msg.sender] = 0;
    require(getMyCurrentRewards()==0, 'Your currrent reward should be 0.');
    (bool success, ) = (msg.sender).call{value: value}("");
  }

  function reward_all_lql_sent(address user) private view returns(uint256, uint256) {    
    (uint256 tmp, uint256 startTime, uint256 stakeNr) = canClaim(user);
    uint256 amount_individuel=0;

    if(stakeNr > 0 && getLiquidity() > 0){
      //take the perc out of the total amount
      uint256 amount_all = (getLiquidity() * claimPerc) / 100; 
      uint256 amount_part = amount_all / denominator;
      amount_individuel = amount_part * stakeNr;
      return (amount_individuel, stakeNr);

    }else{
      return (amount_individuel, stakeNr);
    }
  }

  function reward_part_lql_sent(address user) private view returns(uint256, uint256) {    
    (uint256 tmp, uint256 startTime, uint256 stakeNr) = canClaim(user);
    uint256 amount_individuel=0;

    if(stakeNr > 0 && getLiquidity() > 0){
      uint256 amount_part = getLiquidity() / denominator;
      amount_individuel = amount_part * stakeNr;
      return (amount_individuel, stakeNr);

    }else{
      return (amount_individuel, stakeNr);
    }
  }

  function calculate_reward(address user) public view returns(uint256, uint256) { 
    if(all_liql_sent == true){
      return reward_all_lql_sent(user);
    }else{
      return reward_part_lql_sent(user);
    }
  }

  function setDenominator(uint256 new_denominator, bool dependsOnHolders) external ownerOnly {
    if(dependsOnHolders==true){
      denominator = goldenTicket_holders.length;
    }else{
      denominator = new_denominator;
    }
  }

  function total_needed_liquidity() public view ownerOnly returns(uint256) {
    uint256 neededAmount = 0;
    for(uint256 i=0; i<goldenTicket_holders.length; i++){
      (uint256 amount_individuel, uint256 stakeNr) = calculate_reward(goldenTicket_holders[i]);
      neededAmount += amount_individuel;
    }
    return neededAmount;
  }


  function canClaim(address user) view public returns(uint256, uint256, uint256){
    if(incentives[user].startTime > 0){
      uint256 startTime = incentives[user].startTime + time_treshold;  
      uint256 tmp = block.timestamp;
      uint256 time_diff = tmp - startTime;
      uint256 stakeNr = time_diff / time_treshold;
      return (tmp, startTime, stakeNr);
    }else{
      return (0, 0, 0);
    }
  }

  function initial_incentive(address user, uint256 initial_time_in_s) ownerOnly external {
    incentives[user] = Incentive(initial_time_in_s);
  }

  function getLiquidity() internal view returns(uint256) {
    return address(this).balance;
  }

  
  function liql_back() ownerOnly external {
    (bool success, ) = (msg.sender).call{value: address(this).balance}("");
    if(!success)revert('liql_back() error');
  }





  modifier ownerOnly(){
    if(owner != msg.sender){
      revert('OwnerOnly!');
    }
    _;
  }

  function setProject(address project, bool value) ownerOnly external {
    projects[project] = value;
  }

  function setOwner(address newOwner) external ownerOnly {
    owner = newOwner;
  }

  function setAll_liql_sent(bool new_all_liql_sent) external ownerOnly {
    all_liql_sent = new_all_liql_sent;
  }

  function set_allow_claim(bool new_allow_claim) external ownerOnly {
    allow_claim = new_allow_claim;
  }


  function set_goldenTicket_holders(address[] memory holders) ownerOnly external{
    goldenTicket_holders = holders;
  }

  function add_holder(address holder) ownerOnly external{
    if(isHolder(holder) == false){
      goldenTicket_holders.push(holder);
    }
  }

  function remove_holder(address holder) ownerOnly external{
    for(uint256 i=0; i < goldenTicket_holders.length; i++){
      if(holder == goldenTicket_holders[i]){
        delete goldenTicket_holders[i];
        break;
      }
    }
  }
  

  function get_goldenTicket_holders() public view returns(address[] memory) {
    return goldenTicket_holders;
  }
  

  function isHolder(address holder) view public returns(bool) {
    bool holder_exists = false;
    for(uint256 i=0; i < goldenTicket_holders.length; i++){
      if(goldenTicket_holders[i] == holder){
        holder_exists = true;
        break;
      }
    }
    return holder_exists;
  }



  fallback() payable external{
    revert();
  }

  receive() payable external{

  }
  

}