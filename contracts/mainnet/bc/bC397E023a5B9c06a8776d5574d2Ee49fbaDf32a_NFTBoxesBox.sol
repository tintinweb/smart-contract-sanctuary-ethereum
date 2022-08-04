// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "ERC721.sol";
import "ERC2981.sol";
import "IVendingMachine.sol";
import "Ownable.sol";	
import "SubscriptionService.sol";
import "BoxJsonParser.sol";


contract NFTBoxesBox is ERC721("NFTBox", "[BOX]"), Ownable, ERC2981, BoxJsonParser {
    
	struct BoxMould{
		uint8				live; // bool
		uint8				shared; // bool
		uint128				maxEdition;
		uint128				maxBuyAmount;
		uint128				currentEditionCount;
		uint256				price;
		address payable[]	artists;
		uint256[]			shares;
		string				name;
		string				series;
		string				theme;
		string				ipfsHash;
		string				arweaveHash;
	}

	struct Box {
		uint256				mouldId;
		uint256				edition;
	}

	uint256 totalSupply;
	IVendingMachine public	vendingMachine;
	SubscriptionService public subService;
	uint256 public			boxMouldCount;

	uint256 constant public TOTAL_SHARES = 1000;

	mapping(uint256 => BoxMould) public	boxMoulds;
	mapping(uint256 =>  Box) public	boxes;
	mapping(uint256 => bool) public lockedBoxes;
	mapping(uint256 => mapping(address => uint256)) boxBoughtMapping;
	mapping(uint256 => uint256) subDistroTracker;

	mapping(address => uint256) public teamShare;
	address payable[] public team;


	mapping(address => bool) public authorisedCaller;

	event BoxMouldCreated(uint256 id);
	event BoxBought(uint256 indexed boxMould, uint256 boxEdition, uint256 tokenId);
	event BatchDeployed(uint256 indexed boxMould, uint256 batchSize);

	constructor(address _service) {
		team.push(payable(0x3428B1746Dfd26C7C725913D829BE2706AA89B2e));
		team.push(payable(0x4C7BEdfA26C744e6bd61CBdF86F3fc4a76DCa073));
		team.push(payable(0x00000000002bF160523a704a019a0C0E63a41B66));
		team.push(payable(0x8C26a91205e531E8B35Cf3315f384727B9681D75));

		teamShare[address(0x3428B1746Dfd26C7C725913D829BE2706AA89B2e)] = 600;
        teamShare[address(0x4C7BEdfA26C744e6bd61CBdF86F3fc4a76DCa073)] = 10;
        teamShare[address(0x00000000002bF160523a704a019a0C0E63a41B66)] = 90;
		teamShare[address(0x8C26a91205e531E8B35Cf3315f384727B9681D75)] = 30;
		vendingMachine = IVendingMachine(0x6d4530149e5B4483d2F7E60449C02570531A0751);
		subService = SubscriptionService(_service);
	}


	function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return ERC2981.supportsInterface(interfaceId)
            || ERC721.supportsInterface(interfaceId);
    }

	function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
		_setDefaultRoyalty(_receiver, _feeNumerator);
	} 

	modifier authorised() {
		require(authorisedCaller[msg.sender] || msg.sender == owner(), "Not authorised to execute.");
		_;
	}

	function setSubService(address _newSub) external onlyOwner {
		subService = SubscriptionService(_newSub);
	}

	function setCaller(address _caller, bool _value) external onlyOwner {
		authorisedCaller[_caller] = _value;
	}

	function addTeamMember(address payable _member) external onlyOwner {
		for (uint256 i = 0; i < team.length; i++)
			require( _member != team[i], "members exists already");
		team.push(_member);
	}

	function removeTeamMember(address payable _member) external onlyOwner {
		for (uint256 i = 0; i < team.length; i++)
			if (team[i] == _member) {
				delete teamShare[_member];
				team[i] = team[team.length - 1];
				team.pop();
			}
	}

	function setTeamShare(address _member, uint _share) external onlyOwner {
		require(_share <= TOTAL_SHARES, "share must be below 1000");
		for (uint256 i = 0; i < team.length; i++)
			if (team[i] == _member)
				teamShare[_member] = _share;
	}

	function setLockOnBox(uint256 _id, bool _lock) external authorised {
		require(_id <= boxMouldCount && _id > 0, "ID !exist.");
		lockedBoxes[_id] = _lock;
	}

	function createBoxMould(
		uint128 _max,
		uint128 _maxBuyAmount,
		uint256 _price,
		address payable[] memory _artists,
		uint256[] memory _shares,
		string memory _name,
		string memory _series,
		string memory _theme,
		string memory _ipfsHash,
		string memory _arweaveHash)
		external
		onlyOwner {
		require(_artists.length == _shares.length, "arrays !same len");
		boxMoulds[boxMouldCount + 1] = BoxMould({
			live: uint8(0),
			shared: uint8(0),
			maxEdition: _max,
			maxBuyAmount: _maxBuyAmount,
			currentEditionCount: 0,
			price: _price,
			artists: _artists,
			shares: _shares,
			name: _name,
			series: _series,
			theme: _theme,
			ipfsHash: _ipfsHash,
			arweaveHash: _arweaveHash
		});
		boxMouldCount++;
		lockedBoxes[boxMouldCount] = true;
		emit BoxMouldCreated(boxMouldCount);
	}

	function removeArtist(uint256 _id, address payable _artist) external onlyOwner {
		BoxMould storage boxMould = boxMoulds[_id];
		require(_id <= boxMouldCount && _id > 0, "ID !exist");
		for (uint256 i = 0; i < boxMould.artists.length; i++) {
			if (boxMould.artists[i] == _artist) {
				boxMould.artists[i] = boxMould.artists[boxMould.artists.length - 1];
				boxMould.artists.pop();
				boxMould.shares[i] = boxMould.shares[boxMould.shares.length - 1];
				boxMould.shares.pop();
			}
		}
	}
	
	function addArtists(uint256 _id, address payable _artist, uint256 _share) external onlyOwner {
		BoxMould storage boxMould = boxMoulds[_id];
		require(_id <= boxMouldCount && _id > 0, "ID !exist");
		boxMould.artists.push(_artist);
		boxMould.shares.push(_share);
	}

	function distributeBoxToSubHolders(uint256 _id) external onlyOwner {
		require(_id <= boxMouldCount && _id > 0, "ID !exist");
		uint256 trackerId = subDistroTracker[_id]++;
		require(trackerId < 10, "Distro done");

		BoxMould storage boxMould = boxMoulds[_id];
		uint128 currentEdition = boxMould.currentEditionCount;
		address[] memory subHolders = subService.fetchValidHolders(trackerId * 50, 50);
		uint256 mintTracker;
		uint256 _totalSupply = totalSupply;
		for (uint256 i = 0; i < 50; i++) {
			address holder = subHolders[i];
			if (holder != address(0)) {
				_buy(currentEdition, _id, mintTracker, holder, _totalSupply + mintTracker + 1);
				mintTracker++;
			}
		}
		totalSupply += mintTracker;
		boxMould.currentEditionCount += uint128(mintTracker);
		if (currentEdition + mintTracker == boxMould.maxEdition)
			boxMould.live = uint8(1);
		if (trackerId == 9)
			subService.pushNewBox();
	}

	function buyManyBoxes(uint256 _id, uint128 _quantity) external payable {
		BoxMould storage boxMould = boxMoulds[_id];
		uint128 currentEdition = boxMould.currentEditionCount;
		uint128 max = boxMould.maxEdition;
		require(_id <= boxMouldCount && _id > 0, "ID !exist");
		require(boxMould.live == 0, "!live");
		require(!lockedBoxes[_id], "locked");
		require(boxMould.price * _quantity == msg.value, "!price");
		require(currentEdition + _quantity <= max, "Too many boxes");
		require(boxBoughtMapping[_id][msg.sender] + _quantity <= boxMould.maxBuyAmount, "!buy");

		uint256 _totalSupply = totalSupply;
		for (uint128 i = 0; i < _quantity; i++)
			_buy(currentEdition, _id, i, msg.sender, _totalSupply + i + 1);
		totalSupply += _quantity;
		boxMould.currentEditionCount += _quantity;
		boxBoughtMapping[_id][msg.sender] = boxBoughtMapping[_id][msg.sender] + _quantity;
		if (currentEdition + _quantity == max)
			boxMould.live = uint8(1);
	}

	function _buy(uint128 _currentEdition, uint256 _id, uint256 _new, address _recipient, uint256 _tokenId) internal {
		boxes[_tokenId] = Box(_id, _currentEdition + _new + 1);
		//safe mint?
		emit BoxBought(_id, _currentEdition + _new + 1, _tokenId);
		_mint(_recipient, _tokenId);
	}

	// close a sale if not sold out
	function closeBox(uint256 _id) external authorised {
		BoxMould storage boxMould = boxMoulds[_id];
		require(_id <= boxMouldCount && _id > 0, "ID !exist.");
		boxMould.live = uint8(1);
	}

	function setVendingMachine(address _machine) external onlyOwner {
		vendingMachine = IVendingMachine(_machine);
	}

	function distributeOffchain(uint256 _id, address[][] calldata _recipients, uint256[] calldata _ids) external authorised {
		BoxMould memory boxMould= boxMoulds[_id];
		require(boxMould.live == 1, "live");
		require (_recipients[0].length == _ids.length, "bad array");

		// i is batch number
		for (uint256 i = 0; i < _recipients.length; i++) {
			// j is for the index of nft ID to send
			for (uint256 j = 0;j <  _recipients[0].length; j++)
				vendingMachine.NFTMachineFor(_ids[j], _recipients[i][j]);
		}
		emit BatchDeployed(_id, _recipients.length);
	}

	function distributeShares(uint256 _id) external {
		BoxMould storage boxMould= boxMoulds[_id];
		require(_id <= boxMouldCount && _id > 0, "ID !exist.");
		require(boxMould.live == 1 && boxMould.shared == 0,  "!distribute");
		require(is100(_id), "sum != 100%.");

		boxMould.shared = 1;
		uint256 rev = uint256(boxMould.currentEditionCount) * boxMould.price;
		uint256 share;
		for (uint256 i = 0; i < team.length; i++) {
			share = rev * teamShare[team[i]] / TOTAL_SHARES;
			team[i].transfer(share);
		}
		for (uint256 i = 0; i < boxMould.artists.length; i++) {
			share = rev * boxMould.shares[i] / TOTAL_SHARES;
			boxMould.artists[i].transfer(share);
		}
	}

	function is100(uint256 _id) internal returns(bool) {
		BoxMould storage boxMould= boxMoulds[_id];
		uint256 total;
		for (uint256 i = 0; i < team.length; i++) {
			total = total + teamShare[team[i]];
		}
		for (uint256 i = 0; i < boxMould.shares.length; i++) {
			total = total + boxMould.shares[i];
		}
		return total == TOTAL_SHARES;
	}

	function getArtist(uint256 _id) external view returns (address payable[] memory) {
		return boxMoulds[_id].artists;
	}

	function getArtistShares(uint256 _id) external view returns (uint256[] memory) {
		return boxMoulds[_id].shares;
	}

    function getBoxMetaData(uint256 _id) external view returns 
    (uint256 boxId, uint256 boxEdition, uint128 boxMax, string memory boxName, string memory boxSeries, string memory boxTheme, string memory boxHashIPFS, string memory boxHashArweave) {
        Box memory box = boxes[_id];
        BoxMould memory mould = boxMoulds[box.mouldId];
        return (box.mouldId, box.edition, mould.maxEdition, mould.name, mould.series, mould.theme, mould.ipfsHash, mould.arweaveHash);
    }

	function _transfer(address from, address to, uint256 tokenId) internal override {
		Box memory box = boxes[tokenId];
		require(!lockedBoxes[box.mouldId], "Box is locked");
		super._transfer(from, to, tokenId);
	}

	function tokenURI(uint256 _tokenId) public view override returns(string memory) {
		Box memory box = boxes[_tokenId];
		require(box.mouldId > 0);
		BoxMould memory mould = boxMoulds[box.mouldId];
		return string(
			abi.encodePacked(
				generateTokenUriPart1(box.edition, mould.series, mould.name, mould.theme),
				generateTokenUriPart2(box.mouldId, box.edition, mould.maxEdition, mould.series, mould.ipfsHash, mould.theme)
			)
		);
	}

	// function tokenURITest(uint256 _tokenId) public view returns(string memory) {

	// 	return string(
	// 		abi.encodePacked(
	// 			generateTokenUriPart1(66, "Main", "December 2021", "Finale"),
	// 			generateTokenUriPart2(12, 66, 132, "Main", "QmefbyT1uqjDaHsLzVMmwicjHVAXQjzfkeCXjfBwUA8om2", "Finale")
	// 		)
	// 	);
	// }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
    string internal _name;

    // Token symbol
    string internal _symbol;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "IERC2981.sol";
import "ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

pragma solidity ^0.8.2;

interface IVendingMachine {

	function NFTMachineFor(uint256 NFTId, address _recipient) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
    address internal _owner;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "SubJsonParser.sol";

contract SubscriptionService is ERC721Enumerable, Ownable, SubJsonParser {

	struct SubData {
		uint32 tier;
		uint32 start;
		uint32 length;
	}

	uint256 public constant MAX = 500;
	uint256 public maxSupply = 300;
	bool public paused;
	uint32 public counter;

	uint256[3] public subPrice;
	uint256 buyCounter;

	mapping(uint256 => uint256) expiredStack;
	uint256 expiredCounter;
	mapping(uint256 => SubData) public subData;
	mapping(address => bool) public authorisedCaller;

	bool public initiated;

	event SubBought(address indexed buyer, uint256 indexed tokenId, uint32 tier, uint256 value);

	constructor(string memory _name, string memory _symbol)  ERC721(_name, _symbol) {}

	function init (string memory __name, string memory __symbol) external {
		require(!initiated);
		initiated = true;
		paused = true;
		subPrice[0] = 1_950_000_000_000_000_000;
		subPrice[1] = 3_705_000_000_000_000_000;
		subPrice[2] = 5_265_000_000_000_000_000;

		counter = 1;
		_name = __name;
		_symbol = __symbol;
		_owner = msg.sender;
	}

	modifier notPaused() {
		require(!paused, "Paused");
		_;
	}

	modifier authorised() {
		require(authorisedCaller[msg.sender], "Not authorised to execute.");
		_;
	}

	function setCaller(address _caller, bool _value) external onlyOwner {
		authorisedCaller[_caller] = _value;
	}

	function fetchEth() external onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}

	function pause() external onlyOwner {
		paused = true;
	}

	function unpause() external onlyOwner {
		paused = false;
	}

	function pushNewBox() external authorised {
		counter++;
	}

	function setPrice(uint256 _index, uint256 _price) external onlyOwner {
		subPrice[_index] = _price;
	}

	function setMaxSupply(uint256 _max) external onlyOwner {
		require(_max <= MAX);
		maxSupply = _max;
	}

	function refundSub(uint256 _tokenId) external onlyOwner {
		require(!isExpired(_tokenId), "Expired");
		SubData memory data = subData[_tokenId];
		expiredStack[expiredCounter++] = _tokenId;
		delete subData[_tokenId];
		_burn(_tokenId);
	}

	function expireSub(uint256 _tokenId) external {
		require(isExpired(_tokenId), "Not expired");
		expiredStack[expiredCounter++] = _tokenId;
		delete subData[_tokenId];
		_burn(_tokenId);
	}

	function buySub(uint8 _tier) external payable {
		buySub(_tier, msg.sender);
	}

	function buySubOwner(uint8 _tier, address _for) public payable onlyOwner {
		require(_tier == 0 || _tier == 1 || _tier == 2, "Sub: Wrong sub model");
		require(totalSupply() < maxSupply, "No more subs of that tier to buy");
		require(msg.value == subPrice[_tier], "!price");

		if (buyCounter < MAX) {
			subData[++buyCounter] = SubData(_tier, counter, _getLength(_tier));
			_mint(_for, buyCounter);
			emit SubBought(_for, buyCounter, _tier, msg.value);
		}
		else {
			require(expiredCounter > 0, "No subs available, try next month");
			uint256 id = expiredStack[--expiredCounter];
			subData[id] = SubData(_tier, counter, _getLength(_tier));
			_mint(_for, id);
			emit SubBought(_for, id, _tier, msg.value);
		}
	}

	function buySub(uint8 _tier, address _for) public payable notPaused {
		require(_tier == 0 || _tier == 1 || _tier == 2, "Sub: Wrong sub model");
		require(totalSupply() < maxSupply, "No more subs of that tier to buy");
		require(msg.value == subPrice[_tier], "!price");

		if (buyCounter < MAX) {
			subData[++buyCounter] = SubData(_tier, counter, _getLength(_tier));
			_mint(_for, buyCounter);
			emit SubBought(_for, buyCounter, _tier, msg.value);
		}
		else {
			require(expiredCounter > 0, "No subs available, try next month");
			uint256 id = expiredStack[--expiredCounter];
			subData[id] = SubData(_tier, counter, _getLength(_tier));
			_mint(_for, id);
			emit SubBought(_for, id, _tier, msg.value);
		}
	}

	function isExpired(uint256 _tokenId) public view returns(bool) {
		SubData memory data = subData[_tokenId];
		return data.start + data.length <= counter;
	}

	function _getType(uint32 _length) internal pure returns(uint256) {
		if (_length == 3)
			return 0;
		else if (_length == 6)
			return 1;
		if (_length == 9)
			return 2;
		return 0;
	}

	function _getLength(uint8 _type) internal pure returns(uint32) {
		if (_type == uint8(0))
			return uint32(3);
		else if (_type == uint8(1))
			return uint32(6);
		if (_type == uint8(2))
			return uint32(9);
		return 0;
	}

	function fetchValidHolders(uint256 _start, uint256 _len) external view returns(address[] memory holders) {
		holders = new address[](_len);
		for (uint256 i = _start; i < _start + _len; i++) {
			if (_exists(i)) {
				address owner = ownerOf(i);
				if (!isExpired(i))
					holders[i - _start] = ownerOf(i);
			}
		}
	}

	function returnSubDataOfHolder(address _holder) external view returns(SubData[] memory data) {
		uint256 amount = balanceOf(_holder);
		data = new SubData[](amount);
		for (uint256 i = 0; i < amount; i++) {
			data[i] = subData[tokenOfOwnerByIndex(_holder, i)];
		}
	}

	function hasUserSub(address _holder, uint256 _tierId) external view returns(bool) {
		uint256 amount = balanceOf(_holder);
		for (uint256 i = 0; i < amount; i++) {
			uint256 tokenId = tokenOfOwnerByIndex(_holder, i);
			SubData memory data = subData[tokenId];
			if (data.tier == _tierId && !isExpired(tokenId))
				return true;
		}
		return false;
	}

	function _transfer(address from, address to, uint256 tokenId) internal override notPaused {
		super._transfer(from, to, tokenId);
	}


	function tokenURI(uint256 _tokenId) public view override returns(string memory) {
		SubData memory data = subData[_tokenId];
		require(_exists(_tokenId));
		return string(
			abi.encodePacked(
				generateTokenUriPart1(_tokenId, uint256(data.tier)),
				generateTokenUriPart2(_getLength(uint8(data.tier)), counter, data.start, data.length)
			)
		);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "ERC721.sol";
import "IERC721Enumerable.sol";

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

import "IERC721.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

contract SubJsonParser {

	function generateTokenUriPart1(uint256 _tokenId, uint256 _tier) public pure returns(string memory) {
		return string(
			abi.encodePacked(
				bytes('data:application/json;utf8,{"name":"'),
				_getName(_tokenId, _tier),
				bytes('","description":"'),
				"NFTBox subscription that guarantees the reception of a monthly box until it expires.",
				bytes('","external_url":"'),
				_getExternalUrl()
			)
		);
	}

	function generateTokenUriPart2(uint256 _tier, uint256 _counter, uint256 _start, uint256 _length) public pure returns(string memory) {
		return string(
			abi.encodePacked(
				bytes('","attributes":['),
				_tierSub(_tier),
				_expiry(_counter - _start + _length),
				bytes(',"image":"'),
				_getImageCache(_tier),
				bytes('"}')
			)
		);
	}

	function _getImageCache(uint256 _tier) internal pure returns(string memory) {
		if (_tier == 3)
			return string(abi.encodePacked("https://ipfs.io/ipfs/QmV3GaTzqLvGSRTAuiLQGsBUDDx4Dr7G7gxqtR8eRhudLL"));
		if (_tier == 6)
			return string(abi.encodePacked("https://ipfs.io/ipfs/QmZBtFNpbrstaKwSDzsB3uFGMeN7b5VjT93Udab2EbB2tQ"));
		if (_tier == 9)
			return string(abi.encodePacked("https://ipfs.io/ipfs/QmPCv1DEWH6pTXXVVdR3nqcavT1bzNRY5QoyR6KEzVjUkb"));
		return string(abi.encodePacked(""));
	}

	function _getName(uint256 _tokenId, uint256 _tier) internal pure returns(string memory) {
		return string(abi.encodePacked("NFTBox ", _tierName(_tier), " Subscription"));
	}

	function _tierSub(uint256 _tier) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "Tier","value":"'), _tierName(_tier), bytes('"},')));
	}

	function _tierName(uint256 _tier) internal pure returns(string memory) {
		if (_tier == 0)
			return string(abi.encodePacked("Bronze"));
		if (_tier == 1)
			return string(abi.encodePacked("Silver"));
		if (_tier == 2)
			return string(abi.encodePacked("Gold"));
		if (_tier == 3)
			return string(abi.encodePacked("Bronze"));
		if (_tier == 6)
			return string(abi.encodePacked("Silver"));
		if (_tier == 9)
			return string(abi.encodePacked("Gold"));
	}

	function _expiry(uint256 _expirationCount) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "Boxes left","value":"'), _uint2str(_expirationCount), bytes('"}]')));
	}

	function _getImageCache(string memory _hash) internal pure returns(string memory) {
		return string(abi.encodePacked("https://ipfs.io/ipfs/", _hash));
	}

	function _getExternalUrl() internal pure returns(string memory) {
		return string(abi.encodePacked("https://www.nftboxes.io/"));
	}

	function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint j = _i;
		uint len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint k = len;
		while (_i != 0) {
			k = k-1;
			uint8 temp = (48 + uint8(_i - _i / 10 * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

contract BoxJsonParser {

	function generateTokenUriPart1(uint256 _tokenId, string memory _series, string memory _name, string memory _theme) public pure returns(string memory) {
		return string(
			abi.encodePacked(
				bytes('data:application/json;utf8,{"name":"'),
				_getName(_name, _tokenId),
				bytes('","description":"'),
				"NFTBoxes are a curated monthly box of NFTs on the newest gold standard of NFT technology."
			)
		);
	}

	function generateTokenUriPart2(uint256 _boxId, uint256 _tokenId, uint256 _max, string memory _series, string memory _hash, string memory _theme) public pure returns(string memory) {
		return string(
			abi.encodePacked(
				bytes('","attributes":['),
				_traitBoxId(_boxId),
				_traitBoxSeries(_series),
				_traitBoxTheme(_theme),
				_traitBoxEdition(_tokenId, _max),
				bytes(',"image":"'),
				_getImageCache(_hash),bytes('"}')
			)
		);
	}

	function _traitBoxId(uint256 _boxId) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "box id","value":"'), _uint2str(_boxId), bytes('"},')));
	}

	function _traitBoxSeries(string memory _series) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "box series","value":"'), _series, bytes('"},')));
	}

	function _traitBoxTheme(string memory _theme) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "box theme","value":"'), _theme, bytes('"},')));
	}

	function _traitBoxEdition(uint256 _tokenId, uint256 _maxEdition) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "box edition","value":"'), _uint2str(_tokenId), bytes(' of '), _uint2str(_maxEdition), bytes('"}]')));
	}

	function _getName(string memory _name, uint256 _tokenId) internal pure returns(string memory) {
		return string(abi.encodePacked(_name, " #", _uint2str(_tokenId)));
	}

	function _getImageCache(string memory _hash) internal pure returns(string memory) {
		return string(abi.encodePacked("https://ipfs.io/ipfs/", _hash));
	}

	function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint j = _i;
		uint len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint k = len;
		while (_i != 0) {
			k = k-1;
			uint8 temp = (48 + uint8(_i - _i / 10 * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}
}