// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface EulerClaims {
    struct TokenAmount {
        address token;
        uint amount;
    }

    function claimAndAgreeToTerms(
        bytes32 acceptanceToken,
        uint index,
        TokenAmount[] calldata tokenAmounts,
        bytes32[] calldata proof
    ) external;
}

interface ERC20 {
    function balanceOf(address account) external returns (uint256);

    function transfer(address to, uint256 amount) external;
}

contract AloeBlendRecovery {
    EulerClaims public constant EULER_CLAIMS = EulerClaims(0x4DDce44ab524F49b4050D9d59D7cF61cDa865F84);

    address public constant BLEND_POOL = 0xe53555FDBe3B38455671794b2280b7Fa357C6b48;

    bytes32 private immutable acceptanceToken;

    constructor() {
        acceptanceToken = keccak256(abi.encodePacked(
            address(this),
            bytes32(0x771a3595090b38cc79643cfb9d1449134f0a693fdbc9f1aec8ec1878fb369e75)
        ));
    }

    function recover(
        uint256 index,
        EulerClaims.TokenAmount[] calldata tokenAmounts,
        bytes32[] calldata proof
    ) external {
        EULER_CLAIMS.claimAndAgreeToTerms(acceptanceToken, index, tokenAmounts, proof);

        unchecked {
            uint256 count = tokenAmounts.length;
            for (uint256 i = 0; i < count; i++) {
                EulerClaims.TokenAmount memory tokenAmount = tokenAmounts[i];
                ERC20(tokenAmount.token).transfer(BLEND_POOL, tokenAmount.amount);
            }
        }
    }
}