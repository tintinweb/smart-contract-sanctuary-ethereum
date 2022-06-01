/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
///do not downgrade version (8.x version supports SafeMath natively, and it is used here)
// developed by Sergey Chekriy
// formal tests passed, see test script & test log (additional testing from frontend, multiuser needed)
// 
//
//error codes:
// 0 - no rights
// 1 - not enough balance
// 2 - transfer failed
// 3 - no ether sent
// 4 - sale stage not found
// 5 - not enough ether to buy any feasible amount of tokens
// 6 - crowdsale stage volume is over
// 7 - can only get tokens from vault contract
// 8 - do not accept ether
// 9 - withdraw shares sum cannot be more than 100%
// 10 - withdraw schedule should start after all sales stages finished
// 11 - _from should be less than _to
// 12 - next record _from should be greater than previous record _to
// 13 - wallet not whitelisted
// 14 - function to be called only by wlScriptWallet (set by founders)
// 15 - max per wallet reached, can't sell
//
// Usage:
//
// 1.deploy crowdsale contact with founders, vault, token, crowdsale stages defined in constructor
// 2.changing founders/sales stages are multisig (all founders need to sign within 20 minutes)
// 3.founders need to set active sale stage (multisig), initially first one (0) is active
// 4.one founder is also possible option (in this case transactions are signed immediately)


contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor ()  {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "22");
    }
}


// token interface
contract ERC20Token {
 
    function totalSupply() external view returns (uint256){}
    function balanceOf(address account) external view returns (uint256){}
    function allowance(address owner, address spender) external view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){}
    function approve(address spender, uint256 amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}
    function decimals()  external view returns (uint8){}
  
}



// core contract
contract CrowdSale is ReentrancyGuard {
   
   
    // *** contract properties *** 
    
    uint256 constant ADJ_CONSTANT = 1000000000000000000; 
    address public ownAddress;
    address tokenAddress;
    ERC20Token token;
    
    address wlScriptWallet;
    bool useWhitelisting;
    
    
    mapping (uint256 => address) public approvedFounders;
    uint256 public approvedFoundersLength = 0;
    
    struct SaleStage{
        uint256 volume;
        uint256 _from; //timestamp
        uint256 _to; //timestamp
        uint256 price; //BNB, in wei
        bool direct_buy;
        uint256 max_per_wallet;
    }
    
    mapping (uint256 => SaleStage) public saleStages;
    uint256 public saleStagesLength = 0;
    uint256 public aciveSaleStage = 0;
    
    struct WithdrawSchedule{
        uint256 share; //in 100'000 scale; i.e. 25% -> 0.25:  25000
        uint256 _from; //timestamp 
        uint256 _to;    //timestamp
    }
    
    mapping (uint256 => WithdrawSchedule) public withdrawSchedules;
    uint256 public withdrawSchedulesLength = 0;
    
    struct ScheduleWithdrawStatus{
        mapping(uint256 => bool) schedule_withdraw_status;
    }
    mapping (address => ScheduleWithdrawStatus) userScheduleWithdrawStatus;
    
    mapping (address => bool) public whiteList;
    
    struct CrowdsaleBlance{
        mapping (uint256 => uint256) crowdsale_stage_balance;     
    }
    
    mapping (address => CrowdsaleBlance) userCrowdsaleBalance;
   
    uint8 constant REGISTER_FOUNDER = 1;
    uint8 constant REMOVE_FOUNDER = 2;
    uint8 constant SET_TOKEN = 3;
    uint8 constant ADD_SALE_STAGE = 4;
    uint8 constant REMOVE_SALE_STAGE = 5;
    uint8 constant EMERGENCY_WITHDRAW_TOKENS = 6;
    uint8 constant SET_ACTIVE_SALE_STAGE = 7;
    uint8 constant SET_VAULT_CONTRACT = 8;
    uint8 constant WITHDRAW = 9;
    uint8 constant ADD_WITHDRAW_SCHEDULE = 10;
    uint8 constant REMOVE_WITHDRAW_SCHEDULE = 11;
    uint8 constant SET_wlScriptWallet = 12;
    uint8 constant SET_WHITELISTING = 13;
    
    uint256 constant SIGN_TIMEOUT = 1200;//1200 seconds, 20 minutes
    
    uint256 constant NO_SCHEDULE_SLOT = 999999;
    
    uint256 constant PERC_SCALE = 100000;
    
    struct Signature{
        mapping (address => bool) sign_status;
        mapping (address => uint256) sign_time;
        mapping (address => bytes32) sign_data_hash;
    }
    
    mapping (uint8 => Signature) funcSign;
    
    //actual balances
    mapping (address => uint256) public investorsBalances;
    
    //init balances (after all crowdsale), used to calc shares correctly for scheduled withdrawals 
    mapping (address => uint256) public initInvestorsBalances;
    
    // *** end of properties *** 
     
    constructor()   {
        ownAddress = address(this);
        
        _registerFounder(0x52328CB786255ba4Af980aDc7d04b8Fa66d00F26);
        //_registerFounder(0x1Ec6F54e7Bcebd2Eb4a8b875D28B6b984E57fA0f);
        //_registerFounder(0x3cCbe31D03a30373E12244D0a2a2D569262dC04f);
        
       
       
    }
    
    
    // *** access modifiers *** 
    
     /**
    * @dev - modifier for access to functions for approved founders
    */
    modifier onlyFounder() {
          isFounder();
          _;
    }
    
    /**
    * @dev - utility function for modifier above
    */      
    function isFounder() internal view {
      require(
          isApprovedFounder(msg.sender),
          "only founder can call this function"
          );
    }
    
    /**
    * @dev - utility function for modifier above
    */  
    function isApprovedFounder(address newAddress) internal view returns(bool){
        for (uint256 i = 0; i < approvedFoundersLength; i++){
            if (newAddress == approvedFounders[i]) return true;
        }
        return false;
    }
 
    // *** end of access modifiers *** 
   
   
    // *** set configuration ***
    
    /**
    * @dev setter for kept token address (ERC20)
    * multisig (all founders)
    */    
    function setToken(address newERC20Contract) external onlyFounder{
        signFounder(SET_TOKEN, msg.sender, hash(0,0,newERC20Contract));
        
        if (isAllFoundersSigned(SET_TOKEN)){
            _setToken(newERC20Contract);
            resetSignatures(SET_TOKEN);
        }
    }
    
    
    function _setToken(address newERC20Contract) internal{
        tokenAddress = newERC20Contract;
        token = ERC20Token(tokenAddress);
    }
    
    /**
    * @dev getter for  token address
    */    
    function getToken() external view returns(address){
        return tokenAddress;
    }
    
    
    function setWhitelisting(bool wlStatus) external onlyFounder{
        signFounder(SET_WHITELISTING, msg.sender, hash4uint256bool(0,0,0,0,wlStatus));
        
        if (isAllFoundersSigned(SET_WHITELISTING)){
            _setWhitelisting(wlStatus);
            resetSignatures(SET_WHITELISTING);
        }
    }
    
    
    function _setWhitelisting(bool wlStatus) internal{
        useWhitelisting = wlStatus;
    }
    
    /**
    * @dev getter for  whitelisting approach
    */    
    function getWhitelistingStatus() external view returns(bool){
        return useWhitelisting;
    }
    
     /**
    * @dev setter for whitelisting script wallet
    * multisig (all founders)
    */    
    function setWLScriptWallet(address wallet) external onlyFounder{
        signFounder(SET_wlScriptWallet, msg.sender, hash(0,0,wallet));
        
        if (isAllFoundersSigned(SET_wlScriptWallet)){
            _setWLScriptWallet(wallet);
            resetSignatures(SET_wlScriptWallet);
        }
    }
    
    
    function _setWLScriptWallet(address wallet) internal{
        wlScriptWallet = wallet;
    }
    
    /**
    * @dev getter for  token address
    */    
    function getWLScriptWallet() external view returns(address){
        return wlScriptWallet;
    }
    
    
    
    
    
   
    
    /**
    * @dev whitelist wallet 
    */    
    function addWalletToWhitelist(address wallet) external {
        require(msg.sender == wlScriptWallet, "14");
        whiteList[wallet] = true;
    }

    /**
    * @dev remove wallet from whitelist 
    */    
    function removeWalletToWhitelist(address wallet) external {
         require(msg.sender == wlScriptWallet, "14");
         whiteList[wallet] = false;    
    }
    
    function isWalletWhitelisted(address wallet) external view returns(bool){
        return whiteList[wallet];
    }
    

    /**
    * @dev setter for active sale stage
    * multisig (all founders)
    */    
    function setActiveSaleStage(uint256 activeStage) external onlyFounder{
        signFounder(SET_ACTIVE_SALE_STAGE, msg.sender, hash(activeStage,0,address(0)));
        
        if (isAllFoundersSigned(SET_ACTIVE_SALE_STAGE)){
            _setActiveSaleStage(activeStage);
            resetSignatures(SET_ACTIVE_SALE_STAGE);
        }
    }
    
    
    function _setActiveSaleStage(uint256 activeStage) internal{
        aciveSaleStage = activeStage;
    }
    
    /**
    * @dev getter for  token address
    */    
    function getActiveSaleStage() external view returns(uint256){
        return aciveSaleStage;
    }
    
    // *** end of set configuration ***
  
  
    // *** contract data manipulation ***
   
     /**
    * @dev - register founder  in approvedFounders list 
    * multisig (all founders)
    */     
    function registerFounder(address newFounder) external onlyFounder {
        signFounder(REGISTER_FOUNDER, msg.sender, hash(0,0,newFounder));
        
        if (isAllFoundersSigned(REGISTER_FOUNDER)){
            _registerFounder(newFounder);
            resetSignatures(REGISTER_FOUNDER);
        }
    }
    
     /**
    * @dev - register founder  in approvedFounders list
    * 
    */     
    function _registerFounder(address newFounder) internal {
        approvedFounders[approvedFoundersLength] = newFounder;
        approvedFoundersLength++;
    }
  
  
  
    /**
    * @dev - removes address from approvedFounders list, address to remove is a parameter
    * multisig (all founders)
    */ 
    function removeFounderByAddress(address founderToRemove) external onlyFounder {
        signFounder(REMOVE_FOUNDER, msg.sender, hash(0,0,founderToRemove));
        
        if (isAllFoundersSigned(REMOVE_FOUNDER)){
            _removeFounderByAddress(founderToRemove);
            resetSignatures(REMOVE_FOUNDER);
        }    
    }
  
    function _removeFounderByAddress(address founderToRemove) internal {
         for (uint256 i = 0; i < approvedFoundersLength; i++){
              if (approvedFounders[i] == founderToRemove){
                  _removeFounderAtIndex(i);      
                  return;
              }
         }
    }
  
     /**
    * @dev - removes address from approvedFounders list, address index in list is  a parameter
    */   
    function _removeFounderAtIndex(uint256 index) internal {
         if (index >= approvedFoundersLength) return;
         if (index == approvedFoundersLength -1){
             approvedFoundersLength--;
         } else {
             for (uint256 i = index; i < approvedFoundersLength-1; i++){
                 approvedFounders[i] = approvedFounders[i+1];
             }
             approvedFoundersLength--;
         }
    }
    
    /**
    * @dev - add sale stage record
    * multisig (all founders)
    */     
    function addSaleStage( uint256 tokensVolume, uint256 timeFrom, uint256 timeTo, uint256 stagePrice, bool directBuy, uint256 maxPerWallet) external onlyFounder {
        require(timeFrom < timeTo,"11");
        
        if (saleStagesLength > 0){
            require(saleStages[saleStagesLength-1]._to < timeFrom,"12");
        }
        
        signFounder(ADD_SALE_STAGE, msg.sender, hash5uint256bool(tokensVolume,maxPerWallet,timeFrom,timeTo,stagePrice,directBuy));
        
        if (isAllFoundersSigned(ADD_SALE_STAGE)){
            _addSaleStage(tokensVolume,timeFrom,timeTo,stagePrice,directBuy, maxPerWallet);
            resetSignatures(ADD_SALE_STAGE);
        }    
    }
  
  
    function _addSaleStage( uint256 tokensVolume, uint256 timeFrom, uint256 timeTo, uint256 stagePrice, bool directBuy, uint256 maxPerWallet) internal {
        saleStages[saleStagesLength] = SaleStage(tokensVolume,timeFrom,timeTo,stagePrice,directBuy, maxPerWallet);
        saleStagesLength++;
    }
    
    
    function getEndOfAllSaleStages() public view returns(uint256 timeStamp){
        if (saleStagesLength > 0) {
            return saleStages[saleStagesLength-1]._to;    
        } else {
            return 0;
        }
    }
  
    /**
    * @dev - removes sale stage record, index in list is  a parameter
    * multisig (all founders)
    */   
    function removeSaleStageAtIndex(uint256 index) external onlyFounder {
        signFounder(REMOVE_SALE_STAGE, msg.sender, hash(index,0,address(0)));
        
        if (isAllFoundersSigned(REMOVE_SALE_STAGE)){
            _removeSaleStageAtIndex(index);
            resetSignatures(REMOVE_SALE_STAGE);
        }    
    }
  
    function _removeSaleStageAtIndex(uint256 index) internal {
         if (index >= saleStagesLength) return;
         if (index == saleStagesLength -1){
             saleStagesLength--;
         } else {
             for (uint256 i = index; i < saleStagesLength-1; i++){
                 saleStages[i] = saleStages[i+1];
             }
             saleStagesLength--;
         }
    } 
    
    /**
    * @dev - add withdraw schedule record
    * multisig (all founders)
    */     
    function addWithdrawSchedule( uint256 percentShare, uint256 timeFrom, uint256 timeTo) external onlyFounder {
        uint256 sales_end = getEndOfAllSaleStages();
        
        require(sales_end > 0 && sales_end < timeFrom,"10");
        require(timeFrom < timeTo,"11");
        if (withdrawSchedulesLength > 0){
            require(withdrawSchedules[withdrawSchedulesLength-1]._to < timeFrom,"12");
        }
        
        signFounder(ADD_WITHDRAW_SCHEDULE, msg.sender, hash4uint256bool(percentShare,timeFrom,timeTo,0,false));
        
        if (isAllFoundersSigned(ADD_WITHDRAW_SCHEDULE)){
            _addWithdrawSchedule(percentShare,timeFrom,timeTo);
            resetSignatures(ADD_WITHDRAW_SCHEDULE);
        }    
    }
  
  
    function _addWithdrawSchedule( uint256 percentShare, uint256 timeFrom, uint256 timeTo) internal {
        //check that sum of shares is not more than 100%
        uint256 total_share = percentShare;
        for (uint256 i = 0; i < withdrawSchedulesLength; i++){
            total_share = total_share + withdrawSchedules[i].share;
        }
        require(total_share <= PERC_SCALE,"9");
        
        withdrawSchedules[withdrawSchedulesLength] = WithdrawSchedule(percentShare,timeFrom,timeTo);
        withdrawSchedulesLength++;
    }
  
    /**
    * @dev - removes sale stage record, index in list is  a parameter
    * multisig (all founders)
    */   
    function removeWithdrawScheduleAtIndex(uint256 index) external onlyFounder {
        signFounder(REMOVE_WITHDRAW_SCHEDULE, msg.sender, hash(index,0,address(0)));
        
        if (isAllFoundersSigned(REMOVE_WITHDRAW_SCHEDULE)){
            _removeWithdrawScheduleAtIndex(index);
            resetSignatures(REMOVE_WITHDRAW_SCHEDULE);
        }    
    }
  
    function _removeWithdrawScheduleAtIndex(uint256 index) internal {
         if (index >= withdrawSchedulesLength) return;
         if (index == withdrawSchedulesLength -1){
             withdrawSchedulesLength--;
         } else {
             for (uint256 i = index; i < withdrawSchedulesLength-1; i++){
                 withdrawSchedules[i] = withdrawSchedules[i+1];
             }
             withdrawSchedulesLength--;
         }
    } 
   
    // *** end of contract data manipulation***
    
    
    // *** access control  ***
    function signFounder(uint8 funcCode, address founderAddr, bytes32 hashCode) internal {
        funcSign[funcCode].sign_status[founderAddr] = true;    
        funcSign[funcCode].sign_time[founderAddr] = block.timestamp; 
        funcSign[funcCode].sign_data_hash[founderAddr] = hashCode;  
    }
    
    function resetSignatures(uint8 funcCode) internal {
        for (uint256 i = 0; i < approvedFoundersLength; i++){
            funcSign[funcCode].sign_status[approvedFounders[i]] = false;
            funcSign[funcCode].sign_time[approvedFounders[i]] = 0;
            funcSign[funcCode].sign_data_hash[approvedFounders[i]] = 0;
        }
    }
    
    
    
    function isAllFoundersSigned(uint8 funcCode) public view returns(bool){
        bool status = true;
        bytes32 _hash = funcSign[funcCode].sign_data_hash[approvedFounders[0]];
        for (uint256 i = 0; i < approvedFoundersLength; i++){
            if (!funcSign[funcCode].sign_status[approvedFounders[i]] || 
                funcSign[funcCode].sign_time[approvedFounders[i]] < (block.timestamp - SIGN_TIMEOUT) || 
                funcSign[funcCode].sign_data_hash[approvedFounders[i]] != _hash){
                status = false;
                break;
            }
        }
        return status;
    }
    
    // *** end of access control  *** 
   
     // ***  withdraw  ***
    function emergencyWithdrawTokens(address toWallet, uint256 realAmountTokens) external nonReentrant onlyFounder {
        signFounder(EMERGENCY_WITHDRAW_TOKENS, msg.sender, hash(realAmountTokens,0,toWallet));
        
        if (isAllFoundersSigned(EMERGENCY_WITHDRAW_TOKENS)){
            _emergencyWithdrawTokens(toWallet, realAmountTokens);
            resetSignatures(EMERGENCY_WITHDRAW_TOKENS);
        }    
    }
    
    function _emergencyWithdrawTokens(address toWallet, uint256 realAmountTokens) internal {
            uint256 contractTokenBalance = token.balanceOf(ownAddress);
            
            require(contractTokenBalance >= realAmountTokens, "1"); 
           
            //ensure we revert in case of failure 
            try token.transfer(toWallet, realAmountTokens) returns (bool result) { 
                require(result,"2");
            } catch {
                require(false,"2");
               
            }
    }
    
    /**
    * @dev - withdraw ether
    */
    function withdraw(address payable sendTo, uint256 amountEther) external nonReentrant onlyFounder {
        signFounder(WITHDRAW, msg.sender, hash(amountEther,0,sendTo));
        
        if (isAllFoundersSigned(WITHDRAW)){
            _withdraw(sendTo, amountEther);
            resetSignatures(WITHDRAW);
        }    
    }
    
    function _withdraw(address payable sendTo, uint256 amountEther) internal {
        require(address(this).balance >= amountEther, "1");
        bool success = false;
        // ** send_to.transfer(amount);** 
        (success, ) = sendTo.call{value: amountEther}("");
        require(success, "2");
        // ** end **
    }
    
    // *** end of withdraw  ***
    
    // *** utilities ***
    function hash(uint256 num1, uint256 num2, address addr) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(num1, num2, addr));
    }
    
    function hash4uint256bool(uint256 num1, uint256 num2, uint256 num3,uint256 num4,bool bl) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(num1, num2, num3, num4, bl));
    }
    
    function hash5uint256bool(uint256 num1, uint256 num2, uint256 num3,uint256 num4,uint256 num5, bool bl) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(num1, num2, num3, num4, num5, bl));
    }
    // *** end of utilities ***
    
    // *** buy functions ***
    
    //number of tokens I can buy for amount (in wei), real tokens (i.e. 10**18)
    function calcCanBuy(uint256 forWeiAmount) external view returns(uint256){
        require(forWeiAmount > 0,"forWeiAmount should be > 0");
        (uint256 sell_price, ) = getPriceAndVolume();
        uint256 amountTobuy = forWeiAmount / sell_price;
        uint256 realAmountTobuy = amountTobuy * ADJ_CONSTANT; //tokens adjusted to real ones
        
        return realAmountTobuy; 
    }
    
    function getUserCrowdsaleBalance(uint256 saleStage, address userAddr) external view returns (uint256){
        return userCrowdsaleBalance[userAddr].crowdsale_stage_balance[saleStage];
    }
    
    function getPriceAndVolume() public view returns(uint256 price, uint256 volume){
        uint256 cur_time = block.timestamp;
        uint256 cur_sell_stage = aciveSaleStage;
       
        if (saleStages[cur_sell_stage]._from <= cur_time && saleStages[cur_sell_stage]._to >= cur_time){
            return (saleStages[cur_sell_stage].price, saleStages[cur_sell_stage].volume);
        } else {
            return (0,0);
        }
    }
    
    //utility function for frontend
    function getTime() external view returns(uint256){
        return block.timestamp;
    }
    
    /**
    * @dev user buys tokens - number of tokens calc. based on value sent
    */
    function buy() payable external nonReentrant {
        uint256 cur_sell_stage = aciveSaleStage;
         
        if (cur_sell_stage == 0 && useWhitelisting){
            require(whiteList[msg.sender],"13");
        }
        
        uint256 amountSent = msg.value; //in wei..
        require(amountSent > 0, "3");
        uint256 dexBalance = token.balanceOf(address(this));
        //calc number of tokens (real ones, not converted based on decimals..)
        (uint256 sell_price, uint256 volume) = getPriceAndVolume();
        require(sell_price > 0,"4");
        
        //adjust, for 0.5 tokens, for intstance
        sell_price = sell_price / 1e5;
        uint256 amountTobuy = amountSent / sell_price; //tokens as user see them
       
        uint256 realAmountTobuy = amountTobuy * ADJ_CONSTANT; //tokens adjusted to real ones
        //adjust back
        realAmountTobuy = realAmountTobuy / 1e5;
        
       
        require(realAmountTobuy > 0, "5");
        require(volume >= realAmountTobuy,"6");
        require(realAmountTobuy <= dexBalance, "1");
        
        uint256 forecast_user_balance = userCrowdsaleBalance[msg.sender].crowdsale_stage_balance[cur_sell_stage] + realAmountTobuy;
        
        require(forecast_user_balance <=  saleStages[cur_sell_stage].max_per_wallet, "15"); 
        
        if (saleStages[cur_sell_stage].direct_buy) {
            try token.transfer(msg.sender, realAmountTobuy) returns (bool result) { //ensure we revert in case of failure
                //emit Bought(realAmountTobuy, msg.sender);
                 require(result,"2");
                 saleStages[cur_sell_stage].volume = saleStages[cur_sell_stage].volume - realAmountTobuy;
                 userCrowdsaleBalance[msg.sender].crowdsale_stage_balance[cur_sell_stage] = forecast_user_balance;
            } catch {
                require(false,"2");
            }
        } else {
            investorsBalances[msg.sender] = investorsBalances[msg.sender] + realAmountTobuy;
            initInvestorsBalances[msg.sender] = investorsBalances[msg.sender];
            saleStages[cur_sell_stage].volume = saleStages[cur_sell_stage].volume - realAmountTobuy;
            userCrowdsaleBalance[msg.sender].crowdsale_stage_balance[cur_sell_stage] = forecast_user_balance;
        }
        
    }
    
    //example:
    //total users tokens 100
    //timeslot 1 - share 10%
    //timeslot 2 - share 50%
    //timeslot 3 - share 40%
    //slot 1 - withdrawn 10 (10% from 100), left 90
    //slot 2 - withdrawn 50 (50% from 100). left 50
    //slot 3 - withdrawn 40 (40% from 100), left 0
    //after all slots - withdrawn what left (can be, due to rounding)
    function getMyTokens()  external nonReentrant {
       
        (uint256 inv_withdr_balance, uint256 active_schedule_slot) = getInvestorWithdrawableBalance(msg.sender);
    
        
        if (inv_withdr_balance > 0) {
            if (active_schedule_slot != NO_SCHEDULE_SLOT){
                if (!userScheduleWithdrawStatus[msg.sender].schedule_withdraw_status[active_schedule_slot]){
                    try token.transfer(msg.sender, inv_withdr_balance) returns (bool result) { //ensure we revert in case of failure
                        require(result,"2");
                        //emit Bought(realAmountTobuy, msg.sender);
                        investorsBalances[msg.sender] = investorsBalances[msg.sender] - inv_withdr_balance;
                        //specify that user withdrawn already in this slot
                        
                        userScheduleWithdrawStatus[msg.sender].schedule_withdraw_status[active_schedule_slot] = true;
                        
                    } catch {
                        require(false,"2");
                    }
                }
            } else { //NO_SCHEDULE_SLOT - just withdraw
                try token.transfer(msg.sender, inv_withdr_balance) returns(bool result) { //ensure we revert in case of failure
                        require(result,"2");
                        //emit Bought(realAmountTobuy, msg.sender);
                        investorsBalances[msg.sender] = investorsBalances[msg.sender] - inv_withdr_balance;
                        //specify that user withdrawn already in this slot
                        
                } catch {
                    require(false,"2");
                }
            }
            
            
        } else {
            //
        }
        
    }
   //|| !userScheduleWithdrawStatus[msg.sender].schedule_withdraw_status[active_schedule_slot]
    
    
    function tokensQntUserCanWithdrawNow(address wallet)  external view returns (uint256) {
       
        (uint256 inv_withdr_balance, uint256 active_schedule_slot) = getInvestorWithdrawableBalance(wallet);
    
        
        if (inv_withdr_balance > 0) {
            if (active_schedule_slot != NO_SCHEDULE_SLOT){
                if (!userScheduleWithdrawStatus[wallet].schedule_withdraw_status[active_schedule_slot]){
                    return inv_withdr_balance; 
                } else {
                    return 0;
                }
            } else { //NO_SCHEDULE_SLOT 
                return inv_withdr_balance;
            }
            
            
        } else {
            return 0;
        }
        
    }
    
    function getInvestorBalance(address wallet) external view returns(uint256){
        return investorsBalances[wallet];
    }
    
    function getInvestorWithdrawableBalance(address wallet) internal view returns(uint256 investorBalance, uint256 scheduleSlot){
        uint256 inv_balance = investorsBalances[wallet];
        uint256 cur_time = block.timestamp;
        
        //if no schedules - whole balance can be withdrawn
        if (withdrawSchedulesLength == 0) return (inv_balance, NO_SCHEDULE_SLOT);
        
        //if current time > than last schedule record (_to) - whole balance can be withdrawn
        if (cur_time > withdrawSchedules[withdrawSchedulesLength-1]._to) return (inv_balance, NO_SCHEDULE_SLOT);
        
        //if current time fits into specific schedule - balance based on this schedule can be withdrawn
        for (uint256 i = 0; i < withdrawSchedulesLength; i++){
            if (withdrawSchedules[i]._from <= cur_time && withdrawSchedules[i]._to >= cur_time){
                inv_balance = initInvestorsBalances[wallet];
                inv_balance = inv_balance * withdrawSchedules[i].share;
                inv_balance = inv_balance / PERC_SCALE;
                if (inv_balance > investorsBalances[wallet]) inv_balance = investorsBalances[wallet];
                return (inv_balance, i);
            }    
        }
        
        //if we get there - we are out of schedule slots (i.e. early or one slot ended & another not started)
        return (0, NO_SCHEDULE_SLOT);
    }
    
    function getActiveScheduleSlot() external view returns(uint256 scheduleSlot){
        uint256 cur_time = block.timestamp;
        //if no schedules 
        if (withdrawSchedulesLength == 0) return NO_SCHEDULE_SLOT;
        
        //if current time > than last schedule record (_to) - whole balance can be withdrawn
        if (cur_time > withdrawSchedules[withdrawSchedulesLength-1]._to) return NO_SCHEDULE_SLOT;
        
        //if current time fits into specific schedule - balance based on this schedule can be withdrawn
        for (uint256 i = 0; i < withdrawSchedulesLength; i++){
            if (withdrawSchedules[i]._from <= cur_time && withdrawSchedules[i]._to >= cur_time){
                return  i;
            }    
        }
        
        //if we get there - first schedule did not start
        return NO_SCHEDULE_SLOT;
    }
    
  

    
    
    // *** end of buy functions ***
    
    
    
    // *** contract interfaces ***
     
    
    receive() external payable {
        require(msg.value == 0,"8"); //do not accept ether 
    }
    
    // *** end of contract interfaces ***

    
}