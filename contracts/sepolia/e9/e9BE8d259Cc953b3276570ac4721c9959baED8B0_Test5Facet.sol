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

contract Test5Facet {

    function state() 
        internal pure returns(AppStorage storage s)
    {    
        assembly {
            s.slot := 0
        }
    }

    function test5Func1(uint256 value)
        external
    {
        AppStorage storage s = state();
        s.var1 = value;
    }

    function test5Func2(uint256 value)
        external
    {
        AppStorage storage s = state();
        s.var2 = value;
    }

    function test5Func3()
        external
    {
        AppStorage storage s = state();
        s.var3 = s.var1 + s.var2;
    }

    function test5Func4()
        external view returns(uint256)
    {
        AppStorage storage s = state();
        return s.var3;
    }
}