/**
██████╗░░█████╗░░█████╗░██████╗░  ████████╗░█████╗░  ░░███╗░░
██╔══██╗██╔══██╗██╔══██╗██╔══██╗  ╚══██╔══╝██╔══██╗  ░████║░░
██████╔╝██║░░██║███████║██║░░██║  ░░░██║░░░██║░░██║  ██╔██║░░
██╔══██╗██║░░██║██╔══██║██║░░██║  ░░░██║░░░██║░░██║  ╚═╝██║░░
██║░░██║╚█████╔╝██║░░██║██████╔╝  ░░░██║░░░╚█████╔╝  ███████╗
╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═════╝░  ░░░╚═╝░░░░╚════╝░  ╚══════╝

██████╗░██╗██╗░░░░░██╗░░░░░██╗░█████╗░███╗░░██╗
██╔══██╗██║██║░░░░░██║░░░░░██║██╔══██╗████╗░██║
██████╦╝██║██║░░░░░██║░░░░░██║██║░░██║██╔██╗██║
██╔══██╗██║██║░░░░░██║░░░░░██║██║░░██║██║╚████║
██████╦╝██║███████╗███████╗██║╚█████╔╝██║░╚███║

Telegram: https://t.me/QuantumxCoin

**/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/IUniswapV2Pair.sol";
import "./lib/IUniswapV2Factory.sol";
import "./lib/IUniswapV2Router.sol";

contract Quantum is IERC20, Ownable {
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    mapping(address => bool) private _isBlackListedBot;
    address[] private _blackListedBots;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 4000000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "Quantum";
    string private constant _symbol = "QNTM";
    uint8 private constant _decimals = 18;

    uint256 private _marketingFee = 5;
    uint256 private _devFee = 2;
    uint256 private _useCaseFee = 2;
    uint256 private _useCaseFee2 = 2;
    uint256 private _useCaseFee3 = 1;

    bool private _tradingEnabled = false;

    uint256 private _taxFee = _useCaseFee + _useCaseFee2 + _useCaseFee3;
    uint256 private _teamFee = _marketingFee + _devFee;
    uint256 private _totalFee =
        _marketingFee + _devFee + _useCaseFee + _useCaseFee2 + _useCaseFee3;

    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousTeamFee = _teamFee;
    uint256 private _previousMarketingFee;
    uint256 private _previousDevFee;
    uint256 private _previousUseCase;
    uint256 private _previousUseCase2;
    uint256 private _previousUseCase3;

    address payable public _marketingWalletAddress;
    address payable public _devWalletAddress;
    address payable public _useCaseWallet;
    address payable public _useCaseWallet2;
    address payable public _useCaseWallet3;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwap = false;
    bool public swapEnabled = true;
    bool public tradingActive = true;

    uint256 private _maxTxAmount = 30000000000 * 10**25;
    uint256 private constant _numOfTokensToExchangeForTeam = 5357142 * 10**25;
    uint256 private _maxWalletSize = 4000000000000 * 10**25;

    event botAddedToBlacklist(address account);
    event botRemovedFromBlacklist(address account);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address payable UseCaseWallet3) {
        _marketingWalletAddress = payable(0xe80b57266460FdA41ea3DCBCc31a7B52D9b2F0Cd);
        _devWalletAddress = payable(0xe80b57266460FdA41ea3DCBCc31a7B52D9b2F0Cd);
        _useCaseWallet = payable(0xe80b57266460FdA41ea3DCBCc31a7B52D9b2F0Cd);
        _useCaseWallet2 = payable(0xe80b57266460FdA41ea3DCBCc31a7B52D9b2F0Cd);
        _useCaseWallet3 = UseCaseWallet3;

        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        // Exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - (amount)
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender]+(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - (
                subtractedValue
            )
        );
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function setExcludeFromFee(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = excluded;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rTotal = _rTotal - (rAmount);
        _tFeeTotal = _tFeeTotal+(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / (currentRate);
    }

    function addBotToBlacklist(address account) external onlyOwner {
        require(
            account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            "We cannot blacklist UniSwap router"
        );
        require(!_isBlackListedBot[account], "Account is already blacklisted");
        _isBlackListedBot[account] = true;
        _blackListedBots.push(account);
    }

    function removeBotFromBlacklist(address account) external onlyOwner {
        require(_isBlackListedBot[account], "Account is not blacklisted");
        for (uint256 i = 0; i < _blackListedBots.length; i++) {
            if (_blackListedBots[i] == account) {
                _blackListedBots[i] = _blackListedBots[
                    _blackListedBots.length - 1
                ];
                _isBlackListedBot[account] = false;
                _blackListedBots.pop();
                break;
            }
        }
    }

    function excludeAccount(address account) external onlyOwner {
        require(
            account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            "We can not exclude Uniswap router."
        );
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _teamFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousTeamFee = _teamFee;

        _previousMarketingFee = _marketingFee;
        _previousDevFee = _devFee;
        _previousUseCase = _useCaseFee;
        _previousUseCase2 = _useCaseFee2;
        _previousUseCase3 = _useCaseFee3;

        _marketingFee = 0;
        _devFee = 0;
        _useCaseFee = 0;
        _useCaseFee2 = 0;
        _useCaseFee3 = 0;

        _taxFee = 0;
        _teamFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _teamFee = _previousTeamFee;

        _marketingFee = _previousMarketingFee;
        _devFee = _previousDevFee;
        _useCaseFee = _previousUseCase;
        _useCaseFee2 = _previousUseCase2;
        _useCaseFee3 = _previousUseCase3;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlackListedBot[sender], "You are blacklisted");
        require(!_isBlackListedBot[msg.sender], "You are blacklisted");
        require(!_isBlackListedBot[tx.origin], "You are blacklisted");
        require(
            tradingActive ||
                (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]),
            "Trading is currently not active"
        );
        if (sender != owner() && recipient != owner()) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        }
        if (
            sender != owner() &&
            recipient != owner() &&
            recipient != uniswapV2Pair &&
            recipient != address(0xdead)
        ) {
            uint256 tokenBalanceRecipient = balanceOf(recipient);
            require(
                tokenBalanceRecipient + amount <= _maxWalletSize,
                "Recipient exceeds max wallet size."
            );
        }
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap?
        // also, don't get caught in a circular team event.
        // also, don't swap if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        if (sender != uniswapV2Pair && !_isExcludedFromFee[sender]) {
            require(_tradingEnabled, "Trading is not enabled yet.");
        }

        bool overMinTokenBalance = contractTokenBalance >=
            _numOfTokensToExchangeForTeam;
        if (
            !inSwap &&
            swapEnabled &&
            overMinTokenBalance &&
            sender != uniswapV2Pair
        ) {
            // Swap tokens for ETH and send to resepctive wallets
            swapTokensForEth(contractTokenBalance);

            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                sendETHToTeam(address(this).balance);
            }
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }

        //transfer amount, it will take tax and team fee
        _tokenTransfer(sender, recipient, amount, takeFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToTeam(uint256 amount) private {
        _marketingWalletAddress.transfer(
            amount / (_totalFee) * (_marketingFee)
        );
        _devWalletAddress.transfer(amount / (_totalFee) * (_devFee));
        _useCaseWallet.transfer(amount / (_totalFee) * (_useCaseFee));
        _useCaseWallet2.transfer(amount / (_totalFee) * (_useCaseFee2));
        _useCaseWallet3.transfer(amount / (_totalFee) * (_useCaseFee3));
    }

    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToTeam(contractETHBalance);
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient]+(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient]+(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam * (currentRate);
        _rOwned[address(this)] = _rOwned[address(this)]+(rTeam);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)]+(tTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - (rFee);
        _tFeeTotal = _tFeeTotal+(tFee);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(
            tAmount,
            _taxFee,
            _teamFee
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tTeam,
            currentRate
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 taxFee,
        uint256 teamFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount * (taxFee) / (100);
        uint256 tTeam = tAmount * (teamFee) / (100);
        uint256 tTransferAmount = tAmount - (tFee) - (tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount * (currentRate);
        uint256 rFee = tFee * (currentRate);
        uint256 rTeam = tTeam * (currentRate);
        uint256 rTransferAmount = rAmount - (rFee) - (rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / (tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply - (_rOwned[_excluded[i]]);
            tSupply = tSupply - (_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal / (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getTaxFee() public view returns (uint256) {
        return _taxFee;
    }

    function _getTeamFee() public view returns (uint256) {
        return _teamFee;
    }

    function _getMarketingFee() public view returns (uint256) {
        return _marketingFee;
    }

    function _getDevFee() public view returns (uint256) {
        return _devFee;
    }

    function _geUseCaseFee() public view returns (uint256) {
        return _useCaseFee;
    }

    function _getUseCaseFee2() public view returns (uint256) {
        return _useCaseFee2;
    }

    function _getUseCaseFee3() public view returns (uint256) {
        return _useCaseFee3;
    }

    function _getETHBalance() public view returns (uint256 balance) {
        return address(this).balance;
    }

    function _getMaxTxAmount() public view returns (uint256) {
        return _maxTxAmount;
    }

    function _getMaxWalletSize() public view returns (uint256) {
        return _maxWalletSize;
    }

    function _setMarketingFee(uint256 marketingFee) external onlyOwner {
        require(
            marketingFee >= 1 && marketingFee <= 6,
            "marketingFee should be in 1 - 6"
        );
        _marketingFee = marketingFee;
    }

    function _setDevFee(uint256 devFee) external onlyOwner {
        require(devFee >= 1 && devFee <= 6, "devFee should be in 1 - 6");
        _devFee = devFee;
    }

    function _setUseCaseFee(uint256 useCaseFee) external onlyOwner {
        require(
            useCaseFee >= 1 && useCaseFee <= 6,
            "useCaseFee should be in 1 - 6"
        );
        _useCaseFee = useCaseFee;
    }

    function _setUseCaseFee2(uint256 useCaseFee2) external onlyOwner {
        require(
            useCaseFee2 >= 1 && useCaseFee2 <= 6,
            "useCaseFee2 should be in 1 - 6"
        );
        _useCaseFee2 = useCaseFee2;
    }

    function _setUseCaseFee3(uint256 useCaseFee3) external onlyOwner {
        require(
            useCaseFee3 >= 1 && useCaseFee3 <= 6,
            "useCaseFee3 should be in 1 - 6"
        );
        _useCaseFee3 = useCaseFee3;
    }

    function _setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function _setMaxWalletSize(uint256 maxWalletSize) external onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    function _setUseCaseWallet3(address payable UseCaseWallet3)
        external
        onlyOwner
    {
        _useCaseWallet3 = UseCaseWallet3;
    }

    // Enable Trading
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }

    // Disable Trading
    function disableTrading() external onlyOwner {
        tradingActive = false;
        swapEnabled = false;
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

pragma solidity ^0.8.4;

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

pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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



// pragma solidity >=0.6.2;

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