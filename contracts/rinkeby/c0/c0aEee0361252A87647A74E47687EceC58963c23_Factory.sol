// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


contract Factory {
    event Deployed(address addr, uint salt);


    function getAddress(bytes memory bytecode, uint _salt)
        public
        view
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode))
        );

        return address(uint160(uint(hash)));
    }

    function deploy(bytes memory bytecode, uint _salt) public payable {
        address addr;

        assembly {
            addr := create2(
                callvalue(),
                add(bytecode, 0x20),
                mload(bytecode), 
                _salt 
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, _salt);
    }
}