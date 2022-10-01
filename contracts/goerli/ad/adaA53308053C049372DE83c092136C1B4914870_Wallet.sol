/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Wallet {
    address entryPoint;
    address owner;
    uint256 Nonce;

    constructor(address _entryPoint, address _owner) {
        entryPoint = _entryPoint;
        owner = _owner;
    }

    struct UserOperation {
        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }

    function validateUserOp(UserOperation calldata userOp,
        bytes32 requestId,
        address aggregator,
        uint256 missingWalletFunds) external {
        _requireFromEntryPoint();
        _validateSignature(userOp);
        require(userOp.initCode.length == 0, "initcode not nil");
        _checkAndupdateNonce(userOp);
    }

    function _requireFromEntryPoint() internal view {
        require(msg.sender == entryPoint, "call not from entrypoint");
    }

    function _validateSignature(UserOperation calldata uop)
        internal
        pure
        returns (bool)
    {
        bytes32 sig = bytes32(uop.signature);
        return sig == _hashInfo(uop);
    }

    function _hashInfo(UserOperation calldata uop)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(uop.sender, uop.nonce, uop.callData));
    }

    function _checkAndupdateNonce(UserOperation calldata uop) internal {
        require(Nonce + 1 == uop.nonce, "Nonce incorrect");
        Nonce = Nonce + 1;
    }

    function nonce() external view returns (uint256) {
        return Nonce;
    }
}