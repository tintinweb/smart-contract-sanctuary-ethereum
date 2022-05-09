// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import './params/Index.sol';


contract Generator is Params {

    constructor(GeneratorConstructor.Struct memory input) Params(input) {}

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
        return IGeneratorZerocost(control.zerocost).simulateClassicRace(participants, terrain, theRandomness);
    }

    function generate(Queue.Struct memory queue) external payable returns(Race.Struct memory) {
        (bool success, bytes memory output) = control.methods.delegatecall(msg.data);
        require(success);
        return abi.decode(output,(Race.Struct));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import '@openzeppelin/contracts/access/Ownable.sol';
import './Constructor.sol';
import '../IIndex.sol';
import '../../queues/params/Queue.sol';
import '../../races/params/Race.sol';
import '../../hounds/IIndex.sol';
import '../../randomness/IIndex.sol';
import '../../arenas/params/Arena.sol';
import '../../arenas/IIndex.sol';
import '../../payments/IIndex.sol';
import '../../utils/Converters.sol';
import '../../utils/Sortings.sol';
import '../zerocost/IIndex.sol';


contract Params is Ownable {

    event NewRace(Queue.Struct queue, Race.Struct race);
    GeneratorConstructor.Struct public control;

    constructor(GeneratorConstructor.Struct memory input) {
        control = input;
    }

    function setGlobalParameters(GeneratorConstructor.Struct memory globalParameters) external onlyOwner {
        control = globalParameters;
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
pragma solidity <=0.8.13;


library GeneratorConstructor {
    
    struct Struct {
        address randomness;
        address arenas;
        address hounds;
        address allowed;
        address methods;
        address payments;
        address zerocost;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import '../hounds/params/Hound.sol';
import '../queues/params/Queue.sol';
import '../races/params/Race.sol';


interface IGenerator {

    function simulateClassicRace(uint256[] memory participants, uint256 terrain, uint256 theRandomness) external view returns(uint256[] memory, uint256[] memory);

    function generate(Queue.Struct memory queue) external returns(Race.Struct memory);

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.13;


library Queue {
    
    struct Struct {

        string name;

        address currency;

        uint256[] participants;

        uint256 arena;

        uint256 entryFee;

        uint256 startDate;

        uint256 endDate;

        // Informations about the winners of the race
        uint256 rewardsId;

        uint32 totalParticipants;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.13;


library Race {
    
    struct Struct {

        string name;

        address currency;

        uint256[] participants;

        uint256 arena;

        uint256 entryFee;

        // Informations about the winners of the race
        uint256 rewardsId;

        uint256 randomness;

        bytes seed;

    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import './params/Hound.sol';


interface IHounds {

    function initializeHound(uint256 onId, Hound.Struct memory theHound) external;

    function setTokenURI(uint256 _tokenId, string memory token_uri) external;

    function breedHounds(uint256 hound1, uint256 hound2) external payable;

    function updateHoundStamina(uint256 theId) external;

    function updateHoundBreeding(uint256 theId) external;

    function boostHoundStamina(uint256 theId, address user) external payable;

    function boostHoundBreeding(uint256 theId, address user) external payable;

    function putHoundForBreed(uint256 theId, uint256 fee, bool status) external;

    function hound(uint256 theId) external view returns(Hound.Struct memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function houndOwner(uint256 tokenId) external view returns(address);

    function getBreedCost(uint256 hound1, uint256 hound2) external view returns(uint256);

    function updateHoundRunning(uint256 theId, bool running) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


interface IRandomness {

    function getRandomNumber(bytes memory input) external view returns(uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.13;


library Arena {
    
    struct Struct {
        string name;
        string token_uri;
        uint256 fee;
        uint32 surface;
        uint32 distance;
        uint32 weather;
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import './params/Arena.sol';
import './params/Constructor.sol';


interface IArenas {

    function createArena(Arena.Struct memory arena) external;
    
    function editArena(uint256 theId, Arena.Struct memory arena) external;

    function setTokenUri(uint256 theId, string memory token_uri) external;

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function setGlobalParameters(ArenasConstructor.Struct memory globalParameters) external;
    
    function arena(uint256 theId) external view returns(Arena.Struct memory);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import './params/PaymentRequest.sol';
import './params/Payment.sol';


interface IPayments {

	function transferTokens(Payment.Struct memory payment) external payable;

	function addPayments(uint256 queueId, Payment.Struct[] memory thePayments) external;

	function setPayments(uint256 queueId, Payment.Struct[] memory thePayments) external;

	function sendPayments(PaymentRequest.Struct memory paymentRequest) external payable;

	function sendHardcodedPayments(Payment.Struct[] memory payments) external payable;

	function rawSend(address token, uint256 amount, address to) external;

	function getPayments(uint256 batchId) external view returns(Payment.Struct[] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.13;
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
pragma solidity <=0.8.13;


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
pragma solidity 0.8.13;


interface IGeneratorZerocost {

    function simulateClassicRace(
        uint256[] memory participants, 
        uint256 terrain, 
        uint256 theRandomness
    ) 
        external 
        view 
    returns(
        uint256[] memory, 
        uint256[] memory
    );

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

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.13;

library Hound {

    struct Breeding {
        uint256 breedCooldown;
        uint256 breedingFee;
        uint256 breedLastUpdate;
        bool availableToBreed;
    }

    struct Identity {
        uint256 maleParent;
        uint256 femaleParent;
        uint256 generation;
        uint256 birthDate;
        uint32[54] geneticSequence;
    }

    struct Stamina {
        uint256 staminaLastUpdate;
        uint256 staminaRefill1x;
        uint32 staminaValue;
        uint32 staminaPerHour;
        uint32 staminaCap;
    }

    struct Statistics {
        uint64 totalRuns;
        uint64 firstPlace;
        uint64 secondPlace;
        uint64 thirdPlace;
    }

    struct Struct {
        Statistics statistics;
        Stamina stamina;
        Breeding breeding;
        Identity identity;
        string title;
        string token_uri;
        bool custom;
        bool running;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.13;


library ArenasConstructor {
    struct Struct {
        string name;
        string symbol;
        address restricted;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.13;


library PaymentRequest {
    
    struct Struct {
        uint256 rewardsBatch;
        address[] receivers;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.13;


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
        // 3 - erc20 race winner
        // 4 - erc20 fee
        uint32 paymentType;
        uint32 percentageWon;
        uint32 place;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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