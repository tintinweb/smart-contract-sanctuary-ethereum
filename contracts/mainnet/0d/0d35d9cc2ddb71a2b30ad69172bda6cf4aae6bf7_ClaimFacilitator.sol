/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

pragma solidity 0.8.11;

interface IMerkleWalletClaimer {
    function claimFor(address owner, uint256 index, address wallet, address initialSigningKey, bytes calldata claimantSignature, bytes32[] calldata merkleProof) external;
}

struct ClaimArgs {
    address owner;
    uint256 index;
    address wallet;
    address initialSigningKey;
    bytes claimantSignature;
    bytes32[] merkleProof;
}

contract ClaimFacilitator {
    IMerkleWalletClaimer private constant _claimer = IMerkleWalletClaimer(
        0xD8470a6d796d54F13f243A4cf1a890E65bF3670E
    );

    function claimForInBatch(ClaimArgs[] memory claims) external {
        unchecked {
            for (uint256 i = 0; i < claims.length; ++i) {
                ClaimArgs memory claim = claims[i];
                _claimer.claimFor(
                    claim.owner,
                    claim.index,
                    claim.wallet,
                    claim.initialSigningKey,
                    claim.claimantSignature,
                    claim.merkleProof
                );
            }
        }
    }
}