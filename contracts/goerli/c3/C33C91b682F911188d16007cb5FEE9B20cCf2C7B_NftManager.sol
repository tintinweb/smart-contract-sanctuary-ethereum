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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IKittieNft.sol";

contract NftManager {
    IKittieNft public kittieNftType1;
    IKittieNft public kittieNftType2;
    IKittieNft public kittieNftType3;

    constructor(address _kittieNftType1, address _kittieNftType2, address _kittieNftType3) {
        kittieNftType1 = IKittieNft(_kittieNftType1);
        kittieNftType2 = IKittieNft(_kittieNftType2);
        kittieNftType3 = IKittieNft(_kittieNftType3);
    }

    function mint(
        uint256 _type,
        uint256 _mintAmount,
        bytes32[] calldata merkleProofL1,
        bytes32[] calldata merkleProofL2
    ) external payable {
        if (_type == 1) {
            kittieNftType1.mint(
                msg.sender,
                _mintAmount,
                merkleProofL1,
                merkleProofL2
            );
        } else if (_type == 2) {
            kittieNftType2.mint(
                msg.sender,
                _mintAmount,
                merkleProofL1,
                merkleProofL2
            );
        } else if (_type == 3) {
            kittieNftType3.mint(
                msg.sender,
                _mintAmount,
                merkleProofL1,
                merkleProofL2
            );
        } else {
            revert("Invalid type");
        }
    }

    function claimRewards(uint256 _type) public {
        if (_type == 1) {
            kittieNftType1.claimRewards(msg.sender);
        } else if (_type == 2) {
            kittieNftType2.claimRewards(msg.sender);
        } else if (_type == 3) {
            kittieNftType3.claimRewards(msg.sender);
        } else {
            revert("Invalid type");
        }
    }
}