/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract Test {
    struct EntryPrices {
        uint256 numofEntries;
        uint256 price;
    }
    struct Entries {
        uint256 player; // todo: address
        uint256 entriesLength;
    }
    struct Raffles {
        address winner;
        uint256 randomNum;
        uint256 raised;
        EntryPrices[5] prices;
        Entries[] entries;
    }
    mapping(uint256 => Raffles) public raffles;
    uint256 totalRaffles;
    address immutable owner;

    constructor() {
        owner = msg.sender;
        EntryPrices memory entryprice1 = EntryPrices({
            numofEntries: 10,
            price: 0.001 ether
        });
        EntryPrices memory entryprice2 = EntryPrices({
            numofEntries: 20,
            price: 0.002 ether
        });
        EntryPrices memory entryprice3 = EntryPrices({
            numofEntries: 40,
            price: 0.003 ether
        });

        Raffles storage raffle = raffles[0];

        raffle.prices[0] = entryprice1;
        raffle.prices[1] = entryprice2;
        raffle.prices[2] = entryprice3;

    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function _checkOwner() internal view virtual {
        require(owner == msg.sender, "Ownable: caller is not the owner");
    }

    function getEntries(uint256 raffleId)
        external
        view
        returns (Entries[] memory)
    {
        return raffles[raffleId].entries;
    }

    function prices(uint256 _raffleId)
        external
        view
        returns (EntryPrices[5] memory)
    {
        return raffles[_raffleId].prices;
    }

    /*
    struct Raffles {
        address winner;
        uint256 randomNum;
        uint256 totalEntries;
        uint256 raised;
        EntryPrices[5] prices;
        Entries[] entries;
    }*/

    function testrafflecalldata(EntryPrices[] calldata _prices)
        external
        view
        onlyOwner
        returns (uint256)
    {
        return _prices[0].price;
    }

    function gettotalEntries(uint256 _raffleId) public view returns(uint256){
        uint256 entrieslen = raffles[_raffleId].entries.length;
        return entrieslen > 0 ? raffles[_raffleId].entries[entrieslen - 1].entriesLength : 0;
    }

    function createRaffle(EntryPrices[] calldata _prices) external onlyOwner {
        //return _prices.length;
        unchecked {
            ++totalRaffles; 

            for (uint256 i = 0; i < _prices.length; ++i) {
                raffles[totalRaffles].prices[i] = EntryPrices({
                    numofEntries: _prices[i].numofEntries,
                    price: _prices[i].price
                });
            }
        }
    }

    function buy(
        uint256 raffleId,
        uint256 entryType,
        uint256 player
    ) external payable {
        require(raffleId <= totalRaffles, "Invalid Raffle");
        require(msg.sender == tx.origin);
        //require(raffles[raffleId].prices[entryType].price == msg.value, "Invalid ETH sent");

        Raffles storage raffle = raffles[raffleId];
        uint256 entriesBought = raffles[raffleId].prices[entryType].numofEntries;
        uint256 _totalEntries = gettotalEntries(raffleId);
        //raffle.raised += msg.value;

        raffle.entries.push(
            Entries({
                player: player,
                entriesLength: _totalEntries + entriesBought
            })
        );
    }



    function getWinnerAddressFromRandom(uint256 _raffleId, uint256 _rng)
        external
        view
        returns (uint256)
    {
        uint256 position = findUpperBound(raffles[_raffleId].entries, _rng);
        return raffles[_raffleId].entries[position].player;
    }

    function findUpperBound(Entries[] storage array, uint256 element)
        internal
        view
        returns (uint256)
    {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = (low & high) + (low ^ high) / 2;

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid].entriesLength > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1].entriesLength == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}