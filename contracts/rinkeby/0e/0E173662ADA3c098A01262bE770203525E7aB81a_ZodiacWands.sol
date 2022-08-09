//      ****           *                 **                                       ***** *    **   ***                                 **
//     *  *************                   **     *                             ******  *  *****    ***                                 **
//    *     **********                    **    ***                           **   *  *     *****   ***                                **
//    *             *                     **     *                           *    *  **     * **      **                               **
//     **          *        ****          **                                     *  ***     *         **                               **      ****
//                *        * ***  *   *** **   ***        ****       ****       **   **     *         **    ****    ***  ****      *** **     * **** *
//               *        *   ****   *********  ***      * ***  *   * ***  *    **   **     *         **   * ***  *  **** **** *  *********  **  ****
//              *        **    **   **   ****    **     *   ****   *   ****     **   **     *         **  *   ****    **   ****  **   ****  ****
//             *         **    **   **    **     **    **    **   **            **   **     *         ** **    **     **    **   **    **     ***
//            *          **    **   **    **     **    **    **   **            **   **     *         ** **    **     **    **   **    **       ***
//           *           **    **   **    **     **    **    **   **             **  **     *         ** **    **     **    **   **    **         ***
//          *            **    **   **    **     **    **    **   **              ** *      *         *  **    **     **    **   **    **    ****  **
//      ****           *  ******    **    **     **    **    **   ***     *        ***      ***      *   **    **     **    **   **    **   * **** *
//     *  *************    ****      *****       *** *  ***** **   *******          ******** ********     ***** **    ***   ***   *****        ****
//    *     **********                ***         ***    ***   **   *****             ****     ****        ***   **    ***   ***   ***
//
//
//                              ...             ...
//                             .*%&*..       .,*&&*.
//                            .*%&&&&&/*,,,*/%&&%&&*.
//               ,         ..,%%&&%%&#/*,.,*/%&&%&&&(,..
//                ,%&%////%%/,,,*/%&%*.     .*&%%/*,,,(%%////#&%,
//                .*%&%&&&(,. .   .,%.,     ,.#,.   . .*#&&%%&&*.
//                .*%&&&&&%,.                         .,%&%&&&&*.                       ‘O most honored Greening Force, You who roots in the Sun;
//               .,##***,**#.     .    .*%,.    ..    ,%**,,**&(,                        You who lights up, in shining serenity, within a wheel
//             .,*&*.            ,.,.,,*//**,.,..            ..*%*,.                     that earthly excellence fails to comprehend.
//        .,*/%&&&#/,   ,   .  .*,/((###%%%#####/,,.      .   ./&&&%(**,.
//        .,/%&%&#%&#*..     .,,//((#%&&&&&%%%%%###,,.     ,.*%&&&%&%&*,.                You are enfolded
//          .,(%&%(*,,..    ,,**//(((##%&&&&&%%%%###,/,    ..,,*(#%&(,.                  in the weaving of divine mysteries.
//           .,%/,.     ,  ,,,**///((####%%&&%&%%%###,,         .,#%,
//            ,%*.         ,,,(((///(((#####%%%%%##%#,,          ,/#,                    You redden like the dawn
//           ,/&%(*,..,  .  ,.**(/////@((((((#####&#*.,     ...,*#&%*,                   and you burn: flame of the Sun.”
//         .*&&%&#%&&(,.     ,.*////////&/(/((((#%%*.,     .,%%%&&%&&#*.
//       /((%%&&&&&/,         .,.*(((((///(((#(#(*.,,        .*/%&&&&&%##,               –  Hildegard von Bingen, Causae et Curae
//            .,*%%*.,.          ,,.,*(((((((*,.,,          . .*&#*..
//               .*%*,.....*.        ,,*/%#*,    ,    .......,*%*.
//                .*&%&%%(,.         .,*,(/(,,         .,%&&&&%*.
//                .*&&&*,           ..,*(#//, .    .     .,/#%%,.
//                .#/,.       .       .**#/*.       .       .,%*.
//                                    .**#/,.              .
//                                    .,./*,,

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IZodiacWands.sol";
import "./interfaces/IForge.sol";
import "./interfaces/IConjuror.sol";
import "./WandUnpacker.sol";

contract ZodiacWands is IZodiacWands, ERC721, Ownable {
  IForge public forge;
  IConjuror public conjuror;

  uint256 internal nextTokenId;
  mapping(uint256 => PackedWand) internal wands;

  event WandBuilt(
    uint256 indexed tokenId,
    uint16 stone,
    uint8 handle,
    uint16 halo,
    uint64 background,
    uint128 planets,
    uint256 aspects
  );

  constructor(IConjuror _conjuror) ERC721("ZodiacWands", "WAND") {
    conjuror = _conjuror;
  }

  function mint(
    uint16 stone,
    uint16 halo,
    uint8 handle,
    uint64 background,
    uint128 planets,
    uint256 aspects,
    uint8 visibility
  ) external override returns (uint256) {
    uint256 tokenId = nextTokenId++;
    _safeMint(msg.sender, tokenId);

    wands[tokenId] = PackedWand({
      background: background,
      birth: uint64(block.timestamp),
      planets: planets,
      aspects: aspects,
      stone: stone,
      halo: halo,
      visibility: visibility,
      handle: handle
    });

    emit WandBuilt(tokenId, stone, handle, halo, background, planets, aspects);
    return tokenId;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(ERC721._exists(tokenId), "Wands: URI query for nonexistent token");
    return conjuror.generateWandURI(unpack(tokenId));
  }

  function unpack(uint256 tokenId) internal view returns (Wand memory) {
    Wand memory wand = WandUnpacker.unpack(tokenId, wands[tokenId]);
    wand.xp = address(forge) != address(0)
      ? forge.xp(ERC721.ownerOf(tokenId))
      : 0;
    wand.level = address(forge) != address(0) ? forge.level(tokenId) : 0;

    return wand;
  }

  function setForge(IForge _forge) external onlyOwner {
    forge = _forge;
  }

  function setConjuror(IConjuror _conjuror) external onlyOwner {
    conjuror = _conjuror;
  }
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Types.sol";

interface IZodiacWands is IERC721 {
  function mint(
    uint16 stone,
    uint16 halo,
    uint8 handle,
    uint64 background,
    uint128 planets,
    uint256 aspects,
    uint8 visibility
  ) external returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface IForge {
  struct Character {
    uint256 XP;
    uint256 XPAssigned;
  }

  function level(uint256 tokenId) external view returns (uint32);

  function xp(address avatar) external view returns (uint32);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./Types.sol";

interface IConjuror {
  function generateWandURI(Wand memory wand)
    external
    view
    returns (string memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "./Template.sol";
import "./interfaces/Types.sol";

 // Note this library gets inlined because all methods are internal.
 // changing any of the methods from internal will require tooling adjustments

library WandUnpacker {
  function unpack(uint256 tokenId, PackedWand memory packedWand)
    internal
    pure
    returns (Wand memory)
  {
    Template.Background memory background = unpackBackground(
      packedWand.background
    );
    Template.Halo memory halo = unpackHalo(packedWand.halo);
    halo.hue = (background.color.hue + 180) % 360;

    return
      Wand({
        tokenId: tokenId,
        stone: packedWand.stone,
        halo: halo,
        birth: packedWand.birth,
        handle: unpackHandle(packedWand.handle),
        background: background,
        planets: unpackPlanets(packedWand.planets, packedWand.visibility),
        aspects: unpackAspects(packedWand.aspects),
        xp:0,
        level: 0
      });
  }

  function unpackPlanets(uint128 packedPlanets, uint8 packedVisibility)
    internal
    pure
    returns (Planet[8] memory planets)
  {
    for (uint256 i = 0; i < 8; i++) {
      uint256 chunk = packedPlanets >> (16 * i);
      int8 x = int8(uint8(chunk));
      int8 y = int8(uint8(chunk >> 8));
      bool visible = packedVisibility & (1 << i) != 0;

      planets[i] = Planet({x: x, y: y, visible: visible});
    }
  }

  function unpackAspects(uint256 packedAspects)
    internal
    pure
    returns (Aspect[8] memory aspects)
  {
    for (uint256 i = 0; i < 8; i++) {
      uint256 chunk = packedAspects >> (i * 32);
      int8 x1 = int8(uint8(chunk));
      int8 y1 = int8(uint8(chunk >> 8));
      int8 x2 = int8(uint8(chunk >> 16));
      int8 y2 = int8(uint8(chunk >> 24));
      aspects[i] = Aspect({x1: x1, y1: y1, x2: x2, y2: y2});
    }
  }

  function unpackBackground(uint64 packedBackground)
    internal
    pure
    returns (Template.Background memory background)
  {
    background.radial = (packedBackground & 0x0001) != 0;
    background.dark = (packedBackground & 0x0002) != 0;
    background.color.saturation = uint8(packedBackground >> 2);
    background.color.lightness = uint8(packedBackground >> 10);
    background.color.hue = uint16(packedBackground >> 18);
  }

  function unpackHalo(uint16 packedHalo)
    internal
    pure
    returns (Template.Halo memory halo)
  {
    bool[24] memory rhythm;
    for (uint256 i = 0; i < 24; i++) {
      uint256 bit = i > 12 ? 24 - i : i;
      rhythm[i] = ((1 << bit) & (packedHalo >> 3)) != 0;
    }
    uint8 shape = uint8(packedHalo) & 0x07;

    return
      Template.Halo({
        halo0: shape == 0,
        halo1: shape == 1,
        halo2: shape == 2,
        halo3: shape == 3,
        halo4: shape == 4,
        halo5: shape == 5,
        hue: 0, //(wand.background.color.hue + 180) % 360,
        rhythm: rhythm
      });
  }

  function unpackHandle(uint8 packedHandle)
    internal
    pure
    returns (Template.Handle memory handle)
  {
    return
      Template.Handle({
        handle0: packedHandle == 0,
        handle1: packedHandle == 1,
        handle2: packedHandle == 2,
        handle3: packedHandle == 3
      });
  }
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "../Template.sol";

struct Aspect {
  int8 x1;
  int8 y1;
  int8 x2;
  int8 y2;
}

struct Planet {
  bool visible;
  int8 x;
  int8 y;
}

struct Wand {
  uint256 tokenId;
  uint64 birth;
  uint16 stone;
  Template.Halo halo;
  Template.Handle handle;
  Template.Background background;
  Planet[8] planets;
  Aspect[8] aspects;
  uint32 xp;
  uint32 level;
}

struct PackedWand {
  // order matters !!
  uint64 background;
  uint64 birth;
  uint128 planets;
  uint256 aspects;
  // background
  uint16 stone;
  uint16 halo;
  uint8 visibility;
  uint8 handle;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

string constant __constant0 = '%, 0)"/> </radialGradient> <circle style="fill:url(#grad0)" cx="1000" cy="1925" r="1133"/> <circle style="fill:url(#grad0)" cx="1000" cy="372" r="1133"/> ';

library Template {
  struct __Input {
    Handle handle;
    Background background;
    Xp xp;
    Stone stone;
    uint256 seed;
    Halo halo;
    Planet[8] planets;
    Aspect[8] aspects;
    FilterLayer[3] filterLayers;
    Frame frame;
    Sparkle[] sparkles;
  }

  struct FilterLayer {
    bool fractalNoise;
    uint8 turbFreqX;
    uint8 turbFreqY;
    uint8 turbOct;
    uint8 turbBlur;
    uint8 dispScale;
    uint8 blurX;
    uint8 blurY;
    uint8 specExponent;
    uint8 opacity;
    int16 surfaceScale;
    uint16 specConstant;
    int16 pointX;
    int16 pointY;
    int16 pointZ;
    Color lightColor;
  }

  struct Color {
    uint8 saturation;
    uint8 lightness;
    uint16 hue;
  }

  struct LightColor {
    uint8 saturation;
    uint8 lightness;
    uint16 hue;
  }

  struct Background {
    bool radial;
    bool dark;
    Color color;
  }

  struct Xp {
    bool crown;
    uint32 amount;
    uint32 cap;
  }

  struct Stone {
    bool fractalNoise;
    uint8 turbFreqX;
    uint8 turbFreqY;
    uint8 turbOct;
    int8 redAmp;
    int8 redExp;
    int8 redOff;
    int8 greenAmp;
    int8 greenExp;
    int8 greenOff;
    int8 blueAmp;
    int8 blueExp;
    int8 blueOff;
    uint16 rotation;
  }

  struct Frame {
    bool level1;
    bool level2;
    bool level3;
    bool level4;
    bool level5;
    string title;
  }

  struct Halo {
    bool halo0;
    bool halo1;
    bool halo2;
    bool halo3;
    bool halo4;
    bool halo5;
    uint16 hue;
    bool[24] rhythm;
  }

  struct Handle {
    bool handle0;
    bool handle1;
    bool handle2;
    bool handle3;
  }

  struct Aspect {
    int16 x1;
    int16 y1;
    int16 x2;
    int16 y2;
  }

  struct Planet {
    bool visible;
    int16 x;
    int16 y;
  }

  struct Sparkle {
    uint8 scale;
    uint16 tx;
    uint16 ty;
  }

  function render(__Input memory __input)
    public
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2000 3000" shape-rendering="geometricPrecision" > <style type="text/css"> .bc{fill:none;stroke:#8BA0A5;} </style>',
        BackgroundLayer.filter(__input),
        BackgroundLayer.background(__input.background),
        BackgroundLayer.xpBar(__input.xp),
        BackgroundLayer.stars(__input),
        stone(__input),
        FrameLayer.frame(__input.frame),
        halo(__input.halo),
        HandleLayer.handles(__input.handle),
        birthchart(__input),
        sparkle(__input),
        "</svg>"
      )
    );
  }

  function stone(__Input memory __input)
    internal
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<filter id="s"> <feTurbulence ',
        __input.stone.fractalNoise ? 'type="fractalNoise"' : "",
        ' baseFrequency="',
        SolidMustacheHelpers.uintToString(__input.stone.turbFreqX, 3),
        " ",
        SolidMustacheHelpers.uintToString(__input.stone.turbFreqY, 3),
        '" numOctaves="',
        SolidMustacheHelpers.uintToString(__input.stone.turbOct, 0),
        '" seed="',
        SolidMustacheHelpers.uintToString(__input.seed, 0),
        '" /> <feComponentTransfer> <feFuncR type="gamma" amplitude="',
        SolidMustacheHelpers.intToString(__input.stone.redAmp, 2),
        '" exponent="',
        SolidMustacheHelpers.intToString(__input.stone.redExp, 2),
        '" offset="',
        SolidMustacheHelpers.intToString(__input.stone.redOff, 2)
      )
    );
    __result = string(
      abi.encodePacked(
        __result,
        '" /> <feFuncG type="gamma" amplitude="',
        SolidMustacheHelpers.intToString(__input.stone.greenAmp, 2),
        '" exponent="',
        SolidMustacheHelpers.intToString(__input.stone.greenExp, 2),
        '" offset="',
        SolidMustacheHelpers.intToString(__input.stone.greenOff, 2),
        '" /> <feFuncB type="gamma" amplitude="',
        SolidMustacheHelpers.intToString(__input.stone.blueAmp, 2),
        '" exponent="',
        SolidMustacheHelpers.intToString(__input.stone.blueExp, 2),
        '" offset="',
        SolidMustacheHelpers.intToString(__input.stone.blueOff, 2),
        '" /> <feFuncA type="discrete" tableValues="1"/> </feComponentTransfer> <feComposite operator="in" in2="SourceGraphic" result="tex" /> ',
        ' <feGaussianBlur in="SourceAlpha" stdDeviation="30" result="glow" /> <feColorMatrix in="glow" result="bgg" type="matrix" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 .8 0 " /> <feMerge> <feMergeNode in="bgg"/> <feMergeNode in="tex"/> </feMerge> </filter> <radialGradient id="ss"> <stop offset="0%" stop-color="hsla(0, 0%, 0%, 0)"/> <stop offset="90%" stop-color="hsla(0, 0%, 0%, .8)"/> </radialGradient> <defs> ',
        ' <clipPath id="sc"> <circle cx="1000" cy="1060" r="260"/> </clipPath> </defs> ',
        ' <circle transform="rotate('
      )
    );
    __result = string(
      abi.encodePacked(
        __result,
        SolidMustacheHelpers.uintToString(__input.stone.rotation, 0),
        ', 1000, 1060)" cx="1000" cy="1060" r="260" filter="url(#s)" /> ',
        ' <circle cx="1200" cy="1060" r="520" fill="url(#ss)" clip-path="url(#sc)" /> <defs> <radialGradient id="sf" cx="606.78" cy="1003.98" fx="606.78" fy="1003.98" r="2" gradientTransform="translate(-187630.67 -88769.1) rotate(-33.42) scale(178.04 178.05)" gradientUnits="userSpaceOnUse" > <stop offset=".05" stop-color="#fff" stop-opacity=".7"/> <stop offset=".26" stop-color="#ececec" stop-opacity=".5"/> <stop offset=".45" stop-color="#c4c4c4" stop-opacity=".5"/> <stop offset=".63" stop-color="#929292" stop-opacity=".5"/> <stop offset=".83" stop-color="#7b7b7b" stop-opacity=".5"/> <stop offset="1" stop-color="#cbcbca" stop-opacity=".5"/> </radialGradient> <radialGradient id="sh" cx="1149" cy="2660" fx="1149" fy="2660" r="76" gradientTransform="translate(312 2546) rotate(-20) scale(1 -.5)" gradientUnits="userSpaceOnUse" > <stop offset="0" stop-color="#fff" stop-opacity=".7"/> <stop offset="1" stop-color="#fff" stop-opacity="0"/> </radialGradient> </defs> <path fill="url(#sf)" d="M1184 876a260 260 0 1 1-368 368 260 260 0 0 1 368-368Z"/> <path fill="url(#sh)" d="M919 857c49-20 96-15 107 11 10 26-21 62-70 82s-97 14-107-12c-10-25 21-62 70-81Z"/>'
      )
    );
  }

  function halo(Halo memory __input)
    internal
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<defs> <g id="halo" filter="url(#ge)"> <path d="',
        __input.halo0
          ? "m0 0 114 425c-40-153-6-231 93-231 100 0 134 78 93 231L414 0c-31 116-103 174-207 174C104 174 32 116 0 0Z"
          : "",
        __input.halo1
          ? "M211 0q-29 217-106 215Q29 217 0 0l55 420q-21-164 50-165 72 1 50 165Z"
          : "",
        __input.halo2
          ? "M171 0q0 115 171 162l-10 39q-161-39-161 219 0-258-160-219L1 162Q171 115 171 0Z"
          : "",
        __input.halo3
          ? "M193 0c0 25-96 52-192 79l10 39c90-21 182-7 182 42 0-49 93-63 183-42l10-39C290 52 193 25 193 0Z"
          : "",
        __input.halo4
          ? "m1 244 23 76c73-22 154-25 228-8L323 0q-48 209-206 222A521 521 0 0 0 1 244Z"
          : "",
        __input.halo5
          ? "M157 46Q136 199 50 201c-16 0-33 2-49 4l10 79a442 442 0 0 1 115 0Z"
          : "",
        '" fill="hsl(',
        SolidMustacheHelpers.uintToString(__input.hue, 0),
        ', 10%, 64%)" style="transform: translateX(-50%); transform-box: fill-box;" /> '
      )
    );
    if (__input.halo4) {
      __result = string(
        abi.encodePacked(
          __result,
          ' <circle fill="hsl(',
          SolidMustacheHelpers.uintToString(__input.hue, 0),
          ', 10%, 64%)" cx="0" cy="80" r="40"/> '
        )
      );
    }
    __result = string(abi.encodePacked(__result, " "));
    if (__input.halo5) {
      __result = string(
        abi.encodePacked(
          __result,
          ' <circle fill="hsl(',
          SolidMustacheHelpers.uintToString(__input.hue, 0),
          ', 10%, 64%)" cx="0" cy="60" r="40"/> '
        )
      );
    }
    __result = string(
      abi.encodePacked(
        __result,
        " </g> </defs> ",
        ' <g transform="translate(1000 1060)"> '
      )
    );
    for (uint256 __i; __i < __input.rhythm.length; __i++) {
      __result = string(abi.encodePacked(__result, " "));
      if (__input.rhythm[__i]) {
        __result = string(
          abi.encodePacked(
            __result,
            ' <g style="transform: rotate(calc(',
            SolidMustacheHelpers.uintToString(__i, 0),
            " * 15deg)) translateY(",
            __input.halo0 ? "-770px" : "",
            __input.halo1 ? "-800px" : "",
            __input.halo2 ? "-800px" : "",
            __input.halo3 ? "-800px" : "",
            __input.halo4 ? "-740px" : "",
            __input.halo5 ? "-720px" : "",
            ');" ><use href="#halo"/></g> '
          )
        );
      }
      __result = string(abi.encodePacked(__result, " "));
    }
    __result = string(abi.encodePacked(__result, " </g>"));
  }

  function birthchart(__Input memory __input)
    internal
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<g transform="translate(1000 1060)"> <defs> <radialGradient id="ag" cx="0" cy="0" r="1" gradientTransform="translate(.5 .5)" > <stop stop-color="#FFFCFC" stop-opacity=".7"/> <stop offset="1" stop-color="#534E41" stop-opacity=".6"/> </radialGradient> <clipPath id="ac"><circle cx="0" cy="0" r="260"/></clipPath> <filter id="pb"><feGaussianBlur stdDeviation="4"/></filter> <style> .p0 { fill: #FFF6F2 } .p1 { fill: #FFFCF0 } .p2 { fill: #FFEDED } .p3 { fill: #FFEEF4 } .p4 { fill: #FFF3E9 } .p5 { fill: #ECFDFF } .p6 { fill: #EEF7FF } .p7 { fill: #F8F0FF } </style> </defs> '
      )
    );
    for (uint256 __i; __i < __input.aspects.length; __i++) {
      __result = string(
        abi.encodePacked(
          __result,
          ' <path d="M',
          SolidMustacheHelpers.intToString(__input.aspects[__i].x1, 0),
          ",",
          SolidMustacheHelpers.intToString(__input.aspects[__i].y1, 0),
          " L",
          SolidMustacheHelpers.intToString(__input.aspects[__i].x2, 0),
          ",",
          SolidMustacheHelpers.intToString(__input.aspects[__i].y2, 0),
          ' m25,25" stroke="url(#ag)" stroke-width="8" clip-path="url(#ac)" /> '
        )
      );
    }
    __result = string(abi.encodePacked(__result, ' <g filter="url(#pb)"> '));
    for (uint256 __i2; __i2 < __input.planets.length; __i2++) {
      __result = string(abi.encodePacked(__result, " "));
      if (__input.planets[__i2].visible) {
        __result = string(
          abi.encodePacked(
            __result,
            '<circle cx="',
            SolidMustacheHelpers.intToString(__input.planets[__i2].x, 0),
            '" cy="',
            SolidMustacheHelpers.intToString(__input.planets[__i2].y, 0),
            '" class="p',
            SolidMustacheHelpers.uintToString(__i2, 0),
            '" r="11"/>'
          )
        );
      }
      __result = string(abi.encodePacked(__result, " "));
    }
    __result = string(abi.encodePacked(__result, " </g> </g>"));
  }

  function sparkle(__Input memory __input)
    internal
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<defs> <style type="text/css"> .sp { fill: white } </style> <symbol id="sp" viewBox="0 0 250 377"> <path class="sp" d="m4 41 121 146 125 2-122 2 118 146-121-146-125-2 122-2L4 41Z"/> <path class="sp" d="m105 0 21 185 86-83-86 88 18 187-20-185-87 84 87-88L105 0Z"/> </symbol> </defs> <g filter="url(#bb)" style="opacity: .6"> '
      )
    );
    for (uint256 __i; __i < __input.sparkles.length; __i++) {
      __result = string(
        abi.encodePacked(
          __result,
          ' <use width="250" height="377" transform="translate(',
          SolidMustacheHelpers.uintToString(__input.sparkles[__i].tx, 0),
          " ",
          SolidMustacheHelpers.uintToString(__input.sparkles[__i].ty, 0),
          ") scale(",
          SolidMustacheHelpers.uintToString(__input.sparkles[__i].scale, 2),
          ')" href="#sp" /> '
        )
      );
    }
    __result = string(abi.encodePacked(__result, " </g>"));
  }
}

library BackgroundLayer {
  function filter(Template.__Input memory __input)
    external
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<defs> <filter color-interpolation-filters="sRGB" id="ge" width="250%" height="250%" x="-75%" y="-55%" > <feGaussianBlur in="SourceAlpha" result="alphablur" stdDeviation="8" /> ',
        ' <feGaussianBlur in="SourceAlpha" stdDeviation="30" result="fg" /> <feColorMatrix in="fg" result="bgg" type="matrix" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0 " /> ',
        " "
      )
    );
    for (uint256 __i; __i < __input.filterLayers.length; __i++) {
      __result = string(
        abi.encodePacked(
          __result,
          " <feTurbulence ",
          __input.filterLayers[__i].fractalNoise ? 'type="fractalNoise"' : "",
          ' baseFrequency="',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].turbFreqX,
            3
          ),
          " ",
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].turbFreqY,
            3
          ),
          '" numOctaves="',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].turbOct,
            0
          ),
          '" seed="',
          SolidMustacheHelpers.uintToString(__input.seed, 0),
          '" result="t',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" /> <feGaussianBlur stdDeviation="',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].turbBlur,
            1
          ),
          '" in="SourceAlpha" result="tb',
          SolidMustacheHelpers.uintToString(__i, 0)
        )
      );
      __result = string(
        abi.encodePacked(
          __result,
          '" /> <feDisplacementMap scale="',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].dispScale,
            0
          ),
          '" in="tb',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" in2="t',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" result="dt',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" /> <feColorMatrix type="matrix" values="0 0 0 0 0, 0 0 0 0 0, 0 0 0 0 0, 0 0 0 1 0" in="dt',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" result="cm',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" /> <feGaussianBlur stdDeviation="',
          SolidMustacheHelpers.uintToString(__input.filterLayers[__i].blurX, 1),
          " ",
          SolidMustacheHelpers.uintToString(__input.filterLayers[__i].blurY, 1)
        )
      );
      __result = string(
        abi.encodePacked(
          __result,
          '" in="cm',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" result="bcm',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" /> <feSpecularLighting surfaceScale="',
          SolidMustacheHelpers.intToString(
            __input.filterLayers[__i].surfaceScale,
            0
          ),
          '" specularConstant="',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].specConstant,
            2
          ),
          '" specularExponent="',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].specExponent,
            0
          ),
          '" lighting-color="hsl(',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].lightColor.hue,
            0
          ),
          ", ",
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].lightColor.saturation,
            0
          ),
          "%, ",
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].lightColor.lightness,
            0
          )
        )
      );
      __result = string(
        abi.encodePacked(
          __result,
          '%)" in="bcm',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" result="l',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" > <fePointLight x="',
          SolidMustacheHelpers.intToString(__input.filterLayers[__i].pointX, 0),
          '" y="',
          SolidMustacheHelpers.intToString(__input.filterLayers[__i].pointY, 0),
          '" z="',
          SolidMustacheHelpers.intToString(__input.filterLayers[__i].pointZ, 0),
          '"/> </feSpecularLighting> <feComposite operator="in" in="l',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" in2="cm',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" result="cl1',
          SolidMustacheHelpers.uintToString(__i, 0)
        )
      );
      __result = string(
        abi.encodePacked(
          __result,
          '" /> <feComposite operator="arithmetic" k1="0" k2="0" k3="',
          SolidMustacheHelpers.uintToString(
            __input.filterLayers[__i].opacity,
            2
          ),
          '" k4="0" in="dt',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" in2="cl1',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" result="cl2',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" /> <feComposite operator="in" in2="SourceAlpha" in="cl2',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" result="clf',
          SolidMustacheHelpers.uintToString(__i, 0),
          '" /> '
        )
      );
    }
    __result = string(
      abi.encodePacked(
        __result,
        ' <feMerge> <feMergeNode in="bgg"/> <feMergeNode in="SourceGraphic"/> '
      )
    );
    for (uint256 __i2; __i2 < __input.filterLayers.length; __i2++) {
      __result = string(
        abi.encodePacked(
          __result,
          ' <feMergeNode in="clf',
          SolidMustacheHelpers.uintToString(__i2, 0),
          '"/> '
        )
      );
    }
    __result = string(
      abi.encodePacked(
        __result,
        ' </feMerge> </filter> <filter id="bb"> <feGaussianBlur in="SourceGraphic" stdDeviation="2"/> </filter> </defs>'
      )
    );
  }

  function background(Template.Background memory __input)
    external
    pure
    returns (string memory __result)
  {
    if (__input.radial) {
      __result = string(abi.encodePacked(__result, " "));
      if (__input.dark) {
        __result = string(
          abi.encodePacked(
            __result,
            ' <path style="fill:hsl(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ', 30%, 7%)" d="M0 0h2000v3000H0z"/> <radialGradient id="grad0"> <stop offset="0" style="stop-color: hsl(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ", ",
            SolidMustacheHelpers.uintToString(__input.color.saturation, 0),
            "%, ",
            SolidMustacheHelpers.uintToString(__input.color.lightness, 0),
            '%)"/> <stop offset="1" style="stop-color: hsla(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ", ",
            SolidMustacheHelpers.uintToString(__input.color.saturation, 0),
            "%, ",
            SolidMustacheHelpers.uintToString(__input.color.lightness, 0),
            __constant0
          )
        );
      }
      __result = string(abi.encodePacked(__result, " "));
      if (!__input.dark) {
        __result = string(
          abi.encodePacked(
            __result,
            ' <path style="fill:hsl(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ", ",
            SolidMustacheHelpers.uintToString(__input.color.saturation, 0),
            "%, ",
            SolidMustacheHelpers.uintToString(__input.color.lightness, 0),
            '%)" d="M0 0h2000v3000H0z"/> <radialGradient id="grad0"> <stop offset="0" style="stop-color:hsl(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ', 100%, 95%)"/> <stop offset="1" style="stop-color:hsla(55, 66%, 83',
            __constant0
          )
        );
      }
      __result = string(abi.encodePacked(__result, " "));
    }
    __result = string(abi.encodePacked(__result, " "));
    if (!__input.radial) {
      __result = string(abi.encodePacked(__result, " "));
      if (__input.dark) {
        __result = string(
          abi.encodePacked(
            __result,
            ' <linearGradient id="l0" gradientTransform="rotate(90)"> <stop offset="0%" stop-color="hsl(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ', 30%, 7%)"/> <stop offset="100%" stop-color="hsl(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ", ",
            SolidMustacheHelpers.uintToString(__input.color.saturation, 0),
            "%, ",
            SolidMustacheHelpers.uintToString(__input.color.lightness, 0),
            '%)"/> </linearGradient> <rect style="fill:url(#l0)" width="2000" height="3000"/> '
          )
        );
      }
      __result = string(abi.encodePacked(__result, " "));
      if (!__input.dark) {
        __result = string(
          abi.encodePacked(
            __result,
            ' <linearGradient id="l0" gradientTransform="rotate(90)"> <stop offset="0%" stop-color="hsl(55, 66%, 83%)"/> <stop offset="100%" stop-color="hsl(',
            SolidMustacheHelpers.uintToString(__input.color.hue, 0),
            ", ",
            SolidMustacheHelpers.uintToString(__input.color.saturation, 0),
            "%, ",
            SolidMustacheHelpers.uintToString(__input.color.lightness, 0),
            '%)"/> </linearGradient> <rect style="fill:url(#l0)" width="2000" height="3000"/> '
          )
        );
      }
      __result = string(abi.encodePacked(__result, " "));
    }
    __result = string(
      abi.encodePacked(
        __result,
        ' <path filter="url(#bb)" style="opacity: .5" d="m1000 2435-199 334 195-335-573 212 570-214-892-20 889 18-1123-339 1121 335-1244-713 1243 709-1242-1106L988 2418-133 938 990 2415 101 616l892 1796L423 382l573 2028L801 260l199 2149 199-2149-195 2150 573-2028-569 2030 891-1796-889 1799L2133 938 1012 2418l1244-1102-1243 1106 1243-709-1244 713 1121-335-1123 338 889-17-892 20 570 214-573-212 195 335-199-334z" fill="white" />'
      )
    );
  }

  function xpBar(Template.Xp memory __input)
    external
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<defs> <style> .xpc { fill: none; stroke-width: 1; stroke: #FAFFC0; opacity: 0.7; } .hilt path { fill: url(#hg); } </style> <linearGradient id="xpg" x1="80%" x2="20%" y1="200%" y2="-400%"> <stop offset="0"/> <stop offset=".4" stop-color="#90ee90" stop-opacity="0"/> </linearGradient> <linearGradient id="hg" x1="80%" x2="20%" y1="200%" y2="-400%"> <stop offset="0"/> <stop offset=".4" stop-color="#90ee90"/> </linearGradient> </defs> <circle class="xpc" cx="1000" cy="1060" r="320"/> <circle class="xpc" cx="1000" cy="1060" r="290"/> <path id="xpb" d="M1000 1365a1 1 0 0 0 0-610" stroke-linecap="round" style="stroke-dasharray:calc(',
        SolidMustacheHelpers.uintToString(__input.amount, 0),
        " / ",
        SolidMustacheHelpers.uintToString(__input.cap, 0),
        ' * 37.2%) 100%;fill:none;stroke-width:28;stroke:url(#xpg);opacity:1;mix-blend-mode:plus-lighter"/> <use href="#xpb" transform="matrix(-1 0 0 1 2000 0)"/> <g class="hilt" filter="url(#ge)" id="xph"> <path transform="rotate(45 1000 1365)" d="M980 1345h40v40h-40z"/> <path d="M980 1345h40v40h-40z"/> </g> ',
        __input.crown
          ? ' <use href="#xph" transform="translate(0,-610)"/> '
          : ""
      )
    );
  }

  function stars(Template.__Input memory __input)
    external
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<defs> <filter id="st"> <feTurbulence baseFrequency=".1" seed="',
        SolidMustacheHelpers.uintToString(__input.seed, 0),
        '"/> <feColorMatrix values="0 0 0 7 -4 0 0 0 7 -4 0 0 0 7 -4 0 0 0 0 1" /> </filter> </defs> <clipPath id="stc"> <circle cx="1000" cy="1060" r="520"/> </clipPath> <mask id="stm"> <g filter="url(#st)" transform="scale(2)"> <rect width="100%" height="100%"/> </g> </mask> <circle class="bc" cx="1000" cy="1060" r="260"/> <circle class="bc" cx="1000" cy="1060" r="360"/> <circle class="bc" cx="1000" cy="1060" r="440"/> <circle class="bc" cx="1000" cy="1060" r="520"/> <line class="bc" x1="740" y1="610" x2="1260" y2="1510"/> <line class="bc" x1="1260" y1="610" x2="740" y2="1510"/> <line class="bc" x1="1450" y1="800" x2="550" y2="1320"/> <line class="bc" x1="1450" y1="1320" x2="550" y2="800"/> <g style="filter: blur(2px);"> <rect width="100%" height="100%" fill="white" mask="url(#stm)" clip-path="url(#stc)" /> </g>'
      )
    );
  }
}

library FrameLayer {
  function frame(Template.Frame memory __input)
    external
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<defs> <linearGradient id="gradient-fill"> <stop offset="0" stop-color="black"></stop> <stop offset="0.5" stop-color="rgba(255,255,255,0.5)"></stop> <stop offset="1" stop-color="rgba(255,255,255,0.8)"></stop> </linearGradient> <style type="text/css"> .title {font: 45px serif; fill: #ffffffbb; letter-spacing: 10px} .frame-line { fill: none; stroke: url(#gradient-fill); stroke-miterlimit: 10; stroke-width: 2px; mix-blend-mode: plus-lighter; } .frame-circ { fill: url(#gradient-fill); mix-blend-mode: plus-lighter; } </style> </defs>',
        __input.level1
          ? ' <g> <g id="half1"> <polyline class="frame-line" points="999.95 170.85 1383.84 170.85 1862.82 137.14 1862.82 1863.5 1759.46 2478.5 1481.46 2794.5 999.98 2794.5" ></polyline> <polyline class="frame-line" points="1000 69 1931.46 68.5 1931.39 2930.43 1569.96 2931 1480.96 2828 999.99 2828" ></polyline> </g> <use href="#half1" transform="scale(-1,1) translate(-2000,0)"></use> <circle class="frame-circ" cx="1000" cy="68.5" r="16.65"></circle> </g>'
          : "",
        __input.level2
          ? ' <g> <circle class="frame-circ" cx="1000" cy="68.5" r="16.65"></circle> <g id="half2"> <polyline class="frame-line" points="1000 69 1931.46 68.5 1931.39 2930.43 1569.96 2931 1480.96 2828 1000 2828" ></polyline> <polyline class="frame-line" points="1897.11 102.86 1383.84 137.14 1000 137.14" ></polyline> <polyline class="frame-line" points="1897.17 102.86 1897.46 2896.5 1710.57 2897.5 1607.57 2811.25 1000 2811.25" ></polyline> <polyline class="frame-line" points="1607.57 2794.5 1759.46 2478.5 1862.46 1898 1862.82 711.53 1357.29 206 1000 205.71" ></polyline> <line class="frame-line" x1="1607.57" y1="2794.5" x2="1000" y2="2794.5" ></line> <line class="frame-line" x1="1371.92" y1="172" x2="1000" y2="172"></line> <polyline class="frame-line" points="1371.92 172 1862.82 661.72 1862.82 137.14 1371.92 172" ></polyline> <line class="frame-line" x1="999.41" y1="240.85" x2="998.82" y2="240.85" ></line> <line class="frame-line" x1="999.41" y1="240.85" x2="1000" y2="240.85" ></line> <polyline class="frame-line" points="1000 2773.5 1481.46 2773.5 1573.01 1924.59 1827.75 1412.39 1827.75 725.62 1342.13 240 1000 240.84" ></polyline> <line class="frame-line" x1="999.41" y1="240.85" x2="1000" y2="240.84" ></line> </g> <use href="#half2" transform="scale(-1,1) translate(-2000,0)"></use> </g>'
          : "",
        __input.level3
          ? ' <g> <g id="half3"> <polyline class="frame-line" points="1000 69 1931.5 68.5 1931.43 2930.43 1570 2931 1481 2828 1000 2828" ></polyline> <polyline class="frame-line" points="1529.47 205.71 1494.75 170.99 1434.52 170.99 1366.78 102.65 1000.15 102.51" ></polyline> <polyline class="frame-line" points="1897.15 697.11 1827.43 627.96 1827.43 503.65 1759.61 435.84 1759.65 239.65 1563.41 239.65 1529.47 205.71" ></polyline> <polyline class="frame-line" points="1794.28 470.49 1794.32 205.71 1529.47 205.71" ></polyline> <polyline class="frame-line" points="1505.26 2630.76 1505.26 2329.59 1827.78 1797.3 1827.78 1091.27" ></polyline> <polyline class="frame-line" points="1505.26 2630.76 1505.26 2741.32 1474.99 2773.5 1000.04 2773.5 1000 2773.5" ></polyline> <polyline class="frame-line" points="1827.78 1091.27 1827.78 725.62 1342.17 240 1000 240.84" ></polyline> <line class="frame-line" x1="1000" y1="240.84" x2="998.85" y2="240.85" ></line> <polyline class="frame-line" points="1897.2 697.11 1897.5 2896.5 1710.61 2897.5 1607.61 2811.25 1000 2811.25" ></polyline> <polyline class="frame-line" points="1000 205.71 1357.32 206 1862.86 711.53 1862.5 1898 1759.5 2478.5 1481.5 2794.5 1000 2794.5" ></polyline> <line class="frame-line" x1="1827.78" y1="1091.27" x2="1827.82" y2="1091.1" ></line> <polyline class="frame-line" points="1505.26 2630.76 1367.45 2554.29 1367.45 2220.5 1792.75 1724.22 1792.75 1248.5 1827.78 1091.27" ></polyline> <line class="frame-line" x1="1523.72" y1="2641" x2="1505.26" y2="2630.76" ></line> <polygon class="frame-line" points="1516.66 2779.74 1533.6 2794.5 1754.59 2794.5 1854.26 2880.53 1879.75 2880.53 1879.75 2016.03 1854.5 2050.86 1773.41 2487.85 1516.66 2779.74" ></polygon> <polygon class="frame-line" points="1827.82 2003.62 1827.78 1827.65 1541.42 2300.27 1541.42 2701.3 1745.92 2465.88 1827.82 2003.62" ></polygon> <path class="frame-circ" d="M1523.72,2437.57c-19.52,0-17.5-108.68-17.5-108.68v303.83l17.5,8.28v-203.43Z" ></path> </g> <use href="#half3" transform="scale(-1,1) translate(-2000,0)"></use> <circle class="frame-circ" cx="1000" cy="68.5" r="16.65"></circle> </g>'
          : "",
        __input.level4
          ? ' <g> <g id="half4"> <polyline class="frame-line" points="1000 69 1931.5 68.5 1931.43 2930.43 1570 2931 1481 2828 1000 2828" ></polyline> <line class="frame-line" x1="1897.28" y1="863.04" x2="1897.5" y2="2880.53" ></line> <polyline class="frame-line" points="1897.28 863.04 1897.2 102.86 1000 102.86" ></polyline> <polyline class="frame-line" points="1897.5 2880.53 1897.5 2896.5 1710.61 2897.5 1607.61 2811.25 1000 2811.25" ></polyline> <polyline class="frame-line" points="1897.5 2880.53 1897.5 2880.53 1897.5 862.02 1897.28 863.04" ></polyline> <polyline class="frame-line" points="1897.28 863.04 1880.5 941.98 1880.5 2482.5 1668.74 2606.83 1516.66 2779.74 1533.6 2794.5 1754.59 2794.5 1854.26 2880.53 1897.5 2880.53" ></polyline> <polygon class="frame-line" points="1810.37 1957.47 1584.83 2627.74 1598.53 2636.23 1743.99 2466.19 1833.34 1957.47 1810.37 1957.47" ></polygon> <polygon class="frame-line" points="1792.74 1887.34 1521.19 2335.31 1519.33 2728.41 1540.01 2703.32 1792.74 1957.47 1792.74 1887.34" ></polygon> <line class="frame-line" x1="1760.57" y1="1061.26" x2="1760.57" y2="1185.5" ></line> <line class="frame-line" x1="1760.57" y1="1061.26" x2="1760.57" y2="658.41" ></line> <polyline class="frame-line" points="1367.38 2457.75 1314.63 2424.63 1314.7 2083.5 1743.57 1676.44" ></polyline> <polyline class="frame-line" points="1743.57 1676.44 1760.57 1660.31 1760.57 1185.5" ></polyline> <polygon class="frame-line" points="1385.01 2220.72 1421.7 2503.81 1475.28 2593.06 1489.95 2601.39 1489.95 2324.67 1792.75 1830.71 1792.75 1742.41 1385.01 2220.72" ></polygon> <polyline class="frame-line" points="1743.57 1676.44 1743.57 1265.46 1760.57 1185.5" ></polyline> <polyline class="frame-line" points="1810.78 1825.36 1810.78 1265.44 1827.78 1185.47" ></polyline> <polyline class="frame-line" points="1760.57 1061.26 1725.5 1218.65 1725.5 1592.76 1268.07 1931.48 1268.07 2424.5 1367.45 2484.94" ></polyline> <polyline class="frame-line" points="1367.45 2484.94 1367.45 2220.5 1792.75 1724.22 1792.75 1218.65 1827.78 1061.42" ></polyline> <line class="frame-line" x1="1827.82" y1="1061.26" x2="1827.78" y2="1061.42" ></line> <polyline class="frame-line" points="1367.45 2484.94 1367.45 2554.29 1490.09 2622.34 1490.09 2734.78 1468.95 2756.5 1390.92 2756.5 1310.95 2773.5" ></polyline> <polygon class="frame-line" points="1390.64 240 1827.78 677.14 1827.78 346.02 1504.22 240 1390.64 240" ></polygon> <polygon class="frame-line" points="1827.78 240 1582.82 240 1827.78 315.28 1827.78 240" ></polygon> <line class="frame-line" x1="1827.78" y1="1061.42" x2="1827.78" y2="1185.47" ></line> <polyline class="frame-line" points="1310.95 2773.5 1001.4 2773.5 1000.22 2773.5 1000.04 2773.5 1000 2773.5" ></polyline> <polyline class="frame-line" points="1827.78 1185.47 1827.78 1797.3 1505.26 2329.59 1505.26 2741.32 1474.99 2773.5 1310.95 2773.5" ></polyline> <polyline class="frame-line" points="1827.78 1061.42 1827.78 725.62 1342.17 240 1000 240" ></polyline> <polyline class="frame-line" points="1000 205.71 1383.88 205.71 1862.86 137.14 1862.86 1863.5 1759.5 2478.5 1481.5 2794.5 1000 2794.5" ></polyline> <circle class="frame-circ" cx="1811.14" cy="191.9" r="16.65"></circle> <circle class="frame-circ" cx="1811.14" cy="2745.05" r="16.65"></circle> </g> <use href="#half4" transform="scale(-1,1) translate(-2000,0)"></use> <circle class="frame-circ" cx="1000" cy="68.5" r="16.65"></circle> </g>'
          : "",
        __input.level5
          ? ' <g> <g id="half5"> <circle class="frame-circ" cx="1730.45" cy="2846.73" r="16.65"></circle> <path class="frame-circ" d="M1373.87,2812.06c0-19.52,108.68-17.5,108.68-17.5h-482.63l.2,17.5h373.75Z" ></path> <path class="frame-circ" d="M1373.87,2826.85c0-19.52,108.68-17.5,108.68-17.5h-482.63l.2,17.5h373.75Z" ></path> <polyline class="frame-line" points="1000 137.11 1131.57 137.04 1178.34 68.9 1931.5 68.5 1931.43 2930.43 1570 2931 1481 2828 1000 2828" ></polyline> <polyline class="frame-line" points="1897.28 863.04 1897.2 102.86 1210.67 102.86 1165.79 170.24 1000 170.31" ></polyline> <line class="frame-line" x1="1897.28" y1="863.04" x2="1897.5" y2="2880.53" ></line> <polyline class="frame-line" points="1897.5 2880.53 1897.5 2896.5 1710.61 2897.5 1607.61 2811.25 1000 2811.25" ></polyline> <polyline class="frame-line" points="1897.28 863.04 1880.5 941.98 1880.5 2482.5 1668.74 2606.83 1516.66 2779.74 1533.6 2794.5 1754.59 2794.5 1854.26 2880.53 1897.5 2880.53" ></polyline> <polyline class="frame-line" points="1897.5 2880.53 1897.5 2880.53 1897.5 862.02 1897.28 863.04" ></polyline> <polyline class="frame-line" points="1827.78 1192.28 1827.78 1797.3 1505.26 2329.59 1505.26 2741.32 1474.99 2773.5 1108.16 2773.5" ></polyline> <polyline class="frame-line" points="1108.16 2773.5 1001.4 2773.5 1000.22 2773.5 1000.04 2773.5 1000 2773.5" ></polyline> <polyline class="frame-line" points="1795.65 693.48 1342.17 240 1000 240" ></polyline> <line class="frame-line" x1="1827.78" y1="1192.28" x2="1827.78" y2="1061.42" ></line> <polyline class="frame-line" points="1827.78 1061.42 1827.78 725.62 1795.65 693.48" ></polyline> <polyline class="frame-line" points="1000 205.71 1343.14 205.71 1387.55 137.14 1637.33 137.14 1862.86 724.46 1862.86 1863.5 1759.5 2478.5 1481.5 2794.5 1000 2794.5" ></polyline> <polygon class="frame-line" points="1391.12 258.56 1749.43 619.82 1802.81 619.82 1623.32 160.77 1403.75 160.77 1391.12 258.56" ></polygon> <polyline class="frame-line" points="1743.58 1781.6 1792.75 1724.22 1792.75 1218.65 1827.78 1061.42" ></polyline> <line class="frame-line" x1="1827.82" y1="1061.26" x2="1827.78" y2="1061.42" ></line> <polyline class="frame-line" points="1367.45 2484.94 1367.45 2554.29 1433.9 2622.34 1433.9 2734.78 1412.76 2756.5 1188.13 2756.5 1108.16 2773.5" ></polyline> <polyline class="frame-line" points="1367.45 2484.94 1367.45 2220.5 1743.58 1781.6" ></polyline> <polyline class="frame-line" points="1367.45 2484.94 1268.07 2424.5 1268.07 1931.48 1725.5 1592.76 1725.5 1218.65 1760.57 1061.26 1760.57 658.41" ></polyline> <polyline class="frame-line" points="1760.57 1761.76 1760.57 1218.65 1795.65 1061.26 1795.65 972.9" ></polyline> <line class="frame-line" x1="1795.65" y1="693.48" x2="1795.65" y2="972.9" ></line> <polygon class="frame-line" points="1354.28 1995.11 1516.66 1871.28 1516.66 1822.34 1608.69 1751.67 1608.69 1697.46 1281.35 1941.68 1281.35 2416.1 1354.28 2461.09 1354.28 1995.11" ></polygon> <polygon class="frame-line" points="1367.48 2197.71 1728.39 1776.02 1725.8 1612.05 1621.83 1687.86 1621.83 1758.95 1528.89 1828.67 1528.89 1882.83 1367.48 2003.92 1367.48 2197.71" ></polygon> <polygon class="frame-line" points="1504.51 2079.27 1504.51 2307.23 1795.65 1826.17 1795.65 1741.8 1504.51 2079.27" ></polygon> <polygon class="frame-line" points="1379.42 2225.53 1379.42 2544.67 1447.81 2613.04 1488.39 2613.04 1488.39 2097.65 1379.42 2225.53" ></polygon> <polygon class="frame-line" points="1810.37 1957.47 1584.83 2627.74 1598.53 2636.23 1743.99 2466.19 1833.34 1957.47 1810.37 1957.47" ></polygon> <polygon class="frame-line" points="1792.74 1887.34 1521.19 2335.31 1519.33 2728.41 1540.01 2703.32 1792.74 1957.47 1792.74 1887.34" ></polygon> <polyline class="frame-line" points="1827.78 1192.28 1810.78 1272.24 1810.78 1825.36" ></polyline> <polyline class="frame-line" points="1743.58 1781.6 1743.58 1217.84 1795.65 972.9" ></polyline> <polygon class="frame-line" points="1880.5 2511.85 1862.86 2511.85 1681.48 2620.12 1580.39 2737.19 1618.59 2777.12 1759.78 2776.27 1859.09 2863.38 1880.17 2863.38 1880.5 2511.85" ></polygon> </g> <use href="#half5" transform="scale(-1,1) translate(-2000,0)"></use> <circle class="frame-circ" cx="1000" cy="68.5" r="16.65"></circle> </g>'
          : "",
        '<path opacity="0.4" d="M 529.085 2844.789 L 454.584 2930.999 L 1545.417 2930.989 L 1470.942 2844.789 L 529.085 2844.789 Z" fill="#00000055" stroke="white" stroke-width="3.75" ></path> <clipPath id="tc"> <path d="M 529.085 2844.789 L 454.584 2930.999 L 1545.417 2930.989 L 1470.942 2844.789 L 529.085 2844.789 Z" fill="black" ></path> </clipPath> <path id="ng" d="M 480 2905 L 1520 2905" stroke="none"></path> <text text-anchor="middle" class="title" clip-path="url(#tc)"> <textPath href="#ng" startOffset="50%"> <animate attributeName="startOffset" from="180%" to="-80%" begin="0s" dur="20s" repeatCount="indefinite" ></animate> ',
        __input.title,
        " </textPath> </text>"
      )
    );
  }
}

library HandleLayer {
  function handles(Template.Handle memory __input)
    external
    pure
    returns (string memory __result)
  {
    __result = string(
      abi.encodePacked(
        __result,
        '<defs> <style> .a, .d { fill: none; } .a, .b, .c, .d, .e, .f, .g, .h, .i, .k { stroke: #000; stroke-width: .25px; } .b, .c, .e, .g { fill: #fff; } .pf { fill: #584975; } .red { --wedge-color: #e0727f; } .rf { fill: #ed2d2e; } .nf { fill: #053c5b; } .gr { --wedge-color: #8a9fa4; } .bf{ fill: #1b1925; } .lb { fill: #425288; } .gf { fill: #aad37e; } .bl { --wedge-color: #425288; } .ef { fill: #8a9fa4; } .lgf { fill: #c3cdd7; } .lbf { fill: #8cb3db; } .db { --wedge-color: #3a4757; } </style> <symbol id="wa" viewBox="0 0 111 111"> <style>.cw { fill: var(--wedge-color) }</style> <path class="c" d="M12 111a226 226 0 0 0 99-99l-7-3a226 226 0 0 1-95 95Z"/> <path class="c cw" d="M9 104a226 226 0 0 0 95-95L87 0 75 21c-15 21-32 22-53 1 22 21 20 38-1 53A204 204 0 0 1 0 87Z"/> </symbol> <symbol id="wb" viewBox="0 0 114 65"> <path class="a cw" d="M3 4 0 32s57-14 57 33c0-47 56-33 56-33l-3-28C87-1 30-1 3 4Z"/> <path class="b" d="M0 32s25-6 42 3c-9-5-33-2-33-2l-9-1m113 0s-25-6-41 3c8-5 33-2 33-2l9-1"/> </symbol> <symbol id="c" viewBox="0 0 211 420"> <path class="ef" d="M211 0q-29 217-106 215Q29 217 0 0l55 420q-21-164 50-165 72 1 50 165Z"/> </symbol> <symbol id="g" viewBox="0 0 346 148"> <path class="lbf" d="M173 0c1 20 10 60 173 88-168-21-172 36-173 60-1-24-6-81-173-60C163 60 171 20 173 0Z"/> </symbol> <symbol id="h" viewBox="0 0 48 90"> <path class="b" d="M24 90c0-14 16-34 24-42 0-12-24-30-24-48C24 18 0 36 0 48c8 8 24 28 24 42Z"/> <path class="c" d="M45 40a72 72 0 0 0-21 29C20 58 13 49 3 40 9 29 24 14 24 0c0 14 15 29 21 40Z"/> <path class="b" d="M24 69v21"/> </symbol> </defs> <g filter="url(#ge)" style="opacity: 1; mix-blend-mode: luminosity">',
        __input.handle0
          ? '<path class="pf" d="M1073 2313c-13-13-18-24-25-81-27-194-2-683 34-778l-32-40H950l-32 40c36 95 61 584 34 778-7 57-12 68-25 80Z"/> <rect class="c" x="941" y="1407" width="119" height="7" rx="4"/> <rect class="c" x="941" y="1593" width="119" height="7" rx="4"/> <rect class="c" x="944" y="1631" width="111" height="7" rx="4"/> <rect class="c" x="948" y="1669" width="104" height="7" rx="4"/> <rect class="c" x="951" y="1707" width="98" height="7" rx="4"/> <rect class="c" x="953" y="1745" width="94" height="7" rx="4"/> <rect class="c" x="955" y="1783" width="90" height="7" rx="4"/> <rect class="c" x="957" y="1821" width="87" height="7" rx="4"/> <rect class="c" x="958" y="1859" width="84" height="7" rx="4"/> <rect class="c" x="959" y="1897" width="82" height="7" rx="4"/> <rect class="c" x="960" y="1935" width="81" height="7" rx="4"/> <rect class="c" x="960" y="1973" width="80" height="7" rx="4"/> <rect class="c" x="960" y="2011" width="80" height="7" rx="4"/> <rect class="c" x="960" y="2049" width="80" height="7" rx="4"/> <rect class="c" x="959" y="2087" width="81" height="7" rx="4"/> <rect class="c" x="958" y="2125" width="85" height="7" rx="4"/> <rect class="c" x="955" y="2163" width="90" height="7" rx="4"/> <path class="b" d="M1000 1553a231 231 0 0 1-103-25l5-10a220 220 0 0 0 196-1l6 11a231 231 0 0 1-104 25Z"/> <use class="red" width="111" height="111" transform="translate(1091 1426)" href="#wa"/> <use class="red" width="111" height="111" transform="rotate(90 -258 1168)" href="#wa"/> <use class="red" width="114" height="65" transform="translate(943 2199)" href="#wb"/> <use class="red" width="114" height="65" transform="matrix(-1.25 0 0 -1 1071 1558)" href="#wb"/> <path class="pf" d="M918 1454h164"/> <path class="b" d="M928 2384c10-5 9 15 9 15s-11 4-7 22c0 0-12-32-2-37Zm144 0c-10-5-9 15-9 15s11 4 7 22c0 0 12-32 2-37Z"/> <circle cx="1000" cy="2350" r="80" fill="#ad93c5"/> <path class="b" d="M1000 2351s102 4 68-52l-4 4c29 43-64 42-64 42s-93 1-64-42l-4-4c-34 56 68 52 68 52Zm-51 136 11 63c16-33 64-33 80 0l11-63c-31 38-72 38-102 0Zm89 50a51 51 0 0 0-76 0l-6-35c28 24 60 24 88 0Z"/> <path class="a" d="m949 2487 7 15m6 35-3 13m79-13 2 13m11-63-7 15"/> <path d="M1068 2299c35 56-68 52-68 52s-103 4-68-52a80 80 0 0 0-17 52c5 85 36 217 52 318-20-125 16-133 33-133s53 8 33 133c16-101 47-233 52-318 2-16-5-39-17-52Zm-28 251a46 46 0 0 0-80 0l-11-63c30 38 71 38 102 0Zm33-146c-7 57-43 100-73 100s-66-43-73-100c-1-5-9-48 73-47 82-1 74 42 73 47Z" fill="#e0727f"/>'
          : "",
        __input.handle1
          ? '<rect class="c" x="947" y="1407" width="106" height="7" rx="4"/> <circle cx="1000" cy="2020" r="130" fill="#fff" stroke="#000" stroke-width=".3"/> <circle cx="1000" cy="2020" r="126" fill="#8a9fa4"/> <circle cx="1000" cy="2020" r="118" fill="#efc981"/> <path d="M1000 2001a124 124 0 0 0-109 65 118 118 0 0 0 218 0 124 124 0 0 0-109-65Z" fill="#f5cc14"/> <path class="rf" d="M963 1414h74l42 899H921l42-899z"/> <rect class="c" x="952" y="1567" width="97" height="7" rx="4"/> <rect class="c" x="950" y="1605" width="100" height="7" rx="4"/> <rect class="c" x="949" y="1642" width="103" height="7" rx="4"/> <rect class="c" x="947" y="1679" width="106" height="7" rx="4"/> <rect class="c" x="945" y="1717" width="111" height="7" rx="4"/> <rect class="c" x="944" y="1754" width="113" height="7" rx="4"/> <rect class="c" x="942" y="1791" width="117" height="7" rx="4"/> <rect class="c" x="940" y="1829" width="119" height="7" rx="4"/> <rect class="c" x="939" y="1866" width="123" height="7" rx="4"/> <rect class="c" x="937" y="1903" width="127" height="7" rx="4"/> <rect class="c" x="935" y="1941" width="132" height="7" rx="4"/> <path class="rf" d="m824 2337 168 232c-99-138-17-152-6-157l-38-17c-12 5-53 21-124-58Z"/> <path class="c" d="M896 2411c34 10 66-5 66-5a60 60 0 0 0-33 50Z"/> <path class="rf" d="m909 2419 16 23c6-17 12-23 12-23s-16 2-28 0Z"/> <path class="d" d="m896 2411 13 8m16 23 4 15m8-38a271 271 0 0 1 25-13"/> <path class="rf" d="m1176 2337-168 232c99-138 17-152 6-157l38-17c12 5 53 21 124-58Z"/> <path class="c" d="M1104 2411c-34 10-66-5-66-5a60 60 0 0 1 33 51Z"/> <path class="rf" d="m1091 2419-16 23c-6-17-12-23-12-23s16 2 28 0Z"/> <path class="d" d="m1104 2411-13 8m-16 23-4 15m-8-38a271 271 0 0 0-25-13"/> <circle class="c" cx="1000" cy="2334" r="82"/> <circle class="nf" cx="1000" cy="2334" r="75"/> <rect class="c" x="993" y="2252" width="15" height="164" rx="7"/> <use class="bl" width="114" height="65" transform="matrix(.91 0 0 1.82 948 1487)" href="#wb"/> <path class="b" d="M1000 2163a231 231 0 0 1-103-25l5-10a220 220 0 0 0 196-1l5 11a231 231 0 0 1-103 25Z"/> <path class="nf" d="m1078 2186-10-197c-34-10-106-10-135 0l-11 196Z"/> <use class="gr" width="114" height="65" transform="matrix(-1.5 0 0 -1.77 1085 2239)" href="#wb"/> <use class="gr" width="111" height="111" transform="rotate(90 -563 1474)" href="#wa"/> <use class="gr" width="111" height="111" transform="translate(1089 2036)" href="#wa"/>'
          : "",
        __input.handle2
          ? '<rect class="c" x="932" y="1407" width="135" height="7" rx="4"/> <path class="bf" d="M1060 1415c-56 187-41 540-3 673 34 118 28 165 3 225H940c-25-60-31-107 3-225 38-133 53-486-3-673Z"/> <rect class="c" x="968" y="1873" width="64" height="7" rx="4"/> <rect class="c" x="965" y="1910" width="70" height="7" rx="4"/> <rect class="c" x="962" y="1948" width="7" height="7" rx="4"/> <rect class="c" x="958" y="1985" width="85" height="7" rx="4"/> <rect class="c" x="952" y="2023" width="95" height="7" rx="4"/> <path class="b" d="M1042 1824a234 234 0 0 1-84 0l1-12a222 222 0 0 0 82 0Z"/> <path class="lb" d="M916 1755c-16 41 11 48 46 51l-4 26c-31-28-59-38-77 5 17-41-2-55-50-58l17-20c13 9 47 46 68-4Zm168 0c16 41-11 48-46 51l4 26c31-28 59-38 77 5-17-41 2-55 50-58l-17-20c-13 9-47 46-68-4Z"/> <circle class="bf" cx="1000" cy="2394.6" r="65.5"/> <path class="lb" d="M1000 2342c32 0 16-30 140-16-87-14-140-37-140-71 0 34-53 57-140 71 124-14 108 16 140 16Z"/> <rect class="lb" x="915" y="2375" width="170.5" height="38.3" rx="19.2"/> <path class="lb" d="M1000 2763c0-116 66-174 148-202l-18-56c-110 20-98-63-130-63s-20 83-130 63l-18 56c82 28 148 86 148 202Z"/> <path class="b" d="M1000 2662c4-8 27-73 124-113l-7-22c-34 5-92-5-117-66-25 61-83 71-117 66l-7 22c97 40 120 105 124 113Z"/> <path class="gf" d="M1000 2645c11-22 44-70 114-100l-3-10c-58 7-99-31-111-56-12 25-53 63-111 56l-3 10c71 30 103 78 114 100Zm-117-118 6 8m-13 14 10-4m114 100v18m111-128 6-8m-3 18 10 4m-124-88v18"/> <path class="b" d="M1000 2328s8-9 24-15c-16-8-24-16-24-16s-8 8-24 16c16 6 24 15 24 15Z"/> <path class="gf" d="m1000 2318 7-6-7-5-7 5 7 6z"/> <path class="a" d="M1000 2297v10m-7 5-17 1m24 5v10m7-16 17 1"/> <use class="bl" width="114" height="65" transform="matrix(-.6 0 0 -1.46 1034 1845)" href="#wb"/> <use class="bl" width="114" height="65" transform="matrix(1.2 0 0 1.17 932 2064)" href="#wb"/>'
          : "",
        __input.handle3
          ? '<path class="lbf" d="m1021 2313 35-899H942l38 899h41z"/> <rect class="g" x="932" y="1407" width="135" height="7" rx="4"/> <rect class="g" x="952" y="1724" width="96" height="7" rx="4"/> <rect class="g" x="953" y="1762" width="94" height="7" rx="4"/> <rect class="g" x="955" y="1800" width="91" height="7" rx="4"/> <rect class="g" x="957" y="1837" width="87" height="7" rx="4"/> <rect class="g" x="958" y="1875" width="84" height="7" rx="4"/> <rect class="g" x="960" y="1912" width="81" height="7" rx="4"/> <rect class="g" x="961" y="1950" width="78" height="7" rx="4"/> <rect class="g" x="963" y="1988" width="74" height="7" rx="4"/> <path class="g" d="M1108 2075a212 212 0 0 0-216 0l-4-8a221 221 0 0 1 225 1Z"/> <use class="db" width="114" height="65" transform="matrix(.7 0 0 1.46 961 2021)" href="#wb"/> <use class="db" width="114" height="65" transform="matrix(-1.01 0 0 -1 1058 1696)" href="#wb"/> <use width="211" height="420" transform="matrix(.2 .06 -.08 .26 1060 1982)" href="#c"/> <use width="211" height="420" transform="matrix(.18 .09 -.12 .25 1108 1997)" href="#c"/> <use width="211" height="420" transform="matrix(.2 -.06 .08 .26 900 1994)" href="#c"/> <use width="211" height="420" transform="matrix(.18 -.09 .12 .25 854 2016)" href="#c"/> <circle class="lbf" cx="1000" cy="2257" r="81"/> <path class="ef" d="M1000 2434c133 0 226-73 226-73l-87-120c45 63 21 99-39 118-60 20-100-3-100-56 0 53-39 76-100 56-59-19-84-55-39-118l-87 120s93 73 226 73Z"/> <path d="m825 2318-28 39s58 41 142 55c26-12 45-23 45-42-55 34-145-8-159-52Zm350 0 28 39s-58 41-141 55c-27-12-45-23-46-42 56 34 145-8 159-52Z" fill="#c3cdd7"/> <use width="346" height="148" transform="translate(827 2370)" href="#g"/> <path class="b" d="M1000 2471s14-19 51-28c-37-15-51-33-51-33s-13 18-51 33c37 9 51 28 51 28Z"/> <path d="M1000 2462c11-11 25-17 33-20a143 143 0 0 1-33-23 143 143 0 0 1-33 23c8 3 22 9 33 20Z" fill="#3a4757"/> <path class="b" d="m967 2442-18 1m51-24v-9m33 32 18 1m-51 19v10"/> <use width="48" height="90" transform="translate(976 2167)" href="#h"/> <use width="48" height="90" transform="rotate(90 -572 1662)" href="#h"/> <use width="48" height="90" transform="rotate(-90 1596 686)" href="#h"/> <use width="48" height="90" transform="rotate(180 512 1174)" href="#h"/>'
          : "",
        "</g>"
      )
    );
  }
}

library SolidMustacheHelpers {
  function intToString(int256 i, uint256 decimals)
    internal
    pure
    returns (string memory)
  {
    if (i >= 0) {
      return uintToString(uint256(i), decimals);
    }
    return string(abi.encodePacked("-", uintToString(uint256(-i), decimals)));
  }

  function uintToString(uint256 i, uint256 decimals)
    internal
    pure
    returns (string memory)
  {
    if (i == 0) {
      return "0";
    }
    uint256 j = i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    uint256 strLen = decimals >= len
      ? decimals + 2
      : (decimals > 0 ? len + 1 : len);

    bytes memory bstr = new bytes(strLen);
    uint256 k = strLen;
    while (k > 0) {
      k -= 1;
      uint8 temp = (48 + uint8(i - (i / 10) * 10));
      i /= 10;
      bstr[k] = bytes1(temp);
      if (decimals > 0 && strLen - k == decimals) {
        k -= 1;
        bstr[k] = ".";
      }
    }
    return string(bstr);
  }
}