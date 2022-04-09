/**
 *Submitted for verification at Etherscan.io on 2022-04-09
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


interface IMain {
   
function transferFrom( address from,   address to, uint256 tokenId) external;
function ownerOf( uint _tokenid) external view returns (address);
}

interface IMain2 {
   
function transferFrom( address from,   address to, uint256 tokenId) external;
function ownerOf( uint _tokenid) external view returns (address);
}
interface IMain3 {
   
function transferFrom( address from,   address to, uint256 tokenId) external;
function ownerOf( uint _tokenid) external view returns (address);
}




interface IPEXXX{
function burn(address holder, uint amount) external;
function mint(address _address , uint amount) external;
function balanceOf(address _address) external returns (uint);
function transferFrom( address from,   address to, uint256 amount) external;
}

contract Staking is Ownable{
     

  
  

   uint16 public totalNFTStaked ;
  

   
   struct stakeOwner{
     
      uint16[] tokens ;  
      uint64 rewardStartTime ;
      uint rewards;
   }
   
    
 
   //stakedNft []staked;
   mapping(address => stakeOwner) public stakeOwners ;
  
 
  // uint startTime = block.timestamp;
   
   uint public dailyReward = 1500 ether ; 
   uint public dailyReward2 ;
   uint public dailyReward3;
  
  



   
address public mainAddress = 0x34c588688E130369636Bb16867A541Fe0dD40234; 

address public main2;
address public main3;
address public rewardtokenaddress = 0xedCf9d0Dbd5C5ACf7356030028E942d675e21e95;
address public treasurywallet =0x9102f3A3Bc64805386bb811bEf527e4972a18A68;

IMain Main = IMain(mainAddress);
IMain2 Main2 = IMain2(main2);
IMain3 Main3 = IMain3(main3);
IPEXXX PEXXX= IPEXXX(rewardtokenaddress);


 constructor() {
  
 }

 

  function setDailyReward (uint _reward) external onlyOwner{
     dailyReward= _reward;
     delete _reward;
  }
  function setDailyReward2 (uint _reward) external onlyOwner{
     dailyReward= _reward;
     delete _reward;
  }
  function setDailyReward3 (uint _reward) external onlyOwner{
     dailyReward= _reward;
     delete _reward;
  }
 
 function stake(uint16 [] calldata data) external{
    uint16 _number= uint16(data.length );
    require(_number > 0 , "Invalid Number");
   
    uint16 tokens=uint16(stakeOwners[ msg.sender].tokens.length);

    
    
    if(tokens > 0){
      stakeOwners[ msg.sender].rewards = calculateReward(msg.sender);
    }
 
      
      stakeOwners[ msg.sender].rewardStartTime = uint64(block.timestamp);
      totalNFTStaked += _number;
      storeTokens(_number , data);
    
      for(uint16 i ; i< _number ; i++)
    {  
       require(Main.ownerOf(data[i]) == msg.sender, "Not the owner");
    Main.transferFrom( msg.sender, address(this),data[i]);
    }
    delete tokens;
 }

  
 function storeTokens(uint16 _number , uint16 [] calldata data  ) internal {
       uint16 tokenID;
    for(uint16 i; i< _number ; i++)
    {
     tokenID=data[i];
      stakeOwners[ msg.sender].tokens.push(tokenID);
    }

 delete tokenID;
  
 }


   
 






  function getFulltokenOf(address _address) external view returns(uint16 [] memory)
 {
    return stakeOwners[_address].tokens;
   
 }

 

  function checkIfStaked(address _address) external view returns (bool){
     if(stakeOwners[_address].tokens.length > 0){
     return  true;
     }
     else
      return false;
  }
 
  


 
   

   
   


 
  function checkHowManyStaked(address _address) external view returns(uint){
  return stakeOwners[_address].tokens.length;
  }

 
  function checkRewards() external view returns(uint){
  return stakeOwners[ msg.sender].rewards;
  }
 
  
 function getStakeTime(address _address) public view returns(uint64){
    uint64 endTime = uint64(block.timestamp);
    return endTime - stakeOwners[_address].rewardStartTime;
 }

 
 function getStakeTimeInDays(address _address) public view returns (uint64){
    return (getStakeTime(_address)/ uint64(1 days));
 }



 function calculateReward(address _address) public view returns (uint){
   uint _reward;
    

         _reward = stakeOwners[msg.sender].rewards + ( (dailyReward /86400) * getStakeTime(_address) * stakeOwners[msg.sender].tokens.length);

    
    return _reward ;
  
 }

 

 function getRewardforUnstaking(uint16 tokens) internal {

    uint totalreward = calculateReward(msg.sender);
    uint unstakeReward = totalreward/ stakeOwners[msg.sender].tokens.length ;
    unstakeReward = unstakeReward * tokens;
    stakeOwners[ msg.sender].rewards= totalreward - unstakeReward;
    
    uint bribe = (unstakeReward * 25 )/100 ;
    
    uint tokensleft = unstakeReward - bribe;
 
    PEXXX.mint( msg.sender , tokensleft);
    PEXXX.mint(treasurywallet , bribe);
    stakeOwners[ msg.sender].rewardStartTime = uint64(block.timestamp);
   


 }




 function claimReward() public{
  
    require(stakeOwners[ msg.sender].tokens.length > 0 , "You have not staked any NFTs"); 
    uint reward = calculateReward(msg.sender);
    uint bribe = reward * 25/100 ;
    
    uint tokensleft = reward - bribe;
 
    PEXXX.mint( msg.sender , tokensleft);
    PEXXX.mint(treasurywallet , bribe);
    stakeOwners[ msg.sender].rewardStartTime = uint64(block.timestamp);
   stakeOwners[ msg.sender].rewards=0;
    

 }
 

 function unstake(uint16 [] calldata data) external{
    require(stakeOwners[ msg.sender].tokens.length> 0, "You have not staked any NFTs"); 
    uint16 tokens =uint16(data.length);
    require(tokens > 0, "You have not selected any NFT to unstake"); 
    getRewardforUnstaking(tokens);
    uint16 tokenID;
    for(uint16 i; i<tokens; i++)
    {
    tokenID=data[i];
    Main.transferFrom(address(this),msg.sender,tokenID);
    removeToken(tokenID);
    }
   
   totalNFTStaked -= tokens;
 

    
    delete tokenID;
 }
 


   function removeToken(uint16 token) internal {
   uint x=   stakeOwners[ msg.sender].tokens.length  ;
   if (token == stakeOwners[ msg.sender].tokens[x-1])
   {
        stakeOwners[ msg.sender].tokens.pop();
   }
   else{
    for (uint i ; i < stakeOwners[ msg.sender].tokens.length ; i ++)
    {

      if(token == stakeOwners[ msg.sender].tokens[i] )
      {
        uint16 temp = stakeOwners[ msg.sender].tokens[x-1];
        stakeOwners[ msg.sender].tokens[x-1]   =  stakeOwners[ msg.sender].tokens[i];
        stakeOwners[ msg.sender].tokens[i] = temp;
        stakeOwners[ msg.sender].tokens.pop();
      }
    }
   }
   }

	function setMainAddress(address contractAddr) external onlyOwner {
		mainAddress = contractAddr;
        Main= IMain(mainAddress);
	}  
    function setRewardTokenAddress (address contractAddr) external onlyOwner {
	
         
       PEXXX= IPEXXX(contractAddr) ; 
	}  

   function withdraw() external onlyOwner{
      uint _balance = address(this).balance;
     payable(msg.sender).transfer(_balance ); 
   }

}