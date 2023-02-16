// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IKittieNft {
    function mint(
        address account,
        uint256 _mintAmount,
        bytes32[] calldata merkleProofL1,
        bytes32[] calldata merkleProofL2
    ) external payable;

    function claimRewards(address account) external;

    function calculateMintingCost(
        address account,
        uint256 _mintAmount,
        bytes32[] calldata merkleProofL1,
        bytes32[] calldata merkleProofL2
    ) external view returns (uint256);

    function getClaimableAmount(address _account)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IKittieNft.sol";

contract NftManager {
    IKittieNft public kittieNftType1;
    IKittieNft public kittieNftType2;
    IKittieNft public kittieNftType3;

    constructor(
        address _kittieNftType1,
        address _kittieNftType2,
        address _kittieNftType3
    ) {
        kittieNftType1 = IKittieNft(_kittieNftType1);
        kittieNftType2 = IKittieNft(_kittieNftType2);
        kittieNftType3 = IKittieNft(_kittieNftType3);
    }

    function calculateMintingCost(
        uint256 _type,
        address account,
        uint256 _mintAmount,
        bytes32[] calldata merkleProofL1,
        bytes32[] calldata merkleProofL2
    ) external view returns (uint256) {
        if (_type == 1) {
            return
                kittieNftType1.calculateMintingCost(
                    account,
                    _mintAmount,
                    merkleProofL1,
                    merkleProofL2
                );
        } else if (_type == 2) {
            return
                kittieNftType2.calculateMintingCost(
                    account,
                    _mintAmount,
                    merkleProofL1,
                    merkleProofL2
                );
        } else if (_type == 3) {
            return
                kittieNftType3.calculateMintingCost(
                    account,
                    _mintAmount,
                    merkleProofL1,
                    merkleProofL2
                );
        } else {
            revert("Invalid type");
        }
    }

    function mint(
        uint256 _type,
        uint256 _mintAmount,
        bytes32[] calldata merkleProofL1,
        bytes32[] calldata merkleProofL2
    ) external payable {
        if (_type == 1) {
            kittieNftType1.mint{value: msg.value}(
                msg.sender,
                _mintAmount,
                merkleProofL1,
                merkleProofL2
            );
        } else if (_type == 2) {
            kittieNftType2.mint{value: msg.value}(
                msg.sender,
                _mintAmount,
                merkleProofL1,
                merkleProofL2
            );
        } else if (_type == 3) {
            kittieNftType3.mint{value: msg.value}(
                msg.sender,
                _mintAmount,
                merkleProofL1,
                merkleProofL2
            );
        } else {
            revert("Invalid type");
        }
    }

    function claimRewards() public {
        address account = msg.sender;

        uint256 claimable1 = kittieNftType1.getClaimableAmount(account);
        uint256 claimable2 = kittieNftType2.getClaimableAmount(account);
        uint256 claimable3 = kittieNftType3.getClaimableAmount(account);

        require(
            claimable1 > 0 || claimable2 > 0 || claimable3 > 0,
            "You have no rewards to claim"
        );

        if (claimable1 > 0) {
            kittieNftType1.claimRewards((account));
        }
        if (claimable2 > 0) {
            kittieNftType2.claimRewards((account));
        }
        if (claimable3 > 0) {
            kittieNftType3.claimRewards((account));
        }
    }

    function getClaimableAmount(address account)
        external
        view
        returns (uint256)
    {
        return
            kittieNftType1.getClaimableAmount(account) +
            kittieNftType2.getClaimableAmount(account) +
            kittieNftType3.getClaimableAmount(account);
    }
}