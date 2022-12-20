// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//SPD-Licenced: UNLICENSED
//task duration checker; if worker published later than task duration - custrmer can penalry him;
//to add require minimum SBT points to make work;
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConsumerV3.sol";

contract Main is PriceConsumerV3  {

    address public owner;
    uint256 public fee;

    constructor (uint256 _fee) {
        require(_fee >=0 || _fee <= 25);
        fee = _fee;
        owner = msg.sender;
    }

    
    enum TaskStatuses { Canceled, Published, atWork, waitingForApproval, Finished } //Canceled first, bcz after delete struct, it's actually not delete, it fills by 0's.
    TaskStatuses currentTaskStatus;
    

    struct Task {
        TaskStatuses currentTaskStatus;
        address publisherAddress;
        string taskName;
        string linkAtTaskDescription;
        uint256 taskDuration;
        address workerAddress;
        uint256 price;
        uint256 fee;
        bool payed;
    }

    Task[] public arrayTasks;

    function publishTask(string calldata _taskName, string calldata _linkAtTaskDescription, uint256 _taskDuration) external payable {
        require(msg.value > minimumPrice(),"Less than minimum price"); 
        arrayTasks.push(Task({
            currentTaskStatus: TaskStatuses.Published,
            publisherAddress: msg.sender,
            taskName: _taskName,
            linkAtTaskDescription: _linkAtTaskDescription,
            taskDuration: _taskDuration,
            workerAddress: 0x0000000000000000000000000000000000000000,
            price: msg.value - fee,
            fee: msg.value * fee / 100,
            payed: false
        }));
    }

    function minimumPrice() public view returns(uint256)  {
        return uint256(PriceConsumerV3.getLatestPrice()*10**7/100); //1% from chainLinkFeedPriceEth
    }

    function cancelPublishedTask(uint256 _taskId) public {
        require(arrayTasks[_taskId].publisherAddress == msg.sender,"You are not allowed to cancel it");
        require(arrayTasks[_taskId].currentTaskStatus == TaskStatuses.Published,"Can't cancel in this status");
        delete arrayTasks[_taskId];
    }

    function getTask(uint256 _taskId) public { //In current version no need to accept worker query by customer.
        require(arrayTasks[_taskId].currentTaskStatus == TaskStatuses.Published,"Can't take task in this status");
        arrayTasks[_taskId].currentTaskStatus = TaskStatuses.atWork;
        arrayTasks[_taskId].workerAddress = msg.sender;
    }

    function passTask(uint256 _taskId) public {
        require(arrayTasks[_taskId].currentTaskStatus == TaskStatuses.atWork,"Can't take task in this status");
        require(arrayTasks[_taskId].workerAddress == msg.sender,"Can't take task in this status");
        arrayTasks[_taskId].currentTaskStatus = TaskStatuses.waitingForApproval;
    }

    
    function approveTask(uint256 _taskId) public {
        require(arrayTasks[_taskId].currentTaskStatus == TaskStatuses.waitingForApproval,"Can't take task in this status");
        require(arrayTasks[_taskId].publisherAddress ==  msg.sender,"Can't take task in this status");
        arrayTasks[_taskId].currentTaskStatus = TaskStatuses.waitingForApproval;
        arrayTasks[_taskId].currentTaskStatus = TaskStatuses.Finished;
        
        require(arrayTasks[_taskId].payed == false,"Re-entrant guard");
        arrayTasks[_taskId].payed = true;
                
        (bool result, ) = arrayTasks[_taskId].workerAddress.call{value:arrayTasks[_taskId].price}(""); //Ree!
        require(result,"Seems receiver can't receive eth");
    }


    function withdraw() public {
        require(msg.sender == owner, "You are not an owner");
        (bool result, ) = owner.call{value:address(this).balance}(""); //Ree!
        require(result,"Unsuccessful withdraw");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }


}