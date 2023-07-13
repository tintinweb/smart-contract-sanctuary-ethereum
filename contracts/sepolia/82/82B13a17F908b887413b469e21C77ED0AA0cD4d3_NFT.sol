pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

/// ============ Imports ============
import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // OZ: ERC721URIStorage 
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol"; // OZ: Counters
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol"; // OZ: Strings
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol"; // OZ: Base64
import { ChapterStorage } from "./storage/ChapterStorage.sol";
import { UnitStorage } from "./storage/UnitStorage.sol";
// import { SVGGenerator } from "./utils/SVGGenerator.sol";
import { SVGGeneratorAnother} from "./utils/SVGGeneratorAnother.sol";
import { SplitSequence } from "./utils/SplitSequence.sol";

contract NFT is ERC721URIStorage{
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address chapterStorage;
    address unitStorage;

    mapping(uint256 => uint256) public tokenIdToLevels;
    constructor(address _unitStorage, address _chapterStorage) ERC721("Experimental", "NFT"){
        unitStorage = _unitStorage;
        chapterStorage = _chapterStorage;
    }
    function generateUnit(uint256 tokenId) public returns (string memory){
        // was before, working version
        // bytes memory svg = abi.encodePacked(
        //     '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">'
        //     '<style>.base { fill: white; font-family: serif; font-size: 14px; }</style>'
        //     '<rect width="100%" height="100%" fill="black" />'
        //     '<text x="100%" y="100%" class="base" dominant-baseline="middle" text-anchor="middle">',"This book is the product of joint research, discovery and iteration since we began the Economic Space Agency (ECSA) project in 2015. Its composing process has consisted of diverse intellectual inputs, revelations, impasses, often heated debate and constantly-evolving analysis. It is not easy to step into the new economic space, where we constantly find ourselves in uncertain terrain. We have found out it is possible only by experimenting and risking together.",'</text>'
        //     // '<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">',"Levels: ", getLevels(tokenId),'</text>'
        //     '</svg>'
        // );

    //working experiment!
    // bytes memory svg = abi.encodePacked(
    //     '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0 800 600">'
    //     '<text x="50%" y="50%" text-anchor="middle" dominant-baseline="middle" font-family="Arial" font-size="12" fill="black">'
    //     '<tspan x="50%" dy="-8.5em">Robust economic media, capable of heteroglossic and dialogical forms of account, are required to create a multiperspectival values-system.</tspan>'
    //     '<tspan x="50%" dy="2em">These media demand far more than merely a non-national variant of monetary media expressive of the capitalist value form.</tspan>'
    //     '<tspan x="50%" dy="2em">While the non-national dimension of cryptocurrencies introduced a significant rupture with conventional monetary substrates,</tspan>'
    //     '<tspan x="50%" dy="2em">platformed as they are as national currencies on nation states, their legally recognized institutions and their military police,</tspan>'
    //     '<tspan x="50%" dy="2em">this ultimately simple replatforming of singular denominations on distributed computing by existing cryptocurrencies is not enough.</tspan>'
    //     '<tspan x="50%" dy="2em">Bitcoin did in fact break the nationally managed monopolies on 21st-century monetary issuance by introducing a scalable currency(/asset/option)</tspan>'
    //     '<tspan x="50%" dy="2em">platformed on distributed computing, but it has done, and can do, little or nothing to challenge the monologic denomination of value as a</tspan>'
    //     '<tspan x="50%" dy="2em">one-dimensional, that is as a unitary, currency format.</tspan>'
    //     '<tspan x="50%" dy="2em">Bitcoin may contest the nation, but it, and its fetishism, is all about it being an option on the value-form as historically worked up under,</tspan>'
    //     '<tspan x="50%" dy="2em">and as, capitalism. The question "Bitcoin or USD" scarcely touches the relations of production.</tspan>'
    //     '<tspan x="50%" dy="2em">We must see clearly that the "disintermediation" of "trusted third parties" and of existing states, even if it were to be accomplished,</tspan>'
    //     '<tspan x="50%" dy="2em">is only one part of the picture of a liberated monetary medium, which is also to say, a liberated socius.</tspan>'
    //     '<tspan x="50%" dy="2em">We require the possibility for _anyone_ to offer denominations of value that can be taken up by those who share such values as specified</tspan>'
    //     '<tspan x="50%" dy="2em">and indeed offered in the proffered denomination. Only then will we have a genuinely multiperspectival system.</tspan>'
    //     '</text>'
    //     '</svg>'
    // );
        // previously working
        // string memory sentence = "While this power for anyone to write a derivative may sound esoteric (or even impossible and/or undesirable) - and part of the book that follows this foreword _is_ somewhat esoteric - a breaking down the barriers to the publishing of derivative instruments means that, in a world already rendered precarious by the history of racial capitalism, everyone (not just elites) may be better able to manage their undeniable risk by organizing their economy, cooperatively and collectively, and in terms of what is valuable to them. If neoliberalism taught us anything, it is that the way out of the problems of capitalism cannot, and will never, be through the creation of more capitalism. That is why we have reimagined the cryptotoken as a set of programmable capabilities (agreements) that may be enabled only when recognized and thereby validated by peers. Their semantic content represents a wager that the relationship, or agreement, they formalize expresses something of value (anything whatever) to both parties. Because each party or agent is enabled in the network through composing themselves - by entering into a portfolio of such tokenized arrangements that are in principle limitless - the wealth of each agent then becomes a composite of the qualified interests of others.";
        string memory sentence = UnitStorage(unitStorage).get(tokenId);
        string[] memory sequence = SplitSequence.splitSentence(sentence, 95);
        bytes memory svg = abi.encodePacked(SVGGeneratorAnother.generateSVG(sequence));

        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svg)
            )
        );
    }
    function getLevels(uint256 tokenId) public view returns (string memory){
        uint256 levels = tokenIdToLevels[tokenId];
        return levels.toString();
    }

    // Unit ( Not a metadata )
    // Metadata:
    // - Footnote
    // - Figure
    // - Chapter
    // - Section
    // - Heading
    // - Num Footnotes
    // - Inlcudes figure
    // - Length
    // - Self-referenciality
    // - X
    // - Y
    // - Z
    // - Unit descriptor: Nodewords
    // - Networded A
    // - Networded B

function getTokenURI(uint256 tokenId) public returns (string memory) {
    bytes memory dataURI = abi.encodePacked(
        '{',
            '"name": "Ecsa Book #', tokenId.toString(), '",',
            '"description": "Collective co-publishing",',
            '"image": "', generateUnit(tokenId), '",',
        '"attributes": [',
        '{',
            '"trait_type": "Footnote",',
            '"value": "Chain Battles #', tokenId.toString(), '"',
        '},',
        '{',
            '"trait_type": "Figure",',
            '"value": "Battles on chain"',
        '},',
        '{',
            '"trait_type": "Chapter",',
            '"value": "', ChapterStorage(chapterStorage).get(tokenId), '"',
        '},',
        '{',
            '"trait_type": "Section",',
            '"value": "Chain Battles #', tokenId.toString(), '"',
        '},',
        '{',
            '"trait_type": "Heading",',
            '"value": "Battles on chain"',
        '},',
        '{',
            '"trait_type": "Num Footnotes",',
            '"value": "', tokenId.toString(), '"',
        '},',
        '{',
            '"trait_type": "Includes figure",',
            '"value": "Chain Battles #', tokenId.toString(), '"',
        '},',
        '{',
            '"trait_type": "Length",',
            '"value": "Battles on chain"',
        '},',
        '{',
            '"trait_type": "Self-referentiality",',
            '"value": "', tokenId.toString(), '"',
        '},',
        '{',
            '"trait_type": "X",',
            '"value": "Chain Battles #', tokenId.toString(), '"',
        '},',
        '{',
            '"trait_type": "Y",',
            '"value": "Battles on chain"',
        '},',
        '{',
            '"trait_type": "Z",',
            '"value": "', tokenId.toString(), '"',
        '},',
        '{',
            '"trait_type": "Unit descriptor: Nodewords",',
            '"value": "Chain Battles #', tokenId.toString(), '"',
        '},',
        '{',
            '"trait_type": "Networked A",',
            '"value": "Battles on chain"',
        '},',
        '{',
            '"trait_type": "Networked B",',
            '"value": "', tokenId.toString(), '"',
        '}',
        ']',
        '}'
    );
    
    return string(
        abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(dataURI)
        )
    );
    }
    function mint() public {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        tokenIdToLevels[newItemId] = 0;
        _setTokenURI(newItemId, getTokenURI(newItemId));
    }
    // function mintMultiple(uint256 numberOfNfts) public {
        
    // }
    function train(uint256 tokenId) public {
        require(_exists(tokenId), "Please use an existing Token");
        require(ownerOf(tokenId) == msg.sender, "You must own This token to train it");
        uint256 currentLevel = tokenIdToLevels[tokenId];
        tokenIdToLevels[tokenId] = currentLevel + 1;
        _setTokenURI(tokenId, getTokenURI(tokenId)); 
    }
    // set onlyOwner
    function setChapterStorage(address _chapterStorage) public {
        chapterStorage = _chapterStorage;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

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

        _afterTokenTransfer(address(0), to, tokenId, 1);
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

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

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

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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

        _beforeTokenTransfer(from, to, tokenId, 1);

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

        _afterTokenTransfer(from, to, tokenId, 1);
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

contract ChapterStorage{
    string[] public chapters;
    
    // set to onlyOwner()
    // check if value exists - 
    constructor(){
        chapters.push('');
        chapters.push('Acknowledgment1');
        chapters.push('Acknowledgment2');
        chapters.push('Acknowledgment3');
        chapters.push('Acknowledgment4');
        chapters.push('Acknowledgment5');
        chapters.push('Acknowledgment6');
        chapters.push('Acknowledgment7');
        chapters.push('Acknowledgment8');
    }
    function set(uint256 location, string calldata _unit) external {
        chapters[location] = _unit;
    }
    //Returns the currently stored unsigned integer
    function get(uint256 location) public view returns (string memory) {
        return chapters[location];
    }

}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

contract UnitStorage{
    string[] public units;
    
    // set to onlyOwner()
    // check if value exists - 
    constructor(){
        units.push("");
        units.push("ACKNOWLEDGMENT");
        units.push("This book is the product of joint research, discovery and iteration since we began the Economic Space Agency (ECSA) project in 2015. Its composing process has consisted of diverse intellectual inputs, revelations, impasses, often heated debate and constantly-evolving analysis. It is not easy to step into the new economic space, where we constantly find ourselves in uncertain terrain. We've found out it is possible only by experimenting and risking together.");
        units.push("Many people and insights have been a part of this process; simply too many to mention here. The three of us who have authored this book see ourselves as bearers of the influences and express our deep appreciation of all engagement. There are some people who we wish to name whose intellectual input and cooperation has been vital and is directly recognizable in this book: Jonathan Beller, Fabian Bruder, Pekko Koskinen, Ben Lee, Joel Mason and Bob Meister. #livinginthespread #ECSAforever");
        units.push("We thank Matt Slater for producing an audio version of two drafts of this manuscript, Pablo Somonte Ruano for designing the cover and the figures and Stevphen Shukaitis, editor of Minor Compositions, for boldly taking on our manuscript.");
        units.push("We'd also like to thank our families and close friends for risking with us.");
        units.push("ON ECONOMIC INTELLIGENCE");
        // "_Protocols for Postacapitalist Expression _" should just be presented as italic in final SVG
        units.push("_Protocols for Postcapitalist Expression_, written by ECSA (Economic Space Agency) thinkers Dick Bryan, Jorge Lopez and Akseli Virtanen, marks an advance in the struggle for economic justice by directly addressing, and endeavoring to redress, the expropriation of the general intellect. The questions: Will the accumulated know-how of the species, alienated and, as Franco 'Bifo' Berardi (2012) put it, 'looking for a body,' lead to so-called humanity's absolute demise (along with massive unrest and incalculable ecosystemic damage)? Or, is there emerging a path towards reparations, restoration, a just economy, and thus, a sustainable planetary society? It is as if the political slogan 'No justice, no peace!' now defines the spread of the possible futures for the global timeline.");
        units.push("Significantly, _Protocols for Postcapitalist Expression_ does not give up on economic calculation or computing. It acknowledges that Economic Intelligence exists in historically sedimented economic categories and practices, but at the same time it recognizes that the form of knowledge that existing accounting creates simply cannot care about, and much less _for_, everyone. Composing a virtual computer, capitalist accounting processes allow for the judicious, that is profitable, apportioning of resources by producing a matrix of the fluctuating costs of production. Capital accumulation may be optimized by watching, in Hayek's famous phrase, 'the hands of a few dials.' However, this calculus remains an imperial project beholden to the myriad violences of racial capitalism. In order to operationalize the world, the integration of money and computing reconstitutes the world as numbers, which is to say, as information. Arguably, we could even say, information is itself a derivative of the value-form.[1] We might be forgiven for asking: does the collapse of values to exchange value, and more generally of qualities to number and thus to information have any liberatory potential whatsoever?");
        units.push("POSTCAPITALIST FUTURES");
        units.push("Those who make it to the end of the TV series _Westworld_ (Season 4), may discover where all this derivation and calculation may now be leading. Computing represents an arbitrage on intelligence that ultimately cheapens and thus discounts life. The show's verisimilitude, what we could think of as its late capitalist realism, serves as a kind of trailer for, or preamble to, what would appear - _is appearing_ - as a mutation in global consciousness and capacity, due to the financialization of knowledge. Because computing is inexorably entwined with existing markets and the statistical and predictive strategies necessary for the optimization of returns, computing, in the show at least, takes over species-being as it rapidly becomes the species-grave. The only 'creature' who will be left to remember whatever beauty, alternative values, grace and capacity for love that may have been expressed in the centuries of human emergence, is an AI.");
        units.push("'One last dangerous game,' says Dolores to herself in the emptied world at the smoking end of four seasons of _Westworld_ tragedies. What is that game? The series does not tell us, but the book before you might. Despite the real bleakness of the current world, we might propose, (and I think, must assume) that, here and now, some parts or fractions of 'us' have thus far survived the rapacious calculus of profit, and are actively seeking ways to do things otherwise. At the very least, we know that some 'we' or some parts of 'us' must now intervene if further catastrophes are to be prevented. Through the lens of economics and financial calculus, _Protocols for Postcapitalist Expression_ proposes a new form of economic intelligence and value-computing. The text proposes measures that do not collapse the qualitative concerns for well-being and being-with of those who currently are subjects of and subject to racial capitalism. ECSA has sought a way to allow for the expression and persistence of qualitative values on a computational substrate, an economic medium, such that these values are capable of (collectively) organizing economy. In theory, it becomes possible to avoid the collapse of people's various pursuits into the value-form that is accumulated by capital and institutionalized through oppression, and to denominate quantities in terms of socially agreed upon qualities or qualifications, which is to say, values. Precluding the collapse of values by money and information opens a path to avoiding the collapse of space, time, and species existence by computational capitalism.");
        units.push("This proposed re-organization of value production and thus also of sociality requires a re-casting of what we today think of as the real or natural economic forms indexed under notions including 'equity,' 'credit' and (productive) 'labor.' Analytically in _Protocols,_ these traditional terms have been decomposed, grasped as social arrangements and 'network effects,' and recomposed such that new conceptualizations and new types of actions and inflections - new socialities - become possible, while undervalued and marginalized traditional forms of sociality might thrive. Through this process of deconstruction and recomposition of actual and social computing, the text announces a possible socio-economic, computational strategy; a 'play,' for economics and for futurity, in what may well be the 'one last dangerous game.'");
        units.push("I say dangerous not only to refer to the current conditions on planet Earth, but because _Protocols_ does accept aspects of the power of the value form and of economic calculus to organize societies at scale. Even as it recognizes the necessity for constellations of qualified local inputs that can persist on an economic substrate, it accepts the need for large scale organization, economic interoperability and network-specific units of account. It actually proposes that 'economy' needs to become more granular and more generalized. What needs to be altered is _what_ the controls are, _who_ has access to them, and the kind of literacy and feedback they require. While _Protocols_ is a book of politico-economic analysis and insight, it should also be read as a script for the means to reappropriate the general intellect and thus use collective knowledge for the good of the social and ecological body. Surfaced from the unconscious operating systems of capital and reformatted, the protocols for constituting and holding equity become those for the distributed sharing of stake and thus for collectivizing risks and returns. The protocols for bank credit and monetary issuance become protocols for the peer-to-peer issuance of credit and for peer-to-peer credit clearing that is interoperable through a network of peers. The protocols for the organization of labor become protocols for the distributed assemblage of 'performances.' Units of account become qualified measures and indices, devoted to the emergence of interoperable qualitative values. Economy moves from stranger-based to interpersonal to collective; the imperial organization of commodities by the accumulation of capital becomes the collection organization of sociality by all.");
        units.push("By shifting the architecture of economy and opening it as a design space, _Protocols_ would enable, in principle, everyone to engage newly with and access differently what is, in effect, the historical objectifications of 'human' thought and practice endemic to capitalist infrastructure. But we could do so at a lower cost - to ourselves and to the lives of most of us! - and thereby, slowly, reclaim the wealth of our species capacities. Modifying accounting methods can create possibilities for the shedding of inequalities sedimented into capital. Users of the protocols, finding economic alternatives in one another, may refuse value extraction, get more of what we value for less, and be able to do so without exploiting others or being exploited. Altering the computing that backgrounds our sociality, _Protocols_ would create zones of just and convivial social production (cooperatives, ephemeral and enduring) attuned to the values of like-minded co-creators cooperating in forms of mutual aid expressive of their shared values and concerns. The result of the use of qualitative values to account for and to organize economy at once produces and requires _a redesigned economic medium_, and _a new type of economic grammar_ which utilizes different rules of composition, expression and accountability.");
        units.push("The text is the first complete edition of this new, if still rudimentary, economic grammar; it is a kind of manual for reprogramming the economic operating system. It is also a boot-strapping strategy to take back species abilities and creations that have been captured as assets (private property and monetary instruments). These assets include machinic fixed capital (platforms, code and clouds) as well as our own collateralized futures. The text, as an offer, is designed to open a spread between capitalist and postcapitalist futures. It would allow us to wager on the option that is justice (Meister).");
        units.push("Whether as software, as clouds or as platforms, capital owns and rents back to us the accumulated products of human minds - our know-how and knowledge. Resituating the abstractions of economic know-how, the ECSA Economic Space Protocol described by Bryan, Lopez and Virtanen, opens the possibility for creative capacities that are unalienated from their creators, that indeed produce a commonly-held set of capacities, a 'synthetic commons,' particularized and directed by the living concerns of those who create it. It holds out the possibility that we might cooperate in new ways and use our performative powers to wager and indeed _finance_ postcapitalist futures."); 
        units.push("Economic media, redesigned, opens a spread on the social contract\n Consider 'social media' - what can be clearly seen as a world-changing extractive technology grafted onto the sociality it at once enables and overdetermines. It is no secret that the mega-media platforms and their hardware make money while they make us sick. In this 21st century recasting and expropriation of the general intellect, now giving rise to financialized AI, social media platforms absorb communication and consciousness along with all of our struggles for meaning, pleasure, connection, fulfillment and liberation. Their interfaces, algorithms and data-bases convert our all-too-human aspirations into private property and thus into capital. Thus, the expression of our struggles for happiness, knowledge and communion with one another produce an alienated and therefore alienating wealth for others. All those desires for liberation end up producing their antithesis: capital. By turning our meanings into accumulated data that function for capital as contingent claims on value that we will produce in the future, the economic logic of social media turns any and all politics expressed by means of its platforms, including the politics of solidarity, love and living otherwise, into a practical politics of hierarchy and capitalist extraction. By converting all of our semiotic signals into financialized information, and thus into profits, 'social' media stripmines our libido, our consciousness, our imagination. In doing so, all the points of meaning and affect distributed across the socius and absorbed in one way or another by computing can thereby be grasped for performing social and organizational functions in a matrix of financialized information. This information in its architecture and management - _its organizational protocols_ - transfers value up the stack, only to devalue the increasingly abject denizens of planet Earth. In the current world operating system, for which social media forms only one, albeit _paradigmatic_, layer of calculation, the meanings we create and the emotions we experience, however real and 'immediate' they may be, are interfaces with computing; they are productive interfaces with racial capitalism. As we perform, in the very expression of our quests for life, what elsewhere I have called 'informatic labor,' we experience first hand the alienation of our performative powers in the actually existing economic media of racial capitalism, that is, computational racial capitalism.");
        // ^ revisit this paragraph later if solution \n ( `Economic media, redesigned, opens a spread on the social contract` is heading ) does not separate heading from the rest. 
        units.push("The internet promised to democratize expression by enabling publishing and indeed broadcasting from below; but nothing about the internet changed the basic economic architecture of capitalist extraction. Indeed, in decentralizing communications, the internet extended and granularized the centralizing logics and logistics of capitalism, pushing them deeper into expressivity, thought and affect. It captures mass expressivity and converts it into capital. This colonization of the imaginary and symbolic registers results in a financialized cybernetics of mind. For democratization to happen in a meaningful way, the systems of accounts inherent in many-to-many distributed media, be they networked monetary systems (USD) or communications (Facebook), must become programmable from below. For this to happen, platforms and computing must be made programmable from below. The cybernetics of economic media must be deleveraged from capital accumulation. This transformation, and how it may be achieved, is indicated in _Protocols_.");
        units.push("Why do the cybernetics of sociality matter? For our futurity and indeed for our survival, we require an alternative to monological systems of value as expressed in national monies. We require, in short, a _multi-dimensional_ modality of valuation not bound by the econometrics and informatic collapse inherent in capital. Multidimensional valuation implies the creation of eco-social relations that can dialogically express and preserve discourse-based values on an economic substrate, while being programmable in real time by any and all participants. (Before anyone up and leaves at the sudden thought of having to wake up and program, think first of an interface like _Instagram_ with a tunable economic logic built in. Think also of how these already-familiar technologies of social mediation change our experiences and actualities of relation and 'reality.') We require the power to qualify value and to allow such qualification to both persist in an economic system and be computable. Ultimately, we will require that this system itself be collectively owned; that it be a commons.");
        units.push("Robust economic media, capable of heteroglossic and dialogical forms of account, are required to create a multiperspectival values-system. These media demand far more than merely a non-national variant of monetary media expressive of the capitalist value form. While the non-national dimension of cryptocurrencies introduced a significant rupture with conventional monetary substrates, platformed as they are as national currencies on nation states, their legally recognized institutions and their military police, this ultimately simple replatforming of singular denominations on distributed computing by existing cryptocurrencies is not enough. Bitcoin did in fact break the nationally managed monopolies on 21st century monetary issuance by introducing a scalable currency(/asset/option) platformed on distributed computing, but it has done, and can do, little or nothing to challenge the monologic denomination of value as a one-dimensional, that is as a unitary, currency format. Bitcoin may contest the nation, but it, and its fetishism, is all about it being an option on the value-form as historically worked up under, and as, capitalism. The question 'Bitcoin or USD' scarcely touches the relations of production. We must see clearly that the 'disintermediation' of 'trusted third parties' and of existing states, even if it were to be accomplished, is only one part of the picture of a liberated monetary medium, which is also to say, a liberated socius. We require the possibility for _anyone_ to offer denominations of value that can be taken up by those who share such values as specified and indeed offered in the proffered denomination. Only then will we have a genuinely multiperspectival system.");
        units.push("To foreground this possibility of reprogramming a global operating system, one that is at once computational and financial, stakes a claim for a different order of significance for cryptomedia. Even Ethereum, and other 'Layer 1' projects that utilize smart contracts and allow for further token issuance, lack a robust grammar for composable asset creation and peer-to-peer issuance; a grammar that would allow for the on-chain preservation of qualities and the spontaneous creation of denominations. Outlining the emergence of a far more robust economic medium than what is currently wet dreamt by the 'when Lambo?' crypto bros going on about libertarian forms of self-sovereignty, _Protocols_ posits a transformation not just of economy but of sociality, of subjectivity, of national politics and of ecopolitics by means of the composition and recomposition of relations of production. For those actively working in the ECSA project, what unites us as current contributors, even among our many differences, is that the radical development of economic media means that the intelligence of sociality, including that which has not been subsumed, can work for the socius, rather than be captured, farmed, privatized and put back on the market in an arbitrage on knowledge, where proprietary innovation captures the returns.");
        units.push("As _Protocols_ explains, robust economic media mean that, through the equitable nomination of new asset classes and the collective denomination of values (practices which will require networked recognition, participation and validation), innovation can be collectively shared rather than capitalized. The text argues that through the sharing of stake, wealth, whose actual origins are inexorably social, can be socialized. We might add that _Protocols_ intimates that society might ultimately be decolonized because it would, after a time, no longer be organized from the imperial standpoint of Value. The deep plurality of being, though suppressed in commodity reification and egoism alike, but in fact constituting each and all, might at last be felt and actualized. It means, in short, that the other person might at last become not a limit to your freedom, but the realization of it.");
        units.push("Note that no other major crypto project addresses the world in these terms. Nor do they think very deeply, if at all, about the adjoined problem of sovereignty _and_ subjectivity, or the cybernetics thereof. It has become clearer to the participants in the ECSA project that the form many recognize as the sovereign individual is but an iteration of the value form, an avatar of capital.[2] But given these economic and formal overdeterminations of agency and the reign of this type of sovereignty, we see that history, or at least collective survival, demands better chances. We have had enough of egomania and nationalism. The significance of things on the ground must be registered and economically expressed. To those ends, _Protocols for Postcapitalist Expression_ is in pursuit of something of a different order; something that must _risk_ the increasing granularization and resolution of computing and of the economy that computing has always expressed. _Protocols_ must risk this granularization and resolution _because that is what is already happening._ But collective survival necessitates something that also simultaneously enables a _detournement_ of extant economic logics and practices. ECSA's analysis recognizes that the concentration of agency, whether in the form of the propertied individual or of the propertied immortal individuals called corporations and states, requires the collapse of the concerns of others, of their perspectives and of their information. It is precisely the refusal of that collapse that motivates the work presented in _Protocols_.");
        units.push("The book reveals another economic path than to have your interests collapsed as bank interest. The world is / we are ready for an economic and computational grammar that is answerable in new ways. That also means programmable in new ways, where programming by the many becomes both the way to answer economic precarity and the means to posit and preserve a plurality of qualitative values. We will answer economy with economy! The leveraged monologue of national monies, the leveraged computing architectures of privately-owned platforms, the near monopoly on who can issue what kinds of monies and types of financial instruments, including derivatives, must, if the people and ecosystems of Earth are to thrive, be delimited and, in their current forms, swept away. All of these media, we now perceive, are not only financial forms, but also informatic forms: programs in every sense of the word. They are integrated, interoperating systems, and are systems of account beholden, ultimately, to little other than profit in nationally-denominated monies; monies, we can remind ourselves, that are optimized by states and supported by their historical, institutionalized forms of organizational inequality, prisons and warlike foreign policy.");
        units.push("ECSA understands these systems of account, whether conceived of as interfaces, databases, financial instruments and ledgers, or as forms of money or money as capital, to be _semantic forms_; forms that have meaning and thus compatibility and commensurability with one another, but also, and as importantly, forms that put exorbitant pressure on life and _its_ meanings. Today's socio-economic systems threaten insolvency, war and extinction. They threaten all forms of meaning-making that are close to the flesh and close to the earth: desire, the imagination, consciousness, speech, writing, landscape, oceans, the body, the self. They pressure meaning, living and life, and can do so because money is composed of a set of contracts; contracts that, in effect, have subsumed, and then become, the social contract. That subsumption of the social contract by the protocols of the media of racial capitalism is the ultimate meaning of 'the dissolution of traditional societies.' The ECSA project, to create non-extractive, disalienating, just economy and sociality, is given new impetus with this volume and the promise it holds. A recasting of the current social contract has long been dreamt. At last, perhaps, we have an option on postcapitalism; one that, by reimagining the who and the how in the creation of contracts, will allow us to open and live in the spread between two basic futures: collectivism or extinction.");
        // units.push("'The one last dangerous game' proposed here feels correct and indeed compelling. It contends that, against disaster, our species has some chance of survival where the odds increase if we can use collective intelligence to wager livable futures. Whether in the form of decolonial resurgence, platform cooperatives, or hospice, I cannot say, but to offer the care the planet requires seems to involve an even deeper entry of the species and the bios into informatics and economics. It will not be lost on anyone that the digital operations of these very things have already done so much harm.");
        // units.push("The book in your hands or on your screen would be a new beginning. It represents not a settling of accounts but a new mode of accounting and of being accountable to one another. A revaluation of values becomes possible by means of what is here called an 'economic grammar,' a grammar for the assemblage of new relations of production and thus new modes of production, and new forms of (collective) relation and self-governance. The core idea is to express values differently, such that the qualitative concerns of any and potentially all members of society may be expressed at once semantically and economically on a persistent and programmable substrate. These values may be assembled by many parties and then used to coordinate performances in accord with socially agreed upon and thus collectively mandated metrics. 'Agreement' here is a semantic and an economic term that, though formally accurate, is not quite adequate to affectively express the character and indeed the _feel_ of social co-creation ECSA sees as becoming possible with a new grammar for the multitudes.");
        // units.push("As a starting point among starting points, this text comes out of years of research at ECSA and offers the most comprehensive treatment and latest refinements of a set of protocols based on an analysis of finance, monetary networks, and the extractive processes of postmodern value production. A critique of this latter, namely the capture of semiotic and other forms of social performances by ambient computing, has enabled ECSA to endeavor to liberate social performances from such capture. 'Performance' in this text has emerged, dialectically as it were, as the most general act of production; what is extracted on the job, at work, on social media, in maker-spaces and in the arts. Always dialogical, performance can be taken as a category of social interaction and world-creation that names the emergent superset for other productive capacities designated by terms including labor, attention, attention economy, cognition, cognitive capitalism and virtuosity.");
        // units.push("Counter-intuitively perhaps, the strategy includes the generalization of the power to issue - to issue financial instruments that not only fund co-creation, but create possibilities for speculation and arbitrage. A capacity to express, issue, and wager on shared futures shifts the economic ground, particularly for the smallest players who currently have no access to scripting economic protocols with which a shared future might be wagered. Can we create with and for one another's todays and tomorrows in ways that cause less suffering and are more convivial than they could be were we to attempt to do it in the capitalist markets? Can we use our powers of co-creation to siphon value out of the capitalist system in order to build a collectivist postcapitalism? To be dramatic, part of the political answer to the obscene leverage of class power and national power on the masses, is to generalize, which is to say democratize, the power to write (co-author) derivative contracts (co-author since in these protocols, all issuance is bilateral). It is time that the masses leveraged our claims, by creating our own economic networks with a new grammar and co-created, optional rules of play. This power, made possible by platforming protocols for cooperation around values creation, allows for an extended practice of community as well as the elaboration of what Randy Martin (2013a, 2015; Lee and Martin 2016) called 'social derivatives.' The social derivative is a cultural instrument that is wagered in social spaces already shot through with financial volatility. It allows marginalized groups, in Martin's words, to 'risk together to get more of what we want.' It is in this way that the logic contained in _Protocols_, that allows for the mass authorship of social derivatives, may well succeed in democratization where the internet failed.");
        // units.push("While this power for anyone to write a derivative may sound esoteric (or even impossible and/or undesirable) - and part of the book that follows this foreword _is_ somewhat esoteric - a breaking down the barriers to the publishing of derivative instruments means that, in a world already rendered precarious by the history of racial capitalism, everyone (not just elites) may be better able to manage their undeniable risk by organizing their economy, cooperatively and collectively, and in terms of what is valuable to them. If neoliberalism taught us anything, it is that the way out of the problems of capitalism cannot, and will never, be through the creation of more capitalism. That is why we have reimagined the cryptotoken as a set of programmable capabilities (agreements) that may be enabled only when recognized and thereby validated by peers. Their semantic content represents a wager that the relationship, or agreement, they formalize expresses something of value (anything whatever) to both parties. Because each party or agent is enabled in the network through composing themselves - by entering into a portfolio of such tokenized arrangements that are in principle limitless - the wealth of each agent then becomes a composite of the qualified interests of others.");
        // units.push("THE REVALUATION OF VALUE");
        // units.push("A social derivative is a wager in the cultural sphere that responds to volatility in order that a local group can 'risk together.' _Protocols_ has tried to formalize a way to express those socio-economic wagers, such that others can validate or join them non-extractively by means of their own staking and/or performance. It becomes possible, at first in principle but later practically, to nominate and denominate values and then to collectively organize socio-economic outcomes of any type that preserve, foster and realize said values: differentiable, negotiable and socially agreed upon qualitative values. This is economic expressivity. When many actors are offering such semio-economic proposals and performances on a collectively-owned economic media platform, socio-economic actors such as ourselves may engage in a multidimensional system of valuation and production attuned to anything whatever: clean beaches, dance cultures, reforestation, spoken word, prison abolition, decolonial resurgence, blood free computing, and much more. When we have a way of sharing risk, both by sharing stake (staking a performance) and/or offering performance, in a variety of qualitative outcomes by means of a scalable peer-to-peer network, we get forms of distributed risk and reward that can create a distributed form of awareness - a consciousness attuned to the specific interests of many others. This awareness results from, and constitutes, a new form of economic space and new form of economic agency: economic space agency. It will also transform subjectivity/objectivity and the membrane between self and other.");
        // units.push("Though this new economic language may sound like it requires a learning curve too steep for the 'average' person, the literacy and innovation will come, just as it did and does on paradigm shifting platforms such as Facebook, Instagram and TikTok. Here, the emerging paradigm comes with the social programmability inherent in expressivity directly linked to the programmability of economy. The postcapitalist economy will be about creating new forms of social relations; new relations of production that are qualitative and non-extractive. Collectively, we will script parameters that express our semantically based, qualitative values, and collectively we will manifest these values. We may hope, and perhaps expect, that within a few years or decades, folks will not be programming their fractal celebrity; they will be programming together the nuanced worlds they actually want to live in and creating the relationships they want to have there.");
        // units.push("There is much to learn, and much to be skeptical of. To answer the global challenges set forth by history will require the input and discernment of millions if not billions of people - it is not a technocratic endeavor. Already there are millions among us who feel the need for alternative economic forms and for a type of radical economy and/or finance that answers onthe-ground problems of access to liquidity. The movement towards basic income is just one expression of this desire. In _Protocols_ what becomes possible is _basic equity_ founded upon ones' social relations. Our requirement for emancipation is not further dispossession of others or ourselves but expanded access to the social product, particularly for those who do not have it. We agree with the growing mass need for our desires and our capacities to count and be counted in ways that remand the benefits to those who sustain the world and remake it everyday.");
        // units.push("It is not lost on us that, in the current economic calculus, a tree, an individual and even a people can be worth more dead than alive, more incarcerated or encamped then free - and we hardly need to mention deforestation, police killings, settler colonialism and genocide to make the point here. But this book, though still incomplete in significant ways and offering more of a possible way forward than any as yet definitive answer, offers what approaches a concrete plan; one that may move readers from increased eco-social literacy to active participation in building an alternative economy. It would organize social participation that will create greater literacy and expressivity even as it endeavors to collectively create and thus instantiate, a new economic medium-an economic medium for the expression and collective management of a postcapitalist economy; a medium that is socially and ecologically responsive, which is to say, increasingly non-extractive because its interfaces are made to be just. The entire project stands or falls on this wager. However, that said, the book is but a seed, one that only collective uptake, and with it collective revision, can nurture and grow.");
        // units.push("Lastly, the desire for non-, ante-, anti- and/or post-capitalism is in no way an invention of this text; what feels new here is the method. I would say that it proposes a new way to mobilize what Harney and Moten (2013) call the general antagonism, and with it, a new form of revolution. What would it be? A _detournement_ of financial processes and tools, a slow takeover of the economic operating system occupying planet earth by those whose interests have been collapsed into bank interest. Indeed, it is the _incapacity_ to do just this granular and collective reformatting of the economy that has marked the failure of previous revolutions. Thus far, beyond the initial desperation, beauty and romanticism of revolutionary movements, we have mostly had various efforts at a seizing of the state that result in the reintroduction and replication of the gendered, racial and hierarchical logics of capitalism. From the Soviets, to the PRC, to scores of post-colonial states, we are familiar with the outcomes. The limitations were both of imagination and technology; movements weighed down by default notions of centralization and bureaucratic organization, notions that informed both emergent states and the discrete state computing that would develop to run them and all the others. This time, with another century of struggle and know-how, if we all listen to history and to the claims of the denizens of Earth, things may be different.");
        // units.push("The ECSA project opens a spread on racial capitalism and endeavors to use its historically consolidated capacities (_our_ capacities), including the power of financial instruments and computing, to wager on postcapitalist outcomes. Contrary to racial capitalism, the arbitrage on intelligence proposed here is to reduce the cost to the planet for collective re-imagination and re-organization, while also collectivizing the returns on the benefits of creating more convivial forms of life. We will reduce the price of survival, in terms of violence to others, in terms of the individual requirements for the value-form (money), and in absolute terms. Perhaps we will collectivize values creation and distribution/sharing to the point of overcoming the value form of capital itself. In any case, by utilizing the accumulated knowledge implicit in financial instruments and computing derived from, but not beholden to, capitalism, we will be creating a grammar for postcapitalist economic expression. The ECSA vision might just open an option on postcapitalist futures. This option would be one where we can risk together for non-capitalist outcomes, and do so from within capital. As Jodi Melamed (2015:82) says: Marx finds value itself to be a pharmekon: it is a poison because it is a measure of how much human labor has been estranged and commodified by capital, yet it is also a medicine because it provides a way to grasp individual human efforts as alienated social forces, which revolutionary struggles can turn toward collective ends.");
        // units.push("Let's do that.");
        // units.push("INTRODUCTION");
        // units.push("CONTESTING THE CURRENT ORDER");
        // units.push("Despite a deepening climate disaster, consecutive global economic crises and a socially devastating pandemic, the last two decades have found us living in an era of capitalist triumphalism. In almost all capitalist countries, political leaders celebrate their achievements in promoting economic growth and stock market record highs while 'successfully managing' wage growth. State 'reforms' of all kinds have seen growing precarity of those whose living standard is low and growing wealth and security for those at the top. Indeed increasing inequality seems to be the current engine of economic growth and it is only in the very recent past that concerns for the biosphere have looked like a constraint on that momentum. At an individual level, it is now clear to many people that the economic aspirations of a previous generation are no longer available to the majority of the population, and especially younger people. The combination of education, finding permanent employment, and saving diligently in a bank or pension fund is no longer a formula for life security - it's not available and increasingly it's not aspired to. Education is now about debt accumulation with no guarantee it will generate the capacity for repayment; permanent employment and the idea of a predictable, secure income is, for a growing proportion of the working population, both unavailable and oppressive, and saving in banks sees negative real returns while wage payments into pension funds constrain current living standards in the name of a self-reliant old age.");
        // units.push("The starkest challenges to capitalist triumphalism have not come from what we would call the traditional 'left': the trades union or the socialist organizations. Predominantly, they have been in defensive mode, trying to hold back change. The emerging challenge is from a different source: people who simply don't want to play by the rules of capitalist economics; who want to define themselves outside its discipline and its system or rewards.");
        // units.push("Generally, these people aren't in trades union or political parties; they may not see themselves as being on the 'left.' So how do we profile these people? Perhaps they are open source developers, but their designs can't be easily monetized, or won't be funded by the internet monopolies. They may well create social benefits, but their innovation doesn't comply with corporate business plans. Perhaps they see themselves as a custodian of the commons, but can't see a way to expand the organization of that role to the scale required. Or maybe they care passionately about environmental decay and work to build biosustainability. But they know that, for all the official posturing about sustainability and concessions to green industry, the current system will never pursue deep changes that will save the planet, because returns to investors will always shout loudest in any debate. They might work in various forms of human care, for low or even zero income, and generally without much social recognition, but they know their contribution is socially essential and should be rewarded with a reasonable income. Or perhaps they work in art and design, and hear governments pronounce on the importance of cultural creation, but see them deliver miniscule funding to people who are indeed performing critical social roles.");
        // units.push("What all these endeavors have in common is that they generate social benefits but aren't recognized as profitable in a capitalist sense; indeed as not creating a surplus, to use a more general term. In a Covid-dominated world, with state fiscal austerity and protracted economic downturn awaiting, their financial future is bleak. Will audiences return with spending power; will governments still give grants; will philanthropists feel as generous?");
        // units.push("An alternative for these sorts of people could be to participate in an economy that values differently: both in the sense of different modes of calculating economic 'value' and with different collective social and ethical values. This would be an economy not driven specifically by profitability, nor reliant on state subsidies or philanthropy, but one which draws on aspirations and affects, to value social, creative and environmental benefits, without reducing all contributions into a price. Artists and designers, along with people performing care roles - care for people or for the environment - could be rewarded for what they actually contribute to society.");
        // units.push("This is the economy that we are aspiring to see built. We are pitching our network design particularly to the generation of people who want to do it differently: who know from personal experience that the conventional economic system is not serving them well individually or collectively, and are looking for ways to participate in building a collective future of their shared design.");
        // 4. deployment succeeded here
        // END OF 1st STORAGE CONTRACT
    }
    function set(uint256 location, string calldata _unit) external {
        units[location] = _unit;
    }
    //Returns the currently stored unsigned integer
    function get(uint256 location) public view returns (string memory) {
        return units[location];
    }

}

pragma solidity ^0.8.4;

library SplitSequence {
    function splitSentence(string memory sentence, uint256 maxLineLength) internal returns (string[] memory) {
        bool containsNewLines = containsPattern(sentence, "\n");

        if (containsNewLines) {
            return splitByPattern(sentence, "\n");
        }

        string[] memory words = splitByPattern(sentence, " ");
        string[] memory lines = new string[](words.length);
        string memory currentLine = "";

        uint256 lineIndex = 0;
        for (uint256 i = 0; i < words.length; i++) {
            string memory word = words[i];

            if (bytes(currentLine).length + bytes(word).length + 1 > maxLineLength) {
                lines[lineIndex] = currentLine;
                currentLine = word;
                lineIndex++;
            } else {
                if (bytes(currentLine).length > 0) {
                    currentLine = string(abi.encodePacked(currentLine, " "));
                }
                currentLine = string(abi.encodePacked(currentLine, word));
            }
        }

        if (bytes(currentLine).length > 0) {
            lines[lineIndex] = currentLine;
            lineIndex++;
        }

        return resizeArray(lines, lineIndex);
    }

    function containsPattern(string memory data, string memory pattern) private pure returns (bool) {
        bytes memory dataBytes = bytes(data);
        bytes memory patternBytes = bytes(pattern);
        uint256 dataLength = dataBytes.length;
        uint256 patternLength = patternBytes.length;

        for (uint256 i = 0; i < dataLength - patternLength + 1; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < patternLength; j++) {
                if (dataBytes[i + j] != patternBytes[j]) {
                    isMatch = false;
                    break;
                }
            }
            if (isMatch) {
                return true;
            }
        }

        return false;
    }

    function splitByPattern(string memory data, string memory pattern) private returns (string[] memory) {
        bytes memory dataBytes = bytes(data);
        bytes memory patternBytes = bytes(pattern);
        uint256 dataLength = dataBytes.length;
        uint256 patternLength = patternBytes.length;
        uint256 count = 0;

        for (uint256 i = 0; i < dataLength - patternLength + 1; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < patternLength; j++) {
                if (dataBytes[i + j] != patternBytes[j]) {
                    isMatch = false;
                    break;
                }
            }
            if (isMatch) {
                count++;
            }
        }

        string[] memory result = new string[](count + 1);
        uint256 index = 0;
        uint256 startIndex = 0;

        for (uint256 i = 0; i < dataLength - patternLength + 1; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < patternLength; j++) {
                if (dataBytes[i + j] != patternBytes[j]) {
                    isMatch = false;
                    break;
                }
            }
            if (isMatch) {
                result[index] = substring(data, startIndex, i);
                index++;
                startIndex = i + patternLength;
            }
        }

        result[index] = substring(data, startIndex, dataLength);
        return result;
    }

    function resizeArray(string[] memory array, uint256 newSize) private pure returns (string[] memory) {
        string[] memory resizedArray = new string[](newSize);
        for (uint256 i = 0; i < newSize; i++) {
            resizedArray[i] = array[i];
        }
        return resizedArray;
    }
    function substring(string memory str, uint startIndex, uint endIndex) private returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
    return string(result);
}
}

pragma solidity ^0.8.0;

library SVGGeneratorAnother {
    // we may pass an array as @argument here as an argument
    function generateSVG(string[] memory sentence) external pure returns (string memory) {
        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0 800 600">',
            '<style>text { font-family: Arial; font-size: 12px; fill: black; text-anchor: middle; dominant-baseline: middle; }</style>',
            '<text x="50%" y="50%">'
        ));

        // to be done character replacment ( )
        // here unciode to SVG
        // if (text contains  "\u2190" = \u2190) = <text> &#8592; </text>
        // if (text contains  "\u2B95" = \u2B95) = <text>&#8594; </text>)
        // if text contains (_ _)
        // if text contains `
        // if text contains \u2211 ( ∑ ) = <text>&sum;</text>
        for (uint256 i = 0; i < sentence.length; i++) {
            string memory tspan = string(abi.encodePacked(
                '<tspan x="50%" dy="', (i == 0) ? "-7em" : "1.5em", '">',
                sentence[i],
                '</tspan>'
            ));
            svg = string(abi.encodePacked(svg, tspan));
        }

        svg = string(abi.encodePacked(svg, '</text></svg>'));

        return svg;
    }
}