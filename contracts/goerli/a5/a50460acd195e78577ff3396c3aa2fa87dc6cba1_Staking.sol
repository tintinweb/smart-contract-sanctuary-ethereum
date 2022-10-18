/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

pragma solidity >=0.5.3<0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// Just inlining part of the standard ERC20 contract
interface ERC20Token {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/**
 * @title Staking is a contract to support locking and releasing ERC-20 tokens
 * for the purposes of staking.
 */
contract Staking {
    struct PendingDeposit {
        address depositor;
        uint256 amount;
    }

    address public _owner;
    address public _authorizedNewOwner;
    address public _tokenAddress;

    address public _withdrawalPublisher;
    address public _fallbackPublisher;
    uint256 public _fallbackWithdrawalDelaySeconds = 1 weeks;

    // 1% of total supply
    uint256 public _immediatelyWithdrawableLimit = 100_000 * (10**18);
    address public _immediatelyWithdrawableLimitPublisher;

    uint256 public _depositNonce = 0;
    mapping(uint256 => PendingDeposit) public _nonceToPendingDeposit;

    uint256 public _maxWithdrawalRootNonce = 0;
    mapping(bytes32 => uint256) public _withdrawalRootToNonce;
    mapping(address => uint256) public _addressToWithdrawalNonce;
    mapping(address => uint256) public _addressToCumulativeAmountWithdrawn;

    bytes32 public _fallbackRoot;
    uint256 public _fallbackMaxDepositIncluded = 0;
    uint256 public _fallbackSetDate = 2**200;

    event WithdrawalRootHashAddition(
        bytes32 indexed rootHash,
        uint256 indexed nonce
    );

    event WithdrawalRootHashRemoval(
        bytes32 indexed rootHash,
        uint256 indexed nonce
    );

    event FallbackRootHashSet(
        bytes32 indexed rootHash,
        uint256 indexed maxDepositNonceIncluded,
        uint256 setDate
    );

    event Deposit(
        address indexed depositor,
        uint256 indexed amount,
        uint256 indexed nonce
    );

    event Withdrawal(
        address indexed toAddress,
        uint256 indexed amount,
        uint256 indexed rootNonce,
        uint256 authorizedAccountNonce
    );

    event FallbackWithdrawal(
        address indexed toAddress,
        uint256 indexed amount
    );

    event PendingDepositRefund(
        address indexed depositorAddress,
        uint256 indexed amount,
        uint256 indexed nonce
    );

    event RenounceWithdrawalAuthorization(
        address indexed forAddress
    );

    event FallbackWithdrawalDelayUpdate(
        uint256 indexed oldValue,
        uint256 indexed newValue
    );

    event FallbackMechanismDateReset(
        uint256 indexed newDate
    );

    event ImmediatelyWithdrawableLimitUpdate(
        uint256 indexed oldValue,
        uint256 indexed newValue
    );

    event OwnershipTransferAuthorization(
        address indexed authorizedAddress
    );

    event OwnerUpdate(
        address indexed oldValue,
        address indexed newValue
    );

    event FallbackPublisherUpdate(
        address indexed oldValue,
        address indexed newValue
    );

    event WithdrawalPublisherUpdate(
        address indexed oldValue,
        address indexed newValue
    );

    event ImmediatelyWithdrawableLimitPublisherUpdate(
        address indexed oldValue,
        address indexed newValue
    );

    constructor(
        address tokenAddress,
        address fallbackPublisher,
        address withdrawalPublisher,
        address immediatelyWithdrawableLimitPublisher
    ) public {
        _owner = msg.sender;
        _fallbackPublisher = fallbackPublisher;
        _withdrawalPublisher = withdrawalPublisher;
        _immediatelyWithdrawableLimitPublisher = immediatelyWithdrawableLimitPublisher;
        _tokenAddress = tokenAddress;
    }

    /********************
     * STANDARD ACTIONS *
     ********************/

    /**
     * @notice Deposits the provided amount of FXC from the message sender into this wallet.
     * Note: The sending address must own the provided amount of FXC to deposit, and
     * the sender must have indicated to the FXC ERC-20 contract that this contract is
     * allowed to transfer at least the provided amount from its address.
     *
     * @param amount The amount to deposit.
     * @return The deposit nonce for this deposit. This can be useful in calling
     * refundPendingDeposit(...).
     */
    function deposit(uint256 amount) external returns(uint256) {
        require(
            amount > 0,
            "Cannot deposit 0"
        );

        _depositNonce = SafeMath.add(_depositNonce, 1);
        _nonceToPendingDeposit[_depositNonce].depositor = msg.sender;
        _nonceToPendingDeposit[_depositNonce].amount = amount;

        emit Deposit(
            msg.sender,
            amount,
            _depositNonce
        );

        bool transferred = ERC20Token(_tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(transferred, "Transfer failed");
        
        return _depositNonce;
    }

    /**
     * @notice Indicates that this address would not like its withdrawable
     * funds to be available for withdrawal. This will prevent withdrawal
     * for this address until the next withdrawal root is published.
     *
     * Note: The caller does not need to know or prove the details of the current
     * withdrawal authorization in order to renounce it.
     * @param forAddress The address for which the withdrawal is being renounced.
     */
    function renounceWithdrawalAuthorization(address forAddress) external {
        require(
            msg.sender == _owner ||
            msg.sender == _withdrawalPublisher ||
            msg.sender == forAddress,
            "Only the owner, withdrawal publisher, and address in question can renounce a withdrawal authorization"
        );
        require(
            _addressToWithdrawalNonce[forAddress] < _maxWithdrawalRootNonce,
            "Address nonce indicates there are no funds withdrawable"
        );
        _addressToWithdrawalNonce[forAddress] = _maxWithdrawalRootNonce;
        emit RenounceWithdrawalAuthorization(forAddress);
    }

    /**
     * @notice Executes a previously authorized token withdrawal.
     * @param toAddress The address to which the tokens are to be transferred.
     * @param amount The amount of tokens to be withdrawn.
     * @param maxAuthorizedAccountNonce The maximum authorized account nonce for the withdrawing
     * address encoded within the withdrawal authorization. Prevents double-withdrawals.
     * @param merkleProof The Merkle tree proof associated with the withdrawal
     * authorization.
     */
    function withdraw(
        address toAddress,
        uint256 amount,
        uint256 maxAuthorizedAccountNonce,
        bytes32[] calldata merkleProof
    ) external {
        require(
            msg.sender == _owner || msg.sender == toAddress,
            "Only the owner or recipient can execute a withdrawal"
        );

        require(
            _addressToWithdrawalNonce[toAddress] <= maxAuthorizedAccountNonce,
            "Account nonce in contract exceeds provided max authorized withdrawal nonce for this account"
        );

        require(
            amount <= _immediatelyWithdrawableLimit,
            "Withdrawal would push contract over its immediately withdrawable limit"
        );

        bytes32 leafDataHash = keccak256(abi.encodePacked(
            toAddress,
            amount,
            maxAuthorizedAccountNonce
        ));

        bytes32 calculatedRoot = calculateMerkleRoot(merkleProof, leafDataHash);
        uint256 withdrawalPermissionRootNonce = _withdrawalRootToNonce[calculatedRoot];

        require(
            withdrawalPermissionRootNonce > 0,
            "Root hash unauthorized");
        require(
            withdrawalPermissionRootNonce > maxAuthorizedAccountNonce,
            "Encoded nonce not greater than max last authorized nonce for this account"
        );

        _immediatelyWithdrawableLimit -= amount; // amount guaranteed <= _immediatelyWithdrawableLimit
        _addressToWithdrawalNonce[toAddress] = withdrawalPermissionRootNonce;
        _addressToCumulativeAmountWithdrawn[toAddress] = SafeMath.add(amount, _addressToCumulativeAmountWithdrawn[toAddress]);

        emit Withdrawal(
            toAddress,
            amount,
            withdrawalPermissionRootNonce,
            maxAuthorizedAccountNonce
        );

        bool transferred = ERC20Token(_tokenAddress).transfer(
            toAddress,
            amount
        );

        require(transferred, "Transfer failed");
    }

    /**
     * @notice Executes a fallback withdrawal transfer.
     * @param toAddress The address to which the tokens are to be transferred.
     * @param maxCumulativeAmountWithdrawn The lifetime withdrawal limit that this address is
     * subject to. This is encoded within the fallback authorization to prevent regular 
     * withdrawal / fallback withdrawal double-spends
     * @param merkleProof The Merkle tree proof associated with the withdrawal authorization.
     */
    function withdrawFallback(
        address toAddress,
        uint256 maxCumulativeAmountWithdrawn,
        bytes32[] calldata merkleProof
    ) external {
        require(
            msg.sender == _owner || msg.sender == toAddress,
            "Only the owner or recipient can execute a fallback withdrawal"
        );
        require(
            SafeMath.add(_fallbackSetDate, _fallbackWithdrawalDelaySeconds) <= block.timestamp,
            "Fallback withdrawal period is not active"
        );
        require(
            _addressToCumulativeAmountWithdrawn[toAddress] < maxCumulativeAmountWithdrawn,
            "Withdrawal not permitted when amount withdrawn is at lifetime withdrawal limit"
        );

        bytes32 msgHash = keccak256(abi.encodePacked(
            toAddress,
            maxCumulativeAmountWithdrawn
        ));

        bytes32 calculatedRoot = calculateMerkleRoot(merkleProof, msgHash);
        require(
            _fallbackRoot == calculatedRoot,
            "Root hash unauthorized"
        );

        // If user is triggering fallback withdrawal, invalidate all existing regular withdrawals
        _addressToWithdrawalNonce[toAddress] = _maxWithdrawalRootNonce;

        // _addressToCumulativeAmountWithdrawn[toAddress] guaranteed < maxCumulativeAmountWithdrawn
        uint256 withdrawalAmount = maxCumulativeAmountWithdrawn - _addressToCumulativeAmountWithdrawn[toAddress];
        _addressToCumulativeAmountWithdrawn[toAddress] = maxCumulativeAmountWithdrawn;
        
        emit FallbackWithdrawal(
            toAddress,
            withdrawalAmount
        );

        bool transferred = ERC20Token(_tokenAddress).transfer(
            toAddress,
            withdrawalAmount
        );

        require(transferred, "Transfer failed");
    }

    /**
     * @notice Refunds a pending deposit for the provided address, refunding the pending funds.
     * This may only take place if the fallback withdrawal period has lapsed.
     * @param depositNonce The deposit nonce uniquely identifying the deposit to cancel
     */
    function refundPendingDeposit(uint256 depositNonce) external {
        address depositor = _nonceToPendingDeposit[depositNonce].depositor;
        require(
            msg.sender == _owner || msg.sender == depositor,
            "Only the owner or depositor can initiate the refund of a pending deposit"
        );
        require(
            SafeMath.add(_fallbackSetDate, _fallbackWithdrawalDelaySeconds) <= block.timestamp,
            "Fallback withdrawal period is not active, so refunds are not permitted"
        );
        uint256 amount = _nonceToPendingDeposit[depositNonce].amount;
        require(
            depositNonce > _fallbackMaxDepositIncluded &&
            amount > 0,
            "There is no pending deposit for the specified nonce"
        );
        delete _nonceToPendingDeposit[depositNonce];

        emit PendingDepositRefund(depositor, amount, depositNonce);

        bool transferred = ERC20Token(_tokenAddress).transfer(
            depositor,
            amount
        );
        require(transferred, "Transfer failed");
    }

    /*****************
     * ADMIN ACTIONS *
     *****************/

    /**
     * @notice Authorizes the transfer of ownership from _owner to the provided address.
     * NOTE: No transfer will occur unless authorizedAddress calls assumeOwnership( ).
     * This authorization may be removed by another call to this function authorizing
     * the null address.
     * @param authorizedAddress The address authorized to become the new owner.
     */
    function authorizeOwnershipTransfer(address authorizedAddress) external {
        require(
            msg.sender == _owner,
            "Only the owner can authorize a new address to become owner"
        );

        _authorizedNewOwner = authorizedAddress;

        emit OwnershipTransferAuthorization(_authorizedNewOwner);
    }

    /**
     * @notice Transfers ownership of this contract to the _authorizedNewOwner.
     */
    function assumeOwnership() external {
        require(
            msg.sender == _authorizedNewOwner,
            "Only the authorized new owner can accept ownership"
        );
        address oldValue = _owner;
        _owner = _authorizedNewOwner;
        _authorizedNewOwner = address(0);

        emit OwnerUpdate(oldValue, _owner);
    }

    /**
     * @notice Updates the Withdrawal Publisher address, the only address other than the
     * owner that can publish / remove withdrawal Merkle tree roots.
     * @param newWithdrawalPublisher The address of the new Withdrawal Publisher
     */
    function setWithdrawalPublisher(address newWithdrawalPublisher) external {
        require(
            msg.sender == _owner,
            "Only the owner can set the withdrawal publisher address"
        );
        address oldValue = _withdrawalPublisher;
        _withdrawalPublisher = newWithdrawalPublisher;

        emit WithdrawalPublisherUpdate(oldValue, _withdrawalPublisher);
    }

    /**
     * @notice Updates the Fallback Publisher address, the only address other than
     * the owner that can publish / remove fallback withdrawal Merkle tree roots.
     * @param newFallbackPublisher The address of the new Fallback Publisher
     */
    function setFallbackPublisher(address newFallbackPublisher) external {
        require(
            msg.sender == _owner,
            "Only the owner can set the fallback publisher address"
        );
        address oldValue = _fallbackPublisher;
        _fallbackPublisher = newFallbackPublisher;

        emit FallbackPublisherUpdate(oldValue, _fallbackPublisher);
    }

    /**
     * @notice Updates the Immediately Withdrawable Limit Publisher address, the only address
     * other than the owner that can set the immediately withdrawable limit.
     * @param newImmediatelyWithdrawableLimitPublisher The address of the new Immediately
     * Withdrawable Limit Publisher
     */
    function setImmediatelyWithdrawableLimitPublisher(
      address newImmediatelyWithdrawableLimitPublisher
    ) external {
        require(
            msg.sender == _owner,
            "Only the owner can set the immediately withdrawable limit publisher address"
        );
        address oldValue = _immediatelyWithdrawableLimitPublisher;
        _immediatelyWithdrawableLimitPublisher = newImmediatelyWithdrawableLimitPublisher;

        emit ImmediatelyWithdrawableLimitPublisherUpdate(
          oldValue,
          _immediatelyWithdrawableLimitPublisher
        );
    }

    /**
     * @notice Modifies the immediately withdrawable limit (the maximum amount that
     * can be withdrawn from withdrawal authorization roots before the limit needs
     * to be updated by Flexa) by the provided amount.
     * If negative, it will be decreased, if positive, increased.
     * This is to prevent contract funds from being drained by error or publisher malice.
     * This does not affect the fallback withdrawal mechanism.
     * @param amount amount to modify the limit by.
     */
    function modifyImmediatelyWithdrawableLimit(int256 amount) external {
        require(
            msg.sender == _owner || msg.sender == _immediatelyWithdrawableLimitPublisher,
            "Only the immediately withdrawable limit publisher and owner can modify the immediately withdrawable limit"
        );
        uint256 oldLimit = _immediatelyWithdrawableLimit;

        if (amount < 0) {
            uint256 unsignedAmount = uint256(-amount);
            _immediatelyWithdrawableLimit = SafeMath.sub(_immediatelyWithdrawableLimit, unsignedAmount);
        } else {
            uint256 unsignedAmount = uint256(amount);
            _immediatelyWithdrawableLimit = SafeMath.add(_immediatelyWithdrawableLimit, unsignedAmount);
        }

        emit ImmediatelyWithdrawableLimitUpdate(oldLimit, _immediatelyWithdrawableLimit);
    }

    /**
     * @notice Updates the time-lock period for a fallback withdrawal to be permitted if no
     * action is taken by Flexa.
     * @param newFallbackDelaySeconds The new delay period in seconds.
     */
    function setFallbackWithdrawalDelay(uint256 newFallbackDelaySeconds) external {
        require(
            msg.sender == _owner,
            "Only the owner can set the fallback withdrawal delay"
        );
        require(
            newFallbackDelaySeconds != 0,
            "New fallback delay may not be 0"
        );

        uint256 oldDelay = _fallbackWithdrawalDelaySeconds;
        _fallbackWithdrawalDelaySeconds = newFallbackDelaySeconds;

        emit FallbackWithdrawalDelayUpdate(oldDelay, newFallbackDelaySeconds);
    }

    /**
     * @notice Adds the root hash of a merkle tree containing authorized token withdrawals.
     * @param root The root hash to be added to the repository.
     * @param nonce The nonce of the new root hash. Must be exactly one higher
     * than the existing max nonce.
     * @param replacedRoots The root hashes to be removed from the repository.
     */
    function addWithdrawalRoot(
        bytes32 root,
        uint256 nonce,
        bytes32[] calldata replacedRoots
    ) external {
        require(
            msg.sender == _owner || msg.sender == _withdrawalPublisher,
            "Only the owner and withdrawal publisher can add and replace withdrawal root hashes"
        );
        require(
            root != 0,
            "Added root may not be 0"
        );
        require(
            // Overflowing uint256 by incrementing by 1 not plausible and guarded by nonce variable.
            _maxWithdrawalRootNonce + 1 == nonce,
            "Nonce must be exactly max nonce + 1"
        );
        require(
            _withdrawalRootToNonce[root] == 0,
            "Root already exists and is associated with a different nonce"
        );

        _withdrawalRootToNonce[root] = nonce;
        _maxWithdrawalRootNonce = nonce;

        emit WithdrawalRootHashAddition(root, nonce);

        for (uint256 i = 0; i < replacedRoots.length; i++) {
            deleteWithdrawalRoot(replacedRoots[i]);
        }
    }

    /**
     * @notice Removes root hashes of a merkle trees containing authorized
     * token withdrawals.
     * @param roots The root hashes to be removed from the repository.
     */
    function removeWithdrawalRoots(bytes32[] calldata roots) external {
        require(
            msg.sender == _owner || msg.sender == _withdrawalPublisher,
            "Only the owner and withdrawal publisher can remove withdrawal root hashes"
        );

        for (uint256 i = 0; i < roots.length; i++) {
            deleteWithdrawalRoot(roots[i]);
        }
    }

    /**
     * @notice Resets the _fallbackSetDate to the current block's timestamp.
     * This is mainly used to deactivate the fallback mechanism so new
     * fallback roots may be published.
     */
    function resetFallbackMechanismDate() external {
        require(
            msg.sender == _owner || msg.sender == _fallbackPublisher,
            "Only the owner and fallback publisher can reset fallback mechanism date"
        );

        _fallbackSetDate = block.timestamp;

        emit FallbackMechanismDateReset(_fallbackSetDate);
    }

    /**
     * @notice Sets the root hash of the Merkle tree containing fallback
     * withdrawal authorizations. This is used in scenarios where the contract
     * owner has stopped interacting with the contract, and therefore is no
     * longer honoring requests to unlock funds. After the configured fallback
     * delay elapses, the withdrawal authorizations included in the supplied
     * Merkle tree can be executed to recover otherwise locked funds.
     * @param root The root hash to be saved as the fallback withdrawal
     * authorizations.
     * @param maxDepositIncluded The max deposit nonce represented in this root.
     */
    function setFallbackRoot(bytes32 root, uint256 maxDepositIncluded) external {
        require(
            msg.sender == _owner || msg.sender == _fallbackPublisher,
            "Only the owner and fallback publisher can set the fallback root hash"
        );
        require(
            root != 0,
            "New root may not be 0"
        );
        require(
            SafeMath.add(_fallbackSetDate, _fallbackWithdrawalDelaySeconds) > block.timestamp,
            "Cannot set fallback root while fallback mechanism is active"
        );
        require(
            maxDepositIncluded >= _fallbackMaxDepositIncluded,
            "Max deposit included must remain the same or increase"
        );
        require(
            maxDepositIncluded <= _depositNonce,
            "Cannot invalidate future deposits"
        );

        _fallbackRoot = root;
        _fallbackMaxDepositIncluded = maxDepositIncluded;
        _fallbackSetDate = block.timestamp;

        emit FallbackRootHashSet(
            root,
            _fallbackMaxDepositIncluded,
            block.timestamp
        );
    }

    /**
     * @notice Deletes the provided root from the collection of
     * withdrawal authorization merkle tree roots, invalidating the
     * withdrawals contained in the tree assocated with this root.
     * @param root The root hash to delete.
     */
    function deleteWithdrawalRoot(bytes32 root) private {
        uint256 nonce = _withdrawalRootToNonce[root];

        require(
            nonce > 0,
            "Root hash not set"
        );

        delete _withdrawalRootToNonce[root];

        emit WithdrawalRootHashRemoval(root, nonce);
    }

    /**
     * @notice Calculates the Merkle root for the unique Merkle tree described by the provided
       Merkle proof and leaf hash.
     * @param merkleProof The sibling node hashes at each level of the tree.
     * @param leafHash The hash of the leaf data for which merkleProof is an inclusion proof.
     * @return The calculated Merkle root.
     */
    function calculateMerkleRoot(
        bytes32[] memory merkleProof,
        bytes32 leafHash
    ) private pure returns (bytes32) {
        bytes32 computedHash = leafHash;

        for (uint256 i = 0; i < merkleProof.length; i++) {
            bytes32 proofElement = merkleProof[i];

            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(
                    computedHash,
                    proofElement
                ));
            } else {
                computedHash = keccak256(abi.encodePacked(
                    proofElement,
                    computedHash
                ));
            }
        }

        return computedHash;
    }
}