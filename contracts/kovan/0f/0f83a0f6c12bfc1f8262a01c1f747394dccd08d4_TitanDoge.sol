/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IPancakeRouter {
    function WETH() external pure returns (address);

    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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

contract TitanDoge is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    string private constant _name = "Titan Doge";
    string private constant _symbol = "TDOGE";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000 * 10**9 * 10**_decimals;

    address payable private _developmentAddress =
        payable(0xf7E566C01d1c102Ed0360447E188f01b581Bd3Bd);
    address payable private _marketingAddress =
        payable(0xC655A6fDA27145CF8890978ff88Fb1213383Cff7);
    address payable private _buyBackAddress =
        payable(0x4674404B75df5354B5cbA1aAAC6d64e5f5ba470d);

    uint256 public buyTax = 9;
    uint256 public sellTax = 9;

    uint256 public liquidityShare = 2;
    uint256 public marketingShare = 4;
    uint256 public buyBackShare = 2;
    uint256 public developmentShare = 2;
    uint256 public totalShare = 10;

    address public pairAddress;
    uint256 private _minimumTokensBeforeSwap = 1000000 * 10**_decimals;
    bool _inSwapAndLiquify = false;

    IPancakeRouter _router =
        IPancakeRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    modifier onlyDev() {
        require(
            owner() == _msgSender() || _developmentAddress == _msgSender(),
            "Caller is not developer"
        );
        _;
    }

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor() {
        _balances[_msgSender()] = _totalSupply;

        pairAddress = IPancakeFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_developmentAddress] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_buyBackAddress] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function rescueTokenInContract(
        address tokenAddress,
        address to,
        uint256 amount
    ) public onlyDev {
        IERC20(tokenAddress).transfer(to, amount);
    }

    function rescueBNBInContract(address payable to, uint256 amount)
        public
        onlyDev
    {
        to.transfer(amount);
    }

    function setTax(uint256 bTax, uint256 sTax) public onlyDev {
        require(bTax < 16, "Buy tax exceed limit 15%");
        require(sTax < 16, "Sell tax exceed limit 15%");
        buyTax = bTax;
        sellTax = sTax;
    }

    function setTaxDistribution(
        uint256 lqShare,
        uint256 mktShare,
        uint256 devShare,
        uint256 bbShare
    ) public onlyDev {
        require(lqShare % 2 == 0, "Liquidity share must be divisible by 2");
        liquidityShare = lqShare;
        marketingShare = mktShare;
        developmentShare = devShare;
        buyBackShare = bbShare;
        totalShare =
            liquidityShare +
            marketingShare +
            developmentShare +
            buyBackShare;
    }

    function setNewDevAddress(address payable newAddress) public onlyDev {
        _developmentAddress = newAddress;
        _isExcludedFromFee[_developmentAddress] = true;
    }

    function setNewMarketingAddress(address payable newAddress) public onlyDev {
        _marketingAddress = newAddress;
        _isExcludedFromFee[_marketingAddress] = true;
    }

    function setNewBuyBackAddress(address payable newAddress) public onlyDev {
        _buyBackAddress = newAddress;
        _isExcludedFromFee[_buyBackAddress] = true;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
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

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
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
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        _balances[sender] = senderBalance - amount;
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            _minimumTokensBeforeSwap;

        bool takeFee = true;

        if (_inSwapAndLiquify) {
            takeFee = false;
        } else if (overMinimumTokenBalance && sender != pairAddress) {
            swapAndLiquify(contractTokenBalance);
        }

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }

        if (recipient != pairAddress && sender != pairAddress) {
            takeFee = false;
        }

        if (recipient == pairAddress && takeFee) {
            uint256 sellFee = (amount * sellTax) / 100;
            _balances[address(this)] = _balances[address(this)] + sellFee;
            emit Transfer(sender, address(this), sellFee);
            amount = amount - sellFee;
        }

        if (sender == pairAddress && takeFee) {
            uint256 buyFee = (amount * buyTax) / 100;
            _balances[address(this)] = _balances[address(this)] + buyFee;
            emit Transfer(sender, address(this), buyFee);
            amount = amount - buyFee;
        }

        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

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

    receive() external payable {}

    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approve(address(this), address(_router), tokenAmount);

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(_router), tokenAmount);

        _router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        uint256 tokensForLiquidity = (tAmount * liquidityShare) /
            2 /
            totalShare;

        uint256 tokensForSwap = tAmount - tokensForLiquidity;

        swapTokensForBNB(tokensForSwap);

        uint256 amountReceived = address(this).balance;

        uint256 totalBNBShare = totalShare - liquidityShare / 2;

        uint256 amountBNBBuyBack = (amountReceived * buyBackShare) /
            totalBNBShare;

        uint256 amountBNBDevelopment = (amountReceived * developmentShare) /
            totalBNBShare;

        uint256 amountBNBMarketing = (amountReceived * marketingShare) /
            totalBNBShare;

        uint256 amountBNBLiquidity = amountReceived -
            amountBNBBuyBack -
            amountBNBDevelopment -
            amountBNBMarketing;

        if (amountBNBMarketing > 0)
            _marketingAddress.transfer(amountBNBMarketing);

        if (amountBNBBuyBack > 0) _buyBackAddress.transfer(amountBNBBuyBack);

        if (amountBNBDevelopment > 0)
            _developmentAddress.transfer(amountBNBDevelopment);

        if (amountBNBLiquidity > 0 && tokensForLiquidity > 0)
            addLiquidity(tokensForLiquidity, amountBNBLiquidity);
    }
}