/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// File contracts/libraries/Context.sol

// SPDX-License-Identifier: None
pragma solidity = 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File contracts/libraries/ProofNonReflectionTokenFees.sol

pragma solidity = 0.8.17;

library ProofNonReflectionTokenFees {
    struct allFees {
        uint256 mainFee;
        uint256 mainFeeOnSell;
        uint256 lpFee;
        uint256 lpFeeOnSell;
    }
}


// File contracts/interfaces/IFACTORY.sol

pragma solidity = 0.8.17;

interface IFACTORY {
    function factoryRevenue() external payable;
}


// File contracts/interfaces/IUniswapV2Router02.sol

pragma solidity = 0.8.17;

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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}


// File contracts/libraries/Ownable.sol

pragma solidity = 0.8.17;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/interfaces/IUniswapV2Factory.sol

pragma solidity = 0.8.17;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File contracts/ProofNonReflectiveToken.sol

pragma solidity = 0.8.17;

contract ProofNonReflectionToken is Context, IERC20, IERC20Metadata {
    //This token was created with PROOF, and audited by Solidity Finance https://proofplatform.io/projects
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private constant _name = 'Dope Coin';
    string private constant _symbol = 'DOPE';

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address public proofAdmin;

    bool public restrictWhales = true;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;

    uint256 public launchedAt;
    uint256 public proofFee = 2;

    uint256 public mainFee;
    uint256 public lpFee;

    uint256 public mainFeeOnSell;
    uint256 public lpFeeOnSell;

    uint256 public totalFee;
    uint256 public totalFeeIfSelling;

    IUniswapV2Router02 public router;
    address public pair;
    address public tokenOwner;
    address public deployer;
    address private factory;
    address payable public mainWallet;

    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingStatus = false;

    mapping(address => bool) public bots;

    uint256 public _maxTxAmount;
    uint256 public _walletMax;
    uint256 public swapThreshold;

    constructor(
        uint percentToLP,
        address owner,
        address factory_,
        address main,
        address initialProofAdmin
        ) {
        deployer = msg.sender;
        factory = factory_;
        _totalSupply = 420000000 * 1e9;

        //Tx & Wallet Limits
        require (percentToLP >= 70, "low lp percent");
        _maxTxAmount = _totalSupply;
        _walletMax = _totalSupply;
        swapThreshold = _totalSupply;

        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        isFeeExempt[address(this)] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[owner] = true;

        isTxLimitExempt[owner] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

        //Fees
        mainFee = 3;
        lpFee = 1;

        mainFeeOnSell = 6;
        lpFeeOnSell = 1;

        totalFee = lpFee + proofFee + mainFee;
        totalFeeIfSelling = lpFeeOnSell +proofFee + mainFeeOnSell;

        require(totalFee <= 12, "Too high fee");
        require(totalFeeIfSelling <= 17, "Too high sell fee");

        tokenOwner = owner;
        mainWallet = payable(main);
        proofAdmin = initialProofAdmin;

        //Initial supply
        uint256 forLP = (_totalSupply * percentToLP) / 100; //95%
        uint256 forOwner = _totalSupply - forLP; //5%

        _balances[msg.sender] += forLP;
        _balances[owner] += forOwner;

        emit Transfer(address(0), msg.sender, forLP);
        emit Transfer(address(0), owner, forOwner);
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyProofAdmin() {
        require(
            proofAdmin == _msgSender(),
            "Ownable: caller is not the proofAdmin"
        );
        _;
    }

    modifier onlyDeployer() {
        require(
            deployer == _msgSender(),
            "Ownable: caller is not the deployer"
        );
        _;
    }

    modifier onlyOwner() {
        require(tokenOwner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    //proofAdmin functions
    function updateProofAdmin(address newAdmin) external virtual onlyProofAdmin {
        proofAdmin = newAdmin;
    }

    function setBots(address[] memory bots_) external onlyProofAdmin {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    //Factory functions
    function swapTradingStatus() external onlyDeployer {
        _maxTxAmount = (_totalSupply * 1) / 1000;
        _walletMax = (_totalSupply * 1) / 1000;
        swapThreshold = (_totalSupply * 5) / 4000;
        setLaunchedAt();
        tradingStatus = !tradingStatus;
    }

    function postLaunchMaxes() external onlyDeployer {
        _maxTxAmount = (_totalSupply * 5) / 1000;
        _walletMax = (_totalSupply * 1) / 100;
    }

    function renounceDeployerAddress() external onlyDeployer {
      deployer = address(0);
    }

    function setLaunchedAt() internal {
        require(launchedAt == 0, "already launched");
        launchedAt = block.timestamp;
    }

    function cancelToken() external onlyProofAdmin {
        isFeeExempt[address(router)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[tokenOwner] = true;
        tradingStatus = true;
    }

    //Owner functions
    function changeFees(
        uint256 initialMainFee,
        uint256 initialMainFeeOnSell,
        uint256 initialLpFee,
        uint256 initialLpFeeOnSell
    ) external onlyOwner {
        mainFee = initialMainFee;
        lpFee = initialLpFee;

        mainFeeOnSell = initialMainFeeOnSell;
        lpFeeOnSell = initialLpFeeOnSell;

        totalFee = lpFee + proofFee + mainFee;
        totalFeeIfSelling = lpFeeOnSell +proofFee + mainFeeOnSell;

        require(totalFee <= 12, "Too high fee");
        require(totalFeeIfSelling <= 17, "Too high fee");
    }

    function changeTxLimit(uint256 newLimit) external onlyOwner {
        require(launchedAt != 0, "!launched");
        require(newLimit >= (_totalSupply * 5) / 1000, "Mmin 0.5% limit");
        require(newLimit <= (_totalSupply * 3) / 100, "Max 3% limit");
        _maxTxAmount = newLimit;
    }

    function changeWalletLimit(uint256 newLimit) external onlyOwner {
        require(launchedAt != 0, "!launched");
        require(newLimit >= (_totalSupply * 5) / 1000, "Mmin 0.5% limit");
        require(newLimit <= (_totalSupply * 3) / 100, "Max 3% limit");
        _walletMax = newLimit;
    }

    function changeRestrictWhales(bool newValue) external onlyOwner {
        require(launchedAt != 0, "!launched");
        require(block.timestamp >= launchedAt + 24 hours, "too soon");
        restrictWhales = newValue;
    }

    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isTxLimitExempt[holder] = exempt;
    }

    function reduceProofFee() external onlyOwner {
        require(proofFee == 2, "!already reduced");
        require(launchedAt != 0, "!launched");
        require(block.timestamp >= launchedAt + 72 hours, "too soon");

        proofFee = 1;
        totalFee = lpFee + proofFee + mainFee;
        totalFeeIfSelling = lpFeeOnSell + proofFee + mainFeeOnSell;
    }

    function formatProofFee() external onlyProofAdmin {
        require (proofFee > 0, "already reduced");
        require(launchedAt != 0, "!launched");
        require(block.timestamp >= launchedAt + 72 hours, "too soon");

        totalFee -= proofFee;
        totalFeeIfSelling -= proofFee;
        proofFee = 0;
    }

    function setMainWallet(address payable newMainWallet) external onlyOwner {
        mainWallet = newMainWallet;
    }

    function setOwnerWallet(address payable newOwnerWallet) external onlyOwner {
        tokenOwner = newOwnerWallet;
    }

    function changeSwapBackSettings(
        bool enableSwapBack,
        uint256 newSwapBackLimit
    ) external onlyOwner {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function delBot(address notbot) external {
        address sender = _msgSender();
        require (sender == proofAdmin || sender == tokenOwner, "Owanble: caller doesn't have permission");
        bots[notbot] = false;
    }

    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() external view virtual override returns (uint8) {
        return 9;
    }
    function totalSupply() external view virtual override returns (uint256) {
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
        external
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
        external
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
    ) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
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
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if(isFeeExempt[sender] || isFeeExempt[recipient] || inSwapAndLiquify){
            return _basicTransfer(sender, recipient, amount);
         } else { 
            return _taxedTransfer(sender,recipient,amount);                  
        }
    }

    function _taxedTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(!bots[sender] && !bots[recipient]);
        require(tradingStatus, "Trading Closed");

        if (!isTxLimitExempt[recipient] && restrictWhales) {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "Max TX Amount"
        );
        }

        if (!isTxLimitExempt[recipient] && restrictWhales && recipient != pair) {
            require(
                _balances[recipient] + amount <= _walletMax,
                "Max Wallet Amount"
            );
        }

        if (
            sender != pair &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            _balances[address(this)] >= swapThreshold
        ) {
            swapBack();
        }

        _balances[sender] = _balances[sender] - amount;
        uint256 finalAmount = amount;

        if (sender == pair || recipient == pair) {
            finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient]
                ? takeFee(sender, recipient, amount)
                : amount;
        }
        
        _balances[recipient] = _balances[recipient] + finalAmount;

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
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

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeApplicable = pair == recipient
            ? totalFeeIfSelling
            : totalFee;
        uint256 feeAmount = amount * feeApplicable / 100;

        _balances[address(this)] = _balances[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function swapBack() internal lockTheSwap {
        uint256 tokensToLiquify = _balances[address(this)];

        uint256 amountToLiquify;
        uint256 proofBalance;
        uint256 amountEthLiquidity;

        // Use sell ratios if buy tax too low
        if (totalFee <= 2) {
            amountToLiquify = tokensToLiquify * lpFeeOnSell / totalFeeIfSelling / 2;
        } else {
            amountToLiquify = tokensToLiquify * lpFee / totalFee / 2;
        }

        uint256 amountToSwap = tokensToLiquify - amountToLiquify;

        _allowances[address(this)][address(router)] = amountToSwap;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;

        // Use sell ratios if buy tax too low
        if (totalFee <= 2) {
            proofBalance = amountETH * proofFee / totalFeeIfSelling;
            amountEthLiquidity = amountETH * lpFeeOnSell / totalFeeIfSelling / 2;
        } else {
            proofBalance = amountETH * proofFee / totalFee;
            amountEthLiquidity = amountETH * lpFee / totalFee / 2;
        }

        uint256 amountEthMain = amountETH - proofBalance - amountEthLiquidity;

        if (amountETH > 0) {
            IFACTORY(factory).factoryRevenue{value: proofBalance}();
            (bool sent1,)=mainWallet.call{value:amountEthMain}("");
            require (sent1, "ETH transfer failed");
        }

        if (amountToLiquify > 0) {
            _allowances[address(this)][address(router)] = amountToLiquify;
            router.addLiquidityETH{value: amountEthLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                0x000000000000000000000000000000000000dEaD,
                block.timestamp 
            );
        }
    }

    receive() external payable {}
}