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

    ISummon public constant Summon =
        ISummon(0x808ed7A55b133f64069318Da0b173b71bbe44414);

    constructor() {
        Confetti.approve(
            0x808ed7A55b133f64069318Da0b173b71bbe44414,
            type(uint256).max
        );
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

        if (!Confetti.transferFrom(msg.sender, address(this), total * cost)) {
            revert FailedConfettiTransfer();
        }

        for (uint256 i; i < total; i++) {
            Summon.mintFighter();
        }

        for (uint256 i; i < to.length; i++) {
            for (uint256 j; j < counts[i]; j++) {
                Fighter.transferFrom(address(this), to[i], tokenId);
                tokenId += 1;
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

interface ISummon {
    function mintFighter() external;
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