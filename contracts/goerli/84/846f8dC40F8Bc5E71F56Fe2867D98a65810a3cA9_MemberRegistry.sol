// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "./interfaces/iInstanceDAO.sol";
import "./interfaces/IMember1155.sol";
import "./interfaces/IDAO20.sol";

contract DAO20 is ERC20 {
    address public owner;
    address public base;
    address public burnInProgress;
    IERC20 baseToken;

    constructor(address baseToken_, string memory name_, string memory symbol_, uint8 decimals_)
        ERC20(name_, symbol_)
    {
        owner = msg.sender;
        base = baseToken_;
        baseToken = IERC20(baseToken_);
    }

    error NotOwner();

    modifier OnlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function wrapMint(uint256 amt) external returns (bool s) {
        s = baseToken.transferFrom(msg.sender, owner, amt);
        if (s) {
            //iInstanceDAO(owner).mintInflation(); /// @dev this breaks mint on anvil. also maybe bad idea. @todo
            _mint(msg.sender, amt);
        }
        require(s, "ngmi");
    }

    function unwrapBurn(uint256 amtToBurn_) external returns (bool s) {
        require(balanceOf(msg.sender) >= amtToBurn_, "Insufficient balance");
        require(burnInProgress == address(0), "burnInProgress");
        burnInProgress = msg.sender;
        uint256 amtToRefund = baseToken.balanceOf(owner) * amtToBurn_ / totalSupply();
        _burn(msg.sender, amtToBurn_);
        s = baseToken.transferFrom(owner, msg.sender, amtToRefund);

        if (s) {
            iInstanceDAO(owner).distributiveSignal(new uint256[](0));
            burnInProgress = address(0);
        }
        require(s, "ngmi");
    }

    function unwrapBurn(address from_, uint256 amtToBurn_) external OnlyOwner {
        require(balanceOf(from_) >= amtToBurn_, "Insufficient balance");
        _burn(from_, amtToBurn_);
    }

    function inflationaryMint(uint256 amt) public OnlyOwner returns (bool) {
        _mint(owner, amt);
        return true;
    }

    function mintInitOne(address to_) external returns (bool) {
        require(msg.sender == owner, "ngmi");
        _mint(to_, 1);
        return balanceOf(to_) == 1;
    }

    /// ////////////////////

    /// Override //////////////

    //// @dev @security DAO token should be transferable only to DAO instances or owner (resource basket multisig)
    /// there's some potential attack vectors on inflation and redistributive signals (re-enterange like)
    /// two options: embrace the messiness |OR| allow transfers only to owner and sub-entities

    function transfer(address to, uint256 amount) public override returns (bool) {
        /// limit transfers
        bool o = msg.sender == owner;
        address parent = iInstanceDAO(owner).parentDAO();
        o = !o ? parent == msg.sender : o;
        o = !o ? to == iInstanceDAO(msg.sender).endpoint() : o;

        // o = !o ? iInstanceDAO(iInstanceDAO(owner).parentDAO()).isMember(msg.sender) : o;
        // o = !o ? (parent == address(0)) && (msg.sig == this.wrapMint.selector) : o;
        // o = !o ? (iInstanceDAO(owner).baseTokenAddress() == msg.sender ) : o;

        require(o, "unauthorized - transfer");
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        /// limit transfers
        bool o = msg.sender == owner;
        o = !o ? iInstanceDAO(owner).parentDAO() == msg.sender : o;
        o = !o ? (IDAO20(msg.sender).base() == address(this)) : o;
        require(o, "unauthorized - transferFrom");

        if (from == owner) _mint(owner, amount);
        require(super.transferFrom(from, to, amount));
        return true;
    }

    // function _balanceOf(address who_) external returns (uint) {
    //     return balanceOf[who_];
    // }

    // function _totalSupply() external returns (uint) {
    //     return this.totalSupply;
    // }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IMember1155.sol";
import "./interfaces/IoDAO.sol";
import "./interfaces/iInstanceDAO.sol";
import "./interfaces/IMembrane.sol";
import "./interfaces/IExternalCall.sol";
import "./utils/Address.sol";
import "./DAO20.sol";
import "./errors.sol";
import "./interfaces/ICantoTurnstile.sol";
import "./interfaces/ICSRvault.sol";

contract DAOinstance {
    uint256 public baseID;
    uint256 public baseInflationRate;
    uint256 public baseInflationPerSec;
    uint256 public instantiatedAt;
    address public parentDAO;
    address public endpoint;
    address ODAO;
    address purgeorExternalCall;
    IERC20 public BaseToken;
    DAO20 public internalToken;
    IMemberRegistry iMR;
    IMembrane iMB;
    IExternalCall iEXT;

    /// # EOA => subunit => [percentage, amt]
    /// @notice stores broadcasted signal of user about preffered distribution [example: 5% of inflation to subDAO x]
    /// @notice formed as address of affirming agent => address of subDAO (or endpoint) => 1-100% percentage amount.
    mapping(address => mapping(address => uint256[2])) userSignal;

    /// #subunit id => [perSecond, timestamp]
    /// @notice stores the nominal amount a subunit is entitled to
    /// @notice formed as address_of_subunit => [amount_of_entitlement_gained_each_second, time_since_last_withdrawal @dev ?]
    mapping(address => uint256[2]) subunitPerSec;

    /// last user distributive signal
    /// @notice stored array of preffered user redistribution percentages. formatted as `address of agent => [array of preferences]
    /// @notice minimum value 1, maximum vaule 100. Sum of percentages needs to add up to 100.
    mapping(address => uint256[]) redistributiveSignal;

    /// expressed: membrane / inflation rate / * | msgSender()/address(0) | value/0
    /// @notice expressed quantifiable support for specified change of membrane, inflation or *
    mapping(uint256 => mapping(address => uint256)) expressed;

    /// list of expressors for id/percent/uri
    /// @notice stores array of agent addresses that are expressing a change
    mapping(uint256 => address[]) expressors;

    // uint256[] private activeIndecisions; ///// @todo

    // ITurnstile TurnS = ITurnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);
    // ICSRvault CSRvault = ICSRvault(0xEcf044C5B4b867CFda001101c617eCd347095B44); /// ICSR VAULT ADDRESS

    constructor(address BaseToken_, address initiator_, address MemberRegistry_) {
        ODAO = msg.sender;
        instantiatedAt = block.timestamp;
        BaseToken = IERC20(BaseToken_);
        baseID = uint160(bytes20(address(this)));
        baseInflationRate = baseID % 100 > 0 ? baseID % 100 : 1;
        iMR = IMemberRegistry(MemberRegistry_);
        iMB = IMembrane(iMR.MembraneRegistryAddress());
        iEXT = IExternalCall(iMR.ExternalCallAddress());
        internalToken = new DAO20(BaseToken_, "WalllaW$_$Internal", "WdoW",18);
        BaseToken.approve(address(internalToken), type(uint256).max - 1);

        subunitPerSec[address(this)][1] = block.timestamp;
        address CSRvault = IoDAO(ODAO).CSRvault();
        ITurnstile(ICSRvault(CSRvault).turnSaddr()).assign(ICSRvault(CSRvault).CSRtokenID());

        emit NewInstance(address(this), BaseToken_, initiator_);
    }

    /*//////////////////////////////////////////////////////////////
                                 events
    //////////////////////////////////////////////////////////////*/

    event StateAdjusted();
    event AdjustedRate();
    event UserPreferedGuidance();
    event FallbackCalled(address caller, uint256 amount, string message);
    event GlobalInflationUpdated(uint256 RatePerYear, uint256 perSecInflation);
    event inflationaryMint(uint256 amount);
    event NewInstance(address indexed at, address indexed baseToken, address owner);

    /*//////////////////////////////////////////////////////////////
                                 modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyMember() {
        if (msg.sender == address(internalToken) || msg.sender == address(this)) {
            _;
        } else {
            if (!isMember(_msgSender())) revert DAOinstance__NotMember();
            _;
        }
    }

    /// percentage anualized 1-100 as relative to the totalSupply of base token
    /// @notice signal preferred annual inflation rate. Multiple preferences possible.
    /// @notice materialized amounts are sensitive to totalSupply. Majoritarian execution.
    /// @param percentagePerYear_ prefered option in range 0 - 100
    function signalInflation(uint256 percentagePerYear_) external onlyMember returns (uint256 inflationRate) {
        require(percentagePerYear_ <= 100, ">100!");
        _expressPreference(percentagePerYear_);

        inflationRate = (internalToken.totalSupply() / ((expressed[percentagePerYear_][address(0)] + 1)) < 2)
            ? _majoritarianUpdate(percentagePerYear_)
            : baseInflationRate;
    }

    /// @notice initiate or support change of membrane in favor of designated by id
    /// @param membraneId_ id of membrane to support change of
    function changeMembrane(uint256 membraneId_) external onlyMember returns (uint256 membraneID) {
        _expressPreference(membraneId_);
        if (!iMB.isMembrane(membraneId_)) revert DAOinstance__invalidMembrane();

        membraneID = ((internalToken.totalSupply() / (expressed[membraneId_][address(0)] + 1) < 2))
            ? _majoritarianUpdate(membraneId_)
            : iMB.inUseMembraneId(address(this));
    }

    /// @notice expresses preference for and executes pre-configured extenrall call with provided id on majoritarian threshold
    /// @param externalCallId_ id of preconfigured externall call
    /// @return callID 0 - if threshold not reached, id input if call is executed.
    function executeCall(uint256 externalCallId_) external onlyMember returns (uint256 callID) {
        if (!iEXT.isValidCall(externalCallId_)) revert DAOinstance__invalidMembrane();
        _expressPreference(externalCallId_);

        callID = ((internalToken.totalSupply() / (expressed[externalCallId_][address(0)] + 1) < 2))
            && (iEXT.exeUpdate(externalCallId_)) ? _majoritarianUpdate(externalCallId_) : 0;
    }

    /// @notice signal prefferred redistribution percentages out of inflation
    /// @notice beneficiaries are ordered chonologically and expects a value for each item retruend by `getDAOsOfToken`
    /// @param cronoOrderedDistributionAmts complete array of preffered sub-entity distributions with sum 100

    function distributiveSignal(uint256[] memory cronoOrderedDistributionAmts)
        external
        onlyMember
        returns (uint256 i)
    {
        address sender = _msgSender();
        uint256 senderForce = internalToken.balanceOf(sender);
        if ((senderForce == 0 && (!(cronoOrderedDistributionAmts.length == 0)))) revert DAOinstance__HasNoSay();
        if (cronoOrderedDistributionAmts.length == 0) cronoOrderedDistributionAmts = redistributiveSignal[sender];
        redistributiveSignal[sender] = cronoOrderedDistributionAmts;

        address[] memory subDAOs = IoDAO(ODAO).getDAOsOfToken(address(internalToken));
        if (subDAOs.length != cronoOrderedDistributionAmts.length) revert DAOinstance__LenMismatch();

        uint256 centum;
        uint256 perSec;
        for (i; i < subDAOs.length;) {
            redistributeSubDAO(subDAOs[i]);

            uint256 submittedValue = cronoOrderedDistributionAmts[i];
            if (subunitPerSec[subDAOs[i]][1] == 0) {
                subunitPerSec[subDAOs[i]][1] = iInstanceDAO(subDAOs[i]).instantiatedAt();
            }
            if (submittedValue == subunitPerSec[subDAOs[i]][0]) continue;

            address entity = subDAOs[i];

            unchecked {
                centum += cronoOrderedDistributionAmts[i];
            }
            if (centum > 100_00) revert DAOinstance__Over100();

            perSec = submittedValue * baseInflationPerSec / 100_00;
            perSec = (senderForce * 1 ether / internalToken.totalSupply()) * perSec / 1 ether;
            /// @dev senderForce < 1%

            subunitPerSec[entity][0] = (subunitPerSec[entity][0] - userSignal[sender][entity][1]) + perSec;
            /// @dev fuzz  (subunitPerSec[entity][0] > userSignal[_msgSender()][entity][1])

            userSignal[sender][entity][1] = perSec;
            userSignal[sender][entity][0] = submittedValue;

            unchecked {
                ++i;
            }
        }
    }

    /// @notice checks and trickles down eligible amounts of inflation balance on path from root to this
    function feedMe() external returns (uint256 fed) {
        address[] memory feedPath = IoDAO(ODAO).getTrickleDownPath(address(this));
        if (feedPath[0] == address(0)) {
            return fed = iInstanceDAO(parentDAO).redistributeSubDAO(address(this));
        }

        uint256 i = 1;
        for (i; i < feedPath.length;) {
            if (feedPath[i] == address(0)) break;
            iInstanceDAO(feedPath[i]).redistributeSubDAO(feedPath[i - 1]);

            unchecked {
                ++i;
            }
        }
        fed = iInstanceDAO(feedPath[0]).redistributeSubDAO(address(this));
    }

    function _postMajorityCleanup(address[] memory agents, uint256 target_) public returns (uint256 outcome) {
        if (expressed[target_][address(0)] < (internalToken.totalSupply() / 2)) revert DAOinstance__notmajority();

        uint256 sum;
        address a;
        for (outcome; outcome < agents.length;) {
            a = agents[outcome];
            unchecked {
                sum += expressed[target_][a];
            }
            delete expressed[target_][a];
            unchecked {
                ++outcome;
            }
        }
        outcome = sum;
    }

    function mintInflation() public returns (uint256 amountToMint) {
        amountToMint = (block.timestamp - subunitPerSec[address(this)][1]);
        if (amountToMint == 0) return amountToMint;

        amountToMint = (amountToMint * baseInflationPerSec);
        require(internalToken.inflationaryMint(amountToMint));
        subunitPerSec[address(this)][1] = block.timestamp;

        _majoritarianUpdate(0);

        emit inflationaryMint(amountToMint);
    }

    function redistributeSubDAO(address subDAO_) public returns (uint256 gotAmt) {
        mintInflation();
        gotAmt = subunitPerSec[subDAO_][0] * (block.timestamp - subunitPerSec[subDAO_][1]);
        subunitPerSec[subDAO_][1] = block.timestamp;
        if (!internalToken.transfer(subDAO_, gotAmt)) revert DAOinstance__itTransferFailed();
    }

    /// @notice mints membership token to specified address if it fulfills the acceptance criteria of the membrane
    /// @param to_ address to mint membership token to
    function mintMembershipToken(address to_) external returns (bool s) {
        if (endpoint != address(0)) revert DAOinstance__isEndpoint();

        if (msg.sender == ODAO) {
            parentDAO = IoDAO(ODAO).getParentDAO(address(this));
            if (to_ == address(uint160(iMB.inUseMembraneId(address(this))))) {
                endpoint = to_;
                return true;
            }
            if (internalToken.mintInitOne(to_)) return iMR.makeMember(to_, baseID);
        }

        s = iMB.checkG(to_, address(this));
        if (!s) revert DAOinstance__Unqualified();
        s = iMR.makeMember(to_, baseID) && s;
    }

    /// @notice burns internal token and returnes to msg.sender the eligible underlying amount of parent tokens
    function withdrawBurn(uint256 amt_) external returns (bool s) {
        if (endpoint != _msgSender()) revert DAOinstance__NotYourEnpoint();
        s = BaseToken.transfer(endpoint, amt_);
    }

    /// @notice immune mechanism to check basis of membership and revoke if invalid
    /// @param who_ address to check
    function gCheckPurge(address who_) external returns (bool) {
        if (msg.sender != address(iMR)) revert DAOinstance__onlyMR();

        delete redistributiveSignal[who_];
        address keepExtCall = purgeorExternalCall;
        purgeorExternalCall = who_;
        this.distributiveSignal(redistributiveSignal[who_]);
        delete purgeorExternalCall;
        purgeorExternalCall = keepExtCall;

        return true;
    }

    // function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
    //     results = new bytes[](data.length);
    //     for (uint256 i = 0; i < data.length; i++) {
    //         results[i] = Address.functionDelegateCall(address(this), data[i]);
    //     }
    //     return results;
    // }

    /// @notice executes the outcome of any given successful majoritarian tipping point
    ///////////////////
    function _majoritarianUpdate(uint256 newVal_) private returns (uint256) {
        if (msg.sig == this.mintInflation.selector) {
            baseInflationPerSec = internalToken.totalSupply() * baseInflationRate / 365 days / 100;
        }

        if (msg.sig == this.signalInflation.selector) {
            baseInflationRate = newVal_;
            baseInflationPerSec = internalToken.totalSupply() * newVal_ / 365 days / 100;
            return _postMajorityCleanup(newVal_);
        }

        if (msg.sig == this.changeMembrane.selector) {
            require(iMB.setMembrane(newVal_, address(this)), "f O.setM.");
            iMR.setUri(iMB.inUseUriOf(address(this)));
            return _postMajorityCleanup(newVal_);
        }

        if (msg.sig == this.executeCall.selector) {
            ExtCall memory callStruct = iEXT.getExternalCallbyID(newVal_);

            uint256 i;
            for (; i < callStruct.contractAddressesToCall.length;) {
                (bool success, bytes memory data) =
                    callStruct.contractAddressesToCall[i].call(callStruct.dataToCallWith[i]);
                if (!success) revert DAOinstance_ExeCallFailed(data);
                unchecked {
                    ++i;
                }
            }
            return _postMajorityCleanup(newVal_);
        }
    }

    /// @dev instantiates in memory a given expressed preference for change
    function _expressPreference(uint256 preference_) private {
        uint256 pressure = internalToken.balanceOf(_msgSender());
        uint256 previous = expressed[preference_][_msgSender()];

        if (previous > 0) expressed[preference_][address(0)] -= previous;
        expressed[preference_][address(0)] += pressure;
        expressed[preference_][_msgSender()] = pressure;
        if (previous == 0) {
            expressors[preference_].push(_msgSender());
            // activeIndecisions.push(preference_);
        }
    }

    /// @dev once a change materializes, this is called to clean state and reset its latent potential
    function _postMajorityCleanup(uint256 target_) private returns (uint256) {
        /// is sum validatation superfluous and prone to error? -&/ gas concerns
        address[] memory agents = expressors[target_];
        uint256 sum = _postMajorityCleanup(agents, target_);

        if (!(sum >= expressed[target_][address(0)])) revert DAOinstance__CannotUpdate();

        /// #extra

        delete expressed[target_][address(0)];
        delete expressors[target_];
        return target_;
    }

    function _msgSender() private view returns (address) {
        if (msg.sender == address(internalToken)) return internalToken.burnInProgress();
        if (msg.sender == address(this) && msg.sig == this.distributiveSignal.selector) return purgeorExternalCall;

        return msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEW
    //////////////////////////////////////////////////////////////*/

    function internalTokenAddress() external view returns (address) {
        return address(internalToken);
    }

    function baseTokenAddress() external view returns (address) {
        return address(BaseToken);
    }

    function getUserReDistribution(address user_) external view returns (uint256[] memory) {
        return redistributiveSignal[user_];
    }

    function isMember(address who_) public view returns (bool) {
        return ((who_ == address(internalToken)) || iMR.balanceOf(who_, baseID) > 0);
    }

    function getUserSignal(address who_, address subUnit_) external view returns (uint256[2] memory) {
        return userSignal[who_][subUnit_];
    }

    function stateOfExpressed(address user_, uint256 prefID_) external view returns (uint256[3] memory pref) {
        pref[0] = expressed[prefID_][user_];
        pref[1] = expressed[prefID_][address(0)];
        pref[2] = internalToken.totalSupply();
    }

    function uri() external view returns (string memory) {
        return iMB.inUseUriOf(address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IoDAO.sol";
import "./interfaces/IExternalCall.sol";
import "./interfaces/ICantoTurnstile.sol";
import "./interfaces/ICSRvault.sol";

contract ExternalCall is IExternalCall {
    uint256 immutable DELAY = 10 * 1 days;

    IoDAO ODAO;

    mapping(uint256 => ExtCall) externalCallById;

    /// id of call => address of dao => lastExecuted
    mapping(uint256 => mapping(address => uint256)) lastExecutedorCreatedAt;

    /// dao nonce
    mapping(address => uint256) nonce;

    constructor(address odao_) {
        ODAO = IoDAO(odao_);
        address CSRvault = IoDAO(ODAO).CSRvault();
        ITurnstile(ICSRvault(CSRvault).turnSaddr()).assign(ICSRvault(CSRvault).CSRtokenID());
    }

    error ExternalCall_UnregisteredDAO();
    error ExternalCall_CallDatasContractsLenMismatch();

    modifier onlyDAO() {
        if (!ODAO.isDAO(msg.sender)) revert ExternalCall_UnregisteredDAO();
        _;
    }

    event NewExternalCall(address indexed CreatedBy, string description, uint256 createdAt);
    event ExternalCallExec(address indexed CalledBy, uint256 indexed WhatCallId, bool SuccessOrLater);

    function createExternalCall(address[] memory contracts_, bytes[] memory callDatas_, string memory description_)
        external
        returns (uint256 idOfNew)
    {
        if (contracts_.length != callDatas_.length) revert ExternalCall_CallDatasContractsLenMismatch();
        ExtCall memory newCall;
        newCall.contractAddressesToCall = contracts_;
        newCall.dataToCallWith = callDatas_;
        newCall.shortDescription = description_;

        idOfNew = uint256(keccak256(abi.encode(newCall))) % 1 ether;
        externalCallById[idOfNew] = newCall;

        emit NewExternalCall(msg.sender, description_, block.timestamp);
    }

    function exeUpdate(uint256 whatExtCallId_) external onlyDAO returns (bool r) {
        r = lastExecutedorCreatedAt[whatExtCallId_][msg.sender] + DELAY <= block.timestamp;
        if (r) {
            delete lastExecutedorCreatedAt[whatExtCallId_][msg.sender];
        } else {
            if (lastExecutedorCreatedAt[whatExtCallId_][msg.sender] == 0) {
                lastExecutedorCreatedAt[whatExtCallId_][msg.sender] = block.timestamp;
            }
        }

        emit ExternalCallExec(msg.sender, whatExtCallId_, r);
    }

    function incrementSelfNonce() external onlyDAO {
        unchecked {
            ++nonce[msg.sender];
        }
    }

    /// @notice at what timestamp the caller executed id_
    function iLastExecuted(uint256 id_) external view returns (uint256) {
        return lastExecutedorCreatedAt[id_][msg.sender];
    }

    function getExternalCallbyID(uint256 id_) external view returns (ExtCall memory) {
        return externalCallById[id_];
    }

    function isValidCall(uint256 id_) external view returns (bool) {
        return externalCallById[id_].contractAddressesToCall.length > 0;
    }

    function getNonceOf(address whom_) external view returns (uint256) {
        return nonce[whom_];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./oDAO.sol";
import "./MembraneRegistry.sol";
import "./ExternalCall.sol";

import "solmate/tokens/ERC1155.sol";
import "./interfaces/IoDAO.sol";
import "./interfaces/iInstanceDAO.sol";
import "./interfaces/IMembrane.sol";

contract MemberRegistry is ERC1155 {
    address public ODAOaddress;
    address public MembraneRegistryAddress;
    address public ExternalCallAddress;

    IoDAO oDAO;
    IMembrane IMB;
    // address[] private roots;
    // address[] private endpoints;
    mapping(address => address[]) endpointsOf;
    mapping(uint256 => string) tokenUri;
    mapping(uint256 => uint256) uidTotalSupply;
    mapping(address => uint256[]) idsOf;

    constructor(address CSRV_) {
        ODAOaddress = address(new ODAO(CSRV_));
        MembraneRegistryAddress = address(new MembraneRegistry(ODAOaddress));
        ExternalCallAddress = address(new ExternalCall(ODAOaddress));
        oDAO = IoDAO(ODAOaddress);
        IMB = IMembrane(MembraneRegistryAddress);
    }

    /*//////////////////////////////////////////////////////////////
                                 errors
    //////////////////////////////////////////////////////////////*/

    error MR1155_Untransferable();
    error MR1155_onlyOdao();
    error MR1155_UnregisteredDAO();
    error MR1155_UnauthorizedID();
    error MR1155_InvalidMintID();
    error MR1155_AlreadyIn();
    error MR1155_OnlyMembraneRegistry();
    error MR1155_OnlyODAO();

    modifier onlyDAO() {
        if (!oDAO.isDAO(msg.sender)) revert MR1155_UnregisteredDAO();
        _;
    }

    modifier onlyMembraneR() {
        if (msg.sender != MembraneRegistryAddress) revert MR1155_OnlyMembraneRegistry();
        _;
    }
    /*//////////////////////////////////////////////////////////////
                                 events
    //////////////////////////////////////////////////////////////*/

    event isNowMember(address who, uint256 id, address dao);

    /*//////////////////////////////////////////////////////////////
                                 external
    //////////////////////////////////////////////////////////////*/

    /// mints membership token to provided address

    function makeMember(address who_, uint256 id_) external onlyDAO returns (bool) {
        /// the id_ of any subunit  is a multiple of DAO address
        if (!(id_ % uint160(bytes20(msg.sender)) == 0)) {
            /// @dev
            revert MR1155_InvalidMintID();
        }
        /// does not yet have member token
        if (balanceOf[who_][id_] > 0) revert MR1155_AlreadyIn();

        /// if first member to join, fetch cell metadata
        /// @todo get membrane meta or dao specific metadata
        // if (tokenUri[id_].length == 0) tokenUri[id_] = oDAO.entityData(id_);

        /// mint membership token
        _mint(who_, id_, 1, abi.encode(tokenUri[id_]));
        idsOf[who_].push(id_);

        emit isNowMember(who_, id_, msg.sender);
        return balanceOf[who_][id_] == 1;
    }

    function setUri(string memory uri_) external onlyDAO {
        tokenUri[uint160(bytes20(msg.sender))] = uri_;
    }

    /*//////////////////////////////////////////////////////////////
                                 view
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view override returns (string memory) {
        return tokenUri[id];
    }

    function getUriOf(address who_) external view returns (string memory) {
        return tokenUri[uint160(bytes20(who_))];
    }

    /// retrieves base DAOs
    // function getRoots(uint256 howMany_) external view returns (address[] memory r) {
    //     if (roots.length < howMany_) howMany_ = endpoints.length;

    //     uint256 i;
    //     r = new address[](howMany_);
    //     for (i; i < howMany_;) {
    //         r[i] = roots[i];
    //         unchecked {
    //             i++;
    //         }
    //     }
    // }

    // function getEndpoints(uint256 howMany_) external view returns (address[] memory r) {
    //     if (endpoints.length < howMany_) howMany_ = endpoints.length;

    //     uint256 i;
    //     r = new address[](howMany_);
    //     for (i; i < howMany_;) {
    //         r[i] = endpoints[i];
    //         unchecked {
    //             i++;
    //         }
    //     }
    // }

    function getActiveMembershipsOf(address who_) external view returns (address[] memory entities) {
        uint256[] memory ids = idsOf[who_];
        uint256 i;
        entities = new address[](ids.length);
        for (i; i < ids.length;) {
            if (balanceOf[who_][ids[i]] > 0) entities[i] = address(uint160(ids[i]));
            unchecked {
                i++;
            }
        }
    }

    function pushIsEndpointOf(address dao_, address endpointOwner_) external {
        if (msg.sender != ODAOaddress) revert MR1155_OnlyODAO();
        // endpoints.push(dao_);
        endpointsOf[endpointOwner_].push(dao_);
    }

    // function pushAsRoot(address dao_) external {
    //     if (msg.sender != ODAOaddress) revert MR1155_OnlyODAO();
    //     // roots.push(dao_);
    // }

    /*//////////////////////////////////////////////////////////////
                                 override
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data)
        public
        override
    {
        if (from != address(0) || to != address(0)) revert MR1155_Untransferable();

        super.safeTransferFrom(from, to, id, amount, data);
    }

    /// @notice custom burn for gCheck functionality
    function gCheckBurn(address who_, address DAO_) external onlyMembraneR returns (bool) {
        uint256 id_ = uint160(bytes20(DAO_));
        _burn(who_, id_, balanceOf[who_][id_]);
        iInstanceDAO(DAO_).gCheckPurge(who_);
        return balanceOf[who_][id_] == 0;
    }

    /// @notice how many tokens does the given id_ has. Useful for checking how many members a DAO has.
    /// @notice id_ is always the uint(address of DAO)
    /// @param id_ id to check how many minted tokens it has associated
    function howManyTotal(uint256 id_) public view returns (uint256) {
        return uidTotalSupply[id_];
    }

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal override {
        super._mint(to, id, amount, data);
        uidTotalSupply[id] += 1;
    }

    function _burn(address from, uint256 id, uint256 amount) internal override {
        super._burn(from, id, amount);
        uidTotalSupply[id] -= 1;
    }

    function _batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) internal override {
        revert("_batchBurn");
    }

    function _batchMint(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override
    {
        revert("_batchMint");
    }

    function getEndpointsOf(address ofWhom_) external view returns (address[] memory) {
        return endpointsOf[ofWhom_];
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override {
        revert("safeBatchTransferFrom");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IoDAO.sol";
import "./interfaces/iInstanceDAO.sol";
import "./interfaces/IMembrane.sol";
import "./interfaces/IMember1155.sol";

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./errors.sol";

contract MembraneRegistry {
    address MRaddress;
    IoDAO ODAO;
    IMemberRegistry iMR;

    mapping(uint256 => Membrane) getMembraneById;
    mapping(address => uint256) usesMembrane;

    constructor(address ODAO_) {
        iMR = IMemberRegistry(msg.sender);
        ODAO = IoDAO(ODAO_);
    }

    error Membrane__membraneNotFound();
    error Membrane__aDAOnot();
    error Membrane__ExpectedODorD();
    error Membrane__MembraneChangeLimited();
    error Membrane__EmptyFieldOnMembraneCreation();
    error Membrane__onlyODAOToSetEndpoint();
    error Membrane__SomethingWentWrong();

    event CreatedMembrane(uint256 id, string metadata);
    event ChangedMembrane(address they, uint256 membrane);
    event gCheckKick(address indexed who);

    /// @notice creates membrane. Used to control and define.
    /// @notice To be read and understood as: Givent this membrane, of each of the tokens_[x], the user needs at least balances_[x].
    /// @param tokens_ ERC20 or ERC721 token addresses array. Each is used as a constituent item of the membrane and condition for
    /// @param tokens_ belonging or not. Membership is established by a chain of binary claims whereby
    /// @param tokens_ the balance of address checked needs to satisfy all balances_ of all tokens_ stated as benchmark for belonging
    /// @param balances_ amounts required of each of tokens_. The order of required balances needs to map to token addresses.
    /// @param meta_ anything you want. Preferably stable CID for reaching aditional metadata such as an IPFS hash of type string.
    function createMembrane(address[] memory tokens_, uint256[] memory balances_, string memory meta_)
        public
        returns (uint256 id)
    {
        /// @dev consider negative as feature . [] <- isZero. sybil f
        /// @dev @security erc165 check
        if (!((tokens_.length / balances_.length) * bytes(meta_).length >= 1)) {
            revert Membrane__EmptyFieldOnMembraneCreation();
        }
        Membrane memory M;
        M.tokens = tokens_;
        M.balances = balances_;
        M.meta = meta_;
        id = uint256(keccak256(abi.encode(M))) % 1 ether;
        getMembraneById[id] = M;

        emit CreatedMembrane(id, meta_);
    }

    function setMembrane(uint256 membraneID_, address dao_) external returns (bool) {
        if ((msg.sender != dao_) && (msg.sender != address(ODAO))) revert Membrane__MembraneChangeLimited();
        if (getMembraneById[membraneID_].tokens.length == 0) revert Membrane__membraneNotFound();

        usesMembrane[dao_] = membraneID_;
        emit ChangedMembrane(dao_, membraneID_);
        return true;
    }

    function setMembraneEndpoint(uint256 membraneID_, address dao_, address owner_) external returns (bool) {
        if (msg.sender != address(ODAO)) revert Membrane__onlyODAOToSetEndpoint();
        if (address(uint160(membraneID_)) == owner_) {
            if (bytes(getMembraneById[membraneID_].meta).length == 0) {
                Membrane memory M;
                M.meta = "endpoint";
                getMembraneById[membraneID_] = M;
            }
            usesMembrane[dao_] = membraneID_;
            return true;
        } else {
            revert Membrane__SomethingWentWrong();
        }
    }

    /// @notice checks if a given address is member in a given DAO.
    /// @notice answers: Does who_ belong to DAO_?
    /// @param who_ what address to check
    /// @param DAO_ in what DAO or subDAO do you want to check if who_ b
    function checkG(address who_, address DAO_) public view returns (bool s) {
        Membrane memory M = getInUseMembraneOfDAO(DAO_);
        uint256 i;
        s = true;
        for (i; i < M.tokens.length;) {
            s = s && (IERC20(M.tokens[i]).balanceOf(who_) >= M.balances[i]);
            unchecked {
                ++i;
            }
        }
    }

    //// @notice checks if a given address (who_) is a member in the given (dao_). Same as checkG()
    ///  @notice if any of the balances checks specified in the membrane fails, the membership token of checked address is burned
    /// @notice this is a defensive, think auto-imune mechanism.
    /// @param who_ checked address
    /// @dev @todo retrace once again gCheck. Consider spam vectors.
    function gCheck(address who_, address DAO_) external returns (bool s) {
        if (iMR.balanceOf(who_, uint160(bytes20(DAO_))) == 0) return false;
        s = checkG(who_, DAO_);
        if (s) return true;
        if (!s) iMR.gCheckBurn(who_, DAO_);

        //// removed liquidate on kick . this burns membership token but lets user own internaltoken. @security consider

        emit gCheckKick(who_);
    }

    /// @notice returns the meta field of a membrane given its id
    /// @param id_ membrane id_
    function entityData(uint256 id_) external view returns (string memory) {
        return getMembraneById[id_].meta;
    }

    /// @notice returns the membrane given its id_
    /// @param id_ id of membrane you want fetched
    /// @return Membrane struct
    function getMembrane(uint256 id_) external view returns (Membrane memory) {
        return getMembraneById[id_];
    }

    /// @notice checks if a given id_ belongs to an instantiated membrane
    function isMembrane(uint256 id_) external view returns (bool) {
        return (getMembraneById[id_].tokens.length > 0);
    }

    /// @notice fetches the id of the active membrane for given provided DAO adress. Returns 0x0 if none.
    /// @param DAOaddress_ address of DAO (or subDAO) to retrieve mebrane id of
    function inUseMembraneId(address DAOaddress_) public view returns (uint256 ID) {
        return usesMembrane[DAOaddress_];
    }

    /// @notice fetches the in use membrane of DAO
    /// @param DAOAddress_ address of DAO (or subDAO) to retrieve in use Membrane of given DAO or subDAO address
    /// @return Membrane struct
    function getInUseMembraneOfDAO(address DAOAddress_) public view returns (Membrane memory) {
        return getMembraneById[usesMembrane[DAOAddress_]];
    }

    /// @notice returns the uri or CID metadata of given DAO address
    /// @param DAOaddress_ address of DAO to fetch `.meta` of used membrane
    /// @return string
    function inUseUriOf(address DAOaddress_) external view returns (string memory) {
        return getInUseMembraneOfDAO(DAOaddress_).meta;
    }
}

/*//////////////////////////////////////////////////////////////
                                 errors
        //////////////////////////////////////////////////////////////*/

error DAOinstance__NotOwner();
error DAOinstance__TransferFailed();
error DAOinstance__Unqualified();
error DAOinstance__NotMember();
error DAOinstance__InvalidMembrane();
error DAOinstance__CannotUpdate();
error DAOinstance__LenMismatch();
error DAOinstance__Over100();
error DAOinstance__nonR();
error DAOinstance__NotEndpoint1();
error DAOinstance__NotEndpoint2();
error DAOinstance__OnlyODAO();
error DAOinstance__YouCantDoThat();
error DAOinstance__notmajority();
error DAOinstance__CannotLiquidate();
error DAOinstance__NotCallMaker();
error DAOinstance__alreadySet();
error DAOinstance__OnlyDAO();
error DAOinstance__HasNoSay();
error DAOinstance__itTransferFailed();
error DAOinstance__NotIToken();
error DAOinstance__isEndpoint();
error DAOinstance__NotYourEnpoint();
error DAOinstance__onlyMR();
error DAOinstance__invalidMembrane();
error DAOinstance_ExeCallFailed(bytes returnedDataByFailedCall);

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

/// @notice Implementation of CIP-001 https://github.com/Canto-Improvement-Proposals/CIPs/blob/main/CIP-001.md
/// @dev Every contract is responsible to register itself in the constructor by calling `register(address)`.
///      If contract is using proxy pattern, it's possible to register retroactively, however past fees will be lost.
///      Recipient withdraws fees by calling `withdraw(uint256,address,uint256)`.
interface ICSRvault {
    function CSRtokenID() external returns (uint256);

    function selfRegister() external returns (bool);

    function withdrawBurn(uint256 amt) external returns (bool);

    function turnSaddr() external returns (address);

    function sharesTokenAddr() external view returns (address);
}

// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

/// @notice Implementation of CIP-001 https://github.com/Canto-Improvement-Proposals/CIPs/blob/main/CIP-001.md
/// @dev Every contract is responsible to register itself in the constructor by calling `register(address)`.
///      If contract is using proxy pattern, it's possible to register retroactively, however past fees will be lost.
///      Recipient withdraws fees by calling `withdraw(uint256,address,uint256)`.
interface ITurnstile {
    struct NftData {
        uint256 tokenId;
        bool registered;
    }

    /// @notice Returns current value of counter used to tokenId of new minted NFTs
    /// @return current counter value
    function currentCounterId() external view returns (uint256);
    /// @notice Returns tokenId that collects fees generated by the smart contract
    /// @param _smartContract address of the smart contract
    /// @return tokenId that collects fees generated by the smart contract
    function getTokenId(address _smartContract) external view returns (uint256);

    /// @notice Returns true if smart contract is registered to collect fees
    /// @param _smartContract address of the smart contract
    /// @return true if smart contract is registered to collect fees, false otherwise
    function isRegistered(address _smartContract) external view returns (bool);

    /// @notice Mints ownership NFT that allows the owner to collect fees earned by the smart contract.
    ///         `msg.sender` is assumed to be a smart contract that earns fees. Only smart contract itself
    ///         can register a fee receipient.
    /// @param _recipient recipient of the ownership NFT
    /// @return tokenId of the ownership NFT that collects fees
    function register(address _recipient) external returns (uint256 tokenId);

    /// @notice Assigns smart contract to existing NFT. That NFT will collect fees generated by the smart contract.
    ///         Callable only by smart contract itself.
    /// @param _tokenId tokenId which will collect fees
    /// @return tokenId of the ownership NFT that collects fees
    function assign(uint256 _tokenId) external returns (uint256);

    /// @notice Withdraws earned fees to `_recipient` address. Only callable by NFT owner.
    /// @param _tokenId token Id
    /// @param _recipient recipient of fees
    /// @param _amount amount of fees to withdraw
    /// @return amount of fees withdrawn
    function withdraw(uint256 _tokenId, address payable _recipient, uint256 _amount) external returns (uint256);

    /// @notice Distributes collected fees to the smart contract. Only callable by owner.
    /// @param _tokenId NFT that earned fees
    function distributeFees(uint256 _tokenId) external;

    function balances(uint256 _tokenId) external view returns (uint256);
}

pragma solidity ^0.8.0;

interface IDAO20 {
    function wrapMint(uint256 amt) external returns (bool s);

    function base() external view returns (address b);

    function owner() external view returns (address o);

    function unwrapBurn(uint256 amtToBurn_) external returns (bool s);

    //////////////////

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct ExtCall {
    address[] contractAddressesToCall;
    bytes[] dataToCallWith;
    string shortDescription;
}

interface IExternalCall {
    function createExternalCall(address[] memory contracts_, bytes[] memory callDatas_, string memory description_)
        external
        returns (uint256);

    function getExternalCallbyID(uint256 id) external view returns (ExtCall memory);

    function incrementSelfNonce() external;

    function exeUpdate(uint256 whatExtCallId_) external returns (bool);

    function isValidCall(uint256 id_) external view returns (bool);

    function getNonceOf(address whom_) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./structs.sol";

interface IMemberRegistry {
    function makeMember(address who_, uint256 id_) external returns (bool);

    function gCheckBurn(address who_, address DAO_) external returns (bool);

    /// onlyMembrane
    function howManyTotal(uint256 id_) external view returns (uint256);
    function setUri(string memory uri_) external;
    function uri(uint256 id) external view returns (string memory);

    function ODAOaddress() external view returns (address);
    function MembraneRegistryAddress() external view returns (address);
    function ExternalCallAddress() external view returns (address);

    function getRoots(uint256 startAt_) external view returns (address[] memory);
    function getEndpointsOf(address who_) external view returns (address[] memory);

    function getActiveMembershipsOf(address who_) external view returns (address[] memory entities);
    function getUriOf(address who_) external view returns (string memory);
    //// only ODAO

    function pushIsEndpoint(address) external;
    function pushAsRoot(address) external;
    //////////////////////// ERC1155

    ///// only odao
    function pushIsEndpointOf(address dao_, address endpointOwner_) external;

    /**
     * @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
     *     @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     *     MUST revert if `_to` is the zero address.
     *     MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
     *     MUST revert on any other error.
     *     MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     *     After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     *     @param _from    Source address
     *     @param _to      Target address
     *     @param _id      ID of the token type
     *     @param _value   Transfer amount
     *     @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
     *     @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     *     MUST revert if `_to` is the zero address.
     *     MUST revert if length of `_ids` is not the same as length of `_values`.
     *     MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
     *     MUST revert on any other error.
     *     MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
     *     Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
     *     After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     *     @param _from    Source address
     *     @param _to      Target address
     *     @param _ids     IDs of each token type (order and length must match _values array)
     *     @param _values  Transfer amounts per token type (order and length must match _ids array)
     *     @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
     * @notice Get the balance of an account's tokens.
     *     @param _owner  The address of the token holder
     *     @param _id     ID of the token
     *     @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
     * @notice Get the balance of multiple account/token pairs
     *     @param _owners The addresses of the token holders
     *     @param _ids    ID of the tokens
     *     @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
     *     @dev MUST emit the ApprovalForAll event on success.
     *     @param _operator  Address to add to the set of authorized operators
     *     @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Queries the approval status of an operator for a given owner.
     *     @param _owner     The owner of the tokens
     *     @param _operator  Address of authorized operator
     *     @return           True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMembrane {
    struct Membrane {
        address[] tokens;
        uint256[] balances;
        bytes meta;
    }

    function getMembrane(uint256 id) external view returns (Membrane memory);

    function setMembrane(uint256 membraneID_, address DAO_) external returns (bool);

    function setMembraneEndpoint(uint256 membraneID_, address subDAOaddr, address owner) external returns (bool);

    function inUseMembraneId(address DAOaddress_) external view returns (uint256 Id);

    function inUseUriOf(address DAOaddress_) external view returns (string memory);

    function getInUseMembraneOfDAO(address DAOAddress_) external view returns (Membrane memory);

    function createMembrane(address[] memory tokens_, uint256[] memory balances_, string memory meta_)
        external
        returns (uint256);
    function isMembrane(uint256 id_) external view returns (bool);

    function checkG(address who, address DAO_) external view returns (bool s);

    function gCheck(address who_, address DAO_) external returns (bool);

    function entityData(uint256 id_) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IMember1155.sol";

interface IoDAO {
    function isDAO(address toCheck) external view returns (bool);

    function createDAO(address BaseTokenAddress_) external returns (address newDAO);

    function createSubDAO(uint256 membraneID_, address parentDAO_) external returns (address subDAOaddr);

    function getParentDAO(address child_) external view returns (address);

    function getDAOsOfToken(address parentToken) external view returns (address[] memory);

    function getDAOfromID(uint256 id_) external view returns (address);

    function getTrickleDownPath(address floor_) external view returns (address[] memory);

    function CSRvault() external view returns (address);

    function MR() external view returns (address MEMBERRegistryAddress);

    function MB() external view returns (address memBRANEregistryAddress);


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface iInstanceDAO {
    function signalInflation(uint256 percentagePerYear_) external returns (uint256 inflationRate);

    function mintMembershipToken(address to_) external returns (bool);

    function changeMembrane(uint256 membraneId_) external returns (uint256 membraneID);

    function executeCall(uint256 externalCallId) external returns (uint256);

    function distributiveSignal(uint256[] memory cronoOrderedDistributionAmts) external returns (uint256);

    function multicall(bytes[] memory) external returns (bytes[] memory results);

    function executeExternalLogic(uint256 callId_) external returns (bool);

    function feedMe() external returns (uint256);

    function redistributeSubDAO(address subDAO_) external returns (uint256);

    function mintInflation() external returns (uint256);

    function feedStart() external returns (uint256 minted);

    function withdrawBurn(uint256 amt_) external returns (uint256 amtWithdrawn);

    function gCheckPurge(address who_) external;

    /// only MR

    // function cleanIndecisionLog() external;

    /// view

    function getActiveIndecisions() external view returns (uint256[] memory);

    function stateOfExpressed(address user_, uint256 prefID_) external view returns (uint256[3] memory pref);

    function internalTokenAddress() external view returns (address);

    function endpoint() external view returns (address);

    function baseTokenAddress() external view returns (address);

    function baseID() external view returns (uint256);

    function instantiatedAt() external view returns (uint256);

    function getUserReDistribution(address ofWhom) external view returns (uint256[] memory);

    function baseInflationRate() external view returns (uint256);

    function baseInflationPerSec() external view returns (uint256);

    function isMember(address who_) external view returns (bool);

    function parentDAO() external view returns (address);

    function getILongDistanceAddress() external view returns (address);

    function uri() external view returns (string memory);
}

struct Membrane {
    address[] tokens;
    uint256[] balances;
    string meta;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./DAOinstance.sol";
import "./interfaces/IMember1155.sol";
import "./interfaces/iInstanceDAO.sol";
import "./interfaces/IoDAO.sol";
import "./interfaces/IMembrane.sol";
import "./interfaces/ICantoTurnstile.sol";
import "./interfaces/ICSRvault.sol";

contract ODAO {
    mapping(uint256 => address) daoOfId;
    mapping(address => address[]) daosOfToken;
    mapping(address => address) childParentDAO;
    mapping(address => address[]) topLevelPath;
    IMemberRegistry MR;
    address public MB;
    address public CSRvault;
    uint256 constant MAX_160 = type(uint160).max;

    constructor(address CSRvault_) {
        MR = IMemberRegistry(msg.sender);
        CSRvault = CSRvault_;
        ITurnstile(ICSRvault(CSRvault).turnSaddr()).assign(ICSRvault(CSRvault).CSRtokenID());
    }

    /*//////////////////////////////////////////////////////////////
                                 errors
    //////////////////////////////////////////////////////////////*/

    error nullTopLayer();
    error NotCoreMember(address who_);
    error aDAOnot();
    error membraneNotFound();
    error SubDAOLimitReached();
    error NonR();
    error FailedToSetMembrane();

    /*//////////////////////////////////////////////////////////////
                                 events
    //////////////////////////////////////////////////////////////*/

    event newDAOCreated(address indexed DAO, address indexed token);
    event subDAOCreated(address indexed parentDAO, address indexed subDAO, address indexed creator);

    /*//////////////////////////////////////////////////////////////
                                 public
    //////////////////////////////////////////////////////////////*/

    /// @notice creates a new DAO gien an ERC20
    /// @param BaseTokenAddress_ ERC20 token contract address
    function createDAO(address BaseTokenAddress_) public returns (address newDAO) {
        newDAO = address(new DAOinstance(BaseTokenAddress_, msg.sender, address(MR)));
        daoOfId[uint160(bytes20(newDAO))] = newDAO;
        daosOfToken[BaseTokenAddress_].push(newDAO);
        // if (msg.sig == this.createDAO.selector) MR.pushAsRoot(newDAO);
        if (msg.sig == this.createDAO.selector) iInstanceDAO(newDAO).mintMembershipToken(msg.sender);
        emit newDAOCreated(newDAO, BaseTokenAddress_);
        if (address(MB) == address(0)) MB = MR.MembraneRegistryAddress();
    }

    //// @security ?: can endpoint-onEndpoint create. remove multiple endpoit.
    ///  --------------- create sub-endpoints for endpoint? @todo

    /// @notice creates child entity subDAO provided a valid membrane ID is given. To create an enpoint use sender address as integer. uint160(0xyourAddress)
    /// @param membraneID_: constituent border conditions and chemestry
    /// @param parentDAO_: parent DAO
    /// @notice @security the creator of the subdao custodies assets
    function createSubDAO(uint256 membraneID_, address parentDAO_) external returns (address subDAOaddr) {
        if (MR.balanceOf(msg.sender, iInstanceDAO(parentDAO_).baseID()) == 0) revert NotCoreMember(msg.sender);
        address internalT = iInstanceDAO(parentDAO_).internalTokenAddress();
        if (daosOfToken[internalT].length > 9_999) revert SubDAOLimitReached();

        subDAOaddr = createDAO(internalT);
        bool isEndpoint = (membraneID_ < MAX_160) && (address(uint160(membraneID_)) == msg.sender);
        isEndpoint
            ? IMembrane(MB).setMembraneEndpoint(membraneID_, subDAOaddr, msg.sender)
            : IMembrane(MB).setMembrane(membraneID_, subDAOaddr);
        if (isEndpoint) MR.pushIsEndpointOf(subDAOaddr, msg.sender);

        childParentDAO[subDAOaddr] = parentDAO_;

        address[] memory parentPath = topLevelPath[parentDAO_];
        topLevelPath[subDAOaddr] = new address[](parentPath.length + 1);

        if (parentPath.length > 0) {
            uint256 i = 1;
            for (i; i <= parentPath.length;) {
                topLevelPath[subDAOaddr][i] = parentPath[i - 1];
                unchecked {
                    ++i;
                }
            }
        }

        topLevelPath[subDAOaddr][0] = parentDAO_;

        iInstanceDAO(subDAOaddr).mintMembershipToken(msg.sender);
        emit subDAOCreated(parentDAO_, subDAOaddr, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEW
    //////////////////////////////////////////////////////////////*/

    /// @notice checks if address is a registered DAOS
    /// @dev used to authenticate membership minting
    /// @param toCheck_: address to check if registered as DAO
    function isDAO(address toCheck_) public view returns (bool) {
        return (daoOfId[uint160(bytes20(toCheck_))] == toCheck_);
    }

    /// @notice get address of member registru address
    function getMemberRegistryAddr() external view returns (address) {
        return address(MR);
    }

    /// @notice given a valid subDAO address, returns the address of the parent. If root DAO, returns address(0x0)
    /// @param child_ sub-DAO address. If root or non-existent, returns adddress(0x0)
    function getParentDAO(address child_) public view returns (address) {
        return childParentDAO[child_];
    }

    /// @notice returns the top-down path, or all the parents in a hierarchical, distance-based order, from closest parent to root.
    function getTrickleDownPath(address floor_) external view returns (address[] memory path) {
        path = topLevelPath[floor_].length > 0 ? topLevelPath[floor_] : new address[](1);
    }

    /// @notice an ERC20 token can have an unlimited number of DAOs. This returns all root DAOs in existence for provided ERC20.
    /// @param parentToken ERC20 contract address
    function getDAOsOfToken(address parentToken) external view returns (address[] memory) {
        return daosOfToken[parentToken];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value: amount}("");
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage)
        internal
        returns (bytes memory)
    {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage)
        internal
        view
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage)
        internal
        pure
        returns (bytes memory)
    {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}