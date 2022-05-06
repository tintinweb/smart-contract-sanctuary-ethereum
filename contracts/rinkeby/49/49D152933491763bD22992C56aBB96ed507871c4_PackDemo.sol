// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;


contract PackDemo {
    struct TargetArgs {
        uint a;
        uint b;
    }

    function target(
        uint a,
        uint dynamic,
        uint b
    ) internal view returns(uint256) {
        return a + dynamic ** b;
    }

    function call(
        uint dynamic,
        bytes memory staticArgs
    ) external view returns(uint256) {
        TargetArgs memory _staticArgs = abi.decode(staticArgs, (TargetArgs));
        return target(_staticArgs.a, dynamic, _staticArgs.b);
    }
}