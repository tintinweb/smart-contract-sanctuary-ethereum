// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "../structs/NiftyType.sol";
import "../utils/Signable.sol";
import "../utils/Withdrawable.sol";
import "../utils/Royalties.sol";

contract Thr33zi3sNG is ERC721, Royalties, Signable, Withdrawable {
    using Address for address;        

    address immutable defaultOwner;
    bool burnAndReplaceOpen;
    uint256 counter;
    uint256 extantSupply;

    constructor(address niftyRegistryContract_, address defaultOwner_) {
        initializeERC721("thr33zi3sNG", "333NG", "https://api.thr33zi3s.com/token/");
        initializeNiftyEntity(niftyRegistryContract_);
        defaultOwner = defaultOwner_;
        admin = msg.sender;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, Royalties, NiftyPermissions) returns (bool) {
        return          
        super.supportsInterface(interfaceId);
    }                                     

    function tokenURI(uint256 tokenId) public virtual view override returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function setBaseURI(string calldata uri) external {
        _requireOnlyValidSender();
        _setBaseURI(uri);        
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }    

    function burn(uint256 tokenId) public {
        _burn(tokenId);
        extantSupply -= 1;
    }

    function mint() public {
        _requireOnlyValidSender();
        uint256 tokenId = counter + 1001; //Start at 1001
        _mint(defaultOwner, tokenId);
        extantSupply += 1;
        counter += 1;
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), ERROR_TRANSFER_TO_ZERO_ADDRESS);
        require(!_exists(tokenId), ERROR_ALREADY_MINTED);
        require(extantSupply + 1 <= 100, "Exceeds Maximum Supply");
        balances[to] += 1;
        owners[tokenId] = to; 

        emit Transfer(address(0), to, tokenId);

    }

    function burnAndReplace(uint256 initialTokenId) public {
        require(burnAndReplaceOpen, "Burn Traits not yet available");
        burn(initialTokenId); // calls require(isApprovedOrOwner, ERROR_NOT_OWNER_NOR_APPROVED);
        uint256 newTokenId = counter + 1001;
        _mint(_msgSender(), newTokenId);
        require(_checkOnERC721Received(address(0), _msgSender(), newTokenId,""), ERROR_NOT_AN_ERC721_RECEIVER); //i.e. safe mint
        counter += 1;
        extantSupply += 1;
    }

    function toggleBurnWindow(bool active) public {
        _requireOnlyValidSender();
        burnAndReplaceOpen = active;
    }
    
    function totalSupply() public view returns (uint256) {
        return extantSupply;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC721Errors.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Receiver.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC721Cloneable.sol";
import "../libraries/Address.sol";
import "../libraries/Context.sol";
import "../libraries/Strings.sol";
import "../utils/ERC165.sol";
import "../utils/GenericErrors.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721 is Context, ERC165, ERC721Errors, GenericErrors, IERC721Metadata, IERC721Cloneable {
    using Address for address;
    using Strings for uint256;

    // Only allow ERC721 to be initialized once
    bool internal initializedERC721;

    // Token name
    string internal tokenName;

    // Token symbol
    string internal tokenSymbol;

    // Base URI For Offchain Metadata
    string internal baseMetadataURI; 

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) internal tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal operatorApprovals;    

    function initializeERC721(string memory name_, string memory symbol_, string memory baseURI_) public override {
        require(!initializedERC721, ERROR_REINITIALIZATION_NOT_PERMITTED);
        tokenName = name_;
        tokenSymbol = symbol_;
        _setBaseURI(baseURI_);
        initializedERC721 = true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Cloneable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */    
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), ERROR_QUERY_FOR_ZERO_ADDRESS);
        return balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = owners[tokenId];
        require(owner != address(0), ERROR_QUERY_FOR_NONEXISTENT_TOKEN);
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */    
    function name() public view virtual override returns (string memory) {
        return tokenName;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */    
    function symbol() public view virtual override returns (string memory) {
        return tokenSymbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */     
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), ERROR_QUERY_FOR_NONEXISTENT_TOKEN);

        string memory uriBase = baseURI();
        return bytes(uriBase).length > 0 ? string(abi.encodePacked(uriBase, tokenId.toString())) : "";
    }

    function baseURI() public view virtual returns (string memory) {
        return baseMetadataURI;
    }

    /**
     * @dev Internal function to set the base URI
     */
    function _setBaseURI(string memory uri) internal {
        baseMetadataURI = uri;        
    }

    /**
     * @dev See {IERC721-approve}.
     */    
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, ERROR_APPROVAL_TO_CURRENT_OWNER);

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), ERROR_NOT_OWNER_NOR_APPROVED);

        _approve(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */    
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), ERROR_QUERY_FOR_NONEXISTENT_TOKEN);
        return tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), ERROR_APPROVE_TO_CALLER);
        operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);        
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */    
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {        
        (address owner, bool isApprovedOrOwner) = _isApprovedOrOwner(_msgSender(), tokenId);
        require(isApprovedOrOwner, ERROR_NOT_OWNER_NOR_APPROVED);
        _transfer(owner, from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */    
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), ERROR_NOT_AN_ERC721_RECEIVER);
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
        return owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (address owner, bool isApprovedOrOwner) {
        owner = owners[tokenId];
        require(owner != address(0), ERROR_QUERY_FOR_NONEXISTENT_TOKEN);
        isApprovedOrOwner = (spender == owner || tokenApprovals[tokenId] == spender || isApprovedForAll(owner, spender));
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
        address owner = ownerOf(tokenId);
        bool isApprovedOrOwner = (_msgSender() == owner || tokenApprovals[tokenId] == _msgSender() || isApprovedForAll(owner, _msgSender()));
        require(isApprovedOrOwner, ERROR_NOT_OWNER_NOR_APPROVED);

        // Clear approvals        
        _clearApproval(owner, tokenId);

        balances[owner] -= 1;
        _clearOwnership(tokenId);

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
    function _transfer(address owner, address from, address to, uint256 tokenId) internal virtual {
        require(owner == from, ERROR_TRANSFER_FROM_INCORRECT_OWNER);
        require(to != address(0), ERROR_TRANSFER_TO_ZERO_ADDRESS);        

        // Clear approvals from the previous owner        
        _clearApproval(owner, tokenId);

        balances[from] -= 1;
        balances[to] += 1;
        _setOwnership(to, tokenId);
        
        emit Transfer(from, to, tokenId);        
    }

    /**
     * @dev Equivalent to approving address(0), but more gas efficient
     *
     * Emits a {Approval} event.
     */
    function _clearApproval(address owner, uint256 tokenId) internal virtual {
        delete tokenApprovals[tokenId];
        emit Approval(owner, address(0), tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address owner, address to, uint256 tokenId) internal virtual {
        tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }    

    function _clearOwnership(uint256 tokenId) internal virtual {
        delete owners[tokenId];
    }

    function _setOwnership(address to, uint256 tokenId) internal virtual {
        owners[tokenId] = to;
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
     *
     * @dev Slither identifies an issue with unused return value.
     * Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unused-return
     * This should be a non-issue.  It is the standard OpenZeppelin implementation which has been heavily used and audited.
     */     
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (to.isContract()) {            
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(ERROR_NOT_AN_ERC721_RECEIVER);
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

struct NiftyType {
    bool isMinted; // 1 bytes
    uint72 niftyType; // 9 bytes
    uint88 idFirst; // 11 bytes
    uint88 idLast; // 11 bytes
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./NiftyPermissions.sol";
import "../libraries/ECDSA.sol";
import "../structs/SignatureStatus.sol";

abstract contract Signable is NiftyPermissions {        

    event ContractSigned(address signer, bytes32 data, bytes signature);

    SignatureStatus public signatureStatus;
    bytes public signature;

    string internal constant ERROR_CONTRACT_ALREADY_SIGNED = "Contract already signed";
    string internal constant ERROR_CONTRACT_NOT_SALTED = "Contract not salted";
    string internal constant ERROR_INCORRECT_SECRET_SALT = "Incorrect secret salt";
    string internal constant ERROR_SALTED_HASH_SET_TO_ZERO = "Salted hash set to zero";
    string internal constant ERROR_SIGNER_SET_TO_ZERO = "Signer set to zero address";

    function setSigner(address signer_, bytes32 saltedHash_) external {
        _requireOnlyValidSender();

        require(signer_ != address(0), ERROR_SIGNER_SET_TO_ZERO);
        require(saltedHash_ != bytes32(0), ERROR_SALTED_HASH_SET_TO_ZERO);
        require(!signatureStatus.isVerified, ERROR_CONTRACT_ALREADY_SIGNED);
        
        signatureStatus.signer = signer_;
        signatureStatus.saltedHash = saltedHash_;
        signatureStatus.isSalted = true;
    }

    function sign(uint256 salt, bytes calldata signature_) external {
        require(!signatureStatus.isVerified, ERROR_CONTRACT_ALREADY_SIGNED);        
        require(signatureStatus.isSalted, ERROR_CONTRACT_NOT_SALTED);
        
        address expectedSigner = signatureStatus.signer;
        bytes32 expectedSaltedHash = signatureStatus.saltedHash;

        require(_msgSender() == expectedSigner, ERROR_INVALID_MSG_SENDER);
        require(keccak256(abi.encodePacked(salt)) == expectedSaltedHash, ERROR_INCORRECT_SECRET_SALT);
        require(ECDSA.recover(ECDSA.toEthSignedMessageHash(expectedSaltedHash), signature_) == expectedSigner, ERROR_UNEXPECTED_DATA_SIGNER);
        
        signature = signature_;        
        signatureStatus.isVerified = true;

        emit ContractSigned(expectedSigner, expectedSaltedHash, signature_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./RejectEther.sol";
import "./NiftyPermissions.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";

abstract contract Withdrawable is RejectEther, NiftyPermissions {

    /**
     * @dev Slither identifies an issue with sending ETH to an arbitrary destianation.
     * https://github.com/crytic/slither/wiki/Detector-Documentation#functions-that-send-ether-to-arbitrary-destinations
     * Recommended mitigation is to "Ensure that an arbitrary user cannot withdraw unauthorized funds."
     * This mitigation has been performed, as only the contract admin can call 'withdrawETH' and they should
     * verify the recipient should receive the ETH first.
     */
    function withdrawETH(address payable recipient, uint256 amount) external {
        _requireOnlyValidSender();
        require(amount > 0, ERROR_ZERO_ETH_TRANSFER);
        require(recipient != address(0), "Transfer to zero address");

        uint256 currentBalance = address(this).balance;
        require(amount <= currentBalance, ERROR_INSUFFICIENT_BALANCE);

        //slither-disable-next-line arbitrary-send        
        (bool success,) = recipient.call{value: amount}("");
        require(success, ERROR_WITHDRAW_UNSUCCESSFUL);
    }
        
    function withdrawERC20(address tokenContract, address recipient, uint256 amount) external {
        _requireOnlyValidSender();
        bool success = IERC20(tokenContract).transfer(recipient, amount);
        require(success, ERROR_WITHDRAW_UNSUCCESSFUL);
    }
    
    function withdrawERC721(address tokenContract, address recipient, uint256 tokenId) external {
        _requireOnlyValidSender();
        IERC721(tokenContract).safeTransferFrom(address(this), recipient, tokenId, "");
    }    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./NiftyPermissions.sol";
import "../libraries/Clones.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC2981.sol";
import "../structs/RoyaltyRecipient.sol";

abstract contract Royalties is NiftyPermissions, IERC2981 {

    event RoyaltyReceiverUpdated(address previousReceiver, address newReceiver);

    uint256 constant public BIPS_PERCENTAGE_TOTAL = 10000;

    RoyaltyRecipient internal royaltyRecipient;

    function supportsInterface(bytes4 interfaceId) public view virtual override(NiftyPermissions, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||            
            super.supportsInterface(interfaceId);
    }

    function getRoyaltySettings() public view returns (RoyaltyRecipient memory) {
        return royaltyRecipient;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) public virtual override view returns (address, uint256) {                        
        return royaltyRecipient.recipient == address(0) ? 
            (address(0), 0) :
            (royaltyRecipient.recipient, (salePrice * royaltyRecipient.bips) / BIPS_PERCENTAGE_TOTAL);
    }

    function initializeRoyalties(address payee, uint256 bips) external returns (RoyaltyRecipient memory) {
        _requireOnlyValidSender();
        require(bips <= BIPS_PERCENTAGE_TOTAL, ERROR_BIPS_OVER_100_PERCENT);
        address previousReceiver = royaltyRecipient.recipient;
        royaltyRecipient.recipient = payee;
        royaltyRecipient.bips = uint16(bips);
        emit RoyaltyReceiverUpdated(previousReceiver, royaltyRecipient.recipient);
        return royaltyRecipient;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract ERC721Errors {
    string internal constant ERROR_QUERY_FOR_ZERO_ADDRESS = "Query for zero address";
    string internal constant ERROR_QUERY_FOR_NONEXISTENT_TOKEN = "Token does not exist";
    string internal constant ERROR_APPROVAL_TO_CURRENT_OWNER = "Current owner approval";
    string internal constant ERROR_APPROVE_TO_CALLER = "Approve to caller";
    string internal constant ERROR_NOT_OWNER_NOR_APPROVED = "Not owner nor approved";
    string internal constant ERROR_NOT_AN_ERC721_RECEIVER = "Not an ERC721Receiver";
    string internal constant ERROR_TRANSFER_FROM_INCORRECT_OWNER = "Transfer from incorrect owner";
    string internal constant ERROR_TRANSFER_TO_ZERO_ADDRESS = "Transfer to zero address";    
    string internal constant ERROR_ALREADY_MINTED = "Token already minted";    
    string internal constant ERROR_NO_TOKENS_MINTED = "No tokens minted";    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";

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

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

import "./IERC721.sol";

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

pragma solidity 0.8.9;

import "./IERC721.sol";

interface IERC721Cloneable is IERC721 {
    function initializeERC721(string calldata name_, string calldata symbol_, string calldata baseURI_) external;    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

abstract contract GenericErrors {
    string internal constant ERROR_INPUT_ARRAY_EMPTY = "Input array empty";
    string internal constant ERROR_INPUT_ARRAY_SIZE_MISMATCH = "Input array size mismatch";
    string internal constant ERROR_INVALID_MSG_SENDER = "Invalid msg.sender";
    string internal constant ERROR_UNEXPECTED_DATA_SIGNER = "Unexpected data signer";
    string internal constant ERROR_INSUFFICIENT_BALANCE = "Insufficient balance";
    string internal constant ERROR_WITHDRAW_UNSUCCESSFUL = "Withdraw unsuccessful";
    string internal constant ERROR_CONTRACT_IS_FINALIZED = "Contract is finalized";
    string internal constant ERROR_CANNOT_CHANGE_DEFAULT_OWNER = "Cannot change default owner";
    string internal constant ERROR_UNCLONEABLE_REFERENCE_CONTRACT = "Uncloneable reference contract";
    string internal constant ERROR_BIPS_OVER_100_PERCENT = "Bips over 100%";
    string internal constant ERROR_NO_ROYALTY_RECEIVER = "No royalty receiver";
    string internal constant ERROR_REINITIALIZATION_NOT_PERMITTED = "Re-initialization not permitted";
    string internal constant ERROR_ZERO_ETH_TRANSFER = "Zero ETH Transfer";
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

import "./ERC165.sol";
import "./GenericErrors.sol";
import "../interfaces/INiftyEntityCloneable.sol";
import "../interfaces/INiftyRegistry.sol";
import "../libraries/Context.sol";

abstract contract NiftyPermissions is Context, ERC165, GenericErrors, INiftyEntityCloneable {    

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    // Only allow Nifty Entity to be initialized once
    bool internal initializedNiftyEntity;

    // If address(0), use enable Nifty Gateway permissions - otherwise, specifies the address with permissions
    address public admin;

    // To prevent a mistake, transferring admin rights will be a two step process
    // First, the current admin nominates a new admin
    // Second, the nominee accepts admin
    address public nominatedAdmin;

    // Nifty Registry Contract
    INiftyRegistry internal permissionsRegistry;    

    function initializeNiftyEntity(address niftyRegistryContract_) public {
        require(!initializedNiftyEntity, ERROR_REINITIALIZATION_NOT_PERMITTED);
        permissionsRegistry = INiftyRegistry(niftyRegistryContract_);
        initializedNiftyEntity = true;
    }       
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return         
        interfaceId == type(INiftyEntityCloneable).interfaceId ||
        super.supportsInterface(interfaceId);
    }        

    function renounceAdmin() external {
        _requireOnlyValidSender();
        _transferAdmin(address(0));
    }    

    function nominateAdmin(address nominee) external {
        _requireOnlyValidSender();
        nominatedAdmin = nominee;
    }

    function acceptAdmin() external {
        address nominee = nominatedAdmin;
        require(_msgSender() == nominee, ERROR_INVALID_MSG_SENDER);
        _transferAdmin(nominee);
    }
    
    function _requireOnlyValidSender() internal view {       
        address currentAdmin = admin;     
        if(currentAdmin == address(0)) {
            require(permissionsRegistry.isValidNiftySender(_msgSender()), ERROR_INVALID_MSG_SENDER);
        } else {
            require(_msgSender() == currentAdmin, ERROR_INVALID_MSG_SENDER);
        }
    }        

    function _transferAdmin(address newAdmin) internal {
        address oldAdmin = admin;
        admin = newAdmin;
        delete nominatedAdmin;        
        emit AdminTransferred(oldAdmin, newAdmin);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity 0.8.9;

import "./Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */    
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

struct SignatureStatus {
    bool isSalted;
    bool isVerified;
    address signer;
    bytes32 saltedHash;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";

interface INiftyEntityCloneable is IERC165 {
    function initializeNiftyEntity(address niftyRegistryContract_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface INiftyRegistry {
   function isValidNiftySender(address sendingKey) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title A base contract that may be inherited in order to protect a contract from having its fallback function 
 * invoked and to block the receipt of ETH by a contract.
 * @author Nathan Gang
 * @notice This contract bestows on inheritors the ability to block ETH transfers into the contract
 * @dev ETH may still be forced into the contract - it is impossible to block certain attacks, but this protects from accidental ETH deposits
 */
 // For more info, see: "https://medium.com/@alexsherbuck/two-ways-to-force-ether-into-a-contract-1543c1311c56"
abstract contract RejectEther {    

    /**
     * @dev For most contracts, it is safest to explicitly restrict the use of the fallback function
     * This would generally be invoked if sending ETH to this contract with a 'data' value provided
     */
    fallback() external payable {        
        revert("Fallback function not permitted");
    }

    /**
     * @dev This is the standard path where ETH would land if sending ETH to this contract without a 'data' value
     * In our case, we don't want our contract to receive ETH, so we restrict it here
     */
    receive() external payable {
        revert("Receiving ETH not permitted");
    }    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity 0.8.9;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

struct RoyaltyRecipient {
    bool isPaymentSplitter; // 1 byte
    uint16 bips; // 2 bytes
    address recipient; // 20 bytes
}