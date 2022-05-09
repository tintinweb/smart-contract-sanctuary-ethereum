// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./starknet/IStarkgate.sol";
import "contracts/starkware/starknet/eth/IStarknetMessaging.sol";

contract L1Conductor {
    // Selector when sending message to L2 to call the `process_message_from_l1` func on the L2 conductor
    uint256 constant PROCESS_MESSAGE_FROM_L1_SELECTOR = 816708063554545988512071046177985264005137018110515604108563152300587620475;
    uint256 constant UINT256_PART_SIZE_BITS = 128;
    uint256 constant UINT256_PART_SIZE = 2**UINT256_PART_SIZE_BITS;

    // Immutable var means it could only be set in the constructor
    IStarknetMessaging public immutable starknetCore;
    uint256 public immutable l2Conductor;
    IStarkgate public immutable inputTokenStarkgate;
    IStarkgate public immutable outputTokenStarkgate;
    ERC20 public inputToken;
    ERC20 public outputToken;
    address public immutable destContract;  // The contract that converts input to output
    bytes4 public immutable sighash;    // The sighash to call on the contract to convert input to output

    // Topic hash: 0xbf09f4e1f80a105e9300ab0f966ce073a6b8f1a1675b0c89d29bdbd2a650b447
    event SuccessfulAmountWithdrawal(uint256 amount);
    // Topic hash: 0xc5db756d9d048094aa5017266616378c86aa7ed91f1d596c3b714b548bbe4fe7
    event UnsuccessfulAmountWithdrawal(uint256 amount);

    event SuccessfulAmountMessageWithdrawal(uint256 amount);
    event UnsuccessfulAmountMessageWithdrawal(uint256 amount);

    constructor(
        IStarknetMessaging _starknetCore,
        uint256 _l2Conductor,
        IStarkgate _inputTokenStarkgate,
        IStarkgate _outputTokenStarkgate,
        ERC20 _inputToken,
        ERC20 _outputToken,
        address _destContract,
        bytes4 _sighash
    ) public {
        starknetCore = _starknetCore;
        l2Conductor = _l2Conductor;
        inputTokenStarkgate = _inputTokenStarkgate;
        outputTokenStarkgate = _outputTokenStarkgate;
        inputToken = _inputToken;
        outputToken = _outputToken;
        destContract = _destContract;
        sighash = _sighash;
    }

    /**
     * This function is triggered by the Keeper (or by a user) and executes all the rides.
     * 
     * If one of the rideAmounts given is not executable (i.e., the tokens haven't made it yet from L2 and we cannot
     * execute them), then this function will still execute the other rideAmounts.
     * 
     * The function returns an array of the rideAmounts which it successfully executed.
     */
    function executeRides(uint256[] calldata rideAmounts) external returns (uint256[] memory successfulRideAmounts) {
        uint256 startGas = gasleft();

        // Attempt to withdraw all rideAmounts from gate
        uint256 rideCount = rideAmounts.length;

        for(uint256 i = 0; i < rideCount; i++) {

            bool success = safeWithdrawFromGate(rideAmounts[i]);
            if (success) {
                emit SuccessfulAmountWithdrawal(rideAmounts[i]);
            } else {
                emit UnsuccessfulAmountWithdrawal(rideAmounts[i]);
            }
        }

        // Consume amount info message
        // The ones that we are able to consume (and have enough input token balance to actually execute) will be
        // pushed to successfulRideAmounts and their total to totalAmount
        uint256 inputTokenBalance = inputToken.balanceOf(address(this));
        uint256[] memory successfulRideAmounts = new uint256[](rideCount);
        uint256 totalAmount = 0;
        uint256 successfulRideCount = 0;
        for(uint256 i = 0; i < rideCount; i++) {
            // If ride amount is bigger than our token balance, skip it
            if (rideAmounts[i] + totalAmount > inputTokenBalance) { continue; }

            // Consume the amount info message
            bool success = consumeAmountMessage(rideAmounts[i]);
            if (success) {
                totalAmount += rideAmounts[i];
                successfulRideAmounts[successfulRideCount] = rideAmounts[i];
                successfulRideCount++;
                emit SuccessfulAmountMessageWithdrawal(rideAmounts[i]);
            } else {
                emit UnsuccessfulAmountMessageWithdrawal(rideAmounts[i]);
            }
        }

        // Return empty array if no rides were successfully withdrawn
        if (totalAmount == 0) return successfulRideAmounts;

        // Swap
        uint256 outputTokenAmount = safeExecuteSwap(totalAmount);

        // Deposit to gate
        safeDepositToGate(outputTokenAmount);

        // Send message to L2 to finalize the ride
        // Construct the message's payload
        uint256[] memory payload = new uint256[](successfulRideCount * 2 + 5);
        payload[0] = successfulRideCount;
        // ride_amounts
        for(uint256 i = 0; i < successfulRideCount; i++) {
            // Convert uint256 to to low and high (in order to be receivable by L2)
            // low 128
            payload[i*2+1] = successfulRideAmounts[i] & (UINT256_PART_SIZE - 1);
            // high 128
            payload[i*2+2] = successfulRideAmounts[i] >> UINT256_PART_SIZE_BITS;
        }
        // total_payout
        payload[successfulRideCount * 2 + 1] = outputTokenAmount & (UINT256_PART_SIZE - 1);
        payload[successfulRideCount * 2 + 2] = outputTokenAmount >> UINT256_PART_SIZE_BITS;

        // gas_used
        // TODO: gas seems off.. it's weirdly unpredictable, for example:
        // goerli tx 0xa21612462039cafa68605a35b9e4520adf862defefb2f802608119fd862d095c:
        // gas reported by contract: 373888 - 71573 = 302315 // (71573 was added as an offset in the contract)
        // actual gas used: 287836
        // goerli tx 0x8c1002a37215c51e79a7255ddc5a52acec4e899e972f209a922295684e1e8890
        // gas reported by contract: 302312
        // actual gas used: 287681
        // could be a problem on goerli specifically (gasUsed() implementation is different than actual node implementation)?
        uint256 gasUsed = startGas - gasleft();
        payload[successfulRideCount * 2 + 3] = gasUsed & (UINT256_PART_SIZE - 1);
        payload[successfulRideCount * 2 + 4] = gasUsed >> UINT256_PART_SIZE_BITS;


        starknetCore.sendMessageToL2(
            l2Conductor,
            PROCESS_MESSAGE_FROM_L1_SELECTOR,
            payload
        );

        return successfulRideAmounts;
    }

    /**
        Attempt to consume the amount message from the L2Conductor of the given amount.
        This function returns false if unsuccessful (e.g., message not available), and true if successful.
        It does not revert.
     */
    function consumeAmountMessage(uint256 amount) internal returns (bool success) {
        uint256[] memory payload = new uint256[](2);
        payload[0] = amount & (UINT256_PART_SIZE - 1);
        payload[1] = amount >> UINT256_PART_SIZE_BITS;

        try starknetCore.consumeMessageFromL2(l2Conductor, payload) returns (bytes32) {
            return true;
        } catch(bytes memory) {
            return false;
        }
    }

    /**
        Withdraw `amount` input token from the Stargate. Ensure that the correct amount was withdrawn.
        Returns true if successful in withdrawing given amount.
        Returns false if withdrawing function is unsucessful.
        Reverts if able to withdraw but wrong amount given from the gate.
     */
    function safeWithdrawFromGate(uint256 amount) internal returns (bool success) {
        uint256 inputTokenAmountBeforeWithdraw = inputToken.balanceOf(address(this));
        (bool success, bytes memory data) = address(inputTokenStarkgate).call(abi.encodeWithSignature(
            "withdraw(uint256,address)",
            amount,
            address(this)
        ));
        if (!success) {return false;}
        uint256 inputTokenAmountAfterWithdraw = inputToken.balanceOf(address(this));
        require(inputTokenAmountBeforeWithdraw + amount == inputTokenAmountAfterWithdraw, "Incorrect amount withdrawn from Starkgate");
        return true;
    }

    /**
        Deposit `amount` output token to the Starkgate. Ensure that the correct amount was deposited.
     */
    function safeDepositToGate(uint256 amount) internal {
        uint256 outputTokenAmountBeforeDeposit = outputToken.balanceOf(address(this));
        outputToken.approve(address(outputTokenStarkgate), amount);
        outputTokenStarkgate.deposit(amount, l2Conductor);
        uint256 outputTokenAmountAfterDeposit = outputToken.balanceOf(address(this));
        require(outputTokenAmountBeforeDeposit - amount == outputTokenAmountAfterDeposit, "Incorrect amount deposited to Starkgate");
    }

    /**
        Execute the func (denoted by sighash) on the contract that converts the input token to the output token.
        Return the amount of output token given.

        Checks:
        * This contract has enough input token
        * Correct amount of input token transferred
        * Output token was given to us

        Reverts if unsuccessful.
     */
    function safeExecuteSwap(uint256 amount) internal returns (uint256) {
        // Input/output token amount before
        uint256 inputTokenAmountBefore = inputToken.balanceOf(address(this));
        uint256 outputTokenAmountBefore = outputToken.balanceOf(address(this));

        // Checks
        require(inputTokenAmountBefore >= amount, "Not enough input token to execute swap.");

        // Approve token and do swap
        inputToken.approve(destContract, amount);
        bytes memory callData = abi.encodeWithSelector(
            sighash,
            amount
        );
        (bool success, bytes memory data) = destContract.call(callData);
        require(success, "Calling destination contract was unsuccessful.");

        // Input/output token amount after
        uint256 inputTokenAmountAfter = inputToken.balanceOf(address(this));
        uint256 outputTokenAmountAfter = outputToken.balanceOf(address(this));

        // Checks
        require(inputTokenAmountBefore - amount == inputTokenAmountAfter, "Incorrect amount of input token was transferred.");
        require(outputTokenAmountAfter > outputTokenAmountBefore, "No output token was transferred.");

        // Return output token amount given
        return outputTokenAmountAfter - outputTokenAmountBefore;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

interface IStarkgate {
    // Used for ETH deposits
    function deposit(uint256 l2Recipient) external;
    // Used for ERC20 deposits
    function deposit(uint256 amount, uint256 l2Recipient) external;
    function withdraw(uint256 amount, address recipient) external;
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

interface IStarknetMessaging {
    // This event needs to be compatible with the one defined in Output.sol.
    event LogMessageToL1(
        uint256 indexed from_address,
        address indexed to_address,
        uint256[] payload
    );

    // An event that is raised when a message is sent from L1 to L2.
    event LogMessageToL2(
        address indexed from_address,
        uint256 indexed to_address,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );

    // An event that is raised when a message from L2 to L1 is consumed.
    event ConsumedMessageToL1(
        uint256 indexed from_address,
        address indexed to_address,
        uint256[] payload
    );

    // An event that is raised when a message from L1 to L2 is consumed.
    event ConsumedMessageToL2(
        address indexed from_address,
        uint256 indexed to_address,
        uint256 indexed selector,
        uint256[] payload,
        uint256 nonce
    );

    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
        external
        returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}