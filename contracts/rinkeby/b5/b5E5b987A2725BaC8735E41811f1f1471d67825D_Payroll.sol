// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Payroll is Ownable{
    /// bytes32 private merklerootOfEmployees ;
    address public _owner;

   uint256 public salaryWaitWindow = 30 seconds;
   IERC20 public employeePaymentToken;
   constructor(address _paymentTokenAddress){
    employeePaymentToken = IERC20(_paymentTokenAddress);
    _owner = msg.sender;
   

   }

    struct NewEmployee{
        address employee;
        string name;
        uint256 age;
        uint256 salaryAmount;
        bool hasInteractedWithSalary;
        uint256 timeOfEmployment;
        uint256 estimatedtimeOfSalary;
        bool    receivedFullPayment;
        mapping(address => uint256) balance;
    }
     uint256 public employed;
    //  mapping(uint256 =>NewEmployee) employedWorkers;
    
    mapping(address => NewEmployee) public employeeRecord;
    mapping(address => bool) public isEmployed;

    event NewEmployeeAdded(address indexed _employee,uint256 _timeOfEmployment);
    event RemovedEmployee(address indexed _exEmployee,uint256 _timeOfRemoval);
    event SalaryChanged(address indexed _employee,uint256 oldSalary, uint256 newSalary, uint256 _timeOfUpdate);

    modifier isPaymentDue(){
        uint256 dueDate = employeeRecord[msg.sender].estimatedtimeOfSalary;
        require( block.timestamp > dueDate,"You are not up for payment yet.");
        

        _;
    }
    modifier enoughTokensLeft(uint256 amountToWithdraw) {
        uint256 tokensLeft = employeePaymentToken.balanceOf(_owner);
        require((employeeRecord[msg.sender].salaryAmount -amountToWithdraw) < tokensLeft, "There are not enough tokens left to claim.");
        _;
    }
    modifier checkIfEmployed(address employeeCheck) {
        require(isEmployed[employeeCheck],"not an employee.");
        _;
    }
    

    function addEmployee(address employee,string memory name , uint256 age,uint256 salaryAmount ) public onlyOwner{
        require(employee != address(0),"Employee cannot be address 0");
        require(!isEmployed[employee],"Employee already exists");
        uint256 timeOfEmployment_ = block.timestamp;

        NewEmployee storage nE= employeeRecord[employee];
        nE.employee = employee;
        nE.name = name;
        nE.age=age;
        nE.salaryAmount=salaryAmount *10 **18;
        nE.timeOfEmployment=timeOfEmployment_;
        nE.estimatedtimeOfSalary=timeOfEmployment_+salaryWaitWindow;
    

        // employeeRecord[employee] = NewEmployee(employee,name,age,salaryAmount,timeOfEmployment_,timeOfEmployment_+salaryWaitWindow,0);
        // uint256 

        isEmployed[employee] = true;
        employed++;

        emit NewEmployeeAdded(employee,timeOfEmployment_);

    }
    function getEmployee(address employee) public view checkIfEmployed(employee) onlyOwner
     returns(

        string  memory name,
        uint256 age,
        uint256 salaryAmount,
        uint256 timeOfEmployment,
        uint256 estimatedtimeOfSalary,
        uint256 balance

    )
    {

       NewEmployee storage _Employee = employeeRecord[employee];
       return (

       _Employee.name,
        _Employee.age,
        _Employee.salaryAmount,
        _Employee.timeOfEmployment,
        _Employee.estimatedtimeOfSalary,
        _Employee.balance[employee]
        ) ;

    }
    function removeEmployee(address[] memory employees) public onlyOwner{
        uint256 j = employees.length;
        for(uint i =0; i<j; i++){
          if( isEmployed[employees[i]]){
            delete  employeeRecord[employees[i]];
             isEmployed[employees[i]] = false;
             employed--;
             emit RemovedEmployee(employees[i],block.timestamp);

          }
        }
    }

    function estimatedTimeBeforeSalary() public view returns(uint256)  {
        
       uint256 dateOfsalary = employeeRecord[msg.sender].estimatedtimeOfSalary;
       uint256 timeBeforeSalary = dateOfsalary - block.timestamp;
       return timeBeforeSalary;


    }
    function setSalaryAmount(address employee,uint256 newSalary) public  checkIfEmployed(employee) onlyOwner{
         NewEmployee storage _Employee = employeeRecord[employee];
         uint256 oldSalary = _Employee.salaryAmount;
         delete _Employee.salaryAmount;
         _Employee.salaryAmount= newSalary;
         require(_Employee.salaryAmount == newSalary,"Salary has not been updated" );
         emit SalaryChanged((employee),oldSalary, newSalary, block.timestamp);

    }

    // function claimPayment()public checkIfEmployed(msg.sender) isPaymentDue{
    //     NewEmployee storage _employee =employeeRecord[msg.sender];
    //     if(!_employee.receivedFullPayment){
    //          uint256 salary = _employee.salaryAmount;
    //          require(salary <= employeePaymentToken.balanceOf(_owner));
          
    //        employeePaymentToken.transferFrom(_owner,msg.sender,salary);
    //        _employee.receivedFullPayment= true;
    //     }

    // }
    function hasInteractedWithSalary() internal  checkIfEmployed(msg.sender) isPaymentDue{
         NewEmployee storage _employee =employeeRecord[msg.sender];

         if(_employee.hasInteractedWithSalary == false){
          uint256 salary = _employee.salaryAmount;
         _employee.balance[msg.sender] += salary;
         _employee.hasInteractedWithSalary = true;
         }
        
   
    }

    function claimPayment(uint256 amountToWithdraw) public isPaymentDue enoughTokensLeft(amountToWithdraw) {
        hasInteractedWithSalary();
        amountToWithdraw= amountToWithdraw*10**18;

        NewEmployee storage _employee =employeeRecord[msg.sender];
        uint256 availableToWithdraw =_employee.balance[msg.sender];

        require(!_employee.receivedFullPayment,"You have withdrawn your full salary");
        require(availableToWithdraw >= amountToWithdraw,"Your balance is less than the amount you wish to withdraw");

        employeePaymentToken.transferFrom(_owner,msg.sender,amountToWithdraw);
        _employee.balance[msg.sender] -= amountToWithdraw;
        _employee.balance[msg.sender]== 0 ?  _employee.receivedFullPayment = true: _employee.receivedFullPayment;

    }
    // function setEmployeeToken(address _newEmployeetoken)
    //     internal
    //     onlyOwner

    // {
    //     employeePaymentToken = EmployeePaymentToken(_newEmployeetoken);
    // }


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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address to, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

 
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool); 
}

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