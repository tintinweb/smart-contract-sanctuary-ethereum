// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage} from "../libraries/LibAppStorage.sol";

contract Demo2Facet {
    AppStorage internal s;

    function getDemo2Val1() public view returns (uint256) {
        uint256 _val1 = s.val1;
        return _val1;
    }

    function setDemo2Val1(uint256 _val1) external {
        s.val1 = _val1;
    }

    function getDemo2Val2() public view returns (uint256) {
        uint256 _val2 = s.val2;
        return _val2;
    }

    function setDemo2Val2(uint256 _val2) external {
        s.val2 = _val2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AppStorage {
    uint256 val1;
    uint256 val2;
    uint256 val3;
}