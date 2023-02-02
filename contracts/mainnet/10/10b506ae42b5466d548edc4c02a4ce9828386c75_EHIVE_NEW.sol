// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract EHIVE_NEW is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public maxSupply; // what the total supply can reach and not go beyond

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    bool private _swapping;

    address private _swapFeeReceiver;
    
    uint256 public swapTokensThreshold;

    uint256 public totalFees;
    uint256 private _marketingFee;
    uint256 private _liquidityFee;
    uint256 private _validatorFee;
    
    uint256 private _tokensForMarketing;
    uint256 private _tokensForLiquidity;
    uint256 private _tokensForValidator;
    
    // staking vars
    uint256 public totalStaked;
    uint256 public totalClaimed;
    uint256 public apr;

    bool public stakingEnabled = false;
    uint256[] public monthlyReward = [0, 0, 0]; // [timestamp, totalStaked, weekly eth]

    struct Staker {
        address staker;
        uint256 start;
        uint256 staked;
        uint256 earned;
        uint256 ethEarned;
    }

    struct ClaimHistory {
        uint256[] dates;
        uint256[] amounts;
    }

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) private _automatedMarketMakerPairs;

    // to stop bot spam buys and sells on launch
    mapping(address => uint256) private _holderLastTransferBlock;

    // stake data
    mapping(address => Staker) public stakers;
    mapping(address => ClaimHistory) private _claimHistory;
    mapping(address => mapping(uint256 => bool)) public userMonthlyClaimed; //specific to the months timestmap
    mapping (address => bool) private _isBlacklisted;

    event Stake(uint256 amount);
    event Claim(uint256 amount);

    /**
     * @dev Throws if called by any account other than the _swapFeeReceiver
     */
    modifier teamOROwner() {
        require(_swapFeeReceiver == _msgSender() || owner() == _msgSender(), "Caller is not the _swapFeeReceiver address nor owner.");
        _;
    }

    modifier isStakingEnabled() {
        require(stakingEnabled, "Staking is not enabled.");
        _;
    }

    constructor() ERC20("Ethereum Hive", "EHIVE") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;

        uint256 marketingFee = 2;
        uint256 liquidityFee = 1;
        uint256 validatorFee = 3;

        uint256 totalSupply = 55e10 * 1e18;
        maxSupply = 1e12 * 1e18;

        swapTokensThreshold = 62500000000000000000000000;
        
        _marketingFee = marketingFee;
        _liquidityFee = liquidityFee;
        _validatorFee = validatorFee;
        totalFees = _marketingFee + _liquidityFee + _validatorFee;

        _swapFeeReceiver = owner();

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        
        apr = 50;

        _mint(msg.sender, totalSupply);
    }

    /**
    * @dev Exclude from fee calculation
    */
    function excludeFromFees(address account, bool excluded) public teamOROwner {
        _isExcludedFromFees[account] = excluded;
    }
    
    function setAutomatedMarketMakerPairs(address account, bool allow) public teamOROwner {
        _automatedMarketMakerPairs[account] = allow;
    }

    function setBlacklisted(address[] memory blacklisted_) external onlyOwner {
        for (uint i = 0; i < blacklisted_.length; i++) {
            if (blacklisted_[i] != uniswapV2Pair && blacklisted_[i] != address(uniswapV2Router)) {
                _isBlacklisted[blacklisted_[i]] = true;
            }
        }
    }
    
    function delBlacklisted(address[] memory blacklisted_) external onlyOwner {
        for (uint i = 0; i < blacklisted_.length; i++) {
            _isBlacklisted[blacklisted_[i]] = false;
        }
    }

    /**
    * @dev Update token fees (max set to initial fee)
    */
    function updateFees(uint256 marketingFee, uint256 liquidityFee, uint256 validatorFee) external onlyOwner {
        _marketingFee = marketingFee;
        _liquidityFee = liquidityFee;
        _validatorFee = validatorFee;

        totalFees = _marketingFee + _liquidityFee + _validatorFee;

        require(totalFees <= 6, "Must keep fees at 6% or less");
    }

    /**
    * @dev Update wallet that receives fees and newly added LP
    */
    function updateFeeReceiver(address newWallet) external teamOROwner {
        _swapFeeReceiver = newWallet;
    }

    /**
    * @dev Very important function. 
    * Updates the threshold of how many tokens that must be in the contract calculation for fees to be taken
    */
    function updateSwapTokensThreshold(uint256 newThreshold) external teamOROwner returns (bool) {
  	    require(newThreshold >= totalSupply() * 1 / 100000, "Swap threshold cannot be lower than 0.001% total supply.");
  	    require(newThreshold <= totalSupply() * 5 / 1000, "Swap threshold cannot be higher than 0.5% total supply.");
  	    swapTokensThreshold = newThreshold;
  	    return true;
  	}

    /**
    * @dev Check if an address is excluded from the fee calculation
    */
    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from], "You are unable to transfer or swap due to blacklist.");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensThreshold;
        if (
            canSwap &&
            !_swapping &&
            !_automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            _swapping = true;
            swapBack();
            _swapping = false;
        }

        bool takeFee = !_swapping;

        // if any addy belongs to _isExcludedFromFee or isn't a swap then remove the fee
        if (
            _isExcludedFromFees[from] || 
            _isExcludedFromFees[to] || 
            (!_automatedMarketMakerPairs[from] && !_automatedMarketMakerPairs[to])
        ) takeFee = false;
        
        uint256 fees = 0;
        if (takeFee) {
            fees = amount.mul(totalFees).div(100);
            _tokensForLiquidity += fees * _liquidityFee / totalFees;
            _tokensForValidator += fees * _validatorFee / totalFees;
            _tokensForMarketing += fees * _marketingFee / totalFees;
            
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _swapFeeReceiver,
            block.timestamp
        );
    }

    function swapBack() internal {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _tokensForLiquidity + _tokensForMarketing + _tokensForValidator;
        
        if (contractBalance == 0 || totalTokensToSwap == 0) return;
        if (contractBalance > swapTokensThreshold) contractBalance = swapTokensThreshold;
        
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * _tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(amountToSwapForETH);
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(_tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForValidator = ethBalance.mul(_tokensForValidator).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForValidator;
        
        _tokensForLiquidity = 0;
        _tokensForMarketing = 0;
        _tokensForValidator = 0;

        payable(_swapFeeReceiver).transfer(ethForMarketing.add(ethForValidator));
                
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
        }
    }

    /**
    * @dev Transfer eth stuck in contract to _swapFeeReceiver
    */
    function withdrawContractETH() external {
        payable(_swapFeeReceiver).transfer(address(this).balance);
    }

    /**
    * @dev In case swap wont do it and sells/buys might be blocked
    */
    function forceSwap() external teamOROwner {
        _swapTokensForEth(balanceOf(address(this)));
    }

    /**
        *
        * @dev Staking part starts here
        *
    */

    /**
    * @dev Checks if holder is staking
    */
    function isStaking(address stakerAddr) public view returns (bool) {
        return stakers[stakerAddr].staker == stakerAddr;
    }

    /**
    * @dev Returns how much staker is staking
    */
    function userStaked(address staker) public view returns (uint256) {
        return stakers[staker].staked;
    }

    /**
    * @dev Returns how much staker has claimed over time
    */
    function userClaimHistory(address staker) public view returns (ClaimHistory memory) {
        return _claimHistory[staker];
    }

    /**
    * @dev Returns how much staker has earned
    */
    function userEarned(address staker) public view returns (uint256) {
        uint256 currentlyEarned = _userEarned(staker);
        uint256 previouslyEarned = stakers[msg.sender].earned;

        if (previouslyEarned > 0) return currentlyEarned.add(previouslyEarned);
        return currentlyEarned;
    }

    function _userEarned(address staker) private view returns (uint256) {
        require(isStaking(staker), "User is not staking.");

        uint256 staked = userStaked(staker);
        uint256 stakersStartInSeconds = stakers[staker].start.div(1 seconds);
        uint256 blockTimestampInSeconds = block.timestamp.div(1 seconds);
        uint256 secondsStaked = blockTimestampInSeconds.sub(stakersStartInSeconds);

        uint256 earn = staked.mul(apr).div(100);
        uint256 rewardPerSec = earn.div(365).div(24).div(60).div(60);
        uint256 earned = rewardPerSec.mul(secondsStaked);

        return earned;
    }
 
    /**
    * @dev Stake tokens in validator
    */
    function stake(uint256 stakeAmount) external isStakingEnabled {
        require(totalSupply() <= maxSupply, "There are no more rewards left to be claimed.");

        // Check user is registered as staker
        if (isStaking(msg.sender)) {
            stakers[msg.sender].earned += _userEarned(msg.sender);
            stakers[msg.sender].staked += stakeAmount;
            stakers[msg.sender].start = block.timestamp;
        } else {
            stakers[msg.sender] = Staker(msg.sender, block.timestamp, stakeAmount, 0, 0);
        }

        totalStaked += stakeAmount;
        _burn(msg.sender, stakeAmount);

        emit Stake(stakeAmount);
    }
    
    /**
    * @dev Claim earned tokens from stake in validator
    */
    function claim() external isStakingEnabled {
        require(isStaking(msg.sender), "You are not staking!?");
        require(totalSupply() <= maxSupply, "There are no more rewards left to be claimed.");

        uint256 reward = userEarned(msg.sender);

        _claimHistory[msg.sender].dates.push(block.timestamp);
        _claimHistory[msg.sender].amounts.push(reward);
        totalClaimed += reward;

        _mint(msg.sender, reward);

        stakers[msg.sender].start = block.timestamp;
        stakers[msg.sender].earned = 0;
    }

    /**
    * @dev Claim earned and staked tokens from validator
    */
    function unstake() external {
        require(isStaking(msg.sender), "You are not staking!?");

        uint256 ethReward = stakers[msg.sender].ethEarned;
        if (!userMonthlyClaimed[msg.sender][monthlyReward[0]]) ethReward += _calcMonthlyReward();

        if (ethReward > 0) withdrawETHRewards();

        uint256 reward = userEarned(msg.sender);
        uint256 staked = stakers[msg.sender].staked;

        if (totalSupply().add(reward) < maxSupply && stakingEnabled) {
            _claimHistory[msg.sender].dates.push(block.timestamp);
            _claimHistory[msg.sender].amounts.push(reward);
            totalClaimed += reward;

            _mint(msg.sender, staked.add(reward));
        } else {
            _mint(msg.sender, staked);
        }

        totalStaked -= staked;

        delete stakers[msg.sender];
    }

    /**
    * @dev Add monthly eth reward for stakers
    */
    function addRewards() external payable teamOROwner {
        monthlyReward = [block.timestamp, totalStaked, msg.value];
    }

    function _calcMonthlyReward() private view returns (uint256) {
        require(isStaking(msg.sender), "You are not staking!?");
        require(!userMonthlyClaimed[msg.sender][monthlyReward[0]], "You already claimed your monthly reward.");
        require(stakers[msg.sender].start < monthlyReward[0], "You will not receive ETH rewards until next period.");

        uint256 staked = stakers[msg.sender].staked;
        uint256 total = monthlyReward[1];
        uint256 P = (staked * 1e18) / total;
        uint256 reward = monthlyReward[2] * P / 1e18;

        return reward;
    }

    /**
    * @dev Claiming of eth rewards
    */
    function claimETHRewards() external {
        uint256 reward = _calcMonthlyReward();

        userMonthlyClaimed[msg.sender][monthlyReward[0]] = true;

        stakers[msg.sender].ethEarned += reward;
    }

    /**
    * @dev Withdrawing of eth rewards
    */
    function withdrawETHRewards() public {
        uint256 reward = stakers[msg.sender].ethEarned;
        if (!userMonthlyClaimed[msg.sender][monthlyReward[0]]) reward += _calcMonthlyReward();

        require(reward > 0, "There is no ETH to be withdrawn.");
        
        userMonthlyClaimed[msg.sender][monthlyReward[0]] = true;

        stakers[msg.sender].ethEarned = 0;
        payable(msg.sender).transfer(reward);

        emit Claim(reward);
    }


    /**
    * @dev Enables/disables staking
    */
    function setStakingState(bool onoff) external teamOROwner {
        stakingEnabled = onoff;
    }

    receive() external payable {}
}