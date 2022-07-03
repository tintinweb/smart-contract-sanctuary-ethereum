// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import '../params/Index.sol';


contract QueuesRestricted is Params {

    constructor(QueuesConstructor.Struct memory input) Params(input) {}

    function createQueues(Queue.Struct[] memory theQueues) external {
        Arena.Struct memory arena;
        for ( uint256 i = 0 ; i < theQueues.length ; ++i ) {
            arena = IArena(control.arenas).arena(theQueues[i].arena);
            require(arena.fee < theQueues[i].entryFee / 2);
            require(arena.feeCurrency == theQueues[i].currency);
            require(theQueues[i].payments.from.length > 0);

            queues[id] = theQueues[i];
            ++id;
        }

        emit QueuesCreation(id-theQueues.length,id-1,theQueues);
    }

    function editQueue(uint256 theId, Queue.Struct memory queue) external {
        Arena.Struct memory arena = IArena(control.arenas).arena(queue.arena);
        require(arena.fee < queue.entryFee / 2);
        queues[theId] = queue;
        emit EditQueue(theId,queues[theId]);
    }

    function closeQueue(uint256 theId) external {
        queues[theId].closed = true;
        emit QueueClosed(theId);
    }

    function deleteQueue(uint256 theId) external {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = queues[theId].entryFee;

        for ( uint256 i = 0; i < queues[theId].participants.length; ++i ) {
            if ( queues[theId].participants[i] > 0 ) {
                require(IUpdateHoundRunning(control.hounds).updateHoundRunning(queues[theId].participants[i], theId) != 0);
                address houndOwner = IHoundOwner(control.hounds).houndOwner(queues[theId].participants[i]);

                IPay(control.payments).pay{
                    value: queues[theId].currency == address(0) ? queues[theId].entryFee : 0
                }(
                    address(this),
                    houndOwner,
                    queues[theId].currency,
                    new uint256[](0),
                    amounts,
                    queues[theId].currency == address(0) ? 3 : 2
                );
            }
        }
        delete queues[theId];
        emit DeleteQueue(theId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Queue.sol';
import './Constructor.sol';
import '../../arenas/params/Arena.sol';
import '../../arenas/interfaces/IArena.sol';
import '../../arenas/interfaces/IArenaOwner.sol';
import '../../utils/Converters.sol';
import '../../payments/interfaces/IPay.sol';
import '../../hounds/interfaces/IUpdateHoundStamina.sol';
import '../../hounds/interfaces/IUpdateHoundRunning.sol';
import '../../hounds/interfaces/IHoundOwner.sol';
import '../../hounds/interfaces/IHound.sol';
import '../../utils/Withdrawable.sol';
import '../../races/interfaces/IRaceStart.sol';
import '../../hounds/params/Hound.sol';


contract Params is Ownable, Withdrawable {
    
    event QueuesCreation(uint256 indexed idStart, uint256 indexed idStop, Queue.Struct[] newQueues);
    event DeleteQueue(uint256 indexed id);
    event PlayerEnqueue(uint256 indexed id, uint256 indexed hound, address indexed player);
    event EditQueue(uint256 indexed id, Queue.Struct queue);
    event QueueClosed(uint256 indexed id);
    event Unenqueue(uint256 indexed id, uint256 indexed hound);

    uint256 public id = 1;
    QueuesConstructor.Struct public control;
    mapping(uint256 => Queue.Struct) public queues;
    mapping(address => bool) public allowed;

    constructor(QueuesConstructor.Struct memory input) {
        control = input;
        handleAllowedCallers(input.allowedCallers);
    }

    function setGlobalParameters(QueuesConstructor.Struct memory globalParameters) external onlyOwner {
        control = globalParameters;
        handleAllowedCallers(globalParameters.allowedCallers);
    }
    
    function queue(uint256 theId) external view returns(Queue.Struct memory) {
        return queues[theId];
    }

    function enqueueCost(uint256 theId) public view returns(uint256) {
        return IArena(control.arenas).arena(queues[theId].arena).fee / queues[theId].totalParticipants + queues[theId].entryFee + 1;
    }

    function handleAllowedCallers(address[] memory allowedCallers) internal {
        for ( uint256 i = 0 ; i < allowedCallers.length ; ++i ) {
            allowed[allowedCallers[i]] = !allowed[allowedCallers[i]];
        }
    }

    function participantsOf(uint256 theId) external view returns(uint256[] memory) {
        return queues[theId].participants;
    }

    fallback() external payable {}
    receive() external payable {}

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.15;
import '../../payments/params/Payment.sol';

library Queue {
    
    struct Struct {

        string name;

        address currency;

        uint256[] participants;

        uint256 arena;

        uint256 entryFee;

        uint256 startDate;

        uint256 endDate;

        Payment.Struct payments;

        uint32 totalParticipants;

        bool closed;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.15;

library QueuesConstructor {
    struct Struct {
        address arenas;
        address hounds;
        address methods;
        address payments;
        address restricted;
        address races;
        address[] allowedCallers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.15;


library Arena {
    
    struct Struct {
        string name;
        string token_uri;
        address feeCurrency;
        uint256 fee;
        uint32 surface;
        uint32 distance;
        uint32 weather;
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import '../params/Arena.sol';


interface IArena {
    
    function arena(uint256 theId) external view returns(Arena.Struct memory);
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


interface IArenaOwner {

    function arenaOwner(uint256 tokenId) external view returns(address);
    
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.15;
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
pragma solidity 0.8.15;


interface IPay {

	function pay(
		address from,
        address to,
        address currency,
        uint256[] memory id, // for batch transfers
        uint256[] memory amount, // for batch transfers
        uint32 paymentType
	) external payable;

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


interface IUpdateHoundStamina {

    function updateHoundStamina(uint256 theId) external;

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


interface IUpdateHoundRunning {

    function updateHoundRunning(uint256 theId, uint256 queueId) external returns(uint256 oldQueueId);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


interface IHoundOwner {

    function houndOwner(uint256 tokenId) external view returns(address);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import '../params/Hound.sol';


interface IHound {

    function hound(uint256 theId) external view returns(Hound.Struct memory);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Withdrawable is Ownable {

    function payout(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Payout: Requested amount to withdraw is too big");
        require(payable(owner()).send(amount), "Payout: Failed to withdraw");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import '../../queues/params/Queue.sol';


interface IRaceStart {

    function raceStart(Queue.Struct memory queue, uint256 theId) external;

}

//SPDX-License-Identifier: MIT
pragma solidity <=0.8.15;

library Hound {

    struct Breeding {
        uint256 lastBreed;
        uint256 breedingCooldown;
        address breedingFeeCurrency;
        uint256 breedingFee;
        uint256 secondsToMaturity;
        uint256 breedingPeriod;
        uint256 breedingStart;
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
        address staminaRefill1xCurrency;
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
        uint256 queueId;
        bool custom;
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
pragma solidity <=0.8.15;


library Payment {
    
    struct Struct {
        address[] from;
        address[] to;
        address[] currency;
        uint256[][] ids;
        uint256[][] amounts;
        uint32[] paymentType;
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