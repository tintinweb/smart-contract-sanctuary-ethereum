/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

pragma solidity 0.8.4;

interface ISetup {
    event Deployed(address instance);

    function isSolved() external view returns (bool);
}

contract Challenge {
    // Private number, will not be public at all ;)
    uint8 private constant answer = 42;

    constructor() payable {}

    function guess(uint8 n) external payable {
        require(msg.value == 100 wei);

        if (n == answer) {
            (bool success, ) = msg.sender.delegatecall('');
            require(success, 'send fail');
        }
    }
}

contract Setup is ISetup {
    Challenge public instance;

    constructor() payable {
        require(msg.value == 100 wei);

        instance = new Challenge{value: 100 wei}();
        emit Deployed(address(instance));
    }

    function isSolved() external override view returns (bool) {
        return address(instance).balance == 0;
    }
}