pragma solidity >=0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ERC721OnChainMetadata.sol";

contract CXY is ERC721OnChainMetadata {
    address cxy = 0x7b753919B953b1021A33F55671716Dc13c1eAe08;

    constructor()
        ERC721OnChainMetadata("Meet the Mint Songs Team (MP4)", "CXY")
    {}

    function claim() public onlyCxy {
        _safeMint(_msgSender(), 1, "");
    }

    modifier onlyCxy() {
        require(msg.sender == cxy, "CXY ONLY");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./OnChainMetadata.sol";

/**
 * @title On-chain metadata for ERC721,
 * making quick and easy to create html/js NFTs, parametric NFTs or any NFT with dynamic metadata.
 * @author Daniel Gonzalez Abalde aka @DGANFT aka DaniGA#9856.
 */
contract ERC721OnChainMetadata is ERC721, OnChainMetadata {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _addValue(
            _contractMetadata,
            key_contract_name,
            abi.encode("Meet the Mint Songs Team (MP4)")
        );
        _addValue(
            _contractMetadata,
            key_contract_description,
            abi.encode(
                string(
                    abi.encodePacked(
                        "This project was specifically designed with my first Ethereum collector, cxy.eth, in mind. Ethereum has become my home for creativity. Polygon is the chain I use to experiment with new types on on-chain EVM art. Ethereum is the chain I use once I'm convicted in my creative style to highlight my highest quality creations. This piece focuses on 100% on-chain metadata. Unlike most smart contracts, which return an IPFS url when platforms query the standard ERC721 tokenURI function, this smart contract stores the metadata JSON on-chain, forever. One of the most straight-forward benefits of this is the ability for other smart contracts to query specific metadata attributes. For most NFTs, other smart contracts can't know the metadata attributes because the tokenURI is just an IPFS cid. This NFT is stored, transparently & immutably on-chain. Other smart contracts will always, with 100% uptime, be able to know the metadata of this NFT and make informed decisions based on that metadata. All 100% trustlessly, unstoppably, & immutably stored on-chain. The art for this podcast nft is an MP4 visualization of the opening clip from the original podcast episode cxy.eth bought on Ethereum mainnet. You could call this a 1/1 derivative project. Thank you to cxy.eth for being my first collector on Ethereum. I made this for you <3. Also special thanks to the Mint Songs team for participating in this podcast episode. I love working with this team full 'o weapons. All royalty sales go to a shared Split contract owned equally by the Mint Songs team (0xBE2A84B8d2b09Ba4b7B8B7173D7cD64D7838C1F9). Original Mint Songs V2 purchase by cxy.eth found here: https://www.mintsongs.com/tokens/0x2B5426A5B98a3E366230ebA9f95a24f09Ae4a584/93. Zora: https://zora.co/collections/0x2B5426A5B98a3E366230ebA9f95a24f09Ae4a584/93 OpenSea: https://opensea.io/assets/ethereum/0x2b5426a5b98a3e366230eba9f95a24f09ae4a584/93"
                    )
                )
            )
        );
        _addValue(
            _contractMetadata,
            key_contract_image,
            abi.encode("ipfs://QmejE2hSTSkDEEfyg4vDfVMd28AyLEQRdhPd4LcacbR4QW")
        );
        _addValue(
            _contractMetadata,
            key_contract_external_link,
            abi.encode(
                "https://github.com/SweetmanTech/token-gated-smart-contracts"
            )
        );
        _addValue(
            _contractMetadata,
            key_contract_seller_fee_basis_points,
            abi.encode(300)
        );
        _addValue(
            _contractMetadata,
            key_contract_fee_recipient,
            abi.encode(0xBE2A84B8d2b09Ba4b7B8B7173D7cD64D7838C1F9)
        );

        _setValue(
            1,
            key_token_name,
            abi.encode("Meet the Mint Songs Team (MP4)")
        );
        _setValue(
            1,
            key_token_description,
            abi.encode(
                "This project was specifically designed with my first Ethereum collector, cxy.eth, in mind. Ethereum has become my home for creativity. Polygon is the chain I use to experiment with new types on on-chain EVM art. Ethereum is the chain I use once I'm convicted in my creative style to highlight my highest quality creations. This piece focuses on 100% on-chain metadata. Unlike most smart contracts, which return an IPFS url when platforms query the standard ERC721 tokenURI function, this smart contract stores the metadata JSON on-chain, forever. One of the most straight-forward benefits of this is the ability for other smart contracts to query specific metadata attributes. For most NFTs, other smart contracts can't know the metadata attributes because the tokenURI is just an IPFS cid. This NFT is stored, transparently & immutably on-chain. Other smart contracts will always, with 100% uptime, be able to know the metadata of this NFT and make informed decisions based on that metadata. All 100% trustlessly, unstoppably, & immutably stored on-chain. The art for this podcast nft is an MP4 visualization of the opening clip from the original podcast episode cxy.eth bought on Ethereum mainnet. You could call this a 1/1 derivative project. Thank you to cxy.eth for being my first collector on Ethereum. I made this for you <3. Also special thanks to the Mint Songs team for participating in this podcast episode. I love working with this team full 'o weapons. All royalty sales go to a shared Split contract owned equally by the Mint Songs team (0xBE2A84B8d2b09Ba4b7B8B7173D7cD64D7838C1F9). Original Mint Songs V2 purchase by cxy.eth found here: https://www.mintsongs.com/tokens/0x2B5426A5B98a3E366230ebA9f95a24f09Ae4a584/93. Zora: https://zora.co/collections/0x2B5426A5B98a3E366230ebA9f95a24f09Ae4a584/93 OpenSea: https://opensea.io/assets/ethereum/0x2b5426a5b98a3e366230eba9f95a24f09ae4a584/93"
            )
        );
        _setValue(
            1,
            key_token_image,
            abi.encode("ipfs://QmY2EdzLTtoTAKCgcomnG9W3fREwtvfJJzMNgHVmT5HbDY")
        );
        _setValue(
            1,
            key_token_animation_url,
            abi.encode("ipfs://QmZ5dCicXg4wsVEDmu7BPBjMzGME1gmkLTWmePYaHYjdpd")
        );
        setTeamTraits();
    }

    function setTeamTraits() private {
        bytes[] memory trait_types = new bytes[](13);
        bytes[] memory trait_values = new bytes[](13);
        bytes[] memory trait_display = new bytes[](13);
        trait_types[0] = abi.encode("cxy.eth");
        trait_types[1] = abi.encode("sweetman.eth");
        trait_types[2] = abi.encode("dwight torculus");
        trait_types[3] = abi.encode("garrett hughes");
        trait_types[4] = abi.encode("jazii richardson");
        trait_types[5] = abi.encode("nikki bean");
        trait_types[6] = abi.encode("nick merich");
        trait_types[7] = abi.encode("nathan pham");
        trait_types[8] = abi.encode("grant joseph");
        trait_types[9] = abi.encode("kameron hayes");
        trait_types[10] = abi.encode("jeremy stover");
        trait_types[11] = abi.encode("wayne hoover");
        trait_types[12] = abi.encode("curtis macduff");
        trait_values[0] = abi.encode("collector");
        trait_values[1] = abi.encode("host");
        trait_values[2] = abi.encode("ceo");
        trait_values[3] = abi.encode("cto");
        trait_values[4] = abi.encode("artist success manager");
        trait_values[5] = abi.encode("community manager");
        trait_values[6] = abi.encode("director of growth");
        trait_values[7] = abi.encode("product manager");
        trait_values[8] = abi.encode("product designer");
        trait_values[9] = abi.encode("software engineer");
        trait_values[10] = abi.encode("software engineer");
        trait_values[11] = abi.encode("sofware engineer");
        trait_values[12] = abi.encode("software engineer");
        trait_display[0] = abi.encode("");
        trait_display[1] = abi.encode("");
        trait_display[2] = abi.encode("");
        trait_display[3] = abi.encode("");
        trait_display[4] = abi.encode("");
        trait_display[5] = abi.encode("");
        trait_display[6] = abi.encode("");
        trait_display[7] = abi.encode("");
        trait_display[8] = abi.encode("");
        trait_display[9] = abi.encode("");
        trait_display[10] = abi.encode("");
        trait_display[11] = abi.encode("");
        trait_display[12] = abi.encode("");
        _setValues(1, key_token_attributes_trait_type, trait_types);
        _setValues(1, key_token_attributes_trait_value, trait_values);
        _setValues(1, key_token_attributes_display_type, trait_display);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "tokenId doesn't exist");
        return _createTokenURI(tokenId);
    }

    function contractURI() public view virtual returns (string memory) {
        return _createContractURI();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title NFT contract with on-chain metadata,
 * making quick and easy to create html/js NFTs, parametric NFTs or any NFT with dynamic metadata.
 * @author Daniel Gonzalez Abalde aka @DGANFT aka DaniGA#9856.
 * @dev The developer is responsible for assigning metadata for the contract (in constructor for instance)
 * and tokens (in mint function for instance), by inheriting this contract and using _addValue() and _setValue() methods.
 * The tokenURI() and contractURI() methods are responsible to call _createTokenURI() and _createContractURI() methods
 * of this contract, which convert metadata into a Base64-encoded json readable by OpenSea, LooksRare and many other NFT platforms.
 */
abstract contract OnChainMetadata {
    struct Metadata {
        uint256 keyCount; // number of metadata keys
        mapping(bytes32 => bytes[]) data; // key => values
        mapping(bytes32 => uint256) valueCount; // key => number of values
    }

    Metadata _contractMetadata; // metadata for the contract
    mapping(uint256 => Metadata) _tokenMetadata; // metadata for each token

    bytes32 constant key_contract_name = "name";
    bytes32 constant key_contract_description = "description";
    bytes32 constant key_contract_image = "image";
    bytes32 constant key_contract_external_link = "external_link";
    bytes32 constant key_contract_seller_fee_basis_points =
        "seller_fee_basis_points";
    bytes32 constant key_contract_fee_recipient = "fee_recipient";

    bytes32 constant key_token_name = "name";
    bytes32 constant key_token_description = "description";
    bytes32 constant key_token_image = "image";
    bytes32 constant key_token_animation_url = "animation_url";
    bytes32 constant key_token_external_url = "external_url";
    bytes32 constant key_token_background_color = "background_color";
    bytes32 constant key_token_youtube_url = "youtube_url";
    bytes32 constant key_token_attributes_trait_type = "trait_type";
    bytes32 constant key_token_attributes_trait_value = "trait_value";
    bytes32 constant key_token_attributes_display_type = "trait_display";

    /**
     * @dev Get the values of a token metadata key.
     * @param tokenId the token identifier.
     * @param key the token metadata key.
     */
    function _getValues(uint256 tokenId, bytes32 key)
        internal
        view
        returns (bytes[] memory)
    {
        return _tokenMetadata[tokenId].data[key];
    }

    /**
     * @dev Get the first value of a token metadata key.
     * @param tokenId the token identifier.
     * @param key the token metadata key.
     */
    function _getValue(uint256 tokenId, bytes32 key)
        internal
        view
        returns (bytes memory)
    {
        bytes[] memory array = _getValues(tokenId, key);
        if (array.length > 0) {
            return array[0];
        } else {
            return "";
        }
    }

    /**
     * @dev Get the values of a contract metadata key.
     * @param key the contract metadata key.
     */
    function _getValues(bytes32 key) internal view returns (bytes[] memory) {
        return _contractMetadata.data[key];
    }

    /**
     * @dev Get the first value of a contract metadata key.
     * @param key the contract metadata key.
     */
    function _getValue(bytes32 key) internal view returns (bytes memory) {
        bytes[] memory array = _getValues(key);
        if (array.length > 0) {
            return array[0];
        } else {
            return "";
        }
    }

    /**
     * @dev Set the values on a token metadata key.
     * @param tokenId the token identifier.
     * @param key the token metadata key.
     * @param values the token metadata values.
     */
    function _setValues(
        uint256 tokenId,
        bytes32 key,
        bytes[] memory values
    ) internal {
        Metadata storage meta = _tokenMetadata[tokenId];

        if (meta.valueCount[key] == 0) {
            _tokenMetadata[tokenId].keyCount = meta.keyCount + 1;
        }
        _tokenMetadata[tokenId].data[key] = values;
        _tokenMetadata[tokenId].valueCount[key] = values.length;
    }

    /**
     * @dev Set a single value on a token metadata key.
     * @param tokenId the token identifier.
     * @param key the token metadata key.
     * @param value the token metadata value.
     */
    function _setValue(
        uint256 tokenId,
        bytes32 key,
        bytes memory value
    ) internal {
        bytes[] memory values = new bytes[](1);
        values[0] = value;
        _setValues(tokenId, key, values);
    }

    /**
     * @dev Set values on a given Metadata instance.
     * @param meta the metadata to modify.
     * @param key the token metadata key.
     * @param values the token metadata values.
     */
    function _addValues(
        Metadata storage meta,
        bytes32 key,
        bytes[] memory values
    ) internal {
        require(
            meta.valueCount[key] == 0,
            "Metadata already contains given key"
        );
        meta.keyCount = meta.keyCount + 1;
        meta.data[key] = values;
        meta.valueCount[key] = values.length;
    }

    /**
     * @dev Set a single value on a given Metadata instance.
     * @param meta the metadata to modify.
     * @param key the token metadata key.
     * @param value the token metadata value.
     */
    function _addValue(
        Metadata storage meta,
        bytes32 key,
        bytes memory value
    ) internal {
        bytes[] memory values = new bytes[](1);
        values[0] = value;
        _addValues(meta, key, values);
    }

    function _createTokenURI(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        bytes memory attributes;
        bytes[] memory trait_type = _getValues(
            tokenId,
            key_token_attributes_trait_type
        );
        if (trait_type.length > 0) {
            attributes = "[";
            bytes[] memory trait_value = _getValues(
                tokenId,
                key_token_attributes_trait_value
            );
            bytes[] memory trait_display = _getValues(
                tokenId,
                key_token_attributes_display_type
            );
            for (uint256 i = 0; i < trait_type.length; i++) {
                attributes = abi.encodePacked(
                    attributes,
                    i > 0 ? "," : "",
                    "{",
                    bytes(trait_display[i]).length > 0
                        ? string(
                            abi.encodePacked(
                                '"display_type": "',
                                string(abi.decode(trait_display[i], (string))),
                                '",'
                            )
                        )
                        : "",
                    '"trait_type": "',
                    string(abi.decode(trait_type[i], (string))),
                    '", "value": "',
                    string(abi.decode(trait_value[i], (string))),
                    '"}'
                );
            }
            attributes = abi.encodePacked(attributes, "]");
        }

        string memory name = string(
            abi.decode(_getValue(tokenId, key_token_name), (string))
        );
        string memory description = string(
            abi.decode(_getValue(tokenId, key_token_description), (string))
        );
        bytes memory image = _getValue(tokenId, key_token_image);
        bytes memory animation_url = _getValue(
            tokenId,
            key_token_animation_url
        );
        bytes memory external_url = _getValue(tokenId, key_token_external_url);
        bytes memory background_color = _getValue(
            tokenId,
            key_token_background_color
        );
        bytes memory youtube_url = _getValue(tokenId, key_token_youtube_url);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "{",
                            '"name": "',
                            name,
                            '", ',
                            '"description": "',
                            description,
                            '"',
                            bytes(image).length > 0
                                ? string(
                                    abi.encodePacked(
                                        ', "image": "',
                                        string(abi.decode(image, (string))),
                                        '"'
                                    )
                                )
                                : "",
                            bytes(animation_url).length > 0
                                ? string(
                                    abi.encodePacked(
                                        ', "animation_url": "',
                                        string(
                                            abi.decode(animation_url, (string))
                                        ),
                                        '"'
                                    )
                                )
                                : "",
                            bytes(external_url).length > 0
                                ? string(
                                    abi.encodePacked(
                                        ', "external_url": "',
                                        string(
                                            abi.decode(external_url, (string))
                                        ),
                                        '"'
                                    )
                                )
                                : "",
                            bytes(attributes).length > 0
                                ? string(
                                    abi.encodePacked(
                                        ', "attributes": ',
                                        attributes
                                    )
                                )
                                : "",
                            bytes(background_color).length > 0
                                ? string(
                                    abi.encodePacked(
                                        ', "background_color": ',
                                        string(
                                            abi.decode(
                                                background_color,
                                                (string)
                                            )
                                        )
                                    )
                                )
                                : "",
                            bytes(youtube_url).length > 0
                                ? string(
                                    abi.encodePacked(
                                        ', "youtube_url": ',
                                        string(
                                            abi.decode(youtube_url, (string))
                                        )
                                    )
                                )
                                : "",
                            "}"
                        )
                    )
                )
            );
    }

    function _createContractURI()
        internal
        view
        virtual
        returns (string memory)
    {
        bytes memory name = _getValue(key_contract_name);
        bytes memory description = _getValue(key_contract_description);
        bytes memory image = _getValue(key_contract_image);
        bytes memory external_url = _getValue(key_contract_external_link);
        bytes memory seller_fee_basis_points = _getValue(
            key_contract_seller_fee_basis_points
        );
        bytes memory fee_recipient = _getValue(key_contract_fee_recipient);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "{",
                            '"name": "',
                            string(abi.decode(name, (string))),
                            '"',
                            bytes(description).length > 0
                                ? string(
                                    abi.encodePacked(
                                        ', "description": "',
                                        string(
                                            abi.decode(description, (string))
                                        ),
                                        '"'
                                    )
                                )
                                : "",
                            bytes(image).length > 0
                                ? string(
                                    abi.encodePacked(
                                        ', "image": "',
                                        string(abi.decode(image, (string))),
                                        '"'
                                    )
                                )
                                : "",
                            bytes(external_url).length > 0
                                ? string(
                                    abi.encodePacked(
                                        ', "external_link": "',
                                        string(
                                            abi.decode(external_url, (string))
                                        ),
                                        '"'
                                    )
                                )
                                : "",
                            bytes(seller_fee_basis_points).length > 0
                                ? string(
                                    abi.encodePacked(
                                        ', "seller_fee_basis_points": ',
                                        Strings.toString(
                                            uint256(
                                                abi.decode(
                                                    seller_fee_basis_points,
                                                    (uint256)
                                                )
                                            )
                                        ),
                                        ""
                                    )
                                )
                                : "",
                            bytes(fee_recipient).length > 0
                                ? string(
                                    abi.encodePacked(
                                        ', "fee_recipient": "',
                                        Strings.toHexString(
                                            uint256(
                                                uint160(
                                                    address(
                                                        abi.decode(
                                                            fee_recipient,
                                                            (address)
                                                        )
                                                    )
                                                )
                                            ),
                                            20
                                        ),
                                        '"'
                                    )
                                )
                                : "",
                            "}"
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

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