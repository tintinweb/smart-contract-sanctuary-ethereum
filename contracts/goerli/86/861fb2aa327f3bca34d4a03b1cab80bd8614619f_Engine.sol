// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any (single) token transfer. This includes minting and burning.
     * See {_beforeConsecutiveTokenTransfer}.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any (single) transfer of tokens. This includes minting and burning.
     * See {_afterConsecutiveTokenTransfer}.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called before consecutive token transfers.
     * Calling conditions are similar to {_beforeTokenTransfer}.
     *
     * The default implementation include balances updates that extensions such as {ERC721Consecutive} cannot perform
     * directly.
     */
    function _beforeConsecutiveTokenTransfer(
        address from,
        address to,
        uint256, /*first*/
        uint96 size
    ) internal virtual {
        if (from != address(0)) {
            _balances[from] -= size;
        }
        if (to != address(0)) {
            _balances[to] += size;
        }
    }

    /**
     * @dev Hook that is called after consecutive token transfers.
     * Calling conditions are similar to {_afterTokenTransfer}.
     */
    function _afterConsecutiveTokenTransfer(
        address, /*from*/
        address, /*to*/
        uint256, /*first*/
        uint96 /*size*/
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

pragma solidity ^0.8.15;

library LeverageMath {
    struct Data {
        // NOTE: Like in PerpV2, we have 2 max leverages: one for when the position is opened and the other for the position ongoing
        uint256 maxLeverageOpen;
        uint256 maxLeverageOngoing;
        uint256 minGuaranteedLeverage;
        uint256 s;
        uint256 b;
        uint256 f0;
        // NOTE: Example 180 days
        uint256 maxTimeGuarantee;
        // NOTE: In case the above is measured in days then it is 365 days
        uint256 FRTemporalBasis;
        // NOTE: Fair Market FR
        // NOTE: Atm we do not support negative FR
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256 res) {
        res = (a <= b) ? a : b;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256 res) {
        res = (a >= b) ? a : b;
    }

    function getMaxLeverage(
        Data storage leverage,
        uint256 fr,
        uint256 timeElapsed,
        uint256 fmfr
    ) public view returns (uint256 maxLeverage_1e6) {
        // console.log("[_getMaxLeverage()] fr >= fmfr --> ", fr >= fmfr);
        // console.log("[_getMaxLeverage()] timeElapsed >= leverage.maxTimeGuarantee --> ", timeElapsed >= leverage.maxTimeGuarantee);
        maxLeverage_1e6 = ((fr >= fmfr) ||
            (timeElapsed >= leverage.maxTimeGuarantee))
            ? (timeElapsed == 0)
                ? leverage.maxLeverageOpen
                : leverage.maxLeverageOngoing
            : _min(
                _max(
                    ((1e6 *
                        leverage.s *
                        leverage.FRTemporalBasis *
                        leverage.b) /
                        ((leverage.maxTimeGuarantee - timeElapsed) *
                            (fmfr - fr + leverage.f0))),
                    leverage.minGuaranteedLeverage
                ),
                leverage.maxLeverageOpen
            );
        // maxLeverage = (fr >= fmfr) ? type(uint256).max : (minRequiredMargin * timeToExpiry / (totTime * (fmfr - fr)));
    }

    function getLeverage(
        uint256 amount,
        uint256 collateral,
        int256 unrealizedPnL,
        uint256 currentPrice
    ) external pure returns (uint256 leverage_1e6) {
        int256 _deltaCollateral = int256(collateral) + unrealizedPnL;
        if (_deltaCollateral <= 0) {
            // NOTE: Leverage of zero is impossible so it is used as spcial value meaning all the collateral is virtually gone atm
            // NOTE: It is virtually gone since this is unrealizedPnL
            return 0;
        }
        leverage_1e6 = (amount * currentPrice * 1e6) / (collateral * 1e18);
    }
}

pragma solidity ^0.8.0;

import "@base64/base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library NFTDescriptor {
    function constructTokenURI(uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        string memory name = string.concat(
            "test name: ",
            Strings.toString(tokenId)
        );
        string memory descriptionPartOne = "test description part 1";
        string memory descriptionPartTwo = "test description part 2";
        string memory image = Base64.encode(bytes(generateSVGImage()));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                descriptionPartOne,
                                descriptionPartTwo,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateSVGImage() internal pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    '<?xml version="1.0" encoding="UTF-8"?>',
                    '<svg version="1.1" viewBox="50 20 600 600" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    "<g>",
                    '<path d="m589.12 253.12h-82.883c-7.8398 0-15.121 3.3594-20.16 8.9609l-13.441 15.68-24.641-56c-6.1602-13.441-21.84-19.602-35.281-14-13.441 6.1602-19.602 21.84-14 35.281l41.441 94.641c3.9219 8.3984 11.199 14.559 20.719 15.68 1.1211 0 2.8008 0.55859 3.9219 0.55859 7.8398 0 15.121-3.3594 20.16-8.9609l33.039-38.078h70.559c14.559 0 26.879-11.762 26.879-26.879 0.56641-14.562-11.195-26.883-26.312-26.883z"/>',
                    '<path d="m353.92 221.76c-6.1602-13.441-21.84-19.602-35.281-14-13.441 6.1602-19.602 21.84-14 35.281l41.441 94.641c4.4805 10.078 14.559 16.238 24.641 16.238 3.3594 0 7.2812-0.55859 10.641-2.2383 13.441-6.1602 19.602-21.84 14-35.281z"/>',
                    '<path d="m259.28 221.76c-3.9219-8.3984-11.199-14.559-20.719-15.68-8.9609-1.6797-18.48 1.6797-24.078 8.9609l-33.039 38.078h-70.566c-14.559 0-26.879 11.762-26.879 26.879 0 14.559 11.762 26.879 26.879 26.879h82.879c7.8398 0 15.121-3.3594 20.16-8.9609l13.441-15.68 24.641 56c4.4805 10.078 14.559 16.238 24.641 16.238 3.3594 0 7.2812-0.55859 10.641-2.2383 13.441-6.1602 19.602-21.84 14-35.281z"/>',
                    "</g>",
                    "</svg>"
                )
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

struct PickOrder {
    address owner; // trader address
    uint256 tokenId;
    uint256 matchid; // trader selected matchid
    uint256 amount;
    uint256 collateral;
    uint256 collateralAdd;
    bool canceled;
    int8 pos;
    // NOTE: Used to apply the check for the Oracle Latency Protection
    uint256 timestamp;
    // NOTE: In this case, we give trader the max full control on the price for matching: no assumption it is symmetric and we do not compute any percentage so introducing some approximations, the trader writes the desired prices
    uint256 slippageMinPrice;
    uint256 slippageMaxPrice;
    uint256 maxTimestamp;
}

library QueuePickOrders {
    struct Data {
        mapping(uint256 => PickOrder) data;
        uint256 currentIdToRead;
        uint256 currentIdToWrite;
    }

    function isEmpty(Data storage x) internal view returns (bool res) {
        res = (x.currentIdToRead == x.currentIdToWrite);
    }

    function length(Data storage x) internal view returns (uint256 res) {
        res = x.currentIdToWrite - x.currentIdToRead;
    }

    function isValidId(Data storage x, uint256 id)
        internal
        view
        returns (bool res)
    {
        res = (id >= x.currentIdToRead) && (id < x.currentIdToWrite);
    }

    function get(Data storage x, uint256 id)
        internal
        view
        returns (bool success, PickOrder storage res)
    {
        res = x.data[id];
        success = isValidId(x, id);
    }

    function push(Data storage x, PickOrder memory o)
        internal
        returns (uint256 id)
    {
        x.data[x.currentIdToWrite] = o;
        id = x.currentIdToWrite;
        x.currentIdToWrite++;
    }

    function pop(Data storage x)
        internal
        returns (bool success, PickOrder memory res)
    {
        if (isEmpty(x)) {
            // NOTE: No require to avoid crashing the TX processing loop
            // TODO: Emit custom event for when it is attached to the FE
            // console.log("[QueuePickOrders.pop()] Empty Queue --> Skipping");
        } else {
            // NOTE: This should make a copy from storage to memory so that storage can be deleted and a gas refund can be obtained
            res = x.data[x.currentIdToRead];

            // NOTE: Gas refund for freeing up memory here
            delete x.data[x.currentIdToRead];

            x.currentIdToRead++;

            success = true;
        }
    }

    function cancel(Data storage x, uint256 id)
        internal
        returns (bool success)
    {
        if (isEmpty(x)) {
            // NOTE: No require to avoid crashing the TX processing loop
            // TODO: Emit custom event for when it is attached to the FE
        } else {
            if (!isValidId(x, id)) {
                // NOTE: I am aware this check includes the empty queue condition, it is just to have more clarity on the error messages
                // NOTE: No require to avoid crashing the TX processing loop
                // TODO: Emit custom event for when it is attached to the FE
            } else {
                x.data[id].canceled = true;
                success = true;
            }
        }
    }
}

pragma solidity ^0.8.13;

interface IMockOracle {
    function getDecimals() external view returns(uint8);
    function setDecimals(uint8) external;
}

pragma solidity ^0.8.13;

struct PriceData {
    // wad
    uint256 price;
    uint256 timestamp;
}

interface IOracle {
    event NewValue(uint256 value, uint256 timestamp);

    function setPrice(uint256 _value) external;

    function decimals() external view returns (uint8);

    function getPrice() external view returns (PriceData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
// import "@dex/lib/math.sol";
import "@dex/lib/NFTDescriptor.sol";
import "@dex/lib/LeverageMath.sol";
import "@dex/lib/PickOrderMath.sol";
import "@dex/oracles/interfaces/IOracle.sol";
import "@dex/oracles/interfaces/IMockOracle.sol";
import "@dex/perp/interfaces/IEngine.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Engine is ERC721, IEngine {
    using QueuePickOrders for QueuePickOrders.Data;
    using LeverageMath for LeverageMath.Data;

    int8 public constant POS_SHORT = -1;
    int8 public constant POS_NEUTRAL = 0;
    int8 public constant POS_LONG = 1;

    using NFTDescriptor for uint256;

    // NOTE: Accounts of addresses
    mapping(address => uint256) public collateral;

    // --- State ---
    IOracle public oracle; // Oracle interface

    QueuePickOrders.Data public opens;

    uint256[] public closes; // Trader close orders queue
    /// @dev The ID of the next token that will be minted. Skips 0
    uint128 private _nextTokenId = 1;
    /// @dev The ID of the next token that will be minted. Skips 0
    uint128 private _nextMatchId = 1;

    uint256 public orderMinAmount;

    uint256 public fmfrPerHour;

    LeverageMath.Data public leverage;

    IERC20Metadata public collateralToken;

    bool initialized;
    struct Decimals {
        uint8 amount;
        uint8 premium;
        uint8 fr;
    }

    struct Match {
        uint256 maker; // maker vault token-id
        uint256 trader; // trader vault token-id
        uint256 amount;
        int256 premium; // In percent of the amount
        uint256 frPerHour;
        int8 pos; // If maker is short = true
        uint256 start; // timestamp of the match starting
        uint256 end; // timestamp of the match ending
        uint256 entryPrice;
        uint256 exitPrice;
        uint256 collateralM; // Maker  collateral
        uint256 collateralT; // Trader collateral
        uint256 fmfrPerHour; // The fair market funding rate when the match was done

        // NOTE: The so called "auto rematch" feature so if true when the trader exits their pos then a new order is automatically re-opened on the book
        // bool auto_resubmit;
    }

    mapping(uint256 => Match) public matches;

    uint256 public lpPoolMakeUpMaker;
    uint256 public lpPoolMakeUpTrader;

    Decimals public decimals;

    // NOTE: Soft Modifiers do not cause the TX to revert
    // modifier softValidMatch(matchId) {
    //     require(matches[matchId].amount > 0, "engine/invalid-match-id");
    //     _;
    // }

    // modifier onlyMaker(uint256 matchId) {
    //     require(
    //         _ownerOf(matches[matchId].maker) == msg.sender,
    //         "[softOnlyMaker] engine/no-maker"
    //     );
    //     _;
    // }

    modifier onlyTrader(uint256 matchId) {
        require(
            _ownerOf(matches[matchId].trader) == msg.sender,
            "[softOnlyTrader] engine/no-trader"
        );
        _;
    }

    modifier onlyTraderOrMaker(uint256 matchId) {
        require(
            (msg.sender == _ownerOf(matches[matchId].trader)) ||
                (msg.sender == _ownerOf(matches[matchId].maker)),
            "engine/only-trader-or-maker"
        );
        _;
    }

    // --- Init ---
    constructor() ERC721("test", "TST") {}

    function initialize(
        address oracle_,
        IERC20Metadata collateralToken_,
        LeverageMath.Data memory leverage_,
        uint256 orderMinAmount_
    ) external override {
        require(!initialized, "initialized");
        initialized = true;
        oracle = IOracle(oracle_);
        collateralToken = collateralToken_;
        leverage = leverage_;
        orderMinAmount = orderMinAmount_;

        decimals.amount = 18;
        decimals.fr = 18;
        decimals.premium = 18;
    }

    function setOracle(IOracle oracle_) public {
        oracle = oracle_;
    }

    function setLeverage(LeverageMath.Data memory _leverage) external {
        leverage = _leverage;
    }

    // TODO: Add onlyOwner
    function setFMFR(uint256 _fmfr) external {
        fmfrPerHour = _fmfr;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId));
        // return tokenId.constructTokenURI();
        return "";
    }

    function deposit(uint256 amount, address recipient) public {
        recipient = (recipient == address(0)) ? msg.sender : recipient;
        require(amount > 0, "account/zero-deposit");
        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
        collateral[recipient] += amount;
    }

    // withdraw free collateral
    function withdraw(uint256 amount, address recipient) public {
        recipient = (recipient == address(0)) ? msg.sender : recipient;
        require(amount > 0, "account/zero-withdrawl");
        require(collateral[msg.sender] >= amount, "account/not-enough-balance");

        collateral[msg.sender] -= amount;
        IERC20(collateralToken).transferFrom(address(this), recipient, amount);
    }

    function getOrder(uint256 orderId)
        public
        view
        returns (PickOrder memory order)
    {
        (, order) = opens.get(orderId);
    }

    function getMatch(uint256 matchId) public view returns (Match memory) {
        return matches[matchId];
    }

    // --- Maker ---
    function open(
        uint256 amount,
        int256 premium,
        // NOTE: We do not allow negative FRs in v1
        uint256 frPerHour,
        int8 pos,
        uint256 collateral_,
        address recipient
    ) external returns (uint256 matchId, uint256 tokenId) {
        uint256 timeElapsed = block.timestamp - oracle.getPrice().timestamp;
        // NOTE: Here there is no check on the order min amount since it can be created as a result of a split
        require(amount > orderMinAmount, "engine/order-min-amount");
        require(frPerHour % (10**(decimals.fr - 3)) == 0, "engine/fr_modulo"); // modulo of 0.1% / hour
        require(
            collateral[recipient] >= collateral_,
            "engine/missing-collateral"
        );
        require(collateral_ > 0, "engine/collateral-zero");

        require(
            LeverageMath.getLeverage(
                amount,
                collateral_,
                0,
                oracle.getPrice().price
            ) <= leverage.getMaxLeverage(frPerHour, timeElapsed, fmfrPerHour),
            // leverage.maxLeverageOpen,
            "engine/max-leverage-open"
        );

        _safeMint(recipient, (tokenId = _nextTokenId++));

        Match memory m;
        m.maker = tokenId; // the token owner is the maker of the match
        m.amount = amount;
        m.premium = premium;
        m.frPerHour = frPerHour;
        m.pos = pos;
        m.collateralM = collateral_;
        matches[(matchId = _nextMatchId++)] = m; // use token-id as idx instead of makerToData
        // m.auto_resubmit = auto_resubmit;
        emit NewMakerOrder(recipient, matchId, tokenId);
    }

    // --- Trader ---

    // pick maker match
    function pick(
        // uint256 tokenId,
        uint256 matchId,
        uint256 amount,
        uint256 collateral_,
        int8 pos
    ) external returns (uint256 orderId) {
        // the match should not be closed already
        Match memory m = matches[matchId];
        require(m.end == 0, "engine/expired_match");
        require(m.maker != 0, "engine/unexisting_match");
        PickOrder memory o;
        o.owner = msg.sender;
        o.matchid = matchId;
        o.amount = amount;
        o.collateral = collateral_;
        o.pos = pos;
        o.timestamp = block.timestamp;
        orderId = opens.push(o);
        emit NewTraderOrder(msg.sender, matchId, orderId);
    }

    // cancel trader order
    // @param id Order ID
    // function cancel(uint256 orderId) external {
    function cancelOrder(uint256 queueId) external {
        (bool success, PickOrder storage o) = opens.get(queueId);
        // PickOrder storage o = orders[orderId];
        require(success, "engine/invalid-order-id");
        require(o.owner == msg.sender, "engine/non-trader");
        emit OrderCanceled(msg.sender, queueId);
        o.canceled = true;
    }

    function cancelMatch(uint256 matchId) external {
        Match memory m = matches[matchId];
        require(m.start == 0, "engine/cancel-active-match");
        require(_ownerOf(m.maker) == msg.sender, "engine/only-maker");
        emit MatchCanceled(msg.sender, matchId);
        delete matches[matchId];
    }

    // submit close trader order
    function close(uint256 matchId) external {
        // uint256 matchId = token2matchTrader[tokenId];
        Match memory m = matches[matchId]; // load Match by trader matchid
        address trader = _ownerOf(m.trader); // load trader add. by trader tokenid
        require(trader != address(0), "engine/trader-nonexistent");
        require(trader == msg.sender, "engine/only-trader-operation");
        closes.push(matchId);
    }

    function redeem(uint256 matchId, uint256 tokenId) external {
        Match memory m = matches[matchId];
        require(
            tokenId == m.maker || tokenId == m.trader,
            "engine/redeem_NFT_mismatch"
        );
        require(m.end != 0, "engine/match_active");
        require(_ownerOf(tokenId) != address(0), "engine/redeem_twice");

        _burn(tokenId);

        settlePnL(matchId);
    }

    function increaseCollateral(uint256 matchId, uint256 amount) external {
        Match memory m = matches[matchId];
        require(
            collateral[msg.sender] >= amount,
            "engine/insufficient-collateral"
        );
        collateral[msg.sender] -= amount;
        // increase maker collateral
        if (msg.sender == _ownerOf(m.maker)) {
            m.collateralM += amount;
            matches[matchId] = m;
        } else if (msg.sender == _ownerOf(m.trader)) {
            m.collateralT += amount;
            matches[matchId] = m;
        } else {
            revert("engine/maker-nor-trader");
        }
    }

    function decreaseCollateral(uint256 matchId, uint256 amount) external {
        require(amount > 0, "engine/amount-zero");
        Match memory m = matches[matchId];
        // increase maker collateral
        if (msg.sender == _ownerOf(m.maker)) {
            uint256 timeElapsedInDays = (block.timestamp - m.start) / 86400;
            require(m.collateralM >= amount, "engine/collateral-too-low");
            require(
                LeverageMath.getLeverage(
                    m.amount,
                    m.collateralM - amount,
                    0,
                    oracle.getPrice().price
                ) <=
                    leverage.getMaxLeverage(
                        m.frPerHour,
                        timeElapsedInDays,
                        m.fmfrPerHour
                    ),
                "engine/max-leverage-open"
            );
            m.collateralM -= amount;
            matches[matchId] = m;
        } else if (msg.sender == _ownerOf(m.trader)) {
            require(m.collateralT >= amount, "engine/collateral-too-low");
            require(
                LeverageMath.getLeverage(
                    m.amount,
                    m.collateralT - amount,
                    0,
                    oracle.getPrice().price
                ) <= leverage.maxLeverageOngoing,
                "engine/max-leverage-open"
            );
            m.collateralT -= amount;
            matches[matchId] = m;
        } else {
            revert("engine/maker-nor-trader");
        }
        collateral[msg.sender] += amount;
    }

    // --- Keeper ---

    // associate trader order to maker match
    function join(uint256 n) internal {
        // uint256 matchId = token2matchMaker[o.tokenId];
        // Match storage m = matches[matchId]; // load by the selected maker tokenid
        (, PickOrder memory order) = opens.pop();
        Match storage m = matches[order.matchid]; // load by the selected maker tokenid

        if (order.canceled) return;
        opens.length();
        // load maker address from tokenId
        address maker = _ownerOf(m.maker);
        // early bailout in case the join is impossible
        if (order.owner == maker) {
            emit MakerIsTrader(order.matchid, maker, n);
            return;
        }
        if (collateral[order.owner] < order.collateral) {
            emit LowTraderCollateral(
                order.matchid,
                order.owner,
                n,
                collateral[order.owner],
                order.collateral
            );
            return;
        }

        if (collateral[maker] < m.collateralM) {
            emit LowMakerCollateral(
                order.matchid,
                maker,
                n,
                collateral[maker],
                m.collateralM
            );
            return;
        }

        PriceData memory priceData = oracle.getPrice(); // load oracle price and timestamp

        // if (priceData.timestamp <= order.timestamp) {
        //     return;
        // }

        if (
            (order.maxTimestamp > 0) &&
            (priceData.timestamp > order.maxTimestamp)
        ) {
            emit OrderExpired(
                order.matchid,
                order.owner,
                maker,
                n,
                order.maxTimestamp
            );
            return;
        }

        uint256 tokenId = _nextTokenId++;
        _safeMint(order.owner, tokenId);
        m.trader = tokenId; // setup match with the trader token
        m.collateralT = uint128(order.collateral); // setup match with trader collateral
        m.start = uint128(priceData.timestamp); // set oracle time we matched
        m.entryPrice = priceData.price; // set oracle price on match
        m.fmfrPerHour = fmfrPerHour;

        // NOTE: Makers can choose to be long or short or neutral so that it is the trader deciding
        m.pos = (m.pos == POS_NEUTRAL) ? (-1 * order.pos) : m.pos;
        if (order.amount < m.amount)
            _split(
                /*_ownerOf(o.tokenId),*/
                m,
                order.amount
            );
        // update the balance available to trader/maker
        collateral[order.owner] -= m.collateralT;
        collateral[maker] -= m.collateralM;

        emit ActiveMatch(
            order.matchid,
            maker,
            order.owner,
            opens.length(),
            m.maker,
            m.trader
        );
    }

    // desassociate trader from match based on trader tokenid
    function unjoin(uint256 matchId) internal {
        PriceData memory priceData = oracle.getPrice();
        Match memory m = matches[matchId]; // load Match by trader matchid
        // // early bailout in case the match is already closed
        if (m.end != 0) return;
        m.exitPrice = priceData.price;
        m.end = priceData.timestamp;
        matches[matchId] = m;
        emit CloseMatch(matchId, m.maker, m.trader);
        // recreate a match for the maker being unmatch
        // console.log("[unjoin()] m.collateralM = ", m.collateralM);

        // TODO: Add PnL Accounting
        // if(m.auto_resubmit) {
        // if(
        //     _getLeverage(m.amount, m.collateralM, oracle.getPrice().price, scaleFactorNotional) >
        //     _getMaxLeverage(m.frPerHour, timeElapsed, leverage, leverage.fmfrPerHour)
        //     )
        //     {
        //         console.log("[unjoin()] Leverage too high --> order can't be reopened");
        //     } else {
        //         _open(
        //             m.amount,
        //             m.premium,
        //             m.frPerHour,
        //             0,
        //             m.pos,
        //             m.collateralM,
        //             _ownerOf(m.maker)
        //         );
        //     }
        // }
    }

    function _split(Match storage m, uint256 amount)
        internal
        returns (uint256 matchId, uint256 tokenId)
    {
        require(amount < m.amount, "engine/unecessary-split");
        uint256 newAmount = m.amount - amount;
        if (newAmount <= orderMinAmount) {
            return (0, 0);
        }
        address maker = _ownerOf(m.maker);
        _safeMint(maker, (tokenId = _nextTokenId++)); // mint maker token
        Match memory newMatch;
        newMatch.maker = tokenId;
        newMatch.amount = newAmount;
        newMatch.premium = m.premium;
        newMatch.frPerHour = m.frPerHour;
        newMatch.pos = m.pos;
        newMatch.collateralM = uint128((m.collateralM * amount) / m.amount);
        // newMatch.collateralM = uint128(m.collateralM * (amount / m.amount));
        // create a new potential match in the order book;
        matches[(matchId = _nextMatchId++)] = newMatch;

        // effects
        m.collateralM = m.collateralM - ((m.collateralM * amount) / m.amount);
        // m.collateralM = uint128(m.collateralM * (1 - (amount / m.amount)));
        m.amount = amount;

        emit NewMakerOrder(maker, matchId, tokenId);
    }

    function pnl(
        uint256 matchId,
        uint256 tokenId,
        uint256 timestamp,
        uint256 exitPrice
    ) external view returns (int256) {
        Match storage m = matches[matchId];
        require(timestamp > m.start, "engine/wrong_timestamp");
        require(
            (tokenId == m.maker) || (tokenId == m.trader),
            "engine/invalid-tokenId"
        );
        return
            _pnl(
                timestamp - m.start,
                m.entryPrice,
                exitPrice,
                m.frPerHour,
                m.amount,
                m.premium,
                tokenId == m.maker,
                m.pos == POS_SHORT
            );
    }

    function _pnl(
        uint256 deltaT,
        uint256 entryPrice,
        uint256 exitPrice,
        uint256 frPerHour,
        uint256 amount,
        int256 premium,
        bool isMaker,
        bool isShort
    ) internal view returns (int256 res) {
        int256 deltaP = int256(exitPrice) - int256(entryPrice);

        int256 aggregatedFR = int256(deltaT * frPerHour * amount * exitPrice) /
            int256(
                3600 *
                    10 **
                        (decimals.fr +
                            decimals.amount +
                            oracle.decimals() -
                            collateralToken.decimals())
            );

        int256 gl = (((isShort) ? -deltaP : deltaP) *
            int256(amount * 10**collateralToken.decimals())) /
            int256(10**(uint256(decimals.amount + oracle.decimals())));

        res =
            gl +
            ((isMaker) ? int256(1) : int256(-1)) *
            (aggregatedFR +
                ((premium *
                    int256(
                        amount * exitPrice * 10**collateralToken.decimals()
                    )) /
                    int256(
                        10 **
                            (decimals.amount +
                                decimals.premium +
                                oracle.decimals())
                    )));
    }

    function isLiquidatable(uint256 matchId, uint256 tokenId)
        public
        view
        returns (
            bool res,
            int256 _uPnL,
            uint256 _leverage
        )
    {
        Match storage m = matches[matchId];
        require(
            (tokenId == m.maker) || (tokenId == m.trader),
            "engine/invalid-tokenId"
        );
        PriceData memory priceData = oracle.getPrice();
        _uPnL = _pnl(
            priceData.timestamp - m.start,
            m.entryPrice,
            priceData.price,
            m.frPerHour,
            m.amount,
            m.premium,
            tokenId == m.maker,
            m.pos == POS_SHORT
        );
        _leverage = LeverageMath.getLeverage(
            m.amount,
            m.collateralM,
            _uPnL,
            priceData.price
        );
        if (tokenId == m.maker) {
            // TODO: Implement using the Maker Leverage
        } else {
            // NOTE: The trader liquidability just depends on the leverage.maxLeverageOngoing Appunto
            res = _leverage >= leverage.maxLeverageOngoing;
        }
    }

    function _settlePnL(
        address addr,
        bool isMaker,
        int256 pnl_
    ) internal {
        int256 _newBalance = (int256(collateral[addr]) + pnl_);
        collateral[addr] = (_newBalance >= 0) ? uint256(_newBalance) : 0;

        // NOTE: Track losses that have to be made up by the LP Pool
        lpPoolMakeUpMaker = uint256(
            ((isMaker) ? int256(1) : int256(0)) *
                ((_newBalance < 0) ? (-_newBalance) : int256(0))
        );
        lpPoolMakeUpTrader = uint256(
            ((!isMaker) ? int256(1) : int256(0)) *
                ((_newBalance < 0) ? (-_newBalance) : int256(0))
        );
    }

    // NOTE: Settles the Unrealized PnL
    function settlePnL(uint256 matchId)
        public
        onlyTraderOrMaker(matchId)
        returns (int256 _makerPnL)
    {
        Match storage m = matches[matchId];
        PriceData memory priceData = oracle.getPrice();
        _makerPnL = _pnl(
            priceData.timestamp - m.start,
            m.entryPrice,
            priceData.price,
            m.frPerHour,
            m.amount,
            m.premium,
            true,
            m.pos == POS_SHORT
        );

        _settlePnL(_ownerOf(m.maker), true, _makerPnL);
        _settlePnL(_ownerOf(m.trader), false, -_makerPnL);
    }

    function liquidate(uint256 matchId, uint256 tokenId) external {
        (bool _isLiquidatable, int256 _uPnL, ) = isLiquidatable(
            matchId,
            tokenId
        );
        require(_isLiquidatable, "engine/not-liquidatable");
        // TODO: Implement
        Match storage m = matches[matchId];
        if (tokenId == m.maker) {
            // TODO: Implement Maker Liquidation --> it means
            // 1) Decapitating current owner
            // 2) Recapitilizing through LP Pool
            // 3) Minting ownership to pool --> Take care about auction start
        } else {
            // TODO: Implement Trader Liquidation
        }
    }

    function runOpens(uint256 n) external {
        n = (n == 0) ? opens.length() : Math.min(n, opens.length());
        for (uint256 i = 0; i < n; ++i) {
            join(i);
        }
    }

    function runCloses(uint256 n) external {
        n = (n == 0) ? closes.length : Math.min(n, closes.length);
        for (uint256 i = 0; i < n; ++i) {
            uint256 matchId = closes[i];
            unjoin(matchId);
        }
        // empty the queue
        delete closes;
    }
}

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@dex/lib/LeverageMath.sol";

interface IEngine {
    event NewMakerOrder(
        address indexed recipient,
        uint256 indexed matchId,
        uint256 tokenId
    );

    event NewTraderOrder(
        address indexed recipient,
        uint256 indexed matchId,
        uint256 orderId
    );

    event ActiveMatch(
        uint256 indexed matchId,
        address indexed maker,
        address indexed trader,
        uint256 orderId,
        uint256 makerToken,
        uint256 traderToken
    );

    event CloseMatch(
        uint256 indexed matchId,
        uint256 indexed makerToken,
        uint256 indexed traderToken
    );

    event MakerIsTrader(
        uint256 indexed matchId,
        address indexed maker,
        uint256 orderId
    );

    event LowTraderCollateral(
        uint256 indexed matchId,
        address indexed trader,
        uint256 orderId,
        uint256 traderCollateral,
        uint256 collateralNeeded
    );

    event LowMakerCollateral(
        uint256 indexed matchId,
        address indexed maker,
        uint256 orderId,
        uint256 makerCollateral,
        uint256 collateralNeeded
    );

    event OrderExpired(
        uint256 indexed matchId,
        address indexed trader,
        address indexed maker,
        uint256 orderId,
        uint256 orderTimestamp
    );

    event OrderCanceled(address indexed trader, uint256 indexed orderId);

    event MatchCanceled(address indexed maker, uint256 indexed matchId);

    function initialize(
        address oracle_,
        IERC20Metadata collateralToken_,
        LeverageMath.Data memory leverage_,
        uint256 orderMinAmount_
    ) external;
}