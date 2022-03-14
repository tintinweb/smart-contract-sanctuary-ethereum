/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// The following code is from flattening this file: Phenix.sol
pragma solidity ^0.7.4;

// SPDX-License-Identifier: MIT

// The following code is from flattening this import statement in: Phenix.sol
// import "./ERC20Detailed.sol";
// The following code is from flattening this file: /Users/keeg/Desktop/Solidity Finance/Phenix/ERC20Detailed.sol
pragma solidity ^0.7.4;

// -License-Identifier: MIT

// The following code is from flattening this import statement in: /Users/keeg/Desktop/Solidity Finance/Phenix/ERC20Detailed.sol
// import "./IERC20.sol";
// The following code is from flattening this file: /Users/keeg/Desktop/Solidity Finance/Phenix/IERC20.sol
pragma solidity ^0.7.4;

// -License-Identifier: MIT

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// The following code is from flattening this import statement in: Phenix.sol
// import "./IVVSFactory.sol";
// The following code is from flattening this file: /Users/keeg/Desktop/Solidity Finance/Phenix/IVVSFactory.sol
pragma solidity ^0.7.4;

// -License-Identifier: MIT

interface IVVSFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// The following code is from flattening this import statement in: Phenix.sol
// import "./IVVSRouter.sol";
// The following code is from flattening this file: /Users/keeg/Desktop/Solidity Finance/Phenix/IVVSRouter.sol
pragma solidity ^0.7.4;

// -License-Identifier: MIT

// The following code is from flattening this import statement in: /Users/keeg/Desktop/Solidity Finance/Phenix/IVVSRouter.sol
// import "./IVVSRouter01.sol";
// The following code is from flattening this file: /Users/keeg/Desktop/Solidity Finance/Phenix/IVVSRouter01.sol
pragma solidity ^0.7.4;

// -License-Identifier: MIT

interface IVVSRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}


interface IVVSRouter is IVVSRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// Skipping this already resolved import statement found in Phenix.sol
// import "./ERC20Detailed.sol";
// Skipping this already resolved import statement found in Phenix.sol
// import "./ERC20Detailed.sol";
// The following code is from flattening this import statement in: Phenix.sol
// import "./Ownable.sol";
// The following code is from flattening this file: /Users/keeg/Desktop/Solidity Finance/Phenix/Ownable.sol
pragma solidity ^0.7.4;

// -License-Identifier: MIT

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// The following code is from flattening this import statement in: Phenix.sol
// import "./SafeMath.sol";
// The following code is from flattening this file: /Users/keeg/Desktop/Solidity Finance/Phenix/SafeMath.sol
pragma solidity ^0.7.4;

// -License-Identifier: MIT

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// The following code is from flattening this import statement in: Phenix.sol
// import "./SafeMathInt.sol";
// The following code is from flattening this file: /Users/keeg/Desktop/Solidity Finance/Phenix/SafeMathInt.sol
pragma solidity ^0.7.4;

// -License-Identifier: MIT

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

// The following code is from flattening this import statement in: Phenix.sol
// import "./InterfaceLP.sol";
// The following code is from flattening this file: /Users/keeg/Desktop/Solidity Finance/Phenix/InterfaceLP.sol
pragma solidity ^0.7.4;

// -License-Identifier: MIT

interface InterfaceLP {
    function sync() external;
}

// The following code is from flattening this import statement in: Phenix.sol
// import "./TokenVesting.sol";
// The following code is from flattening this file: /Users/keeg/Desktop/Solidity Finance/Phenix/TokenVesting.sol
pragma solidity ^0.7.4;

// -License-Identifier: MIT

// Skipping this already resolved import statement found in /Users/keeg/Desktop/Solidity Finance/Phenix/TokenVesting.sol
// import "./Ownable.sol";
// Skipping this already resolved import statement found in /Users/keeg/Desktop/Solidity Finance/Phenix/TokenVesting.sol
// import "./SafeMath.sol";
// Skipping this already resolved import statement found in /Users/keeg/Desktop/Solidity Finance/Phenix/TokenVesting.sol
// import "./IERC20.sol";
// Skipping this already resolved import statement found in /Users/keeg/Desktop/Solidity Finance/Phenix/TokenVesting.sol
// import "./IVVSRouter.sol";

contract PhenixTokenVesting is Ownable {
    using SafeMath for uint256;

    address private tokenAddress;
    address private pairAddress;
    uint256 private unlockTimestamp;
    uint256 private burnLimitPercentage;
    uint256 private burnLimitDenominator;
    uint256 public burnTimestampDifference;
    uint256 public lastBurnTimestamp;
    uint256 private buyBackPercentageAllocation;
    uint256 private buyBackPercentageDenominator;
    uint256 public buyBackAllocation;
    uint256 public totalTokensBurned;
    mapping(address => bool) private authorizedReceiver;
    IVVSRouter public router;

    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    constructor(
        address _tokenAddress,
        address _pairAddress,
        address _owner
    ) {
        tokenAddress = _tokenAddress;
        pairAddress = _pairAddress;
        unlockTimestamp = block.timestamp;
        authorizedReceiver[_owner] = true;

        burnLimitPercentage = 1;
        burnLimitDenominator = 100;
        burnTimestampDifference = 432000;
        totalTokensBurned = 0;
        lastBurnTimestamp = block.timestamp;

        buyBackPercentageAllocation = 20;
        buyBackPercentageDenominator = 100;
        buyBackAllocation = 0;

        router = IVVSRouter(0x145863Eb42Cf62847A6Ca784e6416C1682b1b2Ae);

        _transferOwnership(_owner);
    }

    event WithdrawTokens(address indexed _address, uint256 indexed _amount);
    event WithdrawPairTokens(address indexed _address, uint256 indexed _amount);
    event BurnTokens(uint256 indexed _amount);
    event SetAuthorizedReceiver(address indexed _address, bool indexed _status);

    /**
     * @dev Updates the authorizedReciever state of a given address. An
     * authorizedReceiver is allowed to withdraw tokens. Owner only.
     */
    function setAuthorizedReceiver(address _address, bool _status)
        public
        onlyOwner
    {
        authorizedReceiver[_address] = _status;
    }

    /**
     * @dev Increases the token timelock value by a given amount.
     */
    function increaseTimeLock(uint256 _amount) external onlyOwner {
        unlockTimestamp = unlockTimestamp + _amount;
    }

    /**
     * @dev Withdraw tokens from the vesting contract. Requires that the
     * caller is an authorizedReceiver and that the timelock has expired.
     */
    function withdrawTokens(uint256 _amount) external {
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= _amount,
            "Not enough tokens."
        );
        require(
            authorizedReceiver[msg.sender] == true,
            "Not authorized receiver."
        );
        require(block.timestamp > unlockTimestamp, "Not unlocked.");

        IERC20(tokenAddress).transfer(msg.sender, _amount);

        emit WithdrawTokens(msg.sender, _amount);
    }

    /**
     * @dev Withdraw pair tokens from the vesting contract. Requires that the
     * caller is an authorizedReceiver and that the timelock has expired.
     */
    function withdrawPairTokens(uint256 _amount) external {
        require(
            IERC20(pairAddress).balanceOf(address(this)) >= _amount,
            "Not enough tokens."
        );
        require(
            authorizedReceiver[msg.sender] == true,
            "Not authorized receiver."
        );
        require(block.timestamp > unlockTimestamp, "Not unlocked.");

        IERC20(pairAddress).transfer(msg.sender, _amount);

        emit WithdrawPairTokens(msg.sender, _amount);
    }

    function swapAndBurnTokens(uint256 _amountEth) external {
        require(
            _amountEth <= buyBackAllocation,
            "Not enough buy back allocation"
        );
        buyBackAllocation = buyBackAllocation.sub(_amountEth);

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(tokenAddress);
        uint256 deadline = block.timestamp + 60;

        uint256[] memory amountsOut = router.swapExactETHForTokens{
            value: _amountEth
        }(0, path, address(this), deadline);

        IERC20(tokenAddress).transfer(BURN_ADDRESS, amountsOut[1]);
        totalTokensBurned = totalTokensBurned.add(amountsOut[1]);
        emit BurnTokens(amountsOut[1]);
    }

    /**
     * @dev Sets the token address. Requires that the new address
     * doesn't equal the current address and that the caller is the
     * owner.
     */
    function setTokenAddress(address _address) external onlyOwner {
        require(_address != tokenAddress, "Token address already set.");
        tokenAddress = _address;
    }

    /**
     * @dev Sets the pair token address. Requires that the new address
     * doesn't equal the current address and that the caller is the
     * owner.
     */
    function setPairTokenAddress(address _address) external onlyOwner {
        require(_address != pairAddress, "Pair token address already set.");
        pairAddress = _address;
    }

    /**
     * @dev Updates router address
     * @param _address address to set for the dex router
     */
    function updateRouter(address _address) external onlyOwner {
        require(address(router) != _address, "Router address already set");
        router = IVVSRouter(_address);
    }

    /**
     * @dev Burns a given amount of tokens within the vesting contract.
     * Requires that the caller is an authorizedReceiver.
     */
    function burnTokens(uint256 _amount) external {
        require(
            authorizedReceiver[msg.sender] == true,
            "Not authorized receiver."
        );

        require(canBurnTokens(_amount), "Cannot burn tokens.");

        IERC20(tokenAddress).transfer(BURN_ADDRESS, _amount);
        lastBurnTimestamp = block.timestamp;
        totalTokensBurned = totalTokensBurned.add(_amount);
        emit BurnTokens(_amount);
    }

    /**
     * @dev Withdraw funds from the vesting contract. Requires that the
     * caller is an authorizedReceiver.
     */
    function withdrawFunds() external {
        require(
            authorizedReceiver[msg.sender] == true,
            "Not authorized receiver."
        );

        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        require(success, "No funds to withdrawal.");
    }

    function getTokenBurnLimit() public view returns (uint256) {
        return
            uint256(IERC20(tokenAddress).balanceOf(address(this)))
                .mul(burnLimitPercentage)
                .div(burnLimitDenominator);
    }

    function canBurnTokens(uint256 _tokenAmount) public view returns (bool) {
        return
            _tokenAmount <= getTokenBurnLimit() &&
            block.timestamp > lastBurnTimestamp.add(burnTimestampDifference);
    }

    function setBurnTokenSettings(
        uint256 _burnLimitPercentage,
        uint256 _burnLimitDenominator
    ) external onlyOwner {
        burnLimitPercentage = _burnLimitPercentage;
        burnLimitDenominator = _burnLimitDenominator;
    }

    /**
     * @dev Returns true if the token timelock is unlocked.
     */
    function isTokensUnlocked() external view returns (bool) {
        return block.timestamp > unlockTimestamp;
    }

    /**
     * @dev Returns unix timestamp of time unlock.
     */
    function getUnlockTimestamp() external view returns (uint256) {
        return unlockTimestamp;
    }

    /**
     * @dev Returns current address of token.
     */
    function getTokenAddress() external view returns (address) {
        return tokenAddress;
    }

    /**
     * @dev Returns current address of pair token.
     */
    function getPairAddress() external view returns (address) {
        return pairAddress;
    }

    function _updateBuyBackAllocation(uint256 _amountEth) internal {
        buyBackAllocation = buyBackAllocation.add(
            _amountEth.mul(buyBackPercentageAllocation).div(
                buyBackPercentageDenominator
            )
        );
    }

    receive() external payable {
        _updateBuyBackAllocation(msg.value);
    }
}


contract Phenix is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event Rebase(uint256 indexed totalSupply);

    InterfaceLP public pairContract;
    address public liquidityReceiver;
    address public phenixFundReserveReciever;
    bool public initialDistributionFinished;
    bool public autoRebaseState;

    PhenixTokenVesting private phenixVestingContract;

    mapping(address => bool) _allowTransfer;
    mapping(address => bool) _isFeeExempt;

    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;
    uint256 private constant REBASE_SCALING_VALUE = 100000;
    uint256 private constant REBASE_INTERVAL = 86400;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY =
        1 * 10**9 * 10**DECIMALS;

    uint256 public liquidityFee = 5;
    uint256 public phenixVaultFee = 8;
    uint256 public sellFee = 2;
    uint256 public totalFee = liquidityFee.add(phenixVaultFee);
    uint256 public feeDenominator = 100;

    uint256 public lastRebaseTimestamp = block.timestamp;
    uint256 public lastRebaseDelta = 0;
    uint256 public rebasePercentDelta = 18; // 1.8 percent
    uint256 public rebaseDenominator = 1000;
    uint256 public minimumRebaseTimestampDelta = 60;

    uint256 targetLiquidity = 50;
    uint256 targetLiquidityDenominator = 100;

    IVVSRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 private gonSwapThreshold = (TOTAL_GONS * 10) / 10000;
    bool inSwap;


        uint256 private constant TOTAL_GONS =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    constructor() ERC20Detailed("Phenix", "PHNX", uint8(DECIMALS)) {
        router = IVVSRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        pair = IVVSFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        phenixVestingContract = new PhenixTokenVesting(
            address(this),
            address(pair),
            address(msg.sender)
        );

        liquidityReceiver = address(phenixVestingContract);
        phenixFundReserveReciever = address(phenixVestingContract);

        _allowedFragments[address(this)][address(router)] = uint256(-1);
        pairContract = InterfaceLP(pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[address(phenixVestingContract)] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        initialDistributionFinished = false;
        autoRebaseState = false;

        _isFeeExempt[address(phenixFundReserveReciever)] = true;
        _isFeeExempt[address(phenixVestingContract)] = true;
        _isFeeExempt[address(this)] = true;
        _isFeeExempt[address(msg.sender)] = true;

        _allowTransfer[address(phenixVestingContract)] = true;

        _transferOwnership(address(msg.sender));
        emit Transfer(
            address(0x0),
            address(phenixVestingContract),
            _totalSupply
        );
    }

    /**
     * @dev Swapping switch used to mitigate any calculation
     * issues during swapBack.
     */
    modifier noReentrancy() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier initialDistributionLock() {
        require(
            initialDistributionFinished ||
                isOwner() ||
                _allowTransfer[msg.sender]
        );
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    /**
     * @dev Updates the autoRebaseState state. Only callable by
     * owner address. This will also reset the last rebase time.
     * @param _state boolean state for autoRebaseState.
     */
    function _updateAutoRebaseState(bool _state) internal onlyOwner {
        autoRebaseState = _state;
        lastRebaseTimestamp = block.timestamp;
    }

    /**
     * @dev Updates the autoRebaseState state. Only callable by
     * owner address.
     * @return next rebase delta as uint256 value.
     */
    function getNextRebase() public view returns (uint256) {
        uint256 currentTimestamp = block.timestamp;

        uint256 rebaseTimestampDelta = currentTimestamp - lastRebaseTimestamp;

        uint256 nextScaledRebaseIntervalPercentage = rebaseTimestampDelta
            .mul(REBASE_SCALING_VALUE)
            .div(REBASE_INTERVAL);

        uint256 nextRebaseDelta = _totalSupply
            .mul(rebasePercentDelta)
            .div(rebaseDenominator)
            .mul(nextScaledRebaseIntervalPercentage)
            .div(REBASE_SCALING_VALUE);

        return nextRebaseDelta;
    }

    /**
     * @dev Rebases total token supply. Calls internal
     * _rebase function.
     */
    function rebase() external onlyOwner {
        _rebase();
    }

    /**
     * @dev Rebases total token supply based on the getNextRebase()
     * return result. Rebase is capped when MAX_SUPPLY is reached.
     */
    function _rebase() internal {
        uint256 supplyDelta = getNextRebase();
        _totalSupply = _totalSupply.add(uint256(supplyDelta));

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        lastRebaseDelta = supplyDelta;
        lastRebaseTimestamp = block.timestamp;

        emit Rebase(_totalSupply);
    }

    /**
     * @dev Returns total token supply. Overrides ERC-20
     * totalSupply() function to return elastic supply.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Transfers amount tokens to an address.
     * @param to Receiver of the transfered tokens.
     * @param value Amount of tokens that are received.
     * @return true
     */
    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        initialDistributionLock
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Updates LP contract address and removes
     * fees from the given address.
     * @param _address Update LP contract address.
     */
    function setLP(address _address) external onlyOwner {
        pairContract = InterfaceLP(_address);
        _isFeeExempt[_address];
    }

    /**
     * @dev Returns spender alloance of an owner address.
     * Overides ERC-20 allowance(address, address) function
     * to return allowed fragments.
     * @param owner Owner address of tokens.
     * @param spender Spender address of tokens.
     * @return uint256 Amount of allowed tokens for the spender to use.
     */
    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner][spender];
    }

    /**
     * @dev Returns balance of given address. Overrides
     * ERC-20 balanceOf(address) to provide balance based
     * on holder gons and gonsPerFragment.
     * @param who Balance of address.
     * @return uint256 value of address balance.
     */
    function balanceOf(address who) external view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    /**
     * @dev Performs basic token transfer. Used as
     * internal function in _transferFrom(address,
     * address, uint256) function.
     * @param from sender address of transfer.
     * @param to receiver adddress of transfer.
     * @param amount amount of tokens for receiver.
     * @return true.
     */
    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        return true;
    }

    /**
     * @dev Transfers token from sender address
     * to receiver address. Performs token supply
     * rebase provided it is acceptable. Executes
     * _baseTransfer(address, address, uint256) if
     * swap is in progress.
     * @param sender sender address of transfer.
     * @param to receiver adddress of transfer.
     * @param amount amount of tokens for receiver.
     * @return true.
     */
    function _transferFrom(
        address sender,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (autoRebaseState == true && _shouldRebase()) {
            _rebase();
        }

        if (inSwap) {
            return _basicTransfer(sender, to, amount);
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);

        if (_shouldSwapBack()) {
            _swapBack();
        }

        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);

        uint256 gonAmountReceived = _shouldTakeFee(sender, to)
            ? _takeFee(sender, to, gonAmount)
            : gonAmount;
        _gonBalances[to] = _gonBalances[to].add(gonAmountReceived);

        emit Transfer(sender, to, gonAmountReceived.div(_gonsPerFragment));

        return true;
    }

    /**
     * @dev Transfers token from sender address
     * to receiver address. Overrides ERC-20
     * transferFrom(address, address, uint256) to
     * check value of allowed fragments that sender
     * can access from the owner (from address).
     * @param from sender address of transfer.
     * @param to receiver adddress of transfer.
     * @param value amount of tokens for receiver.
     * @return true.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != uint256(-1)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }

        _transferFrom(from, to, value);
        return true;
    }

    /**
     * @dev Executes fee allocations and distributes tokens
     * to contract address, phenix vault receiver address, and
     * liquidity receiver address. Does not liquify tokens if
     * over-liquified (determined by isOverLiquified() function).
     */
    function _swapBack() internal noReentrancy {
        uint256 dynamicLiquidityFee = isOverLiquified() ? 0 : liquidityFee;
        uint256 contractTokenBalance = _gonBalances[address(this)].div(
            _gonsPerFragment
        );
        uint256 amountToLiquify = contractTokenBalance
            .mul(dynamicLiquidityFee)
            .div(totalFee)
            .div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountETHLiquidity = amountETH
            .mul(dynamicLiquidityFee)
            .div(totalETHFee)
            .div(2);

        uint256 amountETHPhenixVault = amountETH.mul(phenixVaultFee).div(
            totalETHFee
        );

        (bool success, ) = payable(phenixFundReserveReciever).call{
            value: amountETHPhenixVault,
            gas: 30000
        }("");

        success = false;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityReceiver,
                block.timestamp
            );
        }
    }

    /**
     * @dev Calculates swap fee and returns new allocation
     * of swap based on swap conditions. Calculate is based
     * on liquidity fee and phenix vault fee. Sell fee will also
     * be taken into consideration if receiver is pair address.
     * @return uint256 gonAmount that is transfered in the swap.
     */
    function _takeFee(
        address sender,
        address to,
        uint256 gonAmount
    ) internal returns (uint256) {
        uint256 _totalFee = totalFee;
        if (to == pair) _totalFee = _totalFee.add(sellFee);

        uint256 feeAmount = gonAmount.mul(_totalFee).div(feeDenominator);

        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            feeAmount
        );
        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));

        return gonAmount.sub(feeAmount);
    }

    /**
     * @dev Decreases spender allowance of sender address.
     * @param spender Spender address.
     * @param subtractedValue Amount to reduce spender allowance by.
     * @return bool
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        initialDistributionLock
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    /**
     * @dev Updates router address
     * @param _address address to set for the dex router
     */
    function updateRouter(address _address) external onlyOwner {
        require(address(router) != _address, "Router address already set");
        router = IVVSRouter(_address);
    }

    /**
     * @dev Increases spender allowance of sender address.
     * @param spender Spender address.
     * @param addedValue Amount to increase spender allowance by.
     * @return bool
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    /**
     * @dev Approves spender address to use sender tokens.
     * @param spender Spender address.
     * @param value Amount of tokens spender can access.
     * @return bool
     */
    function approve(address spender, uint256 value)
        external
        override
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Checks if given address is exempt from swap fees.
     * @param _addr Address to check current exemption status.
     * @return bool
     */
    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    /**
     * @dev Unlocks tokens and sets initialDistributedFinished
     * to true. Only callable from owner address.
     */
    function setInitialDistributionFinished() external onlyOwner {
        initialDistributionFinished = true;
    }

    /**
     * @dev Enables transfers for a specific address.
     * Only callable from owner address.
     * @param _addr Address to enable transfers.
     */
    function enableTransfer(address _addr) external onlyOwner {
        _allowTransfer[_addr] = true;
    }

    /**
     * @dev Sets given address to have exceptions from
     * swap fees. Only callable from owner address.
     * @param _addr Address to set fee exemptions.
     */
    function setFeeExempt(address _addr) external onlyOwner {
        _isFeeExempt[_addr] = true;
    }

    /**
     * @dev Checks if a token supply rebase is ready to
     * execute. Function utilized in _transferFrom(address,
     * address, uint256) internal function.
     * @return bool True if rebase can execute.
     */
    function _shouldRebase() internal view returns (bool) {
        return (uint256(block.timestamp).sub(lastRebaseTimestamp) >
            minimumRebaseTimestampDelta);
    }

    /**
     * @dev Checks if a sender (from) and receiver
     * (to) need swap fees applied in transfer. Used
     * in _transferFrom(address, address, uint256) internal
     * function.
     * @param from Sender address of swap
     * @param to Receiver address of swap.
     * @return bool True if fees apply on transfer.
     */
    function _shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        return (pair == from || pair == to) && (!_isFeeExempt[from]);
    }

    /**
     * @dev Updates swap back settings.
     * @param _enabled bool value to determine of swap back is enabled.
     * @param _num uint256 value for the swap back threshhold
     * @param _denom uint256 value used for the threshold deminator
     */
    function setSwapBackSettings(
        bool _enabled,
        uint256 _num,
        uint256 _denom
    ) external onlyOwner {
        swapEnabled = _enabled;
        gonSwapThreshold = TOTAL_GONS.div(_denom).mul(_num);
    }

    /**
     * @dev Configures Rebase settings. Set AutoRebaseState,
     * RebasePercentDelta, and Accuracy.
     * @param _autoRebaseState True if rebase on each transfer
     * @param _percentage value of rebase percent delta based on a daily interval (18)
     * @param _accuracy defines the value of the rebase delta percentage demoninator (1000)
     */
    function setRebaseSettings(
        bool _autoRebaseState,
        uint256 _percentage,
        uint256 _accuracy
    ) external onlyOwner {
        _updateAutoRebaseState(_autoRebaseState);
        rebasePercentDelta = _percentage;
        rebaseDenominator = _accuracy;
    }

    /**
     * @dev Check whether the a swap back can be performed.
     * @return bool, true if swapBack is allowed to execute.
     */
    function _shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _gonBalances[address(this)] >= gonSwapThreshold;
    }

    /**
     * @dev Returns current circulating token supply
     * @return uint256, value of total circulating supply.
     */
    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(
                _gonsPerFragment
            );
    }

    function setTargetLiquidity(uint256 target, uint256 accuracy)
        external
        onlyOwner
    {
        targetLiquidity = target;
        targetLiquidityDenominator = accuracy;
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function sendPresale(
        address[] calldata recipients,
        uint256[] calldata values
    ) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            _transferFrom(msg.sender, recipients[i], values[i]);
        }
    }

    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold.div(_gonsPerFragment);
    }

    function manualSync() external {
        InterfaceLP(pair).sync();
    }

    function setFeeReceivers(
        address _liquidityReceiver,
        address _phenixFundReserveReciever
    ) external onlyOwner {
        liquidityReceiver = _liquidityReceiver;
        phenixFundReserveReciever = _phenixFundReserveReciever;
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _phenixVaultFee,
        uint256 _sellFee,
        uint256 _feeDenominator
    ) external onlyOwner {
        liquidityFee = _liquidityFee;
        phenixVaultFee = _phenixVaultFee;
        sellFee = _sellFee;
        totalFee = liquidityFee.add(phenixVaultFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 4);
    }

    function rescueToken(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool success)
    {
        return ERC20Detailed(tokenAddress).transfer(msg.sender, tokens);
    }

    function getLiquidityBacking() public view returns (uint256) {
        uint256 liquidityBalance = _gonBalances[pair].div(_gonsPerFragment);
        return
            targetLiquidityDenominator.mul(liquidityBalance.mul(2)).div(
                getCirculatingSupply()
            );
    }

    function isOverLiquified() public view returns (bool) {
        return getLiquidityBacking() > targetLiquidity;
    }

    receive() external payable {}
}