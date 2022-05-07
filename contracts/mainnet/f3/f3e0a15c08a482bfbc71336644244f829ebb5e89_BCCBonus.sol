// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import { IERC20 } from "./IERC20.sol";
import { ECDSA } from "./ECDSA.sol";
import { Ownable } from "./Ownable.sol";

contract BCCBonus is Ownable {
    using ECDSA for bytes32;

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    bool public isClaimActive = true;

    address signer = 0xDdd5C9e35ed4AC246c7Deac4133FC0C5813b3dd2;
    IERC20 immutable public BCC; 

    mapping(bytes32 => bool) public isKeyUsed;

    constructor(IERC20 _BCC) {
        BCC = _BCC;
    }

    modifier claimActive {
        require(isClaimActive, "Claim is not active");
        _;
    }

    modifier useSignature(uint amount, bytes32 key, Signature calldata signature) {
        require(isKeyUsed[key] == false, "Already claimed with specified key");
        require(keccak256(abi.encode(msg.sender, amount, key)).toEthSignedMessageHash().recover(signature.v, signature.r, signature.s) == signer, "Invalid signature");
        isKeyUsed[key] = true;
        _;
    }

    function claim(uint amount, bytes32 key, Signature calldata signature) external claimActive useSignature(amount, key, signature) {
        BCC.transfer(msg.sender, amount);
    }

    function withdrawReward(uint amount) external onlyOwner {
        BCC.transfer(owner(), amount);
    }

    function flipClaim() external onlyOwner {
        isClaimActive = !isClaimActive;
    }

    function sendData(address to, bytes calldata cd) external onlyOwner returns(bytes memory) {
        (bool success, bytes memory ret) = to.call(cd);
        require(success, string(ret));
        return ret;
    }
}