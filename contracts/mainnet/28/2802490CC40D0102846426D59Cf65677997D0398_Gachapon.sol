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

import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {IERC721} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import {IERC721Metadata} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC721Metadata.sol";

import {IGouda, IMadMouse} from "./lib/interfaces.sol";
import {Ownable} from "./lib/Ownable.sol";
import {Choice} from "./lib/Choice.sol";

import {Tickets} from "./Tickets.sol";

error RaffleNotActive();
error RaffleOngoing();
error RaffleRandomSeedSet();
error RaffleAlreadyCancelled();
error TicketsMaxSupplyReached();

error RaffleUnrevealed();
error PrizeAlreadyClaimed();

error BetterLuckNextTime();
error MachineBeDoinWork();
error NeedsMoarTickets();
error TicketsImplementationUnset();
error InvalidTimestamps();
error InvalidTicketPrice();
error RequirementNotFulfilled();

error ContractCallNotAllowed();

contract Gachapon is Ownable {
    using Strings for uint256;

    event Chachingg();
    event GrappleGrapple();
    event BZZzzt();

    struct Raffle {
        uint40 start;
        uint40 end;
        uint40 ticketSupply;
        uint40 maxTicketSupply;
        uint40 ticketPrice; // in multiples of 1e18
        uint8 requirement;
        uint16 refundRate;
        bool cancelled;
        address tickets;
        uint40 randomSeed;
        address prizeNFT;
        uint32[] prizeTokenIds;
    }

    string ticketURI = "ipfs://QmSwrzsySKnkQmRQoZYmZ2XuJx3NMn2awdHwf1fezAJbq3/silver-ticket.json";
    string losingTicketURI = "ipfs://QmSwrzsySKnkQmRQoZYmZ2XuJx3NMn2awdHwf1fezAJbq3/red-ticket.json";
    string winningTicketURI = "ipfs://QmSwrzsySKnkQmRQoZYmZ2XuJx3NMn2awdHwf1fezAJbq3/gold-ticket.json";

    address ticketsImplementation;

    uint256 public numRaffles;
    mapping(uint256 => Raffle) private raffles;
    mapping(address => uint256) public ticketsToRaffleId;
    mapping(uint256 => uint256) requestIdToLot;

    mapping(uint256 => mapping(uint256 => bool)) public claimedPrize;

    uint256 constant ONE_MONTH = 3600 * 24 * 28;

    IGouda constant gouda = IGouda(0x3aD30C5E3496BE07968579169a96f00D56De4C1A);
    IMadMouse constant genesis = IMadMouse(0x3aD30c5e2985e960E89F4a28eFc91BA73e104b77);
    IMadMouse constant troupe = IMadMouse(0x74d9d90a7fc261FBe92eD47B606b6E0E00d75E70);

    /* ------------- External ------------- */

    function buyTicket(uint256 raffleId, uint256 requirementData) external noContract {
        Raffle storage raffle = raffles[raffleId];
        uint256 ticketSupply = raffle.ticketSupply;

        if (raffle.cancelled || raffle.end < block.timestamp || block.timestamp < raffle.start)
            revert RaffleNotActive();
        if (ticketSupply == raffle.maxTicketSupply) revert TicketsMaxSupplyReached();

        uint256 requirement = raffle.requirement;
        if (requirement != 0 && !fulfillsRequirement(msg.sender, requirement, requirementData))
            revert RequirementNotFulfilled();

        unchecked {
            gouda.burnFrom(msg.sender, raffle.ticketPrice * 1e18);
        }

        uint256 ticketId = ++ticketSupply;
        raffle.ticketSupply = uint40(ticketSupply);

        Tickets(raffle.tickets).mint(msg.sender, ticketId);
    }

    function claimPrize(uint256 raffleId, uint256 ticketId) external noContract {
        Raffle storage raffle = raffles[raffleId];
        Tickets tickets = Tickets(raffle.tickets);

        uint256 randomSeed = raffle.randomSeed;

        if (raffle.cancelled) revert RaffleNotActive();
        if (randomSeed == 0) revert RaffleUnrevealed();

        uint256 numPrizes = raffle.prizeTokenIds.length;
        uint256 numEntrants = raffle.ticketSupply;

        // ticketId starts at 1
        (bool win, uint256 prizeId) = Choice.indexOfSelectNOfM(ticketId - 1, numPrizes, numEntrants, randomSeed);

        if (tickets.ownerOf(ticketId) != msg.sender || !win) revert BetterLuckNextTime();
        if (claimedPrize[raffleId][ticketId]) revert PrizeAlreadyClaimed();

        claimedPrize[raffleId][ticketId] = true;

        IERC721 prizeNFT = IERC721(raffle.prizeNFT);
        prizeNFT.transferFrom(address(this), msg.sender, raffle.prizeTokenIds[prizeId]);
    }

    function burnTickets(uint256[] calldata burnRaffleIds, uint256[] calldata burnTicketIds) external noContract {
        Raffle storage raffle;

        uint256 refund;
        uint256 refundRate;

        uint256 numBurnTickets = burnTicketIds.length;
        if (numBurnTickets == 0) revert NeedsMoarTickets();

        unchecked {
            for (uint256 i; i < numBurnTickets; ++i) {
                raffle = raffles[burnRaffleIds[i]];
                Tickets tickets = Tickets(raffle.tickets);

                tickets.burnFrom(msg.sender, burnTicketIds[i]);

                refundRate = raffle.refundRate;
                if (refundRate > 0) refund += (raffle.ticketPrice * 1e18 * refundRate) >> 16;
            }
        }

        gouda.mint(msg.sender, refund);
    }

    /* ------------- View ------------- */

    function isWinningTicket(uint256 raffleId, uint256 ticketId) public view returns (bool win) {
        Raffle storage raffle = raffles[raffleId];
        uint256 randomSeed = raffle.randomSeed;

        if (raffle.cancelled || randomSeed == 0) return false;

        uint256 numPrizes = raffle.prizeTokenIds.length;
        uint256 numEntrants = raffle.ticketSupply;

        unchecked {
            (win, ) = Choice.indexOfSelectNOfM(ticketId - 1, numPrizes, numEntrants, randomSeed);
        }
        return win;
    }

    function getWinningTickets(uint256 raffleId) public view returns (uint256[] memory ticketIds) {
        Raffle storage raffle = raffles[raffleId];

        uint256 randomSeed = raffle.randomSeed;

        if (raffle.cancelled || randomSeed == 0) return ticketIds;

        uint256 numPrizes = raffle.prizeTokenIds.length;
        uint256 numEntrants = raffle.ticketSupply;

        return Choice.selectNOfM(numPrizes, numEntrants, randomSeed, 1);
    }

    function getWinners(uint256 raffleId) public view returns (address[] memory winners) {
        Tickets tickets = Tickets(raffles[raffleId].tickets);

        uint256[] memory prizeTokenIds = getWinningTickets(raffleId);
        uint256 numIds = prizeTokenIds.length;

        winners = new address[](numIds);
        for (uint256 i; i < numIds; ++i) winners[i] = tickets.ownerOf(prizeTokenIds[i]);
    }

    function getRaffle(uint256 raffleId) external view returns (Raffle memory) {
        return raffles[raffleId];
    }

    function fulfillsRequirement(
        address user,
        uint256 requirement,
        uint256 data
    ) public returns (bool) {
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

    /* ------------- Tickets Callbacks ------------- */

    function ticketsSupply() external view returns (uint256) {
        uint256 raffleId = ticketsToRaffleId[msg.sender];
        return raffles[raffleId].ticketSupply;
    }

    function ticketsName() external view returns (string memory) {
        uint256 raffleId = ticketsToRaffleId[msg.sender];
        string memory prizeNFTName = IERC721Metadata(raffles[raffleId].prizeNFT).name();
        return string.concat("Gouda Slot Machine Raffle #", raffleId.toString(), ": ", prizeNFTName);
    }

    function ticketsSymbol() external view returns (string memory) {
        uint256 raffleId = ticketsToRaffleId[msg.sender];
        return string.concat("GRAFF", raffleId.toString());
    }

    function ticketsTokenURI(uint256 id) external view returns (string memory) {
        uint256 raffleId = ticketsToRaffleId[msg.sender];
        return
            raffles[raffleId].randomSeed != 0
                ? isWinningTicket(raffleId, id) ? winningTicketURI : losingTicketURI
                : ticketURI;
    }

    /* ------------- Owner ------------- */

    function feedToys(
        address prizeNFT,
        uint32[] calldata prizeTokenIds,
        uint40 start,
        uint40 end,
        uint40 ticketPrice,
        uint16 refundRate,
        uint40 maxTicketSupply,
        uint8 requirement
    ) external onlyOwner {
        unchecked {
            for (uint256 i; i < prizeTokenIds.length; ++i)
                IERC721(prizeNFT).transferFrom(msg.sender, address(this), prizeTokenIds[i]);

            uint256 raffleId = ++numRaffles;
            Raffle storage raffle = raffles[raffleId];

            if (ticketsImplementation == address(0)) revert TicketsImplementationUnset();
            if (start < block.timestamp || end <= start || end - start > ONE_MONTH) revert InvalidTimestamps();
            if (ticketPrice >= 1e18) revert InvalidTicketPrice();

            address tickets = createTicketsClone(ticketsImplementation);
            ticketsToRaffleId[tickets] = raffleId;

            raffle.tickets = tickets;
            raffle.prizeNFT = prizeNFT;
            raffle.prizeTokenIds = prizeTokenIds;
            raffle.start = start;
            raffle.end = end;
            raffle.ticketPrice = ticketPrice;
            raffle.refundRate = refundRate;
            raffle.maxTicketSupply = maxTicketSupply;
            raffle.requirement = requirement;

            emit Chachingg();
        }
    }

    function rescueToys(IERC721 toy, uint256[] calldata toyIds) external onlyOwner {
        unchecked {
            for (uint256 i; i < toyIds.length; ++i) toy.transferFrom(address(this), msg.sender, toyIds[i]);
        }
    }

    function cancelRaffle(uint256 raffleId) external onlyOwner {
        unchecked {
            Raffle storage raffle = raffles[raffleId];

            uint256 numToys = raffle.prizeTokenIds.length;

            if (raffle.cancelled) revert RaffleAlreadyCancelled();

            IERC721 prizeNFT = IERC721(raffle.prizeNFT);
            for (uint256 i; i < numToys; ++i) {
                try prizeNFT.transferFrom(address(this), msg.sender, raffles[raffleId].prizeTokenIds[i]) {} catch {}
            }

            raffle.cancelled = true;
        }
    }

    function initiateGrappler(uint256 raffleId) external onlyOwner {
        Raffle storage raffle = raffles[raffleId];

        if (raffle.cancelled) revert RaffleNotActive();
        if (block.timestamp < raffle.end) revert RaffleOngoing();
        if (raffle.randomSeed != 0) revert MachineBeDoinWork();

        emit GrappleGrapple();
        emit BZZzzt();

        raffle.randomSeed = uint40(uint256(blockhash(block.number - 1)));
    }

    function setTicketsImplementation(address ticketsImplementation_) external onlyOwner {
        ticketsImplementation = ticketsImplementation_;
    }

    function setTicketURIs(
        string calldata ticketURI_,
        string calldata losingTicketURI_,
        string calldata winningTicketURI_
    ) external onlyOwner {
        ticketURI = ticketURI_;
        losingTicketURI = losingTicketURI_;
        winningTicketURI = winningTicketURI_;
    }

    /* ------------- Private ------------- */

    // https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
    function createTicketsClone(address target) private returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    /* ------------- Modifier ------------- */

    modifier noContract() {
        if (msg.sender != tx.origin) revert ContractCallNotAllowed();
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Metadata.sol";

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
    function numStaked(address user) external returns (uint256);

    function numOwned(address user) external returns (uint256);

    function balanceOf(address user) external returns (uint256);

    function ownerOf(uint256 tokenId) external returns (address);

    function getLevel(uint256 tokenId) external view returns (uint256);

    function getDNA(uint256 tokenId) external view returns (uint256);
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

import {Gachapon} from "./Gachapon.sol";

error CallerNotOwner();
error CallerNotApproved();
error CallerNotOwnerNorApproved();

error MintExceedsLimit();

error TransferFromIncorrectOwner();
error TransferToNonERC721Receiver();
error TransferToZeroAddress();

error BurnFromIncorrectOwner();

contract SoulboundTickets {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    Gachapon immutable gachapon;

    constructor(Gachapon gachapon_) {
        gachapon = gachapon_;
    }

    /* ------------- View ------------- */

    function tokenURI(uint256 id) external view returns (string memory) {
        return gachapon.ticketsTokenURI(id);
    }

    function name() external view returns (string memory) {
        return gachapon.ticketsName();
    }

    function symbol() external view returns (string memory) {
        return gachapon.ticketsSymbol();
    }

    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* ------------- Restricted ------------- */

    // @note assumes correct handling by master contract in order to save gas
    function mint(address to, uint256 id) external onlyGachapon {
        if (balanceOf[to] == 1) revert MintExceedsLimit();

        ownerOf[id] = to;

        unchecked {
            ++balanceOf[to];
        }

        emit Transfer(address(0), to, id);
    }

    function burnFrom(address from, uint256 id) external onlyGachapon {
        if (ownerOf[id] != from) revert BurnFromIncorrectOwner();

        unchecked {
            --balanceOf[from];
        }

        emit Transfer(from, address(0), id);

        delete ownerOf[id];
    }

    modifier onlyGachapon() {
        if (msg.sender != address(gachapon)) revert CallerNotApproved();
        _;
    }

    /* ------------- O(N) Read Only ------------- */

    function ticketIdOf(address user) external view returns (uint256) {
        unchecked {
            uint256 supply = gachapon.ticketsSupply() + 1;
            for (uint256 id; id < supply; ++id) if (ownerOf[id] == user) return id;
            return 0;
        }
    }
}

contract Tickets {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    Gachapon immutable gachapon;

    constructor(Gachapon gachapon_) {
        gachapon = gachapon_;
    }

    /* ------------- External ------------- */

    function approve(address spender, uint256 id) external virtual {
        address owner = ownerOf[id];

        if ((msg.sender != owner && !isApprovedForAll[owner][msg.sender])) revert CallerNotOwnerNorApproved();

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) external virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (to == address(0)) revert TransferToZeroAddress();

        if (ownerOf[id] != from) revert TransferFromIncorrectOwner();
        if (msg.sender != from && !isApprovedForAll[from][msg.sender] && getApproved[id] != msg.sender)
            revert CallerNotOwnerNorApproved();

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external virtual {
        safeTransferFrom(from, to, id, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            IERC721Receiver(to).onERC721Received(msg.sender, from, id, data) !=
            IERC721Receiver(to).onERC721Received.selector
        ) revert TransferToNonERC721Receiver();
    }

    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* ------------- View ------------- */

    function tokenURI(uint256 id) external view returns (string memory) {
        return gachapon.ticketsTokenURI(id);
    }

    function name() external view returns (string memory) {
        return gachapon.ticketsName();
    }

    function symbol() external view returns (string memory) {
        return gachapon.ticketsSymbol();
    }

    /* ------------- Restricted ------------- */

    function mint(address to, uint256 id) external onlyGachapon {
        if (balanceOf[to] == 1) revert MintExceedsLimit();

        ownerOf[id] = to;

        unchecked {
            ++balanceOf[to];
        }

        emit Transfer(address(0), to, id);
    }

    function burnFrom(address from, uint256 id) external onlyGachapon {
        if (ownerOf[id] != from) revert BurnFromIncorrectOwner();

        unchecked {
            --balanceOf[from];
        }

        emit Transfer(from, address(0), id);

        delete ownerOf[id];
        delete getApproved[id];
    }

    modifier onlyGachapon() {
        if (msg.sender != address(gachapon)) revert CallerNotApproved();
        _;
    }

    /* ------------- O(N) Read Only ------------- */

    function ticketIdOf(address user) external view returns (uint256) {
        unchecked {
            uint256 supply = gachapon.ticketsSupply() + 1;
            for (uint256 id; id < supply; ++id) if (ownerOf[id] == user) return id;
            return 0;
        }
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}