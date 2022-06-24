// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract Tools {
    // random count
    uint256 initialNumber;

    function st2num(string memory numString) public pure returns (uint256) {
        uint256 val = 0;
        bytes memory stringBytes = bytes(numString);
        for (uint256 i = 0; i < stringBytes.length; i++) {
            uint256 exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint256 jval = uval - uint256(0x30);

            val += (uint256(jval) * (10**(exp - 1)));
        }
        return val;
    }

    function random(uint256 number) public returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        initialNumber++,
                        block.timestamp,
                        msg.sender
                    )
                )
            ) % number;
    }

    function retrieve() public view returns (uint256) {
        return initialNumber;
    }

    function sumToInitialNumber(uint256 _sumNumber) public {
        initialNumber += _sumNumber;
    }
}