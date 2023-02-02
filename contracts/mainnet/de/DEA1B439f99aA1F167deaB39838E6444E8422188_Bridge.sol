// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IAuthority.sol";
import "./interfaces/IBurnable.sol";
import "./interfaces/IBridge.sol";

import "./libraries/TransferHelper.sol";
import "./types/AccessControlled.sol";
import "./BridgeToken.sol";
import "./Signer.sol";

// TODO: Gas Fee

contract Bridge is IBridge, AccessControlled, Signer, Pausable {
    uint8 constant DEFAULT_THRESHOLD = 2;
    uint8 public threshold = DEFAULT_THRESHOLD;
    uint8 public activeRelayerCount = 0;
    uint8 public maxActiveRelayers = 255;

    address public feeRecipient;
    uint16 public feeAmount = 10; // 1%
    uint16 public constant feeFactor = 1000;

    uint256 public proposalIndex = 0;
    bytes32 immutable chainId;
    uint256 public balance = 0;

    mapping(address => bool) public isWhitelistedRelayer;
    mapping(bytes32 => mapping(bytes32 => bool)) tokenWhitelistedForChain;

    mapping(bytes32 => Proposal) public __proposals;
    mapping(bytes32 => Token) public __tokens;
    mapping(bytes32 => Chain) public __chains;

    constructor(
        IAuthority _authority,
        bytes32 chainId_,
        address _feeRecipient,
        // Relayers
        address[] memory _relayers,
        // Chains
        bytes32[] memory _chainNames
    ) AccessControlled(_authority) {
        chainId = chainId_;
        feeRecipient = _feeRecipient;

        for (uint8 i = 0; i < _relayers.length; i++) {
            isWhitelistedRelayer[_relayers[i]] = true;
            activeRelayerCount += 1;
        }
        for (uint8 i = 0; i < _chainNames.length; i++) {
            __chains[_chainNames[i]].isWhitelisted = true;
        }
    }

    /*
     * Controller Methods
     */
    function pause() external onlyController {
        _pause();
    }

    function unpause() external onlyController {
        _unpause();
    }

    function setGasFee(bytes32 token, uint256 amount) external onlyController {
        __tokens[token].gasFee = amount;
    }

    function updateFeeAmount(uint16 _feeAmount) external onlyController {
        feeAmount = _feeAmount;
        emit FeeUpdated(feeAmount);
    }

    function updateRelayer(address _relayer, bool isWhitelisted)
        external
        onlyController
    {
        require(isWhitelistedRelayer[_relayer] != isWhitelisted, "redundant");
        isWhitelistedRelayer[_relayer] = isWhitelisted;
        isWhitelisted ? activeRelayerCount++ : activeRelayerCount--;
        emit WhitelistedRelayer(_relayer);
    }

    function updateMaxTransaction(bytes32 _token, uint256 maxTransaction)
        external
        onlyController
    {
        __tokens[_token].maxTransaction = maxTransaction;
    }

    function updateMinTransaction(bytes32 _token, uint256 minTransaction)
        external
        onlyController
    {
        __tokens[_token].minTransaction = minTransaction;
    }

    function addNativeToken(
        bytes32 _token,
        Token memory tokenData,
        bytes32[] memory chainIds
    ) external onlyController {
        // TODO: would you ever remove a token from the whitelist?
        __tokens[_token] = tokenData;

        // whitelist token for chains
        for (uint256 i = 0; i < chainIds.length; i++) {
            require(__chains[chainIds[i]].isWhitelisted, "unsupported chain");
            tokenWhitelistedForChain[_token][chainIds[i]] = true;
        }
    }

    function addNonNativeToken(
        bytes32 _token,
        uint256 maxTransaction,
        uint256 minTransaction,
        address nativeAddress,
        bytes32 nativeChain,
        bytes32[] memory chainIds,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external onlyController {
        require(nativeChain != chainId, "native token");

        // TODO: would you ever remove a token from the whitelist?
        __tokens[_token].maxTransaction = maxTransaction;
        __tokens[_token].minTransaction = minTransaction;
        __tokens[_token].nativeAddress = nativeAddress;
        __tokens[_token].nativeChain = nativeChain;

        // whitelist token for chains
        for (uint256 i = 0; i < chainIds.length; i++) {
            require(__chains[chainIds[i]].isWhitelisted, "unsupported chain");
            tokenWhitelistedForChain[_token][chainIds[i]] = true;
        }

        // only create the token contract if there is no native address set
        require(bytes(name_).length != 0);
        require(bytes(symbol_).length != 0);
        require(decimals_ >= 6 && decimals_ <= 18);
        if (__tokens[_token].localAddress == address(0)) {
            BridgeToken _tokenAddress = new BridgeToken(
                authority,
                name_,
                symbol_,
                decimals_
            );
            __tokens[_token].localAddress = address(_tokenAddress);
            emit BridgeTokenCreated(_token, address(_tokenAddress));
        }
    }

    function whitelistChainId(bytes32 _chainId) external onlyController {
        __chains[_chainId] = Chain({isWhitelisted: true});
    }

    function setThreshold(uint8 _threshold) external onlyController {
        threshold = _threshold;
    }

    /*
     * Relayer Methods
     */

    function unwrapMultipleWithSignatures(
        RelayerRequest[] calldata requests,
        bytes[][] memory signatures
    ) external {
        for (uint256 i = 0; i < requests.length; i++) {
            bytes32 hashedProposal = hashProposal(requests[i]);
            for (uint256 j = 0; j < signatures[i].length; j++) {
                address signer = recoverSigner(
                    hashedProposal,
                    signatures[i][j]
                );
                _handleUnwrap(requests[i], hashedProposal, signer);
            }
        }
    }

    function unwrapWithSignatures(
        RelayerRequest calldata request,
        bytes[] memory signatures
    ) external {
        bytes32 hashedProposal = hashProposal(request);
        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = recoverSigner(hashedProposal, signatures[i]);
            _handleUnwrap(request, hashedProposal, signer);
        }
    }

    function unwrapWithSignature(
        RelayerRequest calldata request,
        bytes memory signature
    ) external {
        bytes32 hashedProposal = hashProposal(request);
        address signer = recoverSigner(hashedProposal, signature);
        _handleUnwrap(request, hashedProposal, signer);
    }

    function overrideUnwrap(bytes32 hashedProposal) external onlyController {
        // used to override finalization of transaction
        __proposals[hashedProposal].completed = true;
    }

    function batchUnwrap(RelayerRequest[] calldata requests) external {
        uint256 completed = 0;
        for (uint256 i = 0; i < requests.length; i++) {
            RelayerRequest calldata cur = requests[i];
            bytes32 hashedProposal = hashProposal(cur);
            if (
                __proposals[hashedProposal].completed ||
                __proposals[hashedProposal].voted[msg.sender]
            ) {
                continue;
            }
            unwrap(cur);
            completed++;
        }
        require(completed > 0, "no op"); // this prevents accidently calling this and having no actions take place
    }

    function unwrap(RelayerRequest calldata request) public {
        bytes32 hashedProposal = hashProposal(request);
        _handleUnwrap(request, hashedProposal, msg.sender);
    }

    function _handleUnwrap(
        RelayerRequest calldata request,
        bytes32 hashedProposal,
        address sender
    ) internal whenNotPaused {
        require(isWhitelistedRelayer[sender], "not a valid relayer");
        require(request.targetChainId == chainId, "wrong chain");
        require(!__proposals[hashedProposal].completed, "already unwrapped");
        require(
            !__proposals[hashedProposal].voted[msg.sender],
            "already voted"
        );

        __proposals[hashedProposal].voted[msg.sender] = true;
        __proposals[hashedProposal].voteCount += 1;

        emit ProposalVoted(hashedProposal, msg.sender);

        if (__proposals[hashedProposal].voteCount >= threshold) {
            _unwrap(request.token, request.amount, request.recipient);
            __proposals[hashedProposal].completed = true;
            emit ProposalFinalized(hashedProposal);
        }
    }

    /*
     * Public Method
     */

    function wrap(
        bytes32 token,
        uint256 amount,
        address recipient,
        bytes32 targetChainId
    ) public payable whenNotPaused {
        require(__chains[targetChainId].isWhitelisted, "chain not supported");
        require(
            tokenWhitelistedForChain[token][targetChainId],
            "chain not supported for token"
        );
        require(__tokens[token].isWhitelisted, "token not whitelisted");
        require(
            amount <= __tokens[token].maxTransaction,
            "over max transaction"
        );
        require(
            amount >= __tokens[token].minTransaction,
            "under min transaction"
        );

        uint256 gasFee = __tokens[token].gasFee;
        uint256 fee = (amount * feeAmount) / feeFactor;
        require(gasFee + fee < amount, "Transfer Amount Less Than Fee");
        amount -= fee + gasFee;

        if (__tokens[token].isGasToken) {
            payable(feeRecipient).transfer(fee + gasFee);
        } else {
            TransferHelper.safeTransferFrom(
                __tokens[token].localAddress,
                msg.sender,
                feeRecipient,
                fee + gasFee
            );
        }

        if (__tokens[token].isGasToken) {
            require(balance + amount <= address(this).balance);
            balance = address(this).balance;
        } else {
            TransferHelper.safeTransferFrom(
                __tokens[token].localAddress,
                msg.sender,
                address(this),
                amount
            );
        }

        if (__tokens[token].nativeChain != chainId) {
            IBurnable(__tokens[token].localAddress).burn(amount);
        }

        emit LockedToken(
            token,
            amount,
            recipient,
            targetChainId,
            block.number,
            proposalIndex++ // increment index to prevent collisions
        );
    }

    /*
     * Private Functions
     */

    function _unwrap(
        bytes32 token,
        uint256 amount,
        address recipient
    ) private {
        if (__tokens[token].nativeChain == chainId) {
            if (__tokens[token].isGasToken) {
                (bool sent, bytes memory _data) = payable(recipient).call{
                    value: amount
                }("");
                require(sent, "Failed to send Ether");
            } else {
                TransferHelper.safeTransfer(
                    __tokens[token].localAddress,
                    recipient,
                    amount
                );
            }
        } else {
            IBridgeToken(__tokens[token].localAddress).mint(recipient, amount);
        }
    }

    function deposit() external payable {
        balance += msg.value;
    }

    function sync() external {
        balance = address(this).balance;
    }

    /*
     * VIEWS
     */

    function hasVoted(bytes32 _hashedProposal, address voter)
        external
        view
        returns (bool)
    {
        return __proposals[_hashedProposal].voted[voter];
    }

    /*
     * Pure Functions
     */

    function hashProposal(RelayerRequest calldata request)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    request.token,
                    request.amount,
                    request.recipient,
                    request.targetChainId,
                    request.transactionBlockNumber,
                    request._proposalIndex
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IBridgeToken.sol";

import "./types/AccessControlled.sol";
import "./interfaces/IAuthority.sol";

contract BridgeToken is IBridgeToken, ERC20, AccessControlled {
    uint8 immutable _decimals;

    constructor(
        IAuthority _authority,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) AccessControlled(_authority) {
        _decimals = decimals_;
    }

    function mint(address account, uint256 amount) external onlyBridge {
        _mint(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

interface IAuthority {
    function bridge() external view returns (address);

    function controller() external view returns (address);

    function ping() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./IBridgeToken.sol";

interface IBridge {
    struct Proposal {
        mapping(address => bool) voted;
        uint8 voteCount;
        bool completed;
    }

    struct RelayerRequest {
        bytes32 token;
        uint256 amount;
        address recipient;
        bytes32 targetChainId;
        uint256 transactionBlockNumber;
        uint256 _proposalIndex;
    }

    struct Token {
        bool isWhitelisted;
        address localAddress;
        // track the native token address for simplicity, even if redundant
        address nativeAddress;
        bytes32 nativeChain;
        // max amount in a single transaction
        uint256 maxTransaction;
        // min amount in a single transaction
        uint256 minTransaction;
        bool isGasToken;
        uint256 gasFee;
    }

    struct Chain {
        bool isWhitelisted;
    }

    event FeeUpdated(uint16);
    event ProposalFinalized(bytes32);
    event ProposalVoted(bytes32, address);
    event LockedToken(
        bytes32 token,
        uint256 amount,
        address recipient,
        bytes32 targetChainId,
        uint256 blockNumber,
        uint256 proposalIndex
    );
    event WhitelistedRelayer(address);
    event BridgeTokenCreated(bytes32, address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

interface IBridgeToken {
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

interface IBurnable {
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//solhint-disable avoid-low-level-calls
//solhint-disable reason-string

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract Signer {
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65);
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        public
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "../interfaces/IAuthority.sol";

abstract contract AccessControlled {
    /* ========== EVENTS ========== */
    event AuthorityUpdated(IAuthority indexed authority);
    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */
    IAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);

        if (address(_authority) != address(this)) {
            _ping();
        }
    }

    /* ========== MODIFIERS ========== */

    modifier onlyBridge() {
        require(msg.sender == authority.bridge(), UNAUTHORIZED);
        _;
    }

    modifier onlyController() {
        require(msg.sender == authority.controller(), UNAUTHORIZED);
        _;
    }

    function _ping() internal {
        // used to track contracts using the authority on the authority contract
        // could simplify upgrades
        authority.ping();
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IAuthority _newAuthority) external onlyController {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);

        _ping();
    }
}