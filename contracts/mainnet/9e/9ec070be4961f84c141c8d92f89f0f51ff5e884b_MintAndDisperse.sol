// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract MintAndDisperse {
    uint256 public constant cost = 100 * 10**18;

    error LengthMismatch();
    error FailedConfettiTransfer();
    error RemainingFighters();

    IConfetti public constant Confetti =
        IConfetti(0xCfef8857E9C80e3440A823971420F7Fa5F62f020);

    IFighter public constant Fighter =
        IFighter(0x87E738a3d5E5345d6212D8982205A564289e6324);

    constructor() {
        Confetti.approve(
            0x67283EE31eA17Bb03D958c0386155e6665DE5fbf,
            type(uint256).max
        );
    }

    function _summon() internal {
        unchecked {
            assembly {
                let ptr := mload(0x40)
                mstore(
                    ptr,
                    0xa19b908200000000000000000000000000000000000000000000000000000000
                )

                let success := call(
                    gas(),
                    0x67283EE31eA17Bb03D958c0386155e6665DE5fbf,
                    0,
                    ptr,
                    0x04,
                    0,
                    0
                )

                if iszero(success) {
                    revert(0, 0)
                }
            }
        }
    }

    function execute(
        uint256 total,
        uint256 tokenId,
        address[] calldata to,
        uint256[] calldata counts
    ) external {
        if (to.length != counts.length) {
            revert LengthMismatch();
        }

        unchecked {
            if (
                !Confetti.transferFrom(msg.sender, address(this), total * cost)
            ) {
                revert FailedConfettiTransfer();
            }

            for (uint256 i; i < total; i++) {
                _summon();
            }

            for (uint256 i; i < to.length; i++) {
                for (uint256 j; j < counts[i]; j++) {
                    Fighter.transferFrom(address(this), to[i], tokenId);
                    tokenId += 1;
                }
            }
        }

        if (Fighter.balanceOf(address(this)) > 0) {
            revert RemainingFighters();
        }
    }
}

interface IFighter {
    function balanceOf(address) external returns (uint256);

    function tokenOfOwnerByIndex(address, uint256) external returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

interface IConfetti {
    function approve(address, uint256) external returns (bool);

    function balanceOf(address) external returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}