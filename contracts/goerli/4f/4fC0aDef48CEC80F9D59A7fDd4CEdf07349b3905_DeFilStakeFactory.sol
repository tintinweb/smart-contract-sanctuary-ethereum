// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DeFilStake.sol";

contract DeFilStakeFactory is Ownable {
    event Created(address indexed deFilStake, address indexed creator);

    mapping (string => address) private _defilStakes;

    function create(
        string memory filmId,
        uint256 target_,
        uint256 fundingStartsAt_,
        address[] memory stakingTokens_,
        address maintainer_,
        address filmAdmin_,
        address rewardToken_) public onlyOwner returns (address) {
        DeFilStake defilStake = new DeFilStake(
            target_,
            fundingStartsAt_,
            stakingTokens_,
            maintainer_,
            filmAdmin_,
            rewardToken_
        );

        _defilStakes[filmId] = address(defilStake);

        emit Created(address(defilStake), msg.sender);

        return address(defilStake);
    }

    function getDeFilStakeAddress(string memory filmId) public view returns (address) {
        return _defilStakes[filmId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./DeFilStakingTokens.sol";
import "./reward/DeFilRewardToken.sol";
import "./oracle/Lido.sol";

contract DeFilStake is DeFilStakingTokens, DeFilRewardToken, Lido {
    // target amount of APY in USDC
    uint256 public target;

    // funding period in seconds
    uint256 public constant fundingPeriod = 30 * 24 * 60 * 60;
    // timestamp funding starts
    uint256 public fundingStartsAt;
    // timestamp funding ends
    uint256 public fundingEndsAt;

    // Maintainer account to receive 2% of APY every 2 weeks
    address public maintainer;
    // Admin account to receive 98% of APY every 2 weeks
    address public filmAdmin;

    enum State {
        PENDING,
        FUNDING,
        STAKING,
        REFUNDING,
        SUCCEEDED
    }
    State public fundState;

    // maps account to token address to amount
    mapping (address => mapping(address => uint256)) deposits;
    // maps token address to total deposits amount
    mapping (address => uint256) public totalDeposits;
    // maps token address to its amount exchanged to stETH
    mapping (address => uint256) exchanged;
    // total stETH tokens staked in LIDO
    uint256 stakedToLido;
    // total stETH as APY received
    uint256 apyReceived;
    // stETH tokens as APY distributed to accounts (Maintainer and Admin)
    mapping (address => uint256) apyDistributed;
    uint256 apyDistributedToMaintainers;
    uint256 apyDistributedToAdmins;

    event Depositted(address indexed account_, address indexed tokenAddress, uint256 amount_);
    event Exchanged(address indexed token_, uint256 sentAmount_, uint256 receivedAmount_);
    event StakedToLido(uint256 EthAmount, uint256 StEthAmount);
    event APYReceived(uint256 amount_);
    event APYTransferred(address indexed account_, uint256 amount_);
    event Rewarded(address indexed account, uint256 amount_);
    event Withdrawn(address indexed account, uint256 amount_);

    constructor(
        uint256 target_,
        uint256 fundingStartsAt_,
        address[] memory stakingTokens_,
        address maintainer_,
        address filmAdmin_,
        address rewardToken_
    ) 
        DeFilStakingTokens(stakingTokens_)
        DeFilRewardToken(rewardToken_)
    {
        target = target_;

        fundingStartsAt = fundingStartsAt_;
        fundingEndsAt = fundingStartsAt + fundingPeriod;

        maintainer = maintainer_;
        filmAdmin = filmAdmin_;

        rewardToken = rewardToken_;
    }
    
    modifier onlyFundingPeriod() {
        // verify if current timestamp is within funding period
        require(_isState(State.FUNDING), "Invalid Funding Period");
        _;
    }
    modifier onlyRefundingPeriod() {
        // verify if condition for refunding has met
        require(_isState(State.REFUNDING));
        _;
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           

    function deposit() public payable onlyFundingPeriod {
        // verify ETH is supported
        isTokenStakeable(address(0x0));
        // increase ETH deposits of account=msg.sender by amount=msg.value
        deposits[address(0x0)][msg.sender] += msg.value;
        // increase ETH total deposits by msg.value
        totalDeposits[address(0x0)] += msg.value;
        // emit Depositted event
        emit Depositted(msg.sender, address(0x0), msg.value);
    }

    function depositCustomToken(uint256 amount_, address token_) public onlyFundingPeriod {
        // verify token_ is supported
        isTokenStakeable(token_);
        // transfer amount_ of token_ to DeFil account
        _safeTransfer(token_, address(this), amount_);
        // increase token_ deposits of account=msg.sender by amount_
        deposits[token_][msg.sender] += amount_;
        // increase token_ total deposits by amount_
        totalDeposits[token_] += amount_;
        // emit Depositted event
        emit Depositted(msg.sender, token_, amount_);
    }

    function depositsOf(address account_, address token_) public view returns (uint256) {
        return deposits[token_][account_];
    }

    function stakeToLido() public {
        // verify if funds have reached target
        if (_apyReachedTarget()) {
            // stake stETH values to LIDO
            uint256 _stakeable = _getLidoStakeableAmount(address(0x0));
            uint256 StETH = submitToLido(_stakeable);
            // emit StakedToLido event
            emit StakedToLido(_stakeable, StETH);
        }
    }

    function distributeAPY() public {
        // verify last time rewarded must be within every 2 weeks
        // transfer 2% of LIDO intersts to maintainer
        // transfer 98% of LIDO intersts to film admin
        // emit APYTransferred event
    }

    function claimAPY() public {
        // verify last time rewarded must be within every 2 weeks
        // if maintainer => transfer 2% APY
        // if admin =? transfer 98% APY
        // emit APYTransferred event
    }

    function claimRewards() public onlyRefundingPeriod {
        // calculate desired rewardds of msg.sender
        // transfer reward token
        // emit Rewarded event
    }

    function withdraw() public onlyRefundingPeriod {
        // transfer principal assets to msg.sender in stETH
        // update user's balance
        // emit Withdrawn event
    }

    function _fundsReachedTarget() private returns(bool) {
        // use chainlink API Integrator to get ETH/USDC rate
        // calculate deposits in USDC
        // compare USDC converted deposits with target * 0.7
    }

    function _apyReachedTarget() private returns(bool) {
        // calculate total APY received
        // compare total APY received with target APY
    }

    function _convertDepositsToSTETH() private {
        // use curve.fi to exchange as much values of deposits to stETH
        // emit Exchanged event
    }


    function _updateFundState() private {
        // if now < start => state = NOT_STARTED
        if (block.timestamp < fundingStartsAt) {
            fundState = State.PENDING;
        }
        // if now is between starts-ends funding => state = FUNDING
        else if (block.timestamp > fundingStartsAt && block.timestamp < fundingEndsAt) {
            fundState = State.FUNDING;
        }
        // if funding period has ended
        else if (block.timestamp > fundingEndsAt) {
            // if APY > target => state = REFUNDING
            if (_apyReachedTarget()) {
                fundState = State.SUCCEEDED;
            }
            // if now > end funding && _isReachedTarget() => state = STAKING
            else if (_fundsReachedTarget()) {
                fundState = State.STAKING;
            }
            // if now > end funding && !_isReachedTarget() => state = REFUNDING
            else if (!_fundsReachedTarget()) {
                fundState = State.REFUNDING;
            }
        }
    }
    
    function _isState(State _state) private returns (bool) {
        _updateFundState();
        if (fundState == _state) 
            return true;
        return false;
    }
    
    function _getLidoStakeableAmount(address token_) private view returns (uint256 stakeable) {
        stakeable = totalDeposits[token_] - exchanged[token_];
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract DeFilStakingTokens {
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    // tokens supported
    mapping (address => bool) private _stakingTokens;

    constructor(address[] memory stakingTokens_) {
        for (uint8 i = 0; i < stakingTokens_.length; i++) {
            _addStakingToken(stakingTokens_[i]);
        }
    }

    function isTokenStakeable(address token_) public view returns (bool) {
        return _stakingTokens[token_];
    }

    function _addStakingToken(address token_) private {
        _stakingTokens[token_] = true;
    }

    function _safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract DeFilRewardToken {
    // address of Rewarding Token
    address public rewardToken;

    constructor(address rewardToken_) {
        rewardToken = rewardToken_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ILido.sol";

contract Lido {
    address lido = 0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F; // Goerli Testnet

    function submitToLido(uint256 value_) public returns (uint256 StETH) {
        StETH = ILido(lido).submit{ value: value_ }(address(0x0));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface ILido {
    function totalSupply() external view returns (uint256);
    function getTotalShares() external view returns (uint256);

    function stop() external;
    function resume() external;

    function pauseStaking() external;
    function resumeStaking() external;
    function setStakingLimit(uint256 _maxStakeLimit, uint256 _stakeLimitIncreasePerBlock) external;
    function removeStakingLimit() external;
    function isStakingPaused() external view returns (bool);
    function getCurrentStakeLimit() external view returns (uint256);
    function getStakeLimitFullInfo() external view returns (
        bool isStakingPaused,
        bool isStakingLimitSet,
        uint256 currentStakeLimit,
        uint256 maxStakeLimit,
        uint256 maxStakeLimitGrowthBlocks,
        uint256 prevStakeLimit,
        uint256 prevStakeBlockNumber
    );

    event Stopped();
    event Resumed();

    event StakingPaused();
    event StakingResumed();
    event StakingLimitSet(uint256 maxStakeLimit, uint256 stakeLimitIncreasePerBlock);
    event StakingLimitRemoved();
    function setProtocolContracts(
        address _oracle,
        address _treasury,
        address _insuranceFund
    ) external;

    event ProtocolContactsSet(address oracle, address treasury, address insuranceFund);

    function setFee(uint16 _feeBasisPoints) external;
    function setFeeDistribution(
        uint16 _treasuryFeeBasisPoints,
        uint16 _insuranceFeeBasisPoints,
        uint16 _operatorsFeeBasisPoints
    ) external;
    function getFee() external view returns (uint16 feeBasisPoints);
    function getFeeDistribution() external view returns (
        uint16 treasuryFeeBasisPoints,
        uint16 insuranceFeeBasisPoints,
        uint16 operatorsFeeBasisPoints
    );

    event FeeSet(uint16 feeBasisPoints);

    event FeeDistributionSet(uint16 treasuryFeeBasisPoints, uint16 insuranceFeeBasisPoints, uint16 operatorsFeeBasisPoints);

    function receiveELRewards() external payable;

    event ELRewardsReceived(uint256 amount);

    function setELRewardsWithdrawalLimit(uint16 _limitPoints) external;

    event ELRewardsWithdrawalLimitSet(uint256 limitPoints);

    function setWithdrawalCredentials(bytes32 _withdrawalCredentials) external;

    function getWithdrawalCredentials() external view returns (bytes memory);

    event WithdrawalCredentialsSet(bytes32 withdrawalCredentials);

    function setELRewardsVault(address _executionLayerRewardsVault) external;

    event ELRewardsVaultSet(address executionLayerRewardsVault);

    function handleOracleReport(uint256 _epoch, uint256 _eth2balance) external;

    function submit(address _referral) external payable returns (uint256 StETH);

    event Submitted(address indexed sender, uint256 amount, address referral);

    event Unbuffered(uint256 amount);

    event Withdrawal(address indexed sender, uint256 tokenAmount, uint256 sentFromBuffer,
                     bytes32 indexed pubkeyHash, uint256 etherAmount);


    function getTotalPooledEther() external view returns (uint256);

    function getBufferedEther() external view returns (uint256);

    function getBeaconStat() external view returns (uint256 depositedValidators, uint256 beaconValidators, uint256 beaconBalance);
}