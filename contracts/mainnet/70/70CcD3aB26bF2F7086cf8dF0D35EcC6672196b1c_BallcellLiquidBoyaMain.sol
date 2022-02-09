// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// 🤛 👁👄👁 🤜 < Let's enjoy Solidity!!

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/BallcellLiquidBoyaParameters.sol";
import "./BallcellLiquidBoyaMainCreateParameters.sol";
import "./BallcellLiquidBoyaMainMetadata.sol";

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

contract OwnableDelegateProxy {}

contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

contract BallcellLiquidBoyaMain is ERC721Enumerable, Ownable {
	uint256 private constant _TOKEN_SUPPLY_AUCTION = 1;
	uint256 private constant _TOKEN_SUPPLY_PROMOTION = 33;
	uint256 private constant _TOKEN_SUPPLY_REWARD = 66;
	uint256 private constant _TOKEN_SUPPLY_HOMEPAGE = 2900;
	uint256 private constant _HOMEPAGE_AMOUNT = 5;
	uint256 private constant _HOMEPAGE_PRICE = 0.03 ether;

	address private _addressProxyRegistry;
	address private _addressContractImage;
	uint256 private _passcode = 0;

	uint256 private _currentTokenId = 0;
	uint256 private _tokenCountHomepage = 0;
	uint256 private _tokenCountPromotion = 0;
	uint256 private _tokenCountReward = 0;

	bool private _saleIsActive = false;
	bool private _saleIsFinish = false;

	bool private _canceled = false;
	bool private _revealed = false;
	string private _seedPhrase = "";
	bytes32 private _seedNumber = 0;

    mapping(uint256 => string) private _tokenNames;

	constructor() ERC721("BallcellLiquidBoya", "BCL") {
		_mintAuction();
	}

	function settingAddressProxyRegistry(address value) public {
		require(_addressProxyRegistry == 0x0000000000000000000000000000000000000000, "already set");
		_addressProxyRegistry = value;
	}

	function settingAddressContractImage(address value) public {
		require(_addressContractImage == 0x0000000000000000000000000000000000000000, "already set");
		_addressContractImage = value;
	}

	function settingPasscode(uint256 value) public {
		require(_passcode == 0, "already set");
		_passcode = value;
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	// ホームページで情報を取得できるようにする関数
	uint private constant _keyMintTotal = 0;
	uint private constant _keyMintRemains = 1;
	uint private constant _keyMintPurchasable = 2;
	uint private constant _keyMintPricePerToken = 3;
	uint private constant _keyMintFlagActive = 4;
	uint private constant _keyMintFlagFinish = 5;
	function getMintInformation() public view returns (uint256[6] memory) {
		uint256[6] memory array;
		uint256 mintTotal = _TOKEN_SUPPLY_AUCTION + _TOKEN_SUPPLY_PROMOTION + _TOKEN_SUPPLY_REWARD + _TOKEN_SUPPLY_HOMEPAGE;
		uint256 mintRemains = _TOKEN_SUPPLY_HOMEPAGE - _tokenCountHomepage;
		uint256 mintPurchasable = _HOMEPAGE_AMOUNT;
		array[_keyMintTotal] = mintTotal;
		array[_keyMintRemains] = mintRemains;
		array[_keyMintPurchasable] = mintPurchasable < mintRemains ? mintPurchasable : mintRemains;
		array[_keyMintPricePerToken] = _HOMEPAGE_PRICE;
		array[_keyMintFlagActive] = _saleIsActive ? 1 : 0;
		array[_keyMintFlagFinish] = _saleIsFinish ? 1 : 0;
		return array;
	}

	function getRemainPromotion() public view returns (uint256) {
		return _TOKEN_SUPPLY_PROMOTION - _tokenCountPromotion;
	}

	function getRemainReward() public view returns (uint256) {
		return _TOKEN_SUPPLY_REWARD - _tokenCountReward;
	}

	function _tokenParameters(uint256 tokenId) private view returns (BallcellLiquidBoyaParameters.Parameters memory) {
		require(_exists(tokenId), "non existent token");
		BallcellLiquidBoyaMainCreateParameters.Arguments memory arguments;
		arguments.canceled = _canceled;
		arguments.revealed = _revealed;
		arguments.tokenId = tokenId;
		arguments.passcode = _passcode;
		arguments.owner = _exists(tokenId) ? ownerOf(tokenId) : address(0);
		arguments.seedPhrase = _seedPhrase;
		arguments.seedNumber = _seedNumber;
		arguments.isSpecial = tokenId <= _TOKEN_SUPPLY_AUCTION + _TOKEN_SUPPLY_PROMOTION + _TOKEN_SUPPLY_REWARD;
		return BallcellLiquidBoyaMainCreateParameters.createParameters(arguments);
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		BallcellLiquidBoyaParameters.Parameters memory parameters = _tokenParameters(tokenId);
		return BallcellLiquidBoyaMainMetadata.metadata(parameters, _tokenNames[tokenId], _addressContractImage);
	}

	function tokenArray(uint256 tokenId) public view returns (uint16[18] memory) {
		BallcellLiquidBoyaParameters.Parameters memory parameters = _tokenParameters(tokenId);
		return BallcellLiquidBoyaParameters.createArray(parameters);
	}

	function setSaleIsActive(bool value) public onlyOwner {
		require(!_saleIsFinish, "Sale has already finished");
		require(!_saleIsActive || !value, "Sale has already started");
		require(_saleIsActive || value, "Sale has already stopped");
		_saleIsActive = value;
	}

	// 永遠に販売を終了する関数
	function setSaleIsFinish() public onlyOwner {
		require(!_saleIsFinish, "Sale has already finished");
		_saleIsFinish= true;
	}

	// testnetで存在を隠蔽する関数
	function setCancel(bool value) public onlyOwner {
		require(!_canceled || !value, "already canceled");
		require(_canceled || value, "not canceled");
		_canceled = value;
	}

	function reveal(string memory seedPhrase) public onlyOwner {
		require(!_revealed, "already revealed");
		_revealed = true;
		_seedPhrase = seedPhrase;
		_seedNumber = blockhash(block.number - 1);
	}

	function rename(uint256 tokenId, string memory tokenName) public onlyOwner {
		bytes32 hashCurr = keccak256(abi.encodePacked(_tokenNames[tokenId]));
		bytes32 hashNext = keccak256(abi.encodePacked(tokenName));
		require(hashCurr != hashNext, "same name");
		_tokenNames[tokenId] = tokenName;
	}

	function _mintAuction() private onlyOwner {
		uint256 tokenAmountMint = _TOKEN_SUPPLY_AUCTION;
		uint256 tokenOffset = 1;
		for (uint256 i = 0; i < tokenAmountMint; i++) {
			address minter = msg.sender;
			uint256 tokenId = tokenOffset + i;
			_safeMint(minter, tokenId);
			_tokenNames[tokenId] = "origin";
		}
	}

	function mintPromotion(address[] memory winner, string memory tokenName) public onlyOwner {
		uint256 tokenAmountMint = winner.length;
		uint256 tokenAmountExist = _tokenCountPromotion;
		uint256 tokenSupply = _TOKEN_SUPPLY_PROMOTION;
		uint256 tokenOffset = 1 + tokenAmountExist + _TOKEN_SUPPLY_AUCTION;
		require(tokenAmountExist + tokenAmountMint <= tokenSupply, "token stock shortage");
		for (uint256 i = 0; i < tokenAmountMint; i++) {
			address minter = winner[i];
			uint256 tokenId = tokenOffset + i;
			_safeMint(minter, tokenId);
			_tokenNames[tokenId] = tokenName;
		}
		_tokenCountPromotion = tokenAmountExist + tokenAmountMint;
	}

	function mintReward(address[] memory winner, string memory tokenName) public onlyOwner {
		uint256 tokenAmountMint = winner.length;
		uint256 tokenAmountExist = _tokenCountReward;
		uint256 tokenSupply = _TOKEN_SUPPLY_REWARD;
		uint256 tokenOffset = 1 + tokenAmountExist + _TOKEN_SUPPLY_AUCTION + _TOKEN_SUPPLY_PROMOTION;
		require(tokenAmountExist + tokenAmountMint <= tokenSupply, "token stock shortage");
		for (uint256 i = 0; i < tokenAmountMint; i++) {
			address minter = winner[i];
			uint256 tokenId = tokenOffset + i;
			_safeMint(minter, tokenId);
			_tokenNames[tokenId] = tokenName;
		}
		_tokenCountReward = tokenAmountExist + tokenAmountMint;
	}

	function mintHomepage(uint tokenAmountMint) public payable {
		require(!_saleIsFinish, "Sale has finished");
		require(_saleIsActive, "Sale has stopped");
		uint256 tokenAmountExist = _tokenCountHomepage;
		uint256 tokenSupply = _TOKEN_SUPPLY_HOMEPAGE;
		uint256 tokenOffset = 1 + tokenAmountExist + _TOKEN_SUPPLY_AUCTION + _TOKEN_SUPPLY_PROMOTION + _TOKEN_SUPPLY_REWARD;
		require(tokenAmountMint <= _HOMEPAGE_AMOUNT, "incorrect token amount");
		require(tokenAmountExist + tokenAmountMint <= tokenSupply, "token stock shortage");
		require(tokenAmountMint * _HOMEPAGE_PRICE <= msg.value, "incorrect ether amount");
		address minter = msg.sender;
		for (uint256 i = 0; i < tokenAmountMint; i++) {
			uint256 tokenId = tokenOffset + i;
			_safeMint(minter, tokenId);
		}
		_tokenCountHomepage = tokenAmountExist + tokenAmountMint;
	}

	function withdraw() public onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, "no balance");
		payable(msg.sender).transfer(balance);
	}

	function isApprovedForAll(address owner, address operator) override public view returns (bool) {
		if (_addressProxyRegistry == address(0)) { return super.isApprovedForAll(owner, operator); }
		ProxyRegistry proxyRegistry = ProxyRegistry(_addressProxyRegistry);
		if (address(proxyRegistry.proxies(owner)) == operator) { return true; }
		return super.isApprovedForAll(owner, operator);
	}
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

// SPDX-License-Identifier: MIT

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
     * by default, can be overriden in child contracts.
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 🤛 👁👄👁 🤜 < Let's enjoy Solidity!!

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

library BallcellLiquidBoyaParameters {
	struct Parameters {
		bool revealed;
		uint256 tokenId;
		uint256 passcode;

		uint256 rotation;
		uint256 angle;
		uint256 distance;
		uint256 swing;
		uint256 radiusBody;
		uint256 radiusFoot;
		uint256 radiusHand;
		uint256 radiusHead;

		uint256 colorHueBody;
		uint256 colorHueRFoot;
		uint256 colorHueLFoot;
		uint256 colorHueRHand;
		uint256 colorHueLHand;
		uint256 colorHueHead;
		uint256 colorHueREye;
		uint256 colorHueLEye;
		uint256 colorLightnessBody;
		uint256 colorLightnessEye;

		bool colorFlagOne;
		ColorTypeBody colorTypeBody;
		ColorTypeEye colorTypeEye;

		BackgroundType backgroundType;
		uint256 backgroundColor;
		uint256 backgroundRandom;
	}

	enum ColorTypeBody { Neutral, Bright, Dark }
	enum ColorTypeEye { Monotone, Single, Double }
	enum BackgroundType { None, Single, Circle, PolkaDot, GradationLinear, Lgbt }

	uint constant _keyRotation = 0;
	uint constant _keyAngle = 1;
	uint constant _keyDistance = 2;
	uint constant _keySwing = 3;
	uint constant _keyRadiusBody = 4;
	uint constant _keyRadiusFoot = 5;
	uint constant _keyRadiusHand = 6;
	uint constant _keyRadiusHead = 7;
	uint constant _keyColorHueBody = 8;
	uint constant _keyColorHueRFoot = 9;
	uint constant _keyColorHueLFoot = 10;
	uint constant _keyColorHueRHand = 11;
	uint constant _keyColorHueLHand = 12;
	uint constant _keyColorHueHead = 13;
	uint constant _keyColorHueREye = 14;
	uint constant _keyColorHueLEye = 15;
	uint constant _keyColorLightnessBody = 16;
	uint constant _keyColorLightnessEye = 17;
	function createArray(Parameters memory parameters) internal pure returns (uint16[18] memory) {
		uint16[18] memory array;
		array[_keyRotation] = uint16(parameters.rotation);
		array[_keyAngle] = uint16(parameters.angle);
		array[_keyDistance] = uint16(parameters.distance);
		array[_keySwing] = uint16(parameters.swing);
		array[_keyRadiusBody] = uint16(parameters.radiusBody);
		array[_keyRadiusFoot] = uint16(parameters.radiusFoot);
		array[_keyRadiusHand] = uint16(parameters.radiusHand);
		array[_keyRadiusHead] = uint16(parameters.radiusHead);
		array[_keyColorHueBody] = uint16(parameters.colorHueBody);
		array[_keyColorHueRFoot] = uint16(parameters.colorHueRFoot);
		array[_keyColorHueLFoot] = uint16(parameters.colorHueLFoot);
		array[_keyColorHueRHand] = uint16(parameters.colorHueRHand);
		array[_keyColorHueLHand] = uint16(parameters.colorHueLHand);
		array[_keyColorHueHead] = uint16(parameters.colorHueHead);
		array[_keyColorHueREye] = uint16(parameters.colorHueREye);
		array[_keyColorHueLEye] = uint16(parameters.colorHueLEye);
		array[_keyColorLightnessBody] = uint16(parameters.colorLightnessBody);
		array[_keyColorLightnessEye] = uint16(parameters.colorLightnessEye);
		return array;
	}
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 🤛 👁👄👁 🤜 < Let's enjoy Solidity!!

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

import "../common/BallcellLiquidBoyaParameters.sol";
import "../../utils/Random.sol";

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

library BallcellLiquidBoyaMainCreateParameters {
	struct Arguments {
		bool canceled;
		bool revealed;
		uint256 tokenId;
		uint256 passcode;
		address owner;
		string seedPhrase;
		bytes32 seedNumber;
		bool isSpecial;
	}

	function createParameters(Arguments memory arguments) internal pure returns (BallcellLiquidBoyaParameters.Parameters memory) {
		BallcellLiquidBoyaParameters.Parameters memory parameters;
		parameters.revealed = arguments.revealed;
		parameters.tokenId = arguments.tokenId;
		parameters.passcode = arguments.passcode;

		if (arguments.canceled) {
			// キャンセルパペット
			parameters.rotation = 60;
			parameters.angle = 60;
			parameters.distance = 9;
			parameters.swing = 0;
			parameters.radiusBody = 1;
			parameters.radiusFoot = 1;
			parameters.radiusHand = 1;
			parameters.radiusHead = 6;
			parameters.colorHueBody = 0;
			parameters.colorHueRFoot = 0;
			parameters.colorHueLFoot = 0;
			parameters.colorHueRHand = 0;
			parameters.colorHueLHand = 0;
			parameters.colorHueHead = 0;
			parameters.colorHueREye = 0;
			parameters.colorHueLEye = 0;
			parameters.colorLightnessBody = 100;
			parameters.colorLightnessEye = 0;
			parameters.colorFlagOne = true;
			parameters.colorTypeBody = BallcellLiquidBoyaParameters.ColorTypeBody.Neutral;
			parameters.colorTypeEye = BallcellLiquidBoyaParameters.ColorTypeEye.Monotone;
			parameters.backgroundType = BallcellLiquidBoyaParameters.BackgroundType.None;
			parameters.backgroundColor = 0;
			parameters.backgroundRandom = 0;
		} else if (!arguments.revealed) {
			// 開示前のダミーパペット
			Random.Status memory randomStatus;
			Random.init(randomStatus, uint256(keccak256(abi.encodePacked(arguments.tokenId))));
			parameters.rotation = Random.get(randomStatus) % (120 + 1);
			parameters.angle = Random.get(randomStatus) % (90 + 1);
			parameters.distance = 2;
			parameters.swing = 10;
			parameters.radiusBody = 5;
			parameters.radiusFoot = 3;
			parameters.radiusHand = 2;
			parameters.radiusHead = 6;
			parameters.colorHueBody = 0;
			parameters.colorHueRFoot = 0;
			parameters.colorHueLFoot = 0;
			parameters.colorHueRHand = 0;
			parameters.colorHueLHand = 0;
			parameters.colorHueHead = 0;
			parameters.colorHueREye = 0;
			parameters.colorHueLEye = 0;
			parameters.colorLightnessBody = 0;
			parameters.colorLightnessEye = 100;
			parameters.colorFlagOne = true;
			parameters.colorTypeBody = BallcellLiquidBoyaParameters.ColorTypeBody.Neutral;
			parameters.colorTypeEye = BallcellLiquidBoyaParameters.ColorTypeEye.Monotone;
			parameters.backgroundType = BallcellLiquidBoyaParameters.BackgroundType.None;
			parameters.backgroundColor = 0;
			parameters.backgroundRandom = 0;
		} else if (arguments.tokenId == 1) {
			// tokenId=1 オリジンパペット
			parameters.rotation = 90;
			parameters.angle = 60;
			parameters.distance = 2;
			parameters.swing = 10;
			parameters.radiusBody = 5;
			parameters.radiusFoot = 3;
			parameters.radiusHand = 2;
			parameters.radiusHead = 6;
			parameters.colorHueBody = 0;
			parameters.colorHueRFoot = 0;
			parameters.colorHueLFoot = 0;
			parameters.colorHueRHand = 0;
			parameters.colorHueLHand = 0;
			parameters.colorHueHead = 0;
			parameters.colorHueREye = 0;
			parameters.colorHueLEye = 0;
			parameters.colorLightnessBody = 50;
			parameters.colorLightnessEye = 0;
			parameters.colorFlagOne = true;
			parameters.colorTypeBody = BallcellLiquidBoyaParameters.ColorTypeBody.Neutral;
			parameters.colorTypeEye = BallcellLiquidBoyaParameters.ColorTypeEye.Monotone;
			parameters.backgroundType = BallcellLiquidBoyaParameters.BackgroundType.None;
			parameters.backgroundColor = 0;
			parameters.backgroundRandom = 0;
		} else {
			// 乱数の準備
			Random.Status memory randomStatusToken;
			Random.Status memory randomStatusOwner;
			bytes memory seedToken = abi.encodePacked(arguments.seedPhrase, arguments.seedNumber, arguments.tokenId);
			bytes memory seedOwner = abi.encodePacked(arguments.seedPhrase, arguments.seedNumber, arguments.owner);
			Random.init(randomStatusToken, uint256(keccak256(seedToken)));
			Random.init(randomStatusOwner, uint256(keccak256(seedOwner)));

			// パラメータテーブル
			uint8[20][5] memory table;
			table[0] = [0, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 4, 5, 6, 7, 8, 9];
			table[1] = [3, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 7, 7, 8, 9];
			table[2] = [1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4];
			table[3] = [1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4];
			table[4] = [3, 4, 4, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 8, 8, 9];

			// トークンに紐づくパペット形状
			parameters.rotation = Random.get(randomStatusToken) % (120 + 1);
			parameters.angle = Random.get(randomStatusToken) % (90 + 1);
			parameters.distance = table[0][Random.get(randomStatusToken) % 20];
			parameters.swing = Random.get(randomStatusToken) % (40 + 1);
			parameters.radiusBody = table[1][Random.get(randomStatusToken) % 20];
			parameters.radiusFoot = table[2][Random.get(randomStatusToken) % 20];
			parameters.radiusHand = table[3][Random.get(randomStatusToken) % 20];
			parameters.radiusHead = table[4][Random.get(randomStatusToken) % 20];

			// オーナーに紐づくパペット色
			parameters.colorHueBody = Random.get(randomStatusOwner) % 360;
			parameters.colorHueRFoot = Random.get(randomStatusOwner) % 360;
			parameters.colorHueLFoot = Random.get(randomStatusOwner) % 360;
			parameters.colorHueRHand = Random.get(randomStatusOwner) % 360;
			parameters.colorHueLHand = Random.get(randomStatusOwner) % 360;
			parameters.colorHueHead = Random.get(randomStatusOwner) % 360;
			parameters.colorHueREye = Random.get(randomStatusOwner) % 360;
			parameters.colorHueLEye = Random.get(randomStatusOwner) % 360;

			// トークンに紐づくパペット特殊色 単色
			// 単色パペットは激レアなので、レアリティの存在しないホームページのミントからは出現しない。
			if (arguments.isSpecial && Random.get(randomStatusToken) % 10 == 0) {
				parameters.colorFlagOne = true;
				parameters.colorHueRFoot = parameters.colorHueBody;
				parameters.colorHueLFoot = parameters.colorHueBody;
				parameters.colorHueRHand = parameters.colorHueBody;
				parameters.colorHueLHand = parameters.colorHueBody;
				parameters.colorHueHead = parameters.colorHueBody;
			} else {
				parameters.colorFlagOne = false;
			}

			// トークンに紐づくパペット特殊色 輝度
			if (Random.get(randomStatusToken) % 2 == 0) {
				parameters.colorTypeBody = BallcellLiquidBoyaParameters.ColorTypeBody.Neutral;
				parameters.colorLightnessBody = 50;
				parameters.colorLightnessEye = 20;
			} else if (Random.get(randomStatusToken) % 2 == 0) {
				parameters.colorTypeBody = BallcellLiquidBoyaParameters.ColorTypeBody.Bright;
				parameters.colorLightnessBody = 80;
				parameters.colorLightnessEye = 20;
			} else {
				parameters.colorTypeBody = BallcellLiquidBoyaParameters.ColorTypeBody.Dark;
				parameters.colorLightnessBody = 20;
				parameters.colorLightnessEye = 80;
			}

			// トークンに紐づくパペット特殊色 目
			if (Random.get(randomStatusToken) % 2 == 0) {
				parameters.colorTypeEye = BallcellLiquidBoyaParameters.ColorTypeEye.Monotone;
				parameters.colorHueREye = 0;
				parameters.colorHueLEye = 0;
				parameters.colorLightnessEye = parameters.colorLightnessEye > 50 ? 100 : 0;
			} else if (Random.get(randomStatusToken) % 2 == 0) {
				parameters.colorTypeEye = BallcellLiquidBoyaParameters.ColorTypeEye.Single;
				parameters.colorHueLEye = parameters.colorHueREye;
			} else {
				parameters.colorTypeEye = BallcellLiquidBoyaParameters.ColorTypeEye.Double;
			}

			// 背景パラメータ
			uint backgroundType = Random.get(randomStatusToken) % 4;
			if (backgroundType == 0) { parameters.backgroundType = BallcellLiquidBoyaParameters.BackgroundType.None; }
			if (backgroundType == 1) { parameters.backgroundType = BallcellLiquidBoyaParameters.BackgroundType.Single; }
			if (backgroundType == 2) { parameters.backgroundType = BallcellLiquidBoyaParameters.BackgroundType.Circle; }
			if (backgroundType == 3) { parameters.backgroundType = BallcellLiquidBoyaParameters.BackgroundType.PolkaDot; }
			parameters.backgroundColor = Random.get(randomStatusToken) % 360;
			parameters.backgroundRandom = Random.get(randomStatusToken);
		}

		return parameters;
	}
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 🤛 👁👄👁 🤜 < Let's enjoy Solidity!!

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

import "@openzeppelin/contracts/utils/Strings.sol";
import "../common/BallcellLiquidBoyaParameters.sol";
import "../../utils/Base64.sol";

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

interface _BallcellLiquidBoyaImage {
	function svg(BallcellLiquidBoyaParameters.Parameters memory parameters) external pure returns (bytes memory);
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

library BallcellLiquidBoyaMainMetadata {
	function metadata(BallcellLiquidBoyaParameters.Parameters memory parameters, string memory tokenName, address addressContractImage) internal pure returns (string memory) {
		bytes memory temporary = "{";
		temporary = abi.encodePacked(temporary, '"name": "', _name(parameters, tokenName), '", ');
		temporary = abi.encodePacked(temporary, '"description": "', _description(), '", ');
		temporary = abi.encodePacked(temporary, '"attributes": ', _attributes(parameters), ", ");
		temporary = abi.encodePacked(temporary, '"image": "', _image(parameters, addressContractImage), '"');
		temporary = abi.encodePacked(temporary, "}");
		return string(abi.encodePacked("data:application/json;base64,", Base64.encode(temporary)));
	}

	function _name(BallcellLiquidBoyaParameters.Parameters memory parameters, string memory tokenName) private pure returns (bytes memory) {
		if (bytes(tokenName).length == 0) { tokenName = "liquid boya"; }
		return abi.encodePacked(tokenName, " #", Strings.toString(parameters.tokenId));
	}

	function _description() private pure returns (bytes memory) {
		return "ballcell liquid boya is a full on-chain NFT.";
	}

	function _attributes(BallcellLiquidBoyaParameters.Parameters memory parameters) private pure returns (bytes memory) {
		if (!parameters.revealed) { return "[]"; }
		bytes memory temporary = "[";
		if (parameters.radiusBody < 5) { temporary = abi.encodePacked(temporary, '{"trait_type":"body size","value":"small"}', ","); }
		if (parameters.radiusBody == 5) { temporary = abi.encodePacked(temporary, '{"trait_type":"body size","value":"normal"}', ","); }
		if (parameters.radiusBody > 5) { temporary = abi.encodePacked(temporary, '{"trait_type":"body size","value":"big"}', ","); }
		if (parameters.radiusFoot < 3) { temporary = abi.encodePacked(temporary, '{"trait_type":"foot size","value":"small"}', ","); }
		if (parameters.radiusFoot == 3) { temporary = abi.encodePacked(temporary, '{"trait_type":"foot size","value":"normal"}', ","); }
		if (parameters.radiusFoot > 3) { temporary = abi.encodePacked(temporary, '{"trait_type":"foot size","value":"big"}', ","); }
		if (parameters.radiusHand < 2) { temporary = abi.encodePacked(temporary, '{"trait_type":"hand size","value":"small"}', ","); }
		if (parameters.radiusHand == 2) { temporary = abi.encodePacked(temporary, '{"trait_type":"hand size","value":"normal"}', ","); }
		if (parameters.radiusHand > 2) { temporary = abi.encodePacked(temporary, '{"trait_type":"hand size","value":"big"}', ","); }
		if (parameters.radiusHead < 6) { temporary = abi.encodePacked(temporary, '{"trait_type":"head size","value":"small"}', ","); }
		if (parameters.radiusHead == 6) { temporary = abi.encodePacked(temporary, '{"trait_type":"head size","value":"normal"}', ","); }
		if (parameters.radiusHead > 6) { temporary = abi.encodePacked(temporary, '{"trait_type":"head size","value":"big"}', ","); }
		if (parameters.colorTypeBody == BallcellLiquidBoyaParameters.ColorTypeBody.Neutral) { temporary = abi.encodePacked(temporary, '{"trait_type":"body color","value":"neutral"}', ","); }
		if (parameters.colorTypeBody == BallcellLiquidBoyaParameters.ColorTypeBody.Bright) { temporary = abi.encodePacked(temporary, '{"trait_type":"body color","value":"bright"}', ","); }
		if (parameters.colorTypeBody == BallcellLiquidBoyaParameters.ColorTypeBody.Dark) { temporary = abi.encodePacked(temporary, '{"trait_type":"body color","value":"dark"}', ","); }
		if (parameters.colorTypeEye == BallcellLiquidBoyaParameters.ColorTypeEye.Monotone) { temporary = abi.encodePacked(temporary, '{"trait_type":"eye color","value":"monotone"}', ","); }
		if (parameters.colorTypeEye == BallcellLiquidBoyaParameters.ColorTypeEye.Single) { temporary = abi.encodePacked(temporary, '{"trait_type":"eye color","value":"single"}', ","); }
		if (parameters.colorTypeEye == BallcellLiquidBoyaParameters.ColorTypeEye.Double) { temporary = abi.encodePacked(temporary, '{"trait_type":"eye color","value":"double"}', ","); }
		if (parameters.colorFlagOne) { temporary = abi.encodePacked(temporary, '{"trait_type":"special","value":"one color"}', ","); }
		if (parameters.backgroundType == BallcellLiquidBoyaParameters.BackgroundType.None) { temporary = abi.encodePacked(temporary, '{"trait_type":"background","value":"none"}', ","); }
		if (parameters.backgroundType == BallcellLiquidBoyaParameters.BackgroundType.Single) { temporary = abi.encodePacked(temporary, '{"trait_type":"background","value":"single"}', ","); }
		if (parameters.backgroundType == BallcellLiquidBoyaParameters.BackgroundType.Circle) { temporary = abi.encodePacked(temporary, '{"trait_type":"background","value":"circle"}', ","); }
		if (parameters.backgroundType == BallcellLiquidBoyaParameters.BackgroundType.PolkaDot) { temporary = abi.encodePacked(temporary, '{"trait_type":"background","value":"polka dot"}', ","); }
		temporary = abi.encodePacked(temporary, '{"display_type":"number","trait_type":"rotation","value":"', Strings.toString(parameters.rotation), '"}', ",");
		temporary = abi.encodePacked(temporary, '{"display_type":"number","trait_type":"angle","value":"', Strings.toString(parameters.angle), '"}', ",");
		temporary = abi.encodePacked(temporary, '{"display_type":"number","trait_type":"distance","value":"', Strings.toString(parameters.distance), '"}', ",");
		temporary = abi.encodePacked(temporary, '{"display_type":"number","trait_type":"swing","value":"', Strings.toString(parameters.swing), '"}');
		return abi.encodePacked(temporary, "]");
	}

	function _image(BallcellLiquidBoyaParameters.Parameters memory parameters, address addressContractImage) private pure returns (bytes memory) {
		bytes memory temporary = _BallcellLiquidBoyaImage(addressContractImage).svg(parameters);
		return abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(temporary));
	}
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------
// Xorshift

library Random {
	struct Status {
		uint256 x;
		uint256 y;
		uint256 z;
		uint256 w;
	}

	function init(Status memory status, uint256 seed) internal pure {
		status.x = 123456789;
		status.y = 362436069;
		status.z = 521288629;
		status.w = 88675123;
		status.w ^= seed;
	}

	function get(Status memory status) internal pure returns (uint256) {
		uint256 x = status.x;
		uint256 w = status.w;
		uint256 t = (x ^ (x << 11));
		status.x = status.y;
		status.y = status.z;
		status.z = status.w;
		status.w = (w ^ (w >> 19)) ^ (t ^ (t >> 8));
		return status.w;
	}
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

// https://nawoo.hateblo.jp/entry/2021/09/28/203446
// https://github.com/Brechtpd/base64
// https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2884

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
	bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	/// @notice Encodes some bytes to the base64 representation
	function encode(bytes memory data) internal pure returns (string memory) {
		uint256 len = data.length;
		if (len == 0) return "";

		// multiply by 4/3 rounded up
		uint256 encodedLen = 4 * ((len + 2) / 3);

		// Add some extra buffer at the end
		bytes memory result = new bytes(encodedLen + 32);

		bytes memory table = TABLE;

		assembly {
			let tablePtr := add(table, 1)
			let resultPtr := add(result, 32)

			for {
				let i := 0
			} lt(i, len) {

			} {
				i := add(i, 3)
				let input := and(mload(add(data, i)), 0xffffff)

				let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
				)
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
				)
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
				)
				out := shl(224, out)

				mstore(resultPtr, out)

				resultPtr := add(resultPtr, 4)
			}

			switch mod(len, 3)
			case 1 {
				mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
			}
			case 2 {
				mstore(sub(resultPtr, 1), shl(248, 0x3d))
			}

			mstore(result, encodedLen)
		}

		return string(result);
	}
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------