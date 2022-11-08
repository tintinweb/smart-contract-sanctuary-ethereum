/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

pragma solidity ^0.8.1;
pragma abicoder v2;
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
interface ISwapPair {
    function token0() external view returns (address);
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}
interface ISwapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
contract LGP is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint256 private _minTotalSupply;
    string private _name;
    string private _symbol;
    uint256 public priceOld;
    uint256 public priceBlock = block.number;
    address public manager;
    address public store;
    address public stake;
    address public aLGP;
    address public usdt;
    address public swapPair;
    ISwapRouter private _swapRouter;
    bool _inSwapAndLiquify;
    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
    function setManager(address account) public {
        if (manager == msg.sender) {
            manager = account;
        }
    }
    function setPair(address pair) public {
        if (manager == msg.sender) {
            swapPair = pair;
        }
    }
    function setAddress(
        address _store,
        address _stake,
        address _aLGP
    ) public {
        if (manager == msg.sender) {
            store = _store;
            stake = _stake;
            aLGP = _aLGP;
        }
    }
    constructor() {
        _name = "LGP DAO";
        _symbol = "LGP";
        store = 0xb068006FAAD615ac7b23E9Ec189bE3AD9f3cEFa5;
        stake = 0x1Df6Bcef949B52192D04923d59e630f7F5ca5E88;
        aLGP = 0xd26343cA2E35a4dc97d15178A326EF794e1126a8;
        manager = 0x1Df6Bcef949B52192D04923d59e630f7F5ca5E88;
        address admin = 0xbd9851fA8fB221644e1DE756296F1E296fb85C78;
        usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        _swapRouter = ISwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _mint(admin, 1_0000_0000 * 1e18);
    }
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
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
        address owner = msg.sender;
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
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
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
    event LogMsgSender(address account, address account1, address account2);
    function _transfer(
        address from,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        address to = recipient;
        if (0x0000000000000000000000000000000000000001 == recipient)
            to = address(0);
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        if (
            to == swapPair &&
            !_inSwapAndLiquify &&
            balanceOf(address(this)) > getAutoSwapMin(10 * 1e18)
        ) {
            _swapAndLiquify();
        }
        if (_inSwapAndLiquify || from == address(this) || to == address(this)) {
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        } else if (swapPair == from) {
            _updatePrice();
            uint256 every = amount / 1000;
            _balances[address(this)] += every * 15;
            emit Transfer(from, address(this), every * 15);
            _balances[manager] += every * 4;
            emit Transfer(from, manager, every * 4);
            _balances[stake] += every;
            emit Transfer(from, stake, every);
            _balances[to] += amount - (every * 20);
            emit Transfer(from, to, amount - (every * 20));
        } else if (swapPair == to) {
            _updatePrice();
            uint256 every = amount / 1000;
            _balances[address(this)] += every * 15;
            emit Transfer(from, address(this), every * 15);
            _balances[aLGP] += every * 5;
            emit Transfer(from, aLGP, every * 5);
            uint256 amountFinal = amount - (every * 20);
            uint256 price = getPrice();
            if (price < (priceOld * 50) / 100) {
                _balances[address(this)] += every * 30;
                emit Transfer(from, address(this), every * 30);
                _balances[address(0)] += every * 300;
                emit Transfer(from, address(0), every * 300);
                amountFinal = amountFinal - (every * 330);
            } else if (price < (priceOld * 70) / 100) {
                _balances[address(this)] += every * 30;
                emit Transfer(from, address(this), every * 30);
                _balances[address(0)] += every * 150;
                emit Transfer(from, address(0), every * 150);
                amountFinal = amountFinal - (every * 180);
            } else if (price < (priceOld * 80) / 100) {
                _balances[address(this)] += every * 30;
                emit Transfer(from, address(this), every * 30);
                _balances[address(0)] += every * 70;
                emit Transfer(from, address(0), every * 70);
                amountFinal = amountFinal - (every * 100);
            }
            _balances[to] += amountFinal;
            emit Transfer(from, to, amountFinal);
        } else {
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }
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
    function _burn(address account, uint256 amount)
        internal
        virtual
        returns (bool)
    {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _balances[address(0)] += amount;
        }
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
        return true;
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
    function _setMinTotalSupply(uint256 amount) internal {
        _minTotalSupply = amount;
    }
    function getAutoSwapMin(uint256 minNum) public view returns (uint256) {
        uint256 price = getPrice();
        if (price == 0) return minNum;
        return (10e18 * 1e6) / price;
    }
    function getPrice() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        (uint256 reserve1, uint256 reserve2, ) = ISwapPair(swapPair)
            .getReserves();
        if (reserve1 == 0 || reserve2 == 0) {
            return 0;
        } else {
            return _swapRouter.getAmountsOut(1 * 10**decimals(), path)[1];
        }
    }
    function _updatePrice() private {
        if (priceBlock > 0 && block.number > priceBlock) {
            priceBlock = block.number + 28800;
            priceOld = getPrice();
        } else if (priceBlock > 0 && getPrice() > priceOld) {
            priceOld = getPrice();
        }
    }
    function _swapAndLiquify() private lockTheSwap {
        uint256 amount = balanceOf(address(this));
        if (amount > 0) {
            address token0 = ISwapPair(swapPair).token0();
            (uint256 reserve0, uint256 reserve1, ) = ISwapPair(swapPair)
                .getReserves();
            if (reserve0 > 0 && reserve1 > 0) {
                uint256 tokenPool = reserve0;
                if (token0 != address(this)) tokenPool = reserve1;
                if (amount > tokenPool / 100) {
                    amount = tokenPool / 100;
                }
                _swapTokensForETH(amount);
            }
        }
    }
    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = usdt;
        path[2] = _swapRouter.WETH();
        _approve(address(this), address(_swapRouter), tokenAmount);
        _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            store,
            block.timestamp
        );
        emit SwapTokensForETH(tokenAmount, path);
    }
    event SwapTokensForETH(uint256 tokenAmount, address[] path);
}