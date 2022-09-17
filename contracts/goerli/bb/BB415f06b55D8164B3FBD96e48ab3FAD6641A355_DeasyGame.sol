// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/access/Ownable.sol";

// contract for the p2e game for non techs
contract DeasyGame {

    // event to emit that a new user has registered during the plattform
    event RegisteredUser (uint32 indexed userId, address indexed userAddress);
    // event that a game step is rewarded with an internal pic
    event RewardedGame (uint indexed userId, uint indexed gameId, bytes32 cid);
    // event that a new game was registered after completion
    event RegisteredGame (uint indexed _userId, uint indexed _gameId);
    // event to give feedback about added points
    event SavedPoints(uint indexed _userId, uint indexed _gameId, uint indexed points);

    // counter for new users
    uint32 public idCounter; 

    // struct for registration of new Users including userId and userAddress
    struct User{
        uint32 userId;
        address userAddress;
    }

    // struct for gane registrartion including values for gameId, points for a 
    // specific game id and a cid to a picture if rewarded
    struct Game{
        uint gameId;
        uint points;
        bool  rewarded;
        bytes32 cid;
    }

    // array of all users
    User[] public users;
    // array of all games 
    //Game[] public games;

    // mapping of all games from a specific user to its user id
    mapping (uint32 => mapping(uint32 => Game)) public userIdToGameId;
    // mapping of user address to its userid
    mapping ( address => uint) public userAddressToUserid;

    // registration of a new user after its login
    function registerUser(address _userAddress) external {
        // check that an user can only register once
        require(userAddressToUserid[_userAddress] == 0 , "Wallet not unique");
        idCounter++;
        // add the user to the users array
        users.push(User({
            userId: idCounter,
            userAddress: _userAddress
        }));
        // set the useride in mapping to concerning address
        userAddressToUserid[_userAddress] = idCounter;
        // emit event to the frontend that is succesful registered
        emit RegisteredUser (idCounter, _userAddress);
    }
        
    
    // registration of a game after startet 
    function registerGame(uint32 _userId, uint32 _gameId) external {
        userIdToGameId[_userId][_gameId].gameId = _gameId;
        userIdToGameId[_userId][_gameId].points = 0;
        userIdToGameId[_userId][_gameId].rewarded = false;

        emit RegisteredGame(_userId, _gameId);
    }

    // function to save the current points a user has reached in a game
    function savePoints(uint32 _userId, uint32 _gameId , uint32 _point ) external {
        // we have to think about this step
        userIdToGameId[_userId][_gameId].points += _point;
        emit SavedPoints(_userId, _gameId, userIdToGameId[_userId][_gameId].points);
    }

    // reward of a game when succesfully played
    function rewardGame(uint32 _userId, uint32 _gameId, bytes32 _cid) external  {
        // check if rewards has already been paid
        require(userIdToGameId[_userId][_gameId].rewarded == false );
        // cid of the reward in the maaping for a specific user
        userIdToGameId[_userId][_gameId].cid = _cid;
        // check that user got its reward 
        userIdToGameId[_userId][_gameId].rewarded = true;
        // emeit the event that the game has beeen rewarded
        emit RewardedGame(_userId, _gameId, _cid);
    }

}