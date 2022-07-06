// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

pragma solidity ^0.8.7;

error Anonim__NeedMoreThanZero(uint256 amount);
error Anonim__NotSupplied();
error Anonim__CannotWithdrawMoreThanSupplied(uint256 amount);
error Anonim__CouldNotBorrowMoreThan80PercentOfCollateral();
error Anonim__ThisTokenIsNotAvailable(address tokenAddress);
error Anonim__NotAllowedBeforeRepayingExistingLoan(uint256 amount);
error Anonim__TransactionFailed();
error Anonim__SorryWeCurrentlyDoNotHaveThisToken(address tokenAddress);
error Anonim__UpKeepNotNeeded();

contract Anonim is ReentrancyGuard, KeeperCompatibleInterface, Ownable {
    address[] private s_allowedTokens;
    address[] private s_suppliers;
    address[] private s_borrowers;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;

    //////////////////
    //// Events /////
    ////////////////

    event TokenSupplied(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 indexed amount
    );
    event TokenWithdrawn(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 indexed amount
    );
    event TokenBorrowed(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 indexed amount
    );
    event TokenRepaid(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 indexed amount
    );

    //////////////////////
    /////  mappings  /////
    /////////////////////

    // token address -> total supply of that token
    mapping(address => uint256) private s_totalSupply;

    // tokenAddress & user address -> their supplied balances
    mapping(address => mapping(address => uint256)) private s_supplyBalances;

    // tokenAddress & user adddress -> their borrowed balance
    mapping(address => mapping(address => uint256)) private s_borrowedBalances;

    // token address -> price feeds
    mapping(address => AggregatorV3Interface) private s_priceFeeds;

    // userAddress -> all of his unique supplied tokens
    mapping(address => address[]) private s_supplierUniqueTokens;

    // userAddress -> all of his unique borrowed tokens
    mapping(address => address[]) private s_borrowerUniqueTokens;

    /////////////////////
    ///   Modifiers   ///
    /////////////////////

    modifier hasSupplied() {
        bool success;
        for (uint256 i = 0; i < s_allowedTokens.length; i++) {
            if (s_supplyBalances[s_allowedTokens[i]][msg.sender] > 0) {
                success = true;
            }
        }

        if (!success) {
            revert Anonim__NotSupplied();
        }
        _;
    }

    modifier notZero(uint256 amount) {
        if (amount <= 0) {
            revert Anonim__NeedMoreThanZero(amount);
        }
        _;
    }

    modifier isTokenAllowed(address tokenAddress) {
        bool execute;
        for (uint256 i = 0; i < s_allowedTokens.length; i++) {
            if (s_allowedTokens[i] == tokenAddress) {
                execute = true;
            }
        }

        if (!execute) {
            revert Anonim__ThisTokenIsNotAvailable(tokenAddress);
        }
        _;
    }

    //////////////////////////
    ///  Main  Functions   ///
    /////////////////////////

    constructor(
        address[] memory allowedTokens,
        address[] memory priceFeeds,
        uint256 updateInterval
    ) {
        s_allowedTokens = allowedTokens;
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            s_priceFeeds[allowedTokens[i]] = AggregatorV3Interface(priceFeeds[i]);
        }
        i_interval = updateInterval;
        s_lastTimeStamp = block.timestamp;
    }

    function supply(address tokenAddress, uint256 amount)
        external
        payable
        isTokenAllowed(tokenAddress)
        notZero(amount)
        nonReentrant
    {
        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert Anonim__TransactionFailed();
        }
        s_totalSupply[tokenAddress] += amount;
        s_supplyBalances[tokenAddress][msg.sender] += amount;
        addSupplier(msg.sender);
        addUniqueToken(s_supplierUniqueTokens[msg.sender], tokenAddress);
        emit TokenSupplied(tokenAddress, msg.sender, amount);
    }

    function withdraw(address tokenAddress, uint256 amount)
        external
        payable
        hasSupplied
        notZero(amount)
        nonReentrant
    {
        if (amount > s_supplyBalances[tokenAddress][msg.sender]) {
            revert Anonim__CannotWithdrawMoreThanSupplied(amount);
        }

        revertIfHighBorrowing(tokenAddress, msg.sender, amount);
        s_supplyBalances[tokenAddress][msg.sender] -= amount;
        s_totalSupply[tokenAddress] -= amount;
        removeSupplierAndUniqueToken(tokenAddress, msg.sender);
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit TokenWithdrawn(tokenAddress, msg.sender, amount);
    }

    function borrow(address tokenAddress, uint256 amount)
        external
        payable
        isTokenAllowed(tokenAddress)
        hasSupplied
        notZero(amount)
        nonReentrant
    {
        if (s_totalSupply[tokenAddress] <= 0) {
            revert Anonim__SorryWeCurrentlyDoNotHaveThisToken(tokenAddress);
        }

        notMoreThanMaxBorrow(tokenAddress, msg.sender, amount);
        addBorrower(msg.sender);
        addUniqueToken(s_borrowerUniqueTokens[msg.sender], tokenAddress);
        s_borrowedBalances[tokenAddress][msg.sender] += amount;
        s_totalSupply[tokenAddress] -= amount;
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit TokenBorrowed(tokenAddress, msg.sender, amount);
    }

    function repay(address tokenAddress, uint256 amount)
        external
        payable
        notZero(amount)
        nonReentrant
    {
        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert Anonim__TransactionFailed();
        }

        s_borrowedBalances[tokenAddress][msg.sender] -= amount;
        s_totalSupply[tokenAddress] += amount;
        removeBorrowerAndUniqueToken(tokenAddress, msg.sender);
        emit TokenRepaid(tokenAddress, msg.sender, amount);
    }

    function liquidation() external onlyOwner {
        for (uint256 i = 0; i < s_borrowers.length; i++) {
            if (getTotalBorrowValue(s_borrowers[i]) >= getTotalSupplyValue(s_borrowers[i])) {
                for (uint256 index = 0; index < s_allowedTokens.length; index++) {
                    s_supplyBalances[s_allowedTokens[index]][s_borrowers[i]] = 0;
                    s_borrowedBalances[s_allowedTokens[index]][s_borrowers[i]] = 0;
                }
            }
        }
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool hasUsers = (s_borrowers.length > 0) || (s_suppliers.length > 0);
        bool isTimePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        upkeepNeeded = (hasUsers && isTimePassed);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Anonim__UpKeepNotNeeded();
        }

        if (s_borrowers.length > 0) {
            for (uint256 i = 0; i < s_borrowers.length; i++) {
                for (
                    uint256 index = 0;
                    index < s_borrowerUniqueTokens[s_borrowers[i]].length;
                    index++
                ) {
                    s_borrowedBalances[s_borrowerUniqueTokens[s_borrowers[i]][index]][
                        s_borrowers[i]
                    ] += (
                        (s_borrowedBalances[s_borrowerUniqueTokens[s_borrowers[i]][index]][
                            s_borrowers[i]
                        ] / uint256(50)) // chargind 2 % APY per 30 sec
                    );
                }
            }
        }

        if (s_suppliers.length > 0) {
            for (uint256 i = 0; i < s_suppliers.length; i++) {
                for (
                    uint256 index = 0;
                    index < s_supplierUniqueTokens[s_suppliers[i]].length;
                    index++
                ) {
                    s_supplyBalances[s_supplierUniqueTokens[s_suppliers[i]][index]][
                        s_suppliers[i]
                    ] += (s_supplyBalances[s_supplierUniqueTokens[s_suppliers[i]][index]][
                        s_suppliers[i]
                    ] / uint256(100)); // rewarding 1 % APY per 30 sec
                }
            }
        }

        s_lastTimeStamp = block.timestamp;
    }

    function faucet(address tokenAddress) external {
        IERC20(tokenAddress).transfer(msg.sender, 10000 * 10**18);
    }

    ////////////////////////
    // Helper functions ////
    ///////////////////////

    function revertIfHighBorrowing(
        address tokenAddress,
        address userAddress,
        uint256 amount
    ) private view {
        uint256 availableAmountValue = getTotalSupplyValue(userAddress) -
            ((uint256(100) * getTotalBorrowValue(userAddress)) / uint256(80));

        (uint256 price, uint256 decimals) = getLatestPrice(tokenAddress);
        uint256 askedAmountValue = amount * (price / 10**decimals);

        if (askedAmountValue > availableAmountValue) {
            revert Anonim__NotAllowedBeforeRepayingExistingLoan(amount);
        }
    }

    function notMoreThanMaxBorrow(
        address tokenAddress,
        address userAddress,
        uint256 amount
    ) private view {
        uint256 maxBorrow = getMaxBorrow(userAddress);
        (uint256 price, uint256 decimals) = getLatestPrice(tokenAddress);
        uint256 askedAmountValue = amount * (price / 10**decimals);

        if (askedAmountValue > maxBorrow) {
            revert Anonim__CouldNotBorrowMoreThan80PercentOfCollateral();
        }
    }

    function addUniqueToken(address[] storage uniqueTokenArray, address tokenAddress) private {
        if (uniqueTokenArray.length == 0) {
            uniqueTokenArray.push(tokenAddress);
        } else {
            bool add = true;
            for (uint256 i = 0; i < uniqueTokenArray.length; i++) {
                if (uniqueTokenArray[i] == tokenAddress) {
                    add = false;
                }
            }
            if (add) {
                uniqueTokenArray.push(tokenAddress);
            }
        }
    }

    function addSupplier(address userAddress) private {
        if (s_suppliers.length == 0) {
            s_suppliers.push(userAddress);
        } else {
            bool add = true;
            for (uint256 i = 0; i < s_suppliers.length; i++) {
                if (s_suppliers[i] == userAddress) {
                    add = false;
                }
            }
            if (add) {
                s_suppliers.push(userAddress);
            }
        }
    }

    function addBorrower(address userAddress) private {
        if (s_borrowers.length == 0) {
            s_borrowers.push(userAddress);
        } else {
            bool add = true;
            for (uint256 i = 0; i < s_borrowers.length; i++) {
                if (s_borrowers[i] == userAddress) {
                    add = false;
                }
            }
            if (add) {
                s_borrowers.push(userAddress);
            }
        }
    }

    function removeSupplierAndUniqueToken(address tokenAddress, address userAddress) private {
        if (s_supplyBalances[tokenAddress][userAddress] <= 0) {
            remove(s_supplierUniqueTokens[userAddress], tokenAddress);
        }

        if (s_supplierUniqueTokens[userAddress].length == 0) {
            remove(s_suppliers, userAddress);
        }
    }

    function removeBorrowerAndUniqueToken(address tokenAddress, address userAddress) private {
        if (s_borrowedBalances[tokenAddress][userAddress] <= 0) {
            remove(s_borrowerUniqueTokens[userAddress], tokenAddress);
        }
        if (s_borrowerUniqueTokens[userAddress].length == 0) {
            remove(s_borrowers, userAddress);
        }
    }

    function remove(address[] storage array, address removingAddress) private {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == removingAddress) {
                array[i] = array[array.length - 1];
                array.pop();
            }
        }
    }

    ////////////////////////////
    ///   getter functions   ///
    ////////////////////////////

    function getTokenTotalSupply(address tokenAddress) external view returns (uint256) {
        return s_totalSupply[tokenAddress];
    }

    function getAllTokenSupplyInUsd() external view returns (uint256) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < s_allowedTokens.length; i++) {
            (uint256 price, uint256 decimals) = getLatestPrice(s_allowedTokens[i]);

            totalValue += ((price / 10**decimals) * s_totalSupply[s_allowedTokens[i]]);
        }
        return totalValue;
    }

    function getSupplyBalance(address tokenAddress, address userAddress)
        external
        view
        returns (uint256)
    {
        return s_supplyBalances[tokenAddress][userAddress];
    }

    function getBorrowedBalance(address tokenAddress, address userAddress)
        external
        view
        returns (uint256)
    {
        return s_borrowedBalances[tokenAddress][userAddress];
    }

    function getLatestPrice(address tokenAddress) public view returns (uint256, uint256) {
        (, int256 price, , , ) = s_priceFeeds[tokenAddress].latestRoundData();
        uint256 decimals = uint256(s_priceFeeds[tokenAddress].decimals());
        return (uint256(price), decimals);
    }

    function getMaxBorrow(address userAddress) public view returns (uint256) {
        uint256 availableAmountValue = getTotalSupplyValue(userAddress) -
            ((uint256(100) * getTotalBorrowValue(userAddress)) / uint256(80));

        return (availableAmountValue * uint256(80)) / uint256(100);
    }

    function getMaxWithdraw(address tokenAddress, address userAddress)
        external
        view
        returns (uint256)
    {
        uint256 availableAmountValue = getTotalSupplyValue(userAddress) -
            ((uint256(100) * getTotalBorrowValue(userAddress)) / uint256(80));

        (uint256 price, uint256 decimals) = getLatestPrice(tokenAddress);
        return availableAmountValue / (price / 10**decimals);
    }

    function getMaxTokenBorrow(address tokenAddress, address userAddress)
        external
        view
        returns (uint256)
    {
        uint256 availableAmountValue = getTotalSupplyValue(userAddress) -
            ((uint256(100) * getTotalBorrowValue(userAddress)) / uint256(80));

        (uint256 price, uint256 decimals) = getLatestPrice(tokenAddress);
        return ((availableAmountValue / (price / 10**decimals)) * uint256(80)) / uint256(100);
    }

    function getTotalSupplyValue(address userAddress) public view returns (uint256) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < s_allowedTokens.length; i++) {
            (uint256 price, uint256 decimals) = getLatestPrice(s_allowedTokens[i]);

            totalValue += ((price / 10**decimals) *
                s_supplyBalances[s_allowedTokens[i]][userAddress]);
        }
        return totalValue;
    }

    function getTotalBorrowValue(address userAddress) public view returns (uint256) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < s_allowedTokens.length; i++) {
            (uint256 price, uint256 decimals) = getLatestPrice(s_allowedTokens[i]);
            totalValue += ((price / 10**decimals) *
                s_borrowedBalances[s_allowedTokens[i]][userAddress]);
        }
        return totalValue;
    }

    function getAllowedTokens() external view returns (address[] memory) {
        return s_allowedTokens;
    }

    function getSuppliers() external view returns (address[] memory) {
        return s_suppliers;
    }

    function getBorrowers() external view returns (address[] memory) {
        return s_borrowers;
    }

    function getUniqueSupplierTokens(address userAddress)
        external
        view
        returns (address[] memory)
    {
        return s_supplierUniqueTokens[userAddress];
    }

    function getUniqueBorrowerTokens(address userAddress)
        external
        view
        returns (address[] memory)
    {
        return s_borrowerUniqueTokens[userAddress];
    }

    function getInterval() external view returns (uint256) {
        return i_interval;
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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