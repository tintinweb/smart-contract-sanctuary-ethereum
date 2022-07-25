// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";

contract Roulette is Ownable {
    // Sizes optimized to fit in a 256 bits storage slot.
    struct Bet {
        uint80 value;
        uint160 blockNumber;
        uint8 rouletteNumber;
        bool claimed;
    }

    struct Winning {
        uint index;
        uint value;
    }

    uint80 public minimumBet = 0.0001 ether;
    uint80 public maximumBet = 0.01 ether;

    uint8 private constant ROULETTE_MAX_NUMBER = 36;

    mapping(address => Bet[]) private userBets;

    event BetPlaced(address user, uint index);
    event RewardClaimed(address user, uint index);

    constructor() {}

    receive() external payable {}

    fallback() external payable {
        revert("Invalid function called.");
    }

    function placeBet(uint8 rouletteNumber) external payable {
        require(msg.value >= minimumBet, "Transaction value is below the minimum bet.");
        require(msg.value <= maximumBet, "Transaction value is above the maximum bet.");
        require(rouletteNumber <= ROULETTE_MAX_NUMBER, "rouletteNumber must be between 0 and 36.");

        Bet memory newBet = Bet({
            value: uint80(msg.value),
            blockNumber: uint160(block.number),
            rouletteNumber: uint8(rouletteNumber),
            claimed: false
        });

        Bet[] storage bets = userBets[msg.sender];

        bets.push(newBet);
        uint newBetIndex = bets.length - 1;

        emit BetPlaced(msg.sender, newBetIndex);
    }

    function claimRewardByIndex(uint index) external {
        uint reward = getUserRewardByIndex(msg.sender, index);

        userBets[msg.sender][index].claimed = true;

        if (reward > 0) {
            sendReward(reward);
        }

        emit RewardClaimed(msg.sender, index);
    }

    function setMinimumBet(uint80 value) external onlyOwner {
        minimumBet = value;
    }

    function setMaximumBet(uint80 value) external onlyOwner {
        minimumBet = value;
    }

    function withdraw(uint amount) external onlyOwner {
        sendFunds(amount, owner());
    }

    function getUserBets(address user) external view returns (Bet[] memory) {
        return userBets[user];
    }

    function getUserWinningBets(address user) external view returns (Winning[] memory) {
        Bet[] memory bets = userBets[user];

        require(bets.length > 0, "You have not placed any bets.");

        bool hasUnclaimedBets = false;
        // Array needs to be fixed size so allocate maximum size and copy into a smaller array after.
        Winning[] memory unclaimedWinnings = new Winning[](userBets[user].length);
        uint nextWinningsIndex = 0;
        for (uint i = 0; i < bets.length; i++) {
            Bet memory bet = bets[i];

            if (bet.claimed) continue;
            hasUnclaimedBets = true;
            if (!isBlockMined(bet.blockNumber + 1)) break;
            if (!isBlockHashStillAvailable(bet.blockNumber + 1)) continue;
            if (!isWinningBet(bet)) continue;

            Winning memory winning = Winning({
                index: i,
                value: getWinningBetReward(bet)
            });

            unclaimedWinnings[nextWinningsIndex++] = winning;
        }

        require(hasUnclaimedBets, "You don't have any unclaimed bets.");
        
        Winning[] memory resizedWinnings = new Winning[](nextWinningsIndex);
        for (uint i = 0; i < nextWinningsIndex; i++) {
            resizedWinnings[i] = unclaimedWinnings[i];
        }

        return resizedWinnings;
    }

    function getUserTotalRewards(address user) external view returns (uint) {
        Bet[] memory bets = userBets[user];

        require(bets.length > 0, "You have not placed any bets.");

        bool hasUnclaimedBets = false;
        uint totalRewards = 0;
        for (uint i = 0; i < bets.length; i++) {
            Bet memory bet = bets[i];

            if (bet.claimed) continue;
            hasUnclaimedBets = true;
            if (!isBlockMined(bet.blockNumber + 1)) break;
            if (!isBlockHashStillAvailable(bet.blockNumber + 1)) continue;
            if (!isWinningBet(bet)) continue;

            totalRewards += getWinningBetReward(bet);
        }

        require(hasUnclaimedBets, "You don't have any unclaimed bets.");

        return totalRewards;
    }

    function getBlockRouletteNumber(uint blockNumber) external view returns (uint)
    {
        require(isBlockMined(blockNumber + 1), "This block's number is not available yet.");
        require(
            isBlockHashStillAvailable(blockNumber + 1),
            "This block's number is not available anymore because it is too old."
        );

        return getBlockRouletteNumberUnsafe(blockNumber);
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getUserRewardByIndex(address user, uint index) public view returns (uint) {
        require(userBets[user].length > index, "The requested bet does not exist.");

        Bet memory bet = userBets[user][index];

        require(!bet.claimed, "This reward has already been claimed.");
        require(
            isBlockMined(bet.blockNumber + 1),
            "You need to wait for at least one block to be mined after the bet was made for its reward to become available."
        );
        require(
            isBlockHashStillAvailable(bet.blockNumber + 1),
            "This reward is not available anymore because it is too old."
        );

        if (isWinningBet(bet)) {
            return getWinningBetReward(bet);
        } else {
            return 0;
        }
    }

    function isBlockMined(uint blockNumber) internal view returns (bool) {
        return block.number > blockNumber;
    }

    function isBlockHashStillAvailable(uint blockNumber) internal view returns (bool) {
        // blockhash only works for the last 256 blocks
        // No reward can be claimed after 256 blocks have passed so that someone can't exploit this
        return block.number <= blockNumber + 256;
    }

    function isWinningBet(Bet memory bet) internal view returns (bool) {
        return bet.rouletteNumber == getBlockRouletteNumberUnsafe(bet.blockNumber);
    }

    function getBlockRouletteNumberUnsafe(uint blockNumber) internal view returns (uint)
    {
        return uint(blockhash(blockNumber + 1)) % (ROULETTE_MAX_NUMBER + 1);
    }

    function getWinningBetReward(Bet memory bet) internal pure returns (uint) {
        return bet.value * ROULETTE_MAX_NUMBER;
    }

    function sendReward(uint amount) private {
        sendFunds(amount, msg.sender);
    }

    function sendFunds(uint amount, address recipient) private {
        require(amount <= getContractBalance(), "Amount to send exceeds contract balance.");

        (bool success,) = payable(recipient).call{value: amount}("");
        require(success, "Could not send funds.");
    }
}