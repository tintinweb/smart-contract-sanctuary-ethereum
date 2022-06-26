/**
 *Submitted for verification at Etherscan.io on 2022-06-26
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



contract KaijuFrenzStaking is Ownable{
     


  
uint16 public totalgen0NFTStaked ;

   struct stakeOwner{
     
     Gen0staker gen0;
     
   }
   struct Gen0staker{
     
      uint16[] tokens ;  
      uint64 rewardStartTime ;
      uint rewards;
   }
  


    
  
   //stakedNft []staked;
   mapping(address => stakeOwner) public stakeOwners ;
   
 
  // uint startTime = block.timestamp;
   
   uint public dailyGen0Reward = 4 ether ; 

  
  



   
address public gen0 = 0xC92090f070bf50eEC26D849c88A68112f4f3D98e; 




IGenesis0 genesis0= IGenesis0(gen0) ;



 constructor() {
  
 }

   /// ---------- Setting info --------------///

 function setGen0Address(address contractAddr) external onlyOwner {
		gen0 = contractAddr;
       genesis0 = IGenesis0(gen0);
	}  
    
    
  function setdailyGen0Reward (uint _reward) external onlyOwner{
        
     dailyGen0Reward= _reward;
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

}