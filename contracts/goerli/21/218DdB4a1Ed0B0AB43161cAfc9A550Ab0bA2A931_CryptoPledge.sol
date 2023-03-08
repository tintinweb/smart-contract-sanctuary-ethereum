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

pragma solidity ^0.8.8;

// By testing, getter functions for mapping are much cheaper then dyn arrays
// Using mapping vs dyn arrays also allows to implement `delete` in the future
// Pledge struct with fields in the shown order costs the least gas !
//

/* ========== ERRORS ========== */
error CryptoPledge__AlreadyRefunded();
error CryptoPledge__DurationMoreThanNow();
error CryptoPledge__NotCreator();
error CryptoPledge__NotEnoughProfit();
error CryptoPledge__NotYetComplete();
error CryptoPledge__PledgeStatusNotOpen();
error CryptoPledge__RefundFailed();
error CryptoPledge__TransferDonateFailed();
error CryptoPledge__TransferTakeProfitFailed();
error CryptoPledge__WrongDuration();
error CryptoPledge__WrongValue();
error CryptoPledge__WrongGoalNumber();

//import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title A contract for making pledges
 * @author pixpi.eth
 * @notice Allows users to make pledges for diff goals, add supporters
 * @dev Test phase
 */
contract CryptoPledge is Ownable {
    /* ========== TYPE DECLARATIONS ========== */
    enum Goal {
        Fitness,
        Diet,
        QuitSmoking
    }
    enum Status {
        Open,
        Failed,
        Complete,
        Refund
    }
    // maybe fixed amount of supporters ? to save gas, but how to add a new ? with no push
    struct Pledge {
        address donateTo;
        Status status;
        uint32 duration;
        uint64 amount; // in wei, limits up to ~18 eth
        address owner;
        Goal goal;
    }

    /* ========== STATE VARIABLES ========== */
    mapping(uint256 => mapping(address => bool)) supporters; // pledgeId => address[] supporters
    mapping(uint256 => Pledge) public pledges;
    mapping(address => uint256[]) pledgers;
    mapping(address => bool) public donors;
    uint256 public numPledges = 1;
    uint256 public profit;

    /* ========== GLOBAL VARIABLES ========== */
    uint64 public constant MIN_PLEDGE_AMOUNT = 0.001 ether;
    uint64 public constant MAX_PLEDGE_AMOUNT = 18 ether;
    uint256 public constant MIN_DURATION_TIME = 24 hours;
    uint256 public constant MAX_DURATION_TIME = 365 days;
    uint256 public constant FAILED_PLEDGE_FEE = 10; // 10% of a failed pledge is taken by the contract
    uint256 public constant MIN_DONATION_AMOUNT = 0.01 ether;

    /* ========== EVENTS ========== */
    event PledgeCreated(
        address indexed pledger,
        uint256 indexed pledgeId,
        Goal goal,
        uint256 amount,
        uint256 duration
    );
    event PledgeFailed(uint256 indexed pledgeId);
    event PledgeComplete(uint256 indexed pledgeId);
    event PledgeRefund(uint256 indexed pledgeId, uint256 amount);

    /* ========== MODIFIERS ========== */
    modifier onlyCreator(uint256 pledgeId) {
        if (pledges[pledgeId].owner != msg.sender) {
            revert CryptoPledge__NotCreator();
        }
        _;
    }

    /* ========== FUNCTIONS ========== */
    // In order: constructor, receive, fallback, external, public, internal, private, view / pure

    /**
     * @dev Creates a new pledge
     * @param _goal Goal type
     * @param _duration Timestamp when a pledge would be `Complete`
     * @param _donateTo Address to send if Pledge Failed
     */
    function createPledge(
        Goal _goal,
        uint32 _duration,
        address _donateTo
    ) public payable returns (uint256) {
        if (msg.value < MIN_PLEDGE_AMOUNT || msg.value > MAX_PLEDGE_AMOUNT) {
            revert CryptoPledge__WrongValue();
        }
        if (_goal > type(Goal).max) {
            revert CryptoPledge__WrongGoalNumber();
        }
        if (_duration < MIN_DURATION_TIME || _duration > MAX_DURATION_TIME) {
            revert CryptoPledge__WrongDuration();
        }

        uint256 pledgeId;
        unchecked {
            pledgeId = numPledges++;
        }
        pledges[pledgeId] = Pledge({
            amount: uint64(msg.value),
            duration: _duration + uint32(block.timestamp),
            owner: msg.sender,
            donateTo: _donateTo,
            goal: _goal,
            status: Status.Open
        });
        pledgers[msg.sender].push(pledgeId);

        emit PledgeCreated(msg.sender, pledgeId, _goal, msg.value, _duration);
        return pledgeId;
    }

    /**
     * @dev Adds a supporter to the pledge
     * @param supporter Address of supporter
     * @param pledgeId Id of a pledge
     */
    function addSupporter(address supporter, uint256 pledgeId) public {
        supporters[pledgeId][supporter] = true;
    }

    /**
     * @dev Reports a failed pledge
     * @notice reporter is either the creator or from his `supporters` list
     * @param pledgeId Id of a pledge
     */
    function reportPledgeFailed(uint256 pledgeId) public {
        if (
            !(pledges[pledgeId].owner == msg.sender ||
                supporters[pledgeId][msg.sender])
        ) {
            revert CryptoPledge__NotCreator();
        }
        if (pledges[pledgeId].status != Status.Open) {
            revert CryptoPledge__PledgeStatusNotOpen();
        }
        pledges[pledgeId].status = Status.Failed;

        unchecked {
            (bool success, ) = payable(pledges[pledgeId].donateTo).call{
                value: (pledges[pledgeId].amount * (100 - FAILED_PLEDGE_FEE)) /
                    100
            }("");
            if (!success) {
                revert CryptoPledge__TransferDonateFailed();
            }
        }
        profit += (pledges[pledgeId].amount * FAILED_PLEDGE_FEE) / 100;

        emit PledgeFailed(pledgeId);
    }

    /**
     * @dev Reports a completed pledge
     * @param pledgeId Id of a pledge
     */
    function reportPledgeComplete(
        uint256 pledgeId
    ) public onlyCreator(pledgeId) {
        if (pledges[pledgeId].duration > block.timestamp) {
            revert CryptoPledge__DurationMoreThanNow();
        }

        if (pledges[pledgeId].status != Status.Open) {
            revert CryptoPledge__PledgeStatusNotOpen();
        }

        pledges[pledgeId].status = Status.Complete;
        emit PledgeComplete(pledgeId);
    }

    /**
     * @dev Withdraw if a pledge is `Complete`
     * @param pledgeId Id of a pledge
     */
    function withdraw(uint256 pledgeId) public onlyCreator(pledgeId) {
        if (pledges[pledgeId].status == Status.Refund) {
            revert CryptoPledge__AlreadyRefunded();
        }
        if (pledges[pledgeId].status != Status.Complete) {
            revert CryptoPledge__NotYetComplete();
        }

        pledges[pledgeId].status = Status.Refund;
        (bool success, ) = payable(msg.sender).call{
            value: pledges[pledgeId].amount
        }("");
        if (!success) {
            revert CryptoPledge__RefundFailed();
        }

        emit PledgeRefund(pledgeId, pledges[pledgeId].amount);
    }

    /**
     * @dev Take a profit
     * @param amount Amount to take
     */
    function takeProfit(uint256 amount) public onlyOwner {
        if (profit < amount) {
            revert CryptoPledge__NotEnoughProfit();
        }

        unchecked {
            profit -= amount;
        }
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert CryptoPledge__TransferTakeProfitFailed();
        }
    }

    /**
     * @dev Make a donation
     * Any donation is valid, but req >= min_amount to become a donor
     */
    function makeDonation() public payable {
        profit += msg.value;
        if (msg.value >= MIN_DONATION_AMOUNT) {
            donors[msg.sender] = true;
        }
    }

    /* ========== GETTER FUNCTIONS ========== */

    /**
     * @dev Check time left for a given pledge
     * @param pledgeId Id of a pledge
     * @return Amount left in seconds
     */
    function checkTimeLeft(uint256 pledgeId) public view returns (uint256) {
        return pledges[pledgeId].duration - block.timestamp;
    }

    function getPledges(
        address _pledger
    ) public view returns (uint256[] memory) {
        return pledgers[_pledger];
    }

    function getSupporter(
        uint256 pledgeId,
        address supporter
    ) public view returns (bool) {
        return supporters[pledgeId][supporter];
    }
}