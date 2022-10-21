// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Math.sol";

contract MCNC is ERC20, Ownable {

    using Math for uint256;

    address public walletOrigin = 0x046C458Bf5dFBC6B191c59ecF45c07473Fc2e6bc;
    address public walletMarketProtection = 0x364F1E2781D9c7901fa5c9F3308F474c52631c8b;
    address public walletFoundingPartners = 0x8ffe85249F1aDd94A0D94306A0C66B6738348dA9;
    address public walletBlockedFoundingPartners = 0x770D3bef65F8Ae51869F58Bc1461f3Fe3c1150c1;
    address public walletSocialPartners = 0xa199096E1dE5fCe2A0ffC4622cFf225766D19BF3;
    address public walletProgrammersAndPartners = 0x7D63F43442517e07c9F06Bbe5E7Edc14e3E80704;
    address public walletPrivateInvestors = 0x97beAace7f455bc1bbe7b1942A40eCa2deF06dF9;
    address public walletStakingMCNC = 0xAA31Ee7988626392aC629662c0E0c65633b568fE;
    address public walletUnlock = 0x8742758d47Adce4A8584aeA708102be6b492177E;

    address public operatorAddress;

    uint256 public MAX_BURN_AMOUNT = 0 * (10 ** decimals());
    uint256 public BURN_AMOUNT = 0 * (10 ** decimals());
    uint256 public lastBurnDay = block.timestamp;
    uint256 public burnedAmount = 0;

    uint256 private _maxStakingAmount = 20_000_000 * (10 ** decimals());
    uint256 private _maxStakingAmountPerAccount = 10_000_000 * (10 ** decimals());
    uint256 private _totalStakingAmount = 0;
    uint256 private _stakingPeriod = block.timestamp + 29 days;
    uint256 private _stakingFirstPeriod = block.timestamp + 29 days;
    uint256 private _stakingSecondPeriod = block.timestamp + 29 days;

    uint256 private _stakingFirstPeriodReward = 7;
    uint256 private _stakingSecondPeriodReward = 7;
    
    uint256 public deployedTime = block.timestamp;

    uint256 public lastUnlockTime;
    uint256 public unlockAmountPerMonth = 100_000 * (10 ** decimals());
    
    // Mapping owner address to staked token count
    mapping (address => uint) _stakedBalances;
    
    // Mapping from owner to last reward time
    mapping (address => uint) _rewardedLastTime;

    event StakingSucceed(address indexed account, uint256 totalStakedAmount);
    event WithdrawSucceed(address indexed account, uint256 remainedStakedAmount);

    /**
    * @dev modifier which requires that account must be operator
    */
    modifier onlyOperator() {
        require(_msgSender() == operatorAddress, "operator: wut?");
        _;
    }

    /**
    * @dev modifier which requires that walletAddress is not blocked address(walletMarketProtection),
    * until blocking period.
    */
    modifier onlyUnblock(address walletAddress) {
        require((walletAddress != walletMarketProtection && walletAddress != walletBlockedFoundingPartners)
                    || block.timestamp > deployedTime + 365 days, "This wallet address is blocked for 365 years." );
        _;
    }

    /**
    * @dev Constructor: mint pre-defined amount of tokens to special wallets.
     */
    constructor() ERC20("Multi Network Connect", "MCNC") {
        operatorAddress = _msgSender();
        //uint totalSupply = 100_000_000 * (10 ** decimals());

        // 30% of total supply to walletOrigin
        _mint(walletOrigin, 30_000_000 * (10 ** decimals()));

        // 1% of total supply to walletMarketProtection
        _mint(walletMarketProtection, 1_000_000 * (10 ** decimals()));

        // 9% of total supply to walletFoundingPartners
        _mint(walletFoundingPartners, 9_000_000 * (10 ** decimals()));

        // 1% of total supply to walletBlockedFoundingPartners
        _mint(walletBlockedFoundingPartners, 10_000_000 * (10 ** decimals()));

        // 30% of total supply to walletSocialPartners
        _mint(walletSocialPartners, 30_000_000 * (10 ** decimals()));

        // 9% of total supply to walletProgrammersAndPartners
        _mint(walletProgrammersAndPartners, 9_000_000 * (10 ** decimals()));

        // 20% of total supply to walletPrivateInvestors
        _mint(walletPrivateInvestors, 20_000_000 * (10 ** decimals()));
    }

    /**
    * @dev set operator address
    * callable by owner
    */
    function setOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Cannot be zero address");
        operatorAddress = _operator;
    }

    /**
     * @dev Destroys `amount` tokens from `walletOrigin`, reducing the
     * total supply.
     *
     * Requirements:
     *
     * - total burning amount can not exceed `_maxBurnAmount`
     * - burning moment have to be 90 days later from `lastBurnDay`
     */
    function burn() external onlyOperator {
        
        require(burnedAmount + BURN_AMOUNT <= MAX_BURN_AMOUNT, "Burning too much.");
        require(lastBurnDay + 90 days <= block.timestamp, "It's not time to burn. 90 days aren't passed since last burn");
        lastBurnDay = block.timestamp;

        _burn(walletOrigin, BURN_AMOUNT);
        burnedAmount += BURN_AMOUNT;
    }

    /**
     * @dev Stake `amount` tokens from `msg.sender` to `walletOrigin`, calculate reward upto now.
     *
     * Emits a {StakingSucceed} event with `account` and total staked balance of `account`
     *
     * Requirements:
     *
     * - `account` must have at least `amount` tokens
     * - staking moment have to be in staking period
     * - staked balance of each account can not exceed `_maxStakingAmountPerAccount`
     * - total staking amount can not exceed `_totalStakingAmount`
     */
    function stake(uint amount) external {
        
        address account = _msgSender();

        require(balanceOf(account) >= amount, "insufficient balance for staking.");
        require(block.timestamp <= _stakingPeriod, "The time is over staking period.");

        _updateReward(account);

        _stakedBalances[account] += amount;
        require(_stakedBalances[account] <= _maxStakingAmountPerAccount, "This account overflows staking amount");
        
        _totalStakingAmount += amount;
        require(_totalStakingAmount <= _maxStakingAmount, "Total staking amount overflows its limit.");
        
        _transfer(account, walletStakingMCNC, amount);
        
        emit StakingSucceed(account, _stakedBalances[account]);
    }

    /**
     * @dev Returns the amount of tokens owned by `account`. Something different from ERC20 is
     * adding reward which is not yet appended to account wallet.
     */
    function balanceOf(address account) public view override returns (uint) {
        return ERC20.balanceOf(account) + getAvailableReward(account);
    }

    /**
     * @dev Get account's reward which is yielded after last rewarded time.
     *
     * @notice if getting moment is after stakingPeriod, the reward must be 0.
     * 
     * First `if` statement is in case of `lastTime` is before firstPeriod.
     *         `lastTime`  block.timestamp(if1)                   block.timestamp(if2)
     * ||----------|---------------|------------||------------------------|-----------||
     *              firstPeriod                             secondPeriod
     *
     * Second `if` statement is in case of block.timestamp is in secondPeriod.
     */
    function getAvailableReward(address account) public view returns (uint) {

        if (_rewardedLastTime[account] > _stakingPeriod) return 0;
        
        uint reward = 0;
        if (_rewardedLastTime[account] <= _stakingFirstPeriod) {
            uint rewardDays = _stakingFirstPeriod.min(block.timestamp) - _rewardedLastTime[account];
            rewardDays /= 1 days;
            reward = rewardDays * _stakedBalances[account] * _stakingFirstPeriodReward / 1000000;
        }

        if (block.timestamp > _rewardedLastTime[account]) {
            uint rewardDays = _stakingPeriod.min(block.timestamp) - _rewardedLastTime[account];
            rewardDays /= 1 days;
            reward += 29 * _stakedBalances[account] * _stakingSecondPeriodReward / 1000000;
        }
        
        return reward;
    }

    /**
     * @dev Withdraw `amount` tokens from stakingPool(`walletOrigin`) to `msg.sender` address, calculate reward upto now.
     *
     * Emits a {WithdrawSucceed} event with `account` and total staked balance of `account`
     *
     * Requirements:
     *
     * - staked balance of `msg.sender` must be at least `amount`.
     */
    function withdraw(uint amount) external {
        address account = _msgSender();
        require (_stakedBalances[account] >= amount, "Can't withdraw more than staked balance");

        _updateReward(account);

        _stakedBalances[account] -= amount;
        _totalStakingAmount -= amount;
        _transfer(walletStakingMCNC, account, amount);

        emit WithdrawSucceed(account, _stakedBalances[account]);
    } 

    /**
     * @dev Hook that is called before any transfer of tokens. 
     * Here, update from's balance by adding not-yet-appended reward.
     *
     * Requirements:
     *
     * - blocked wallet (walletMarketProtection) can't be tranferred or transfer any balance.
    function _beforeTokenTransfer(address from, address to, uint256) internal override onlyUnblock(from) {
        if (from != address(0) && from != walletOrigin) {
            _updateReward(from);
        }
    }*/

    /**
     * @dev Get account's available reward which is yielded from last rewarded moment.
     * And append available reward to account's balance.
     */
    function _updateReward(address account) public {
        uint availableReward = getAvailableReward(account);
        _rewardedLastTime[account] = block.timestamp;
        _transfer(walletOrigin, account, availableReward);
    }

    /**
     * @dev Unlock `walletMarketProtection`, which means that transfer tokens from `walletMarketProtection`
     * to `walletUnlock`, so that it can be traded across users.ok
     */
    function unlockProtection() public onlyOperator {
        require (block.timestamp > deployedTime + 5 * 31 days, "Unlock is not allowed now");
        require (block.timestamp > lastUnlockTime + 31 days, "Unlock must be 31 days later from previous unlock");
        lastUnlockTime = block.timestamp;
        _transfer(walletMarketProtection, walletUnlock, unlockAmountPerMonth);
    }
}