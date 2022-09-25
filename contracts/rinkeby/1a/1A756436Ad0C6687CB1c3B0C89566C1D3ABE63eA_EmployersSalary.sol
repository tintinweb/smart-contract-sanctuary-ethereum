/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/EmployerSalaryDistribution.sol



pragma solidity >=0.7.0 <0.9.0;



contract EmployersSalary is Ownable{

    uint256 midLevelSalary = 1 ether ;
    uint256 highLevelSalary = 2 ether ;

    struct EmployeeDetails{
        string name;
        string position;
        uint8 idNo;
        address accountNo;
        bool salaryPaid;
    }

   EmployeeDetails[] public highLevelEmployeeDetails;
   EmployeeDetails[] public midLevelEmployeeDetails;

modifier checkLevelOfEmployee(uint256 _levelOfEmployee ){
     require(_levelOfEmployee == 1 || _levelOfEmployee == 2,"only two type of employess 1 = highLevel , 2 = midLevel ");
     _;
}


//use this function to register
   function registerEmployee(string memory _name,uint8 _idNo,address payable  _accountNo,uint256 _levelOfEmployee) public onlyOwner  checkLevelOfEmployee(_levelOfEmployee ) returns(string memory) {
     return  registerEmployessToPosition(_name,_idNo,_accountNo,_levelOfEmployee);
   }
//use this function to remove
   function removeEmployees(address _accountNo,uint256 _levelOfEmployee) external  onlyOwner checkLevelOfEmployee(_levelOfEmployee ) returns (bool){
     return removeEmployess(_accountNo,_levelOfEmployee);
       
   }


   function changeSalaryStatus(bool paid,uint256 _levelOfEmployee) external  onlyOwner {
       if(_levelOfEmployee == 1){
       uint256 length = highLevelEmployeeDetails.length;
      
       for(uint256 i = 0;i< length;i++){
           
            highLevelEmployeeDetails[i].salaryPaid = paid;
             }
            
          }

       else{
            uint256 length = midLevelEmployeeDetails.length;
       for(uint256 i = 0;i< length;i++){
           
            highLevelEmployeeDetails[i].salaryPaid = paid;
             
             
          }
     

       }
   }


   function checkEmployeeGotPaid(address _accountNo,uint _levelOfEmployee ) public view  returns(bool){
       require(_accountNo != address(0),"please do not enter the zero address");
       if(_levelOfEmployee == 1){
       uint256 length = highLevelEmployeeDetails.length;
       uint count;
       for(uint256 i = 0;i< length;i++){
           if(highLevelEmployeeDetails[i].accountNo == _accountNo ){
               return highLevelEmployeeDetails[i].salaryPaid;
             }
             count++;
          }
       if(count == length){
           revert("employee not found");
    
          }
          return true;
       }else{
            uint256 length = midLevelEmployeeDetails.length;
       uint count;
       for(uint256 i = 0;i< length;i++){
           if(midLevelEmployeeDetails[i].accountNo == _accountNo ){
               return highLevelEmployeeDetails[i].salaryPaid;
             }
             count++;
          }
       if(count == length){
           revert("employee not found");
    
          }
          return true;

       }
   }
  
//use this function to send salaries

   function sendSalaries(uint256 _levelOfEmployee ) public payable  onlyOwner checkLevelOfEmployee(_levelOfEmployee ) returns(bool){
       if(_levelOfEmployee == 1){
         for(uint i = 0;i<highLevelEmployeeDetails.length;i++){
           require( !highLevelEmployeeDetails[i].salaryPaid,"salary already paid for this employee");
           highLevelEmployeeDetails[i].salaryPaid = true;
           payable(highLevelEmployeeDetails[i].accountNo).transfer(highLevelSalary );
           
       }
        return true;
     }else {
          
            for(uint i = 0;i<midLevelEmployeeDetails.length;i++){
           require( !midLevelEmployeeDetails[i].salaryPaid,"salary already paid for this employee");
             midLevelEmployeeDetails[i].salaryPaid = true;
           payable(midLevelEmployeeDetails[i].accountNo).transfer(midLevelSalary );
        
          }
           return true;
   }
   
   }

   function checkNoOfEmployees() public view  returns (uint256 total){
      uint highLevel = highLevelEmployeeDetails.length;
      uint lowLevel =   midLevelEmployeeDetails.length;
      total = highLevel+lowLevel;
     

   }




    function registerEmployessToPosition(string memory _name,uint8 _idNo,address payable  _accountNo,uint256 _levelOfEmployee) internal returns (string memory) {
        require(_accountNo != address(0),"please do not enter the zero address");
     
       if(_levelOfEmployee == 1){
             EmployeeDetails memory detailsHighLevel = EmployeeDetails(_name,"MidLevelEMployee",_idNo,_accountNo,false);
            highLevelEmployeeDetails.push(detailsHighLevel);
            uint length = highLevelEmployeeDetails.length;
            return   highLevelEmployeeDetails[length-1].name;
       }else{
          
            EmployeeDetails memory detailsMidLevel = EmployeeDetails(_name,"MidLevelEMployee",_idNo,_accountNo,false);
            midLevelEmployeeDetails.push(detailsMidLevel);
            uint length = midLevelEmployeeDetails.length;
            return   midLevelEmployeeDetails[length-1].name;

       }
   }

   function removeEmployess(address _accountNo,uint256 _levelOfEmployee) internal returns(bool) {
       require(_accountNo != address(0),"please do not enter the zero address");
      
       if(_levelOfEmployee == 1){
              uint256 length = highLevelEmployeeDetails.length;
       uint count;
       for(uint256 i = 0;i< length;i++){
           if(highLevelEmployeeDetails[i].accountNo == _accountNo ){
               highLevelEmployeeDetails[i] = midLevelEmployeeDetails[length-1];
               highLevelEmployeeDetails.pop();
           }
          count++;
       }
       if(count == length){
           revert("employee not found");
       }
       return true;


       }
       else{
            uint256 length = midLevelEmployeeDetails.length;
       uint count;
       for(uint256 i = 0;i< length;i++){
           if(midLevelEmployeeDetails[i].accountNo == _accountNo ){
               midLevelEmployeeDetails[i] = midLevelEmployeeDetails[length-1];
               midLevelEmployeeDetails.pop();
           }
          count++;
       }
       if(count == length){
           revert("employee not found");
       }
       return true;

       }

      
   }


      function setSalaries(uint _salary ,uint256 _levelOfEmployees) external  onlyOwner{
        require(_levelOfEmployees == 1 || _levelOfEmployees == 2,"only two type of employess 1 = highLevel , 2 = midLevel ");
        if(_levelOfEmployees == 1){
             highLevelSalary += _salary ;

        }else{
           
             midLevelSalary += _salary;
        }
       
   }


}