// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Index.sol';


contract QueuesMethods is Params {

    constructor(QueuesConstructor.Struct memory input) Params(input) {}

    function unenqueue(uint256 theId, uint256 hound) external {
        address houndOwner = IHoundOwner(control.hounds).houndOwner(hound);
        require(houndOwner == msg.sender);

        uint256[] memory replacedParticipants = queues[theId].core.participants;
        uint256[] memory replacedEnqueueDates = queues[theId].core.enqueueDates;
        delete queues[theId].core.participants;
        delete queues[theId].core.enqueueDates;

        if ( replacedParticipants.length > 0 ) {
            bool exists;
            for ( uint256 i = 0 ; i < replacedParticipants.length ; ++i ) {
                if ( replacedParticipants[i] == hound ) {
                    exists = true;
                    require(replacedEnqueueDates[i] < block.timestamp - queues[theId].cooldown);
                } else {
                    queues[theId].core.participants.push(replacedParticipants[i]);
                    queues[theId].core.enqueueDates.push(replacedEnqueueDates[i]);
                }
            }
            require(exists);
        }


        require(IUpdateHoundRunning(control.hounds).updateHoundRunning(hound, 0) == theId);

        
        ( , , MicroPayment.Struct memory entryFee) = IEnqueueCost(control.zerocost).enqueueCost(theId);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = entryFee.amount;

        IPay(control.payments).pay(
            control.payments,
            houndOwner,
            entryFee.currency,
            new uint256[](0),
            amounts,
            entryFee.currency == address(0) ? Payment.PaymentTypes.DEFAULT : Payment.PaymentTypes.ERC20
        );

        emit Unenqueue(theId, hound);
    }

    function enqueue(uint256 theId, uint256 hound) external payable {
        require(
            queues[theId].totalParticipants > 0 && !queues[theId].closed && 
            ((queues[theId].endDate == 0 && queues[theId].startDate == 0) || (queues[theId].startDate <= block.timestamp && queues[theId].endDate >= block.timestamp)) && 
            IAllowance(control.hounds).allowance(msg.sender, hound) && 
            queues[theId].lastCompletion < block.timestamp - queues[theId].cooldown
        );

        HoundIdentity.Struct memory identity = IGetIdentity(control.incubator).getIdentity(hound);
        bool validSpecie;
        for ( uint256 i = 0 ; i < queues[theId].speciesAllowed.length ; ++i ) {
            if ( queues[theId].speciesAllowed[i] == identity.specie ) {
                validSpecie = true;
                break;
            }
        }
        require(validSpecie);

        for ( uint256 i = 0 ; i < queues[theId].core.participants.length ; ++i ) {
            require(queues[theId].core.participants[i] != hound);
        }

        queues[theId].core.participants.push(hound);
        queues[theId].core.enqueueDates.push(block.timestamp);

        require(IUpdateHoundRunning(control.hounds).updateHoundRunning(hound, theId) == 0);

        address arenaCurrency = IArenaCurrency(control.arenas).arenaCurrency(queues[theId].core.arena);

        (
            MicroPayment.Struct memory alphaduneFee, 
            MicroPayment.Struct memory arenaFee, 
            MicroPayment.Struct memory entryFee
        ) = IEnqueueCost(control.zerocost).enqueueCost(theId);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = alphaduneFee.amount;

        IPay(control.payments).pay{
            value: alphaduneFee.currency == address(0) ? alphaduneFee.amount : 0
        }(
            msg.sender,
            control.payments,
            alphaduneFee.currency,
            new uint256[](0),
            amounts,
            arenaCurrency == address(0) ? Payment.PaymentTypes.DEFAULT : Payment.PaymentTypes.ERC20
        );

        amounts[0] = arenaFee.amount;
        IPay(control.payments).pay{
            value: arenaFee.currency == address(0) ? arenaFee.amount : 0
        }(
            msg.sender,
            control.payments,
            arenaFee.currency,
            new uint256[](0),
            amounts,
            arenaCurrency == address(0) ? Payment.PaymentTypes.DEFAULT : Payment.PaymentTypes.ERC20
        );

        amounts[0] = entryFee.amount;
        IPay(control.payments).pay{
            value: entryFee.currency == address(0) ? entryFee.amount : 0
        }(
            msg.sender,
            control.payments,
            entryFee.currency,
            new uint256[](0),
            amounts,
            arenaCurrency == address(0) ? Payment.PaymentTypes.DEFAULT : Payment.PaymentTypes.ERC20
        );


        if ( queues[theId].core.participants.length == queues[theId].totalParticipants ) {

            IRaceStart(control.races).raceStart(theId, queues[theId]);

            delete queues[theId].core.participants;
            delete queues[theId].core.enqueueDates;

            queues[theId].lastCompletion = block.timestamp;

        }
    
        emit PlayerEnqueue(theId,hound,msg.sender);

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Queue.sol';
import './Constructor.sol';
import '../../arenas/params/Arena.sol';
import '../../arenas/interfaces/IArena.sol';
import '../../arenas/interfaces/IArenaOwner.sol';
import '../../arenas/interfaces/IArenaFee.sol';
import '../../arenas/interfaces/IArenaCurrency.sol';
import '../../utils/Converters.sol';
import '../../payments/interfaces/IPay.sol';
import '../../payments/params/MicroPayment.sol';
import '../../hounds/interfaces/IUpdateHoundRunning.sol';
import '../../hounds/interfaces/IHoundOwner.sol';
import '../../hounds/interfaces/IHound.sol';
import '../../utils/Withdrawable.sol';
import '../../races/interfaces/IRaceStart.sol';
import '../../hounds/params/Hound.sol';
import '../interfaces/IEnqueueCost.sol';
import '../../incubator/interfaces/IGetIdentity.sol';
import '../../hounds/interfaces/IAllowance.sol';


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

    function staminaCostOf(uint256 theId) external view returns(uint32) {
        return queues[theId].staminaCost;
    }

    function handleAllowedCallers(address[] memory allowedCallers) internal {
        for ( uint256 i = 0 ; i < allowedCallers.length ; ++i ) {
            allowed[allowedCallers[i]] = !allowed[allowedCallers[i]];
        }
    }

    function participantsOf(uint256 theId) external view returns(uint256[] memory) {
        return queues[theId].core.participants;
    }

    function enqueueDatesOf(uint256 theId) external view returns(uint256[] memory) {
        return queues[theId].core.enqueueDates;
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

library QueuesConstructor {
    struct Struct {

        // Contract modules
        address methods;
        address restricted;
        address queues;
        address zerocost;

        // External dependencies
        address arenas;
        address hounds;
        address payments;
        address races;
        address incubator;
        
        // Whitelist boilerplate
        address[] allowedCallers;
    }
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


interface IArenaOwner {

    function arenaOwner(uint256 tokenId) external view returns(address);
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Arena.sol';


interface IArenaFee {
    
    function arenaFee(uint256 theId) external view returns(uint256);
    
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
import '../params/Payment.sol';

interface IPay {

	function pay(
		address from,
        address to,
        address currency,
        uint256[] memory ids, // for batch transfers
        uint256[] memory amounts, // for batch transfers
        Payment.PaymentTypes paymentType
	) external payable;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library MicroPayment {
    
    struct Struct {
        address currency;
        uint256 amount;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IUpdateHoundRunning {

    function updateHoundRunning(uint256 theId, uint256 queueId) external returns(uint256 oldQueueId);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IHoundOwner {

    function houndOwner(uint256 tokenId) external view returns(address);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/Hound.sol';


interface IHound {

    function hound(uint256 theId) external view returns(Hound.Struct memory);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Withdrawable is Ownable {

    function payout(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Payout: Requested amount to withdraw is too big");
        require(payable(owner()).send(amount), "Payout: Failed to withdraw");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../queues/params/Queue.sol';


interface IRaceStart {

    function raceStart(
        uint256 queueId,
        Queue.Struct memory queue
    ) external;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../../payments/params/MicroPayment.sol';

interface IEnqueueCost {

    function enqueueCost(uint256 theId) external view returns(
        MicroPayment.Struct memory, 
        MicroPayment.Struct memory, 
        MicroPayment.Struct memory
    );

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '../params/HoundIdentity.sol';


interface IGetIdentity {

    function getIdentity(uint256 theId) external view returns(HoundIdentity.Struct memory);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IAllowance {

    function allowance(address sender, uint256 tokenId) external view returns(bool);

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