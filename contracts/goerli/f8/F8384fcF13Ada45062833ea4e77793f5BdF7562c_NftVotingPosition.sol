pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "ERC721.sol";
import "IERC20.sol";
import "Ownable.sol";
import "NftBattleArena.sol";

/// @title NftVotingPosition
/// @notice contract for voters to interacte with BattleArena functions
contract NftVotingPosition is ERC721, Ownable
{
	event NftBattleArenaSet(address nftBattleArena);

	NftBattleArena public nftBattleArena;
	IERC20 public dai;
	IERC20 public zoo;

	constructor(string memory _name, string memory _symbol, address _dai, address _zoo) ERC721(_name, _symbol)
	{
		dai = IERC20(_dai);
		zoo = IERC20(_zoo);

	}

	modifier onlyVotingOwner(uint256 votingPositionId) {
		require(ownerOf(votingPositionId) == msg.sender, "Not the owner of voting");
		_;
	}

	function setNftBattleArena(address _nftBattleArena) external onlyOwner
	{
		require(address(nftBattleArena) == address(0));

		nftBattleArena = NftBattleArena(_nftBattleArena);

		emit NftBattleArenaSet(_nftBattleArena);
	}

	function createNewVotingPosition(uint256 stakingPositionId, uint256 amount) external
	{
		require(amount != 0, "zero vote not allowed");                                        // Requires for vote amount to be more than zero.
		dai.transferFrom(msg.sender, address(nftBattleArena), amount);                        // Transfers DAI to arena contract for vote.
		(,uint256 votingPositionId) = nftBattleArena.createVotingPosition(stakingPositionId, msg.sender, amount);
		_safeMint(msg.sender, votingPositionId);
	}

	function addDaiToPosition(uint256 votingPositionId, uint256 amount) external onlyVotingOwner(votingPositionId) returns (uint256 votes)
	{
		dai.transferFrom(msg.sender, address(nftBattleArena), amount);                        // Transfers DAI to arena contract for vote.
		nftBattleArena.addDaiToVoting(votingPositionId, msg.sender, amount, 0);               // zero for yTokens coz its not swap.
	}

	function addZooToPosition(uint256 votingPositionId, uint256 amount) external onlyVotingOwner(votingPositionId) returns (uint256 votes) 
	{
		zoo.transferFrom(msg.sender, address(nftBattleArena), amount);                        // Transfers ZOO to arena contract for vote.
		nftBattleArena.addZooToVoting(votingPositionId, msg.sender, amount);
	}

	function withdrawDaiFromVotingPosition(uint256 votingPositionId, address beneficiary, uint256 daiNumber) external onlyVotingOwner(votingPositionId)
	{
		nftBattleArena.withdrawDaiFromVoting(votingPositionId, msg.sender, beneficiary, daiNumber, false);//beneficiary, false);
	}

	function withdrawZooFromVotingPosition(uint256 votingPositionId, uint256 zooNumber, address beneficiary) external onlyVotingOwner(votingPositionId)
	{
		nftBattleArena.withdrawZooFromVoting(votingPositionId, msg.sender, zooNumber, beneficiary);
	}

	function claimRewardFromVoting(uint256 votingPositionId, address beneficiary) external onlyVotingOwner(votingPositionId)
	{
		nftBattleArena.claimRewardFromVoting(votingPositionId, msg.sender, beneficiary);
	}

	/// @notice Function to move votes from one position to another.
	/// @notice If moving to nft not voted before(i.e. creating new position), then newVotingPosition should be zero.
	/// @param votingPositionId - Id of position votes moving from.
	/// @param daiNumber - amount of dai moving.
	/// @param newStakingPositionId - id of stakingPosition moving to.
	/// @param newVotingPosition - id of voting position moving to, if exist. If there are no such, should be zero.
	function swapVotesFromPosition(uint256 votingPositionId, uint256 daiNumber, uint256 newStakingPositionId, address beneficiary, uint256 newVotingPosition) external onlyVotingOwner(votingPositionId)
	{
		require(daiNumber != 0, "zero vote not allowed");                                        // Requires for vote amount to be more than zero.
		require(ownerOf(newVotingPosition) == msg.sender || newVotingPosition == 0, "Not the owner of voting"); // Requires to be owner of another position, otherwise it should be zero.
		nftBattleArena.swapPositionVotes(votingPositionId, msg.sender, beneficiary, daiNumber, newStakingPositionId, newVotingPosition);
	}

	/// Claims rewards from multiple voting positions
	/// @param votingPositionIds array of voting positions indexes
	/// @param beneficiary address to transfer reward to
	function batchClaimRewardsFromVotings(uint256[] calldata votingPositionIds, address beneficiary) external
	{
		for (uint256 i = 0; i < votingPositionIds.length; i++)
		{
			require(msg.sender == ownerOf(votingPositionIds[i]), "Not the owner of voting");

			nftBattleArena.claimRewardFromVoting(votingPositionIds[i], msg.sender, beneficiary);
		}
	}

	function batchWithdrawDaiFromVoting(uint256[] calldata votingPositionIds, address beneficiary, uint256 daiNumber) external
	{
		for (uint256 i = 0; i < votingPositionIds.length; i++)
		{
			require(msg.sender == ownerOf(votingPositionIds[i]), "Not the owner of voting");

			nftBattleArena.withdrawDaiFromVoting(votingPositionIds[i], msg.sender, beneficiary, daiNumber, false);
		}
	}

	function batchWithdrawZooFromVoting(uint256[] calldata votingPositionIds, uint256 zooNumber, address beneficiary) external
	{
		for (uint256 i = 0; i < votingPositionIds.length; i++)
		{
			require(msg.sender == ownerOf(votingPositionIds[i]), "Not the owner of voting");

			nftBattleArena.withdrawZooFromVoting(votingPositionIds[i], msg.sender, zooNumber, beneficiary);
		}
	}

	/// @notice Function to claim incentive reward for voting, proportionally of collection weight in ve-Model pool.
	function claimIncentiveVoterReward(uint256 votingPositionId, address beneficiary) external returns (uint256)
	{
		require(ownerOf(votingPositionId) == msg.sender, "Not the owner!");             // Requires to be owner of position.

		uint256 reward = nftBattleArena.calculateIncentiveRewardForVoter(votingPositionId);

		zoo.transfer(beneficiary, reward);

		return reward;
	}

	function batchClaimIncentiveVoterReward(uint256[] calldata votingPositionIds, address beneficiary) external
	{
		for (uint256 i = 0; i < votingPositionIds.length; i++)
		{
			require(ownerOf(votingPositionIds[i]) == msg.sender, "Not the owner!");             // Requires to be owner of position.

			uint256 reward = nftBattleArena.calculateIncentiveRewardForVoter(votingPositionIds[i]);

			zoo.transfer(beneficiary, reward);
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "IVault.sol";
import "IZooFunctions.sol";
import "ZooGovernance.sol";
import "ListingList.sol";
import "ERC20.sol";
import "Math.sol";

/// @notice Struct for stages of vote battle.
enum Stage
{
	FirstStage,
	SecondStage,
	ThirdStage,
	FourthStage,
	FifthStage
}

/// @title NftBattleArena contract.
/// @notice Contract for staking ZOO-Nft for participate in battle votes.
contract NftBattleArena
{
	using Math for uint256;
	using Math for int256;

	ERC20 public zoo;                                                // Zoo token interface.
	ERC20 public dai;                                                // DAI token interface
	VaultAPI public vault;                                           // Yearn interface.
	ZooGovernance public zooGovernance;                              // zooGovernance contract.
	IZooFunctions public zooFunctions;                               // zooFunctions contract.
	ListingList public veZoo;

	/// @notice Struct with info about rewards mechanic.
	struct BattleRewardForEpoch
	{
		int256 yTokensSaldo;                                         // Saldo from deposit in yearn in yTokens.
		uint256 votes;                                               // Total amount of votes for nft in this battle in this epoch.
		uint256 yTokens;                                             // Amount of yTokens.
		uint256 tokensAtBattleStart;                                 // Amount of yTokens at start.
		uint256 pricePerShareAtBattleStart;
		uint256 pricePerShareCoef;                                   // pps1*pps2/pps2-pps1
	}

	/// @notice Struct with info about staker positions.
	struct StakerPosition
	{
		uint256 startDate;
		uint256 startEpoch;                                          // Epoch when started to stake.
		uint256 endDate;
		uint256 endEpoch;                                            // Epoch when ended to stake.
		uint256 lastRewardedEpoch;                                   // Epoch when last reward claimed.
		uint256 lastUpdateEpoch;
		address collection;
		uint256 lastEpochOfIncentiveReward;
	}

	/// @notice struct with info about voter positions.
	struct VotingPosition
	{
		uint256 stakingPositionId;                                   // Id of staker position voted for.
		uint256 startDate;
		uint256 endDate;
		uint256 daiInvested;                                         // Amount of dai invested in voting.
		uint256 yTokensNumber;                                       // Amount of yTokens get for dai.
		uint256 zooInvested;                                         // Amount of Zoo used to boost votes.
		uint256 daiVotes;                                            // Amount of votes get from voting with dai.
		uint256 votes;                                               // Amount of total votes from dai, zoo and multiplier.
		uint256 startEpoch;                                          // Epoch when created voting position.
		uint256 endEpoch;                                            // Epoch when liquidated voting position.
		uint256 lastRewardedEpoch;                                   // Epoch when last reward claimed.
		uint256 yTokensRewardDebt;                                   // Amount of yTokens which voter can claim for past epochs before add/withdraw votes.
		uint256 lastEpochOfIncentiveReward;
	}

	/// @notice Struct for records about pairs of Nfts for battle.
	struct NftPair
	{
		uint256 token1;                                              // Id of staker position of 1st candidate.
		uint256 token2;                                              // Id of staker position of 2nd candidate.
		bool playedInEpoch;                                          // Returns true if winner chosen.
		bool win;                                                    // Boolean where true is when 1st candidate wins, and false for 2nd.
	}

	/// @notice Event about staked nft.                         FirstStage
	event CreatedStakerPosition(uint256 indexed currentEpoch, address indexed staker, uint256 indexed stakingPositionId);

	/// @notice Event about withdrawed nft from this pool.      FirstStage
	event RemovedStakerPosition(uint256 indexed currentEpoch, address indexed staker, uint256 indexed stakingPositionId);


	/// @notice Event about created voting position.            SecondStage
	event CreatedVotingPosition(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, uint256 daiAmount, uint256 votes, uint256 votingPositionId);

	/// @notice Event about liquidating voting position.        FirstStage
	event LiquidatedVotingPosition(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, address beneficiary, uint256 votingPositionId, uint256 zooReturned, uint256 daiReceived);


	/// @notice Event about swapping votes from one position to another.
	event SwappedPositionVotes(uint256 indexed currentEpoch, address indexed voter, uint256 indexed newStakingPositionId, address beneficiary, uint256 votingPositionId, uint256 daiNumber, uint256 newVotingPositionId);


	/// @notice Event about recomputing votes from dai.         SecondStage
	event RecomputedDaiVotes(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, uint256 votingPositionId, uint256 newVotes, uint256 oldVotes);

	/// @notice Event about recomputing votes from zoo.         FourthStage
	event RecomputedZooVotes(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, uint256 votingPositionId, uint256 newVotes, uint256 oldVotes);


	/// @notice Event about adding dai to voter position.       SecondStage
	event AddedDaiToVoting(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, uint256 votingPositionId, uint256 amount, uint256 votes);

	/// @notice Event about adding zoo to voter position.       FourthStage
	event AddedZooToVoting(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, uint256 votingPositionId, uint256 amount, uint256 votes);


	/// @notice Event about withdraw dai from voter position.   FirstStage
	event WithdrawedDaiFromVoting(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, address beneficiary, uint256 votingPositionId, uint256 daiNumber);

	/// @notice Event about withdraw zoo from voter position.   FirstStage
	event WithdrawedZooFromVoting(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, uint256 votingPositionId, uint256 zooNumber, address beneficiary);


	/// @notice Event about claimed reward from voting.         FirstStage
	event ClaimedRewardFromVoting(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, address beneficiary, uint256 yTokenReward, uint256 daiReward, uint256 votingPositionId);

	/// @notice Event about claimed reward from staking.        FirstStage
	event ClaimedRewardFromStaking(uint256 indexed currentEpoch, address indexed staker, uint256 indexed stakingPositionId, address beneficiary, uint256 yTokenReward, uint256 daiReward);


	/// @notice Event about paired nfts.                        ThirdStage
	event PairedNft(uint256 indexed currentEpoch, uint256 indexed fighter1, uint256 indexed fighter2, uint256 pairIndex);

	/// @notice Event about winners in battles.                 FifthStage
	event ChosenWinner(uint256 indexed currentEpoch, uint256 indexed fighter1, uint256 indexed fighter2, bool winner, uint256 pairIndex, uint256 playedPairsAmount);

	/// @notice Event about changing epochs.
	event EpochUpdated(uint256 date, uint256 newEpoch);

	//uint256 public battlesStartDate;
	uint256 public epochStartDate;                                                 // Start date of battle epoch.
	uint256 public currentEpoch = 1;                                               // Counter for battle epochs.

	uint256 public firstStageDuration = 10 minutes;// hours;        //todo:change time //3 days;    // Duration of first stage(stake).
	uint256 public secondStageDuration = 10 minutes;// hours;       //todo:change time //7 days;    // Duration of second stage(DAI)'.
	uint256 public thirdStageDuration = 10 minutes;// hours;        //todo:change time //2 days;    // Duration of third stage(Pair).
	uint256 public fourthStageDuration = 10 minutes;// hours;       //todo:change time //5 days;    // Duration fourth stage(ZOO).
	uint256 public fifthStageDuration = 10 minutes;// hours;        //todo:change time //2 days;    // Duration of fifth stage(Winner).
	uint256 public epochDuration = firstStageDuration + secondStageDuration + thirdStageDuration + fourthStageDuration + fifthStageDuration; // Total duration of battle epoch.

	uint256[] public activeStakerPositions;                                        // Array of ZooBattle nfts, which are StakerPositions.
	uint256 public numberOfNftsWithNonZeroVotes;                                   // Staker positions with votes for, eligible to pair and battle.
	uint256 public nftsInGame;                                                     // Amount of Paired nfts in current epoch.

	uint256 public numberOfStakingPositions = 1;
	uint256 public numberOfVotingPositions = 1;

	address public treasury;                                                       // Address of ZooDao insurance pool.
	address public gasPool;                                                        // Address of ZooDao gas fee compensation pool.
	address public team;                                                           // Address of ZooDao team reward pool.

	address public nftStakingPosition;
	address public nftVotingPosition;

	uint256 public baseStakerReward = 83333 * 10 ** 18;       // 83 333 zoo.
	uint256 public baseVoterReward = 2000000 * 10 ** 18;      // 2 000 000 zoo.

	// epoch number => index => NftPair struct.
	mapping (uint256 => NftPair[]) public pairsInEpoch;                            // Records info of pair in struct for battle epoch.

	// epoch number => number of played pairs in epoch.
	mapping (uint256 => uint256) public numberOfPlayedPairsInEpoch;                // Records amount of pairs with chosen winner in current epoch.

	// position id => StakerPosition struct.
	mapping (uint256 => StakerPosition) public stakingPositionsValues;             // Records info about ZooBattle nft-position of staker.

	// position id => VotingPosition struct.
	mapping (uint256 => VotingPosition) public votingPositionsValues;              // Records info about ZooBattle nft-position of voter.

	// epoch index => collection => number of staked nfts.
	mapping (uint256 => mapping (address => uint256)) public numberOfStakedNftsInCollection;

	// collection => last epoch when was updated info about numberOfStakedNftsInCollection.
	mapping (address => uint256) public lastUpdatesOfStakedNumbers;

	// // address collection => uint amount of dai invested.
	// mapping (address => uint256) public collectionDaiInvested;

	// staker position id => epoch = > rewards struct.
	mapping (uint256 => mapping (uint256 => BattleRewardForEpoch)) public rewardsForEpoch;

	// epoch number => timestamp of epoch start
	mapping (uint256 => uint256) public epochsStarts;

	modifier only(address who)
	{
		require(msg.sender == who);
		_;
	}

	/// @notice Contract constructor.
	/// @param _zoo - address of Zoo token contract.
	/// @param _dai - address of DAI token contract.
	/// @param _vault - address of yearn.
	/// @param _zooGovernance - address of ZooDao Governance contract.
	/// @param _treasuryPool - address of ZooDao treasury pool.
	/// @param _gasFeePool - address of ZooDao gas fee compensation pool.
	/// @param _teamAddress - address of ZooDao team reward pool.
	constructor (
		address _zoo,
		address _dai,
		address _vault,
		address _zooGovernance,
		address _treasuryPool,
		address _gasFeePool,
		address _teamAddress,
		address _nftStakingPosition,
		address _nftVotingPosition,
		address _veZoo)
	{
		zoo = ERC20(_zoo);
		dai = ERC20(_dai);
		vault = VaultAPI(_vault);
		zooGovernance = ZooGovernance(_zooGovernance);
		zooFunctions = IZooFunctions(zooGovernance.zooFunctions());
		veZoo = ListingList(_veZoo);

		treasury = _treasuryPool;
		gasPool = _gasFeePool;
		team = _teamAddress;
		nftStakingPosition = _nftStakingPosition;
		nftVotingPosition = _nftVotingPosition;

		//battlesStartDate = block.timestamp;
		epochStartDate = block.timestamp;	//todo:change time for prod + n days; // Start date of 1st battle.
		epochsStarts[currentEpoch] = block.timestamp;
	}

	/// @notice Function to get amount of nft in array StakerPositions/staked in battles.
	/// @return amount - amount of ZooBattles nft.
	function getStakerPositionsLength() public view returns (uint256 amount)
	{
		return activeStakerPositions.length;
	}

	/// @notice Function to get amount of nft pairs in epoch.
	/// @param epoch - number of epoch.
	/// @return length - amount of nft pairs.
	function getNftPairLength(uint256 epoch) public view returns(uint256 length) 
	{
		return pairsInEpoch[epoch].length;
	}

	/// @notice Function to calculate amount of tokens from shares.
	/// @param sharesAmount - amount of shares.
	/// @return tokens - calculated amount tokens from shares.
	function sharesToTokens(uint256 sharesAmount) public view returns (uint256 tokens)
	{
		return sharesAmount * vault.pricePerShare() / (10 ** dai.decimals());
	}

	/// @notice Function for calculating tokens to shares.
	/// @param tokens - amount of tokens to calculate.
	/// @return shares - calculated amount of shares.
	function tokensToShares(uint256 tokens) public view returns (uint256 shares)
	{
		return tokens * (10 ** dai.decimals()) / (vault.pricePerShare());
	}

	/// @notice Function for staking NFT in this pool.
	function createStakerPosition(address staker, address token) public only(nftStakingPosition) returns (uint256)
	{
		require(getCurrentStage() == Stage.FirstStage, "Wrong stage!");                         // Requires to be at first stage in battle epoch.

		// todo: Possible need to change to stakingPositionsValues[numberOfStakingPositions] = StakerPosition(...); 
		StakerPosition storage position = stakingPositionsValues[numberOfStakingPositions];
		position.startEpoch = currentEpoch;                                                     // Records startEpoch.
		position.startDate = block.timestamp;
		position.lastRewardedEpoch = currentEpoch;                                              // Records lastRewardedEpoch
		position.collection = token;
		position.lastEpochOfIncentiveReward = currentEpoch;

		numberOfStakedNftsInCollection[currentEpoch][token]++;

		activeStakerPositions.push(numberOfStakingPositions);                                   // Records this position to stakers positions array.

		emit CreatedStakerPosition(currentEpoch, staker, numberOfStakingPositions);             // Emits StakedNft event.

		return numberOfStakingPositions++;                                                      // Increments amount and id of future positions.
	}

	/// @notice Function for withdrawing staked nft.
	/// @param stakingPositionId - id of staker position.
	function removeStakerPosition(uint256 stakingPositionId, address staker) public only(nftStakingPosition)
	{
		require(getCurrentStage() == Stage.FirstStage, "Wrong stage!");             // Requires to be at first stage in battle epoch.
		require(stakingPositionsValues[stakingPositionId].endEpoch == 0, "Nft unstaked");// Requires token to be staked.

		stakingPositionsValues[stakingPositionId].endEpoch = currentEpoch;                      // Records epoch when unstaked.
		stakingPositionsValues[stakingPositionId].endDate = block.timestamp;
		updateInfo(stakingPositionId);

		if (rewardsForEpoch[stakingPositionId][currentEpoch].votes > 0)
		{
			for(uint256 i = 0; i < numberOfNftsWithNonZeroVotes; i++)
			{
				if (activeStakerPositions[i] == stakingPositionId)
				{
					activeStakerPositions[i] = activeStakerPositions[numberOfNftsWithNonZeroVotes - 1];
					activeStakerPositions[numberOfNftsWithNonZeroVotes - 1] = activeStakerPositions[activeStakerPositions.length - 1];
					numberOfNftsWithNonZeroVotes--;
					break;
				}
			}
		}
		else
		{
			for(uint256 i = numberOfNftsWithNonZeroVotes; i < activeStakerPositions.length; i++)
			{
				if (activeStakerPositions[i] == stakingPositionId)
				{
					activeStakerPositions[i] = activeStakerPositions[activeStakerPositions.length - 1];
					break;
				}
			}
		}
		
		address collection = stakingPositionsValues[stakingPositionId].collection;
		updateInfoAboutStakedNumber(collection);
		numberOfStakedNftsInCollection[currentEpoch][collection]--;
		activeStakerPositions.pop();                                                            // Removes staker position from array.

		emit RemovedStakerPosition(currentEpoch, staker, stakingPositionId);                    // Emits UnstakedNft event.
	}

	/// @notice Function for vote for nft in battle.
	/// @param stakingPositionId - id of staker position.
	/// @param amount - amount of dai to vote.
	/// @return votes - computed amount of votes.
	function createVotingPosition(uint256 stakingPositionId, address voter, uint256 amount) external only(nftVotingPosition) returns (uint256 votes, uint256 votingPositionId)
	{
		require(getCurrentStage() == Stage.SecondStage, "Wrong stage!");                        // Requires to be at second stage of battle epoch.

		updateInfo(stakingPositionId);
		// address collection = stakingPositionsValues[stakingPositionId].collection;

		dai.approve(address(vault), amount);                                                    // Approves Dai for yearn.
		uint256 yTokensNumber = vault.deposit(amount);                                          // Deposits dai to yearn vault and get yTokens.

		(votes, votingPositionId) = _createVotingPosition(stakingPositionId, voter, yTokensNumber, amount);
	}

	function _createVotingPosition(uint256 stakingPositionId, address voter, uint256 yTokens, uint256 amount) internal returns (uint256 votes, uint256 votingPositionId)
	{
		require(stakingPositionsValues[stakingPositionId].startDate != 0 && stakingPositionsValues[stakingPositionId].endEpoch == 0, "Not staked"); // Requires for staking position to be staked.

		votes = zooFunctions.computeVotesByDai(amount);                                         // Calculates amount of votes.
		votingPositionsValues[numberOfVotingPositions].stakingPositionId = stakingPositionId;   // Records staker position Id voted for.
		votingPositionsValues[numberOfVotingPositions].startDate = block.timestamp;
		votingPositionsValues[numberOfVotingPositions].daiInvested = amount;                    // Records amount of dai invested.
		votingPositionsValues[numberOfVotingPositions].yTokensNumber = yTokens;                 // Records amount of yTokens got from yearn vault.
		votingPositionsValues[numberOfVotingPositions].daiVotes = votes;                        // Records computed amount of votes to daiVotes.
		votingPositionsValues[numberOfVotingPositions].votes = votes;                           // Records computed amount of votes to total votes.
		votingPositionsValues[numberOfVotingPositions].startEpoch = currentEpoch;               // Records epoch when position created.
		votingPositionsValues[numberOfVotingPositions].lastRewardedEpoch = currentEpoch;        // Sets starting point for reward to current epoch.
		votingPositionsValues[numberOfVotingPositions].lastEpochOfIncentiveReward = currentEpoch;

		
		// collectionDaiInvested[collection] += amount;

		BattleRewardForEpoch storage battleReward = rewardsForEpoch[stakingPositionId][currentEpoch];
		
		if (battleReward.votes == 0)                                                            // If staker position had zero votes before,
		{
			for(uint256 i = 0; i < activeStakerPositions.length; i++)
			{
				if (activeStakerPositions[i] == stakingPositionId) 
				{
					if (stakingPositionId != numberOfNftsWithNonZeroVotes) 
					{
						(activeStakerPositions[i], activeStakerPositions[numberOfNftsWithNonZeroVotes]) = (activeStakerPositions[numberOfNftsWithNonZeroVotes], activeStakerPositions[i]);
					}
					numberOfNftsWithNonZeroVotes++;                                            // Increases amount of nft eligible for pairing.
					break;
				}
			}
		}

		battleReward.votes += votes;                                                            // Adds votes for staker position for this epoch.
		battleReward.yTokens += yTokens;                                                        // Adds yTokens for this staker position for this epoch.

		votingPositionId = numberOfVotingPositions;
		numberOfVotingPositions++;

		emit CreatedVotingPosition(currentEpoch, voter, stakingPositionId, amount, votes, votingPositionId);
	}

	/// todo: must be changed by decrease DAI
	/// @notice Function to liquidate voting position and claim reward.
	/// @param votingPositionId - id of position.
	/// @param beneficiary - address of recipient.
	function _liquidateVotingPosition(uint256 votingPositionId, address voter, address beneficiary, uint256 stakingPositionId, bool toSwap) internal
	{
		uint256 daiInvested = votingPositionsValues[votingPositionId].daiInvested;
		uint256 zooInvested = votingPositionsValues[votingPositionId].zooInvested; // Amount of zoo to withdraw.

		uint256 yTokens = _calculateYTokensRewardsOfVoting(votingPositionId);

		if (toSwap == false)
		{
			vault.withdraw(yTokens, beneficiary);
		}
		
		_withdrawZoo(zooInvested, beneficiary);

		votingPositionsValues[votingPositionId].endEpoch = currentEpoch;                        // Sets endEpoch to currentEpoch.
		votingPositionsValues[votingPositionId].endDate = block.timestamp;

		rewardsForEpoch[stakingPositionId][currentEpoch].votes -= votingPositionsValues[votingPositionId].votes;
		
		if (rewardsForEpoch[stakingPositionId][currentEpoch].yTokens >= yTokens)
		{
			rewardsForEpoch[stakingPositionId][currentEpoch].yTokens -= yTokens;
		}
		else
		{
			rewardsForEpoch[stakingPositionId][currentEpoch].yTokens = 0;
		}

		if (rewardsForEpoch[stakingPositionId][currentEpoch].votes == 0 && stakingPositionsValues[stakingPositionId].endDate == 0)
		{
			// Move staking position to part with staked without votes
			for(uint256 i = 0; i < activeStakerPositions.length; i++)
			{
				if (activeStakerPositions[i] == stakingPositionId)
				{
					(activeStakerPositions[i], activeStakerPositions[numberOfNftsWithNonZeroVotes - 1]) = (activeStakerPositions[numberOfNftsWithNonZeroVotes - 1], activeStakerPositions[i]);
					numberOfNftsWithNonZeroVotes--;
					break;
				}
			}
		}
		// collectionDaiInvested[collection] -= daiNumber; // todo: fix

		emit LiquidatedVotingPosition(currentEpoch, voter, stakingPositionId, beneficiary, votingPositionId, zooInvested * 995 / 1000, daiInvested);
	}

	function _calculateYTokensRewardsOfVoting(uint256 votingPositionId) internal returns(uint256 yTokens) 
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		uint256 stakingPositionId = votingPosition.stakingPositionId;

		yTokens = votingPosition.yTokensNumber;
		uint256 daiInvested = votingPosition.daiInvested;

		uint256 startEpoch = votingPosition.lastRewardedEpoch;
		uint256 endEpoch = computeLastEpoch(votingPositionId);

		for (uint256 i = startEpoch; i < endEpoch; i++)
		{
			if (rewardsForEpoch[stakingPositionId][i].pricePerShareCoef != 0)
			{
				yTokens -= daiInvested / (rewardsForEpoch[stakingPositionId][i].pricePerShareCoef);
			}
		}
	}

	/// @notice Function to swap votes from one position to another.
	function swapPositionVotes(uint256 votingPositionId, address voter, address beneficiary, uint256 daiNumber, uint256 newStakingPositionId, uint256 newVotingPositionId) external only(nftVotingPosition)
	{
		uint256 stakingPositionId =  votingPositionsValues[votingPositionId].stakingPositionId;               // Gets id of staker position.
		updateInfo(stakingPositionId);
		require(getCurrentStage() == Stage.FirstStage, "Wrong stage!"); // Requires correct stage.

		uint256 daiInvested = votingPositionsValues[votingPositionId].daiInvested;
		uint256 yTokens = tokensToShares(daiNumber);

		withdrawDaiFromVoting(votingPositionId, voter, beneficiary, daiNumber, true); // Calls internal withdrawDai.

		if (newVotingPositionId == 0)    // If zero, i.e. new position doesn't exist.
		{
			_createVotingPosition(newStakingPositionId, voter, yTokens, daiNumber); // Creates new position to swap there.
		}
		else                             // If position existing, swap to it.
		{
			require(votingPositionsValues[newVotingPositionId].endDate == 0, "unstaked"); // Requires for position to exist and still be staked.
			newStakingPositionId = votingPositionsValues[votingPositionId].stakingPositionId;
			addDaiToVoting(newVotingPositionId, msg.sender, daiNumber, yTokens);             // swap votes to existing position.
		}
		emit SwappedPositionVotes(currentEpoch, voter, newStakingPositionId, beneficiary, votingPositionId, daiNumber, newVotingPositionId);
	}

	/// @notice Function to recompute votes from dai.
	/// @notice Reasonable to call at start of new epoch for better multiplier rate, if voted with low rate before.
	/// @param votingPositionId - id of voting position.
	function recomputeDaiVotes(uint256 votingPositionId) public
	{
		require(getCurrentStage() == Stage.SecondStage, "Wrong stage!");                      // Requires to be at second stage of battle epoch.

		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		
		_updateVotingRewardDebt(votingPositionId);

		uint256 stakingPositionId = votingPosition.stakingPositionId;
		updateInfo(stakingPositionId);

		uint256 daiNumber = votingPosition.daiInvested;                               // Gets amount of dai from voting position.
		uint256 newVotes = zooFunctions.computeVotesByDai(daiNumber);                 // Recomputes dai to votes.
		uint256 votes = votingPosition.votes;                                         // Gets amount of votes from voting position.

		require(newVotes > votes, "Recompute to lower value");                        // Requires for new votes amount to be bigger than before.

		votingPosition.daiVotes = newVotes;                                           // Records new votes amount from dai.
		votingPosition.votes = newVotes;                                              // Records new votes amount total.

		rewardsForEpoch[stakingPositionId][currentEpoch].votes += newVotes - votes;   // Increases rewards for staker position for added amount of votes in this epoch.
		emit RecomputedDaiVotes(currentEpoch, msg.sender, stakingPositionId, votingPositionId, newVotes, votes);
	}

	/// @notice Function to recompute votes from zoo.
	/// @param votingPositionId - id of voting position.
	function recomputeZooVotes(uint256 votingPositionId) public
	{
		require(getCurrentStage() == Stage.FourthStage, "Wrong stage!");              // Requires to be at 4th stage.

		// todo: maybe move codeblock to modifier
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		
		_updateVotingRewardDebt(votingPositionId);

		uint256 stakingPositionId = votingPosition.stakingPositionId;
		updateInfo(stakingPositionId);

		uint256 zooNumber = votingPosition.zooInvested;                               // Gets amount of zoo invested from voting position.
		uint256 newZooVotes = zooFunctions.computeVotesByZoo(zooNumber);              // Recomputes zoo to votes.
		uint256 oldZooVotes = votingPosition.votes - votingPosition.daiVotes;
		
		require(newZooVotes > oldZooVotes, "Recompute to lower value");               // Requires for new votes amount to be bigger than before.

		uint256 delta = newZooVotes + votingPosition.daiVotes / votingPosition.votes; // Gets amount of recently added zoo votes.
		rewardsForEpoch[stakingPositionId][currentEpoch].votes += delta;              // Adds amount of recently added votes to reward for staker position for current epoch.
		votingPosition.votes += delta;                                                // Add amount of recently added votes to total votes in voting position.

		emit RecomputedZooVotes(currentEpoch, msg.sender, stakingPositionId, votingPositionId, newZooVotes, oldZooVotes);
	}

	/// @notice Function to add dai tokens to voting position.
	/// @param votingPositionId - id of voting position.
	/// @param voter - address of voter.
	/// @param amount - amount of dai tokens to add.
	/// @param _yTokens - amount of yTokens from previous position when called with swap.
	function addDaiToVoting(uint256 votingPositionId, address voter, uint256 amount, uint256 _yTokens) public only(nftVotingPosition) returns (uint256 votes)
	{
		require(getCurrentStage() == Stage.SecondStage || _yTokens != 0, "Wrong stage!");              // Requires to be at second stage of battle epoch.

		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		uint256 stakingPositionId = votingPosition.stakingPositionId;                 // Gets id of staker position.
		require(stakingPositionsValues[stakingPositionId].endEpoch == 0, "Position removed");// Requires to be staked.

		_updateVotingRewardDebt(votingPositionId);

		uint256 yTokens = _calculateYTokensRewardsOfVoting(votingPositionId);
		uint256 daiInvested = votingPosition.daiInvested;

		votingPosition.yTokensNumber = yTokens;

		// address collection = stakingPositionsValues[stakingPositionId].collection;

		votes = zooFunctions.computeVotesByDai(amount);                                 // Gets computed amount of votes from multiplier of dai.
		if (_yTokens == 0) // if no _yTokens from another position with swap.
		{
			dai.approve(address(vault), amount);                                        // Approves dai to yearn.
			_yTokens = vault.deposit(amount);                                      // Deposits dai to yearn and gets yTokens.
		}
		votingPosition.daiInvested += amount;                    // Adds amount of dai to voting position.
		votingPosition.yTokensNumber += _yTokens;           // Adds yTokens to voting position.
		votingPosition.daiVotes += votes;                        // Adds computed daiVotes amount from to voting position.
		votingPosition.votes += votes;                           // Adds computed votes amount to totalVotes amount for voting position.

		updateInfo(stakingPositionId);

		rewardsForEpoch[stakingPositionId][currentEpoch].votes += votes;          // Adds votes to staker position for current epoch.
		rewardsForEpoch[stakingPositionId][currentEpoch].yTokens += _yTokens;// Adds yTokens to rewards from staker position for current epoch.

		// collectionDaiInvested[collection] += amount;

		emit AddedDaiToVoting(currentEpoch, voter, stakingPositionId, votingPositionId, amount, votes);
	}

	/// @notice Function to add zoo tokens to voting position.
	/// @param votingPositionId - id of voting position.
	/// @param amount - amount of zoo tokens to add.
	function addZooToVoting(uint256 votingPositionId, address voter, uint256 amount) external only(nftVotingPosition) returns (uint256 votes)
	{
		require(getCurrentStage() == Stage.FourthStage, "Wrong stage!");            // Requires to be at 3rd stage.

		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		

		_updateVotingRewardDebt(votingPositionId);


		votes = zooFunctions.computeVotesByZoo(amount);                             // Gets computed amount of votes from multiplier of zoo.
		require(votingPosition.zooInvested + amount <= votingPosition.daiInvested, "Exceed limit");// Requires for votes from zoo to be less than votes from dai.

		uint256 stakingPositionId = votingPosition.stakingPositionId;               // Gets id of staker position.
		updateInfo(stakingPositionId);

		rewardsForEpoch[stakingPositionId][currentEpoch].votes += votes;            // Adds votes for staker position.
		votingPositionsValues[votingPositionId].votes += votes;                     // Adds votes to voting position.
		votingPosition.zooInvested += amount;                                       // Adds amount of zoo tokens to voting position.

		emit AddedZooToVoting(currentEpoch, voter, stakingPositionId, votingPositionId, amount, votes);
	}

	/// @notice Functions to withdraw dai from voting position.
	/// @param votingPositionId - id of voting position.
	/// @param daiNumber - amount of dai to withdraw.
	// @ param beneficiary - address of recipient.
	function withdrawDaiFromVoting(uint256 votingPositionId, address voter, address beneficiary, uint256 daiNumber, bool toSwap) public only(nftVotingPosition)
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		uint256 stakingPositionId = votingPosition.stakingPositionId;               // Gets id of staker position.
		updateInfo(stakingPositionId);

		require(getCurrentStage() == Stage.FirstStage || stakingPositionsValues[stakingPositionId].endDate != 0, "Wrong stage!"); // Requires correct stage or nft to be unstaked.
		require(votingPosition.endEpoch == 0, "Position removed");                         // Requires to be not liquidated yet.

		
		_updateVotingRewardDebt(votingPositionId);


		if (daiNumber >= votingPosition.daiInvested)
		{
			_liquidateVotingPosition(votingPositionId, voter, beneficiary, stakingPositionId, toSwap);
			return;
		}

		uint256 yTokens = _calculateYTokensRewardsOfVoting(votingPositionId);
		uint256 shares = tokensToShares(daiNumber);

		if (toSwap == false)
		{
			// vault.withdraw(shares, voter);
			shares = vault.withdrawTokens(daiNumber, voter);        // Withdraws from yearn amount of yTokens.//todo
		}

		uint256 deltaVotes = votingPosition.daiVotes * daiNumber / votingPosition.daiInvested; 
		rewardsForEpoch[stakingPositionId][currentEpoch].yTokens -= shares;
		rewardsForEpoch[stakingPositionId][currentEpoch].votes -= deltaVotes;

		votingPosition.yTokensNumber = yTokens - shares;
		votingPosition.daiVotes -= deltaVotes;
		votingPosition.votes -= deltaVotes;
		votingPosition.daiInvested -= daiNumber;                                        // Decreases daiInvested amount of position.

		if (votingPosition.zooInvested > votingPosition.daiInvested)                    // If zooInvested more than daiInvested left in position.
		{
			_rebalanceExceedZoo(votingPositionId, voter);
		}

		emit WithdrawedDaiFromVoting(currentEpoch, voter, stakingPositionId, beneficiary, votingPositionId, daiNumber);
	}

	function _rebalanceExceedZoo(uint256 votingPositionId, address beneficiary) internal
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		uint256 zooDelta = votingPosition.zooInvested - votingPosition.daiInvested; // Extra zoo returns to recipient.
		_withdrawZoo(zooDelta, beneficiary);
		uint256 votesDelta = zooFunctions.computeVotesByZoo(zooDelta);
		votingPosition.zooInvested -= zooDelta;
		votingPosition.votes -= votesDelta;
	}

	/// @notice Functions to withdraw zoo from voting position.
	/// @param votingPositionId - id of voting position.
	/// @param zooNumber - amount of zoo to withdraw.
	/// @param beneficiary - address of recipient.
	function withdrawZooFromVoting(uint256 votingPositionId, address voter, uint256 zooNumber, address beneficiary) external only(nftVotingPosition)
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];

		_updateVotingRewardDebt(votingPositionId);

		uint256 stakingPositionId = votingPosition.stakingPositionId;                   // Gets id of staker position from this voting position.
		require(getCurrentStage() == Stage.FirstStage || stakingPositionsValues[stakingPositionId].endDate != 0, "Wrong stage!"); // Requires correct stage or nft to be unstaked.

		require(votingPosition.endEpoch == 0, "Position removed");                    // Requires to be not liquidated yet.

		uint256 zooInvested = votingPosition.zooInvested;
		if (zooNumber > zooInvested)
		{
			zooNumber = zooInvested;
		}

		_withdrawZoo(zooNumber, beneficiary);

		uint256 zooVotes = votingPosition.votes - votingPosition.daiVotes;
		uint256 deltaVotes = zooVotes * zooNumber / zooInvested;

		votingPosition.votes -= deltaVotes;
		votingPosition.zooInvested -= zooNumber;

		updateInfo(stakingPositionId);
		rewardsForEpoch[stakingPositionId][currentEpoch].votes -= deltaVotes;

		emit WithdrawedZooFromVoting(currentEpoch, voter, stakingPositionId, votingPositionId, zooNumber, beneficiary);
	}

	/// @notice Function to claim reward in yTokens from voting.
	/// @param votingPositionId - id of voting position.
	/// @param beneficiary - address of recipient of reward.
	function claimRewardFromVoting(uint256 votingPositionId, address voter, address beneficiary) external only(nftVotingPosition) returns (uint256 daiReward)
	{
		require(getCurrentStage() == Stage.FirstStage, "Wrong stage!");                // Requires to be at first stage.

		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		uint256 stakingPositionId = votingPosition.stakingPositionId;                  // Gets staker position id from voter position.

		updateInfo(stakingPositionId);

		uint256 yTokenReward = getPendingVoterReward(votingPositionId);// Calculates amount of reward.

		yTokenReward += votingPosition.yTokensRewardDebt;
		votingPosition.yTokensRewardDebt = 0;

		daiReward = vault.withdraw(yTokenReward * 98 / 100, address(this));                  // Withdraws dai from vault for yTokens.

		_daiRewardDistribution(beneficiary, stakingPositionId, daiReward);

		if (rewardsForEpoch[stakingPositionId][currentEpoch].yTokens >= yTokenReward * 980 / 1000)
		{
			rewardsForEpoch[stakingPositionId][currentEpoch].yTokens -= yTokenReward * 980 / 1000;// Subtracts yTokens for this position.
		}
		else
		{
			rewardsForEpoch[stakingPositionId][currentEpoch].yTokens = 0;
		}

		uint256 lastEpoch = computeLastEpoch(votingPositionId);
		votingPosition.lastRewardedEpoch = lastEpoch;                                  // Records epoch of last reward claimed.

		emit ClaimedRewardFromVoting(currentEpoch, voter, stakingPositionId, beneficiary, yTokenReward, daiReward, votingPositionId);
	}


	/// @notice Function to calculate pending reward from voting for position with this id.
	/// @param votingPositionId - id of voter position in battles.
	/// @return yTokens - amount of pending reward.
	function getPendingVoterReward(uint256 votingPositionId) public view returns (uint256 yTokens)
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];

		uint256 startEpoch = votingPosition.lastRewardedEpoch;
		uint256 endEpoch = computeLastEpoch(votingPositionId);

		uint256 stakingPositionId = votingPosition.stakingPositionId;// Gets staker position id from voter position.

		for (uint256 i = startEpoch; i < endEpoch; i++)
		{
			int256 saldo = rewardsForEpoch[stakingPositionId][i].yTokensSaldo;                // Gets saldo from staker position.

			if (saldo > 0)
			{
				uint256 totalVotes = rewardsForEpoch[stakingPositionId][i].votes;                 // Gets total votes from staker position.
				yTokens += uint256(saldo) * votingPosition.votes / totalVotes;                               // Calculates yTokens amount for voter.
			}
		}

		return yTokens;
	}


	/// @notice Updates yTokensRewardDebt of voting
	/// @notice Called before every actio with voting to prevent increasing share % in battle reward
	/// @param votingPositionId ID of voting to be updated
	function _updateVotingRewardDebt(uint256 votingPositionId) internal {
		uint256 reward = getPendingVoterReward(votingPositionId);

		if (reward != 0)
		{
			votingPositionsValues[votingPositionId].yTokensRewardDebt += reward;
		}

		votingPositionsValues[votingPositionId].lastRewardedEpoch = currentEpoch;
	}

	/// @notice Function to claim reward for staker.
	/// @param stakingPositionId - id of staker position.
	/// @param beneficiary - address of recipient.
	function claimRewardFromStaking(uint256 stakingPositionId, address staker, address beneficiary) public only(nftStakingPosition) returns (uint256 daiReward)
	{
		require(getCurrentStage() == Stage.FirstStage, "Wrong stage!");                       // Requires to be at first stage in battle epoch.

		updateInfo(stakingPositionId);
		(uint256 yTokenReward, uint256 end) = getPendingStakerReward(stakingPositionId);
		stakingPositionsValues[stakingPositionId].lastRewardedEpoch = end;                    // Records epoch of last reward claim.

		daiReward = vault.withdraw(yTokenReward, beneficiary);                                            // Gets reward from yearn.

		emit ClaimedRewardFromStaking(currentEpoch, staker, stakingPositionId, beneficiary, yTokenReward, daiReward);
	}

	/// @notice Function to get pending reward fo staker for this position id.
	/// @param stakingPositionId - id of staker position.
	/// @return stakerReward - reward amount for staker of this nft.
	function getPendingStakerReward(uint256 stakingPositionId) public view returns (uint256 stakerReward, uint256 end)
	{
		uint256 endEpoch = stakingPositionsValues[stakingPositionId].endEpoch;                // Gets endEpoch from position.
		// todo: check that endEpoch (not lastRewardedEpoch)
		end = endEpoch == 0 ? currentEpoch : endEpoch;                                        // Sets end variable to endEpoch if it non-zero, otherwise to currentEpoch.
		int256 yTokensReward;                                                                 // Define reward in yTokens.

		for (uint256 i = stakingPositionsValues[stakingPositionId].lastRewardedEpoch; i < end; i++)
		{
			int256 saldo = rewardsForEpoch[stakingPositionId][i].yTokensSaldo;                // Get saldo from staker position.

			if (saldo > 0)
			{
				yTokensReward += saldo * 20 / 1000;                                             // Calculates reward for staker.
			}
		}

		stakerReward = uint256(yTokensReward);                                                // Calculates reward amount.
	}

	/// @notice Function for pair nft for battles.
	/// @param stakingPositionId - id of staker position.
	function pairNft(uint256 stakingPositionId) external
	{
		require(getCurrentStage() == Stage.ThirdStage, "Wrong stage!");                       // Requires to be at 3 stage of battle epoch.
		require(numberOfNftsWithNonZeroVotes / 2 > nftsInGame / 2, "No opponent");            // Requires enough nft for pairing.
		uint256 index1;                                                                       // Index of nft paired for.
		uint256 i;

		for (i = nftsInGame; i < numberOfNftsWithNonZeroVotes; i++)
		{
			if (activeStakerPositions[i] == stakingPositionId)
			{
				index1 = i;
				break;
			}
		}

		require(i != numberOfNftsWithNonZeroVotes, "Wrong position");                         // Position not found in list of voted for and not paired.

		(activeStakerPositions[index1], activeStakerPositions[nftsInGame]) = (activeStakerPositions[nftsInGame], activeStakerPositions[index1]);// Swaps nftsInGame with index.
		nftsInGame++;                                                                         // Increases amount of paired nft.

		uint256 random = zooFunctions.computePseudoRandom() % (numberOfNftsWithNonZeroVotes - nftsInGame); // Get random number.

		uint256 index2 = random + nftsInGame;                                                 // Get index of opponent.
		uint256 pairIndex = getNftPairLength(currentEpoch);

		uint256 stakingPosition2 = activeStakerPositions[index2];                             // Get staker position id of opponent.
		pairsInEpoch[currentEpoch].push(NftPair(stakingPositionId, stakingPosition2, false, false));// Pushes nft pair to array of pairs.

		updateInfo(stakingPositionId);
		updateInfo(stakingPosition2);

		rewardsForEpoch[stakingPositionId][currentEpoch].tokensAtBattleStart = sharesToTokens(rewardsForEpoch[stakingPositionId][currentEpoch].yTokens); // Records amount of yTokens on the moment of pairing for candidate.
		rewardsForEpoch[stakingPosition2][currentEpoch].tokensAtBattleStart = sharesToTokens(rewardsForEpoch[stakingPosition2][currentEpoch].yTokens);   // Records amount of yTokens on the moment of pairing for opponent.

		rewardsForEpoch[stakingPositionId][currentEpoch].pricePerShareAtBattleStart = vault.pricePerShare();
		rewardsForEpoch[stakingPosition2][currentEpoch].pricePerShareAtBattleStart = vault.pricePerShare();

		(activeStakerPositions[index2], activeStakerPositions[nftsInGame]) = (activeStakerPositions[nftsInGame], activeStakerPositions[index2]); // Swaps nftsInGame with index of opponent.
		nftsInGame++;                                                                        // Increases amount of paired nft.

		emit PairedNft(currentEpoch, stakingPositionId, stakingPosition2, pairIndex);
	}

	/// @notice Function to request random once per epoch.
	function requestRandom() public
	{
		require(getCurrentStage() == Stage.FifthStage, "Wrong stage!");             // Requires to be at 5th stage.

		vault.increaseMockBalance();

		zooFunctions.requestRandomNumber();                                             // call random for randomResult from chainlink or blockhash.
	}

	/// @notice Function for chosing winner for exact pair of nft.
	/// @notice returns error if random number for deciding winner is NOT requested NOR fulfilled in ZooFunctions contract
	/// @param pairIndex - index of nft pair.
	function chooseWinnerInPair(uint256 pairIndex) external
	{
		require(getCurrentStage() == Stage.FifthStage, "Wrong stage!");                     // Requires to be at 5th stage.

		NftPair storage pair = pairsInEpoch[currentEpoch][pairIndex];

		require(pair.playedInEpoch == false, "Winner already chosen");                      // Requires to be not paired before.

		uint256 votes1 = rewardsForEpoch[pair.token1][currentEpoch].votes;
		uint256 votes2 = rewardsForEpoch[pair.token2][currentEpoch].votes;
		uint256 randomNumber = zooFunctions.getRandomResult();                                // Gets random number from zooFunctions.

		pair.win = zooFunctions.decideWins(votes1, votes2, randomNumber); 				   // Calculates winner and records it.
		pair.playedInEpoch = true;                                                           // Records that this pair already played this epoch.
		numberOfPlayedPairsInEpoch[currentEpoch]++;                                          // Increments amount of pairs played this epoch.


		// Getting winner and loser to calculate rewards
		(uint256 winner, uint256 loser) = pair.win? (pair.token1, pair.token2) : (pair.token2, pair.token1);
		_calculateBattleRewards(winner, loser);


		emit ChosenWinner(currentEpoch, pair.token1, pair.token2, pair.win, pairIndex, numberOfPlayedPairsInEpoch[currentEpoch]); // Emits ChosenWinner event.

		if (numberOfPlayedPairsInEpoch[currentEpoch] == pairsInEpoch[currentEpoch].length)
		{
			updateEpoch();                                                                   // calls updateEpoch if winner determined in every pair.
		}
	}
	

	/// Calculates calulation logic of battle rewards
	/// @param winner stakingPositionId of NFT that WON in battle
	/// @param loser stakingPositionId of NFT that LOST in battle
	function _calculateBattleRewards(uint256 winner, uint256 loser) internal
	{
		BattleRewardForEpoch storage winnerRewards = rewardsForEpoch[winner][currentEpoch];
		BattleRewardForEpoch storage loserRewards = rewardsForEpoch[loser][currentEpoch];

		uint256 pps1 = winnerRewards.pricePerShareAtBattleStart;

		// Skip if price per share didn't change since pairing
		if (pps1 == vault.pricePerShare())
		{
			return;
		}

		winnerRewards.pricePerShareCoef = vault.pricePerShare() * pps1 / (vault.pricePerShare() - pps1);
		loserRewards.pricePerShareCoef = winnerRewards.pricePerShareCoef;

		// Income = yTokens at battle end - yTokens at battle start
		uint256 income1 = winnerRewards.yTokens - tokensToShares(winnerRewards.tokensAtBattleStart);
		uint256 income2 = loserRewards.yTokens - tokensToShares(loserRewards.tokensAtBattleStart);

		winnerRewards.yTokensSaldo += int256(income1 + income2);
		loserRewards.yTokensSaldo -= int256(income2);

		rewardsForEpoch[winner][currentEpoch + 1].yTokens = winnerRewards.yTokens + income1 + income2;
		rewardsForEpoch[loser][currentEpoch + 1].yTokens = loserRewards.yTokens - income2;
	}


	/// @dev Function for updating position in case of battle didn't happen after pairing.
	function updateInfo(uint256 stakingPositionId) public
	{
		uint256 lastUpdateEpoch = stakingPositionsValues[stakingPositionId].lastUpdateEpoch;
		if (lastUpdateEpoch == currentEpoch)
			return;

		rewardsForEpoch[stakingPositionId][currentEpoch].votes = rewardsForEpoch[stakingPositionId][lastUpdateEpoch].votes;
		rewardsForEpoch[stakingPositionId][currentEpoch].yTokens = rewardsForEpoch[stakingPositionId][lastUpdateEpoch].yTokens;
		stakingPositionsValues[stakingPositionId].lastUpdateEpoch = currentEpoch;
	}

	/// @notice Function to increment epoch.
	function updateEpoch() public {
		require(getCurrentStage() == Stage.FifthStage, "Wrong stage!");             // Requires to be at fourth stage.
		require(block.timestamp >= epochStartDate + epochDuration || numberOfPlayedPairsInEpoch[currentEpoch] == pairsInEpoch[currentEpoch].length); // Requires fourth stage to end, or determine every pair winner.

		zooFunctions = IZooFunctions(zooGovernance.zooFunctions());                 // Sets ZooFunctions to contract specified in zooGovernance.

		epochStartDate = block.timestamp;                                           // Sets start date of new epoch.
		currentEpoch++;                                                             // Increments currentEpoch.
		epochsStarts[currentEpoch] = block.timestamp;
		nftsInGame = 0;                                                             // Nullifies amount of paired nfts.

		zooFunctions.resetRandom();     // Resets random in zoo functions.

		firstStageDuration = zooFunctions.firstStageDuration();
		secondStageDuration = zooFunctions.secondStageDuration();
		thirdStageDuration = zooFunctions.thirdStageDuration();
		fourthStageDuration = zooFunctions.fourthStageDuration();
		fifthStageDuration = zooFunctions.fifthStageDuration();

		epochDuration = firstStageDuration + secondStageDuration + thirdStageDuration + fourthStageDuration + fifthStageDuration; // Total duration of battle epoch.

		emit EpochUpdated(block.timestamp, currentEpoch);
	}

	/// @notice Function to calculate incentive reward for voter.
	function calculateIncentiveRewardForVoter(uint256 votingPositionId) external only(nftVotingPosition) returns (uint256)
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];

		address collection = stakingPositionsValues[votingPosition.stakingPositionId].collection;
		updateInfo(votingPosition.stakingPositionId);
		uint256 lastEpoch = computeLastEpoch(votingPositionId); // Last epoch 

		veZoo.updateCurrentEpochAndReturnPoolWeight(collection);
		veZoo.updateCurrentEpochAndReturnPoolWeight(address(0));

		// todo: should to add zooRewardDebt and update it every call with dai operations.
		uint256 start = votingPosition.lastEpochOfIncentiveReward;
		uint256 reward = 0;
		for (uint256 i = votingPosition.lastEpochOfIncentiveReward; i < lastEpoch; i++) // Need different start epoch and last epoch.
		{
			uint256 startEpoch = veZoo.getEpochNumber(epochsStarts[i]);
			uint256 endEpoch = veZoo.getEpochNumber(epochsStarts[i + 1]);
			// todo: should to move calculations to veZoo
			for (uint256 j = startEpoch; j < endEpoch; j++)
			{
				if (veZoo.poolWeight(address(0), j) != 0 && rewardsForEpoch[votingPosition.stakingPositionId][i].votes != 0)
					reward += baseVoterReward * votingPosition.daiVotes * veZoo.poolWeight(collection, j) / veZoo.poolWeight(address(0), j) / rewardsForEpoch[votingPosition.stakingPositionId][i].votes;
			}
		}

		votingPosition.lastEpochOfIncentiveReward = currentEpoch;

		return reward;
	}

	/// @notice Function to calculate incentive reward for staker.
	function calculateIncentiveRewardForStaker(uint256 stakingPositionId) external only(nftStakingPosition) returns (uint256)
	{
		StakerPosition storage stakingPosition = stakingPositionsValues[stakingPositionId];

		address collection = stakingPosition.collection;
		updateInfo(stakingPositionId);
		updateInfoAboutStakedNumber(collection);
		veZoo.updateCurrentEpochAndReturnPoolWeight(collection);
		veZoo.updateCurrentEpochAndReturnPoolWeight(address(0));

		uint256 end = stakingPosition.endEpoch == 0 ? currentEpoch : stakingPosition.endEpoch; 

		uint256 reward = 0;
		uint256 start = stakingPosition.lastEpochOfIncentiveReward;

		for (uint256 i = start; i < end; i++)
		{
			uint256 startEpoch = veZoo.getEpochNumber(epochsStarts[i]);
			uint256 endEpoch = veZoo.getEpochNumber(epochsStarts[i + 1]);
			for (uint256 j = startEpoch; j < endEpoch; j++)
			{
				if (veZoo.poolWeight(address(0), j) != 0)
					reward += baseStakerReward * veZoo.poolWeight(collection, j) / veZoo.poolWeight(address(0), j) / numberOfStakedNftsInCollection[i][collection];
			}
		}

		stakingPosition.lastEpochOfIncentiveReward = currentEpoch;

		return reward;
	}

	/// @notice Function to get last epoch.
	function computeLastEpoch(uint256 votingPositionId) public view returns (uint256 lastEpochNumber)
	{
		uint256 stakingPositionId = votingPositionsValues[votingPositionId].stakingPositionId;  // Gets staker position id from voter position.
		uint256 lastEpochOfStaking = stakingPositionsValues[stakingPositionId].endEpoch;        // Gets endEpoch from staking position.

		// Staking - finished, Voting - finished
		if (lastEpochOfStaking != 0 && votingPositionsValues[votingPositionId].endEpoch != 0)
		{
			lastEpochNumber = Math.min(lastEpochOfStaking, votingPositionsValues[votingPositionId].endEpoch);
		}
		// Staking - finished, Voting - existing 
		else if (lastEpochOfStaking != 0)
		{
			lastEpochNumber = lastEpochOfStaking;
		}
		// Staking - exists, Voting - finished
		else if (votingPositionsValues[votingPositionId].endEpoch != 0)
		{
			lastEpochNumber = votingPositionsValues[votingPositionId].endEpoch;
		}
		// Staking - exists, Voting - exists
		else
		{
			lastEpochNumber = currentEpoch;
		}
	}

	function updateInfoAboutStakedNumber(address collection) public
	{
		uint256 start = lastUpdatesOfStakedNumbers[collection] > 1 ? lastUpdatesOfStakedNumbers[collection] : 1;
		for (uint256 i = start; i <= currentEpoch; i++)
		{
			numberOfStakedNftsInCollection[i][collection] += numberOfStakedNftsInCollection[i - 1][collection];
		}

		lastUpdatesOfStakedNumbers[collection] = currentEpoch;
	}

	function _daiRewardDistribution(address beneficiary, uint256 stakingPositionId, uint256 daiReward) internal
	{
		address collection = stakingPositionsValues[stakingPositionId].collection;
		address royalteRecipient = veZoo.royalteRecipient(collection);

		dai.transfer(beneficiary, daiReward * 935 / 980);                             // Transfers voter part of reward.
		dai.transfer(treasury, daiReward * 20 / 980);                                 // Transfers treasury part.
		dai.transfer(gasPool, daiReward * 10 / 980);                                  // Transfers gasPool part.
		dai.transfer(team, daiReward * 10 / 980);                                     // Transfers team part.
		dai.transfer(royalteRecipient, daiReward * 5 / 980);
	}

	/// @notice Internal function to calculate amount of zoo to burn and withdraw.
	function _withdrawZoo(uint256 zooAmount, address beneficiary) internal
	{
		uint256 zooWithdraw = zooAmount * 995 / 1000; // Calculates amount of zoo to withdraw.
		uint256 zooToBurn = zooAmount * 5 / 1000;     // Calculates amount of zoo to burn.

		zoo.transfer(beneficiary, zooWithdraw);                                           // Transfers zoo to beneficiary.
		zoo.transfer(address(1), zooToBurn);
	}

	/// @notice Function to view current stage in battle epoch.
	/// @return stage - current stage.
	function getCurrentStage() public view returns (Stage)
	{
		if (block.timestamp < epochStartDate + firstStageDuration)
		{
			return Stage.FirstStage;                                                // Staking stage
		}
		else if (block.timestamp < epochStartDate + firstStageDuration + secondStageDuration)
		{
			return Stage.SecondStage;                                               // Dai vote stage.
		}
		else if (block.timestamp < epochStartDate + firstStageDuration + secondStageDuration + thirdStageDuration)
		{
			return Stage.ThirdStage;                                                // Pair stage.
		}
		else if (block.timestamp < epochStartDate + firstStageDuration + secondStageDuration + thirdStageDuration + fourthStageDuration)
		{
			return Stage.FourthStage;                                               // Zoo vote stage.
		}
		else
		{
			return Stage.FifthStage;                                                // Choose winner stage.
		}
	}
}

pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

interface VaultAPI {
	function deposit(uint256 amount) external returns (uint256);

	function withdraw(uint256 maxShares, address recipient) external returns (uint256);

	function pricePerShare() external view returns (uint256);

	function withdrawTokens(uint256 daiNumber, address receiver) external returns (uint256 shares);

	function increaseMockBalance() external;
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

/// @title interface of Zoo functions contract.
interface IZooFunctions {

	/// @notice returns random number.
	function randomResult() external view returns(uint256 random);

	/// @notice sets random number in battles back to zero.
	function resetRandom() external;

	function randomFulfilled() external view returns(bool);

	/// @notice Function for choosing winner in battle.
	function decideWins(uint256 votesForA, uint256 votesForB, uint256 random) external view returns (bool);

	/// @notice Function for generating random number.
	function requestRandomNumber() external;

	/// @notice Function for getting random number.
	function getRandomResult() external returns(uint256);

	function computePseudoRandom() external view returns (uint256);

	/// @notice Function for calculating voting with Dai in vote battles.
	function computeVotesByDai(uint256 amount) external view returns (uint256);

	/// @notice Function for calculating voting with Zoo in vote battles.
	function computeVotesByZoo(uint256 amount) external view returns (uint256);

	function firstStageDuration() external view returns (uint256);

	function secondStageDuration() external view returns (uint256);

	function thirdStageDuration() external view returns (uint256);

	function fourthStageDuration() external view returns (uint256);

	function fifthStageDuration() external view returns (uint256);
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "IZooFunctions.sol";
import "Ownable.sol";

/// @title Contract ZooGovernance.
/// @notice Contract for Zoo Dao vote proposals.
contract ZooGovernance is Ownable {

	address public zooFunctions;                    // Address of contract with Zoo functions.

	/// @notice Contract constructor.
	/// @param baseZooFunctions - address of baseZooFunctions contract.
	/// @param aragon - address of aragon zoo dao agent.
	constructor(address baseZooFunctions, address aragon) {

		zooFunctions = baseZooFunctions;

		transferOwnership(aragon);                  // Sets owner to aragon.
	}

	/// @notice Function for vote for changing Zoo fuctions.
	/// @param newZooFunctions - address of new zoo functions contract.
	function changeZooFunctionsContract(address newZooFunctions) external onlyOwner
	{
		zooFunctions = newZooFunctions;
	}

}

pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "Ownable.sol";
import "IERC20.sol";
import "ERC721.sol";

/// @title ListingList
/// @notice Contract for recording nft contracts eligible for Zoo Dao Battles.
contract ListingList is Ownable, ERC721
{
	struct CollectionRecord
	{
		uint256 decayRate;
		uint256 rateOfIncrease;
		uint256 weightAtTheStart;
	}

	struct VePositionInfo
	{
		uint256 expirationDate;
		uint256 zooLocked;
		address collection;
		uint256 decayRate;
	}

	IERC20 public zoo;                                                               // Zoo collection interface.

	/// @notice Event records address of allowed nft contract.
	event NewContractAllowed(address indexed collection, address royalteRecipient);

	event ContractDisallowed(address indexed collection, address royalteRecipient);

	event RoyalteRecipientChanged(address indexed collection, address recipient);

	event VotedForCollection(address indexed collection, address indexed voter, uint256 amount);

	event ZooUnlocked(address indexed voter,address indexed collection, uint256 amount);

	mapping (address => uint256) public lastUpdatedEpochsForCollection;

	// Nft contract => allowed or not.
	mapping (address => bool) public eligibleCollections;

	// Nft contract => address recipient.
	mapping (address => address) public royalteRecipient;

	// collection => epoch number => Record
	mapping (address => mapping (uint256 => CollectionRecord)) public collectionRecords;

	mapping (uint256 => VePositionInfo) public vePositions;

	mapping (address => uint256[]) public tokenOfOwnerByIndex;

	uint256 public epochDuration;

	uint256 public startDate;

	uint256 public minTimelock;

	uint256 public maxTimelock;

	uint256 public vePositionIndex = 1;

	constructor(address _zoo, uint256 _duration, uint256 _minTimelock, uint256 _maxTimelock) ERC721("veZoo", "VEZOO")
	{
		require(_minTimelock <= _duration, "Duration should be more than minTimeLock");

		zoo = IERC20(_zoo);
		startDate = block.timestamp;
		epochDuration = _duration;
		minTimelock = _minTimelock;
		maxTimelock = _maxTimelock;
	}

	function getEpochNumber(uint256 timestamp) public view returns (uint256)
	{
		return (timestamp - startDate) / epochDuration + 1;// epoch numbers must start from 1
	}

	function getVectorForEpoch(address collection, uint256 epochIndex) public view returns (uint256)
	{
		require(lastUpdatedEpochsForCollection[collection] >= epochIndex, "Epoch record was not updated");

		return computeVectorForEpoch(collection, epochIndex);
	}

	// address(0) for total (collection sum)
	/// @notice Function to get ve-model pool weight for nft collection.
	function poolWeight(address collection, uint256 epochIndex) public view returns(uint256 weight)
	{
		require(lastUpdatedEpochsForCollection[collection] >= epochIndex, "Epoch and colletion records were not updated");

		return collectionRecords[collection][epochIndex].weightAtTheStart;
	}

	function updateCurrentEpochAndReturnPoolWeight(address collection) public returns (uint256 weight)
	{
		uint256 epochNumber = getEpochNumber(block.timestamp);
		uint256 i = lastUpdatedEpochsForCollection[collection];
		weight = poolWeight(collection, i);

		while (i < epochNumber)
		{
			CollectionRecord storage collectionRecord = collectionRecords[collection][i + 1];
			CollectionRecord storage collectionRecordOfPreviousEpoch = collectionRecords[collection][i];

			collectionRecord.weightAtTheStart = collectionRecord.weightAtTheStart + collectionRecordOfPreviousEpoch.weightAtTheStart - computeVectorForEpoch(collection, i) * epochDuration;
			collectionRecord.decayRate += collectionRecordOfPreviousEpoch.decayRate;
			collectionRecord.rateOfIncrease += collectionRecordOfPreviousEpoch.rateOfIncrease;

			i++;
			weight = collectionRecord.weightAtTheStart;
		}

		lastUpdatedEpochsForCollection[collection] = epochNumber;
	}

/* ========== Eligible projects and royalte managemenet ===========*/

	/// @notice Function to allow new NFT contract into eligible projects.
	/// @param collection - address of new Nft contract.
	function allowNewContractForStaking(address collection, address _royalteRecipient) external onlyOwner
	{
		eligibleCollections[collection] = true;                                          // Boolean for contract to be allowed for staking.

		royalteRecipient[collection] = _royalteRecipient;                                // Recipient for % of reward from that nft collection.

		lastUpdatedEpochsForCollection[collection] = getEpochNumber(block.timestamp);

		emit NewContractAllowed(collection, _royalteRecipient);                                             // Emits event that new contract are allowed.
	}

	/// @notice Function to allow multiplie contracts into eligible projects.
	function batchAllowNewContract(address[] calldata tokens, address[] calldata royalteRecipients) external onlyOwner
	{
		for (uint256 i = 0; i < tokens.length; i++)
		{
			eligibleCollections[tokens[i]] = true;

			royalteRecipient[tokens[i]] = royalteRecipients[i];                     // Recipient for % of reward from that nft collection.

			emit NewContractAllowed(tokens[i], royalteRecipients[i]);                                     // Emits event that new contract are allowed.
		}
	}

	/// @notice Function to disallow contract from eligible projects and change royalte recipient for already staked nft.
	function disallowContractFromStaking(address collection, address recipient) external onlyOwner
	{
		eligibleCollections[collection] = false;

		royalteRecipient[collection] = recipient;                                        // Recipient for % of reward from that nft collection.

		emit ContractDisallowed(collection, recipient);                                             // Emits event that new contract are allowed.
	}

	/// @notice Function to set or change royalte recipient without removing from eligible projects.
	function setRoyalteRecipient(address collection, address recipient) external onlyOwner
	{
		royalteRecipient[collection] = recipient;

		emit RoyalteRecipientChanged(collection, recipient);
	}

/* ========== Ve-Model voting part ===========*/
	
	function voteForNftCollection(address collection, uint256 amount, uint256 lockTime) public
	{
		require(eligibleCollections[collection], "NFT collection is not allowed");
		require(lockTime <= maxTimelock && lockTime >= minTimelock, "incorrect lockTime");
		

		zoo.transferFrom(msg.sender, address(this), amount);

		addRecordForNewPosition(collection, amount, lockTime, msg.sender);

		tokenOfOwnerByIndex[msg.sender].push(vePositionIndex);
		_mint(msg.sender, vePositionIndex++);
	}

	function unlockZoo(uint256 positionId) external
	{
		VePositionInfo storage vePosition = vePositions[positionId];
		require(ownerOf(positionId) == msg.sender);
		uint256 currentEpoch = getEpochNumber(block.timestamp);
		
		require(block.timestamp >= vePosition.expirationDate, "time lock doesn't expire");

		zoo.transfer(msg.sender, vePosition.zooLocked);
		_burn(positionId);

		emit ZooUnlocked(msg.sender, vePosition.collection, vePosition.zooLocked);
	}

	function prolongate(uint256 positionId, uint256 lockTime) external
	{
		require(lockTime <= maxTimelock && lockTime >= minTimelock, "incorrect lockTime");

		VePositionInfo storage vePosition = vePositions[positionId];
		require(ownerOf(positionId) == msg.sender);
		uint256 currentEpoch = getEpochNumber(block.timestamp);
		uint256 expirationEpoch = getEpochNumber(vePosition.expirationDate);
		address collection = vePosition.collection;
		uint256 decayRate = vePosition.decayRate;

		updateCurrentEpochAndReturnPoolWeight(collection);
		updateCurrentEpochAndReturnPoolWeight(address(0));

		if (expirationEpoch < currentEpoch)
		{
			collectionRecords[msg.sender][expirationEpoch].rateOfIncrease -= decayRate;
			collectionRecords[msg.sender][getEpochNumber(block.timestamp)].rateOfIncrease += decayRate;
		}

		addRecordForNewPosition(collection, vePosition.zooLocked, lockTime, msg.sender);
	}

	function addRecordForNewPosition(address collection, uint256 amount, uint256 lockTime, address owner) internal
	{
		uint256 weight = amount * lockTime / maxTimelock;
		uint256 currentEpoch = getEpochNumber(block.timestamp);

		uint256 unlockEpoch = getEpochNumber(block.timestamp + lockTime);
		uint256 decay = weight / lockTime;
		vePositions[vePositionIndex] = VePositionInfo(block.timestamp + lockTime, amount, collection, decay);

		collectionRecords[address(0)][currentEpoch + 1].decayRate += decay;
		collectionRecords[address(0)][currentEpoch + 1].weightAtTheStart += weight;
		collectionRecords[collection][currentEpoch + 1].decayRate += decay;
		collectionRecords[collection][currentEpoch + 1].weightAtTheStart += weight;

		collectionRecords[address(0)][unlockEpoch].rateOfIncrease += decay;
		collectionRecords[collection][unlockEpoch].rateOfIncrease += decay;
		
		emit VotedForCollection(collection, msg.sender, amount);
	}

	function computeVectorForEpoch(address collection, uint256 epochIndex) internal view returns (uint256)
	{
		CollectionRecord storage collectionRecord = collectionRecords[collection][epochIndex];

		return collectionRecord.decayRate - collectionRecord.rateOfIncrease;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

import "IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}