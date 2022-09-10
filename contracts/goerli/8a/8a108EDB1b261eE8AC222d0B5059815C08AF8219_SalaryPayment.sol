// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// Imports 

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract SalaryPayment is KeeperCompatibleInterface {

    // Self defined Data Types

      struct Employee {
        uint256 share;
        uint256 AmountPaid;
      }



    // State Variables

    address private immutable i_employer;
    uint256 private i_interval;
    mapping(address => Employee) private s_employeeAddressToEmployeeInfo;
    address payable[] private s_employeesToBePaid;
    uint256 private s_startingTimeStamp;
    uint256 private i_balance;

    // Errors

    error UpkeepNotNeeded();
    error OnlyEmployer();

    // Modifiers

    modifier onlyEmployer {
        if(msg.sender != i_employer){
            revert OnlyEmployer();
        }
        _;
    }

    // events 

    event EmployeesPaid();

    // State functions 

    constructor(uint256 interval){
        i_employer = msg.sender;
        i_interval = interval;
        s_startingTimeStamp = block.timestamp;
    }

    function addEmployee(address employeeAddress,uint256 employeesShare)public onlyEmployer{
        s_employeesToBePaid.push(payable(employeeAddress));
        s_employeeAddressToEmployeeInfo[employeeAddress].share = employeesShare;  
    }
     
    function checkUpkeep(bytes memory /* performData */) public view override returns (bool UpkeepNeeded , bytes memory /* performData */){

        bool balance =  (address(this).balance > 0);
        bool employees = (s_employeesToBePaid.length > 0);
        bool timeStamp = ((block.timestamp - s_startingTimeStamp)>i_interval);

        UpkeepNeeded = (balance && employees && timeStamp);
    }

    function performUpkeep(bytes memory /* performData */) external override {

        (bool UpkeepNeeded,) = checkUpkeep("");

        if(!UpkeepNeeded){
            revert UpkeepNotNeeded();
        }

        for (uint index = 0; index < s_employeesToBePaid.length; index++) {
            address payable employeeToBePaid = s_employeesToBePaid[index];
            uint256 share = s_employeeAddressToEmployeeInfo[employeeToBePaid].share;
            uint256 amountToBePaid = i_balance * share / 10;
            (bool paymentSuccess,) = employeeToBePaid.call{value:amountToBePaid}("");
            s_employeeAddressToEmployeeInfo[employeeToBePaid].AmountPaid = amountToBePaid; 
        }

        s_startingTimeStamp = block.timestamp;
        s_employeesToBePaid = new address payable[](0);
        emit EmployeesPaid();
        
    } 

    function setLatestTimeStamp() public onlyEmployer{
        s_startingTimeStamp = block.timestamp;
    }

    function addBalance() public payable onlyEmployer{
        i_balance = msg.value;
    }
    

    // View Functions 

    function getBalance() public view returns(uint256){
        return uint256(address(this).balance);
    }

    function getTimeStamp() public view returns(uint256){
        return s_startingTimeStamp;
    }

    function getEmployeeToBePaid(uint256 index) public view returns(address){
        return s_employeesToBePaid[index];
    }

    function getEmployeeInfo(address employeeAddress) public view returns(Employee memory){
        return s_employeeAddressToEmployeeInfo[employeeAddress];
    }

    function getInterval() public view returns(uint256){
        return i_interval;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}