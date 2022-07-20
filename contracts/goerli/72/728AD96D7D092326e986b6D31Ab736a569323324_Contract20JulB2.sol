// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ParentContract.sol";

contract Contract20JulB2 is ParentContract
{
    function Greeting() public override pure returns(string memory)
    {
        return "Hi";
    }

    function Adios() public pure returns(string memory)
    {
        return Farewell();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ParentContract
{
    function Greeting() public virtual returns(string memory);

    function Farewell() public pure returns(string memory)
    {
        return "Goodbye";
    }
}