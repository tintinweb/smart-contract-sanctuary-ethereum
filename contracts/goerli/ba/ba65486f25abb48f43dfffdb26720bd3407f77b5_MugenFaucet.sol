//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IMugen} from "./interfaces/IMugen.sol";

contract MugenFaucet {
    IMugen public mugen;

    constructor(address _mugen) {
        mugen = IMugen(_mugen);
    }

    function _mint(address to, uint256 amount) public {
        mugen.mint(to, amount);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMugen {
    function mint(address _to, uint256 _amount) external;
}