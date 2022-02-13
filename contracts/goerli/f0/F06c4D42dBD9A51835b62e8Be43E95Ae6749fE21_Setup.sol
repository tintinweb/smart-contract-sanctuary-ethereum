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
    // Private number, will not be public at all ;)
    uint8 private constant answer = 4;

    constructor() payable {}

    function guess(uint8 n) external payable {
        require(msg.value == 1 ether);

        if(n == answer) {
            // Send all ether to user
            (bool success, ) = msg.sender.call{ value: address(this).balance }('');
            require(success, 'send fail');
        }
    }
}