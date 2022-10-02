//SPDX-License-Identifier: CC0-1.0

/**
 * @notice Implementation of the eip-5516 interface.
 * Note: this implementation only allows for each user to own only 1 token type for each `id`.
 * @author Matias Arazi <[email protected]> , Lucas Martín Grasso Ramos <[email protected]>
 * See https://eips.ethereum.org/EIPS/eip-5516
 *
 */

pragma solidity >=0.8.9;

import "../base/ERC165.sol";
import "../interfaces/ERC1155/IERC1155MetadataURI.sol";
import "../interfaces/ERC1155/IERC1155Receiver.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";
import "../interfaces/IERC5516.sol";
import { LibERC5516 } from  "../libraries/LibERC5516.sol";

contract ERC5516Facet is Context, ERC165, IERC1155, IERC1155MetadataURI, IERC5516 {

    using Address for address;

    string constant internal IPFSURI = "https://ipfs.io/ipfs/";
    string constant public name = "ZERTIFICATES";
    string constant public symbol = "ZERTS";
    string constant internal CONTRACT_URI = "Qmbpy53C1k9XLYhz7UR5YvACYPS3FQEaZb4ffnAGmD2fQL";

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC5516).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     */
    function uri(uint256 id)
        external
        view
        
        override
        returns (string memory)
    {
        return string(abi.encodePacked(IPFSURI, LibERC5516.getTokenURI(id)));
    }

    function contractUri() external pure returns (string memory) {
        return string(
                abi.encodePacked(IPFSURI, CONTRACT_URI)
            );
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     *
     */
    function balanceOf(address account, uint256 id)
        public
        view
        
        override
        returns (uint256)
    {
        require(account != address(0), "EIP5516: Address zero error");
        if (LibERC5516.getBalance(account, id)) {
            return 1;
        } else {
            return 0;
        }
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     *
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "EIP5516: Array lengths mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev Get tokens owned by a given address
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     *
     */
    function tokensFrom(address account)
        public
        view
        
        override
        returns (uint256[] memory)
    {
        require(account != address(0), "EIP5516: Address zero error");

        uint256 nonce = LibERC5516.getNonce();

        uint256 _tokenCount = 0;

        for (uint256 i = 1; i <= nonce; ) {
            if (LibERC5516.getBalance(account, i)) {
                unchecked {
                    ++_tokenCount;
                }
            }
            unchecked {
                ++i;
            }
        }

        uint256[] memory _ownedTokens = new uint256[](_tokenCount);

        for (uint256 i = 1; i <= nonce; ) {
            if (LibERC5516.getBalance(account, i)) {
                _ownedTokens[--_tokenCount] = i;
            }
            unchecked {
                ++i;
            }
        }

        return _ownedTokens;
    }

    /**
     * @dev Get tokens marked as _pendings of a given address
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     *
     */
    function pendingFrom(address account)
        public
        view
        
        override
        returns (uint256[] memory)
    {
        require(account != address(0), "EIP5516: Address zero error");

        uint256 nonce = LibERC5516.getNonce();

        uint256 _tokenCount = 0;

        for (uint256 i = 1; i <= nonce; ) {
            if (LibERC5516.getPending(account, i)) {
                ++_tokenCount;
            }
            unchecked {
                ++i;
            }
        }

        uint256[] memory _pendingTokens = new uint256[](_tokenCount);

        for (uint256 i = 1; i <= nonce; ) {
            if (LibERC5516.getPending(account, i)) {
                _pendingTokens[--_tokenCount] = i;
            }
            unchecked {
                ++i;
            }
        }

        return _pendingTokens;
    }

    /**
     * @dev Get the URI of the tokens marked as pending of a given address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     *
     */
    function tokensURIFrom(address account)
        external
        view
        
        returns (string[] memory)
    {
        require(account != address(0), "EIP5516: Address zero error");

        (uint256[] memory ownedTokens) = tokensFrom(account);
        uint256 _nTokens = ownedTokens.length;
        string[] memory tokenURIS = new string[](_nTokens);
        
        for (uint256 i = 0; i < _nTokens; ) {
            tokenURIS[i] = string(
                abi.encodePacked(IPFSURI, LibERC5516.getTokenURI(ownedTokens[i]))
            );

            unchecked {
                ++i;
            }
        } 
        return tokenURIS;
    }

    /**
     * @dev Get the URI of the tokens owned by a given address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     *
     */
    function pendingURIFrom(address account)
        external
        view
        
        returns (string[] memory)
    {
        require(account != address(0), "EIP5516: Address zero error");

        (uint256[] memory pendingTokens) = pendingFrom(account);
        uint256 _nTokens = pendingTokens.length;
        string[] memory tokenURIS = new string[](_nTokens);
        
        for (uint256 i = 0; i < _nTokens; ) {
            tokenURIS[i] = string(
                abi.encodePacked(IPFSURI, LibERC5516.getTokenURI(pendingTokens[i]))
            );

            unchecked {
                ++i;
            }
        } 
        return tokenURIS;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        
        override
        returns (bool)
    {
        return LibERC5516.getApproved(account, operator);
    }


    function mint(string memory data) external {
        address _account = _msgSender();
        _mint(_account, data);
    }

    /**
     * @dev mints(creates) a token
     */
    function _mint(address account, string memory data) internal  {
        
        LibERC5516.addToNonce();

        uint256 nonce = LibERC5516.getNonce();

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(nonce);
        uint256[] memory amounts = _asSingletonArray(1);
        bytes memory _bData = bytes(data);

        _beforeTokenTransfer(
            operator,
            address(0),
            operator,
            ids,
            amounts,
            _bData
        );
        LibERC5516.setTokenURI(nonce, data);
        LibERC5516.setTokenMinter(nonce, account);
        emit TransferSingle(operator, address(0), operator, nonce, 1);
        _afterTokenTransfer(
            operator,
            address(0),
            operator,
            ids,
            amounts,
            _bData
        );
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *
     * Requirements:
     *
     * - `from` must be the creator(minter) of `id` or must have allowed _msgSender() as an operator.
     *
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public  override {
        require(amount == 1, "EIP5516: Can only transfer one token");
        require(
            _msgSender() == LibERC5516.getTokenMinter(id) ||
                isApprovedForAll(LibERC5516.getTokenMinter(id), _msgSender()),
            "EIP5516: Unauthorized"
        );

        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {eip-5516-batchTransfer}
     *
     * Requirements:
     *
     * - 'from' must be the creator(minter) of `id` or must have allowed _msgSender() as an operator.
     *
     */
    function batchTransfer(
        address from,
        address[] memory to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external  override {
        require(amount == 1, "EIP5516: Can only transfer one token");
        require(
            _msgSender() == LibERC5516.getTokenMinter(id) ||
                isApprovedForAll(LibERC5516.getTokenMinter(id), _msgSender()),
            "EIP5516: Unauthorized"
        );

        _batchTransfer(from, to, id, amount, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` must be the creator(minter) of the token under `id`.
     * - `to` must be non-zero.
     * - `to` must have the token `id` marked as _pendings.
     * - `to` must not own a token type under `id`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     *   acceptance magic value.
     *
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal  {
        require(from != address(0), "EIP5516: Address zero error");
        require(
            LibERC5516.getPending(to, id) == false && LibERC5516.getBalance(to, id) == false,
            "EIP5516: Already Assignee"
        );

        address operator = _msgSender();

        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        LibERC5516.setPending(to, id, true);

        emit TransferSingle(operator, from, to, id, amount);
        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * Transfers `_id` token from `_from` to every address at `_to[]`.
     *
     * Requirements:
     * - See {eip-5516-safeMultiTransfer}.
     *
     */
    function _batchTransfer(
        address from,
        address[] memory to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal  {
        address operator = _msgSender();

        _beforeBatchedTokenTransfer(operator, from, to, id, data);

        for (uint256 i = 0; i < to.length; ) {
            address _to = to[i];

            require(_to != address(0), "EIP5516: Address zero error");
            require(
                LibERC5516.getPending(_to, id) == false && LibERC5516.getBalance(_to, id) == false,
                "EIP5516: Already Assignee"
            );

            LibERC5516.setPending(_to, id, true);

            unchecked {
                ++i;
            }
        }

        emit TransferMulti(operator, from, to, amount, id);

        _beforeBatchedTokenTransfer(operator, from, to, id, data);
    }

    /**
     * @dev See {eip-5516-claimOrReject}
     *
     * If action == true: Claims pending token under `id`.
     * Else, rejects pending token under `id`.
     *
     */
    function claimOrReject(
        address account,
        uint256 id,
        bool action
    ) external  override {
        require(_msgSender() == account, "EIP5516: Unauthorized");

        _claimOrReject(account, id, action);
    }

    /**
     * @dev See {eip-5516-claimOrReject}
     *
     * For each `id` - `action` pair:
     *
     * If action == true: Claims pending token under `id`.
     * Else, rejects pending token under `id`.
     *
     */
    function claimOrRejectBatch(
        address account,
        uint256[] memory ids,
        bool[] memory actions
    ) external  override {
        require(
            ids.length == actions.length,
            "EIP5516: Array lengths mismatch"
        );

        require(_msgSender() == account, "EIP5516: Unauthorized");

        _claimOrRejectBatch(account, ids, actions);
    }

    /**
     * @dev Claims or Reject pending token under `_id` from address `_account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have a _pendings token under `id` at the moment of call.
     * - `account` mUST not own a token under `id` at the moment of call.
     *
     * Emits a {TokenClaimed} event.
     *
     */
    function _claimOrReject(
        address account,
        uint256 id,
        bool action
    ) internal  {
        require(
            LibERC5516.getPending(account, id) == true && LibERC5516.getBalance(account, id) == false,
            "EIP5516: Not claimable"
        );

        address operator = _msgSender();

        bool[] memory actions = new bool[](1);
        actions[0] = action;
        uint256[] memory ids = _asSingletonArray(id);

        _beforeTokenClaim(operator, account, actions, ids);

        if (action) {
            LibERC5516.setBalance(account, id, true);
            LibERC5516.setPending(account, id, false);
        } else {
            LibERC5516.setPending(account, id, false);
        }

        emit TokenClaimed(operator, account, actions, ids);

        _afterTokenClaim(operator, account, actions, ids);
    }

    /**
     * @dev Claims or Reject _pendings `_id` from address `_account`.
     *
     * For each `id`-`action` pair:
     *
     * Requirements:
     * - `account` cannot be the zero address.
     * - `account` must have a pending token under `id` at the moment of call.
     * - `account` must not own a token under `id` at the moment of call.
     *
     *  Emits a {TokenClaimed} event.
     *
     */
    function _claimOrRejectBatch(
        address account,
        uint256[] memory ids,
        bool[] memory actions
    ) internal  {
        uint256 totalIds = ids.length;
        address operator = _msgSender();

        _beforeTokenClaim(operator, account, actions, ids);

        for (uint256 i = 0; i < totalIds; ) {
            uint256 id = ids[i];

            require(
                LibERC5516.getPending(account, id) == true &&
                    LibERC5516.getBalance(account, id) == false,
                "EIP5516: Not claimable"
            );

            if (actions[i]) {
                LibERC5516.setBalance(account, id, true);
                LibERC5516.setPending(account, id, false);
            } else {
                LibERC5516.setPending(account, id, false);
            }

            unchecked {
                ++i;
            }
        }

        emit TokenClaimed(operator, account, actions, ids);

        _afterTokenClaim(operator, account, actions, ids);
    }


    function burn(uint256 id) external {
        address account = _msgSender();
        _burn(account, id);
    }

    /**
     * @dev Destroys `id` token from `account`
     *
     * Emits a {TransferSingle} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` must own a token under `id`.
     *
     */
    function _burn(address account, uint256 id) internal  {
        require(LibERC5516.getBalance(account, id) == true, "EIP5516: Unauthorized");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(1);

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        LibERC5516.setBalance(account, id, false);

        emit TransferSingle(operator, account, address(0), id, 1);
        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");
    }

    function burnBatch(uint256[] memory ids) external {
        address account = _msgSender();
        _burnBatch(account, ids);
    }

    /**
     * @dev Destroys all tokens under `ids` from `account`
     *
     * Emits a {TransferBatch} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` must own all tokens under `ids`.
     *
     */
    function _burnBatch(address account, uint256[] memory ids)
        internal
        
    {
        uint256 totalIds = ids.length;
        address operator = _msgSender();
        uint256[] memory amounts = _asSingletonArray(totalIds);
        uint256[] memory values = _asSingletonArray(0);

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < totalIds; ) {
            uint256 id = ids[i];

            require(LibERC5516.getBalance(account, id) == true, "EIP5516: Unauthorized");

            LibERC5516.setBalance(account, id, false);

            unchecked {
                ++i;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, values);

        _afterTokenTransfer(operator, account, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     *
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal{
        require(owner != operator, "ERC1155: setting approval status for self");
        LibERC5516.setApproval(owner, operator, approved);
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - `amount` will always be and must be equal to 1.
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - When `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - `amount` will always be and must be equal to 1.
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - When `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called before any batched token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - `amount` will always be and must be equal to 1.
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - When `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeBatchedTokenTransfer(
        address operator,
        address from,
        address[] memory to,
        uint256 id,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any batched token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - `amount` will always be and must be equal to 1.
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - When `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterBatchedTokenTransfer(
        address operator,
        address from,
        address[] memory to,
        uint256 id,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called before any token claim.
     +
     * Calling conditions (for each `action` and `id` pair):
     *
     * - A token under `id` must exist.
     * - When `action` is non-zero, a token under `id` will now be claimed and owned by`operator`.
     * - When `action` is false, a token under `id` will now be rejected.
     * 
     */
    function _beforeTokenClaim(
        address operator,
        address account,
        bool[] memory actions,
        uint256[] memory ids
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token claim.
     +
     * Calling conditions (for each `action` and `id` pair):
     *
     * - A token under `id` must exist.
     * - When `action` is non-zero, a token under `id` is now owned by`operator`.
     * - When `action` is false, a token under `id` was rejected.
     * 
     */
    function _afterTokenClaim(
        address operator,
        address account,
        bool[] memory actions,
        uint256[] memory ids
    ) internal virtual {}

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev see {ERC1155-_doSafeTransferAcceptanceCheck, IERC1155Receivable}
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    /**
     * @dev Unused/Deprecated function
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {}
}

//SPDX-License-Identifier: CC0-1.0

/**
 * @notice Implementation of the eip-5516 interface.
 * Note: this implementation only allows for each user to own only 1 token type for each `id`.
 * @author Matias Arazi <[email protected]> , Lucas Martín Grasso Ramos <[email protected]>
 * See https://eips.ethereum.org/EIPS/eip-5516
 *
 */

pragma solidity >=0.8.9;

library LibERC5516{

    bytes32 constant internal ERC5516_STORAGE_POSITION = keccak256("ERC5516.facet.storage");

    struct ERC5516Storage {
        // Used for making each token unique, Maintains ID registry and quantity of tokens minted.
        uint256 nonce;
        // Mapping from token ID to account balances
        mapping(address => mapping(uint256 => bool)) balances;

        // Mapping from address to mapping id bool that states if address has tokens(under id) awaiting to be claimed
        mapping(address => mapping(uint256 => bool)) pendings;

        // Mapping from account to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;

        // Mapping from ID to minter address.
        mapping(uint256 => address) tokenMinters;

        // Mapping from ID to URI.
        mapping(uint256 => string) tokenUris;

        // Used as the URI for all token types by relying on ID substitution, e.g. https://ipfs.io/ipfs/token.data
        string uri;

        string name; string symbol;

        string contractUri;
    }

    function diamondStorage() internal pure returns (ERC5516Storage storage ds) {
      bytes32 position = ERC5516_STORAGE_POSITION;
      assembly {
          ds.slot := position
        }
    }
    
    //NONCE FUNCTIONS
    function getNonce() internal view returns (uint256) {
        ERC5516Storage storage ds = diamondStorage();
        return ds.nonce;
    }

    function addToNonce() internal {
        ERC5516Storage storage ds = diamondStorage();
        ds.nonce++;
    }
    //NONCE FUNCTIONS

    //BALANCE FUNCTIONS
    function setBalance(address _account, uint256 _id, bool balance) internal {
        ERC5516Storage storage ds = diamondStorage();
        ds.balances[_account][_id] = balance;
    }

    function getBalance(address _account, uint256 _id) internal view returns (bool) {
        ERC5516Storage storage ds = diamondStorage();
        return ds.balances[_account][_id];
    }
    //BALANCE FUNCTIONS

    //PENDING FUNCTIONS
    function setPending(address _account, uint256 _id, bool pending) internal {
        ERC5516Storage storage ds = diamondStorage();
        ds.pendings[_account][_id] = pending;
    }

    function getPending(address _account, uint256 _id) internal view returns (bool) {
        ERC5516Storage storage ds = diamondStorage();
        return ds.pendings[_account][_id];
    }
    //PENDING FUNCTIONS

    //OPERATOR FUNCTIONS
    function setApproval(address _owner, address _operator, bool _approved) internal {
        ERC5516Storage storage ds = diamondStorage();
        ds.operatorApprovals[_owner][_operator] = _approved;
    }

    function getApproved(address _owner, address _operator) internal view returns (bool) {
        ERC5516Storage storage ds = diamondStorage();
        return ds.operatorApprovals[_owner][_operator];
    }
    //OPERATOR FUNCTIONS

    //TOKEN FUNCTIONS
    function setTokenMinter(uint256 _id, address _minter) internal {
        ERC5516Storage storage ds = diamondStorage();
        ds.tokenMinters[_id] = _minter;
    }

    function getTokenMinter(uint256 _id) internal view returns (address) {
        ERC5516Storage storage ds = diamondStorage();
        return ds.tokenMinters[_id];
    }

    function setTokenURI(uint256 _id, string memory _uri) internal {
        ERC5516Storage storage ds = diamondStorage();
        ds.tokenUris[_id] = _uri;
    }

    function getTokenURI(uint256 _id) internal view returns (string memory) {
        ERC5516Storage storage ds = diamondStorage();
        return ds.tokenUris[_id];
    }
    //TOKEN FUNCTIONS

}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.8;

/**
    @title Soulbound, Multi-Token standard.
    @notice Interface of the EIP-5516
    Note: The ERC-165 identifier for this interface is 0x8314f22b.
 */

interface IERC5516 {
    /**
     * @dev Emitted when `account` claims or rejects pending tokens under `ids[]`.
     */
    event TokenClaimed(
        address indexed operator,
        address indexed account,
        bool[] actions,
        uint256[] ids
    );

    /**
     * @dev Emitted when `from` transfers token under `id` to every address at `to[]`.
     */
    event TransferMulti(
        address indexed operator,
        address indexed from,
        address[] to,
        uint256 amount,
        uint256 id
    );

    /**
     * @dev Get tokens owned by a given address.
     */
    function tokensFrom(address from) external view returns (uint256[] memory);

    /**
     * @dev Get tokens awaiting to be claimed by a given address.
     */
    function pendingFrom(address from) external view returns (uint256[] memory);

    /**
     * @dev Claims or Reject pending `id`.
     *
     * Requirements:
     * - `account` must have a pending token under `id` at the moment of call.
     * - `account` must not own a token under `id` at the moment of call.
     *
     * Emits a {TokenClaimed} event.
     *
     */
    function claimOrReject(
        address account,
        uint256 id,
        bool action
    ) external;

    /**
     * @dev Claims or Reject pending tokens under `ids[]`.
     *
     * Requirements for each `id` `action` pair:
     * - `account` must have a pending token under `id` at the moment of call.
     * - `account` must not own a token under `id` at the moment of call.
     *
     * Emits a {TokenClaimed} event.
     *
     */
    function claimOrRejectBatch(
        address account,
        uint256[] memory ids,
        bool[] memory actions
    ) external;

    /**
     * @dev Transfers `_id` token from `_from` to every address at `_to[]`.
     *
     * Requirements:
     *
     * - `_from` MUST be the creator(minter) of `id`.
     * - All addresses in `to[]` MUST be non-zero.
     * - All addresses in `to[]` MUST have the token `id` under `_pendings`.
     * - All addresses in `to[]` MUST not own a token type under `id`.
     *
     * Emits a {TransfersMulti} event.
     *
     */
    function batchTransfer(
        address from,
        address[] memory to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
    
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC165.sol";

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

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../IERC165.sol";

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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