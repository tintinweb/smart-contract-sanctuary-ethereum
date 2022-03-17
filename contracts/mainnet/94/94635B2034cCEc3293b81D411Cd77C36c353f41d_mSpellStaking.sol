// SPDX-License-Identifier: MIT
// Inspired by Stable Joe Staking which in turn is derived from the SushiSwap MasterChef contract

pragma solidity 0.8.10;
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "../libraries/BoringOwnable.sol";

/**
 * @title Magic Spell Staking
 * @author 0xMerlin
 */
contract mSpellStaking is BoringOwnable {
    using SafeTransferLib for ERC20;

    /// @notice Info of each user
    struct UserInfo {
        uint128 amount;

        uint128 rewardDebt;
        uint128 lastAdded;
        /**
         * @notice We do some fancy math here. Basically, any point in time, the amount of JOEs
         * entitled to a user but is pending to be distributed is:
         *
         *   pending reward = (user.amount * accRewardPerShare) - user.rewardDebt[token]
         *
         * Whenever a user deposits or withdraws SPELL. Here's what happens:
         *   1. accRewardPerShare (and `lastRewardBalance`) gets updated
         *   2. User receives the pending reward sent to his/her address
         *   3. User's `amount` gets updated
         *   4. User's `rewardDebt[token]` gets updated
         */
    }

    ERC20 public immutable spell;
    /// @notice Array of tokens that users can claim
    ERC20 public immutable mim;
    /// @notice Last reward balance of `token`
    uint256 public lastRewardBalance;

    /// @notice amount of time that the position is locked for.
    uint256 private constant LOCK_TIME = 24 hours;
    bool public toggleLockup;

    /// @notice Accumulated `token` rewards per share, scaled to `ACC_REWARD_PER_SHARE_PRECISION`
    uint256 public accRewardPerShare;
    /// @notice The precision of `accRewardPerShare`
    uint256 public constant ACC_REWARD_PER_SHARE_PRECISION = 1e24;

    /// @dev Info of each user that stakes SPELL
    mapping(address => UserInfo) public userInfo;

    /// @notice Emitted when a user deposits SPELL
    event Deposit(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws SPELL
    event Withdraw(address indexed user, uint256 amount);

    /// @notice Emitted when a user claims reward
    event ClaimReward(address indexed user, uint256 amount);

    /// @notice Emitted when a user emergency withdraws its SPELL
    event EmergencyWithdraw(address indexed user, uint256 amount);

    /**
     * @notice Initialize a new mSpellStaking contract
     * @dev This contract needs to receive an ERC20 `_rewardToken` in order to distribute them
     * (with MoneyMaker in our case)
     * @param _mim The address of the MIM token
     * @param _spell The address of the SPELL token
     */
    constructor(
        ERC20 _mim,
        ERC20 _spell
    ) {
        require(address(_mim) != address(0), "mSpellStaking: reward token can't be address(0)");
        require(address(_spell) != address(0), "mSpellStaking: spell can't be address(0)");

        spell = _spell;
        toggleLockup = true;

        mim = _mim;
    }

    /**
     * @notice Deposit SPELL for reward token allocation
     * @param _amount The amount of SPELL to deposit
     */
    function deposit(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];

        uint256 _previousAmount = user.amount;
        uint256 _newAmount = user.amount + _amount;
        user.amount = uint128(_newAmount);
        user.lastAdded = uint128(block.timestamp);

        updateReward();

        uint256 _previousRewardDebt = user.rewardDebt;
        user.rewardDebt = uint128(_newAmount * accRewardPerShare / ACC_REWARD_PER_SHARE_PRECISION);

        if (_previousAmount != 0) {
            uint256 _pending = _previousAmount * accRewardPerShare / ACC_REWARD_PER_SHARE_PRECISION - _previousRewardDebt;
            if (_pending != 0) {
                safeTokenTransfer(mim, msg.sender, _pending);
                emit ClaimReward(msg.sender, _pending);
            }
        }

        spell.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice View function to see pending reward token on frontend
     * @param _user The address of the user
     * @return `_user`'s pending reward token
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 _totalSpell = spell.balanceOf(address(this));
        uint256 _accRewardTokenPerShare = accRewardPerShare;

        uint256 _rewardBalance = mim.balanceOf(address(this));

        if (_rewardBalance != lastRewardBalance && _totalSpell != 0) {
            uint256 _accruedReward = _rewardBalance - lastRewardBalance;
            _accRewardTokenPerShare = _accRewardTokenPerShare + _accruedReward * ACC_REWARD_PER_SHARE_PRECISION / _totalSpell;
        }
        return user.amount * _accRewardTokenPerShare / ACC_REWARD_PER_SHARE_PRECISION - user.rewardDebt;
    }

    /**
     * @notice Withdraw SPELL and harvest the rewards
     * @param _amount The amount of SPELL to withdraw
     */
    function withdraw(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];

        require(!toggleLockup || user.lastAdded + LOCK_TIME < block.timestamp, "mSpell: Wait for LockUp");

        uint256 _previousAmount = user.amount;
        uint256 _newAmount = user.amount - _amount;
        user.amount = uint128(_newAmount);

        updateReward();

        uint256 _pending = _previousAmount * accRewardPerShare / ACC_REWARD_PER_SHARE_PRECISION - user.rewardDebt;
        user.rewardDebt = uint128(_newAmount * accRewardPerShare / ACC_REWARD_PER_SHARE_PRECISION);

        if (_pending != 0) {
            safeTokenTransfer(mim, msg.sender, _pending);
            emit ClaimReward(msg.sender, _pending);
        }

        spell.safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY
     */
    function emergencyWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];

        uint256 _amount = user.amount;

        user.amount = 0;
        user.rewardDebt = 0;

        spell.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _amount);
    }

    /**
     * @notice Update reward variables
     * @dev Needs to be called before any deposit or withdrawal
     */
    function updateReward() public {
        uint256 _rewardBalance = mim.balanceOf(address(this));
        uint256 _totalSpell = spell.balanceOf(address(this));

        // Did mSpellStaking receive any token
        if (_rewardBalance == lastRewardBalance || _totalSpell == 0) {
            return;
        }

        uint256 _accruedReward = _rewardBalance - lastRewardBalance;

        accRewardPerShare = accRewardPerShare + _accruedReward * ACC_REWARD_PER_SHARE_PRECISION / _totalSpell;
        lastRewardBalance = _rewardBalance;
    }

    /**
     * @notice Safe token transfer function, just in case if rounding error
     * causes pool to not have enough reward tokens
     * @param _token The address of then token to transfer
     * @param _to The address that will receive `_amount` `rewardToken`
     * @param _amount The amount to send to `_to`
     */
    function safeTokenTransfer(
        ERC20 _token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 _rewardBalance = _token.balanceOf(address(this));

        if (_amount > _rewardBalance) {
            lastRewardBalance = lastRewardBalance - _rewardBalance;
            _token.safeTransfer(_to, _rewardBalance);
        } else {
            lastRewardBalance = lastRewardBalance - _amount;
            _token.safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice Allows to enable and disable the lockup
     * @param status The new lockup status
     */

     function toggleLockUp(bool status) external onlyOwner {
        toggleLockup = status;
     }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                           EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");

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
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
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