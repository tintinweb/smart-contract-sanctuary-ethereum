/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Test {
     using SafeMath for uint256;
    
     struct Pair {
        IBEP20 pairedWithAddress;
        uint256 liveRate;
        uint256 buyFee;
        uint256 sellFee;
        uint256 incPricePer;
        uint256 decPricePer;
        uint256 minBuy;
        uint256 minSell;
        uint256 maxBuy;
        uint256 maxSell;
        bool    buyOn;
        bool    sellOn;
    }

    struct Staking {
        uint256 programId;
        uint256 stakingDate;
        uint256 staking;
        uint256 lastWithdrawalDate;
        uint256 currentRewards;
        bool    isExpired;
        uint256 genRewards;
        uint256 stakingToken;
        bool    isAddedStaked;
    }

    struct Program {
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
        uint256 maxDailyInterest;
    }
  
     
    struct User {
        uint id;
        address referrer;
        uint256 programCount;
        uint256 totalStakingBusd;
        uint256 totalStakingToken;
        uint256 airdropReward;
        mapping(uint256 => Staking) programs;
    }
    
    mapping(string => Pair)  pairs;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    
    Program[] private stakingPrograms_;
    
    uint256 private constant INTEREST_CYCLE = 1 days;
    uint256 maxImpact;
    uint256 public lastUserId = 2;
    
    uint256 public  total_staking_token = 0;
    uint256 public  total_staking_busd = 0;
        
    uint256 public  total_withdraw_token = 0;
    uint256 public  total_withdraw_busd = 0;
    
    uint256 public  total_token_buy = 0;
    uint256 public  total_token_sell = 0;
	

	bool   public  stakingOn = true;
	bool   public  airdropOn = true;
	

	
	uint256 public  priceIncUpdateGap = 3000*1e18;
	uint256 public  priceDecUpdateGap = 7000*1e18;
	
    address public owner;
 
    
    event Registration(address indexed user, address indexed referrer, uint256 indexed userId, uint256 referrerId, uint8 position);
    event CycleStarted(address indexed user,uint256 stakeID, uint256 walletUsedBusd, uint256 totalToken);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate, uint busd_amount);
    event onWithdraw(address  _user, uint256 withdrawalAmountToken);
    event ReferralReward(address  _user,address _from,uint256 reward);
    IBEP20 private graceToken; 
    IBEP20 private busdToken; 

    constructor(address ownerAddress, IBEP20 _busdToken, IBEP20 _graceToken)  
    {
        owner = ownerAddress;
        
        graceToken = _graceToken;
        busdToken = _busdToken;
        
        stakingPrograms_.push(Program(110,365*24*60*60,110));  //  365 Days
        stakingPrograms_.push(Program(120,365*24*60*60,120));
        stakingPrograms_.push(Program(130,365*24*60*60,130));
        stakingPrograms_.push(Program(140,365*24*60*60,140));
                
        users[ownerAddress].id= 1;
        users[ownerAddress].referrer= address(0);
        users[ownerAddress].programCount= uint(0);
        users[ownerAddress].totalStakingBusd= uint(0);
        users[ownerAddress].totalStakingToken= uint(0);
        users[ownerAddress].airdropReward= uint(0);
        
        
        idToAddress[1] = ownerAddress;
    } 
    

    function makePairs(string memory _name, IBEP20 _token, uint256 _liveRate, uint256 _buyFee, uint256 _sellFee, uint256 _incPricePer, uint256 _decPricePer, uint256 _minBuy, uint256 _minSell, uint256 _maxBuy, uint256 _maxSell) public {
        require(msg.sender==owner);
        pairs[_name].pairedWithAddress=_token;
        pairs[_name].liveRate=_liveRate;
        pairs[_name].buyFee=_buyFee;
        pairs[_name].sellFee=_sellFee;
        pairs[_name].incPricePer=_incPricePer;
        pairs[_name].decPricePer=_decPricePer;
        pairs[_name].minBuy=_minBuy;
        pairs[_name].minSell=_minSell;
        pairs[_name].maxBuy=_maxBuy;
        pairs[_name].maxSell=_maxSell;
        pairs[_name].buyOn=true;
        pairs[_name].sellOn=true;
    }

    function getPairs(string memory _name) public view returns(Pair memory){
            return pairs[_name];
    }

    function setMaxImpact(uint256 _impact) public {
            maxImpact=_impact;
    }
    


    function calcBuy(string memory _coin, uint256 amount) public view returns(uint256 _newRate, uint256 _priceImpact, uint256 _liquidityFee, uint256 _amount, uint256 _recieved_amt, uint256 _min_recieved_amt)
	{
           uint256 priceImpact=(amount.div(pairs[_coin].minBuy)).mul(pairs[_coin].incPricePer);
           
           if(priceImpact>maxImpact)
              priceImpact=maxImpact;

           uint256 newRate=pairs[_coin].liveRate.add((pairs[_coin].liveRate.mul(priceImpact)).div(1e20)); 
           uint256 liquidityFee=(amount.mul(pairs[_coin].buyFee)).div(1e20); 
                 
           uint256 recieved_amt=(amount.mul(1e18)).div(newRate);
           amount=amount-liquidityFee; 
           uint256 min_recieved_amt=(amount.mul(1e18)).div(newRate);
           return(newRate, priceImpact, liquidityFee, amount, recieved_amt, min_recieved_amt);        				
	 }


      function calcSell(string memory _coin, uint256 amount) public view returns(uint256 _newRate, uint256 _priceImpact, uint256 _liquidityFee, uint256 _amount, uint256 _recieved_amt, uint256 _min_recieved_amt)
	{
           uint256 priceImpact=(amount.div(pairs[_coin].minSell)).mul(pairs[_coin].decPricePer);
           
           if(priceImpact>maxImpact)
              priceImpact=maxImpact;

           uint256 newRate=pairs[_coin].liveRate.sub((pairs[_coin].liveRate.mul(priceImpact)).div(1e20)); 
           uint256 liquidityFee=(amount.mul(pairs[_coin].sellFee)).div(1e20); 
                 
           uint256 recieved_amt=(amount.mul(newRate)).div(1e18);
           amount=amount-liquidityFee; 
           uint256 min_recieved_amt=(amount.mul(newRate)).div(1e18);
           return(newRate,priceImpact,liquidityFee,amount,recieved_amt,min_recieved_amt);        				
	 }

    function swapBuy(string memory _coin, uint256 amount, address referrer, uint8 position) public payable
	{
        require(!isContract(msg.sender),"Can not be contract!");
        require(amount>=pairs[_coin].minBuy,"Minimum Quantity Error!");
        require(amount<=pairs[_coin].maxBuy,"Maximum Quantity Error!");

        uint256 priceImpact=(amount.div(pairs[_coin].minBuy)).mul(pairs[_coin].incPricePer);
           
           if(priceImpact>maxImpact)
              priceImpact=maxImpact;

           uint256 newRate=pairs[_coin].liveRate.add((pairs[_coin].liveRate.mul(priceImpact)).div(1e20)); 
           uint256 liquidityFee=(amount.mul(pairs[_coin].buyFee)).div(1e20); 
           amount=amount-liquidityFee; 
           uint256 min_recieved_amt=(amount.mul(1e18)).div(newRate);
           
           pairs[_coin].liveRate=newRate;
           pairs[_coin].pairedWithAddress.transferFrom(msg.sender,address(this),(amount+liquidityFee));	
           graceToken.transfer(msg.sender,min_recieved_amt);

           start_staking(amount, min_recieved_amt, referrer, position);			
	 }


     function swapSell(string memory _coin, uint256 amount) public payable
	{
        require(!isContract(msg.sender),"Can not be contract!");
        require(amount>=pairs[_coin].minSell,"Minimum Quantity Error!");
        require(amount<=pairs[_coin].maxSell,"Maximum Quantity Error!");

        uint256 priceImpact=(amount.div(pairs[_coin].minSell)).mul(pairs[_coin].decPricePer);
           
           if(priceImpact>maxImpact)
              priceImpact=maxImpact;

           uint256 newRate=pairs[_coin].liveRate.sub((pairs[_coin].liveRate.mul(priceImpact)).div(1e20)); 
           uint256 liquidityFee=(amount.mul(pairs[_coin].sellFee)).div(1e20); 
           amount=amount-liquidityFee; 
           uint256 min_recieved_amt=(amount.mul(newRate)).div(1e18);
           
           pairs[_coin].liveRate=newRate;
           graceToken.transferFrom(msg.sender,address(this),(amount+liquidityFee));	
           pairs[_coin].pairedWithAddress.transfer(msg.sender,min_recieved_amt);				
	 }


    function withdrawBalance(uint256 amt,uint8 _type) public 
    {
        require(msg.sender == owner, "onlyOwner");
        if(_type==1)
        payable(msg.sender).transfer(amt);
        else if(_type==2)
        busdToken.transfer(msg.sender,amt);
        else
        graceToken.transfer(msg.sender,amt);
    }
    
      function multisend(address payable[]  memory  _contributors, uint256[] memory _balances) public payable 
     {
        require(msg.sender==owner,"Only Owner");
        uint256 i = 0;
        for (i; i < _contributors.length; i++) 
        {
            graceToken.transfer(_contributors[i],_balances[i]);
        }
    }
    
  
    function registration(address userAddress, address referrerAddress, uint8 position) private 
    {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        
        require(size == 0, "cannot be a contract");
        
        
            users[userAddress].id= lastUserId;
            users[userAddress].referrer= referrerAddress;
            users[userAddress].programCount= 0;
            users[userAddress].totalStakingBusd= 0;
            users[userAddress].totalStakingToken= 0;
            users[userAddress].airdropReward= 0;
        
        
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id,position);
    }
    
    // Staking Process
    
    function start_staking(uint256 walletUsedBusd, uint256 walletUsedToken, address referrer, uint8 position) private 
    {
        require(stakingOn,"Staking Stopped.");
        require(position==1 || position==2,"Invalid Position.");
        if(!isUserExists(msg.sender))
	    {
	        registration(msg.sender, referrer,position);   
	    }
        require(isUserExists(msg.sender), "user not exists");

        require(walletUsedBusd>=25*1e18, "Minimum 25 Dollar");
        
        uint256 programCount = users[msg.sender].programCount;

        uint8 _programId=getProgramId(users[msg.sender].totalStakingBusd+walletUsedBusd);
        users[msg.sender].programs[programCount].programId = _programId;
        users[msg.sender].programs[programCount].stakingDate = block.timestamp;
        users[msg.sender].programs[programCount].lastWithdrawalDate = block.timestamp;
        users[msg.sender].programs[programCount].staking = walletUsedBusd;
        users[msg.sender].programs[programCount].currentRewards = 0;
        users[msg.sender].programs[programCount].genRewards = 0;
        users[msg.sender].programs[programCount].isExpired = false;
        users[msg.sender].programs[programCount].stakingToken = walletUsedToken;
        users[msg.sender].programCount = users[msg.sender].programCount.add(1);
        
        users[msg.sender].totalStakingToken = users[msg.sender].totalStakingToken.add(walletUsedToken);
        users[msg.sender].totalStakingBusd = users[msg.sender].totalStakingBusd.add(walletUsedBusd);
        
        address referrerAddress=users[msg.sender].referrer;
        
        if(msg.sender!=owner)
        {
            uint256 refBonus=(walletUsedToken.mul(10)).div(100);
            graceToken.transfer(referrerAddress,refBonus);
            emit ReferralReward(referrerAddress,msg.sender,refBonus);
        }
	    	
	    emit CycleStarted(msg.sender,users[msg.sender].programCount, walletUsedBusd,walletUsedToken);
    }
 
    
    function withdraw() public payable 
	{
        require(msg.value == 0, "withdrawal doesn't allow to transfer bnb simultaneously");
        uint256 uid = users[msg.sender].id;
        require(uid != 0, "Can not withdraw because no any stakings");
        uint256 withdrawalAmount=0;
        for (uint256 i = 0; i < users[msg.sender].programCount; i++) 
        {
            if (users[msg.sender].programs[i].isExpired) {
                users[msg.sender].programs[i].genRewards=0;
                continue;
            }

            Program storage program = stakingPrograms_[users[msg.sender].programs[i].programId];

            bool isExpired = false;
            bool isAddedStaked = false;
            uint256 withdrawalDate = block.timestamp;
            if(program.term > 0) {
                uint256 endTime = users[msg.sender].programs[i].stakingDate.add(program.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                    isAddedStaked=true;
                    
                    if(users[msg.sender].programs[i].programId>=0 && users[msg.sender].programs[i].programId<4)
                    {
                        withdrawalAmount += users[msg.sender].programs[i].stakingToken;
                    }
                }
            }
            
            uint256 stakingPercent = stakingPrograms_[users[msg.sender].programs[i].programId].dailyInterest;
            
            uint256 amount = _calculateRewards(users[msg.sender].programs[i].stakingToken , stakingPercent , withdrawalDate , users[msg.sender].programs[i].lastWithdrawalDate , stakingPercent);

            withdrawalAmount += amount;
            withdrawalAmount += users[msg.sender].programs[i].genRewards;
            
            users[msg.sender].programs[i].lastWithdrawalDate = withdrawalDate;
            users[msg.sender].programs[i].isExpired = isExpired;
            users[msg.sender].programs[i].isAddedStaked = isAddedStaked;
            users[msg.sender].programs[i].currentRewards += amount;
            users[msg.sender].programs[i].genRewards=0;
        }
        
        if(withdrawalAmount>0)
        {
            graceToken.transfer(msg.sender,withdrawalAmount);
            total_withdraw_token=total_withdraw_token+(withdrawalAmount);
            emit onWithdraw(msg.sender, withdrawalAmount);
        }
    }
    
    
    function updateRewards() private
	{
        require(msg.value == 0, "withdrawal doesn't allow to transfer bnb simultaneously");
        uint256 uid = users[msg.sender].id;
        require(uid != 0, "Can not withdraw because no any stakings");
        
        for (uint256 i = 0; i < users[msg.sender].programCount; i++) 
        {
            if (users[msg.sender].programs[i].isExpired) {
                continue;
            }

            Program storage program = stakingPrograms_[users[msg.sender].programs[i].programId];

            bool isExpired = false;
            bool isAddedStaked = false;
            uint256 withdrawalDate = block.timestamp;
            if (program.term > 0) {
                uint256 endTime = users[msg.sender].programs[i].stakingDate.add(program.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                }
            }
            
            uint256 stakingPercent=stakingPrograms_[users[msg.sender].programs[i].programId].dailyInterest;
            
            uint256 amount = _calculateRewards(users[msg.sender].programs[i].stakingToken , stakingPercent , withdrawalDate , users[msg.sender].programs[i].lastWithdrawalDate , stakingPercent);

            users[msg.sender].programs[i].lastWithdrawalDate = withdrawalDate;
            users[msg.sender].programs[i].isExpired = isExpired;
            users[msg.sender].programs[i].isAddedStaked = isAddedStaked;
            users[msg.sender].programs[i].currentRewards += amount;
            users[msg.sender].programs[i].genRewards += amount;
        }
    }
    
    function getStakingProgramByUID(address _user) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory,uint256[] memory, bool[] memory, bool[] memory) 
    {
       
        User storage staker = users[_user];
        uint256[] memory stakingDates = new  uint256[](staker.programCount);
        uint256[] memory stakings = new  uint256[](staker.programCount);
        uint256[] memory currentRewards = new  uint256[](staker.programCount);
        bool[] memory isExpireds = new  bool[](staker.programCount);
        uint256[] memory newRewards = new uint256[](staker.programCount);
        uint256[] memory genRewards = new uint256[](staker.programCount);
        bool[] memory isAddedStakeds = new bool[](staker.programCount);

        for(uint256 i=0; i<staker.programCount; i++){
            require(staker.programs[i].stakingDate!=0,"wrong staking date");
            currentRewards[i] = staker.programs[i].currentRewards;
            genRewards[i] = staker.programs[i].genRewards;
            isAddedStakeds[i] = staker.programs[i].isAddedStaked;
            stakingDates[i] = staker.programs[i].stakingDate;
            stakings[i] = staker.programs[i].stakingToken;
    
            uint256 stakingPercent=stakingPrograms_[staker.programs[i].programId].dailyInterest;
            
            if (staker.programs[i].isExpired) {
                isExpireds[i] = true;
                newRewards[i] = 0;
                
            } else {
                isExpireds[i] = false;
                if (stakingPrograms_[staker.programs[i].programId].term > 0) {
                    if (block.timestamp >= staker.programs[i].stakingDate.add(stakingPrograms_[staker.programs[i].programId].term)) {
                        newRewards[i] = _calculateRewards(staker.programs[i].stakingToken, stakingPercent, staker.programs[i].stakingDate.add(stakingPrograms_[staker.programs[i].programId].term), staker.programs[i].lastWithdrawalDate, stakingPercent);
                        isExpireds[i] = true;
                       
                    }
                    else{
                        newRewards[i] = _calculateRewards(staker.programs[i].stakingToken, stakingPercent, block.timestamp, staker.programs[i].lastWithdrawalDate, stakingPercent);
                      
                    }
                } else {
                    newRewards[i] = _calculateRewards(staker.programs[i].stakingToken, stakingPercent, block.timestamp, staker.programs[i].lastWithdrawalDate, stakingPercent);
                 
                }
            }
        }

        return
        (
        stakingDates,
        stakings,
        currentRewards,
        newRewards,
        genRewards,
        isExpireds,
        isAddedStakeds
        );
    }
    
    function getStakingToken(address _user) public view returns (uint256[] memory) 
    {
       
        User storage staker = users[_user];
        uint256[] memory stakings = new  uint256[](staker.programCount);

        for(uint256 i=0; i<staker.programCount; i++){
            require(staker.programs[i].stakingDate!=0,"wrong staking date");
            stakings[i] = staker.programs[i].stakingToken;
        }

        return
        (
            stakings
        );
    }

	function _calculateRewards(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start , uint256 _maxDailyInterest) private pure returns (uint256) {

        uint256 numberOfDays =  (_now - _start) / INTEREST_CYCLE ;
        uint256 result = 0;
        uint256 index = 0;
        if(numberOfDays > 0){
          uint256 secondsLeft = (_now - _start);
           for (index; index < numberOfDays; index++) {
               if(_dailyInterestRate + index <= _maxDailyInterest ){
                   secondsLeft -= INTEREST_CYCLE;
                     result += (_amount * (_dailyInterestRate + index) / 100000 * INTEREST_CYCLE) / (24*60*60);
               }
               else
               {
                 break;
               }
            }

            result += (((_amount.mul(_dailyInterestRate)).div(100000)) * secondsLeft) / (24*60*60);

            return result;

        }else{
            return (_amount * _dailyInterestRate / 100000 * (_now - _start)) / (24*60*60);
        }

    }
	
	function getProgramId(uint256 _amount) public pure returns(uint8)
	{	    
	    if(_amount>=25000*1e18)
	    return 3;
	    else if(_amount>=5000*1e18)
	    return 2;
	    else if(_amount>=500*1e18)
	    return 1;
	    else
	    return 0;
	}

 
	
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }   
   
  
    
    function sendAirdropToken(address _user,uint256 token) public payable
    {
        require(msg.sender==owner,"Only Owner.");
        require(isUserExists(_user),"User Not Exist.");
        graceToken.transfer(_user,token*1e18);
	    users[_user].airdropReward=users[_user].airdropReward+token;
    }
  
    
    
    function switchStaking(uint8 _type) public payable
    {
        require(msg.sender==owner,"Only Owner");
            if(_type==1)
            stakingOn=true;
            else
            stakingOn=false;
    }
       
    
    function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}