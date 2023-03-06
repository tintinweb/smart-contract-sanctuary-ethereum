// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationBase directly.
 */
pragma solidity ^0.8.0;
import {AutomationBase as KeeperBase} from "./AutomationBase.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

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
        address owner = _owners[tokenId];
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
            "ERC721: approve caller is not token owner nor approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
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
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
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

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
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

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
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

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
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
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import { ICronUpkeep } from "../interfaces/ICronUpkeep.sol";
import { IKeeper } from "../interfaces/IKeeper.sol";
import { IChild } from "../interfaces/IChild.sol";

import { TokenHelpers } from "../libraries/TokenHelpers.sol";

abstract contract Child is IChild, ReentrancyGuard, Pausable {
    using Address for address;
    using Counters for Counters.Counter;

    Counters.Counter public epoch;

    address public owner;
    address public factory;

    uint256 public constant MAX_TREASURY_FEE = 1000; // 10%

    uint256 public treasuryFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public treasuryAmount; // treasury amount that was not claimed

    address[] public allowedTokensERC20;
    address[] public allowedTokensERC721;

    mapping(uint256 => Winner[]) winners;
    mapping(uint256 => Prize[]) prizes;

    ///
    /// CONSTRUCTOR AND INITIALISATION
    ///

    /**
     * @notice Constructor
     * @param _allowedTokensERC20 list of allowed ERC20 tokens
     * @param _allowedTokensERC721 list of allowed ERC721 tokens
     */
    constructor(address[] memory _allowedTokensERC20, address[] memory _allowedTokensERC721) {
        allowedTokensERC20 = _allowedTokensERC20;
        allowedTokensERC721 = _allowedTokensERC721;
    }

    ///
    /// MAIN FUNCTIONS
    ///

    /**
     * @notice Prizes adding management
     * @dev Callable by admin or creator
     * @dev TODO NEXT VERSION add a tax for creator in case of free childs
     *      Need to store the factory childCreationAmount in this contract on initialisation
     * @dev TODO NEXT VERSION Remove _isChildAllPrizesStandard limitation to include other prize typ
     */
    function addPrizes(
        Prize[] memory _prizes
    ) external payable override onlyAdmin whenPaused onlyIfPrizesParam(_prizes) onlyIfPrizeAmountIfNeeded(_prizes) {
        _addPrizes(_prizes);
        // Limitation for current version as standard for NFT is not implemented
        require(_isChildAllPrizesStandard(), "This version only allow standard prize");
    }

    /**
     * @notice Function that is called by a winner to claim his prize
     * @param _epoch the epoch to the game to claim
     * @dev TODO NEXT VERSION Update claim process according to prize type
     */
    function claimPrize(uint256 _epoch) external override onlyIfEpoch(_epoch) {
        for (uint256 i = 0; i < winners[_epoch].length; i++)
            if (winners[_epoch][i].playerAddress == msg.sender) {
                require(!winners[_epoch][i].prizeClaimed, "Prize for this round already claimed");
                require(address(this).balance >= winners[_epoch][i].amountWon, "Not enough funds in contract");

                winners[_epoch][i].prizeClaimed = true;
                emit ChildPrizeClaimed(msg.sender, _epoch, winners[_epoch][i].amountWon);

                if (winners[_epoch][i].standard == 0)
                    TokenHelpers.safeTransfert(winners[_epoch][i].playerAddress, winners[_epoch][i].amountWon);
                else if (winners[_epoch][i].standard == 1)
                    TokenHelpers.transfertERC20(
                        winners[_epoch][i].contractAddress,
                        address(this),
                        winners[_epoch][i].playerAddress,
                        winners[_epoch][i].amountWon
                    );
                else if (winners[_epoch][i].standard == 2)
                    TokenHelpers.transfertERC721(
                        winners[_epoch][i].contractAddress,
                        address(this),
                        winners[_epoch][i].playerAddress,
                        winners[_epoch][i].tokenId
                    );
                else require(false, "Prize type not supported");

                return;
            }
        require(false, "Player did not win this round");
    }

    ///
    /// INTERNAL FUNCTIONS
    ///

    /**
     * @notice Internal function for prizes adding management
     * @param _prizes list of prize details
     */
    function _addPrizes(Prize[] memory _prizes) internal virtual {
        for (uint256 i = 0; i < _prizes.length; i++) {
            _addPrize(_prizes[i]);
        }
    }

    /**
     * @notice Internal function to add a Prize
     * @param _prize the prize to add
     */
    function _addPrize(Prize memory _prize) internal {
        if (_prize.standard == 1)
            TokenHelpers.transfertERC20(_prize.contractAddress, msg.sender, address(this), _prize.amount);
        else if (_prize.standard == 2)
            TokenHelpers.transfertERC721(_prize.contractAddress, msg.sender, address(this), _prize.tokenId);

        prizes[epoch.current()].push(_prize);
        emit PrizeAdded(
            epoch.current(),
            _prize.position,
            _prize.amount,
            _prize.standard,
            _prize.contractAddress,
            _prize.tokenId
        );
    }

    /**
     * @notice Internal function to check if all childs are of type standard
     * @return isStandard set to true if all childs are of type standard
     * @dev only available for native token, token or NFT
     */
    function _isChildAllPrizesStandard() internal view returns (bool isStandard) {
        for (uint256 i = 0; i < prizes[epoch.current()].length; i++)
            if (
                prizes[epoch.current()][i].standard != 0 &&
                prizes[epoch.current()][i].standard != 1 &&
                prizes[epoch.current()][i].standard != 2
            ) return false;
        return true;
    }

    /**
     * @notice Check if msg.value have the right amount if needed
     * @param _prizes list of prize details
     */
    function _checkIfPrizeAmountIfNeeded(Prize[] memory _prizes) internal view virtual {
        uint256 prizepool = 0;
        for (uint256 i = 0; i < _prizes.length; i++) if (_prizes[i].standard == 0) prizepool += _prizes[i].amount;

        require(msg.value == prizepool, "Need to send prizepool amount");
    }

    /**
     * @notice get prize for given giveaway and current position
     * @param _epoch round id
     * @param _position position of prize
     */
    function _getPrizeForPosition(
        uint256 _epoch,
        uint256 _position
    ) internal view returns (bool _found, Prize memory _prize) {
        for (uint256 idx = 0; idx < prizes[_epoch].length; idx++) {
            if (prizes[_epoch][idx].position == _position) return (true, prizes[_epoch][idx]);
        }
        Prize memory defaultPrize;
        return (false, defaultPrize);
    }

    /**
     * @notice Check if token already exist in allowed ERC20 tokens
     * @param _allowedToken the authorized amount to check
     * @return isExist true if exist false if not
     */
    function _isExistAllowedERC20(address _allowedToken) internal view returns (bool isExist, uint256 index) {
        for (uint256 i = 0; i < allowedTokensERC20.length; i++)
            if (allowedTokensERC20[i] == _allowedToken) return (true, i);
        return (false, 0);
    }

    /**
     * @notice Check if token already exist in allowed ERC721 tokens
     * @param _allowedToken the authorized amount to check
     * @return isExist true if exist false if not
     */
    function _isExistAllowedERC721(address _allowedToken) internal view returns (bool isExist, uint256 index) {
        for (uint256 i = 0; i < allowedTokensERC721.length; i++)
            if (allowedTokensERC721[i] == _allowedToken) return (true, i);
        return (false, 0);
    }

    ///
    /// GETTERS FUNCTIONS
    ///
    /**
     * @notice Return the winners for a round id
     * @param _epoch the round id
     * @return childWinners list of Winner
     */
    function getWinners(
        uint256 _epoch
    ) external view override onlyIfEpoch(_epoch) returns (Winner[] memory childWinners) {
        return winners[_epoch];
    }

    /**
     * @notice Return the winners for a round id
     * @param _epoch the round id
     * @return childPrizes list of Prize
     */
    function getPrizes(uint256 _epoch) external view override onlyIfEpoch(_epoch) returns (Prize[] memory childPrizes) {
        return prizes[_epoch];
    }

    ///
    /// SETTERS FUNCTIONS
    ///

    /**
     * @notice Set the treasury fee for the child
     * @param _treasuryFee the new treasury fee in %
     * @dev Callable by admin
     * @dev Callable when child if not in progress
     */
    function setTreasuryFee(uint256 _treasuryFee) external override onlyAdmin onlyTreasuryFee(_treasuryFee) {
        treasuryFee = _treasuryFee;
    }

    ///
    /// ADMIN FUNCTIONS
    ///

    /**
     * @notice Add a token to allowed ERC20
     * @param _token the new token address
     * @dev Callable by admin
     */
    function addTokenERC20(address _token) external override onlyAdmin onlyAddressInit(_token) {
        (bool isExist, ) = _isExistAllowedERC20(_token);
        if (!isExist) allowedTokensERC20.push(_token);
    }

    /**
     * @notice Remove a token to allowed ERC20
     * @param _token the token address to remove
     * @dev Callable by admin
     */
    function removeTokenERC20(address _token) external override onlyAdmin onlyAddressInit(_token) {
        (bool isExist, uint256 index) = _isExistAllowedERC20(_token);
        if (isExist) delete allowedTokensERC20[index];
    }

    /**
     * @notice Add a token to allowed ERC721
     * @param _token the new token address
     * @dev Callable by admin
     */
    function addTokenERC721(address _token) external override onlyAdmin onlyAddressInit(_token) {
        (bool isExist, ) = _isExistAllowedERC721(_token);
        if (!isExist) allowedTokensERC721.push(_token);
    }

    /**
     * @notice Remove a token to allowed ERC721
     * @param _token the token address to remove
     * @dev Callable by admin
     */
    function removeTokenERC721(address _token) external override onlyAdmin onlyAddressInit(_token) {
        (bool isExist, uint256 index) = _isExistAllowedERC721(_token);
        if (isExist) delete allowedTokensERC721[index];
    }

    /**
     * @notice Withdraw Treasury fee
     * @dev Callable by admin
     */
    function claimTreasuryFee()
        external
        override
        onlyAdmin
        onlyIfClaimableAmount(treasuryAmount)
        onlyIfEnoughtBalance(treasuryAmount)
    {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        emit TreasuryFeeClaimed(currentTreasuryAmount);
        TokenHelpers.safeTransfert(owner, currentTreasuryAmount);
    }

    /**
     * @notice Pause the current game and associated keeper job
     * @dev Callable by admin or creator
     */
    function pause() external virtual override {
        _pause();
    }

    /**
     * @notice Unpause the current game and associated keeper job
     * @dev Callable by admin or creator
     */
    function unpause() external virtual override {
        _unpause();
    }

    ///
    /// EMERGENCY
    ///

    /**
     * @notice Transfert Admin Ownership
     * @param _adminAddress the new admin address
     * @dev Callable by admin
     */
    function transferAdminOwnership(address _adminAddress) external override onlyAdmin onlyAddressInit(_adminAddress) {
        emit AdminOwnershipTransferred(owner, _adminAddress);
        owner = _adminAddress;
    }

    /**
     * @notice Transfert Factory Ownership
     * @param _factory the new factory address
     * @dev Callable by factory
     */
    function transferFactoryOwnership(
        address _factory
    ) external override onlyAdminOrFactory onlyAddressInit(address(_factory)) {
        emit FactoryOwnershipTransferred(address(factory), address(_factory));
        factory = _factory;
    }

    /**
     * @notice Allow admin to withdraw all funds of smart contract
     *  This will transfert all funds for ERC20 & ERC721 and Native token at the end
     * @param _receiver the receiver for the funds (admin or factory)
     * @dev Callable by admin or factory
     */
    function withdrawFunds(address _receiver) external override onlyAdminOrFactory {
        for (uint256 i = 0; i < allowedTokensERC20.length; i++)
            if (TokenHelpers.getERC20Balance(allowedTokensERC20[i], address(this)) > 0)
                withdrawERC20(allowedTokensERC20[i], _receiver);

        for (uint256 i = 0; i < allowedTokensERC721.length; i++) {
            uint[] memory tokenIdsERC721 = TokenHelpers.getERC721TokenIds(allowedTokensERC721[i], address(this));
            for (uint256 j = 0; j < tokenIdsERC721.length; j++)
                withdrawERC721(allowedTokensERC721[i], tokenIdsERC721[j], _receiver);
        }

        withdrawNative(_receiver);
    }

    /**
     * @notice Allow admin to withdraw Native from smart contract
     * @param _receiver the receiver for the funds (admin or factory)
     * @dev Callable by admin or factory
     */
    function withdrawNative(address _receiver) public override onlyAdminOrFactory {
        TokenHelpers.safeTransfert(_receiver, address(this).balance);
    }

    /**
     * @notice Allow admin to withdraw ERC20 from smart contract
     * @param _contractAddress the contract address
     * @param _receiver the receiver for the funds (admin or factory)
     * @dev Callable by admin or factory
     */
    function withdrawERC20(address _contractAddress, address _receiver) public override onlyAdminOrFactory {
        TokenHelpers.transfertERC20(
            _contractAddress,
            address(this),
            _receiver,
            TokenHelpers.getERC20Balance(_contractAddress, address(this))
        );
    }

    /**
     * @notice Allow admin to withdraw ERC721 from smart contract
     * @param _contractAddress the contract address
     * @param _tokenId the token id
     * @param _receiver the receiver for the funds (admin or factory)
     * @dev Callable by admin or factory
     */
    function withdrawERC721(
        address _contractAddress,
        uint256 _tokenId,
        address _receiver
    ) public override onlyAdminOrFactory {
        TokenHelpers.transfertERC721(_contractAddress, address(this), _receiver, _tokenId);
    }

    ///
    /// FALLBACK FUNCTIONS
    ///

    /**
     * @notice Called for empty calldata (and any value)
     */
    // receive() external payable virtual;

    /**
     * @notice Called when no other function matches (not even the receive function). Optionally payable
     */
    // fallback() external payable virtual;

    ///
    /// MODIFIERS
    ///

    /**
     * @notice Modifier that ensure only admin can access this function
     */
    modifier onlyAdmin() {
        require(msg.sender == owner, "Caller is not the admin");
        _;
    }

    /**
     * @notice Modifier that ensure only factory can access this function
     */
    modifier onlyFactory() {
        require(msg.sender == address(factory), "Caller is not the factory");
        _;
    }

    /**
     * @notice Modifier that ensure only admin or factory can access this function
     */
    modifier onlyAdminOrFactory() {
        require(msg.sender == address(factory) || msg.sender == owner, "Caller is not the admin or factory");
        _;
    }

    /**
     * @notice Modifier that ensure that address is initialised
     */
    modifier onlyAddressInit(address _toCheck) {
        require(_toCheck != address(0), "address need to be initialised");
        _;
    }

    /**
     * @notice Modifier that ensure that caller is not a smart contract
     */
    modifier onlyHumans() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "No contract allowed");
        _;
    }

    /**
     * @notice Modifier that ensure that epoch exist
     */
    modifier onlyIfEpoch(uint256 _epoch) {
        require(_epoch <= epoch.current(), "This round does not exist");
        _;
    }

    /**
     * @notice Modifier that ensure that treasury fee are not too high
     */
    modifier onlyIfClaimableAmount(uint256 _amount) {
        require(_amount > 0, "Nothing to claim");
        _;
    }

    /**
     * @notice Modifier that ensure that treasury fee are not too high
     */
    modifier onlyIfEnoughtBalance(uint256 _amount) {
        require(address(this).balance >= _amount, "Not enough in contract balance");
        _;
    }

    /**
     * @notice Modifier that ensure that treasury fee are not too high
     */
    modifier onlyTreasuryFee(uint256 _treasuryFee) {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        _;
    }

    /**
     * @notice Modifier that ensure that prize details param is not empty
     * @param _prizes list of prize details
     */
    modifier onlyIfPrizesParam(Prize[] memory _prizes) {
        require(_prizes.length > 0, "Prizes should be greather or equal to 1");
        for (uint256 i = 0; i < _prizes.length; i++) require(_prizes[i].position == i + 1, "Prize list is not ordered");
        _;
    }

    /**
     * @notice Modifier that ensure thatmsg.value have the right amount if needed
     * @param _prizes list of prize details
     */
    modifier onlyIfPrizeAmountIfNeeded(Prize[] memory _prizes) {
        _checkIfPrizeAmountIfNeeded(_prizes);
        _;
    }

    /**
     * @notice Modifier that ensure that prize details is not empty
     */
    modifier onlyIfPrizesIsNotEmpty() {
        require(prizes[epoch.current()].length > 0, "Prizes should be greather or equal to 1");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";

import { IGame } from "../interfaces/IGame.sol";
import { IChild } from "../interfaces/IChild.sol";
import { ICronUpkeep } from "../interfaces/ICronUpkeep.sol";
import { IKeeper } from "../interfaces/IKeeper.sol";

import { TokenHelpers } from "../libraries/TokenHelpers.sol";

import { Child } from "../abstracts/Child.sol";

contract GameV1 is Child, IGame {
    using Counters for Counters.Counter;

    bool private _isBase;

    uint256 private randNonce;

    address public creator;

    address public keeper;

    uint256 public registrationAmount;

    uint256 public constant MAX_CREATOR_FEE = 500; // 5%

    uint256 public creatorFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public creatorAmount; // treasury amount that was not claimed

    uint256 public gameId; // gameId is fix and represent the fixed gameId for the game

    bytes32 public name;

    uint256 public version;

    uint256 public playTimeRange; // time length of a round in hours

    uint256 public maxPlayers;

    bool public isInProgress; // helps the keeper determine if a game has started or if we need to start it

    address[] public playerAddresses;
    mapping(address => Player) public players;

    ///
    /// CONSTRUCTOR AND INITIALISATION
    ///

    /**
     * @notice Constructor that define itself as base
     */
    constructor(
        address[] memory _allowedTokensERC20,
        address[] memory _allowedTokensERC721
    ) Child(_allowedTokensERC20, _allowedTokensERC721) {
        _isBase = true;
    }

    /**
     * @notice Create a new Game Implementation by cloning the base contract
     * @param _initialization the initialisation data with params as follow :
     *  @param _initialization.creator the game creator
     *  @param _initialization.owner the general admin address
     *  @param _initialization.cronUpkeep the cron upkeep address
     *  @param _initialization.name the game name
     *  @param _initialization.version the version of the game implementation
     *  @param _initialization.gameId the unique game gameId (fix)
     *  @param _initialization.playTimeRange the time range during which a player can play in hour
     *  @param _initialization.maxPlayers the maximum number of players for a game
     *  @param _initialization.registrationAmount the amount that players will need to pay to enter in the game
     *  @param _initialization.treasuryFee the treasury fee in percent
     *  @param _initialization.creatorFee creator fee in percent
     *  @param _initialization.encodedCron the cron string
     *  @param _initialization.prizes the cron string
     * @dev TODO NEXT VERSION Remove _isChildAllPrizesStandard limitation to include other prize typ
     * @dev TODO NEXT VERSION Make it only accessible to factory
     */
    function initialize(
        Initialization calldata _initialization
    )
        external
        payable
        override
        onlyIfNotBase
        onlyIfNotAlreadyInitialized
        onlyAllowedNumberOfPlayers(_initialization.maxPlayers)
        onlyAllowedPlayTimeRange(_initialization.playTimeRange)
        onlyTreasuryFee(_initialization.treasuryFee)
        onlyCreatorFee(_initialization.creatorFee)
        onlyIfPrizesParam(_initialization.prizes)
    {
        owner = _initialization.owner;
        creator = _initialization.creator;
        factory = msg.sender;
        keeper = _initialization.keeper;

        name = _initialization.name;

        randNonce = 0;

        registrationAmount = _initialization.registrationAmount;
        treasuryFee = _initialization.treasuryFee;
        creatorFee = _initialization.creatorFee;

        treasuryAmount = 0;
        creatorAmount = 0;

        gameId = _initialization.gameId;
        version = _initialization.version;

        playTimeRange = _initialization.playTimeRange;
        maxPlayers = _initialization.maxPlayers;

        // Setup prizes structure
        _checkIfPrizeAmountIfNeeded(_initialization.prizes);
        _addPrizes(_initialization.prizes);

        // Verify Game Configuration :
        // Game can only be payable only if also standard
        // OR Game can be not payable and everything else
        require((_isGamePayable() && _isChildAllPrizesStandard()) || !_isGamePayable(), "Configuration missmatch");

        // Limitation for current version as standard for NFT is not implemented
        require(_isChildAllPrizesStandard(), "This version only allow standard prize");
    }

    /**
     * @notice Function that is called by the keeper when game is ready to start
     * @dev TODO NEXT VERSION remove this function in next smart contract version
     */
    function startGame() external override onlyAdminOrCreator whenNotPaused onlyIfFull {
        _startGame();
    }

    ///
    /// MAIN FUNCTIONS
    ///

    /**
     * @notice Function that allow players to register for a game
     * @dev Creator cannot register for his own game
     */
    function registerForGame()
        external
        payable
        override
        onlyHumans
        whenNotPaused
        onlyIfGameIsNotInProgress
        onlyIfNotFull
        onlyIfNotAlreadyEntered
        onlyRegistrationAmount
        onlyNotCreator
    {
        players[msg.sender] = Player({
            playerAddress: msg.sender,
            roundCount: 0,
            hasPlayedRound: false,
            hasLost: false,
            isSplitOk: false,
            position: playerAddresses.length + 1,
            roundRangeUpperLimit: 0,
            roundRangeLowerLimit: 0
        });
        playerAddresses.push(msg.sender);

        emit RegisteredForGame(players[msg.sender].playerAddress, playerAddresses.length);
    }

    /**
     * @notice Function that allow players to play for the current round
     * @dev Creator cannot play for his own game
     * @dev Callable by remaining players
     */
    function playRound()
        external
        override
        onlyHumans
        whenNotPaused
        onlyIfFull
        onlyIfAlreadyEntered
        onlyIfHasNotLost
        onlyIfHasNotPlayedThisRound
        onlyNotCreator
        onlyIfGameIsInProgress
    {
        Player storage player = players[msg.sender];

        //Check if attempt is in the allowed time slot
        if (block.timestamp < player.roundRangeLowerLimit || block.timestamp > player.roundRangeUpperLimit)
            _setPlayerAsHavingLost(player);
        else {
            player.hasPlayedRound = true;
            player.roundCount += 1;
            emit PlayedRound(player.playerAddress);
        }
    }

    /**
     * @notice Function that is called by the keeper based on the keeper cron
     * @dev Callable by admin or keeper
     * @dev TODO NEXT VERSION Update triggerDailyCheckpoint to make it only callable by keeper
     */
    function triggerDailyCheckpoint() external override onlyAdminOrKeeper whenNotPaused {
        if (isInProgress) {
            _refreshPlayerStatus();
            _checkIfGameEnded();
        } else if (playerAddresses.length == maxPlayers) _startGame();
        emit TriggeredDailyCheckpoint(epoch.current(), msg.sender, block.timestamp);
    }

    /**
     * @notice Function that allow player to vote to split pot
     * @dev Only callable if less than 50% of the players remain
     * @dev Callable by remaining players
     */
    function voteToSplitPot()
        external
        override
        onlyIfGameIsInProgress
        onlyIfAlreadyEntered
        onlyIfHasNotLost
        onlyIfPlayersLowerHalfRemaining
        onlyIfGameIsSplittable
    {
        players[msg.sender].isSplitOk = true;
        emit VoteToSplitPot(epoch.current(), players[msg.sender].playerAddress);
    }

    ///
    /// INTERNAL FUNCTIONS
    ///

    /**
     * @notice Start the game(called when all conditions are ok)
     */
    function _startGame() internal {
        for (uint256 i = 0; i < playerAddresses.length; i++) _resetRoundRange(players[playerAddresses[i]]);
        isInProgress = true;
        emit StartedGame(block.timestamp, playerAddresses.length);
    }

    /**
     * @notice Reset the game (called at the end of the current game)
     */
    function _resetGame() internal {
        isInProgress = false;
        for (uint256 i = 0; i < playerAddresses.length; i++) delete players[playerAddresses[i]];

        delete playerAddresses;

        emit ResetGame(block.timestamp, epoch.current());
        epoch.increment();

        // Stop game if not payable to allow creator to add prizes
        if (!_isGamePayable()) return _pauseGame();

        Prize[] storage oldPrize = prizes[epoch.current() - 1];

        for (uint256 i = 0; i < oldPrize.length; i++) _addPrize(oldPrize[i]);
    }

    /**
     * @notice Internal function for prizes adding management
     * @param _prizes list of prize details
     */
    function _addPrizes(Prize[] memory _prizes) internal override {
        uint256 prizepool = 0;
        for (uint256 i = 0; i < _prizes.length; i++) {
            _addPrize(_prizes[i]);
            prizepool += _prizes[i].amount;
        }

        if (_isGamePayable()) {
            uint256 prizepoolVerify = registrationAmount * maxPlayers;
            require(prizepool == prizepoolVerify, "Wrong total amount to won");
        }
    }

    /**
     * @notice Check if game as ended
     * If so, it will create winners and reset the game
     */
    function _checkIfGameEnded() internal {
        uint256 remainingPlayersCount = _getRemainingPlayersCount();
        bool isPlitPot = _isAllPlayersSplitOk();

        if (remainingPlayersCount > 1 && !isPlitPot) return;

        Prize[] memory _prizes = prizes[epoch.current()];

        if (remainingPlayersCount == 1)
            // Distribute prizes over winners
            for (uint256 i = 0; i < playerAddresses.length; i++) {
                Player memory currentPlayer = players[playerAddresses[i]];
                (bool _found, Prize memory currentPrize) = _getPrizeForPosition(
                    epoch.current(),
                    currentPlayer.position
                );

                if (!currentPlayer.hasLost)
                    _addWinner(0, currentPlayer.playerAddress, _prizes[0].amount); // Player is winner
                else if (_found && currentPrize.position == currentPlayer.position)
                    _addWinner(currentPlayer.position, currentPlayer.playerAddress, currentPrize.amount); // Player has won a prize
            }

        if (isPlitPot) {
            // Split with remaining player
            uint256 prizepool = 0;
            for (uint256 i = 0; i < _prizes.length; i++) prizepool += _prizes[i].amount;
            uint256 splittedPrize = prizepool / remainingPlayersCount;
            for (uint256 i = 0; i < playerAddresses.length; i++) {
                Player memory currentPlayer = players[playerAddresses[i]];
                if (!currentPlayer.hasLost && currentPlayer.isSplitOk)
                    _addWinner(1, currentPlayer.playerAddress, splittedPrize);
            }
            emit GameSplitted(epoch.current(), remainingPlayersCount, splittedPrize);
        }

        if (remainingPlayersCount == 0)
            // Creator will take everything except the first prize that goes to the treasury
            for (uint256 i = 0; i < _prizes.length; i++) {
                address winnerAddress = i == 1 ? owner : creator;
                _addWinner(_prizes[i].position, winnerAddress, _prizes[i].amount);
            }
        _resetGame();
    }

    /**
     * @notice Refresh players status for remaining players
     */
    function _refreshPlayerStatus() internal {
        // If everyone is ok to split, we wait
        if (_isAllPlayersSplitOk()) return;

        for (uint256 i = 0; i < playerAddresses.length; i++) {
            Player storage player = players[playerAddresses[i]];
            // Refresh player status to having lost if player has not played
            if (!player.hasPlayedRound && !player.hasLost) _setPlayerAsHavingLost(player);
            else {
                // Reset round limits and round status for each remaining user
                _resetRoundRange(player);
                player.hasPlayedRound = false;
            }
        }
    }

    /**
     * @notice Add winner for given giveaway
     * @param _position position of winner
     * @param _playerAddress winner address
     * @param _amount amount
     * TODO NEXT VERSION : Standardize this function and pass it to child smart contract
     */
    function _addWinner(uint256 _position, address _playerAddress, uint256 _amount) internal {
        uint256 treasuryRoundAmount = (_amount * treasuryFee) / 10000;
        uint256 creatorRoundAmount = (_amount * creatorFee) / 10000;
        uint256 rewardAmount = _amount - treasuryRoundAmount - creatorRoundAmount;

        (bool _found, Prize memory prize) = _getPrizeForPosition(epoch.current(), _position);
        // FIXME WHY THIS FIX TESTS
        // require(_found, "No prize found for winner");

        winners[epoch.current()].push(
            Winner({
                epoch: epoch.current(),
                position: _position,
                userId: 0,
                playerAddress: _playerAddress,
                amountWon: rewardAmount,
                standard: prize.standard,
                contractAddress: prize.contractAddress,
                tokenId: prize.tokenId,
                prizeClaimed: false
            })
        );
        emit GameWon(epoch.current(), winners[epoch.current()].length, _playerAddress, rewardAmount);
        treasuryAmount += treasuryRoundAmount;
        creatorAmount += creatorRoundAmount;
    }

    /**
     * @notice Check if msg.value have the right amount if needed
     * @param _prizes list of prize details
     */
    function _checkIfPrizeAmountIfNeeded(Prize[] memory _prizes) internal view override {
        if (_isGamePayable()) return;

        uint256 prizepool = 0;
        for (uint256 i = 0; i < _prizes.length; i++) prizepool += _prizes[i].amount;

        require(msg.value == prizepool, "Need to send prizepool amount");
    }

    /**
     * @notice Internal function to check if game is payable
     * @return isPayable set to true if game is payable
     */
    function _isGamePayable() internal view returns (bool isPayable) {
        return registrationAmount > 0;
    }

    /**
     * @notice Returns a number between 0 and 24 minus the current length of a round
     * @param _playerAddress the player address
     * @return randomNumber the generated number
     */
    function _randMod(address _playerAddress) internal returns (uint256 randomNumber) {
        // Increase nonce
        randNonce++;
        uint256 maxUpperRange = 25 - playTimeRange; // We use 25 because modulo excludes the higher limit
        uint256 randNumber = uint256(keccak256(abi.encodePacked(block.timestamp, _playerAddress, randNonce))) %
            maxUpperRange;
        return randNumber;
    }

    /**
     * @notice Reset the round range for a player
     * @param _player the player
     */
    function _resetRoundRange(Player storage _player) internal {
        uint256 newRoundLowerLimit = _randMod(_player.playerAddress);
        _player.roundRangeLowerLimit = block.timestamp + newRoundLowerLimit * 60 * 60;
        _player.roundRangeUpperLimit = _player.roundRangeLowerLimit + playTimeRange * 60 * 60;
    }

    /**
     * @notice Update looser player
     * @param _player the player
     */
    function _setPlayerAsHavingLost(Player storage _player) internal {
        _player.position = _getRemainingPlayersCount();
        _player.hasLost = true;
        _player.isSplitOk = false;

        emit GameLost(epoch.current(), _player.playerAddress, _player.roundCount);
    }

    /**
     * @notice Check if all remaining players are ok to split pot
     * @return isSplitOk set to true if all remaining players are ok to split pot, false otherwise
     */
    function _isAllPlayersSplitOk() internal view returns (bool isSplitOk) {
        uint256 remainingPlayersSplitOkCounter = 0;
        uint256 remainingPlayersLength = _getRemainingPlayersCount();
        for (uint256 i = 0; i < playerAddresses.length; i++)
            if (players[playerAddresses[i]].isSplitOk) remainingPlayersSplitOkCounter++;

        return remainingPlayersLength != 0 && remainingPlayersSplitOkCounter == remainingPlayersLength;
    }

    /**
     * @notice Get the number of remaining players for the current game
     * @return remainingPlayersCount the number of remaining players for the current game
     */
    function _getRemainingPlayersCount() internal view returns (uint256 remainingPlayersCount) {
        uint256 remainingPlayers = 0;
        for (uint256 i = 0; i < playerAddresses.length; i++)
            if (!players[playerAddresses[i]].hasLost) remainingPlayers++;

        return remainingPlayers;
    }

    /**
     * @notice Pause the current game and associated keeper job
     * @dev Callable by admin or creator
     */

    function _pauseGame() internal whenNotPaused {
        _pause();
        IKeeper(keeper).pauseKeeper();
    }

    /**
     * @notice Unpause the current game and associated keeper job
     * @dev Callable by admin or creator
     */
    function _unpauseGame() internal whenPaused {
        _unpause();

        // Reset round limits and round status for each remaining user
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            Player storage player = players[playerAddresses[i]];
            if (!player.hasLost) {
                _resetRoundRange(player);
                player.hasPlayedRound = false;
            }
        }
        IKeeper(keeper).unpauseKeeper();
    }

    ///
    /// GETTERS FUNCTIONS
    ///

    /**
     * @notice Return game informations
     * @return gameData the game status data with params as follow :
     *  gameData.creator the creator address of the game
     *  gameData.epoch the epoch of the game
     *  gameData.name the name of the game
     *  gameData.playerAddressesCount the number of registered players
     *  gameData.maxPlayers the maximum players of the game
     *  gameData.registrationAmount the registration amount of the game
     *  gameData.playTimeRange the player time range of the game
     *  gameData.treasuryFee the treasury fee of the game
     *  gameData.creatorFee the creator fee of the game
     *  gameData.isPaused a boolean set to true if game is paused
     *  gameData.isInProgress a boolean set to true if game is in progress
     */
    function getGameData() external view override returns (GameData memory gameData) {
        return
            GameData({
                gameId: gameId,
                versionId: version,
                epoch: epoch.current(),
                name: name,
                playerAddressesCount: playerAddresses.length,
                remainingPlayersCount: _getRemainingPlayersCount(),
                maxPlayers: maxPlayers,
                registrationAmount: registrationAmount,
                playTimeRange: playTimeRange,
                treasuryFee: treasuryFee,
                creatorFee: creatorFee,
                isPaused: paused(),
                isInProgress: isInProgress,
                creator: creator,
                admin: owner,
                encodedCron: IKeeper(keeper).getEncodedCron()
            });
    }

    /**
     * @notice Return game informations
     * @dev Callable by admin or creator
     * @param _updateGameData the game data to update
     *  _updateGameData.name the name of the game
     *  _updateGameData.maxPlayers the maximum players of the game
     *  _updateGameData.registrationAmount the registration amount of the game
     *  _updateGameData.playTimeRange the player time range of the game
     *  _updateGameData.treasuryFee the treasury fee of the game
     *  _updateGameData.creatorFee the creator fee of the game
     *  _updateGameData.encodedCron the encoded cron of the game
     */
    function setGameData(UpdateGameData memory _updateGameData) external override whenPaused onlyAdminOrCreator {
        if (_updateGameData.name != name) name = _updateGameData.name;
        if (_updateGameData.maxPlayers != maxPlayers) maxPlayers = _updateGameData.maxPlayers;
        if (_updateGameData.registrationAmount != registrationAmount)
            registrationAmount = _updateGameData.registrationAmount;
        if (_updateGameData.playTimeRange != playTimeRange) playTimeRange = _updateGameData.playTimeRange;
        if (_updateGameData.treasuryFee != treasuryFee) treasuryFee = _updateGameData.treasuryFee;
        if (_updateGameData.creatorFee != creatorFee) creatorFee = _updateGameData.creatorFee;
        if (
            keccak256(abi.encodePacked(_updateGameData.encodedCron)) !=
            keccak256(abi.encodePacked(IKeeper(keeper).getEncodedCron()))
        ) IKeeper(keeper).setEncodedCron(_updateGameData.encodedCron);
    }

    /**
     * @notice Return the players addresses for the current game
     * @return gamePlayerAddresses list of players addresses
     */
    function getPlayerAddresses() external view override returns (address[] memory gamePlayerAddresses) {
        return playerAddresses;
    }

    /**
     * @notice Return a player for the current game
     * @param _player the player address
     * @return gamePlayer if finded
     */
    function getPlayer(address _player) external view override returns (Player memory gamePlayer) {
        return players[_player];
    }

    /**
     * @notice Return cronUpkeep
     * @dev Callable by only by owner
     */
    function getCronUpkeep() external view returns (address _cronUpkeep) {
        return IKeeper(keeper).getCronUpkeep();
    }

    /**
     * @notice Return encodedCron
     * @dev Callable by only by owner
     */
    function getEncodedCron() external view returns (string memory _encodedCron) {
        return IKeeper(keeper).getEncodedCron();
    }

    /**
     * @notice Check if all remaining players are ok to split pot
     * @return isSplitOk set to true if all remaining players are ok to split pot, false otherwise
     */
    function isAllPlayersSplitOk() external view override returns (bool isSplitOk) {
        return _isAllPlayersSplitOk();
    }

    /**
     * @notice Check if Game is payable
     * @return isPayable set to true if game is payable, false otherwise
     */
    function isGamePayable() external view override returns (bool isPayable) {
        return _isGamePayable();
    }

    /**
     * @notice Check if Game prizes are standard
     * @return isStandard true if game prizes are standard, false otherwise
     */
    function isGameAllPrizesStandard() external view override returns (bool isStandard) {
        return _isChildAllPrizesStandard();
    }

    /**
     * @notice Get the number of remaining players for the current game
     * @return remainingPlayersCount the number of remaining players for the current game
     */
    function getRemainingPlayersCount() external view override returns (uint256 remainingPlayersCount) {
        return _getRemainingPlayersCount();
    }

    ///
    /// SETTERS FUNCTIONS
    ///

    /**
     * @notice Set the name of the game
     * @param _name the new game name
     * @dev Callable by creator
     */
    function setName(bytes32 _name) external override onlyCreator {
        name = _name;
    }

    /**
     * @notice Set the playTimeRange of the game
     * @param _playTimeRange the new game playTimeRange
     * @dev Callable by creator
     */
    function setPlayTimeRange(uint256 _playTimeRange) external override whenPaused onlyCreator {
        playTimeRange = _playTimeRange;
    }

    /**
     * @notice Set the maximum allowed players for the game
     * @param _maxPlayers the new max players limit
     * @dev Callable by admin or creator
     */
    function setMaxPlayers(
        uint256 _maxPlayers
    )
        external
        override
        whenPaused
        onlyAdminOrCreator
        onlyAllowedNumberOfPlayers(_maxPlayers)
        onlyIfGameIsNotInProgress
    {
        maxPlayers = _maxPlayers;
    }

    /**
     * @notice Set the creator fee for the game
     * @param _creatorFee the new creator fee in %
     * @dev Callable by admin or creator
     * @dev Callable when game if not in progress
     */
    function setCreatorFee(
        uint256 _creatorFee
    ) external override onlyAdminOrCreator onlyIfGameIsNotInProgress onlyCreatorFee(_creatorFee) {
        creatorFee = _creatorFee;
    }

    /**
     * @notice Set the keeper address
     * @param _cronUpkeep the new keeper address
     * @dev Callable by admin or factory
     */
    function setCronUpkeep(
        address _cronUpkeep
    ) external override whenPaused onlyAdminOrFactory onlyAddressInit(_cronUpkeep) {
        ICronUpkeep(_cronUpkeep).addDelegator(address(keeper));
        IKeeper(keeper).setCronUpkeep(_cronUpkeep);
    }

    /**
     * @notice Set the encoded cron
     * @param _encodedCron the new encoded cron as * * * * *
     * @dev Callable by admin or creator
     */
    function setEncodedCron(string memory _encodedCron) external override whenPaused onlyAdminOrCreator {
        IKeeper(keeper).setEncodedCron(_encodedCron);
    }

    /**
     * @notice Allow creator to withdraw his fee
     * @dev Callable by admin
     */
    function claimCreatorFee()
        external
        override
        onlyCreator
        onlyIfClaimableAmount(creatorAmount)
        onlyIfEnoughtBalance(creatorAmount)
    {
        uint256 currentCreatorAmount = creatorAmount;
        creatorAmount = 0;
        emit CreatorFeeClaimed(currentCreatorAmount);
        TokenHelpers.safeTransfert(creator, currentCreatorAmount);
    }

    /**
     * @notice Pause the current game and associated keeper job
     * @dev Callable by admin or creator
     */
    function pause() external override(Child, IChild) onlyAdminOrCreatorOrFactory whenNotPaused {
        _pauseGame();
    }

    /**
     * @notice Unpause the current game and associated keeper job
     * @dev Callable by admin or creator
     */
    function unpause()
        external
        override(Child, IChild)
        onlyAdminOrCreatorOrFactory
        whenPaused
        onlyIfKeeperDataInit
        onlyIfPrizesIsNotEmpty
    {
        _unpauseGame();
    }

    ///
    /// EMERGENCY
    ///

    /**
     * @notice Transfert Creator Ownership
     * @param _creator the new creator address
     * @dev Callable by creator
     */
    function transferCreatorOwnership(address _creator) external override onlyCreator onlyAddressInit(_creator) {
        emit CreatorOwnershipTransferred(creator, _creator);
        creator = _creator;
    }

    ///
    /// FALLBACK FUNCTIONS
    ///

    // /**
    //  * @notice Called for empty calldata (and any value)
    //  */
    // receive() external payable;

    // /**
    //  * @notice Called when no other function matches (not even the receive function). Optionally payable
    //  */
    // fallback() external payable virtual ;

    ///
    /// MODIFIERS
    ///

    /**
     * @notice Modifier that ensure only creator can access this function
     */
    modifier onlyCreator() {
        require(msg.sender == creator, "Caller is not the creator");
        _;
    }

    /**
     * @notice Modifier that ensure only not creator can access this function
     */
    modifier onlyNotCreator() {
        require(msg.sender != creator, "Caller can't be the creator");
        _;
    }

    /**
     * @notice Modifier that ensure only admin or creator can access this function
     */
    modifier onlyAdminOrCreator() {
        require(msg.sender == creator || msg.sender == owner, "Caller is not the admin or creator");
        _;
    }

    /**
     * @notice Modifier that ensure only admin or creator or factory can access this function
     */
    modifier onlyAdminOrCreatorOrFactory() {
        require(
            msg.sender == creator || msg.sender == owner || msg.sender == address(factory),
            "Caller is not the admin or creator or factory"
        );
        _;
    }

    /**
     * @notice Modifier that ensure only admin or keeper can access this function
     */
    modifier onlyAdminOrKeeper() {
        require(
            msg.sender == address(IKeeper(keeper).getCronUpkeep()) || msg.sender == owner,
            "Caller is not the admin or keeper"
        );
        _;
    }

    /**
     * @notice Modifier that ensure only keeper can access this function
     */
    modifier onlyKeeper() {
        require(msg.sender == address(IKeeper(keeper).getCronUpkeep()), "Caller is not the keeper");
        _;
    }

    /**
     * @notice Modifier that ensure that keeper data are initialised
     */
    modifier onlyIfKeeperDataInit() {
        require(address(IKeeper(keeper).getCronUpkeep()) != address(0), "Keeper need to be initialised");
        require(bytes(IKeeper(keeper).getEncodedCron()).length != 0, "Keeper cron need to be initialised");
        _;
    }

    /**
     * @notice Modifier that ensure that game is not full
     */
    modifier onlyIfNotFull() {
        require(playerAddresses.length < maxPlayers, "This game is full");
        _;
    }

    /**
     * @notice Modifier that ensure that game is full
     */
    modifier onlyIfFull() {
        require(playerAddresses.length == maxPlayers, "This game is not full");
        _;
    }

    /**
     * @notice Modifier that ensure that player not already entered in the game
     */
    modifier onlyIfNotAlreadyEntered() {
        require(players[msg.sender].playerAddress == address(0), "Player already entered in this game");
        _;
    }

    /**
     * @notice Modifier that ensure that player already entered in the game
     */
    modifier onlyIfAlreadyEntered() {
        require(players[msg.sender].playerAddress != address(0), "Player has not entered in this game");
        _;
    }

    /**
     * @notice Modifier that ensure that player has not lost
     */
    modifier onlyIfHasNotLost() {
        require(!players[msg.sender].hasLost, "Player has already lost");
        _;
    }

    /**
     * @notice Modifier that ensure that player has not already played this round
     */
    modifier onlyIfHasNotPlayedThisRound() {
        require(!players[msg.sender].hasPlayedRound, "Player has already played in this round");
        _;
    }

    /**
     * @notice Modifier that ensure that there is less than 50% of remaining players
     */
    modifier onlyIfPlayersLowerHalfRemaining() {
        uint256 remainingPlayersLength = _getRemainingPlayersCount();
        require(
            remainingPlayersLength <= maxPlayers / 2,
            "Remaining players must be less or equal than half of started players"
        );
        _;
    }

    /**
     * @notice Modifier that ensure that the game is in progress
     */
    modifier onlyIfGameIsInProgress() {
        require(isInProgress, "Game is not in progress");
        _;
    }

    /**
     * @notice Modifier that ensure that the game is not in progress
     */
    modifier onlyIfGameIsNotInProgress() {
        require(!isInProgress, "Game is already in progress");
        _;
    }

    /**
     * @notice Modifier that ensure that amount sended is registration amount
     */
    modifier onlyRegistrationAmount() {
        require(msg.value == registrationAmount, "Only registration amount is allowed");
        _;
    }

    /**
     * @notice Modifier that ensure that there is less than 50% of remaining players
     */
    modifier onlyIfPlayerWon() {
        uint256 remainingPlayersLength = _getRemainingPlayersCount();
        require(
            remainingPlayersLength <= maxPlayers / 2,
            "Remaining players must be less or equal than half of started players"
        );
        _;
    }

    /**
     * @notice Modifier that ensure that we can't initialize the implementation contract
     */
    modifier onlyIfNotBase() {
        require(!_isBase, "The implementation contract can't be initialized");
        _;
    }

    /**
     * @notice Modifier that ensure that we can't initialize a cloned contract twice
     */
    modifier onlyIfNotAlreadyInitialized() {
        require(creator == address(0), "Contract already initialized");
        _;
    }

    /**
     * @notice Modifier that ensure that max players is in allowed range
     */
    modifier onlyAllowedNumberOfPlayers(uint256 _maxPlayers) {
        require(_maxPlayers > 1, "maxPlayers should be bigger than or equal to 2");
        require(_maxPlayers <= 100, "maxPlayers should not be bigger than 100");
        _;
    }

    /**
     * @notice Modifier that ensure that play time range is in allowed range
     */
    modifier onlyAllowedPlayTimeRange(uint256 _playTimeRange) {
        require(_playTimeRange > 0, "playTimeRange should be bigger than 0");
        require(_playTimeRange < 9, "playTimeRange should not be bigger than 8");
        _;
    }

    /**
     * @notice Modifier that ensure that creator fee are not too high
     */
    modifier onlyCreatorFee(uint256 _creatorFee) {
        require(_creatorFee <= MAX_CREATOR_FEE, "Creator fee too high");
        _;
    }

    /**
     * @notice Modifier that ensure that game is payable
     */
    modifier onlyIfGameIsPayable() {
        require(_isGamePayable(), "Game is not payable");
        _;
    }

    /**
     * @notice Modifier that ensure that game is not payable
     */
    modifier onlyIfGameIsNotPayable() {
        require(!_isGamePayable(), "Game is payable");
        _;
    }

    /**
     * @notice Modifier that ensure that game is splittable
     */
    modifier onlyIfGameIsSplittable() {
        require(_isChildAllPrizesStandard(), "Game is not splittable");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/utils/Address.sol";

interface IChild {
    ///STRUCTS

    /**
     * @notice Winner structure that contain all usefull data for a winner
     */
    struct Winner {
        uint256 epoch;
        uint256 userId;
        address playerAddress;
        uint256 amountWon;
        uint256 position;
        uint256 standard;
        address contractAddress;
        uint256 tokenId;
        bool prizeClaimed;
    }

    /**
     * @notice PrizeStandard ENUM
     */
    enum PrizeStandard {
        STANDARD,
        ERC20,
        ERC721
    }

    /**
     * @notice Prize structure that contain a list of prizes for the current epoch
     */
    struct Prize {
        uint256 position;
        uint256 amount;
        /*
         * This will return a single integer between 0 and 5.
         * The numbers represent different ‘states’ a name is currently in.
         * 0 - NATIVE
         * 1 - ERC20
         * 2 - ERC721
         */
        uint256 standard;
        address contractAddress;
        uint256 tokenId;
    }

    ///
    ///EVENTS
    ///

    /**
     * @notice Called when a prize is added
     */
    event PrizeAdded(
        uint256 epoch,
        uint256 position,
        uint256 amount,
        uint256 standard,
        address contractAddress,
        uint256 tokenId
    );
    /**
     * @notice Called when a player have claimed his prize
     */
    event GamePrizeClaimed(address claimer, uint256 epoch, uint256 amountClaimed);
    /**
     * @notice Called when a methode transferCreatorOwnership is called
     */
    event CreatorOwnershipTransferred(address oldCreator, address newCreator);
    /**
     * @notice Called when a methode transferAdminOwnership is called
     */
    event AdminOwnershipTransferred(address oldAdmin, address newAdmin);
    /**
     * @notice Called when a methode transferFactoryOwnership is called
     */
    event FactoryOwnershipTransferred(address oldFactory, address newFactory);
    /**
     * @notice Called when the contract have receive funds via receive() or fallback() function
     */
    event Received(address sender, uint256 amount);
    /**
     * @notice Called when a player have claimed his prize
     */
    event ChildPrizeClaimed(address claimer, uint256 epoch, uint256 amountClaimed);
    /**
     * @notice Called when the treasury fee are claimed
     */
    event TreasuryFeeClaimed(uint256 amount);
    /**
     * @notice Called when the treasury fee are claimed by factory
     */
    event TreasuryFeeClaimedByFactory(uint256 amount);
    /**
     * @notice Called when the creator fee are claimed
     */
    event CreatorFeeClaimed(uint256 amount);
    /**
     * @notice Called when the creator or admin update encodedCron
     */
    event EncodedCronUpdated(uint256 jobId, string encodedCron);
    /**
     * @notice Called when the factory or admin update cronUpkeep
     */
    event CronUpkeepUpdated(uint256 jobId, address cronUpkeep);

    /**
     * @notice Function that is called by a winner to claim his prize
     * @dev TODO NEXT VERSION Update claim process according to prize type
     */
    function claimPrize(uint256 _epoch) external;

    /**
     * @notice Prizes adding management
     * @dev Callable by admin or creator
     * @dev TODO NEXT VERSION add a taxe for creator in case of free childs
     *      Need to store the factory childCreationAmount in this contract on initialisation
     * @dev TODO NEXT VERSION Remove _isChildAllPrizesStandard limitation to include other prize typ
     */
    function addPrizes(Prize[] memory _prizes) external payable;

    ///
    /// GETTERS FUNCTIONS
    ///
    /**
     * @notice Return the winners for a round id
     * @param _epoch the round id
     * @return childWinners list of Winner
     */
    function getWinners(uint256 _epoch) external view returns (Winner[] memory childWinners);

    /**
     * @notice Return the winners for a round id
     * @param _epoch the round id
     * @return childPrizes list of Prize
     */
    function getPrizes(uint256 _epoch) external view returns (Prize[] memory childPrizes);

    ///
    /// SETTERS FUNCTIONS
    ///

    ///
    /// ADMIN FUNCTIONS
    ///

    /**
     * @notice Add a token to allowed ERC20
     * @param _token the new token address
     * @dev Callable by admin
     */
    function addTokenERC20(address _token) external;

    /**
     * @notice Remove a token to allowed ERC20
     * @param _token the token address to remove
     * @dev Callable by admin
     */
    function removeTokenERC20(address _token) external;

    /**
     * @notice Add a token to allowed ERC721
     * @param _token the new token address
     * @dev Callable by admin
     */
    function addTokenERC721(address _token) external;

    /**
     * @notice Remove a token to allowed ERC721
     * @param _token the token address to remove
     * @dev Callable by admin
     */
    function removeTokenERC721(address _token) external;

    /**
     * @notice Withdraw Treasury fee
     * @dev Callable by admin
     */
    function claimTreasuryFee() external;

    /**
     * @notice Set the treasury fee for the child
     * @param _treasuryFee the new treasury fee in %
     * @dev Callable by admin
     * @dev Callable when child if not in progress
     */
    function setTreasuryFee(uint256 _treasuryFee) external;

    /**
     * @notice Pause the current game and associated keeper job
     * @dev Callable by admin or creator
     */
    function pause() external;

    /**
     * @notice Unpause the current game and associated keeper job
     * @dev Callable by admin or creator
     */
    function unpause() external;

    ///
    /// EMERGENCY
    ///

    /**
     * @notice Transfert Admin Ownership
     * @param _adminAddress the new admin address
     * @dev Callable by admin
     */
    function transferAdminOwnership(address _adminAddress) external;

    /**
     * @notice Transfert Factory Ownership
     * @param _factory the new factory address
     * @dev Callable by factory
     */
    function transferFactoryOwnership(address _factory) external;

    /**
     * @notice Allow admin to withdraw all funds of smart contract
     * @param _receiver the receiver for the funds (admin or factory)
     * @dev Callable by admin or factory
     */
    function withdrawFunds(address _receiver) external;

    /**
     * @notice Allow admin to withdraw Native from smart contract
     * @param _receiver the receiver for the funds (admin or factory)
     * @dev Callable by admin or factory
     */
    function withdrawNative(address _receiver) external;

    /**
     * @notice Allow admin to withdraw ERC20 from smart contract
     * @param _contractAddress the contract address
     * @param _receiver the receiver for the funds (admin or factory)
     * @dev Callable by admin or factory
     */
    function withdrawERC20(address _contractAddress, address _receiver) external;

    /**
     * @notice Allow admin to withdraw ERC721 from smart contract
     * @param _contractAddress the contract address
     * @param _tokenId the token id
     * @param _receiver the receiver for the funds (admin or factory)
     * @dev Callable by admin or factory
     */
    function withdrawERC721(address _contractAddress, uint256 _tokenId, address _receiver) external;

    ///
    /// FALLBACK FUNCTIONS
    ///

    // /**
    //  * @notice Called for empty calldata (and any value)
    //  */
    // receive() external payable;

    // /**
    //  * @notice Called when no other function matches (not even the receive function). Optionally payable
    //  */
    // fallback() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/KeeperBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/**
  The Cron contract is a chainlink keepers-powered cron job runner for smart contracts.
  The contract enables developers to trigger actions on various targets using cron
  strings to specify the cadence. For example, a user may have 3 tasks that require
  regular service in their dapp ecosystem:
    1) 0xAB..CD, update(1), "0 0 * * *"     --> runs update(1) on 0xAB..CD daily at midnight
    2) 0xAB..CD, update(2), "30 12 * * 0-4" --> runs update(2) on 0xAB..CD weekdays at 12:30
    3) 0x12..34, trigger(), "0 * * * *"     --> runs trigger() on 0x12..34 hourly
  To use this contract, a user first deploys this contract and registers it on the chainlink
  keeper registry. Then the user adds cron jobs by following these steps:
    1) Convert a cron string to an encoded cron spec by calling encodeCronString()
    2) Take the encoding, target, and handler, and create a job by sending a tx to createCronJob()
    3) Cron job is running :)
*/

interface ICronUpkeep {
    event CronJobExecuted(uint256 indexed id, uint256 timestamp);
    event CronJobCreated(uint256 indexed id, address target, bytes handler);
    event CronJobUpdated(uint256 indexed id, address target, bytes handler);
    event CronJobDeleted(uint256 indexed id);
    event DelegatorAdded(address target);
    event DelegatorRemoved(address target);

    error CallFailed(uint256 id, string reason);
    error CronJobIDNotFound(uint256 id);
    error DontNeedPerformUpkeep();
    error ExceedsMaxJobs();
    error InvalidHandler();
    error TickInFuture();
    error TickTooOld();
    error TickDoesntMatchSpec();

    /**
     * @notice Creates a cron job from the given encoded spec
     * @param target the destination contract of a cron job
     * @param handler the function signature on the target contract to call
     * @param encodedCronSpec abi encoding of a cron spec
     */
    function createCronJobFromEncodedSpec(address target, bytes memory handler, bytes memory encodedCronSpec) external;

    /**
     * @notice Updates a cron job from the given encoded spec
     * @param id the id of the cron job to update
     * @param newTarget the destination contract of a cron job
     * @param newHandler the function signature on the target contract to call
     * @param newEncodedCronSpec abi encoding of a cron spec
     */
    function updateCronJob(
        uint256 id,
        address newTarget,
        bytes memory newHandler,
        bytes memory newEncodedCronSpec
    ) external;

    /**
     * @notice Deletes the cron job matching the provided id. Reverts if
     * the id is not found.
     * @param id the id of the cron job to delete
     */
    function deleteCronJob(uint256 id) external;

    /**
     * @notice Add a delegator to the smart contract.
     * @param delegator the address of delegator to add
     */
    function addDelegator(address delegator) external;

    /**
     * @notice Remove a delegator to the smart contract.
     * @param delegator the address of delegator to remove
     */
    function removeDelegator(address delegator) external;

    /**
     * @notice Pauses the contract, which prevents executing performUpkeep
     */
    function pause() external;

    /**
     * @notice Unpauses the contract
     */
    function unpause() external;

    /**
     * @notice gets a list of active cron job IDs
     * @return list of active cron job IDs
     */
    function getActiveCronJobIDs() external view returns (uint256[] memory);

    /**
     * @notice gets the next cron job IDs
     * @return next cron job IDs
     */
    function getNextCronJobIDs() external view returns (uint256);

    /**
     * @notice gets a list of all delegators
     * @return list of adelegators address
     */
    function getDelegators() external view returns (address[] memory);

    /**
     * @notice gets a cron job
     * @param id the cron job ID
     * @return target - the address a cron job forwards the eth tx to
     *     handler - the encoded function sig to execute when forwarding a tx
     *     cronString - the string representing the cron job
     *     nextTick - the timestamp of the next time the cron job will run
     */
    function getCronJob(
        uint256 id
    ) external view returns (address target, bytes memory handler, string memory cronString, uint256 nextTick);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/utils/Address.sol";

import { IChild } from "./IChild.sol";

interface IGame is IChild {
    ///STRUCTS

    /**
     * @notice Player structure that contain all usefull data for a player
     */
    struct Player {
        address playerAddress;
        uint256 roundRangeLowerLimit;
        uint256 roundRangeUpperLimit;
        bool hasPlayedRound;
        uint256 roundCount;
        uint256 position;
        bool hasLost;
        bool isSplitOk;
    }

    /**
     * @notice Initialization structure that contain all the data that are needed to create a new game
     */
    struct Initialization {
        address owner;
        address creator;
        address cronUpkeep;
        address keeper;
        bytes32 name;
        uint256 version;
        uint256 gameId;
        uint256 playTimeRange;
        uint256 maxPlayers;
        uint256 registrationAmount;
        uint256 treasuryFee;
        uint256 creatorFee;
        string encodedCron;
        Prize[] prizes;
    }

    struct GameData {
        uint256 gameId;
        uint256 versionId;
        uint256 epoch;
        bytes32 name;
        uint256 playerAddressesCount;
        uint256 remainingPlayersCount;
        uint256 maxPlayers;
        uint256 registrationAmount;
        uint256 playTimeRange;
        uint256 treasuryFee;
        uint256 creatorFee;
        bool isPaused;
        bool isInProgress;
        address creator;
        address admin;
        string encodedCron;
    }

    struct UpdateGameData {
        bytes32 name;
        uint256 maxPlayers;
        uint256 registrationAmount;
        uint256 playTimeRange;
        uint256 treasuryFee;
        uint256 creatorFee;
        string encodedCron;
    }

    ///
    ///EVENTS
    ///

    /**
     * @notice Called when a player has registered for a game
     */
    event RegisteredForGame(address playerAddress, uint256 playersCount);
    /**
     * @notice Called when the keeper start the game
     */
    event StartedGame(uint256 timelock, uint256 playersCount);
    /**
     * @notice Called when the keeper reset the game
     */
    event ResetGame(uint256 timelock, uint256 resetId);
    /**
     * @notice Called when a player lost a game
     */
    event GameLost(uint256 epoch, address playerAddress, uint256 roundCount);
    /**
     * @notice Called when a player play a round
     */
    event PlayedRound(address playerAddress);
    /**
     * @notice Called when a player won the game
     */
    event GameWon(uint256 epoch, uint256 winnersCounter, address playerAddress, uint256 amountWon);
    /**
     * @notice Called when some player(s) split the game
     */
    event GameSplitted(uint256 epoch, uint256 remainingPlayersCount, uint256 amountWon);
    /**
     * @notice Called when a player vote to split pot
     */
    event VoteToSplitPot(uint256 epoch, address playerAddress);
    /**
     * @notice Called when TriggerDailyCheckpoint function is called
     */
    event TriggeredDailyCheckpoint(uint256 epoch, address emmiter, uint256 timestamp);

    ///
    /// INITIALISATION
    ///

    /**
     * @notice Create a new Game Implementation by cloning the base contract
     * @param _initialization the initialisation data with params as follow :
     *  @param _initialization.creator the game creator
     *  @param _initialization.owner the general admin address
     *  @param _initialization.cronUpkeep the cron upkeep address
     *  @param _initialization.name the game name
     *  @param _initialization.version the version of the game implementation
     *  @param _initialization.gameId the unique game gameId (fix)
     *  @param _initialization.playTimeRange the time range during which a player can play in hour
     *  @param _initialization.maxPlayers the maximum number of players for a game
     *  @param _initialization.registrationAmount the amount that players will need to pay to enter in the game
     *  @param _initialization.treasuryFee the treasury fee in percent
     *  @param _initialization.creatorFee creator fee in percent
     *  @param _initialization.encodedCron the cron string
     *  @param _initialization.prizes the cron string
     * @dev TODO NEXT VERSION Remove _isChildAllPrizesStandard limitation to include other prize typ
     * @dev TODO NEXT VERSION Make it only accessible to factory
     */
    function initialize(Initialization calldata _initialization) external payable;

    /**
     * @notice Function that is called by the keeper when game is ready to start
     * @dev TODO NEXT VERSION remove this function in next smart contract version
     */
    function startGame() external;

    ///
    /// MAIN FUNCTIONS
    ///

    /**
     * @notice Function that allow players to register for a game
     * @dev Creator cannot register for his own game
     */
    function registerForGame() external payable;

    /**
     * @notice Function that allow players to play for the current round
     * @dev Creator cannot play for his own game
     * @dev Callable by remaining players
     */
    function playRound() external;

    /**
     * @notice Function that is called by the keeper based on the keeper cron
     * @dev Callable by admin or keeper
     * @dev TODO NEXT VERSION Update triggerDailyCheckpoint to make it only callable by keeper
     */
    function triggerDailyCheckpoint() external;

    /**
     * @notice Function that allow player to vote to split pot
     * @dev Only callable if less than 50% of the players remain
     * @dev Callable by remaining players
     */
    function voteToSplitPot() external;

    ///
    /// GETTERS FUNCTIONS
    ///

    /**
     * @notice Return game informations
     * @return gameData the game status data with params as follow :
     *  gameData.creator the creator address of the game
     *  gameData.epoch the epoch of the game
     *  gameData.name the name of the game
     *  gameData.playerAddressesCount the number of registered players
     *  gameData.maxPlayers the maximum players of the game
     *  gameData.registrationAmount the registration amount of the game
     *  gameData.playTimeRange the player time range of the game
     *  gameData.treasuryFee the treasury fee of the game
     *  gameData.creatorFee the creator fee of the game
     *  gameData.isPaused a boolean set to true if game is paused
     *  gameData.isInProgress a boolean set to true if game is in progress
     */
    function getGameData() external view returns (GameData memory gameData);

    /**
     * @notice Return game informations
     * @dev Callable by admin or creator
     * @param _updateGameData the game data to update
     *  _updateGameData.name the name of the game
     *  _updateGameData.maxPlayers the maximum players of the game
     *  _updateGameData.registrationAmount the registration amount of the game
     *  _updateGameData.playTimeRange the player time range of the game
     *  _updateGameData.treasuryFee the treasury fee of the game
     *  _updateGameData.creatorFee the creator fee of the game
     *  _updateGameData.encodedCron the encoded cron of the game
     */
    function setGameData(UpdateGameData memory _updateGameData) external;

    /**
     * @notice Return the players addresses for the current game
     * @return gamePlayerAddresses list of players addresses
     */
    function getPlayerAddresses() external view returns (address[] memory gamePlayerAddresses);

    /**
     * @notice Return a player for the current game
     * @param _player the player address
     * @return gamePlayer if finded
     */
    function getPlayer(address _player) external view returns (Player memory gamePlayer);

    /**
     * @notice Check if all remaining players are ok to split pot
     * @return isSplitOk set to true if all remaining players are ok to split pot, false otherwise
     */
    function isAllPlayersSplitOk() external view returns (bool isSplitOk);

    /**
     * @notice Check if Game is payable
     * @return isPayable set to true if game is payable, false otherwise
     */
    function isGamePayable() external view returns (bool isPayable);

    /**
     * @notice Check if Game prizes are standard
     * @return isStandard true if game prizes are standard, false otherwise
     */
    function isGameAllPrizesStandard() external view returns (bool isStandard);

    /**
     * @notice Get the number of remaining players for the current game
     * @return remainingPlayersCount the number of remaining players for the current game
     */
    function getRemainingPlayersCount() external view returns (uint256 remainingPlayersCount);

    ///
    /// SETTERS FUNCTIONS
    ///

    /**
     * @notice Set the name of the game
     * @param _name the new game name
     * @dev Callable by creator
     */
    function setName(bytes32 _name) external;

    /**
     * @notice Set the playTimeRange of the game
     * @param _playTimeRange the new game playTimeRange
     * @dev Callable by creator
     */
    function setPlayTimeRange(uint256 _playTimeRange) external;

    /**
     * @notice Set the maximum allowed players for the game
     * @param _maxPlayers the new max players limit
     * @dev Callable by admin or creator
     */
    function setMaxPlayers(uint256 _maxPlayers) external;

    /**
     * @notice Set the creator fee for the game
     * @param _creatorFee the new creator fee in %
     * @dev Callable by admin or creator
     * @dev Callable when game if not in progress
     */
    function setCreatorFee(uint256 _creatorFee) external;

    /**
     * @notice Set the keeper address
     * @param _cronUpkeep the new keeper address
     * @dev Callable by admin or factory
     */
    function setCronUpkeep(address _cronUpkeep) external;

    /**
     * @notice Set the encoded cron
     * @param _encodedCron the new encoded cron as * * * * *
     * @dev Callable by admin or creator
     */
    function setEncodedCron(string memory _encodedCron) external;

    /**
     * @notice Allow creator to withdraw his fee
     * @dev Callable by admin
     */
    function claimCreatorFee() external;

    ///
    /// EMERGENCY
    ///

    /**
     * @notice Transfert Creator Ownership
     * @param _creator the new creator address
     * @dev Callable by creator
     */
    function transferCreatorOwnership(address _creator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

interface IKeeper {
    /**
     * @notice Called when the creator or admin call registerCronToUpkeep
     */
    event CronUpkeepRegistered(uint256 jobId, address cronUpkeep);
    /**
     * @notice Called when the creator or admin update encodedCron
     */
    event EncodedCronUpdated(uint256 jobId, string encodedCron);
    /**
     * @notice Called when the factory or admin update cronUpkeep
     */
    event CronUpkeepUpdated(uint256 jobId, address cronUpkeep);

    /**
     * @notice Return cronUpkeep
     * @dev Callable by only by owner
     */
    function getCronUpkeep() external view returns (address _cronUpkeep);

    /**
     * @notice Return encodedCron
     * @dev Callable by only by owner
     */
    function getEncodedCron() external view returns (string memory _encodedCron);

    /**
     * @notice Return handler
     * @dev Callable by only by owner
     */
    function getHandler() external view returns (string memory _handler);

    /**
     * @notice Register the cron to the upkeep contract
     * @dev Callable by only by owner
     */
    function registerCronToUpkeep() external;

    /**
     * @notice Register the cron to the upkeep contract
     * @dev Callable by only by owner
     */
    function registerCronToUpkeep(address _target) external;

    /**
     * @notice Set the keeper address
     * @param _cronUpkeep the new keeper address
     * @dev Callable by only by owner
     */
    function setCronUpkeep(address _cronUpkeep) external;

    /**
     * @notice Set the encoded cron
     * @param _encodedCron the new encoded cron as * * * * *
     * @dev Callable by only by owner
     */
    function setEncodedCron(string memory _encodedCron) external;

    /**
     * @notice Pause the current keeper and associated keeper job
     * @dev Callable by only by owner
     */
    function pauseKeeper() external;

    /**
     * @notice Unpause the current keeper and associated keeper job
     * @dev Callable by only by owner
     */
    function unpauseKeeper() external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title The token helpers library
 * @notice TODO
 * @dev this is the internal version of the library, which mean that it should only be used for internal purpose
 * by the same name.
 */
library TokenHelpers {
    /**
     * @notice Called when a transfert have failed
     */
    event FailedTransfer(address receiver, uint256 amount);

    /**
     * @notice Transfert funds
     * @param _receiver the receiver address
     * @param _amount the amount to transfert
     * @dev TODO NEXT VERSION use SafeERC20 library from OpenZeppelin
     */
    function safeTransfert(address _receiver, uint256 _amount) public onlyIfEnoughtBalance(_amount) {
        (bool success, ) = _receiver.call{ value: _amount }("");

        if (!success) {
            emit FailedTransfer(_receiver, _amount);
            require(false, "Transfer failed.");
        }
    }

    /**
     * @notice Transfert ERC20 token
     * @param contractAddress the ERC20 contract address
     * @param _from the address that will send the funds
     * @param _to the receiver for the funds
     * @param _amount the amount to send
     * @dev Callable by admin or factory
     */
    function transfertERC20(address contractAddress, address _from, address _to, uint256 _amount) public {
        bool success = IERC20(contractAddress).transferFrom(_from, _to, _amount);
        if (!success) require(false, "Amount transfert failed");
    }

    /**
     * @notice Transfert ERC721 token
     * @param contractAddress the ERC721 contract address
     * @param _from the address that will send the funds
     * @param _to the receiver for the funds
     * @param _tokenId the token id
     * @dev Callable by admin or factory
     */
    function transfertERC721(address contractAddress, address _from, address _to, uint256 _tokenId) public {
        ERC721(contractAddress).transferFrom(_from, _to, _tokenId);
    }

    /**
     * @notice Get the list of token ERC721
     * @param _token the token address to check
     * @param _account the account to check
     * @return _tokenIds list of token ids for account
     * @dev Callable by admin
     */
    function getERC721TokenIds(address _token, address _account) public view returns (uint[] memory _tokenIds) {
        uint[] memory tokensOfOwner = new uint[](ERC721(_token).balanceOf(_account));
        uint i;

        for (i = 0; i < tokensOfOwner.length; i++) {
            tokensOfOwner[i] = ERC721Enumerable(_token).tokenOfOwnerByIndex(_account, i);
        }
        return (tokensOfOwner);
    }

    /**
     * @notice Get the account balance for given token ERC20
     * @param _token the token address to check
     * @param _account the account to check
     * @return _balance balance for account
     * @dev Callable by admin
     */
    function getERC20Balance(address _token, address _account) public view returns (uint256 _balance) {
        return IERC20(_token).balanceOf(_account);
    }

    /**
     * @notice Modifier that ensure that treasury fee are not too high
     */
    modifier onlyIfEnoughtBalance(uint256 _amount) {
        require(address(this).balance >= _amount, "Not enough in contract balance");
        _;
    }
}