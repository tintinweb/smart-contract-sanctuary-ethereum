// $$\       $$\                     $$\       $$\ $$\   $$\                     $$$$$$$$\                               $$\
// $$ |      \__|                    \__|      $$ |\__|  $$ |                    $$  _____|                              \__|
// $$ |      $$\  $$$$$$\  $$\   $$\ $$\  $$$$$$$ |$$\ $$$$$$\   $$\   $$\       $$ |   $$$$$$\   $$$$$$\  $$$$$$\$$$$\  $$\ $$$$$$$\   $$$$$$\
// $$ |      $$ |$$  __$$\ $$ |  $$ |$$ |$$  __$$ |$$ |\_$$  _|  $$ |  $$ |      $$$$$\ \____$$\ $$  __$$\ $$  _$$  _$$\ $$ |$$  __$$\ $$  __$$\
// $$ |      $$ |$$ /  $$ |$$ |  $$ |$$ |$$ /  $$ |$$ |  $$ |    $$ |  $$ |      $$  __|$$$$$$$ |$$ |  \__|$$ / $$ / $$ |$$ |$$ |  $$ |$$ /  $$ |
// $$ |      $$ |$$ |  $$ |$$ |  $$ |$$ |$$ |  $$ |$$ |  $$ |$$\ $$ |  $$ |      $$ |  $$  __$$ |$$ |      $$ | $$ | $$ |$$ |$$ |  $$ |$$ |  $$ |
// $$$$$$$$\ $$ |\$$$$$$$ |\$$$$$$  |$$ |\$$$$$$$ |$$ |  \$$$$  |\$$$$$$$ |      $$ |  \$$$$$$$ |$$ |      $$ | $$ | $$ |$$ |$$ |  $$ |\$$$$$$$ |
// \________|\__| \____$$ | \______/ \__| \_______|\__|   \____/  \____$$ |      \__|   \_______|\__|      \__| \__| \__|\__|\__|  \__| \____$$ |
//                     $$ |                                      $$\   $$ |                                                            $$\   $$ |
//                     $$ |                                      \$$$$$$  |                                                            \$$$$$$  |
//                     \__|                                       \______/                                                              \______/
//
// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./metatx/ERC2771ContextUpgradeable.sol";
import "./interfaces/IHyphenLiquidityFarmingV2.sol";

import "../security/Pausable.sol";
import "./interfaces/ILPToken.sol";
import "./interfaces/ILiquidityProviders.sol";

contract HyphenLiquidityFarming is
    Initializable,
    ERC2771ContextUpgradeable,
    OwnableUpgradeable,
    Pausable,
    ReentrancyGuardUpgradeable,
    IERC721ReceiverUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ILPToken public lpToken;
    ILiquidityProviders public liquidityProviders;

    struct NFTInfo {
        address payable staker;
        uint256 rewardDebt;
        uint256 unpaidRewards;
        bool isStaked;
    }

    struct PoolInfo {
        uint256 accTokenPerShare;
        uint256 lastRewardTime;
    }

    struct RewardsPerSecondEntry {
        uint256 rewardsPerSecond;
        uint256 timestamp;
    }

    /// @notice Mapping to track the rewarder pool.
    mapping(address => PoolInfo) public poolInfo;

    /// @notice Info of each NFT that is staked.
    mapping(uint256 => NFTInfo) public nftInfo;

    /// @notice Reward Token
    mapping(address => address) public rewardTokens;

    /// @notice Staker => NFTs staked
    mapping(address => uint256[]) public nftIdsStaked;

    /// @notice Token => Total Shares Staked
    mapping(address => uint256) public totalSharesStaked;

    /// @notice Token => Reward Rate Updation history
    mapping(address => RewardsPerSecondEntry[]) public rewardRateLog;

    uint256 private constant ACC_TOKEN_PRECISION = 1e12;
    address internal constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event LogDeposit(address indexed user, address indexed baseToken, uint256 nftId);
    event LogWithdraw(address indexed user, address baseToken, uint256 nftId, address indexed to);
    event LogOnReward(address indexed user, address indexed baseToken, uint256 amount, address indexed to);
    event LogUpdatePool(address indexed baseToken, uint256 lastRewardTime, uint256 lpSupply, uint256 accToken1PerShare);
    event LogRewardPerSecond(address indexed baseToken, uint256 rewardPerSecond);
    event LogRewardPoolInitialized(address _baseToken, address _rewardToken, uint256 _rewardPerSecond);
    event LogNativeReceived(address indexed sender, uint256 value);
    event LiquidityProviderUpdated(address indexed liquidityProviders);
    event LogNftMigrated(address indexed owner, uint256 indexed nftId, IHyphenLiquidityFarmingV2 farmingContract);

    function initialize(
        address _trustedForwarder,
        address _pauser,
        ILiquidityProviders _liquidityProviders,
        ILPToken _lpToken
    ) public initializer {
        __ERC2771Context_init(_trustedForwarder);
        __Ownable_init();
        __Pausable_init(_pauser);
        __ReentrancyGuard_init();
        liquidityProviders = _liquidityProviders;
        lpToken = _lpToken;
    }

    function setTrustedForwarder(address _tf) external onlyOwner {
        _setTrustedForwarder(_tf);
    }

    /// @notice Initialize the rewarder pool.
    /// @param _baseToken Base token to be used for the rewarder pool.
    /// @param _rewardToken Reward token to be used for the rewarder pool.
    /// @param _rewardPerSecond Reward rate per base token.
    function initalizeRewardPool(
        address _baseToken,
        address _rewardToken,
        uint256 _rewardPerSecond
    ) external onlyOwner {
        require(rewardTokens[_baseToken] == address(0), "ERR__POOL_ALREADY_INITIALIZED");
        require(_baseToken != address(0), "ERR__BASE_TOKEN_IS_ZERO");
        require(_rewardToken != address(0), "ERR_REWARD_TOKEN_IS_ZERO");
        rewardTokens[_baseToken] = _rewardToken;
        rewardRateLog[_baseToken].push(RewardsPerSecondEntry(_rewardPerSecond, block.timestamp));
        emit LogRewardPoolInitialized(_baseToken, _rewardToken, _rewardPerSecond);
    }

    function updateLiquidityProvider(ILiquidityProviders _liquidityProviders) external onlyOwner {
        require(address(_liquidityProviders) != address(0), "ERR__LIQUIDITY_PROVIDER_IS_ZERO");
        liquidityProviders = _liquidityProviders;
        emit LiquidityProviderUpdated(address(liquidityProviders));
    }

    function _sendErc20AndGetSentAmount(
        IERC20Upgradeable _token,
        uint256 _amount,
        address _to
    ) private returns (uint256) {
        uint256 beforeBalance = _token.balanceOf(address(this));
        _token.safeTransfer(_to, _amount);
        return beforeBalance - _token.balanceOf(address(this));
    }

    /// @notice Update the reward state of a nft, and if possible send reward funds to _to.
    /// @param _nftId NFT ID that is being locked
    /// @param _to Address to which rewards will be credited.
    function _sendRewardsForNft(uint256 _nftId, address payable _to) internal {
        NFTInfo storage nft = nftInfo[_nftId];
        require(nft.isStaked, "ERR__NFT_NOT_STAKED");

        (address baseToken, , uint256 amount) = lpToken.tokenMetadata(_nftId);
        amount /= liquidityProviders.BASE_DIVISOR();

        PoolInfo memory pool = updatePool(baseToken);
        uint256 pending;
        uint256 amountSent;
        if (amount > 0) {
            pending = ((amount * pool.accTokenPerShare) / ACC_TOKEN_PRECISION) - nft.rewardDebt + nft.unpaidRewards;
            if (rewardTokens[baseToken] == NATIVE) {
                uint256 balance = address(this).balance;
                if (pending > balance) {
                    unchecked {
                        nft.unpaidRewards = pending - balance;
                    }
                    (bool success, ) = _to.call{value: balance}("");
                    require(success, "ERR__NATIVE_TRANSFER_FAILED");
                    amountSent = balance;
                } else {
                    nft.unpaidRewards = 0;
                    (bool success, ) = _to.call{value: pending}("");
                    require(success, "ERR__NATIVE_TRANSFER_FAILED");
                    amountSent = pending;
                }
            } else {
                IERC20Upgradeable rewardToken = IERC20Upgradeable(rewardTokens[baseToken]);
                uint256 balance = rewardToken.balanceOf(address(this));
                if (pending > balance) {
                    unchecked {
                        nft.unpaidRewards = pending - balance;
                    }
                    amountSent = _sendErc20AndGetSentAmount(rewardToken, balance, _to);
                } else {
                    nft.unpaidRewards = 0;
                    amountSent = _sendErc20AndGetSentAmount(rewardToken, pending, _to);
                }
            }
        }
        nft.rewardDebt = (amount * pool.accTokenPerShare) / ACC_TOKEN_PRECISION;
        emit LogOnReward(_msgSender(), baseToken, amountSent, _to);
    }

    /// @notice Sets the sushi per second to be distributed. Can only be called by the owner.
    /// @param _rewardPerSecond The amount of Sushi to be distributed per second.
    function setRewardPerSecond(address _baseToken, uint256 _rewardPerSecond) external onlyOwner {
        require(_rewardPerSecond <= 10**40, "ERR__REWARD_PER_SECOND_TOO_HIGH");
        rewardRateLog[_baseToken].push(RewardsPerSecondEntry(_rewardPerSecond, block.timestamp));
        emit LogRewardPerSecond(_baseToken, _rewardPerSecond);
    }

    /// @notice Allows owner to reclaim/withdraw any tokens (including reward tokens) held by this contract
    /// @param _token Token to reclaim, use 0x00 for Ethereum
    /// @param _amount Amount of tokens to reclaim
    /// @param _to Receiver of the tokens, first of his name, rightful heir to the lost tokens,
    /// reightful owner of the extra tokens, and ether, protector of mistaken transfers, mother of token reclaimers,
    /// the Khaleesi of the Great Token Sea, the Unburnt, the Breaker of blockchains.
    function reclaimTokens(
        address _token,
        uint256 _amount,
        address payable _to
    ) external onlyOwner {
        require(_to != address(0), "ERR__TO_IS_ZERO");
        require(_amount != 0, "ERR__AMOUNT_IS_ZERO");
        if (_token == NATIVE) {
            (bool success, ) = payable(_to).call{value: _amount}("");
            require(success, "ERR__NATIVE_TRANSFER_FAILED");
        } else {
            IERC20Upgradeable(_token).safeTransfer(_to, _amount);
        }
    }

    /// @notice Deposit LP tokens
    /// @param _nftId LP token nftId to deposit.
    function deposit(uint256 _nftId, address payable _to) external whenNotPaused nonReentrant {
        address msgSender = _msgSender();

        require(_to != address(0), "ERR__TO_IS_ZERO");
        require(
            lpToken.isApprovedForAll(msgSender, address(this)) || lpToken.getApproved(_nftId) == address(this),
            "ERR__NOT_APPROVED"
        );

        NFTInfo storage nft = nftInfo[_nftId];
        require(!nft.isStaked, "ERR__NFT_ALREADY_STAKED");

        (address baseToken, , uint256 amount) = lpToken.tokenMetadata(_nftId);
        amount /= liquidityProviders.BASE_DIVISOR();

        require(rewardTokens[baseToken] != address(0), "ERR__POOL_NOT_INITIALIZED");
        require(rewardRateLog[baseToken].length != 0, "ERR__POOL_NOT_INITIALIZED");

        lpToken.safeTransferFrom(msgSender, address(this), _nftId);

        PoolInfo memory pool = updatePool(baseToken);
        nft.isStaked = true;
        nft.staker = _to;
        nft.rewardDebt = (amount * pool.accTokenPerShare) / ACC_TOKEN_PRECISION;

        nftIdsStaked[_to].push(_nftId);
        totalSharesStaked[baseToken] += amount;

        emit LogDeposit(msgSender, baseToken, _nftId);
    }

    /// @notice Withdraw LP tokens
    /// @param _nftId LP token nftId to withdraw.
    /// @param _to The receiver of `amount` withdraw benefit.
    function withdraw(uint256 _nftId, address payable _to) external whenNotPaused nonReentrant {
        uint256 index = getStakedNftIndex(_msgSender(), _nftId);
        _withdraw(_nftId, _to, index);
    }

    function getStakedNftIndex(address _staker, uint256 _nftId) public view returns (uint256) {
        uint256 nftsStakedLength = nftIdsStaked[_staker].length;
        uint256 index;
        unchecked {
            for (index = 0; index < nftsStakedLength; ++index) {
                if (nftIdsStaked[_staker][index] == _nftId) {
                    return index;
                }
            }
        }
        revert("ERR__NFT_NOT_STAKED");
    }

    function _withdraw(
        uint256 _nftId,
        address payable _to,
        uint256 _index
    ) private {
        address msgSender = _msgSender();

        require(nftIdsStaked[msgSender][_index] == _nftId, "ERR__NOT_OWNER");
        require(nftInfo[_nftId].staker == msgSender, "ERR__NOT_OWNER");
        require(nftInfo[_nftId].unpaidRewards == 0, "ERR__UNPAID_REWARDS_EXIST");

        nftIdsStaked[msgSender][_index] = nftIdsStaked[msgSender][nftIdsStaked[msgSender].length - 1];
        nftIdsStaked[msgSender].pop();

        _sendRewardsForNft(_nftId, _to);
        delete nftInfo[_nftId];

        (address baseToken, , uint256 amount) = lpToken.tokenMetadata(_nftId);
        amount /= liquidityProviders.BASE_DIVISOR();
        totalSharesStaked[baseToken] -= amount;

        lpToken.safeTransferFrom(address(this), msgSender, _nftId);

        emit LogWithdraw(msgSender, baseToken, _nftId, _to);
    }

    function withdrawV2(
        uint256 _nftId,
        address payable _to,
        uint256 _index
    ) external whenNotPaused nonReentrant {
        _withdraw(_nftId, _to, _index);
    }

    /// @notice Extract all rewards without withdrawing LP tokens
    /// @param _nftId LP token nftId for which rewards are to be withdrawn
    /// @param _to The receiver of withdraw benefit.
    function extractRewards(uint256 _nftId, address payable _to) external whenNotPaused nonReentrant {
        require(nftInfo[_nftId].staker == _msgSender(), "ERR__NOT_OWNER");
        _sendRewardsForNft(_nftId, _to);
    }

    /// @notice Calculates an up to date value of accTokenPerShare
    /// @notice An updated value of accTokenPerShare is comitted to storage every time a new NFT is deposited, withdrawn or rewards are extracted
    function getUpdatedAccTokenPerShare(address _baseToken) public view returns (uint256) {
        uint256 accumulator = 0;
        uint256 lastUpdatedTime = poolInfo[_baseToken].lastRewardTime;
        uint256 counter = block.timestamp;
        uint256 i = rewardRateLog[_baseToken].length - 1;
        while (true) {
            if (lastUpdatedTime >= counter) {
                break;
            }
            unchecked {
                accumulator +=
                    rewardRateLog[_baseToken][i].rewardsPerSecond *
                    (counter - max(lastUpdatedTime, rewardRateLog[_baseToken][i].timestamp));
            }
            counter = rewardRateLog[_baseToken][i].timestamp;
            if (i == 0) {
                break;
            }
            --i;
        }

        // We know that during all the periods that were included in the current iterations,
        // the value of totalSharesStaked[_baseToken] would not have changed, as we only consider the
        // updates to the pool that happened after the lastUpdatedTime.
        accumulator = (accumulator * ACC_TOKEN_PRECISION) / totalSharesStaked[_baseToken];
        return accumulator + poolInfo[_baseToken].accTokenPerShare;
    }

    /// @notice View function to see pending Token
    /// @param _nftId NFT for which pending tokens are to be viewed
    /// @return pending reward for a given user.
    function pendingToken(uint256 _nftId) external view returns (uint256) {
        NFTInfo storage nft = nftInfo[_nftId];
        if (!nft.isStaked) {
            return 0;
        }

        (address baseToken, , uint256 amount) = lpToken.tokenMetadata(_nftId);
        amount /= liquidityProviders.BASE_DIVISOR();

        PoolInfo memory pool = poolInfo[baseToken];
        uint256 accToken1PerShare = pool.accTokenPerShare;
        if (block.timestamp > pool.lastRewardTime && totalSharesStaked[baseToken] != 0) {
            accToken1PerShare = getUpdatedAccTokenPerShare(baseToken);
        }
        return ((amount * accToken1PerShare) / ACC_TOKEN_PRECISION) - nft.rewardDebt + nft.unpaidRewards;
    }

    /// @notice Update reward variables of the given pool.
    /// @return pool Returns the pool that was updated.
    function updatePool(address _baseToken) public whenNotPaused returns (PoolInfo memory pool) {
        pool = poolInfo[_baseToken];
        if (totalSharesStaked[_baseToken] > 0) {
            pool.accTokenPerShare = getUpdatedAccTokenPerShare(_baseToken);
        }
        pool.lastRewardTime = block.timestamp;
        poolInfo[_baseToken] = pool;
        emit LogUpdatePool(_baseToken, pool.lastRewardTime, totalSharesStaked[_baseToken], pool.accTokenPerShare);
    }

    /// @notice View function to see the tokens staked by a given user.
    /// @param _user Address of user.
    function getNftIdsStaked(address _user) external view returns (uint256[] memory nftIds) {
        nftIds = nftIdsStaked[_user];
    }

    function getRewardRatePerSecond(address _baseToken) external view returns (uint256) {
        return rewardRateLog[_baseToken][rewardRateLog[_baseToken].length - 1].rewardsPerSecond;
    }

    function migrateNftsToV2(uint256[] calldata _nftIds, IHyphenLiquidityFarmingV2 _farmingV2) external {
        uint256 length = _nftIds.length;
        address payable msgSender = payable(_msgSender());

        for (uint256 i = 0; i < length; ) {
            uint256 nftId = _nftIds[i];
            uint256 index = getStakedNftIndex(_msgSender(), nftId);

            require(nftIdsStaked[msgSender][index] == nftId, "ERR__NOT_OWNER");
            require(nftInfo[nftId].staker == msgSender, "ERR__NOT_OWNER");

            nftIdsStaked[msgSender][index] = nftIdsStaked[msgSender][nftIdsStaked[msgSender].length - 1];
            nftIdsStaked[msgSender].pop();

            _sendRewardsForNft(nftId, msgSender);

            require(nftInfo[nftId].unpaidRewards == 0, "ERR__UNPAID_REWARDS_EXIST");
            delete nftInfo[nftId];

            (address baseToken, , uint256 amount) = lpToken.tokenMetadata(nftId);
            amount /= liquidityProviders.BASE_DIVISOR();
            totalSharesStaked[baseToken] -= amount;

            lpToken.approve(address(_farmingV2), nftId);
            _farmingV2.deposit(nftId, msgSender);

            emit LogNftMigrated(msgSender, nftId, _farmingV2);

            unchecked {
                ++i;
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override(IERC721ReceiverUpgradeable) returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    receive() external payable {
        emit LogNativeReceived(_msgSender(), msg.value);
    }

    function max(uint256 _a, uint256 _b) private pure returns (uint256) {
        return _a >= _b ? _a : _b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721ReceiverUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 * Here _trustedForwarder is made internal instead of private
 * so it can be changed via Child contracts with a setter method.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    event TrustedForwarderChanged(address indexed _tf);

    address internal _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal initializer {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal initializer {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function _setTrustedForwarder(address _tf) internal virtual {
        require(_tf != address(0), "TrustedForwarder can't be 0");
        _trustedForwarder = _tf;
        emit TrustedForwarderChanged(_tf);
    }

    uint256[49] private __gap;
}

interface IHyphenLiquidityFarmingV2 {
    function changePauser(address newPauser) external;

    function deposit(uint256 _nftId, address _to) external;

    function extractRewards(
        uint256 _nftId,
        address[] memory _rewardTokens,
        address _to
    ) external;

    function getNftIdsStaked(address _user) external view returns (uint256[] memory nftIds);

    function getRewardRatePerSecond(address _baseToken, address _rewardToken) external view returns (uint256);

    function getRewardTokens(address _baseToken) external view returns (address[] memory);

    function getStakedNftIndex(address _staker, uint256 _nftId) external view returns (uint256);

    function getUpdatedAccTokenPerShare(address _baseToken, address _rewardToken) external view returns (uint256);

    function initialize(
        address _trustedForwarder,
        address _pauser,
        address _liquidityProviders,
        address _lpToken
    ) external;

    function isPauser(address pauser) external view returns (bool);

    function isTrustedForwarder(address forwarder) external view returns (bool);

    function liquidityProviders() external view returns (address);

    function lpToken() external view returns (address);

    function nftIdsStaked(address, uint256) external view returns (uint256);

    function nftInfo(uint256) external view returns (address staker, bool isStaked);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function pendingToken(uint256 _nftId, address _rewardToken) external view returns (uint256);

    function poolInfo(address, address) external view returns (uint256 accTokenPerShare, uint256 lastRewardTime);

    function reclaimTokens(
        address _token,
        uint256 _amount,
        address _to
    ) external;

    function renounceOwnership() external;

    function renouncePauser() external;

    function rewardRateLog(
        address,
        address,
        uint256
    ) external view returns (uint256 rewardsPerSecond, uint256 timestamp);

    function setRewardPerSecond(
        address _baseToken,
        address _rewardToken,
        uint256 _rewardPerSecond
    ) external;

    function setTrustedForwarder(address _tf) external;

    function totalSharesStaked(address) external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function unpause() external;

    function updateLiquidityProvider(address _liquidityProviders) external;

    function withdraw(uint256 _nftId, address _to) external;

    function withdrawAtIndex(
        uint256 _nftId,
        address _to,
        uint256 _index
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Initializable, PausableUpgradeable {
    address private _pauser;

    event PauserChanged(address indexed previousPauser, address indexed newPauser);

    /**
     * @dev The pausable constructor sets the original `pauser` of the contract to the sender
     * account & Initializes the contract in unpaused state..
     */
    function __Pausable_init(address pauser) internal initializer {
        require(pauser != address(0), "Pauser Address cannot be 0");
        __Pausable_init();
        _pauser = pauser;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isPauser(address pauser) public view returns (bool) {
        return pauser == _pauser;
    }

    /**
     * @dev Throws if called by any account other than the pauser.
     */
    modifier onlyPauser() {
        require(isPauser(msg.sender), "Only pauser is allowed to perform this operation");
        _;
    }

    /**
     * @dev Allows the current pauser to transfer control of the contract to a newPauser.
     * @param newPauser The address to transfer pauserShip to.
     */
    function changePauser(address newPauser) public onlyPauser whenNotPaused {
        _changePauser(newPauser);
    }

    /**
     * @dev Transfers control of the contract to a newPauser.
     * @param newPauser The address to transfer ownership to.
     */
    function _changePauser(address newPauser) internal {
        require(newPauser != address(0));
        emit PauserChanged(_pauser, newPauser);
        _pauser = newPauser;
    }

    function renouncePauser() external virtual onlyPauser whenNotPaused {
        emit PauserChanged(_pauser, address(0));
        _pauser = address(0);
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "../structures/LpTokenMetadata.sol";

interface ILPToken {
    function approve(address to, uint256 tokenId) external;

    function balanceOf(address _owner) external view returns (uint256);

    function exists(uint256 _tokenId) external view returns (bool);

    function getAllNftIdsByUser(address _owner) external view returns (uint256[] memory);

    function getApproved(uint256 tokenId) external view returns (address);

    function initialize(
        string memory _name,
        string memory _symbol,
        address _trustedForwarder
    ) external;

    function isApprovedForAll(address _owner, address operator) external view returns (bool);

    function isTrustedForwarder(address forwarder) external view returns (bool);

    function liquidityPoolAddress() external view returns (address);

    function mint(address _to) external returns (uint256);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function paused() external view returns (bool);

    function renounceOwnership() external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setLiquidityPool(address _lpm) external;

    function setWhiteListPeriodManager(address _whiteListPeriodManager) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenMetadata(uint256)
        external
        view
        returns (
            address token,
            uint256 totalSuppliedLiquidity,
            uint256 totalShares
        );

    function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferOwnership(address newOwner) external;

    function updateTokenMetadata(uint256 _tokenId, LpTokenMetadata memory _lpTokenMetadata) external;

    function whiteListPeriodManager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ILiquidityProviders {
    function BASE_DIVISOR() external view returns (uint256);

    function initialize(address _trustedForwarder, address _lpToken) external;

    function addLPFee(address _token, uint256 _amount) external;

    function addNativeLiquidity() external;

    function addTokenLiquidity(address _token, uint256 _amount) external;

    function claimFee(uint256 _nftId) external;

    function getFeeAccumulatedOnNft(uint256 _nftId) external view returns (uint256);

    function getSuppliedLiquidityByToken(address tokenAddress) external view returns (uint256);

    function getTokenPriceInLPShares(address _baseToken) external view returns (uint256);

    function getTotalLPFeeByToken(address tokenAddress) external view returns (uint256);

    function getTotalReserveByToken(address tokenAddress) external view returns (uint256);

    function getSuppliedLiquidity(uint256 _nftId) external view returns (uint256);

    function increaseNativeLiquidity(uint256 _nftId) external;

    function increaseTokenLiquidity(uint256 _nftId, uint256 _amount) external;

    function isTrustedForwarder(address forwarder) external view returns (bool);

    function owner() external view returns (address);

    function paused() external view returns (bool);

    function removeLiquidity(uint256 _nftId, uint256 amount) external;

    function renounceOwnership() external;

    function setLiquidityPool(address _liquidityPool) external;

    function setLpToken(address _lpToken) external;

    function setWhiteListPeriodManager(address _whiteListPeriodManager) external;

    function sharesToTokenAmount(uint256 _shares, address _tokenAddress) external view returns (uint256);

    function totalLPFees(address) external view returns (uint256);

    function totalLiquidity(address) external view returns (uint256);

    function totalReserve(address) external view returns (uint256);

    function totalSharesMinted(address) external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function whiteListPeriodManager() external view returns (address);

    function increaseCurrentLiquidity(address tokenAddress, uint256 amount) external;

    function decreaseCurrentLiquidity(address tokenAddress, uint256 amount) external;

    function getCurrentLiquidity(address tokenAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

struct LpTokenMetadata {
    address token;
    uint256 suppliedLiquidity;
    uint256 shares;
}