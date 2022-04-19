// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "hardhat/console.sol";

interface ILendingToken {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);
}

contract LendingContract is Ownable, ReentrancyGuard {
    uint256 public immutable borrowRatio;
    uint256 public immutable minDuration;
    uint256 public immutable maxDuration;
    uint256 public immutable maxFee;
    uint256 public immutable minFee;
    uint256 public immutable overdraftPercentDuration; // 50% allowed overdraft as base
    uint256 public immutable overdraftFee; // additional fee each day
    ILendingToken token;

    uint256 totalFees;
    uint256 totalOverdraft;

    enum UserState { INITIAL, BORROWED, RETURNED }

    struct Customer {
        uint256 id;
        uint256 amount;
        uint256 eth;
        uint256 untilTime;
        uint256 overdraftTime;
        UserState state;
    }

    mapping(address => Customer) customers;
    mapping(uint256 => address) idToAddress;
    uint256 totalIds = 0;
    uint256 lowerId = 1;

    modifier onlyInitial() {
        require(customers[msg.sender].state == UserState.INITIAL, "CANNOT_BORROW_TWICE");
        _;
    }
    modifier onlyBorrowed() {
        require(customers[msg.sender].state == UserState.BORROWED, "ONLY_ACTIVE_BORROWERS");
        _;
    }
    modifier onlyReturned() {
        require(customers[msg.sender].state == UserState.RETURNED, "ONLY_AFTER_TOKENS_RETURN");
        _;
    }
    modifier tokenSet() {
        require(address(token) != address(0), "TOKEN_CONTRACT_NOT_SET");
        _;
    }

    event TokensBorrowed(address _customer, uint _amount, uint _duration);
    event TokensReturnSuccess(address _customer, uint _amount);
    event OverdraftFeeSuccess(address _customer, uint _amount);
    event OverdraftExpired(address _customer);
    event NotEnoughEthForOverdraft(address _customer);
    event EthReturnedSuccess(address _customer, uint _amount);
    event EthOwnerWithdraw(uint _amount);
    event OverdraftOwnerWithdraw(uint _amount);
    event OverdraftFeeUpdated(uint _amount);

    constructor(
        uint256 _borrowRatio,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _minFee,
        uint256 _maxFee,
        uint256 _overdraftPercentDuration,
        uint256 _overdraftFee
        // ILendingToken _token
    ) {
        require(_maxDuration > _minDuration, "MIN_DURATION_BIGGER_THAN_MAX");
        require(_minDuration > 0, "MIN_DURATION_ZERO");
        require(_borrowRatio > 0, "RATIO_ZERO");
        require(_maxFee >= _minFee, "MIN_FEE_BIGGER_THAN_MAX");
        require(_overdraftPercentDuration <= 100, "OVERDRAFT_DURATION_TOO_LARGE");
        require(_overdraftFee > 0, "OVERDRAFT_FEE_ZERO");

        borrowRatio = _borrowRatio;
        minDuration = _minDuration;
        maxDuration = _maxDuration;
        maxFee = _maxFee;
        minFee = _minFee;
        overdraftPercentDuration = _overdraftPercentDuration;
        overdraftFee = _overdraftFee;
        // token = _token;
        // _token.transferOwnership(address(this));
    }

    function setToken(ILendingToken _token) external onlyOwner {
        require(address(token) == address(0), "TOKEN_ALREADY_SET");
        require(address(this) == _token.owner(), "INCORRECT_TOKEN_OWNER");
        token = _token;
    }

    function borrowTokens(uint256 _durationDays) external payable tokenSet onlyInitial {
        require(msg.value > minFee, "ETH_AMOUNT_TOO_SMALL");
        require(_durationDays >= minDuration, "DURATION_TOO_SMALL");
        require(_durationDays <= maxDuration, "DURATION_TOO_LARGE");

        uint256 _fee = minFee +
            (_durationDays - minDuration) * (maxFee - minFee) / (maxDuration - minDuration);
        customers[msg.sender].amount = msg.value * borrowRatio;
        customers[msg.sender].eth = msg.value - _fee;
        customers[msg.sender].untilTime = block.timestamp + _durationDays * 1 days;
        customers[msg.sender].state = UserState.BORROWED;
        customers[msg.sender].overdraftTime = block.timestamp + (_durationDays * (100 + overdraftPercentDuration) / 100) * 1 days;

        totalIds++;
        customers[msg.sender].id = totalIds ;
        idToAddress[totalIds ] = msg.sender;
        
        token.mint(msg.sender, msg.value * borrowRatio);
        totalFees += _fee;
        emit TokensBorrowed(msg.sender, customers[msg.sender].amount, _durationDays);
    }

    function returnTokens() external tokenSet onlyBorrowed {
        uint256 _balance = token.balanceOf(msg.sender);
        require(_balance >= customers[msg.sender].amount, "NOT_ENOUGH_TOKENS_TO_RETURN");
        if (block.timestamp > customers[msg.sender].overdraftTime) {
            totalOverdraft += customers[msg.sender].eth;
            _trimCustomerMap(msg.sender);
            delete customers[msg.sender];
            emit OverdraftExpired(msg.sender);
            return;
        }
        
        uint256 _overdraftFee = 0;
        if (block.timestamp > customers[msg.sender].untilTime) {
            _overdraftFee = uint(overdraftFee * (block.timestamp - customers[msg.sender].untilTime) / 1 days);

            if (_overdraftFee > customers[msg.sender].eth)  {
                totalOverdraft += customers[msg.sender].eth;
                _trimCustomerMap(msg.sender);
                delete customers[msg.sender];
                emit NotEnoughEthForOverdraft(msg.sender);
                return;
            }

            customers[msg.sender].eth -= _overdraftFee;
            totalOverdraft += _overdraftFee;
            emit OverdraftFeeSuccess(msg.sender, _overdraftFee);
        }
        token.burn(msg.sender, customers[msg.sender].amount);
        customers[msg.sender].state = UserState.RETURNED;
        emit TokensReturnSuccess(msg.sender, customers[msg.sender].amount);
        
    }

    function withdrawEth() external tokenSet onlyReturned nonReentrant {
        require(block.timestamp > customers[msg.sender].untilTime, "REQUIRED_TIME_NOT_PASSED");
        require(customers[msg.sender].eth > 0, "NO_ETH_TO_RETRIEVE");
        address payable _customer = payable(msg.sender);
        _customer.transfer(customers[msg.sender].eth);
        emit EthReturnedSuccess(msg.sender, customers[msg.sender].eth);
        _trimCustomerMap(msg.sender);
        delete customers[msg.sender];
    }

    function _trimCustomerMap(address _customer) internal {
        if (customers[_customer].id == totalIds) {
            totalIds--;
        } else if (customers[_customer].id == lowerId) {
            lowerId++;
        }
    }

    function withdrawFeeContractEth() external tokenSet onlyOwner {
        address payable _owner = payable(owner());
        require(totalFees > 0, "NO_FEE_TO_WITHDRAW");

        _owner.transfer(totalFees);
        emit EthOwnerWithdraw(totalFees);
        totalFees = 0;
    }

    function withdrawOverdraftContractEth() external tokenSet onlyOwner {
        address payable _owner = payable(owner());
        require(totalOverdraft > 0, "NO_OVERDRAFT_TO_WITHDRAW");
        require(token.balanceOf(_owner) >= totalOverdraft * borrowRatio, "NOT_ENOUGH_TOKENS_TO_BURN");

        token.burn(_owner, totalOverdraft * borrowRatio);
        _owner.transfer(totalOverdraft);
        emit OverdraftOwnerWithdraw(totalOverdraft);
        totalOverdraft = 0;
    }

    function calculateOverdraft() external tokenSet onlyOwner {
        address _customer;
        uint256 _newTotalIds = totalIds;
        uint256 _newLowerId = lowerId;
        bool _reduceIds = true;
        for (uint i = lowerId; i <= totalIds; i++) {
            _customer = idToAddress[i];
            if (customers[_customer].id == 0) {
                _newLowerId++;
                continue;
            } else if (customers[_customer].state == UserState.RETURNED ||
                       customers[_customer].untilTime >= block.timestamp) {
                break;
            }  else if (customers[_customer].state == UserState.BORROWED &&
                        customers[_customer].overdraftTime < block.timestamp) {
                totalOverdraft += customers[_customer].eth;
                emit OverdraftExpired(_customer);
                delete customers[_customer];
                _newLowerId++;

            } else {
                break;
            }
        }
        lowerId = _newLowerId;
        for (uint i = totalIds; i > lowerId; i--) {
            _customer = idToAddress[i];
            if (customers[_customer].id == 0 && _reduceIds == true) {
                _newTotalIds--;
                continue;
            } else if (customers[_customer].id == 0) {
                continue;
            } else if (customers[_customer].state == UserState.RETURNED ||
                       customers[_customer].untilTime >= block.timestamp) {
                _reduceIds = false;
                continue;
            }  else if (customers[_customer].state == UserState.BORROWED &&
                        customers[_customer].overdraftTime < block.timestamp) {
                totalOverdraft += customers[_customer].eth;
                emit OverdraftExpired(_customer);
                delete customers[_customer];
                if (_reduceIds == true) {
                    _newTotalIds--;
                }
            } else {
                _reduceIds = false;
            }
        }
        totalIds = _newTotalIds;
        emit OverdraftFeeUpdated(totalOverdraft);
    }

    function balanceOf(address user) external view tokenSet returns(uint256) {
        return token.balanceOf(user);
    }

    function getTotalFees() external view onlyOwner returns(uint256) {
        return totalFees;
    }
    function getTotalOverdraft() external view onlyOwner returns(uint256) {
        return totalOverdraft;
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