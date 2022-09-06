/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// File: contracts/ExampleExternalContract.sol


pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

// File: contracts/5_Staker.sol


pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading


contract Staker {
    ExampleExternalContract public exampleExternalContract;

    uint public constant threshold = 1 ether;
    uint public deadline = block.timestamp + 72 hours;
    bool public openForWithdraw;
    mapping(address => uint) public balances;

    event Stake(address staker, uint amount);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() external payable {
        require(timeLeft() > 0, "contract expired");
        balances[msg.sender] = msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() external {
        require(timeLeft() == 0 && !openForWithdraw);
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        }
        openForWithdraw = true;
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function
    // Add a `withdraw()` function to let users withdraw their balance
    function withdraw() external {
        uint callerBalance = balances[msg.sender];
        require(openForWithdraw && callerBalance > 0);
        balances[msg.sender] = 0;
        (bool success, ) = address(msg.sender).call{value: callerBalance}("");
        require(success, "error");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint) {
        return block.timestamp > deadline ? 0 : deadline - block.timestamp;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        (bool result, ) = address(this).delegatecall(
            abi.encodeWithSelector(Staker.stake.selector)
        );
        require(result, "could not call stake");
    }
}