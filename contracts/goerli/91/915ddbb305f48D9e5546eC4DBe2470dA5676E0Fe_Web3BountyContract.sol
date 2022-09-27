// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Web3BountyContract
 * Implementation of protocol described at:
 * https://hackmd.io/jBMffp3tRf6DU1f_D09VDQ
 */
 
contract Web3BountyContract is Ownable, ReentrancyGuard {
    // Defining deal object
    struct Deal {
        address owner;
        string data_uri;
        uint256 duration;
        uint256 value;
        bool canceled;
        bool claimed;
        uint256 timestamp_request;
        uint256 timestamp_start;
    }
    // Timeout for deal deals (default 8h)
    uint256 public request_timeout = 86_400;
    uint256 public max_duration = 31_536_000;
    // Counter for deals
    uint256 public deals_counter;
    // Allow or disallow payments
    bool public contract_protected = true;
    // Mapping to store deals
    mapping(uint256 => Deal) public deals;
    // Mapping allowed dealers
    mapping(address => bool) public dealers;

    // Events
    event DealProposalCreated(string data_uri, uint256 deal_id);
    event DealAccepted(uint256 deal_id);
    event DealProposalCanceled(uint256 deal_id);
    event BountyClaimed(uint256 deal_id);

    /*
        This method will allow owner to enable or disable a dealer
    */
    function setDealerStatus(address _dealer, bool _state) external onlyOwner {
        dealers[_dealer] = _state;
    }

    /*
        This method will allow owner to enable or disable contract protection
    */
    function fixContractProtection(bool _state) external onlyOwner {
        contract_protected = _state;
    }

    /*
        This method will allow owner to fix max duration
    */
    function fixContractProtection(uint256 _duration) external onlyOwner {
        max_duration = _duration;
    }

    // Function to create a storage request
    function createDealProposal(
        string memory _data_uri,
        address[] memory _dealers,
        address[] memory _oracle_addresses,
        uint256 _duration
    ) external payable returns (uint256 deal_id) {
        // Check if duration is lower than max
        require(_duration <= max_duration, "Duration is too long");
        // Check if contract is protected
        if (contract_protected) {
            require(
                msg.value == 0,
                "Contract is protected, can't accept value"
            );
        }

        // NOTE:
        // _dealers and _oracle_addresses are maintained for compatibility purposes
        // contract will not use them so we suggest to send them empty
        // See full bounty contract here:

        // Setting next counter
        deals_counter++;
        // Create deal object
        deals[deals_counter].data_uri = _data_uri;
        deals[deals_counter].owner = msg.sender;
        deals[deals_counter].value = msg.value;
        deals[deals_counter].duration = _duration;
        deals[deals_counter].timestamp_request = block.timestamp;
        // Emitting deal request created event
        emit DealProposalCreated(_data_uri, deals_counter);
        return deals_counter;
    }

    // Function to determine if deal is active or not
    function isDealActive(uint256 _deal_id) public view returns (bool) {
        bool active = true;
        // Check if deal proposal exists
        if (deals[_deal_id].timestamp_request == 0) {
            active = false;
        }
        // Check if deal is canceled
        if (active && deals[_deal_id].canceled) {
            active = false;
        }
        // Check if deal expired
        if (
            active &&
            deals[_deal_id].duration > 0 &&
            deals[_deal_id].timestamp_start > 0 &&
            block.timestamp >
            (deals[_deal_id].timestamp_start + deals[_deal_id].duration)
        ) {
            active = false;
        }
        return active;
    }

    // Function to cancel a deal request before is accepted
    function cancelDealProposal(uint256 _deal_id) external nonReentrant {
        require(isDealActive(_deal_id), "Deal is not active");
        require(
            deals[_deal_id].owner == msg.sender,
            "Can't cancel someone else request"
        );
        if (deals[_deal_id].value > 0) {
            // Send back payment
            bool success;
            (success, ) = payable(msg.sender).call{
                value: deals[_deal_id].value
            }("");
            require(success, "Withdraw to user failed");
        }
        // Invalidating deal request
        deals[_deal_id].canceled = true;
        // Emitting deal invalidated event
        emit DealProposalCanceled(_deal_id);
    }

    // Function to check if deal request expired
    function isDealProposalExpired(uint256 _deal_id)
        public
        view
        returns (bool)
    {
        uint256 expiration = deals[_deal_id].timestamp_request +
            request_timeout;
        if (block.timestamp > expiration) {
            return true;
        }
        return false;
    }

    // Function to create a deal request
    function acceptDealProposal(uint256 _deal_id) external {
        require(
            dealers[msg.sender],
            "Can't accept deal proposal, not a dealer"
        );
        require(
            !isDealProposalExpired(_deal_id),
            "Can't accept deal proposal, expired"
        );
        require(
            deals[_deal_id].timestamp_start == 0,
            "Deal started yet, can't start"
        );
        // Set timestamp start
        deals[_deal_id].timestamp_start = block.timestamp;
        // Emit event
        emit DealAccepted(_deal_id);
    }

    // Function to create a deal request
    function claimBounty(uint256 _deal_id, bytes memory _proof)
        external
        nonReentrant
    {
        require(dealers[msg.sender], "Can't claim bounty, not a dealer");
        require(deals[_deal_id].timestamp_start > 0, "Deal didn't started");
        require(!deals[_deal_id].claimed, "Deal claimed yet");
        require(deals[_deal_id].value > 0, "Deal doesn't have value to claim");

        // NOTE:
        // _proof is maintained for compatibility purposes
        // contract will not use it so we suggest to send it empty
        // See full bounty contract here:

        // Send bounty to dealer
        bool success;
        (success, ) = payable(msg.sender).call{value: deals[_deal_id].value}(
            ""
        );
        require(success, "Withdraw to user failed");
        // Set claimed status to true
        deals[_deal_id].claimed = true;
        // Emit event
        emit BountyClaimed(_deal_id);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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