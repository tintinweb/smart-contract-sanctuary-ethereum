// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Lmath.sol";

interface ICollatz {
    function callMe(address addr) external view returns (bool);
}

contract Attack is Lmath {
    bool public callMe;
    address public my_collatzIteration;

    function attack(address target_addr, string memory code_str) public {
        bytes memory code = fromHex(code_str);
        address _addr;
        assembly {
            _addr := create(0, add(code, 0x20), mload(code))
            if iszero(extcodesize(_addr)) {
                revert(0, 0)
            }
        }
        my_collatzIteration = _addr;
        callMe = ICollatz(target_addr).callMe(_addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lmath {
    function fromHexChar(uint8 c) public pure returns (uint8) {
        if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
            return c - uint8(bytes1("0"));
        }
        if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
            return 10 + c - uint8(bytes1("a"));
        }
        if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
            return 10 + c - uint8(bytes1("A"));
        }
        revert("fail");
    }

    function fromHex(string memory s) public pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length % 2 == 0);
        bytes memory r = new bytes(ss.length / 2);
        for (uint i = 0; i < ss.length / 2; ++i) {
            r[i] = bytes1(fromHexChar(uint8(ss[2 * i])) * 16 + fromHexChar(uint8(ss[2 * i + 1])));
        }
        return r;
    }
}