//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MatchContract is Ownable {

    struct MatchData {
        bool initialized;
        uint8 team1CountryCode;
        uint8 team2CountryCode;
        uint8 matchId;
        uint256 startTime;
        uint256 tokenAmount;
        
    }

    struct AllMatchData {
        string team1Country;
        string team2Country;
        uint8 team1CountryCode;
        uint8 team2CountryCode;
        uint8 matchId;
        uint8 roundId;
        uint256 startTime;
        
    }

    AllMatchData[] getAllMatch;

    address public admin;
    uint256 totalVestingDays;
    uint8 public matchLength;
    mapping(uint8 => uint256) tokenAmount;
    mapping(uint8 => MatchData) public matchesInfo;
    mapping(uint8 => string) public countryNames;
    mapping(uint256 => uint256[]) private matchId;


    modifier onlyOwnerAndAdmin() {
        require(owner() == _msgSender() || _msgSender() == admin, "Ownable: caller is not the owner or admin");
        _;
    }

    constructor() {
        setCode();
        totalVestingDays = 50;
        setAdmin(_msgSender());
        
        tokenAmount[1] = 2000;
        tokenAmount[2] = 4000;
        tokenAmount[3] = 8000;
        tokenAmount[4] = 15000;
        tokenAmount[5] = 30000; 

        matchesInfo[1] = MatchData({
            initialized: true,
            team1CountryCode: 1,
            team2CountryCode: 27,
            matchId: 1,
            startTime: 1668960000,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[2] = MatchData({
            initialized: true,
            team1CountryCode: 6,
            team2CountryCode: 18,
            matchId: 2,
            startTime: 1669035600,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[3] = MatchData({
            initialized: true,
            team1CountryCode: 17,
            team2CountryCode: 10,
            matchId: 3,
            startTime: 1669046400,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[4] = MatchData({
            initialized: true,
            team1CountryCode: 15,
            team2CountryCode: 30,
            matchId: 4,
            startTime: 1669057200,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[5] = MatchData({
            initialized: true,
            team1CountryCode: 5,
            team2CountryCode: 28,
            matchId: 5,
            startTime: 1669111200,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[6] = MatchData({
            initialized: true,
            team1CountryCode: 11,
            team2CountryCode: 24,
            matchId: 6,
            startTime: 1669122000,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[7] = MatchData({
            initialized: true,
            team1CountryCode: 9,
            team2CountryCode: 22,
            matchId: 7,
            startTime: 1669132800,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[8] = MatchData({
            initialized: true,
            team1CountryCode: 4,
            team2CountryCode: 32,
            matchId: 8,
            startTime: 1669143600,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[9] = MatchData({
            initialized: true,
            team1CountryCode: 20,
            team2CountryCode: 16,
            matchId: 9,
            startTime: 1669197600,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[10] = MatchData({
            initialized: true,
            team1CountryCode: 12,
            team2CountryCode: 19,
            matchId: 10,
            startTime: 1669208400,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[11] = MatchData({
            initialized: true,
            team1CountryCode: 7,
            team2CountryCode: 31,
            matchId: 11,
            startTime: 1669219200,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[12] = MatchData({
            initialized: true,
            team1CountryCode: 3,
            team2CountryCode: 26,
            matchId: 12,
            startTime: 1669230000,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[13] = MatchData({
            initialized: true,
            team1CountryCode: 14,
            team2CountryCode: 25,
            matchId: 13,
            startTime: 1669284000,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[14] = MatchData({
            initialized: true,
            team1CountryCode: 13,
            team2CountryCode: 23,
            matchId: 14,
            startTime:  1669294800,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[15] = MatchData({
            initialized: true,
            team1CountryCode: 8,
            team2CountryCode: 29,
            matchId: 15,
            startTime: 1669305600,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[16] = MatchData({
            initialized: true,
            team1CountryCode: 2,
            team2CountryCode: 21,
            matchId: 16,
            startTime: 1669316400,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[17] = MatchData({
            initialized: true,
            team1CountryCode: 18,
            team2CountryCode: 30,
            matchId: 17,
            startTime: 1669370400,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[18] = MatchData({
            initialized: true,
            team1CountryCode: 1,
            team2CountryCode: 17,
            matchId: 18,
            startTime: 1669381200,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[19] = MatchData({
            initialized: true,
            team1CountryCode: 10,
            team2CountryCode: 27,
            matchId: 19,
            startTime: 1669392000,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[20] = MatchData({
            initialized: true,
            team1CountryCode: 6,
            team2CountryCode: 15,
            matchId: 20,
            startTime: 1669402800,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[21] = MatchData({
            initialized: true,
            team1CountryCode: 24,
            team2CountryCode: 32,
            matchId: 21,
            startTime: 1669456800,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[22] = MatchData({
            initialized: true,
            team1CountryCode: 22,
            team2CountryCode: 28,
            matchId: 22,
            startTime: 1669467600,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[23] = MatchData({
            initialized: true,
            team1CountryCode: 4,
            team2CountryCode: 11,
            matchId: 23,
            startTime: 1669478400,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[24] = MatchData({
            initialized: true,
            team1CountryCode: 5,
            team2CountryCode: 9,
            matchId: 24,
            startTime: 1669489200,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[25] = MatchData({
            initialized: true,
            team1CountryCode: 19,
            team2CountryCode: 31,
            matchId: 25,
            startTime: 1669543200,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[26] = MatchData({
            initialized: true,
            team1CountryCode: 3,
            team2CountryCode: 20,
            matchId: 26,
            startTime: 1669554000,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[27] = MatchData({
            initialized: true,
            team1CountryCode: 16,
            team2CountryCode: 26,
            matchId: 27,
            startTime: 1669564800,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[28] = MatchData({
            initialized: true,
            team1CountryCode: 7,
            team2CountryCode: 12,
            matchId: 28,
            startTime: 1669575600,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[29] = MatchData({
            initialized: true,
            team1CountryCode: 21,
            team2CountryCode: 25,
            matchId: 29,
            startTime: 1669629600,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[30] = MatchData({
            initialized: true,
            team1CountryCode: 23,
            team2CountryCode: 29,
            matchId: 30,
            startTime: 1669640400,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[31] = MatchData({
            initialized: true,
            team1CountryCode: 2,
            team2CountryCode: 14,
            matchId: 31,
            startTime: 1669651200,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[32] = MatchData({
            initialized: true,
            team1CountryCode: 8,
            team2CountryCode: 13,
            matchId: 32,
            startTime: 1669662000,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[33] = MatchData({
            initialized: true,
            team1CountryCode: 27,
            team2CountryCode: 17,
            matchId: 33,
            startTime: 1669734000,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[34] = MatchData({
            initialized: true,
            team1CountryCode: 10,
            team2CountryCode: 1,
            matchId: 34,
            startTime: 1669734000,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[35] = MatchData({
            initialized: true,
            team1CountryCode: 18,
            team2CountryCode: 15,
            matchId: 35,
            startTime: 1669748400,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[36] = MatchData({
            initialized: true,
            team1CountryCode: 6,
            team2CountryCode: 30,
            matchId: 36,
            startTime: 1669748400,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[37] = MatchData({
            initialized: true,
            team1CountryCode: 11,
            team2CountryCode: 32,
            matchId: 37,
            startTime: 1669820400,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[38] = MatchData({
            initialized: true,
            team1CountryCode: 24,
            team2CountryCode: 4,
            matchId: 38,
            startTime: 1669820400,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[39] = MatchData({
            initialized: true,
            team1CountryCode: 22,
            team2CountryCode: 5,
            matchId: 39,
            startTime: 1669834800,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[40] = MatchData({
            initialized: true,
            team1CountryCode: 28,
            team2CountryCode: 9,
            matchId: 40,
            startTime: 1669834800,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[41] = MatchData({
            initialized: true,
            team1CountryCode: 16,
            team2CountryCode: 3,
            matchId: 41,
            startTime: 1669906800,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[42] = MatchData({
            initialized: true,
            team1CountryCode: 26,
            team2CountryCode: 20,
            matchId: 42,
            startTime: 1669906800,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[43] = MatchData({
            initialized: true,
            team1CountryCode: 19,
            team2CountryCode: 7,
            matchId: 43,
            startTime: 1669921200,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[44] = MatchData({
            initialized: true,
            team1CountryCode: 31,
            team2CountryCode: 12,
            matchId: 44,
            startTime: 1669921200,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[45] = MatchData({
            initialized: true,
            team1CountryCode: 29,
            team2CountryCode: 13,
            matchId: 45,
            startTime: 1669993200,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[46] = MatchData({
            initialized: true,
            team1CountryCode: 23,
            team2CountryCode: 8,
            matchId: 46,
            startTime: 1669993200,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[47] = MatchData({
            initialized: true,
            team1CountryCode: 21,
            team2CountryCode: 14,
            matchId: 47,
            startTime: 1670007600,
            tokenAmount: tokenAmount[1]
        });
        matchesInfo[48] = MatchData({
            initialized: true,
            team1CountryCode: 2,
            team2CountryCode: 25,
            matchId: 48,
            startTime: 1670007600,
            tokenAmount: tokenAmount[1]
        });

        for (uint8 i = 1; i < 33; i=unchecked_inc(i)) {
            setMatchDataByCountryCode(i);
        }
        matchLength = 48;
        setAllMatchData();
    }

    function unchecked_inc(uint8 i) private pure returns(uint8) {
        unchecked{ return i+1;}
    } 


    function setAdmin(address _adminAddress) public onlyOwnerAndAdmin {
        admin = _adminAddress;
    }

    function getAirdropAmount(uint8 _roundId) public view returns (uint256) {
        return (tokenAmount[_roundId]);
    }

    function getMatchesInfo(uint8 _matchId) public view returns(MatchData memory){
        return matchesInfo[_matchId];
    }

    function getVestingDays() public view returns (uint256) {
        return totalVestingDays;
    }

    function getMatchesOfCountry(uint256 _CountryCode)
        public
        view
        returns (uint256[] memory)
    {
        require(_CountryCode < 33, "Invalid Country code");
        return matchId[_CountryCode];
    }

    function setAirdropAmount(uint8 _roundId, uint256 _amount)
        public
        onlyOwnerAndAdmin
    {
        tokenAmount[_roundId] = _amount;
    }

    function setVestingDays(uint256 _totalVestingDays) public onlyOwnerAndAdmin {
        totalVestingDays = _totalVestingDays;
    }

    function setMatchData(
        uint8 _team1CountryCode,
        uint8 _team2CountryCode,
        uint8 _matchId,
        uint256 _startTime,
        uint8 _roundId
    ) public onlyOwnerAndAdmin {
        require(!matchesInfo[_matchId].initialized, "Match is already there");
        matchesInfo[_matchId] = MatchData({
            initialized: true,
            team1CountryCode: _team1CountryCode,
            team2CountryCode: _team2CountryCode,
            matchId: _matchId,
            startTime: _startTime,
            tokenAmount: getAirdropAmount(_roundId)           
        });

        matchLength++; 

        matchId[_team1CountryCode].push(_matchId);
        matchId[_team2CountryCode].push(_matchId);


        getAllMatch.push(
            AllMatchData({
                team1Country : countryNames[_team1CountryCode],
                team2Country : countryNames[_team2CountryCode],
                team1CountryCode: _team1CountryCode,
                team2CountryCode:_team2CountryCode,
                matchId:_matchId,
                roundId:_roundId,
                startTime:_startTime
                })
            );
    }

    function setMatchDataBulk(
        uint8[] memory _team1CountryCode,
        uint8[] memory _team2CountryCode,
        uint8[] memory _matchId,
        uint256[] memory _startTime,
        uint8[] memory _roundId
    ) public onlyOwnerAndAdmin {

        for(uint i =0;i<_team1CountryCode.length;i++){
            
            require(!matchesInfo[_matchId[i]].initialized, "Match is already there");
            matchesInfo[_matchId[i]] = MatchData({    
                initialized: true,
                team1CountryCode: _team1CountryCode[i],
                team2CountryCode: _team2CountryCode[i],
                matchId: _matchId[i],
                startTime: _startTime[i],
                tokenAmount: getAirdropAmount(_roundId[i])
            });
            
            matchLength++; 
                
            matchId[_team1CountryCode[i]].push(_matchId[i]);
            matchId[_team2CountryCode[i]].push(_matchId[i]);
            
            getAllMatch.push(

                AllMatchData({
                
                    team1Country : countryNames[_team1CountryCode[i]],
                    team2Country : countryNames[_team2CountryCode[i]],
                    team1CountryCode: _team1CountryCode[i],
                    team2CountryCode:_team2CountryCode[i],
                    matchId:_matchId[i],
                    roundId:_roundId[i],
                    startTime:_startTime[i]
                })
            );    
        }
    }

    function setMatchDataByCountryCode(uint8 _CountryCode) internal onlyOwnerAndAdmin{
        for (uint8 i = 1; i < 49; i=unchecked_inc(i)) {
            if (
                (matchesInfo[i].team1CountryCode == _CountryCode) ||
                (matchesInfo[i].team2CountryCode == _CountryCode)
            ) {
                matchId[_CountryCode].push(i);
            }
        }
    }

    function setCountryCode(string memory _country, uint8 _countryCode)
        public
        onlyOwnerAndAdmin
    {
        countryNames[_countryCode] = _country;
    }

    function setCode() internal onlyOwnerAndAdmin {
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
        for (uint8 i = 0; i < arr.length; i=unchecked_inc(i)) {
            countryNames[i + 1] = arr[i];
        }
    }

    function updateMatchData(
        uint8 _team1CountryCode,
        uint8 _team2CountryCode,
        uint8 _matchId,
        uint256 _startTime,
        uint8 _roundId
    ) public onlyOwnerAndAdmin {
        require(matchesInfo[_matchId].initialized, "Match is not there");
        matchesInfo[_matchId] = MatchData({
            initialized: true,
            team1CountryCode: _team1CountryCode,
            team2CountryCode: _team2CountryCode,
            matchId: _matchId,
            startTime: _startTime,
            tokenAmount: getAirdropAmount(_roundId)
        });

        getAllMatch[_matchId-1] = AllMatchData({

            team1Country :  countryNames[_team1CountryCode],
            team2Country :  countryNames[_team2CountryCode],
            team1CountryCode: _team1CountryCode,
            team2CountryCode:_team2CountryCode,
            matchId:_matchId,
            roundId:_roundId,
            startTime:_startTime

        });


    }

    function setAllMatchData() internal onlyOwnerAndAdmin{

        for (uint8 i = 1; i <= matchLength; i=unchecked_inc(i)) {

            getAllMatch.push(

                AllMatchData({
                    team1Country : countryNames[matchesInfo[i].team1CountryCode],
                    team2Country : countryNames[matchesInfo[i].team2CountryCode],
                    team1CountryCode: matchesInfo[i].team1CountryCode,
                    team2CountryCode:matchesInfo[i].team2CountryCode,
                    matchId:matchesInfo[i].matchId,
                    roundId:1,
                    startTime:matchesInfo[i].startTime
                })
            );
        } 
 
    }

    function getAllMatchData() public view returns( AllMatchData[] memory) {
        return getAllMatch;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}