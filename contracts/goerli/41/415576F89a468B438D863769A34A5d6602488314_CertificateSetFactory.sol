// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./CertificateSet.sol";

contract CertificateSetFactory is Ownable {
    address public walletMapping;
    address[] private _certificateSets;

    constructor(address _walletMapping) {
        walletMapping = _walletMapping;
    }

    /**
     * @notice Deploys a new CertificateSet contract
     * @dev Only callable by CertificateSetFactory owner
     * @param owner Contract owner address
     */
    function createCertificateSet(
        address owner,
        string memory baseUri
    ) external onlyOwner {
        address newCertificateSet = address(
            new CertificateSet(owner, walletMapping, baseUri)
        );
        _certificateSets.push(newCertificateSet);
    }

    /**
     * @notice Returns array of all deployed CertificateSet contract addresses
     * @return Array of CertificateSet contract addresses
     */
    function certificateSets() public view returns (address[] memory) {
        return _certificateSets;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IWalletMapping.sol";
import "../interfaces/ICertificateSet.sol";
import "./BitMaps.sol";

contract CertificateSet is
    Context,
    ERC165,
    IERC1155,
    ICertificateSet,
    Ownable,
    IERC1155MetadataURI
{
    using BitMaps for BitMaps.BitMap;

    enum CertificateStatus{ CREATED, DROPPED, ISSUED }

    address public walletMapping;
    uint96 public maxCertificateType;
    string public contractURI;
    string private _uri;
    mapping(address => BitMaps.BitMap) private _balances;
    mapping(uint256 => uint256) private _expiries;

//===========================

    //Certificate issuer (ADMIN)
    mapping(uint256 => address) private _issuer;
    
    //Certificate value of keccak256(receiver_name + certificate_no + certificate_title + description_text + certificate_score + certificate_date)
    mapping(uint256 => bytes32) private _certificateHash;

    //Certificate receiver
    mapping(uint256 => address) private _receiver;
    mapping(uint256 => bool) private _signedByReceiver;

    //Certificate signer
    mapping(uint256 => uint256) private _totalApprover;
    mapping(uint256 => uint) private _totalSignature;
    mapping(uint256 => address[]) private _approvers;
    mapping(uint256 => bool[]) private _signedByApprovers;

    mapping(uint256 => CertificateStatus) public _status;

//===========================



    address private constant ZERO_ADDRESS = address(0);
    uint256 private constant BITMAP_SIZE = 256;

    event CertificateDropped(uint256 date);
    event CertificateIssued(uint256 date);
    event SignedByReceiver(address receiver, uint256 date);
    event SignedByApprover(address approver, uint256 date);

    constructor(
        address _owner,
        address _walletMapping,
        string memory _baseUri
    ) {
        walletMapping = _walletMapping;
        setURI(
            string.concat(
                _baseUri,
                Strings.toHexString(uint160(address(this)), 20),
                "/"
            )
        ); // base + address(this) + /
        setContractURI(
            string.concat(
                _baseUri,
                Strings.toHexString(uint160(address(this)), 20),
                "/"
            )
        ); // base + address(this) + /
        transferOwnership(_owner);
    }

    /**
     * @notice Get token metadata URI
     * @param id token id
     * @return URI string
     */
    function uri(uint256 id) external view returns (string memory) {
        return string.concat(_uri, Strings.toString(id));
    }

    /**
     * @notice Get token expiry timestamp (unix)
     * @param tokenId token id
     * @return expiry timestamp (unix)
     */
    function expiryOf(uint256 tokenId) external view returns (uint256) {
        return _expiries[tokenId];
    }

    /**
     * @notice Get balances for a list of token/address pairs
     * @param accounts account addresses
     * @param ids token ids
     * @return array of balances for each token/address pair
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) external view returns (uint256[] memory) {
        uint256 count = accounts.length;
        if (count != ids.length) revert ArrayParamsUnequalLength();
        uint256[] memory batchBalances = new uint256[](count);
        for (uint256 i = 0; i < count; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }

    /**
     * @notice Mint token to an account address
     * @dev Checks if "to" address param has an associated linked wallet (in WalletMapping). If yes, mints to that address. If no, mints to the "to" address. Only callable by contract owner.
     * @param to Address to mint to
     * @param certificateType Desired certificate type to mint (must not currently own)
     * @param expiry Token expiration timestamp (unix). If no expiry, input "0"
     * @return tokenId Token id of successfully minted token
     */
    function mint(
        address to,
        uint96 certificateType,
        uint256 expiry,        
        bytes32 certificateHash,
        address[] memory signers
    ) external onlyOwner returns (uint256 tokenId) {
        address user = getUser(to);

        tokenId = _mint(user, certificateType, expiry, certificateHash, signers);

        emit TransferSingle(_msgSender(), ZERO_ADDRESS, user, tokenId, 1);
        _doSafeTransferAcceptanceCheck(
            _msgSender(),
            ZERO_ADDRESS,
            user,
            tokenId,
            1,
            ""
        );
    }

    function receiverSigning(uint256 tokenId, bytes memory signature) external {
        _receiverSigning(tokenId, signature);
        emit CertificateIssued(block.timestamp);
    }
    
    function approverSigning(uint256 tokenId, bytes memory signature) external {
        _approverSigning(tokenId, signature);
    }

    /**
     * @notice Mint multiple tokens to an account address
     * @dev Checks if "to" address param has an associated linked wallet (in WalletMapping). If yes, mints to that address. If no, mints to the "to" address. Only callable by contract owner.
     * @param account Address to mint to
     * @param certificateTypes Certificate types to mint
     * @param expiries Token expiration timestamps (unix). If no expiries, input array of "0" (matching certificateTypes length)
     * @return tokenIds Token ids of successfully minted tokens
     */
    function mintBatch(
        address account,
        uint96[] memory certificateTypes,
        uint256[] memory expiries,
        bytes32[] memory certificateHash,
        address[][] memory signers
    ) external onlyOwner returns (uint256[] memory tokenIds) {
        if (certificateTypes.length != expiries.length)
            revert ArrayParamsUnequalLength();
        address user = getUser(account);
        uint256 mintCount = certificateTypes.length;

        tokenIds = new uint[](mintCount);
        uint[] memory amounts = new uint[](mintCount); // used in event

        for (uint256 i = 0; i < mintCount; i++) {
            uint256 tokenId = _mint(user, certificateTypes[i], expiries[i], certificateHash[i], signers[i]);
            tokenIds[i] = tokenId;
            amounts[i] = 1;
        }

        emit TransferBatch(_msgSender(), ZERO_ADDRESS, user, tokenIds, amounts);
        _doSafeBatchTransferAcceptanceCheck(
            _msgSender(),
            ZERO_ADDRESS,
            user,
            tokenIds,
            amounts,
            ""
        );
    }

    /**
     * @notice Revoke (burn) a token from an account address
     * @dev Checks if "account" address param has an associated linked wallet (in WalletMapping). If yes, revokes from that address. If no, revokes from the "account" address. Only callable by contract owner. Deletes token expiry.
     * @param account Address to revoke from
     * @param certificateType Certificate type to revoke (must currently own)
     * @return tokenId Token id of successfully revoked token
     */
    function revoke(
        address account,
        uint96 certificateType
    ) external onlyOwner returns (uint256 tokenId) {
        address user = getUser(account);
        tokenId = _revoke(user, certificateType);
        emit TransferSingle(_msgSender(), user, ZERO_ADDRESS, tokenId, 1);
    }

    /**
     * @notice Revoke (burn) multiple tokens from an account address
     * @dev Checks if "account" address param has an associated linked wallet (in WalletMapping). If yes, revokes from that address. If no, revokes from the "account" address. Only callable by contract owner. Deletes token expiry.
     * @param account Address to revoke from
     * @param certificateTypes Desired certificate types to revoke (must currently own)
     * @return tokenIds Token ids of successfully revoked tokens
     */
    function revokeBatch(
        address account,
        uint96[] memory certificateTypes
    ) external onlyOwner returns (uint[] memory tokenIds) {
        address user = getUser(account);
        uint256 revokeCount = certificateTypes.length;

        tokenIds = new uint[](revokeCount); // used in event, return value
        uint[] memory amounts = new uint[](revokeCount); // used in event

        for (uint256 i = 0; i < revokeCount; i++) {
            uint256 tokenId = _revoke(user, certificateTypes[i]);
            tokenIds[i] = tokenId;
            amounts[i] = 1;
        }

        emit TransferBatch(_msgSender(), user, ZERO_ADDRESS, tokenIds, amounts);
    }

    // TODO: this should have a return check value
    /**
     * @notice Transition tokens from a lite wallet to a linked real wallet
     * @dev Certificate (token) ownership state is stored in bitmaps. To save gas, this function copies over the "from" address's bitmap state (1 uint256 for each 256 token types) to the "to" address, and emits individual transfer events in a loop.
     * @param from Address to transiton all tokens from
     * @param to Address to transition all tokens to
     */
    function moveUserTokensToWallet(address from, address to) external {
        if (getUser(from) != to) revert WalletNotLinked(to);
        uint256 bitmapCount = maxCertificateType / BITMAP_SIZE;
        for (uint256 i = 0; i <= bitmapCount; i++) {
            uint256 bitmap = _balances[from]._data[i];
            if (bitmap != 0) {
                emitTransferEvents(bitmap, from, to);
                _balances[to]._data[i] = bitmap; // copy over ownership bitmap
                delete _balances[from]._data[i]; // delete old ownership bitmap
            }
        }
        emit TransitionWallet(from, to);
    }

    // No-Ops for ERC1155 transfer and approval functions. CertificateSet tokens are Soulbound and cannot be transferred. Functions are included for ERC1155 interface compliance

    /** 
     * @notice will revert. Soulbound tokens cannot be transferred.
    */
    function setApprovalForAll(address operator, bool approved) external pure {
        revert SoulboundTokenNoSetApprovalForAll(operator, approved);
    }

    /** 
     * @notice will revert. Soulbound tokens cannot be transferred.
    */
    function isApprovedForAll(
        address account,
        address operator
    ) external pure returns (bool) {
        revert SoulboundTokenNoIsApprovedForAll(account, operator);
    }

    /** 
     * @notice will revert. Soulbound tokens cannot be transferred.
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external pure {
        revert SoulboundTokenNoSafeTransferFrom(from, to, id, amount, data);
    }

    /** 
     * @notice will revert. Soulbound tokens cannot be transferred.
    */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external pure {
        revert SoulboundTokenNoSafeBatchTransferFrom(
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice Update token metadata base URI
     * @param newuri New URI
     */
    function setURI(string memory newuri) public onlyOwner {
        _uri = newuri;
    }

    /**
     * @notice Update contract metadata URI
     * @param newuri New URI
     */
    function setContractURI(string memory newuri) public onlyOwner {
        contractURI = newuri;
    }

    /**
     * @notice Get token balance of an account address
     * @param account Account address
     * @param id Token id
     * @return balance Token balance (1 or 0)
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view returns (uint256 balance) {
        (uint96 _certificateType, address _account) = decodeTokenId(id);
        address user = getUser(_account);
        if (user != account) return 0;
        BitMaps.BitMap storage bitmap = _balances[user];
        bool owned = BitMaps.get(bitmap, _certificateType);
        return owned ? 1 : 0;
    }

    /**
     * @notice Returns a serialized token id based on a certificateType and owner account address
     * @dev Each user can only own one of each certificate type. Serializing ids based on a certificateType and owner address allows us to have both shared, certificateType level metadata as well as individual token data (e.g. expiry timestamp). First 12 bytes = certificateType (uint96), next 20 bytes = owner address.
     * @param certificateType Certificate type
     * @param account Owner account address
     * @return tokenId Serialized token id
     */
    function encodeTokenId(
        uint96 certificateType,
        address account
    ) public pure returns (uint256 tokenId) {
        tokenId = uint256(bytes32(abi.encodePacked(certificateType, account)));
    }

    /**
     * @notice Decodes a serialized token id to reveal its certificateType and owner account address
     * @param tokenId Serialized token id
     * @return certificateType Certificate type
     * @return account Owner account address
     */
    function decodeTokenId(
        uint256 tokenId
    ) public pure returns (uint96 certificateType, address account) {
        certificateType = uint96(tokenId >> 160);
        account = address(uint160(uint256(((bytes32(tokenId) << 96) >> 96))));
    }

    /** 
     * @dev Verifies contract supports the standard ERC1155 interface
    */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

   
    

    /** 
     * @dev Internal shared function to mint tokens and set expiries
    */
    function _mint(
        address user,
        uint96 certificateType,
        uint256 expiry,
        bytes32 certificateHash,
        address[] memory signers
    ) internal returns (uint256 tokenId) {
        tokenId = encodeTokenId(certificateType, user);

        bool isExpired = expiry > 0 && expiry <= block.timestamp;
        uint256 priorBalance = balanceOf(user, tokenId);
        if (isExpired) revert IncorrectExpiry(user, certificateType, expiry);
        if (priorBalance > 0)
            revert IncorrectBalance(user, certificateType, priorBalance); // token already owned

        BitMaps.BitMap storage balances = _balances[user];
        BitMaps.set(balances, certificateType);
        _expiries[tokenId] = expiry;
        _certificateHash[tokenId] = certificateHash;
        _issuer[tokenId] = msg.sender;
        _receiver[tokenId] = user;
        _signedByReceiver[tokenId] = false;
        _approvers[tokenId] = signers;
        _totalApprover[tokenId] = signers.length;
        _totalSignature[tokenId] = 0;
        uint256 index;
        for(index = 0; index < _totalApprover[tokenId]; index++) {
            _signedByApprovers[tokenId].push(false);
        }
        _status[tokenId] = CertificateStatus.CREATED;

        uint96 nextPossibleNewCertificateType = uint96(maxCertificateType) + 1; // ensure new certificateTypes are one greater, pack bitmaps sequentially
        if (certificateType > nextPossibleNewCertificateType)
            revert NewCertificateTypeNotIncremental(certificateType, maxCertificateType);
        if (certificateType == nextPossibleNewCertificateType) maxCertificateType = certificateType;
    }

    /** 
     * @dev Internal shared function to revoke (burn) tokens and delete associated expiries
    */
    function _revoke(
        address user,
        uint96 certificateType
    ) internal returns (uint256 tokenId) {
        tokenId = encodeTokenId(certificateType, user);

        uint256 priorBalance = balanceOf(user, tokenId);
        if (priorBalance == 0)
            revert IncorrectBalance(user, certificateType, priorBalance); // token not owned

        BitMaps.BitMap storage balances = _balances[user];
        BitMaps.unset(balances, certificateType);
        delete _expiries[tokenId];
    }
    
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
    
    function _receiverSigning(uint256 tokenId, bytes memory signature) internal {
        require(_status[tokenId] == CertificateStatus.CREATED, 'invalid certificate status');
        require(_totalSignature[tokenId] == _totalApprover[tokenId], 'waiting for approver signature');
        require(!_signedByReceiver[tokenId], 'already signed by receiver');
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _certificateHash[tokenId]));
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        require(ecrecover(prefixedHash, v, r, s) == _receiver[tokenId], 'invalid receiver signature');
        
        _signedByReceiver[tokenId] = true;
        _status[tokenId] = CertificateStatus.ISSUED;
        emit SignedByReceiver(_receiver[tokenId], block.timestamp);
    }
    
    function _approverSigning(uint256 tokenId, bytes memory signature) internal {
        require(_status[tokenId] == CertificateStatus.CREATED, 'invalid certificate status');
        int approverIndex = -1;
        uint256 index;
        for (index = 0; index < _approvers[tokenId].length; index++) {
            if (_approvers[tokenId][index] == msg.sender) {
                approverIndex = int(index);
            }
        }
        require(approverIndex >= 0, 'approver not found');
        require(!_signedByApprovers[tokenId][uint256(approverIndex)], 'already signed');
        if (approverIndex > 0) {
            require(_signedByApprovers[tokenId][uint256(approverIndex - 1)], 'waiting for other approver');
        }
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _certificateHash[tokenId]));
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        require(ecrecover(prefixedHash, v, r, s) == _approvers[tokenId][uint256(approverIndex)], 'invalid approver signature');
        
        _signedByApprovers[tokenId][uint256(approverIndex)] = true;
        _totalSignature[tokenId] = _totalSignature[tokenId] + 1;
        emit SignedByApprover(_approvers[tokenId][uint256(approverIndex)], block.timestamp);
    }

    /** 
     * @dev Checks if an account address has an associated linked real wallet in WalletMapping. If so, returns it. Otherwise, returns original account address param value
    */
    function getUser(address account) internal view returns (address) {
        return IWalletMapping(walletMapping).getLinkedWallet(account);
    }

    /** 
     * @dev Internal function to emit transfer events for each owned certificate (used in transitioning tokens after wallet linking)
    */
    function emitTransferEvents(
        uint256 bitmap,
        address from,
        address to
    ) private {
        for (uint256 i = 0; i < BITMAP_SIZE; i++) {
            if (bitmap & (1 << i) > 0) {
                // token type is owned
                emit TransferSingle(
                    _msgSender(),
                    from,
                    to,
                    encodeTokenId(uint96(i), from),
                    1
                );
            }
        }
    }

    /** 
     * @dev ERC1155 receiver check to ensure a "to" address can receive the ERC1155 token standard, used in single mint
    */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            // check if contract
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
                    revert ERC1155ReceiverRejectedTokens();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155ReceiverNotImplemented();
            }
        }
    }

    /** 
     * @dev ERC1155 receiver check to ensure a "to" address can receive the ERC1155 token standard, used in batch mint
    */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            // check if contract
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert ERC1155ReceiverRejectedTokens();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155ReceiverNotImplemented();
            }
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

import "../IERC1155.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface IWalletMapping {
    error UserAlreadyLinked(address userAddress);
    error WalletAlreadyLinked(address walletAddress);
    error StringLongerThan31Bytes(string str);

    function linkWallet(address userAddress, address walletAddress) external;

    function getLinkedWallet(
        address userAddress
    ) external view returns (address);

    function getLiteWalletAddress(
        string memory firstName,
        string memory lastName,
        uint256 phoneNumber
    ) external pure returns (address liteWallet);

    function transitionCertificatesByContracts(
        address from,
        address to,
        address[] memory contracts
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface ICertificateSet {
    error IncorrectExpiry(address user, uint96 certificateType, uint256 expiry);
    error IncorrectBalance(address user, uint96 certificateType, uint256 balance);
    error NewCertificateTypeNotIncremental(uint96 certificateType, uint256 maxCertificateType);
    error ArrayParamsUnequalLength();
    error WalletNotLinked(address walletAddress);
    error SoulboundTokenNoSetApprovalForAll(address operator, bool approved);
    error SoulboundTokenNoIsApprovedForAll(address account, address operator);
    error SoulboundTokenNoSafeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes data
    );
    error SoulboundTokenNoSafeBatchTransferFrom(
        address from,
        address to,
        uint256[] ids,
        uint256[] amounts,
        bytes data
    );
    error ERC1155ReceiverNotImplemented();
    error ERC1155ReceiverRejectedTokens();

    event TransitionWallet(
        address indexed kycAddress,
        address indexed walletAddress
    );

    function setURI(string memory newuri) external;

    function setContractURI(string memory newuri) external;

    function expiryOf(uint256 tokenId) external view returns (uint256);

    function mint(
        address account,
        uint96 certificateType,
        uint256 expiryTimestamp,
        bytes32 certificateHash,
        address[] memory signers
    ) external returns (uint256 tokenId);

    function receiverSigning(
        uint256 tokenId, 
        bytes memory signature
    ) external;
    
    function approverSigning(
        uint256 tokenId, 
        bytes memory signature
    ) external;

    function mintBatch(
        address to,
        uint96[] memory certificateTypes,
        uint256[] memory expiryTimestamps,        
        bytes32[] memory certificateHash,
        address[][] memory signers
    ) external returns (uint256[] memory tokenIds);

    function revoke(
        address account,
        uint96 certificateType
    ) external returns (uint256 tokenId);

    function revokeBatch(
        address to,
        uint96[] memory certificateTypes
    ) external returns (uint256[] memory tokenIds);

    function moveUserTokensToWallet(
        address kycAddress,
        address walletAddress
    ) external;

    function encodeTokenId(
        uint96 certificateType,
        address account
    ) external pure returns (uint256 tokenId);

    function decodeTokenId(
        uint256 tokenId
    ) external pure returns (uint96 certificateType, address account);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.12;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(
        BitMap storage bitmap,
        uint256 index
    ) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
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