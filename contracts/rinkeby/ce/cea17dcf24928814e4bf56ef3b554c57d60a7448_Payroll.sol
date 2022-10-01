/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

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

// File: VSpay.sol


pragma solidity ^0.8.17;


// import "./MYTOKEN.sol";

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
        // bool hasInteractedWithSalary;
        uint256 timeOfEmployment;
        // uint256 estimatedtimeOfSalary;
        // bool    receivedFullPayment;
        mapping(address => uint256) balance;
        uint256 EmissionRatePerMinute;
        mapping(address => uint256) employeeWithdrawalTime;
        mapping(address => bool) claimedPaymentAtAnyTime;
        mapping(address => bool) isEmployeeOnLeave;
        mapping(address => uint256) balanceBeforeLeave;
        uint256 timeOfLeaveRequest;
        uint256 timeOfLeaveResumption;
        bool hasBeenOnLeave;
    }
     uint256 public employed;
    //  mapping(uint256 =>NewEmployee) employedWorkers;
    
    mapping(address => NewEmployee) public employeeRecord;
    mapping(address => bool) public isEmployed;

    event NewEmployeeAdded(address indexed _employee,uint256 _timeOfEmployment);
    event RemovedEmployee(address indexed _exEmployee,uint256 _timeOfRemoval);
    event SalaryChanged(address indexed _employee,uint256 oldSalary, uint256 newSalary, uint256 _timeOfUpdate);

    event ClaimedSalary(address indexed,uint256 _amountClaimed,uint256 _timeOfClaim);
    event severanceFeePaid(address indexed _employee,uint256 _amountPaid,uint256 _timeOfSeverance);

    event EmployeeLeaveRequest(address indexed , uint256 _timeOfLeave);
    event EmployeeResumeLeave(address indexed, uint256 _durationOfLeave);
    

    modifier isPaymentDue(){
        uint256 dueDate = employeeRecord[msg.sender].timeOfEmployment + salaryWaitWindow;
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
        require(!isEmployed[employee],"Employee =already exists");
        uint256 timeOfEmployment_ = block.timestamp;
        uint256 EmissionRatePerMinute_ = salaryAmount/30/24/60;

        NewEmployee storage nE= employeeRecord[employee];
        nE.employee = employee;
        nE.name = name;
        nE.age=age;
        nE.salaryAmount=salaryAmount *10 **18;
        nE.timeOfEmployment=timeOfEmployment_;
       
        nE.EmissionRatePerMinute = EmissionRatePerMinute_;
    

        // employeeRecord[employee] = NewEmployee(employee,name,age,salaryAmount,timeOfEmployment_,timeOfEmployment_+salaryWaitWindow,0);
        // uint256 

        isEmployed[employee] = true;
        employed++;

        emit NewEmployeeAdded(employee,timeOfEmployment_);

    }
   
    function getEmployee(address employee) public  checkIfEmployed(employee) onlyOwner
     returns(

        string  memory name,
        uint256 age,
        uint256 salaryAmount,
        uint256 timeOfEmployment,
      
        uint256 balance,
        uint256 MinuteRate

    )
    {

       NewEmployee storage _Employee = employeeRecord[employee];

    //    uint256 emittedTime =block.timestamp -_Employee.timeOfEmployment;
    //     delete _Employee.balance[employee];
    //     uint256 newBalance = emittedTime * _Employee.hourlyEmissionRate;
    //     _Employee.balance[employee] =newBalance;
      
       _Employee.balance[employee]= getBalance(employee);

       return (

       _Employee.name,
        _Employee.age,
        _Employee.salaryAmount,
        _Employee.timeOfEmployment,
        // _Employee.estimatedtimeOfSalary,
        _Employee.balance[employee],
        _Employee.EmissionRatePerMinute
        ) ;

    }
    function removeEmployee(address[] memory employees) public onlyOwner{
        uint256 j = employees.length;
        for(uint i =0; i<j; i++){
          if( isEmployed[employees[i]]){
            //   getBalance(employees[i]);
            severanceFee(employees[i]);

            delete  employeeRecord[employees[i]];
             isEmployed[employees[i]] = false;
             employed--;
             emit RemovedEmployee(employees[i],block.timestamp);

          }
        }
    }
    function  getEmployeeCount() public view returns(uint256){
        return employed;
    }
    // function estimatedTimeBeforeSalary() public view returns(uint256)  {
        
    //    uint256 dateOfsalary = employeeRecord[msg.sender].estimatedtimeOfSalary;
    //    uint256 timeBeforeSalary = dateOfsalary - block.timestamp;
    //    return timeBeforeSalary;


    // }
    function updateSalaryAmount(address employee,uint256 newSalary) public  checkIfEmployed(employee) onlyOwner{
         NewEmployee storage _Employee = employeeRecord[employee];
         require(!_Employee.isEmployeeOnLeave[employee], "Can't update salary when employee is on leave");
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
    // mapping(address => uint256) employeeWithdrawalTime;
    function getBalance(address employee) public returns(uint256){
         
        NewEmployee storage _Employee = employeeRecord[employee];

        if(_Employee.isEmployeeOnLeave[employee]){
            delete  _Employee.balance[employee];
            return _Employee.balanceBeforeLeave[employee];

        }
        else if (!_Employee.isEmployeeOnLeave[employee] &&!_Employee.claimedPaymentAtAnyTime[employee] &&!_Employee.hasBeenOnLeave){
              uint256 emittedTime =block.timestamp -_Employee.timeOfEmployment;
              delete _Employee.balance[employee];
              uint256 newBalance = emittedTime/60 * _Employee.EmissionRatePerMinute;
               delete  _Employee.balance[employee];
            _Employee.balance[employee] =newBalance;
            return _Employee.balance[employee];
             
        }
        else if(!_Employee.isEmployeeOnLeave[employee] &&!_Employee.claimedPaymentAtAnyTime[employee] &&_Employee.hasBeenOnLeave)
         {
              uint256 emittedTime =block.timestamp -_Employee.timeOfLeaveResumption;
              
              uint256 EmittedBalance = emittedTime/60 * _Employee.EmissionRatePerMinute;
              require(_Employee.balanceBeforeLeave[msg.sender] > 0, "Error:You never went on Leave");
              uint256 newBalance =_Employee.balanceBeforeLeave[msg.sender] + EmittedBalance;
              delete  _Employee.balance[employee];
              _Employee.balance[employee] =newBalance;
              return _Employee.balance[employee];

        }
        else if (!_Employee.isEmployeeOnLeave[employee] &&_Employee.claimedPaymentAtAnyTime[employee] &&!_Employee.hasBeenOnLeave) 
        {
            uint256 emittedTime = block.timestamp - _Employee.employeeWithdrawalTime[employee];

            uint256 newBalance = emittedTime/60 * _Employee.EmissionRatePerMinute;
            // uint256 newBalance =
            delete _Employee.balance[employee];
            _Employee.balance[employee] =newBalance;
            return _Employee.balance[employee];
        }
        else {
            if(_Employee.timeOfLeaveResumption>_Employee.employeeWithdrawalTime[employee]){
                uint256 emittedTime =block.timestamp -_Employee.timeOfLeaveResumption;
              
              uint256 EmittedBalance = emittedTime/60 * _Employee.EmissionRatePerMinute;
              require(_Employee.balanceBeforeLeave[msg.sender] > 0, "Error:You never went on Leave");
              uint256 newBalance =_Employee.balanceBeforeLeave[msg.sender] + EmittedBalance;
              delete  _Employee.balance[employee];
              _Employee.balance[employee] =newBalance;
              return _Employee.balance[employee];

            }else{
            uint256 emittedTime = block.timestamp - _Employee.employeeWithdrawalTime[employee];

            uint256 newBalance = emittedTime/60 * _Employee.EmissionRatePerMinute;
            // uint256 newBalance =
            delete _Employee.balance[employee];
            _Employee.balance[employee] =newBalance;
            return _Employee.balance[employee];

            }
           
            

        }

    }
    function requestLeave() public checkIfEmployed(msg.sender){
        
        NewEmployee storage _employee =employeeRecord[msg.sender];
        require(!_employee.isEmployeeOnLeave[msg.sender], "You are already on leave");
        uint256 accruedBalance = getBalance(msg.sender);

        delete _employee.balanceBeforeLeave[msg.sender];
        _employee.balanceBeforeLeave[msg.sender] = accruedBalance;

        delete _employee.EmissionRatePerMinute;
        _employee.EmissionRatePerMinute = 0;

        _employee.isEmployeeOnLeave[msg.sender] = true;

        delete _employee.timeOfLeaveRequest;
       _employee.timeOfLeaveRequest = block.timestamp;

       _employee.hasBeenOnLeave = true;
       
       emit EmployeeLeaveRequest(msg.sender,block.timestamp);

    }
    function resumeLeave() public checkIfEmployed(msg.sender){
         NewEmployee storage _employee =employeeRecord[msg.sender];
        require(_employee.isEmployeeOnLeave[msg.sender], "You are not on leave");
        // uint256 accruedBalance = getBalance(msg.sender);
        delete _employee.EmissionRatePerMinute;
        _employee.EmissionRatePerMinute = _employee.salaryAmount/30/24/60;

        _employee.isEmployeeOnLeave[msg.sender] = false;

         delete  _employee.timeOfLeaveResumption;
        _employee.timeOfLeaveResumption =block.timestamp;
        uint256 durationOfLeave = _employee.timeOfLeaveResumption -_employee.timeOfLeaveRequest;


        emit EmployeeResumeLeave(msg.sender,durationOfLeave);

    }
        
    // function hasInteractedWithSalary() internal  checkIfEmployed(msg.sender) isPaymentDue{
    //      NewEmployee storage _employee =employeeRecord[msg.sender];

    //      if(_employee.hasInteractedWithSalary == false){
    //       uint256 salary = _employee.salaryAmount;
    //      _employee.balance[msg.sender] += salary;
    //      _employee.hasInteractedWithSalary = true;
    //      }
        
   
    // }
    // function leaveOfAbsense
    function severanceFee(address employee) internal onlyOwner enoughTokensLeft(getBalance(employee)){
        
         employeePaymentToken.transferFrom(_owner,employee,getBalance(employee));

         emit severanceFeePaid(employee,getBalance(employee),block.timestamp);

    }

    function claimPayment(uint256 amountToWithdraw) public isPaymentDue  checkIfEmployed(msg.sender) enoughTokensLeft(amountToWithdraw) {
       getBalance(msg.sender);
        amountToWithdraw= amountToWithdraw*10**18;

        NewEmployee storage _employee =employeeRecord[msg.sender];
        uint256 availableToWithdraw =_employee.balance[msg.sender];

        // require(!_employee.receivedFullPayment,"You have withdrawn your full salary");
        require(availableToWithdraw >= amountToWithdraw,"Your balance is less than the amount you wish to withdraw");

        // employeePaymentToken.transferFrom(_owner,msg.sender,amountToWithdraw);
         employeePaymentToken.transferFrom(_owner,msg.sender,amountToWithdraw);
        // _employee.balance[msg.sender] -= amountToWithdraw;
        // _employee.balance[msg.sender]== 0 ?  _employee.receivedFullPayment = true: _employee.receivedFullPayment;
       
        delete _employee.employeeWithdrawalTime[msg.sender];
        // uint256 currentTime = block.timestamp;
         _employee.employeeWithdrawalTime[msg.sender]= block.timestamp;
         _employee.claimedPaymentAtAnyTime[msg.sender] =true;
         emit ClaimedSalary(msg.sender,availableToWithdraw,block.timestamp);
        


    }
    // function setEmployeeToken(address _newEmployeetoken)
    //     internal
    //     onlyOwner

    // {
    //     employeePaymentToken = EmployeePaymentToken(_newEmployeetoken);
    // }


}