/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: Unlicensed

/* 
Welcome frens,

I created a new kind of tokenomic. I hope you’ll accept it as a refreshing trading experience.
It’s 0% fees in and out.
One can sell only if he is one of the last 3 buyers (Min 0,2%)
Max tx : 1%
I would change the values according to the price variation.
Have fun

----------------------------------------------------------------
Lore:
Shiberus the three headed Shiba is the guardian of Trinidoge's liquidity.
Each one of his heads allows one sell at a time, forcing most jeets and paperhands to stay onboard.
One can sell only if he his within the last 3 buyers of the token. If so, Shiberus will let you sell for a fair price.

----------------------------------------------------------------
Useful links:

Telegram: https://t.me/trinidogeportal
Website: https://trinidoge.com/ 
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
        require(owner() == _msgSender(), "Ownable: caller is not allowed");
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

contract Token is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint256 MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
    string private constant _name = "Trinidoge";
    string private constant _symbol = "3D";
    uint8 private constant _decimals = 9;

    address[] private _snipers;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isSniper;
    mapping(address => bool) private _liquidityHolders;
    mapping(address => bool) private bots;
    uint256 _totalSupply = 1000000000 * 10**9;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint8 private _unFreezeIndex = 0;
    address[3] public unFreezeArray;

    bool public tradingOpen = false;
    bool sniperProtection = true;

    uint256 public wipeBlocks = 1;
    uint256 public launchedAt;
    uint256 public unFreezeAmount = _totalSupply / 500; // 0.2%
    uint256 public _maxTxAmount = _totalSupply / 100; // 1%
    uint256 public _maxWalletSize = _totalSupply / 50; // 2%

    event MaxTxAmountUpdated(uint256 _maxTxAmount);

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
        _liquidityHolders[msg.sender] = true;

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

    function setSniperProtection(bool _sniperProtection) public onlyOwner {
        sniperProtection = _sniperProtection;
    }

    function byeByeSnipers() public onlyOwner {
        if (_snipers.length > 0) {
            uint256 oldContractBalance = _balances[address(this)];
            for (uint256 i = 0; i < _snipers.length; i++) {
                _balances[address(this)] = _balances[address(this)].add(
                    _balances[_snipers[i]]
                );
                emit Transfer(
                    _snipers[i],
                    address(this),
                    _balances[_snipers[i]]
                );
                _balances[_snipers[i]] = 0;
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
                owner(),
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

            if (sniperProtection) {
                if (
                    launchedAt > 0 &&
                    from == uniswapV2Pair &&
                    !_liquidityHolders[from] &&
                    !_liquidityHolders[to]
                ) {
                    if (block.number - launchedAt <= wipeBlocks) {
                        if (!_isSniper[to]) {
                            _snipers.push(to);
                        }
                        _isSniper[to] = true;
                    }
                }
            }

            // Transfer or Buy
            if (to != uniswapV2Pair) {
                require(
                    balanceOf(to) + amount < _maxWalletSize,
                    "TOKEN: Balance exceeds wallet size!"
                );
                // Buy
                if (
                    from == uniswapV2Pair &&
                    amount >= unFreezeAmount &&
                    !isUnFreezed(from)
                ) {
                    pushUnfreezed(to);
                }
            } else if (
                // Sell
                to == uniswapV2Pair
            ) {
                require(
                    isUnFreezed(from),
                    "TOKEN: You can't sell because you are freezed !"
                );
            }
        }

        _transferNoTax(from, to, amount);
    }

    function pushUnfreezed(address _unfreezed) private {
        nextUnfreezedIndex();
        unFreezeArray[_unFreezeIndex] = _unfreezed;
    }

    function nextUnfreezedIndex() private {
        _unFreezeIndex = _unFreezeIndex + 1 > 2 ? 0 : _unFreezeIndex + 1;
    }

    function isUnFreezed(address _addr) public view returns (bool) {
        for (uint256 idx = 0; idx < unFreezeArray.length; idx++) {
            if (unFreezeArray[idx] == _addr) {
                return true;
            }
        }
        return false;
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
        sniperProtection = true;
        launchedAt = block.number;
    }

    function blockBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function airdrop(address[] calldata recipients, uint256[] calldata amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            _transferNoTax(msg.sender, recipients[i], amount[i]);
        }
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

    receive() external payable {}

    function transferOwnership(address newOwner) public override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
        _isExcludedFromFee[owner()] = true;
    }

    function setMaxTxnAmount(uint256 maxTxNumerator) public onlyOwner {
        _maxTxAmount = (maxTxNumerator * _totalSupply) / 1000;
    }

    function setUnfreezeAmount(uint256 unFreezeNumerator) public onlyOwner {
        unFreezeAmount = (unFreezeNumerator * _totalSupply) / 1000;
    }

    function setMaxWalletSize(uint256 maxWalletNumerator) public onlyOwner {
        _maxWalletSize = (maxWalletNumerator * _totalSupply) / 1000;
    }

    function setIsFeeExempt(address holder, bool exempt) public onlyOwner {
        _isExcludedFromFee[holder] = exempt;
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