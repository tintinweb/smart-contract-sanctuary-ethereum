/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >= 0.7.0 < 0.9.0;

contract Basics {

    //--[1]-General Variables--
    uint public myBalance =1000;
    int private txAmount = -2;
    string internal coinName = "Poop Coin";
    bool isValid = true;

    //--[2]-Globasl variables--
    uint public blockTime = block.timestamp;
    address public sender = msg.sender;

    //--[3]-Arrays--
    string[] public tokenNames = ["Chainlink", "Ethereum", "Dodge"];
    
    //--[4] Date and Time--
    uint timeNow15Sec = 1 seconds;
    uint timeNow1Min = 1 minutes;
    uint timeNow1Hour = 1 hours;
    uint public timeNow1Day = 2 days;
    uint timeNow1Week = 1 weeks;

    //--[5] Struct--
    struct User {
        string name;
        address userAddress;
        bool hasTraded;
    }
    User[] public users;

    //--[6] Mapping--
    mapping(string => string) public accountNameMap;

    mapping(address => mapping(string => User)) private userNestedMap;

    //--[7] Enums--
    enum coinRanking {STRONG, CAUTION, DODGY}
    coinRanking trustLevel;
    coinRanking public defaultTrustLevel = coinRanking.CAUTION;

    //--[8] Functions--
    struct Coin {
        string name;
        string symbole;
        uint supply;
    }    
    mapping (address => Coin) internal myCoins;

    //-Guessing game-
    function guessNumber(uint _guess) public pure returns (bool){ 
        if (_guess == 5){
            return true;
        }else {
            return false;
        }
    }

    //-Get coin name-
    function getMyCoinName() public view returns(string memory){
        return coinName;
    }

    //-Multiply Balance-
    function multiplyBalance(uint _multiplier) external {
        myBalance = myBalance * _multiplier;
    }

    //--[9] Loop--
    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint){
        for (uint i=_startFrom; i < _myCoins.length; i++){
            string memory coin = _myCoins[i];

            if (keccak256(abi.encodePacked(coin)) == keccak256(abi.encodePacked(_find))){
                return i;
            }
        }
        return 999;
    }

    //Mint Token
    function mintToken(string memory _name, string memory _symbol, uint _supply) external{
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    //Multiply Balance
    function getToken() public view returns (Coin memory){
        return myCoins[msg.sender];
    }
}

    //--[10] Inheritance--
    contract I360EpicToken{
        
        uint availableSupply;
        uint maxSupply;

        constructor(uint _startingSupply, uint _maxSupply){
            availableSupply = _startingSupply;
            maxSupply = _maxSupply;
        }
    }

    contract SqueedEpicToken is I360EpicToken {
        constructor(uint ss, uint ms) I360EpicToken (ss, ms){}

        function getAvailableSupply() public view returns (uint){
           return availableSupply;
        }

        function getMaxSupply() public view returns (uint){
           return maxSupply;
        }
    }