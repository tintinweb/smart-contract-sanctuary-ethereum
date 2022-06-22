/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

pragma solidity ^0.5.0;

contract HorsEther {

    struct Race {
        uint[] horses; // currently only running 5 horse races
        bool paidOut; // after a race is paidOut it can be considered done
        uint expireTime; //unix timestamp
        uint[] bets;
        int winner; // -1 until a winner is determined
    }

    struct Bet {
        address payable bettorAddr;//bettor address
        bool rewarded; // if true, person already has been rewarded
        uint horseNum; //horse on which better is betting
        uint betAmount; //amount they bet
    }

    // lookup betIds from the uint[] of bets in Race structs
    mapping(uint => Bet) private betIdToBet;

    Race[] private races;

    uint betsInSystem = 0;

    //bytes32 public adminPassHash = keccak256(abi.encode("")); //useful for manually generating passwords
    bytes32 private adminPassHash = 0xc8d1bf7f2c23c61179850dae51b6ec884c2215578d89634882b1d4cb66984c47;

    function createRace(uint[] memory _horseNumbers, uint _raceTime, string memory _password) public {
        require(keccak256(abi.encode(_password)) == adminPassHash, "admin password is incorrect");
        require(_raceTime > now, "Race must take place in the future");

        uint[] memory bets;
        races.push(Race(_horseNumbers, false, _raceTime, bets, -1));
    }

    function getNumberOfBetsOnRace(uint _raceIndex) public view returns(uint) {
        return races[_raceIndex].bets.length;
    }

    function getNumberOfHorsesInRace(uint _raceIndex) public view returns(uint) {
        return races[_raceIndex].horses.length;
    }

    function getNumberOfRaces() public view returns(uint) {
        return races.length;
    }

    function getRace(uint raceIndex) public view returns(uint[] memory, bool, uint, uint, int) {
        return (races[raceIndex].horses, races[raceIndex].paidOut, races[raceIndex].expireTime,
        getNumberOfBetsOnRace(raceIndex), races[raceIndex].winner);
    }

    function createBet(uint _raceIndex, uint _horseIndex, uint _amount) public payable{
        require(msg.value >= _amount,
            "Bet amount must be equal or less than sent amount");
        require(_raceIndex < races.length, "Race does not exist");
        require(races[_raceIndex].expireTime > now, "Race has already run");
        require((_horseIndex >= 0 && _horseIndex < races[_raceIndex].horses.length),
            "Horse number does not exist in this race");

        betsInSystem++;
        uint newBetId = (betsInSystem);
        betIdToBet[newBetId] = Bet(msg.sender, false, _horseIndex, _amount);
        races[_raceIndex].bets.push(newBetId);
    }

    // Randomly generates a race winner, pays betters, and marks the race completed
    function evaluateRace(uint _raceIndex, string memory _password) public payable {
        require(keccak256(abi.encode(_password)) == adminPassHash, "admin password is incorrect");
        require(races[_raceIndex].expireTime < now, "Race not yet run");
        require(races[_raceIndex].paidOut == false, "Race already evaluated");
        require(_raceIndex < races.length, "Race does not exist");

        uint random_number = uint(blockhash(block.number-1))%10;
        int winner = 1000;
        if(random_number == 1 || random_number == 0) {
            winner = 0;
        } else if(random_number == 2 || random_number == 3) {
            winner = 1;
        } else if(random_number == 4 || random_number == 5) {
            winner = 2;
        } else if(random_number == 6 || random_number == 7) {
            winner = 3;
        } else if(random_number == 8 || random_number == 9) {
            winner = 4;
        }
        require(winner != 1000 && winner >= 0, "random winner errored");

        if(races[_raceIndex].bets.length > 0) {
            for(uint i = 0; i < races[_raceIndex].bets.length; i++){
                Bet memory tempBet = betIdToBet[races[_raceIndex].bets[i]];
                if(tempBet.horseNum == uint(winner)) {
                    uint winAmount = tempBet.betAmount*races[_raceIndex].horses.length;
                    require(address(this).balance > winAmount, "Not enough funds to reward bettor");
                    tempBet.bettorAddr.transfer(winAmount- uint(winAmount/5));
                }
            }
        }

        races[_raceIndex].paidOut = true;
        races[_raceIndex].winner = winner;
    }
}