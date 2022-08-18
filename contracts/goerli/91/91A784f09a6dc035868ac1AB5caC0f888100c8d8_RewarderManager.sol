/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: Rewarder/RewarderManager.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;



contract RewarderManager{

    address internal owner;
    address dropStorage;
    address coreServer;
    address questServer;
    address hypoContract;
    mapping (uint => uint) hypoNonce;
    IERC1155 RobotParts;

    struct transaction{
        uint8[5] rewards;
        address address_;
        uint id;
        uint hypoId;
        bytes sign;
    }

    constructor(address robotparts){
        owner = msg.sender;
        RobotParts = IERC1155(robotparts);
    }

    function setVault (address newVault_) public {
        require(msg.sender == owner, "RewardManager: you are not an owner");
        dropStorage = newVault_;
    }

    function setCoreServer (address server_) public{
        require(msg.sender == owner, "You are not an owner");
        coreServer = server_;
    }

    function setQuestServer (address server_) public{
        require(msg.sender == owner, "You are not an owner");
        questServer = server_;
    }

    function setHypoContract (address newContract) public{
        require(msg.sender == owner, "You are not an owner");
        hypoContract = newContract;
    }

    function setOwner (address newOwner) public {
        require(msg.sender == owner, "You are not an owner");
        owner = newOwner;
    }

    function getSessionId (uint id) public view returns(uint){
        return hypoNonce[id];
    }

    
    function checkTxSign(transaction[] calldata _txs, bytes calldata sign) public view returns(bool){
        return areAllTxsSigned(_txs, sign);
    }

    function unstorage (transaction[] calldata _txs, bytes calldata sign)public {
        require(areAllTxsSigned(_txs, sign), "RewarderManager: wrong signature");
        IERC721 Hypo = IERC721(hypoContract);
        require(Hypo.ownerOf(_txs[0].hypoId) == msg.sender, "You are not an owner of hypo");
        hypoNonce[_txs[0].hypoId] += 1;
        uint _id = _txs[0].hypoId;
        uint256[] memory robotPartsAmount = new uint[](5);
        for (uint i = 0; i < _txs.length; i++){
            require(_id == _txs[i].hypoId, "Quests from different hypos");
            for(uint k = 0; k < 5; k++){
                robotPartsAmount[k] += _txs[i].rewards[k];
            }
            if (_txs[i].address_ != address(0)){
                IERC721 NFT = IERC721(_txs[i].address_);
                NFT.safeTransferFrom(dropStorage, msg.sender, _txs[i].id, "");
            }
        }
        uint256[] memory ids = new uint256[](5);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;
        ids[3] = 3;
        ids[4] = 4;
        RobotParts.safeBatchTransferFrom(dropStorage, msg.sender, ids, robotPartsAmount, "");
    }

    function areAllTxsSigned(transaction[] calldata _txs, bytes calldata sign) private view returns(bool){
        bytes memory gsign;
        for (uint i = 0; i < _txs.length; i++){
            gsign = abi.encodePacked(gsign, _txs[i].sign);
        }
        bool r = isSigned(keccak256(gsign), sign, coreServer);
        require(r, "RewarderManager: General signature error");
        for (uint i = 0; i < _txs.length; i++){
            r = isTxSigned(_txs[i], questServer) && r;
            require(r, "RewarderManager: Tx signature error");
        }
        return r; 
    }

    function isTxSigned (transaction calldata _tx, address _address)private view returns(bool){
        bytes32 _messageHash = keccak256(txMessage(_tx));
        return isSigned(_messageHash, _tx.sign, _address);
    }

    function txMessage(transaction calldata _tx)private view returns(bytes memory){
        return abi.encodePacked(_tx.rewards[0],_tx.rewards[1],_tx.rewards[2],_tx.rewards[3],_tx.rewards[4],_tx.address_, _tx.id, _tx.hypoId, hypoNonce[_tx.hypoId]);
    }

    function isSigned (bytes32 _messageHash, bytes calldata _sign, address _address)private pure returns(bool){
        return recover(getEthSignedHash(_messageHash), _sign) == _address;
    }

    function getEthSignedHash(bytes32 _messageHash) private pure returns(bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    function recover(bytes32 _messageSignedHash, bytes memory _sign)private pure returns(address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_sign);
        return ecrecover(_messageSignedHash, v, r, s);
    }
    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v){
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }


}