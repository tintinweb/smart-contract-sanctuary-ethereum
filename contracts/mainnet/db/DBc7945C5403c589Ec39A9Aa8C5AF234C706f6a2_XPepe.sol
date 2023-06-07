/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

//                           $XPEPE XPepe
//███╗░░██╗░█████╗░████████╗░█████╗░███╗░░██╗░█████╗░███╗░░██╗██╗░░░██╗███╗░░░███╗░█████╗░██╗░░░██╗░██████╗
//████╗░██║██╔══██╗╚══██╔══╝██╔══██╗████╗░██║██╔══██╗████╗░██║╚██╗░██╔╝████╗░████║██╔══██╗██║░░░██║██╔════╝
//██╔██╗██║██║░░██║░░░██║░░░███████║██╔██╗██║██║░░██║██╔██╗██║░╚████╔╝░██╔████╔██║██║░░██║██║░░░██║╚█████╗░
//██║╚████║██║░░██║░░░██║░░░██╔══██║██║╚████║██║░░██║██║╚████║░░╚██╔╝░░██║╚██╔╝██║██║░░██║██║░░░██║░╚═══██╗
//██║░╚███║╚█████╔╝░░░██║░░░██║░░██║██║░╚███║╚█████╔╝██║░╚███║░░░██║░░░██║░╚═╝░██║╚█████╔╝╚██████╔╝██████╔╝
//╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚═╝░░╚══╝░░░╚═╝░░░╚═╝░░░░░╚═╝░╚════╝░░╚═════╝░╚═════╝░
//                                 (t.me/NotAnonymousLaunches)
// 
// 
// t.me/XPepeLaunch
// https://www.xpepe.me/
//
// Buy here (https://beta.x7.finance)
// 
// Safe Contracts. Anti Bot. 
//
// (All Launches will start with a 20% Buy/Sell Fee, and a max transaction/wallet limit to prevent bots and snipers.)
// (Fees will eventually be reduced to 0%, walletlimitations disabled and the Contract renounced.)
// 
// Trade on your own risk. I just provide SAFE Contracts.
//

// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
 
abstract contract Ownable {
    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor() {
        _transferOwnership(msg.sender);
    }
 
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
 
    function owner() public view virtual returns (address) {
        return _owner;
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
 
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
 
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }
 
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
 
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
 
interface IERC20Metadata is IERC20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
}
 
contract ERC20 is IERC20, IERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
 
    constructor(string memory name_, string memory symbol_) {
        _symbol = symbol_;
        _name = name_;
    }
 
    function name() public view virtual override returns (string memory) {
        return _name;
    }
 
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
 
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
 
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
 
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
 
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }
 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }
 
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
 
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
 
        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
 
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
 
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }
 
        emit Transfer(from, to, amount);
    }
 
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
 
        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }
 
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
 
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }
 
        emit Transfer(account, address(0), amount);
    }
 
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}
 
interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
 
interface IPair {
    function mint(address to) external returns (uint liquidity);
}
 
interface IRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
 
interface IWETH is IERC20 {
    function deposit() external payable;
}
 
interface IX7InitialLiquidityLoanTerm {}
 
interface ILendingPool {
 
    function getInitialLiquidityLoan(
        address tokenAddress,
        uint256 amount,
        address loanTermContract,
        uint256 loanAmount,
        uint256 loanDurationSeconds,
        address liquidityReceiver,
        uint256 deadline
    ) external payable returns (uint256 loanID);
 
    function getDiscountedQuote(
        address borrower,
        IX7InitialLiquidityLoanTerm loanTerm,
        uint256 loanAmount,
        uint256 loanDurationSeconds
    ) external view returns (uint256[7] memory);
 
    function payLiability(uint256 loanID) external payable;
    function liquidationReward() external view returns (uint256);
    function getRemainingLiability(uint256 loanID) external view returns (uint256);
}
 
contract XPepe is ERC20, Ownable {
 
    bool public launched;
    bool public limitsEnabled;
    bool public loanSatisfied;
    bool public feesEnabled;
 
    uint256 public buyFeeNumerator;
    uint256 public sellFeeNumerator;
    uint256 public maxTxnAmount;
    uint256 public maxWalletAmount;
 
    uint256 public disableLimitsTimestamp;
 
    uint256 public feeTokens;
    uint256 public feesCollected;
    uint256 public maxFeesToCollect;
    uint256 public loanPayoffFraction;
 
    address public liquidationAMM;
    address public feeRecipient;
    address public weth;
    IRouter public router;
    ILendingPool public lendingPool;
 
    uint256 public loanID;
 
    uint256 private startTradingBlockNumber;
    bool private inFeeLiquidation = false;
 
    receive() external payable {}
 
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) Ownable() ERC20(name, symbol) {
        _mint(address(this), supply);
        feeRecipient = msg.sender;
    }
 
    function setFeeRecipient(address feeRecipient_) external {
        require(msg.sender == owner() || msg.sender == feeRecipient);
        feeRecipient = feeRecipient_;
    }
 
    function disableLimits() external onlyOwner {
        require(limitsEnabled);
        limitsEnabled = false;
    }
 
    function setFees(uint256 _buyFeeNumerator, uint256 _sellFeeNumerator) public onlyOwner {
        require(_buyFeeNumerator <= buyFeeNumerator && _sellFeeNumerator <= sellFeeNumerator);
        buyFeeNumerator = _buyFeeNumerator;
        sellFeeNumerator = _sellFeeNumerator;
        if (buyFeeNumerator + sellFeeNumerator == 0) {
            feesEnabled = false;
        }
    }
 
    function _transfer(address from, address to, uint256 amount) internal override {
        if (amount == 0 || inFeeLiquidation || !launched) {
            super._transfer(from, to, amount);
            return;
        }
 
        // Sell
        if (to == liquidationAMM) {
            if (feeTokens > 0) {
                inFeeLiquidation = true;
                swapTokensForEth(feeTokens);
                feeTokens = 0;
                inFeeLiquidation = false;
            }
 
            if (feesEnabled) {
                uint256 feeAmount = amount * sellFeeNumerator / 10000;
                if (feeAmount > 0) {
                    amount = amount - feeAmount;
                    super._transfer(from, address(this), feeAmount);
                    feeTokens += feeAmount;
                }
            }
 
            if (!loanSatisfied && address(this).balance > 0) {
                lendingPool.payLiability{value: address(this).balance / loanPayoffFraction}(loanID);
                if (lendingPool.getRemainingLiability(loanID) == 0) {
                    loanSatisfied = true;
                }
            }
 
            if (address(this).balance > 0) {
                if (feesCollected >= maxFeesToCollect) {
                    setFees(0, 0);
                } else {
                    // Will not revert on failure to prevent accidental honeypot
                    (bool success,) = feeRecipient.call{value: address(this).balance}("");
                    if (success) {
                        feesCollected += address(this).balance;
                    }                    
                }   
            }
        }
 
        // Buy
        if (from == liquidationAMM && feesEnabled) {
            uint256 feeAmount = amount * buyFeeNumerator / 10000;
            if (feeAmount > 0) {
                amount = amount - feeAmount;
                super._transfer(from, address(this), feeAmount);
                feeTokens += feeAmount;
            }
        }
 
        if (limitsEnabled) {
            require(amount <= maxTxnAmount);
            if (to != liquidationAMM) {
                require(amount + balanceOf(to) <= maxWalletAmount);
            }
 
            if (block.timestamp > disableLimitsTimestamp) {
                limitsEnabled = false;
            } else {
                require(block.number >= startTradingBlockNumber);
            }
        }
 
        super._transfer(from, to, amount);
    }
 
    function airdrop(address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        uint256 excessTokens = balanceOf(address(this)) - feeTokens;
 
        for (uint256 i; i<addresses.length; i++) {
            super._transfer(address(this), addresses[i], amounts[i]);
            excessTokens -= amounts[i];
        }
    }
 
    function quoteLaunchValue(
        address lendingPoolAddress,
        address loanTermAddress,
        uint256 loanAmount,
        uint256 loanDuration
    ) external view returns (uint256) {
        ILendingPool pool = ILendingPool(lendingPoolAddress);
 
        uint256[7] memory quote = pool.getDiscountedQuote(
            address(this),
            IX7InitialLiquidityLoanTerm(loanTermAddress),
            loanAmount,
            loanDuration
        );
 
        uint256 originationFee = quote[3];
        uint256 liquidationReward = pool.liquidationReward();
 
        return originationFee + liquidationReward;
    }
 
    function launch(
        // lendingPool, loanTerm, router
        address[3] memory addressConfig,
        // Token Amount, Loan amount, loan duration seconds, payoff fraction (2 = 1/2, 3 = 1/3 etc.)
        uint256[4] memory loanConfig,
        // Buy, sell, maxFeesToCollect
        uint256[3] memory feeConfig,
        // Txn, wallet, block delay, limitSeconds
        uint256[4] memory limitConfig
    ) external payable onlyOwner {
 
        require(loanConfig[0] <= balanceOf(address(this)), "Insufficient tokens");
 
        lendingPool = ILendingPool(addressConfig[0]);
 
        uint256[7] memory quote = lendingPool.getDiscountedQuote(
            address(this),
            IX7InitialLiquidityLoanTerm(addressConfig[1]),
            loanConfig[1],  // Amount
            loanConfig[2]   // Duration
        );
 
        uint256 originationFee = quote[3];
        uint256 liquidationReward = lendingPool.liquidationReward();
 
        _approve(address(this), addressConfig[0], balanceOf(address(this)));
 
        require(originationFee + liquidationReward <= address(this).balance, "Insufficient ETH");
 
        loanID = lendingPool.getInitialLiquidityLoan{value: originationFee + liquidationReward}(
            address(this),
            loanConfig[0],     // Token Amount
            addressConfig[1],  // Loan Term Address
            loanConfig[1],     // Loan Amount
            loanConfig[2],     // Loan Duration
            msg.sender,
            block.timestamp
        );
 
        loanPayoffFraction = loanConfig[3];
 
        router = IRouter(addressConfig[2]);
        weth = router.WETH();
 
        IFactory factory = IFactory(router.factory());
        liquidationAMM = factory.getPair(address(this), router.WETH());
 
        buyFeeNumerator = feeConfig[0];
        sellFeeNumerator = feeConfig[1];
 
        maxTxnAmount = limitConfig[0];
        maxWalletAmount = limitConfig[1];
 
        startTradingBlockNumber = block.number + limitConfig[2];
        disableLimitsTimestamp = block.timestamp + limitConfig[3];
 
        feesEnabled = true;
        limitsEnabled = true;
        maxFeesToCollect = feeConfig[2];
        launched = true;
    }
 
    function swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = weth;
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}