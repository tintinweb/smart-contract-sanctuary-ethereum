// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Ownable} from "./Ownable.sol";
import {ECDSA} from "./ECDSA.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";

contract BuxSwapClaimer is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    error NonceAlreadyUsed();
    error InvalidSignature();
    error ClaimExpired();

    address public claimSigner; // ECDSA signer
    address public buxswapContract; // vault
    mapping(uint256 => bool) private usedNonces;

    constructor(address signer) {
        claimSigner = signer;
    }

    /// @dev set a new buxswap contract
    function setBuxswapContract(address buxswap) external onlyOwner {
        buxswapContract = buxswap;
    }

    ////////////////
    /// Claiming ///
    ////////////////

    /// @dev claim a supported ERC20 token
    function claim(
        address token,
        uint256 amount,
        uint256 nonce,
        uint256 expires,
        bytes memory signature
    ) external nonReentrant {
        if (usedNonces[nonce]) revert NonceAlreadyUsed();
        if (block.timestamp > expires) revert ClaimExpired();

        // verify signature
        bytes32 msgHash = keccak256(
            abi.encodePacked(_msgSender(), token, nonce, expires, amount)
        );
        if (!isValidSignature(msgHash, signature)) revert InvalidSignature();
        usedNonces[nonce] = true;

        IBuxSwap(buxswapContract).claim(_msgSender(), token, amount);
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool isValid)
    {
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return signedHash.recover(signature) == claimSigner;
    }
}

interface IBuxSwap {
    function claim(
        address to,
        address token,
        uint256 amount
    ) external;
}