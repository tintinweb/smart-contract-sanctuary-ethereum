// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./base/Controllable.sol";
import "sol-temple/src/tokens/ERC721.sol";
import "sol-temple/src/tokens/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Ape Runners RUN
/// @author naomsa <https://twitter.com/naomsa666>
contract ApeRunnersRUN is
  Ownable,
  Pausable,
  Controllable,
  ERC20("Ape Runners", "RUN", 18, "1")
{
  /* -------------------------------------------------------------------------- */
  /*                               Airdrop Details                              */
  /* -------------------------------------------------------------------------- */

  /// @notice Ape Runners contract.
  ERC721 public immutable apeRunners;

  /// @notice Ape Runner id => claimed airdrop.
  mapping(uint256 => bool) public airdroped;

  constructor(address newApeRunners) {
    apeRunners = ERC721(newApeRunners);
  }

  /* -------------------------------------------------------------------------- */
  /*                                Airdrop Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Claim pending airdrop for each Ape Runner.
  /// @param ids Ape Runner token ids to claim airdrop.
  function claim(uint256[] memory ids) external {
    uint256 pending;

    for (uint256 i; i < ids.length; i++) {
      require(apeRunners.ownerOf(ids[i]) == msg.sender, "Not the token owner");
      require(!airdroped[ids[i]], "Airdrop already claimed");
      airdroped[ids[i]] = true;
      pending += 300 ether;
    }

    super._mint(msg.sender, pending);
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Owner Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Add or edit contract controllers.
  /// @param addrs Array of addresses to be added/edited.
  /// @param state New controller state of addresses.
  function setControllers(address[] calldata addrs, bool state)
    external
    onlyOwner
  {
    for (uint256 i; i < addrs.length; i++)
      super._setController(addrs[i], state);
  }

  /// @notice Switch the contract paused state between paused and unpaused.
  function togglePaused() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }

  /* -------------------------------------------------------------------------- */
  /*                                ERC-20 Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Mint tokens.
  /// @param to Address to get tokens minted to.
  /// @param value Number of tokens to be minted.
  function mint(address to, uint256 value) external onlyController {
    super._mint(to, value);
  }

  /// @notice Burn tokens.
  /// @param from Address to get tokens burned from.
  /// @param value Number of tokens to be burned.
  function burn(address from, uint256 value) external onlyController {
    super._burn(from, value);
  }

  /// @notice See {ERC20-_beforeTokenTransfer}.
  /// @dev Overriden to block transactions while the contract is paused (avoiding bugs).
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// @title Controllable
abstract contract Controllable {
  /// @notice address => is controller.
  mapping(address => bool) private _isController;

  /// @notice Require the caller to be a controller.
  modifier onlyController() {
    require(
      _isController[msg.sender],
      "Controllable: Caller is not a controller"
    );
    _;
  }

  /// @notice Check if `addr` is a controller.
  function isController(address addr) public view returns (bool) {
    return _isController[addr];
  }

  /// @notice Set the `addr` controller status to `status`.
  function _setController(address addr, bool status) internal {
    _isController[addr] = status;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title ERC721
/// @author naomsa <https://twitter.com/naomsa666>
/// @notice A complete ERC721 implementation including metadata and enumerable
/// functions. Completely gas optimized and extensible.
abstract contract ERC721 is IERC165, IERC721, IERC721Metadata, IERC721Enumerable {
  /*         _           _            */
  /*        ( )_        ( )_          */
  /*    ___ | ,_)   _ _ | ,_)   __    */
  /*  /',__)| |   /'__` )| |   /'__`\  */
  /*  \__, \| |_ ( (_| || |_ (  ___/  */
  /*  (____/`\__)`\__,_)`\__)`\____)  */

  /// @notice See {ERC721Metadata-name}.
  string public name;

  /// @notice See {ERC721Metadata-symbol}.
  string public symbol;

  /// @notice See {ERC721Enumerable-totalSupply}.
  uint256 public totalSupply;

  /// @notice Array of all owners.
  mapping(uint256 => address) private _owners;

  /// @notice Mapping of all balances.
  mapping(address => uint256) private _balanceOf;

  /// @notice Mapping from token Id to it's approved address.
  mapping(uint256 => address) private _tokenApprovals;

  /// @notice Mapping of approvals between owner and operator.
  mapping(address => mapping(address => bool)) private _isApprovedForAll;

  /*   _                            */
  /*  (_ )                _         */
  /*   | |    _      __  (_)   ___  */
  /*   | |  /'_`\  /'_ `\| | /'___) */
  /*   | | ( (_) )( (_) || |( (___  */
  /*  (___)`\___/'`\__  |(_)`\____) */
  /*              ( )_) |           */
  /*               \___/'           */

  /// @dev Set token's name and symbol.
  constructor(string memory name_, string memory symbol_) {
    name = name_;
    symbol = symbol_;
  }

  /// @notice See {ERC721-balanceOf}.
  function balanceOf(address account_) public view virtual returns (uint256) {
    require(account_ != address(0), "ERC721: balance query for the zero address");
    return _balanceOf[account_];
  }

  /// @notice See {ERC721-ownerOf}.
  function ownerOf(uint256 tokenId_) public view virtual returns (address) {
    require(_exists(tokenId_), "ERC721: query for nonexistent token");
    address owner = _owners[tokenId_];
    return owner;
  }

  /// @notice See {ERC721Metadata-tokenURI}.
  function tokenURI(uint256) public view virtual returns (string memory);

  /// @notice See {ERC721-approve}.
  function approve(address to_, uint256 tokenId_) public virtual {
    address owner = ownerOf(tokenId_);
    require(to_ != owner, "ERC721: approval to current owner");

    require(
      msg.sender == owner || _isApprovedForAll[owner][msg.sender],
      "ERC721: caller is not owner nor approved for all"
    );

    _approve(to_, tokenId_);
  }

  /// @notice See {ERC721-getApproved}.
  function getApproved(uint256 tokenId_) public view virtual returns (address) {
    require(_exists(tokenId_), "ERC721: query for nonexistent token");
    return _tokenApprovals[tokenId_];
  }

  /// @notice See {ERC721-setApprovalForAll}.
  function setApprovalForAll(address operator_, bool approved_) public virtual {
    _setApprovalForAll(msg.sender, operator_, approved_);
  }

  /// @notice See {ERC721-isApprovedForAll}.
  function isApprovedForAll(address account_, address operator_) public view virtual returns (bool) {
    return _isApprovedForAll[account_][operator_];
  }

  /// @notice See {ERC721-transferFrom}.
  function transferFrom(
    address from_,
    address to_,
    uint256 tokenId_
  ) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId_), "ERC721: transfer caller is not owner nor approved");
    _transfer(from_, to_, tokenId_);
  }

  /// @notice See {ERC721-safeTransferFrom}.
  function safeTransferFrom(
    address from_,
    address to_,
    uint256 tokenId_
  ) public virtual {
    safeTransferFrom(from_, to_, tokenId_, "");
  }

  /// @notice See {ERC721-safeTransferFrom}.
  function safeTransferFrom(
    address from_,
    address to_,
    uint256 tokenId_,
    bytes memory data_
  ) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId_), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from_, to_, tokenId_, data_);
  }

  /// @notice See {ERC721Enumerable.tokenOfOwnerByIndex}.
  function tokenOfOwnerByIndex(address account_, uint256 index_) public view returns (uint256 tokenId) {
    require(index_ < balanceOf(account_), "ERC721Enumerable: Index out of bounds");
    uint256 count;
    for (uint256 i; i < totalSupply; ++i) {
      if (account_ == _owners[i]) {
        if (count == index_) return i;
        else count++;
      }
    }
    revert("ERC721Enumerable: Index out of bounds");
  }

  /// @notice See {ERC721Enumerable.tokenByIndex}.
  function tokenByIndex(uint256 index_) public view virtual returns (uint256) {
    require(index_ < totalSupply, "ERC721Enumerable: Index out of bounds");
    return index_;
  }

  /// @notice Returns a list of all token Ids owned by `owner`.
  function walletOfOwner(address account_) public view returns (uint256[] memory) {
    uint256 balance = balanceOf(account_);
    uint256[] memory ids = new uint256[](balance);

    for (uint256 i = 0; i < balance; i++) ids[i] = tokenOfOwnerByIndex(account_, i);
    return ids;
  }

  /*             _                               _    */
  /*   _        ( )_                            (_ )  */
  /*  (_)  ___  | ,_)   __   _ __   ___     _ _  | |  */
  /*  | |/' _ `\| |   /'__`\( '__)/' _ `\ /'__` ) | |  */
  /*  | || ( ) || |_ (  ___/| |   | ( ) |( (_| | | |  */
  /*  (_)(_) (_)`\__)`\____)(_)   (_) (_)`\__,_)(___) */

  /// @notice Safely transfers `tokenId_` token from `from_` to `to`, checking first that contract recipients
  /// are aware of the ERC721 protocol to prevent tokens from being forever locked.
  function _safeTransfer(
    address from_,
    address to_,
    uint256 tokenId_,
    bytes memory data_
  ) internal virtual {
    _transfer(from_, to_, tokenId_);
    _checkOnERC721Received(from_, to_, tokenId_, data_);
  }

  /// @notice Returns whether `tokenId_` exists.
  function _exists(uint256 tokenId_) internal view virtual returns (bool) {
    return tokenId_ < totalSupply && _owners[tokenId_] != address(0);
  }

  /// @notice Returns whether `spender_` is allowed to manage `tokenId`.
  function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal view virtual returns (bool) {
    require(_exists(tokenId_), "ERC721: query for nonexistent token");
    address owner = _owners[tokenId_];
    return (spender_ == owner || getApproved(tokenId_) == spender_ || isApprovedForAll(owner, spender_));
  }

  /// @notice Safely mints `tokenId_` and transfers it to `to`.
  function _safeMint(address to_, uint256 tokenId_) internal virtual {
    _safeMint(to_, tokenId_, "");
  }

  /// @notice Same as {_safeMint}, but with an additional `data_` parameter which is
  /// forwarded in {ERC721Receiver-onERC721Received} to contract recipients.
  function _safeMint(
    address to_,
    uint256 tokenId_,
    bytes memory data_
  ) internal virtual {
    _mint(to_, tokenId_);
    _checkOnERC721Received(address(0), to_, tokenId_, data_);
  }

  /// @notice Mints `tokenId_` and transfers it to `to_`.
  function _mint(address to_, uint256 tokenId_) internal virtual {
    require(!_exists(tokenId_), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to_, tokenId_);

    _owners[tokenId_] = to_;
    totalSupply++;
    unchecked {
      _balanceOf[to_]++;
    }

    emit Transfer(address(0), to_, tokenId_);
    _afterTokenTransfer(address(0), to_, tokenId_);
  }

  /// @notice Destroys `tokenId`. The approval is cleared when the token is burned.
  function _burn(uint256 tokenId_) internal virtual {
    address owner = ownerOf(tokenId_);

    _beforeTokenTransfer(owner, address(0), tokenId_);

    // Clear approvals
    _approve(address(0), tokenId_);

    totalSupply--;
    _balanceOf[owner]--;
    delete _owners[tokenId_];

    emit Transfer(owner, address(0), tokenId_);
    _afterTokenTransfer(owner, address(0), tokenId_);
  }

  /// @notice Transfers `tokenId_` from `from_` to `to`.
  function _transfer(
    address from_,
    address to_,
    uint256 tokenId_
  ) internal virtual {
    require(_owners[tokenId_] == from_, "ERC721: transfer of token that is not own");

    _beforeTokenTransfer(from_, to_, tokenId_);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId_);

    _owners[tokenId_] = to_;
    unchecked {
      _balanceOf[from_]--;
      _balanceOf[to_]++;
    }

    emit Transfer(from_, to_, tokenId_);
    _afterTokenTransfer(from_, to_, tokenId_);
  }

  /// @notice Approve `to_` to operate on `tokenId_`
  function _approve(address to_, uint256 tokenId_) internal virtual {
    _tokenApprovals[tokenId_] = to_;
    emit Approval(_owners[tokenId_], to_, tokenId_);
  }

  /// @notice Approve `operator_` to operate on all of `account_` tokens.
  function _setApprovalForAll(
    address account_,
    address operator_,
    bool approved_
  ) internal virtual {
    require(account_ != operator_, "ERC721: approve to caller");
    _isApprovedForAll[account_][operator_] = approved_;
    emit ApprovalForAll(account_, operator_, approved_);
  }

  /// @notice ERC721Receiver callback checking and calling helper.
  function _checkOnERC721Received(
    address from_,
    address to_,
    uint256 tokenId_,
    bytes memory data_
  ) private {
    if (to_.code.length > 0) {
      try IERC721Receiver(to_).onERC721Received(msg.sender, from_, tokenId_, data_) returns (bytes4 returned) {
        require(returned == 0x150b7a02, "ERC721: safe transfer to non ERC721Receiver implementation");
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: safe transfer to non ERC721Receiver implementation");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
  }

  /// @notice Hook that is called before any token transfer.
  function _beforeTokenTransfer(
    address from_,
    address to_,
    uint256 tokenId_
  ) internal virtual {}

  /// @notice Hook that is called after any token transfer.
  function _afterTokenTransfer(
    address from_,
    address to_,
    uint256 tokenId_
  ) internal virtual {}

  /*    ___  _   _  _ _      __   _ __  */
  /*  /',__)( ) ( )( '_`\  /'__`\( '__) */
  /*  \__, \| (_) || (_) )(  ___/| |    */
  /*  (____/`\___/'| ,__/'`\____)(_)    */
  /*               | |                  */
  /*               (_)                  */

  /// @notice See {ERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId_) public view virtual returns (bool) {
    return
      interfaceId_ == type(IERC721).interfaceId || // ERC721
      interfaceId_ == type(IERC721Metadata).interfaceId || // ERC721Metadata
      interfaceId_ == type(IERC721Enumerable).interfaceId || // ERC721Enumerable
      interfaceId_ == type(IERC165).interfaceId; // ERC165
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/**
 * @title ERC20
 * @author naomsa <https://twitter.com/naomsa666>
 * @notice A complete ERC20 implementation including EIP-2612 permit feature.
 * Inspired by Solmate's ERC20, aiming at efficiency.
 */
abstract contract ERC20 is IERC20 {
  /*         _           _            */
  /*        ( )_        ( )_          */
  /*    ___ | ,_)   _ _ | ,_)   __    */
  /*  /',__)| |   /'_` )| |   /'__`\  */
  /*  \__, \| |_ ( (_| || |_ (  ___/  */
  /*  (____/`\__)`\__,_)`\__)`\____)  */

  /// @notice See {ERC20-name}.
  string public name;

  /// @notice See {ERC20-symbol}.
  string public symbol;

  /// @notice See {ERC20-decimals}.
  uint8 public immutable decimals;

  /// @notice Used to hash the Domain Separator.
  string public version;

  /// @notice See {ERC20-totalSupply}.
  uint256 public totalSupply;

  /// @notice See {ERC20-balanceOf}.
  mapping(address => uint256) public balanceOf;

  /// @notice See {ERC20-allowance}.
  mapping(address => mapping(address => uint256)) public allowance;

  /// @notice See {ERC2612-nonces}.
  mapping(address => uint256) public nonces;

  /*   _                            */
  /*  (_ )                _         */
  /*   | |    _      __  (_)   ___  */
  /*   | |  /'_`\  /'_ `\| | /'___) */
  /*   | | ( (_) )( (_) || |( (___  */
  /*  (___)`\___/'`\__  |(_)`\____) */
  /*              ( )_) |           */
  /*               \___/'           */

  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    string memory version_
  ) {
    name = name_;
    symbol = symbol_;
    decimals = decimals_;
    version = version_;
  }

  /// @notice See {ERC20-transfer}.
  function transfer(address to_, uint256 value_) public returns (bool) {
    _transfer(msg.sender, to_, value_);
    return true;
  }

  /// @notice See {ERC20-transferFrom}.
  function transferFrom(
    address from_,
    address to_,
    uint256 value_
  ) public returns (bool) {
    uint256 allowed = allowance[from_][msg.sender];
    require(allowed >= value_, "ERC20: allowance exceeds transfer value");
    if (allowed != type(uint256).max) allowance[from_][msg.sender] -= value_;

    _transfer(from_, to_, value_);
    return true;
  }

  /// @notice See {ERC20-approve}.
  function approve(address spender_, uint256 value_) public returns (bool) {
    _approve(msg.sender, spender_, value_);
    return true;
  }

  /// @notice See {ERC2612-DOMAIN_SEPARATOR}.
  function DOMAIN_SEPARATOR() public view returns (bytes32) {
    return _hashEIP712Domain(name, version, block.chainid, address(this));
  }

  /// @notice See {ERC2612-permit}.
  function permit(
    address owner_,
    address spender_,
    uint256 value_,
    uint256 deadline_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_
  ) public {
    require(deadline_ >= block.timestamp, "ERC20: expired permit deadline");

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 digest = _hashEIP712Message(
      DOMAIN_SEPARATOR(),
      keccak256(
        abi.encode(
          0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9,
          owner_,
          spender_,
          value_,
          nonces[owner_]++,
          deadline_
        )
      )
    );

    address signer = ecrecover(digest, v_, r_, s_);
    require(signer != address(0) && signer == owner_, "ERC20: invalid signature");

    _approve(owner_, spender_, value_);
  }

  /*             _                               _    */
  /*   _        ( )_                            (_ )  */
  /*  (_)  ___  | ,_)   __   _ __   ___     _ _  | |  */
  /*  | |/' _ `\| |   /'__`\( '__)/' _ `\ /'_` ) | |  */
  /*  | || ( ) || |_ (  ___/| |   | ( ) |( (_| | | |  */
  /*  (_)(_) (_)`\__)`\____)(_)   (_) (_)`\__,_)(___) */

  /// @notice Internal transfer helper. Throws if `value_` exceeds `from_` balance.
  function _transfer(
    address from_,
    address to_,
    uint256 value_
  ) internal {
    require(balanceOf[from_] >= value_, "ERC20: insufficient balance");
    _beforeTokenTransfer(from_, to_, value_);

    unchecked {
      balanceOf[from_] -= value_;
      balanceOf[to_] += value_;
    }

    emit Transfer(from_, to_, value_);
    _afterTokenTransfer(from_, to_, value_);
  }

  /// @notice Internal approve helper.
  function _approve(
    address owner_,
    address spender_,
    uint256 value_
  ) internal {
    allowance[owner_][spender_] = value_;
    emit Approval(owner_, spender_, value_);
  }

  /// @notice Internal minting logic.
  function _mint(address to_, uint256 value_) internal {
    _beforeTokenTransfer(address(0), to_, value_);

    totalSupply += value_;
    unchecked {
      balanceOf[to_] += value_;
    }

    emit Transfer(address(0), to_, value_);
    _afterTokenTransfer(address(0), to_, value_);
  }

  /// @notice Internal burning logic.
  function _burn(address from_, uint256 value_) internal {
    _beforeTokenTransfer(from_, address(0), value_);
    require(balanceOf[from_] >= value_, "ERC20: burn value exceeds balance");

    unchecked {
      balanceOf[from_] -= value_;
      totalSupply -= value_;
    }

    emit Transfer(from_, address(0), value_);
    _afterTokenTransfer(from_, address(0), value_);
  }

  /**
   * @notice EIP721 domain hashing helper.
   * @dev Modified from https://github.com/0xProject/0x-monorepo/blob/development/contracts/utils/contracts/src/LibEIP712.sol
   */
  function _hashEIP712Domain(
    string memory name_,
    string memory version_,
    uint256 chainId_,
    address verifyingContract_
  ) private pure returns (bytes32) {
    bytes32 result;
    assembly {
      // Calculate hashes of dynamic data
      let nameHash := keccak256(add(name_, 32), mload(name_))
      let versionHash := keccak256(add(version_, 32), mload(version_))

      // Load free memory pointer
      let memPtr := mload(64)

      // Store params in memory
      mstore(memPtr, 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f)
      mstore(add(memPtr, 32), nameHash)
      mstore(add(memPtr, 64), versionHash)
      mstore(add(memPtr, 96), chainId_)
      mstore(add(memPtr, 128), verifyingContract_)

      // Compute hash
      result := keccak256(memPtr, 160)
    }
    return result;
  }

  /**
   * @notice EIP721 typed message hashing helper.
   * @dev Modified from https://github.com/0xProject/0x-monorepo/blob/development/contracts/utils/contracts/src/LibEIP712.sol
   */
  function _hashEIP712Message(bytes32 domainSeparator_, bytes32 hash_) private pure returns (bytes32) {
    bytes32 result;
    assembly {
      // Load free memory pointer
      let memPtr := mload(64)

      mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000) // EIP191 header
      mstore(add(memPtr, 2), domainSeparator_) // EIP712 domain hash
      mstore(add(memPtr, 34), hash_) // Hash of struct

      // Compute hash
      result := keccak256(memPtr, 66)
    }
    return result;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 value
  ) internal virtual {}

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 value
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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