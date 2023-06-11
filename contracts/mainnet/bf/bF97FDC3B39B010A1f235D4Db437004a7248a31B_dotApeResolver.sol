/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// File: dotApe/implementations/namehash.sol


pragma solidity 0.8.7;

contract apeNamehash {
    function getNamehash(string memory _name) public pure returns (bytes32 namehash) {
        namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked('ape')))
        );
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
    }

    function getNamehashSubdomain(string memory _name, string memory _subdomain) public pure returns (bytes32 namehash) {
        namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked('ape')))
        );
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(_subdomain)))
        );
    }
}
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


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/interfaces/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File: dotApe/implementations/addressesImplementation.sol


pragma solidity ^0.8.7;

interface IApeAddreses {
    function owner() external view returns (address);
    function getDotApeAddress(string memory _label) external view returns (address);
}

pragma solidity ^0.8.7;

abstract contract apeAddressesImpl {
    address dotApeAddresses;

    constructor(address addresses_) {
        dotApeAddresses = addresses_;
    }

    function setAddressesImpl(address addresses_) public onlyOwner {
        dotApeAddresses = addresses_;
    }

    function owner() public view returns (address) {
        return IApeAddreses(dotApeAddresses).owner();
    }

    function getDotApeAddress(string memory _label) public view returns (address) {
        return IApeAddreses(dotApeAddresses).getDotApeAddress(_label);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyRegistrar() {
        require(msg.sender == getDotApeAddress("registrar"), "Ownable: caller is not the registrar");
        _;
    }

    modifier onlyErc721() {
        require(msg.sender == getDotApeAddress("erc721"), "Ownable: caller is not erc721");
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == getDotApeAddress("team"), "Ownable: caller is not team");
        _;
    }

}
// File: dotApe/implementations/registryImplementation.sol



pragma solidity ^0.8.7;


pragma solidity ^0.8.7;

interface IApeRegistry {
    function setRecord(bytes32 _hash, uint256 _tokenId, string memory _name, uint256 expiry_) external;
    function getTokenId(bytes32 _hash) external view returns (uint256);
    function getName(uint256 _tokenId) external view returns (string memory);
    function currentSupply() external view returns (uint256);
    function nextTokenId() external view returns (uint256);
    function addOwner(address address_) external;
    function changeOwner(address address_, uint256 tokenId_) external;
    function getOwner(uint256 tokenId) external view returns (address);
    function getExpiration(uint256 tokenId) external view returns (uint256);
    function changeExpiration(uint256 tokenId, uint256 expiration_) external;
    function setPrimaryName(address address_, uint256 tokenId) external;
    function getPrimaryName(address address_) external view returns (string memory);
    function getPrimaryNameTokenId(address address_) external view returns (uint256);
    function getTxtRecord(uint256 tokenId, string memory label) external view returns (string memory);
}

pragma solidity ^0.8.7;

abstract contract apeRegistryImpl is apeAddressesImpl {
    
    function setRecord(bytes32 _hash, uint256 _tokenId, string memory _name, uint256 expiry_) internal {
        IApeRegistry(getDotApeAddress("registry")).setRecord(_hash, _tokenId, _name, expiry_);
    }

    function getTokenId(bytes32 _hash) internal view returns (uint256) {
        return IApeRegistry(getDotApeAddress("registry")).getTokenId(_hash);
    }

    function getName(uint256 _tokenId) internal view returns (string memory) {
        return IApeRegistry(getDotApeAddress("registry")).getName(_tokenId);     
    }

    function nextTokenId() internal view returns (uint256) {
        return IApeRegistry(getDotApeAddress("registry")).nextTokenId();
    }

    function currentSupply() internal view returns (uint256) {
        return IApeRegistry(getDotApeAddress("registry")).currentSupply();
    }

    function addOwner(address address_) internal {
        IApeRegistry(getDotApeAddress("registry")).addOwner(address_);
    }

    function changeOwner(address address_, uint256 tokenId_) internal {
        IApeRegistry(getDotApeAddress("registry")).changeOwner(address_, tokenId_);
    }

    function getOwner(uint256 tokenId) internal view returns (address) {
        return IApeRegistry(getDotApeAddress("registry")).getOwner(tokenId);
    }

    function getExpiration(uint256 tokenId) internal view returns (uint256) {
        return IApeRegistry(getDotApeAddress("registry")).getExpiration(tokenId);
    }

    function changeExpiration(uint256 tokenId, uint256 expiration_) internal {
        return IApeRegistry(getDotApeAddress("registry")).changeExpiration(tokenId, expiration_);
    }

    function setPrimaryName(address address_, uint256 tokenId) internal {
        return IApeRegistry(getDotApeAddress("registry")).setPrimaryName(address_, tokenId);
    }

    function getPrimaryName(address address_) internal view returns (string memory) {
        return IApeRegistry(getDotApeAddress("registry")).getPrimaryName(address_);
    }

    function getPrimaryNameTokenId(address address_) internal view returns (uint256) {
        return IApeRegistry(getDotApeAddress("registry")).getPrimaryNameTokenId(address_);
    }

    function getTxtRecord(uint256 tokenId, string memory label) internal view returns (string memory) {
        return IApeRegistry(getDotApeAddress("registry")).getTxtRecord(tokenId, label);
    }
}
// File: dotApe/implementations/erc721Implementation.sol



pragma solidity ^0.8.7;




pragma solidity ^0.8.7;

interface apeIERC721 {
    function mint(address to) external;
    function transferExpired(address to, uint256 tokenId) external;
}

pragma solidity ^0.8.7;

abstract contract apeErc721Impl is apeAddressesImpl {
    
    function mint(address to) internal {
        apeIERC721(getDotApeAddress("erc721")).mint(to);
    }

    function transferExpired(address to, uint256 tokenId) internal {
        apeIERC721(getDotApeAddress("erc721")).transferExpired(to, tokenId);
    }

    function totalSupply() internal view returns (uint256) {
        return IERC721Enumerable(getDotApeAddress("erc721")).totalSupply();
    }

}
// File: dotApe/resolver.sol


pragma solidity ^0.8.7;





contract dotApeResolver is apeErc721Impl, apeRegistryImpl, apeNamehash {

    constructor(address _address) apeAddressesImpl(_address) {}
   

    function resolveAddress(address address_) public view returns (string memory) {
        return getPrimaryName(address_);   
    }

    function resolveAddressToTokenId(address address_) public view returns (uint256) {
        return getPrimaryNameTokenId(address_);
    }

    function resolveName(string memory name_) public view returns (address) {
        return getOwner(getTokenId(getNamehash(name_)));
    }

    function resolveNameToTokenId(string memory name_) public view returns (uint256) {
        return getTokenId(getNamehash(name_));
    }

    function resolveTokenId(uint256 token_) public view returns (string memory) {
        return string(abi.encodePacked(getName(token_), ".ape"));  
    }

    function resolveAddressBatch(address[] memory addresses) public view returns (string[] memory) {
        string[] memory outputs = new string[](addresses.length);
        
        for (uint256 i = 0; i < addresses.length; i++) {
            outputs[i] = getPrimaryName(addresses[i]);
        }
        
        return outputs;
    }

    function resolveAddressToTokenIdBatch(address[] memory addresses) public view returns (uint256[] memory) {
        uint256[] memory outputs = new uint256[](addresses.length);
        
        for (uint256 i = 0; i < addresses.length; i++) {
            outputs[i] = getPrimaryNameTokenId(addresses[i]);
        }
        
        return outputs;
    }

    function resolveNameBatch(string[] memory names) public view returns (address[] memory) {
        address[] memory outputs = new address[](names.length);
        
        for (uint256 i = 0; i < names.length; i++) {
            outputs[i] = getOwner(getTokenId(getNamehash(names[i])));
        }
        
        return outputs;
    }

    function resolveNameToTokenIdBatch(string[] memory names) public view returns (uint256[] memory) {
        uint256[] memory outputs = new uint256[](names.length);
        
        for (uint256 i = 0; i < names.length; i++) {
            outputs[i] = resolveNameToTokenId(names[i]);
        }
        
        return outputs;
    }

    function resolveTokenIdBatch(uint256[] memory tokenIds) public view returns (string[] memory) {
        string[] memory outputs = new string[](tokenIds.length);
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            outputs[i] = resolveTokenId(tokenIds[i]);
        }
        
        return outputs;
    }

    function getAllTokenIdsOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 totalTokens = totalSupply(); // Total number of tokens
        
        uint256[] memory tokenIds = new uint256[](totalTokens);
        uint256 tokenCount = 0;
        
        for (uint256 tokenId = 1; tokenId <= totalTokens; tokenId++) {
            address tokenOwner = getOwner(tokenId);
            if (tokenOwner == owner) {
                tokenIds[tokenCount] = tokenId;
                tokenCount++;
            }
        }
        
        // Resize the tokenIds array to the actual number of tokens owned by the owner
        assembly {
            mstore(tokenIds, tokenCount)
        }
        
        return tokenIds;
    }

    function getAllNamesOfOwner(address owner) public view returns (string[] memory) {
        uint256 totalTokens = totalSupply(); // Total number of tokens
        
        string[] memory names = new string[](totalTokens);
        uint256 nameCount = 0;
        
        for (uint256 tokenId = 1; tokenId <= totalTokens; tokenId++) {
            address tokenOwner = getOwner(tokenId);
            if (tokenOwner == owner) {
                string memory tokenName = resolveTokenId(tokenId); // Assuming there's a function to retrieve the name of a token given its ID
                names[nameCount] = tokenName;
                nameCount++;
            }
        }
        
        // Resize the names array to the actual number of names owned by the owner
        assembly {
            mstore(names, nameCount)
        }
        
        return names;
    }

    struct Token {
        uint256 tokenId;
        string name;
    }

    function getAllTokensOfOwner(address owner) public view returns (Token[] memory) {
        uint256 totalTokens = totalSupply(); // Total number of tokens
        
        Token[] memory tokens = new Token[](totalTokens);
        uint256 tokenCount = 0;
        
        for (uint256 tokenId = 1; tokenId <= totalTokens; tokenId++) {
            address tokenOwner = getOwner(tokenId);
            if (tokenOwner == owner) {
                string memory tokenName = resolveTokenId(tokenId);
                tokens[tokenCount] = Token(tokenId, tokenName);
                tokenCount++;
            }
        }
        
        // Resize the tokens array to the actual number of tokens owned by the owner
        assembly {
            mstore(tokens, tokenCount)
        }
        
        return tokens;
    }

    function getTxtRecords(uint256 tokenId, string[] memory labels) public view returns (string[] memory) {
        string[] memory output = new string[](labels.length);

        for(uint256 i=0; i<labels.length; i++) {
            output[i] = getTxtRecord(tokenId, labels[i]);
        }

        return output;
    }
}