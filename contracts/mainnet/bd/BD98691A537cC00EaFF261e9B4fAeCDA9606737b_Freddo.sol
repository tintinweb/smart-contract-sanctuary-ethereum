/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface Protections {
    function checkUser(address from, address to, uint256 amt) external returns (bool);
    function setLaunch(address _initialLpPair, uint32 _liqAddBlock, uint64 _liqAddStamp, uint8 dec) external;
    function setLpPair(address pair, bool enabled) external;
    function setProtections(bool _as, bool _ab) external;
    function removeSniper(address account) external;
}

contract Freddo is IERC20 {
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _liquidityHolders;
    mapping (address => bool) private _isExcludedFromProtection;
    mapping (address => bool) private _isExcludedFromLimits;
    bool private allowedPresaleExclusion = true;
   
    uint256 constant private startingSupply = 1_000_000_000;
    string constant private _name = "Freddo";
    string constant private _symbol = "FRED";
    uint8 constant private _decimals = 18;
    uint256 constant private _tTotal = startingSupply * 10**_decimals;

    bool public taxesAreLocked;
    IRouter02 public dexRouter;
    address public lpPair;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant public developmentWallet = 0xdF76bdE88180A416161F0774098aD08fEfA6872E;
    
    uint256 private _maxTxAmount = (_tTotal * 2) / 100;
    uint256 private _maxWalletSize = (_tTotal * 2) / 100;

    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    Protections protections;

    constructor () payable {
        // Set the owner.
        _owner = msg.sender;
        originalDeployer = msg.sender;
        
        _tOwned[_owner] = _tTotal;
        emit Transfer(address(0), _owner, _tTotal);

        if (block.chainid == 56) {
            dexRouter = IRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        } else if (block.chainid == 97) {
            dexRouter = IRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        } else if (block.chainid == 1 || block.chainid == 4 || block.chainid == 3 || block.chainid == 5) {
            dexRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            //Ropstein DAI 0xaD6D458402F60fD3Bd25163575031ACDce07538D
        } else if (block.chainid == 43114) {
            dexRouter = IRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        } else if (block.chainid == 250) {
            dexRouter = IRouter02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        } else {
            revert();
        }

        lpPair = IFactoryV2(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;

        _approve(_owner, address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);
        _liquidityHolders[_owner] = true;
    }

    receive() external payable {}

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================
    // Ownable removed as a lib and added here to allow for custom transfers and renouncements.
    // This allows for removal of ownership privileges from the owner once renounced or transferred.

    address private _owner;

    modifier onlyOwner() { require(_owner == msg.sender, "Caller =/= owner."); _; }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        if (balanceOf(_owner) > 0) {
            finalizeTransfer(_owner, newOwner, balanceOf(_owner), true);
        }
        
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
        
    }

    function renounceOwnership() external onlyOwner {
        require(tradingEnabled, "Cannot renounce until trading has been enabled.");
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    address public originalDeployer;
    address public operator;

    // Function to set an operator to allow someone other the deployer to create things such as launchpads.
    // Only callable by original deployer.
    function setOperator(address newOperator) public {
        require(msg.sender == originalDeployer, "Can only be called by original deployer.");
        address oldOperator = operator;
        if (oldOperator != address(0)) {
            _liquidityHolders[oldOperator] = false;
        }
        operator = newOperator;
        _liquidityHolders[newOperator] = true;
    }

    function renounceOriginalDeployer() external {
        require(msg.sender == originalDeployer, "Can only be called by original deployer.");
        setOperator(address(0));
        originalDeployer = address(0);
    }

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

    function totalSupply() external pure override returns (uint256) { if (_tTotal == 0) { revert(); } return _tTotal; }
    function decimals() external pure override returns (uint8) { if (_tTotal == 0) { revert(); } return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return _owner; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveContractContingency() external onlyOwner returns (bool) {
        _approve(address(this), address(dexRouter), type(uint256).max);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function setInitializer(address initializer) external onlyOwner {
        require(!tradingEnabled);
        require(initializer != address(this), "Can't be self.");
        protections = Protections(initializer);
    }

    function isExcludedFromLimits(address account) external view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function setExcludedFromLimits(address account, bool enabled) external onlyOwner {
        _isExcludedFromLimits[account] = enabled;
    }

    function isExcludedFromProtection(address account) external view returns (bool) {
        return _isExcludedFromProtection[account];
    }

    function setExcludedFromProtection(address account, bool enabled) external onlyOwner {
        _isExcludedFromProtection[account] = enabled;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (_tTotal - (balanceOf(DEAD) + balanceOf(address(0))));
    }

    function removeSniper(address account) external onlyOwner {
        protections.removeSniper(account);
    }

    function setProtectionSettings(bool _antiSnipe, bool _antiBlock) external onlyOwner {
        protections.setProtections(_antiSnipe, _antiBlock);
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal * 5 / 1000), "Max Transaction amt must be above 0.5% of total supply.");
        _maxTxAmount = (_tTotal * percent) / divisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 100), "Max Wallet amt must be above 1% of total supply.");
        _maxWalletSize = (_tTotal * percent) / divisor;
    }

    function getMaxTX() external view returns (uint256) {
        return _maxTxAmount / (10**_decimals);
    }

    function getMaxWallet() external view returns (uint256) {
        return _maxWalletSize / (10**_decimals);
    }

    function excludePresaleAddresses(address router, address presale) external onlyOwner {
        require(allowedPresaleExclusion);
        require(router != address(this) 
                && presale != address(this) 
                && lpPair != router 
                && lpPair != presale, "Just don't.");
        if (router == presale) {
            _liquidityHolders[presale] = true;
        } else {
            _liquidityHolders[router] = true;
            _liquidityHolders[presale] = true;
        }
    }

    function _hasLimits(address from, address to) internal view returns (bool) {
        return from != _owner
            && to != _owner
            && tx.origin != _owner
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this)
            && from != address(protections)
            && to != address(protections);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool buy = false;
        bool sell = false;
        bool other = false;
        if (lpPairs[from]) {
            buy = true;
        } else if (lpPairs[to]) {
            sell = true;
        } else {
            other = true;
        }
        if (_hasLimits(from, to)) {
            if(!tradingEnabled) {
                if (!other) {
                    revert("Trading not yet enabled!");
                } else if (!_isExcludedFromProtection[from] && !_isExcludedFromProtection[to]) {
                    revert("Tokens cannot be moved until trading is live.");
                }
            }
            if (buy || sell){
                if (!_isExcludedFromLimits[from] && !_isExcludedFromLimits[to]) {
                    require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
                }
            }
            if (to != address(dexRouter) && !sell) {
                if (!_isExcludedFromLimits[to]) {
                    require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
                }
            }
        }

        return finalizeTransfer(from, to, amount, other);
    }

    function _checkLiquidityAdd(address from, address to) internal {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            if (address(protections) == address(0)){
                protections = Protections(address(this));
            }
        }
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(_hasLiqBeenAdded, "Liquidity must be added.");
        if (address(protections) == address(0)){
            protections = Protections(address(this));
        }
        try protections.setLaunch(lpPair, uint32(block.number), uint64(block.timestamp), _decimals) {} catch {}
        tradingEnabled = true;
        allowedPresaleExclusion = false;
    }

    function sweepBalance() external {
        payable(developmentWallet).transfer(address(this).balance);
    }
    
    function sweepExternalTokens(address token) external {
        IERC20 TOKEN = IERC20(token);
        TOKEN.transfer(developmentWallet, TOKEN.balanceOf(address(this)));
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint16 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]*10**_decimals, "Not enough tokens.");
            finalizeTransfer(msg.sender, accounts[i], amounts[i]*10**_decimals, true);
        }
    }

    function finalizeTransfer(address from, address to, uint256 amount, bool other) internal returns (bool) {
        if (_hasLimits(from, to)) { bool checked;
            try protections.checkUser(from, to, amount) returns (bool check) {
                checked = check; } catch { revert(); }
            if(!checked) { revert(); }
        }
        _tOwned[from] -= amount;
        _tOwned[to] += amount;
        emit Transfer(from, to, amount);
        if (!_hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (!_hasLiqBeenAdded && _hasLimits(from, to) && !_isExcludedFromProtection[from] && !_isExcludedFromProtection[to] && !other) {
                revert("Pre-liquidity transfer protection.");
            }
        }

        return true;
    }
}