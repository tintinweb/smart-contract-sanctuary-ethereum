// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM`MMM NMM MMM MMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMhMMMMMMM  MMMMMMMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM  MM-MMMMM   MMMM    MMMM   lMMMDMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMM jMMMMl   MM    MMM  M  MMM   M   MMMM MMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMM MMMMMMMMM  , `     M   Y   MM  MMM  BMMMMMM MMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMM MMMMMMMMMMMM  IM  MM  l  MMM  X   MM.  MMMMMMMMMM MMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.nlMMMMMMMMMMMMMMMMM]._  MMMMMMMMMMMMMMMNMMMMMMMMMMMMMM
// MMMMMMMMMMMMMM TMMMMMMMMMMMMMMMMMM          +MMMMMMMMMMMM:  rMMMMMMMMN MMMMMMMMMMMMMM
// MMMMMMMMMMMM MMMMMMMMMMMMMMMM                  MMMMMM           MMMMMMMM qMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMM^                   MMMb              .MMMMMMMMMMMMMMMMMMM
// MMMMMMMMMM MMMMMMMMMMMMMMM                     MM                  MMMMMMM MMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM                     M                   gMMMMMMMMMMMMMMMMM
// MMMMMMMMu MMMMMMMMMMMMMMM                                           MMMMMMM .MMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMM                                           :MMMMMMMMMMMMMMMM
// MMMMMMM^ MMMMMMMMMMMMMMMl                                            MMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMM                                             MMMMMMMMMMMMMMMM
// MMMMMMM MMMMMMMMMMMMMMMM                                             MMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMM                                             MMMMMMMMMMMMMMMM
// MMMMMMr MMMMMMMMMMMMMMMM                                             MMMMMMMM .MMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMM                                           MMMMMMMMMMMMMMMMM
// MMMMMMM MMMMMMMMMMMMMMMMM                                         DMMMMMMMMMM MMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM                              MMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMM|`MMMMMMMMMMMMMMMM         q                      MMMMMMMMMMMMMMMMMMM  MMMMMMM
// MMMMMMMMMTMMMMMMMMMMMMMMM                               qMMMMMMMMMMMMMMMMMMgMMMMMMMMM
// MMMMMMMMq MMMMMMMMMMMMMMMh                             jMMMMMMMMMMMMMMMMMMM nMMMMMMMM
// MMMMMMMMMM MMMMMMMMMMMMMMMQ      nc    -MMMMMn        MMMMMMMMMMMMMMMMMMMM MMMMMMMMMM
// MMMMMMMMMM.MMMMMMMMMMMMMMMMMMl            M1       `MMMMMMMMMMMMMMMMMMMMMMrMMMMMMMMMM
// MMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMM               :MMMMMMMMMM MMMMMMMMMMMM qMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMMMX       MMMMMMMMMMMMMMM  uMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMM DMMMMMMMMM   IMMMMMMMMMMMMMMMMMMMMMMM   M   Y  MMMMMMMN MMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMM MMMMMM    ``    M      MM  MMM   , MMMM    Mv  MMM MMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMM MMh  Ml  .   M  MMMM  I  MMMT  M     :M   ,MMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMM MMMMMMMMt  MM  MMMMB m  ]MMM  MMMM   MMMMMM MMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMM MMMMM  MMM   TM   MM  9U  .MM  _MMMMM MMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMM YMMMMMMMn     MMMM    +MMMMMMM1`MMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMMMMM MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.`MMM MMM MMMMM`.MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM author: phaze MMM

import {Choice} from "./lib/Choice.sol";
import {Ownable} from "./lib/Ownable.sol";
import {IGouda, IMadMouse} from "./lib/interfaces.sol";

error NoWhitelistRemaining();
error MaxEntriesReached();
error ContractCallNotAllowed();
error NotActive();
error RequirementNotFulfilled();
error RandomSeedAlreadyChosen();

contract Marketplace is Ownable {
    event BurnForItem(address indexed user, bytes32 indexed id);

    struct MarketItem {
        uint32 totalSupply;
        uint224 restingPrice;
    }

    mapping(bytes32 => MarketItem) public marketItems;
    mapping(bytes32 => mapping(address => uint256)) public numEntries;

    mapping(bytes32 => mapping(uint256 => address)) public raffleEntries;
    mapping(bytes32 => uint256) public raffleRandomSeeds;

    IGouda constant gouda = IGouda(0x3aD30C5E3496BE07968579169a96f00D56De4C1A);
    IMadMouse constant genesis = IMadMouse(0x3aD30c5e2985e960E89F4a28eFc91BA73e104b77);
    IMadMouse constant troupe = IMadMouse(0x74d9d90a7fc261FBe92eD47B606b6E0E00d75E70);

    /* ------------- External ------------- */

    function purchaseMarketItem(
        uint256 start,
        uint256 end,
        uint256 price,
        uint256 maxEntries,
        uint256 maxSupply,
        uint256 requirement,
        uint256 requirementData
    ) external onlyEOA {
        unchecked {
            bytes32 hash = keccak256(abi.encode(start, end, price, maxEntries, maxSupply, requirement));

            if (block.timestamp < start || end < block.timestamp) revert NotActive();

            MarketItem storage marketItem = marketItems[hash];
            uint256 totalSupply = ++marketItem.totalSupply;

            if (totalSupply > maxSupply) revert NoWhitelistRemaining();
            if (++numEntries[hash][msg.sender] > maxEntries) revert MaxEntriesReached();
            if (requirement != 0 && !fulfillsRequirement(msg.sender, requirement, requirementData))
                revert RequirementNotFulfilled();

            gouda.burnFrom(msg.sender, price);
            emit BurnForItem(msg.sender, hash);
        }
    }

    function purchaseMarketItemDutchAuction(
        uint256 start,
        uint256 end,
        uint256 startPrice,
        uint256 endPrice,
        uint256 maxEntries,
        uint256 maxSupply,
        uint256 requirement,
        uint256 requirementData
    ) external onlyEOA {
        unchecked {
            bytes32 hash = keccak256(abi.encode(start, end, startPrice, endPrice, maxEntries, maxSupply, requirement));

            uint256 price;
            if (block.timestamp < start) revert NotActive();

            // assumptions: endPrice < startPrice; timestamp >= start; start <= end
            uint256 timestamp = block.timestamp > end ? end : block.timestamp;
            price = startPrice - ((startPrice - endPrice) * (timestamp - start)) / (end - start); // overflow unlikely

            MarketItem storage marketItem = marketItems[hash];

            if (++marketItem.totalSupply > maxSupply) revert NoWhitelistRemaining();
            if (++numEntries[hash][msg.sender] > maxEntries) revert MaxEntriesReached();
            if (requirement != 0 && !fulfillsRequirement(msg.sender, requirement, requirementData))
                revert RequirementNotFulfilled();

            marketItem.restingPrice = uint224(price);

            gouda.burnFrom(msg.sender, price);
            emit BurnForItem(msg.sender, hash);
        }
    }

    function purchaseMarketItemRaffle(
        uint256 start,
        uint256 end,
        uint256 price,
        uint256 maxEntries,
        uint256 maxSupply,
        uint256 numPrizes,
        uint256 requirement,
        uint256 requirementData
    ) external onlyEOA {
        unchecked {
            bytes32 hash = keccak256(abi.encode(start, end, price, maxEntries, maxSupply, numPrizes, requirement));

            if (block.timestamp < start || end < block.timestamp) revert NotActive();

            MarketItem storage marketItem = marketItems[hash];

            uint256 totalSupply = ++marketItem.totalSupply;

            if (totalSupply > maxSupply) revert NoWhitelistRemaining();
            if (++numEntries[hash][msg.sender] > maxEntries) revert MaxEntriesReached();
            if (requirement != 0 && !fulfillsRequirement(msg.sender, requirement, requirementData))
                revert RequirementNotFulfilled();

            raffleEntries[hash][totalSupply] = msg.sender;

            gouda.burnFrom(msg.sender, price);
            emit BurnForItem(msg.sender, hash);
        }
    }

    /* ------------- View ------------- */

    function getRaffleEntries(bytes32 hash) external view returns (address[] memory) {
        uint256 totalSupply = marketItems[hash].totalSupply;

        address[] memory entrants = new address[](totalSupply);

        for (uint256 i; i < totalSupply; ++i) entrants[i] = raffleEntries[hash][i + 1];

        return entrants;
    }

    function getRaffleWinners(bytes32 hash, uint256 numPrizes) public view returns (address[] memory winners) {
        uint256 randomSeed = raffleRandomSeeds[hash];
        if (randomSeed == 0) return winners;

        uint256[] memory winnerIds = Choice.selectNOfM(numPrizes, marketItems[hash].totalSupply, randomSeed);

        uint256 numIds = winnerIds.length;

        winners = new address[](numIds);

        for (uint256 i; i < numIds; ++i) winners[i] = raffleEntries[hash][winnerIds[i] + 1];
    }

    /* ------------- Owner ------------- */

    function revealRaffle(
        uint256 start,
        uint256 end,
        uint256 price,
        uint256 maxEntries,
        uint256 maxSupply,
        uint256 numPrizes,
        uint256 requirement
    ) external onlyOwner {
        bytes32 hash = keccak256(abi.encode(start, end, price, maxEntries, maxSupply, numPrizes, requirement));

        if (block.timestamp < end) revert NotActive();

        if (raffleRandomSeeds[hash] != 0) revert RandomSeedAlreadyChosen();

        raffleRandomSeeds[hash] = uint256(keccak256(abi.encode(blockhash(block.number - 1), hash)));
    }

    /* ------------- View ------------- */

    // 1: genesis
    // 2: troupe
    // 3: genesis / troupe
    // 4: level >= 2
    // 5: level == 3
    function fulfillsRequirement(
        address user,
        uint256 requirement,
        uint256 data
    ) public view returns (bool) {
        unchecked {
            if (requirement == 1 && genesis.numOwned(user) > 0) return true;
            else if (requirement == 2 && troupe.numOwned(user) > 0) return true;
            else if (
                requirement == 3 &&
                // specify data == 1 to direct that user is holding troupe and potentially save an sload;
                // or leave unspecified and worst-case check both
                ((data != 2 && troupe.numOwned(user) > 0) || (data != 1 && genesis.numOwned(user) > 0))
            ) return true;
            else if (
                requirement == 4 &&
                (
                    data > 5000 // specify owner-held id: data > 5000 refers to genesis collection
                        ? genesis.getLevel(data - 5000) > 1 && genesis.ownerOf(data - 5000) == user
                        : troupe.getLevel(data) > 1 && troupe.ownerOf(data) == user
                )
            ) return true;
            else if (
                requirement == 5 &&
                (
                    data > 5000
                        ? genesis.getLevel(data - 5000) > 2 && genesis.ownerOf(data - 5000) == user
                        : troupe.getLevel(data) > 2 && troupe.ownerOf(data) == user
                )
            ) return true;
            return false;
        }
    }

    /* ------------- Modifier ------------- */

    modifier onlyEOA() {
        if (msg.sender != tx.origin) revert ContractCallNotAllowed();
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// author: phaze

// assumption: n << m
// caveats: splits random number into 16 parts for efficiency
// this means that 65536 is the highest random number
// (can skew uniform distributions when m is hight)
library Choice {
    function selectNOfM(
        uint256 n,
        uint256 m,
        uint256 r
    ) internal pure returns (uint256[] memory) {
        unchecked {
            if (n > m) n = m;

            uint256[] memory choice = new uint256[](n);

            uint256 s;
            uint256 slot;

            uint256 j;
            uint256 c;

            bool invalidChoice;

            for (uint256 i; i < n; ++i) {
                do {
                    slot = (s & 0xF) << 4;
                    if (slot == 0 && i != 0) r = uint256(keccak256(abi.encode(r, s)));
                    c = ((r >> slot) & 0xFFFF) % m;
                    invalidChoice = false;
                    for (j = 0; j < i && !invalidChoice; ++j) invalidChoice = choice[j] == c;
                    ++s;
                } while (invalidChoice);

                choice[i] = c;
            }
            return choice;
        }
    }

    function selectNOfM(
        uint256 n,
        uint256 m,
        uint256 r,
        uint256 offset
    ) internal pure returns (uint256[] memory) {
        unchecked {
            if (n > m) n = m;

            uint256[] memory choice = new uint256[](n);

            uint256 s;
            uint256 slot;

            uint256 j;
            uint256 c;

            bool invalidChoice;

            for (uint256 i; i < n; ++i) {
                do {
                    slot = (s & 0xF) << 4;
                    if (slot == 0 && i != 0) r = uint256(keccak256(abi.encode(r, s)));
                    c = (((r >> slot) & 0xFFFF) % m) + offset;
                    invalidChoice = false;
                    for (j = 0; j < i && !invalidChoice; ++j) invalidChoice = choice[j] == c;
                    ++s;
                } while (invalidChoice);

                choice[i] = c;
            }
            return choice;
        }
    }

    function indexOfSelectNOfM(
        uint256 x,
        uint256 n,
        uint256 m,
        uint256 r
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (n > m) n = m;

            uint256[] memory choice = new uint256[](n);

            uint256 s;
            uint256 slot;

            uint256 j;
            uint256 c;

            bool invalidChoice;

            for (uint256 i; i < n; ++i) {
                do {
                    slot = (s & 0xF) << 4;
                    if (slot == 0 && i != 0) r = uint256(keccak256(abi.encode(r, s)));
                    c = ((r >> slot) & 0xFFFF) % m;
                    invalidChoice = false;
                    for (j = 0; j < i && !invalidChoice; ++j) invalidChoice = choice[j] == c;
                    ++s;
                } while (invalidChoice);

                if (x == c) return (true, i);

                choice[i] = c;
            }
            return (false, 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error CallerNotOwner();

abstract contract Ownable {
    address _owner = msg.sender;

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) revert CallerNotOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IGouda {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function mint(address user, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

interface IMadMouse {
    function numStaked(address user) external view returns (uint256);

    function numOwned(address user) external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getLevel(uint256 tokenId) external view returns (uint256);

    function getDNA(uint256 tokenId) external view returns (uint256);
}