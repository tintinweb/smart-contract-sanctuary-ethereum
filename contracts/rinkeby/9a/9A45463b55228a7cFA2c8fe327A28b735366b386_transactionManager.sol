import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./stakeable.sol";
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IClaim {
    function initClaim(address _payee, uint256 _amount) external payable;
}

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

contract transactionManager is Stakeable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    event LogDepositReceived(address indexed payee);
    event Claimed(uint256 indexed amount, address indexed payee);

    NFTContractFunctions private ERC721KeyCards;

    uint256 private P1Reward = 210; // Basis Point
    uint256 private P2Reward = 280;
    uint256 private P3Reward = 460;
    uint256 private P4Reward = 930;
    uint256 private P1Duration = 864000; // Seconds
    uint256 private P2Duration = 3888000;
    uint256 private P3Duration = 7776000;
    uint256 private P4Duration = 15552000;
    uint256 private constant PACKAGE_1 = 1;
    uint256 private constant PACKAGE_2 = 2;
    uint256 private constant PACKAGE_3 = 3;
    uint256 private constant PACKAGE_4 = 4;
    uint256 private maxAllowancePerKey = 5000000000000000000;
    uint256 private minStakeValue = 100000000000000000;
    uint256 private maxStakeValue = 5000000000000000000;
    uint256 private minWithdraw = 100000000000000000;
    address private __checkKeys = 0x0000000000000000000000000000000000000000; // null address
    address private _claimContract = 0x0000000000000000000000000000000000000000;
    //0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    //0xe713da41157afd626765d8624ce6aa2e2cda0e788972dce0d6620ef0d5983efa
    bytes32 private constant EXEC = keccak256(abi.encodePacked("EXEC"));
    address payable public owner; // current owner of the contract

    constructor() {
        owner = payable(msg.sender);
        _grantRole(ADMIN, msg.sender);
    }

    receive() external payable {}

    fallback() external payable {
        require(msg.data.length == 0);
        emit LogDepositReceived(msg.sender);
    }

    function beginStake(
        uint256 _amount,
        uint256 _package,
        uint256[] memory _keysToBeUsed
    ) external payable nonReentrant whenNotPaused {
        require(
            msg.sender.code.length > 0,
            "Wont accept calls from another contracts."
        );
        require(msg.value > 0, "Not enoiugh eth Sent.");
        require(
            checkTokens(_keysToBeUsed, msg.sender) == true,
            "Not all Keys presented are owned by this address."
        );
        require(checkKey() >= 1, "This address dont have any Key.");
        require(
            _package == PACKAGE_1 ||
                _package == PACKAGE_2 ||
                _package == PACKAGE_3 ||
                _package == PACKAGE_4,
            "Invalid Package"
        );
        require(msg.value == _amount, "Invalid amount of eth sent.");
        require(_amount >= minStakeValue, "Cannot stake less than minimum");
        require(_amount <= maxStakeValue, "Cannot stake more than maximum");

        for (uint256 i = 0; i < _keysToBeUsed.length; i++) {
            require(
                ERC721KeyCards.isApprovedForAll(msg.sender, address(this)) ==
                    true,
                "Contract is not approved to spend Keys."
            );
            ERC721KeyCards.safeTransferFrom(
                msg.sender,
                address(this),
                _keysToBeUsed[i]
            );
        }
        uint256 _rewardPerHour = 0;
        uint256 _timePeriodInSeconds = 0;
        if (_package == PACKAGE_1) {
            _rewardPerHour = P1Reward;
            _timePeriodInSeconds = P1Duration;
        }
        if (_package == PACKAGE_2) {
            _rewardPerHour = P2Reward;
            _timePeriodInSeconds = P2Duration;
        }
        if (_package == PACKAGE_3) {
            _rewardPerHour = P3Reward;
            _timePeriodInSeconds = P3Duration;
        }
        if (_package == PACKAGE_4) {
            _rewardPerHour = P4Reward;
            _timePeriodInSeconds = P4Duration;
        }
        require(
            ((_amount / _rewardPerHour) * (_timePeriodInSeconds / 3600)) <=
                (_keysToBeUsed.length * maxAllowancePerKey),
            "Not enough Keys for this package."
        );
        _stake(_amount, _rewardPerHour, _timePeriodInSeconds, msg.sender);
    }

    function admin_beginStake(
        uint256 _amount,
        uint256 _package,
        uint256[] memory _keysToBeUsed,
        address _spender
    ) external payable nonReentrant onlyRole(ADMIN) whenNotPaused {
        require(
            msg.sender.code.length > 0,
            "Wont accept calls from another contracts."
        );
        require(
            checkTokens(_keysToBeUsed, _spender) == true,
            "Not all Keys presented are owned by this address."
        );
        require(checkKey() >= 1, "This address dont have any Key.");
        require(
            _package == PACKAGE_1 ||
                _package == PACKAGE_2 ||
                _package == PACKAGE_3 ||
                _package == PACKAGE_4,
            "Invalid Package"
        );
        require(msg.value == _amount, "Invalid amount of eth sent.");
        require(_amount >= minStakeValue, "Cannot stake less than minimum");
        require(_amount <= maxStakeValue, "Cannot stake more than maximum");

        for (uint256 i = 0; i < _keysToBeUsed.length; i++) {
            require(
                ERC721KeyCards.isApprovedForAll(_spender, address(this)) ==
                    true,
                "Contract is not approved to spend Keys."
            );
            ERC721KeyCards.safeTransferFrom(
                _spender,
                address(this),
                _keysToBeUsed[i]
            );
        }
        uint256 _rewardPerHour = 0;
        uint256 _timePeriodInSeconds = 0;
        if (_package == PACKAGE_1) {
            _rewardPerHour = P1Reward;
            _timePeriodInSeconds = P1Duration;
        }
        if (_package == PACKAGE_2) {
            _rewardPerHour = P2Reward;
            _timePeriodInSeconds = P2Duration;
        }
        if (_package == PACKAGE_3) {
            _rewardPerHour = P3Reward;
            _timePeriodInSeconds = P3Duration;
        }
        if (_package == PACKAGE_4) {
            _rewardPerHour = P4Reward;
            _timePeriodInSeconds = P4Duration;
        }
        require(
            ((_amount / _rewardPerHour) * (_timePeriodInSeconds / 3600)) <=
                (_keysToBeUsed.length * maxAllowancePerKey),
            "Not enough Keys for this package."
        );
        _stake(_amount, _rewardPerHour, _timePeriodInSeconds, _spender);
    }

    function withdrawStake(uint256 amount, uint256 stake_index)
        external
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        require(
            msg.sender.code.length > 0,
            "Wont accept calls from another contracts."
        );
        require(amount >= minWithdraw, "Amount is less than minimum");
        return _withdrawStake(amount, stake_index);
    }

    function checkTokens(uint256[] memory _tokenList, address _msgSender)
        internal
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

    function checkKey() internal view returns (uint256) {
        require(__checkKeys != address(0), "Key Contract not set.");
        return ERC721KeyCards.balanceOf(msg.sender);
    }

    /// @notice Initiates Pool participition in batches.
    function initPool(uint256 _amount, address _payee)
        external
        nonReentrant
        onlyRole(ADMIN)
    {
        require(msg.sender == owner, "Only Owner can perform this operation.");
        payable(_payee).transfer(_amount);
    }

    /// @notice Initiates claim for specific address.
    function broadcastClaim(address payable _payee, uint256 _amount)
        external
        payable
        onlyRole(EXEC)
        nonReentrant
        whenNotPaused
    {
        require(_claimContract != address(0), "Claim Contract not set.");
        IClaim(_claimContract).initClaim{value: msg.value}(_payee, _amount);
        emit Claimed(_amount, _payee);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function setPackageOne(uint256 _P1Reward, uint256 _P1Duration)
        public
        onlyRole(ADMIN)
    {
        P1Reward = _P1Reward;
        P1Duration = _P1Duration;
    }

    function setPackageTwo(uint256 _P2Reward, uint256 _P2Duration)
        public
        onlyRole(ADMIN)
    {
        P2Reward = _P2Reward;
        P2Duration = _P2Duration;
    }

    function setPackageThree(uint256 _P3Reward, uint256 _P3Duration)
        public
        onlyRole(ADMIN)
    {
        P3Reward = _P3Reward;
        P3Duration = _P3Duration;
    }

    function setPackageFour(uint256 _P4Reward, uint256 _P4Duration)
        public
        onlyRole(ADMIN)
    {
        P4Reward = _P4Reward;
        P4Duration = _P4Duration;
    }

    function setCheckKeysContractAddress(address KeysContract)
        public
        onlyRole(ADMIN)
    {
        __checkKeys = KeysContract;
        ERC721KeyCards = NFTContractFunctions(__checkKeys);
    }

    function setClaimContract(address ClaimContract) public onlyRole(ADMIN) {
        _claimContract = ClaimContract;
    }

    function setmaxAllowancePerKey(uint256 _maxAllowancePerKey)
        public
        onlyRole(ADMIN)
    {
        maxAllowancePerKey = _maxAllowancePerKey;
    }

    function setMinWithdraw(uint256 _minWithdraw) public onlyRole(ADMIN) {
        minWithdraw = _minWithdraw;
    }

    function pause() public whenNotPaused onlyRole(ADMIN) {
        _pause();
    }

    function unPause() public whenPaused onlyRole(ADMIN) {
        _unpause();
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Stakeable {
    using SafeMath for uint256;

    uint256 private initialTimestamp;
    uint256 private timePeriod;
    uint256 private maxPositions = 1;
    uint256 private MinStakeValueToClosePosition = 100000000000000000;
    address private StakingAccount = 0x0000000000000000000000000000000000000000;
    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);
    event Withdrawn(address indexed, uint256 amount, uint256 timestamp);
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 timestamp,
        uint256 _plan,
        uint256 timePeriod
    );

    mapping(bytes32 => mapping(address => bool)) public roles;

    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant EXEC = keccak256(abi.encodePacked("EXEC"));

    constructor() {
        stakeholders.push();
    }

    struct Stake {
        address user;
        uint256 amount;
        uint256 since;
        uint256 rewardPerHour;
        uint256 timePeriod;
        uint256 reward;
    }
    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }

    struct StakingSummary {
        Stake[] stakes;
    }

    Stakeholder[] internal stakeholders;
    mapping(address => uint256) internal stakes;

    function _addStakeholder(address staker) internal returns (uint256) {
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex;
    }

    function _stake(
        uint256 _amount,
        uint256 _rewardPerHour,
        uint256 _timePeriodInSeconds,
        address _Sender
    ) internal {
        require(StakingAccount != address(0), "Staking account not set.");
        require(_amount > 0, "Cannot stake zero eth.");
        require(canStake(_Sender), "Already have max open positions.");
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
                _rewardPerHour,
                timePeriod,
                0
            )
        );
        emit Staked(
            _Sender,
            _amount,
            index,
            timestamp,
            _rewardPerHour,
            timePeriod
        );
        payable(StakingAccount).transfer(_amount);
    }

    function calculateStakeReward(Stake memory _current_stake)
        internal
        view
        returns (uint256)
    {
        return
            (((block.timestamp - _current_stake.since) / 1 hours) *
                _current_stake.amount) / _current_stake.rewardPerHour;
    }

    function _withdrawStake(uint256 amount, uint256 index)
        internal
        returns (uint256)
    {
        uint256 user_index = stakes[msg.sender];
        require(user_index > 0, "No active positions.");
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        require(current_stake.amount > 0, "No active positions.");
        uint256 reward = calculateStakeReward(current_stake);
        current_stake.amount = current_stake.amount + reward;
        require(
            amount <= current_stake.amount,
            "Staking: Cannot withdraw more than you have staked"
        );
        require(reward > 0, "Error: Reward not ready yet.");
        require(
            block.timestamp >= current_stake.timePeriod,
            "Error: Not ready to withdraw yet."
        );
        current_stake.amount = current_stake.amount - amount;
        if (current_stake.amount < MinStakeValueToClosePosition) {
            delete stakeholders[user_index].address_stakes[index];
            stakeholders[user_index].address_stakes[index] = stakeholders[
                user_index
            ].address_stakes[
                    stakeholders[user_index].address_stakes.length - 1
                ];
            stakeholders[user_index].address_stakes.pop();
        } else {
            stakeholders[user_index]
                .address_stakes[index]
                .amount = current_stake.amount;
            stakeholders[user_index].address_stakes[index].since = block
                .timestamp;
        }
        emit Withdrawn(msg.sender, amount, block.timestamp);
        return current_stake.amount;
    }

    function hasStake(address _staker, uint256 index)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(
            index <= maxPositions - 1,
            "Index out of range for Max Open Positions"
        );
        StakingSummary memory summary = StakingSummary(
            stakeholders[stakes[_staker]].address_stakes
        );
        require(summary.stakes.length > 0, "No active positions.");
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].reward = availableReward;
        }
        return (
            summary.stakes[index].user,
            summary.stakes[index].amount,
            summary.stakes[index].since,
            summary.stakes[index].rewardPerHour,
            summary.stakes[index].timePeriod,
            summary.stakes[index].reward
        );
    }

    function canStake(address _staker) internal view returns (bool result) {
        StakingSummary memory summary = StakingSummary(
            stakeholders[stakes[_staker]].address_stakes
        );
        if (summary.stakes.length >= maxPositions) {
            return false;
        }
        return true;
    }

    function setMaxPositions(uint256 _maxPositions) public onlyRole(ADMIN) {
        maxPositions = _maxPositions;
    }

    //@notice: co-exists with maxStakeValue
    function setMinStakeValueToClosePosition(
        uint256 _MinStakeValueToClosePosition
    ) public onlyRole(ADMIN) {
        MinStakeValueToClosePosition = _MinStakeValueToClosePosition;
    }

    function setStakingAccount(address _StakingAccount) public onlyRole(ADMIN) {
        StakingAccount = _StakingAccount;
    }

    modifier onlyRole(bytes32 _role) {
        require(
            roles[_role][msg.sender],
            "Role: You're not authorized to perform this operation."
        );
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
}