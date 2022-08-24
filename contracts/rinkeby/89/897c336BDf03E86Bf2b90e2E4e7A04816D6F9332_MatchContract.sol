//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract MatchContract {
    struct MatchData {
        bool initialized;
        uint256 team1CountryCode;
        uint256 team2CountryCode;
        uint8 matchId;
        uint256 startTime;
        uint256 tokenAmount;
        string location;
    }

    //
    mapping(uint8 => MatchData) public matchesInfo;
    uint256 totalVestingDays;
    mapping(uint256 => uint256) tokenAmount;
    mapping(uint256 => uint256[]) private matchId;
    mapping(uint8 => string) public countryNames;
    uint8 private TotalMatches = 48;

    constructor() {
        setCode();
        totalVestingDays = 90;
        tokenAmount[1] = 500;
        tokenAmount[2] = 1000;
        tokenAmount[3] = 1500;
        tokenAmount[4] = 2000;
        tokenAmount[5] = 2500;

        matchesInfo[1] = MatchData({
            initialized: true,
            team1CountryCode: 1,
            team2CountryCode: 27,
            matchId: 1,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Bayt Stadium"
        });

        matchesInfo[2] = MatchData({
            initialized: true,
            team1CountryCode: 17,
            team2CountryCode: 10,
            matchId: 2,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Thumama Stadium"
        });

        matchesInfo[3] = MatchData({
            initialized: true,
            team1CountryCode: 6,
            team2CountryCode: 18,
            matchId: 3,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Khalifa International Stadium"
        });
        matchesInfo[4] = MatchData({
            initialized: true,
            team1CountryCode: 15,
            team2CountryCode: 30,
            matchId: 4,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Ahmad Bin Ali Stadium"
        });
        matchesInfo[5] = MatchData({
            initialized: true,
            team1CountryCode: 4,
            team2CountryCode: 32,
            matchId: 5,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Janoub Stadium"
        });
        matchesInfo[6] = MatchData({
            initialized: true,
            team1CountryCode: 11,
            team2CountryCode: 24,
            matchId: 6,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Education City Stadium"
        });
        matchesInfo[7] = MatchData({
            initialized: true,
            team1CountryCode: 9,
            team2CountryCode: 22,
            matchId: 7,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Stadium 974"
        });
        matchesInfo[8] = MatchData({
            initialized: true,
            team1CountryCode: 5,
            team2CountryCode: 28,
            matchId: 8,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Lusail Stadium"
        });
        matchesInfo[9] = MatchData({
            initialized: true,
            team1CountryCode: 3,
            team2CountryCode: 26,
            matchId: 9,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Ahmad Bin Ali Stadium"
        });
        matchesInfo[10] = MatchData({
            initialized: true,
            team1CountryCode: 7,
            team2CountryCode: 31,
            matchId: 10,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Thumama Stadium"
        });
        matchesInfo[11] = MatchData({
            initialized: true,
            team1CountryCode: 12,
            team2CountryCode: 19,
            matchId: 11,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Khalifa International Stadium"
        });
        matchesInfo[12] = MatchData({
            initialized: true,
            team1CountryCode: 20,
            team2CountryCode: 16,
            matchId: 12,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Bayt Stadium"
        });
        matchesInfo[13] = MatchData({
            initialized: true,
            team1CountryCode: 14,
            team2CountryCode: 25,
            matchId: 13,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Janoub Stadium"
        });
        matchesInfo[14] = MatchData({
            initialized: true,
            team1CountryCode: 13,
            team2CountryCode: 23,
            matchId: 14,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Education City Stadium"
        });
        matchesInfo[15] = MatchData({
            initialized: true,
            team1CountryCode: 8,
            team2CountryCode: 29,
            matchId: 15,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Stadium 974"
        });
        matchesInfo[16] = MatchData({
            initialized: true,
            team1CountryCode: 2,
            team2CountryCode: 21,
            matchId: 16,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Lusail Stadium"
        });
        matchesInfo[17] = MatchData({
            initialized: true,
            team1CountryCode: 18,
            team2CountryCode: 30,
            matchId: 17,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Ahmad Bin Ali Stadium"
        });
        matchesInfo[18] = MatchData({
            initialized: true,
            team1CountryCode: 1,
            team2CountryCode: 17,
            matchId: 18,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Thumama Stadium"
        });
        matchesInfo[19] = MatchData({
            initialized: true,
            team1CountryCode: 10,
            team2CountryCode: 27,
            matchId: 19,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Khalifa International Stadium"
        });
        matchesInfo[20] = MatchData({
            initialized: true,
            team1CountryCode: 6,
            team2CountryCode: 15,
            matchId: 20,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Bayt Stadium"
        });
        matchesInfo[21] = MatchData({
            initialized: true,
            team1CountryCode: 24,
            team2CountryCode: 32,
            matchId: 21,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Janoub Stadium"
        });
        matchesInfo[22] = MatchData({
            initialized: true,
            team1CountryCode: 22,
            team2CountryCode: 28,
            matchId: 22,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Education City Stadium"
        });
        matchesInfo[23] = MatchData({
            initialized: true,
            team1CountryCode: 4,
            team2CountryCode: 11,
            matchId: 23,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Stadium 974"
        });
        matchesInfo[24] = MatchData({
            initialized: true,
            team1CountryCode: 5,
            team2CountryCode: 9,
            matchId: 24,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Lusail Stadium"
        });
        matchesInfo[25] = MatchData({
            initialized: true,
            team1CountryCode: 19,
            team2CountryCode: 31,
            matchId: 25,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Ahmad Bin Ali Stadium"
        });
        matchesInfo[26] = MatchData({
            initialized: true,
            team1CountryCode: 3,
            team2CountryCode: 20,
            matchId: 26,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Thumama Stadium"
        });
        matchesInfo[27] = MatchData({
            initialized: true,
            team1CountryCode: 16,
            team2CountryCode: 26,
            matchId: 27,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Khalifa International Stadium"
        });
        matchesInfo[28] = MatchData({
            initialized: true,
            team1CountryCode: 7,
            team2CountryCode: 12,
            matchId: 28,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Bayt Stadium"
        });
        matchesInfo[29] = MatchData({
            initialized: true,
            team1CountryCode: 21,
            team2CountryCode: 25,
            matchId: 29,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Janoub Stadium"
        });
        matchesInfo[30] = MatchData({
            initialized: true,
            team1CountryCode: 23,
            team2CountryCode: 29,
            matchId: 30,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Education City Stadium"
        });
        matchesInfo[31] = MatchData({
            initialized: true,
            team1CountryCode: 2,
            team2CountryCode: 14,
            matchId: 31,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Stadium 974"
        });
        matchesInfo[32] = MatchData({
            initialized: true,
            team1CountryCode: 8,
            team2CountryCode: 13,
            matchId: 32,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Lusail Stadium"
        });
        matchesInfo[33] = MatchData({
            initialized: true,
            team1CountryCode: 6,
            team2CountryCode: 30,
            matchId: 33,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Ahmad Bin Ali Stadium"
        });
        matchesInfo[34] = MatchData({
            initialized: true,
            team1CountryCode: 18,
            team2CountryCode: 15,
            matchId: 34,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Thumama Stadium"
        });
        matchesInfo[35] = MatchData({
            initialized: true,
            team1CountryCode: 27,
            team2CountryCode: 17,
            matchId: 35,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Khalifa International Stadium"
        });
        matchesInfo[36] = MatchData({
            initialized: true,
            team1CountryCode: 10,
            team2CountryCode: 1,
            matchId: 36,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Bayt Stadium"
        });
        matchesInfo[37] = MatchData({
            initialized: true,
            team1CountryCode: 11,
            team2CountryCode: 32,
            matchId: 37,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Janoub Stadium"
        });
        matchesInfo[38] = MatchData({
            initialized: true,
            team1CountryCode: 24,
            team2CountryCode: 4,
            matchId: 38,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Education City Stadium"
        });
        matchesInfo[39] = MatchData({
            initialized: true,
            team1CountryCode: 22,
            team2CountryCode: 5,
            matchId: 39,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Stadium 974"
        });
        matchesInfo[40] = MatchData({
            initialized: true,
            team1CountryCode: 28,
            team2CountryCode: 9,
            matchId: 40,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Lusail Stadium"
        });
        matchesInfo[41] = MatchData({
            initialized: true,
            team1CountryCode: 16,
            team2CountryCode: 3,
            matchId: 41,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Ahmad Bin Ali Stadium"
        });
        matchesInfo[42] = MatchData({
            initialized: true,
            team1CountryCode: 26,
            team2CountryCode: 20,
            matchId: 42,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Thumama Stadium"
        });
        matchesInfo[43] = MatchData({
            initialized: true,
            team1CountryCode: 19,
            team2CountryCode: 7,
            matchId: 43,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Khalifa International Stadium"
        });
        matchesInfo[44] = MatchData({
            initialized: true,
            team1CountryCode: 31,
            team2CountryCode: 12,
            matchId: 44,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Bayt Stadium"
        });
        matchesInfo[45] = MatchData({
            initialized: true,
            team1CountryCode: 29,
            team2CountryCode: 13,
            matchId: 45,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Al Janoub Stadium"
        });
        matchesInfo[46] = MatchData({
            initialized: true,
            team1CountryCode: 23,
            team2CountryCode: 8,
            matchId: 46,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Education City Stadium"
        });
        matchesInfo[47] = MatchData({
            initialized: true,
            team1CountryCode: 21,
            team2CountryCode: 14,
            matchId: 47,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Stadium 974"
        });
        matchesInfo[48] = MatchData({
            initialized: true,
            team1CountryCode: 2,
            team2CountryCode: 25,
            matchId: 48,
            startTime: 1661255688,
            tokenAmount: 500,
            location: "Lusail Stadium"
        });

        for (uint256 i = 1; i < 33; i++) {
            setMatchDataByCountryCode(i);
        }
    }

    function getAirdropAmount(uint256 _roundId) public view returns (uint256) {
        return (tokenAmount[_roundId]);
    }

    function setAirdropAmount(uint256 _roundId, uint256 _amount) public {
        tokenAmount[_roundId] = _amount;
    }

    function getVestingDays() public view returns (uint256) {
        return totalVestingDays;
    }

    function setVestingDays(uint256 _totalVestingDays) public {
        totalVestingDays = _totalVestingDays;
    }

    function setMatchData(
        uint256 _team1CountryCode,
        uint256 _team2CountryCode,
        uint8 _matchId,
        uint256 _startTime,
        uint256 _roundId,
        string memory _location
    ) public {
        require(!matchesInfo[_matchId].initialized, "Match is already there");
        matchesInfo[_matchId] = MatchData({
            initialized: true,
            team1CountryCode: _team1CountryCode,
            team2CountryCode: _team2CountryCode,
            matchId: _matchId,
            startTime: _startTime,
            tokenAmount: getAirdropAmount(_roundId),
            location: _location
        });
        TotalMatches = (_matchId > 48) ? _matchId : 48;
        setMatchDataByCountryCode(_team1CountryCode);
        setMatchDataByCountryCode(_team2CountryCode);
    }

    function updateMatchData(
        uint256 _team1CountryCode,
        uint256 _team2CountryCode,
        uint8 _matchId,
        uint256 _startTime,
        uint256 _roundId,
        string memory _location
    ) public {
        require(matchesInfo[_matchId].initialized, "Match is not there");
        matchesInfo[_matchId] = MatchData({
            initialized: true,
            team1CountryCode: _team1CountryCode,
            team2CountryCode: _team2CountryCode,
            matchId: _matchId,
            startTime: _startTime,
            tokenAmount: getAirdropAmount(_roundId),
            location: _location
        });
    }

    function setMatchDataByCountryCode(uint256 _CountryCode) internal {
        for (uint8 i = 1; i < TotalMatches + 1; i++) {
            if (
                (matchesInfo[i].team1CountryCode == _CountryCode) ||
                (matchesInfo[i].team2CountryCode == _CountryCode)
            ) {
                matchId[_CountryCode].push(i);
            }
        }
    }

    function getMatchesOfCountry(uint256 _CountryCode)
        public
        view
        returns (uint256[] memory)
    {
        return matchId[_CountryCode];
    }

    function setCountryCode(string memory _country, uint8 _countryCode) public {
        countryNames[_countryCode] = _country;
    }

    function setCode() public {
        string[32] memory arr = [
            "Qatar",
            "Brazil",
            "Belgium",
            "France",
            "Argentina",
            "England",
            "Spain",
            "Portugal",
            "Mexico",
            "Netherlands",
            "Denmark",
            "Germany",
            "Uruguay",
            "Switzerland",
            "USA",
            "Croatia",
            "Senegal",
            "Iran",
            "Japan",
            "Morocco",
            "Serbia",
            "Poland",
            "South Korea",
            "Tunisia",
            "Cameroon",
            "Canada",
            "Ecuador",
            "saudi Arabia",
            "Ghana",
            "Wales",
            "Costa Rica",
            "Australia"
        ];
        for (uint8 i = 0; i < arr.length; i++) {
            countryNames[i + 1] = arr[i];
        }
    }
}