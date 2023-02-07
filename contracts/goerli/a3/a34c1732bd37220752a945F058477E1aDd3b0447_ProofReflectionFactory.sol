// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: None
pragma solidity = 0.8.17;

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;
}

// SPDX-License-Identifier: None
pragma solidity = 0.8.17;

interface IFACTORY {
    function factoryRevenue() external payable;
}

// SPDX-License-Identifier: None
pragma solidity = 0.8.17;

import "../libraries/ProofReflectionFactoryFees.sol";
interface IProofReflectionTokenCutter {
    function setBasicData(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply,
        uint percentToLP,
        address owner,
        address routerAddress,
        address initialProofAdmin,
        ProofReflectionFactoryFees.allFees memory fees
    ) external;
}

// SPDX-License-Identifier: None
pragma solidity = 0.8.17;

interface ITeamFinanceLocker {
    function lockToken(
        address _tokenAddress,
        address _withdrawalAddress,
        uint256 _amount,
        uint256 _unlockTime,
        bool _mintNFT
    ) external payable returns (uint256 _id);
}

// SPDX-License-Identifier: None
pragma solidity = 0.8.17;

interface ITokenCutter {
    function swapTradingStatus() external;

    function setLaunchedAt() external;

    function cancelToken() external;
}

// SPDX-License-Identifier: None
pragma solidity = 0.8.17;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// SPDX-License-Identifier: None
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

// SPDX-License-Identifier: None
pragma solidity = 0.8.17;

import "./Context.sol";

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

// SPDX-License-Identifier: None
pragma solidity = 0.8.17;

library ProofReflectionFactoryFees {
    struct allFees {
        uint256 reflectionFee;
        uint256 reflectionFeeOnSell;
        uint256 lpFee;
        uint256 lpFeeOnSell;
        uint256 devFee;
        uint256 devFeeOnSell;
    }
}

// SPDX-License-Identifier: None
pragma solidity = 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./libraries/Context.sol";
import "./libraries/Ownable.sol";
import "./libraries/ProofReflectionFactoryFees.sol";
import "./interfaces/ITeamFinanceLocker.sol";
import "./interfaces/ITokenCutter.sol";
import "./interfaces/IFACTORY.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IProofReflectionTokenCutter.sol";
import "./tokenCutters/ProofReflectionTokenCutter.sol";

contract ProofReflectionFactory is Ownable {
    struct proofToken {
        bool status;
        address pair;
        address owner;
        uint256 unlockTime;
        uint256 lockId;
    }

    struct tokenParam {
        string tokenName;
        string tokenSymbol;
        uint256 initialSupply;
        uint percentToLP;
        uint256 initialReflectionFee;
        uint256 initialReflectionFeeOnSell;
        uint256 initialLpFee;
        uint256 initialLpFeeOnSell;
        uint256 initialDevFee;
        uint256 initialDevFeeOnSell;
        uint256 unlockTime;
    }

    mapping(address => proofToken) public validatedPairs;

    address public proofAdmin;
    address public routerAddress;
    address public lockerAddress;
    address payable public revenueAddress;
    address payable public rewardPoolAddress;

    event TokenCreated(address _address);

    constructor(
        address initialRouterAddress,
        address initialLockerAddress,
        address initialRewardPoolAddress,
        address initialRevenueAddress
    ) {
        routerAddress = initialRouterAddress;
        lockerAddress = initialLockerAddress;
        proofAdmin = msg.sender;
        revenueAddress = payable(initialRevenueAddress);
        rewardPoolAddress = payable(initialRewardPoolAddress);
    }

    function createToken(
        tokenParam memory tokenParam_
    ) external payable {
        require(
            tokenParam_.unlockTime >= block.timestamp + 30 days,
            "unlock under 30 days"
        );
        require(msg.value >= 1 ether, "not enough liquidity");

        //create token

        ProofReflectionFactoryFees.allFees memory fees = ProofReflectionFactoryFees.allFees(
            tokenParam_.initialReflectionFee,
            tokenParam_.initialReflectionFeeOnSell,
            tokenParam_.initialLpFee,
            tokenParam_.initialLpFeeOnSell,
            tokenParam_.initialDevFee,
            tokenParam_.initialDevFeeOnSell
        );

        ProofReflectionTokenCutter newToken = new ProofReflectionTokenCutter();
        IProofReflectionTokenCutter(address(newToken)).setBasicData(
            tokenParam_.tokenName,
            tokenParam_.tokenSymbol,
            tokenParam_.initialSupply,
            tokenParam_.percentToLP,
            msg.sender,
            routerAddress,
            proofAdmin,
            fees
        );
        emit TokenCreated(address(newToken));

        //add liquidity
        newToken.approve(routerAddress, type(uint256).max);
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        router.addLiquidityETH{value: msg.value}(
            address(newToken),
            newToken.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 111
        );

        // disable trading
        newToken.swapTradingStatus();

        validatedPairs[address(newToken)] = proofToken(
            false,
            newToken.pair(),
            msg.sender,
            tokenParam_.unlockTime,
            0
        );
    }

    function finalizeToken(address tokenAddress) public payable {
        require(validatedPairs[tokenAddress].owner == msg.sender, "!owner");
        require(validatedPairs[tokenAddress].status == false, "validated");

        address _pair = validatedPairs[tokenAddress].pair;
        uint256 _unlockTime = validatedPairs[tokenAddress].unlockTime;
        IERC20(_pair).approve(lockerAddress, type(uint256).max);

        uint256 lpBalance = IERC20(_pair).balanceOf(address(this));

        uint256 _lockId = ITeamFinanceLocker(lockerAddress).lockToken{
            value: msg.value
        }(_pair, msg.sender, lpBalance, _unlockTime, false);
        validatedPairs[tokenAddress].lockId = _lockId;

        //enable trading
        ITokenCutter(tokenAddress).swapTradingStatus();
        ITokenCutter(tokenAddress).setLaunchedAt();

        validatedPairs[tokenAddress].status = true;
    }

    function cancelToken(address tokenAddress) public {
        require(validatedPairs[tokenAddress].owner == msg.sender, "!owner");
        require(validatedPairs[tokenAddress].status == false, "validated");

        address _pair = validatedPairs[tokenAddress].pair;
        address _owner = validatedPairs[tokenAddress].owner;

        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        IERC20(_pair).approve(routerAddress, type(uint256).max);
        uint256 _lpBalance = IERC20(_pair).balanceOf(address(this));

        // enable transfer and allow router to exceed tx limit to remove liquidity
        ITokenCutter(tokenAddress).cancelToken();
        router.removeLiquidityETH(
            address(tokenAddress),
            _lpBalance,
            0,
            0,
            _owner,
            block.timestamp
        );

        // disable transfer of token
        ITokenCutter(tokenAddress).swapTradingStatus();

        delete validatedPairs[tokenAddress];
    }

    function factoryRevenue() external payable virtual {
        if (address(this).balance >= 0) {
            uint256 bal = address(this).balance/2;
            revenueAddress.transfer(bal);
            rewardPoolAddress.transfer(bal);
        }
    }

    function setLockerAddress(address newlockerAddress) external onlyOwner {
        lockerAddress = newlockerAddress;
    }

    function setRouterAddress(address newRouterAddress) external onlyOwner {
        routerAddress = payable(newRouterAddress);
    }

    function setProofAdmin(address newProofAdmin) external onlyOwner {
        proofAdmin = newProofAdmin;
    }

    function setRevenueAddress(address newRevenueAddress) external onlyOwner {
        revenueAddress = payable(newRevenueAddress);
    }

    function setRewardPoolAddress(address newRewardPoolAddress) external onlyOwner {
        rewardPoolAddress = payable(newRewardPoolAddress);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: None
pragma solidity = 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../libraries/Ownable.sol";
import "../libraries/Context.sol";
import "../libraries/ProofReflectionFactoryFees.sol";
import "../interfaces/IFACTORY.sol";
import "../interfaces/IDividendDistributor.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";

contract ProofReflectionTokenCutter is Context, IERC20, IERC20Metadata {
    //This token was created with PROOF, and audited by Solidity Finance — https://proofplatform.io/projects
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 9;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address public proofAdmin;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;

    uint256 public launchedAt;
    uint256 public _proofFee = 2;

    uint256 public reflectionFee;
    uint256 public lpFee;
    uint256 public devFee;

    uint256 public reflectionFeeOnSell;
    uint256 public lpFeeOnSell;
    uint256 public devFeeOnSell;

    uint256 public totalFee;
    uint256 public totalFeeIfSelling;

    uint256 private txnCurrentTaxFee = 0;
    uint256 private txnCurrentReflectionFee = 0;

    uint256 public revenueFee = 2;

    IUniswapV2Router02 public router;
    address public pair;
    address public factory;
    address public tokenOwner;
    address payable public devWallet;

    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingStatus = true;

    mapping(address => bool) private bots;

    uint256 public _maxTxAmount;

    constructor() {
        factory = msg.sender;
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

    modifier onlyOwner() {
        require(tokenOwner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyFactory() {
        require(factory == _msgSender(), "Ownable: caller is not the factory");
        _;
    }

    function setBasicData(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply,
        uint percentToLP,
        address owner,
        address routerAddress,
        address initialProofAdmin,
        ProofReflectionFactoryFees.allFees memory fees
    ) external onlyFactory {
        _name = tokenName;
        _symbol = tokenSymbol;
        _tTotal += initialSupply;
        _rTotal = (MAX - (MAX % _tTotal));

        //Initial supply
        require (percentToLP >= 70, "low lp percent");
        uint256 forLP = (initialSupply * percentToLP) / 100; //95%
        uint256 forOwner = initialSupply - forLP; //5%

        _maxTxAmount = (initialSupply * 5) / 1000;

        router = IUniswapV2Router02(routerAddress);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _allowances[address(this)][address(router)] = MAX;

        isFeeExempt[address(this)] = true;
        isFeeExempt[factory] = true;

        isTxLimitExempt[owner] = true;
        isTxLimitExempt[factory] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

        reflectionFee = fees.reflectionFee;
        lpFee = fees.lpFee;
        devFee = fees.devFee;

        reflectionFeeOnSell = fees.reflectionFeeOnSell;
        lpFeeOnSell = fees.lpFeeOnSell;
        devFeeOnSell = fees.devFeeOnSell;

        totalFee = devFee + lpFee + revenueFee;
        totalFeeIfSelling = devFeeOnSell + lpFeeOnSell + revenueFee;

        require(totalFee <= 12, "Too high fee");
        require(totalFeeIfSelling <= 17, "Too high fee");

        tokenOwner = owner;
        devWallet = payable(owner);
        proofAdmin = initialProofAdmin;

        _rOwned[address(0)] += _rTotal;

        _transferStandard(address(0), _msgSender(), forLP);
        _transferStandard(address(0), owner, forOwner);

        emit Transfer(address(0), _msgSender(), forLP);
        emit Transfer(address(0), owner, forOwner);
    }

    //proofAdmin functions
    function updateProofAdmin(address newAdmin) public virtual onlyProofAdmin {
        proofAdmin = newAdmin;
    }

    function setBots(address[] memory bots_) external onlyProofAdmin {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    //Factory functions
    function swapTradingStatus() public onlyFactory {
        tradingStatus = !tradingStatus;
    }

    function setLaunchedAt() public onlyFactory {
        require(launchedAt == 0, "already launched");
        launchedAt = block.timestamp;
    }

    function cancelToken() public onlyFactory {
        isFeeExempt[address(router)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[tokenOwner] = true;
        tradingStatus = true;
    }

    function changeFees(
        uint256 initialReflectionFee,
        uint256 initialReflectionFeeOnSell,
        uint256 initialLpFee,
        uint256 initialLpFeeOnSell,
        uint256 initialDevFee,
        uint256 initialDevFeeOnSell
    ) external onlyOwner {
        reflectionFee = initialReflectionFee;
        lpFee = initialLpFee;
        devFee = initialDevFee;

        reflectionFeeOnSell = initialReflectionFeeOnSell;
        lpFeeOnSell = initialLpFeeOnSell;
        devFeeOnSell = initialDevFeeOnSell;

        totalFee = devFee + lpFee + revenueFee;
        totalFeeIfSelling = devFeeOnSell + lpFeeOnSell + revenueFee;

        require(totalFee <= 12, "Too high fee");
        require(totalFeeIfSelling <= 17, "Too high fee");
    }

    function reduceProofFee() external onlyOwner {
        require(revenueFee == 2, "!already reduced");
        require(launchedAt != 0, "!launched");
        require(block.timestamp >= launchedAt + 72 hours, "too soon");

        revenueFee = 1;
        totalFee = devFee + lpFee + revenueFee;
        totalFeeIfSelling = devFeeOnSell + lpFeeOnSell + revenueFee;
    }

    function formatProofFee() external onlyProofAdmin {
        require (revenueFee > 0, "already reduced");
        require(launchedAt != 0, "!launched");
        require(block.timestamp >= launchedAt + 72 hours, "too soon");

        totalFee -= revenueFee;
        totalFeeIfSelling -= revenueFee;
        revenueFee = 0;
        
    }

    function changeTxLimit(uint256 newLimit) external onlyOwner {
        require(launchedAt != 0, "!launched");
        require(newLimit >= (_tTotal * 5) / 1000, "Mmin 0.5% limit");
        require(block.timestamp >= launchedAt + 24 hours, "too soon");
        _maxTxAmount = newLimit;
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

    function setDevWallet(address payable newDevWallet) external onlyOwner {
        devWallet = payable(newDevWallet);
    }

    function changeSwapBackSettings(bool enableSwapBack) external onlyOwner {
        swapAndLiquifyEnabled = enableSwapBack;
    }

    function delBot(address notbot) external {
        address sender = _msgSender();
        require (sender == proofAdmin || sender == tokenOwner, "Owanble: caller doesn't have permission");
        bots[notbot] = false;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return tokenFromReflection(_rOwned[account]);
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

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require (_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
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
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (
            sender != tokenOwner &&
            recipient != tokenOwner &&
            !isTxLimitExempt[recipient]
        ) {
            require(amount <= _maxTxAmount || isTxLimitExempt[sender], "tx");
            require(!bots[sender] && !bots[recipient]);

            if (
                sender == pair &&
                recipient != address(router) &&
                !isFeeExempt[recipient]
            ) {
                require(tradingStatus, "!trading");
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwapAndLiquify && sender != pair && tradingStatus) {
                if (contractTokenBalance > 0) {
                    if (
                        contractTokenBalance > balanceOf(pair) * 5 / 100
                    ) {
                        contractTokenBalance = balanceOf(pair) * 5 / 100;
                    }
                    swapTokensForEth(contractTokenBalance);
                }
            }
        }

        if (isFeeExempt[sender] || isFeeExempt[recipient]) {
            txnCurrentTaxFee = 0;
            txnCurrentReflectionFee = 0;
        } else if (recipient == pair) {
            txnCurrentTaxFee = totalFeeIfSelling;
            txnCurrentReflectionFee = reflectionFeeOnSell;
        } else if (sender == pair) {
            txnCurrentTaxFee = totalFee;
            txnCurrentReflectionFee = reflectionFee;
        } else {
            txnCurrentTaxFee = 0;
            txnCurrentReflectionFee = reflectionFee;
        }

        _transferStandard(sender, recipient, amount);

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

    function _takeDev(uint256 tDev) private {
        uint256 currentRate = _getRate();
        uint256 rDev = tDev * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rDev;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tDev
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tDev) = _getTValues(
            tAmount,
            txnCurrentReflectionFee,
            txnCurrentTaxFee
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tDev,
            currentRate
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tDev);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 _taxFee,
        uint256 _devFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount * _taxFee / 100;
      uint256 tDev = tAmount * _devFee / 100;
        uint256 tTransferAmount = tAmount - tFee - tDev;
        return (tTransferAmount, tFee, tDev);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tDev,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rDev = tDev * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rDev;
        return (rAmount, rTransferAmount, rFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        uint256 tokensToLiquify = tokenAmount;

        uint256 amountToLiquify = tokensToLiquify * lpFee / totalFee / 2;

        uint256 amountToSwap = tokensToLiquify - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;

        uint256 devBalance = amountETH * devFee / totalFee;
        uint256 revenueBalance = amountETH * revenueFee / totalFee;

        uint256 amountEthLiquidity = amountETH * lpFee / totalFee / 2;

        if (amountETH > 0) {
            IFACTORY(factory).factoryRevenue{value: revenueBalance}();
            (bool sent,)=devWallet.call{value:devBalance}("");
            require (sent, "ETH transfer failed");
        }

        if (amountToLiquify > 0) {
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