//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Incrementer.sol";

contract Caller {
    Incrementer public incrContract;

    constructor(address contrAddr) {
        incrContract = Incrementer(payable(contrAddr));
    }

    function callIncrement() public {
        incrContract.increment();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Incrementer {
    uint private counter;

    function increment() public {
        counter += 1;
    }
}