// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error AutomatedPayment__NotFound();
error AutomatedPayment__OnlyOwnerAllowed();
error AutomatedPayment__NotEnoughFunds();
error AutomatedPayment__NotEnoughTimePassed();
error AutomatedPayment__CannotPerformUpkeep();

contract AutomatedPayment is KeeperCompatibleInterface {
    uint256 public immutable i_interval;
    uint256 public startTime;
    address public immutable i_owner;
    address payable[] public employees;
    address[] public funders;

    mapping(address => uint256) coorespondingEmployeeSalary;
    mapping(address => uint256) public coorespondingFunderAmount;

    constructor(address owner, uint256 interval) {
        i_owner = owner;
        i_interval = interval;
        startTime = block.timestamp;
    }

    receive() external payable {
        fund();
    }

    function fund() public payable {
        funders.push(msg.sender);
        coorespondingFunderAmount[msg.sender] += msg.value;
    }

    function addEmployee(address payable employee, uint256 salary)
        public
        onlyOwner
    {
        employees.push(employee);
        coorespondingEmployeeSalary[employee] = salary;
    }

    function updateEmployeeSalary(address employee, uint256 salary)
        public
        onlyOwner
    {
        uint256 index = isEmployee(employee);
        coorespondingEmployeeSalary[employee] = salary;
    }

    function deleteEmployee(address employee) public onlyOwner {
        uint256 index = isEmployee(employee);
        employees[index] = employees[employees.length - 1];
        employees.pop();

        delete coorespondingEmployeeSalary[employee];
    }

    function isEmployee(address employee) public view returns (uint256) {
        for (uint256 i = 0; i < employees.length; i++) {
            if (employees[i] == employee) {
                return i;
            }
        }

        revert AutomatedPayment__NotFound();
    }

    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        view
        override
        returns (
            bool upKeepNeeded,
            bytes memory /* performData*/
        )
    {
        bool timePassed = (block.timestamp - startTime) > i_interval;
        bool enoughFunds = (address(this).balance >= getTotalSalariesAmount());
        bool employeeExist = employees.length >= 1;
        upKeepNeeded = (timePassed && enoughFunds && employeeExist);
    }

    function performUpkeep(
        bytes memory /*performData*/
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert AutomatedPayment__CannotPerformUpkeep();
        }
        for (uint256 i = 0; i < employees.length; i++) {
            employees[i].transfer(coorespondingEmployeeSalary[employees[i]]);
        }
        startTime = block.timestamp;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunders() public view returns (address[] memory) {
        return funders;
    }

    function getEmployees()
        public
        view
        onlyOwner
        returns (address payable[] memory)
    {
        return employees;
    }

    function getEmployeeSalary(address employee)
        public
        view
        onlyOwner
        returns (uint256)
    {
        return coorespondingEmployeeSalary[employee];
    }

    function getTotalSalariesAmount() internal view returns (uint256) {
        uint256 totalAmount;
        for (uint256 i = 0; i < employees.length; i++) {
            totalAmount += coorespondingEmployeeSalary[employees[i]];
        }

        return totalAmount;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    modifier areEnoughFundsAvailable() {
        uint256 totalAmount = getTotalSalariesAmount();
        if (totalAmount > address(this).balance)
            revert AutomatedPayment__NotEnoughFunds();
        _;
    }

    modifier onlyOwner() {
        if (i_owner != msg.sender) revert AutomatedPayment__OnlyOwnerAllowed();
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