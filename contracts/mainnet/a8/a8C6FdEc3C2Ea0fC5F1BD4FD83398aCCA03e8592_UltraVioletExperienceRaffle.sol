//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title Ultra Violet Experience Raffle
/// @author Nicolás Acosta - nicoacosta.eth - @0xnico_ - gh/NicoAcosta
contract UltraVioletExperienceRaffle {
    address private immutable _deployer;

    uint256 public winnerId;

    string public snapshotURL;

    bool public raffled; // false by default

    constructor(string memory _snapshotURL) {
        _deployer = msg.sender;
        snapshotURL = _snapshotURL;
    }

    function winnerRaffle() external {
        require(msg.sender == _deployer, "Caller is not contract deployer");

        require(!raffled, "Already raffled");

        raffled = true;

        winnerId = _randomId();
    }

    function _randomId() private view returns (uint256) {
        return
            (uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number),
                        block.timestamp,
                        msg.sender
                    )
                )
            ) % 66) + 5; // from 5 to 70
    }
}