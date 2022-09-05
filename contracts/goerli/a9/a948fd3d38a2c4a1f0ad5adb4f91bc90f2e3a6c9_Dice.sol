// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Import this file to use console.log
import "./Manager.sol";

contract Dice is Manager {
    struct Profile {
        uint256 prize;
    }

    uint256 public lockedValue;

    mapping(address => Profile) public profiles;

    event BetResult(
        address indexed addr,
        uint256 playtime,
        bool result,
        uint8 score
    );

    event Received(address, uint256);

    error InvalidBetScore(uint8, uint8);

    error TooLargeBetValue(uint256, uint256);

    /**
     * make contract receivable
     */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * fallback
     */
    fallback() external payable {}

    /**
     * pay the game, bet on the score. if the random num equals score, then win!
     * todo study reentrancy
     */
    function bet(uint8 score) external payable {
        if (score > maxBetScore) {
            revert InvalidBetScore(score, maxBetScore);
        }

        require(msg.value > 0, "Ticket is not valid");
        if (msg.value > maxBetValue) {
            revert TooLargeBetValue(msg.value, maxBetValue);
        }

        uint8 rnd = uint8(random() % maxBetScore) + 1;
        bool is_win = rnd == score;

        if (rnd == score) {
            // give reward to user,
            // todo bug ananylse
            uint256 reward = uint256(msg.value * (winRate / 100));
            profiles[msg.sender].prize += reward;
            lockedValue += reward;
        }

        emit BetResult(msg.sender, block.timestamp, is_win, rnd);
    }

    /**
     * query msg.sender prize
     */
    function prize() public view returns (uint256) {
        return profiles[msg.sender].prize;
    }

    /**
     * withdraw msg.sender balance in profile
     */
    function withdraw() public {
        uint256 sender_prize = profiles[msg.sender].prize;
        require(sender_prize > 0, "No balance available");
        require(sender_prize <= address(this).balance, "Insufficient balance");

        profiles[msg.sender].prize = 0;
        lockedValue -= sender_prize;

        uint256 amount = sender_prize - (sender_prize * withdrawFeeRate) / 1000;

        payable(msg.sender).transfer(amount);
    }

    /**
     *  take fee to contract owner
     */
    function takeFee() public onlyOwner {
        require(address(this).balance > lockedValue, "Insufficient balance");

        uint256 available = address(this).balance - lockedValue;

        owner.transfer(available);
    }

    /**
     * generate a random num
     */
    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        blockhash(block.number - 1)
                    )
                )
            );
    }
}