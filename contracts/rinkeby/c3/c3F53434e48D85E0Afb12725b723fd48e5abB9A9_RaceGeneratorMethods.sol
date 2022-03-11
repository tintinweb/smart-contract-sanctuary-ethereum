// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import '@openzeppelin/contracts/access/Ownable.sol';
import '../../utils/Sortings.sol';
import '../../utils/Converters.sol';
import '../../arenas/Arena.sol';
import '../../hounds/Hound.sol';
import '../../hounds/IData.sol';
import '../../arenas/IData.sol';
import '../../randomness/vanilla/IData.sol';
import '../../payments/PaymentRequest.sol';
import '../races/Race.sol';
import '../races/Queue.sol';
import './Constructor.sol';


contract RaceGeneratorMethods is Ownable {

    event NewRace(Queue.Struct queue, Race.Struct race);
    Constructor.Struct public control;
    string error = "Failed to delegatecall";
    IHoundsData public houndsContract;

    function setGlobalParameters(
        Constructor.Struct memory input
    ) external onlyOwner {
        control = input;
        houndsContract = IHoundsData(control.hounds);
    }

    function computeHoundsStats(uint256[] memory participants, Arena.Struct memory terrain) internal view returns(uint256[] memory) {

        uint256[] memory stats = new uint256[](participants.length);

        Hound.Struct memory hound;

        for ( uint256 i = 0 ; i < participants.length ; ++i ) {

            hound = IHoundsData(control.hounds).hound(participants[i]);

            stats[i] = uint256((hound.identity.geneticSequence[30] + hound.identity.geneticSequence[31] + hound.identity.geneticSequence[32] + hound.identity.geneticSequence[33]) * 99);
            uint256 tmp = stats[i];

            if ( hound.identity.geneticSequence[9] == terrain.surface )
                stats[i] += tmp / 20;
            if ( hound.identity.geneticSequence[10] == terrain.distance )
                stats[i] += tmp / 20;
            if ( hound.identity.geneticSequence[11] == terrain.weather )
                stats[i] += tmp / 20;

            if ( hound.stamina.staminaCap / 2 > hound.stamina.stamina )
                stats[i] = stats[i] * 90 / 100;

        }

        return stats;

    }

    function simulateClassicRace(
        uint256[] memory participants, 
        uint256 terrain, 
        uint256 theRandomness
    ) 
        public 
        view 
    returns(
        uint256[] memory, 
        uint256[] memory
    ) {
        
        Arena.Struct memory theTerrain = IArenas(control.terrains).arena(terrain);
        
        uint256[] memory houndsPower = computeHoundsStats(participants, theTerrain);
        
        uint256 variation = uint256(keccak256(abi.encode(theRandomness, block.difficulty))) % 15;

        for ( uint256 j = 0 ; j < houndsPower.length ; ++j ) 
            houndsPower[j] = houndsPower[j] + ( ( houndsPower[j] * variation ) / 100 );
        
        return Sortings.rankPlayers(
            houndsPower,
            participants,
            0,
            houndsPower.length-1
        );

    }

    function generate(Queue.Struct memory queue) external payable returns(Race.Struct memory race) {

        require(control.allowed == msg.sender, "23");
        
        require(queue.participants.length == queue.totalParticipants, "19");

        require(queue.entryFee <= msg.value, "17");

        uint256 theRandomness = IRandomnessVanillaData(control.randomness).getRandomNumber(abi.encode(block.timestamp));

        (, uint256[] memory participants) = simulateClassicRace(queue.participants,queue.arena,theRandomness);

        (bool success, ) = control.payments.delegatecall(
            abi.encodeWithSignature(
                "compoundTransfer((uint256,address[]))",
                PaymentRequest.Struct(
                    queue.rewardsId,
                    Converters.erc721IdsToOwners(control.hounds,participants)
                )
            )
        );
        require(success,"Failed to createLoan via delegatecall");
    
        race = Race.Struct(
            queue.currency,
            participants,
            queue.arena,
            queue.entryFee,
            queue.rewardsId,
            theRandomness,
            abi.encode(participants)
        );

        emit NewRace(queue,race);

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;


library Sortings {

    // @DIIMIIM: quick sort algorithm
    function rankPlayers(
        uint256[] memory power, 
        uint256[] memory players, 
        uint256 left, 
        uint256 right
    ) 
        public 
        pure 
    returns(
        uint256[] memory, 
        uint256[] memory
    ) {
        uint256 i = left;
        uint256 j = right;
        if (i == j) return (players,power);
        uint256 pivot = power[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (power[uint(i)] > pivot) i++;
            while (pivot > power[uint(j)]) j--;
            if (i <= j) {
                (power[uint(i)], power[uint(j)]) = (power[uint(j)], power[uint(i)]);
                (players[uint(i)], players[uint(j)]) = (players[uint(j)], players[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            rankPlayers(power, players, left, j);
        if (i < right)
            rankPlayers(power, players, i, right);
        return (players,power);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

library Converters {

    // @DIIMIIM: quick sort algorithm
    function erc721IdsToOwners(
        address erc721Contract,
        uint256[] memory ids
    ) 
        public 
        view 
    returns(
        address[] memory
    ) {
        address[] memory owners = new address[](ids.length);
        IERC721 contractToCall = IERC721(erc721Contract);
        for ( uint256 i = 0 ; i < ids.length ; ++i ) {
            owners[i] = contractToCall.ownerOf(ids[i]);
        }
        return owners;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;


library Arena {
    
    struct Struct {
        address owner;
        uint256 fee;
        uint32 surface;
        uint32 distance;
        uint32 weather;
    }

    struct Wrapped {
        uint256 id;
        Struct arena;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;
import './Statistics.sol';
import './Stamina.sol';
import './Breeding.sol';
import './Identity.sol';

library Hound {
    struct Struct {
        Statistics.Struct statistics;
        Stamina.Struct stamina;
        Breeding.Struct breeding;
        Identity.Struct identity;
        string title;
        string token_url;
        bool custom;
        bool running;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;
import './GlobalVariables.sol';
import './Hound.sol';

interface IHoundsData {
    function setGlobalParameters(GlobalVariables.Struct memory input) external;
    function adminCreateHound(Hound.Struct memory theHounds) external;
    function breedHounds(uint256 hound1, uint256 hound2) external payable;
    function updateHoundStamina(uint256 theId) external;
    function updateHoundBreeding(uint256 theId, uint256 breedingCooldownToConsume) external;
    function putHoundForBreed(uint256 _hound, uint256 fee, bool status) external;
    function hound(uint256 theId) external view returns(Hound.Struct memory);
    function ownerOf(uint256 tokenId) external view returns(address);
    function handleHoundTransfer(uint256 theId, address from, address to) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenURI(uint256 _tokenId) external view returns(string memory);
    function setTokenURI(uint256 _tokenId, string memory token_url) external;
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;

import './Arena.sol';


interface IArenas {
    function createArena(Arena.Struct memory arena) external;
    function editArena(uint256 theId, Arena.Struct memory arena) external;
    function arena(uint256 theId) external view returns(Arena.Struct memory);
    function ownerOf(uint256 tokenId) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;


interface IRandomnessVanillaData {
    function getRandomNumber(bytes memory input) external view returns(uint256);
    function setGlobalParameters(address methods) external;
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;


library PaymentRequest {
    
    struct Struct {
        uint256 rewardsBatch;
        address[] receivers;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;
import '../../payments/Payment.sol';

library Race {
    
    struct Struct {

        // address(0) for ETH
        address currency;

        // Race seed
        uint256[] participants;

        // arena of the race
        uint256 arena;

        // ETH based
        uint256 entryFee;

        // Informations about the winners of the race
        uint256 rewardsId;

        // Race randomness
        uint256 randomness;

        // Race seed
        bytes seed;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;
import '../../payments/Payment.sol';

library Queue {
    
    /**
     * DIIMIIM:
     * Participants can pay with multiple currencies, ETH included
     */
    struct Struct {

        // address(0) for ETH
        address currency;

        // Participants
        // totalParticipants will be the array length here
        uint256[] participants;

        // arena of the race
        uint256 arena;

        // ETH based
        uint256 entryFee;

        // Start date
        uint256 startDate;

        // End date
        uint256 endDate;

        // Informations about the winners of the race
        uint256 rewardsId;

        // Total number of participants
        uint32 totalParticipants;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;


library Constructor {
    
    struct Struct {
        address randomness;
        address terrains;
        address hounds;
        address allowed;
        address methods;
        address payments;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
pragma solidity <=0.8.12;

library Statistics {
    struct Struct {
        uint64 totalRuns;
        uint64 firstPlace;
        uint64 secondPlace;
        uint64 thirdPlace;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;

library Stamina {
    struct Struct {
        uint256 lastUpdate;
        uint256 staminaRefill1x;
        uint32 stamina;
        uint32 staminaPerHour;
        uint32 staminaCap;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;

library Breeding {
    struct Struct {
        uint256 breedCooldown;
        uint256 breedingFee;
        uint256 lastUpdate;
        bool availableToBreed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;

library Identity {
    struct Struct {
        uint256 maleParent;
        uint256 femaleParent;
        uint256 generation;
        uint32[54] geneticSequence;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;

library GlobalVariables {
    struct Struct {
        address[] allowedCallers;
        address methods;
        address incubator;
        address staterApi;
        address shop;
        address payments;
        uint256 breedCost;
        uint256 breedFee;
        uint256 refillCost;
        uint256 refillBreedingCooldownCost;
        uint256 refillStaminaCooldownCost;
        bool[] isAllowed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.12;


library Payment {
    
    struct Struct {
        address from;
        address payable to;
        address currency;
        uint256[] tokenIds;
        uint256 qty;
        // 0 - erc721
        // 1 - erc1155
        // 2 - erc20
        uint32 paymentType;
    }

}