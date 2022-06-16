/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

//SPDX-License-Identifier:Unlicensed
pragma solidity ^0.6.0;

/**
 * @title SafeMath
 * @dev   Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256){
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b,"Calculation error");
        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256){
        // Solidity only automatically asserts when dividing by 0
        require(b > 0,"Calculation error");
        uint256 c = a / b;
        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        require(b <= a,"Calculation error");
        uint256 c = a - b;
        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        require(c >= a,"Calculation error");
        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256){
        require(b != 0,"Calculation error");
        return a % b;
    }
}

/**
 * @title IToken
 * @dev   Contract interface for token contract 
 */
abstract contract IToken {
    function balanceOf(address) public virtual returns (uint256);
    function transfer(address, uint256) public virtual returns (bool);
    function transferFrom(address, address, uint256) public virtual returns (bool);
    function approve(address , uint256) public virtual returns (bool);
}

contract Ownable {

  address public _owner;                              // variable for Owner of the Contract.

  /*
  * ---------------------------------------------------------------------------------------------------------------------------
  * Functions for owner.
  * ---------------------------------------------------------------------------------------------------------------------------
  */

   /**
   * @dev get address of smart contract owner
   * @return address of owner
   */
   function getowner() public view returns (address) {
     return _owner;
   }

   /**
   * @dev modifier to check if the message sender is owner
   */
   modifier onlyOwner() {
     require(isOwner(),"You are not authenticate to make this transfer");
     _;
   }

   /**
   * @dev Internal function for modifier
   */
   function isOwner() internal view returns (bool) {
      return msg.sender == _owner;
   }

   /**
   * @dev Transfer ownership of the smart contract. For owner only
   * @return request status
   */
   function transferOwnership(address newOwner) public onlyOwner returns (bool){
      _owner = newOwner;
      return true;
   }
}

/**
 * @title Lending&Borrowing
 * @dev   Lending&Borrowing Contract 
 */
contract LendingBorrowing is Ownable {

  using SafeMath for uint256;

  /*
  * ---------------------------------------------------------------------------------------------------------------------------
  * Functionality of Constructor
  * ---------------------------------------------------------------------------------------------------------------------------
  */
  
  // constructor to declare owner of the contract during time of deploy  
  constructor() public {
     _owner = msg.sender;
  }

  /*
  * ---------------------------------------------------------------------------------------------------------------------------
  * Functionality of Interface
  * ---------------------------------------------------------------------------------------------------------------------------
  */
  
  // Interface declaration for contract
  IToken itoken;
    
  // function to set Token Contract Address for Token Transfer Functions
  function setTokenContractAddress(address tokenContractAddress) external onlyOwner returns(bool){
    itoken = IToken(tokenContractAddress);
    return true;
  }
  
  // function to withdraw token from the contract
  function withdrawToken(uint256 amount) external onlyOwner returns(bool){
    require(amount > 0,"Please input valid value and tey again!!!");
    itoken.transfer(msg.sender,amount);
    return true;
  } 
  
  // function to withdraw native token from the contract
  function withdrawNativeToken() external onlyOwner returns(bool){
    msg.sender.transfer(address(this).balance);
    return true;
  }
  
  /*
  * ----------------------------------------------------------------------------------------------------------------------------
  * Variable, Mapping for Lender Functionality
  * ----------------------------------------------------------------------------------------------------------------------------
  */
  
  // mapping for users with id => address Address
  mapping (uint256 => address payable) private _lenderAddress;
  
  // mapping for user with address => id id
  mapping (address => uint256[]) private _lenderId;
  
  // mapping for users with id => Time
  mapping (uint256 => uint256) private _lenderStartTime;

  // mapping for users with id => End Time
  mapping (uint256 => uint256) private _lenderEndTime;

  //
  mapping(uint256=>uint256) private _lenderTotalDays;

  // mapping for users with id => Amount to keep track for amount by user 
  mapping (uint256 => uint256) private _lenderAmount;
   
  // mapping for users with id => Status
  mapping (uint256 => bool) private _lenderTransactionstatus; 

  // variable to keep count of lender
  uint256 private _lenderCount = 0;

  // variable for lender time management
  uint256 private _lenderTime;
  
  // variable for total native token in contract
  uint256 public totalNativeAmount = 0;

  // variable for total token in contract
  uint256 public totalTokenAmount = 0;
  
  //
  enum lenderStatus {PENDING, OPEN, CLOSED}
  
  //
  mapping (uint256 => lenderStatus) private _currentLenderStatus;
  
  //
  enum lenderType {ETH, TOKEN}
  
  //
  mapping (uint256 => lenderType) private _currentLenderType;


  /*
  * ----------------------------------------------------------------------------------------------------------------------------
  * Variable, Mapping for Borrower Functionality
  * ----------------------------------------------------------------------------------------------------------------------------
  */
  
  // mapping for users with id => address Address
  mapping (uint256 => address payable) private _borrowerAddress;
  
  // mapping for user with address => id id
  mapping (address => uint256[]) private _borrowerId;
  
  // mapping for users with id => Time
  mapping (uint256 => uint256) private _borrowerStartTime;

  // mapping for users with id => End Time
  mapping (uint256 => uint256) private _borrowerEndTime;

  // 
  mapping(uint256=>uint256) private _borrowerTotalDays;

  // mapping for user with id => borrowerAmount
  mapping (uint256 => uint256) private _borrowerAmount;

  //
  mapping (uint256 => uint256) private _borrowerNewAmount;

  // mapping for users with id => Amount to keep track for amount by user 
  mapping (uint256 => uint256) private _borrowerCollatoralAmount;
  
  // mapping for users with id => Status
  mapping (uint256 => bool) private _borrowerTransactionstatus; 

  // variable to keep count of lender
  uint256 private _borrowerCount = 0;

  // variable for lender time management
  uint256 private _borrowerTime;
  
  // variable for total native token in contract
  uint256 public borrowerTotalTokenAmount = 0;

  // variable for total native in contract
  uint256 public borrowerTotalNativeAmount = 0;

  //
  enum borrowerStatus {OPEN, CLOSED}

  //
  mapping (uint256 => borrowerStatus) private _currentBorrowerStatus;
 
  //
  enum borrowerType {ETH, TOKEN}
  
  //
  mapping (uint256 => borrowerType) private _currentBorrowerType;

  uint256 public TOKEN_INTEREST  = 5;       // variable constant to manage token interest
  uint256 public NATIVE_INTEREST = 7;       // variable constant to manage native token interest

  // function to calculate reward for the message sender for token
  function getTokenInterestById(uint256 id) public view returns(uint256){
    if(_borrowerTotalDays[id] == 30) {
        return (_borrowerTotalDays[id]*TOKEN_INTEREST/10000);
    } else if(_borrowerTotalDays[id] == 90) {
               return (_borrowerTotalDays[id]*TOKEN_INTEREST/10000);
      } else if(_borrowerTotalDays[id] == 180) { 
                 return (_borrowerTotalDays[id]*TOKEN_INTEREST/10000);
        } else if(_borrowerTotalDays[id] == 360) { 
                   return (_borrowerTotalDays[id]*TOKEN_INTEREST/10000);
          } else {
              return 0;
          }
  }

  // function to calculate penalty for the message sender for token
  function getNativeTokenInterestById(uint256 id) public view returns(uint256){
    if(_borrowerTotalDays[id] == 30) {
        return (_borrowerTotalDays[id]*NATIVE_INTEREST/10000);
    } else if(_borrowerTotalDays[id] == 90) {
               return (_borrowerTotalDays[id]*NATIVE_INTEREST/10000);
      } else if(_borrowerTotalDays[id] == 180) { 
                 return (_borrowerTotalDays[id]*NATIVE_INTEREST/10000);
        } else if(_borrowerTotalDays[id] == 360) { 
                   return (_borrowerTotalDays[id]*NATIVE_INTEREST/10000);
          } else {
              return 0;
          }
  }


  /*
  * -----------------------------------------------------------------------------------------------------------------------------------
  * Functions for Lender Functionality
  * -----------------------------------------------------------------------------------------------------------------------------------
  */

  // need to make modifier to check days 
 
  // function to performs 
  function lenderPayOffInNative(uint256 time) external payable returns(bool){
    require(time > 0, "Invalid Value , Please Try Again!!!");
    require(msg.value > 0, "Invalid Amount, Please Try Again!!!");
    _lenderTime = now + (time * 1 days);
    _lenderCount = _lenderCount + 1 ;
    _lenderAddress[_lenderCount] = msg.sender;
    _lenderId[msg.sender].push(_lenderCount);
    _lenderStartTime[_lenderCount] = now;
    _lenderEndTime[_lenderCount] = _lenderTime;
    _lenderTotalDays[_lenderCount] = time;
    _lenderAmount[_lenderCount] = msg.value;
    //iwtoken.transfer(msg.sender,_lenderAmount[_lenderCount]);
    totalNativeAmount = totalNativeAmount.add(msg.value);
    _currentLenderStatus[_lenderCount] = lenderStatus.PENDING;
    _currentLenderType[_lenderCount] = lenderType.ETH;
    _lenderTransactionstatus[_lenderCount] = false;
    return true;
  }

   // function to performs 
  function lenderPayOffInToken(uint256 tokens, uint256 time) external returns(bool){
    require(time > 0, "Invalid Value , Please Try Again!!!");
    require(tokens > 0, "Invalid token Amount, Please Try Again!!!");
    _lenderTime = now + (time * 1 days);
    _lenderCount = _lenderCount + 1 ;
    _lenderAddress[_lenderCount] = msg.sender;
    _lenderId[msg.sender].push(_lenderCount);
    _lenderStartTime[_lenderCount] = now;
    _lenderEndTime[_lenderCount] = _lenderTime;
    _lenderTotalDays[_lenderCount] = time;
    _lenderAmount[_lenderCount] = tokens;
    itoken.transferFrom(msg.sender, address(this),tokens);
    //iwtoken.transfer(msg.sender,tokens);
    totalTokenAmount = totalTokenAmount.add(tokens);
    _currentLenderStatus[_lenderCount] = lenderStatus.PENDING;
    _currentLenderType[_lenderCount] = lenderType.TOKEN;
    _lenderTransactionstatus[_lenderCount] = false;
    return true;
  }

  // function to performs 
  function lenderWithdrawinNative(uint256 id) external returns(bool){
    require(id > 0, "Invalid Value , Please Try Again!!!");
    require(_lenderAddress[id] == msg.sender,"No Lender Information found on this address and ID");
    require(_lenderTransactionstatus[id] != true,"Either Amount are already withdrawn or blocked by admin");
    if(_currentLenderStatus[id] == lenderStatus.OPEN){
       _lenderAddress[id].transfer(_lenderAmount[id]);        
       _lenderTransactionstatus[_lenderCount] = true;
    } else {
        return false;
      }
    return true; 
  }

  //
  function lenderWithdrawInToken(uint256 id) external returns(bool){
    require(id > 0, "Invalid Value , Please Try Again!!!");
    require(_lenderAddress[id] == msg.sender,"No Lender Information found on this address and ID");
    require(_lenderTransactionstatus[id] != true,"Either Amount are already withdrawn or blocked by admin");
    if(_currentLenderStatus[id] == lenderStatus.OPEN){
       itoken.transfer(address(this),_lenderAmount[id]);        
       _lenderTransactionstatus[_lenderCount] = true;
    } else {
        return false;
      }
    return true; 
  }

  // function to get lender count
  function getLenderCount() public view returns(uint256){
    return _lenderCount;
  }
  
  // function to get total native token
  function getTotalNativeAmount() public view returns(uint256){
    return totalNativeAmount;
  }

  // function to get total native token
  function getTotalTokenAmount() public view returns(uint256){
    return totalTokenAmount;
  }

  /*
  * -----------------------------------------------------------------------------------------------------------------------------------
  * Functions for Borrower Functionality
  * -----------------------------------------------------------------------------------------------------------------------------------
  */ 
  
  //
  function loanTakeOffInToken(uint256 tokens, uint256 time) external payable returns(bool){ 
    _borrowerTime = now + (time * 1 days);
    _borrowerCount = _borrowerCount + 1 ;
    _borrowerAddress[_borrowerCount] = msg.sender;
    _borrowerId[msg.sender].push(_borrowerCount);
    _borrowerStartTime[_borrowerCount] = now;
    _borrowerEndTime[_borrowerCount] = _borrowerTime;
    _borrowerTotalDays[_borrowerCount] = time;
    _borrowerAmount[_borrowerCount] = tokens;  
    _borrowerNewAmount[_borrowerCount] = msg.value;
    _borrowerCollatoralAmount[_borrowerCount] = msg.value.sub(getTokenInterestById(_borrowerCount));
    _lenderStartTime[_borrowerCount] = now;
    _lenderEndTime[_borrowerCount] = _borrowerTime;
    //iwtoken.transfer(msg.sender,_borrowerCollatoralAmount[_borrowerCount]);
    itoken.transfer(msg.sender,tokens);
    //itoken.transfer(msg.sender,tokens.add(getTokenInterestById(_borrowerCount)));
    borrowerTotalTokenAmount = borrowerTotalTokenAmount.add(tokens);
    borrowerTotalNativeAmount = borrowerTotalNativeAmount.add(msg.value);
    _currentBorrowerStatus[_borrowerCount] = borrowerStatus.OPEN;
    _currentBorrowerType[_borrowerCount] = borrowerType.TOKEN;
    _lenderTransactionstatus[_borrowerCount] = false;
    return true;
  }  

  //
  function loanTakeOffInNativeToken(uint256 tokens, uint256 time) external payable returns(bool){ 
    _borrowerTime = now + (time * 1 days);
    _borrowerCount = _borrowerCount + 1 ;
    _borrowerAddress[_borrowerCount] = msg.sender;
    _borrowerId[msg.sender].push(_borrowerCount);
    _borrowerStartTime[_borrowerCount] = now;
    _borrowerEndTime[_borrowerCount] = _borrowerTime;
    _borrowerTotalDays[_borrowerCount] = time;
    _borrowerAmount[_borrowerCount] = msg.value; 
    _borrowerNewAmount[_borrowerCount] = tokens; 
    _borrowerCollatoralAmount[_borrowerCount] = tokens.sub(getNativeTokenInterestById(_borrowerCount));
    _lenderStartTime[_borrowerCount] = now;
    _lenderEndTime[_borrowerCount] = _borrowerTime;
    //iwtoken.transfer(msg.sender,_borrowerCollatoralAmount[_borrowerCount]);
    _borrowerAddress[_borrowerCount].transfer(msg.value);
    itoken.transferFrom(msg.sender, address(this), tokens);        
    //itoken.transfer(msg.sender,msg.value);
    borrowerTotalTokenAmount = borrowerTotalTokenAmount.add(tokens);
    borrowerTotalNativeAmount = borrowerTotalNativeAmount.add(msg.value);
    _currentBorrowerStatus[_borrowerCount] = borrowerStatus.OPEN;
    _currentBorrowerType[_borrowerCount] = borrowerType.ETH;
    _lenderTransactionstatus[_borrowerCount] = false;
    return true;
  }

  // function to get Borrower count
  function getBorrowerCount() public view returns(uint256){
    return _borrowerCount;
  }
  
  // function to get total native token
  function getBorrowerTotalNativeAmount() public view returns(uint256){
    return borrowerTotalNativeAmount;
  }

  // function to get total native token
  function getBorrowerTotalTokenAmount() public view returns(uint256){
    return borrowerTotalTokenAmount;
  }

  /*
  * ----------------------------------------------------------------------------------------------------------------------------------
  * Get Functions for Lender Functionality
  * ----------------------------------------------------------------------------------------------------------------------------------
  */

  // function to get address by id
  function getLenderAddressById(uint256 id) external view returns (address){
    require(id <= _lenderCount,"Unable to reterive data on specified id, Please try again!!");
    return _lenderAddress[id];
  }
  
  // function to get  id by address
  function getLenderIdByAddress(address add) external view returns(uint256[] memory){
    require(add != address(0),"Invalid Address, Pleae Try Again!!!");
    return _lenderId[add];
  }
  
  // function to get Starting time by id
  function getLenderStartTimeById(uint256 id) external view returns(uint256){
    require(id <= _lenderCount,"Unable to reterive data on specified id, Please try again!!");
    return _lenderStartTime[id];
  }
  
  // function to get End time by id
  function getLenderEndTimeById(uint256 id) external view returns(uint256){
    require(id <= _lenderCount,"Unable to reterive data on specified id, Please try again!!");
    return _lenderEndTime[id];
  }

   // function to get lender Total Days by Id
  function getLenderTotalDaysById(uint256 id) external view returns(uint256){
    require(id <= _lenderCount,"Unable to reterive data on specified id, Please try again!!");
    return _lenderTotalDays[id];
  }
  
  // function to get user amount token by id
  function getLenderAmountById(uint256 id) external view returns(uint256){
    require(id <= _lenderCount,"Unable to reterive data on specified id, Please try again!!");
    return _lenderAmount[id];
  }

  // function to get transactionstatus by id
  function getLenderTransactionStatus(uint256 id) external view returns(bool){
    require(id <= _lenderCount,"Unable to reterive data on specified id, Please try again!!");
    return _lenderTransactionstatus[id];
  }

  // funtion to get
  function getLenderType(uint256 id) external view returns(lenderType){
    require(id <= _lenderCount,"Unable to reterive data on specified id, Please try again!!");
    return _currentLenderType[id];
  }

  // function to get 
  function getLenderStatus(uint256 id) external view returns(lenderStatus){
    return _currentLenderStatus[id];
  }

  /*
  * ----------------------------------------------------------------------------------------------------------------------------------
  * Get Functions for Borrower Functionality
  * ----------------------------------------------------------------------------------------------------------------------------------
  */

  // function to get address by id
  function getborrowerAddressById(uint256 id) external view returns (address){
    require(id <= _borrowerCount,"Unable to reterive data on specified id, Please try again!!");
    return _borrowerAddress[id];
  }
  
  // function to get  id by address
  function getborrowerIdByAddress(address add) external view returns(uint256[] memory){
    require(add != address(0),"Invalid Address, Pleae Try Again!!!");
    return _borrowerId[add];
  }
  
  // function to get Starting time by id
  function getborrowerStartTimeById(uint256 id) external view returns(uint256){
    require(id <= _borrowerCount,"Unable to reterive data on specified id, Please try again!!");
    return _borrowerStartTime[id];
  }
  
  // function to get End time by id
  function getborrowerEndTimeById(uint256 id) external view returns(uint256){
    require(id <= _borrowerCount,"Unable to reterive data on specified id, Please try again!!");
    return _borrowerEndTime[id];
  }

   // function to get lender Total Days by Id
  function getborrowerTotalDaysById(uint256 id) external view returns(uint256){
    require(id <= _borrowerCount,"Unable to reterive data on specified id, Please try again!!");
    return _borrowerTotalDays[id];
  }
  
  // function to get user amount token by id
  function getborrowerAmountById(uint256 id) external view returns(uint256){
    require(id <= _borrowerCount,"Unable to reterive data on specified id, Please try again!!");
    return _borrowerAmount[id];
  }

  // function to get user collatoral amount token by id
  function getborrowerCollatoralAmountById(uint256 id) external view returns(uint256){
    require(id <= _borrowerCount,"Unable to reterive data on specified id, Please try again!!");
    return _borrowerCollatoralAmount[id];
  }

  // function to ge
  function getBorrowerNewAmount(uint256 id) external view returns(uint256){
    require(id <= _borrowerCount,"Unable to reterive data on specified id, Please try again!!");
    return _borrowerNewAmount[id];
  }

  // function to get transactionstatus by id
  function getborrowerTransactionStatus(uint256 id) external view returns(bool){
    require(id <= _borrowerCount,"Unable to reterive data on specified id, Please try again!!");
    return _borrowerTransactionstatus[id];
  }

  // funtion to get
  function getBorrowerType(uint256 id) external view returns(borrowerType){
    require(id <= _borrowerCount,"Unable to reterive data on specified id, Please try again!!");
    return _currentBorrowerType[id];
  }

  // function to ge
  function getBorrowerStatus(uint256 id) external view returns(borrowerStatus){
    require(id <= _borrowerCount,"Unable to reterive data on specified id, Please try again!!");
    return _currentBorrowerStatus[id];
  }

}