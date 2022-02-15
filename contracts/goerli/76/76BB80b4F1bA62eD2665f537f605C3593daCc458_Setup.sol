pragma solidity 0.8.4;

import './ISetup.sol';
import './ExampleQuizExploit.sol';

contract Setup is ISetup {
    ExampleQuizExploit public instance;

    constructor() payable {
        require(msg.value == 1 ether);

        instance = new ExampleQuizExploit{value: 1 ether}();
        emit Deployed(address(instance));
    }

    function isSolved() external override view returns (bool) {
        return address(instance).balance == 0;
    }
}

pragma solidity 0.8.4;

interface ISetup {
    event Deployed(address instance);

    function isSolved() external view returns (bool);
}

pragma solidity 0.8.4;

contract ExampleQuizExploit {
    
    constructor() payable {
    }
    mapping(address => int) public rankedUsers;
    mapping(address => uint) public balances;

    function deposit() external payable {
        require(msg.value > 0);
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        uint bal = balances[msg.sender];
        require(bal > 0);

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] = 0;
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}