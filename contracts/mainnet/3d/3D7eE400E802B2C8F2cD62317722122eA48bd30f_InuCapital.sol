// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/**
Inu Capital
Active Defi Farming through Collective Capital Management

we send our regards, respect and love to MCC, ReFi, ACYC, SBC, and all of
our other predecessors.

To those who fork us, we send our best wishes. May your code be error free.

Thus, we enter Elysium. May the Gates Open for Thee

https://inucapital.io
**/

contract InuCapital is Ownable, IERC20 {
    address private constant UNISWAPROUTER = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    string private constant _name = "Inu Capital";
    string private constant _symbol = "INC";

    uint256 public buyLiquidityFeeBPS = 500;
    uint256 public reflectionFeeBPS = 500;

    uint256 public treasuryFeeBPS = 1300;
    uint256 public dividendFeeBPS = 600;
    uint256 public devFeeBPS = 100;
    uint256 public maxTxBPS = 25;
    uint256 public maxWalletBPS = 100;

    uint256 public swapTokensAtAmount = 100000 * (10**18);
    uint256 public lastSwapTime;
    bool swapAllToken = true;

    bool private tradingEnabled = false;
    bool public swapEnabled = true;
    bool public taxEnabled = true;
    bool private reflectionEnabled = true;
    bool private dividendEnabled = true;

    uint256 private _totalSupply;
    bool private swapping;

    // dev fund
    address devWallet = address(0xfE33e3E48b1BA04708037B9Da2F0D4caD7A42dfb);
    // treasury and liquidity wallet
    address treasuryWallet = address(0xfE33e3E48b1BA04708037B9Da2F0D4caD7A42dfb);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    event SendDividends(uint256 amount);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    DividendTracker public immutable dividendTracker;
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;

    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    constructor() {
        dividendTracker = new DividendTracker(address(this));

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(UNISWAPROUTER);

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router), true);

        dividendTracker.excludeFromReflections(address(dividendTracker), true);
        dividendTracker.excludeFromReflections(address(this), true);
        dividendTracker.excludeFromReflections(owner(), true);
        dividendTracker.excludeFromReflections(address(_uniswapV2Router), true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(dividendTracker), true);

        excludeFromMaxTx(owner(), true);
        excludeFromMaxTx(address(this), true);
        excludeFromMaxTx(address(dividendTracker), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(dividendTracker), true);

        uint256 initialAmount = 10000000000 * (10**18);
        _totalSupply += initialAmount;
        _balances[owner()] += initialAmount;
        emit Transfer(address(0), owner(), initialAmount);
    }

    receive() external payable {}

    function name() external pure returns (string memory) { return _name; }

    function symbol() external pure returns (string memory) { return _symbol; }

    function decimals() external pure returns (uint8) { return 18; }

    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "Inu: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "Inu: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function setTradingEnabled(bool _value) external onlyOwner {
        tradingEnabled = _value;
    }

    function getTradingEnabled() external view onlyOwner returns (bool) {
        return tradingEnabled;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(
            tradingEnabled ||
                sender == owner() ||
                recipient == owner(),
            "Not Open"
        );

        require(sender != address(0), "Inu: transfer from the zero address");
        require(recipient != address(0), "Inu: transfer to the zero address");

        uint256 _maxTxAmount = (totalSupply() * maxTxBPS) / 10000;
        uint256 _maxWallet = (totalSupply() * maxWalletBPS) / 10000;
        require(
            amount <= _maxTxAmount || _isExcludedFromMaxTx[sender],
            "TX Limit Exceeded"
        );

        if (
            sender != owner() &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != uniswapV2Pair
        ) {
            uint256 currentBalance = balanceOf(recipient);
            require(
                _isExcludedFromMaxWallet[recipient] || (currentBalance + amount <= _maxWallet),
                "Inu: recipient not excluded from max wallet and transfer will cause balance of recipient to be > maxWallet"
            );
        }

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "Inu: transfer amount exceeds balance"
        );

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            swapEnabled && // True
            canSwap && // true
            !swapping && // swapping=false !false true
            !automatedMarketMakerPairs[sender] && // no swap on remove liquidity step 1 or DEX buy
            sender != address(uniswapV2Router) && // no swap on remove liquidity step 2
            sender != owner() &&
            recipient != owner()
        ) {
            swapping = true;

            if (!swapAllToken) {
                contractTokenBalance = swapTokensAtAmount;
            }
            _executeSwap(contractTokenBalance);

            lastSwapTime = block.timestamp;
            swapping = false;
        }

        bool takeFee;

        if (
            sender == uniswapV2Pair ||
            recipient == uniswapV2Pair
        ) {
            takeFee = true;
        }

        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }

        if (swapping || !taxEnabled) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees;
            if (sender == address(uniswapV2Pair)) { // buy
              fees = (amount * (buyLiquidityFeeBPS + reflectionFeeBPS)) / 10000;
              uint256 liquidityFee = (amount * buyLiquidityFeeBPS) / 10000;
              uint256 dividendFee = (amount * reflectionFeeBPS) / 10000;
              _executeTransfer(sender, treasuryWallet, liquidityFee);
              _executeTransfer(sender, address(dividendTracker), dividendFee);
              dividendTracker.distributeReflections(dividendFee);
            } else {                                // sell
              fees = (amount * (treasuryFeeBPS + dividendFeeBPS + devFeeBPS)) / 10000;
              _executeTransfer(sender, address(this), fees);
            }
            amount -= fees;
        }

        _executeTransfer(sender, recipient, amount);

        dividendTracker.setBalance(payable(sender), balanceOf(sender));
        dividendTracker.setBalance(payable(recipient), balanceOf(recipient));
    }

    function sendReflections(
        address sender,
        uint256 amount
    ) external onlyOwner
    {
      _executeTransfer(sender, address(dividendTracker), amount);
      dividendTracker.distributeReflections(amount);
    }

    function _executeTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "Inu: transfer from the zero address");
        require(recipient != address(0), "Inu: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "Inu: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "Inu: approve from the zero address");
        require(spender != address(0), "Inu: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function swapTokensForNative(uint256 tokens) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokens);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0, // accept any amount of native
            path,
            address(this),
            block.timestamp
        );
    }

    function _executeSwap(uint256 tokens) private {
        if (tokens <= 0) {
            return;
        }
        swapTokensForNative(tokens);
        uint256 nativeAfterSwap = address(this).balance;

        uint256 tokensTreasury;
        if (treasuryWallet != address(0)) {
          tokensTreasury = (nativeAfterSwap * (treasuryFeeBPS)) / (treasuryFeeBPS + dividendFeeBPS + devFeeBPS);
          if (tokensTreasury > 0) {
            payable(treasuryWallet).transfer(tokensTreasury);
          }
        }

        uint256 tokensDev;
        if (devWallet != address(0)) {
          tokensDev = (nativeAfterSwap * devFeeBPS) / (treasuryFeeBPS + dividendFeeBPS + devFeeBPS);
          if (tokensDev > 0) {
            payable(devWallet).transfer(tokensDev);
          }
        }

        uint256 tokensDividend;
        if (dividendTracker.totalSupply() > 0) {
          tokensDividend = (nativeAfterSwap * dividendFeeBPS) / (treasuryFeeBPS + dividendFeeBPS + devFeeBPS);
          if (tokensDividend > 0) {
              (bool success, ) = address(dividendTracker).call{
                  value: tokensDividend
              }("");
              if (success) {
                  emit SendDividends(tokensDividend);
              }
          }
        }
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Inu: account is already set to requested state"
        );
        _isExcludedFromFees[account] = excluded;
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function manualSendDividend(uint256 amount, address holder)
        external
        onlyOwner
    {
        dividendTracker.manualSendDividend(amount, holder);
    }

    function excludeFromDividendsOrReflections(address account, bool excluded, bool mode)
        public
        onlyOwner
    {
      if (mode) { // DIVIDENDS
        dividendTracker.excludeFromDividends(account, excluded);
      } else {    // REFLECTIONS
        dividendTracker.excludeFromReflections(account, excluded);
      }
    }

    function isExcludedFromDividendsAndReflections(address account)
        external
        view
        returns (bool, bool)
    {
        return (dividendTracker.isExcludedFromDividends(account), dividendTracker.isExcludedFromReflections(account));
    }

    function setWallet(
        address payable _treasuryWallet,
        address payable _devWallet
    ) external onlyOwner {
        treasuryWallet = _treasuryWallet;
        devWallet = _devWallet;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(pair != uniswapV2Pair, "Inu: DEX pair can not be removed");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function setFee(
        uint256 _reflectionFee,
        uint256 _buyLiquidityFee,
        uint256 _treasuryFee,
        uint256 _dividendFee,
        uint256 _devFee
    ) external onlyOwner {
        uint256 denom = 10000;
        uint256 totalFees = (_reflectionFee / denom) + (_buyLiquidityFee / denom)+ (_treasuryFee / denom) +
            (_dividendFee / denom) + (_devFee / denom);
        require(
            totalFees <= 1.0,
            "Inu: Total Fees cannot exceed 100%"
        );
        reflectionFeeBPS = _reflectionFee;
        buyLiquidityFeeBPS = _buyLiquidityFee;
        treasuryFeeBPS = _treasuryFee;
        dividendFeeBPS = _dividendFee;
        devFeeBPS = _devFee;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Inu: automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        if (value) {
            dividendTracker.excludeFromDividends(pair, true);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "Inu: the router is already set to the new address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function claimDividend() external {
        require(dividendEnabled, "Inu: Dividends Disabled");
        dividendTracker.processAccount(payable(_msgSender()));
    }

    function claimReflection() external {
        require(reflectionEnabled, "Inu: Reflections Disabled");
        uint256 amount = dividendTracker.processAccountReflection(payable(_msgSender()));
        _executeTransfer(address(dividendTracker), address(_msgSender()), amount);
    }

    function claimAll() external {
        require(dividendEnabled, "Inu: Dividends Disabled");
        require(reflectionEnabled, "Inu: Reflections Disabled");
        dividendTracker.processAccount(payable(_msgSender()));
        uint256 amount = dividendTracker.processAccountReflection(payable(_msgSender()));
        _executeTransfer(address(dividendTracker), address(_msgSender()), amount);
    }

    function getAccountDividendInfo(address account)
        external
        view
        returns (
          address,
          uint256,
          uint256,
          uint256,
          uint256
        )
    {
        return dividendTracker.getAccountDividendInfo(account);
    }

    function getAccountReflectionInfo(address account)
        public
        view
        returns (
          address,
          uint256,
          uint256,
          uint256,
          uint256
        )
    {
        return dividendTracker.getAccountReflectionInfo(account);
    }

    function getLastClaimTime(address account) external view returns (uint256) {
        return dividendTracker.getLastClaimTime(account);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function setTokenomicsSettings(
      bool _dividendEnabled,
      bool _reflectionEnabled,
      bool _tradingEnabled,
      bool _taxEnabled
    ) external onlyOwner {
      dividendEnabled = _dividendEnabled;
      reflectionEnabled = _reflectionEnabled;
      tradingEnabled = _tradingEnabled;
      taxEnabled = _taxEnabled;
    }

    function updateDividendSettings(
        bool _swapEnabled,
        uint256 _swapTokensAtAmount,
        bool _swapAllToken
    ) external onlyOwner {
        swapEnabled = _swapEnabled;
        swapTokensAtAmount = _swapTokensAtAmount;
        swapAllToken = _swapAllToken;
    }

    function setMax(uint256 _maxTxBPS, uint256 _maxWalletBPS) external onlyOwner {
        maxTxBPS = _maxTxBPS;
        maxWalletBPS = _maxWalletBPS;
    }

    function excludeFromMaxTx(address account, bool excluded) public onlyOwner {
        _isExcludedFromMaxTx[account] = excluded;
    }

    function isExcludedFromMaxTx(address account) external view returns (bool) {
        return _isExcludedFromMaxTx[account];
    }

    function excludeFromMaxWallet(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    function isExcludedFromMaxWallet(address account)
        external
        view
        returns (bool)
    {
        return _isExcludedFromMaxWallet[account];
    }

    function rescueToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function rescueETH(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function rescueReflection(uint256 _amount) external onlyOwner {
        _executeTransfer(address(dividendTracker), msg.sender, _amount);
    }

    function investorAirdrop(address[] calldata recipients, uint256 amount) external onlyOwner {
      // thank you investors!
      for (uint256 _i = 0; _i < recipients.length; _i++) {
        transferFrom(msg.sender, recipients[_i], amount);
      }
    }

    function snapshotAirdrop(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
      for (uint256 _i = 0; _i < recipients.length; _i++) {
        transferFrom(msg.sender, recipients[_i], amounts[_i]);
      }
    }
}

contract DividendTracker is Ownable, IERC20 {
    string private constant _name = "Inu_DividendTracker";
    string private constant _symbol = "Inu_DividendTracker";

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    uint256 private constant magnitude = 2**128;
    uint256 public immutable minTokenBalanceForDividends;
    uint256 private magnifiedDividendPerShare;
    uint256 public totalDividendsDistributed;
    uint256 public totalDividendsWithdrawn;
    uint256 private magnifiedReflectionPerShare;
    uint256 public totalReflectionsDistributed;
    uint256 public totalReflectionsWithdrawn;

    address public tokenAddress;

    struct AccountTracker {
      bool excludedFromDividends;
      bool excludedFromReflections;
      int256 magnifiedDividendCorrections;
      uint256 withdrawnDividends;
      int256 magnifiedReflectionCorrections;
      uint256 withdrawnReflections;
      uint256 lastClaimTimes;
    }

    mapping(address => AccountTracker) public accountTracker;

    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
    event ExcludeFromDividends(address indexed account, bool excluded);
    event ClaimDividend(address indexed account, uint256 amount);

    struct AccountInfo {
        address account;
        uint256 withdrawableDividends;
        uint256 totalDividends;
        uint256 lastClaimTime;
    }

    constructor(address _tokenAddress) {
        minTokenBalanceForDividends = 10000 * (10**18);
        tokenAddress = _tokenAddress;
    }

    receive() external payable {
        distributeDividends();
    }

    function distributeDividends() public payable {
        require(_totalSupply > 0);
        if (msg.value > 0) {
            magnifiedDividendPerShare =
                magnifiedDividendPerShare +
                ((msg.value * magnitude) / _totalSupply);
            emit DividendsDistributed(msg.sender, msg.value);
            totalDividendsDistributed += msg.value;
        }
    }

    function distributeReflections(uint256 amount) external onlyOwner {
      require(_totalSupply > 0);
      if (amount > 0) {
          magnifiedReflectionPerShare =
              magnifiedReflectionPerShare +
              ((amount * magnitude) / _totalSupply);
          emit DividendsDistributed(msg.sender, amount);
          totalReflectionsDistributed += amount;
      }
    }

    function setBalance(address payable account, uint256 newBalance)
        external
        onlyOwner
    {
        if (accountTracker[account].excludedFromDividends) {
            return;
        }
        if (newBalance >= minTokenBalanceForDividends) {
            _setBalance(account, newBalance);
        } else {
            _setBalance(account, 0);
        }
    }

    function excludeFromDividends(address account, bool excluded) external onlyOwner
    {
        require(
            accountTracker[account].excludedFromDividends != excluded,
            "Inu_DividendTracker: account already set to requested state"
        );
        accountTracker[account].excludedFromDividends = excluded;
        emit ExcludeFromDividends(account, excluded);
    }

    function isExcludedFromDividends(address account) external view returns (bool)
    {
        return accountTracker[account].excludedFromDividends;
    }

    function excludeFromReflections(address account, bool excluded) external onlyOwner
    {
        require(
            accountTracker[account].excludedFromReflections != excluded,
            "Inu_DividendTracker: account already set to requested state"
        );
        accountTracker[account].excludedFromReflections = excluded;
        emit ExcludeFromDividends(account, excluded);
    }

    function isExcludedFromReflections(address account)
        external
        view
        returns (bool)
    {
        return accountTracker[account].excludedFromReflections;
    }

    function manualSendDividend(uint256 amount, address holder)
        external
        onlyOwner
    {
        uint256 contractETHBalance = address(this).balance;
        payable(holder).transfer(amount > 0 ? amount : contractETHBalance);
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = _balances[account];
        if (newBalance > currentBalance) {
            uint256 addAmount = newBalance - currentBalance;
            _mint(account, addAmount);
        } else if (newBalance < currentBalance) {
            uint256 subAmount = currentBalance - newBalance;
            _burn(account, subAmount);
        }
    }

    function _mint(address account, uint256 amount) private {
        require(
            account != address(0),
            "Inu_DividendTracker: mint to the zero address"
        );
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        accountTracker[account].magnifiedDividendCorrections =
            accountTracker[account].magnifiedDividendCorrections -
            int256(magnifiedDividendPerShare * amount);
        accountTracker[account].magnifiedReflectionCorrections =
            accountTracker[account].magnifiedReflectionCorrections -
            int256(magnifiedReflectionPerShare * amount);
    }

    function _burn(address account, uint256 amount) private {
        require(
            account != address(0),
            "Inu_DividendTracker: burn from the zero address"
        );
        uint256 accountBalance = _balances[account];
        require(
            accountBalance >= amount,
            "Inu_DividendTracker: burn amount exceeds balance"
        );
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        accountTracker[account].magnifiedDividendCorrections =
            accountTracker[account].magnifiedDividendCorrections +
            int256(magnifiedDividendPerShare * amount);
        accountTracker[account].magnifiedReflectionCorrections =
            accountTracker[account].magnifiedReflectionCorrections +
            int256(magnifiedReflectionPerShare * amount);
    }

    function processAccount(address payable account)
        external
        onlyOwner
        returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);
        if (amount > 0) {
            accountTracker[account].lastClaimTimes = block.timestamp;
            emit ClaimDividend(account, amount);
            return true;
        }
        return false;
    }

    function processAccountReflection(address payable account)
        external
        onlyOwner
        returns (uint256)
    {
        uint256 amount = _withdrawReflectionOfUser(account);
        if (amount > 0) {
            accountTracker[account].lastClaimTimes = block.timestamp;
            emit ClaimDividend(account, amount);
            return amount;
        }
        return amount;
    }

    function _withdrawDividendOfUser(address payable account)
        private
        returns (uint256)
    {
        if (accountTracker[account].excludedFromDividends) { return 0;}
        uint256 _withdrawableDividend = accumulativeDividendOf(account) - accountTracker[account].withdrawnDividends;
        if (_withdrawableDividend > 0) {
            accountTracker[account].withdrawnDividends += _withdrawableDividend;
            totalDividendsWithdrawn += _withdrawableDividend;
            (bool success, ) = account.call{
                value: _withdrawableDividend,
                gas: 3000
            }("");
            if (!success) {
                accountTracker[account].withdrawnDividends -= _withdrawableDividend;
                totalDividendsWithdrawn -= _withdrawableDividend;
                return 0;
            }
            emit DividendWithdrawn(account, _withdrawableDividend);
            return _withdrawableDividend;
        }
        return 0;
    }

    function accumulativeDividendOf(address account)
        public
        view
        returns (uint256)
    {
        if (accountTracker[account].excludedFromDividends) { return 0;}
        int256 a = int256(magnifiedDividendPerShare * balanceOf(account));
        int256 b = accountTracker[account].magnifiedDividendCorrections; // this is an explicit int256 (signed)
        return uint256(a + b) / magnitude;
    }

    function getAccountDividendInfo(address account)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        AccountInfo memory info;
        info.account = account;
        if (accountTracker[account].excludedFromDividends) {
            info.withdrawableDividends = 0;
            info.totalDividends = 0;
        } else {
            info.totalDividends = accumulativeDividendOf(account);
            info.withdrawableDividends = info.totalDividends - accountTracker[account].withdrawnDividends;
        }
        info.lastClaimTime = accountTracker[account].lastClaimTimes;
        return (
            info.account,
            info.withdrawableDividends,
            info.totalDividends,
            info.lastClaimTime,
            totalDividendsWithdrawn
        );
    }

    function _withdrawReflectionOfUser(address payable account)
        private
        returns (uint256)
    {
        if (accountTracker[account].excludedFromReflections) { return 0; }
        uint256 amount = accumulativeReflectionOf(account) - accountTracker[account].withdrawnReflections;
        if (amount > 0) {
            accountTracker[account].withdrawnReflections += amount;
            totalReflectionsWithdrawn += amount;
            emit DividendWithdrawn(account, amount);
            return amount;
        }
        return 0;
    }

    function accumulativeReflectionOf(address account)
        public
        view
        returns (uint256)
    {
        if (accountTracker[account].excludedFromReflections) { return 0; }
        int256 a = int256(magnifiedReflectionPerShare * balanceOf(account));
        int256 b = accountTracker[account].magnifiedReflectionCorrections; // this is an explicit int256 (signed)
        return uint256(a + b) / magnitude;
    }

    function getAccountReflectionInfo(address account)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        AccountInfo memory info;
        info.account = account;
        if (accountTracker[account].excludedFromReflections) {
            info.withdrawableDividends = 0;
            info.totalDividends = 0;
        } else {
            info.totalDividends = accumulativeReflectionOf(account);
            info.withdrawableDividends = info.totalDividends - accountTracker[account].withdrawnReflections;
        }
        info.lastClaimTime = accountTracker[account].lastClaimTimes;
        return (
            info.account,
            info.withdrawableDividends,
            info.totalDividends,
            info.lastClaimTime,
            totalReflectionsWithdrawn
        );
    }

    function getLastClaimTime(address account) external view returns (uint256) {
        return accountTracker[account].lastClaimTimes;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address, uint256) external pure override returns (bool) {
        revert("Inu_DividendTracker: method not implemented");
    }

    function allowance(address, address)
        external
        pure
        override
        returns (uint256)
    {
        revert("Inu_DividendTracker: method not implemented");
    }

    function approve(address, uint256) external pure override returns (bool) {
        revert("Inu_DividendTracker: method not implemented");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure override returns (bool) {
        revert("Inu_DividendTracker: method not implemented");
    }
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}