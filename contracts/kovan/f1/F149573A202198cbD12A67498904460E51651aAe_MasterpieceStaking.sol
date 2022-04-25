// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ParasetStaking.sol";

/// @notice The Masterpiece staking contract. It allows for a fixed PRIME token
/// rewards distributed evenly across all stakers per block.
contract MasterpieceStaking is ParasetStaking, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct VestingInfo {
        uint256 vestedAmount;
        uint256 lastDepositBlock;
    }

    struct MasterpieceInfo {
        uint256 ethReward;
        uint256 ethClaimed;
    }

    /// @notice Pool id to masterpeice
    mapping(uint256 => MasterpieceInfo) public masterpieceInfo;
    /// @notice Pool id to vesting
    mapping(uint256 => VestingInfo) public vestingInfo;

    /// @notice Minimum number of vesting blocks per ETH
    uint256 public ethVestingPeriod;

    event EthRewardsAdded(uint256[] _tokenIds, uint256[] _ethRewards);
    event EthRewardsSet(uint256[] _tokenIds, uint256[] _ethRewards);

    event HarvestEth(address indexed user, uint256 amount);

    /// @param _prime The PRIME token contract address.
    /// @param _parallelAlpha The Parallel Alpha contract address.
    /// @param _pullFromAddress The pullFromAddress contract address.
    constructor(
        IERC20 _prime,
        IERC1155 _parallelAlpha,
        address _pullFromAddress
    ) ParasetStaking(_prime, _parallelAlpha, _pullFromAddress) {}

    function setEthVestingPeriod(uint256 _ethVestingPeriod) public onlyOwner {
        ethVestingPeriod = _ethVestingPeriod;
    }

    function addEthRewards(uint256[] memory _pids, uint256[] memory _ethRewards)
        public
        payable
        onlyOwner
    {
        require(
            _pids.length == _ethRewards.length,
            "token ids and eth rewards lengths aren't the same"
        );
        uint256 totalEthRewards = 0;
        for (uint256 i = 0; i < _pids.length; i++) {
            uint256 pid = _pids[i];
            uint256 ethReward = _ethRewards[i];
            masterpieceInfo[pid].ethReward += ethReward;
            totalEthRewards += ethReward;
        }
        require(msg.value >= totalEthRewards, "Not enough eth sent");
        emit EthRewardsAdded(_pids, _ethRewards);
    }

    function setEthRewards(uint256[] memory pids, uint256[] memory _ethRewards)
        public
        payable
        onlyOwner
    {
        require(
            pids.length == _ethRewards.length,
            "token ids and eth rewards lengths aren't the same"
        );
        uint256 currentTotalEth = 0;
        uint256 newTotalEth = 0;
        for (uint256 i = 0; i < pids.length; i++) {
            uint256 pid = pids[i];
            uint256 ethReward = _ethRewards[i];
            MasterpieceInfo storage _masterpieceInfo = masterpieceInfo[pid];
            // new eth reward - old eth reward
            currentTotalEth += _masterpieceInfo.ethReward;
            newTotalEth += ethReward;
            _masterpieceInfo.ethReward = ethReward;
        }
        if (newTotalEth > currentTotalEth) {
            require(
                msg.value >= (newTotalEth - currentTotalEth),
                "Not enough eth sent"
            );
        }
        emit EthRewardsSet(pids, _ethRewards);
    }

    // vestingInfo

    /// @notice Deposit Masterpiece for PRIME allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount Amount of parasets to deposit for pid.
    function deposit(uint256 pid, uint256 amount) public override {
        VestingInfo storage _vesting = vestingInfo[pid];
        DepositInfo storage _deposit = depositInfo[pid][msg.sender];

        _vesting.vestedAmount +=
            _deposit.amount *
            (((block.number - _vesting.lastDepositBlock) * 1 ether) /
                ethVestingPeriod);

        _vesting.lastDepositBlock = block.number;

        ParasetStaking.deposit(pid, amount);
    }

    /// @notice Withdraw Masterpiece.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount amounts to withdraw for the paraset
    function withdraw(uint256 pid, uint256 amount) public override {
        VestingInfo storage _vesting = vestingInfo[pid];
        DepositInfo storage _deposit = depositInfo[pid][msg.sender];

        _vesting.vestedAmount +=
            _deposit.amount *
            (((block.number - _vesting.lastDepositBlock) * 1 ether) /
                ethVestingPeriod);

        super.withdraw(pid, amount);
    }

    /// @notice Harvest eth for transaction sender.
    /// @param pid Token id to harvest.
    function harvestEth(uint256 pid) public nonReentrant {
        DepositInfo storage _deposit = depositInfo[pid][msg.sender];
        MasterpieceInfo storage _masterpieceInfo = masterpieceInfo[pid];
        VestingInfo storage _vesting = vestingInfo[pid];

        require(
            _masterpieceInfo.ethClaimed < _masterpieceInfo.ethReward,
            "Already claimed all eth"
        );

        uint256 remainingRewards = _masterpieceInfo.ethReward -
            _masterpieceInfo.ethClaimed;

        uint256 vestedAmount = _deposit.amount *
            (((block.number - _vesting.lastDepositBlock) * 1 ether) /
                ethVestingPeriod) +
            _vesting.vestedAmount;

        uint256 pendingEthReward = vestedAmount >= remainingRewards
            ? remainingRewards
            : vestedAmount;
        _masterpieceInfo.ethClaimed += pendingEthReward;

        (bool sent, ) = msg.sender.call{value: pendingEthReward}("");
        require(sent, "Failed to send Ether");

        emit HarvestEth(msg.sender, pendingEthReward);
    }

    /// @notice Harvest eth and PRIME for transaction sender.
    /// @param pid Pool id to harvest.
    function harvestPrimeAndEth(uint256 pid) public nonReentrant {
        harvestPrime(pid);
        harvestEth(pid);
    }

    /// @notice Harvest multiple pools
    /// @param pids Pool IDs of all to be harvested
    function harvestPools(uint256[] calldata pids) public override {
        for (uint256 i = 0; i < pids.length; ++i) {
            harvestPrimeAndEth(pids[i]);
        }
    }

    /// @notice Withdraw Masterpiece and harvest PRIME for transaction sender.
    /// @param pid Token id to withdraw.
    function withdrawAndHarvestPrime(uint256 pid, uint256 amount)
        public
        override
    {
        VestingInfo storage _vesting = vestingInfo[pid];
        DepositInfo storage _deposit = depositInfo[pid][msg.sender];

        _vesting.vestedAmount +=
            _deposit.amount *
            ((block.number - _vesting.lastDepositBlock) / ethVestingPeriod);

        super.withdrawAndHarvestPrime(pid, amount);
    }

    /// @notice Withdraw Masterpiece and harvest eth for transaction sender.
    /// @param pid Token id to withdraw.
    function withdrawAndHarvestEth(uint256 pid, uint256 amount)
        public
        nonReentrant
    {
        withdraw(pid, amount);
        harvestEth(pid);
    }

    /// @notice Withdraw Masterpiece and harvest eth and prime for transaction sender.
    /// @param pid Token id to withdraw.
    function withdrawAndHarvestPrimeAndEth(uint256 pid, uint256 amount)
        public
        nonReentrant
    {
        withdrawAndHarvestPrime(pid, amount);
        harvestEth(pid);
    }

    function sweepETH(address payable to, uint256 amount) public onlyOwner {
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice The Prime Key staking contract. It allows for a fixed PRIME token
/// rewards distributed evenly across all stakers per block.
contract ParasetStaking is Ownable, ERC1155Holder {
    using SafeERC20 for IERC20;

    /// @notice Info of each Deposit.
    /// `amount` Number of parasets the user has provided.
    /// `rewardDebt` The amount of PRIME entitled to the user.
    struct DepositInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each pool.
    /// Contains the start and end blocks of the rewards
    struct PoolInfo {
        uint128 accPrimePerShare;
        uint256 allocPoint;
        uint64 lastRewardBlock;
        uint256[] parasetTokenIds;
        uint256 totalParasetSupply;
    }

    /// @notice Address of PRIME contract.
    IERC20 public PRIME;

    /// @notice Address of Parallel Alpha erc1155
    IERC1155 public parallelAlpha;

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;

    /// @notice Prime amount distributed for given period. primeAmountPerBlock = primeAmount / (endBlock - startBlock)
    uint256 public startBlock; // staking start block.
    uint256 public endBlock; // staking end block.
    uint256 public primeAmount; // the amount of PRIME to give out as rewards.
    uint256 public primeAmountPerBlock; // the amount of PRIME to give out as rewards per block.

    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    /// @notice Address of the rewarder.
    address public rewarder;

    /// @notice Deposit info of each user that stakes parasets tokens.
    // poolID(per paraset) => user address => deposit info
    mapping(uint256 => mapping(address => DepositInfo)) public depositInfo;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256[] amounts,
        address indexed to
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event HarvestPrime(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event LogPoolAddition(uint256 indexed pid, uint256[] parasetTokenIds);
    event LogPoolSetAllocPoint(uint256 pid, uint256 allocPoint);
    event LogUpdatePool(
        uint256 indexed pid,
        uint64 lastRewardBlock,
        uint256 primeKeySupply,
        uint256 accPrimePerShare
    );
    event LogSetPrimePerBlock(
        uint256 primeAmount,
        uint256 startBlock,
        uint256 endBlock,
        uint256 primeAmountPerBlock
    );
    event LogInit();

    /// @param _prime The PRIME token contract address.
    /// @param _parallelAlpha The Parallel Alpha contract address.
    /// @param _rewarder The rewarder contract address.
    constructor(
        IERC20 _prime,
        IERC1155 _parallelAlpha,
        address _rewarder
    ) {
        parallelAlpha = _parallelAlpha;
        PRIME = _prime;
        rewarder = _rewarder;
    }

    /// @notice Returns the number of pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    function getPoolTokenIds(uint256 _pid)
        public
        view
        returns (uint256[] memory parasetTokenIds)
    {
        return poolInfo[_pid].parasetTokenIds;
    }

    /// @notice Add a new paraset to the pool. Can only be called by the owner.
    /// DO NOT add the same token id more than once. Rewards will be messed up if you do.
    /// @param _allocPoint AP of the new pool.
    /// @param _parasetTokenIds TokenIds for a ParallelAlpha ERC1155 paraset.
    function addPool(uint256 _allocPoint, uint256[] memory _parasetTokenIds)
        public
        onlyOwner
    {
        require(
            _parasetTokenIds.length > 0,
            "Paraset TokenIds cannot be empty"
        );
        require(_allocPoint > 0, "Allocation point cannot be 0 or negative");
        totalAllocPoint += _allocPoint;
        poolInfo.push(
            PoolInfo({
                accPrimePerShare: 0,
                allocPoint: _allocPoint,
                lastRewardBlock: uint64(startBlock),
                parasetTokenIds: _parasetTokenIds,
                totalParasetSupply: 0
            })
        );
        emit LogPoolAddition(poolInfo.length - 1, _parasetTokenIds);
    }

    // Set remaining prime to distribute between endBlock-startBlock
    function setPrimePerBlock(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _primeAmount
    ) public onlyOwner {
        require(
            _startBlock < _endBlock,
            "Endblock cant be less than Startblock"
        );
        require(endBlock < block.number, "Only updates after initial endBlock");
        // Update all pools before proceeding, ensure rewards calculated up to this block
        for (uint256 i = 0; i < poolInfo.length; ++i) {
            updatePool(i);
        }
        primeAmount = _primeAmount;
        startBlock = _startBlock;
        endBlock = _endBlock;
        primeAmountPerBlock = _primeAmount / (_endBlock - _startBlock);
        emit LogSetPrimePerBlock(
            _primeAmount,
            _startBlock,
            _endBlock,
            primeAmountPerBlock
        );
    }

    function setEndBlock(uint256 _endBlock) public onlyOwner {
        require(startBlock < block.number, "staking have not started yet");
        require(endBlock < _endBlock, "invalid end block");
        for (uint256 i = 0; i < poolInfo.length; ++i) {
            updatePool(i);
        }
        // Update pool stuffs
        endBlock = _endBlock;
        primeAmountPerBlock = primeAmount / (endBlock - startBlock);
    }

    function addPrimeAmount(uint256 _primeAmount) public onlyOwner {
        require(
            startBlock < block.number && block.number < endBlock,
            "Only topups inside a period"
        );

        // Update all pools
        for (uint256 i = 0; i < poolInfo.length; ++i) {
            updatePool(i);
        }
        // Top up current cycle's PRIME
        primeAmount += _primeAmount;
        primeAmountPerBlock = primeAmount / (endBlock - block.number);
    }

    /// @notice Update the given pool's PRIME allocation point.  Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    function setPoolAllocPoint(uint256 _pid, uint256 _allocPoint)
        public
        onlyOwner
    {
        // Update all pools
        for (uint256 i = 0; i < poolInfo.length; ++i) {
            updatePool(i);
        }
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        emit LogPoolSetAllocPoint(_pid, _allocPoint);
    }

    // Pull from address
    function setRewarder(address _rewarder) public onlyOwner {
        rewarder = _rewarder;
    }

    function setPRIME(IERC20 _PRIME) public onlyOwner {
        PRIME = _PRIME;
    }

    function setParallelAlpha(IERC1155 _parallelAlpha) public onlyOwner {
        parallelAlpha = _parallelAlpha;
    }

    /// @notice View function to see pending PRIME on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending PRIME reward for a given user.
    function pendingPrime(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending)
    {
        PoolInfo memory pool = poolInfo[_pid];
        DepositInfo storage _deposit = depositInfo[_pid][_user];
        uint256 accPrimePerShare = pool.accPrimePerShare;
        uint256 parasetSupply = pool.totalParasetSupply;

        if (
            startBlock <= block.number &&
            pool.lastRewardBlock < block.number &&
            parasetSupply > 0
        ) {
            uint256 updateToBlock = block.number < endBlock
                ? block.number
                : endBlock;
            uint256 blocks = updateToBlock - pool.lastRewardBlock;
            uint256 primeReward = (blocks *
                primeAmountPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accPrimePerShare = accPrimePerShare + (primeReward / parasetSupply);
        }
        pending = uint256(
            int256(_deposit.amount * accPrimePerShare) - _deposit.rewardDebt
        );
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    function updatePool(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];
        if (startBlock > block.number || pool.lastRewardBlock >= block.number) {
            return;
        }
        uint256 updateToBlock = block.number < endBlock
            ? block.number
            : endBlock;
        uint256 parasetSupply = pool.totalParasetSupply;
        if (parasetSupply > 0) {
            uint256 blocks = updateToBlock - pool.lastRewardBlock;
            uint256 primeReward = (blocks *
                primeAmountPerBlock *
                pool.allocPoint) / totalAllocPoint;
            primeAmount -= primeReward;
            pool.accPrimePerShare = uint128(
                uint256(pool.accPrimePerShare) + (primeReward / parasetSupply)
            );
        }
        pool.lastRewardBlock = uint64(updateToBlock);
        emit LogUpdatePool(
            pid,
            pool.lastRewardBlock,
            parasetSupply,
            pool.accPrimePerShare
        );
    }

    /// @notice Deposit parasets for PRIME allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount Amount of parasets to deposit for pid.
    function deposit(uint256 pid, uint256 amount) public virtual {
        require(amount > 0, "Specify valid paraset amount to deposit");
        updatePool(pid);
        DepositInfo storage _deposit = depositInfo[pid][msg.sender];

        // Create amounts array for paraset BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[pid].parasetTokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = amount;
        }

        // Effects
        poolInfo[pid].totalParasetSupply += amount;
        _deposit.amount += amount;
        _deposit.rewardDebt += int256(amount * poolInfo[pid].accPrimePerShare);

        parallelAlpha.safeBatchTransferFrom(
            msg.sender,
            address(this),
            poolInfo[pid].parasetTokenIds,
            amounts,
            bytes("")
        );

        emit Deposit(msg.sender, pid, amounts, msg.sender);
    }

    /// @notice Withdraw parasets.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount amounts to withdraw for the paraset
    function withdraw(uint256 pid, uint256 amount) public virtual {
        updatePool(pid);
        DepositInfo storage _deposit = depositInfo[pid][msg.sender];

        // Create amounts array for paraset BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[pid].parasetTokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = amount;
        }

        // Effects
        poolInfo[pid].totalParasetSupply -= amount;
        _deposit.rewardDebt -= int256(amount * poolInfo[pid].accPrimePerShare);
        _deposit.amount -= amount;

        parallelAlpha.safeBatchTransferFrom(
            address(this),
            msg.sender,
            poolInfo[pid].parasetTokenIds,
            amounts,
            bytes("")
        );

        emit Withdraw(msg.sender, pid, amount, msg.sender);
    }

    /// @notice HarvestPrime proceeds for transaction sender to msg.sender.
    /// @param pid The index of the pool. See `poolInfo`.
    function harvestPrime(uint256 pid) public {
        updatePool(pid);
        DepositInfo storage _deposit = depositInfo[pid][msg.sender];
        int256 accumulatedPrime = int256(
            _deposit.amount * poolInfo[pid].accPrimePerShare
        );
        uint256 _pendingPrime = uint256(accumulatedPrime - _deposit.rewardDebt);

        // Effects
        _deposit.rewardDebt = accumulatedPrime;

        // Interactions
        if (_pendingPrime != 0) {
            PRIME.safeTransferFrom(rewarder, msg.sender, _pendingPrime);
        }

        emit HarvestPrime(msg.sender, pid, _pendingPrime);
    }

    /// @notice HarvestPrime multiple pools
    /// @param pids Pool IDs of all to be harvested
    function harvestPools(uint256[] calldata pids) public virtual {
        for (uint256 i = 0; i < pids.length; ++i) {
            harvestPrime(pids[i]);
        }
    }

    /// @notice Withdraw parasets and harvest proceeds for transaction sender to msg.sender.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount Paraset amount to withdraw.
    function withdrawAndHarvestPrime(uint256 pid, uint256 amount) public virtual {
        updatePool(pid);
        DepositInfo storage _deposit = depositInfo[pid][msg.sender];
        int256 accumulatedPrime = int256(
            _deposit.amount * poolInfo[pid].accPrimePerShare
        );
        uint256 _pendingPrime = uint256(accumulatedPrime - _deposit.rewardDebt);

        // Create amounts array for paraset BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[pid].parasetTokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = amount;
        }

        // Effects
        poolInfo[pid].totalParasetSupply -= amount;
        _deposit.rewardDebt =
            accumulatedPrime -
            int256(amount * poolInfo[pid].accPrimePerShare);
        _deposit.amount = _deposit.amount - amount;

        PRIME.safeTransferFrom(rewarder, msg.sender, _pendingPrime);

        parallelAlpha.safeBatchTransferFrom(
            address(this),
            msg.sender,
            poolInfo[pid].parasetTokenIds,
            amounts,
            bytes("")
        );

        emit Withdraw(msg.sender, pid, amount, msg.sender);
        emit HarvestPrime(msg.sender, pid, _pendingPrime);
    }

    function sweepERC1155(
        IERC1155 erc1155,
        address to,
        uint256 tokenID,
        uint256 amount
    ) public onlyOwner {
        require(parallelAlpha == erc1155, "only parallelAlpha");
        erc1155.safeTransferFrom(address(this), to, tokenID, amount, bytes(""));
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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