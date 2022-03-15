/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract BetEscrow {

    event BetOffered(uint betId);

    enum Status {
        Offered,
        Accepted,
        Settled
    }

    enum Outcome {
        A,
        B,
        Neutral
    }

    struct Bet {
        uint id;
        address playerA;
        address playerB;
        address oracle;
        IERC20 token;
        uint amount;
        Status status;
    }

    mapping(uint => Bet) public bets;

    uint public nextBetId = 0;

    function offerBet(address _playerB, address _oracle, IERC20 token, uint amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        Bet memory bet = Bet({
            id: nextBetId,
            playerA: msg.sender,
            playerB: _playerB,
            oracle: _oracle,
            token: token,
            amount: amount,
            status: Status.Offered
        });

        bets[nextBetId] = bet;
        emit BetOffered(nextBetId);
        nextBetId += 1;
    }

    function withdrawOffer(uint betId) external {
        Bet memory bet = bets[betId];
        require(msg.sender == bet.playerA, "Not the offer creator");
        require(bet.status == Status.Offered, "Not offered");
        // Cache values before deleting
        IERC20 _token = bet.token;
        uint _amount = bet.amount;
        // Delete bet before refunding to prevent reentrancy
        delete bets[betId];
        // Refund
        _token.transfer(msg.sender, _amount);
    }

    function acceptBet(uint betId) external {
        Bet memory bet = bets[betId];
        require(msg.sender == bet.playerB, "Not the offer recipient");
        require(bet.status == Status.Offered, "Not offered");

        bet.token.transferFrom(msg.sender, address(this), bet.amount);
        bets[betId].status = Status.Accepted;
    }

    function settleBet(uint betId, Outcome outcome) external {
        Bet memory bet = bets[betId];
        require(msg.sender == bet.oracle, "Not the oracle");
        require(bet.status == Status.Accepted, "Not accepted");

        bets[betId].status = Status.Settled;

        if (outcome == Outcome.A) {
            bet.token.transfer(bet.playerA, 2 * bet.amount);
        } else if (outcome == Outcome.B) {
            bet.token.transfer(bet.playerB, 2 * bet.amount);
        } else if (outcome == Outcome.Neutral) {
            bet.token.transfer(bet.playerA, bet.amount);
            bet.token.transfer(bet.playerB, bet.amount);
        }
    }
}