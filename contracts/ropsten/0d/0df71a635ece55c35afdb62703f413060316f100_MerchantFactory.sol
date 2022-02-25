/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAffiliatePool {
    /**
     * deposit affiliate fee
     * _account: affiliator wallet address
     * _amount: deposit amount
     */
    function deposit(address _account, uint256 _amount) external returns (bool);

    /**
     * withdraw affiliate fee
     * withdraw sender's affiliate fee to sender address
     * _amount: withdraw amount. withdraw all amount if _amount is 0
     */
    function withdraw(uint256 _amount) external returns (bool);

    /**
     * get affiliate fee balance
     * _account: affiliator wallet address
     */
    function balanceOf(address _account) external view returns (uint256);


    /**
     * initialize contract (only owner)
     * _tokenAddress: token contract address of affiliate fee
     */
    function initialize(address _tokenAddress) external;

    /**
     * transfer ownership (only owner)
     * _account: wallet address of new owner
     */
    function transferOwnership(address _account) external;

    /**
     * recover wrong tokens (only owner)
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external;

    /**
     * @dev called by the owner to pause, triggers stopped state
     * deposit, withdraw method is suspended
     */
    function pause() external;

    /**
     * @dev called by the owner to unpause, untriggers stopped state
     * deposit, withdraw method is enabled
     */
    function unpause() external;
}

// File: contracts\libs\IStakingPool.sol

pragma solidity ^0.8.0;

interface IStakingPool {
    function balanceOf(address _account) external view returns (uint256);

    function getShare(address _account) external view returns (uint256);
}

// File: contracts\libs\IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


abstract contract MerchantSharedProperty is Ownable {
    enum FeeMethod {
        SIMPLE,
        LIQU,
        AFLIQU
    }

    enum SharedProperty {
        FEE_MAX_PERCENT,
        FEE_MIN_PERCENT,
        DONATION_FEE,
        TRANSACTION_FEE,
        WEB3_BALANCE_FOR_FREE_TX,
        MIN_AMOUNT_TO_PROCESS_FEE,
        MARKETING_WALLET,
        DONATION_WALLET,
        WEB3_TOKEN,
        AFFILIATE_POOL,
        STAKING_POOL,
        MAIN_SWAP_ROUTER,
        SWAP_ROUTERS
    }
    mapping(SharedProperty => bool) private propSelfUpdates; // Property is updated in the contract itself

    mapping(address => bool) private payTokenBlcklist; // List of tokens can not be used for paying
    mapping(address => bool) private recTokenWhitelist; // list of tokens can be used for receiving

    // Merchant factory contract address
    address public MERCHANT_FACTORY;

    uint16 private feeMaxPercent; // FEE_MAX default 0.5%
    uint16 private feeMinPercent; // FEE_MIN default 0.1%

    uint16 private donationFee; // Donation fee default 0.15%
    uint16 public constant MAX_TRANSACTION_FEE = 1000; // Max transacton fee 10%
    uint16 private transactionFee; // Transaction fee multiplied by 100, default 0.5%

    uint256 private web3BalanceForFreeTx; // If any wallet has 1000 Web3 tokens, it will be exempted from the transaction fee
    uint256 private minAmountToProcessFee; // When there is 1 BNB staked, fee will be processed

    address payable private marketingWallet; // Marketing address
    address payable private donationWallet; // Donation wallet

    IAffiliatePool private affiliatePool;
    IStakingPool private stakingPool;
    IERC20 private web3Token;

    IUniswapV2Router02 private mainSwapRouter; // Main swap router
    address[] private swapRouters; // Available swap routers

    FeeMethod public feeProcessingMethod = FeeMethod.SIMPLE; // How to process fee
    address public merchantWallet; // Merchant wallet
    address public affiliatorWallet;

    event TransactionFeeUpdated(uint16 previousFee, uint16 newFee);
    event DonationFeeUpdated(uint256 previousFee, uint256 newFee);
    event FeeMaxPercentUpdated(uint256 previousFee, uint256 newFee);
    event FeeMinPercentUpdated(uint256 previousFee, uint256 newFee);
    event Web3BalanceForFreeTxUpdated(
        uint256 previousBalance,
        uint256 newBalance
    );
    event MinAmountToProcessFeeUpdated(uint256 oldAmount, uint256 newAmount);
    event MarketingWalletUpdated(
        address payable oldWallet,
        address payable newWallet
    );
    event DonationWalletUpdated(
        address payable oldWallet,
        address payable newWallet
    );
    event MerchantWalletUpdated(address oldWallet, address newWallet);
    event AffiliatorWalletUpdatd(address oldWallet, address newWallet);
    event FeeProcessingMethodUpdated(FeeMethod oldMethod, FeeMethod newMethod);
    event Web3TokenUpdated(address oldToken, address newToken);
    event AffiliatePoolUpdated(IAffiliatePool oldPool, IAffiliatePool newPool);
    event StakingPoolUpdated(IStakingPool oldPool, IStakingPool newPool);
    event MainSwapRouterUpdated(address indexed oldRouter, address indexed newRouter);
    event SwapRouterAdded(address indexed newRouter);

    function viewFeeMaxPercent() public view virtual returns (uint16) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.FEE_MAX_PERCENT]
        ) {
            return feeMaxPercent;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewFeeMaxPercent();
    }

    function viewFeeMinPercent() public view virtual returns (uint16) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.FEE_MIN_PERCENT]
        ) {
            return feeMinPercent;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewFeeMinPercent();
    }

    function viewDonationFee() public view virtual returns (uint16) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.DONATION_FEE]
        ) {
            return donationFee;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewDonationFee();
    }

    function viewTransactionFee() public view virtual returns (uint16) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.TRANSACTION_FEE]
        ) {
            return transactionFee;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewTransactionFee();
    }

    function viewWeb3BalanceForFreeTx() public view virtual returns (uint256) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.WEB3_BALANCE_FOR_FREE_TX]
        ) {
            return web3BalanceForFreeTx;
        }
        return
            MerchantSharedProperty(MERCHANT_FACTORY).viewWeb3BalanceForFreeTx();
    }

    function viewMinAmountToProcessFee() public view virtual returns (uint256) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.MIN_AMOUNT_TO_PROCESS_FEE]
        ) {
            return minAmountToProcessFee;
        }
        return
            MerchantSharedProperty(MERCHANT_FACTORY)
                .viewMinAmountToProcessFee();
    }

    function viewMarketingWallet()
        public
        view
        virtual
        returns (address payable)
    {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.MARKETING_WALLET]
        ) {
            return marketingWallet;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewMarketingWallet();
    }

    function viewDonationWallet()
        public
        view
        virtual
        returns (address payable)
    {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.DONATION_WALLET]
        ) {
            return donationWallet;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewDonationWallet();
    }

    function viewWeb3Token() public view virtual returns (IERC20) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.WEB3_TOKEN]
        ) {
            return web3Token;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewWeb3Token();
    }

    function viewAffiliatePool() public view virtual returns (IAffiliatePool) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.AFFILIATE_POOL]
        ) {
            return affiliatePool;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewAffiliatePool();
    }

    function viewStakingPool() public view virtual returns (IStakingPool) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.STAKING_POOL]
        ) {
            return stakingPool;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewStakingPool();
    }

    function viewMainSwapRouter() public view virtual returns (IUniswapV2Router02) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.MAIN_SWAP_ROUTER]
        ) {
            return mainSwapRouter;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewMainSwapRouter();
    }

    function viewSwapRouters() public view virtual returns (address[] memory) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.SWAP_ROUTERS]
        ) {
            return swapRouters;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewSwapRouters();
    }

    function isBlacklistedFromPayToken(address _token)
        public
        view
        returns (bool)
    {
        return payTokenBlcklist[_token];
    }

    function isWhitelistedForRecToken(address _token)
        public
        view
        returns (bool)
    {
        return recTokenWhitelist[_token];
    }

    /**
     * @dev Update fee max percentage
     * Only callable by owner
     */
    function updateFeeMaxPercent(uint16 _maxPercent) public onlyOwner {
        require(
            _maxPercent <= 10000 && _maxPercent >= feeMinPercent,
            "Invalid value"
        );

        emit FeeMaxPercentUpdated(feeMaxPercent, _maxPercent);
        feeMaxPercent = _maxPercent;
        propSelfUpdates[SharedProperty.FEE_MAX_PERCENT] = true;
    }

    /**
     * @dev Update fee min percentage
     * Only callable by owner
     */
    function updateFeeMinPercent(uint16 _minPercent) public onlyOwner {
        require(
            _minPercent <= 10000 && _minPercent <= feeMaxPercent,
            "Invalid value"
        );

        emit FeeMinPercentUpdated(feeMinPercent, _minPercent);
        feeMinPercent = _minPercent;
        propSelfUpdates[SharedProperty.FEE_MIN_PERCENT] = true;
    }

    /**
     * @dev Update donation fee
     * Only callable by owner
     */
    function updateDonationFee(uint16 _fee) public onlyOwner {
        require(_fee <= 10000, "Invalid fee");

        emit DonationFeeUpdated(donationFee, _fee);
        donationFee = _fee;
        propSelfUpdates[SharedProperty.DONATION_FEE] = true;
    }

    /**
     * @dev Update the transaction fee
     * Can only be called by the owner
     */
    function updateTransactionFee(uint16 _fee) public onlyOwner {
        require(_fee <= MAX_TRANSACTION_FEE, "Invalid fee");
        emit TransactionFeeUpdated(transactionFee, _fee);
        transactionFee = _fee;
        propSelfUpdates[SharedProperty.TRANSACTION_FEE] = true;
    }

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateWeb3BalanceForFreeTx(uint256 _web3Balance) public onlyOwner {
        require(_web3Balance > 0, "Invalid value");
        emit Web3BalanceForFreeTxUpdated(web3BalanceForFreeTx, _web3Balance);
        web3BalanceForFreeTx = _web3Balance;
        propSelfUpdates[SharedProperty.WEB3_BALANCE_FOR_FREE_TX] = true;
    }

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateMinAmountToProcessFee(uint256 _minAmount) public onlyOwner {
        require(_minAmount > 0, "Invalid value");
        emit MinAmountToProcessFeeUpdated(minAmountToProcessFee, _minAmount);
        minAmountToProcessFee = _minAmount;
        propSelfUpdates[SharedProperty.MIN_AMOUNT_TO_PROCESS_FEE] = true;
    }

    /**
     * @dev Update the marketing wallet address
     * Can only be called by the owner.
     */
    function updateMarketingWallet(address payable _marketingWallet)
        public
        onlyOwner
    {
        require(_marketingWallet != address(0), "Invalid address");
        emit MarketingWalletUpdated(marketingWallet, _marketingWallet);
        marketingWallet = _marketingWallet;
        propSelfUpdates[SharedProperty.MARKETING_WALLET] = true;
    }

    /**
     * @dev Update the donation wallet address
     * Can only be called by the owner.
     */
    function updateDonationWallet(address payable _donationWallet)
        public
        onlyOwner
    {
        require(_donationWallet != address(0), "Invalid address");
        emit DonationWalletUpdated(donationWallet, _donationWallet);
        donationWallet = _donationWallet;
        propSelfUpdates[SharedProperty.DONATION_WALLET] = true;
    }

    /**
     * @dev Update web3 token address
     * Callable only by owner
     */
    function updateWeb3TokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "Invalid token");

        emit Web3TokenUpdated(address(web3Token), _tokenAddress);
        web3Token = IERC20(_tokenAddress);
        propSelfUpdates[SharedProperty.WEB3_TOKEN] = true;
    }

    function updateaffiliatePool(IAffiliatePool _affiliatePool)
        public
        onlyOwner
    {
        require(address(_affiliatePool) != address(0), "Invalid pool");
        emit AffiliatePoolUpdated(affiliatePool, _affiliatePool);
        affiliatePool = _affiliatePool;
        propSelfUpdates[SharedProperty.AFFILIATE_POOL] = true;
    }

    function updateStakingPool(IStakingPool _stakingPool) public onlyOwner {
        require(address(_stakingPool) != address(0), "Invalid pool");
        emit StakingPoolUpdated(stakingPool, _stakingPool);
        stakingPool = _stakingPool;
        propSelfUpdates[SharedProperty.STAKING_POOL] = true;
    }

    /**
     * @dev Update the main swap router.
     * Can only be called by the owner.
     */
    function updateMainSwapRouter(address _router) public onlyOwner {
        require(_router != address(0), "Invalid router");
        emit MainSwapRouterUpdated(address(mainSwapRouter), _router);
        mainSwapRouter = IUniswapV2Router02(_router);
        propSelfUpdates[SharedProperty.MAIN_SWAP_ROUTER] = true;
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the owner.
     */
    function addSwapRouter(address _router) public onlyOwner {
        require(_router != address(0), "Invalid router");
        emit SwapRouterAdded(_router);
        swapRouters.push(_router);
        propSelfUpdates[SharedProperty.SWAP_ROUTERS] = true;
    }

    /**
     * @dev Update the merchant wallet address
     * Can only be called by the owner.
     */
    function updateMerchantWallet(address _merchantWallet) public onlyOwner {
        require(_merchantWallet != address(0), "Invalid address");
        emit MerchantWalletUpdated(merchantWallet, _merchantWallet);
        merchantWallet = _merchantWallet;
    }

    /**
     * @dev Update affiliator wallet address
     * Only callable by owner
     */
    function updateAffiliatorWalletAddress(address _walletAddress)
        public
        onlyOwner
    {
        require(_walletAddress != address(0), "Invalid address");
        emit AffiliatorWalletUpdatd(affiliatorWallet, _walletAddress);
        affiliatorWallet = _walletAddress;
    }

    /**
     * @dev Update fee processing method
     * Only callable by owner
     */
    function updateFeeProcessingMethod(FeeMethod _method) public onlyOwner {
        if (_method == FeeMethod.AFLIQU) {
            require(
                address(web3Token) != address(0) &&
                    address(affiliatePool) != address(0) &&
                    affiliatorWallet != address(0),
                "Invalid condition1"
            );
        }
        if (_method == FeeMethod.LIQU) {
            require(address(web3Token) != address(0), "Invalid condition2");
        }

        emit FeeProcessingMethodUpdated(feeProcessingMethod, _method);
        feeProcessingMethod = _method;
    }

    /**
     * @dev Exclude a token from paying blacklist
     * Only callable by owner
     */
    function excludeFromPayTokenBlacklist(address _token) public onlyOwner {
        require(_token != address(0), "Invalid token");
        payTokenBlcklist[_token] = false;
    }

    /**
     * @dev Include a token in paying blacklist
     * Only callable by owner
     */
    function includeInPayTokenBlacklist(address _token) public onlyOwner {
        require(_token != address(0), "Invalid token");
        payTokenBlcklist[_token] = true;
    }

    /**
     * @dev Exclude a token from receiving whitelist
     * Only callable by owner
     */
    function excludeFromRecTokenWhitelist(address _token) public onlyOwner {
        require(_token != address(0), "Invalid token");
        recTokenWhitelist[_token] = false;
    }

    /**
     * @dev Include a token in receiving whitelist
     * Only callable by owner
     */
    function includeInRecTokenWhitelist(address _token) public onlyOwner {
        require(_token != address(0), "Invalid token");
        recTokenWhitelist[_token] = true;
    }
}

contract MerchantFactory is MerchantSharedProperty {
    constructor() {
        updateFeeMaxPercent(50); // FEE_MAX default 0.5%
        updateFeeMinPercent(10); // FEE_MIN default 0.1%
        updateDonationFee(15); // Donation fee default 0.15%
        updateTransactionFee(50); // Transaction fee multiplied by 100, default 0.5%
        updateWeb3BalanceForFreeTx(1000 ether); // If any wallet has 1000 Web3 tokens, it will be exempted from the transaction fee
        updateMinAmountToProcessFee(1 ether); // When there is 1 BNB staked, fee will be processed
        updateMainSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Default main swap router, pancakev2 router
        addSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Default swap router, pancakev2 router

        updateMarketingWallet(payable(_msgSender()));
        updateDonationWallet(payable(_msgSender()));
    }
}