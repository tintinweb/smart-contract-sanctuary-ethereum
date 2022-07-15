// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "@solmate/auth/Owned.sol";
import "@solmate/tokens/ERC20.sol";
import "@solmate/utils/SafeTransferLib.sol";
import "@solmate/utils/ReentrancyGuard.sol";
import "@open-zeppelin/utils/structs/EnumerableSet.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/fees/IFeeManager.sol";
import "../exchanges/mixins/MechanismGated.sol";
import "../../interfaces/token/IStaked.sol";

/// @title Staking contract
/// @author 0xEND
/// @notice Contract for staking + claiming rewards
contract Staked is IStaked, MechanismGated, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for IWETH;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct TokenRewards {
        uint128 accrued;
        uint128 paidPerToken;
    }

    /// ~~~ Struct ~~~
    struct Balance {
        uint128 unlocked;
        uint128 locked;
    }

    /// ~~~ Variables ~~~

    uint256 private constant PRECISION = 10**18;

    /// @notice Total ERC20s staked for a given account
    mapping(address => Balance) public balanceOf;

    /// @notice Rewards per token per user
    mapping(address => mapping(address => TokenRewards)) public rewards;

    /// @notice Sourcer Fees
    mapping(address => mapping(address => uint256)) public sourcerFees;

    /// @notice Rewards per token
    mapping(address => uint256) public noStakingRewards;

    /// @notice Token Rewards
    EnumerableSet.AddressSet private _rewardTokens;

    /// @notice Wrapped ETH contract
    IWETH private _WETH;

    /// @notice Total staked tokens
    uint256 public totalStaked = 0;

    /// @notice Pixel ERC20  token
    ERC20 private _pixelToken;

    /// @notice Locked contract address
    /// @dev We only let this contract stake locked tokens
    address private _lockedContractAddress;

    /// @notice Tracks the amount of rewards for each currency a staked token holds
    mapping(address => uint256) private _rewardPerToken;

    /// ~~~ Events ~~~

    /// @notice Emmited when someone stakes
    /// @param staker Address staking
    /// @param amount Number of tokens staked
    event Stake(address staker, uint256 amount);

    /// @notice Emmited when someone unstakes
    /// @param staker Address unstaking
    /// @param amount Number of tokens unstaked
    event Unstake(address staker, uint256 amount);

    /// @notice Emmited when someone staking locked tokens
    /// @param recipient Address recipient
    /// @param amount Number of tokens received+staked
    event StakeLocked(address recipient, uint256 amount);

    /// @notice Emmited when someone unstakes previously locked tokens
    /// @param recipient Address recipient
    /// @param amount Number of tokens to be received
    event UnstakeLocked(address recipient, uint256 amount);

    /// @notice Emmited when the `Locked` address is updated
    /// @param lockedContractAddress New address
    event LockedContractAddressUpdated(address lockedContractAddress);

    /// ~~~ Custom Errors ~~~
    error TokenNotAcceptedError(address token);

    error OnlyCallableByLockedContractError();

    /// @notice Functions only callable by the locked contract
    modifier onlyLockedContract() virtual {
        if (msg.sender != _lockedContractAddress) {
            revert OnlyCallableByLockedContractError();
        }
        _;
    }

    /// @dev Called everytime someone stakes/unstakes or claims rewards.
    /// @param user User involved in the transaction
    modifier updateRewards(address user) {
        uint256 totalRewardTokens = _rewardTokens.length();
        for (uint256 i = 0; i < totalRewardTokens; ) {
            address token = _rewardTokens.at(i);
            Balance memory balance = balanceOf[user];
            TokenRewards memory tokenRewards = rewards[user][token];
            uint128 rewardPerToken = uint128(_rewardPerToken[token]);
            tokenRewards.accrued =
                ((balance.locked + balance.unlocked) *
                    (rewardPerToken - tokenRewards.paidPerToken)) /
                uint128(PRECISION);
            tokenRewards.paidPerToken = rewardPerToken;
            rewards[user][token] = tokenRewards;
            unchecked {
                ++i;
            }
        }
        _;
    }

    constructor(address pixelTokenAddress, address wethAddress) {
        _pixelToken = ERC20(pixelTokenAddress);
        _WETH = IWETH(wethAddress);
        _rewardTokens.add(address(0)); // ETH
    }

    function stake(uint256 amount) external override updateRewards(msg.sender) {
        _pixelToken.safeTransferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender].unlocked += uint128(amount);
        totalStaked += amount;
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount)
        external
        override
        updateRewards(msg.sender)
    {
        balanceOf[msg.sender].unlocked -= uint128(amount);
        totalStaked -= amount;
        _pixelToken.safeTransfer(msg.sender, amount);
        emit Unstake(msg.sender, amount);
    }

    function stakeLocked(
        address from,
        address lockedAddress,
        uint256 amount
    ) external override onlyLockedContract updateRewards(lockedAddress) {
        _pixelToken.safeTransferFrom(from, address(this), amount);
        balanceOf[lockedAddress].locked += uint128(amount);
        totalStaked += amount;
        emit StakeLocked(lockedAddress, amount);
    }

    function unstakeLocked(address lockedAddress, uint256 amount)
        external
        override
        onlyLockedContract
        updateRewards(lockedAddress)
    {
        balanceOf[lockedAddress].locked -= uint128(amount);
        totalStaked -= amount;
        _pixelToken.safeTransfer(lockedAddress, amount);
        emit StakeLocked(lockedAddress, amount);
    }

    function addFeesReceived(address token, IFeeManager.Fees memory fees)
        external
        override
        onlyApprovedMechanism(msg.sender)
        returns (uint256)
    {
        if (!_rewardTokens.contains(token)) {
            revert TokenNotAcceptedError(token);
        }

        uint256 total = fees.sourcers.length;
        uint256 totalFees = 0;
        for (uint256 i = 0; i < total; ) {
            unchecked {
                uint256 amount = fees.amounts[i];
                sourcerFees[fees.sourcers[i]][token] += amount;
                totalFees += amount;
                ++i;
            }
        }
        uint256 protocolAmount = fees.protocolAmount;
        if (totalStaked == 0) {
            noStakingRewards[token] += protocolAmount;
        } else {
            _rewardPerToken[token] +=
                (protocolAmount * PRECISION) /
                totalStaked;
        }
        return totalFees + fees.protocolAmount;
    }

    function claimSourcerFees() external override nonReentrant {
        uint256 totalRewardTokens = _rewardTokens.length();
        for (uint256 i = 0; i < totalRewardTokens; ) {
            address token = _rewardTokens.at(i);
            uint256 fees = sourcerFees[msg.sender][token];
            sourcerFees[msg.sender][token] = 0;
            if (fees > 0) {
                if (_isEthAddress(token)) {
                    _sendEthOrWrapped(msg.sender, fees);
                } else {
                    ERC20(token).safeTransfer(msg.sender, fees);
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function claimNoStakingRewards() external override onlyOwner {
        uint256 totalRewardTokens = _rewardTokens.length();
        for (uint256 i = 0; i < totalRewardTokens; ) {
            address token = _rewardTokens.at(i);
            uint256 amount = noStakingRewards[token];
            if (amount > 0) {
                if (_isEthAddress(token)) {
                    _sendEthOrWrapped(owner, amount);
                } else {
                    ERC20(token).safeTransfer(owner, amount);
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function unlockedBalanceOf(address user)
        external
        view
        override
        returns (uint256)
    {
        return uint256(balanceOf[user].unlocked);
    }

    function lockedBalanceOf(address user)
        external
        view
        override
        returns (uint256)
    {
        return uint256(balanceOf[user].locked);
    }

    function claimRewards()
        external
        override
        updateRewards(msg.sender)
        nonReentrant
    {
        uint256 totalRewardTokens = _rewardTokens.length();
        for (uint256 i = 0; i < totalRewardTokens; ) {
            address token = _rewardTokens.at(i);
            uint256 accrued = rewards[msg.sender][token].accrued;
            rewards[msg.sender][token].accrued = 0;
            if (accrued > 0) {
                if (_isEthAddress(token)) {
                    _sendEthOrWrapped(msg.sender, accrued);
                } else {
                    ERC20(token).safeTransfer(msg.sender, accrued);
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function setLockedContractAddress(address lockedContractAddress)
        external
        override
        onlyOwner
    {
        _lockedContractAddress = lockedContractAddress;
        emit LockedContractAddressUpdated(lockedContractAddress);
    }

    function addRewardToken(address tokenAddress) external onlyOwner {
        _rewardTokens.add(tokenAddress);
    }

    /// @dev Beware of gas costs. Mainly offered for view accessors. See (`EnumerableSet`).
    function getRewardTokens() external view returns (address[] memory) {
        return _rewardTokens.values();
    }

    function getRewardsAccrued(address user, address token)
        external
        view
        returns (uint128)
    {
        return rewards[user][token].accrued;
    }

    receive() external payable {}

    function _isEthAddress(address currency) private pure returns (bool) {
        return currency == address(0);
    }

    function _sendEthOrWrapped(address owner, uint256 amount) private {
        bool success;

        assembly {
            success := call(gas(), owner, amount, 0, 0, 0, 0)
        }
        if (!success) {
            _WETH.deposit{value: amount}();
            _WETH.safeTransfer(owner, amount);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "@solmate/tokens/ERC20.sol";

abstract contract IWETH is ERC20 {
    function deposit() external payable virtual;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

/// @title Fee Manager
/// @author 0xEND
/// @notice It keeps track of sourcers and the logic for calculating fees.
interface IFeeManager {
    struct Fees {
        address payable[] sourcers;
        uint256[] amounts;
        uint256 protocolAmount;
    }

    /// @notice Registers a new sourcer
    /// @param sourcerAddress Address of the new sourcer
    /// @return The new sourcer id
    function newSourcer(address payable sourcerAddress)
        external
        returns (uint256);

    /// @notice Returns the sourcer id for a given address. 0 if not found.
    /// @param sourcerAddress Address of the sourcer
    /// @return Sourcer address or 0 if not found
    function getSourcerId(address payable sourcerAddress)
        external
        view
        returns (uint256);

    /// @notice Given a transaction, return the corresponding recipients and amounts
    /// @param makerSourcerId Sourcer Id that facilitated the maker order
    /// @param takerSourcerId Sourcer Id that facilitated the taker order
    /// @param amount Total amount of the transaction
    /// @return Fees corresponding to sourcers + protocol
    function getFees(
        uint256 makerSourcerId,
        uint256 takerSourcerId,
        uint256 amount
    ) external returns (Fees memory);

    /// @notice Updates the total fee charged on transactions
    /// @param newTotalFee The new total fee
    function updateTotalFee(uint256 newTotalFee) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;
import "@solmate/auth/Owned.sol";
import "@open-zeppelin/interfaces/IERC721.sol";

/// @title Mechanism Gated
/// @author 0xEND
/// @notice Contracts inheriting have functions that can only be called by approved mechanisms.
abstract contract MechanismGated is Owned(msg.sender) {
    /// ~~~ Variables ~~~
    /// @notice True if a mechanism is approved.
    mapping(address => bool) approvedMechanisms;

    /// ~~~ Errors ~~~
    /// @notice Thrown when a mechanism is not approved
    error MechanismNotApproved(address mechanismAddress);

    /// @notice Only allow approved mechanisms.
    /// @param mechanismAddress Address of the mechanism interacting with the function
    modifier onlyApprovedMechanism(address mechanismAddress) {
        if (!isMechanismApproved(mechanismAddress)) {
            revert MechanismNotApproved(mechanismAddress);
        }
        _;
    }

    /// @notice Approves a new mechanism
    /// @param mechanismAddress Address of the mechanism to be approved
    function approveMechanism(address mechanismAddress) external onlyOwner {
        approvedMechanisms[mechanismAddress] = true;
    }

    /// @notice Removes mechanism
    /// @param mechanismAddress Address of the mechanism to be removed
    function removeMechanism(address mechanismAddress) external onlyOwner {
        approvedMechanisms[mechanismAddress] = false;
    }

    /// @notice Check if a given mechanism is approved
    /// @param mechanismAddress Address of the mechanism to be checked
    /// @return Whether the mechanism is approved
    function isMechanismApproved(address mechanismAddress)
        public
        view
        returns (bool)
    {
        return approvedMechanisms[mechanismAddress];
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "../fees/IFeeManager.sol";

/// @title IPixelToken
/// @author 0xEND
/// @notice  TODO: Staking contract for pixel tokens.
interface IStaked {
    /// @notice Stakes `amount` tokens of `msg.sender`. Throws if more than available
    /// @param amount Number of tokens to be staked
    function stake(uint256 amount) external;

    /// @notice Unstakes `amount` tokens of `msg.sender`. Throws if more than available
    /// @param amount Number of tokens to be staked
    function unstake(uint256 amount) external;

    /// @notice Stakes locked tokens. Throws if more than available
    /// @param from Account that currently holds the tokens
    /// @param lockedAddress Address that receieves the locked + staked tokens
    /// @param amount Number of tokens received
    /// @dev Only the Locked contract can call this.
    function stakeLocked(
        address from,
        address lockedAddress,
        uint256 amount
    ) external;

    /// @notice Unstake originally locked tokens of `lockedAddress`. Throws if more than available
    /// @param lockedAddress Recipient of the locked tokens to be staked
    /// @param amount Number of tokens to be unstaked + sent to `lockedAddress`
    /// @dev Only the Locked contract can call this.
    function unstakeLocked(address lockedAddress, uint256 amount) external;

    /// @notice Sets the address of the `Locked` contract. Only owner can call it.
    /// @param lockedContractAddress New address of the `Locked` contract
    function setLockedContractAddress(address lockedContractAddress) external;

    /// @notice Add a token in which we could get rewards
    /// @param tokenAddress Address of the ERC20
    function addRewardToken(address tokenAddress) external;

    /// @notice Returns all available reward tokens.
    function getRewardTokens() external view returns (address[] memory);

    /// @notice Get staked balance of a given user
    /// @param user Address for given user
    /// @return Staked tokens (not locked)
    function unlockedBalanceOf(address user) external view returns (uint256);

    /// @notice Get locked staked balance of a given user
    /// @param user Address for given user
    /// @return Staked locked tokens
    function lockedBalanceOf(address user) external view returns (uint256);

    /// @notice Called when transfering fees to this contract
    /// @param token Token in which fees were paid/transfered
    /// @param fees Fees involved in the txn
    function addFeesReceived(address token, IFeeManager.Fees memory fees)
        external
        returns (uint256);

    /// @notice Sends fees accrued as a sourcer to `msg.sender`
    function claimSourcerFees() external;

    /// @notice Sends to the contract owner protocol fees when no one is staking
    function claimNoStakingRewards() external;

    /// @notice Sends protocol fees accrued by staking  to `msg.sender`
    function claimRewards() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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