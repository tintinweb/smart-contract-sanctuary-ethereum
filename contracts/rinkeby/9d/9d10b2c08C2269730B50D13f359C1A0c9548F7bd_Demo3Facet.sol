// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage} from "../libraries/LibAppStorage.sol";

contract Demo3Facet {
    AppStorage internal s;

    function getDemo3Val1() public view returns (uint256) {
        uint256 _val1 = s.val1;
        return _val1;
    }

    function setDemo3Val1(uint256 _val1) external {
        s.val1 = _val1;
    }

    function getDemo3Val2() public view returns (uint256) {
        uint256 _val2 = s.val2;
        return _val2;
    }

    function setDemo3Val2(uint256 _val2) external {
        s.val2 = _val2;
    }

    function getDemo3Val3() public view returns (uint256) {
        uint256 _val3 = s.val3;
        return _val3;
    }

    function setDemo3Val3(uint256 _val3) external {
        s.val3 = _val3;
    }

    function getDemo3Val4() public view returns (uint256) {
        uint256 _val4 = s.val4;
        return _val4;
    }

    function setDemo3Val4(uint256 _val4) external {
        s.val2 = _val4;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AppStorage {
    uint256 val1;
    uint256 val2;
    uint256 val3;
    uint256 val4;
}