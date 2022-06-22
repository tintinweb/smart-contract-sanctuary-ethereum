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


import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    mapping (address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool public openForWithdraw;

    event Stake( address sender, uint256 value );

    modifier deadlinePassed( bool requireDeadlinePassed ) {
        uint256 timeRemaining = timeLeft();
        if( requireDeadlinePassed ) {
            require(timeRemaining <= 0, "Deadline has not been passed yet");
        } else {
            require(timeRemaining > 0, "Deadline is already passed");
        }
        _;
    }


    modifier stakingNotCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "Staking period has completed");
        _;
    }


    constructor( address exampleExternalContractAddress ) public {
        exampleExternalContract = ExampleExternalContract( exampleExternalContractAddress );
    }


    function stake() public payable deadlinePassed( false ) stakingNotCompleted {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }


    function execute() public stakingNotCompleted {
        uint256 contractBalance = address( this ).balance;
        if( contractBalance >= threshold ) {
            exampleExternalContract.complete{ value: contractBalance }();
        } else {
            openForWithdraw = true;
        }
    }


    function withdraw( address payable _to ) public deadlinePassed( true ) stakingNotCompleted {
        require(openForWithdraw, "Not open for withdraw");
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "userBalance is 0");
        balances[msg.sender] = 0;

        ( bool sent, ) = _to.call{value: userBalance}( '' );
        require(sent, 'Failed to send to address');
    }


    function timeLeft() public view returns( uint256 ) {
        if( block.timestamp >= deadline ) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    receive() external payable {
        stake();
    }
}