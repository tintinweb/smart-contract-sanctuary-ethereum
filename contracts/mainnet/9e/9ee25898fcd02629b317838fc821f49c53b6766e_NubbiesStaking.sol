/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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





pragma solidity ^0.8.0;


interface IGenesis0 {
   
function transferFrom( address from,   address to, uint256 tokenId) external;
function ownerOf( uint _tokenid) external view returns (address);
}

interface IGenesis2 {
   
function transferFrom( address from,   address to, uint256 tokenId) external;
function ownerOf( uint _tokenid) external view returns (address);
}
interface IFrenzBoostPlatinum {
   
function transferFrom( address from,   address to, uint256 tokenId) external;
function ownerOf( uint _tokenid) external view returns (address);
}
interface IFrenzBoostGold {
   
function transferFrom( address from,   address to, uint256 tokenId) external;
function ownerOf( uint _tokenid) external view returns (address);
}
interface ISpaceship {
   
function transferFrom( address from,   address to, uint256 tokenId) external;
function ownerOf( uint _tokenid) external view returns (address);
}






contract NubbiesStaking is Ownable{
     

  
  

   uint16 public totalNFTStaked ;
  
uint16 public totalgen0NFTStaked ;
uint16 public totalgen2NFTStaked ;
uint16 public totalrfPremiumNFTStaked ;
uint16 public totalrfUnleadedNFTStaked ;
uint16 public totalspaceshipNFTStaked ;
   
   struct stakeOwner{
     
     Gen0staker gen0;
     Gen2staker gen2;
     FBPlatinumStaker rfpremium;
     FBGoldStaker rfunleaded;
     Spaceshipstaker spaceship;
   }
   struct Gen0staker{
     
      uint16[] tokens ;  
      uint64 rewardStartTime ;
      uint rewards;
   }
   struct Gen2staker{
     
      uint16[] tokens ;  
      uint64 rewardStartTime ;
      uint rewards;
   }
    struct FBPlatinumStaker{
     
      uint16[] tokens ;  
      uint64 rewardStartTime ;
      uint rewards;
   }
    struct FBGoldStaker{
     
      uint16[] tokens ;  
      uint64 rewardStartTime ;
      uint rewards;
   }
   struct Spaceshipstaker{
     
      uint16[] tokens ;  
      uint64 rewardStartTime ;
      uint rewards;
   }


    
  
   //stakedNft []staked;
   mapping(address => stakeOwner) public stakeOwners ;
   
 
  // uint startTime = block.timestamp;
   
   uint public dailyGen0Reward = 4 ether ; 
   uint public dailyGen2Reward = 2 ether;
   uint public dailyspaceshipReward = 1  ether;
   uint public dailyPlatinumFrenzBoost  = 4 ether;
   uint public dailyGoldFrenzBoost  = 2 ether;
  
  



   
address public gen0 = 0x091d8E039d532Fd02d7AcC593043acFf05839927; 

address public gen2;
address public spaceshipaddress;
address public PlatinumFrenzBoost;
address public GoldFrenzBoost;


IGenesis0 genesis0= IGenesis0(gen0) ;
IGenesis2 genesis2 ;
IFrenzBoostPlatinum RFPremium ;
IFrenzBoostGold RFUnleaded ;
 ISpaceship spaceship;


 constructor() {
  
 }

   /// ---------- Setting info --------------///

 function setGen0Address(address contractAddr) external onlyOwner {
		gen0 = contractAddr;
       genesis0 = IGenesis0(gen0);
	}  
     function setGen2Address(address contractAddr) external onlyOwner {
		gen2 = contractAddr;
        genesis2 = IGenesis2(gen2);
	} 
     function setSpaceShipAddress(address contractAddr) external onlyOwner {
		spaceshipaddress = contractAddr;
       spaceship = ISpaceship(spaceshipaddress);
	} 
     function setFrenzBoostPlatinumAddress(address contractAddr) external onlyOwner {
		PlatinumFrenzBoost = contractAddr;
        RFPremium = IFrenzBoostPlatinum(PlatinumFrenzBoost);

	}  
     function setFrenzBoostGoldAddress(address contractAddr) external onlyOwner {
		GoldFrenzBoost= contractAddr;
        RFUnleaded = IFrenzBoostGold(GoldFrenzBoost);
	}  
    
  function setdailyGen0Reward (uint _reward) external onlyOwner{
        
     dailyGen0Reward= _reward;
     delete _reward;
  }
  function setdailyGen2Reward (uint _reward) external onlyOwner{
     dailyGen2Reward= _reward;
     delete _reward;
  }
  function setdailyspaceshipReward  (uint _reward) external onlyOwner{
     dailyspaceshipReward = _reward;
     delete _reward;
  }
  function setdailyRFPremiumReward  (uint _reward) external onlyOwner{
     dailyPlatinumFrenzBoost  = _reward;
     delete _reward;
  }
  function setdailyRFUnleadedReward (uint _reward) external onlyOwner{
     dailyGoldFrenzBoost  = _reward;
     delete _reward;
  }
  // ---------- Setting info --------------///

 // ---------- GEN0 --------------///
 function stakeGen0(uint16 [] calldata data) external{
    uint16 _number= uint16(data.length );
    require(_number > 0 , "Invalid Number");
   
  

    uint16 tokens=uint16(stakeOwners[msg.sender].gen0.tokens.length);
    
    if(tokens > 0){
      stakeOwners[ msg.sender].gen0.rewards = calculateGen0Reward(msg.sender);
    }
 
      
      stakeOwners[ msg.sender].gen0.rewardStartTime = uint64(block.timestamp);
      totalNFTStaked += _number;
      totalgen0NFTStaked += _number;
      storeGen0Tokens(_number , data);
    
      for(uint16 i ; i< _number ; i++)
    {  
       require(genesis0.ownerOf(data[i]) == msg.sender, "Not the owner");
    genesis0.transferFrom( msg.sender, address(this),data[i]);
    }
    delete tokens;

 }

function calculateGen0Reward(address _address) public view returns (uint){
   
    
    return  stakeOwners[ _address].gen0.rewards + ( getGen0StakeTime(_address)  * stakeOwners[_address].gen0.tokens.length * (dailyGen0Reward/86400));
  
 }

  
 


 
 function storeGen0Tokens(uint16 _number , uint16 [] calldata data) internal {
    uint16 tokenID;
    for(uint16 i; i< _number ; i++)
    {
     tokenID=data[i];
      stakeOwners[ msg.sender].gen0.tokens.push(tokenID);
    }

 delete tokenID;
 }


  function getFulltokenOfGen0(address _address) external view returns(uint16 [] memory)
 {
    return stakeOwners[_address].gen0.tokens;
   
 }

 

  function checkIfGen0Staked(address _address) public view returns (bool){
     if(stakeOwners[_address].gen0.tokens.length > 0){
     return  true;
     }
     else
      return false;
  }
 
  


 
   

   
   


 
  

 

  
 function getGen0StakeTime(address _address) public view returns(uint64){
     uint64 endTime = uint64(block.timestamp);
    return endTime - stakeOwners[_address].gen0.rewardStartTime;
 }

 
 



 
 

 function claimGen0Reward() external {
  
    require(stakeOwners[ msg.sender].gen0.tokens.length > 0 , "You have not staked any NFTs"); 
   
  
    stakeOwners[ msg.sender].gen0.rewardStartTime = uint64(block.timestamp);
   stakeOwners[ msg.sender].gen0.rewards=0;


 }

function calculateRewardforUnstakingGen0(uint16 [] calldata data , address _address) public  view returns (uint) {
 uint totalreward = calculateGen0Reward(_address);
 uint unstakeReward = totalreward/ stakeOwners[_address].gen0.tokens.length ;
    unstakeReward = unstakeReward * data.length;
    return unstakeReward;
}

  function getRewardforUnstakingGen0(uint16 tokens) internal  {

    uint totalreward = calculateGen0Reward(msg.sender);
    uint unstakeReward = totalreward/ stakeOwners[msg.sender].gen0.tokens.length ;
    unstakeReward = unstakeReward * tokens;
    stakeOwners[ msg.sender].gen0.rewards= totalreward - unstakeReward;
    
   
    
  
 
    //stardust.mint( msg.sender , unstakeReward);
 
    stakeOwners[ msg.sender].gen0.rewardStartTime = uint64(block.timestamp);

 }


 function unstakeGen0(uint16 [] calldata data) external {
    require(stakeOwners[ msg.sender].gen0.tokens.length> 0, "You have not staked any NFTs"); 
    uint16 tokens =uint16(data.length);
    require(tokens > 0, "You have not selected any NFT to unstake"); 
    
    uint16 tokenID;
    for(uint16 i; i<tokens; i++)
    {
    tokenID=data[i];
    genesis0.transferFrom(address(this),msg.sender,tokenID);
    removeGen0Token(tokenID);
    }
   
   totalNFTStaked -= tokens;
   totalgen0NFTStaked -= tokens;

    
 }
 


   function removeGen0Token(uint16 token) internal {
   uint x=   stakeOwners[ msg.sender].gen0.tokens.length  ;
   if (token == stakeOwners[ msg.sender].gen0.tokens[x-1])
   {
        stakeOwners[ msg.sender].gen0.tokens.pop();
   }
   else{
    for (uint i ; i < stakeOwners[ msg.sender].gen0.tokens.length ; i ++)
    {

      if(token == stakeOwners[ msg.sender].gen0.tokens[i] )
      {
        uint16 temp = stakeOwners[ msg.sender].gen0.tokens[x-1];
        stakeOwners[ msg.sender].gen0.tokens[x-1]   =  stakeOwners[ msg.sender].gen0.tokens[i];
        stakeOwners[ msg.sender].gen0.tokens[i] = temp;
        stakeOwners[ msg.sender].gen0.tokens.pop();
      }
    }
   }
   }
// ---------- GEN0 --------------///

	
 // ---------- GEN2 --------------///
 function stakeGen2(uint16 [] calldata data) external{
    uint16 _number= uint16(data.length );
    require(_number > 0 , "Invalid Number");
   
  

    uint16 tokens=uint16(stakeOwners[msg.sender].gen2.tokens.length);
    
    if(tokens > 0){
      stakeOwners[ msg.sender].gen2.rewards = calculateGen2Reward(msg.sender);
    }
 
      
      stakeOwners[ msg.sender].gen2.rewardStartTime = uint64(block.timestamp);
      totalNFTStaked += _number;
      totalgen2NFTStaked += _number;
      storeGen2Tokens(_number , data);
    
      for(uint16 i ; i< _number ; i++)
    {  
       require(genesis2.ownerOf(data[i]) == msg.sender, "Not the owner");
    genesis2.transferFrom( msg.sender, address(this),data[i]);
    }
    delete tokens;

 }

function calculateGen2Reward(address _address) public view returns (uint){
   
    
    return  stakeOwners[ _address].gen2.rewards + ( getGen2StakeTime(_address)  * stakeOwners[_address].gen2.tokens.length * (dailyGen2Reward/86400));
  
 }

  
 


 
 function storeGen2Tokens(uint16 _number , uint16 [] calldata data) internal {
    uint16 tokenID;
    for(uint16 i; i< _number ; i++)
    {
     tokenID=data[i];
      stakeOwners[ msg.sender].gen2.tokens.push(tokenID);
    }

 delete tokenID;
 }


  function getFulltokenOfGen2(address _address) external view returns(uint16 [] memory)
 {
    return stakeOwners[_address].gen2.tokens;
   
 }

 

  function checkIfGen2Staked(address _address) public view returns (bool){
     if(stakeOwners[_address].gen2.tokens.length > 0){
     return  true;
     }
     else
      return false;
  }
 
  


 
   

   
   


 
 
 
  
 function getGen2StakeTime(address _address) public view returns(uint64){
     uint64 endTime = uint64(block.timestamp);
    return endTime - stakeOwners[_address].gen2.rewardStartTime;
 }

 



 
 

 function claimGen2Reward() external returns (uint){
  
    require(stakeOwners[ msg.sender].gen2.tokens.length > 0 , "You have not staked any NFTs"); 
    uint reward = calculateGen2Reward(msg.sender);
    
    
   
 
   
  
    stakeOwners[ msg.sender].gen2.rewardStartTime = uint64(block.timestamp);
   stakeOwners[ msg.sender].gen2.rewards=0;
    return reward;

 }

  function getRewardforUnstakingGen2(uint16 tokens) internal returns (uint){

    uint totalreward = calculateGen2Reward(msg.sender);
    uint unstakeReward = totalreward/ stakeOwners[msg.sender].gen2.tokens.length ;
    unstakeReward = unstakeReward * tokens;
    stakeOwners[ msg.sender].gen2.rewards= totalreward - unstakeReward;
    
   
    
  
 
    //stardust.mint( msg.sender , unstakeReward);
 
    stakeOwners[ msg.sender].gen2.rewardStartTime = uint64(block.timestamp);
   return unstakeReward;
 }


 function unstakeGen2(uint16 [] calldata data) external returns (uint){
    require(stakeOwners[ msg.sender].gen2.tokens.length> 0, "You have not staked any NFTs"); 
    uint16 tokens =uint16(data.length);
    require(tokens > 0, "You have not selected any NFT to unstake"); 
    uint unstakeReward= getRewardforUnstakingGen2(tokens);
    uint16 tokenID;
    for(uint16 i; i<tokens; i++)
    {
    tokenID=data[i];
    genesis2.transferFrom(address(this),msg.sender,tokenID);
    removeGen2Token(tokenID);
    }
   
   totalNFTStaked -= tokens;
   totalgen2NFTStaked -= tokens;

    
     return unstakeReward;
 }
 


   function removeGen2Token(uint16 token) internal {
   uint x=   stakeOwners[ msg.sender].gen2.tokens.length  ;
   if (token == stakeOwners[ msg.sender].gen2.tokens[x-1])
   {
        stakeOwners[ msg.sender].gen2.tokens.pop();
   }
   else{
    for (uint i ; i < stakeOwners[ msg.sender].gen2.tokens.length ; i ++)
    {

      if(token == stakeOwners[ msg.sender].gen2.tokens[i] )
      {
        uint16 temp = stakeOwners[ msg.sender].gen2.tokens[x-1];
        stakeOwners[ msg.sender].gen2.tokens[x-1]   =  stakeOwners[ msg.sender].gen2.tokens[i];
        stakeOwners[ msg.sender].gen2.tokens[i] = temp;
        stakeOwners[ msg.sender].gen2.tokens.pop();
      }
    }
   }
   }
// ---------- GEN2 --------------///
 
 // ---------- PlatinumFrenzBoost --------------///
 function stakeRFPremium(uint16 [] calldata data) external{
    uint16 _number= uint16(data.length );
    require(_number > 0 , "Invalid Number");
   
    require(checkIfGen0Staked(msg.sender) == true , " No Gen0 NFTs staked");
   
  

    uint16 tokens=uint16(stakeOwners[msg.sender].rfpremium.tokens.length);
    
    if(tokens > 0){
      stakeOwners[ msg.sender].rfpremium.rewards = calculateRFPremiumReward(msg.sender);
    }
 
      
      stakeOwners[ msg.sender].rfpremium.rewardStartTime = uint64(block.timestamp);
      totalNFTStaked += _number;
      totalrfPremiumNFTStaked += _number;
      storeRFPremiumTokens(_number , data);
    
      for(uint16 i ; i< _number ; i++)
    {  
       require(RFPremium.ownerOf(data[i]) == msg.sender, "Not the owner");
    RFPremium.transferFrom( msg.sender, address(this),data[i]);
    }
    delete tokens;

 }

function calculateRFPremiumReward(address _address) public view returns (uint){
   
    
    return  stakeOwners[ _address].rfpremium.rewards + ( getRFPremiumStakeTime(_address)  * stakeOwners[_address].rfpremium.tokens.length * (dailyPlatinumFrenzBoost/86400));
  
 }

  
 


 
 function storeRFPremiumTokens(uint16 _number , uint16 [] calldata data) internal {
    uint16 tokenID;
    for(uint16 i; i< _number ; i++)
    {
     tokenID=data[i];
      stakeOwners[ msg.sender].rfpremium.tokens.push(tokenID);
    }

 delete tokenID;
 }


  function getFulltokenOfRFPremium(address _address) external view returns(uint16 [] memory)
 {
    return stakeOwners[_address].rfpremium.tokens;
   
 }

 




 
   

   
   


 
 
  
 function getRFPremiumStakeTime(address _address) public view returns(uint64){
     uint64 endTime = uint64(block.timestamp);
    return endTime - stakeOwners[_address].gen0.rewardStartTime;
 }


 



 
 

 function claimRFPremiumReward() external returns (uint){
  
    require(stakeOwners[ msg.sender].rfpremium.tokens.length > 0 , "You have not staked any NFTs"); 
    uint reward = calculateRFPremiumReward(msg.sender);
    
    
   
 
   
  
    stakeOwners[ msg.sender].rfpremium.rewardStartTime = uint64(block.timestamp);
   stakeOwners[ msg.sender].rfpremium.rewards=0;
    return reward;

 }

  function getRewardforUnstakingRFPremium(uint16 tokens) internal returns (uint) {

    uint totalreward = calculateRFPremiumReward(msg.sender);
    uint unstakeReward = totalreward/ stakeOwners[msg.sender].rfpremium.tokens.length ;
    unstakeReward = unstakeReward * tokens;
    stakeOwners[ msg.sender].rfpremium.rewards= totalreward - unstakeReward;
    
   
    
  
 
   
 
    stakeOwners[ msg.sender].rfpremium.rewardStartTime = uint64(block.timestamp);
   return unstakeReward;
 }


 function unstakeRFPremium(uint16 [] calldata data) external returns (uint){
    require(stakeOwners[ msg.sender].rfpremium.tokens.length> 0, "You have not staked any NFTs"); 
    uint16 tokens =uint16(data.length);
    require(tokens > 0, "You have not selected any NFT to unstake"); 
    uint unstakeReward = getRewardforUnstakingRFPremium(tokens);
    uint16 tokenID;
    for(uint16 i; i<tokens; i++)
    {
    tokenID=data[i];
    RFPremium.transferFrom(address(this),msg.sender,tokenID);
    removeRFPremiumToken(tokenID);
    }
   
   totalNFTStaked -= tokens;
   totalrfPremiumNFTStaked -= tokens;

    
    return unstakeReward;
 }
 


   function removeRFPremiumToken(uint16 token) internal {
   uint x=   stakeOwners[ msg.sender].rfpremium.tokens.length  ;
   if (token == stakeOwners[ msg.sender].rfpremium.tokens[x-1])
   {
        stakeOwners[ msg.sender].rfpremium.tokens.pop();
   }
   else{
    for (uint i ; i < stakeOwners[ msg.sender].rfpremium.tokens.length ; i ++)
    {

      if(token == stakeOwners[ msg.sender].rfpremium.tokens[i] )
      {
        uint16 temp = stakeOwners[ msg.sender].rfpremium.tokens[x-1];
        stakeOwners[ msg.sender].rfpremium.tokens[x-1]   =  stakeOwners[ msg.sender].rfpremium.tokens[i];
        stakeOwners[ msg.sender].rfpremium.tokens[i] = temp;
        stakeOwners[ msg.sender].rfpremium.tokens.pop();
      }
    }
   }
   }
// ---------- PlatinumFrenzBoost --------------///

// ---------- GoldFrenzBoost --------------///
 function stakeRFUnleaded(uint16 [] calldata data) external{
    uint16 _number= uint16(data.length );
    require(_number > 0 , "Invalid Number");
   
  require(checkIfGen2Staked(msg.sender) == true , " No Gen0 NFTs staked");

    uint16 tokens=uint16(stakeOwners[msg.sender].rfunleaded.tokens.length);
    
    if(tokens > 0){
      stakeOwners[ msg.sender].rfunleaded.rewards = calculateRFUnleadedReward(msg.sender);
    }
 
      
      stakeOwners[ msg.sender].rfunleaded.rewardStartTime = uint64(block.timestamp);
      totalNFTStaked += _number;
      totalrfUnleadedNFTStaked += _number;
      storeRFUnleadedTokens(_number , data);
    
      for(uint16 i ; i< _number ; i++)
    {  
       require(RFUnleaded.ownerOf(data[i]) == msg.sender, "Not the owner");
    RFUnleaded.transferFrom( msg.sender, address(this),data[i]);
    }
    delete tokens;

 }

function calculateRFUnleadedReward(address _address) public view returns (uint){
   
    
    return  stakeOwners[ _address].rfunleaded.rewards + ( getRFUnleadedStakeTime(_address)  * stakeOwners[_address].rfunleaded.tokens.length * (dailyGoldFrenzBoost/86400));
  
 }

  
 


 
 function storeRFUnleadedTokens(uint16 _number , uint16 [] calldata data) internal {
    uint16 tokenID;
    for(uint16 i; i< _number ; i++)
    {
     tokenID=data[i];
      stakeOwners[ msg.sender].rfunleaded.tokens.push(tokenID);
    }

 delete tokenID;
 }


  function getFulltokenOfRFUnleaded(address _address) external view returns(uint16 [] memory)
 {
    return stakeOwners[_address].rfunleaded.tokens;
   
 }


  
 
  
 function getRFUnleadedStakeTime(address _address) public view returns(uint64){
     uint64 endTime = uint64(block.timestamp);
    return endTime - stakeOwners[_address].rfunleaded.rewardStartTime;
 }

 



 
 

 function claimRFUnleadedReward() external returns (uint){
  
    require(stakeOwners[ msg.sender].rfunleaded.tokens.length > 0 , "You have not staked any NFTs"); 
    uint reward = calculateRFUnleadedReward(msg.sender);
    
    
   
 
    
  
    stakeOwners[ msg.sender].rfunleaded.rewardStartTime = uint64(block.timestamp);
   stakeOwners[ msg.sender].rfunleaded.rewards=0;
    return reward;

 }

  function getRewardforUnstakingRFUnleaded(uint16 tokens) internal returns (uint){

    uint totalreward = calculateRFUnleadedReward(msg.sender);
    uint unstakeReward = totalreward/ stakeOwners[msg.sender].rfunleaded.tokens.length ;
    unstakeReward = unstakeReward * tokens;
    stakeOwners[ msg.sender].rfunleaded.rewards= totalreward - unstakeReward;
    
   
    
  
 
   
 
    stakeOwners[ msg.sender].rfunleaded.rewardStartTime = uint64(block.timestamp);
    return unstakeReward;
   
 }


 function unstakeRFUnleaded(uint16 [] calldata data) external returns (uint){
    require(stakeOwners[ msg.sender].rfunleaded.tokens.length> 0, "You have not staked any NFTs"); 
    uint16 tokens =uint16(data.length);
    require(tokens > 0, "You have not selected any NFT to unstake"); 
    uint unstakeReward = getRewardforUnstakingRFUnleaded(tokens);
    uint16 tokenID;
    for(uint16 i; i<tokens; i++)
    {
    tokenID=data[i];
    RFUnleaded.transferFrom(address(this),msg.sender,tokenID);
    removeRFUnleadedToken(tokenID);
    }
   
   totalNFTStaked -= tokens;
   totalrfUnleadedNFTStaked -= tokens;

    
     return unstakeReward;
 }
 


   function removeRFUnleadedToken(uint16 token) internal {
   uint x=   stakeOwners[ msg.sender].rfunleaded.tokens.length  ;
   if (token == stakeOwners[ msg.sender].rfunleaded.tokens[x-1])
   {
        stakeOwners[ msg.sender].rfunleaded.tokens.pop();
   }
   else{
    for (uint i ; i < stakeOwners[ msg.sender].rfunleaded.tokens.length ; i ++)
    {

      if(token == stakeOwners[ msg.sender].rfunleaded.tokens[i] )
      {
        uint16 temp = stakeOwners[ msg.sender].rfunleaded.tokens[x-1];
        stakeOwners[ msg.sender].rfunleaded.tokens[x-1]   =  stakeOwners[ msg.sender].rfunleaded.tokens[i];
        stakeOwners[ msg.sender].rfunleaded.tokens[i] = temp;
        stakeOwners[ msg.sender].rfunleaded.tokens.pop();
      }
    }
   }
   }
// ---------- RFUnleaded --------------///

// ---------- Spaceship --------------///
 function stakeSpaceship(uint16 [] calldata data) external{
    uint16 _number= uint16(data.length );
    require(_number > 0 , "Invalid Number");
   
  require(checkIfGen2Staked(msg.sender) == true , " No Gen0 NFTs staked");

    uint16 tokens=uint16(stakeOwners[msg.sender].spaceship.tokens.length);
    
    if(tokens > 0){
      stakeOwners[ msg.sender].spaceship.rewards = calculateSpaceshipReward(msg.sender);
    }
 
      
      stakeOwners[ msg.sender].spaceship.rewardStartTime = uint64(block.timestamp);
      totalNFTStaked += _number;
      totalspaceshipNFTStaked += _number;
      storeSpaceshipTokens(_number , data);
    
      for(uint16 i ; i< _number ; i++)
    {  
       require(spaceship.ownerOf(data[i]) == msg.sender, "Not the owner");
    spaceship.transferFrom( msg.sender, address(this),data[i]);
    }
    delete tokens;

 }

function calculateSpaceshipReward(address _address) public view returns (uint){
   
    
    return  stakeOwners[ _address].spaceship.rewards + ( getSpaceshipStakeTime(_address)  * stakeOwners[_address].spaceship.tokens.length * (dailyspaceshipReward/86400));
  
 }

  
 


 
 function storeSpaceshipTokens(uint16 _number , uint16 [] calldata data) internal {
    uint16 tokenID;
    for(uint16 i; i< _number ; i++)
    {
     tokenID=data[i];
      stakeOwners[ msg.sender].spaceship.tokens.push(tokenID);
    }

 delete tokenID;
 }


  function getFulltokenOfspaceship(address _address) external view returns(uint16 [] memory)
 {
    return stakeOwners[_address].spaceship.tokens;
   
 }

 


  


 
  
  
 function getSpaceshipStakeTime(address _address) public view returns(uint64){
     uint64 endTime = uint64(block.timestamp);
    return endTime - stakeOwners[_address].spaceship.rewardStartTime;
 }





 
 

 function claimSpaceshipReward() external returns(uint){
  
    require(stakeOwners[ msg.sender].spaceship.tokens.length > 0 , "You have not staked any NFTs"); 
    uint reward = calculateSpaceshipReward(msg.sender);
    
    
   
 
   
  
    stakeOwners[ msg.sender].spaceship.rewardStartTime = uint64(block.timestamp);
   stakeOwners[ msg.sender].spaceship.rewards=0;
    return reward;

 }

  function getRewardforUnstakingSpaceship(uint16 tokens) internal returns (uint){

    uint totalreward = calculateSpaceshipReward(msg.sender);
    uint unstakeReward = totalreward/ stakeOwners[msg.sender].spaceship.tokens.length ;
    unstakeReward = unstakeReward * tokens;
    stakeOwners[ msg.sender].spaceship.rewards= totalreward - unstakeReward;
    
   
    
  
 
    
 
    stakeOwners[ msg.sender].spaceship.rewardStartTime = uint64(block.timestamp);
   return unstakeReward;
 }


 function unstakeSpaceship(uint16 [] calldata data) external returns(uint){
    require(stakeOwners[ msg.sender].spaceship.tokens.length> 0, "You have not staked any NFTs"); 
    uint16 tokens =uint16(data.length);
    require(tokens > 0, "You have not selected any NFT to unstake"); 
    uint unstakeReward = getRewardforUnstakingSpaceship(tokens);
    uint16 tokenID;
    for(uint16 i; i<tokens; i++)
    {
    tokenID=data[i];
    spaceship.transferFrom(address(this),msg.sender,tokenID);
    removeSpaceshipToken(tokenID);
    }
   
   totalNFTStaked -= tokens;
   totalspaceshipNFTStaked-= tokens;

   return unstakeReward;
    
 }
 


   function removeSpaceshipToken(uint16 token) internal {
   uint x=   stakeOwners[ msg.sender].spaceship.tokens.length  ;
   if (token == stakeOwners[ msg.sender].spaceship.tokens[x-1])
   {
        stakeOwners[ msg.sender].spaceship.tokens.pop();
   }
   else{
    for (uint i ; i < stakeOwners[ msg.sender].spaceship.tokens.length ; i ++)
    {

      if(token == stakeOwners[ msg.sender].spaceship.tokens[i] )
      {
        uint16 temp = stakeOwners[ msg.sender].spaceship.tokens[x-1];
        stakeOwners[ msg.sender].spaceship.tokens[x-1]   =  stakeOwners[ msg.sender].spaceship.tokens[i];
        stakeOwners[ msg.sender].spaceship.tokens[i] = temp;
        stakeOwners[ msg.sender].spaceship.tokens.pop();
      }
    }
   }
   }
// ---------- Spaceship --------------///
}