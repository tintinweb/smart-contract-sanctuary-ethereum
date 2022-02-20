// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./imports/BridgeBase.sol";

contract BridgeEthereum is BridgeBase {
    constructor(address payable tokenAddress) BridgeBase(tokenAddress, "ETH") {
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Multiownable {
    uint256 private _ownersGeneration;
    uint256 private _requiredConfirmations;
    address[] internal _owners;
    bytes32[] public _allOperations;
    address private _insideCallSender;
    uint256 private _insideCallCount;

    // Reverse lookup tables for _owners and _allOperations
    mapping(address => uint) private _ownersIndices; // Starts from 1
    mapping(bytes32 => uint) private _allOperationsIndices;

    // Owners voting mask per operations
    mapping(bytes32 => uint256) private _votesMaskByOperation;
    mapping(bytes32 => uint256) private _votesCountByOperation;

    constructor() {
        _owners.push(msg.sender);
        _ownersIndices[msg.sender] = 1;
        _requiredConfirmations = 1;
    }

    // ACCESSORS

    function isOwner(address account) public view returns(bool) {
        return _ownersIndices[account] > 0;
    }

    function ownersCount() public view returns(uint) {
        return _owners.length;
    }

    function allOperationsCount() public view returns(uint) {
        return _allOperations.length;
    }

    // MODIFIERS

    /// Allows to perform method by any of the owners
    modifier onlyAnyOwner {
        if (checkHowManyOwners(1)) {
            bool update = (_insideCallSender == address(0));
            if (update) {
                _insideCallSender = msg.sender;
                _insideCallCount = 1;
            }
            _;
            if (update) {
                _insideCallSender = address(0);
                _insideCallCount = 0;
            }
        }
    }

    /// Allows to perform method only after many owners call it with the same arguments
    modifier onlyManyOwners {
        if (checkHowManyOwners(_requiredConfirmations)) {
            bool update = (_insideCallSender == address(0));
            if (update) {
                _insideCallSender = msg.sender;
                _insideCallCount = _requiredConfirmations;
            }
            _;
            if (update) {
                _insideCallSender = address(0);
                _insideCallCount = 0;
            }
        }
    }

    /// Allows to perform method only after all owners call it with the same arguments
    modifier onlyAllOwners {
        if (checkHowManyOwners(_owners.length)) {
            bool update = (_insideCallSender == address(0));
            if (update) {
                _insideCallSender = msg.sender;
                _insideCallCount = _owners.length;
            }
            _;
            if (update) {
                _insideCallSender = address(0);
                _insideCallCount = 0;
            }
        }
    }

    /// Allows to perform method only after some owners call it with the same arguments
    modifier onlySomeOwners(uint howMany) {
        require(howMany > 0, "Multiownable: howMany argument is zero");
        require(howMany <= _owners.length, "Multiownable: howMany argument exceeds the number of owners");
        
        if (checkHowManyOwners(howMany)) {
            bool update = (_insideCallSender == address(0));
            if (update) {
                _insideCallSender = msg.sender;
                _insideCallCount = howMany;
            }
            _;
            if (update) {
                _insideCallSender = address(0);
                _insideCallCount = 0;
            }
        }
    }

    // INTERNAL METHODS

    /// onlyManyOwners modifier helper
    function checkHowManyOwners(uint howMany) internal returns(bool) {
        if (_insideCallSender == msg.sender) {
            require(howMany <= _insideCallCount, "Multiownable: nested owners modifier check require more owners");
            return true;
        }

        uint ownerIndex = _ownersIndices[msg.sender] - 1;
        require(ownerIndex < _owners.length, "Multiownable: msg.sender is not an owner");
        bytes32 operation = keccak256(abi.encodePacked(msg.data, _ownersGeneration));

        require((_votesMaskByOperation[operation] & (2 ** ownerIndex)) == 0, "Multiownable: owner already voted for the operation");
        _votesMaskByOperation[operation] |= (2 ** ownerIndex);
        uint operationVotesCount = _votesCountByOperation[operation] + 1;
        _votesCountByOperation[operation] = operationVotesCount;

        if (operationVotesCount == 1) {
            _allOperationsIndices[operation] = _allOperations.length;
            _allOperations.push(operation);
            emit OperationCreated(operation, howMany, _owners.length, msg.sender);
        }

        emit OperationUpvoted(operation, operationVotesCount, howMany, _owners.length, msg.sender);

        // If enough owners confirmed the same operation
        if (_votesCountByOperation[operation] == howMany) {
            deleteOperation(operation);
            emit OperationPerformed(operation, howMany, _owners.length, msg.sender);
            return true;
        }

        return false;
    }

    /// Used to delete cancelled or performed operation
    /// @param operation defines which operation to delete
    function deleteOperation(bytes32 operation) internal {
        uint index = _allOperationsIndices[operation];
        if (index < _allOperations.length - 1) { // Not last
            _allOperations[index] = _allOperations[_allOperations.length - 1];
            _allOperationsIndices[_allOperations[index]] = index;
        }

        _allOperations.push(_allOperations[_allOperations.length-1]);

        delete _votesMaskByOperation[operation];
        delete _votesCountByOperation[operation];
        delete _allOperationsIndices[operation];
    }

    // PUBLIC METHODS

    /// Allows owners to change their mind by cancelling _votesMaskByOperation operations
    /// @param operation defines which operation to delete
    function cancelPending(bytes32 operation) public onlyAnyOwner {
        uint ownerIndex = _ownersIndices[msg.sender] - 1;
        require((_votesMaskByOperation[operation] & (2 ** ownerIndex)) != 0, "Multiownable: operation not found for this user");
        _votesMaskByOperation[operation] &= ~(2 ** ownerIndex);

        uint operationVotesCount = _votesCountByOperation[operation] - 1;
        _votesCountByOperation[operation] = operationVotesCount;
        emit OperationDownvoted(operation, operationVotesCount, _owners.length, msg.sender);

        if (operationVotesCount == 0) {
            deleteOperation(operation);
            emit OperationCancelled(operation, msg.sender);
        }
    }

    /// Allows owners to change ownership
    /// @param newOwners defines array of addresses of new owners
    function transferOwnership(address[] memory newOwners) public {
        transferOwnership(newOwners, newOwners.length);
    }

    /// Allows owners to change ownership
    /// @param newOwners defines array of addresses of new owners
    /// @param requiredConfirmations defines how many owners can decide
    function transferOwnership(address[] memory newOwners, uint256 requiredConfirmations) public onlyManyOwners {
        require(newOwners.length > 0, "Multiownable: no new owners specified");
        require(newOwners.length <= 256, "Multiownable: exceeded maximum number of owners");
        require(requiredConfirmations > 0, "Multiownable: required confirmations must be greater than zero");
        require(requiredConfirmations <= newOwners.length, "Multiownable: required confirmations exceeds the number of owners");

        // Reset owners reverse lookup table
        for (uint j = 0; j < _owners.length; j++) {
            delete _ownersIndices[_owners[j]];
        }

        for (uint i = 0; i < newOwners.length; i++) {
            require(newOwners[i] != address(0), "Multiownable: owner must be a non-zero address");
            require(_ownersIndices[newOwners[i]] == 0, "Multiownable: all owners must be unique");
            _ownersIndices[newOwners[i]] = i + 1;
        }
        
        emit OwnershipTransferred(_owners, _requiredConfirmations, newOwners, requiredConfirmations);
        _owners = newOwners;
        _requiredConfirmations = requiredConfirmations;
        _allOperations.push(_allOperations[0]);
        _ownersGeneration++;
    }

    event OwnershipTransferred(address[] previousOwners, uint requiredConfirmations, address[] newOwners, uint newRequiredConfirmations);
    event OperationCreated(bytes32 operation, uint howMany, uint ownersCount, address proposer);
    event OperationUpvoted(bytes32 operation, uint votes, uint howMany, uint ownersCount, address upvoter);
    event OperationPerformed(bytes32 operation, uint howMany, uint ownersCount, address performer);
    event OperationDownvoted(bytes32 operation, uint votes, uint ownersCount,  address downvoter);
    event OperationCancelled(bytes32 operation, address lastCanceller);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Multiownable.sol";

abstract contract BridgeBase is Multiownable {
    address private _tokenAddress;
    string private _symbol;

    mapping(address => uint256) private _tokensSent;
    mapping(address => uint256) private _tokensReceived;
    mapping(address => uint256) private _tokensReceivedButNotSent;

    bool transferStatus;
    bool avoidReentrancy;

    constructor(address payable tokenAddress, string memory symbol) {
        _tokenAddress = tokenAddress;
        _symbol = symbol;
    }

    function sendTokens(uint256 amount) public {
        require(msg.sender != address(0), "BridgeBase: Zero account specified");
        require(amount > 0, "BridgeBase: Amount must be non-zero");
        require(ERC20(_tokenAddress).balanceOf(msg.sender) >= amount, "BridgeBase: Insufficient balance");
        
        transferStatus = ERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount);
        if (transferStatus == true) {
            _tokensReceived[msg.sender] += amount;
        }
    }

    function writeTransaction(address user, uint256 amount) public onlyAllOwners {
        require(user != address(0), "BridgeBase: Zero account specified");
        require(amount > 0, "BridgeBase: Amount must be non-zero");
        require(!avoidReentrancy);
        
        avoidReentrancy = true;
        _tokensReceivedButNotSent[user] += amount;
        avoidReentrancy = false;
    }

    function receiveTokens(uint256[] memory commissions) public payable {
        if (_tokensReceivedButNotSent[msg.sender] != 0) {
            require(commissions.length == _owners.length, "BridgeBase: The numbers of commissions and owners do not match");
            uint256 sum;

            for(uint i = 0; i < commissions.length; i++) {
                sum += commissions[i];
            }

            require(msg.value >= sum, string(abi.encodePacked("BridgeBase: Insufficient amount (less than the amount of commissions) of ", _symbol)));
            require(msg.value >= _owners.length * 150000 * 10**9, string(abi.encodePacked("BridgeBase: Insufficient amount (less than the internal commission) of ", _symbol)));
        
            for (uint i = 0; i < _owners.length; i++) {
                address payable owner = payable(_owners[i]);
                uint256 commission = commissions[i];
                owner.transfer(commission);
            }
            
            uint256 amountToSend = _tokensReceivedButNotSent[msg.sender] - _tokensSent[msg.sender];
            transferStatus = ERC20(_tokenAddress).transfer(msg.sender, amountToSend);

            if (transferStatus) {
                _tokensSent[msg.sender] += amountToSend;
            }
        }
    }

    function withdrawTokens(uint256 amount, address receiver) public onlyAllOwners {
        require(receiver != address(0), "BridgeBase: Zero account specified");
        require(amount > 0, "BridgeBase: Amount must be non-zero");
        require(ERC20(_tokenAddress).balanceOf(address(this)) >= amount, "BridgeBase: Insufficient balance");
        
        ERC20(_tokenAddress).transfer(receiver, amount);
    }

    function withdrawEther(uint256 amount, address payable receiver) public onlyAllOwners {
        require(receiver != address(0), "BridgeBase: Zero account specified");
        require(amount > 0, "BridgeBase: Amount must be non-zero");
        require(address(this).balance >= amount, "BridgeBase: Insufficient balance");

        receiver.transfer(amount);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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