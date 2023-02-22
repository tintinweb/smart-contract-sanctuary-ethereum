/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

//NEED TO ADD SPDX LICENSCE

pragma solidity >=0.8.0 <0.9.0;

/*
Still needed:
    1. Additional functionality for tiered payouts, currently winner take all ie. add multiple winners
    2. Chainlink keeper should be calling close pool function, it should be the only one able and depends on Leo's implementation
    3. Not immediete concern. But implement close pool function to work for different rounds
*/

/**
 * @title Pool
 * @dev James Pusey
 */
contract SCTestMatrix {
    event UserBet(string[][] bracketPrediction, uint256 score);
    event emitUint256(uint256);
    event emitWinner(uint winner);

    mapping(uint => UserBracketEntry) public addressToBracketMap; //adresses used as a key to associated bracket data
    mapping(uint256 => uint) public uintToAddressMap;// eventually plan on removing this  but works for implemenation as of right now
    uint256 public numberOfPlayers;
    string[][] public actualWinners;//testing var

    event UpdatedMessages(string[][] userBet, string[][] actualBet); //testing event to be used later
    uint public winner; //testing var

    struct UserBracketEntry {
        string[][] bracketPrediction;
        uint256 score; //in future could remove this aswell
    }

    function enterPool(
        string[][] memory _bracketPrediction,
        uint addy
    ) public payable returns (uint) {
        /*
        require(
            _bracketPrediction.length <= 6,
            "roundOneWinners length incorrect"
        );
        require(
            _bracketPrediction.length >= 3,
            "roundOneWinners length incorrect"
        );
    */
        if(isMappingObjectExists(addy)){
            //addressToBracketMap[msg.sender].bracketPredition = _bracketPrediction;
            
            addressToBracketMap[addy] = UserBracketEntry(
                _bracketPrediction,
                0 //could remove later
            );
            
        }else{
            addressToBracketMap[addy] = UserBracketEntry(
                _bracketPrediction,
                0 //could remove later
        );
        }
        uintToAddressMap[numberOfPlayers] = addy;
        numberOfPlayers++;
        uint sender = addy;
        return sender;
    }

    //to do: implement winners with same score ie. determine if array or mapping functions is better implementation in solidity
    function closePool(
        string[][] memory _bracketWinners
    ) public payable {
        uint winnerAddress;
        uint256 winnerScore = 0;
        //uint256 roundNumber = getRound(bracketPrediction);
        // todo: add in require for only oracle can call this function, and readjust total(Round)


        for (uint256 i = 0; i < numberOfPlayers; i++) {
            uint256 _currentScoreForPlayer = 0;
            UserBracketEntry memory _playersBracketStruct = addressToBracketMap[
                uintToAddressMap[i]
            ];
            _currentScoreForPlayer = totalRound(
                _playersBracketStruct.bracketPrediction,
                _bracketWinners,
                _playersBracketStruct.score
            );

            if (_currentScoreForPlayer > winnerScore) {
                winnerScore = _currentScoreForPlayer;
                winnerAddress = uintToAddressMap[i];
            }
            //addressToBracketMap[uintToAddressMap[i]].score = _currentScoreForPlayer;
        }
        /*
        bool sent = payWinner(winnerAddress);
        require(sent, "Failed to send Ether");
        */
        winner = winnerAddress;
    }

    //No native function to compare strings in Solidity so created one
    //NEEDS TESTING
    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function totalRound(
        string[][] memory _bracketPrediction,
        string[][] memory _roundWinners,
        uint256 _currentScoreForPlayer
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < _bracketPrediction.length; i++) {
            for (uint256 j = 0; j < _roundWinners[j].length; j++) {
                if (compareStrings(_bracketPrediction[i][j], _roundWinners[i][j])) {
                    _currentScoreForPlayer += 1;//entryfee;
                }
            }
        }
        return _currentScoreForPlayer;
    }

    //Determines if value exits in mapping function (need to connect it to predicgtion not score)
    function isMappingObjectExists(
        uint key
    )public view returns (bool) {
        if(addressToBracketMap[key].score != 0 ){
            return true;
        } 
        else{
            return false;
        }
    }

    // Getter functions
    function getPlayersEntry(uint _addr)
        public
        view
        returns (UserBracketEntry memory)
    {
        return addressToBracketMap[_addr];
    }

    //Determines Round based off of length of bracket array (ie, for round 1 there should be 6 arrays contained within for 32 games, 16 games... final game)
    function getRound(string[] memory _bracketPrediction
    )internal pure returns(uint256){
        uint8[4] memory roundLengths = [6,5,4,3];
        for (uint256 i = 1; i <= _bracketPrediction.length +1; i++) {
            if (_bracketPrediction.length == roundLengths[i]){
                return i;
            }
        }
        revert('Improper Bracket Stucture');//Should create a function that throws errors in future
    }

    function update(string[][] memory newwinner) public {
      string[][] memory oldwinner = actualWinners;
       actualWinners= newwinner;
      emit UpdatedMessages(oldwinner, newwinner);
    }

    //Below functions are used for testing.

    function get_actualWinners() public view returns (string[][] memory) {
        return actualWinners;
    }

    function get_addressToBracketMap(uint _key) public view returns (string[][] memory, uint256) {
        UserBracketEntry memory playersBracketStruct = addressToBracketMap[_key];
        return (playersBracketStruct.bracketPrediction, playersBracketStruct.score);

    }
    function get_uintToAddressMap(uint256 _key) external view returns (uint) {
        return uintToAddressMap[_key];
    }
    function getUser(
        uint256 key
    ) public payable {
        emit UserBet(addressToBracketMap[uintToAddressMap[key]].bracketPrediction, addressToBracketMap[uintToAddressMap[key]].score); 
    }

    function getWinner(
    ) public payable {
        emit emitWinner(winner); 
    }
}