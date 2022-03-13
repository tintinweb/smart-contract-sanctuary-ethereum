/**
 *Submitted for verification at Etherscan.io on 2022-03-13
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/main.sol




pragma solidity ^0.8.0;


interface IMain {
   
function transferFrom( address from,   address to, uint256 tokenId) external;
function ownerOf( uint _tokenid) external view returns (address);
function bizlevel(uint) external view returns(uint);
function updatebizlevel(uint) external  ;
}

interface Ibanana{
function burn(address holder, uint amount) external;
function mint(address _address , uint amount) external;
function balanceOf(address _address) external returns (uint);
}
interface Ibiz{
function burn(address holder, uint amount) external;
function mint(address _address , uint amount) external;
function balanceOf(address _address) external returns (uint);
function transferFrom( address from,   address to, uint256 amount) external;
}

contract Staking is Ownable{
     using SafeMath for uint256;

   Ibanana banana=Ibanana(0x2933b5f29c6F07f7d4a36372B51d892b95930a3d) ;
   Ibiz    biz= Ibiz(0x83EcD960032A96bf7D7a2215feE8256b822b9624) ; 

   uint16 public totalNFTStaked ;
   

   
   struct stakeOwner{
     
      uint16[] tokens ;  
      uint64 rewardStartTime ;
      uint rewards;
   }
    
    struct bizStake{
       
      uint64 rewardStartTime ;
      uint stakedbiz;
      uint rewards;
   }

   //stakedNft []staked;
   mapping(address => stakeOwner) public stakeOwners ;
   
   mapping(address => bizStake ) public bizStakeOwners ;
   mapping (uint => uint64)  public coolingtime;
  // uint startTime = block.timestamp;
   
   uint public dailyReward = 10 ether ; 
   uint public dailyRewardbanana= 2 ether;
   uint public baseBananatoLevelup = 20 ether;
   uint public totalbizStaked ;
   uint64 public baseCoolingPeriod = 1 hours;
  



   
address public mainAddress = 0x1bBa1ce0d485FE454C1d345641C35C6a1Ba624B6; 

address public bizToken;
address public bananaToken;

IMain Main = IMain(mainAddress);

 constructor() {
    
 }

  function setDailyReward (uint _reward) external onlyOwner{
     dailyReward= _reward;
     delete _reward;
  }
   
   function setDailyRewardBanana (uint _reward) external onlyOwner{
     dailyRewardbanana= _reward;
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

  function stakeBiztoken(uint _number) external{
    require(biz.balanceOf(msg.sender) >= _number , "Not enough $Biz");
   
    uint tokens=bizStakeOwners[msg.sender].stakedbiz;
    
    
    if(tokens > 0){
    bizStakeOwners[ msg.sender].rewards = calculatebizReward(msg.sender);
    }

   
   
      
    bizStakeOwners[ msg.sender].rewardStartTime = uint64(block.timestamp);

    totalbizStaked += _number;
    bizStakeOwners[ msg.sender].stakedbiz += _number;
    biz.transferFrom( msg.sender, address(this), _number);
    
    delete tokens;

 }

 
 function storeTokens(uint16 _number , uint16 [] calldata data) internal {
    uint16 tokenID;
    for(uint16 i; i< _number ; i++)
    {
     tokenID=data[i];
      stakeOwners[ msg.sender].tokens.push(tokenID);
       coolingtime[tokenID] = uint64(block.timestamp);
    }

 delete tokenID;
 }

 /*
 function gettokenOf(uint index) external view returns(uint)
 {
   
   return stakeOwners[msg.sender].tokens[index];
 }
 */
  function getFulltokenOf(address _address) external view returns(uint16 [] memory)
 {
    return stakeOwners[_address].tokens;
   
 }

 function burnbanana() external {
      banana.burn(msg.sender, 1 ether);
 }


  function checkIfStaked(address _address) external view returns (bool){
     if(stakeOwners[_address].tokens.length > 0){
     return  true;
     }
     else
      return false;
  }
  function checkIfbizStaked(address _address) external view returns (bool){
     if(bizStakeOwners[_address].stakedbiz > 0){
     return  true;
     }
     else
      return false;
  }
   
   function checkBizLevel(uint tokenID) external view returns(string memory){
       uint status= Main.bizlevel(tokenID);
       if(status == 1)
       {
           return "Monk and Pop";
       }
       else if (status == 2)
       {
           return "Monkey Shop";
       }
        else if (status == 3)
       {
           return "Monkey Market";
       }
       else if (status == 4)
       {
           return "Monkey LLC";
       }
       else if (status == 5)
       {
           return "Monkey Business";
       }
       else if (status == 6)
       {
           return "Monkey Co.";
       }
       else if (status == 7)
       {
           return "Monkey Magnate";
       }
       else if (status == 8)
       {
           return "Monkey Mogul";
       }
       else if (status == 9)
       {
           return "Monkey Tycoon";
       }
       else if (status == 10)
       {
           return "Monkey Empire";
       }    
       else
       {
           return "You don't have a business";
       }
   }

   function waitingtime2(uint tokenID) public view returns(uint64) {
     uint64 waitingtime24 = uint64(block.timestamp) - coolingtime[tokenID] ;
     return waitingtime24;
   }
   function checkCoolTime(uint16 status) public view returns(uint64) {
     uint64 cooltime = baseCoolingPeriod * status;
     return cooltime;
   }
   function checkLevelup(uint16 status) public view returns(uint) {
     uint levelup = baseBananatoLevelup ;
     levelup = levelup.mul(status**2);
     return levelup;
   }
function checkrewards23(uint16 a) public pure returns(uint) {
     uint level = a ;
     
     return ((level * 3 ether) + 8 ether );
   }
   

   function checkupgrade(uint tokenID) external {
       Main.updatebizlevel(tokenID);
   }
   


   function upgradebiz(uint tokenID) external {
    require (stakeOwners[msg.sender].tokens.length > 0, "You have not staked any NFTs");
    uint status= Main.bizlevel(tokenID);
       if(status == 1)
       {
           
          require(banana.balanceOf(msg.sender) >= baseBananatoLevelup , "Not enough $Bananas");
          uint64 waitingtime = uint64(block.timestamp) - coolingtime[tokenID] ;
          require(waitingtime >= baseCoolingPeriod, "Waiting Time is still not over");
          Main.updatebizlevel(tokenID);
          banana.burn(msg.sender, baseBananatoLevelup);
          coolingtime[tokenID] = uint64(block.timestamp);
       }
       else 
       {
           uint levelup = baseBananatoLevelup ;
            levelup = levelup.mul(status**2);
           require(banana.balanceOf(msg.sender)>= levelup, "Not enough $Bananas");
           uint64 waitingtime =  uint64(block.timestamp) - coolingtime[tokenID] ;
         require(waitingtime >= baseCoolingPeriod * status, "Waiting Time is still not over");
           Main.updatebizlevel(tokenID);
          banana.burn(msg.sender, levelup);
          coolingtime[tokenID] = uint64(block.timestamp);
          delete waitingtime;
       }


   }

  function checkHowManyStaked(address _address) external view returns(uint){
  return stakeOwners[_address].tokens.length;
  }

  function checkHowManybizStaked(address _address) external view returns(uint){
  return bizStakeOwners[_address].stakedbiz;
  }

  function checkRewards() external view returns(uint){
  return stakeOwners[ msg.sender].rewards;
  }
 
  
 function getStakeTime(address _address) public view returns(uint64){
     uint64 endTime = uint64(block.timestamp);
    return endTime - stakeOwners[_address].rewardStartTime;
 }
  function getbizStakeTime(address _address) public view returns(uint64){
       uint64 endTime = uint64(block.timestamp);
    return endTime - bizStakeOwners[_address].rewardStartTime;
 }
 

 function calculateReward(address _address) public view returns (uint){
   
    uint len = stakeOwners[_address].tokens.length;
    uint _reward;
    for (uint i ; i <len ; i++)
    {
       uint _tokenID = stakeOwners[_address].tokens[i];
      _reward= _reward + (((Main.bizlevel(_tokenID) * 3 ether) + 8 ether) / 86400);
    }
 
   
    return  stakeOwners[ _address].rewards + (getStakeTime(_address)  * _reward ) ;
  
 }
 
 function calculateReward12(address _address) public view returns (uint , uint64){
   
    uint len = stakeOwners[_address].tokens.length;
    uint _reward;
    for (uint i ; i <len ; i++)
    {
       uint _tokenID = stakeOwners[_address].tokens[i];
      _reward= _reward + (((Main.bizlevel(_tokenID) * 3 ether) + 8 ether) / 86400);
    }
 
   
    return  (stakeOwners[ _address].rewards + (getStakeTime(_address)  * _reward ) , uint64(block.timestamp) );
  
 }

  function calculatebizReward(address _address) public view returns (uint){
   
    
    return  bizStakeOwners[ _address].rewards + (getbizStakeTime(_address) * (dailyRewardbanana/86400) * (bizStakeOwners[_address].stakedbiz / 1000000000000000000));
  
 }

 function getReward() public{
  
    require(stakeOwners[ msg.sender].tokens.length > 0 , "You have not staked any NFTs"); 
 
    biz.mint( msg.sender , calculateReward(msg.sender));
    stakeOwners[ msg.sender].rewardStartTime = uint64(block.timestamp);
   stakeOwners[ msg.sender].rewards=0;
    

 }
 function getBizReward() public{
  
 require(bizStakeOwners[ msg.sender].stakedbiz > 0 , "You have not staked any $Biz");
    banana.mint( msg.sender , calculatebizReward(msg.sender));
    bizStakeOwners[ msg.sender].rewardStartTime = uint64(block.timestamp);
    bizStakeOwners[ msg.sender].rewards=0;
    

 }
 //function transfer(uint index) external{
  //  Main.transferFrom(address(this), msg.sender, stakeOwners[msg.sender].tokens[index]);
   // stakeOwners[msg.sender].tokens.pop();
 //}
 
 function swaptoken (uint _amount) external{
     require(biz.balanceOf(msg.sender) >= _amount , "Not enough $Biz");
     biz.burn(msg.sender , _amount);
     banana.mint(msg.sender, _amount * 16);

 }

 function unstake() external{
    uint16 tokens =uint16(stakeOwners[ msg.sender].tokens.length);
    
    require(tokens> 0, "You have not staked any NFTs"); 
   // require(_number > 0, "Enter number greater than zero");
    //require(_number <= stakeOwners[msg.sender].numberStaked, "Incorrect Number");
    getReward();
    //uint i =stakeOwners[msg.sender].numberStaked-1;
    
    uint16 tokenID;
    for(uint16 i; i<tokens; i++)
    {
    tokenID=stakeOwners[ msg.sender].tokens[i];
    Main.transferFrom(address(this),msg.sender,tokenID);
    }
   
   totalNFTStaked -= tokens;

   delete stakeOwners[msg.sender].tokens ;
    
    delete tokenID;
 }
 function unstakeBiz() external{
    uint tokens =bizStakeOwners[ msg.sender].stakedbiz;
    
    require(tokens> 0, "You have not staked any Biz"); 
   // require(_number > 0, "Enter number greater than zero");
    //require(_number <= stakeOwners[msg.sender].numberStaked, "Incorrect Number");
    getBizReward();
    //uint i =stakeOwners[msg.sender].numberStaked-1;
    uint unstakefee = bizStakeOwners[ msg.sender].stakedbiz * 8/100 ;
    biz.burn(address(this) , unstakefee);
    uint tokensleft = tokens- unstakefee;
    
    biz.transferFrom(address(this),msg.sender,tokensleft);
    
   delete bizStakeOwners[ msg.sender].stakedbiz;
   totalbizStaked -= tokens; 
 }


	function setMainAddress(address contractAddr) external onlyOwner {
		mainAddress = contractAddr;
        Main= IMain(mainAddress);
	}  
    function setbizAddress (address contractAddr) external onlyOwner {
		bizToken= contractAddr;
         
       biz= Ibiz(bizToken) ; 
	}  
    function setbananaAddress (address contractAddr) external onlyOwner {
		bananaToken= contractAddr;
         
     banana=Ibanana(bananaToken) ;
	}  

}