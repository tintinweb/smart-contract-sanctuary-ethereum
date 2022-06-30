//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./UniversalERC20.sol";
import "./ISwapRouter.sol";

// File: contracts/GameHubPaymentGateway.sol

contract GameHubPaymentGateway is OwnableUpgradeable, PausableUpgradeable {
    using UniversalERC20 for IERC20Upgradeable;

    uint16 private constant DELIMINATOR = 10000;

    /** Fee distribution logic */
    uint16 public _marketingRate;
    uint16 public _treasuryRate;
    uint16 public _charityRate;

    /** Swap to unit token or not before distribution */
    bool public _swapAtDeposit;

    /** Rates of unit token to game coin */
    uint256 public _gameCoinPrice;

    /** Min / max limitation per deposit (it is calculated in unit token) */
    uint256 public _maxDepositAmount;
    uint256 public _minDepositAmount;

    /** Wallet addresses for distributing deposited funds */
    address public _marketingWallet;
    address public _treasuryWallet;
    address public _charityWallet;

    /** Unit token corresponding to game coin */
    address public _unitToken; // Ropsten USDC
    /** Swap router address */
    ISwapRouter public _swapRouter; // Ropsten router

    /** Accounts blocked to deposit */
    mapping(address => bool) public _accountBlacklist;
    /** Tokens whitelisted for deposit */
    mapping(address => bool) public _tokenWhitelist;

    event NewDeposit(
        address indexed account,
        address indexed payToken, // paid token
        uint256 payAmount, // paid token amount
        address indexed unitToken, // unit token
        uint256 unitAmount, // amount in unit token
        uint256 gameCoinAmount // game coin amount allocated to the user
    );
    event NewDistribute(
        address indexed account,
        address indexed token,
        uint256 marketingAmount,
        uint256 treasuryAmount,
        uint256 charityAmount
    );
    event NewAccountBlacklist(address indexed account, bool blacklisted);
    event NewTokenWhitelist(address indexed token, bool whitelisted);

    function initialize(
        address marketingWallet,
        address treasuryWallet,
        address charityWallet
    ) public initializer {
        __Pausable_init();

        _marketingWallet = marketingWallet;
        _treasuryWallet = treasuryWallet;
        _charityWallet = charityWallet;

        _marketingRate = 3000;
        _treasuryRate = 2000;
        _charityRate = 5000;
    }

    /**
     * @dev To receive ETH
     */
    receive() external payable {}

    /**
     * @notice Deposit tokens to get game coins
     * @dev Only available when gateway is not paused
     * @param tokenIn_: deposit token, must whitelisted, allow native token (0x0)
     * @param path_: optional param for indicating swap path instead of default path
     */
    function deposit(
        address tokenIn_,
        uint256 amountIn_,
        address[] memory path_
    ) external payable whenNotPaused {
        require(!_accountBlacklist[_msgSender()], "Blacklisted account");
        require(_tokenWhitelist[tokenIn_], "Token not whitelisted");

        IERC20Upgradeable payingToken = IERC20Upgradeable(tokenIn_);
        uint256 balanceBefore = payingToken.universalBalanceOf(address(this));
        payingToken.universalTransferFrom(
            _msgSender(),
            address(this),
            amountIn_
        );
        if (!payingToken.isETH()) {
            amountIn_ =
                payingToken.universalBalanceOf(address(this)) -
                balanceBefore;
        }

        uint256 unitAmount = 0;
        uint256 gameCoinAmount = 0;
        // Swap to unitToken, and distribute
        if (_swapAtDeposit) {
            (unitAmount, gameCoinAmount) = doSwapWithDeposit(
                tokenIn_,
                amountIn_,
                path_
            );
            distributeToken(IERC20Upgradeable(_unitToken), unitAmount);
        }
        // Just distribute tokenIn
        else {
            distributeToken(IERC20Upgradeable(tokenIn_), amountIn_);
            (unitAmount, gameCoinAmount) = viewConversion(
                tokenIn_,
                amountIn_,
                path_
            );
        }

        require(
            _minDepositAmount == 0 || _minDepositAmount <= gameCoinAmount,
            "Too small amount"
        );
        require(
            _maxDepositAmount == 0 || _maxDepositAmount >= gameCoinAmount,
            "Too much amount"
        );

        emit NewDeposit(
            _msgSender(),
            tokenIn_,
            amountIn_,
            _unitToken,
            unitAmount,
            gameCoinAmount
        );
    }

    /**
     * @notice Get valid path for swapping to unit token
     * @param givenPath_: User defined swap path
     * @return given path if valid, or new valid path
     */
    function getValidPath(address tokenIn_, address[] memory givenPath_)
        public
        view
        returns (address[] memory)
    {
        bool isValidStart = true;
        bool isValidEnd = true;
        address WETH = _swapRouter.WETH();

        if (givenPath_.length < 2) {
            isValidStart = false;
        } else if (IERC20Upgradeable(tokenIn_).isETH()) {
            if (givenPath_[0] != WETH) {
                isValidStart = false;
            }
        } else if (!isSameTokens(givenPath_[0], tokenIn_)) {
            isValidStart = false;
        } else if (IERC20Upgradeable(_unitToken).isETH()) {
            if (givenPath_[givenPath_.length - 1] != WETH) {
                isValidEnd = false;
            }
        } else if (
            !isSameTokens(givenPath_[givenPath_.length - 1], _unitToken)
        ) {
            isValidEnd = false;
        }

        if (isValidStart && isValidEnd) {
            return givenPath_;
        } else {
            address[] memory newValidPath = new address[](2);
            newValidPath[0] = IERC20Upgradeable(tokenIn_).isETH()
                ? WETH
                : tokenIn_;
            newValidPath[1] = IERC20Upgradeable(_unitToken).isETH()
                ? WETH
                : _unitToken;
            return newValidPath;
        }
    }

    /**
     * @notice View converted amount in unit token, and game coin amount
     * @param path_: swap path for the conversion
     */
    function viewConversion(
        address tokenIn_,
        uint256 amountIn_,
        address[] memory path_
    ) public view returns (uint256 unitAmount_, uint256 gameCoinAmount_) {
        address[] memory validPath = getValidPath(tokenIn_, path_);
        address WETH = _swapRouter.WETH();

        if (
            isSameTokens(tokenIn_, _unitToken) ||
            (tokenIn_ == WETH && IERC20Upgradeable(_unitToken).isETH()) ||
            (IERC20Upgradeable(tokenIn_).isETH() && _unitToken == WETH)
        ) {
            // No need to expect amount in case of tokenIn = unitToken, WETH => ETH, ETH => WETH
            unitAmount_ = amountIn_;
        } else {
            uint256[] memory amountsOut = _swapRouter.getAmountsOut(
                amountIn_,
                validPath
            );
            unitAmount_ = amountsOut[amountsOut.length - 1];
        }
        gameCoinAmount_ = unitAmount_ / _gameCoinPrice;
    }

    /**
     * @notice Swap deposited tokens to unitToken
     */
    function doSwapWithDeposit(
        address tokenIn_,
        uint256 amountIn_,
        address[] memory path_
    ) internal returns (uint256 unitAmount_, uint256 gameCoinAmount_) {
        address WETH = _swapRouter.WETH();
        address[] memory validPath = getValidPath(tokenIn_, path_);

        // tokenIn = unitToken, no need any swap
        if (isSameTokens(tokenIn_, _unitToken)) {
            unitAmount_ = amountIn_;
        }
        // WETH => ETH,
        else if (tokenIn_ == WETH && IERC20Upgradeable(_unitToken).isETH()) {
            IWETH(WETH).withdraw(amountIn_);
            unitAmount_ = amountIn_;
        }
        // ETH => WETH
        else if (IERC20Upgradeable(tokenIn_).isETH() && _unitToken == WETH) {
            IWETH(WETH).deposit{value: amountIn_}();
            unitAmount_ = amountIn_;
        } else {
            uint256 balanceBefore = IERC20Upgradeable(_unitToken)
                .universalBalanceOf(address(this));
            if (!IERC20Upgradeable(tokenIn_).isETH()) {
                // Approve operation for swapping
                IERC20Upgradeable(tokenIn_).universalApprove(
                    address(_swapRouter),
                    amountIn_
                );
            }
            // tokenIn => ETH
            if (IERC20Upgradeable(_unitToken).isETH()) {
                _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amountIn_,
                    0,
                    validPath,
                    address(this),
                    block.timestamp + 300
                );
            }
            // ETH => unitToken
            else if (IERC20Upgradeable(tokenIn_).isETH()) {
                _swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: amountIn_
                }(0, validPath, address(this), block.timestamp + 300);
            }
            // tokenIn => unitToken
            else {
                _swapRouter
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        amountIn_,
                        0,
                        validPath,
                        address(this),
                        block.timestamp + 300
                    );
            }
            unitAmount_ =
                IERC20Upgradeable(_unitToken).universalBalanceOf(
                    address(this)
                ) -
                balanceBefore;
        }
        gameCoinAmount_ = unitAmount_ / _gameCoinPrice;
    }

    /**
     * @notice Distribute token as the distribution rates
     */
    function distributeToken(IERC20Upgradeable token_, uint256 amount_)
        internal
    {
        uint256 marketingAmount = (amount_ * _marketingRate) / DELIMINATOR;
        uint256 treasuryAmount = (amount_ * _treasuryRate) / DELIMINATOR;
        uint256 charityAmount = amount_ - marketingAmount - treasuryAmount;

        if (marketingAmount > 0) {
            token_.universalTransfer(_marketingWallet, marketingAmount);
        }
        if (charityAmount > 0) {
            token_.universalTransfer(_charityWallet, charityAmount);
        }
        if (treasuryAmount > 0) {
            token_.universalTransfer(_treasuryWallet, treasuryAmount);
        }
        emit NewDistribute(
            _msgSender(),
            address(token_),
            marketingAmount,
            treasuryAmount,
            charityAmount
        );
    }

    /**
     * @notice Check if 2 tokens are same
     */
    function isSameTokens(address token1_, address token2_)
        internal
        pure
        returns (bool)
    {
        return
            token1_ == token2_ ||
            (IERC20Upgradeable(token1_).isETH() &&
                IERC20Upgradeable(token2_).isETH());
    }

    /**
     * @notice Block account from deposit or not
     * @dev Only owner can call this function
     */
    function blockAccount(address account_, bool flag_) external onlyOwner {
        _accountBlacklist[account_] = flag_;

        emit NewAccountBlacklist(account_, flag_);
    }

    /**
     * @notice Allow token for deposit or not
     * @dev Only owner can call this function
     */
    function allowToken(address token_, bool flag_) external onlyOwner {
        _tokenWhitelist[token_] = flag_;

        emit NewTokenWhitelist(token_, flag_);
    }

    /**
     * @notice Set swap router
     * @dev Only owner can call this function
     */
    function setSwapRouter(address swapRouter_) external onlyOwner {
        require(swapRouter_ != address(0), "Invalid swap router");
        _swapRouter = ISwapRouter(swapRouter_);
    }

    /**
     * @notice Set deposit min / max limit
     * @dev Only owner can call this function
     */
    function setDepositLimit(uint256 minAmount_, uint256 maxAmount_)
        external
        onlyOwner
    {
        _minDepositAmount = minAmount_;
        _maxDepositAmount = maxAmount_;
    }

    /**
     * @notice Toggle if deposited tokens are swapped to the unit token or not
     * @dev Only owner can call this function
     */
    function toggleSwapAtDeposit() external onlyOwner {
        _swapAtDeposit = !_swapAtDeposit;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pauseGateway() external onlyOwner {
        super._pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpauseGateway() external onlyOwner {
        super._unpause();
    }

    /**
     * @notice Set unit token and the rate of unit token to game coin
     * @dev Only owner can call this function
     */
    function setUnitTokenAndRate(address unitToken_, uint256 rate_)
        external
        onlyOwner
    {
        IERC20Upgradeable(unitToken_).universalBalanceOf(address(this)); // Check the token address is valid
        require(rate_ > 0, "Invalid rates to game coin");
        _unitToken = unitToken_;
        _gameCoinPrice = rate_;
    }

    /**
     * @notice Set distribution rates, sum of the params should be 100% (10000)
     * @dev Only owner can call this function
     */
    function setDistributionRates(
        uint16 marketingRate_,
        uint16 treasuryRate_,
        uint16 charityRate_
    ) external onlyOwner {
        require(
            marketingRate_ + treasuryRate_ + charityRate_ == DELIMINATOR,
            "Invalid values"
        );
        _marketingRate = marketingRate_;
        _treasuryRate = treasuryRate_;
        _charityRate = charityRate_;
    }

    /**
     * @notice Set distribution wallets
     * @dev Only owner can call this function
     */
    function setDistributionWallets(
        address marketingWallet_,
        address treasuryWallet_,
        address charityWallet_
    ) external onlyOwner {
        require(marketingWallet_ != address(0), "Invalid marketing wallet");
        require(treasuryWallet_ != address(0), "Invalid treasury wallet");
        require(charityWallet_ != address(0), "Invalid charity wallet");
        _marketingWallet = marketingWallet_;
        _treasuryWallet = treasuryWallet_;
        _charityWallet = charityWallet_;
    }

    /**
     * @notice It allows the admin to recover tokens sent to the contract
     * @param token_: the address of the token to withdraw
     * @param amount_: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverTokens(address token_, uint256 amount_) external onlyOwner {
        IERC20Upgradeable(token_).universalTransfer(_msgSender(), amount_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// File: contracts/UniversalERC20.sol

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library UniversalERC20 {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable private constant ZERO_ADDRESS =
        IERC20Upgradeable(0x0000000000000000000000000000000000000000);
    IERC20Upgradeable private constant ETH_ADDRESS =
        IERC20Upgradeable(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            payable(address(uint160(to))).transfer(amount);
            return true;
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(
                from == msg.sender && msg.value >= amount,
                "Wrong useage of ETH.universalTransferFrom()"
            );
            if (to != address(this)) {
                payable(address(uint160(to))).transfer(amount);
            }
            if (msg.value > amount) {
                payable(msg.sender).transfer(msg.value - amount);
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalTransferFromSenderToThis(
        IERC20Upgradeable token,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            if (msg.value > amount) {
                // Return remainder if exist
                payable(msg.sender).transfer(msg.value - amount);
            }
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function universalApprove(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) internal {
        if (!isETH(token)) {
            if (amount > 0 && token.allowance(address(this), to) > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(IERC20Upgradeable token, address who)
        internal
        view
        returns (uint256)
    {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(IERC20Upgradeable token)
        internal
        view
        returns (uint256)
    {
        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall{
            gas: 10000
        }(abi.encodeWithSignature("decimals()"));
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall{gas: 10000}(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20Upgradeable token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) ||
            address(token) == address(ETH_ADDRESS));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// File: contracts/interfaces/IWETH.sol

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// File: contracts/interfaces/ISwapRouter

/**
 * @title ISwapRouter
 * @dev Abbreviated interface of UniswapV2Router
 */
interface ISwapRouter {
    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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