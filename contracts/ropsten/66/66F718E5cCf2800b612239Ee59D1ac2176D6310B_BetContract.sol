/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

pragma solidity ^0.8.0;

contract BetContract {
    struct Fixture {
        uint256 fixId;
        string home;
        string away;
        string date;
        bool active;
        bool invalidated;
        string winner;
        uint256[] bets;
    }

    struct Bet {
        uint256 betId;
        uint256 fixId;
        address punter; // we are going to assume that only EOA wallets can be punters
        string team;
        uint256 amount;
        int256 payOut;
        bool invalidated;
        bool payedOut;
    }

    struct BettingTotals {
        uint256 home;
        uint256 away;
    }

    address public owner;
    uint256 fixtureCounter;
    uint256 betCounter;
    uint256 loserCut;
    bool locked;

    mapping(uint256 => Fixture) fixtures;
    mapping(uint256 => Bet) allBets;
    mapping(address => uint256[]) userBets;

    uint256[] betIdList;
    uint256[] fixtureIdList;

    /**
     * Contract initialization.
     */
    constructor() {
        owner = msg.sender;
        fixtureCounter = 0;
        betCounter = 0;
        loserCut = 99;
        locked = false;
    }

    /**
     * A function that adds a fixture.
     *
     * @param _home the home team
     * @param _away the away team
     * @param _date the date of the match
     */
    function addFixture(
        string memory _home,
        string memory _away,
        string memory _date
    ) public {
        require(
            msg.sender == owner,
            "Only UQ Sports Administration can add Fixtures"
        );

        require(
            checkFixtureInput(_home, _away, _date) == true,
            "Duplicate Fixture"
        );

        Fixture memory newFixture = fixtures[fixtureCounter++];
        newFixture.fixId = (fixtureCounter - 1);
        newFixture.home = _home;
        newFixture.away = _away;
        newFixture.date = _date;
        newFixture.active = true;
        newFixture.winner = "";
        newFixture.invalidated = false;

        fixtureIdList.push(fixtureCounter - 1);
        fixtures[fixtureCounter - 1] = newFixture;
    }

    function checkFixtureInput(
        string memory _home,
        string memory _away,
        string memory _date
    ) private view returns (bool) {
        string memory newFixture = string(
            abi.encodePacked(_home, _away, _date)
        );
        bool valid = true;
        for (uint256 i = 0; i < fixtureIdList.length; i++) {
            if (fixtures[i].active) {
                string memory oldFixture = string(
                    abi.encodePacked(
                        fixtures[i].home,
                        fixtures[i].away,
                        fixtures[i].date
                    )
                );
                if (
                    keccak256(abi.encodePacked(oldFixture)) ==
                    keccak256(abi.encodePacked(newFixture))
                ) {
                    valid = false;
                    break;
                }
            }
        }
        return valid;
    }

    function getFixtures() public view returns (uint256[] memory) {
        return fixtureIdList;
    }

    /**
     * Read only function to retrieve a fixture.
     */
    function getFixture(uint256 fixtureId)
        public
        view
        returns (Fixture memory)
    {
        return fixtures[fixtureId];
    }

    function getFixtureCount() public view returns (uint256) {
        return fixtureCounter;
    }

    function getBet(uint256 betID) public view returns (Bet memory) {
        return allBets[betID];
    }

    function getBetCounter() public view returns (uint256) {
        return betCounter;
    }

    function getUserBets() public view returns (uint256[] memory) {
        return userBets[msg.sender];
    }

    /**
     * A function to place bets on a particular sport.
     */
    function placeBet(
        uint256 fixtureID,
        string memory team,
        uint256 amount
    ) public payable {
        require(
            msg.sender != owner,
            "UQ Sports Administration cannot place bets"
        );
        require(amount > 0, "Bet amount must be greater than 0");
        require(
            amount == msg.value,
            "Amount deposited does not equal message value"
        );

        require(checkBetInput(fixtureID, team) == true, "Not a valid Bet");

        address a = msg.sender;
        Bet memory newBet;
        newBet.fixId = fixtureID;
        newBet.betId = (betCounter);
        newBet.punter = a;
        newBet.team = team;
        newBet.amount = amount;

        allBets[betCounter] = newBet;

        // Add to user bets
        userBets[msg.sender].push(betCounter);

        fixtures[fixtureID].bets.push(betCounter);
        betIdList.push(betCounter);
        allBets[betCounter] = newBet;

        betCounter++;
    }

    function checkBetInput(uint256 fixtureID, string memory team)
        private
        view
        returns (bool)
    {
        bool valid = true;
        if (!fixtures[fixtureID].active) {
            valid = false;
        }
        if (
            !(keccak256(abi.encodePacked(team)) ==
                keccak256(abi.encodePacked(fixtures[fixtureID].home))) &&
            !(keccak256(abi.encodePacked(team)) ==
                keccak256(abi.encodePacked(fixtures[fixtureID].away)))
        ) {
            valid = false;
        }
        return valid;
    }

    function retrieveFunds(uint256 betId) public payable {
        require(!locked, "Re-entrancy detected");
        require(
            fixtures[allBets[betId].fixId].active == false,
            "Cannot withdraw winnings, fixture is still active"
        );
        require(
            allBets[betId].payedOut == false,
            "Bet has already been payed out"
        );
        require(allBets[betId].payOut >= 0, "This bet has not been won");
        require(
            allBets[betId].punter == msg.sender,
            "Not the owner of this bet"
        );

        locked = true;
        (bool success, ) = allBets[betId].punter.call{
            value: uint256(allBets[betId].payOut)
        }("");
        require(success, "Failed to withdraw winnings");
        allBets[betId].payedOut = true;
        locked = false;
    }

    function getBettingTotals(uint256 fixtureId)
        public
        view
        returns (BettingTotals memory)
    {
        uint256 home = 0;
        uint256 away = 0;

        for (uint256 i = 0; i < fixtures[fixtureId].bets.length; i++) {
            if (
                keccak256(
                    abi.encodePacked(
                        (allBets[fixtures[fixtureId].bets[i]].team)
                    )
                ) == keccak256(abi.encodePacked(fixtures[fixtureId].home))
            ) {
                home += allBets[fixtures[fixtureId].bets[i]].amount;
            } else {
                away += allBets[fixtures[fixtureId].bets[i]].amount;
            }
        }

        BettingTotals memory totals;
        totals.home = home;
        totals.away = away;

        return totals;
    }

    function setWinner(uint256 fixtureId, string memory winner) public {
        require(
            msg.sender == owner,
            "Only UQ Sports Administration can set the winner"
        );
        require(fixtures[fixtureId].active == true, "Fixture is inactive");

        // Set winner and inactive
        fixtures[fixtureId].active = false;
        fixtures[fixtureId].winner = winner;

        // Calculate winner and loser totals
        uint256 losersTotal;
        uint256 winnersTotal;
        BettingTotals memory totals = getBettingTotals(fixtureId);
        if (
            keccak256(abi.encodePacked(fixtures[fixtureId].home)) ==
            keccak256(abi.encodePacked((winner)))
        ) {
            // Home Winner
            losersTotal = (totals.away / 100) * loserCut;
            winnersTotal = totals.home;
        } else {
            // Away winner
            losersTotal = (totals.home / 100) * loserCut;
            winnersTotal = totals.away;
        }

        // Set bet payouts
        for (uint256 i = 0; i < fixtures[fixtureId].bets.length; i++) {
            if (
                keccak256(
                    abi.encodePacked(
                        (allBets[fixtures[fixtureId].bets[i]].team)
                    )
                ) == keccak256(abi.encodePacked((winner)))
            ) {
                // Winner
                uint256 amountBet = allBets[fixtures[fixtureId].bets[i]].amount;
                uint256 payOut = amountBet +
                    ((((amountBet * 100) / winnersTotal) * losersTotal) / 100);
                allBets[fixtures[fixtureId].bets[i]].payOut = int256(payOut);
            } else {
                // Loser
                allBets[fixtures[fixtureId].bets[i]].payOut = -int256(
                    allBets[fixtures[fixtureId].bets[i]].amount
                );
                allBets[fixtures[fixtureId].bets[i]].payedOut = true;
            }
        }
    }

    function setInvalidated(uint256 fixtureId) public {
        require(
            msg.sender == owner,
            "Only UQ Sports Administration can set the winner"
        );

        fixtures[fixtureId].invalidated = true;
        fixtures[fixtureId].active = false;
        for (uint256 i = 0; i < fixtures[fixtureId].bets.length; i++) {
            allBets[fixtures[fixtureId].bets[i]].payOut = int256(
                allBets[fixtures[fixtureId].bets[i]].amount
            );
            allBets[fixtures[fixtureId].bets[i]].invalidated = true;
        }
    }

    function takeEarnings() public onlyOwner {
        require(!locked, "Re-entrancy detected");
        uint256 amount = address(this).balance;
        bool fixturesActive = false;
        bool allBetsPaid = true;
        locked = true;
        for (uint256 i = 0; i < fixtureCounter; i++) {
            if (fixtures[i].active == true) {
                fixturesActive = true;
            }
        }
        for (uint256 i = 0; i < betCounter; i++) {
            if (allBets[i].payedOut == false) {
                allBetsPaid = false;
            }
        }
        require(
            fixturesActive == false,
            "There is still a fixture in play, cannot withdraw funds"
        );
        require(
            allBetsPaid,
            "There are still unpaid bets, wait until all bets have been claimed"
        );
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Fail in transferring funds to UQ admin");
        locked = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only UQ admin can call this function");
        _;
    }

    receive() external payable {
        //do nothing - function to receive ether.
    }

    fallback() external payable {
        //do nothing
    }
}