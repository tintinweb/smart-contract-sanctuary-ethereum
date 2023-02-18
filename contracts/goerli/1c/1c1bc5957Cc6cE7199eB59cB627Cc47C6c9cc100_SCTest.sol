/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

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
contract SCTest {
    mapping(uint256 => UserBracketEntry) public addressToBracketMap; //adresses used as a key to associated bracket data
    mapping(uint256 => uint256) public uintToAddressMap;// eventually plan on removing this  but works for implemenation as of right now
    uint256 public numberOfPlayers;

    string public actualWinners;//testing var
    uint public winner; //testing var

    struct UserBracketEntry {
        string bracketPrediction;
        uint256 score; //in future could remove this aswell
    }

    function enterPool(
        string memory _bracketPrediction,
        uint256 addy
    ) public payable returns (uint256) {
        /*
        require(
            addressToBracketMap[addy]== 0;
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
    /*
    function closePool(
        string memory _bracketWinners
    ) public payable returns (uint256){
        uint256 winnerAddress;
        uint256 winnerScore = 0;
        //uint256 roundNumber = getRound(bracketPrediction);
        // todo: add in require for only oracle can call this function, and readjust total(Round)

        for (uint256 i = 0; i < numberOfPlayers; i++) {
            uint256 currentScoreForPlayer = 0;

            UserBracketEntry memory playersBracketStruct = addressToBracketMap[
                uintToAddressMap[i]
            ];
            currentScoreForPlayer = totalRound(
                playersBracketStruct.bracketPrediction,
                _bracketWinners,
                playersBracketStruct.score
            );

            if (currentScoreForPlayer > winnerScore) {
                winnerScore = currentScoreForPlayer;
                winnerAddress = uintToAddressMap[i];
            }
            addressToBracketMap[uintToAddressMap[i]].score = currentScoreForPlayer;
        }
        
        bool sent = payWinner(winnerAddress);
        require(sent, "Failed to send Ether");
        
        winner = winnerAddress;
        return winnerAddress;
    }
*/

/*
    function closePool(
        string memory _bracketWinners
    ) public payable returns (uint256){
        uint256 winnerAddress;
        uint256 winnerScore = 0;
        //uint256 roundNumber = getRound(bracketPrediction);
        // todo: add in require for only oracle can call this function, and readjust total(Round)

        for (uint256 i = 0; i < numberOfPlayers; i++) {
            uint256 currentScoreForPlayer = 0;

            UserBracketEntry memory playersBracketStruct = addressToBracketMap[
                uintToAddressMap[i]
            ];
            currentScoreForPlayer = totalRound(
                playersBracketStruct.bracketPrediction,
                _bracketWinners//,
                //playersBracketStruct.score
            );

            if (currentScoreForPlayer > winnerScore) {
                winnerScore = currentScoreForPlayer;
                winnerAddress = uintToAddressMap[i];
            }
            addressToBracketMap[uintToAddressMap[i]].score = currentScoreForPlayer;
        }
        
        winner = winnerAddress;
        return winnerAddress;
    }
*/
    //No native function to compare strings in Solidity so created one
    //NEEDS TESTING
    function compareStrings(string memory a, string memory b)
        //internal
        //pure
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function totalRound(
        string memory _bracketPrediction,
        string memory _roundWinners//,
        //uint256 currentScoreForPlayer
    ) public payable returns (uint256) {
        uint256 currentScoreForPlayer = 0;
        if (compareStrings(_bracketPrediction, _roundWinners)) {
            currentScoreForPlayer =currentScoreForPlayer + 1 ;//entryfee;
        }
        return currentScoreForPlayer;
        
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
/*
    //Determines Round based off of length of bracket array (ie, for round 1 there should be 6 arrays contained within for 32 games, 16 games... final game)
    function getRound(string memory _bracketPrediction
    )internal pure returns(uint256){
        uint8[4] memory roundLengths = [6,5,4,3];
        for (uint256 i = 1; i <= _bracketPrediction.length +1; i++) {
            if (_bracketPrediction.length == roundLengths[i]){
                return i;
            }
        }
        revert('Improper Bracket Stucture');//Should create a function that throws errors in future
    }
*/
    //Below functions are used for testing.

    function get_actualWinners() public view returns (string memory) {
        return actualWinners;
    }

    function get_addressToBracketMap(uint _key) public view returns (string memory, uint256) {
        UserBracketEntry memory playersBracketStruct = addressToBracketMap[_key];
        return (playersBracketStruct.bracketPrediction, playersBracketStruct.score);

    }
    function get_uintToAddressMap(uint256 _key) external view returns (uint) {
        return uintToAddressMap[_key];
    }
/*
    function getLength() public view returns (uint256)
    {
        return actualWinners.length;
    }
*/
/*
    function getLengthRound(uint256 index) public view returns(uint){
        return actualWinners[index].length;
    }
*/
}