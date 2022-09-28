/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

//SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

error NOT_WHITELISTED_OR_OWNER();
error INVALID_SIGNATURE_LENGTH();

interface Factory {
    function whitelists(address _payer, address _signer)
        external
        view
        returns (uint256);

    function ownerOf(uint256 _id) external view returns (address);
}

interface Payer {
    function withdraw(uint256 _id, uint256 _amount) external;
}

contract LlamaPayV2GaslessWithdrawal {
    address public immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function getMessageHash(
        address _payer,
        uint256 _id,
        uint256 _amount,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_payer, _id, _amount, _nonce));
    }

    function splitSignature(bytes memory _sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        if (_sig.length != 65) revert INVALID_SIGNATURE_LENGTH();

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }

    function getSigner(
        bytes32 _signature,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public pure returns (address) {
        return ecrecover(_signature, _v, _r, _s);
    }

    function executeGaslessWithdrawal(
        address _payer,
        uint256 _id,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) external {
        bytes32 messageHash = getMessageHash(_payer, _id, _amount, _nonce);
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        address signer = getSigner(messageHash, v, r, s);
        if (
            Factory(factory).whitelists(_payer, signer) != 1 &&
            signer != Factory(factory).ownerOf(_id)
        ) revert NOT_WHITELISTED_OR_OWNER();
        Payer(_payer).withdraw(_id, _amount);
    }
}