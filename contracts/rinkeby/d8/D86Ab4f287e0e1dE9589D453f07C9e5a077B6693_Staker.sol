// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    
// @TODO memory / gas optimizations ?!
    uint256 private immutable STAKING_INTERVAL;

    ExampleExternalContract public exampleExternalContract;

    mapping ( address => uint256 ) public balances;

    uint256 public immutable THRESHOLD;
    
    uint public deadline;
    
    bool public openForWithdraw = false;

    event Stake(address sender, uint256 amount);
    event ThresholdNotMet(address sender, uint256 contractBalance);
    event BalanceUtilized(address sender, uint256 contractBalance);
    event WithdrawSuccess(address sender);
    event StakingRestarted(address sender);

    error CalledTooEarly(address sender);
    error AlreadyExecuting(address sender);
    error UserHasZeroBalance(address sender);

    modifier onlyAfterStakingEnded() {
        if(
            0 < deadline
            && block.timestamp < deadline
        ) {
            revert("Function should only be called after staking ended.");
            //revert CalledTooEarly(msg.sender);
        }
        _;
    }

    modifier notCompleted() {
        if (exampleExternalContract.completed()) {
            revert("Staking already succeeded.");
        }
        _;
    }

    constructor(address exampleExternalContractAddress, uint256 threshold, uint256 staking_interval) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
        THRESHOLD = threshold;
        STAKING_INTERVAL = staking_interval;
        deadline = block.timestamp + staking_interval;
    }

    function restartStaking() private {
        deadline = block.timestamp + STAKING_INTERVAL;
        openForWithdraw = false;
        emit StakingRestarted(msg.sender);
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable notCompleted {
        address sender = msg.sender;
        uint256 amount = msg.value;

        if (0 == deadline) {
            revert("Next staking round has not started yet, withdrawal is in progess.");
            // revert CalledTooEarly(sender);
        }

        if(deadline < block.timestamp) {
            revert("Staking round ended. Press 'execute'.");
            // revert CalledTooEarly(sender);
        }

        balances[sender] += amount;
        emit Stake(sender, amount);
    }


    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    function execute() public onlyAfterStakingEnded notCompleted {
        address sender = msg.sender;
        uint256 contractBalance = address(this).balance;

        if(0 == deadline) {
            revert("Already executing...");
            //return  AlreadyExecuting(sender);
        }

        deadline = 0;

        if(0 == contractBalance) {
            return restartStaking();
        }

        if (contractBalance < THRESHOLD) {
            openForWithdraw = true;
            emit ThresholdNotMet(sender, contractBalance);
            return;
        }
     
        exampleExternalContract.complete{value: contractBalance}();

        deadline = block.timestamp + STAKING_INTERVAL;

        emit BalanceUtilized(sender, contractBalance);
    }

    // Add a `withdraw()` function to let users withdraw their balance
    function withdraw() public onlyAfterStakingEnded notCompleted {
        address sender = msg.sender;
        uint256 sender_balance = balances[sender];

        if(!openForWithdraw) {
            revert("Function should only be called after staking ended.");
            // //revert CalledTooEarly(sender);
        }

        if (0 == sender_balance) {
            revert("User has zero balance.");
            //revert UserHasZeroBalance(sender);
        }

        delete balances[sender];

        payable(sender).transfer(sender_balance);

        if(0 == address(this).balance) {
            return restartStaking();
        }
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        return (0 < deadline
            && block.timestamp < deadline)
            ? deadline - block.timestamp
            : 0;
    }


    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }


}