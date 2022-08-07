// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAmplifi.sol";
import "./interfaces/IUniswap.sol";
import "./AmplifiNode.sol";
import "./Types.sol";

/**
 * Amplifi
 * Website: https://perpetualyield.io/
 * Telegram: https://t.me/Amplifi_ERC
 * Twitter: https://twitter.com/amplifidefi
 */
contract Amplifi is IERC20, IAmplifi, Ownable {
    string public constant name = "Amplifi";
    string public constant symbol = "AMPLIFI";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 121_373e18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    IERC20 public immutable WETH;
    IERC20 public immutable USDC;

    IUniswapV2Router02 public immutable router;
    address public immutable pair;

    AmplifiNode public amplifiNode;
    address private amplifiNodeAddress;

    uint256 public maxWallet = type(uint256).max;

    mapping(address => bool) public isDisabledExempt;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isMaxExempt;
    mapping(address => bool) public isUniswapPair;

    // Fees are charged on swaps
    Types.FeeRecipients public feeRecipients;
    Types.Fees public fees;
    uint16 public feeTotal = 900;

    // Taxes are charged on transfers and burned
    uint16 public tax = 300;

    // Basis for all fee and tax values
    uint16 public constant bps = 10_000;

    bool public contractSellEnabled = true;
    uint256 public contractSellThreshold = 65e18;
    uint256 public minSwapAmountToTriggerContractSell = 0;

    bool public mintingEnabled = true;
    bool public burningEnabled = true;
    bool public tradingEnabled = false;
    bool public isContractSelling = false;

    modifier contractSelling() {
        isContractSelling = true;
        _;
        isContractSelling = false;
    }

    constructor(
        address _router,
        address _usdc,
        address _gampVault
    ) {
        router = IUniswapV2Router02(_router);
        USDC = IERC20(_usdc);

        pair = IUniswapV2Factory(router.factory()).createPair(address(USDC), address(this));

        WETH = IERC20(router.WETH());

        amplifiNode = new AmplifiNode(this, router, USDC, msg.sender);
        amplifiNodeAddress = address(amplifiNode);

        isDisabledExempt[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        isMaxExempt[msg.sender] = true;
        isDisabledExempt[amplifiNodeAddress] = true;
        isFeeExempt[amplifiNodeAddress] = true;
        isMaxExempt[amplifiNodeAddress] = true;
        isDisabledExempt[address(0)] = true;
        isFeeExempt[address(0)] = true;
        isMaxExempt[address(0)] = true;
        isMaxExempt[address(this)] = true;
        isUniswapPair[pair] = true;

        allowance[address(this)][address(router)] = type(uint256).max;

        feeRecipients = Types.FeeRecipients(
            0xc766B8c9741BC804FCc378FdE75560229CA3AB1E,
            0x682Ce32507D2825A540Ad31dC4C2B18432E0e5Bd,
            0x146f0Af003d2eB9B06a1900F5de9d01708072c3f,
            0x394110aceF86D93b20705d2Df00bE1629ce741De,
            0x8C3F0b1Bd87965bE0dc01A9b7fc3003abec1A3CB,
            0xbE328EAAe2199409a447c4121C7979fFfAaCd4d5,
            _gampVault,
            0x74B605FD7cfC830A862Ee6F2F2e1007608B4b2fF,
            0x5A23C387112e8e213B0755191e7d1cdC26b0C1b2,
            0x6f967da9c0E1764159408988fDcF6c3B7Bf0F9F7,
            0x454cD1e89df17cDB61D868C6D3dBC02bC2c38a17
        );

        fees = Types.Fees(175, 87, 87, 87, 44, 44, 44, 44, 44, 44, 200);

        uint256 toEmissions = 39_000e18;
        uint256 toDeployer = totalSupply - toEmissions;

        balanceOf[msg.sender] = toDeployer;
        emit Transfer(address(0), msg.sender, toDeployer);

        balanceOf[amplifiNodeAddress] = toEmissions;
        emit Transfer(address(0), amplifiNodeAddress, toEmissions);
    }

    function mint(uint256 _amount) external onlyOwner {
        require(mintingEnabled, "Minting is disabled");

        totalSupply += _amount;
        unchecked {
            balanceOf[msg.sender] += _amount;
        }
        emit Transfer(address(0), msg.sender, _amount);
    }

    function burn(address _burnee, uint256 _amount) external onlyOwner returns (bool) {
        require(burningEnabled, "Burning is disabled");
        require(balanceOf[_burnee] >= _amount, "Cannot burn more than an account has");

        totalSupply -= _amount;

        balanceOf[_burnee] -= _amount;
        emit Transfer(_burnee, address(0), _amount);
        return true;
    }

    function burnForAmplifier(address _burnee, uint256 _amount) external returns (bool) {
        require(msg.sender == address(amplifiNode), "Only the Amplifier Node contract can burn");
        require(balanceOf[_burnee] >= _amount, "Cannot burn more than an account has");

        uint256 allowed = allowance[_burnee][msg.sender];
        if (allowed != type(uint256).max) {
            allowance[_burnee][msg.sender] = allowed - _amount;
        }

        totalSupply -= _amount;

        balanceOf[_burnee] -= _amount;
        emit Transfer(_burnee, address(0), _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        return _transferFrom(msg.sender, _recipient, _amount);
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        uint256 allowed = allowance[_sender][msg.sender];
        if (allowed != type(uint256).max) {
            allowance[_sender][msg.sender] = allowed - _amount;
        }

        return _transferFrom(_sender, _recipient, _amount);
    }

    function _transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private returns (bool) {
        if (isContractSelling) {
            return _simpleTransfer(_sender, _recipient, _amount);
        }

        require(tradingEnabled || isDisabledExempt[_sender], "Trading is currently disabled");

        bool sell = isUniswapPair[_recipient] || _recipient == address(router);

        if (!sell && !isMaxExempt[_recipient]) {
            require((balanceOf[_recipient] + _amount) <= maxWallet, "Max wallet has been triggered");
        }

        if (
            sell &&
            _amount >= minSwapAmountToTriggerContractSell &&
            !isUniswapPair[msg.sender] &&
            !isContractSelling &&
            contractSellEnabled &&
            balanceOf[address(this)] >= contractSellThreshold
        ) {
            _contractSell();
        }

        balanceOf[_sender] -= _amount;

        uint256 amountAfter = _amount;
        if (
            ((isUniswapPair[_sender] || _sender == address(router)) ||
                (isUniswapPair[_recipient] || _recipient == address(router)))
                ? !isFeeExempt[_sender] && !isFeeExempt[_recipient]
                : false
        ) {
            amountAfter = _collectFee(_sender, _amount);
        } else if (!isFeeExempt[_sender] && !isFeeExempt[_recipient]) {
            amountAfter = _collectTax(_sender, _amount);
        }

        unchecked {
            balanceOf[_recipient] += amountAfter;
        }
        emit Transfer(_sender, _recipient, amountAfter);

        return true;
    }

    function _simpleTransfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private returns (bool) {
        balanceOf[_sender] -= _amount;
        unchecked {
            balanceOf[_recipient] += _amount;
        }
        return true;
    }

    function _contractSell() private contractSelling {
        uint256 ethBefore = address(this).balance;

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = address(USDC);
        path[2] = address(WETH);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            balanceOf[address(this)],
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 ethAfter = address(this).balance - ethBefore;

        if (ethAfter > bps) {
            bool success;
            (success, ) = feeRecipients.operations.call{value: (ethAfter * fees.operations) / bps}("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.validatorAcquisition.call{value: (ethAfter * fees.validatorAcquisition) / bps}(
                ""
            );
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.PCR.call{value: (ethAfter * fees.PCR) / bps}("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.yield.call{value: (ethAfter * fees.yield) / bps}("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.xChainValidatorAcquisition.call{
                value: (ethAfter * fees.xChainValidatorAcquisition) / bps
            }("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.indexFundPools.call{value: (ethAfter * fees.indexFundPools) / bps}("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.gAMPRewardsPool.call{value: (ethAfter * fees.gAMPRewardsPool) / bps}("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.OTCSwap.call{value: (ethAfter * fees.OTCSwap) / bps}("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.rescueFund.call{value: (ethAfter * fees.rescueFund) / bps}("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.protocolImprovement.call{value: (ethAfter * fees.protocolImprovement) / bps}(
                ""
            );
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.developers.call{value: (ethAfter * fees.developers) / bps}("");
            require(success, "Could not send ETH");
        }
    }

    function _collectFee(address _sender, uint256 _amount) private returns (uint256) {
        uint256 feeAmount = (_amount * feeTotal) / bps;

        unchecked {
            balanceOf[address(this)] += feeAmount;
        }
        emit Transfer(_sender, address(this), feeAmount);

        return _amount - feeAmount;
    }

    function _collectTax(address _sender, uint256 _amount) private returns (uint256) {
        uint256 taxAmount = (_amount * tax) / bps;

        totalSupply -= taxAmount;

        emit Transfer(_sender, address(0), _amount);

        return _amount - taxAmount;
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        maxWallet = _maxWallet;
    }

    function setIsDisabledExempt(address _holder, bool _exempt) external onlyOwner {
        isDisabledExempt[_holder] = _exempt;
    }

    function setIsFeeExempt(address _holder, bool _exempt) external onlyOwner {
        isFeeExempt[_holder] = _exempt;
    }

    function setIsMaxExempt(address _holder, bool _exempt) external onlyOwner {
        isMaxExempt[_holder] = _exempt;
    }

    function setIsUniswapPair(address _pair, bool _isPair) external onlyOwner {
        isUniswapPair[_pair] = _isPair;
    }

    function setContractSelling(
        bool _contractSellEnabled,
        uint256 _contractSellThreshold,
        uint256 _minSwapAmountToTriggerContractSell
    ) external onlyOwner {
        contractSellEnabled = _contractSellEnabled;
        contractSellThreshold = _contractSellThreshold;
        minSwapAmountToTriggerContractSell = _minSwapAmountToTriggerContractSell;
    }

    function setFees(Types.Fees calldata _fees) external onlyOwner {
        fees = _fees;

        feeTotal =
            _fees.operations +
            _fees.validatorAcquisition +
            _fees.PCR +
            _fees.yield +
            _fees.xChainValidatorAcquisition +
            _fees.indexFundPools +
            _fees.gAMPRewardsPool +
            _fees.OTCSwap +
            _fees.rescueFund +
            _fees.protocolImprovement +
            _fees.developers;
    }

    function setFeeRecipients(Types.FeeRecipients calldata _feeRecipients) external onlyOwner {
        feeRecipients = _feeRecipients;
    }

    function setTax(uint16 _tax) external onlyOwner {
        tax = _tax;
    }

    function setTradingEnabled(bool _enabled) external onlyOwner {
        tradingEnabled = _enabled;
    }

    function setAmplifiNode(AmplifiNode _amplifiNode) external onlyOwner {
        amplifiNode = _amplifiNode;
        amplifiNodeAddress = address(amplifiNode);

        isDisabledExempt[amplifiNodeAddress] = true;
        isFeeExempt[amplifiNodeAddress] = true;
        isMaxExempt[amplifiNodeAddress] = true;
    }

    function permanentlyDisableMinting() external onlyOwner {
        mintingEnabled = false;
    }

    function permanentlyDisableBurning() external onlyOwner {
        burningEnabled = false;
    }

    function withdrawETH(address _recipient) external onlyOwner {
        (bool success, ) = _recipient.call{value: address(this).balance}("");
        require(success, "Could not send ETH");
    }

    function withdrawToken(IERC20 _token, address _recipient) external onlyOwner {
        _token.transfer(_recipient, _token.balanceOf(address(this)));
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IAmplifi is IERC20 {
    function burnForAmplifier(address _burnee, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner, address indexed spender, uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value)
        external
        returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    )
        external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0, address indexed token1, address pair, uint256
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

interface IUniswapV2Router01 {
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
        returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        returns (uint256 amountETH);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAmplifi.sol";
import "./interfaces/IUniswap.sol";
import "./FusePool.sol";
import "./Types.sol";

contract AmplifiNode is Ownable, ReentrancyGuard {
    uint16 public maxMonths = 6;
    uint16 public maxAmplifiersPerMinter = 96;
    uint256 public gracePeriod = 30 days;
    uint256 public gammaPeriod = 72 days;
    uint256 public fuseWaitPeriod = 90 days;

    uint256 public totalAmplifiers = 0;
    mapping(uint256 => Types.Amplifier) public amplifiers;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(uint256 => uint256)) public ownedAmplifiers;
    mapping(uint256 => uint256) public ownedAmplifiersIndex;

    mapping(Types.FuseProduct => uint256) public fuseLockDurations;
    mapping(Types.FuseProduct => FusePool) public fusePools;
    mapping(Types.FuseProduct => uint256) public boosts;

    uint256 public creationFee = 0;
    uint256 public renewalFee = 0.006 ether;
    uint256 public fuseFee = 0.007 ether;
    uint256 public mintPrice = 20e18;

    uint256[20] public rates = [
        700000000000,
        595000000000,
        505750000000,
        429887500000,
        365404375000,
        310593718750,
        264004660937,
        224403961797,
        190743367527,
        162131862398,
        137812083039,
        117140270583,
        99569229995,
        84633845496,
        71938768672,
        61147953371,
        51975760365,
        44179396311,
        37552486864,
        31919613834
    ];

    IAmplifi public immutable amplifi;
    IUniswapV2Router02 public immutable router;
    IERC20 public immutable USDC;

    Types.AmplifierFeeRecipients public feeRecipients;

    uint16 public claimFee = 600;
    // Basis for above fee values
    uint16 public constant bps = 10_000;

    constructor(
        IAmplifi _amplifi,
        IUniswapV2Router02 _router,
        IERC20 _usdc,
        address _owner
    ) {
        transferOwnership(_owner);
        amplifi = _amplifi;
        router = _router;
        USDC = _usdc;

        feeRecipients = Types.AmplifierFeeRecipients(
            0xc766B8c9741BC804FCc378FdE75560229CA3AB1E,
            0x682Ce32507D2825A540Ad31dC4C2B18432E0e5Bd,
            0x454cD1e89df17cDB61D868C6D3dBC02bC2c38a17
        );

        fuseLockDurations[Types.FuseProduct.OneYear] = 365 days;
        fuseLockDurations[Types.FuseProduct.ThreeYears] = 365 days * 3;
        fuseLockDurations[Types.FuseProduct.FiveYears] = 365 days * 5;

        fusePools[Types.FuseProduct.OneYear] = new FusePool(_owner, 365 days);
        fusePools[Types.FuseProduct.ThreeYears] = new FusePool(_owner, 365 days * 3);
        fusePools[Types.FuseProduct.FiveYears] = new FusePool(_owner, 365 days * 5);

        boosts[Types.FuseProduct.OneYear] = 2e18;
        boosts[Types.FuseProduct.ThreeYears] = 12e18;
        boosts[Types.FuseProduct.FiveYears] = 36e18;
    }

    function createAmplifier(uint256 _months) external payable nonReentrant returns (uint256) {
        require(msg.value == getRenewalFeeForMonths(_months) + creationFee, "Invalid Ether value provided");
        return _createAmplifier(_months);
    }

    function createAmplifierBatch(uint256 _amount, uint256 _months)
        external
        payable
        nonReentrant
        returns (uint256[] memory ids)
    {
        require(msg.value == (getRenewalFeeForMonths(_months) + creationFee) * _amount, "Invalid Ether value provided");
        ids = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; ) {
            ids[i] = _createAmplifier(_months);
            unchecked {
                ++i;
            }
        }
        return ids;
    }

    function _createAmplifier(uint256 _months) internal returns (uint256) {
        require(balanceOf[msg.sender] < maxAmplifiersPerMinter, "Too many amplifiers");
        require(_months > 0 && _months <= maxMonths, "Must be 1-6 months");

        require(amplifi.burnForAmplifier(msg.sender, mintPrice), "Not able to burn");

        (bool success, ) = feeRecipients.validatorAcquisition.call{
            value: getRenewalFeeForMonths(_months) + creationFee
        }("");
        require(success, "Could not send ETH");

        uint256 id;
        uint256 length;
        unchecked {
            id = totalAmplifiers++;
            length = balanceOf[msg.sender]++;
        }

        amplifiers[id] = Types.Amplifier(
            Types.FuseProduct.None,
            msg.sender,
            block.timestamp,
            block.timestamp + 30 days * _months,
            0,
            0,
            0,
            0,
            0
        );
        ownedAmplifiers[msg.sender][length] = id;
        ownedAmplifiersIndex[id] = length;

        return id;
    }

    function renewAmplifier(uint256 _id, uint256 _months) external payable nonReentrant {
        require(msg.value == getRenewalFeeForMonths(_months), "Invalid Ether value provided");
        _renewAmplifier(_id, _months);
    }

    function renewAmplifierBatch(uint256[] calldata _ids, uint256 _months) external payable nonReentrant {
        uint256 length = _ids.length;
        require(msg.value == (getRenewalFeeForMonths(_months)) * length, "Invalid Ether value provided");
        for (uint256 i = 0; i < length; ) {
            _renewAmplifier(_ids[i], _months);
            unchecked {
                ++i;
            }
        }
    }

    function _renewAmplifier(uint256 _id, uint256 _months) internal {
        Types.Amplifier storage amplifier = amplifiers[_id];

        require(amplifier.minter == msg.sender, "Invalid ownership");
        require(amplifier.expires + gracePeriod >= block.timestamp, "Grace period expired");

        uint256 monthsLeft = 0;
        if (block.timestamp > amplifier.expires) {
            monthsLeft = (block.timestamp - amplifier.created) / 30 days;
        }
        require(_months + monthsLeft <= maxMonths, "Too many months");

        (bool success, ) = feeRecipients.validatorAcquisition.call{value: getRenewalFeeForMonths(_months)}("");
        require(success, "Could not send ETH");

        amplifier.expires += 30 days * _months;
    }

    function fuseAmplifier(uint256 _id, Types.FuseProduct fuseProduct) external payable nonReentrant {
        Types.Amplifier storage amplifier = amplifiers[_id];

        require(amplifier.minter == msg.sender, "Invalid ownership");
        require(amplifier.fuseProduct == Types.FuseProduct.None, "Already fused");
        require(amplifier.expires > block.timestamp, "Amplifier expired");

        require(msg.value == fuseFee, "Invalid Ether value provided");

        (bool success, ) = feeRecipients.validatorAcquisition.call{value: msg.value}("");
        require(success, "Could not send ETH");

        INetwork network = fusePools[fuseProduct];
        network.increaseShare(msg.sender, block.timestamp + fuseLockDurations[fuseProduct]);

        amplifier.fuseProduct = fuseProduct;
        amplifier.fused = block.timestamp;
        amplifier.unlocks = block.timestamp + fuseLockDurations[fuseProduct];
    }

    function claimAMPLIFI(uint256 _id) external nonReentrant {
        _claimAMPLIFI(_id);
    }

    function claimAMPLIFIBatch(uint256[] calldata _ids) external nonReentrant {
        uint256 length = _ids.length;
        for (uint256 i = 0; i < length; ) {
            _claimAMPLIFI(_ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _claimAMPLIFI(uint256 _id) internal {
        Types.Amplifier storage amplifier = amplifiers[_id];
        require(amplifier.minter == msg.sender, "Invalid ownership");
        require(amplifier.fuseProduct == Types.FuseProduct.None, "Must be unfused");
        require(amplifier.expires > block.timestamp, "Amplifier expired");

        uint256 amount = getPendingAMPLIFI(_id);
        amount = takeClaimFee(amount);
        amplifi.transfer(msg.sender, amount);

        amplifier.numClaims++;
        amplifier.lastClaimed = block.timestamp;
    }

    function claimETH(uint256 _id) external nonReentrant {
        _claimETH(_id);
    }

    function claimETHBatch(uint256[] calldata _ids) external nonReentrant {
        uint256 length = _ids.length;
        for (uint256 i = 0; i < length; ) {
            _claimETH(_ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _claimETH(uint256 _id) internal {
        Types.Amplifier storage amplifier = amplifiers[_id];
        require(amplifier.minter == msg.sender, "Invalid ownership");
        require(amplifier.fuseProduct != Types.FuseProduct.None, "Must be fused");
        require(amplifier.expires > block.timestamp, "Amplifier expired");
        require(block.timestamp - amplifier.fused > fuseWaitPeriod, "Cannot claim ETH yet");

        fusePools[amplifier.fuseProduct].distributeDividend(msg.sender);

        if (amplifier.unlocks <= block.timestamp) {
            require(amplifi.transfer(msg.sender, boosts[amplifier.fuseProduct]));

            fusePools[amplifier.fuseProduct].decreaseShare(amplifier.minter);
            amplifier.fuseProduct = Types.FuseProduct.None;
            amplifier.fused = 0;
            amplifier.unlocks = 0;
        }
    }

    function getPendingAMPLIFI(uint256 _id) public view returns (uint256) {
        Types.Amplifier memory amplifier = amplifiers[_id];

        uint256 rate = amplifier.numClaims >= rates.length ? rates[rates.length - 1] : rates[amplifier.numClaims];
        uint256 amount = (block.timestamp - (amplifier.numClaims > 0 ? amplifier.lastClaimed : amplifier.created)) *
            (rate);
        if (amplifier.created < block.timestamp + gammaPeriod) {
            uint256 _seconds = (block.timestamp + gammaPeriod) - amplifier.created;
            uint256 _percent = 100;
            if (_seconds >= 4838400) {
                _percent = 900;
            } else if (_seconds >= 4233600) {
                _percent = 800;
            } else if (_seconds >= 3628800) {
                _percent = 700;
            } else if (_seconds >= 3024000) {
                _percent = 600;
            } else if (_seconds >= 2419200) {
                _percent = 500;
            } else if (_seconds >= 1814400) {
                _percent = 400;
            } else if (_seconds >= 1209600) {
                _percent = 300;
            } else if (_seconds >= 604800) {
                _percent = 200;
            }
            uint256 _divisor = amount * _percent;
            (, uint256 result) = tryDiv(_divisor, 10000);
            amount -= result;
        }

        return amount;
    }

    function takeClaimFee(uint256 amount) internal returns (uint256) {
        uint256 fee = (amount * claimFee) / bps;

        address[] memory path = new address[](2);
        path[0] = address(amplifi);
        path[1] = address(USDC);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(fee, 0, path, address(this), block.timestamp);

        uint256 usdcToSend = USDC.balanceOf(address(this)) / 2;

        USDC.transfer(feeRecipients.operations, usdcToSend);
        USDC.transfer(feeRecipients.developers, usdcToSend);

        return amount - fee;
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) {
                return (false, 0);
            }
            return (true, a / b);
        }
    }

    function getRenewalFeeForMonths(uint256 _months) public view returns (uint256) {
        return renewalFee * _months;
    }

    function airdropAmplifiers(
        address[] calldata _users,
        uint256[] calldata _months,
        Types.FuseProduct[] calldata _fuseProducts
    ) external onlyOwner returns (uint256[] memory ids) {
        require(_users.length == _months.length && _months.length == _fuseProducts.length, "Lengths not aligned");

        uint256 length = _users.length;
        ids = new uint256[](length);
        for (uint256 i = 0; i < length; ) {
            ids[i] = _airdropAmplifier(_users[i], _months[i], _fuseProducts[i]);
            unchecked {
                ++i;
            }
        }

        return ids;
    }

    function _airdropAmplifier(
        address _user,
        uint256 _months,
        Types.FuseProduct _fuseProduct
    ) internal returns (uint256) {
        require(_months <= maxMonths, "Too many months");

        uint256 id;
        uint256 length;
        unchecked {
            id = totalAmplifiers++;
            length = balanceOf[_user]++;
        }

        uint256 fused;
        uint256 unlocks;

        if (_fuseProduct != Types.FuseProduct.None) {
            fused = block.timestamp;
            unlocks = block.timestamp + fuseLockDurations[_fuseProduct];
        }

        amplifiers[id] = Types.Amplifier(
            _fuseProduct,
            _user,
            block.timestamp,
            block.timestamp + 30 days * _months,
            0,
            0,
            fused,
            unlocks,
            0
        );
        ownedAmplifiers[_user][length] = id;
        ownedAmplifiersIndex[id] = length;

        return id;
    }

    function removeAmplifier(uint256 _id) external onlyOwner {
        uint256 lastAmplifierIndex = balanceOf[amplifiers[_id].minter];
        uint256 amplifierIndex = ownedAmplifiersIndex[_id];

        if (amplifierIndex != lastAmplifierIndex) {
            uint256 lastAmplifierId = ownedAmplifiers[amplifiers[_id].minter][lastAmplifierIndex];

            ownedAmplifiers[amplifiers[_id].minter][amplifierIndex] = lastAmplifierId; // Move the last amplifier to the slot of the to-delete token
            ownedAmplifiersIndex[lastAmplifierId] = amplifierIndex; // Update the moved amplifier's index
        }

        // This also deletes the contents at the last position of the array
        delete ownedAmplifiersIndex[_id];
        delete ownedAmplifiers[amplifiers[_id].minter][lastAmplifierIndex];

        balanceOf[amplifiers[_id].minter]--;
        totalAmplifiers--;

        delete amplifiers[_id];
    }

    function setRates(uint256[] calldata _rates) external onlyOwner {
        require(_rates.length == rates.length, "Invalid length");

        uint256 length = _rates.length;
        for (uint256 i = 0; i < length; ) {
            rates[i] = _rates[i];
            unchecked {
                ++i;
            }
        }
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMonths(uint16 _maxMonths) external onlyOwner {
        maxMonths = _maxMonths;
    }

    function setFees(
        uint256 _creationFee,
        uint256 _renewalFee,
        uint256 _fuseFee,
        uint16 _claimFee
    ) external onlyOwner {
        creationFee = _creationFee;
        renewalFee = _renewalFee;
        fuseFee = _fuseFee;
        claimFee = _claimFee;
    }

    function setFuseLockDurations(Types.FuseProduct _fuseProduct, uint256 _duration) external onlyOwner {
        fuseLockDurations[_fuseProduct] = _duration;
    }

    function setFusePool(Types.FuseProduct _fuseProduct, FusePool _fusePool) external onlyOwner {
        fusePools[_fuseProduct] = _fusePool;
    }

    function setBoosts(Types.FuseProduct _fuseProduct, uint256 _boost) external onlyOwner {
        boosts[_fuseProduct] = _boost;
    }

    function setFeeRecipients(Types.AmplifierFeeRecipients calldata _feeRecipients) external onlyOwner {
        feeRecipients = _feeRecipients;
    }

    function setPeriods(
        uint256 _gracePeriod,
        uint256 _gammaPeriod,
        uint256 _fuseWaitPeriod
    ) external onlyOwner {
        gracePeriod = _gracePeriod;
        gammaPeriod = _gammaPeriod;
        fuseWaitPeriod = _fuseWaitPeriod;
    }

    function approveRouter() external onlyOwner {
        amplifi.approve(address(router), type(uint256).max);
    }

    function withdrawETH(address _recipient) external onlyOwner {
        (bool success, ) = _recipient.call{value: address(this).balance}("");
        require(success, "Could not send ETH");
    }

    function withdrawToken(IERC20 _token, address _recipient) external onlyOwner {
        _token.transfer(_recipient, _token.balanceOf(address(this)));
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Types {
    struct FeeRecipients {
        address operations;
        address validatorAcquisition;
        address PCR;
        address yield;
        address xChainValidatorAcquisition;
        address indexFundPools;
        address gAMPRewardsPool;
        address OTCSwap;
        address rescueFund;
        address protocolImprovement;
        address developers;
    }

    struct Fees {
        uint16 operations;
        uint16 validatorAcquisition;
        uint16 PCR;
        uint16 yield;
        uint16 xChainValidatorAcquisition;
        uint16 indexFundPools;
        uint16 gAMPRewardsPool;
        uint16 OTCSwap;
        uint16 rescueFund;
        uint16 protocolImprovement;
        uint16 developers;
    }

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 started;
        uint256 unlocks;
    }

    enum FuseProduct {
        None,
        OneYear,
        ThreeYears,
        FiveYears
    }

    struct Amplifier {
        FuseProduct fuseProduct;
        address minter;
        uint256 created;
        uint256 expires;
        uint256 numClaims;
        uint256 lastClaimed;
        uint256 fused;
        uint256 unlocks;
        uint256 lastFuseClaimed;
    }

    struct AmplifierFeeRecipients {
        address operations;
        address validatorAcquisition;
        address developers;
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
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswap.sol";
import "./interfaces/INetwork.sol";
import "./Types.sol";

contract FusePool is INetwork, Ownable {
    address immutable token;
    uint256 immutable duration;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;
    mapping(address => uint256) public totalRewardsToUser;
    mapping(address => Types.Share) public shares;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    modifier onlyToken() {
        require(msg.sender == token);
        _;
    }

    constructor(address _owner, uint256 _duration) {
        _transferOwnership(_owner);

        token = msg.sender;
        duration = _duration;
    }

    function increaseShare(address _shareholder, uint256 _unlocks) external override onlyToken {
        if (shares[_shareholder].amount == 0) {
            addShareholder(_shareholder);
        }

        totalShares++;
        shares[_shareholder].amount++;
        shares[_shareholder].unlocks = _unlocks;
        shares[_shareholder].started = block.timestamp;
        shares[_shareholder].totalExcluded = getCumulativeDividends(
            shares[_shareholder].amount,
            shares[_shareholder].started,
            shares[_shareholder].unlocks
        );
        assert(shares[_shareholder].totalExcluded == 0);
    }

    function decreaseShare(address _shareholder) external override onlyToken {
        if (shares[_shareholder].amount == 1) {
            removeShareholder(_shareholder);
        }

        totalShares--;
        shares[_shareholder].totalExcluded = getCumulativeDividends(
            shares[_shareholder].amount,
            shares[_shareholder].started,
            shares[_shareholder].started
        );
        shares[_shareholder].amount--;
        shares[_shareholder].started = 0;
        shares[_shareholder].unlocks = 0;
    }

    function deposit() external payable override onlyOwner {
        uint256 amount = msg.value;
        totalDividends += amount;
        dividendsPerShare += (dividendsPerShareAccuracyFactor * amount) / totalShares;
    }

    function distributeDividend(address _shareholder) external onlyToken {
        uint256 amount = getPendingDividend(_shareholder);

        if (amount > 0) {
            shares[_shareholder].totalExcluded = getCumulativeDividends(
                shares[_shareholder].amount,
                shares[_shareholder].started,
                shares[_shareholder].unlocks
            );
            shares[_shareholder].totalRealised += amount;
            totalDistributed += amount;

            (bool success, ) = _shareholder.call{value: amount}("");
            require(success, "Could not send ETH");

            totalRewardsToUser[_shareholder] = totalRewardsToUser[_shareholder] + amount;
        }
    }

    function getPendingDividend(address _shareholder) public view returns (uint256) {
        if (shares[_shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[_shareholder].amount,
            shares[_shareholder].started,
            shares[_shareholder].unlocks
        );
        uint256 shareholderTotalExcluded = shares[_shareholder].totalExcluded;
        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(
        uint256 share,
        uint256 started,
        uint256 unlocks
    ) internal view returns (uint256) {
        if (unlocks > block.timestamp) {
            unlocks = block.timestamp;
        }

        uint256 total = (share * dividendsPerShare) / dividendsPerShareAccuracyFactor;

        uint256 end = started + duration;
        uint256 endAbs = end - started;
        uint256 nowAbs = unlocks - started;

        return (total * nowAbs) / endAbs;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function withdrawETH(address _recipient) external onlyOwner {
        (bool success, ) = _recipient.call{value: address(this).balance}("");
        require(success, "Could not send ETH");
    }

    function withdrawToken(IERC20 _token, address _recipient) external onlyOwner {
        _token.transfer(_recipient, _token.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface INetwork {
    function increaseShare(address _shareholder, uint256 _unlocks) external;
    function decreaseShare(address _shareholder) external;

    function deposit() external payable;

    function distributeDividend(address _shareholder) external;
}