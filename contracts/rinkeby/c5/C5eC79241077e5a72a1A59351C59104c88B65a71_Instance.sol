//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IInstance.sol";

contract Instance {
    address INSTANCE;
    IInstance level = IInstance(INSTANCE);

    constructor(address _instance) {
        INSTANCE = _instance;
    }

    function completeLevel() public {
        string memory _password = level.password();
        level.authenticate(_password);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IInstance {
    function password() external returns (string memory);
    function authenticate(string memory passkey) external;
}