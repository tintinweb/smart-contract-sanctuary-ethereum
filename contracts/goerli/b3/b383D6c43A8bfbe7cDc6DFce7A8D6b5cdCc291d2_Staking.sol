// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma abicoder v2;

import "./libs/ECDSA.sol";
import "./interfaces/HMTokenInterface.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IEscrow.sol";
import "./libs/Math.sol";
import "./libs/Stakes.sol";

/**
 * @title Staking contract
 * @dev The Staking contract allows Operator, Exchange Oracle, Recording Oracle and Reputation Oracle to stake to Escrow.
 */
contract Staking is IStaking {
    using SafeMath for uint256;
    using Stakes for Stakes.Staker;

    // Owner address
    address public owner;

    // ERC20 Token address
    address public eip20;
    
    // Escrow factory address
    address public escrowFactory;

    // Reward pool address
    address public rewardPool;

    // Minimum amount of tokens an staker needs to stake
    uint256 public minimumStake;

    // Time in blocks to unstake
    uint32 public lockPeriod;

    // Staker stakes: staker => Stake
    mapping(address => Stakes.Staker) public stakes;

    // Allocations : escrowAddress => Allocation
    mapping(address => IStaking.Allocation) public allocations;

    // List of addresses allowed to slash stakes
    mapping(address => bool) public slashers;

    // 100% in parts per million
    uint32 private constant MAX_PPM = 1000000;

    /**
     * @dev Emitted when `staker` stake `tokens` amount.
     */
    event StakeDeposited(address indexed staker, uint256 tokens);

    /**
     * @dev Emitted when `staker` unstaked and locked `tokens` amount `until` block.
     */
    event StakeLocked(address indexed staker, uint256 tokens, uint256 until);

    /**
     * @dev Emitted when `staker` withdrew `tokens` staked.
     */
    event StakeWithdrawn(address indexed staker, uint256 tokens);

    /**
     * @dev Emitted when `staker` was slashed for a total of `tokens` amount.
     */
    event StakeSlashed(
        address indexed staker,
        uint256 tokens,
        uint256 reward
    );

    /**
     * @dev Emitted when `staker` allocated `tokens` amount to `escrowAddress`.
     */
    event StakeAllocated(
        address indexed staker,
        uint256 tokens,
        address indexed escrowAddress,
        uint256 createdAt
    );

    /**
     * @dev Emitted when `staker` close an allocation `escrowAddress`.
     */
    event AllocationClosed(
        address indexed staker,
        uint256 tokens,
        address indexed escrowAddress,
        uint256 closedAt
    );

    /**
     * @dev Emitted when `owner` set address as `staker` with `role`.
     */
    event SetStaker(address indexed staker, Stakes.Role indexed role);

    constructor(
        address _eip20,
        address _escrowFactory,
        uint256 _minimumStake,
        uint32 _lockPeriod
    ) {
        eip20 = _eip20;
        escrowFactory = _escrowFactory;
        owner = msg.sender;
        _setMinimumStake(_minimumStake);
        _setLockPeriod(_lockPeriod);
    }


    /**
     * @dev Return the list of the stakers with pagination.
     * @param _role Role of the stakers
     * @param _page Requested page
     * @param _resultsPerPage Results per page
     */
    /*function getListOfStakers(Stakes.Role _role, uint256 _page, uint256 _resultsPerPage) external view returns (Stakes.Staker[] memory) {
        return stakes;
    }*/

    /**
     * @dev Set the minimum stake amount.
     * @param _minimumStake Minimum stake
     */
    function setMinimumStake(uint256 _minimumStake) external override onlyOwner {
        _setMinimumStake(_minimumStake);
    }

    /**
     * @dev Set the minimum stake amount.
     * @param _minimumStake Minimum stake
     */
    function _setMinimumStake(uint256 _minimumStake) private {
        require(_minimumStake > 0, "Must be a positive number");
        minimumStake = _minimumStake;
    }

    /**
     * @dev Set the lock period for unstaking.
     * @param _lockPeriod Period in blocks to wait for token withdrawals after unstaking
     */
    function setLockPeriod(uint32 _lockPeriod) external override onlyOwner {
        _setLockPeriod(_lockPeriod);
    }

    /**
     * @dev Set the lock period for unstaking.
     * @param _lockPeriod Period in blocks to wait for token withdrawals after unstaking
     */
    function _setLockPeriod(uint32 _lockPeriod) private {
        require(_lockPeriod > 0, "Must be a positive number");
        lockPeriod = _lockPeriod;
    }

    /**
     * @dev Add address to the list of stakers.
     * @param _staker Staker's address
     * @param _role Role of the staker
     */
    function setStaker(address _staker, Stakes.Role _role) external onlyOwner {
        require(_staker != address(0), "Must be a valid address");
        require(_staker != msg.sender, "Staker cannot set himself");

        require(stakes[_staker].role != Stakes.Role.Null, "Staker already exists");

        Stakes.Staker memory staker = Stakes.Staker(
            _role,
            0,
            0,
            0,
            0
        );

        stakes[_staker] = staker;
        emit SetStaker(_staker, _role);
    }

    /**
     * @dev Return the result of checking if the staker has a specific role.
     * @param _staker Staker's address
     * @param _role Role of the staker
     * @return True if _staker has role
     */
    function isRole(address _staker, Stakes.Role _role) external view returns (bool) {
        Stakes.Staker memory staker = stakes[_staker];
        return staker.role == _role;
    }

    /**
     * @dev Return if escrowAddress is use for allocation.
     * @param _escrowAddress Address used as signer by the staker for an allocation
     * @return True if _escrowAddress already used
     */
    function isAllocation(address _escrowAddress) external view override returns (bool) {
        return _getAllocationState(_escrowAddress) != AllocationState.Null;
    }

    /**
     * @dev Getter that returns if an staker has any stake.
     * @param _staker Address of the staker
     * @return True if staker has staked tokens
     */
    function hasStake(address _staker) external view override returns (bool) {
        return stakes[_staker].tokensStaked > 0;
    }

    /**
     * @dev Return the allocation by job ID.
     * @param _escrowAddress Address used as allocation identifier
     * @return Allocation data
     */
    function getAllocation(address _escrowAddress)
        external
        view
        override
        returns (Allocation memory)
    {
        return _getAllocation(_escrowAddress);
    }

    /**
     * @dev Return the allocation by job ID.
     * @param _escrowAddress Address used as allocation identifier
     * @return Allocation data
     */
    function _getAllocation(address _escrowAddress)
        private
        view
        returns (Allocation memory)
    {
        return allocations[_escrowAddress];
    }

    /**
     * @dev Return the current state of an allocation.
     * @param _escrowAddress Address used as the allocation identifier
     * @return AllocationState
     */
    function getAllocationState(address _escrowAddress)
        external
        view
        override
        returns (AllocationState)
    {
        return _getAllocationState(_escrowAddress);
    }

    /**
     * @dev Return the current state of an allocation, partially depends on job status
     * @param _escrowAddress Job identifier (Escrow address)
     * @return AllocationState
     */
    function _getAllocationState(address _escrowAddress) private view returns (AllocationState) {
        Allocation storage allocation = allocations[_escrowAddress];

        if (allocation.staker == address(0)) {
            return AllocationState.Null;
        }

        IEscrow escrow = IEscrow(_escrowAddress);
        IEscrow.EscrowStatuses escrowStatus = escrow.getStatus();

        if (allocation.createdAt != 0 && allocation.tokens > 0 && escrowStatus == IEscrow.EscrowStatuses.Pending) {
            return AllocationState.Pending;
        }

        if (allocation.closedAt == 0 && escrowStatus == IEscrow.EscrowStatuses.Launched) {
            return AllocationState.Active;
        }

        if (allocation.closedAt > 0  && escrowStatus == IEscrow.EscrowStatuses.Complete) {
            return AllocationState.Completed;
        }

        return AllocationState.Closed;
    }

    /**
     * @dev Get the total amount of tokens staked by the staker.
     * @param _staker Address of the staker
     * @return Amount of tokens staked by the staker
     */
    function getStakedTokens(address _staker) external view override returns (uint256) {
        return stakes[_staker].tokensStaked;
    }

    /**
     * @dev Deposit tokens on the staker stake.
     * @param _tokens Amount of tokens to stake
     */
    function stake(uint256 _tokens) external override onlyStaker(msg.sender) {
        require(_tokens > 0, "Must be a positive number");
        require(
            stakes[msg.sender].tokensSecureStake().add(_tokens) >= minimumStake,
            "Total stake is below the minimum threshold"
        );

        // Transfer tokens to stake from caller to staking contract
        HMTokenInterface token = HMTokenInterface(eip20);
        token.transferFrom(msg.sender, address(this), _tokens);

        // Deposit tokens into the indexer stake
        stakes[msg.sender].deposit(_tokens);
        
        emit StakeDeposited(msg.sender, _tokens);
    }

    /**
     * @dev Unstake tokens from the staker stake, lock them until lock period expires.
     * @param _tokens Amount of tokens to unstake
     */
    function unstake(uint256 _tokens) external override onlyStaker(msg.sender) {
        Stakes.Staker storage staker = stakes[msg.sender];

        require(staker.tokensStaked > 0, "Must be a positive number");

        // Tokens to lock is capped to the available tokens
        uint256 tokensToLock = Math.min(staker.tokensUsed(), _tokens);
        require(tokensToLock > 0, "Must be a positive number");

        // Check minimum stake
        uint256 newStake = staker.tokensSecureStake().sub(tokensToLock);
        require(newStake == 0 || newStake >= minimumStake, "Total stake is below the minimum threshold");

        // Withdraw any unlocked tokens based the locking period
        uint256 tokensToWithdraw = staker.tokensWithdrawable();
        if (tokensToWithdraw > 0) {
            _withdraw(msg.sender);
        }

        // Update the staker stake locking tokens
        staker.lockTokens(tokensToLock, lockPeriod);

        emit StakeLocked(msg.sender, staker.tokensLocked, staker.tokensLockedUntil);
    }

    /**
     * @dev Withdraw staker tokens based on the locking period.
     */
    function withdraw() external override onlyStaker(msg.sender) {
        _withdraw(msg.sender);
    }

    /**
     * @dev Withdraw staker tokens once the lock period has passed.
     * @param _staker Address of staker to withdraw funds from
     */
    function _withdraw(address _staker) private {
        // Get tokens available for withdraw and update balance
        uint256 tokensToWithdraw = stakes[_staker].withdrawTokens();
        require(tokensToWithdraw > 0, "Stake has no available tokens for withdrawal");

        HMTokenInterface token = HMTokenInterface(eip20);
        token.transfer(_staker, tokensToWithdraw);

        emit StakeWithdrawn(_staker, tokensToWithdraw);
    }

    /**
     * @dev Slash the staker stake allocated to the escrow.
     * @param _staker Address of staker to slash
     * @param _escrowAddress Escrow address
     * @param _tokens Amount of tokens to slash from the indexer stake
     * @param _reward Amount of reward tokens to send to a reward pool
     */
    function slash(
        address _staker,
        address _escrowAddress,
        uint256 _tokens,
        uint256 _reward
    ) external override onlyValidator(msg.sender) {
        require(_escrowAddress != address(0), "Must be a valid address");

        Stakes.Staker storage staker = stakes[_staker];

        // Rewards comes from tokens slashed balance
        require(_tokens >= _reward, "Reward cannot be more than the allocated tokens");

        // Get allocate by escrow address
        Allocation storage allocation = allocations[_escrowAddress];
        
        // Only able to slash a non-zero number of tokens
        require(allocation.tokens > 0, "Must be a positive number");

        // Cannot slash stake of an indexer without any or enough stake
        require(_tokens <= allocation.tokens, "Slash tokens exceed allocated ones");

        // Remove tokens to slash from the allocation and staker allocated stake
        staker.unallocate(_tokens);
        allocation.tokens = allocation.tokens.sub(_tokens);

        // Transfer to reward pool a reward for slashing
        HMTokenInterface token = HMTokenInterface(eip20);
        token.transfer(rewardPool, _reward);

        emit StakeSlashed(msg.sender, _tokens, _reward);
    }

    /**
     * @dev Allocate available tokens to an escrow.
     * @param _escrowAddress The allocationID will work to identify collected funds related to this allocation
     * @param _tokens Amount of tokens to allocate
     */
    function allocate(
        address _escrowAddress,
        uint256 _tokens
    ) external override onlyStaker(msg.sender) {
        _allocate(msg.sender, _escrowAddress, _tokens);
    }

    /**
     * @dev Allocate available tokens to an escrow.
     * @param _staker Staker address to allocate funds from.
     * @param _escrowAddress The escrow address which collected funds related to this allocation
     * @param _tokens Amount of tokens to allocate
     */
    function _allocate(
        address _staker,
        address _escrowAddress,
        uint256 _tokens
    ) private {
        // Check allocation
        require(_escrowAddress != address(0), "Must be a valid address");
        require(
            stakes[msg.sender].tokensAvailable() >= _tokens,
            "Insufficient amount of tokens in the stake"
        );
        require(_tokens > 0, "Must be a positive number");
        require(_getAllocationState(_escrowAddress) == AllocationState.Null, "Allocation has a null state");

        // Creates an allocation
        Allocation memory allocation = Allocation(
            _escrowAddress, // Escrow address
            _staker, // Staker address
            _tokens, // Tokens allocated
            block.number, // createdAt
            0 // closedAt
        );

        allocations[_escrowAddress] = allocation;
        stakes[_staker].allocate(allocation.tokens);

        emit StakeAllocated(
            _staker,
            allocation.tokens,
            _escrowAddress,
            allocation.createdAt
        );
    }

    /**
     * @dev Close an allocation and free the staked tokens.
     * @param _escrowAddress The allocation identifier
     */
    function closeAllocation(address _escrowAddress) external override onlyStaker(msg.sender) {
        _closeAllocation(_escrowAddress);
    }

    /**
     * @dev Close an allocation and free the staked tokens.
     * @param _escrowAddress The allocation identifier
     */
    function _closeAllocation(address _escrowAddress) private {
        // Allocation must exist and be active
        AllocationState allocationState = _getAllocationState(_escrowAddress);
        require(allocationState == AllocationState.Completed, "Allocation has no completed state");

        // Get allocation
        Allocation memory allocation = allocations[_escrowAddress];

        allocation.closedAt = block.number;
        uint256 diffInBlocks = Math.diffOrZero(allocation.closedAt, allocation.createdAt);
        require(diffInBlocks > 0, "Allocation cannot be closed so early");

        stakes[allocation.staker].unallocate(allocation.tokens);

        emit AllocationClosed(
            allocation.staker,
            allocation.tokens,
            _escrowAddress,
            allocation.closedAt
        );
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not a owner");
        _;
    }

    modifier onlyStaker(address _staker) {
        Stakes.Staker memory staker = stakes[_staker];
        require(staker.role != Stakes.Role.Null, "Caller is not a staker");
        _;
    }

    modifier onlyValidator(address _staker) {
        Stakes.Staker memory staker = stakes[_staker];
        require(staker.role == Stakes.Role.Validator, "Caller is not a validator");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "./Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface HMTokenInterface {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance The balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function transferBulk(address[] calldata _tos, uint256[] calldata _values, uint256 _txId) external returns (uint256 _bulkCount);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./SafeMath.sol";

/**
 * @title Math Library
 * @notice A collection of functions to perform math operations
 */
library Math {
    using SafeMath for uint256;

    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Calculates the weighted average of two values pondering each of these
     * values based on configured weights. The contribution of each value N is
     * weightN/(weightA + weightB).
     * @param valueA The amount for value A
     * @param weightA The weight to use for value A
     * @param valueB The amount for value B
     * @param weightB The weight to use for value B
     */
    function weightedAverage(
        uint256 valueA,
        uint256 weightA,
        uint256 valueB,
        uint256 weightB
    ) internal pure returns (uint256) {
        return valueA.mul(weightA).add(valueB.mul(weightB)).div(weightA.add(weightB));
    }

    /**
     * @dev Returns the difference between two numbers or zero if negative.
     */
    function diffOrZero(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y) ? x.sub(y) : 0;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return
         a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma abicoder v2;

import "./SafeMath.sol";
import "./Math.sol";

/**
 * @title Structures, methods and data are available to manage the staker state.
 */
library Stakes {
    using SafeMath for uint256;
    using Stakes for Stakes.Staker;

    /**
     * @dev Possible roles for participants
     * Roles:
     * - Null = Staker == address(0)
     * - Operator = Job Launcher
     * - Validator = Validator
     * - ExchangeOracle = Exchange Oracle
     * - ReputationOracle = Reputation Oracle
     * - RecordingOracle = Recording Oracle
     */
    enum Role {
        Null,
        Operator,
        Validator,
        ExchangeOracle,
        ReputationOracle,
        RecordingOracle
    }

    struct Staker {
        Role role;
        uint256 tokensStaked; // Tokens staked by the Staker
        uint256 tokensAllocated; // Tokens allocated for jobs
        uint256 tokensLocked; // Tokens locked for withdrawal
        uint256 tokensLockedUntil; // Tokens locked until time
    }

    /**
     * @dev Deposit tokens to the staker stake.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to deposit
     */
    function deposit(Stakes.Staker storage stake, uint256 _tokens) internal {
        stake.tokensStaked = stake.tokensStaked.add(_tokens);
    }

    /**
     * @dev Withdraw tokens from the staker stake.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to release
     */
    function withdraw(Stakes.Staker storage stake, uint256 _tokens) internal {
        stake.tokensStaked = stake.tokensStaked.sub(_tokens);
    }

    /**
     * @dev Add tokens from the main stack to tokensAllocated.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to allocate
     */
    function allocate(Stakes.Staker storage stake, uint256 _tokens) internal {
        stake.tokensAllocated = stake.tokensAllocated.add(_tokens);
    }

    /**
     * @dev Unallocate tokens from a escrowAddress back to the main stack.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to unallocate
     */
    function unallocate(Stakes.Staker storage stake, uint256 _tokens) internal {
        stake.tokensAllocated = stake.tokensAllocated.sub(_tokens);
    }

    /**
     * @dev Lock tokens until a lock period pass.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to unstake
     * @param _period Period in blocks that need to pass before withdrawal
     */
    function lockTokens(
        Stakes.Staker storage stake,
        uint256 _tokens,
        uint256 _period
    ) internal {
        uint256 lockingPeriod = _period;

        if (stake.tokensLocked > 0) {
            lockingPeriod = Math.weightedAverage(
                Math.diffOrZero(stake.tokensLockedUntil, block.number), // Remaining lock period
                stake.tokensLocked,
                _period,
                _tokens
            );
        }

        stake.tokensLocked = stake.tokensLocked.add(_tokens);
        stake.tokensLockedUntil = block.number.add(lockingPeriod);
    }

    /**
     * @dev Unlock tokens.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to unkock
     */
    function unlockTokens(Stakes.Staker storage stake, uint256 _tokens) internal {
        stake.tokensLocked = stake.tokensLocked.sub(_tokens);
        if (stake.tokensLocked == 0) {
            stake.tokensLockedUntil = 0;
        }
    }

    /**
     * @dev Return all tokens available for withdrawal.
     * @param stake Staker struct
     * @return Amount of tokens available for withdrawal
     */
    function withdrawTokens(Stakes.Staker storage stake) internal returns (uint256) {
        uint256 tokensToWithdraw = stake.tokensWithdrawable();

        if (tokensToWithdraw > 0) {
            stake.unlockTokens(tokensToWithdraw);
            stake.withdraw(tokensToWithdraw);
        }

        return tokensToWithdraw;
    }

    /**
     * @dev Return all tokens available in stake.
     * @param stake Staker struct
     * @return Token amount
     */
    function tokensAvailable(Stakes.Staker memory stake) internal pure returns (uint256) {
        return stake.tokensStaked.sub(stake.tokensUsed());
    }

    /**
     * @dev Return all tokens used in allocations and locked for withdrawal.
     * @param stake Staker struct
     * @return Token amount
     */
    function tokensUsed(Stakes.Staker memory stake) internal pure returns (uint256) {
        return stake.tokensAllocated.add(stake.tokensLocked);
    }

    /**
     * @dev Return the amount of tokens staked which are not locked.
     * @param stake Staker struct
     * @return Token amount
     */
    function tokensSecureStake(Stakes.Staker memory stake) internal pure returns (uint256) {
        return stake.tokensStaked.sub(stake.tokensLocked);
    }

    /**
     * @dev Tokens available for withdrawal after lock period.
     * @param stake Staker struct
     * @return Token amount
     */
    function tokensWithdrawable(Stakes.Staker memory stake) internal view returns (uint256) {
        if (stake.tokensLockedUntil == 0 || block.number < stake.tokensLockedUntil) {
            return 0;
        }
        return stake.tokensLocked;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma abicoder v2;

interface IStaking {
    /**
     * @dev Possible states an allocation can be
     * States:
     * - Null = Staker == address(0)
     * - Pending = not Null && tokens > 0 && escrowAddress status == Pending
     * - Active = Pending && escrowAddress status == Launched
     * - Closed = Active && closedAt != 0
     * - Completed = Closed && closedAt && escrowAddress status == Complete
     */
    enum AllocationState {
        Null,
        Pending,
        Active,
        Closed,
        Completed
    }

    /**
     * @dev Allocate HMT tokens for the purpose of serving queries of a subgraph deployment
     * An allocation is created in the allocate() function and consumed in claim()
     */
    struct Allocation {
        address escrowAddress;
        address staker;
        uint256 tokens; // Tokens allocated to a escrowAddress
        uint256 createdAt; // Time when allocation was created
        uint256 closedAt; // Time when allocation was closed
    }

    function setMinimumStake(uint256 _minimumStake) external;

    function setLockPeriod(uint32 _lockPeriod) external;

    // function setStaker(address _staker, Role _role) external;

    // function isRole(address _account, Role role) external view returns (bool);

    function isAllocation(address _escrowAddress) external view returns (bool);

    function hasStake(address _indexer) external view returns (bool);

    function getAllocation(address _escrowAddress) external view returns (Allocation memory);

    function getAllocationState(address _escrowAddress) external view returns (AllocationState);

    function getStakedTokens(address _staker) external view returns (uint256);

    function stake(uint256 _tokens) external;

    function unstake(uint256 _tokens) external;

    function withdraw() external;

    function slash(
        address _staker,
        address _escrowAddress,
        uint256 _tokens,
        uint256 _reward
    ) external;

    function allocate(
        address escrowAddress,
        uint256 _tokens
    ) external;

    function closeAllocation(address _escrowAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./HMTokenInterface.sol";
import "../libs/SafeMath.sol";


interface IEscrow {
    enum EscrowStatuses {Launched, Pending, Partial, Paid, Complete, Cancelled}

    function addTrustedHandlers(address[] memory _handlers) external;

    function setup(
        address _reputationOracle,
        address _recordingOracle,
        uint256 _reputationOracleStake,
        uint256 _recordingOracleStake,
        string memory _url,
        string memory _hash
    ) external;

    function abort() external;

    function cancel() external returns (bool);

    function complete() external;

    function storeResults(string memory _url, string memory _hash) external;

    function bulkPayOut(
        address[] memory _recipients,
        uint256[] memory _amounts,
        string memory _url,
        string memory _hash,
        uint256 _txId
    ) external returns (bool); 

    function getStatus() external view returns (EscrowStatuses);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.9;

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