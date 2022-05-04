// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Base64.sol";
import "@niftygateway/nifty-contracts/contracts/libraries/Json.sol";                                                          
import "@niftygateway/nifty-contracts/contracts/tokens/ERC721.sol";

contract OnchainERC721 is ERC721 {    
        
    string[] private imageData;

    constructor() {
        initializeERC721("Onchain ERC721", "ONCHAIN", "");
    }  

    function uploadImagePart(string calldata data) public {
        imageData.push(data);
    }     
    
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }            

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }              

    function mint(address to, uint256 tokenId) external {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");        

        balances[to] += 1;
        owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }        

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), ERROR_QUERY_FOR_NONEXISTENT_TOKEN);        

        bytes memory byteString = abi.encodePacked(Json.openJsonObject());
                  
        byteString = abi.encodePacked(byteString, Json.pushJsonPrimitiveStringAttribute("name", "Onchain ERC721", true));
        byteString = abi.encodePacked(byteString, Json.pushJsonPrimitiveStringAttribute("description", "This is a test", true));        
        byteString = abi.encodePacked(byteString, Json.pushJsonPrimitiveStringAttribute("external_url", "https://niftygateway.com", true));        
        byteString = abi.encodePacked(byteString, Json.pushJsonPrimitiveStringAttribute("background_color", "ffffff", true));        
        //byteString = abi.encodePacked(byteString, Json.pushJsonPrimitiveStringAttribute("image_data", "<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='1000' height='1000'><rect width='1000' height='1000' style='fill:rgb(0,0,255);stroke-width:3;stroke:rgb(0,0,0)'/></svg>", false));        

        bytes memory png;

        for (uint256 i = 0; i < imageData.length; i++) {
            png = abi.encodePacked(png, imageData[i]);
        }

        byteString = abi.encodePacked(byteString, Json.pushJsonPrimitiveStringAttribute("image_data", string(png), false));

        byteString = abi.encodePacked(byteString, Json.closeJsonObject());

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(byteString)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library Json {    

    function openJsonObject() internal pure returns (string memory) {        
        return string(abi.encodePacked("{"));
    }

    function closeJsonObject() internal pure returns (string memory) {
        return string(abi.encodePacked("}"));
    }

    function openJsonArray() internal pure returns (string memory) {        
        return string(abi.encodePacked("["));
    }

    function closeJsonArray() internal pure returns (string memory) {        
        return string(abi.encodePacked("]"));
    }

    function pushJsonPrimitiveStringAttribute(string memory name, string memory value, bool insertComma) internal pure returns (string memory) {
        return string(abi.encodePacked('"', name, '": "', value, '"', insertComma ? ',' : ''));
    }

    function pushJsonPrimitiveNonStringAttribute(string memory name, string memory value, bool insertComma) internal pure returns (string memory) {
        return string(abi.encodePacked('"', name, '": ', value, insertComma ? ',' : ''));
    }

    function pushJsonComplexAttribute(string memory name, string memory value, bool insertComma) internal pure returns (string memory) {
        return string(abi.encodePacked('"', name, '": ', value, insertComma ? ',' : ''));
    }

    function pushJsonArrayElement(string memory value, bool insertComma) internal pure returns (string memory) {
        return string(abi.encodePacked(value, insertComma ? ',' : ''));
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