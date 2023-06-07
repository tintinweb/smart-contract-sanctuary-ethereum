// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IBrewlabsPair.sol";
import "./libraries/SafeMath.sol";
import "./libraries/BrewlabsLibrary.sol";

contract BrewlabsSwapFeeManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;

    address private factory;

    struct FeeDistribution {
        uint256 lpFee;
        uint256 brewlabsFee;
        uint256 tokenOwnerFee;
        uint256 stakingFee;
        uint256 referralFee;
    }

    struct LPStakingInfo {
        uint256 lpSupply; // total LP token supply
        uint256 accRewards0;
        uint256 accRewards1;
        address[] lpStakersArray; // list of lp holder
        mapping(address => uint256) lpStaked; // keep lp balance of lp holders
        mapping(address => uint256) rewardsTable0; // last updated token0 rewards for lp holders
        mapping(address => uint256) rewardsTable1; // last updated token1 rewards for lp holders
    }

    struct Pool {
        address token0;
        address token1;
        address tokenOwner;
        LPStakingInfo lpStakingInfo;
        FeeDistribution feeDistribution;
        address referrer;
        mapping(address => uint256) balanceOfLpProvider; // fee token balance assigned to lp holders
        mapping(address => uint256) balanceOfBrewlabs; // fee token balance assigned to brewlabs treasury
        mapping(address => uint256) balanceOfTokenOwner; // fee token balance assigned to token owner
        mapping(address => uint256) balanceOfReferral; // fee token balance assigned to stakers of referral contract
        mapping(address => uint256) totalBalance;
        uint256 timeToOpen;
    }

    uint256 private constant DEFAULT_LP_FEE = 25; // 0.25%
    uint256 private constant DEFAULT_BREWLABS_FEE = 5; // 0.05%

    uint256 private constant MAX_TOKEN_OWNER_FEE = 5; // 0.05%
    uint256 private constant MAX_STAKING_FEE = 5; // 1%
    uint256 private constant MAX_REFERRAL_FEE = 100; // 1%

    mapping(address => Pool) private pools;
    address[] public pairs;

    event RewardClaimed(address indexed to, address indexed pair, uint256 token0Amount, uint256 token1Amount);
    event RewardDeposited(address indexed pair, address indexed token, uint256 amount);
    event TokenOwnerUpdated(address indexed pair, address indexed tokenOwner);
    event ReferrerUpdated(address indexed pair, address indexed referrer);

    modifier validPair(address pair, address token0, address token1) {
        require(pair == BrewlabsLibrary.pairFor(factory, token0, token1), "BrewlabsFeeManager: INVALID PAIR");
        _;
    }

    modifier existPair(address pair) {
        require(pools[pair].token0 != address(0) && pools[pair].token1 != address(0), "BrewlabsFeeManager: PAIR DOESN'T EXIST");
        _;
    }

    // constructor() public {}

    function initialize(address _factory) external initializer {
        __Ownable_init();
        factory = _factory;
    }

    function setTokenOwner(address pair, address tokenOwner) external onlyOwner existPair(pair) {
        require(tokenOwner != address(0), "BrewlabsFeeManager: INVALID TOKEN OWNER ADDRESS");
        pools[pair].tokenOwner = tokenOwner;
        emit TokenOwnerUpdated(pair, tokenOwner);
    }

    function setReferrer(address pair, address referrer) external onlyOwner existPair(pair) {
        require(referrer != address(0), "BrewlabsFeeManager: INVALID REFERRER ADDRESS");
        pools[pair].referrer = referrer;
        emit ReferrerUpdated(pair, referrer);
    }

    function setTime2OpenPool(address pair, uint256 time) external onlyOwner existPair(pair) {
        require(time > block.timestamp, "BrewlabsFeeManager: ELAPSED TIME");
        pools[pair].timeToOpen = time;
    }

    function setFeeDistribution(address pair, bytes calldata feeDistribution) external onlyOwner existPair(pair) {
        require(
            block.timestamp < pools[pair].timeToOpen, "BrewlabsFeeManager: AFTER THE POOL OPENED, UNABLE TO CHANGE FEE"
        );
        _setFeeDistribution(pair, feeDistribution);
    }

    /**
     * @dev initialize pool for the pair represented by token0 and token1, which wil keep
     * fee balance coming from the pair. this should be called by factory at the time of lp creation
     * @param token0 token0 address of lp pair
     * @param token1 token1 address of lp pair
     */
    function createPool(address token0, address token1) external {
        require(msg.sender == factory, "BrewlabsFeeManager: FORBIDDEN");
        address pair = BrewlabsLibrary.pairFor(factory, token0, token1);

        pools[pair].token0 = token0;
        pools[pair].token1 = token1;

        pools[pair].feeDistribution.lpFee = DEFAULT_LP_FEE;
        pools[pair].feeDistribution.brewlabsFee = DEFAULT_BREWLABS_FEE;

        pools[pair].timeToOpen = block.timestamp + 3600 * 24;

        pairs.push(pair);
    }

    /**
     * @dev update fee rewarding stats based on new minted lp token amount
     * this should be called by pair token contract at the time of minting lp token
     * @param to liquidity provider the lp newly being minted to
     * @param token0 token0 address of lp pair
     * @param token1 token1 address of lp pair
     * @param pair caller - lp pair token address
     */
    function lpMinted(address to, address token0, address token1, address pair)
        external
        validPair(pair, token0, token1)
    {
        _updateLPRewardsTable(pair);
        _updateStakedLP(pair, to);
        _updateLPSupply(pair);
    }

    /**
     * @dev update lp fee rewarding stats based on burnt lp token
     * this should be called by pair token contract at the time of burning lp token
     * @param from liquidity provider the lp being burnt from
     * @param token0 token0 address of lp pair
     * @param token1 token1 address of lp pair
     * @param pair caller - lp pair token address
     */
    function lpBurned(address from, address token0, address token1, address pair)
        external
        validPair(pair, token0, token1)
    {
        _updateLPRewardsTable(pair);
        _updateStakedLP(pair, from);
        if (pools[pair].lpStakingInfo.lpStaked[from] == 0) {
            __claimLPFee(pair, from);
        }
        _updateLPSupply(pair);
    }

    /**
     * @dev update lp fee rewarding stats based on transfer transaction details
     * this should be called by pair token contract at the time of lp token transfer
     * @param from lp sender
     * @param to lp receiver
     * @param token0 token0 address of lp pair
     * @param token1 token1 address of lp pair
     * @param pair caller - lp pair token address
     */
    function lpTransferred(address from, address to, address token0, address token1, address pair)
        external
        validPair(pair, token0, token1)
    {
        _updateLPRewardsTable(pair);
        uint256 lpBalanceBeforeTransfer = pools[pair].lpStakingInfo.lpStaked[from];
        require(lpBalanceBeforeTransfer > 0, "BrewlabsFeeManager: INVALID TRANSFER");
        _updateStakedLP(pair, from);
        _updateStakedLP(pair, to);
        uint256 lpBalanceAfterTransfer = pools[pair].lpStakingInfo.lpStaked[from];
        require(lpBalanceBeforeTransfer > lpBalanceAfterTransfer, "BrewlabsFeeManager: INVALID TRANSFER");
        {
            address _from = from;
            address _to = to;
            uint256 movingReward0 = pools[pair].lpStakingInfo.rewardsTable0[_from].mul(
                lpBalanceBeforeTransfer - lpBalanceAfterTransfer
            ).div(lpBalanceBeforeTransfer);
            pools[pair].lpStakingInfo.rewardsTable0[_from] -= movingReward0;
            pools[pair].lpStakingInfo.rewardsTable0[_to] += movingReward0;
            uint256 movingReward1 = pools[pair].lpStakingInfo.rewardsTable1[_from].mul(
                lpBalanceBeforeTransfer - lpBalanceAfterTransfer
            ).div(lpBalanceBeforeTransfer);
            pools[pair].lpStakingInfo.rewardsTable1[_from] -= movingReward1;
            pools[pair].lpStakingInfo.rewardsTable1[_to] += movingReward1;
        }
    }

    /**
     * @dev deposit fee token from pair at the time of user trading.
     * @param pair fee token resource
     * @param token fee token address
     * @param amount fee token amount being deposited
     */
    function notifyRewardAmount(address pair, address token, uint256 amount) external existPair(pair) {
        require(token == pools[pair].token0 || token == pools[pair].token1, "BrewlabsFeeManager: INVALID TOKEN DEPOSIT");
        require(amount > 0, "BrewlabsFeeManager: INSUFFICIENT REWARD AMOUNT");
        uint256 beforeAmt = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        uint256 afterAmt = IERC20(token).balanceOf(address(this));
        amount = afterAmt - beforeAmt;

        (
            uint256 totalFee,
            uint256 lpFee,
            uint256 brewlabsFee,
            uint256 tokenOwnerFee,
            uint256 stakingFee,
            uint256 referralFee
        ) = getFeeDistribution(pair);

        totalFee = totalFee - brewlabsFee - stakingFee;

        pools[pair].balanceOfLpProvider[token] += amount.mul(lpFee).div(totalFee);
        pools[pair].balanceOfTokenOwner[token] += amount.mul(tokenOwnerFee).div(totalFee);
        pools[pair].balanceOfReferral[token] += amount.mul(referralFee).div(totalFee);
        pools[pair].totalBalance[token] += amount;
        emit RewardDeposited(pair, token, amount);
    }

    /**
     * @dev claim all relevant fee from the pair including lpfee, tokenownerfee and referralfee
     *  @param pair brewlabs pair address represent the pool in which keeping fee
     */
    function claim(address pair) public nonReentrant existPair(pair) {
        address token0 = pools[pair].token0;
        address token1 = pools[pair].token1;
        uint256 totalBalance0BeforeClaim = pools[pair].totalBalance[token0];
        uint256 totalBalance1BeforeClaim = pools[pair].totalBalance[token1];

        _claimLPFee(pair, msg.sender);

        if (msg.sender == pools[pair].referrer) {
            _claimReferralFee(pair);
        }

        if (msg.sender == pools[pair].tokenOwner) {
            _claimTokenOwnerFee(pair);
        }

        uint256 totalBalance0AfterClaim = pools[pair].totalBalance[token0];
        uint256 totalBalance1AfterClaim = pools[pair].totalBalance[token1];

        emit RewardClaimed(
            msg.sender,
            pair,
            totalBalance0BeforeClaim - totalBalance0AfterClaim,
            totalBalance1BeforeClaim - totalBalance1AfterClaim
            );
    }

    /**
     * @dev claim fees from multiple pairs at a time
     *  @param brewlabs_pairs array of brewlabs pairs' address represent the pools in which keepinng fee
     */
    function claimAll(address[] calldata brewlabs_pairs) external nonReentrant {
        require(brewlabs_pairs.length > 0, "BrewlabsFeeManager: NOWHERE TO CLAIM FROM");
        for (uint256 i; i < brewlabs_pairs.length; i++) {
            claim(brewlabs_pairs[i]);
        }
    }

    function _setFeeDistribution(address pair, bytes memory feeDistribution) internal {
        (uint256 _lpFee, uint256 _brewlabsFee, uint256 _tokenOwnerFee, uint256 _stakingFee, uint256 _referralFee) =
            abi.decode(feeDistribution, (uint256, uint256, uint256, uint256, uint256));
        require(_lpFee == DEFAULT_LP_FEE, "BrewlabsFeeManager: INVALID LP FEE VALUE");
        require(_brewlabsFee == DEFAULT_BREWLABS_FEE, "BrewlabsFeeManager: INVALID BREWLABS FEE VALUE");
        require(_tokenOwnerFee <= MAX_TOKEN_OWNER_FEE, "BrewlabsFeeManager: INVALID TOKEN OWNER FEE VALUE");
        require(_stakingFee <= MAX_STAKING_FEE, "BrewlabsFeeManager: INVALID TOKEN HOLDER FEE VALUE");
        require(_referralFee <= MAX_REFERRAL_FEE, "BrewlabsFeeManager: INVALID REFERRAL FEE VALUE");

        if (_referralFee > 0 && pools[pair].referrer == address(0)) {
            revert("BrewlabsFeeManager: REFERRER NOT DEFINED YET");
        }
        if (_tokenOwnerFee > 0 && pools[pair].tokenOwner == address(0)) {
            revert("BrewlabsFeeManager: TOKEN OWNER NOT DEFINED YET");
        }

        pools[pair].feeDistribution.lpFee = _lpFee;
        pools[pair].feeDistribution.brewlabsFee = _brewlabsFee;
        pools[pair].feeDistribution.tokenOwnerFee = _tokenOwnerFee;
        pools[pair].feeDistribution.stakingFee = _stakingFee;
        pools[pair].feeDistribution.referralFee = _referralFee;
    }

    function _updateStakedLP(address pair, address to) internal {
        uint256 lpBalance = IBrewlabsPair(pair).balanceOf(to);
        if (pools[pair].lpStakingInfo.lpStaked[to] == 0 && lpBalance > 0) {
            pools[pair].lpStakingInfo.lpStakersArray.push(to);
        }
        if (pools[pair].lpStakingInfo.lpStaked[to] > 0 && lpBalance == 0) {
            uint256 length = pools[pair].lpStakingInfo.lpStakersArray.length;
            for (uint256 i; i < length; i++) {
                if (to == pools[pair].lpStakingInfo.lpStakersArray[i]) {
                    pools[pair].lpStakingInfo.lpStakersArray[i] = pools[pair].lpStakingInfo.lpStakersArray[length - 1];
                    pools[pair].lpStakingInfo.lpStakersArray.pop();
                    break;
                }
            }
        }
        pools[pair].lpStakingInfo.lpStaked[to] = lpBalance;
    }

    function _updateLPSupply(address pair) internal {
        pools[pair].lpStakingInfo.lpSupply = IBrewlabsPair(pair).totalSupply();
    }

    function _updateLPRewardsTable(address pair) internal {
        LPStakingInfo storage lpStakingInfo = pools[pair].lpStakingInfo;
        if (lpStakingInfo.lpSupply == 0) return;
        address token0 = pools[pair].token0;
        address token1 = pools[pair].token1;

        uint256 balance0 = pools[pair].balanceOfLpProvider[token0];
        uint256 balance1 = pools[pair].balanceOfLpProvider[token1];

        uint256 leftOver0 = balance0 - lpStakingInfo.accRewards0;
        uint256 leftOver1 = balance1 - lpStakingInfo.accRewards1;

        for (uint256 i; i < lpStakingInfo.lpStakersArray.length; i++) {
            address lpStaker = lpStakingInfo.lpStakersArray[i];
            uint256 amount0Plus = leftOver0.mul(lpStakingInfo.lpStaked[lpStaker]).div(lpStakingInfo.lpSupply);
            uint256 amount1Plus = leftOver1.mul(lpStakingInfo.lpStaked[lpStaker]).div(lpStakingInfo.lpSupply);

            pools[pair].lpStakingInfo.rewardsTable0[lpStaker] += amount0Plus;
            pools[pair].lpStakingInfo.rewardsTable1[lpStaker] += amount1Plus;

            pools[pair].lpStakingInfo.accRewards0 += amount0Plus;
            pools[pair].lpStakingInfo.accRewards1 += amount1Plus;
        }
    }

    function _claimLPFee(address pair, address to) internal {
        _updateStakedLP(pair, to);
        (uint256 amount0, uint256 amount1) = pendingLPRewards(pair, to);
        if (amount0 > 0 || amount1 > 0) {
            _updateLPRewardsTable(pair);
            __claimLPFee(pair, to);
        }
    }

    function __claimLPFee(address pair, address to) internal {
        address token0 = pools[pair].token0;
        address token1 = pools[pair].token1;
        uint256 claimAmount0 = pools[pair].lpStakingInfo.rewardsTable0[to];
        uint256 claimAmount1 = pools[pair].lpStakingInfo.rewardsTable1[to];
        pools[pair].lpStakingInfo.accRewards0 -= claimAmount0;
        pools[pair].lpStakingInfo.accRewards1 -= claimAmount1;
        pools[pair].lpStakingInfo.rewardsTable0[to] = 0;
        pools[pair].lpStakingInfo.rewardsTable1[to] = 0;

        if (claimAmount0 > 0) {
            pools[pair].balanceOfLpProvider[token0] -= claimAmount0;
            pools[pair].totalBalance[token0] -= claimAmount0;
            IERC20(token0).transfer(to, claimAmount0);
        }
        if (claimAmount1 > 0) {
            pools[pair].balanceOfLpProvider[token1] -= claimAmount1;
            pools[pair].totalBalance[token1] -= claimAmount1;
            IERC20(token1).transfer(to, claimAmount1);
        }
    }

    function _claimReferralFee(address pair) internal {
        address token0 = pools[pair].token0;
        address token1 = pools[pair].token1;
        address referrer = pools[pair].referrer;
        uint256 rewards0 = pools[pair].balanceOfReferral[token0];
        uint256 rewards1 = pools[pair].balanceOfReferral[token1];

        if (rewards0 > 0) {
            pools[pair].balanceOfReferral[token0] = 0;
            pools[pair].totalBalance[token0] -= rewards0;
            IERC20(token0).transfer(referrer, rewards0);
        }
        if (rewards1 > 0) {
            pools[pair].balanceOfReferral[token1] = 0;
            pools[pair].totalBalance[token1] -= rewards1;
            IERC20(token1).transfer(referrer, rewards1);
        }
    }

    function _claimTokenOwnerFee(address pair) internal {
        address token0 = pools[pair].token0;
        address token1 = pools[pair].token1;
        address tokenOwner = pools[pair].tokenOwner;
        uint256 rewards0 = pools[pair].balanceOfTokenOwner[token0];
        uint256 rewards1 = pools[pair].balanceOfTokenOwner[token1];

        if (rewards0 > 0) {
            pools[pair].balanceOfTokenOwner[token0] = 0;
            pools[pair].totalBalance[token0] -= rewards0;
            IERC20(token0).transfer(tokenOwner, rewards0);
        }
        if (rewards1 > 0) {
            pools[pair].balanceOfTokenOwner[token1] = 0;
            pools[pair].totalBalance[token1] -= rewards1;
            IERC20(token1).transfer(tokenOwner, rewards1);
        }
    }

    ////// VIEW FUNCTIONS //////
    function getFeeDistribution(address pair)
        public
        view
        existPair(pair)
        returns (
            uint256 totalFee,
            uint256 lpFee,
            uint256 brewlabsFee,
            uint256 tokenOwnerFee,
            uint256 stakingFee,
            uint256 referralFee
        )
    {
        lpFee = pools[pair].feeDistribution.lpFee;
        brewlabsFee = pools[pair].feeDistribution.brewlabsFee;
        tokenOwnerFee = pools[pair].feeDistribution.tokenOwnerFee;
        stakingFee = pools[pair].feeDistribution.stakingFee;
        referralFee = pools[pair].feeDistribution.referralFee;

        totalFee = lpFee + brewlabsFee + tokenOwnerFee + stakingFee + referralFee;
    }

    function getReferrer(address pair) external view returns (address) {
        return pools[pair].referrer;
    }

    function getTokenOwner(address pair) external view returns (address) {
        return pools[pair].tokenOwner;
    }

    function pendingLPRewards(address pair, address staker) public view returns (uint256 amount0, uint256 amount1) {
        LPStakingInfo storage lpStakingInfo = pools[pair].lpStakingInfo;
        address token0 = pools[pair].token0;
        address token1 = pools[pair].token1;
        uint256 balance0 = pools[pair].balanceOfLpProvider[token0];
        uint256 balance1 = pools[pair].balanceOfLpProvider[token1];
        uint256 lpBalance = IBrewlabsPair(pair).balanceOf(staker);
        uint256 leftOver0 = balance0 - lpStakingInfo.accRewards0;
        uint256 leftOver1 = balance1 - lpStakingInfo.accRewards1;
        amount0 = lpStakingInfo.lpSupply == 0
            ? 0
            : lpStakingInfo.rewardsTable0[staker] + leftOver0.mul(lpBalance).div(lpStakingInfo.lpSupply);
        amount1 = lpStakingInfo.lpSupply == 0
            ? 0
            : lpStakingInfo.rewardsTable1[staker] + leftOver1.mul(lpBalance).div(lpStakingInfo.lpSupply);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import "../proxy/Initializable.sol";

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

pragma solidity ^0.7.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.5.0;

interface IBrewlabsPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getAmountIn(uint256 amountOut, address tokenIn, uint256 discount) external view returns (uint256);
    function getAmountOut(uint256 amountIn, address tokenIn, uint256 discount) external view returns (uint256);
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint16 feePercent, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);

    function setFeePercent(uint16 feePercent) external;
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, uint256 discount, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

import "../interfaces/IBrewlabsPair.sol";

import "./SafeMath.sol";

library BrewlabsLibrary {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "BrewlabsLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "BrewlabsLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"8ebb0b7a7757868409afdbecbf08097e01f7e2b2f101deb163e5272e73a69c48" // init code hash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,,) = IBrewlabsPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "BrewlabsLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "BrewlabsLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path, uint256 discount)
        internal
        view
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "BrewlabsLibrary: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            IBrewlabsPair pair = IBrewlabsPair(pairFor(factory, path[i], path[i + 1]));
            amounts[i + 1] = pair.getAmountOut(amounts[i], path[i], discount);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path, uint256 discount)
        internal
        view
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "BrewlabsLibrary: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            IBrewlabsPair pair = IBrewlabsPair(pairFor(factory, path[i - 1], path[i]));
            amounts[i - 1] = pair.getAmountIn(amounts[i], path[i - 1], discount);
        }
    }
}

pragma solidity >=0.5.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "ds-math-div-by-zero");
        z = x / y;
    }
}