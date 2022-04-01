// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./Factory.sol";

//for bytecode argument, feel free to use Dummy contract 0xd5064b7067EAfA6a30ef8b20BcD0bbDa82D0F21e

contract Challenge {
    bool public isSolved;
    Factory factory;

    constructor(address _factory) {
        factory = Factory(_factory);
    }

    function createContract(bytes memory bytecode, uint256 salt) public {
        isSolved = factory.createContract(bytecode, salt);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract Factory {
    function createContract(bytes memory bytecode, uint256 salt)
        public
        returns (bool)
    {
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        require(isForbidden(addr), "Only Forbidden Contracts");
        require(isFunded(addr), "Only Funded Contracts");
        return true;
    }

    function isForbidden(address _addr) internal pure returns (bool) {
        bytes20 addr = bytes20(_addr);
        bytes20 id = hex"00000000000000000000000000000000000f0b1d";
        bytes20 mask = hex"00000000000000000000000000000000000fffff";

        for (uint256 i; i != 30; ++i) {
            if (addr & mask == id) {
                return true;
            }
            mask <<= 4;
            id <<= 4;
        }

        return false;
    }

    function isFunded(address _addr) internal view returns (bool) {
        return _addr.balance >= 0.01 ether;
    }
}