// contracts/Igniter.sol
// SPDX-License-Identifier: MIT

/*

██╗░░░░░██╗░░░██╗███╗░░██╗░█████╗░██████╗░  ███████╗██╗░░░░░░█████╗░██████╗░███████╗
██║░░░░░██║░░░██║████╗░██║██╔══██╗██╔══██╗  ██╔════╝██║░░░░░██╔══██╗██╔══██╗██╔════╝
██║░░░░░██║░░░██║██╔██╗██║███████║██████╔╝  █████╗░░██║░░░░░███████║██████╔╝█████╗░░
██║░░░░░██║░░░██║██║╚████║██╔══██║██╔══██╗  ██╔══╝░░██║░░░░░██╔══██║██╔══██╗██╔══╝░░
███████╗╚██████╔╝██║░╚███║██║░░██║██║░░██║  ██║░░░░░███████╗██║░░██║██║░░██║███████╗
╚══════╝░╚═════╝░╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚═╝  ╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝


█▄▄ █░█ █▀█ █▄░█   █ ▀█▀   █▀▄ █▀█ █░█░█ █▄░█
█▄█ █▄█ █▀▄ █░▀█   █ ░█░   █▄▀ █▄█ ▀▄▀▄▀ █░▀█

*/

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Incinerator.sol";

contract Igniter is IERC20, IERC20Metadata, Context, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct KEY_ADDRESSES {
        address payable contractToIgnite;
    }

    struct burnSwapTokens {
        bool approved;
        address token;
        uint256 bonusMultiplier;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _NAME = "TEST Burn Swap";
    string private _SYMBOL = "TBS";
    uint256 private MaxTokensAvailable;
    address contractOwner;
    address payable contractToIgnite;

    mapping(address => bool) _projectWhitelist;
    mapping(address => bool) _projectBlacklist;
    mapping(address => bool) public approvedBurnSwapProjects;
    mapping(address => burnSwapTokens) public approvedBurnSwapTokens;
    mapping(address => uint256) public tokensConverted;

    IUniswapV2Router02 public dexRouter;
    IUniswapV2Pair public pairContract;

    uint256 private _MAX = ~uint256(0);
    uint256 private _DECIMALFACTOR = 18;
    uint256 private _GRANULARITY = 100;
    uint256 public defaultMultiplier = 100000000000000;

    bool public burnSwapState = true;

    KEY_ADDRESSES public keyAddresses;
    event DexFactorySet(IUniswapV2Router02);
    event Received(address sender, uint amount);
    address contractAddress;

    constructor(
        uint256 _supply,
        address _tokenOwner,
        address _RouterAddress,
        address payable _contractToIgnite,
        bool _burnSwapState
    ) Ownable() {
        burnSwapState = _burnSwapState;
        // contractToIgnite = _contractToIgnite;
        keyAddresses = KEY_ADDRESSES({contractToIgnite: _contractToIgnite});
        MaxTokensAvailable = _supply * (10**_DECIMALFACTOR);
        contractOwner = _tokenOwner;

        balances[address(this)] = MaxTokensAvailable;

        emit Transfer(address(0), address(this), MaxTokensAvailable);

        contractAddress = address(this);
        setDexRouter(_RouterAddress);

        burnToken(address(this), balances[address(this)]);
    }

    function name() public view returns (string memory) {
        return _NAME;
    }

    function symbol() public view returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public view returns (uint8) {
        return uint8(_DECIMALFACTOR);
    }

    function totalSupply() external view override returns (uint256) {
        return IERC20(keyAddresses.contractToIgnite).totalSupply();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return IERC20(keyAddresses.contractToIgnite).balanceOf(account);
    }

    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        contractOwner = newOwner;
        _transferOwnership(newOwner);
    }

    function burnToken(address addressBurning,uint256 amountToBurn) private returns (bool) {
        balances[address(0)] = balances[address(0)] + amountToBurn;
        balances[addressBurning] -= amountToBurn;
        MaxTokensAvailable = MaxTokensAvailable - amountToBurn;
        emit Transfer(address(this), address(0), amountToBurn);

        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        IERC20(keyAddresses.contractToIgnite).transfer(recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function approveContract(
        address sourceAddress,
        address contractAddy,
        uint256 amount
    ) public onlyOwner returns (bool approved) {
        approved = IERC20(sourceAddress).approve(contractAddy, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "TOKEN20: approve from the zero address");
        require(spender != address(0), "TOKEN20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    Incinerator parent;

    modifier onlyAuthorized() {
        parent = Incinerator(keyAddresses.contractToIgnite);

        require(
            parent.owner() == msg.sender ||
                parent.authorized(msg.sender) ||
                owner() == msg.sender,
            "Not Authorized"
        );
        _;
    }

    modifier isWhitelisted() {
        parent = Incinerator(keyAddresses.contractToIgnite);

        require(
            parent._projectWhitelist(msg.sender) ||
                contractOwner == msg.sender ||
                keyAddresses.contractToIgnite == msg.sender,
            "Not on the whitelist"
        );
        _;
    }

    modifier isNotBlacklisted() {
        parent = Incinerator(keyAddresses.contractToIgnite);

        require(parent._projectBlacklist(msg.sender) == false, "Blacklisted");
        _;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override onlyOwner returns (bool) {
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(
            sender != address(0),
            "TOKEN20: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "TOKEN20: transfer to the zero address"
        );
        require(
            !_projectBlacklist[sender],
            "Address has been band from sending"
        );
        require(
            !_projectBlacklist[recipient],
            "Address has been band from receiving"
        );
        require(amount > 0, "Transfer amount must be greater than zero");

        actualTransfer(sender, recipient, amount);
    }

    function actualTransfer(
        address s,
        address r,
        uint256 a
    ) private returns (bool) {
        // require(a > 0, "Not Enough Tokens");
        if (a > 0) {
            unchecked {
                balances[s] = balances[s] - a;
            }

            unchecked {
                balances[r] = balances[r] + a;
            }

            emit Transfer(s, r, a);
        }
        return true;
    }

    function lp_TotalTokens(address checkpair)
        public
        view
        returns (uint256 lpTokenSupply)
    {
        lpTokenSupply = IERC20(checkpair).totalSupply();
    }

    function lp_EtherPerLPToken(
        address pairedToken,
        address sourceContract,
        address checkpair
    ) external view returns (uint256 _tokensPerLPToken) {
        uint256 lpTokenSupply = IERC20(checkpair).totalSupply();

        _tokensPerLPToken =
            ((IWETH(pairedToken).balanceOf(address(checkpair)) *
                (defaultMultiplier *
                    IIncinerator(sourceContract)._DECIMALFACTOR())) /
                lpTokenSupply) /
            defaultMultiplier;
    }

    function lp_TotalLpOwnedByProject(address checkpair)
        public
        view
        returns (uint256 lpControlledByProject)
    {
        lpControlledByProject = IERC20(checkpair).balanceOf(address(this));
    }

    function lp_TotalTokensInLPOwnedByProject(
        address sourceContract,
        address checkpair
    ) external view returns (uint256 tokensinlpControlledByProject) {
        uint256 __DECIMALFACTOR = IIncinerator(sourceContract)._DECIMALFACTOR();

        uint256 lpControlledByProject = IERC20(checkpair).balanceOf(
            sourceContract
        );

        uint256 lpTokenSupply = IERC20(checkpair).totalSupply();

        uint256 percentControlled = ((lpControlledByProject *
            (defaultMultiplier * __DECIMALFACTOR)) / lpTokenSupply) /
            defaultMultiplier;

        uint256 tokenbalanceOfPair = IIncinerator(sourceContract).balanceOf(
            checkpair
        );
        tokensinlpControlledByProject =
            (tokenbalanceOfPair * percentControlled) /
            (1 ether);
    }

    function setDexRouter(address routerAddress)
        public
        onlyOwner
        nonReentrant
        returns (bool)
    {
        dexRouter = IUniswapV2Router02(routerAddress);

        emit DexFactorySet(dexRouter);

        return true;
    }

    function updateIgniterContract(address payable _burnerAddress)
        external
        onlyOwner
    {
        require(
            _burnerAddress != address(0),
            "Ownable: new owner is the zero address"
        );
        keyAddresses.contractToIgnite = _burnerAddress;
        contractToIgnite = _burnerAddress;
    }

    function burnSwap(
        address swapAddress,
        uint256 value,
        uint256 minimumExpected,
        address[] memory path
    ) external nonReentrant {
        require(burnSwapState, "Burn swap is currently not available");
        require(
            approvedBurnSwapTokens[swapAddress].approved,
            "Not an approved Burn Swap Project"
        );
        require(path.length > 1, "Path not long enough");
        require(
            path[path.length - 1] == keyAddresses.contractToIgnite,
            "End path not incinerator"
        );
        require(value > 0, "Must send more than Zero tokens");
        IERC20 swapToken = IERC20(address(swapAddress));
        require(
            swapToken.balanceOf(msg.sender) >= value,
            "Token value sent is greater than balance"
        );
        uint256 priorLFGBalance = balanceOf(address(this));
        require(priorLFGBalance > 0, "Must have LFG tokens in reserve");
        // address Pair = IUniswapV2Factory(dexRouter.factory()).getPair(swapAddress, dexRouter.WETH());

        swapToken.safeTransferFrom(msg.sender, address(this), value);

        swapToken.approve(address(dexRouter), type(uint256).max);

        uint256 tempTokenBalance = swapToken.balanceOf(address(this));

        try
            dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tempTokenBalance, // accept as many tokens as we can
                0,
                path,
                address(this), // Send To Recipient
                block.timestamp + 15
            )
        {
            tokensConverted[swapAddress] += value;
        } catch Error(string memory reason1) {
            try
                dexRouter.swapExactTokensForTokens(
                    tempTokenBalance, // accept as many tokens as we can
                    0,
                    path,
                    address(this), // Send To Recipient
                    block.timestamp + 15
                )
            {
                tokensConverted[swapAddress] += value;
            } catch Error(string memory reason2) {
                revert(string(abi.encodePacked(reason1, " -- ", reason2)));
            }
        }

        uint256 priorLFGBalance2 = balanceOf(address(this));
        uint256 netGain = priorLFGBalance2 - priorLFGBalance;

        require(
            priorLFGBalance + netGain >= minimumExpected,
            "Not enough output"
        );
        require(
            priorLFGBalance + netGain > priorLFGBalance,
            "Can not commit a zero gain transaction"
        );

        uint256 swapBonusGain = (netGain 
            * 1 ether  
            * approvedBurnSwapTokens[swapAddress].bonusMultiplier 
            / 10000) 
        / 1 ether;
        transferWithOutFees(msg.sender, netGain);
        transferWithOutFees(msg.sender, swapBonusGain);

    }

    function transferWithOutFees(address to, uint256 _a) internal {
        IIncinerator _incinerator = IIncinerator(keyAddresses.contractToIgnite);
        _incinerator.removeAllFees();
        try _incinerator.transfer(to, _a) {
            _incinerator.restoreAllFees();
        } catch Error(string memory reason1) {
            _incinerator.restoreAllFees();
            revert(reason1);
        }
    }

    function updateBurnSwapProject(
        address swapAddress,
        bool _approved,        
        uint256 bonusMult
    ) external onlyAuthorized {
        approvedBurnSwapTokens[swapAddress] = burnSwapTokens({
            approved: _approved,
            token: swapAddress,            
            bonusMultiplier: bonusMult
        });
    }

    function toggleBurnSwap() external onlyAuthorized {
        burnSwapState = !burnSwapState;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function transferNativeToken(address payable thisAddress, uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        require(0 < amount, "Zero Tokens");
        require(thisAddress.balance >= amount, "Not enough tokens to send");
        thisAddress.transfer(amount);
    }

    function transferContractTokens(address destination, uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        require(0 < amount, "Zero Tokens");
        require(
            IERC20(keyAddresses.contractToIgnite).balanceOf(address(this)) >=
                amount,
            "Not enough tokens to send"
        );
        require(
            IERC20(keyAddresses.contractToIgnite).transfer(destination, amount),
            "transfer failed"
        );
    }

    function getAnyPair(address token1, address token2)
        external
        view
        returns (address)
    {
        return IUniswapV2Factory(dexRouter.factory()).getPair(token1, token2);
    }

    function makeOrphanAndStripOfAssets(
        address newOwner,
        bool moveFunds,
        address payable directionForRecovery
    ) external onlyOwner {
        if (moveFunds) {
            uint256 amountOfSupportToken = IERC20(keyAddresses.contractToIgnite)
                .balanceOf(address(this));

            if (address(this).balance > 0) {
                directionForRecovery.transfer(address(this).balance);
            }

            if (amountOfSupportToken > 0) {
                IERC20(keyAddresses.contractToIgnite).transfer(
                    directionForRecovery,
                    amountOfSupportToken
                );
            }
        }
        transferOwnership(newOwner);
    }

    function transferAnyERC20Token(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external onlyOwner nonReentrant {
        require(0 < amount, "Zero Tokens");
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= amount,
            "Not enough tokens to send"
        );
        require(
            IERC20(tokenAddress).transfer(recipient, amount),
            "transfer failed!"
        );
    }

    function getPair() external view returns (address) {
        return
            IUniswapV2Factory(dexRouter.factory()).getPair(
                keyAddresses.contractToIgnite,
                dexRouter.WETH()
            );
    }

    function getWeth() public view returns (address wethAddress) {
        wethAddress = dexRouter.WETH();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// contracts/Incinerator.sol
// SPDX-License-Identifier: MIT

/*

██╗░░░░░██╗░░░██╗███╗░░██╗░█████╗░██████╗░  ███████╗██╗░░░░░░█████╗░██████╗░███████╗
██║░░░░░██║░░░██║████╗░██║██╔══██╗██╔══██╗  ██╔════╝██║░░░░░██╔══██╗██╔══██╗██╔════╝
██║░░░░░██║░░░██║██╔██╗██║███████║██████╔╝  █████╗░░██║░░░░░███████║██████╔╝█████╗░░
██║░░░░░██║░░░██║██║╚████║██╔══██║██╔══██╗  ██╔══╝░░██║░░░░░██╔══██║██╔══██╗██╔══╝░░
███████╗╚██████╔╝██║░╚███║██║░░██║██║░░██║  ██║░░░░░███████╗██║░░██║██║░░██║███████╗
╚══════╝░╚═════╝░╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚═╝  ╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝


█▄▄ █░█ █▀█ █▄░█   █ ▀█▀   █▀▄ █▀█ █░█░█ █▄░█
█▄█ █▄█ █▀▄ █░▀█   █ ░█░   █▄▀ █▄█ ▀▄▀▄▀ █░▀█

developed by reallunardev.eth
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/DateTimeLib.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;

    function makeOrphanAndStripOfAssets(
        address newOwner,
        address directionForRecovery
    ) external;
}

interface IIncinerator is IERC20 {
    function _DECIMALFACTOR() external view returns (uint256);

    function restoreAllFees() external;

    function removeAllFees() external;
}

interface IIgniter is IERC20 {
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external;

    function lp_EtherPerLPToken(
        address pairedToken,
        address sourceContract,
        address checkpair
    ) external view returns (uint256);

    function lp_TotalTokensInLPOwnedByProject(
        address sourceContract,
        address checkpair
    ) external view returns (uint256);

    function lp_TotalTokens(address checkpair) external view returns (uint256);

    function makeOrphanAndStripOfAssets(
        address newOwner,
        bool moveFunds,
        address directionForRecovery
    ) external;
}

contract Incinerator is
    Context, //Because you need it.
    IERC20Metadata, //Cause they didn't do it in the first one!
    ReentrancyGuard, //To prevent funky stuff ;)
    Ownable //Fpr the Ownage C[o] Keep away!
{
    using Counters for Counters.Counter;

    Counters.Counter private _dayCounter;

    struct DAILY_BURN {
        uint256 id;
        uint256 tokenStartDay;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 amountTobeBurned;
        uint256 amountBurned;
    }

    struct KEY_ADDRESSES {
        address routerAddress;
        address payload2Wallet;
        address payload1Wallet;
        address igniterContract;
    }

    struct FEES {
        uint256 burnSwapRedirect;
        uint256 baseTransferFee;
        uint256 buyBurnFee;
        uint256 sellBurnFee;
        uint256 transferFee;
        uint256 buyLPBurn;
        uint256 sellBurnLP;
        uint256 transferLPBurn;
        uint256 sF1;
        uint256 sF2;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedReceiver;
    mapping(address => bool) private _isExcludedSender;
    mapping(address => bool) public _dexAddresses;
    mapping(address => bool) public _projectWhitelist;
    mapping(address => bool) public _projectBlacklist;
    mapping(address => bool) public authorized;
    mapping(address => bool) public lpPairs;
    mapping(address => bool) private _liquidityHolders;
    mapping(uint256 => DAILY_BURN) public dailyBurn;

    string private _NAME = "Lunar Flare";
    string private _SYMBOL = "LFG";
    uint256 private _DECIMALS = 18;
    string public Author;

    uint256 private _MAX = ~uint256(0);

    uint256 public _DECIMALFACTOR;
    uint256 private _grain = 100;
    uint256 private _TotalSupply;
    uint256 private _totalFees;
    uint256 private totalTokensBurned;
    uint256 public pendingTokenBurnFromTrx;
    uint256 private queuedDailyBurn;

    uint256 public burnSwapClaimBalance;
    uint256 public dailyBurnPercent = 1;
    uint256 public accumulatedBurn = 0;

    uint256 public projTokenBalance;
    uint256 public projEthBalance;

    IUniswapV2Router02 public dexRouter;
    IUniswapV2Pair public pairContract;

    address public primePair;
    address public dexAddresses;
    address contractOwner;

    bool InitialLiquidityRan;
    bool swapFeesimmediately = true;
    bool tradingEnabled = true;

    DAILY_BURN[] public allDailyBurns;
    KEY_ADDRESSES public contractAddresses;
    FEES public contractFees =
        FEES({
            burnSwapRedirect: 400,
            baseTransferFee: 200,
            transferFee: 300,
            buyBurnFee: 100,
            sellBurnFee: 700,
            transferLPBurn: 300,
            buyLPBurn: 800,
            sellBurnLP: 0,
            sF1: 5000,
            sF2: 5000
        });

    FEES ogFees =
        FEES({
            burnSwapRedirect: 400,
            baseTransferFee: 200,
            transferFee: 300,
            buyBurnFee: 100,
            sellBurnFee: 700,
            transferLPBurn: 300,
            buyLPBurn: 800,
            sellBurnLP: 0,
            sF1: 5000,
            sF2: 5000
        });

    event LiquidityPairCreated(address);
    event DexFactorySet(IUniswapV2Router02);
    event TokenBurn(uint256);
    event Received(address sender, uint amount);

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || contractOwner == msg.sender);
        _;
    }

    modifier isNotZeroAddress(address sender, address recipient) {
        require(
            sender != address(0),
            "TOKEN20: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "TOKEN20: transfer to the zero address"
        );

        _;
    }

    modifier isNotBlacklisted(address sender, address recipient) {
        require(
            !_projectBlacklist[recipient],
            "Address has been band from sending"
        );
        require(
            !_projectBlacklist[sender],
            "Address has been band from receiving"
        );
        _;
    }

    constructor(
        uint256 _supply,
        address _tokenOwner,
        address _marketingAddress,
        address _payload1Wallet,
        address _RouterAddress
    ) {
        _DECIMALFACTOR = 10**_DECIMALS;
        _TotalSupply = _supply * _DECIMALFACTOR;
        contractOwner = _tokenOwner;
        dexAddresses = _RouterAddress;
        _dexAddresses[dexAddresses] = true;

        contractAddresses = KEY_ADDRESSES({
            routerAddress: _RouterAddress,
            payload2Wallet: _marketingAddress,
            payload1Wallet: _payload1Wallet,
            igniterContract: address(0)
        });

        authorized[contractOwner] = true;
        _projectWhitelist[contractOwner] = true;
        _projectWhitelist[_payload1Wallet] = true;
        _projectWhitelist[contractAddresses.payload2Wallet] = true;
        _isExcludedReceiver[contractOwner] = true;
        _isExcludedSender[contractOwner] = true;

        balances[address(this)] = (_TotalSupply * 3716426) / 10000000;
        balances[contractOwner] = (_TotalSupply * 6283574) / 10000000;

        emit Transfer(address(0), _tokenOwner, balances[contractOwner]);
        emit Transfer(address(0), address(this), balances[address(this)]);

        setDexRouter(_RouterAddress);

        createPair(dexRouter.WETH(), true); /*_tokenToPegTo*/
    }

    /* ---------------------------------------------------------------- */
    /* ---------------------------VIEWS-------------------------------- */
    /* ---------------------------------------------------------------- */

    /* ------------------------PRIVATE/INTERNAL------------------------ */
    function _getTokenEconomyContribution(
        uint256 tokenAmount,
        uint256 tokenFee,
        uint256 tokenBurn,
        uint256 tokenAdditionalLPBurn
    )
        private
        view
        returns (
            uint256 _tokenFee,
            uint256 _tokenBurn,
            uint256 _secondTokenBurnTally,
            uint256 _transferAmount
        )
    {
        _tokenFee = ((tokenAmount * tokenFee) / _grain) / 100;
        _tokenBurn = ((tokenAmount * tokenBurn) / _grain) / 100;
        _secondTokenBurnTally =
            ((tokenAmount * tokenAdditionalLPBurn) / _grain) /
            100;

        _transferAmount = tokenAmount - (_tokenFee + _tokenBurn);
    }

    /* ------------------------PUBLIC/EXTERNAL----------------------- */

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return balances[account];
    }

    function name() external view returns (string memory) {
        return _NAME;
    }

    function symbol() external view returns (string memory) {
        return _SYMBOL;
    }

    function decimals() external view returns (uint8) {
        return uint8(_DECIMALS);
    }

    function totalSupply() external view override returns (uint256) {
        return _TotalSupply;
    }

    function lp_EtherPerLPToken(
        address pairedToken,
        address sourceContract,
        address checkpair
    ) public view returns (uint256 _tokensPerLPToken) {
        _tokensPerLPToken = IIgniter(contractAddresses.igniterContract)
            .lp_EtherPerLPToken(pairedToken, sourceContract, checkpair);
    }

    function lp_TotalTokens(address checkpair)
        public
        view
        returns (uint256 lpTokenSupply)
    {
        lpTokenSupply = IIgniter(contractAddresses.igniterContract)
            .lp_TotalTokens(checkpair);
    }

    function calculateLPtoUnpair(uint256 _getTokensToRemove)
        internal
        view
        returns (
            uint256 tokensToExtract,
            uint256 ethToExtract,
            uint256 lpToUnpair,
            uint256 controlledLpAmount
        )
    {
        require(balances[primePair] > 0, "Must have Tokens in LP");

        if (_getTokensToRemove > 0) {
            (
                uint112 LPContractTokenBalance,
                uint112 LPWethBalance, /* /*uint32 blockTimestampLast*/

            ) = pairContract.getReserves();

            uint256 percent = ((_getTokensToRemove * (100000000000000000000)) /
                LPContractTokenBalance);

            controlledLpAmount = IERC20(primePair).balanceOf(address(this));

            lpToUnpair =
                (controlledLpAmount * percent) /
                (100000000000000000000);

            ethToExtract = (LPWethBalance * percent) / (100000000000000000000);

            tokensToExtract = _getTokensToRemove;
        }
    }

    function getContractTokenBalance(
        address _tokenAddress,
        address _walletAddress
    ) public view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(_walletAddress);
    }

    function getLPTokenBalance() external view returns (uint256) {
        return getContractTokenBalance(primePair, address(this));
    }

    function getWhitelisted(address _checkThis)
        public
        view
        onlyAuthorized
        returns (bool)
    {
        return _projectWhitelist[_checkThis];
    }

    function getBlacklisted(address _checkThis)
        public
        view
        onlyAuthorized
        returns (bool)
    {
        return _projectBlacklist[_checkThis];
    }

    function pendingBurn() external view returns (uint256) {
        return pendingTokenBurnFromTrx + accumulatedBurn;
    }

    function totalFees() external view returns (uint256) {
        return _totalFees;
    }

    function totalBurn() external view returns (uint256) {
        return totalTokensBurned;
    }

    /* ---------------------------------------------------------------- */
    /* -------------------------FUNCTIONS------------------------------ */
    /* ---------------------------------------------------------------- */

    /* ------------------------PRIVATE/INTERNAL------------------------ */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != _MAX) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _actualTransfer(
        address sender,
        address receiver,
        uint256 _transferAmount
    ) private returns (bool) {
        if (_transferAmount > 0) {
            unchecked {
                balances[sender] -= _transferAmount;
            }
            unchecked {
                balances[receiver] += (_transferAmount);
            }
            emit Transfer(sender, receiver, _transferAmount);
        }
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "TOKEN20: approve from the zero address");
        require(spender != address(0), "TOKEN20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnToken(address addressBurning, uint256 amountToBurn)
        private
        returns (bool)
    {
        require(balances[addressBurning] >= amountToBurn, "Amount Exceeds Balance");
        balances[addressBurning] -= amountToBurn;
        balances[address(0)] += amountToBurn;
        totalTokensBurned += amountToBurn;
        _TotalSupply -= amountToBurn;

        emit TokenBurn(amountToBurn);

        return true;
    }

    function _controlDailyBurn() private {
        uint256 asOf = block.timestamp;

        uint16 _year = DateTimeLib.getYear(asOf);
        uint8 _month = DateTimeLib.getMonth(asOf);
        uint8 _day = DateTimeLib.getDay(asOf);
        uint256 _timestamp = DateTimeLib.toTimestamp(_year, _month, _day);
        uint256 _endtimestamp = DateTimeLib.toTimestamp(
            _year,
            _month,
            _day,
            59,
            59
        );

        if (dailyBurn[_dayCounter.current()].startTimestamp != _timestamp) {
            // burn previous days remainder

            _dayCounter.increment();

            uint256 startingTokensInLP = IIgniter(
                contractAddresses.igniterContract
            ).lp_TotalTokensInLPOwnedByProject(address(this), primePair);

            dailyBurn[_dayCounter.current()] = DAILY_BURN({
                id: _dayCounter.current(),
                tokenStartDay: _TotalSupply - balances[address(0)],
                startTimestamp: _timestamp,
                endTimestamp: _endtimestamp,
                amountTobeBurned: (startingTokensInLP * dailyBurnPercent) / 100,
                amountBurned: 0
            });
        }
        uint256 dburn = dailyBurns();
        if (dburn > 0) {
            queuedDailyBurn = dburn;
        }
    }

    function dailyBurns() public view returns (uint256 _tokensToBurn) {
        if (dailyBurn[_dayCounter.current()].startTimestamp > 0) {
            uint256 _asOf = block.timestamp;

            uint256 tickSinceStart = _asOf -
                dailyBurn[_dayCounter.current()].startTimestamp;

            uint256 totalTicks = dailyBurn[_dayCounter.current()].endTimestamp -
                dailyBurn[_dayCounter.current()].startTimestamp;

            uint256 _toBeBurnedPerTick = dailyBurn[_dayCounter.current()]
                .amountTobeBurned / totalTicks;

            _tokensToBurn = (_toBeBurnedPerTick * tickSinceStart) >
                dailyBurn[_dayCounter.current()].amountBurned
                ? (_toBeBurnedPerTick * tickSinceStart) -
                    dailyBurn[_dayCounter.current()].amountBurned
                : 0;
        } else {
            _tokensToBurn = 0;
        }
    }

    function _getRemainingQueuedDailyBurn()
        public
        view
        returns (uint256 _queuedDailyBurn)
    {
        _queuedDailyBurn =
            dailyBurn[_dayCounter.current()].amountTobeBurned -
            dailyBurn[_dayCounter.current()].amountBurned;
    }

    function removeAllFees() public onlyAuthorized {
        _removeAllFees();
    }

    function _removeAllFees() private {
        contractFees.burnSwapRedirect = 0;
        contractFees.baseTransferFee = 0;

        contractFees.transferFee = 0;
        contractFees.buyBurnFee = 0;
        contractFees.sellBurnFee = 0;

        contractFees.transferLPBurn = 0;
        contractFees.buyLPBurn = 0;
        contractFees.sellBurnLP = 0;
    }

    function _getLPandUnpair(uint256 totalTokensToGet)
        internal
        returns (
            bool success,
            uint256 ___amountToken,
            uint256 ___txETHAmount
        )
    {
        (
            uint256 tokensToExtract,
            ,
            uint256 lpToUnpair,
            uint256 amountControlled
        ) = calculateLPtoUnpair(totalTokensToGet);

        if (tokensToExtract > 0 && lpToUnpair >= 100000000000000) {
            _transferOwnership(msg.sender);

            (bool _result, uint256 _aOut, uint256 _eOut) = removeLiquidity(
                lpToUnpair,
                amountControlled
            );

            require(contractOwner == owner(), "Not current owner");

            return (_result, _aOut, _eOut);
        }

        return (false, 0, 0);
    }

    function removeLiquidity(uint256 _lpToUnpair, uint256 controlledLP)
        internal
        onlyOwner
        returns (
            bool _success,
            uint256 _amountToken,
            uint256 _txETHAmount
        )
    {
        uint256 _priorEthBalance = address(this).balance;

        approveContract(primePair, address(dexRouter), _MAX);

        uint256 unpairThisAmount = _lpToUnpair > controlledLP
            ? controlledLP / 2
            : _lpToUnpair;
        uint256 _priorBalance = balances[address(this)];
        try
            dexRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
                address(this),
                unpairThisAmount,
                0, //tokens to be returned,
                0, //ethAmount to be returned
                address(this),
                block.timestamp + 15
            )
        {
            _amountToken = balances[address(this)] - _priorBalance;
            _txETHAmount = address(this).balance - _priorEthBalance;
            _success = true;

            handleFees();

            _amountToken = balances[address(this)];

            _transferOwnership(contractOwner);
        } catch {
            _transferOwnership(contractOwner);
            _success = false;
            revert("LP Pull Failed");
        }
    }

    function handleFees() private onlyOwner {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        if (
            projTokenBalance > 0 &&
            balances[address(this)] >= projTokenBalance &&
            balances[primePair] > 0
        ) {
            approveContract(address(this), address(dexRouter), _MAX);
            uint256 priorHouseEthBalance = address(this).balance;
            try
                dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    projTokenBalance,
                    0,
                    path,
                    address(this),
                    block.timestamp + 15
                )
            {
                projTokenBalance = 0;

                projEthBalance += (address(this).balance -
                    priorHouseEthBalance);
            } catch {
                payWithTokens();
            }
        } else {
            payWithTokens();
        }
    }

    function payWithTokens() private onlyOwner {
        uint256 split1 = ((projTokenBalance * contractFees.sF1) / _grain) / 100;
        uint256 split2 = ((projTokenBalance * contractFees.sF2) / _grain) / 100;

        _actualTransfer(
            address(this),
            contractAddresses.payload1Wallet,
            split1
        );

        _actualTransfer(
            address(this),
            contractAddresses.payload2Wallet,
            split2
        );

        projTokenBalance = 0;
    }

    function restoreAllFees() public onlyAuthorized {
        _restoreAllFees();
    }

    function updateContractBal(uint256 _ptb, uint256 _peb)
        public
        onlyOwner
        nonReentrant
    {
        projTokenBalance = _ptb;
        projEthBalance = _peb;
    }

    function updateAuthor(string memory _author) public onlyOwner nonReentrant {
        Author = _author;
    }

    function _restoreAllFees() private {
        contractFees = ogFees;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        private
        isNotZeroAddress(sender, recipient)
        isNotBlacklisted(sender, recipient)
    {
        if (!tradingEnabled) {
            if (!(authorized[sender] || owner() == sender)) {
                revert("Trading not yet enabled!");
            }
        }

        require(amount > 0, "Transfer amount must be greater than zero");
        require(balances[sender] >= amount, "Greater than balance");

        //Review this code

        bool takeFee = true;

        if (
            msg.sender == address(this) ||
            recipient == address(this) ||
            _projectWhitelist[recipient] == true ||
            _projectWhitelist[sender] == true ||
            _isExcludedReceiver[recipient] == true ||
            _isExcludedSender[sender] == true
        ) {
            takeFee = false;
        }

        if (takeFee == false) {
            _removeAllFees();
        }

        //Transfer Tokens Burn Fee
        uint256 tokenBurn;
        uint256 additionalBurnFromLP;

        //BUY - Tokens coming from DEX
        if (lpPairs[sender]) {
            tokenBurn = contractFees.buyBurnFee;
            additionalBurnFromLP = contractFees.buyLPBurn;
        }
        //SELL - Tokens going to DEX
        else if (lpPairs[recipient]) {
            tokenBurn = contractFees.sellBurnFee;
            additionalBurnFromLP = contractFees.sellBurnLP;
        }
        //TRANSFER
        else {
            tokenBurn = contractFees.transferFee;
            additionalBurnFromLP = contractFees.transferLPBurn;
        }

        (
            uint256 _baseFee,
            uint256 tokensToBurn,
            uint256 secondTokenBurnTally,
            uint256 tTransferAmount
        ) = _getTokenEconomyContribution(
                amount,
                contractFees.baseTransferFee,
                tokenBurn,
                additionalBurnFromLP
            );

        _actualTransfer(sender, recipient, tTransferAmount);

        if (tokensToBurn > 0) {
            _burnToken(sender, tokensToBurn);
        }

        extraTransferActions(
            takeFee,
            sender,
            recipient,
            _baseFee,
            secondTokenBurnTally
        );

        if (!takeFee) _restoreAllFees();
    }

    function extraTransferActions(
        bool _takeFee,
        address _sender,
        address _recipient,
        uint256 __baseFee,
        uint256 _secondTokenBurnTally
    ) internal {
        if (swapFeesimmediately && balances[primePair] > 0) {
            projTokenBalance += __baseFee;
            _totalFees += projTokenBalance;

            _actualTransfer(_sender, address(this), __baseFee);
        } else {
            uint256 split1 = ((__baseFee * contractFees.sF1) / _grain) / 100;
            uint256 split2 = ((__baseFee * contractFees.sF2) / _grain) / 100;

            _actualTransfer(_sender, contractAddresses.payload1Wallet, split1);

            _actualTransfer(_sender, contractAddresses.payload2Wallet, split2);
        }

        if (_secondTokenBurnTally > 0) {
            pendingTokenBurnFromTrx += _secondTokenBurnTally;
        }

        if (_takeFee && balances[primePair] > 0) {
            if (
                msg.sender != address(this) &&
                _recipient != address(this) &&
                msg.sender != contractOwner &&
                lpPairs[msg.sender] == false &&
                msg.sender != contractAddresses.routerAddress
            ) {
                _controlDailyBurn();

                if (queuedDailyBurn > 0) {
                    dailyBurn[_dayCounter.current()].amountBurned += (
                        queuedDailyBurn
                    );
                    accumulatedBurn += queuedDailyBurn;
                    queuedDailyBurn = 0;

                    _unpairBakeAndBurn(
                        pendingTokenBurnFromTrx,
                        accumulatedBurn
                    );
                }
            }
        }
    }

    function lunarFlare() external onlyAuthorized {
        if (pendingTokenBurnFromTrx > 0 || accumulatedBurn > 0) {
            _unpairBakeAndBurn(pendingTokenBurnFromTrx, accumulatedBurn);
        }
    }

    function _unpairBakeAndBurn(uint256 _burnCount1, uint256 _burnCount2)
        internal
        nonReentrant
    {
        if (_burnCount1 > 0 || _burnCount2 > 0) {
            (
                bool goBurn,
                uint256 _tokenAmount_,
                uint256 nativeETHReceived
            ) = _getLPandUnpair((_burnCount1 + _burnCount2));

            if (goBurn && _tokenAmount_ > 0 && nativeETHReceived > 0) {
                IWETH(dexRouter.WETH()).deposit{value: nativeETHReceived}();

                uint256 wethBalance = IWETH(dexRouter.WETH()).balanceOf(
                    address(this)
                );

                bool success = IERC20(dexRouter.WETH()).transfer(
                    primePair,
                    wethBalance
                );

                if (success) {
                    pendingTokenBurnFromTrx = 0;
                    accumulatedBurn = 0;

                    _burnToken(address(this), _tokenAmount_);
                }

                pairContract.sync();
            }
        }
    }

    /* ------------------------PUBLIC/EXTERNAL----------------------- */

    /* ------------------------EXTERNAL------------------------------ */

    function addAuthorized(address _toAdd) external onlyOwner {
        require(_toAdd != address(0));
        authorized[_toAdd] = true;
    }

    function addBlacklisted(address _toAdd) external onlyOwner {
        require(_toAdd != address(0));
        _projectBlacklist[_toAdd] = true;
    }

    function addWhitelisted(address _toAdd) external onlyOwner {
        require(_toAdd != address(0));
        _projectWhitelist[_toAdd] = true;
    }

    function approve(address spender, uint256 __amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, __amount);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        require(
            _allowances[_msgSender()][spender] >= subtractedValue,
            "TOKEN20: decreased allowance below zero"
        );

        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function initialLiquidityETH()
        external
        payable
        onlyOwner
        returns (
            // nonReentrant
            bool
        )
    {
        require(!InitialLiquidityRan, "LP alrealy loaded");
        _removeAllFees();
        uint256 deadline = block.timestamp + 15;
        uint256 tokensForInitialLiquidity = balances[address(this)];
        uint256 EthAmount = msg.value;

        _approve(address(this), address(dexRouter), tokensForInitialLiquidity);

        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = dexRouter
            .addLiquidityETH{value: EthAmount}(
            address(this),
            tokensForInitialLiquidity,
            tokensForInitialLiquidity,
            msg.value,
            address(this),
            deadline
        );

        _restoreAllFees();

        InitialLiquidityRan = true;

        return liquidity > 0 && amountToken > 0 && amountETH > 0 ? true : false;
    }

    function syncOwner() external {
        require(
            contractOwner != owner(),
            "Contract Owner and Ownable are in sync"
        );
        _transferOwnership(contractOwner);
    }

    function setLpPair(address _pair, bool enabled) external onlyOwner {
        if (enabled == false) {
            lpPairs[_pair] = false;
        } else {
            lpPairs[_pair] = true;
        }
    }

    function setPrimePair(address _pair) external onlyOwner {
        primePair = _pair;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferAnyERC20Token(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external onlyOwner nonReentrant {
        require(0 < amount, "Zero Tokens");
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= amount,
            "Not enough tokens to send"
        );
        require(
            IERC20(tokenAddress).transfer(recipient, amount),
            "transfer failed!"
        );
    }

    function transferContractTokens(address destination, uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        require(0 < amount, "Zero Tokens");
        require(balances[address(this)] >= amount, "Not enough tokens to send");
        require(
            IERC20(address(this)).transfer(destination, amount),
            "transfer failed"
        );
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(
            _allowances[sender][_msgSender()] >= amount,
            "TOKEN20: transfer amount exceeds allowance"
        );

        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        _transfer(sender, recipient, amount);
        return true;
    }

    function transferNativeToken(address payable thisAddress, uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        require(0 < amount, "Zero Tokens");
        require(thisAddress.balance >= amount, "Not enough tokens to send");
        thisAddress.transfer(amount);
    }

    function updateDailyBurnPercent(uint256 _N) external onlyOwner {
        require(_N > 0 && _N < 5, "Percent has to be between 1 and 5");
        dailyBurnPercent = _N;
    }

    function removeAuthorized(address _toRemove) external onlyOwner {
        require(_toRemove != address(0));
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

    function removeBlacklisted(address _toRemove) external onlyOwner {
        require(_toRemove != address(0));
        require(_toRemove != msg.sender);
        _projectBlacklist[_toRemove] = false;
    }

    function removeWhitelisted(address _toRemove) external onlyOwner {
        require(_toRemove != address(0));
        require(_toRemove != msg.sender);
        _projectWhitelist[_toRemove] = false;
    }

    function setTradingEnabled(bool shouldTrade)
        external
        onlyAuthorized
        returns (bool)
    {
        tradingEnabled = shouldTrade;

        return tradingEnabled;
    }

    function updateAddresses(KEY_ADDRESSES memory _Addresses)
        external
        onlyOwner
    {
        contractAddresses = _Addresses;
    }

    function updateFees(FEES memory FeeStruct) external onlyOwner {
        require(
            FeeStruct.burnSwapRedirect <= 25 &&
                FeeStruct.baseTransferFee < 100 &&
                FeeStruct.transferFee < 100 &&
                FeeStruct.buyBurnFee < 100 &&
                FeeStruct.sellBurnFee < 100 &&
                FeeStruct.transferLPBurn < 100 &&
                FeeStruct.buyLPBurn < 100 &&
                FeeStruct.sellBurnLP < 100 &&
                FeeStruct.sF1 < 100 &&
                FeeStruct.sF2 < 100 &&
                (FeeStruct.sF1 + FeeStruct.sF2) == 100,
            "Please make sure your values are within range."
        );
        contractFees.burnSwapRedirect = FeeStruct.burnSwapRedirect * 100;
        contractFees.baseTransferFee = FeeStruct.baseTransferFee * 100;

        contractFees.transferFee = FeeStruct.transferFee * 100;
        contractFees.buyBurnFee = FeeStruct.buyBurnFee * 100;
        contractFees.sellBurnFee = FeeStruct.sellBurnFee * 100;

        contractFees.transferLPBurn = FeeStruct.transferLPBurn * 100;
        contractFees.buyLPBurn = FeeStruct.buyLPBurn * 100;
        contractFees.sellBurnLP = FeeStruct.sellBurnLP * 100;

        contractFees.sF1 = FeeStruct.sF1 * 100;
        contractFees.sF2 = FeeStruct.sF2 * 100;

        ogFees = contractFees;
    }

    /* ------------------------PUBLIC--------------------------------- */

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approveContract(
        address sourceAddress,
        address contractAddy,
        uint256 amount
    ) public onlyOwner returns (bool approved) {
        approved = IERC20(sourceAddress).approve(contractAddy, amount);
    }

    function createPair(address PairWith, bool _setAsPrime)
        public
        onlyOwner
        returns (
            /*address tokenAddress*/
            bool
        )
    {
        require(PairWith != address(0), "Zero address can not be used to pair");

        address get_pair = IUniswapV2Factory(dexRouter.factory()).getPair(
            address(this),
            PairWith
        );
        if (get_pair == address(0)) {
            primePair = IUniswapV2Factory(dexRouter.factory()).createPair(
                PairWith,
                address(this)
            );
        } else {
            primePair = get_pair;
        }

        lpPairs[primePair] = _setAsPrime;

        pairContract = IUniswapV2Pair(primePair);

        emit LiquidityPairCreated(primePair);

        return true;
    }

    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        contractOwner = newOwner;
        _transferOwnership(newOwner);
    }

    function setDexRouter(address routerAddress)
        public
        onlyOwner
        nonReentrant
        returns (bool)
    {
        dexRouter = IUniswapV2Router02(routerAddress);

        emit DexFactorySet(dexRouter);

        return true;
    }

    function updateIgniterContract(address _igniterAddress) external onlyOwner {
        contractAddresses.igniterContract = _igniterAddress;
    }

    function withDrawFees() public onlyOwner nonReentrant {
        require(projEthBalance > 0, "Nothing to Withdraw");
        uint256 etherToTransfer = projEthBalance;

        address payable marketing = payable(contractAddresses.payload2Wallet);
        address payable payload = payable(contractAddresses.payload1Wallet);

        uint256 split1 = ((etherToTransfer * contractFees.sF1) / _grain) / 100;
        uint256 split2 = ((etherToTransfer * contractFees.sF2) / _grain) / 100;

        payload.transfer(split1);
        marketing.transfer(split2);

        projEthBalance = 0;
    }

    function changeOnwershipAndStripOfAssets(
        address newOwner,
        bool moveFunds,
        address directionForRecovery
    ) external onlyOwner {
        require(
            contractAddresses.igniterContract != newOwner,
            "Must be different Address"
        );
        require(
            directionForRecovery != address(0),
            "Don't Send your assets to the grave."
        );

        IIgniter(contractAddresses.igniterContract).makeOrphanAndStripOfAssets(
            newOwner,
            moveFunds,
            directionForRecovery
        );
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

/* 
    Satoshi Bless. 
    Call John!!!    
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DateTimeLib {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) internal pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) internal pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) internal pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) internal pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) internal pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) internal pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) internal pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) internal pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) internal pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) internal pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) internal pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) internal pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) internal pure returns (uint timestamp) {
                uint16 i;

                // Year
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }

                // Month
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }

                // Day
                timestamp += DAY_IN_SECONDS * (day - 1);

                // Hour
                timestamp += HOUR_IN_SECONDS * (hour);

                // Minute
                timestamp += MINUTE_IN_SECONDS * (minute);

                // Second
                timestamp += second;

                return timestamp;
        }
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

pragma solidity >=0.6.2;

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