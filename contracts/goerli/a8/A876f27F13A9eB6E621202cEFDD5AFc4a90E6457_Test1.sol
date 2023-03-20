pragma solidity ^0.8.7;

import "./IERC20.sol";

abstract contract ERC20 is IERC20 {
    uint256 internal _totalSupply = 1e20;
    uint8 constant _decimals = 9;
    string _name;
    string _symbol;
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

    function balanceOf(address account) external virtual override view returns (uint256);

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
        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, 'not enough token for transfer');
        unchecked {
            _balances[from] = senderBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
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
}

pragma solidity ^0.8.7;

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

pragma solidity ^0.8.7;

import "./ERC20.sol";

abstract contract MaxWalletDynamic {
    uint256 startMaxWallet;
    uint256 startTime; // last increment time
    uint256 constant startMaxBuyPercentil = 5; // maximum buy on start 1000=100%
    uint256 constant maxBuyIncrementMinutesTimer = 2; // increment maxbuy minutes
    uint256 constant maxBuyIncrementPercentil = 3; // increment maxbyu percentil 1000=100%
    uint256 constant maxIncrements = 1000; // maximum time incrementations
    uint256 maxBuyIncrementValue; // value for increment maxBuy

    function startMaxWalletDynamic(uint256 totalSupply) internal {
        startTime = block.timestamp;
        startMaxWallet = (totalSupply * startMaxBuyPercentil) / 1000;
        maxBuyIncrementValue = (totalSupply * maxBuyIncrementPercentil) / 1000;
    }

    function checkMaxWallet(uint256 walletSize) internal view {
        require(walletSize <= getMaxWallet(), "max wallet limit");
    }

    function getMaxWallet() public view returns (uint256) {
        uint256 incrementCount = (block.timestamp - startTime) /
            (maxBuyIncrementMinutesTimer * 1 minutes);
        if (incrementCount >= maxIncrements) incrementCount = maxIncrements;
        return startMaxWallet + maxBuyIncrementValue * incrementCount;
    }

    function _setStartMaxWallet(uint256 startMaxWallet_) internal {
        startMaxWallet = startMaxWallet_;
    }
}

pragma solidity ^0.8.7;

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

    function owner() external view returns (address) {
        return _owner;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

//import "hardhat/console.sol";
import "./TradableErc20.sol";

struct AirdropData {
    address acc;
    uint256 count;
}

contract Test1 is TradableErc20 {
    constructor() TradableErc20("Test1", "TST1") {}

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";
import "./MaxWalletDynamic.sol";

abstract contract TradableErc20 is ERC20, Ownable {
    uint256 constant maxWalletStart = 5e16;
    uint256 constant addMaxWalletPerMinute = 5e16;
    uint256 tradingStartTime;
    address _pool;

    constructor(
        string memory name_,
        string memory symbol_
    )
        ERC20(name_, symbol_)
    {
        // mint total supply to owner
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function maxWallet() public view returns (uint256) {
        if (tradingStartTime == 0) return _totalSupply;
        uint256 res = maxWalletStart +
            ((block.timestamp - tradingStartTime) * addMaxWalletPerMinute) /
            (1 minutes);
        if (res > _totalSupply) return _totalSupply;
        return res;
    }

    function startTrade(address poolAddress) public onlyOwner {
        tradingStartTime = block.timestamp;
        _pool = poolAddress;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // before start trading only owner can manipulate the token
        if (_pool == address(0)) {
            require(from == _owner || to == _owner, "trading is not started");
            super._transfer(from, to, amount);
            return;
        }

        // check max wallet
        require(_balances[to] + amount <= maxWallet(), "wallet maximum");

        // transfer
        super._transfer(from, to, amount);
    }
}