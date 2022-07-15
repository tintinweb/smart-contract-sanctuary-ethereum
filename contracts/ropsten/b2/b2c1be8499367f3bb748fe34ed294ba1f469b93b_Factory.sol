/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IName {
    function name() external view returns (bytes32);
}

contract FuzzyIdentityChallenge {
    bool public isComplete;

    function authenticate() public {
        require(isSmarx(msg.sender));
        require(isBadCode(msg.sender));

        isComplete = true;
    }

    function isSmarx(address addr) internal view returns (bool) {
        return IName(addr).name() == bytes32("smarx");
    }

    function isBadCode(address _addr) public pure returns (bool) {
        bytes20 addr = bytes20(_addr);
        bytes20 id = hex"000000000000000000000000000000000badc0de";
        bytes20 mask = hex"000000000000000000000000000000000fffffff";

        for (uint256 i = 0; i < 34; i++) {
            if (addr & mask == id) {
                return true;
            }
            mask <<= 4;
            id <<= 4;
        }

        return false;
    }
}

contract Impersonator is IName {
    function name() external pure returns (bytes32) {
        return bytes32("smarx");
    }

    function impersonateAuthentication(address target) public {
        FuzzyIdentityChallenge(target).authenticate();
    }
}

contract Factory {
    function _encodeBytecode()
        public
        pure
        returns (bytes memory)
    {
        bytes memory bytecode = abi.encodePacked(
            type(Impersonator).creationCode
        );

        return bytecode;
    }

    function deployFactory(bytes32 _salt)
        external
        returns (address)
    {
        address addr;
        bytes memory bytecode = _encodeBytecode();
        assembly {
            addr := create2(callvalue(), add(bytecode, 0x20), mload(bytecode), _salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }

    function predetermineChildAddress(
        bytes32 _salt,
        bytes memory _bytecode
    ) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(
                    abi.encodePacked(
                        _bytecode
                    )
                )
            )
        );

        return address(uint160(uint256(hash)));
    }
}