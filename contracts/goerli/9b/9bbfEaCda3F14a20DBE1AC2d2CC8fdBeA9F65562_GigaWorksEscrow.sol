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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GigaWorksEscrow is Ownable {
    //using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter public totalEscrows;
    Counters.Counter public closedEscrows;
    Counters.Counter public disputedEscrows;

    address payable public Arbitrator;
    uint256 public totalVolume;

    constructor() {
        Arbitrator = payable(msg.sender);
    }

    modifier onlyArbitrator() {
        require(msg.sender == Arbitrator, "Only Arbitrator can call this method");
        _;
        }

    // enum removed awaiting payment...
    enum EscrowStatus { 
            AWAITING_DELIVERY, 
            CLOSED,
            DISPUTED
        }

    mapping(address => uint256[]) public addressToEscrow;
    // mapping(address => uint256) public addressToEscrow;
    mapping(uint256 => Escrow) public idToEscrow;

    struct Escrow {
        uint256 escrowID;
        address payable buyer;
        address payable seller;
        uint256 amount;
        EscrowStatus status;
        //IERC20 token;
    }

// function to retrieve escrows of an address

    function getEscrowIdsOfAddress(address user) public view returns (uint256[] memory) {
        return addressToEscrow[user];
    }
    
// function to retrieve escrow by Id - NOT NEEDED BECAUSE STRUCT IS PUBLIC

    // function getEscrowsById(uint256 escrowId) public view returns (Escrow memory) {
    //     return idToEscrow[escrowId];
    // }

    // events for created, closed, and disputed. add erc20 to events when added

    event Action(
        string actionType,
        uint256 escrowID,
        address buyer,
        address seller,
        uint256 amount,
        EscrowStatus status
    );

    uint256 closingFee = 15; // 15% of transaction value. 1500 basis points = 15%

    function updateClosingFee(uint _closingFee) public onlyArbitrator {
      closingFee = _closingFee;
    }

    function getClosingFee() public view returns (uint256) {
      return closingFee;
    }

// buyer confirms check out to send $ and create escrow 

    function createEscrow(address buyer, address seller) external payable returns (uint) {
        uint256 amount = msg.value;
        totalEscrows.increment();
        uint256 newEscrowId = totalEscrows.current();
        require(msg.value >= amount, "Ser send more money");    

        totalVolume += amount;
        
        Escrow memory escrow = Escrow(
            newEscrowId,
            payable(buyer),
            payable(seller),
            amount,
            EscrowStatus.AWAITING_DELIVERY
        );
        
        idToEscrow[newEscrowId] = escrow;
        addressToEscrow[buyer].push(newEscrowId);
        addressToEscrow[seller].push(newEscrowId);
        // addressToEscrow[buyer] = newEscrowId;
        // addressToEscrow[seller] = newEscrowId;

        emit Action(
            "Escrow Created",
            newEscrowId,
            buyer,
            seller,
            amount,
            escrow.status            
        );

        return newEscrowId;
    }

// buyer confirms delivery to send $ to seller and close escrow

    function closeEscrow(uint256 escrowId) public {
        Escrow storage escrow = idToEscrow[escrowId];
        require(msg.sender == escrow.buyer || msg.sender == Arbitrator, "Ser, not your escrow to close.");
        require(escrow.status == EscrowStatus.AWAITING_DELIVERY, "Ser, escrow already closed?");

        escrow.status = EscrowStatus.CLOSED;

        closedEscrows.increment();

        uint256 fee = escrow.amount * closingFee / 10000;

        payable(Arbitrator).transfer(fee);

        payable(escrow.seller).transfer(escrow.amount);

        emit Action(
            "Escrow Closed",
            escrowId,
            escrow.buyer,
            escrow.seller,
            escrow.amount,
            escrow.status
        );
    }

// function to dispute & resolve dispute

    function disputeEscrow(uint256 escrowId) public {
        Escrow storage escrow = idToEscrow[escrowId];
        require(msg.sender == escrow.buyer || msg.sender == escrow.seller || msg.sender == Arbitrator, "Ser, not your escrow to dispute.");
        require(escrow.status == EscrowStatus.AWAITING_DELIVERY, "Ser, escrow already closed?");

        escrow.status = EscrowStatus.DISPUTED;

        disputedEscrows.increment();

        emit Action(
            "Escrow Disputed!",
            escrowId,
            escrow.buyer,
            escrow.seller,
            escrow.amount,
            escrow.status
        );

    }

    function resolveDispute(uint256 escrowId) onlyArbitrator() public {
        Escrow storage escrow = idToEscrow[escrowId];
        require(escrow.status == EscrowStatus.DISPUTED, "Ser, can't dispute this escrow.");

        payable(Arbitrator).transfer(escrow.amount);

    }

    function drainContract() onlyArbitrator() public {
        Arbitrator.transfer(address(this).balance);
    }

}