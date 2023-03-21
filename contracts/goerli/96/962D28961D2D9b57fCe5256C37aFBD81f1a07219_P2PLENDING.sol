// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;
 // Openzeppelin contracts to improve security of the contract 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract P2PLENDING is Ownable{
  // using the safeMath contract to make sure all our calculations using uint is correct
  using SafeMath for uint;
  //address of the person that asked for the loan thereby activating the credit contract 
  address borrower;
  //Amount of the token requested by the borrower.
  uint requestedAmount;
  //Amount that would be returned by the borrower including the interest
  uint returnAmount;
  //Amount repaid currently.
  uint repaidAmount;
  //Credit interest
  uint interest;
  //Number of times the credit should be repayed 
  uint requestedNumberRepayment;
  //Remaining number of repayment cycle left
  uint remainingRepayment;
  //value of each repayment installment
  uint repaymentInstallment;
  //total number of money returned to the lender 
  uint lenderReturnAmount;
  //the timestamp that the credit was requested
  uint requestedDate;
  //Date the loan should be paid
  uint dateLoanPaid;
  //Timestamp of the last repayment date
  uint lastRepaymentDate;
  //The amount of collateral deposited by the borrower
  uint collateralAmount;
  //Active state of the credit
  bool active=false;
  //bool to ensure withdrawn variable is false when new loan is asked for
  bool withdrawn=false;
  



  /* Stages that every credit contract gets trough.
      *   investment - During this state only investments are allowed.
      *   repayment - During this stage only repayments are allowed.
      *   interestReturns - This stage gives investors opportunity to request their returns.
      *   expired - This is the stage when the contract is finished its purpose.
      *   collateralReturns-This is the stage where the collateral of the borrowe is returned after repayment
      *   interestReturns-This is when the lenders are paid there interest and also refunded any extra fund they have deposited into the contract.
      *   expired- This signals the end of the contract 
  */

  enum State {depositing,investment,repayment,collateralReturns,interestReturns,expired}
  State state;

  //Lenders for the credit
  
  mapping(address => bool) public lenders;
  //Amount of token each investor is putting into the pool
  mapping(address=> uint)  public lendersInvestedAmount;
  //storing the number of lenders;
  uint lendersCount=0;
  //Revoke votes count
  

  // Events
  event LogCreditInitialized(address indexed _address, uint indexed timestamp);
  event LogCreditStateChanged(State indexed state, uint indexed timestamp);
  event LogCreditStateActiveChanged(bool indexed active, uint indexed timestamp);
  

  event LogBorrowerWithdrawal(address indexed _address, uint indexed _amount, uint indexed timestamp);
  event LogBorrowerRepaymentInstallment(address indexed _address, uint indexed _amount, uint indexed timestamp);
  event LogBorrowerRepaymentFinished(address indexed _address, uint indexed timestamp);
  event LogBorrowerCollateralDeposited(address indexed _address,uint indexed amount,uint indexed timestamp);
  event LogBorrowerDefaultsOnPayment(address indexed _address,uint indexed amount,uint indexed timestamp);
  event LogBorrowerCollateralRefunded(address indexed _address,uint indexed _amount,uint indexed timestamp);
  event LogExtraBorrowerCollateralRefunded(address indexed _address,uint indexed _amount,uint indexed timestamp);
  event LogLenderInvestment(address indexed _address, uint indexed _amount, uint indexed timestamp);
  event LogLenderWithdrawal(address indexed _address, uint indexed _amount, uint indexed timestamp);
  event LogLenderRefunded(address indexed _address, uint indexed _amount, uint indexed timestamp);
  

  //Modifiers needed 
  // To ensure the loan is active
  modifier isActive() {
        require(active == true);
        _;
  }
  // To ensure only the borrower can use some functions
  modifier onlyBorrower() {
      require(msg.sender == borrower);
      _;
  }
  // To ensure only the lenders can use some functions
  modifier onlyLender() {
      require(lenders[msg.sender] == true);
      _;
  }
  // Indicates the requirement where the lenders can ask for interest 
  modifier canAskForInterest() {
      require(state == State.interestReturns);
      require(lendersInvestedAmount[msg.sender] > 0);
      _;
  }
  // Indicates the requirement where the lenders can invest 
  modifier canInvest() {
      require(state == State.investment);
      _;
  }
  // Indicates the requirement for borrowers to repay the loan
  modifier canRepay() {
      require(state == State.repayment);
      _;
  }
  // Indicates the requirement for when the borrower can withdraw thier collateral
  modifier canWithdrawCollateral(){
      require(state==State.collateralReturns);
      require(dateLoanPaid>block.timestamp);
      _;

  }
  // Used to indicates that the time the loan should be repaid as elapsed 
  modifier timeElapsed(){
    require(dateLoanPaid<block.timestamp);
    _;
  }
  //Used to indicate that the time the loan should be repaid has not not elapsed 
  modifier timeRunning(){
    require(dateLoanPaid>block.timestamp);
    _;

  }
  //Used to indicate when borrowers can withdraw the loan they asked for 
  modifier canWithdraw() {
      require(address(this).balance >= requestedAmount);
      require(withdrawn==false);
      _;
  }



  //struct that would store the transaction info which will be used in for frontend 
  struct TransactionStruct{
    address borrower;
    uint requestedAmount;
    uint collateralAmount;
    uint repaymentInstallment;
    uint returnAmount;
    uint dateLoanPaid;
    
  }

  //initializing the struct 
  TransactionStruct[] transactions;


   // main constrctor of the contract 
  constructor(){ }


  //This function is used to apply for loans and also it will take in important variables and initialize them
  function applyForLoan(uint _collateralAmount, uint _requestedAmount, uint _requestedNumberRepayment,uint _dateLoanPaid)public{
    require(_dateLoanPaid>block.timestamp,"Input a valid date");
    // this is to make sure the account that triggers this function is marked as the borrower
    borrower=msg.sender;
    // Initializes the amount of collateral that would be deposited by the borrower
    collateralAmount=_collateralAmount;
    //Intializes the amount that is requested by the borrower
    requestedAmount=_requestedAmount;
    // Calculates the percentage interest that would be pais by the borrower(20%)
    interest= ((requestedAmount/100)*20);
    // Intializes the number of times the borrower is able to pay the loan back
    requestedNumberRepayment=_requestedNumberRepayment;
    //Intializes the tracks the number of times left to pay the installments
    remainingRepayment=_requestedNumberRepayment;
    //Calculates the total amount that would be returned by the borrower + interest
    returnAmount =_requestedAmount.add(interest);
    //Calculated the amount of the installments that would be paid
    repaymentInstallment=returnAmount.div(requestedNumberRepayment);
    // Intializes the date that the borrower requested for the loan
    requestedDate=block.timestamp;
    //Intializes the date the borrower as set for final repayment
    dateLoanPaid=_dateLoanPaid;
    //Tracks the amount of the return amount already paid 
    repaidAmount=0;
    // Tracks the number of lenders on one loan application 
    lendersCount=0;
    // Tracks if the borrower as withdrawn the amount of money he requested fir 
    withdrawn=false;
    emit LogCreditInitialized(borrower,block.timestamp);
    active=true;
    emit LogCreditStateActiveChanged(active,block.timestamp);
    // Pushes important variables to the struct above which will make up the transaction tab on the app
    transactions.push(TransactionStruct(borrower,requestedAmount,collateralAmount,repaymentInstallment,returnAmount,dateLoanPaid));
   


  }

  // Function that will enable the borrower to deposit collateral
  function borrowersCollateral() public onlyBorrower isActive payable {
    require (msg.value>=returnAmount);
    collateralAmount = msg.value;
    emit LogBorrowerCollateralDeposited(msg.sender,msg.value,block.timestamp);
    state=State.investment;
    emit LogCreditStateChanged(state, block.timestamp);
  }
  
  // Function which which will enable the lenders to invest there crypto for the requested loan to be serviced
  function invest() public isActive canInvest payable{
    lenders[msg.sender]=true;
    lendersCount++;
    lendersInvestedAmount[msg.sender]=lendersInvestedAmount[msg.sender].add(msg.value);
    emit LogLenderInvestment(msg.sender,msg.value,block.timestamp);
  }

  // Function that enables the borrower to withdraw the requested Loan amount after the lenders have invested 
  function withdraw() public isActive onlyBorrower canWithdraw {
    state=State.repayment;
    withdrawn=true;
    emit LogCreditStateChanged(state,block.timestamp);
    payable(msg.sender).transfer(requestedAmount);
    emit LogBorrowerWithdrawal(msg.sender,requestedAmount,block.timestamp);
  }
    
  // function that will enable the borrower to repay loans installmentally 
  function repay() public onlyBorrower isActive canRepay timeRunning payable{
    require(remainingRepayment>0);
    assert(msg.value<=returnAmount);
    require(msg.value >= repaymentInstallment);
    repaidAmount=repaidAmount+msg.value;
    remainingRepayment--;
    lastRepaymentDate=block.timestamp;
    emit LogBorrowerRepaymentInstallment(msg.sender,msg.value,block.timestamp);
    if(repaidAmount==returnAmount){
      emit LogBorrowerRepaymentFinished(msg.sender,block.timestamp);
      state=State.collateralReturns;
      emit LogCreditStateChanged(state,block.timestamp);
 
    }
   
  }

  //function will enable the borrower to withdraw is collateral after loans has been repaid fully
  function refundCollateral()public isActive onlyBorrower canWithdrawCollateral{
    payable(msg.sender).transfer(collateralAmount);
    emit LogBorrowerCollateralRefunded(msg.sender,collateralAmount,block.timestamp);
    state=State.interestReturns;
    emit LogCreditStateChanged(state,block.timestamp);
  }

  //function will enable the borrower to withdraw is remaining collateral after defaulting on payment 
  function refundCollateralAfterDefault()public isActive onlyBorrower timeElapsed(){
    uint extraCredit=collateralAmount-(returnAmount-repaidAmount);
    emit LogBorrowerDefaultsOnPayment(msg.sender,extraCredit,block.timestamp);
    payable(msg.sender).transfer(extraCredit);
    emit LogBorrowerRepaymentFinished(msg.sender,block.timestamp);
    emit LogExtraBorrowerCollateralRefunded(msg.sender,extraCredit,block.timestamp);
    state=State.interestReturns;
    emit LogCreditStateChanged(state,block.timestamp);
  }

  
  //function which will enable the lenders to request for interest after loan has been paid 
  function requestInterest() public isActive onlyLender canAskForInterest{
    lenderReturnAmount=returnAmount/lendersCount;
    uint interestPerLender=interest/lendersCount;
    assert(address(this).balance>=lenderReturnAmount);
    payable(msg.sender).transfer(interestPerLender);
    emit LogLenderWithdrawal(msg.sender,interestPerLender,block.timestamp);
  }

  //function that will enable the lenders to withdraw their investment after interest has been gotten
  //which will also signify the end of the contract
  function refundFundDeposited()public isActive onlyLender canAskForInterest{
    payable(msg.sender).transfer(lendersInvestedAmount[msg.sender]);
    lendersInvestedAmount[msg.sender]=0;
    emit LogLenderRefunded(msg.sender,lendersInvestedAmount[msg.sender],block.timestamp);
    if(address(this).balance==0){
        active=false;
        emit LogCreditStateActiveChanged(active,block.timestamp);
        state=State.expired;
        emit LogCreditStateChanged(state, block.timestamp);

    }

  }
    
    
  //getter function for getting contract variables and returning it 
  function getCreditInfo() public view returns(address, uint,uint, uint, uint, uint, uint, State, bool, uint){
    return(
        borrower,
        requestedAmount,
        collateralAmount,
        repaymentInstallment,
        remainingRepayment,
        repaidAmount,
        returnAmount,
        state,
        active,
        address(this).balance);
    
  }

  
  //getter function for getting the already intialized transaction struct 
  function getTransactionInfo() public view returns(TransactionStruct[] memory){
    return transactions;
  }

}