/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

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


// File @openzeppelin/contracts/security/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/Betting.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Betting is Ownable, ReentrancyGuard {
    uint256 public minimumBetAmount = 0.001 ether;
    string[] public varians;
    uint8 public poolPercentage;
    // Period to wait before widthdrawing the rest after finished
    uint256 public constant WAIT_PERIOD = 365 days;

    struct Statistics {
        uint256 amountBet;
        uint256 userCount;
        mapping(address => uint256) amounts;
        mapping(address => bool) isPayed;
    }

    mapping(uint256 => Statistics) public variantValues;
    uint256 public finishedAt;
    uint256 public wonVariant;
    uint256 public ownerPayed = 0;

    constructor(string[] memory _varians, uint8 _poolPercentage) {
        varians = _varians;
        poolPercentage = _poolPercentage;
    }

    // minimumBetAmount manipuliation

    function setMinimumBetAmount(uint256 _minimumBetAmount) public onlyOwner {
        minimumBetAmount = _minimumBetAmount;
    }

    // Betting
    function bet(uint256 _variant) public payable {
        require(finishedAt == 0, "Betting already finished");
        require(
            msg.value >= minimumBetAmount,
            "Bid less then minimum bet amount"
        );
        require(_variant < varians.length, "Variant not exist");
        variantValues[_variant].amountBet += msg.value;
        if (variantValues[_variant].amounts[msg.sender] == 0) {
            // first time
            variantValues[_variant].userCount += 1;
        }
        variantValues[_variant].amounts[msg.sender] += msg.value;
    }

    // stats
    function getAllBetStat() public view returns (uint256, uint256) {
        uint256 users = 0;
        uint256 amountBet = 0;
        for (uint256 i = 0; i < varians.length; i++) {
            users += variantValues[i].userCount;
            amountBet += variantValues[i].amountBet;
        }
        return (users, amountBet);
    }

    function currentMultiplier(uint256 _variant) public view returns (uint256) {
        (, uint256 amountBet) = getAllBetStat();
        if (variantValues[_variant].amountBet == 0) {
            return 1000;
        }
        return (amountBet * 100) / (variantValues[_variant].amountBet);
    }

    function getCurrentAmount(uint256 _variant, address _user)
        public
        view
        returns (uint256)
    {
        return variantValues[_variant].amounts[_user];
    }

    // finish betting
    function finishBetting(uint256 variant) public onlyOwner {
        require(finishedAt == 0, "Betting is already finished");
        finishedAt = block.timestamp;
        wonVariant = variant;
    }

    // withdraw
    function getReward() public nonReentrant {
        require(finishedAt != 0, "Betting is not finished yet");
        require(
            !variantValues[wonVariant].isPayed[msg.sender],
            "You already payed"
        );
        variantValues[wonVariant].isPayed[msg.sender] = true;

        uint256 amount = (variantValues[wonVariant].amounts[msg.sender] *
            currentMultiplier(wonVariant) *
            poolPercentage) / 10_000; //as multiplier and poolPercentage is 100x
        require(amount != 0, "GetReward amount is 0. User win nothing");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Unable to send value, recipient may have reverted");
    }

    // withdraw for owner
    function getOwnerWidhdrawalAmountAvailable() public view returns (uint256) {
        if (finishedAt != 0 && (block.timestamp > finishedAt + WAIT_PERIOD)) {
            return address(this).balance;
        }

        (, uint256 allBetAmount) = getAllBetStat();
        uint256 allWidthdrawalAmount = (allBetAmount * (100 - poolPercentage)) /
            100;
        return allWidthdrawalAmount - ownerPayed;
    }

    function withdraw(uint256 amount, address _to)
        public
        onlyOwner
        nonReentrant
    {
        require(
            amount <= getOwnerWidhdrawalAmountAvailable(),
            "Withdraw: you cant withdraw this amount"
        );
        (bool success, ) = _to.call{value: amount}("");
        require(
            success,
            "Withdraw: Unable to send value, recipient may have reverted"
        );

        ownerPayed += amount;
    }

    // function withdrawRestAfterWaitTime() public {
    //     require(finishedAt != 0, "Betting is not finished yet");
    //     require(
    //         block.timestamp > finishedAt + WAIT_PERIOD,
    //         "Wait time not passed yet"
    //     );
    //     uint256 balance = address(this).balance;
    //     (bool success, ) = owner().call{value: balance}("");
    //     require(success, "Withdraw failed");
    // }

    // we not support token payments. Just in case someone send token here
    function withdrawToken(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }
}