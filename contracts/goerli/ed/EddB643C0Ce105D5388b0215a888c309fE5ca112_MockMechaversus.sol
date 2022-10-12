// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";


contract MockMechaversus {

    using Counters for Counters.Counter;
    Counters.Counter private _matchCounter;

    // @dev The number of Players in a single Match
    uint8 constant PLAYERS_COUNT = 2;

    // @dev The mocked arena_id
    uint256 constant ARENA_ID = 1234;

    struct Match {
        uint256 _id;
        uint256 _arenaId;
        address[] _players;
        uint256[] _decks;
        uint256 _amount;
        address _winner;
    }

    struct Entity {
        uint8 _type;
        uint256 _coordinates;
        uint256 _EP;
        uint256 _SP;
        uint256 _MP;
        uint256 _GP;
        uint256 _DP;
    }

    // @dev match_id => Match struct{}
    mapping( uint256 => Match ) private _matches;

    // @dev match_id => entity_id => Entity{}
    mapping( uint256 => mapping( uint256 => Entity )) private _matchEntities;

    // @dev part_id => if is broken
    mapping ( uint256 => uint256 ) private _breakingLoad;

    event GenerateMatch(
        uint256 matchId,
        uint256 arenaId,
        address creator,
        uint256 matchAmount
    );

    event JoinMatch(
        uint256 matchId,
        uint256 arenaId,
        address player,
        uint256 deckId,
        uint256 joinAmount
    );

    event UpdateEntities(
        uint256 matchId,
        address player,
        uint256[] entityIDs,
        uint8[] types,
        uint256[] coordinates,
        uint256[] EP,
        uint256[] SP,
        uint256[] MP,
        uint256[] GP,
        uint256[] DP
    );

    event EndMatch(
        uint256 matchId,
        address winner
    );

    constructor() {
        _matchCounter.reset();
        _matchCounter.increment();
    }

    function getMatch( uint256 match_id ) public view returns ( Match memory ) {
        return _matches[ match_id ];
    }

    function getEntity( uint256 match_id, uint256 entity_id ) public view returns ( Entity memory ) {
        return _matchEntities[ match_id ][entity_id];
    }

    function getBreakingLoad( uint256 entity_id ) public view returns ( uint256 ) {
        return _breakingLoad[ entity_id ];
    }

    // @dev Mocked version that implement the Match generation
    function generateMatch( uint256 amount ) public virtual {

        uint256 matchId = _matchCounter.current();
        _matchCounter.increment();

        _matches[ matchId ] = Match({
            _id: matchId,
            _arenaId: ARENA_ID,
            _players: new address[]( PLAYERS_COUNT ),
            _decks: new uint256[]( PLAYERS_COUNT ),
            _amount: amount,
            _winner: address(0x0)
        });

        emit GenerateMatch( matchId, ARENA_ID, msg.sender, amount );
    }

    // @dev Mocked version that implement the Player joining to the Match
    function joinMatch( uint256 matchId, uint256 deckId ) public virtual {

        // @dev Player send half of Mechadium to the reserve
        uint256 joinAmount = _matches[ matchId ]._amount / PLAYERS_COUNT;

        _matches[ matchId ]._players.push( msg.sender );
        _matches[ matchId ]._decks.push( deckId );

        emit JoinMatch( matchId, _matches[ matchId ]._arenaId, msg.sender, deckId, joinAmount );
    }

    // @dev Mocked version that implement the Match Entities data updating
    function updateEntities(
        uint256 matchId,
        uint256[] memory entityIDs,
        uint8[] memory types,
        uint256[] memory coordinates,
        uint256[] memory EP,
        uint256[] memory SP,
        uint256[] memory MP,
        uint256[] memory GP,
        uint256[] memory DP
    ) public virtual returns ( bool ){

        require(
            entityIDs.length == types.length &&
            entityIDs.length == coordinates.length &&
            entityIDs.length == EP.length &&
            entityIDs.length == SP.length &&
            entityIDs.length == MP.length &&
            entityIDs.length == GP.length &&
            entityIDs.length == DP.length,
            "Arrays lengths mismatch"
        );

        for( uint256 i = 0; i < entityIDs.length; i++){

            _matchEntities[ matchId ][ entityIDs[i] ] = Entity({
                _type: types[i],
                _coordinates: coordinates[i],
                _EP: EP[i],
                _SP: SP[i],
                _MP: MP[i],
                _GP: GP[i],
                _DP: DP[i]
            });
        }

        emit UpdateEntities( matchId, msg.sender, entityIDs, types, coordinates, EP, SP, MP, GP, DP );

        return true;
    }

    // @dev Mocked version that implement the Entities Breaking Load value updating
    function endMatch( uint256 matchId, address winner, uint256[] memory entityIDs, uint256[] memory EPs ) public virtual {

        require( entityIDs.length == EPs.length, "partsIDs and erosions length mismatch");

        for( uint256 i = 0; i < entityIDs.length; i++ ) {
            _breakingLoad[ entityIDs[i] ] = EPs[i];
        }

        emit EndMatch( matchId, winner );
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