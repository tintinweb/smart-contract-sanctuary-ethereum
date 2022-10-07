/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

// File: node_modules\@openzeppelin\contracts\math\SafeMath.sol

pragma solidity >=0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

pragma solidity >=0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\ownership\Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 _    _                                _   _____                                   _             
| |  | |                              | | /  __ \                                 (_)            
| |  | |_ __ __ _ _ __  _ __   ___  __| | | /  \/ ___  _ __ ___  _ __   __ _ _ __  _  ___  _ __  
| |/\| | '__/ _` | '_ \| '_ \ / _ \/ _` | | |    / _ \| '_ ` _ \| '_ \ / _` | '_ \| |/ _ \| '_ \ 
\  /\  / | | (_| | |_) | |_) |  __/ (_| | | \__/\ (_) | | | | | | |_) | (_| | | | | | (_) | | | |
 \/  \/|_|  \__,_| .__/| .__/ \___|\__,_|  \____/\___/|_| |_| |_| .__/ \__,_|_| |_|_|\___/|_| |_|
                 | |   | |                                      | |                              
                 |_|   |_|                                      |_|                              
 _____ _        _    _                              __   _____                                   
/  ___| |      | |  (_)                            /  | |  _  |                                  
\ `--.| |_ __ _| | ___ _ __   __ _  __   _____ _ __`| | | |/' |                                  
 `--. \ __/ _` | |/ / | '_ \ / _` | \ \ / / _ \ '__|| | |  /| |                                  
/\__/ / || (_| |   <| | | | | (_| |  \ V /  __/ |  _| |_\ |_/ /                                  
\____/ \__\__,_|_|\_\_|_| |_|\__, |   \_/ \___|_|  \___(_)___/                                   
                              __/ |                                                              
                             |___/                                                              

/**
 * 1.0
 * Initial release
 */

pragma solidity ^0.5.0;
//Interfaces to the various externals
interface CTKN {
    ////Interface to Token
  function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool);
  function balanceOf(address owner) external view returns (uint256);
  function transfer(address _to, uint256 _tokens) external returns (bool);
  function mintBurnTokensExternally(uint _mode,address _reciever,uint _numtokens) external;
}
    ////Interface to DB for additional Bonus's!
interface wrapperdb {
    function isBlockedNFT(uint _tokenID) external view returns(bool,uint256);
    function getWrappedStatus(address _migrator) external view returns(bool);
    function getFeesStatus(address _migrator) external view returns(uint);
}
    ////Interface to the WrappedCompanion NFT
interface wrappedcompanion{
  function balanceOf(address owner) external view returns (uint256);
  function ownerOf(uint256 tokenId) external view returns (address);
}
 


contract WTCStaking is Context, Ownable {
 
    address public Owner;
    uint public basetotalsupply;
    bool public whalelimiter = true;  ////Introducing a way to cap the reward if a whale is slowly bleeding off funds///
    //NB Addresses/////////
    address public wrappedcompnft = 0xc1A3bfd6678Ce5fb16db9A544cBd279850baA81D;
    address public CTKNAddress = 0x8227a53a088D3Fbdf315c094B27B4b6e643571cd;
    address public wdbaddress = 0x35ca5509F05793ad82eA703f8fAa5eFDE546F007 ;
    //NB Variables//
    uint public basereward = 10e18; // base reward of 10 CTKN per NFT
    uint public wlreward = 3e18; // base reward of 10 CTKN per NFT
    uint public boostpernft = 5; //5%
    bool public stakingenabled = true;
    uint public wtcsupply; //default of 555!
    bool public mintpayout = true;
    uint private collectionfee = 760000000000000; //0.00076ETH @ $1 27/9/2022
    bool public feesenabled = true; // Enable fee!
    bool public wrapperboost = true; // Enable boost for wrappers
    uint public wboostpercentage = 10; //% of boost for wrappers
    uint public numpruned; //number of illegal stakers cleaned up
    bool public collectrewards = true; //Collect rewards
    bool public legendaryboost = true;
    bool public rareboost = true;
    /////////Mappings and arrays ///////////////////////
    mapping(address => uint256) internal rewards; //Rewards Collection
    mapping(address => uint256) internal stakes; ///Number of NFT's staked
    mapping(address => uint256) internal lastclaim; // Blocktime of the last claim of rewards
    mapping(address => uint256) internal startedstaking; // Initial staking date
    mapping(address => uint256) internal dailyreward; //daily reward calculated at initial staking
    mapping(address => bool) internal blockedstaker; //mapping to block staker
    mapping(address => bool) internal whitelist; //mapping to handlewhitelist stakers for other rugged projects
    address[] internal stakeholders; //Dynamic array to keep track of users who are staking NFT'S
    uint[] internal legendaries; //Array to hold the current legendary NFT's -> Will recieve a 30% boost
    uint[] internal rares; //Array to hold the current rare NFT's -> Will recieve an extra a 20% boost
    ///////////////////////////////////////////////////
  
    
  using SafeMath for uint;
  
  
  constructor () public {
      Owner = msg.sender; //Owner of Contract
      wtcsupply = 555;
      /////Initialize the Arrays for the Legendaries and the rares!
      //rares!
      rares.push(63);
      rares.push(64);
      rares.push(65);

      //Legendaries////////////////
      legendaries.push(12);
      
      ////////////////////////////////



  }
  ///Sets the contract address of the CTKN Token//////
  function setCTKNAddress(address _CTKNaddress) external onlyOwner {
    CTKNAddress = _CTKNaddress;
  }

  ///Sets the contract address of the db wrapper//////
  function setdbAddress(address _dbaddress) external onlyOwner {
    wdbaddress = _dbaddress;
  }

  ///Manages Whitelist entries//////
  function manageWhiteList(address _wl,bool _allowed) external onlyOwner {
    whitelist[_wl] = _allowed;
  }

  ///Retrieves WL//////
  function isOnWhitelist(address _wl)external view returns(bool) {
    bool temp;
    temp = whitelist[_wl];
    return temp;
  }

  /////Manage Legendaries/////
  function addLegendary(uint _nftno) external onlyOwner
   {
       (bool _isLegendary, ) = isLegendary(_nftno);
       if(!_isLegendary) legendaries.push(_nftno);
   }

  function removeLegendary(uint _nftno) external onlyOwner
   {
       (bool _isLegendary, uint256 s) = isLegendary(_nftno);
       if(_isLegendary){
           legendaries[s] = legendaries[legendaries.length - 1];
           legendaries.pop();           
       }
   }
   
   /////Legendary
   function isLegendary(uint _nftno) public view returns(bool, uint256)
   {
       for (uint256 s = 0; s < legendaries.length; s += 1){
           if (_nftno == legendaries[s]) return (true, s);
       }
       return (false, 0);
   }

  function isRareOwner(address _holder) public view returns(bool)
   {
       for (uint256 s = 0; s < rares.length; s += 1){
           if (wrappedcompanion(wrappedcompnft).ownerOf(rares[s]) == _holder) return (true);
       }
       return (false);
   }

   function isLegendaryOwner(address _holder) public view returns(bool)
   {
       for (uint256 s = 0; s < legendaries.length; s += 1){
           if (wrappedcompanion(wrappedcompnft).ownerOf(legendaries[s]) == _holder) return (true);
       }
       return (false);
   }




  //Function to manage fees
  function manageFeeAndRewards(uint _option,uint _weiAmount,bool _enabled)external onlyOwner{
      if (_option==1)
      {
      collectionfee = _weiAmount; //Set Fee
      }
      if (_option==2)
      {
      feesenabled = _enabled; // Enable/Disable fee
      }
      if (_option==3)
      {
      wrapperboost = _enabled; // Enable/Disable wrapperboost
      }
      if (_option==4)
      {
      wboostpercentage = _weiAmount; // Set the % boost
      }
      if (_option==5)
      {
      collectrewards = _enabled; // Enable/Disable reward withdrawl
      }
      if (_option==6)
      {
      legendaryboost = _enabled; // Enable/Disable Legendary Boost
      }
      if (_option==7)
      {
      rareboost = _enabled; // Enable/Disable rare Boost
      }

  }
  
  //return current fee for website
  function getFee()external view returns(uint)
  {
      return collectionfee;
  }


  //Function to manage blocked addresses
  function setBlockedStakers(address _bannedStaker,bool _isblocked) external onlyOwner{
      blockedstaker[_bannedStaker] = _isblocked;
  }

     //Function to set reward percentages
  function setRewardValues(uint _option,uint _value,address _staker) external onlyOwner{
        if (_option ==1) //base reward
        {
            basereward = _value;
        }
        if (_option ==2) //Boosterpernft
        {
            boostpernft = _value;
        }
        if (_option==3)
        {
            dailyreward[_staker] = _value; //Adjust stakers daily reward if needs be
        }
        if (_option ==4) //WL base reward
        {
           wlreward = _value;
        }
    }
    
     
    function EnabledDisableStaking(bool EnableDisable_) public onlyOwner{
            stakingenabled = EnableDisable_;
    }  
  ////////////STAKING FUNCTIONS//////////
 
   function isStakeholder(address _address) public view returns(bool, uint256)
   {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           if (_address == stakeholders[s]) return (true, s);
       }
       return (false, 0);
   }
   
   /**
    * @notice A method to add a stakeholder.
    * @param _stakeholder The stakeholder to add.
    */
   function addStakeholder(address _stakeholder) private
   {
       (bool _isStakeholder, ) = isStakeholder(_stakeholder);
       if(!_isStakeholder) stakeholders.push(_stakeholder);
   }

   /**
    * @notice A method to remove a stakeholder.
    * @param _stakeholder The stakeholder to remove.
    */
   function removeStakeholder(address _stakeholder) private
   {
       (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder){
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
           rewards[_stakeholder]=0; //Set the reward to 0
           
       }
   }
   
   /////Admin functions to manage the users if needs be//
   /////This is one step further to prune the number of stakers///
   function forceRemoveStakeholder(address _stakeholder) public onlyOwner
   {
       (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder){
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
           rewards[_stakeholder]=0; //Set the reward to 0
           
       }

   
   }
   
   
   function stakeOf(address _stakeholder) public view returns(uint256)  ///pool 1 = Safe pool 2 = Risky
   {
       uint256 temp = 0;
       temp = stakes[_stakeholder];
       return temp;
   }

   /**
    * @notice A method to the aggregated stakes from all stakeholders.
    * @return uint256 The aggregated stakes from all stakeholders.
    */
   function totalStakes() public view returns(uint256){ ///pool 1 = Safe pool 2 = Risky
       uint256 _totalStakes = 0;
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
       }
       return _totalStakes;
   }
   
   //function to get the number of NFT's a user owns via balanceOf
   function getNFTCount(address _holder) public view returns(uint){
       uint temp;
       temp = wrappedcompanion(wrappedcompnft).balanceOf(_holder);
       return temp;
   }
  
   function createStake() external
   {
       uint temp;
       bool wluser = whitelist[msg.sender];
       bool isblocked = blockedstaker[msg.sender];
       require(isblocked!=true,"Not Authorized to Stake!");
       (bool currentstakeholder,) = isStakeholder(msg.sender);
       require(stakingenabled == true, "Staking Not Enabled!");
       require(currentstakeholder==false,"Already Staked!");
       if (wluser==false){
       //get numberofNFTs to stake
       temp = getNFTCount(msg.sender);
       require(temp > 0,"Error,No NFT's to Stake!");
       }
       if (wluser==true)
       {
           //Only allowing 1 NFT for non Wrapped Companion holders
           temp = 1;
       }
       //Add user to StakeDB
       addStakeholder(msg.sender);
       stakes[msg.sender] = stakes[msg.sender].add(temp);
       //Calculate Reward//
       if (wluser==false) //Wrapper!
       {
       dailyreward[msg.sender] = calculateDailyReward(temp);
       }
       if(wluser==true) //non Wrapper!
       {
       dailyreward[msg.sender] = wlreward; //Hardcode a reward    
       }
       //Set initial claim
       lastclaim[msg.sender] = block.timestamp;
       //Set initial stake date
       startedstaking[msg.sender] = block.timestamp;
           
       
   }
   
  
   function removeStake() public
   {
       uint temp;
       uint temp2;
       bool wluser;
       wluser = whitelist[msg.sender];
       if (wluser==false)
       {
       temp = getNFTCount(msg.sender);
       require (temp >= stakes[msg.sender],"Error - NFT count too low to withdraw");
       }   
       stakes[msg.sender] = 0;
       if(stakes[msg.sender] == 0) //Remove entire stake and rewards
       {
           removeStakeholder(msg.sender);
           //Frictionless staking///
           temp2 = rewards[msg.sender]; ///Only do the rewards//
           rewards[msg.sender] = 0; //Clear balance to ensure correct accounting
           if(mintpayout==false) //transfer out of the contract itself
           {
           CTKN(CTKNAddress).transfer(msg.sender,temp2);
           }
           if(mintpayout==true) //mint directly
           {
           CTKN(CTKNAddress).mintBurnTokensExternally(1,msg.sender,temp2);
           }
           //Set start stake date to 0
           startedstaking[msg.sender] = 0;
           //Set initialclaim date back to 0
           lastclaim[msg.sender] = 0;
           
          
        }
       
       
   }
  
    function withdrawRewards()
       payable public
   {
       uint temp;
       require (collectrewards==true,"Withdrawls are disabled!");
       if (feesenabled==true)
       {
           require(msg.value>=collectionfee,"Collection fee is not enough!");
       }
       uint reward;
       bool wluser = whitelist[msg.sender]; //get Whitelist status
       if (wluser==false)
       {
       temp = getNFTCount(msg.sender);   
       require (temp >= stakes[msg.sender],"Number of NFT's too low!");
       }
       //block if less than 24 hours since last claim
       temp = lastclaim[msg.sender];
       require (block.timestamp >= temp + 1 minutes);
       //////////////////////////////////////////////
       reward = calculatePayoutAmount(msg.sender);
       rewards[msg.sender] = 0; //Clear balance to ensure correct accounting
          if(mintpayout==false) //transfer out of the contract itself
           {
           CTKN(CTKNAddress).transfer(msg.sender,reward);
           }
          if(mintpayout==true) //mint directly
           {
           CTKN(CTKNAddress).mintBurnTokensExternally(1,msg.sender,reward);
           }
       lastclaim[msg.sender]=block.timestamp; //Set last claim
     
      
     
   }
  
   
 
    ///Function for user to check the amount of Staking rewards
    function rewardOf(address _stakeholder) public view returns(uint256)
   {
       return calculatePayoutAmount(_stakeholder);
   }
  
   /////Functions to Verify total rewards for safe and Risky rewards
   function totalRewards() public view returns(uint256)  ////Safe Staking
   {
       uint256 _totalRewards = 0;
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           _totalRewards = _totalRewards.add(calculatePayoutAmount(stakeholders[s]));
       }
       return _totalRewards;
   }
  
   /////Function to correct the stake of a user if they need assistance -> The stake can ONLY be lowered not increased
   /////Due to the nature of frictionless, a user may sell their RCVR and then attempt to lower their stake, this could cause issues when withdrawing rewards
   
   function adjustTotalStaked(address _User,uint _newstake) public onlyOwner
   {
           require(stakes[_User] > _newstake, "Only-");
           stakes[_User] = _newstake;

   }
   function calculatePayoutAmount(address _payee) public view returns(uint)
   {
     uint temp;
     uint temp2;
     uint lastcollect;
     temp = dailyreward[_payee];
     lastcollect = lastclaim[_payee];
     if(block.timestamp >= lastcollect + 1 minutes)
     {
         temp2 = temp;
     }
     if(block.timestamp >= lastcollect + 2 minutes)
     {
         temp2 = temp.mul(2);
     }
     if(block.timestamp >= lastcollect + 3 minutes)
     {
         temp2 = temp.mul(3);
     }
     if(block.timestamp >= lastcollect + 4 minutes)
     {
         temp2 = temp.mul(4);
     }
     if(block.timestamp >= lastcollect + 5 minutes)
     {
         temp2 = temp.mul(5);
     }
     if(block.timestamp >= lastcollect + 6 minutes)
     {
         temp2 = temp.mul(6);
     }
     if(block.timestamp >= lastcollect + 7 minutes)
     {
         temp2 = temp.mul(7);
     }
     if(block.timestamp >= lastcollect + 8 minutes)
     {
         temp2 = temp.mul(8);
     }
     if(block.timestamp >= lastcollect + 9 minutes)
     {
         temp2 = temp.mul(9);
     }
     if(block.timestamp >= lastcollect + 10 minutes)
     {
         temp2 = temp.mul(10);
     }
     if(block.timestamp >= lastcollect + 11 minutes)
     {
         temp2 = temp.mul(11);
     }
     if(block.timestamp >= lastcollect + 12 minutes)
     {
         temp2 = temp.mul(12);
     }
     if(block.timestamp >= lastcollect + 13 minutes)
     {
         temp2 = temp.mul(13);
     }
     if(block.timestamp >= lastcollect + 14 minutes)
     {
         temp2 = temp.mul(14);
     }
     if(block.timestamp >= lastcollect + 15 minutes) //Stops payout at 16 days
     {
         temp2 = temp.mul(15);
     }
     return temp2;
   }


   /////////////////////NB Function to calculate rewards//////////////////
   function calculateDailyReward(uint _numNFT)   
       public view
       returns(uint256)
   {
       uint temp;
       uint temp2;
       uint temp4;
       bool temp3;
       //Has the user wrapped?
       temp3 = wrapperdb(wdbaddress).getWrappedStatus(msg.sender);
       uint basesplit = basereward.div(100); 
       //Get wrapped status
       temp = basereward;
       if(_numNFT==1)
       {
           //Default!
       }
       if(_numNFT==2)
       {
           temp2 = basesplit.mul(10);
           temp = temp + temp2; 
       }
       if(_numNFT==3)
       {
           temp2 = basesplit.mul(15);
           temp = temp + temp2;
       }
       if(_numNFT==4)
       {
           temp2 = basesplit.mul(20);
           temp = temp + temp2;
       }
       if(_numNFT==5)
       {
           temp2 = basesplit.mul(25);
           temp = temp + temp2;
       }
       if(_numNFT==6)
       {
           temp2 = basesplit.mul(30);
           temp = temp + temp2;
       }
       if(_numNFT==7)
       {
           temp2 = basesplit.mul(35);
           temp = temp + temp2;
       }
       if(_numNFT==8)
       {
           temp2 = basesplit.mul(40);
           temp = temp + temp2;
       }
       if(_numNFT==9)
       {
           temp2 = basesplit.mul(45);
           temp = temp + temp2;
       }
       if(_numNFT>=10)
       {
           temp2 = basesplit.mul(50);
           temp = temp + temp2;
       }
       ///Boost reward if wallet is a wrapper!
       if(wrapperboost==true && temp3==true)
       {
        temp2 = 0; //reuse temp2
        temp2 = temp.div(100);
        if (wboostpercentage==10)
        {
            temp4 = temp2.mul(10);
            temp = temp.add(temp4);
        }
        if (wboostpercentage==20)
        {
            temp4 = temp2.mul(20);
            temp = temp.add(temp4);
        }
        if (wboostpercentage==30)
        {
            temp4 = temp2.mul(30);
            temp = temp.add(temp4);
        }
        if (wboostpercentage==50)
        {
            temp4 = temp2.mul(50);
            temp = temp.add(temp4);
        }
        
       }
       if (legendaryboost==true)
        {
        //Boots reward if user holds a legendary
        temp3 = isLegendaryOwner(msg.sender);
        if (temp3==true)
        {
        temp4 = temp.div(100);
        temp2 = temp4.mul(30); //30% boost for Legendary holder!
        temp = temp.add(temp2);
        }
        }
        if (rareboost==true)
        {
        //Boots reward if user holds a rare
        temp3 = isRareOwner(msg.sender);
        if (temp3==true)
        {
        temp4 = temp.div(100);
        temp2 = temp4.mul(20); //20% boost for holder holder!
        temp = temp.add(temp2);
        }
        }
       return temp; // 
   }
   
   
   ///Function to get the number of stakeholders in a pool
   function getnumStakers() onlyOwner public view returns(uint) 
   {
       
           return stakeholders.length;
      
   }

   //Function to audit stakers
   //Can be run by anybody and timer in future
   function auditStakers() external {
       bool wluser;
       address temp;
       uint numnfts;
      for (uint256 s = 0; s < stakeholders.length; s += 1){
          temp = stakeholders[s]; // Get address
          wluser = whitelist[temp];
          if (wluser==false)
          {
             numnfts = getNFTCount(temp); //Get NFT Count
             if (numnfts != stakes[temp]) // Stakes are not the same! Gaming?
             {
                 removeStakeholder(temp);
                 numpruned += 1; //increase Count!
             }
          } 
       }
   }
  
}///////////////////Contract END//////////////////////