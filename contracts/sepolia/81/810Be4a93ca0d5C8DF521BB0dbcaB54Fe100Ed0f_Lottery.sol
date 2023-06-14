/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.17 and less than 0.9.0
pragma solidity ^0.8.17;

contract Lottery {
    struct Participant {
        address wallet;
        uint tickets;
    }

    struct Winner {
        address wallet;
        string prize;
    }

    uint public lotteryID;
    string[] public prizes;

    uint randNonce;
    address[] winners;
    address[] participants;
    mapping(address => uint) participantsMap; // wallet -> number of tickets
    mapping(address => string) winnersMap; // wallet -> prize

    constructor(uint _lotteryID, uint _randNonce, string[] memory _prizes) {
        require(_prizes.length > 0, "prizes required");

        randNonce = _randNonce;
        lotteryID = _lotteryID;
        prizes = _prizes;
    }

    function addParticipants(Participant[] calldata _participants) public {
        for (uint i = 0; i < _participants.length; i++) {
            Participant memory participant = _participants[i];
            require(winners.length == 0, "lottery completed");
            require(participant.tickets > 0, "wallet should have tickets");
            require(participantsMap[participant.wallet] == 0, "duplicate");

            participants.push(participant.wallet);
            participantsMap[participant.wallet] = participant.tickets;
        }
    }

    function checkTickets(address participant) public view returns (uint) {
        return participantsMap[participant];
    }

    function checkPrize(address participant) public view returns (string memory) {
        return winnersMap[participant];
    }

    function getWinners() public view returns (Winner[] memory) {
        require(winners.length > 0, "lottery not completed");

        Winner[] memory ww = new Winner[](winners.length);
        for (uint i = 0; i < winners.length; i++) {
            ww[i] = Winner(winners[i], prizes[i]);
        }

        return ww;
    }

    function draw2() external {
        require(winners.length == 0, "lottery completed");
        require(participants.length > 0, "not enougth participants");
        require(prizes.length <= participants.length, "not enougth participants");

        winners = new address[](prizes.length);
        address[] memory walletsInDraw = participants;
        uint[] memory weightSum = new uint[](walletsInDraw.length);

        weightSum[0] = participantsMap[walletsInDraw[0]];
        for (uint j = 1; j < weightSum.length; j++) {
            weightSum[j] = weightSum[j - 1] + participantsMap[walletsInDraw[j]];
        }

        for (uint i = 0; i < prizes.length; i++) {
            uint maxWeight = weightSum[weightSum.length - 1 - i];
            uint winnerIdx = getRandomIdx(
                weightSum,
                weightSum.length - i,
                maxWeight
            );

            winners[i] = walletsInDraw[winnerIdx];
            walletsInDraw[winnerIdx] = walletsInDraw[walletsInDraw.length - 1];

            if (winnerIdx == 0) {
                weightSum[0] = participantsMap[walletsInDraw[0]];
                winnerIdx++;
            }

            for (uint j = winnerIdx; j < weightSum.length; j++) {
                weightSum[j] = weightSum[j - 1] + participantsMap[walletsInDraw[j]];
            }
        }
    }

    function draw() public {
        require(winners.length == 0, "lottery completed");
        require(participants.length > 0, "not enougth participants");
        require(prizes.length <= participants.length, "not enougth participants");

        winners = new address[](prizes.length);
        uint[] memory weightSum = new uint[](participants.length);

        weightSum[0] = participantsMap[participants[0]];
        for (uint j = 1; j < weightSum.length; j++) {
            weightSum[j] = weightSum[j - 1] + participantsMap[participants[j]];
        }
        uint maxWeight = weightSum[weightSum.length - 1];

        for (uint i = 0; i < prizes.length; i++) {
            while (true) {
                uint winnerIdx = getRandomIdx(
                    weightSum,
                    weightSum.length - i,
                    maxWeight
                );
                address winner = participants[winnerIdx];
                 // check already won
                if (bytes(winnersMap[winner]).length > 0) {
                    continue;
                }
                winners.push(winner);
                winnersMap[winner] = prizes[i];
                break;
            }
        }
    }

    function getRandomIdx(
        uint[] memory weightSum,
        uint len,
        uint maxWeight
    ) internal returns (uint) {
        uint weight = randMod(maxWeight + 1);
        uint left = 0;
        uint right = len - 1;

        while (left < right) {
            uint mid = (left + right) / 2;

            if (weightSum[mid] == weight) {
                return mid;
            } else if (weightSum[mid] < weight) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }

        return left;
    }

    // Random number
    function randMod(uint _modulus) internal returns (uint) {
        randNonce++;
        return
            uint(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % _modulus;
    }
}