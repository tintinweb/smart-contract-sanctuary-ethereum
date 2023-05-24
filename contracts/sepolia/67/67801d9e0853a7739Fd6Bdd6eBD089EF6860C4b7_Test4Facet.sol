//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

struct AppStorage {
    uint256 var1;
    uint256 var2;
    uint256 var3;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { AppStorage } from "../AppStorage.sol";

contract Test4Facet {
    AppStorage internal s;

    function test4Func1(uint256 value)
        external
    {
        s.var1 = value;
    }

    function test4Func2(uint256 value)
        external
    {
        s.var2 = value;
    }

    function test4Func3()
        external
    {
        s.var3 = s.var1 + s.var2;
    }

    function test4Func4()
        external view returns(uint256)
    {
        return s.var3;
    }
}