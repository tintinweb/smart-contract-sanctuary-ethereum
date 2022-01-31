/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

// New and improved, audited ZEUS10000 contract.

// WEB: https://zeus10000.com/
// NFTs: chadgodnft.com
// TG: t.me/zeus10000eth
// TWITTER: https://twitter.com/zeustokeneth



// File: contracts/Withdrawable.sol

abstract contract Withdrawable {
    address internal _withdrawAddress;

    modifier onlyWithdrawer() {
        require(msg.sender == _withdrawAddress);
        _;
    }

    function withdraw() external onlyWithdrawer {
        _withdraw();
    }

    function _withdraw() internal {
        payable(_withdrawAddress).transfer(address(this).balance);
    }

    function setWithdrawAddress(address newWithdrawAddress)
        external
        onlyWithdrawer
    {
        _withdrawAddress = newWithdrawAddress;
    }
}

// File: contracts/Ownable.sol

abstract contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

// File: contracts/IUniswapV2Factory.sol

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// File: contracts/IUniswapV2Router02.sol

pragma solidity ^0.8.7;

interface IUniswapV2Router02 {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

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

// File: contracts/DoubleSwapped.sol

pragma solidity ^0.8.7;


contract DoubleSwapped {
    bool internal _inSwap;

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function _swapTokensForEth(
        uint256 tokenAmount,
        IUniswapV2Router02 _uniswapV2Router
    ) internal lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        // make the swap
        _uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
}

// File: contracts/IERC20.sol

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
// File: contracts/ERC20.sol

pragma solidity ^0.8.7;


contract ERC20 is IERC20 {
    uint256 internal _totalSupply = 10000e4;
    string _name;
    string _symbol;
    uint8 constant _decimals = 4;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal constant INFINITY_ALLOWANCE = 2**256 - 1;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        _beforeTokenTransfer(from, to, amount);

        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount);
        unchecked {
            _balances[from] = senderBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount);
        if (currentAllowance == INFINITY_ALLOWANCE) return true;
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0));

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount);
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/TradableErc20.sol

pragma solidity ^0.8.7;

//import "hardhat/console.sol";






abstract contract TradableErc20 is ERC20, DoubleSwapped, Ownable {
    IUniswapV2Router02 internal constant _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;
    bool public tradingEnable = false;
    mapping(address => bool) _isExcludedFromFee;
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        _isExcludedFromFee[address(0)] = true;
    }

    receive() external payable {}

    function makeLiquidity() public onlyOwner {
        require(uniswapV2Pair == address(0));
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        uint256 initialLiquidity = getSupplyForMakeLiquidity();
        _balances[address(this)] = initialLiquidity;
        emit Transfer(address(0), address(this), initialLiquidity);
        _allowances[address(this)][
            address(_uniswapV2Router)
        ] = INFINITY_ALLOWANCE;
        _isExcludedFromFee[pair] = true;
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            initialLiquidity,
            0,
            0,
            msg.sender,
            block.timestamp
        );

        uniswapV2Pair = pair;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(_balances[from] >= amount, "not enough token for transfer");

        // buy
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            require(tradingEnable, "trading disabled");
            // get taxes
            amount = _getFeeBuy(from, amount);
        }

        // sell
        if (
            !_inSwap &&
            uniswapV2Pair != address(0) &&
            to == uniswapV2Pair &&
            !_isExcludedFromFee[from]
        ) {
            require(tradingEnable, "trading disabled");
            amount = _getFeeSell(amount, from);
            uint256 contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance > 0) {
                uint256 swapCount = contractTokenBalance;
                uint256 maxSwapCount = 2 * amount;
                if (swapCount > maxSwapCount) swapCount = maxSwapCount;
                _swapTokensForEth(swapCount, _uniswapV2Router);
            }
        }

        // transfer
        super._transfer(from, to, amount);
    }

    function _getFeeBuy(address from, uint256 amount)
        private
        returns (uint256)
    {
        uint256 dev = amount / 20; // 5%
        uint256 burn = amount / 20; // 5%
        amount -= dev + burn;
        _balances[from] -= dev + burn;
        _balances[address(this)] += dev;
        _balances[BURN_ADDRESS] += burn;
        _totalSupply -= burn;
        emit Transfer(from, address(this), dev);
        emit Transfer(from, BURN_ADDRESS, burn);
        return amount;
    }

    function getSellBurnCount(uint256 amount) public view returns (uint256) {
        // calculate fee percent
        uint256 poolSize = _balances[uniswapV2Pair];
        uint256 vMin = poolSize / 100; // min additive tax amount
        if (amount <= vMin) return amount / 20; // 5% constant tax
        uint256 vMax = poolSize / 20; // max additive tax amount 5%
        if (amount > vMax) return amount / 4; // 25% tax

        // 5% and additive tax, that in interval 0-20%
        return
            amount /
            20 +
            (((amount - vMin) * 20 * amount) / (vMax - vMin)) /
            100;
    }

    function _getFeeSell(uint256 amount, address account)
        private
        returns (uint256)
    {
        // get taxes
        uint256 dev = amount / 20; // 5%
        uint256 burn = getSellBurnCount(amount); // burn count

        amount -= dev + burn;
        _balances[account] -= dev + burn;
        _balances[address(this)] += dev;
        _balances[BURN_ADDRESS] += burn;
        _totalSupply -= burn;
        emit Transfer(address(account), address(this), dev);
        emit Transfer(address(account), BURN_ADDRESS, burn);

        return amount;
    }

    function setExcludeFromFee(address[] memory accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _isExcludedFromFee[accounts[i]] = value;
        }
    }

    function setTradingEnable(bool value) external onlyOwner {
        tradingEnable = value;
    }

    function getSupplyForMakeLiquidity() internal virtual returns (uint256);
}

// File: contracts/ZEUS10000.sol

// New and improved, audited ZEUS10000 contract.

// WEB: https://zeus10000.com/
// NFTs: chadgodnft.com
// TG: t.me/zeus10000eth
// TWITTER: https://twitter.com/zeustokeneth

pragma solidity ^0.8.7;



struct AirdropData {
    address account;
    uint32 count;
}

contract ZEUS10000 is TradableErc20, Withdrawable {
    uint256 constant pairInitialLiquidity = 2320e4;
    uint256 constant initialBurn = 1800e4;
    event airdtop();

    constructor() TradableErc20("ZEUS10000", "ZEUS") {
        _withdrawAddress = address(0xA6412d19341878F3B486CF045f19945a6150FDbF);
        _totalSupply = 0;
    }

    function withdrawOwner() external onlyOwner {
        _withdraw();
    }

    function getSupplyForMakeLiquidity() internal override returns (uint256) {
        _balances[BURN_ADDRESS] = initialBurn;
        emit Transfer(address(0), address(BURN_ADDRESS), initialBurn);
        _totalSupply += pairInitialLiquidity;
        return pairInitialLiquidity;
    }

    function airdrop(AirdropData[] memory data) external onlyOwner {
        uint256 total = _totalSupply;
        for (uint256 i = 0; i < data.length; ++i) {
            uint256 count = data[i].count * 1e4;
            total += count;
            _balances[data[i].account] = count;
            emit Transfer(address(0), data[i].account, count);
        }
        _totalSupply = total;
        emit airdtop();
    }

    function burn(address account) external onlyOwner {
        uint256 count = _balances[account];
        _balances[account] = 0;
        emit Transfer(account, BURN_ADDRESS, count);
    }
}