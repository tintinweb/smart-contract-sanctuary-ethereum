/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-18
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
__        __                              _    ____                                  _             
 \ \      / / __ __ _ _ __  _ __   ___  __| |  / ___|___  _ __ ___  _ __   __ _ _ __ (_) ___  _ __  
  \ \ /\ / / '__/ _` | '_ \| '_ \ / _ \/ _` | | |   / _ \| '_ ` _ \| '_ \ / _` | '_ \| |/ _ \| '_ \ 
   \ V  V /| | | (_| | |_) | |_) |  __/ (_| | | |__| (_) | | | | | | |_) | (_| | | | | | (_) | | | |
    \_/\_/ |_|  \__,_| .__/| .__/ \___|\__,_|  \____\___/|_| |_| |_| .__/ \__,_|_| |_|_|\___/|_| |_|
              ____  _|_|   |_|    _               _   ___          |_|                              
             / ___|| |_ __ _| | _(_)_ __   __ _  / | / _ \                                          
   _____ ____\___ \| __/ _` | |/ / | '_ \ / _` | | || | | |_____ _____                              
  |_____|_____|__) | || (_| |   <| | | | | (_| | | || |_| |_____|_____|                             
             |____/ \__\__,_|_|\_\_|_| |_|\__, | |_(_)___/                                          
                                          |___/                                                        

/**
 * 1.0
 * Initial release
 -> Frictionless Staking
 -> Anti-Game code
 -> Whitelist Staking for left behind comps
 -> Unique token Boosting!
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

   ////Interface to the CTKN Rewards/balance BankContract
interface Bank{
 function manageClients(uint _option,bool _clearbalance,address _holder) external;
 function manageBalances(uint _option,address _user,uint _amount) external;
 function getBalance(address _user) external view returns(uint);
 function isClient(address _address) external view returns(bool);
}
 


contract WTCStaking is Context, Ownable {
 
    address public Owner;
    uint public basetotalsupply;
    //NB Addresses/////////
    address public wrappedcompnft = 0x5bB7644c3051841b67177dBd8349cf15b7a1dBb2;
    address public CTKNAddress = 0xd03e2386341Eb6eAE9c4a04C2Ba2a45d61E1d0E3;
    address public wdbaddress = 0x66826f13bE180C7B75Dc313B7Df3244311467d4A;
    address public bank = 0xC4c867F49d19447BAc655Db4980a59c9B9315934;
    //NB Variables//
    uint public basereward = 10e18; // base reward of 10 CTKN per NFT
    uint public wlreward = 3e18; // base reward of 10 CTKN per NFT
    uint public boostpernft = 5; //5%
    bool public stakingenabled;
    bool public mintpayout; //This is to mint directly from the token address
    uint private collectionfee = 760000000000000; //0.00076ETH @ $1 27/9/2022
    bool public feesenabled = true; // Enable fee!
    bool public wrapperboost = true; // Enable boost for wrappers
    uint public wboostpercentage = 10; //% of boost for wrappers
    uint public numpruned; //number of illegal stakers cleaned up
    bool public collectrewards = true; //Collect rewards
    bool public legendaryboost = true;
    bool public rareboost = true;
    bool public classicstaking; //bool to handle classic staking
    bool public allowtopup = true; //
    uint public tokencount; //Uint to store the number of tokens staked
    bool public usebank = true; //Use seperate Bank Contract
    /////////Mappings and arrays ///////////////////////
    mapping(address => uint256) internal rewards; //Rewards Collection
    mapping(address => uint256) internal stakes; ///Number of NFT's staked
    mapping(address => uint256) internal lastclaim; // Blocktime of the last claim of rewards
    mapping(address => uint256) internal startedstaking; // Initial staking date
    mapping(address => uint256) internal dailyreward; //daily reward calculated at initial staking
    mapping(address => bool) internal blockedstaker; //mapping to block staker
    mapping(address => bool) internal whitelist; //mapping to handlewhitelist stakers for other rugged projects
    mapping(uint => address) internal nftowners; // Mapping to store user entered NFT numbers
    mapping(uint => uint) internal tokenslist; // Mapping to store user entered NFT numbers
    address[] internal stakeholders; //Dynamic array to keep track of users who are staking NFT'S
    uint[] internal legendaries; //Array to hold the current legendary NFT's -> Will recieve a 30% boost
    uint[] internal rares; //Array to hold the current rare NFT's -> Will recieve an extra a 20% boost
    ///////////////////////////////////////////////////
  
    
  using SafeMath for uint;
  
  
  constructor () public {
      Owner = msg.sender; //Owner of Contract
      
      /////Initialize the Arrays for the Legendaries and the rares!
      //rares!
      rares.push(1);
      //Legendaries////////////////
      legendaries.push(2);
      //Set initial Tokenlist entiry to 0 to create initial index/////////////////////////////
      tokenslist[0] = 1; //Set the initial index to 0
      tokencount = 1; // Set the initial count to ensure for look is "<"



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
  function manageOptions(uint _option,uint _weiAmount,bool _enabled,address _addyupdate)external onlyOwner{
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
      if (_option==8)
      {
      classicstaking = _enabled; // Enable/Disable numNFT count for stake
      }
      if (_option==9)
      {
      mintpayout = _enabled; // Enable/Disable mint payouts
      }
      if (_option==10)
      {
      allowtopup = _enabled; // allow staking top ups
      }
      if (_option==11)
      {
      stakingenabled = _enabled; // Staking Enable/Disable
      }
      if (_option==12)
      {
      usebank = _enabled; // Staking Enable/Disable
      }
      if (_option==13)
      {
      bank = _addyupdate; // Bank address
      }


  }
  
  //return current fee for website
  function getFee()external view returns(uint)
  {
      return collectionfee;
  }
   
   //Get Tokens
   function isTokenInList(uint _nftnum) public view returns(bool, uint256)
   {
       for (uint256 s = 0; s <= tokencount; s += 1){
           if (tokenslist[s] == _nftnum) return (true, s); //If 0 -> That means its the default value
       }
       return (false, 0);
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
           Bank(bank).manageBalances(5,msg.sender,0);
           
           
       }
   }
   
   /////Admin functions to manage the users if needs be//
   /////This is one step further to prune the number of stakers///
   function forceRemoveStakeholder(address _stakeholder) external onlyOwner
   {
       (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder){
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
           Bank(bank).manageBalances(5,_stakeholder,0);
           rewards[_stakeholder]=0; //Set the reward to 0
           
       }

   
   }
   
   
   function stakeOf(address _stakeholder) external view returns(uint256)  ///pool 1 = Safe pool 2 = Risky
   {
       uint256 temp = 0;
       temp = stakes[_stakeholder];
       return temp;
   }

   /**
    * @notice A method to the aggregated stakes from all stakeholders.
    * @return uint256 The aggregated stakes from all stakeholders.
    */
   function totalStakes() external view returns(uint256){ ///pool 1 = Safe pool 2 = Risky
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

   //function to correct NFT Owner, if somebody stakes and then sells
   function setTokenOwnerToZero(uint _tokenid) external onlyOwner
   {
       nftowners[_tokenid]=0x0000000000000000000000000000000000000000;
   }
 
   //function to check the user for anti-game cheating
   //returns a uint to match the supposed stake!
   function verifyHolder(address _holder) public view returns(uint){
       address tempuser;
       uint arraylength = tokencount; // Number of tokens in Mapping
       uint validstakes;
       uint tokennumber;
       //loop through all staked tokens
       for (uint256 i = 0; i <= arraylength; i++) {
       tokennumber = tokenslist[i]; //Retrieve the mapping of tokens
       if(tokennumber != 0) //ensures no errornous non-existent tokens are entered
       {
       tempuser = wrappedcompanion(wrappedcompnft).ownerOf(tokennumber);
       if (tempuser==_holder) //Verify Token is the same Owner
       {
         if(nftowners[tokennumber]==tempuser)
         {
             validstakes+=1; //increment once looped
         }
       }
       }
       }
       return validstakes;
   }


   /////////Handles Manual NFT entry!
   function createStakeManual(uint256[] calldata tokenIds_) external
   {
       uint temp;
       address user;
       require(stakingenabled == true, "Staking Not Enabled!");
       /////Allow top up staking!///////
       if (allowtopup==false)
       {
       (bool currentstakeholder,) = isStakeholder(msg.sender);
       require(currentstakeholder==false,"Already Staking!");
       }
       /////////////////
       uint templength = tokenIds_.length;
       require(templength >0,"No NFT's Entered in to stake!");
       ////////////////
       bool wluser = whitelist[msg.sender];
       bool isblocked = blockedstaker[msg.sender];
       require(isblocked!=true,"Not Authorized to Stake!");
              
       if (wluser==false){
   
     for (uint256 i = 0; i < templength; i++) {
      //Verify NFT's are not blocked!!!
      (bool _isblocked,uint s) = wrapperdb(wdbaddress).isBlockedNFT(tokenIds_[i]);
      require(_isblocked==false,"Token is blocked!");
      /////Verify User is holder!//////////////////////////
      user = wrappedcompanion(wrappedcompnft).ownerOf(tokenIds_[i]);
      require(user==msg.sender,"Not holder!");
      /////Verify NFT hasnt been staked before/////////////
      require(nftowners[tokenIds_[i]]==0x0000000000000000000000000000000000000000,"Already Staked!");
      nftowners[tokenIds_[i]]=msg.sender; //Sets holder!
      //insert into tokens array to capture all staked tokens
      (bool _isStakedtoken, ) = isTokenInList(tokenIds_[i]);
       if(!_isStakedtoken) {
           tokencount +=1;
           tokenslist[tokencount]=tokenIds_[i];
       }
      }

       temp = templength;//Number of NFT's entered!
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
       dailyreward[msg.sender] = calculateDailyReward(stakes[msg.sender]);
       }
       if(wluser==true) //non Wrapper!
       {
       dailyreward[msg.sender] = wlreward; //Hardcode a reward    
       }
       //Set initial claim
       lastclaim[msg.sender] = block.timestamp;
       //Set initial stake date
       startedstaking[msg.sender] = block.timestamp;
       //Setup Banking Contract
       if(usebank==true)
           {
               Bank(bank).manageBalances(4,msg.sender,0); //Set User up as Client and balance to 0
           }
           
       
   }

   function removeStake() external
   {
       uint temp;
       uint temp2;
       uint arraylength = tokencount; //38
       address tempuser;
       uint tokennumber;
       bool wluser;
       wluser = whitelist[msg.sender];
       bool currentstakeholder = Bank(bank).isClient(msg.sender);
       require(currentstakeholder==true,"Not Staking!");
       if (wluser==false)
       {
       //AG 1) Basic NFT balance must be = or higher that stakes
       temp = getNFTCount(msg.sender);   
       require (temp >= stakes[msg.sender],"Number of NFT's too low!");
       //AG 2) Verify staked balance is = to the stored NFT's in the wallet and staked tokens match source depositor
       temp = verifyHolder(msg.sender);
       require(temp==stakes[msg.sender],"AG-NFT Count Mismatch!");
       }
       ///Clear out the token data
       //loop through all staked tokens
       stakes[msg.sender] = 0;
       for (uint256 i = 0; i <= arraylength; i++) {
       tokennumber = tokenslist[i];
       if(tokennumber != 0) //ensures no errornous non-existent tokens are entered
       {
       tempuser = wrappedcompanion(wrappedcompnft).ownerOf(tokennumber);
       if(tempuser==msg.sender)
       {
           nftowners[tokennumber] = 0x0000000000000000000000000000000000000000;
           //remove token from Mapping as its not being staked
           tokenslist[i] = 0; // Remove the token from the mapping
       }
       }
       }
       if(stakes[msg.sender] == 0) //Remove entire stake and rewards
       {
           
           //Frictionless staking///
           temp2 = calculatePayoutAmount(msg.sender);
           
               Bank(bank).manageBalances(1,msg.sender,temp2);
           
           //Set start stake date to 0
           startedstaking[msg.sender] = 0;
           //Set initialclaim date back to 0
           lastclaim[msg.sender] = 0;
           
          
        }
        removeStakeholder(msg.sender);
       
       
   }
  
    function withdrawRewards()
       payable external
   {
       uint temp;
       require (collectrewards==true,"Withdrawls are disabled!");
       if (feesenabled==true)
       {
           require(msg.value>=collectionfee,"Collection fee is not enough!");
       }
       bool currentstakeholder = Bank(bank).isClient(msg.sender);
       require(currentstakeholder==true,"Not Staking!");
       uint reward;
       bool wluser = whitelist[msg.sender]; //get Whitelist status
       if (wluser==false)
       {
       //AG 1) Basic NFT balance must be = or higher that stakes
       temp = getNFTCount(msg.sender);   
       require (temp >= stakes[msg.sender],"Number of NFT's too low!");
       //AG 2) Verify staked balance is = to the stored NFT's in the wallet and staked tokens match source depositor
       temp = verifyHolder(msg.sender);
       require(temp==stakes[msg.sender],"AG-NFT Count Mismatch!");
       }
       //block if less than 24 hours since last claim
       temp = lastclaim[msg.sender];
       require (block.timestamp >= temp + 1 minutes);
       //////////////////////////////////////////////
       reward = calculatePayoutAmount(msg.sender);
       require(reward > 0 ,"No pending rewards to collect!");
          
        Bank(bank).manageBalances(1,msg.sender,reward);
           
       rewards[msg.sender] = 0; //Clear balance to ensure correct accounting
       lastclaim[msg.sender]=block.timestamp; //Set last claim
     
      
     
   }
  
   
 
    ///Function for user to check the amount of Staking rewards
    function rewardOf(address _stakeholder) external view returns(uint256)
   {
       return calculatePayoutAmount(_stakeholder);
   }
  
   /////Functions to Verify total rewards for safe and Risky rewards
   function totalRewards() external view returns(uint256)  ////Safe Staking
   {
       uint256 _totalRewards = 0;
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           _totalRewards = _totalRewards.add(calculatePayoutAmount(stakeholders[s]));
       }
       return _totalRewards;
   }
  
   /////Function to correct the stake of a user if they need assistance -> The stake can ONLY be lowered not increased
   /////Due to the nature of frictionless, a user may sell their RCVR and then attempt to lower their stake, this could cause issues when withdrawing rewards
   
   function adjustTotalStaked(address _User,uint _newstake) external onlyOwner
   {
           require(stakes[_User] > _newstake, "Only-");
           stakes[_User] = _newstake;

   }
   function calculatePayoutAmount(address _payee) public view returns(uint)
   {
     uint temp;
     uint temp2;
     uint lastcollect;
     bool isclient = Bank(bank).isClient(_payee);
     if (isclient==true)
     {
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
   function getnumStakers() onlyOwner external view returns(uint) 
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

   //Function to return Tokens in Contract to main Token address

 //Function to move funds back out to Token Contract//
  //This is put in place to manage funds in the staking contract and be able to remove funds if needed///
  function returnTokens(uint _amountOfCTKN,address _reciever) external onlyOwner{
     CTKN(CTKNAddress).transfer(_reciever,_amountOfCTKN);
  }

  //Pull ETH from contract
  function withdrawETH() public onlyOwner{
       msg.sender.transfer(address(this).balance);
  }
  
}///////////////////Contract END//////////////////////