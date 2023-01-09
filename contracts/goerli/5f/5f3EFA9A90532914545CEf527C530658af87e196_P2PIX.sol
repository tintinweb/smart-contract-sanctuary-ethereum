// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library DataTypes {
    struct Deposit {
        /// @dev Remaining tokens available.
        uint256 remaining;
        /// @dev The PIX account for the seller receive transactions.
        string pixTarget;
        address seller;
        /// @dev ERC20 stable token address.
        address token;
        /// @dev Could be invalidated by the seller.
        bool valid;
    }

    struct Lock {
        uint256 depositID;
        /// @dev Amount to be paid for relayer.
        uint256 relayerPremium;
        /// @dev Amount to be tranfered via PIX.
        uint256 amount;
        /// @dev If not paid at this block will be expired.
        uint256 expirationBlock;
        /// @dev Where the tokens are sent the when order gets validated.
        address buyerAddress;
        /// @dev Relayer's target address that receives `relayerPremium` funds.
        address relayerTarget;
        /// @dev Relayer address (msg.sender) that facilitated this transaction.
        /// @dev Reputation points accruer.
        address relayerAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// prettier-ignore
interface EventAndErrors {
    /// ███ Events ████████████████████████████████████████████████████████████

    event DepositAdded(
        address indexed seller,
        uint256 depositID,
        address token,
        uint256 amount
    );
    event DepositClosed(
        address indexed seller,
        uint256 depositID
    );
    event DepositWithdrawn(
        address indexed seller,
        uint256 depositID,
        uint256 amount
    );
    event LockAdded(
        address indexed buyer,
        bytes32 indexed lockID,
        uint256 depositID,
        uint256 amount
    );
    event LockReleased(
        address indexed buyer, 
        bytes32 lockId,
        uint256 amount
    );
    event LockReturned(
        address indexed buyer, 
        bytes32 lockId
    );
    event FundsWithdrawn(
        address owner, 
        uint256 amount
    );
    event RootUpdated(
        address seller, 
        bytes32 merkleRoot
    );
    event AllowedERC20Updated(
        address indexed token,
        bool indexed state
    );
    event ReputationUpdated(address reputation);
    event LockBlocksUpdated(uint256 blocks);
    event ValidSignersUpdated(address[] signers);

    /// ███ Errors ████████████████████████████████████████████████████████████

    /// @dev Deposit already exist and it is still valid.
    /// @dev 0xc44bd765
    error DepositAlreadyExists();
    /// @dev Only seller could call this function.
    /// @dev `msg.sender` and the seller differ.
    /// @dev 0x85d1f726
    error OnlySeller();
    /// @dev Lock not expired or already released.
    /// @dev Another lock with same ID is not expired yet.
    /// @dev 0xd0404f85
    error NotExpired();
    /// @dev Loop bounds have overflowed.
    /// @dev 0xdfb035c9
    error LoopOverflow();
    /// @dev Deposit not valid anymore.
    /// @dev 0xb2e532de
    error InvalidDeposit();
    /// @dev Not enough token remaining on deposit.
    /// @dev 0x22bbb43c
    error NotEnoughTokens();
    /// @dev Lock already released or returned.
    /// @dev 0x63b4904e
    error AlreadyReleased();
    /// @dev Transaction already used to unlock payment.
    /// @dev 0xf490a6ea
    error TxAlreadyUsed();
    /// @dev Signer is not a valid signer.
    /// @dev 0x815e1d64
    error InvalidSigner();
    /// @dev Address doesn't exist in a MerkleTree.
    /// @dev Address not allowed as relayer.
    /// @dev 0x3b8474be
    error AddressDenied();
    /// @dev Arrays' length don't match.
    /// @dev 0xff633a38
    error LengthMismatch();
    /// @dev No tokens array provided as argument.
    /// @dev 0xdf957883
    error NoTokens();
    /// @dev Token address not allowed to be deposited.
    /// @dev 0x1578328e
    error TokenDenied();
    /// @dev Wished amount to be locked exceeds the limit allowed.
    /// @dev 0x1c18f846
    error AmountNotAllowed();
    /// @dev Reverts when success return value returns false.
    /// @dev 0xe10bf1cc
    error StaticCallFailed();
    /// @dev Reverts on an expired lock.
    /// @dev 0xf6fafba0
    error LockExpired();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(
        address indexed user,
        address indexed newOwner
    );

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

    function setOwner(
        address newOwner
    ) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IReputation {
    function limiter(
        uint256 _userCredit
    ) external pure returns (uint256 _spendLimit);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

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

    mapping(address => mapping(address => uint256))
        public allowance;

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

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
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

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

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
        require(
            deadline >= block.timestamp,
            "PERMIT_DEADLINE_EXPIRED"
        );

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

            require(
                recoveredAddress != address(0) &&
                    recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR()
        public
        view
        virtual
        returns (bytes32)
    {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator()
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
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

    function _mint(
        address to,
        uint256 amount
    ) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(
        address from,
        uint256 amount
    ) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

/// @title Counters
/// @author buf0t9
/// @author Modified from OpenZeppelin Contracts
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol)
/// @notice Provides counters that can only be incremented, decrementedor reset.
/// @dev Include with `using Counters for Counters.Counter;`
library Counters {
    // solhint-disable no-inline-assembly
    struct Counter {
        /// @dev Interactions must be restricted to the library's function.
        uint256 _val; // := 0
    }

    /// @dev 0xce3a3d37
    error DecOverflow();

    function current(
        Counter storage counter
    ) internal view returns (uint256 _val) {
        assembly {
            _val := sload(counter.slot)
        }
    }

    function increment(Counter storage counter) internal {
        assembly {
            let _val := sload(counter.slot)
            sstore(counter.slot, add(_val, 0x01))
        }
    }

    function decrement(Counter storage counter) internal {
        assembly {
            let _val := sload(counter.slot)
            if or(iszero(_val), lt(_val, 0x00)) {
                mstore(0x00, 0xce3a3d37)
                revert(0x1c, 0x04)
            }
            sstore(counter.slot, sub(_val, 0x01))
        }
    }

    function reset(Counter storage counter) internal {
        assembly {
            sstore(counter.slot, 0)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @notice Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.
/// @author Solady
/// (https://github.com/vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solmate
/// (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from OpenZeppelin
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)
library MerkleProofLib {
    /// @dev Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(
                    proof.offset,
                    shl(5, proof.length)
                )
                // Initialize `offset` to the offset of `proof` in the calldata.
                let offset := proof.offset
                // Iterate over proof elements to compute root hash.
                for {

                } 1 {

                } {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(
                        5,
                        gt(leaf, calldataload(offset))
                    )
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(
                        xor(scratch, 0x20),
                        calldataload(offset)
                    )
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    if iszero(lt(offset, end)) {
                        break
                    }
                }
            }
            isValid := eq(leaf, root)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @notice Reentrancy protection for smart contracts.
/// @author z0r0z.eth
/// @author Modified from Seaport
///         (https://github.com/ProjectOpenSea/seaport/blob/main/contracts/lib/ReentrancyGuard.sol)
/// @author Modified from Solmate
///         (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    error Reentrancy();

    uint256 private guard = 1;

    modifier nonReentrant() virtual {
        setReentrancyGuard();

        _;

        clearReentrancyGuard();
    }

    /// @dev Check guard sentinel value and set it.
    function setReentrancyGuard() internal virtual {
        if (guard == 2) revert Reentrancy();

        guard = 2;
    }

    /// @dev Unset sentinel value.
    function clearReentrancyGuard() internal virtual {
        guard = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { ERC20 } from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(
        address to,
        uint256 amount
    ) internal {
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
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                0,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(4, from) // Append the "from" argument.
            mstore(36, to) // Append the "to" argument.
            mstore(68, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(
                        eq(mload(0), 1),
                        gt(returndatasize(), 31)
                    ),
                    iszero(returndatasize())
                ),
                // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
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
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                0,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(
                        eq(mload(0), 1),
                        gt(returndatasize(), 31)
                    ),
                    iszero(returndatasize())
                ),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
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
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                0,
                0x095ea7b300000000000000000000000000000000000000000000000000000000
            )
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(
                        eq(mload(0), 1),
                        gt(returndatasize(), 31)
                    ),
                    iszero(returndatasize())
                ),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

///         ______         __
/// .-----.|__    |.-----.|__|.--.--.
/// |  _  ||    __||  _  ||  ||_   _|
/// |   __||______||   __||__||__.__|
/// |__|           |__|
///

import { Owned } from "./lib/auth/Owned.sol";
import { Counters } from "./lib/utils/Counters.sol";
import { ERC20, SafeTransferLib } from "./lib/utils/SafeTransferLib.sol";
import { IReputation } from "./lib/interfaces/IReputation.sol";
import { MerkleProofLib as Merkle } from "./lib/utils/MerkleProofLib.sol";
import { ReentrancyGuard } from "./lib/utils/ReentrancyGuard.sol";
import { EventAndErrors } from "./EventAndErrors.sol";
import { DataTypes as DT } from "./DataTypes.sol";

contract P2PIX is
    EventAndErrors,
    Owned(msg.sender),
    ReentrancyGuard
{
    // solhint-disable use-forbidden-name
    // solhint-disable no-inline-assembly

    using Counters for Counters.Counter;
    using DT for DT.Deposit;
    using DT for DT.Lock;

    /// ███ Storage ████████████████████████████████████████████████████████████

    IReputation public reputation;
    Counters.Counter public depositCount;

    /// @dev Default blocks that lock will hold tokens.
    uint256 public defaultLockBlocks;
    /// @dev The scalar of BRZ token.
    uint256 public constant WAD = 1e18;

    /// @dev Stores an relayer's last computed credit.
    mapping(uint256 => uint256) public userRecord;
    /// @dev List of valid Bacen signature addresses
    mapping(uint256 => bool) public validBacenSigners;
    /// @dev Seller list of deposits
    mapping(uint256 => DT.Deposit) public mapDeposits;
    /// @dev List of Locks.
    mapping(bytes32 => DT.Lock) public mapLocks;
    /// @dev List of Pix transactions already signed.
    mapping(bytes32 => bool) public usedTransactions;
    /// @dev Seller casted to key => Seller's allowlist merkleroot.
    mapping(uint256 => bytes32) public sellerAllowList;
    /// @dev Tokens allowed to serve as the underlying amount of a deposit.
    mapping(ERC20 => bool) public allowedERC20s;

    /// ███ Constructor ████████████████████████████████████████████████████████

    constructor(
        uint256 defaultBlocks,
        address[] memory validSigners,
        IReputation _reputation,
        address[] memory tokens,
        bool[] memory tokenStates
    ) payable {
        setDefaultLockBlocks(defaultBlocks);
        setReputation(_reputation);
        setValidSigners(validSigners);
        tokenSettings(tokens, tokenStates);
    }

    /// ███ Public FX ██████████████████████████████████████████████████████████

    /// @notice Creates a deposit order based on a seller's
    /// offer of an amount of ERC20 tokens.
    /// @dev Seller needs to send his tokens to the P2PIX smart contract.
    /// @param _pixTarget Pix key destination provided by the offer's seller.
    /// @param allowlistRoot Optional allow list merkleRoot update `bytes32` value.
    /// @return depositID The `uint256` return value provided
    /// as the deposit identifier.
    /// @dev Function sighash: 0xbfe07da6.
    function deposit(
        address _token,
        uint256 _amount,
        string calldata _pixTarget,
        bytes32 allowlistRoot
    ) public returns (uint256 depositID) {
        ERC20 t = ERC20(_token);
        if (!allowedERC20s[t]) revert TokenDenied();

        (depositID) = _encodeDepositID();

        DT.Deposit memory d = DT.Deposit({
            remaining: _amount,
            pixTarget: _pixTarget,
            seller: msg.sender,
            token: _token,
            valid: true
        });

        setReentrancyGuard();

        if (allowlistRoot != 0) {
            setRoot(msg.sender, allowlistRoot);
        }

        mapDeposits[depositID] = d;
        depositCount.increment();

        SafeTransferLib.safeTransferFrom(
            t,
            msg.sender,
            address(this),
            _amount
        );

        clearReentrancyGuard();

        emit DepositAdded(
            msg.sender,
            depositID,
            _token,
            _amount
        );
    }

    /// @notice Enables seller to invalidate future
    /// locks made to his/her token offering order.
    /// @dev This function does not affect any ongoing active locks.
    /// @dev Function sighash: 0x72fada5c.

    function cancelDeposit(uint256 depositID) public {
        _onlySeller(depositID);
        mapDeposits[depositID].valid = false;
        emit DepositClosed(
            mapDeposits[depositID].seller,
            depositID
        );
    }

    /// @notice Public method designed to lock an remaining amount of
    /// the deposit order of a seller.
    /// @dev This method can be performed either by:
    /// - An user allowed via the seller's allowlist;
    /// - An user with enough userRecord to lock the wished amount;
    /// @dev There can only exist a lock per each `_amount` partitioned
    /// from the total `remaining` value.
    /// @dev Locks can only be performed in valid orders.
    /// @param _buyerAddress The address of the buyer of a `_depositID`.
    /// @param _relayerTarget Target address entitled to the `relayerPremium`.
    /// @param _relayerPremium The refund/premium owed to a relayer.
    /// @param _amount The deposit's remaining amount wished to be locked.
    /// @param merkleProof This value should be:
    /// - Provided as a pass if the `msg.sender` is in the seller's allowlist;
    /// - Left empty otherwise;
    /// @param expiredLocks An array of `bytes32` identifiers to be
    /// provided so to unexpire locks using this transaction gas push.
    /// @return lockID The `bytes32` value returned as the lock identifier.
    /// @dev Function sighash: 0x03aaf306.
    function lock(
        uint256 _depositID,
        address _buyerAddress,
        address _relayerTarget,
        uint256 _relayerPremium,
        uint256 _amount,
        bytes32[] calldata merkleProof,
        bytes32[] calldata expiredLocks
    ) public nonReentrant returns (bytes32 lockID) {
        unlockExpired(expiredLocks);
        DT.Deposit storage d = mapDeposits[_depositID];

        if (!d.valid) revert InvalidDeposit();
        if (d.remaining < _amount) revert NotEnoughTokens();

        (lockID) = _encodeLockID(
            _depositID,
            _amount,
            _buyerAddress
        );

        DT.Lock memory l = DT.Lock({
            depositID: _depositID,
            relayerPremium: _relayerPremium,
            amount: _amount,
            expirationBlock: (block.number +
                defaultLockBlocks),
            buyerAddress: _buyerAddress,
            relayerTarget: _relayerTarget,
            relayerAddress: msg.sender
        });

        if (merkleProof.length != 0) {
            merkleVerify(
                merkleProof,
                sellerAllowList[_castAddrToKey(d.seller)],
                msg.sender
            );

            _addLock(lockID, l, d);

            // Halt execution and output `lockID`.
            return lockID;
        } else {
            if (l.amount <= 1e2 ether) {
                _addLock(lockID, l, d);
                // Halt execution and output `lockID`.
                return lockID;
            } else {
                uint256 userCredit = userRecord[
                    _castAddrToKey(msg.sender)
                ];
                uint256 spendLimit;
                (spendLimit) = _limiter(userCredit / WAD);

                if (
                    l.amount > (spendLimit * WAD) ||
                    l.amount > 1e6 ether
                ) revert AmountNotAllowed();

                _addLock(lockID, l, d);
                // Halt execution and output `lockID`.
                return lockID;
            }
        }
    }

    /// @notice Lock release method that liquidate lock
    /// orders and distributes relayer fees.
    /// @dev This method can be called by any public actor
    /// as long the signature provided is valid.
    /// @dev `relayerPremium` gets splitted equaly
    /// if `relayerTarget` addresses differ.
    /// @dev If the `msg.sender` of this method and `l.relayerAddress` are the same,
    /// `msg.sender` accrues both l.amount and l.relayerPremium as userRecord credit.
    ///  In case of they differing:
    /// - `lock` caller gets accrued with `l.amount` as userRecord credit;
    /// - `release` caller gets accrued with `l.relayerPremium` as userRecord credit;
    /// @param _relayerTarget Target address entitled to the `relayerPremim`.
    /// @dev Function sighash: 0x4e1389ed.
    function release(
        bytes32 lockID,
        address _relayerTarget,
        bytes32 pixTimestamp,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public nonReentrant {
        DT.Lock storage l = mapLocks[lockID];

        if (l.amount == 0) revert AlreadyReleased();
        if (l.expirationBlock < block.number)
            revert LockExpired();

        DT.Deposit storage d = mapDeposits[l.depositID];
        bytes32 message = keccak256(
            abi.encodePacked(
                d.pixTarget,
                l.amount,
                pixTimestamp
            )
        );
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                message
            )
        );

        if (usedTransactions[message] == true)
            revert TxAlreadyUsed();

        uint256 signer = _castAddrToKey(
            ecrecover(messageDigest, v, r, s)
        );

        if (!validBacenSigners[signer])
            revert InvalidSigner();

        ERC20 t = ERC20(d.token);

        // We cache values before zeroing them out.
        uint256 lockAmount = l.amount;
        uint256 totalAmount = (lockAmount - l.relayerPremium);

        l.amount = 0;
        l.expirationBlock = 0;
        usedTransactions[message] = true;

        if (msg.sender != l.relayerAddress) {
            userRecord[_castAddrToKey(msg.sender)] += l
                .relayerPremium;
            userRecord[
                _castAddrToKey(l.relayerAddress)
            ] += lockAmount;
        } else {
            userRecord[_castAddrToKey(msg.sender)] += (l
                .relayerPremium + lockAmount);
        }

        SafeTransferLib.safeTransfer(
            t,
            l.buyerAddress,
            totalAmount
        );

        // Method doesn't check for zero address.
        if (l.relayerPremium != 0) {
            if (_relayerTarget != l.relayerTarget) {
                SafeTransferLib.safeTransfer(
                    t,
                    l.relayerTarget,
                    (l.relayerPremium >> 1)
                );
                SafeTransferLib.safeTransfer(
                    t,
                    _relayerTarget,
                    (l.relayerPremium >> 1)
                );
            } else {
                SafeTransferLib.safeTransfer(
                    t,
                    _relayerTarget,
                    l.relayerPremium
                );
            }
        }

        emit LockReleased(l.buyerAddress, lockID, lockAmount);
    }

    /// @notice Unlocks expired locks.
    /// @dev Triggered in the callgraph by both `lock` and `withdraw` functions.
    /// @dev This method can also have any public actor as its `tx.origin`.
    /// @dev For each successfull unexpired lock recovered,
    /// `userRecord[_castAddrToKey(l.relayerAddress)]` is decreased by half of its value.
    /// @dev Function sighash: 0x8e2749d6.
    function unlockExpired(bytes32[] calldata lockIDs)
        public
    {
        uint256 i;
        uint256 locksSize = lockIDs.length;

        for (i; i < locksSize; ) {
            DT.Lock storage l = mapLocks[lockIDs[i]];

            _notExpired(l);

            mapDeposits[l.depositID].remaining += l.amount;
            l.amount = 0;

            uint256 userKey = _castAddrToKey(
                l.relayerAddress
            );
            uint256 _newUserRecord = (userRecord[userKey] >>
                1);

            if (_newUserRecord <= 1e2 ether) {
                userRecord[userKey] = 1e2 ether;
            } else {
                userRecord[userKey] = _newUserRecord;
            }
            emit LockReturned(l.buyerAddress, lockIDs[i]);

            unchecked {
                ++i;
            }
        }

        assembly {
            if lt(i, locksSize) {
                // LoopOverflow()
                mstore(0x00, 0xdfb035c9)
                revert(0x1c, 0x04)
            }
        }
    }

    /// @notice Seller's expired deposit fund sweeper.
    /// @dev A seller may use this method to recover
    /// tokens from expired deposits.
    /// @dev Function sighash: 0x36317972.
    function withdraw(
        uint256 depositID,
        bytes32[] calldata expiredLocks
    ) public nonReentrant {
        _onlySeller(depositID);
        unlockExpired(expiredLocks);

        DT.Deposit storage d = mapDeposits[depositID];

        if (d.valid == true) {
            cancelDeposit(depositID);
        }

        ERC20 token = ERC20(d.token);

        // Withdraw remaining tokens from mapDeposit[depositID]
        uint256 amount = d.remaining;
        d.remaining = 0;

        // safeTransfer tokens to seller
        SafeTransferLib.safeTransfer(token, d.seller, amount);

        emit DepositWithdrawn(msg.sender, depositID, amount);
    }

    function setRoot(address addr, bytes32 merkleroot)
        public
    {
        if (addr == msg.sender) {
            sellerAllowList[
                _castAddrToKey(addr)
            ] = merkleroot;
            emit RootUpdated(addr, merkleroot);
        } else revert OnlySeller();
    }

    /// ███ Owner Only █████████████████████████████████████████████████████████

    /// @dev Contract's underlying balance withdraw method.
    /// @dev Function sighash: 0x5fd8c710.
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        SafeTransferLib.safeTransferETH(msg.sender, balance);
        emit FundsWithdrawn(msg.sender, balance);
    }

    function setReputation(IReputation _reputation)
        public
        onlyOwner
    {
        assembly {
            sstore(reputation.slot, _reputation)
        }
        emit ReputationUpdated(address(_reputation));
    }

    function setDefaultLockBlocks(uint256 _blocks)
        public
        onlyOwner
    {
        assembly {
            sstore(defaultLockBlocks.slot, _blocks)
        }
        emit LockBlocksUpdated(_blocks);
    }

    function setValidSigners(address[] memory _validSigners)
        public
        onlyOwner
    {
        unchecked {
            uint256 i;
            uint256 len = _validSigners.length;
            for (i; i < len; ) {
                uint256 key = _castAddrToKey(
                    _validSigners[i]
                );
                validBacenSigners[key] = true;
                ++i;
            }
        }
        emit ValidSignersUpdated(_validSigners);
    }

    function tokenSettings(
        address[] memory _tokens,
        bool[] memory _states
    ) public onlyOwner {
        /* Yul Impl */
        assembly {
            // first 32 bytes eq to array's length
            let tLen := mload(_tokens)
            // NoTokens()
            if iszero(tLen) {
                mstore(0x00, 0xdf957883)
                revert(0x1c, 0x04)
            }
            // LengthMismatch()
            if iszero(eq(tLen, mload(_states))) {
                mstore(0x00, 0xff633a38)
                revert(0x1c, 0x04)
            }
            let tLoc := add(_tokens, 0x20)
            let sLoc := add(_states, 0x20)
            for {
                let end := add(tLoc, mul(tLen, 0x20))
            } iszero(eq(tLoc, end)) {
                tLoc := add(tLoc, 0x20)
                sLoc := add(sLoc, 0x20)
            } {
                // cache hashmap entry in scratch space
                mstore(0x00, mload(tLoc))
                mstore(0x20, allowedERC20s.slot)
                let mapSlot := keccak256(0x00, 0x40)
                sstore(mapSlot, mload(sLoc))
                log3(
                    0,
                    0,
                    // AllowedERC20Updated(address, bool)
                    0x5d6e86e5341d57a92c49934296c51542a25015c9b1782a1c2722a940131c3d9a,
                    mload(tLoc),
                    mload(sLoc)
                )
            }
        }
    }

    /// ███ Helper FX ██████████████████████████████████████████████████████████

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /// @notice Access control private view method that
    /// performs auth check on an deposit's seller.
    /// @dev Function sighash: 0x4125a4d9.
    function _onlySeller(uint256 _depositID) private view {
        if (mapDeposits[_depositID].seller != msg.sender)
            revert OnlySeller();
    }

    /// @notice Private view auxiliar logic that reverts
    /// on a not expired lock passed as argument of the function.
    /// @dev Called exclusively by the `unlockExpired` method.
    /// @dev Function sighash: 0x74e2a0bb.
    function _notExpired(DT.Lock storage _l) private view {
        if (_l.expirationBlock > block.number)
            revert NotExpired();
        if (_l.amount == 0) revert AlreadyReleased();
    }

    /// @notice Internal view auxiliar logic that returns a new valid `_depositID`.
    /// @dev It reverts on an already valid counter (`uint256`) value.
    /// @dev Function sighash: 0xdb51d697.
    function _encodeDepositID()
        internal
        view
        returns (uint256 _depositID)
    {
        (_depositID) = depositCount.current();
    }

    function _addLock(
        bytes32 _lockID,
        DT.Lock memory _l,
        DT.Deposit storage _d
    ) internal {
        mapLocks[_lockID] = _l;
        _d.remaining -= _l.amount;

        emit LockAdded(
            _l.buyerAddress,
            _lockID,
            _l.depositID,
            _l.amount
        );
    }

    /// @notice Private view auxiliar logic that encodes/returns
    /// the `bytes32` identifier of an lock.
    /// @dev reverts on a not expired lock with the same ID passed
    /// as argument of the function.
    /// @dev Called exclusively by the `lock` method.
    /// @dev Function sighash: 0x3fc5fb52.
    function _encodeLockID(
        uint256 _depositID,
        uint256 _amount,
        address _buyerAddress
    ) private view returns (bytes32 _lockID) {
        _lockID = keccak256(
            abi.encodePacked(
                _depositID,
                _amount,
                _buyerAddress
            )
        );
        if (mapLocks[_lockID].expirationBlock >= block.number)
            revert NotExpired();
    }

    function merkleVerify(
        bytes32[] calldata _merkleProof,
        bytes32 root,
        address _addr
    ) private pure {
        if (
            !Merkle.verify(
                _merkleProof,
                root,
                bytes32(uint256(uint160(_addr)))
            )
        ) revert AddressDenied();
    }

    function _limiter(uint256 _userCredit)
        internal
        view
        returns (uint256 _spendLimit)
    {
        // enconde the fx sighash and args
        bytes memory encodedParams = abi.encodeWithSelector(
            IReputation.limiter.selector,
            _userCredit
        );
        // cast the uninitialized return values to memory
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        // perform staticcall from the stack w yul
        assembly {
            success := staticcall(
                // gas
                0x7530,
                // address
                sload(reputation.slot),
                // argsOffset
                add(encodedParams, 0x20),
                // argsSize
                mload(encodedParams),
                // retOffset
                0x00,
                // retSize
                0x20
            )
            returnSize := returndatasize()
            returnValue := mload(0x00)
            _spendLimit := returnValue
            // reverts if call does not succeed.
            if iszero(success) {
                mstore(0x00, 0xe10bf1cc)
                revert(0x1c, 0x04)
            }
        }
    }

    /// @notice Public method that handles `address`
    /// to `uint256` safe type casting.
    /// @dev Function sighash: 0x4b2ae980.
    function _castAddrToKey(address _addr)
        public
        pure
        returns (uint256 _key)
    {
        _key = uint256(uint160(address(_addr))) << 12;
    }
}