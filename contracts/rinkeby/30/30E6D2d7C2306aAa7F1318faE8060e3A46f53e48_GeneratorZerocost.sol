// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Index.sol';


contract GeneratorZerocost is Params {

    constructor(GeneratorConstructor.Struct memory input) Params(input) {}

    function computeHoundsStats(
        uint256[] memory participants, 
        Arena.Struct memory terrain
    ) 
        internal 
        view 
    returns(
        uint256[] memory
    ) {

        uint256[] memory stats = new uint256[](participants.length);
        HoundIdentity.Struct memory identity;
        HoundStamina.Struct memory stamina;

        for ( uint256 i = 0 ; i < participants.length ; ++i ) {

            identity = IGetIdentity(control.incubator).getIdentity(participants[i]);
            stamina = IGetStamina(control.gamification).getStamina(participants[i]);

            stats[i] = uint256((identity.geneticSequence[30] + identity.geneticSequence[31] + identity.geneticSequence[32] + identity.geneticSequence[33]) * 99);
            uint256 tmp = stats[i];

            if ( identity.geneticSequence[9] == terrain.surface )
                stats[i] += tmp / 20;
            if ( identity.geneticSequence[10] == terrain.distance )
                stats[i] += tmp / 20;
            if ( identity.geneticSequence[11] == terrain.weather )
                stats[i] += tmp / 20;

            if ( stamina.staminaCap / 2 > stamina.staminaValue )
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
        
        Arena.Struct memory theTerrain = IArena(control.arenas).arena(terrain);
        
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

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/access/Ownable.sol';
import './Constructor.sol';
import '../interfaces/ISimulateClassicRace.sol';
import '../../queues/params/Queue.sol';
import '../../races/params/Race.sol';
import '../../hounds/interfaces/IHound.sol';
import '../../randomness/IGetRandomNumber.sol';
import '../../arenas/params/Arena.sol';
import '../../arenas/interfaces/IArena.sol';
import '../../arenas/interfaces/IArenaCurrency.sol';
import '../../utils/Converters.sol';
import '../../utils/Sortings.sol';
import '../../incubator/params/HoundIdentity.sol';
import '../../incubator/interfaces/IGetIdentity.sol';
import '../../gamification/params/HoundStamina.sol';
import '../../gamification/interfaces/IGetStamina.sol';
import '../../queues/params/Core.sol';


contract Params is Ownable {

    GeneratorConstructor.Struct public control;

    constructor(GeneratorConstructor.Struct memory input) {
        control = input;
    }

    function setGlobalParameters(GeneratorConstructor.Struct memory globalParameters) external onlyOwner {
        control = globalParameters;
    }

    fallback() external payable {}
    receive() external payable {}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity 0.8.17;


library GeneratorConstructor {
    
    struct Struct {
        address randomness;
        address arenas;
        address hounds;
        address allowed;
        address methods;
        address payments;
        address zerocost;
        address incubator;
        address gamification;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface ISimulateClassicRace {

    function simulateClassicRace(uint256[] memory participants, uint256 terrain, uint256 theRandomness) external view returns(uint256[] memory, uint256[] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../payments/params/Payment.sol';
import './Core.sol';
import '../../incubator/params/Specie.sol';

library Queue {
    
    struct Struct {

        Core.Struct core;

        uint256 startDate;

        uint256 endDate;

        uint256 lastCompletion;

        uint32 totalParticipants;

        uint32 cooldown;

        uint32 staminaCost;

        Specie.Enum[] speciesAllowed;

        bool closed;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../payments/params/Payment.sol';
import '../../queues/params/Core.sol';

library Race {
    
    struct Struct {

        Core.Struct core;

        uint256 randomness;

        uint256 queueId;

        bytes seed;

    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Hound.sol';


interface IHound {

    function hound(uint256 theId) external view returns(Hound.Struct memory);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IGetRandomNumber {

    function getRandomNumber(bytes memory input) external view returns(uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library Arena {
    
    struct Struct {
        string name;
        string token_uri;

        address currency;
        uint256 fee;
        
        uint32 surface;
        uint32 distance;
        uint32 weather;
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Arena.sol';


interface IArena {
    
    function arena(uint256 theId) external view returns(Arena.Struct memory);
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Arena.sol';


interface IArenaCurrency {
    
    function arenaCurrency(uint256 theId) external view returns(address);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
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
pragma solidity 0.8.17;


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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './Specie.sol';

library HoundIdentity {

    struct Struct {
        uint256 maleParent;
        uint256 femaleParent;
        uint256 generation;
        uint256 birthDate;
        uint32[54] geneticSequence;
        string extensionTraits;
        Specie.Enum specie;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/HoundIdentity.sol';


interface IGetIdentity {

    function getIdentity(uint256 theId) external view returns(HoundIdentity.Struct memory);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library HoundStamina {

    struct Struct {
        address staminaRefillCurrency;
        uint256 staminaLastUpdate;
        uint256 staminaRefill1x;
        uint256 refillStaminaCooldownCost;
        uint32 staminaValue;
        uint32 staminaPerTimeUnit;
        uint32 staminaCap;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/HoundStamina.sol';


interface IGetStamina {

    function getStamina(uint256 id) external view returns(HoundStamina.Struct memory);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../payments/params/Payment.sol';

library Core {
    
    struct Struct {

        string name;

        address feeCurrency;

        address entryFeeCurrency;

        uint256[] participants;

        uint256[] enqueueDates;

        uint256 arena;

        uint256 entryFee;

        uint256 fee;

        Payment.Struct payments;

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
pragma solidity 0.8.17;


library Payment {

    enum PaymentTypes {
        ERC721,
        ERC1155,
        ERC20,
        DEFAULT
    }
    
    struct Struct {
        address[] from;
        address[] to;
        address[] currency;
        uint256[][] ids;
        uint256[][] amounts;
        PaymentTypes[] paymentType;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library Specie {
    enum Enum {
        FREE_HOUND,
        NORMAL,
        CHAD,
        RACER,
        COMMUNITY,
        SPEC_OPS,
        PRIME
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../incubator/params/HoundIdentity.sol';
import '../../gamification/params/HoundBreeding.sol';
import '../../gamification/params/HoundStamina.sol';
import '../../races/params/HoundStatistics.sol';
import './HoundProfile.sol';


library Hound {
    struct Struct {
        HoundStatistics.Struct statistics;
        HoundStamina.Struct stamina;
        HoundBreeding.Struct breeding;
        HoundIdentity.Struct identity;
        HoundProfile.Struct profile;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library HoundBreeding {

    struct Struct {
        address breedingFeeCurrency;
        address breedingCooldownCurrency;
        uint256 lastBreed;
        uint256 breedingCooldown;
        uint256 breedingFee;
        uint256 breedingCooldownTimeUnit;
        uint256 refillBreedingCooldownCost;
        bool availableToBreed;
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library HoundStatistics {

    struct Struct {
        uint64 totalRuns;
        uint64 firstPlace;
        uint64 secondPlace;
        uint64 thirdPlace;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library HoundProfile {
    struct Struct {
        string name;
        string token_uri;
        uint256 queueId;
        bool custom;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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