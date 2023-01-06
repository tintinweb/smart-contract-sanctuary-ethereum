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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
pragma solidity 0.8.17;

import "./UBIToken.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/** @title Universal Basic Information Dashboard
 *  @author Armand Daigle
 *  @notice This contract rewards registered users with the UBI Token for submitting information
 *  and voting in a city or DAO context. Proof of Humanity, Proof of Existence, and CityDAO Citizen
 *  NFT requires/checks have been removed so that this contract can be deployed and interacted with
 *  by anyone. However, to demonstrate functionality in a concrete context, the variables and
 *  comments have been written with CityDAO in mind. 'Citizens' in general to mean DAO members.
 *  However, the bigger goal would be to implement this in actual cities of course. To see a version
 *  with all bells and whistles, check the UBIDashboard.sol file in the "../portfolio" folder.
 *  @dev If it is desired to only allow the contract owner to open and close UBI rounds, uncomment
 *  the Ownable.sol import line, uncomment the 'onlyOwner' modifiers on those functions, and add
 *  'is Ownable' after the contract name.
 */
contract UBIDashboard {
    struct CitizenData {
        UBIProgress progress;
        uint16 ubiCounter;
        uint16 firstUBIRoundVoted;
        uint8 ubiPercentage;
        bool inGoodStanding;
        bool votedPreviousRound;
    }

    /// Enum keeps track of what stage each Citizen is at
    enum UBIProgress {
        HasNotSubmittedUBI,
        HasSubmittedUBI,
        HasBeenPaid
    }

    /// Immutable Interface Variables
    UBIToken public immutable i_ubiToken;

    /// Mappings and Variables for Citizen Data
    mapping(address => bool) public registeredCitizens;
    mapping(address => CitizenData) public walletToCitizenUBIData;

    /// State Variables - UBI Rounds
    address[] public votedThisRound;
    uint256 public currentUBIAmount;
    uint256 public totalUBIThisRound;
    uint256 public totalUBIEver;
    uint256 public ubiRoundOpenTime;
    uint256 public ubiRoundCloseTime;
    uint32 public avgDCWThisRound;
    uint16 public ubiRoundNumber;
    bool public ubiRoundIsOpen;

    /// Events
    event CitizenHasRegistered(address);
    event UBIRoundHasOpened(uint256, uint256);
    event CitizenHasVoted(); // No address emitted to maintain some privacy.
    event UBIRoundHasClosed(uint256, uint32);
    event CitizenHasBeenPaid(address, uint256);

    /// Errors
    error AlreadyRegistered();
    error MustHoldCitizenNFT(string, address);
    error MustBeRegisteredCitizen();
    error UBIRoundIsAlreadyOpen();
    error TooEarlyToCloseRound();
    error UBIRoundHasAlreadyBeenClosed();
    error ScoreMustBeBetween0and100();
    error WithdrawFirstORAlreadySubmitted();
    error MustSubmitUBIBeforePayment();
    error AlreadyClaimedUBIPayment();
    error MustBeInGoodStandingToReceiveUBI();

    constructor(address _ubiToken) {
        i_ubiToken = UBIToken(_ubiToken);
    }

    receive() external payable {}

    fallback() external payable {}

    /** @dev This function handles Citizen/Member Registration and can be implemented in several
     *  ways.
     */
    function register() external {
        // Does not let user register twice
        if (registeredCitizens[msg.sender]) {
            revert AlreadyRegistered();
        }

        // See portfolio version of this contract for Citizen NFT and proof of personhood checks.

        // This mapping makes the whole system go.
        walletToCitizenUBIData[msg.sender] = CitizenData(
            UBIProgress.HasNotSubmittedUBI,
            0,
            0,
            0,
            false,
            false
        );

        registeredCitizens[msg.sender] = true;
        emit CitizenHasRegistered(msg.sender);
    }

    /** @notice Timestamps are converted to regular datetime on the front end.
     *  @dev Chainlink Automation can be used to open and close UBI rounds. Refer to the README
     *  for more info. Either way, anyone can call this function.
     */
    function openRound() external /*onlyOwner*/ {
        if (ubiRoundIsOpen == true) {
            revert UBIRoundIsAlreadyOpen();
        }

        // We reset round variables to fresh states. (As Dave Grohl says, "Fresh POOOTS!")
        delete votedThisRound;
        ubiRoundIsOpen = true;
        ubiRoundNumber++;
        ubiRoundOpenTime = block.timestamp;
        avgDCWThisRound = 0;
        totalUBIThisRound = 0;
        // Twelve hours between rounds to allow for updating, maintenance, etc.
        ubiRoundCloseTime = ubiRoundOpenTime + 13 days + 12 hours;
        emit UBIRoundHasOpened(ubiRoundOpenTime, ubiRoundCloseTime);
    }

    /** @notice In it's full form, submitUBI is intended to have many requirements, including
     *  knowledge quizzes, community feedback surveys, proposal education and discussion, and
     *  voting completion. For portfolio purposes, Citizens will only answer one question on the
     *  front end and submit their Democratic (or DAO) Collective Welfare (DCW) Score with this
     *  function. However, the nuts and bolts are all there to make this a full-fledged UBI system
     *  and dashboard. To read more on DCW, read the essay by Ralph Merkle that is linked to in the
     *  README.
     *  @dev All Proof of Personhood and Citizen Token checks can be duplicated here if desired,
     *  to ensure that all Citizens / DAO members keep current with their identifications and as an
     *  anti-shenanigans measure.
     *  @param dcwScore Each Citizen / DAO member has a routine chance to update their score.
     */
    function submitUBI(uint32 dcwScore) external {
        if (ubiRoundIsOpen == false) {
            revert UBIRoundHasAlreadyBeenClosed();
        }
        if (dcwScore > 100 || dcwScore < 0) {
            revert ScoreMustBeBetween0and100();
        }

        if (!registeredCitizens[msg.sender]) {
            revert MustBeRegisteredCitizen();
        }
        if (
            walletToCitizenUBIData[msg.sender].votedPreviousRound == true ||
            walletToCitizenUBIData[msg.sender].progress == UBIProgress.HasSubmittedUBI
        ) {
            revert WithdrawFirstORAlreadySubmitted();
        } else {
            // Updating Citizen and control variables.
            if (walletToCitizenUBIData[msg.sender].firstUBIRoundVoted == 0) {
                walletToCitizenUBIData[msg.sender].firstUBIRoundVoted = ubiRoundNumber;
            }
            walletToCitizenUBIData[msg.sender].ubiCounter++;
            walletToCitizenUBIData[msg.sender].progress = UBIProgress.HasSubmittedUBI;
            // This boolean needs to be set here at this user touchpoint but will be used during
            // the next round when user withdraws. This eliminates the need for a for loop to reset
            // statuses.
            walletToCitizenUBIData[msg.sender].votedPreviousRound = true;
            // Add 1 to the denominator since the first round a person votes should be counted. We
            // also need to avoid fractions below 1, so we multiply by 100 before dividing.
            walletToCitizenUBIData[msg.sender].ubiPercentage = uint8(
                ((walletToCitizenUBIData[msg.sender].ubiCounter * 100) /
                    ((ubiRoundNumber - walletToCitizenUBIData[msg.sender].firstUBIRoundVoted) + 1))
            );
            votedThisRound.push(msg.sender);
            // This math must be done at UBI submittal, since UBI withdrawals can/will happen
            // during future UBI rounds.
            currentUBIAmount = uint256(i_ubiToken.ubiPayment());
            totalUBIThisRound = votedThisRound.length * currentUBIAmount;
            totalUBIEver += currentUBIAmount;

            // For portfolio purposes, a Citizen is considered to be in UBI "good standing" if
            // they have completed 70% or more of the UBI rounds since the Citizen first voted.
            if (walletToCitizenUBIData[msg.sender].ubiPercentage >= 70) {
                walletToCitizenUBIData[msg.sender].inGoodStanding = true;
            } else {
                walletToCitizenUBIData[msg.sender].inGoodStanding = false;
            }

            avgDCWThisRound = (dcwScore + avgDCWThisRound) / uint32(votedThisRound.length);

            emit CitizenHasVoted();
        }
    }

    /// @dev Straight forward function that is called by the Chainlink Automation Network
    /// in a production build. Either way, anyone can call this function.
    function closeRound() external /*onlyOwner*/ {
        if (ubiRoundIsOpen == false) {
            revert UBIRoundHasAlreadyBeenClosed();
        }
        // This if statement is commented out so anyone can open and close rounds on command for
        // portfolio purposes. The unit and staging tests were done with this section uncommented.
        if (block.timestamp < ubiRoundCloseTime) {
            revert TooEarlyToCloseRound();
        }
        ubiRoundIsOpen = false;
        uint256 timeRoundClosed = block.timestamp;

        emit UBIRoundHasClosed(timeRoundClosed, avgDCWThisRound);
    }

    /** @notice User can withdraw/claim at any time, inside or outside any UBI round. If a user does
     *  not withdraw their UBI for the completed round, it gets accounted for in the submitUBI logic
     *  for the totalUBIThisRound and totalUBIEver variables, but it's possible that the tokens never
     *  get minted on the blockchain. The user can withdraw the amount even years later, however,
     *  they will not be able to submit UBI until they withdraw. This was done for simplicity's sake
     *  and to eliminate pricey loops to change UBI stage gating at open or close of each round.
     *  @dev All Proof of Personhood and Citizen Token checks do NOT need to be duplicated here.
     *  With the checks at the UBI submittal call, a delinquent person can only claim one
     *  non-compliant UBI distribution. Avoiding data corruption takes precedence over UBI supply.
     */
    function withdrawUBI() external {
        if (!registeredCitizens[msg.sender]) {
            revert MustBeRegisteredCitizen();
        }
        if (walletToCitizenUBIData[msg.sender].progress == UBIProgress.HasBeenPaid) {
            revert AlreadyClaimedUBIPayment();
        }
        if (
            walletToCitizenUBIData[msg.sender].progress == UBIProgress.HasNotSubmittedUBI ||
            walletToCitizenUBIData[msg.sender].votedPreviousRound == false
        ) {
            revert MustSubmitUBIBeforePayment();
        }
        if (walletToCitizenUBIData[msg.sender].votedPreviousRound == true) {
            walletToCitizenUBIData[msg.sender].progress = UBIProgress.HasBeenPaid;
            walletToCitizenUBIData[msg.sender].votedPreviousRound = false;
            uint256 ubiAmount;
            ubiAmount = uint256(i_ubiToken.ubiPayment());
            // Finally, the actual minting. The only way to mint UBI is to complete
            // UBI Dashboard rounds.
            i_ubiToken.payUBI(msg.sender);
            emit CitizenHasBeenPaid(msg.sender, ubiAmount);
        }
    }

    /// Getters
    /// @notice In between rounds, "...ThisRound" means the one that just ended.
    /// @return Once openRound() is called, this array is emptied and begins anew.
    function getWhoHasVotedThisRound() external view returns (address[] memory) {
        return votedThisRound;
    }

    /** @dev This getter includes math because if a Citizen does not vote for, say, 45 rounds,
     *  then the logic will not be triggered to update the ubiPercentage in the CitizenData struct
     *  for those 45 rounds.
     */
    function getCitizenUBIPercentage(address citizen) external view returns (uint8) {
        uint8 percentage = uint8(
            ((walletToCitizenUBIData[citizen].ubiCounter * 100) /
                ((ubiRoundNumber - walletToCitizenUBIData[citizen].firstUBIRoundVoted) + 1))
        );
        return percentage;
    }

    function getUBIStats()
        external
        view
        returns (uint16, uint256, uint256, uint256, uint256, uint256)
    {
        return (
            ubiRoundNumber,
            ubiRoundOpenTime,
            ubiRoundCloseTime,
            totalUBIThisRound,
            totalUBIEver,
            ubiRoundCloseTime + 12 hours
        );
    }

    function getTotalAVGDCWThisRound() external view returns (uint32) {
        return avgDCWThisRound;
    }

    function getUBITokenAddress() external view returns (address) {
        return address(i_ubiToken);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Universal Basic Information Token
/// @author Armand Daigle
/// @notice This contract and token connect to the UBI Dashboard contract
/// to reward users for submitting information and voting in a DAO or city context.
contract UBIToken is ERC20, Ownable {
    uint256 public startingTimeStamp;
    uint32 public ubiPayment = 1000;

    /// @notice Initial supply can be anything, but 0 is the best for everyone!
    constructor(uint256 initialSupply) ERC20("CityDAO UBI Token", "CUBI") {
        _mint(msg.sender, initialSupply);
        startingTimeStamp = block.timestamp;
    }

    /**
     *  @dev After deploying this contract and UBIDashboard.sol, the owner must
     *  transferOwnership of this contract to the UBIDashboard.sol address, so
     *  it can mint tokens and pay users.
     */
    function payUBI(address to) external onlyOwner {
        _mint(to, ubiIssuanceHalving());
    }

    /// @notice Unlimited supply with halving every ~two years.
    /// @return Current amount, which UBI Dashboard calls out at each payment.
    function ubiIssuanceHalving() public returns (uint32) {
        if ((block.timestamp - startingTimeStamp) >= 730 days) {
            ubiPayment /= 2;
            startingTimeStamp = block.timestamp;
        }
        return (ubiPayment);
    }
}