// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ParentContract.sol";

contract ChildContract is ParentContract
{
    function OverrideMe() override public {}

    function Greetings() external pure returns(string memory)
    {
        return SayHi();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

abstract contract ParentContract
{
    function OverrideMe() public virtual;

    function SayHi() public pure virtual returns(string memory)
    {
        return "Hi";
    }
}