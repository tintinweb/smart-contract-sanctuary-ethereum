// SPDX-License-Identifier: unlicensed
pragma solidity >=0.8.13;

contract C {

    address public _create2;
    address public predict;

    function getBytecode(address _owner, uint256 args)
        public
        pure
        returns (bytes memory)
    {
        bytes memory bytecode = type(D).creationCode;

        return abi.encodePacked(bytecode, abi.encode(_owner, args));
    }

    function getAddress(bytes memory bytecode, uint256 _salt)
        public
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(bytecode)
            )
        );

        // NOTE: cast last 20 bytes of hash to address
        predict = address(uint160(uint256(hash)));
    }

    function deploy(
        uint256 args,
        uint256 _salt
    ) public payable {
        D ad = new D{salt : bytes32(_salt)}(args);
        _create2 = address(ad);
    }
}

contract D {
    uint256 public x;
    address public owner;

    constructor(uint256 a) {
        x = a;
        owner = msg.sender;
    }
}