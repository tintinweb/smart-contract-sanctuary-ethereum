// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "ERC721URIStorage.sol";
import "Strings.sol";
import "DiceUtilities.sol";
import "Base64.sol";

contract CyberneticOrganism is ERC721URIStorage{

    uint256 public tokenCounter;

    struct Character {
        string name;

        int8 strength;
        int8 agility;
        int8 presence;
        int8 toughness;
        int8 knowledge;
        int8 hitPoints;

        //        string style;       //1-50
        //        string feature;     //1-50
        //        string obsession;   //1-50
        //        string wants;       //1-20
        //        string quirk;       //1-20
    }

    Character[] public characters;

    event strengthUpdated(uint256 tokenId, int256 strength);
    event agilityUpdated(uint256 tokenId, int256 agility);
    event dieRolled(uint roll, uint result);
    event scoreCalculated(uint roll, int8 score);
    event roll(uint roll);

    constructor () ERC721 ("CyberneticOrganism", "CY80RG"){
        tokenCounter = 0;
    }

    //    function createCollectible(string memory tokenURI, string memory name) public returns (uint256) {
    function createCollectible(string memory name) public returns (uint256) {
        uint256 newTokenId = tokenCounter;

        uint8[] memory manyRolls = DiceUtilities.dieRollsMultiple(6, 3, 5);

        int8 strength = DiceUtilities.rollToAbilityModifier(manyRolls[0]);
        emit scoreCalculated(manyRolls[0], strength);
        int8 agility = DiceUtilities.rollToAbilityModifier(manyRolls[1]);
        emit scoreCalculated(manyRolls[1], agility);
        int8 presence = DiceUtilities.rollToAbilityModifier(manyRolls[2]);
        emit scoreCalculated(manyRolls[2], presence);
        int8 toughness = DiceUtilities.rollToAbilityModifier(manyRolls[3]);
        emit scoreCalculated(manyRolls[3], toughness);
        int8 knowledge = DiceUtilities.rollToAbilityModifier(manyRolls[4]);
        emit scoreCalculated(manyRolls[4], knowledge);

        int8 hitPoints = int8(DiceUtilities.dieRoll(8)) + toughness;
        emit dieRolled(8, DiceUtilities.dieRoll(8));

        //        int8 armor = 0;

        //        uint8[] memory oneToFiftyRolls = DiceUtilities.dieRollsMultiple(50, 1, 3);
        //        string memory style = DiceUtilities.rollToStyle(oneToFiftyRolls[0]);
        //        string memory feature = DiceUtilities.rollToStyle(oneToFiftyRolls[1]);
        //        string memory obsession = DiceUtilities.rollToStyle(oneToFiftyRolls[2]);
        //
        //        uint8[] memory oneToTwentyRolls = DiceUtilities.dieRollsMultiple(20, 1, 2);
        //        string memory wants = DiceUtilities.rollToStyle(oneToTwentyRolls[0]);
        //        string memory quirk = DiceUtilities.rollToStyle(oneToTwentyRolls[1]);

        characters.push(
            Character(
                name,
                strength,
                agility,
                presence,
                toughness,
                knowledge,
                hitPoints
            //                style,
            //                feature,
            //                obsession,
            //                wants,
            //                quirk
            )
        );

        _safeMint(msg.sender, newTokenId);
        //        _setTokenURI(newTokenId, _buildTokenURI(uint256(uint160(msg.sender))));
        _setTokenURI(newTokenId, _buildTokenURI(newTokenId, msg.sender));
        tokenCounter = tokenCounter + 1;

        return newTokenId;
    }

    function getNumberOfCharacters() public view returns (uint256) {
        return characters.length;
    }

    function getCharacterStats(uint256 tokenId) public view returns (
        string memory, // name
        int, // strength
        int, // agility
        int, // presence
        int, // toughness
        int, // knowledge
        int // hitPoints
    )
    {
        // only allowed to return max of 7 attributes
        return (
        characters[tokenId].name,
        characters[tokenId].strength,
        characters[tokenId].agility,
        characters[tokenId].presence,
        characters[tokenId].toughness,
        characters[tokenId].knowledge,
        characters[tokenId].hitPoints
        );
    }

    function setStrength(uint256 tokenId, int8 strength) public {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        characters[tokenId].strength = strength;
        emit strengthUpdated(tokenId, strength);
    }

    function getStrength(uint256 tokenId) public view returns (int8){
        return characters[tokenId].strength;
    }

    function setAgility(uint256 tokenId, int8 agility) public {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        characters[tokenId].agility = agility;
        emit agilityUpdated(tokenId, agility);
    }

    function _buildTokenURI(uint256 id, address walletAddress) internal view returns (string memory) {

        // We create the an array of string with max length 17
        string[17] memory parts;

        // Part 1 is the opening of an SVG.
        // TODO: Edit the SVG as you wish. I recommend to play around with SVG on https://www.svgviewer.dev/ and figma first.
        // Change the background color, or font style.
//        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 450 350"><style>.base { stroke: "black"; font-family: monospace; font-size: 12px; }</style><rect width="100%" height="100%" fill="yellow" /><text x="10" y="20" class="base">';

        parts[1] = characters[id].name;
        parts[2] = uint256ToString(uint256(uint8(characters[id].strength)));
        parts[3] = uint256ToString(uint256(uint8(characters[id].agility)));
        parts[4] = uint256ToString(uint256(uint8(characters[id].presence)));
        parts[5] = uint256ToString(uint256(uint8(characters[id].toughness)));
        parts[6] = uint256ToString(uint256(uint8(characters[id].knowledge)));
        parts[7] = uint256ToString(uint256(uint8(characters[id].hitPoints)));

        parts[8] = "</text></svg>";

        // We do it for all and then we combine them.
        // The reason its split into two parts is due to abi.encodePacked has
        // a limit of how many arguments to accept. If too many, you will get
        // "stack too deep" error
        string memory svg = string(
            abi.encodePacked(
                parts[0],
                "Soul: 0x", _toString(walletAddress), '</text><text x="10" y="40" class="base">',
                "Name: ", parts[1], '</text><text x="10" y="60" class="base">',
                "Strength: ", parts[2], '</text><text x="10" y="80" class="base">',
                "Agility: ", parts[3], '</text><text x="10" y="100" class="base">'
            )
        );
        // add 4 more parts
        svg = string(
            abi.encodePacked(
                svg,
                "Presence: ", parts[4], '</text><text x="10" y="120" class="base">',
                "Toughness: ", parts[5],'</text><text x="10" y="140" class="base">',
                "Knowledge: ", parts[6],'</text><text x="10" y="160" class="base">',
                "Hit Points: ", parts[7],'</text><text x="10" y="180" class="base">',
                parts[8]
            )
        );

        string memory attributes = string(
            abi.encodePacked(
                '{ "trait_type": "Base", "value": "Cy80RG"}',
                ', {"trait_type": "Strength", "value": ', parts[2], '}',
                ', {"trait_type": "Agility", "value": ', parts[3], '}',
                ', {"trait_type": "Presence", "value": ', parts[4], '}',
                ', {"trait_type": "Toughness", "value": ', parts[5], '}',
                ', {"trait_type": "Knowledge", "value": ', parts[6], '}'
            )
        );
        // add 1 more
        attributes = string(
            abi.encodePacked(
                attributes,
                    ', {"trait_type": "Hit Points", "value": ', parts[7], '}'
            )
        );

        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            parts[1],
                            '", "image":"',
                            image,
                            '", "description": "I am souldbound."',
                            ', "attributes": [',
                                attributes,
                            ']}'
                        )
                    )
                )
            )
        );
    }

    function _toString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uint256ToString(uint256 number) internal pure returns (string memory) {
        // from int8 to uint8 to uint256
        if (number > 200){
            return string(abi.encodePacked("-", Strings.toString(256-number)));
        }
        return Strings.toString(number);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "ERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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

import "IERC721.sol";

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

import "IERC165.sol";

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
pragma solidity >=0.8.0 <0.9.0;

import "cyborg_tables.sol";

library DiceUtilities {

    /**
        @notice Roll dice
        @param die How many faces on the dice
        @return Die result
     */
    function dieRoll(uint die) internal view returns (uint8) {
        uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        uint8 dieResult = uint8(randomHash % die + 1);
        return dieResult;
    }

    /**
        @notice Roll dice
        @param die How many faces on the dice
        @param n How many dice to add together
        @return addedUp Total of all dice
     */
    function dieRolls(uint die, uint256 n) internal view returns (uint8 addedUp) {

        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        for (uint256 i = 0; i < n; i++) {
            addedUp += uint8(uint256(keccak256(abi.encode(randomValue, i))) % die + 1);
//            addedUp += uint8(uint256(keccak256(abi.encodePacked(randomValue, i, tx.gasprice))) % die + 1);
        }
        return addedUp;
    }

    /**
        @notice Roll dice
        @param die How many faces on the dice
        @param dice How many dice to add together
        @param n How many groups of dice to create
        @return expandedRolls Total of all dice in groups
     */
    function dieRollsMultiple(uint die, uint dice, uint256 n) internal view returns (uint8[] memory expandedRolls) {
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        expandedRolls = new uint8[](n);
        for (uint256 i = 0; i < n; i++) {
            uint8 addedUp;
            for (uint256 j = 0; j < dice; j++) {
                addedUp += uint8(uint256(keccak256(abi.encode(randomValue, i))) % die + 1);
            }
            expandedRolls[i] = addedUp;
        }
        return expandedRolls;
    }

    /**
        @notice Roll dice
        @param roll Convert dice to agility modifier
        @return agility modifier
     */
    function rollToAbilityModifier(uint roll) internal pure returns (int8) {
        if      (roll <= 4) return -3;
        else if (roll <= 6) return -2;
        else if (roll <= 8) return -1;
        else if (roll <= 12) return 0;
        else if (roll <= 14) return 1;
        else if (roll <= 17) return 2;
        else                 return 3;
    }

    /**
        @notice Roll dice
        @param roll     Convert 1-50 to Style
        @return style
     */
    function rollToStyle(uint roll) internal pure returns (string memory) {
        return cyborg_tables.getStyle(roll);
    }

    /**
        @notice Roll dice
        @param roll     Convert 1-50 to Features
        @return style
     */
    function rollToFeature(uint roll) internal pure returns (string memory) {
        return cyborg_tables.getFeature(roll);
    }

    /**
        @notice Roll dice
        @param roll     Convert 1-50 to Obsession
        @return style
     */
    function rollToObsession(uint roll) internal pure returns (string memory) {
        return cyborg_tables.getObsession(roll);
    }

    /**
        @notice Roll dice
        @param roll     Convert 1-20 to Wants
        @return style
     */
    function rollToWants(uint roll) internal pure returns (string memory) {
        return cyborg_tables.getWants(roll);
    }

    /**
        @notice Roll dice
        @param roll     Convert 1-20 to Quirk
        @return style
     */
    function rollToQuirk(uint roll) internal pure returns (string memory) {
        return cyborg_tables.getQuirk(roll);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library cyborg_tables {

    function getStyle(uint roll) public pure returns (string memory){

        string[] memory style = new string[](50);
        style[1] = "0Core";
        style[2] = "Acid panda";
        style[3] = "Beastie";
        style[4] = "Bitcrusher";
        style[5] = "Bloodsport";
        style[6] = "Cadavercore";
        style[7] = "Codefolk";
        style[8] = "Converter";
        style[9] = "Corpodrone";
        style[10] = "Cosmopunk";
        style[11] = "Cvit";
        style[12] = "Cybercrust";
        style[13] = "CyPop";
        style[14] = "Daemonista";
        style[15] = "Deathbloc";
        style[16] = "Doomtroop";
        style[17] = "Ghoul";
        style[18] = "Glitchmode";
        style[19] = "Goregrinder";
        style[20] = "Gutterscum";
        style[21] = "Hexcore";
        style[22] = "Hype street";
        style[23] = "Kill mode";
        style[24] = "Meta";
        style[25] = "Mimic";

        style[26] = "Minimal";
        style[27] = "Minotaur";
        style[28] = "Mobwave";
        style[29] = "Monsterwave";
        style[30] = "Murdercore";
        style[31] = "Necropop";
        style[32] = "Neurotripper";
        style[33] = "NuFlesh";
        style[34] = "NuGoth";
        style[35] = "NuPrep";
        style[36] = "Oceanwave";
        style[37] = "OG";
        style[38] = "Old-school cyberpunk";
        style[39] = "Orbital";
        style[40] = "Postlife";
        style[41] = "Pyrocore";
        style[42] = "Razormouth";
        style[43] = "Retro metal";
        style[44] = "Riot kid";
        style[45] = "Robomode";
        style[46] = "Roller bruiser";
        style[47] = "Technoir";
        style[48] = "Trad punk";
        style[49] = "Wallgoth";
        style[50] = "Waster";

        return style[roll];
    }

    function getFeature(uint roll) public pure returns (string memory){

        string[] memory feature = new string[](50);
        feature[1] = "Abundance of rings";
        feature[2] = "All monochrome";
        feature[3] = "Artificial skin";
        feature[4] = "Beastlike";
        feature[5] = "Broken nose";
        feature[6] = "Burn scars";
        feature[7] = "Complete hairless";
        feature[8] = "Cosmetic gills";
        feature[9] = "Covered in tattoos";
        feature[10] = "Customized voicebox";
        feature[11] = "Disheveled look";
        feature[12] = "Dollfaced";
        feature[13] = "Dueling scars";
        feature[14] = "Elaborate hairstyle";
        feature[15] = "Enhanced cheeckbones";
        feature[16] = "Fluorescent veins";
        feature[17] = "Forehead display";
        feature[18] = "Giant RCD helmet rig";
        feature[19] = "Glitterskin";
        feature[20] = "Glowing respirator";
        feature[21] = "Golden grillz";
        feature[22] = "Headband";
        feature[23] = "Heavy on the makeup";
        feature[24] = "Holomorphed face";
        feature[25] = "Interesting perfume";

        feature[26] = "Lace trimmings";
        feature[27] = "Laser branded";
        feature[28] = "Lipless-just teeth";
        feature[29] = "Mirror eyes";
        feature[30] = "More plastic than skin";
        feature[31] = "Necrotic face";
        feature[32] = "Nonhuman ears";
        feature[33] = "Palms covered in notes";
        feature[34] = "Pattern overdose";
        feature[35] = "Plenty of piercings";
        feature[36] = "Radiant eyebrows";
        feature[37] = "Rainbow haircut";
        feature[38] = "Ritual scarifications";
        feature[39] = "Robotlike";
        feature[40] = "Shoulder pads";
        feature[41] = "Subdermal implants";
        feature[42] = "Tons of jewelery";
        feature[43] = "Traditional amulets";
        feature[44] = "Translucent skin";
        feature[45] = "Transparent wear";
        feature[46] = "Unkept hair";
        feature[47] = "Unnatural eyes";
        feature[48] = "UV-inked face";
        feature[49] = "VIP lookalike";
        feature[50] = "War paints";

        return feature[roll];
    }

    function getObsession(uint roll) public pure returns (string memory){

        string[] memory obsession = new string[](50);
        obsession[1] = "Adrenaline";
        obsession[2] = "AI Poetry";
        obsession[3] = "Ammonium Chloride Candy";
        obsession[4] = "Ancient Grimoires";
        obsession[5] = "Arachnids";
        obsession[6] = "Belts";
        obsession[7] = "Blades";
        obsession[8] = "Bones";
        obsession[9] = "Customized Cars";
        obsession[10] = "Dronespotting";
        obsession[11] = "Experimental Stimuli";
        obsession[12] = "Explosives";
        obsession[13] = "Extravagant Manicure";
        obsession[14] = "Gauze and Band-aids";
        obsession[15] = "Gin";
        obsession[16] = "Graffiti";
        obsession[17] = "Hand-Pressed Synthpresso";
        obsession[18] = "Handheld Games";
        obsession[19] = "Headphones";
        obsession[20] = "History Sims";
        obsession[21] = "Interactive Holo-ink";
        obsession[22] = "Journaling";
        obsession[23] = "Masks";
        obsession[24] = "Medieval Weaponry";
        obsession[25] = "Microbots";

        obsession[26] = "Mixing Stimulants";
        obsession[27] = "Model Mech Kits";
        obsession[28] = "Obsolete Tech";
        obsession[29] = "Porcelain figurines";
        obsession[30] = "Painted Shirts";
        obsession[31] = "Puppets";
        obsession[32] = "Records";
        obsession[33] = "Recursive Synthesizers";
        obsession[34] = "Shades";
        obsession[35] = "Slacklining";
        obsession[36] = "Sneakers";
        obsession[37] = "Stim Smokes";
        obsession[38] = "Style Hopping";
        obsession[39] = "Tarot";
        obsession[40] = "Taxidermy";
        obsession[41] = "Trendy Food";
        obsession[42] = "Urban Exploring";
        obsession[43] = "Vampires vs. Werewolves";
        obsession[44] = "Vintage Army Jackets";
        obsession[45] = "Vintage TV Shows";
        obsession[46] = "Virtuaflicks";
        obsession[47] = "Virtuapals";
        obsession[48] = "Voice Modulators";
        obsession[49] = "Watches";
        obsession[50] = "Wigs";

        return obsession[roll];
    }

    function getWants(uint roll) public pure returns (string memory){

        string[] memory wants = new string[](20);
        wants[1] = "Anarchy";
        wants[2] = "Burn It All Down";
        wants[3] = "Cash";
        wants[4] = "Drugs";
        wants[5] = "Enlightenment";
        wants[6] = "Fame";
        wants[7] = "Freedom";
        wants[8] = "Fun";
        wants[9] = "Justice";
        wants[10] = "Love";
        wants[11] = "Mayhem";
        wants[12] = "Power Over Others";
        wants[13] = "Revenge";
        wants[14] = "Safety for Loved Ones";
        wants[15] = "Save the World";
        wants[16] = "See Others Fail";
        wants[17] = "Self-Control";
        wants[18] = "Self-Actualization";
        wants[19] = "Success";
        wants[20] = "To Kill";

        return wants[roll];
    }

    function getQuirk(uint roll) public pure returns (string memory){

        string[] memory quirk = new string[](20);
        quirk[1] = "Chainsmoker";
        quirk[2] = "Chew on Hair";
        quirk[3] = "Compulsive Swearing";
        quirk[4] = "Constantly Watching Holos";
        quirk[5] = "Coughs";
        quirk[6] = "Fiddles with Jewelry";
        quirk[7] = "Flirty";
        quirk[8] = "Gestures a Lot";
        quirk[9] = "Giggles Inappropriately";
        quirk[10] = "Hat/Hood and Shades, Always";
        quirk[11] = "Itchy";
        quirk[12] = "Loudly Chews Gum";
        quirk[13] = "Must Tag Every Location";
        quirk[14] = "Never Looks Anyone in the Eye";
        quirk[15] = "Nosepicker";
        quirk[16] = "Rapid Blinking";
        quirk[17] = "Reeks of Lighter Fluid";
        quirk[18] = "Scratches Facial Scar";
        quirk[19] = "Twitchy";
        quirk[20] = "Wheezes";

        return quirk[roll];
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