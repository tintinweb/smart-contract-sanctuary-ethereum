// SPDX-License-Identifier: MIT
//                       ,ƒ   ,╗Γ                ╚╔,   \,
//                      ██L  ▓▐▌                  ▓▌╬Γ  ▀█
//                     ██▌▒, ╚▓▀▓                ╬█ß▌ ,@╟██
//                     ▐███/▒w▓╦█▓@g╖        ╓g╥▓█╦▓╔╫\███▌
//                      '█████▄ █████▓▄@w╤¢▄╬███▓█,╓█████'
//                         █████████▀▀▄▓██▓▄▀▀█████████`
//                           ╙████████▄▓▄▄▓▄████████▀
//                             ▄████▓▓██▀▀██▓▓████▄
//                            ███╣█████▌╬▓▐█████Ñ▀██
//                               ╘▓▀██]▓▓▓▓╝████┘
//                                 ╚╣████████▌╝
//                                    ▀████▀`

// ╫╬╬╬╬╬╬@╗    ,╬╬╬╖    ╫╬╬╬╬╬╬@╗ ╙╬╬╖   @╬╝  ╬╬     ╬╬  ,@╬╬╣╬╬@,  ╬╬     ╬╬U ╟╬╬
// ║╢╣,,,╓╢╬   ,╣╢ ╣╢┐   ║╢╣,,,╓╢╬   ╨╢@╓╬╣╜   ╢╢     ╢╢  ╟╢╢╖╖,```  ╢╢U,,,,╢╢U ╟╢╢
// ║╢╣╜╜╜╨║@  ,╣╢Ç,]╢╢,  ║╢╣╜╜╜╨╢@    `╢╢╣     ╢╢    ]╢╢    ╙╙╩╩╣╢@  ╢╢╨╨╨╨╨╢╢U ╟╢╢
// ║╢╣╦╦╦@╢╢  ╣╢╜╜╜╜╨╢╢  ║╢╣╦╦╦@╢╢     ╢╢[     ╚╢╣╦╦@╬╢╝  ╚╢╬╦╗╦╬╢╝  ╢╢     ╢╢U ╟╢╢

//    ╢ ╓╢╜╙╢╖ ║╢ ╢╢, ╢L    ╢╢╖  @╜╙╚N   ╢╜╙╙╢ ╢[  ║[ ╢    ║[   ║╢╙╙╢╖ ╢   ╢ ]╢╖  ╢
// ╓  ║ ╢[  ,║ ║╢ ║ ╙╢╢L   ╢╣╓║╖ ,╙╙╢@   ║╜╙╙╢ ╢[  ║[ ║    ║[   ║║╝╢╢  ║   ║ ]║╙╢╢║
// `╙╙╜  `╙╙"  ╙' ╙   ╙   "╜   ╙ `╙╙╙    ╙╙╙╙`  ╙╙╙`  ╙╙╙╙ ╙╙╙╙'╙╙  ╙"  ╙╙╙   ╙  `╙

// Is an improved fork token with
// the function of a passive staking protocol
// on the Ethereum network Mainnet,
// which is launched for the purpose
// of Continue the BULLISH trend

// https://babyushi.com/
// https://twitter.com/babyushieth
// https://t.me/babyushiengchat
// https://t.me/babyushieng

// Rewards 8%
// BuyBack 3%
// AutoLp 1%
// Marketing 8%

pragma solidity ^0.8.14;

import './interfaces/RewardsTracker.sol';
import './interfaces/Ownable.sol';
import './interfaces/IDex.sol';
import './interfaces/IERC20.sol';
import './interfaces/ERC20.sol';

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }
}

contract ERC20BABYUSH1 is ERC20, Ownable, RewardsTracker {
    using Address for address payable;

    IRouter public router;
    address public pair;

    bool private swapping;
    bool public antiBotSystem;
    bool public swapEnabled = true;

    address public marketingWallet = 0xdE747aeF6E223601352aD01A9115D34b7a333c04;
    address public buybackWallet = 0x5e901ca79A5CDe2804772910Fa3eC7eAC651F147;

    uint256 public swapTokensAtAmount = 10_000_000 * 10**18;
    uint256 public maxWalletAmount = 105_000_000 * 10**18;
    uint256 public gasLimit = 300_000;
    uint256 public goldenHourStart;

    struct Taxes {
        uint64 rewards;
        uint64 marketing;
        uint64 buyback;
        uint64 lp;
    }

    Taxes public buyTaxes = Taxes(8, 8, 3, 1);
    Taxes public sellTaxes = Taxes(8, 8, 3, 1);

    uint256 public totalBuyTax = 20;
    uint256 public totalSellTax = 20;

    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public antiBot;
    mapping(address => bool) public isPair;

    ///////////////
    //   Events  //
    ///////////////

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor(address _router, address _rewardToken) ERC20('BUSHI', 'BUSHI') RewardsTracker(_router, _rewardToken) {
        router = IRouter(_router);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());

        isPair[pair] = true;

        minBalanceForRewards = 210_000 * 10**18;
        claimDelay = 1 hours;

        // exclude from receiving dividends
        excludedFromDividends[address(this)] = true;
        excludedFromDividends[owner()] = true;
        excludedFromDividends[address(0xdead)] = true;
        excludedFromDividends[address(_router)] = true;
        excludedFromDividends[address(pair)] = true;

        // exclude from paying fees or having max transaction amount
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[buybackWallet] = true;

        antiBotSystem = true;
        antiBot[address(this)] = true;
        antiBot[owner()] = true;
        antiBot[marketingWallet] = true;
        antiBot[buybackWallet] = true;

        // _mint is an internal function in ERC20.sol that is only called here,
        // and CANNOT be called ever again
        _mint(owner(), 21e9 * (10**18));
    }

    receive() external payable {}

    /// @notice Manual claim the dividends
    function claim() external {
        super._processAccount(payable(msg.sender));
    }

    function rescueERC20(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function rescueETH() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        payable(owner()).sendValue(ETHbalance);
    }

    function updateRouter(address newRouter) external onlyOwner {
        router = IRouter(newRouter);
    }

    /////////////////////////////////
    // Exclude / Include functions //
    /////////////////////////////////

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    ///////////////////////
    //  Setter Functions //
    ///////////////////////

    function setRewardToken(address newToken) external onlyOwner {
        super._setRewardToken(newToken);
    }

    function startGoldenHour() external onlyOwner {
        goldenHourStart = block.timestamp;
    }

    function setMarketingWallet(address newWallet) external onlyOwner {
        marketingWallet = newWallet;
    }

    function setBuybackWallet(address newWallet) external onlyOwner {
        buybackWallet = newWallet;
    }

    function setClaimDelay(uint256 amountInSeconds) external onlyOwner {
        claimDelay = amountInSeconds;
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount * 10**18;
    }

    function setBuyTaxes(
        uint64 _rewards,
        uint64 _marketing,
        uint64 _buyback,
        uint64 _lp
    ) external onlyOwner {
        buyTaxes = Taxes(_rewards, _marketing, _buyback, _lp);
        totalBuyTax = _rewards + _marketing + _buyback + _lp;
    }

    function setSellTaxes(
        uint64 _rewards,
        uint64 _marketing,
        uint64 _buyback,
        uint64 _lp
    ) external onlyOwner {
        sellTaxes = Taxes(_rewards, _marketing, _buyback, _lp);
        totalSellTax = _rewards + _marketing + _buyback + _lp;
    }

    function setMaxWallet(uint256 maxWalletPercentage) external onlyOwner {
        maxWalletAmount = (maxWalletPercentage * totalSupply()) / 1000;
    }

    function setGasLimit(uint256 newGasLimit) external onlyOwner {
        gasLimit = newGasLimit;
        //QWxsIHJpZ2h0cyBiZWxvbmcgdG8gQkFZVVNISS4gQ29weWluZyBhIGNvbnRyYWN0IGlzIGEgdmlvbGF0aW9uIGFuZCBzdWdnZXN0cyB0aGF0IHdob2V2ZXIgZGlkIGl0IGhhcyBzbW9vdGhpZXMgaW5zdGVhZCBvZiBicmFpbnMu
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function setMinBalanceForRewards(uint256 minBalance) external onlyOwner {
        minBalanceForRewards = minBalance * 10**18;
    }

    function setAntiBotStatus(bool value) external onlyOwner {
        _setAntiBotStatus(value);
    }

    function _setAntiBotStatus(bool value) internal {
        antiBotSystem = value;
    }

    function addAntiBot(address _address) external onlyOwner {
        _addAntiBot(_address);
    }

    function addMultipleAntiBot(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _addAntiBot(_addresses[i]);
        }
    }

    function _addAntiBot(address _address) internal {
        antiBot[_address] = true;
    }

    function removeMultipleAntiBot(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _removeAntiBot(_addresses[i]);
        }
    }

    function _removeAntiBot(address _address) internal {
        antiBot[_address] = false;
    }

    /// @dev Set new pairs created due to listing in new DEX
    function setPair(address newPair, bool value) external onlyOwner {
        _setPair(newPair, value);
    }

    function _setPair(address newPair, bool value) private {
        isPair[newPair] = value;

        if (value) {
            excludedFromDividends[newPair] = true;
        }
    }

    ////////////////////////
    // Transfer Functions //
    ////////////////////////

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');
        require(amount > 0, 'Transfer amount must be greater than zero');
        if (antiBotSystem) {
            require(antiBot[tx.origin], 'Address is bot');
        }

        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping) {
            if (!isPair[to]) {
                require(balanceOf(to) + amount <= maxWalletAmount, 'You are exceeding maxWallet');
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            swapEnabled &&
            !isPair[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to] &&
            totalSellTax > 0
        ) {
            swapping = true;
            swapAndLiquify(swapTokensAtAmount);
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (!isPair[to] && !isPair[from]) takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            if (isPair[to]) feeAmt = (amount * totalSellTax) / 100;
            else if (isPair[from]) {
                if (block.timestamp < goldenHourStart + 1 hours)
                    feeAmt = (amount * (buyTaxes.lp + buyTaxes.buyback)) / 100;
                else feeAmt = (amount * totalBuyTax) / 100;
            }

            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
        }
        super._transfer(from, to, amount);

        super.setBalance(from, balanceOf(from));
        super.setBalance(to, balanceOf(to));

        if (!swapping) {
            super.autoDistribute(gasLimit);
        }
    }

    function swapAndLiquify(uint256 tokens) private {
        // Split the contract balance into halves
        uint256 denominator = totalSellTax * 2;
        uint256 tokensToAddLiquidityWith = (tokens * sellTaxes.lp) / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance = deltaBalance / (denominator - sellTaxes.lp);
        uint256 bnbToAddLiquidityWith = unitBalance * sellTaxes.lp;

        if (bnbToAddLiquidityWith > 0) {
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        }

        // Send ETH to marketing
        uint256 marketingAmt = unitBalance * 2 * sellTaxes.marketing;
        if (marketingAmt > 0) {
            payable(marketingWallet).sendValue(marketingAmt);
        }

        // Send ETH to buyback
        uint256 buybackAmt = unitBalance * 2 * sellTaxes.buyback;
        if (buybackAmt > 0) {
            payable(buybackWallet).sendValue(buybackAmt);
        }

        // Send ETH to rewards
        uint256 dividends = unitBalance * 2 * sellTaxes.rewards;
        if (dividends > 0) super._distributeDividends(dividends);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path, // QWxsIHJpZ2h0cyBiZWxvbmcgdG8gQkFZVVNISS4gQ29weWluZyBhIGNvbnRyYWN0IGlzIGEgdmlvbGF0aW9uIGFuZCBzdWdnZXN0cyB0aGF0IHdob2V2ZXIgZGlkIGl0IGhhcyBzbW9vdGhpZXMgaW5zdGVhZCBvZiBicmFpbnMu
            address(this),
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IDex.sol";
import "./IERC20.sol";

/// @title RewardsTracker
/// @author FreezyEx (https://github.com/FreezyEx)
/// @dev A contract that allows anyone to pay and distribute ethers to users as shares.
/// @notice This contract is based on erc1726 by Roger-Wu (https://github.com/Roger-Wu/erc1726-dividend-paying-token)

contract RewardsTracker is Ownable {

    mapping(address => uint256) public userShares;
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    mapping(address => bool) public excludedFromDividends;
    mapping(address => uint256) public lastClaimTime;
    mapping(address => uint256) public elegibleUsersIndex;
    mapping(address => bool ) public isElegible;

    address[] elegibleUsers;

    IRouter public rewardRouter;
    address public rewardToken;

    uint256 constant internal magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;
    uint256 public totalDividends;
    uint256 public totalDividendsWithdrawn;
    uint256 public totalShares;
    uint256 public minBalanceForRewards;
    uint256 public claimDelay;
    uint256 public currentIndex;

    event ExcludeFromDividends(address indexed account, bool value);
    event Claim(address indexed account, uint256 amount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);

    constructor(address _router, address _rewardToken) {
      rewardRouter = IRouter(_router);
      rewardToken = _rewardToken;
    }

    function excludeFromDividends(address account, bool value) external onlyOwner {
        require(excludedFromDividends[account] != value);
        excludedFromDividends[account] = value;
        if(value == true){
          _setBalance(account, 0);
        }
        else{
          _setBalance(account, userShares[account]);
        }
        emit ExcludeFromDividends(account, value);

    }
    
    function _setRewardToken(address newToken) internal{
      rewardToken = newToken;
    }

    function getAccount(address account) public view returns (uint256 withdrawableUserDividends, uint256 totalUserDividends, uint256 lastUserClaimTime, uint256 withdrawnUserDividends) {
        withdrawableUserDividends = withdrawableDividendOf(account);
        totalUserDividends = accumulativeDividendOf(account);
        lastUserClaimTime = lastClaimTime[account];
        withdrawnUserDividends = withdrawnDividends[account]; 
    }

    function setBalance(address account, uint256 newBalance) internal {
        if(excludedFromDividends[account]) {
            return;
        }   
        _setBalance(account, newBalance);
    }

    function _setMinBalanceForRewards(uint256 newMinBalance) internal {
        minBalanceForRewards = newMinBalance;
    }

    function autoDistribute(uint256 gasAvailable) public {
      uint256 size = elegibleUsers.length;
      if(size == 0) return;

      uint256 gasSpent = 0;
      uint256 gasLeft = gasleft();
      uint256 lastIndex = currentIndex;
      uint256 iterations = 0;

      while(gasSpent < gasAvailable && iterations < size){
        if(lastIndex >= size){
          lastIndex = 0;
        }
        address account = elegibleUsers[lastIndex];
        if(lastClaimTime[account] + claimDelay < block.timestamp){
          _processAccount(account);
        }
        lastIndex++;
        iterations++;
        gasSpent += gasLeft - gasleft();
        gasLeft = gasleft();
      }

      currentIndex = lastIndex;

    }

    function _processAccount(address account) internal returns(bool){
        uint256 amount = _withdrawDividendOfUser(account);

          if(amount > 0) {
              lastClaimTime[account] = block.timestamp;
              emit Claim(account, amount);
              return true;
          }
          return false;
    }

    function distributeDividends() external payable {
      if (msg.value > 0) {
      _distributeDividends(msg.value);
      }
    }

    function _distributeDividends(uint256 amount) internal {
      require(totalShares > 0);
      magnifiedDividendPerShare = magnifiedDividendPerShare + (amount * magnitude / totalShares);
      totalDividends= totalDividends + amount;
    }
    
    function _withdrawDividendOfUser(address user) internal returns (uint256) {
      uint256 _withdrawableDividend = withdrawableDividendOf(user);
      if (_withdrawableDividend > 0) {
        withdrawnDividends[user] += _withdrawableDividend;
        totalDividendsWithdrawn += _withdrawableDividend;
        emit DividendWithdrawn(user, _withdrawableDividend);
        (bool success) = swapEthForCustomToken(user, _withdrawableDividend);
        if(!success) {
          (bool secondSuccess,) = payable(user).call{value: _withdrawableDividend, gas: 3000}("");
          if(!secondSuccess) {
            withdrawnDividends[user] -= _withdrawableDividend;
            totalDividendsWithdrawn -= _withdrawableDividend;
            return 0;
          }       
        }
        return _withdrawableDividend;
      }
      return 0;
    }

    function swapEthForCustomToken(address user, uint256 amt) internal returns (bool) {
      address[] memory path = new address[](2);
      path[0] = rewardRouter.WETH();
      path[1] = rewardToken;
      
      try rewardRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amt}(0, path, user, block.timestamp) {
        return true;
      } catch {
        return false;
      }
    }

    function dividendOf(address _owner) public view returns(uint256) {
      return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view returns(uint256) {
      return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
    }

    function withdrawnDividendOf(address _owner) public view returns(uint256) {
      return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view returns(uint256) {
      return uint256(int256(magnifiedDividendPerShare * userShares[_owner]) + magnifiedDividendCorrections[_owner]) / magnitude;
    }

    function addShares(address account, uint256 value) internal {
      userShares[account] += value;
      totalShares += value;

      magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account] - int256(magnifiedDividendPerShare * value);
    }

    function removeShares(address account, uint256 value) internal {
      userShares[account] -= value;
      totalShares -= value;

      magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account] + int256(magnifiedDividendPerShare * value);
    }

    function _setBalance(address account, uint256 newBalance) internal {
      uint256 currentBalance = userShares[account];
      if(currentBalance > 0) {
        _processAccount(account);
      }
      if(newBalance < minBalanceForRewards && isElegible[account]){
        isElegible[account] = false;
        elegibleUsers[elegibleUsersIndex[account]] = elegibleUsers[elegibleUsers.length - 1];
        elegibleUsersIndex[elegibleUsers[elegibleUsers.length - 1]] = elegibleUsersIndex[account];
        elegibleUsers.pop();
        removeShares(account, currentBalance);
      }
      else{
        if(userShares[account] == 0){
          isElegible[account] = true;
          elegibleUsersIndex[account] = elegibleUsers.length;
          elegibleUsers.push(account);
        }
        if(newBalance > currentBalance) {
          uint256 mintAmount = newBalance - currentBalance;
          addShares(account, mintAmount);
        } else if(newBalance < currentBalance) {
          uint256 burnAmount = currentBalance - newBalance;
          removeShares(account, burnAmount);
        }
      }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;   
}

// SPDX-License-Identifier: MIT

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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