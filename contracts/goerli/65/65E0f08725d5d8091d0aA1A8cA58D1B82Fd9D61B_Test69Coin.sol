/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

//
//
//.##...##...####....####...##..##..######..#####....####...##..##..#####...######..##..##.
//.###.###..##..##..##......##.##...##......##..##..##......##..##..##..##..##......##.##..
//.##.#.##..######...####...####....####....##..##...####...######..#####...####....####...
//.##...##..##..##......##..##.##...##......##..##......##..##..##..##..##..##......##.##..
//.##...##..##..##...####...##..##..######..#####....####...##..##..##..##..######..##..##.
//
//


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
}

interface IWETH is IERC20 {
    function deposit() external payable;
}

contract Test69Coin is ERC20, Ownable {

    // Cannot be unset. Useful for DEX pairs and CEX wallets.
    mapping (address => bool) isLimitExempt;

    uint256 public maxTxnAmount = type(uint256).max;
    uint256 public txnLimitDenominator = 10000;
    uint256 public txnLimitNumerator;

    // Cannot be set lower than 0.5% of supply
    uint256 public minTxnLimitNumerator = 50;

    uint256 public maxWalletAmount = type(uint256).max;
    uint256 public walletLimitDenominator = 10000;
    uint256 public walletLimitNumerator;

    // Cannot be set lower than 1% of supply
    uint256 public minWalletLimitNumerator = 100;

    bool public limitsEnabled;
    uint256 earliestBlock;



    bool private inFeeLiquidation = false;
    bool public feesEnabled;
    uint256 public collectedFees;

    uint256 public buyFeeNumerator;
    uint256 public sellFeeNumerator;

    address public liquidationAMM;
    address public feeRecipient;
    address public weth;
    IRouter public router;

    receive() external payable {}

    constructor() Ownable() ERC20("Test", "TEST") {
        _mint(address(this), 10**12 * 10**18);
    }

    function setIsLimitExempt(address _contract) external onlyOwner {
        isLimitExempt[_contract] = true;
    }

    function setTxnLimit(uint256 numerator) external onlyOwner {
        require(numerator >= minTxnLimitNumerator);
        txnLimitNumerator = numerator;
        maxTxnAmount = totalSupply() * numerator  / txnLimitDenominator;
    }

    function setWalletLimit(uint256 numerator) external onlyOwner {
        require(numerator >= minWalletLimitNumerator);
        walletLimitNumerator = numerator;
        maxWalletAmount = totalSupply() * numerator / walletLimitDenominator;
    }

    function toggleLimits() external onlyOwner {
        limitsEnabled = !limitsEnabled;
    }

    function permanentlyDisableFees() external onlyOwner {
        require(!feesEnabled);
        feesEnabled = false;
    }

    function setFees(uint256 _buyFeeNumerator, uint256 _sellFeeNumerator) external onlyOwner {
        require(_buyFeeNumerator <= buyFeeNumerator && _sellFeeNumerator <= sellFeeNumerator);
        buyFeeNumerator = _buyFeeNumerator;
        sellFeeNumerator = _sellFeeNumerator;
    }


    function _transfer(address from, address to, uint256 amount) internal override {
        if (amount == 0 || inFeeLiquidation) {
            super._transfer(from, to, amount);
            return;
        }

        if (limitsEnabled && from != address(this)) {
            // Enforce TXN limit
            require(amount <= maxTxnAmount, "Exceeded Max TXN Limit");

            // Enforce Wallet Limit
            if (!isLimitExempt[to]) {
                require(amount + balanceOf(to) <= maxWalletAmount, "Exceeded Max Wallet Limit");
            }

            // Enforce block delay
            require(block.number >= earliestBlock, "No trading before liquidity add cooldown");
        }

        // Sell
        if (to == liquidationAMM) {
            if (collectedFees > 0) {
                inFeeLiquidation = true;
                swapTokensForEth(collectedFees);
                collectedFees = 0;
                inFeeLiquidation = false;
            }

            if (feesEnabled) {
                uint256 feeAmount = amount * sellFeeNumerator / 100;
                amount = amount - feeAmount;
                super._transfer(from, address(this), feeAmount);
                collectedFees += feeAmount;
            }
        }

        // Buy
        if (from == liquidationAMM && feesEnabled) {
            uint256 feeAmount = amount * buyFeeNumerator / 100;
            amount = amount - feeAmount;
            super._transfer(from, address(this), feeAmount);
            collectedFees += feeAmount;
        }

        

        super._transfer(from, to, amount);
    }

    function launch(
        address _router,
        address AMM,
        address _weth,
        uint256 _delay,
        uint256 launchTokenAmount,
        address lpReceiver,
        address _feeRecipient,
        uint256 _buyFeeNumerator,
        uint256 _sellFeeNumerator,
        uint256 _maxTxnNumerator,
        uint256 _maxWalletNumerator
    ) external payable onlyOwner {
        require(launchTokenAmount <= balanceOf(address(this)));

        router = IRouter(_router);
        liquidationAMM = AMM;
        isLimitExempt[AMM] = true;
        weth = _weth;

        limitsEnabled = true;
        feesEnabled = true;

        buyFeeNumerator = _buyFeeNumerator;
        sellFeeNumerator = _sellFeeNumerator;

        txnLimitNumerator = _maxTxnNumerator;
        maxTxnAmount = totalSupply() * _maxTxnNumerator  / txnLimitDenominator;

        walletLimitNumerator = _maxWalletNumerator;
        maxWalletAmount = totalSupply() * _maxWalletNumerator / walletLimitDenominator;

        feeRecipient = _feeRecipient;

        // Token Reserves for Operations
        super._transfer(address(this), _feeRecipient, 70000000000000000000000000000);



        // Deposit WETH for liquidity
        IWETH WETH = IWETH(_weth);
        WETH.deposit{value: msg.value}();

        // Transfer launchTokenAmount tokens to the pool
        super._transfer(address(this), AMM, launchTokenAmount);

        // Transfer initial liquidity into the AMM
        WETH.transfer(AMM, msg.value);

        // Mint LP tokens to the LP Receiver
        IPair(AMM).mint(lpReceiver);

        // Set the earliestBlock to annoy snipers.
        earliestBlock = block.number + _delay;
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
            feeRecipient,
            block.timestamp
        );
    }
}