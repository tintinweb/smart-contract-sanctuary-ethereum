//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
}



contract Test is IERC20 {
    address public owner;

    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    uint256 public purchaseTimeLockEnd;

    IUniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;

    string private constant NAME = "Test";
    string private constant SYMBOL = "TEST";
    uint8 private constant DECIMALS = 18;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Error: Caller is not the contract owner");
        _;
    }

    constructor(uint256 amount, uint256 timelock) {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        purchaseTimeLockEnd = timelock;

        totalSupply = amount;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
        owner = msg.sender;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return allowances[holder][spender];
    }

    function name() external pure returns (string memory) {
        return NAME;
    }

    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function renounceOwnership() external virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(
            allowances[sender][msg.sender] >= amount,
            "Error: insufficient allowance."
        );
        allowances[sender][msg.sender] -= amount;

        return _transfer(sender, recipient, amount);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transfer(msg.sender, recipient, amount);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        require(
            sender != address(0) && recipient != address(0)
        );

        uint256 senderBalance = balances[sender];
        require(
            senderBalance >= amount
        );
        if (sender == uniswapV2Pair && block.timestamp < purchaseTimeLockEnd) {
            revert(
                "Error: Purchase from Uniswap DEX"
            );
        }
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}