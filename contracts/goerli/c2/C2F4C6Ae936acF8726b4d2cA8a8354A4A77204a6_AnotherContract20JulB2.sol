// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AnotherParentContract.sol";


contract AnotherContract20JulB2 is AnotherParentContract
{
    function Greeting() public override pure returns(string memory)
    {
        return "Hi";
    }

    function AnotherGreeting() public pure returns(string memory)
    {
        return "Hello";
    }

    function Adios() public pure returns(string memory)
    {
        return Farewell();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract AnotherParentContract
{
    function Greeting() public virtual returns(string memory);

    function Farewell() public pure returns(string memory)
    {
        return "Goodbye";
    }

    function AnotherFarewell() public pure returns(string memory)
    {
        return "Bye";
    }
}