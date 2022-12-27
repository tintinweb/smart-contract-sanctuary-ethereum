/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

/**
Telegram: https://t.me/build_alpha
Website: https://www.buildalpha.io
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
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

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Counters {
    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

contract Ownable {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
     
    function createPair(address tokenA, address tokenB) external returns (address pair);
 }

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
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external returns (uint amountToken, uint amountETH); 
}

library SignedSafeMath {
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

library SafeCast {
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(
            value <= type(uint224).max,
            "SafeCast: value doesn't fit in 224 bits"
        );
        return uint224(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(
            value <= type(uint128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return uint128(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(
            value <= type(uint96).max,
            "SafeCast: value doesn't fit in 96 bits"
        );
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(
            value <= type(uint64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(
            value <= type(uint32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(
            value <= type(uint16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(
            value <= type(uint8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(
            value <= uint256(type(int256).max),
            "SafeCast: value doesn't fit in an int256"
        );
        return int256(value);
    }
}


contract ALPHA is ERC20, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    string private constant _name = "BUILD ALPHA";
    string private constant _symbol = "ALPHA";
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1e12 * 10**18;

    IUniswapV2Router02 private uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    bool private tradingOpen = false;
    uint256 private launchBlock = 0;
    address private uniswapV2Pair;

    mapping(address => bool) private automatedMarketMakerPairs;
    mapping(address => bool) public isExcludeFromFee;
    mapping(address => bool) public isBot;
    mapping(address => bool) public isExcludeFromMaxWalletAmount;

    uint256 public maxWalletAmount;

    uint256 public baseBuyTax = 5;
    uint256 public baseSellTax = 5;

    uint256 private autoLP = 20;
    uint256 private dev1Fee = 35;
    uint256 private dev2Fee = 20;
    uint256 private marketingFee = 25;

    uint256 public minContractTokensToSwap = 1e9 * 10**18;

    mapping(address => uint256) public initialBuyTimestamp;

    address private dev1WalletAddress;
    address private dev2WalletAddress;
    address private marketingWalletAddress;

    event BuyFees(address from, address to, uint256 amountTokens);
    event SellFees(address from, address to, uint256 amountTokens);
    event AddLiquidity(uint256 amountTokens, uint256 amountEth);
    event SwapTokensForEth(uint256 sentTokens, uint256 receivedEth);
    event SwapEthForTokens(uint256 sentEth, uint256 receivedTokens);
    event DistributeFees(uint256 dev1Eth, uint256 dev2Eth, uint256 remarketingEth);


    constructor(
        address _dev1WalletAddress,
        address _dev2WalletAddress,
        address _marketingWalletAddress
    ) ERC20(_name, _symbol) {
        dev1WalletAddress = _dev1WalletAddress;
        dev2WalletAddress = _dev2WalletAddress;
        marketingWalletAddress = _marketingWalletAddress;

        maxWalletAmount = (_tTotal * 5) / 10000; // 0.05% maxWalletAmount (initial limit)

        isExcludeFromFee[owner()] = true;
        isExcludeFromFee[address(this)] = true;
        isExcludeFromFee[dev1WalletAddress] = true;
        isExcludeFromFee[dev2WalletAddress] = true;
        isExcludeFromFee[marketingWalletAddress] = true;
        isExcludeFromMaxWalletAmount[owner()] = true;
        isExcludeFromMaxWalletAmount[address(this)] = true;
        isExcludeFromMaxWalletAmount[address(uniswapV2Router)] = true;
        isExcludeFromMaxWalletAmount[dev1WalletAddress] = true;
        isExcludeFromMaxWalletAmount[dev2WalletAddress] = true;
        isExcludeFromMaxWalletAmount[marketingWalletAddress] = true;

        _mint(owner(), _tTotal);

    }

    /**
     * @dev Function to recover any ETH sent to Contract by Mistake.
    */
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{ value: address(this).balance }(
            ""
        );
    }

    /**
     * @dev Function to recover any ERC20 Tokens sent to Contract by Mistake.
    */
    function recoverAnyERC20TokensFromContract(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "ALPHA: Trading is already open");
        uint256 _launchTime;
        
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        isExcludeFromMaxWalletAmount[address(uniswapV2Pair)] = true;

        automatedMarketMakerPairs[uniswapV2Pair] = true;

        addLiquidity(balanceOf(address(this)), address(this).balance);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        tradingOpen = true;
        _launchTime = block.timestamp;
        launchBlock = block.number;
    }

    function manualSwap() external onlyOwner {
        uint256 totalTokens = balanceOf(address(this));

        swapTokensForEth(totalTokens);
    }

    function manualSend() external onlyOwner {
        uint256 totalEth = address(this).balance;

        uint256 dev1FeesToSend = totalEth.mul(dev1Fee).div(
            uint256(100).sub(autoLP)
        );
        uint256 dev2FeesToSend = totalEth.mul(dev2Fee).div(
            uint256(100).sub(autoLP)
        );
        uint256 marketingFeesToSend = totalEth.mul(marketingFee).div(
            uint256(100).sub(autoLP)
        );
        uint256 remainingEthForFees = totalEth.sub(dev1FeesToSend).sub(dev2FeesToSend).sub(marketingFeesToSend);
        dev1FeesToSend = dev1FeesToSend.add(remainingEthForFees);

        sendEthToWallets(dev1FeesToSend, dev2FeesToSend, marketingFeesToSend);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        require(!isBot[_from] && !isBot[_to]);

        uint256 transferAmount = _amount;
        if (
            tradingOpen &&
            (automatedMarketMakerPairs[_from] ||
                automatedMarketMakerPairs[_to]) &&
            !isExcludeFromFee[_from] &&
            !isExcludeFromFee[_to]
        ) {
             
            transferAmount = takeFees(_from, _to, _amount);
        }


        if (!automatedMarketMakerPairs[_to] && !isExcludeFromMaxWalletAmount[_to]) {
            require(balanceOf(_to) + transferAmount <= maxWalletAmount,
                "ALPHA: Wallet balance limit reached"
            );
        }

        super._transfer(_from, _to, transferAmount);

    }

    function _setAutomatedMarketMakerPair(address _pair, bool _value) private {
        require(
            automatedMarketMakerPairs[_pair] != _value,
            "ALPHA: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[_pair] = _value;
    }

    function _setLiquidityPair(address _pair, bool _value) external onlyOwner {
        require(
            automatedMarketMakerPairs[_pair] != _value,
            "ALPHA: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[_pair] = _value;
    }

    function setExcludeFromFee(address _address, bool _isExludeFromFee)
        external onlyOwner {
        isExcludeFromFee[_address] = _isExludeFromFee;
    }

    function setExcludeFromMaxWalletAmount(address _address, bool _isExludeFromMaxWalletAmount)
        external onlyOwner {
        isExcludeFromMaxWalletAmount[_address] = _isExludeFromMaxWalletAmount;
    }

    function setMaxWallet(uint256 newMaxWallet) external onlyOwner {
        require(newMaxWallet >= (totalSupply() * 1 / 1000)/1e18, "Cannot set maxWallet lower than 0.1%");
        maxWalletAmount = newMaxWallet * (10**_decimals);
    }
    

    function setTaxes(
        uint256 _baseBuyTax,
        uint256 _baseSellTax,
        uint256 _autoLP,
        uint256 _dev1Fee,
        uint256 _dev2Fee,
        uint256 _marketingFee
    ) external onlyOwner {
        require(_baseBuyTax <= 10 && _baseSellTax <= 10);

        baseBuyTax = _baseBuyTax;
        baseSellTax = _baseSellTax;
        autoLP = _autoLP;
        dev1Fee = _dev1Fee;
        dev2Fee = _dev2Fee;
        marketingFee = _marketingFee;
    }

    function setMinContractTokensToSwap(uint256 _numToken) public onlyOwner {
        minContractTokensToSwap = _numToken * (10**_decimals);
    }

    function setBots(address[] calldata _bots) public onlyOwner {
        for (uint256 i = 0; i < _bots.length; i++) {
            if (
                _bots[i] != uniswapV2Pair &&
                _bots[i] != address(uniswapV2Router)
            ) {
                isBot[_bots[i]] = true;
            }
        }
    }

    function setWalletAddress(address _dev1WalletAddress, address _dev2WalletAddress, address _marketingWalletAddress) external onlyOwner {
        dev1WalletAddress = _dev1WalletAddress;
        dev2WalletAddress = _dev2WalletAddress;
        marketingWalletAddress = _marketingWalletAddress;
    }

    function takeFees(
        address _from,
        address _to,
        uint256 _amount
    ) private returns (uint256) {
        uint256 fees;
        uint256 remainingAmount;
        require(
            automatedMarketMakerPairs[_from] || automatedMarketMakerPairs[_to],
            "ALPHA: No market makers found"
        );

        if (automatedMarketMakerPairs[_from]) {
            uint256 totalBuyTax;

            totalBuyTax = baseBuyTax;

            fees = _amount.mul(totalBuyTax).div(100);

            remainingAmount = _amount.sub(fees);

            super._transfer(_from, address(this), fees);

            emit BuyFees(_from, address(this), fees);
        } else {
            uint256 totalSellTax;
            
            totalSellTax = baseSellTax;

            fees = _amount.mul(totalSellTax).div(100);

            remainingAmount = _amount.sub(fees);

            super._transfer(_from, address(this), fees);
            uint256 tokensToSwap = balanceOf(address(this));

            if (tokensToSwap > minContractTokensToSwap) {
                distributeTokensEth(tokensToSwap);
            }

            emit SellFees(_from, address(this), fees);
        }

        return remainingAmount;
    }

    function distributeTokensEth(uint256 _tokenAmount) private {
        uint256 tokensForLiquidity = _tokenAmount.mul(autoLP).div(100);

        uint256 halfLiquidity = tokensForLiquidity.div(2);
        uint256 tokensForSwap = _tokenAmount.sub(halfLiquidity);

        uint256 totalEth = swapTokensForEth(tokensForSwap);

        uint256 ethForAddLP = totalEth.mul(autoLP).div(100);
        uint256 dev1FeesToSend = totalEth.mul(dev1Fee).div(100);
        uint256 dev2FeesToSend = totalEth.mul(dev2Fee).div(100);
        uint256 marketingFeesToSend = totalEth.mul(marketingFee).div(100);
        uint256 remainingEthForFees = totalEth
            .sub(ethForAddLP)
            .sub(dev1FeesToSend)
            .sub(dev2FeesToSend)
            .sub(marketingFeesToSend);
        dev1FeesToSend = dev1FeesToSend.add(remainingEthForFees);

        sendEthToWallets(dev1FeesToSend, dev2FeesToSend, marketingFeesToSend);

        if (halfLiquidity > 0 && ethForAddLP > 0) {
            addLiquidity(halfLiquidity, ethForAddLP);
        }
    }

    function sendEthToWallets(uint256 _dev1Fees, uint256 _dev2Fees, uint256 _marketingFees)
        private
    {
        if (_dev1Fees > 0) {
            payable(dev1WalletAddress).transfer(_dev1Fees);
        }
        if (_dev2Fees > 0) {
            payable(dev2WalletAddress).transfer(_dev2Fees);
        }
        if (_marketingFees > 0) {
            payable(marketingWalletAddress).transfer(_marketingFees);
        }
        emit DistributeFees(_dev1Fees, _dev2Fees, _marketingFees);
    }

    function swapTokensForEth(uint256 _tokenAmount) private returns (uint256) {
        uint256 initialEthBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 receivedEth = address(this).balance.sub(initialEthBalance);

        emit SwapTokensForEth(_tokenAmount, receivedEth);
        return receivedEth;
    }

    function swapEthForTokens(uint256 _ethAmount, address _to)
        private
        returns (uint256)
    {
        uint256 initialTokenBalance = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _ethAmount
        }(0, path, _to, block.timestamp);

        uint256 receivedTokens = balanceOf(address(this)).sub(
            initialTokenBalance
        );

        emit SwapEthForTokens(_ethAmount, receivedTokens);
        return receivedTokens;
    }

    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
        emit AddLiquidity(_tokenAmount, _ethAmount);
    }

    function availableContractTokenBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    receive() external payable {}
}