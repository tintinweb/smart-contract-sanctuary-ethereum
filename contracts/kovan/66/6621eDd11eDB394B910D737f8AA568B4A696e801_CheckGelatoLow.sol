// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDripCheck {
    // DripCheck contracts that want to take parameters as inputs MUST expose a struct called
    // Params and a variable named params (with a type Params). This makes it possible to properly
    // encode parameters. Solidity does not support generics so it's not possible to do this with
    // explicit typing.

    function check(address _recipient, bytes memory _params) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IDripCheck } from "../IDripCheck.sol";

interface IGelatoTreasury {
    function userTokenBalance(address _user, address _token) external view returns (uint256);
}

contract CheckGelatoLow is IDripCheck {
    struct Params {
        uint256 threshold;
        address treasury;
    }
    Params public params;

    function check(address _recipient, bytes memory _params) external view returns (bool) {
        Params memory p = abi.decode(_params, (Params));
        return
            IGelatoTreasury(p.treasury).userTokenBalance(
                _recipient,
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
            ) < p.threshold;
    }
}