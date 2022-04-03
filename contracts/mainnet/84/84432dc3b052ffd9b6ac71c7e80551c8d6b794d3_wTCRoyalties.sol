/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

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
 __          __                             _    _____                                  _             
 \ \        / /                            | |  / ____|                                (_)            
  \ \  /\  / / __ __ _ _ __  _ __   ___  __| | | |     ___  _ __ ___  _ __   __ _ _ __  _  ___  _ __  
   \ \/  \/ / '__/ _` | '_ \| '_ \ / _ \/ _` | | |    / _ \| '_ ` _ \| '_ \ / _` | '_ \| |/ _ \| '_ \ 
    \  /\  /| | | (_| | |_) | |_) |  __/ (_| | | |___| (_) | | | | | | |_) | (_| | | | | | (_) | | | |
     \/  \/ |_|  \__,_| .__/| .__/ \___|\__,_|  \_____\___/|_| |_| |_| .__/ \__,_|_| |_|_|\___/|_| |_|
                      | |   | |                                      | |                              
  _____               |_| _ |_|          _____            _          |_|     _                        
 |  __ \                 | | |          / ____|          | |                | |                       
 | |__) |___  _   _  __ _| | |_ _   _  | |     ___  _ __ | |_ _ __ __ _  ___| |_                      
 |  _  // _ \| | | |/ _` | | __| | | | | |    / _ \| '_ \| __| '__/ _` |/ __| __|                     
 | | \ \ (_) | |_| | (_| | | |_| |_| | | |___| (_) | | | | |_| | | (_| | (__| |_                      
 |_|  \_\___/ \__, |\__,_|_|\__|\__, |  \_____\___/|_| |_|\__|_|  \__,_|\___|\__|                     
               __/ |             __/ |                                                                
              |___/             |___/                                                                
/**
 - This is designed to handle the royalty distributions to holders
  - Royalties are split 50/50 with treasury and holders by default. Fees are adjustable
 */

pragma solidity ^0.5.0;


interface wrappedcompanion{
  function balanceOf(address owner) external view returns (uint256);
}
interface wrapperdb {
    function isHolder(address _address) external view returns(bool);
    function getWrappedStatus(address _migrator) external view returns(bool);
    function getNumHolders(uint _feed) external view returns(uint);
    function getHolderAddress(uint _index) external view returns(address payable);
    function setUserStatus(address _wrapper,uint _status,bool _haswrapped) external;
    function manageHolderAddresses(bool status,address _holder) external;
    
}
 


contract wTCRoyalties is Context, Ownable {
 
    address public wrappednft = 0x16e2220Bba4a2c5C71f628f4DB2D5D1e0D6ad6e0;
    address public dbcontract = 0x131Bc921fDf520E62eca46c1011Fc885d6B29B9f;
    address public Owner;
    address payable public multisig = 0xCEcB4B16bF486a9B786A2a981a43de8647dCb1C0;
    address payable public payee;
    address payable public charity = 0x8B99F3660622e21f2910ECCA7fBe51d654a1517D;
    uint public joiningfee = 10000000000000000; //0.01ETH A joining fee
    bool public royaltydistribution; ///Enable/Disable Rewards
    bool public anonrebalance; //USed to block anons from running a rebalance
    bool public adjustforcontract;
    uint public amounttoholders;
    uint public fixedpayoutamount;
    uint public lastrebalancetime; //This is the blocktime of the last split
    uint public amounttotreasury;
    uint public amounttocharity;
    uint public totalpayouts;
    uint public setfeed =2; //Default to array length
    uint public totaltreasureypayouts;
    uint public numberofclaims;
    uint public numholders;
    bool public holdersoverride; //Default to false
    bool public masspayoutenabled = true; // A reflection for the users if needs be!
    uint public defaultfee = 2; //the fee set for a user when the buy joining

    //NB Addresses/////////
    /////Mappings///////
    mapping(address => uint) internal payouttime;
    
  using SafeMath for uint;
  
  
  constructor () public {
      Owner = msg.sender; //Owner of Contract
      lastrebalancetime = block.timestamp; //Set the initial to deploy time
            
  }
 
  ///Sets the fees
  function setFeesAndNB(int option,uint _value) external onlyOwner
  {
      if (option==1)
      {
          joiningfee = _value;
      }
      if(option==2)
      {
          defaultfee = _value;
      }
      if(option==3)
      {
          setfeed = _value;
      }
      
  }
  function forceNumHolders(bool _onoroff,uint _numholders) external onlyOwner{
      holdersoverride = _onoroff;
      numholders = _numholders;
  }
    
   ///Sets the contract address of the NFT itself//////
  function setNFTAddress(address _nftaddress) external onlyOwner {
    wrappednft = _nftaddress;
  }

   ///Sets the Multi-Sig address//////
  function setMultiSig(address payable _multiaddress) external onlyOwner {
    multisig = _multiaddress;
  }

  ///Sets the contract address of the DB //////
  function setDBAddress(address _dbaddress) external onlyOwner {
   dbcontract = _dbaddress;
  }

    ///Function to enable/disable the Royalty Payouts
    function onoffRoyalties(bool _enabled) external onlyOwner{
        royaltydistribution = _enabled;
    }
    //Function to enable mass payout of royalties
    function enableMassPayout(bool _onoroff) external onlyOwner{
        masspayoutenabled = _onoroff;
    } 
    //Function to enable anon rebalance
    function enableAnonRebalance(bool _onoroff) external onlyOwner{
       anonrebalance = _onoroff;
    } 
    //Function to enable anon rebalance
    function enableAdjust(bool _onoroff) external onlyOwner{
       adjustforcontract = _onoroff;
    } 

   ///Function for user to check the amount of ETH roughly to be paid out
    function rewardOf() external view returns(uint)
   {
       uint temp;
       temp = fixedpayoutamount;
       if (block.timestamp > lastrebalancetime + 24 hours )
       {
           temp = 9999999; ///A rebalance is due!
       }
    return temp;

   }
   
   ////Function to handle the payout of royalties
   function claim() external {
       //Get the amounts of ETH required for reflection
       uint ETHsplit;
       bool iseligable;
       uint lastpaid;
       
       if(msg.sender!=Owner)
       {
       require(royaltydistribution==true,"Royalties not enabled!");
       lastpaid = payouttime[msg.sender];
       iseligable = canClaim(msg.sender);
       require(iseligable==true,"You are not eligable to make a claim");
       require(block.timestamp > lastpaid + 24 hours,"You are only able to claim once every 24 hours!");
       } 
       ///Determine if a rebalance is needed//
       if (block.timestamp > lastrebalancetime + 24 hours )
       {
           lastrebalancetime = block.timestamp;
           ETHsplit = address(this).balance;
           ETHsplit = ETHsplit.div(100); //divides it into 1% parts
           amounttoholders = ETHsplit.mul(50);
           amounttotreasury = ETHsplit.mul(49); //Leave 1% in wallet as a buffer
           ////send money to treasury////
           multisig.transfer(amounttotreasury);
           //Get the number of holders in the array to determine the payout///
           if (holdersoverride==false) //This is a failsafe to ensure that if needs be the num holders is able to be a fixed amount
           {
           if(setfeed==1)
           {
           numholders = wrapperdb(dbcontract).getNumHolders(1); //returns number of holders based on wraps
           }
           if(setfeed==2)
           {
           numholders = wrapperdb(dbcontract).getNumHolders(2); //returns length of the array (Should be value -1 (-1 for the NFT contract itself)
           }
           ///This is to accomodate for the wTc contract being considered as a holder. Due to the nature of the wrapper, the numholders is  +1.
           ///Having an extra holder adds a buffer of funds in the contract
           if(adjustforcontract==true)
           {
               numholders = numholders - 1;
           }

           }
           fixedpayoutamount = amounttoholders.div(numholders);

       }

       ///mass payout for holders if required
       if (masspayoutenabled==true && msg.sender==Owner) //Only the owner is able to do this!
       {
        address payable tempaddress;
        for (uint256 s = 0; s < numholders; s += 1)
        {
           tempaddress = wrapperdb(dbcontract).getHolderAddress(s);
           //Are they eligable?//
           iseligable = canClaim(tempaddress);
           if (iseligable==true)
           {
           //first verify 24 hour period
           lastpaid = payouttime[tempaddress];
           if(block.timestamp > lastpaid + 24 hours)
           {
           
           
           tempaddress.transfer(fixedpayoutamount);
           ///Mark the users time for claim
            payouttime[tempaddress] = block.timestamp;
           }
           }
       }
       }
       
       if(msg.sender!=Owner)
       {
       msg.sender.transfer(fixedpayoutamount);
       ///Mark the users time for claim
       payouttime[msg.sender] = block.timestamp;
       }
       
       
       totalpayouts += fixedpayoutamount;
       numberofclaims +=1;
      
       }
    
    ///Rebalance function which can be run manually,is able to be run 
    function forceRebalance() external {
         if(msg.sender!=Owner)
         {
         require (block.timestamp > lastrebalancetime + 24 hours,"Rebalance is not due!");
         }
         if(anonrebalance==false)
         {
             require(msg.sender==Owner,"Not Authorized");
         }
           uint ETHsplit;
           lastrebalancetime = block.timestamp;
           ETHsplit = address(this).balance;
           ETHsplit = ETHsplit.div(100); //divides it into 1% parts
           amounttoholders = ETHsplit.mul(50);
           amounttotreasury = ETHsplit.mul(49);
           ////send money to treasury////
           multisig.transfer(amounttotreasury);
           //Get the number of holders in the array to determine the payout///
           if (holdersoverride==false) //This is a failsafe to ensure that if needs be the num holders is able to be a fixed amount
           {
           numholders = wrapperdb(dbcontract).getNumHolders(2); //returns length of the array (Should be value -1 (-1 for the NFT contract itself)
           }
           fixedpayoutamount = amounttoholders.div(numholders);//
    }
       //returns stats from reflecting
    function Stats(uint option) view external returns(uint)
    {
        uint temp;
        if (option==1)
        {
         temp = totalpayouts;   
        }
        if (option==2)
        {
         temp = numberofclaims;      
        }
        if (option==3)
        {
         temp = totaltreasureypayouts;      
        }
        
        return temp;
    }
    ///Verify that a user is eligable to claim
    function canClaim(address _wallet) public view returns(bool)
    {
        bool temp; //defaults to false
        uint numberofNFT;
        //////First verify that the user has wrapped...
        temp = wrapperdb(dbcontract).getWrappedStatus(_wallet);
        /////Are they still holding?
        numberofNFT = wrappedcompanion(wrappednft).balanceOf(_wallet);
        if (temp==true && numberofNFT > 0)
        {
            temp = true;
        }
        return temp;
    }
    ///Allows buyers on OS to join fees...but only afer 24 hours!
    function joinRoyalty() payable external{
        uint numberofnft;
        bool temp;
        require(msg.value >= joiningfee,"Joining fee not met!");
        numberofnft = wrappedcompanion(wrappednft).balanceOf(msg.sender);
        require(numberofnft>0,"You do not hold any wrapped NFTs");
        temp = canClaim(msg.sender);
        require(temp==false,"You are already eligable");
        wrapperdb(dbcontract).setUserStatus(msg.sender,defaultfee,true);
        //add user to array!
        wrapperdb(dbcontract).manageHolderAddresses(true,msg.sender);
        payouttime[msg.sender] = block.timestamp;
    }
    ////To recieve ETH
    function () external payable {
    
  }
     
  
   
  
}///////////////////Contract END//////////////////////