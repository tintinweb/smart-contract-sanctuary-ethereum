pragma solidity 0.7.4;

import './ISetup.sol';
import './Dead.sol';

contract Setup is ISetup {
    Dead public instance;

    constructor() payable {
        require(msg.value == 0.1 ether);

        instance = new Dead{value: 0.1 ether}();
        emit Deployed(address(instance));
    }

    function isSolved() external override view returns (bool) {
        return instance.killed();
    }
}