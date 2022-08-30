// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract Create2Factory {
    event ContractCreated(address indexed addr);

    function deploy(bytes calldata creationCode, bytes32 _salt)
        external
        returns (address)
    {
        return _deploy(creationCode, _salt, msg.sender);
    }

    function _deploy(
        bytes memory code,
        bytes32 _salt,
        address _sender
    ) internal returns (address) {
        address addr = _create2(code, _salt, _sender);
        emit ContractCreated(addr);

        return addr;
    }

    function _create2(
        bytes memory code,
        bytes32 _salt,
        address _sender
    ) internal returns (address) {
        address payable addr;
        bytes32 salt = _getSalt(_salt, _sender);

        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        return addr;
    }

    function getDeploymentAddress(
        bytes32 creationCodeHash,
        bytes32 _salt,
        address _sender
    ) public view returns (address) {
        // Adapted from https://github.com/archanova/solidity/blob/08f8f6bedc6e71c24758d20219b7d0749d75919d/contracts/contractCreator/ContractCreator.sol
        bytes32 salt = _getSalt(_salt, _sender);
        bytes32 rawAddress = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                creationCodeHash
            )
        );

        return address(bytes20(rawAddress << 96));
    }

    function _getSalt(bytes32 _salt, address _sender)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_salt, _sender));
    }
}