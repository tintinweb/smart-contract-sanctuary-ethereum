// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../library/Arrays.sol";

contract MockMechaversus {

    using Counters for Counters.Counter;
    Counters.Counter private _matchCounter;

    // @dev The number of Players in a single Match
    uint8 constant PLAYERS_COUNT = 2;

    // @dev The mocked arena_id
    uint256 constant ARENA_ID = 1234;

    // @dev Arena sizes in-game
    bytes4 public constant ARENA_SIZE = "1010";

    // @dev Number of maximum active Match for each address
    uint8 public constant MAX_ACTIVE_MATCH = 3;

    // @dev Entity type index
    uint8 public constant TYPE_NEXUS = 1;
    uint8 public constant TYPE_MECHA = 2;

    // @dev Action type index
    uint8 public constant TYPE_ATTACK = 1;
    uint8 public constant TYPE_BUFF = 2;
    uint8 public constant TYPE_NERF = 3;

    struct Action {
        uint256 _performerId;
        uint8 _actionType;
        bytes4 _coordinates;
        uint256 _targetId;
        int256 _targetEP;
    }

    struct Match {
        uint256 _id;
        uint256 _startBlock;
        uint256 _arenaId;
        address _creator;
        address[] _activePlayers;
        address[] _players;
        uint256[] _decks;
        uint256 _amount;
        uint256 _lastActionId;
        address _winner;
    }

    // @dev match_id => Match_struct{}
    mapping( uint256 => Match ) private _matches;

    // @dev match_id => action_id => Action_struct{}
    mapping( uint256 => mapping( uint256 => Action ) ) _matchActions;

    // @dev deck_id => is_used_in_match
    mapping( uint256 => bool ) private _usedDeck;

    // @dev creator_address => active_match_ids[]
    mapping( address => uint256[] ) private _activeMatch;

    event GenerateMatch(
        uint256 matchId,
        uint256 arenaId,
        address creator,
        uint256 matchAmount
    );

    event DestroyMatch(
        uint256 matchId
    );

    event JoinMatch(
        uint256 matchId,
        uint256 arenaId,
        address player,
        uint256 deckId,
        uint256 joinAmount
    );

    event LeaveMatch(
        uint256 matchId,
        address player
    );

    event UpdateMatch(
        uint256 matchId,
        address player,
        uint256 performerId,
        uint8[] actionType,
        bytes4[] coordinates,
        uint256[] targetIDs,
        int256[] targetEPs
    );

    event SurrendMatch(
        uint256 matchId,
        address surrender
    );

    event EndMatch(
        uint256 matchId,
        address winner
    );

    constructor() {
        _matchCounter.reset();
        _matchCounter.increment();
    }

    modifier callerIsPlayer( uint256 matchId ) {
        bool founded = false;
        for( uint256 i = 0; i < PLAYERS_COUNT; i++) founded = founded || _matches[ matchId ]._activePlayers[i] == msg.sender;
        require( founded, "Method callable just from Match Players" );
        _;
    }

    function getMatchCounter() public view returns (uint256) {
        return _matchCounter.current();
    }

    function getMatch( uint256 matchId ) public view returns ( Match memory ) {
        return _matches[ matchId ];
    }

    function getMatchActive( address creator ) public view returns ( uint256[] memory ) {
        return _activeMatch[ creator ];
    }

    function getMatchPlayers( uint256 matchId ) public view returns ( address[] memory ) {
        return _matches[ matchId ]._players;
    }

    function getMatchDecks( uint256 matchId ) public view returns ( uint256[] memory ) {
        return _matches[ matchId ]._decks;
    }

    function getMatchArena( uint256 matchId ) public view returns ( uint256 ) {
        return _matches[ matchId ]._arenaId;
    }

    function getMatchActions( uint256 matchId ) public view returns ( Action[] memory ) {
        Action[] memory actions = new Action[]( _matches[ matchId ]._lastActionId );
        for ( uint256 i = 0; i < _matches[ matchId ]._lastActionId; i++ ){
            actions[i] = _matchActions[ matchId ][i+1];
        }
        return actions;
    }

    function isDeckUsed( uint256 deckId  ) public view returns ( bool ) {
        return bool( _usedDeck[ deckId ] );
    }


    function generateMatch( uint256 amount ) public virtual {

        require( _activeMatch[ msg.sender ].length <= MAX_ACTIVE_MATCH, "This address have" );

        address[] memory emptyPlayers;
        uint256[] memory emptyDecks;
        uint256 matchId = _matchCounter.current();
        _matchCounter.increment();

        _matches[ matchId ] = Match({
            _id: matchId,
            _startBlock: block.number,
            _arenaId: ARENA_ID,
            _creator: msg.sender,
            _activePlayers: emptyPlayers,
            _players: emptyPlayers,
            _decks: emptyDecks,
            _amount: amount,
            _lastActionId: uint256(0),
            _winner: address(0x0)
        });

        _activeMatch[ msg.sender ].push( matchId );

        emit GenerateMatch( matchId, ARENA_ID, msg.sender, amount );
    }


    function destroyMatch( uint256 matchId ) public virtual {

        require( _matches[ matchId ]._creator == msg.sender, "Just the Match creator can Destroy it" );
        require( _matches[ matchId ]._players.length == 0 , "All players should leave before destroy this Match" );

        delete _matches[ matchId ];
        _activeMatch[ msg.sender ] = Arrays.popUint256( _activeMatch[ msg.sender ], matchId );

        emit DestroyMatch( matchId );
    }


    function joinMatch( uint256 matchId, uint256 deckId ) public virtual {

        require( !_usedDeck[ deckId ] , "This Deck is already used in another Match");
        require( _matches[ matchId ]._players.length < PLAYERS_COUNT, "All Players have already join this Match" );

        _matches[ matchId ]._activePlayers.push( msg.sender );
        _matches[ matchId ]._players.push( msg.sender );
        _matches[ matchId ]._decks.push( deckId );
        _usedDeck[ deckId ] = true;

        emit JoinMatch( matchId, _matches[ matchId ]._arenaId, msg.sender, deckId, _matches[ matchId ]._amount );
    }


    function leaveMatch( uint256 matchId ) public virtual callerIsPlayer(matchId){

        for( uint256 i = 0; i < _matches[ matchId ]._players.length; i++ ){
            if( _matches[ matchId ]._players[i] == msg.sender ) {
                _matches[ matchId ]._activePlayers = Arrays.popAddress( _matches[ matchId ]._activePlayers, _matches[ matchId ]._activePlayers[i] );
                _matches[ matchId ]._players = Arrays.popAddress( _matches[ matchId ]._players, _matches[ matchId ]._players[i] );
                _matches[ matchId ]._decks = Arrays.popUint256( _matches[ matchId ]._decks, _matches[ matchId ]._decks[i] );
                _usedDeck[ _matches[ matchId ]._decks[i] ] = false;
            }
        }

        emit LeaveMatch( matchId, msg.sender );
    }


    function updateMatch(
        uint256 matchId,
        uint256 performerId,
        uint8[] memory actionType,
        bytes4[] memory coordinates,
        uint256[] memory targetIDs,
        int256[] memory targetEPs
    ) public virtual callerIsPlayer(matchId){

        require( _matches[ matchId ]._players.length == PLAYERS_COUNT, "All Players should join this Match first" );
        require(
            actionType.length == coordinates.length &&
            actionType.length == targetIDs.length &&
            actionType.length == targetEPs.length,
            "Arrays lengths mismatch"
        );

        for( uint256 i = 0; i < actionType.length; i++){

            require( coordinates[i] <= ARENA_SIZE, "Coordinate provided should be inside of Arena" );

            uint256 actionId = _matches[ matchId ]._lastActionId + 1;
            _matches[ matchId ]._lastActionId = actionId;

            _matchActions[ matchId ][ actionId ] = Action({
                _performerId: performerId,
                _actionType: actionType[i],
                _coordinates: coordinates[i],
                _targetId: targetIDs[i],
                _targetEP: targetEPs[i]
            });
        }

        emit UpdateMatch( matchId, msg.sender, performerId, actionType, coordinates, targetIDs, targetEPs);
    }


    function surrendMatch( uint256 matchId ) public virtual callerIsPlayer(matchId){

        _looseMatch( matchId, msg.sender );

        emit SurrendMatch( matchId, msg.sender );
    }

    function _looseMatch( uint256 matchId, address player ) internal virtual {

        _matches[ matchId ]._activePlayers = Arrays.popAddress( _matches[ matchId ]._activePlayers, player );
        if( _matches[ matchId ]._activePlayers.length == 1 ) _endMatch( matchId, _matches[ matchId ]._activePlayers[0] );
    }

    function _endMatch( uint256 matchId, address winner ) internal virtual {

        for( uint256 i = 0; i < _matches[ matchId ]._decks.length; i++ ) _usedDeck[ _matches[ matchId ]._decks[i] ] = false;

        _activeMatch[ _matches[ matchId ]._creator ] = Arrays.popUint256( _activeMatch[ msg.sender ], matchId );

        emit EndMatch( matchId, winner );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// @dev Arrays Library for pop elements
library Arrays {

    function popUint256( uint256[] memory array, uint256 element ) internal pure returns( uint256[] memory ){

        uint256[] memory poppedArray = new uint256[]( array.length - 1);
        uint x = 0;
        for (uint256 i = 0; i < array.length; i++ ) {
            if (array[i] != element) {
                poppedArray[x] = array[i];
                x++;
            }
        }
        return poppedArray;
    }

    function popAddress( address[] memory array, address element ) internal pure returns( address[] memory ){

        address[] memory poppedArray = new address[]( array.length - 1);
        uint x = 0;
        for (uint256 i = 0; i < array.length; i++ ) {
            if (array[i] != element) {
                poppedArray[x] = array[i];
                x++;
            }
        }
        return poppedArray;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}