//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SpaceLP.sol";

// @title SpaceRouter
// @author Mathias Scherer
// @notice This contract is the router for SpaceLP
contract SpaceRouter {
    // Variables
    // @notice The address of the SpaceLP contract
    SpaceLP public immutable LIQUIDITY_POOL;
    // @notice The address of the SpaceCoin contract
    IERC20 public immutable SPC_CONTRACT;

    enum COINS {
        ETH,
        SPC
    }

    // @notice Error thrown if the slippage is too high
    // @param _amount The amount of tokens to transfer
    // @param _desiredMinAmount The desired minimum amount of tokens to transfer
    // @param _coinOut The coin to transfer
    error SlippageError(
        uint256 _amount,
        uint256 _desiredMinAmount,
        COINS _coinOut
    );

    // @notice Error thrown if adding liquidity has failed
    // @param _reason The reason for the failure
    error AddLiquiditiyFailed(string _reason);

    // @notice Error thrown if removing liquidity has failed
    // @param _gottenEth The amount of ETH gotten from removing liquidity
    // @param _gottenSpc The amount of SPC gotten from removing liquidity
    // @param _minEth The minimum amount of ETH expected
    // @param _minSpc The minimum amount of SPC expected
    error RemoveLiquidityFailed(
        uint256 _gottenEth,
        uint256 _gottenSpc,
        uint256 _minEth,
        uint256 _minSpc
    );

    // @notice Constructor
    // @param _lp The address of the SpaceLP contract
    // @param _spcContract The address of the SpaceCoin contract
    constructor(address payable _lp, address _spcContract) {
        LIQUIDITY_POOL = SpaceLP(_lp);
        SPC_CONTRACT = IERC20(_spcContract);
    }

    // @notice Swap ETH for SPC
    // @dev calls the underlying SpaceLP contract to swap ETH for SPC
    // @param _to The address of the recipient
    // @param _desiredMinAmount The desired minimum amount of tokens to transfer
    // @returns The amount of tokens received
    function swapETHForSPC(address _to, uint256 _desiredMinAmount)
        external
        payable
        returns (uint256)
    {
        uint256 amount = LIQUIDITY_POOL.swap{value: msg.value}(_to);
        _checkSlippage(amount, _desiredMinAmount, COINS.SPC);
        return amount;
    }

    // @notice Swap SPC for ETH (approve to Router on SPC contract first)
    // @dev transfers the tokens to the LP contract
    // @param _to The address of the recipient
    // @param _inAmount The amount of tokens to transfer
    // @param _desiredMinAmount The desired minimum amount of tokens to transfer
    // @returns The amount of tokens received
    function swapSPCForETH(
        address _to,
        uint256 _inAmount,
        uint256 _desiredMinAmount
    ) external returns (uint256) {
        SPC_CONTRACT.transferFrom(
            msg.sender,
            address(LIQUIDITY_POOL),
            _inAmount
        );
        uint256 amount = LIQUIDITY_POOL.swap(_to);
        _checkSlippage(amount, _desiredMinAmount, COINS.ETH);
        return amount;
    }

    // @notice Add liquidity to the LP contract (approve to Router on SPC contract first)
    // @dev transfers the tokens to the LP contract. The function prioritizes the desired ETH amount over SPC
    // @dev returns the amount of ETH that isn't used if no optimal ratio in the bounderies of SPC is found
    // @param _minEth The miniumum amount of ETH to add
    // @param _desiredSpc The desired amount of SPC to add (max amount of SPC)
    // @param _minSpc The minimum amount of SPC to add
    // @param _to The address of the recipient for the LP tokens
    // @returns The amount of coins added to the LP contract
    function addLiquidity(
        uint128 _minEth,
        uint128 _desiredSpc,
        uint128 _minSpc,
        address _to
    ) external payable returns (uint256, uint256) {
        (uint128 ethBalance, uint128 spcBalance) = LIQUIDITY_POOL
            .getCoinBalances();
        uint256 desiredEth = msg.value;
        uint256 optimalSpc;
        if (ethBalance == 0 || spcBalance == 0) {
            optimalSpc = _desiredSpc;
        } else {
            optimalSpc = getRatio(desiredEth, ethBalance, spcBalance);
        }
        // proritizes ETH over SPC in the desired amount
        if (optimalSpc <= _desiredSpc && optimalSpc >= _minSpc) {
            SPC_CONTRACT.transferFrom(
                msg.sender,
                address(LIQUIDITY_POOL),
                optimalSpc
            );
            LIQUIDITY_POOL.mintLPTokens{value: desiredEth}(_to);
            return (optimalSpc, desiredEth);
        }
        uint256 optimalEth = getRatio(_desiredSpc, spcBalance, ethBalance);
        if (optimalEth <= desiredEth && optimalEth >= _minEth) {
            SPC_CONTRACT.transferFrom(
                msg.sender,
                address(LIQUIDITY_POOL),
                _desiredSpc
            );
            uint256 ethToReturn = desiredEth - optimalEth;
            LIQUIDITY_POOL.mintLPTokens{value: optimalEth}(_to);
            (bool success, ) = msg.sender.call{value: ethToReturn}("");
            if (success == false) {
                revert AddLiquiditiyFailed("ETH return failed");
            }
            return (_desiredSpc, optimalEth);
        }
        revert AddLiquiditiyFailed("No optimal ratio found");
    }

    // @notice Remove liquidity from the LP contract (approve the Router on the LP contract first)
    // @dev Transfers the tokens from the sender to the LP contract
    // @param _liquidity The amount of liquidity to remove
    // @param _minEth The minimum amount of ETH to remove
    // @param _minSpc The minimum amount of SPC to remove
    // @param _to The address of the recipient
    // @returns The amount of tokens removed
    function removeLiquidity(
        uint256 _liqudity,
        uint256 _minEth,
        uint256 _minSpc,
        address _to
    ) external returns (uint256, uint256) {
        LIQUIDITY_POOL.transferFrom(
            msg.sender,
            address(LIQUIDITY_POOL),
            _liqudity
        );
        (uint256 amountEth, uint256 amountSpc) = LIQUIDITY_POOL.burnLPTokens(
            _to
        );
        if (amountEth < _minEth || amountSpc < _minSpc) {
            revert RemoveLiquidityFailed(
                amountEth,
                amountSpc,
                _minEth,
                _minSpc
            );
        }
        return (amountEth, amountSpc);
    }

    // @notice Gets the optimal ratio of ETH to SPC
    // @param _input The amount to convert
    // @param _balance1 The balance of the coin to convert from
    // @param _balance2 The balance of the coin to convert to
    // @returns The optimal amount to convert to
    function getRatio(
        uint256 _input,
        uint256 _balance1,
        uint256 _balance2
    ) public pure returns (uint256) {
        return (_input * _balance2) / _balance1;
    }

    // @notice Checks for slippage. Throws if the slippage is to high
    // @dev Only checks for the lower bound of the slippage
    // @param _amount The amount to check
    // @param _desiredMinAmount The desired minimum amount
    // @param _coin The coin to check
    function _checkSlippage(
        uint256 _amount,
        uint256 _desiredMinAmount,
        COINS _coin
    ) internal pure {
        if (_amount < _desiredMinAmount) {
            revert SlippageError(_amount, _desiredMinAmount, _coin);
        }
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./helpers/MathHelper.sol";

// @title SpaceLP
// @author Mathias Scherer
// @notice SpaceLP is a smart contract that is used to exchange ETH and SPC.
contract SpaceLP is ERC20, MathHelper {
    // Variables
    // Sized as uint128 to pack them into 1 storage slot
    uint128 public ethBalance;
    uint128 public spcBalance;

    // SpaceCoin contract address
    IERC20 public immutable SPC_CONTRACT;

    enum COINS {
        ETH,
        SPC
    }

    // Events
    // @notice Emited when swap succeeds
    // @param _from The source coin
    // @param _to The target coin
    // @param _in Amount of source coin
    // @param _out Amount of target coin
    // @param _recipient The recipient address
    event Swapped(
        COINS _from,
        COINS _to,
        uint256 _in,
        uint256 _out,
        address indexed _recipient
    );

    // @notice Emited when liquidity is added
    // @param _addedETH Amount of ETH added
    // @param _addedSPC Amount of SPC added
    // @param _from The source address (transaction sender)
    // @param _recipient The recipient of the LP tokens
    event LiquidityAdded(
        uint256 _addedETH,
        uint256 _addedSPC,
        address indexed _from,
        address indexed _recipient
    );

    // @notice Emited when liquidity is removed
    // @param _removedLiquidity Amount of LP tokens removed
    // @param _removedETH Amount of ETH removed
    // @param _removedSPC Amount of SPC removed
    // @param _recipient The recipient of the coins
    event LiquidityRemoved(
        uint256 _removedLiqudity,
        uint256 _removedETH,
        uint256 _removedSPC,
        address indexed _recipient
    );

    // @notice Emited when ETH has been received by the receive function
    // @param _amount Amount of ETH received
    // @param _from The sender address
    event ReceivedETH(uint256 _amount, address indexed _from);

    // Errors
    // @notice Error thrown when the wrong coin is selected
    // @param _coin The coin that was selected
    error InvalidCoin(COINS _coin);

    // @notice Error thrown when the balance is too low
    // @param _coin The coin that was selected
    // @param _requiredAmount The required amount
    // @param _availableAmount The available amount
    error InsufficientLiqudity(
        COINS _coin,
        uint256 _requestedAmount,
        uint256 _availableAmount
    );

    // @notice Error when a transfer fails
    // @param _coin The coin that was selected
    // @param _amount The amount to be sent
    // @param _recipient The recipient address
    error TransferFailed(COINS _coin, uint256 _amount, address _recipient);

    // @notice Error when not enough liquidity was added
    // @param _addedETH Amount of ETH added
    // @param _addedSPC Amount of SPC added
    // @param _liquidity The amount of liquidity added
    error InsufficientLiquidityAdded(
        uint256 _addedETH,
        uint256 _addedSPC,
        uint256 _liqudity
    );

    // @notice Error when not enough liquidity was removed
    // @param _removedETH Amount of ETH removed
    // @param _removedSPC Amount of SPC removed
    // @param _liquidity The amount of liquidity removed
    error InsufficientLiquidityRemoved(
        uint256 _removedETH,
        uint256 _removedSPC,
        uint256 _liqudity
    );

    // @notice Thrown when a swap failed
    error SwapFailed();

    // @notice Initalizes the contract and the ERC20 LP tokens
    // @param _spcContract The address of the SpaceCoin contract
    constructor(address _spcContract) ERC20("ETH-SpaceCoin LP", "ETHSPC_LP") {
        SPC_CONTRACT = IERC20(_spcContract);
    }

    // @notice Returns the K from the constant product formula (k = x * y)
    // @dev Uses stored balances in Storage
    // @returns The K value
    function getK() public view returns (uint256) {
        return uint256(ethBalance) * uint256(spcBalance);
    }

    // @notice Returns the K with the actual balances
    // @dev uses the actual balances
    // @returns The K value
    function getCurrentK() public view returns (uint256) {
        return address(this).balance * SPC_CONTRACT.balanceOf(address(this));
    }

    // @notice Returns the stored amount of each token
    // @dev uses the stored balances in Storage
    // @returns (ethBalance, spcBalance)
    function getCoinBalances() public view returns (uint128, uint128) {
        return (ethBalance, spcBalance);
    }

    // @notice Returns the current amount of each token
    // @dev uses the actual balances casted as uint128
    // @returns (ethBalance, spcBalance)
    function getCurrentCoinBalances() public view returns (uint128, uint128) {
        return (
            MathHelper.toUint128(address(this).balance),
            MathHelper.toUint128(SPC_CONTRACT.balanceOf(address(this)))
        );
    }

    // @notice Returns the current coin balance of a coin
    // @dev uses the actual balances casted as uint128
    // @param _coin The coin to get the balance of
    // @returns The current balance of the coin
    function getCurrentCoinBalance(COINS _coin) public view returns (uint128) {
        if (_coin == COINS.ETH) {
            return MathHelper.toUint128(address(this).balance);
        } else if (_coin == COINS.SPC) {
            return MathHelper.toUint128(SPC_CONTRACT.balanceOf(address(this)));
        }
        revert InvalidCoin(_coin);
    }

    // @notice Mints the LP tokens for the current balance difference
    // @dev Takes the difference between the actual and the stored balance to calculate the amount of liquidity
    // @param _to The recipient address of the LP tokens
    // @returns The amount of LP tokens minted
    function mintLPTokens(address _to) external payable returns (uint256) {
        (
            uint256 currentETHBalance,
            uint256 currentSPCBalance
        ) = getCurrentCoinBalances();
        (
            uint128 storedEthBalance,
            uint128 storedSpcBalance
        ) = getCoinBalances();
        uint256 addedETH = currentETHBalance - storedEthBalance;
        uint256 addedSPC = currentSPCBalance - storedSpcBalance;

        uint256 totalSupply = totalSupply();
        uint256 liquidity;
        // Took from the UniswapV2 Whitepaper Section 3.4 (https://uniswap.org/whitepaper.pdf)
        if (totalSupply == 0) {
            if (addedSPC == 0 || addedETH == 0) {
                revert InsufficientLiquidityAdded(addedETH, addedSPC, 0);
            }
            // reflects the behavior of UniswapV1. The changes in UniswapV2 were made because of the abundance of ETH
            // in some pairs and to insure that it is the right ratio. But we know that the initial ratio is correct
            // because we deposite it by ourselves.
            liquidity = addedETH;
        } else {
            liquidity = MathHelper.min(
                (addedETH * totalSupply) / storedEthBalance,
                (addedSPC * totalSupply) / storedSpcBalance
            );
        }
        if (liquidity == 0) {
            revert InsufficientLiquidityAdded(addedETH, addedSPC, liquidity);
        }

        _update(currentETHBalance, currentSPCBalance);
        _mint(_to, liquidity);
        emit LiquidityAdded(addedETH, addedSPC, msg.sender, _to);
        return liquidity;
    }

    // @notice Burns LP tokens and returns the correct amount of coins
    // @dev Uses the current and not the stored balances to calculate the amount of coins to be returned
    // @param _to The recipient address of the coins
    // @returns (amount of ETH, amount of SPC)
    function burnLPTokens(address _to) external returns (uint256, uint256) {
        (
            uint256 currentETHBalance,
            uint256 currentSPCBalance
        ) = getCurrentCoinBalances();
        uint256 toBurnLiquidity = balanceOf(address(this));

        uint256 totalSupply = totalSupply();
        uint256 amountETH = (toBurnLiquidity * currentETHBalance) / totalSupply;
        uint256 amountSPC = (toBurnLiquidity * currentSPCBalance) / totalSupply;
        if (amountETH == 0 || amountSPC == 0) {
            revert InsufficientLiquidityRemoved(
                amountETH,
                amountSPC,
                toBurnLiquidity
            );
        }
        _update(currentETHBalance - amountETH, currentSPCBalance - amountSPC);
        _burn(address(this), toBurnLiquidity);
        _transferETH(amountETH, _to);
        _transferSPC(amountSPC, _to);
        emit LiquidityRemoved(toBurnLiquidity, amountETH, amountSPC, _to);
        return (amountETH, amountSPC);
    }

    // @notice swaps the coins
    // @dev Uses the difference between the actual and the stored balances to calculate the amount of coins to be returned
    // @param _to The recipient address of the coins
    // @returns amount of coins swapped out
    function swap(address _to) external payable returns (uint256) {
        (
            uint128 currentEthBalance,
            uint128 currentSpcBalance
        ) = getCurrentCoinBalances();
        (
            uint128 storedEthBalance,
            uint128 storedSpcBalance
        ) = getCoinBalances();

        uint256 k = getK();
        uint256 amount;
        // swaps ETH to SPC
        if (currentEthBalance > storedEthBalance) {
            uint256 diff = currentEthBalance - storedEthBalance;
            amount = getAmountOut(storedSpcBalance, storedEthBalance, diff);
            _update(
                currentEthBalance,
                currentSpcBalance - MathHelper.toUint128(amount)
            );
            _transferSPC(amount, _to);
            emit Swapped(COINS.ETH, COINS.SPC, diff, amount, _to);
            // swaps SPC to ETH
        } else if (currentSpcBalance > storedSpcBalance) {
            uint256 diff = currentSpcBalance - storedSpcBalance;
            amount = getAmountOut(storedEthBalance, storedSpcBalance, diff);
            _update(
                currentEthBalance - MathHelper.toUint128(amount),
                currentSpcBalance
            );
            _transferETH(amount, _to);
            emit Swapped(COINS.SPC, COINS.ETH, diff, amount, _to);
        } else {
            revert SwapFailed();
        }

        if (k > getK()) {
            revert SwapFailed();
        }
        return amount;
    }

    // @notice Calculates the amount of coins to be returned
    // @param _balance1 The balance of the coin to go out
    // @param _balance2 The balance of the coin to go in
    // @param _diff The amount of coins to be exchanged
    // @returns The amount of coins to be returned
    function getAmountOut(
        uint256 _balance1,
        uint256 _balance2,
        uint256 _diff
    ) public view returns (uint256) {
        return _balance1 - getK() / (_balance2 + _diff - (_diff / 100));
    }

    // @notice Receive function for ETH
    // @dev Has no other effects than emitting an event
    receive() external payable {
        emit ReceivedETH(msg.value, msg.sender);
    }

    // @notice updates the stored balances
    // @param _targetEthBalance The new ETH balance
    // @param _targetSpcBalance The new SPC balance
    function _update(uint256 _targetEthBalance, uint256 _targetSpcBalance)
        internal
    {
        ethBalance = MathHelper.toUint128(_targetEthBalance);
        spcBalance = MathHelper.toUint128(_targetSpcBalance);
    }

    // @notice Transfers ETH to the recipient
    // @param _amount The amount of ETH to be transferred
    // @param _to The recipient address
    function _transferETH(uint256 _amount, address _to) internal {
        uint128 balance = getCurrentCoinBalance(COINS.ETH);
        if (_amount > balance) {
            revert InsufficientLiqudity(COINS.ETH, _amount, balance);
        }
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert TransferFailed(COINS.ETH, _amount, _to);
        }
    }

    // @notice Transfers SPC to the recipient
    // @param _amount The amount of SPC to be transferred
    // @param _to The recipient address
    function _transferSPC(uint256 _amount, address _to) internal {
        uint128 balance = getCurrentCoinBalance(COINS.SPC);
        if (_amount > balance) {
            revert InsufficientLiqudity(COINS.SPC, _amount, balance);
        }
        bool success = SPC_CONTRACT.transfer(_to, _amount);
        if (!success) {
            revert TransferFailed(COINS.SPC, _amount, _to);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// @title MathHelper
// @author Mathias Scherer
// @notice Helper class for math operations
contract MathHelper {

    error ValueToLarge(uint256 _value, uint256 _max);

    // @notice Converts the given uint256 to a uint64
    // @param _value Value to convert
    // @return Value as uint64
    function toUint64(uint256 _value) public pure returns (uint64) {
        unchecked {
            uint64 x;
            if(_value > x-1) {
                revert ValueToLarge(_value, x-1);
            }
            return uint64(_value);
        }
    }

    // @notice Converts the given uint256 to a uint128
    // @param _value Value to convert
    // @return Value as uint128
    function toUint128(uint256 _value) public pure returns (uint128) {
        unchecked {
            uint128 x;
            if(_value > x-1) {
                revert ValueToLarge(_value, x-1);
            }
            return uint128(_value);
        }
    }

    // @notice Returns the smaller number
    // @param x First number
    // @param y Second number
    // @return Smaller number
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }
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