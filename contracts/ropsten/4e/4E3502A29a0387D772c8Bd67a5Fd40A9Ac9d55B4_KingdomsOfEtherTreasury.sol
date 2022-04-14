// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract KingdomsOfEtherTreasury is Ownable {
    uint128 public constant PERCENT_DENOMINATOR = 10;
    uint128 public constant PRIMARY_SALES_TREASURY_PERCENT = 6;
    uint128 public constant PRIMARY_SALES_OPERATIONAL_PERCENT = 1;
    uint128 public constant PRIMARY_SALES_FOUNDERS_PERCENT = 3;
    uint128 public constant SECONDARY_SALES_TREASURY_PERCENT = 4;
    uint128 public constant SECONDARY_SALES_OPERATIONAL_PERCENT = 3;
    uint128 public constant SECONDARY_SALES_PRIMES_PERCENT = 3;
    uint256 public constant MIN_REWARD = 10_000;

    enum Role {
        TREASURY,
        OPERATIONAL,
        PRIMES,
        FOUNDERS
    }

    struct Incomes {
        uint128 primarySales;
        uint128 secondarySales;
        uint128 treasuryDonated;
        uint128 operationalDonated;
    }

    struct Outcomes {
        // all packs in uint256
        uint128 treasuryPaid;
        uint128 operationalPaid;
        uint128 primesPaid;
        uint128 foundersPaid;
    }

    /* state */
    Incomes public incomes;
    Outcomes public outcomes;
    address payable public primes;
    address payable public founders;
    address payable public treasury;

    /* errors */
    string public constant REWARD_UNKNOWN_ROLE = "UNKNOWN ROLE";
    string public constant DONATE_UNKNOWN_ROLE = "UNKNOWN ROLE";
    string public constant ALREADY_INITIALIZED = "ALREADY INITIALIZED";
    string public constant ROLE_IS_NOT_INITIALIZED = "ROLE IS NOT INITIALIZED";
    string public constant REWARD_IS_LESS_THAN_MIN = "REWARD IS LESS THAN MIN";

    constructor(address payable _founders) Ownable() {
        founders = _founders;
    }

    function setTreasuryDAO(address payable _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function initPrimes(address payable _primes) external onlyOwner {
        require(primes == address(0), ALREADY_INITIALIZED);
        primes = _primes;
    }

    /**
     * @notice receive donates to Operational or Treasury
     */
    function donate(Role _role) external payable {
        //console.log("primary sale %s: %s", msg.sender, msg.value);
        if (_role == Role.OPERATIONAL) {
            incomes.operationalDonated += uint128(msg.value);
        } else if (_role == Role.TREASURY) {
            incomes.treasuryDonated += uint128(msg.value);
        } else {
            revert(DONATE_UNKNOWN_ROLE);
        }
    }

    /**
     * @notice primary sale (invoked by nft contract on mint)
     */
    function primarySale() external payable {
        //console.log("primary sale %s: %s", msg.sender, msg.value);
        incomes.primarySales += uint128(msg.value);
    }

    /**
     * @notice secondary sale (invoked by ERC-2981)
     */
    receive() external payable {
        //console.log("secondary sale {}:{}", msg.sender, msg.value);
        incomes.secondarySales += uint128(msg.value);
    }

    function payReward(Role _role) public returns (uint256 _reward) {
        address payable _account;
        uint128 _paid;
        uint128 _total;
        Incomes memory _incomes = incomes;
        Outcomes memory _outcomes = outcomes;
        if (_role == Role.TREASURY) {
            _account = treasury;
            _total =
                _incomes.treasuryDonated +
                _incomes.primarySales *
                PRIMARY_SALES_TREASURY_PERCENT +
                _incomes.secondarySales *
                SECONDARY_SALES_TREASURY_PERCENT;
            _total /= PERCENT_DENOMINATOR;
            _paid = _outcomes.treasuryPaid;
            _outcomes.treasuryPaid = _total;
        } else if (_role == Role.OPERATIONAL) {
            _account = payable(owner());
            _total =
                _incomes.operationalDonated +
                _incomes.primarySales *
                PRIMARY_SALES_OPERATIONAL_PERCENT +
                _incomes.secondarySales *
                SECONDARY_SALES_OPERATIONAL_PERCENT;
            _total /= PERCENT_DENOMINATOR;
            _paid = _outcomes.operationalPaid;
            _outcomes.operationalPaid = _total;
        } else if (_role == Role.PRIMES) {
            _account = primes;
            _total =
                (_incomes.secondarySales * SECONDARY_SALES_PRIMES_PERCENT) /
                PERCENT_DENOMINATOR;
            _paid = _outcomes.primesPaid;
            _outcomes.primesPaid = _total;
        } else if (_role == Role.FOUNDERS) {
            _account = founders;
            _total =
                (_incomes.primarySales * PRIMARY_SALES_FOUNDERS_PERCENT) /
                PERCENT_DENOMINATOR;
            _paid = _outcomes.foundersPaid;
            _outcomes.foundersPaid = _total;
        } else {
            revert(REWARD_UNKNOWN_ROLE);
        }
        _reward = uint256(_total - _paid);
        require(_account != address(0), ROLE_IS_NOT_INITIALIZED);
        require(_reward > MIN_REWARD, REWARD_IS_LESS_THAN_MIN);
        _account.transfer(_reward);
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