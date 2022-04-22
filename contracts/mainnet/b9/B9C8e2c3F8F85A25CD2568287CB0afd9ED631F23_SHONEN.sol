// SPDX-License-Identifier: MIT
/**
 * telegram: https://t.me/shonenverify
 * website: https://www.shonen.io/
 */
pragma solidity ^0.8.10;

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, TOKEN the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

contract SHONEN is Context, ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _holders;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromTax;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _taxableExchange;

    string private _name = "SHONEN";
    string private _symbol = "SHONEN";
    uint8 private _decimals = 18;
    uint256 private _tTotal = 100000000000 * 1e18;

    IUniswapV2Router02 public uniswapRouter;
    address public immutable uniSwapPair;

    address payable private marketingWallet;
    address payable private devWallet;
    address payable private daoWallet;
    address payable private tempBuyBackWallet;

    uint256 _marketingTax;
    uint256 public _buyMarketingTax = 100; // 10%
    uint256 public _sellMarketingTax = 100;

    uint256 _devTax;
    uint256 public _buyDevTax = 100;
    uint256 public _sellDevTax = 100;

    uint256 _daoTax;
    uint256 public _buyDAOTax = 20; // 2%
    uint256 public _sellDAOTax = 20;

    uint256 _tempBuyBackTax;
    uint256 public _buyBackTax = 30; // 3% can be turned off

    bool inSwapAndLiquify = false;
    bool public swapAndLiquifyEnabled = true;
    bool public isBuyBackTaxEnabled = true;

    uint256 public maxSellTransaction = 1000000000 * 10**9; // 1% of total suppy
    uint256 public maxBuyTransaction = 2000000000 * 10**9; // 2% of total suppy
    uint256 public minTokenNumberToSell = 100000000 * 10**9; // 0.1% of total supply

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
        address payable _marketingWallet,
        address payable _devWallet,
        address payable _daoWallet,
        address payable _tempBuyBackWallet
    ) {
        IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        // Create a Uniswap pair for this new token
        uniSwapPair = IUniswapV2Factory(_uniswapRouter.factory()).createPair(
            address(this),
            _uniswapRouter.WETH()
        );

        _taxableExchange[uniSwapPair] = true;

        // set the rest of the contract variables
        uniswapRouter = _uniswapRouter;
        tempBuyBackWallet = _tempBuyBackWallet;
        daoWallet = _daoWallet;
        marketingWallet = _marketingWallet;
        devWallet = _devWallet;

        //exclude owner and this contract from Tax
        _isExcludedFromTax[owner()] = true;
        _isExcludedFromTax[address(this)] = true;
        _isExcludedFromTax[_tempBuyBackWallet] = true;
        _isExcludedFromTax[_daoWallet] = true;
        _isExcludedFromTax[_marketingWallet] = true;
        _isExcludedFromTax[_devWallet] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[_tempBuyBackWallet] = true;
        _isExcludedFromMaxTx[_daoWallet] = true;
        _isExcludedFromMaxTx[_marketingWallet] = true;
        _isExcludedFromMaxTx[_devWallet] = true;

        _holders[owner()] = _tTotal;
        emit Transfer(address(0), owner(), _tTotal);
    }

    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _holders[account];
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
            _allowances[sender][_msgSender()].sub(
                amount,
                "SHONEN: transfer amount exceeds allowance"
            )
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
            _allowances[_msgSender()][spender].add(addedValue)
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
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "SHONEN: decreased allowance below zero"
            )
        );
        return true;
    }

    // getter functions

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function isTaxableExchange(address pair) public view returns (bool) {
        return _taxableExchange[pair];
    }

    function isExcludedFromTax(address account) public view returns (bool) {
        return _isExcludedFromTax[account];
    }

    function excludeFromTax(address account) public onlyOwner {
        _isExcludedFromTax[account] = true;
    }

    function includeInTax(address account) public onlyOwner {
        _isExcludedFromTax[account] = false;
    }

    function setAmountLimits(uint256 _maxSellTxAmount, uint256 _maxBuyTxAmount)
        public
        onlyOwner
    {
        require(_maxSellTxAmount >= 500000000 * 1e18); // must be greater than 0.5%
        maxSellTransaction = _maxSellTxAmount;
        maxBuyTransaction = _maxBuyTxAmount;
    }

    function removeMaxBuyLimit() public onlyOwner {
        maxBuyTransaction = _tTotal;
    }

    function removeAllBuyTaxes() external onlyOwner {
        _tempBuyBackTax = 0;
        _buyDAOTax = 0;
        _buyMarketingTax = 0;
        _buyDevTax = 0;
    }

    function removeAllSellTaxes() external onlyOwner {
        _tempBuyBackTax = 0;
        _sellDAOTax = 0;
        _sellMarketingTax = 0;
        _sellDevTax = 0;
    }

    function setAllBuyTaxes(
        uint256 _bBuyBackTax,
        uint256 _bDAOTax,
        uint256 _bMarketingTax,
        uint256 _bDevTax
    ) external onlyOwner {
        uint256 sumOfTaxes = _bDevTax.add(_bMarketingTax).add(_bDAOTax).add(
            isBuyBackTaxEnabled ? _bBuyBackTax : 0
        );
        require(InTaxRange(sumOfTaxes));
        _buyBackTax = _bBuyBackTax;
        _buyDAOTax = _bDAOTax;
        _buyMarketingTax = _bMarketingTax;
        _buyDevTax = _bDevTax;
    }

    function setSellSellTaxes(
        uint256 _sBuyBackTax,
        uint256 _sDAOTax,
        uint256 _sMarketingTax,
        uint256 _sDevTax
    ) external onlyOwner {
        uint256 sumOfTaxes = _sDevTax.add(_sMarketingTax).add(_sDAOTax).add(
            isBuyBackTaxEnabled ? _sBuyBackTax : 0
        );
        require(InTaxRange(sumOfTaxes));
        _buyBackTax = _sBuyBackTax;
        _sellDAOTax = _sDAOTax;
        _sellMarketingTax = _sMarketingTax;
        _sellDevTax = _sDevTax;
    }

    function setMinTokenNumberToSell(uint256 _amount) public onlyOwner {
        minTokenNumberToSell = _amount;
    }

    function setExcludeFromMaxTx(address _address, bool _state)
        public
        onlyOwner
    {
        _isExcludedFromMaxTx[_address] = _state;
    }

    function addExchangePair(address _pairAddress) public onlyOwner {
        _taxableExchange[_pairAddress] = true;
    }

    function removeExchangePair(address _pairAddress) public onlyOwner {
        _taxableExchange[_pairAddress] = false;
    }

    function setSwapAndLiquifyEnabled(bool _state) public onlyOwner {
        swapAndLiquifyEnabled = _state;
        emit SwapAndLiquifyEnabledUpdated(_state);
    }

    function setNewTaxWallets(
        address payable _tempBuyBackWallet,
        address payable _daoWallet,
        address payable _marketingWallet,
        address payable _devWallet
    ) external onlyOwner {
        tempBuyBackWallet = _tempBuyBackWallet;
        daoWallet = _daoWallet;
        marketingWallet = _marketingWallet;
        devWallet = _devWallet;
    }

    function setTempBuyBackWallet(address payable _tempBuyBackWallet)
        external
        onlyOwner
    {
        tempBuyBackWallet = _tempBuyBackWallet;
    }

    function setDAOWallet(address payable _daoWallet) external onlyOwner {
        daoWallet = _daoWallet;
    }

    function setMarketingWallet(address payable _marketingWallet)
        external
        onlyOwner
    {
        marketingWallet = _marketingWallet;
    }

    function setDevelopmentWallet(address payable _devWallet)
        external
        onlyOwner
    {
        devWallet = _devWallet;
    }

    function removeMaxTxLimits() external onlyOwner {
        maxSellTransaction = _tTotal;
        maxBuyTransaction = _tTotal;
    }

    function setUniswapRouter(IUniswapV2Router02 _uniswapRouter)
        external
        onlyOwner
    {
        uniswapRouter = _uniswapRouter;
    }

    function toggleBuyBackTax() external onlyOwner {
        isBuyBackTaxEnabled = !isBuyBackTaxEnabled;
    }

    // internal functions

    function takeBuyBackTax() internal view returns (uint256) {
        return isBuyBackTaxEnabled ? _tempBuyBackTax : 0;
    }

    function sumOfTaxPerTx(uint256 tAmount) internal view returns (uint256) {
        uint256 percentage = tAmount
            .mul(_daoTax.add(_marketingTax).add(_devTax).add(takeBuyBackTax()))
            .div(1e3);
        return percentage;
    }

    function _takeAllTax(uint256 tAmount) internal {
        uint256 tFee = tAmount
            .mul(_daoTax.add(_marketingTax).add(_devTax).add(takeBuyBackTax()))
            .div(1e3);

        _holders[address(this)] = _holders[address(this)].add(tFee);
        emit Transfer(_msgSender(), address(this), tFee);
    }

    function InTaxRange(uint256 tAmount) private pure returns (bool) {
        uint256 max = 160; // 16%
        return tAmount <= max;
    }

    function removeAllFee() private {
        _tempBuyBackTax = 0;
        _daoTax = 0;
        _marketingTax = 0;
        _devTax = 0;
    }

    function takeBuyFee() private {
        _tempBuyBackTax = _buyBackTax;
        _daoTax = _buyDAOTax;
        _marketingTax = _buyMarketingTax;
        _devTax = _buyDevTax;
    }

    function takeSellFee() private {
        _tempBuyBackTax = _buyBackTax;
        _daoTax = _sellDAOTax;
        _marketingTax = _sellMarketingTax;
        _devTax = _sellDevTax;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "SHONEN: approve from the zero address");
        require(spender != address(0), "SHONEN: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "SHONEN: transfer from the zero address");
        require(to != address(0), "SHONEN: transfer to the zero address");
        require(
            amount > 0,
            "SHONEN: Transfer amount must be greater than zero"
        );

        if (
            !_isExcludedFromMaxTx[from] && !_isExcludedFromMaxTx[to] // by default false
        ) {
            if (_taxableExchange[to]) {
                // sell
                require(
                    amount <= maxSellTransaction.add(5 * 1e18),
                    "SHONEN: max sell transaction exceeded"
                );
            }
            if (_taxableExchange[from]) {
                // buy
                require(
                    amount <= maxBuyTransaction.add(5 * 1e18),
                    "SHONEN: max buy transaction exceeded"
                );
            }
        }

        // swap and liquify
        swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromTax account then remove the fee
        if (_isExcludedFromTax[from] || _isExcludedFromTax[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    // take fee if takefee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        else if (_taxableExchange[sender]) takeBuyFee();
        else if (_taxableExchange[recipient]) takeSellFee();
        else removeAllFee();

        uint256 tTransferAmount = amount.sub(sumOfTaxPerTx(amount));
        _holders[sender] = _holders[sender].sub(amount);
        _holders[recipient] = _holders[recipient].add(tTransferAmount);
        _takeAllTax(amount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function manualSwap() external onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this)).sub(
            1000 * 1e18
        ); // maintain tokens in the contract
        require(
            contractTokenBalance > 0,
            "SHONEN: contract balance must be greater than zero"
        );
        _approve(address(this), address(uniswapRouter), contractTokenBalance);
        swapTokensForETH(contractTokenBalance);
    }

    function manualSend() external onlyOwner {
        uint256 deltaBalance = getContractBalance();
        require(deltaBalance > 0, "SHONEN: Insufficient contract balance");
        uint256 totalPercent = _daoTax.add(_marketingTax).add(_devTax).add(
            takeBuyBackTax()
        );

        uint256 devisor = 1e3;

        uint256 buyBackPercent = takeBuyBackTax().mul(devisor).div(
            totalPercent
        );

        uint256 daoPercent = _daoTax.mul(devisor).div(totalPercent);
        uint256 marketingPercent = _marketingTax.mul(devisor).div(totalPercent);
        uint256 devPercent = _devTax.mul(devisor).div(totalPercent);

        totalPercent = daoPercent.add(marketingPercent).add(devPercent).add(
            buyBackPercent
        );

        if (totalPercent > 0) {
            if (isBuyBackTaxEnabled) {
                tempBuyBackWallet.transfer(
                    deltaBalance.mul(buyBackPercent).div(totalPercent)
                );
            }

            daoWallet.transfer(deltaBalance.mul(daoPercent).div(totalPercent));
            marketingWallet.transfer(
                deltaBalance.mul(marketingPercent).div(totalPercent)
            );
            devWallet.transfer(deltaBalance.mul(devPercent).div(totalPercent));
        } else {
            devWallet.transfer(deltaBalance); // transfer all to dev if div by zero error (all tax values removed
        }
    }

    function swapAndLiquify(address from, address to) private {
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= maxSellTransaction) {
            contractTokenBalance = maxSellTransaction;
        }

        bool shouldSell = contractTokenBalance >= minTokenNumberToSell;

        if (
            !inSwapAndLiquify &&
            shouldSell &&
            !_taxableExchange[from] &&
            swapAndLiquifyEnabled &&
            !(from == address(this) && _taxableExchange[to])
        ) {
            // split the contract balance

            contractTokenBalance = minTokenNumberToSell;
            // approve contract
            _approve(
                address(this),
                address(uniswapRouter),
                contractTokenBalance
            );

            takeSellFee();
            uint256 totalPercent = _daoTax.add(_marketingTax).add(_devTax).add(
                takeBuyBackTax()
            );

            if (totalPercent > 0) {
                uint256 devisor = 1e3;
                uint256 buyBackPercent = takeBuyBackTax().mul(devisor).div(
                    totalPercent
                );
                uint256 daoPercent = _daoTax.mul(devisor).div(totalPercent);
                uint256 marketingPercent = _marketingTax.mul(devisor).div(
                    totalPercent
                );
                uint256 devPercent = _devTax.mul(devisor).div(totalPercent);

                swapTokensForETH(contractTokenBalance);

                uint256 deltaBalance = getContractBalance();

                totalPercent = daoPercent
                    .add(marketingPercent)
                    .add(devPercent)
                    .add(buyBackPercent);

                // tax transfers
                if (isBuyBackTaxEnabled) {
                    tempBuyBackWallet.transfer(
                        deltaBalance.mul(buyBackPercent).div(totalPercent)
                    );
                }

                daoWallet.transfer(
                    deltaBalance.mul(daoPercent).div(totalPercent)
                );
                marketingWallet.transfer(
                    deltaBalance.mul(marketingPercent).div(totalPercent)
                );
                devWallet.transfer(
                    deltaBalance.mul(devPercent).div(totalPercent)
                );
            }
        }
    }

    function swapTokensForETH(uint256 tokenAmount) internal lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        // make the swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}