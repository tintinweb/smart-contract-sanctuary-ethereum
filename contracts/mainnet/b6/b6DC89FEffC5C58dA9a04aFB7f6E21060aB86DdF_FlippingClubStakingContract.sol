// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Flipping Club - flippingclub.xyz
/**
 *  ______ _ _             _                _____ _       _
 * |  ____| (_)           (_)              / ____| |     | |
 * | |__  | |_ _ __  _ __  _ _ __   __ _  | |    | |_   _| |__
 * |  __| | | | '_ \| '_ \| | '_ \ / _` | | |    | | | | | '_ \
 * | |    | | | |_) | |_) | | | | | (_| | | |____| | |_| | |_) |
 * |_|    |_|_| .__/| .__/|_|_| |_|\__, |  \_____|_|\__,_|_.__/
 *            | |   | |             __/ |
 *   _____ _  |_|   |_|  _         |___/  _____            _                  _
 *  / ____| |      | |  (_)              / ____|          | |                | |
 * | (___ | |_ __ _| | ___ _ __   __ _  | |     ___  _ __ | |_ _ __ __ _  ___| |_
 *  \___ \| __/ _` | |/ / | '_ \ / _` | | |    / _ \| '_ \| __| '__/ _` |/ __| __|
 *  ____) | || (_| |   <| | | | | (_| | | |___| (_) | | | | |_| | | (_| | (__| |_
 * |_____/ \__\__,_|_|\_\_|_| |_|\__, |  \_____\___/|_| |_|\__|_|  \__,_|\___|\__|
 *                                __/ |
 *                               |___/
 *
 * @title Flipping Club Staking Contract v3.1 - flippingclub.xyz
 * @author Flipping Club Team
 * @dev Using v1 contract for burn function so a new Approval is not required. This version includes Minor improvements.
 * @notice Direct interaction with this contract not recommended. Always use the frontend provided.
 * @notice We don't use proxies to update our contracts as this contradicts the transparency of the contract.
 */

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./stakeable.sol";
import "./NFTContractFunctions.sol";
import "./burnFunctions.sol";

contract FlippingClubStakingContract is Stakeable, Pausable, Ownable {
    using SafeMath for uint256;
    uint256 private maxAllowancePerKey = 5000000000000000000;
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant EXEC = keccak256(abi.encodePacked("EXEC"));
    bytes32 private constant CLAIM = keccak256(abi.encodePacked("CLAIM"));
    bool private delegateBurn = true;
    address private __checkKeys;
    address private __burnKeys;
    event LogDepositReceived(address indexed payee);
    event Claimed(uint256 indexed amount, address indexed payee);
    NFTContractFunctions private ERC721KeyCards;
    burnFunctions private ERC721KeyBurn;
    struct StakePackage {
        uint256 duration;
        uint256 reward;
        uint256 min;
        uint256 max;
    }
    mapping(uint256 => StakePackage[]) private Packages;

    constructor(address payable _newAdmin) {
        _grantRole(ADMIN, _newAdmin);
        _grantRole(ADMIN, msg.sender);
        _grantRole(EXEC, _newAdmin);
    }

    receive() external payable {
        emit LogDepositReceived(msg.sender);
    }

    function addPackage(
        uint256 _name,
        uint256 duration,
        uint256 reward,
        uint256 min,
        uint256 max
    ) public {
        Packages[_name].push(StakePackage(duration, reward, min, max));
    }

    function getPackage(uint256 packageName)
        private
        view
        returns (StakePackage memory)
    {
        require(Packages[packageName].length > 0, "No Package");
        StakePackage memory package = Packages[packageName][0];
        return package;
    }

    function beginStake(
        uint256 _amount,
        uint256 _package,
        uint256[] memory _keysToBeUsed
    ) external payable nonReentrant whenNotPaused {
        _beginStake(_amount, _package, _keysToBeUsed, msg.sender);
    }

    function exec_beginStake(
        uint256 _amount,
        uint256 _package,
        uint256 _startTime,
        address _spender,
        uint256 _numKeys,
        uint256 rewards
    ) external nonReentrant onlyRole(EXEC) whenNotPaused {
        StakePackage memory package = getPackage(_package);
        uint256 _reward = package.reward;
        uint256 _timePeriodInSeconds = package.duration;
        uint256 _minStakeValue = package.min;
        uint256 _maxStakeValue = package.max;
        require(
            _amount >= _minStakeValue && _amount <= _maxStakeValue,
            "Value not in range"
        );
        require(enoughKeys(_amount, _reward, _numKeys), "Not enough Keys.");
        _admin_stake(
            _amount,
            _reward,
            _timePeriodInSeconds,
            _spender,
            _startTime,
            _numKeys,
            rewards
        );
    }

    function _beginStake(
        uint256 _amount,
        uint256 _package,
        uint256[] memory _keysToBeUsed,
        address _spender
    ) private {
        StakePackage memory package = getPackage(_package);
        uint256 _reward = package.reward;
        uint256 _timePeriodInSeconds = package.duration;
        uint256 _minStakeValue = package.min;
        uint256 _maxStakeValue = package.max;

        require(
            _amount >= _minStakeValue && _amount <= _maxStakeValue,
            "Stake value not in range"
        );
        require(msg.value == _amount, "Invalid amount sent.");
        require(
            checkTokens(_keysToBeUsed, _spender) == true,
            "Not all Keys owned by address."
        );
        require(checkKey() >= 1, "Address have no Key.");
        require(
            enoughKeys(_amount, _reward, _keysToBeUsed.length),
            "Not enough Keys."
        );
        delegateBurn
            ? burnKeys(_keysToBeUsed, _spender)
            : _burnKeys(_keysToBeUsed, _spender);

        _stake(
            _amount,
            _reward,
            _timePeriodInSeconds,
            _spender,
            _keysToBeUsed.length
        );
    }

    function enoughKeys(
        uint256 _amount,
        uint256 _reward,
        uint256 _numKeys
    ) private view returns (bool) {
        if (_amount.mul(_reward).div(100) <= _numKeys.mul(maxAllowancePerKey)) {
            return true;
        }
        return false;
    }

    function withdrawStake(uint256 index) external nonReentrant whenNotPaused {
        require(_hasStake(msg.sender, index), "No active positions.");
        _withdrawStake(index);
    }

    function withdrawReturn(uint256 index) external nonReentrant whenNotPaused {
        require(_hasStake(msg.sender, index), "No active positions.");
        _withdrawReturn(index);
    }

    function admin_withdraw_close(
        uint256 stake_index,
        address payable _spender,
        bool refund
    ) external onlyRole(ADMIN) {
        require(_hasStake(_spender, stake_index), "Nothing available.");
        _admin_withdraw_close(stake_index, _spender, refund);
    }

    function checkTokens(uint256[] memory _tokenList, address _msgSender)
        private
        view
        returns (bool)
    {
        require(__checkKeys != address(0), "Key Contract not set.");
        for (uint256 i = 0; i < _tokenList.length; i++) {
            if (ERC721KeyCards.ownerOf(_tokenList[i]) != _msgSender) {
                return false;
            }
        }
        return true;
    }

    function burnKeys(uint256[] memory _keysToBeUsed, address _spender) public {
        require(__burnKeys != address(0), "Delegated Burn not set.");
        ERC721KeyBurn.burnKeys(_keysToBeUsed, _spender);
    }

    function _burnKeys(uint256[] memory _keysToBeUsed, address _spender)
        public
    {
        address burnAddress = 0x000000000000000000000000000000000000dEaD;
        for (uint256 i = 0; i < _keysToBeUsed.length; i++) {
            require(
                ERC721KeyCards.isApprovedForAll(_spender, address(this)) ==
                    true,
                "BurnKeys: Contract is not approved to spend Keys."
            );
            ERC721KeyCards.safeTransferFrom(
                _spender,
                burnAddress,
                _keysToBeUsed[i]
            );
        }
    }

    function checkKey() private view returns (uint256) {
        require(__checkKeys != address(0), "Key Contract not set.");
        return ERC721KeyCards.balanceOf(msg.sender);
    }

    function initPool(uint256 _amount, address _payee)
        external
        nonReentrant
        onlyRole(ADMIN)
    {
        payable(_payee).transfer(_amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function setCheckKeysContractAddress(address KeysContract)
        external
        onlyRole(ADMIN)
    {
        __checkKeys = KeysContract;
        ERC721KeyCards = NFTContractFunctions(__checkKeys);
    }

    function setBurnContractAddress(address BurnContract)
        external
        onlyRole(ADMIN)
    {
        __burnKeys = BurnContract;
        ERC721KeyBurn = burnFunctions(__burnKeys);
    }

    function setMaxAllowancePerKey(uint256 _maxAllowancePerKey)
        external
        onlyRole(ADMIN)
    {
        maxAllowancePerKey = _maxAllowancePerKey;
    }

    function pause() external whenNotPaused onlyRole(ADMIN) {
        _pause();
    }

    function unPause() external whenPaused onlyRole(ADMIN) {
        _unpause();
    }

    function setDelegateBurn(bool status) external {
        delegateBurn = status;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// Copyright (c) 2022 Flipping Club - flippingclub.xyz
/**
 *  ______ _ _             _                _____ _       _
 * |  ____| (_)           (_)              / ____| |     | |
 * | |__  | |_ _ __  _ __  _ _ __   __ _  | |    | |_   _| |__
 * |  __| | | | '_ \| '_ \| | '_ \ / _` | | |    | | | | | '_ \
 * | |    | | | |_) | |_) | | | | | (_| | | |____| | |_| | |_) |
 * |_|    |_|_| .__/| .__/|_|_| |_|\__, |  \_____|_|\__,_|_.__/
 *            | |   | |             __/ |
 *   _____ _  |_|   |_|  _         |___/  _____            _                  _
 *  / ____| |      | |  (_)              / ____|          | |                | |
 * | (___ | |_ __ _| | ___ _ __   __ _  | |     ___  _ __ | |_ _ __ __ _  ___| |_
 *  \___ \| __/ _` | |/ / | '_ \ / _` | | |    / _ \| '_ \| __| '__/ _` |/ __| __|
 *  ____) | || (_| |   <| | | | | (_| | | |___| (_) | | | | |_| | | (_| | (__| |_
 * |_____/ \__\__,_|_|\_\_|_| |_|\__, |  \_____\___/|_| |_|\__|_|  \__,_|\___|\__|
 *                                __/ |
 *                               |___/
 *
 * @title Flipping Club Staking Contract - Dependency v3.1 - flippingclub.xyz
 * @author Flipping Club Team
 * @notice Direct interaction with this contract not recommended. Always use the frontend provided.
 * @notice We don't use proxies to update our contracts as this contradicts the transparency of the contract.
 */
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity 0.8.15;

contract Stakeable is ReentrancyGuard {
    using SafeMath for uint256;
    uint256 private initialTimestamp;
    uint256 private _maxAllowancePerKey = 5000000000000000000;
    uint256 private timePeriod;
    uint256 private maxPositions = 4;
    uint256 private MinStakeValueToClosePosition = 100000000000000000;
    uint256 private MovePercentageBasisNumber = 30;
    uint256 private minWithdraw = 100000000000000000;
    address private StakingAccount;
    bool private MoveFundsUponReceipt;
    bool private partialWithdraw = true;
    bool private MovePercentageOfFundsUponReceipt = true;
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant EXEC = keccak256(abi.encodePacked("EXEC"));
    bytes32 private constant CLAIM = keccak256(abi.encodePacked("CLAIM"));
    Stakeholder[] internal stakeholders;
    mapping(bytes32 => mapping(address => bool)) public roles;
    mapping(address => uint256) internal stakes;
    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);
    event Withdrawn(address indexed, uint256 amount, uint256 timestamp);
    event Extended(
        address user,
        uint256 amount,
        uint256 since,
        uint256 reward,
        uint256 timePeriod,
        uint256 usedKeys
    );
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 timestamp,
        uint256 _plan,
        uint256 timePeriod,
        uint256 usedKeys
    );

    struct Stake {
        address user;
        uint256 amount;
        uint256 since;
        uint256 totalReturn;
        uint256 timePeriod;
        uint256 reward;
        uint256 usedKeys;
    }
    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }

    struct StakingSummary {
        Stake[] stakes;
    }

    constructor() {
        stakeholders.push();
    }

    function _addStakeholder(address staker) private returns (uint256) {
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex;
    }

    function _stake(
        uint256 _amount,
        uint256 _totalReturn,
        uint256 _timePeriodInSeconds,
        address _Sender,
        uint256 usedKeys
    ) internal {
        require(StakingAccount != address(0), "Staking account not set.");
        require(canStake(_Sender), "Max open positions.");
        if (MoveFundsUponReceipt) {
            payable(StakingAccount).transfer(_amount);
        }
        if (MovePercentageOfFundsUponReceipt) {
            payable(StakingAccount).transfer(
                (_amount.mul(MovePercentageBasisNumber)).div(100)
            );
        }
        uint256 index = stakes[_Sender];
        uint256 timestamp = block.timestamp;
        if (index == 0) {
            index = _addStakeholder(_Sender);
        }
        initialTimestamp = block.timestamp;
        timePeriod = initialTimestamp.add(_timePeriodInSeconds);
        stakeholders[index].address_stakes.push(
            Stake(
                payable(_Sender),
                _amount,
                timestamp,
                _totalReturn,
                timePeriod,
                0,
                usedKeys
            )
        );
        emit Staked(
            _Sender,
            _amount,
            index,
            timestamp,
            _totalReturn,
            timePeriod,
            usedKeys
        );
    }

    function _admin_stake(
        uint256 _amount,
        uint256 _totalReturn,
        uint256 _timePeriodInSeconds,
        address _Sender,
        uint256 _startTime,
        uint256 usedKeys,
        uint256 rewards
    ) internal {
        require(canStake(_Sender), "Max open positions.");

        uint256 index = stakes[_Sender];
        uint256 timestamp = _startTime;
        if (index == 0) {
            index = _addStakeholder(_Sender);
        }
        initialTimestamp = _startTime;
        timePeriod = initialTimestamp.add(_timePeriodInSeconds);
        stakeholders[index].address_stakes.push(
            Stake(
                payable(_Sender),
                _amount,
                timestamp,
                _totalReturn,
                timePeriod,
                rewards,
                usedKeys
            )
        );
        emit Staked(
            _Sender,
            _amount,
            index,
            timestamp,
            _totalReturn,
            timePeriod,
            usedKeys
        );
    }

    function calculateStakeReward(Stake memory _current_stake)
        private
        view
        returns (uint256)
    {
        if (block.timestamp > _current_stake.timePeriod) {
            return
                (_current_stake.amount.mul(_current_stake.totalReturn)).div(
                    100
                );
        }
        return 0;
    }

    function _withdrawStake(uint256 index) internal {
        uint256 user_index = stakes[msg.sender];
        require(user_index > 0, "Address not registered.");
        require(index <= maxPositions - 1, "Index out of range.");
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        require(current_stake.amount > 0, "No active positions.");
        require(
            block.timestamp >= current_stake.timePeriod,
            "Not matured yet."
        );
        uint256 reward = current_stake.reward.add(
            calculateStakeReward(current_stake)
        );
        require(reward > 0, "Claim not ready.");
        uint256 _amount = current_stake.amount.add(reward);
        require(_amount >= minWithdraw, "Amount is less than minimum");
        require(address(this).balance > _amount, "Not enough balance.");
        delete stakeholders[user_index].address_stakes[index];
        stakeholders[user_index].address_stakes[index] = stakeholders[
            user_index
        ].address_stakes[stakeholders[user_index].address_stakes.length - 1];
        stakeholders[user_index].address_stakes.pop();
        payable(msg.sender).transfer(_amount);
        emit Withdrawn(msg.sender, _amount, block.timestamp);
    }

    function _withdrawReturn(uint256 index) internal {
        uint256 user_index = stakes[msg.sender];
        require(user_index > 0, "Address not registered.");
        require(partialWithdraw, "Partial withdraw is not enabled.");
        require(index <= maxPositions - 1, "Index out of range.");
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        require(current_stake.amount > 0, "No active positions.");

        require(
            block.timestamp >= current_stake.timePeriod,
            "Not matured yet."
        );
        uint256 reward = current_stake.reward.add(
            calculateStakeReward(current_stake)
        );
        require(reward > 0, "Claim not ready.");
        uint256 _amount = reward;
        require(_amount >= minWithdraw, "Amount is less than minimum");
        require(address(this).balance > _amount, "Not enough balance.");

        if (
            _enoughKeys(
                stakeholders[user_index].address_stakes[index].amount,
                stakeholders[user_index].address_stakes[index].totalReturn,
                reward,
                stakeholders[user_index].address_stakes[index].usedKeys
            )
        ) {
            uint256 timeDiff = (
                stakeholders[user_index].address_stakes[index].timePeriod
            ).sub(stakeholders[user_index].address_stakes[index].since);
            stakeholders[user_index].address_stakes[index].since = block
                .timestamp;
            stakeholders[user_index].address_stakes[index].timePeriod = block
                .timestamp
                .add(timeDiff);
            stakeholders[user_index].address_stakes[index].reward = 0;
            payable(msg.sender).transfer(_amount);
            emit Withdrawn(msg.sender, _amount, block.timestamp);
            emit Extended(
                stakeholders[user_index].address_stakes[index].user,
                stakeholders[user_index].address_stakes[index].amount,
                stakeholders[user_index].address_stakes[index].since,
                stakeholders[user_index].address_stakes[index].reward,
                stakeholders[user_index].address_stakes[index].timePeriod,
                stakeholders[user_index].address_stakes[index].usedKeys
            );
        } else {
            _amount = current_stake.amount.add(reward);
            delete stakeholders[user_index].address_stakes[index];
            stakeholders[user_index].address_stakes[index] = stakeholders[
                user_index
            ].address_stakes[
                    stakeholders[user_index].address_stakes.length - 1
                ];
            stakeholders[user_index].address_stakes.pop();
            payable(msg.sender).transfer(_amount);
            emit Withdrawn(msg.sender, _amount, block.timestamp);
        }
    }

    function _admin_withdraw_close(
        uint256 index,
        address payable _spender,
        bool refund
    ) internal {
        uint256 user_index = stakes[_spender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        uint256 reward = current_stake.reward.add(
            calculateStakeReward(current_stake)
        );
        uint256 claimable = current_stake.amount.add(reward);
        delete stakeholders[user_index].address_stakes[index];
        stakeholders[user_index].address_stakes[index] = stakeholders[
            user_index
        ].address_stakes[stakeholders[user_index].address_stakes.length - 1];
        stakeholders[user_index].address_stakes.pop();
        if (refund) {
            require(address(this).balance >= claimable, "Not enough balance.");
            payable(_spender).transfer(claimable);
        }
    }

    function _extendStake(uint256 index) public {
        uint256 user_index = stakes[msg.sender];
        require(user_index > 0, "Address not registered.");
        require(index <= maxPositions - 1, "Index out of range.");
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        require(current_stake.amount > 0, "No active positions.");
        uint256 reward = current_stake.reward.add(
            calculateStakeReward(current_stake)
        );
        require(reward > 0, "Extend not Possible.");
        require(
            _enoughKeys(
                stakeholders[user_index].address_stakes[index].amount,
                stakeholders[user_index].address_stakes[index].totalReturn,
                reward,
                stakeholders[user_index].address_stakes[index].usedKeys
            ),
            "Not enough allowance left."
        );
        uint256 timeDiff = (
            stakeholders[user_index].address_stakes[index].timePeriod
        ).sub(stakeholders[user_index].address_stakes[index].since);
        stakeholders[user_index].address_stakes[index].since = block.timestamp;
        stakeholders[user_index].address_stakes[index].timePeriod = block
            .timestamp
            .add(timeDiff);
        stakeholders[user_index].address_stakes[index].reward = reward;
        emit Extended(
            stakeholders[user_index].address_stakes[index].user,
            stakeholders[user_index].address_stakes[index].amount,
            stakeholders[user_index].address_stakes[index].since,
            stakeholders[user_index].address_stakes[index].reward,
            stakeholders[user_index].address_stakes[index].timePeriod,
            stakeholders[user_index].address_stakes[index].usedKeys
        );
    }

    function _enoughKeys(
        uint256 _amount,
        uint256 _PlanReward,
        uint256 _FutReward,
        uint256 _numKeys
    ) internal view returns (bool) {
        if (
            _amount.mul(_PlanReward).div(100).add(_FutReward) <=
            _numKeys.mul(_maxAllowancePerKey)
        ) {
            return true;
        }
        return false;
    }

    function _stakeLength(address _staker) external view returns (uint256) {
        StakingSummary memory summary = StakingSummary(
            stakeholders[stakes[_staker]].address_stakes
        );
        return summary.stakes.length;
    }

    function getAllStakes(address _staker)
        external
        view
        returns (StakingSummary memory)
    {
        StakingSummary memory summary = StakingSummary(
            stakeholders[stakes[_staker]].address_stakes
        );
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].reward = summary.stakes[s].reward.add(
                availableReward
            );
        }
        return summary;
    }

    function getSingleStake(address _staker, uint256 index)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(index <= maxPositions - 1, "Index out of range.");
        StakingSummary memory summary = StakingSummary(
            stakeholders[stakes[_staker]].address_stakes
        );
        require(summary.stakes.length > 0, "No active positions.");
        require(summary.stakes.length > index, "Index not valid.");

        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].reward = summary.stakes[s].reward.add(
                availableReward
            );
        }
        return (
            summary.stakes[index].amount,
            summary.stakes[index].since,
            summary.stakes[index].totalReturn,
            summary.stakes[index].timePeriod,
            summary.stakes[index].reward,
            summary.stakes[index].usedKeys
        );
    }

    function _hasStake(address _staker, uint256 index)
        internal
        view
        returns (bool)
    {
        require(index <= maxPositions - 1, "Index out of range.");
        StakingSummary memory summary = StakingSummary(
            stakeholders[stakes[_staker]].address_stakes
        );
        if (summary.stakes.length > 0 && summary.stakes.length > index) {
            return true;
        }
        return false;
    }

    function canStake(address _staker) private view returns (bool result) {
        StakingSummary memory summary = StakingSummary(
            stakeholders[stakes[_staker]].address_stakes
        );
        if (summary.stakes.length >= maxPositions) {
            return false;
        }
        return true;
    }

    function setMaxPositions(uint256 _maxPositions) external onlyRole(ADMIN) {
        maxPositions = _maxPositions;
    }

    function setMinStakeValueToClosePosition(
        uint256 _MinStakeValueToClosePosition
    ) external onlyRole(ADMIN) {
        MinStakeValueToClosePosition = _MinStakeValueToClosePosition;
    }

    function setStakingAccount(address _StakingAccount)
        external
        onlyRole(ADMIN)
    {
        StakingAccount = _StakingAccount;
    }

    function setMoveFundsUponReceipt(bool _MoveFundsUponReceipt)
        external
        onlyRole(ADMIN)
    {
        MoveFundsUponReceipt = _MoveFundsUponReceipt;
    }

    function setMovePercentageBasisNumber(uint256 _MovePercentageBasisNumber)
        external
        onlyRole(ADMIN)
    {
        MovePercentageBasisNumber = _MovePercentageBasisNumber;
    }

    function setPartialWithdraw(bool _partialWithdraw)
        external
        onlyRole(ADMIN)
    {
        partialWithdraw = _partialWithdraw;
    }

    function setMovePercentageOfFundsUponReceipt(
        bool _MovePercentageOfFundsUponReceipt
    ) external onlyRole(ADMIN) {
        MovePercentageOfFundsUponReceipt = _MovePercentageOfFundsUponReceipt;
    }

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "Not authorized.");
        _;
    }

    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }

    function grantRole(bytes32 _role, address _account)
        external
        onlyRole(ADMIN)
    {
        _grantRole(_role, _account);
    }

    function _revokeRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account)
        external
        onlyRole(ADMIN)
    {
        _revokeRole(_role, _account);
    }

    function set_maxAllowancePerKey(uint256 __maxAllowancePerKey)
        external
        onlyRole(ADMIN)
    {
        _maxAllowancePerKey = __maxAllowancePerKey;
    }

    function setMinWithdraw(uint256 _minWithdraw) external onlyRole(ADMIN) {
        minWithdraw = _minWithdraw;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface NFTContractFunctions {
    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function approve(address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface burnFunctions {
    function burnKeys(uint256[] memory _keysToBeUsed, address _spender)
        external;
}