/**
 *Submitted for verification at Etherscan.io on 2022-03-08
*/

pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}


contract Staker {
    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool public openForWithdraw;
    bool public isExecuted;

    event Stake(address, uint256);

    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed);
        _;
    }

    function stake() external payable {
        require(deadline > block.timestamp);
        address _address = msg.sender;
        uint256 _amount = msg.value;
        balances[_address] += _amount;
        emit Stake(_address, _amount);
    }

    function execute() external notCompleted {
        require(deadline <= block.timestamp);
        require(!isExecuted);
        isExecuted = true;
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    function withdraw(address payable _address) external notCompleted {
        require(openForWithdraw, "Must be called execute first!");
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        _address.transfer(amount);
    }

    function timeLeft() public view returns (uint256) {
        uint256 timestamp = block.timestamp;
        if (timestamp < deadline) {
            return deadline - timestamp;
        }
        return 0;
    }

    receive() external payable {
        require(deadline > block.timestamp);
        address _address = msg.sender;
        uint256 _amount = msg.value;
        balances[_address] += _amount;
        emit Stake(_address, _amount);
    }
}