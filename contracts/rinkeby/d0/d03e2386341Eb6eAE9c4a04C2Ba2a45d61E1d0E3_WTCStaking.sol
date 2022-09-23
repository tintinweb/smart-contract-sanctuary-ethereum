/**
 *Submitted for verification at Etherscan.io on 2022-09-22
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
 
    address public CTKNAddress = 0x5F6B7E4a565C745Ccb0C34A80C2F217A8e981AD7 ;
    address public Owner;
    uint public basetotalsupply;
    bool public whalelimiter = true;  ////Introducing a way to cap the reward if a whale is slowly bleeding off funds///
    //NB Addresses/////////
    address public wrappedcompnft = 0xc1A3bfd6678Ce5fb16db9A544cBd279850baA81D;
    //NB Variables//
    uint public basereward = 10e18; // base reward of 10 CTKN per NFT
    uint public boostpernft = 5; //5%
    bool public stakingenabled = true;
    uint public wtcsupply; //default of 555!
    bool public mintpayout = true;
    /////////Mappings and arrays ///////////////////////
    mapping(address => uint256) internal rewards; //Rewards Collection
    mapping(address => uint256) internal stakes; ///Number of NFT's staked
    mapping(address => uint256) internal lastclaim; // Blocktime of the last claim of rewards
    mapping(address => uint256) internal dailyreward; //daily reward calculated at initial staking
    mapping(address => bool) internal blockedstaker; //mapping to block staker
    address[] internal stakeholders; //Dynamic array to keep track of users who are staking NFT'S
    ///////////////////////////////////////////////////
  
    
  using SafeMath for uint;
  
  
  constructor () public {
      Owner = msg.sender; //Owner of Contract
      wtcsupply = 555;
  }
  ///Sets the contract address of the RCVR Token//////
  function setCTKNAddress(address _CTKNaddress) external onlyOwner {
    CTKNAddress = _CTKNaddress;
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
  
   function createSafeStake() external
   {
       uint temp;
       (bool currentstakeholder,) = isStakeholder(msg.sender);
       require(stakingenabled == true, "Staking Not Enabled!");
       require(currentstakeholder==false,"Already Staked!");
       //get numberofNFTs to stake
       temp = getNFTCount(msg.sender);
       require(temp > 0,"Error,No NFT's to Stake!");
       //Add user to StakeDB
       addStakeholder(msg.sender);
       stakes[msg.sender] = stakes[msg.sender].add(temp);
       //Calculate Reward//
       dailyreward[msg.sender] = calculateDailyReward(temp);
       //Set initial claim
       lastclaim[msg.sender] = block.timestamp;
           
       
   }
   
  
   function removeStake() public
   {
       uint temp;
       uint temp2;
       temp = getNFTCount(msg.sender);
       require (temp >= stakes[msg.sender],"Error - NFT count too low to withdraw");
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
           
           
          
        }
       
       
   }
  
    function withdrawRewards()
       public
   {
       
       uint reward;
  
       uint temp = getNFTCount(msg.sender);   
       require (temp >= stakes[msg.sender],"Number of NFT's too low!");
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
       uint basesplit = basereward.div(100); 
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
       return temp; // 
   }
   
   
   ///Function to get the number of stakeholders in a pool
   function getnumStakers() onlyOwner public view returns(uint) 
   {
       
           return stakeholders.length;
      
   }
   
  
}///////////////////Contract END//////////////////////