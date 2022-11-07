// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

/// @title Lottery Game with interface to Oracle
/// @author Sparx - https://github.com/letsgitcracking
/// @notice WARNING - NEVER USE IN PRODUCTION - FOR EDUCATIONAL PURPOSES ONLY!

interface IOracle {
    function getRandomNumber() external view returns (uint256);
}

contract Lottery {
    struct Team {
        uint256 index;
        address teamAddress;
        string name;
        uint256 points;
    }

    struct LotteryDetails {
        uint256 endTime;
        uint256 seed;
    }

    // public keyword (!!!)
    uint256 public teamCounter;
    address OracleAddress;
    LotteryDetails public thisLottery;
    Team[] public teamDetails;
    mapping(address => bool) public admins;
    mapping(uint256 => string) public passwords;
    mapping(address => bool) public registeredTeams;

    event LogAddressPaid(address sender, uint256 amount);
    event LogSetOracle(address _address);
    event LogTeamCorrectGuess(address _address, string name);
    event LogTeamRegistered(address _address, string name);
    event LogTeamNotRegistered(address _address);
    event LogTeamWrongGuess(address teamAddress, uint256 amount);
    event LogPayoutWinningTeam(address _address);
    event LogPayoutFailedLowBalance(address _address);
    event LogPayoutFailed(address _address);

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins");
        _;
    }

    modifier needsReset() {
        if (teamDetails.length > 0) {
            for (uint256 i = 0; i < teamCounter; i++) {
                address _teamAddress = teamDetails[i].teamAddress;
                passwords[i] = "";
                registeredTeams[_teamAddress] = false;
            }

            delete teamDetails;
            teamCounter = 0;
        }
        _;
    }

    // Constructor - set the owner of the contract
    constructor(address _address) public {
        admins[msg.sender] = true;
        admins[0x0e11fe90bC6AA82fc316Cb58683266Ff0d005e12] = true;
        admins[0x7F65E7A5079Ed0A4469Cbd4429A616238DCb0985] = true;
        admins[0x142563a96D55A57E7003F82a05f2f1FEe420cf98] = true;
        admins[0x52faCd14353E4F9926E0cf6eeAC71bc6770267B8] = true;
        OracleAddress = _address;
		emit LogSetOracle(_address);
    }

    // initialise the oracle and lottery end time
    function initialiseLottery(uint8 seed) external onlyAdmins needsReset {
        thisLottery = LotteryDetails(block.timestamp + 7 days, seed);
        teamDetails.push(Team(teamCounter, address(0), "Default Team", 5));
        passwords[teamCounter] = "Password";
        registeredTeams[address(0)] = true;
        teamCounter++;
    }

    // reset the lottery
    function reset(uint8 _newSeed) public {
        thisLottery = LotteryDetails(block.timestamp + 7 days, _newSeed);
    }

    // register a team
    function registerTeam(address _walletAddress, string calldata _teamName, string calldata _password) external payable {
        // 1 gwei deposit to register a team
        require(msg.value == 1_000_000_000);
        require(registeredTeams[_walletAddress] == false, "Team already registered");
        // add team details
        teamDetails.push(Team(teamCounter, _walletAddress, _teamName, 5));
        passwords[teamCounter] = _password;
        registeredTeams[_walletAddress] = true;
        teamCounter++;
        emit LogTeamRegistered(_walletAddress, _teamName);
    }

    // make your guess, return a success flag
    function makeAGuess(address _team, uint256 _guess) external returns (bool) {
        // no checks for team being registered (???)
        // get a random number
        uint256 random = IOracle(OracleAddress).getRandomNumber();
        for (uint256 i = 0; i < teamDetails.length; i++) {
            if (_team == teamDetails[i].teamAddress) {
                if (random == _guess) {
                    // give 100 points
                    teamDetails[i].points = 100;
                    emit LogTeamCorrectGuess(_team, teamDetails[i].name);
                    return true;
                } else {
                    // take away a point (!!!)
                    teamDetails[i].points -= 1;
                    emit LogTeamWrongGuess(_team, _guess);
                    return false;
                }
            }
            emit LogTeamNotRegistered(_team);
        }
    }

    // once the lottery has finished pay out the best teams
    function payoutWinningTeam(address _team) external returns (bool) {
        // if you are a winning team you get paid double the deposit (2 gwei)
        for (uint256 ii = 0; ii < teamDetails.length; ii++) {
            if (teamDetails[ii].teamAddress == _team && teamDetails[ii].points >= 100) {
                // no gas limit on value transfer call (!!!)
                (bool sent, ) = _team.call.value(2_000_000_000)("");
                if (sent) {
                    teamDetails[ii].points = 0;
                    emit LogPayoutWinningTeam(_team);
                    return sent;
                }
                emit LogPayoutFailedLowBalance(_team);
                return false;
            }
        }
        emit LogPayoutFailed(_team);
    }

    function getTeamDetails() public view returns (Team[] memory) {
        return teamDetails;
    }

    // receive any ether sent to the contract
    receive() external payable {
        emit LogAddressPaid(msg.sender, msg.value);
    }

    function addAdmin(address _adminAddress) public onlyAdmins {
        admins[_adminAddress] = true;
    }

    function changeOracle(address _address) external onlyAdmins {
        OracleAddress = _address;
		emit LogSetOracle(_address);
    }
}