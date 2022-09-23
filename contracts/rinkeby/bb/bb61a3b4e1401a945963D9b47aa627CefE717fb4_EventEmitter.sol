// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract EventEmitter {
    event CHEST_OPENED(
        uint256 num,
        uint256 godId,
        uint256 prize,
        uint256 timestamp
    );
    event METH_CLAIMED(address user, uint256 amount, uint256 timestamp);
    event TEEN_RESURRECTED(
        address user,
        uint256 sacrificed,
        uint256 resurrected,
        uint256 newlyMinted
    );

    function useItem(
        uint256 tokenId,
        uint256 resurrected,
        uint256 lastTokenReceived
    ) external {
        emit TEEN_RESURRECTED(
            msg.sender,
            tokenId,
            resurrected,
            lastTokenReceived
        );
    }

    function claimTeenMeth(uint256 amount) external {
        emit METH_CLAIMED(msg.sender, amount, block.timestamp);
    }

    function openChest(
        uint256 godId,
        uint256 num,
        uint256 prize
    ) external {
        emit CHEST_OPENED(godId, num, prize, block.timestamp);
    }
}