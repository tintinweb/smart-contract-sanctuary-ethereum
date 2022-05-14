// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IInfinityFeeTreasury, OrderTypes} from '../interfaces/IInfinityFeeTreasury.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {IERC20, SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IComplication} from '../interfaces/IComplication.sol';
import {IStaker, StakeLevel} from '../interfaces/IStaker.sol';
import {IFeeManager, FeeParty} from '../interfaces/IFeeManager.sol';
import {IMerkleDistributor} from '../interfaces/IMerkleDistributor.sol';

// import 'hardhat/console.sol';

/**
 * @title InfinityFeeTreasury
 * @notice allocates and disburses fees to all parties: creators/curators
 */
contract InfinityFeeTreasury is IInfinityFeeTreasury, IMerkleDistributor, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  address public INFINITY_EXCHANGE;
  address public STAKER_CONTRACT;
  address public CREATOR_FEE_MANAGER;

  uint16 public CURATOR_FEE_BPS = 250;

  uint16 public BRONZE_EFFECTIVE_FEE_BPS = 10000;
  uint16 public SILVER_EFFECTIVE_FEE_BPS = 10000;
  uint16 public GOLD_EFFECTIVE_FEE_BPS = 10000;
  uint16 public PLATINUM_EFFECTIVE_FEE_BPS = 10000;

  event CreatorFeesClaimed(address indexed user, address currency, uint256 amount);
  event CuratorFeesClaimed(address indexed user, address currency, uint256 amount);

  event StakerContractUpdated(address stakingContract);
  event CreatorFeeManagerUpdated(address manager);
  event CollectorFeeManagerUpdated(address manager);

  event CuratorFeeUpdated(uint16 newBps);
  event EffectiveFeeBpsUpdated(StakeLevel level, uint16 newBps);

  event FeeAllocated(address collection, address currency, uint256 totalFees);

  // creator address to currency to amount
  mapping(address => mapping(address => uint256)) public creatorFees;
  // currency to amount
  mapping(address => uint256) public curatorFees;
  // currency address to root
  mapping(address => bytes32) public merkleRoots;
  // user to currency to claimed amount
  mapping(address => mapping(address => uint256)) public cumulativeClaimed;

  constructor(
    address _infinityExchange,
    address _stakerContract,
    address _creatorFeeManager
  ) {
    INFINITY_EXCHANGE = _infinityExchange;
    STAKER_CONTRACT = _stakerContract;
    CREATOR_FEE_MANAGER = _creatorFeeManager;
  }

  fallback() external payable {}

  receive() external payable {}

  function allocateFees(
    address seller,
    address buyer,
    OrderTypes.OrderItem[] calldata items,
    uint256 amount,
    address currency,
    uint256 minBpsToSeller,
    address execComplication,
    bool feeDiscountEnabled
  ) external payable override nonReentrant {
    // console.log('allocating fees');
    require(msg.sender == INFINITY_EXCHANGE, 'Fee distribution: Only Infinity exchange');
    // token staker discount
    uint16 effectiveFeeBps = 10000;
    if (feeDiscountEnabled) {
      effectiveFeeBps = _getEffectiveFeeBps(seller);
    }
    // console.log('effective fee bps', effectiveFeeBps);

    // creator fee
    uint256 totalFees = _allocateFeesToCreators(execComplication, items, amount, currency);

    // curator fee
    totalFees += _allocateFeesToCurators(amount, currency, effectiveFeeBps);

    // check min bps to seller is met
    // console.log('amount:', amount);
    // console.log('totalFees:', totalFees);
    uint256 remainingAmount = amount - totalFees;
    // console.log('remainingAmount:', remainingAmount);
    require((remainingAmount * 10000) >= (minBpsToSeller * amount), 'Fees: Higher than expected');

    // transfer fees to contract
    // console.log('transferring total fees', totalFees);
    // ETH
    if (currency == address(0)) {
      require(msg.value >= amount, 'insufficient amount sent');
      // transfer amount to seller
      (bool sent, ) = seller.call{value: remainingAmount}('');
      require(sent, 'failed to send ether to seller');
    } else {
      IERC20(currency).safeTransferFrom(buyer, address(this), totalFees);
      // transfer final amount (post-fees) to seller
      IERC20(currency).safeTransferFrom(buyer, seller, remainingAmount);
    }

    // emit events
    for (uint256 i = 0; i < items.length; ) {
      // fee allocated per collection is simply totalFee divided by number of collections in the order
      emit FeeAllocated(items[i].collection, currency, totalFees / items.length);
      unchecked {
        ++i;
      }
    }
  }

  function refundMatchExecutionGasFee(
    uint256 startGas,
    OrderTypes.Order[] calldata sells,
    address matchExecutor,
    address weth
  ) external override nonReentrant {
    // console.log('refunding gas fees');
    require(msg.sender == INFINITY_EXCHANGE, 'Gas fee refund: Only Infinity exchange');
    for (uint256 i = 0; i < sells.length; ) {
      _refundMatchExecutionGasFee(startGas, sells[i].signer, matchExecutor, weth);
      unchecked {
        ++i;
      }
    }
  }

  function _refundMatchExecutionGasFee(
    uint256 startGas,
    address seller,
    address matchExecutor,
    address weth
  ) internal {
    // console.log('refunding gas fees to executor for sale executed on behalf of', seller);
    // todo: check weth transfer gas cost
    uint256 gasCost = (startGas - gasleft() + 30000) * tx.gasprice;
    // console.log('gasCost:', gasCost);
    IERC20(weth).safeTransferFrom(seller, matchExecutor, gasCost);
  }

  function claimCreatorFees(address currency) external override nonReentrant {
    require(creatorFees[msg.sender][currency] > 0, 'Fees: No creator fees to claim');
    // ETH
    if (currency == address(0)) {
      (bool sent, ) = msg.sender.call{value: creatorFees[msg.sender][currency]}('');
      require(sent, 'failed to send ether');
    } else {
      IERC20(currency).safeTransfer(msg.sender, creatorFees[msg.sender][currency]);
    }
    creatorFees[msg.sender][currency] = 0;
    emit CreatorFeesClaimed(msg.sender, currency, creatorFees[msg.sender][currency]);
  }

  function claimCuratorFees(
    address currency,
    uint256 cumulativeAmount,
    bytes32 expectedMerkleRoot,
    bytes32[] calldata merkleProof
  ) external override nonReentrant {
    // process
    _processClaim(currency, cumulativeAmount, expectedMerkleRoot, merkleProof);

    // transfer
    unchecked {
      uint256 amount = cumulativeAmount - cumulativeClaimed[msg.sender][currency];
      curatorFees[currency] -= amount;
      if (currency == address(0)) {
        (bool sent, ) = msg.sender.call{value: amount}('');
        require(sent, 'failed to send ether');
      } else {
        IERC20(currency).safeTransfer(msg.sender, amount);
      }
      emit CuratorFeesClaimed(msg.sender, currency, amount);
    }
  }

  function verify(
    bytes32[] calldata proof,
    bytes32 root,
    bytes32 leaf
  ) external pure override returns (bool) {
    return _verifyAsm(proof, root, leaf);
  }

  // ====================================================== INTERNAL FUNCTIONS ================================================

  function _processClaim(
    address currency,
    uint256 cumulativeAmount,
    bytes32 expectedMerkleRoot,
    bytes32[] calldata merkleProof
  ) internal {
    require(merkleRoots[currency] == expectedMerkleRoot, 'invalid merkle root');

    // Verify the merkle proof
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, cumulativeAmount));
    require(_verifyAsm(merkleProof, expectedMerkleRoot, leaf), 'invalid merkle proof');

    // Mark it claimed
    uint256 preclaimed = cumulativeClaimed[msg.sender][currency];
    require(preclaimed < cumulativeAmount, 'merkle: nothing to claim');
    cumulativeClaimed[msg.sender][currency] = cumulativeAmount;
  }

  function _getEffectiveFeeBps(address user) internal view returns (uint16) {
    StakeLevel stakeLevel = IStaker(STAKER_CONTRACT).getUserStakeLevel(user);
    if (stakeLevel == StakeLevel.BRONZE) {
      // console.log('user is bronze');
      return BRONZE_EFFECTIVE_FEE_BPS;
    } else if (stakeLevel == StakeLevel.SILVER) {
      // console.log('user is silver');
      return SILVER_EFFECTIVE_FEE_BPS;
    } else if (stakeLevel == StakeLevel.GOLD) {
      // console.log('user is gold');
      return GOLD_EFFECTIVE_FEE_BPS;
    } else if (stakeLevel == StakeLevel.PLATINUM) {
      // console.log('user is platinum');
      return PLATINUM_EFFECTIVE_FEE_BPS;
    }
    return 10000;
  }

  function _allocateFeesToCreators(
    address execComplication,
    OrderTypes.OrderItem[] calldata items,
    uint256 amount,
    address currency
  ) internal returns (uint256) {
    // console.log('allocating fees to creators');
    // console.log('avg sale price', amount / items.length);
    uint256 creatorsFee = 0;
    IFeeManager feeManager = IFeeManager(CREATOR_FEE_MANAGER);
    for (uint256 h = 0; h < items.length; ) {
      (, address[] memory feeRecipients, uint256[] memory feeAmounts) = feeManager.calcFeesAndGetRecipients(
        execComplication,
        items[h].collection,
        0, // to comply with ierc2981 and royalty registry
        amount / items.length // amount per collection on avg
      );
      // console.log('collection', items[h].collection, 'num feeRecipients:', feeRecipients.length);
      for (uint256 i = 0; i < feeRecipients.length; ) {
        if (feeRecipients[i] != address(0) && feeAmounts[i] != 0) {
          // console.log('fee amount', i, feeAmounts[i]);
          creatorFees[feeRecipients[i]][currency] += feeAmounts[i];
          creatorsFee += feeAmounts[i];
        }
        unchecked {
          ++i;
        }
      }
      unchecked {
        ++h;
      }
    }
    // console.log('creatorsFee:', creatorsFee);
    return creatorsFee;
  }

  function _allocateFeesToCurators(
    uint256 amount,
    address currency,
    uint16 effectiveFeeBps
  ) internal returns (uint256) {
    // console.log('allocating fees to curators');
    uint256 curatorsFee = (((CURATOR_FEE_BPS * amount) / 10000) * effectiveFeeBps) / 10000;
    // update storage
    curatorFees[currency] += curatorsFee;
    // console.log('curatorsFee:', curatorsFee);
    return curatorsFee;
  }

  function _verifyAsm(
    bytes32[] calldata proof,
    bytes32 root,
    bytes32 leaf
  ) private pure returns (bool valid) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let mem1 := mload(0x40)
      let mem2 := add(mem1, 0x20)
      let ptr := proof.offset

      for {
        let end := add(ptr, mul(0x20, proof.length))
      } lt(ptr, end) {
        ptr := add(ptr, 0x20)
      } {
        let node := calldataload(ptr)

        switch lt(leaf, node)
        case 1 {
          mstore(mem1, leaf)
          mstore(mem2, node)
        }
        default {
          mstore(mem1, node)
          mstore(mem2, leaf)
        }

        leaf := keccak256(mem1, 0x40)
      }

      valid := eq(root, leaf)
    }
  }

  // ====================================================== VIEW FUNCTIONS ================================================

  function getEffectiveFeeBps(address user) external view returns (uint16) {
    return _getEffectiveFeeBps(user);
  }

  // ================================================= ADMIN FUNCTIONS ==================================================

  function rescueTokens(
    address destination,
    address currency,
    uint256 amount
  ) external onlyOwner {
    IERC20(currency).safeTransfer(destination, amount);
  }

  function rescueETH(address destination) external payable onlyOwner {
    (bool sent, ) = destination.call{value: msg.value}('');
    require(sent, 'Failed to send Ether');
  }

  function updateStakingContractAddress(address _stakerContract) external onlyOwner {
    STAKER_CONTRACT = _stakerContract;
    emit StakerContractUpdated(_stakerContract);
  }

  function updateCreatorFeeManager(address manager) external onlyOwner {
    CREATOR_FEE_MANAGER = manager;
    emit CreatorFeeManagerUpdated(manager);
  }

  function updateCuratorFees(uint16 bps) external onlyOwner {
    CURATOR_FEE_BPS = bps;
    emit CuratorFeeUpdated(bps);
  }

  function updateEffectiveFeeBps(StakeLevel stakeLevel, uint16 bps) external onlyOwner {
    if (stakeLevel == StakeLevel.BRONZE) {
      BRONZE_EFFECTIVE_FEE_BPS = bps;
    } else if (stakeLevel == StakeLevel.SILVER) {
      SILVER_EFFECTIVE_FEE_BPS = bps;
    } else if (stakeLevel == StakeLevel.GOLD) {
      GOLD_EFFECTIVE_FEE_BPS = bps;
    } else if (stakeLevel == StakeLevel.PLATINUM) {
      PLATINUM_EFFECTIVE_FEE_BPS = bps;
    }
    emit EffectiveFeeBpsUpdated(stakeLevel, bps);
  }

  function setMerkleRoot(address currency, bytes32 _merkleRoot) external override onlyOwner {
    emit MerkelRootUpdated(currency, merkleRoots[currency], _merkleRoot);
    merkleRoots[currency] = _merkleRoot;
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
import {OrderTypes} from '../libs/OrderTypes.sol';

interface IInfinityFeeTreasury {
  function getEffectiveFeeBps(address user) external view returns (uint16);

  function allocateFees(
    address seller,
    address buyer,
    OrderTypes.OrderItem[] calldata items,
    uint256 amount,
    address currency,
    uint256 minBpsToSeller,
    address execComplication,
    bool feeDiscountEnabled
  ) external payable;

  function refundMatchExecutionGasFee(
    uint256 startGas,
    OrderTypes.Order[] calldata sells,
    address matchExecutor,
    address weth
  ) external;

  function claimCreatorFees(address currency) external;

  function claimCuratorFees(
    address currency,
    uint256 cumulativeAmount,
    bytes32 expectedMerkleRoot,
    bytes32[] calldata merkleProof
  ) external;
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
pragma solidity ^0.8.0;

import {OrderTypes} from '../libs/OrderTypes.sol';

interface IComplication {
  function canExecOrder(
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed
  ) external view returns (bool, uint256);

  function canExecTakeOrder(OrderTypes.Order calldata makerOrder, OrderTypes.Order calldata takerOrder)
    external
    view
    returns (bool, uint256);

  function getProtocolFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from '../libs/OrderTypes.sol';

enum Duration {
  NONE,
  THREE_MONTHS,
  SIX_MONTHS,
  TWELVE_MONTHS
}

enum StakeLevel {
  NONE,
  BRONZE,
  SILVER,
  GOLD,
  PLATINUM
}

interface IStaker {
  function stake(address user, uint256 amount, Duration duration) external;

  function changeDuration(uint256 amount, Duration oldDuration, Duration newDuration) external;

  function unstake(uint256 amount) external;

  function rageQuit() external;

  function getUserTotalStaked(address user) external view returns (uint256);

  function getUserTotalVested(address user) external view returns (uint256);

  function getRageQuitAmounts(address user) external view returns (uint256, uint256);

  function getUserStakePower(address user) external view returns (uint256);

  function getUserStakeLevel(address user) external view returns (StakeLevel);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum FeeParty {
  CREATORS,
  COLLECTORS,
  CURATORS
}

interface IFeeManager {
  function calcFeesAndGetRecipients(
    address complication,
    address collection,
    uint256 tokenId,
    uint256 amount
  )
    external
    view
    returns (
      FeeParty partyName,
      address[] memory,
      uint256[] memory
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMerkleDistributor {
  // This event is triggered whenever a call to #setMerkleRoot succeeds.
  event MerkelRootUpdated(address currency, bytes32 oldMerkleRoot, bytes32 newMerkleRoot);

  // Sets the merkle root of the merkle tree containing cumulative account balances available to claim.
  function setMerkleRoot(address currency, bytes32 merkleRoot) external;

  function verify(
    bytes32[] calldata proof,
    bytes32 root,
    bytes32 leaf
  ) external returns (bool);
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
pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 */
library OrderTypes {
  struct TokenInfo {
    uint256 tokenId;
    uint256 numTokens;
  }

  struct OrderItem {
    address collection;
    TokenInfo[] tokens;
  }

  struct Order {
    // is order sell or buy
    bool isSellOrder;
    address signer;
    // total length: 7
    // in order:
    // numItems - min/max number of items in the order
    // start and end prices in wei
    // start and end times in block.timestamp
    // minBpsToSeller
    // nonce
    uint256[] constraints;
    // collections and tokenIds
    OrderItem[] nfts;
    // address of complication for trade execution (e.g. OrderBook), address of the currency (e.g., WETH)
    address[] execParams;
    // additional parameters like rarities, private sale buyer etc
    bytes extraParams;
    // uint8 v: parameter (27 or 28), bytes32 r, bytes32 s
    bytes sig;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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