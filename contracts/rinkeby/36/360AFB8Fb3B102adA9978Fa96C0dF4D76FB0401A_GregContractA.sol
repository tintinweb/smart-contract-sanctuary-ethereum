// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./GregContractAInterface.sol";


contract GregContractA is GregContractAInterface {

    uint private _counter;

    constructor() {
        _counter = 0;
    }

    function getCount() public view returns (uint counter) {
        return _counter;
    }

    function increment() public {
        _counter = _counter + 1;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;


interface GregContractAInterface {
    function getCount() external view returns (uint counter);

    function increment() external;
}