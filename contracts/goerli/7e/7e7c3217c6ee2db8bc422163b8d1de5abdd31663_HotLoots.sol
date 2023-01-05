// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "Ownable.sol";

contract HotLoots is Ownable {
    address[] public users;
    uint256 public entryfee;

    event RaffleCreated(
        uint256 indexed raffleId
    );

    event RaffleStarted(uint256 indexed raffleId);
    
    event RaffleEnded(
        uint256 indexed raffleId,
        address indexed winner
    );

    event UsesrJoined(uint256 raffleId, address user);
    
    event EntrySold(
        uint256 indexed raffleId,
        address indexed buyer,
        uint256 currentSize,
        uint256 priceStructureId
    );

    struct PriceStructure {
        uint256 id;
        uint256 numEntries;
        uint256 price;
    }

    event JoinedPrice(uint256 id, uint256 numEntries, uint256 price);

    mapping(uint256 => PriceStructure[4]) public prices;

    struct EntriesBought {
        uint256 currentEntriesLength;
        address user;
    }

    mapping(uint256 => EntriesBought[]) public entriesList;

    struct RaffleStruct {
        uint256 raffleId;
        address winner;
        uint256 entriesLength;
    }

    RaffleStruct[] public raffles;
    address public mainOwner;

    constructor() {
        mainOwner = msg.sender;
    }

    function createRaffle (uint256 raffleId, PriceStructure[] calldata _prices) external onlyOwner returns (uint256){
        RaffleStruct memory raffle = RaffleStruct({
            raffleId: raffleId,
            winner: address(0),
            entriesLength: 0
        });

        raffles.push(raffle);

        require(_prices.length > 0, "No prices");

        for (uint256 i = 0; i < _prices.length; i++) {
            require(_prices[i].numEntries > 0, "numEntries is 0");

            PriceStructure memory p = PriceStructure({
                id: _prices[i].id,
                numEntries: _prices[i].numEntries,
                price: _prices[i].price
            });

            prices[raffleId][i] = p;
        }

        emit RaffleCreated(
            raffles.length - 1
        );

        return raffles.length - 1;
    }

    function buyTickets(
        uint256 _raffleId,
        uint256 _priceId
    ) public payable {
        
        require(msg.sender != address(0), "msg.sender is null");
        uint raffleStruct = getRaffleId(_raffleId);
        PriceStructure memory priceStruct = getPriceStructForId(_raffleId, _priceId);
        require(priceStruct.numEntries > 0, "id not supported");

        require(
            msg.value == priceStruct.price,
            "msg.value must be equal to the price"
        );

        EntriesBought memory entryBought = EntriesBought({
            user: msg.sender,
            currentEntriesLength: raffles[raffleStruct].entriesLength + priceStruct.numEntries
        });

        entriesList[raffleStruct].push(entryBought);
        raffles[raffleStruct].entriesLength = raffles[raffleStruct].entriesLength + priceStruct.numEntries;

        emit EntrySold(
            _raffleId,
            msg.sender,
            raffles[raffleStruct].entriesLength,
            _priceId
        );
    }

    function getRaffleId(uint256 _idRaffle)
        internal
        view
        returns (uint){
            for (uint256 i = 0; i < raffles.length; i++) {
                if (raffles[i].raffleId == _idRaffle) {
                    return i;
                }
            }
            return 0;
    }

    function getRaffle(uint256 _idRaffle)
        internal
        view
        returns (RaffleStruct memory){
            for (uint256 i = 0; i < raffles.length; i++) {
                if (raffles[i].raffleId == _idRaffle) {
                    return raffles[i];
                }
            }
            return RaffleStruct({raffleId: _idRaffle, winner: address(0), entriesLength: 0});
    }

    function getPriceStructForId(uint256 _idRaffle, uint256 _id)
        internal
        view
        returns (PriceStructure memory)
    {
        for (uint256 i = 0; i < 4; i++) {
            if (prices[_idRaffle][i].id == _id) {
                return prices[_idRaffle][i];
            }
        }
        return PriceStructure({id: 0, numEntries: 0, price: 0});
    }

    function setWinner(uint _raffleId, address winnerUser) external onlyOwner returns (address winner){
        uint raffleStruct = getRaffleId(_raffleId);
        raffles[raffleStruct].winner = winnerUser;

        emit RaffleEnded(_raffleId, winnerUser);
        return winnerUser;
    }
}