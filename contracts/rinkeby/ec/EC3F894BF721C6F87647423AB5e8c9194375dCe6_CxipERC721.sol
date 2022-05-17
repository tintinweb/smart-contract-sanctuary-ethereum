// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

import "./external/OpenSea.sol";
import "./interface/IERC165.sol";
import "./interface/ICxipERC721.sol";
import "./interface/ICxipProvenance.sol";
import "./interface/ICxipRegistry.sol";
import "./interface/IPA1D.sol";
import "./library/Address.sol";
import "./library/Bytes.sol";
import "./library/Strings.sol";
import "./struct/CollectionData.sol";
import "./struct/TokenData.sol";
import "./struct/Verification.sol";

/**
 * @title CXIP ERC721
 * @author CXIP-Labs
 * @notice A smart contract for minting and managing ERC721 NFTs.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract CxipERC721 {
    /**
     * @dev Stores default collection data: name, symbol, and royalties.
     */
    CollectionData private _collectionData;

    /**
     * @dev Internal last minted token id, to allow for auto-increment.
     */
    uint256 private _currentTokenId;

    /**
     * @dev Array of all token ids in collection.
     */
    uint256[] private _allTokens;

    /**
     * @dev Map of token id to array index of _ownedTokens.
     */
    mapping(uint256 => uint256) private _ownedTokensIndex;

    /**
     * @dev Token id to wallet (owner) address map.
     */
    mapping(uint256 => address) private _tokenOwner;

    /**
     * @dev 1-to-1 map of token id that was assigned an approved operator address.
     */
    mapping(uint256 => address) private _tokenApprovals;

    /**
     * @dev Map of total tokens owner by a specific address.
     */
    mapping(address => uint256) private _ownedTokensCount;

    /**
     * @dev Map of array of token ids owned by a specific address.
     */
    mapping(address => uint256[]) private _ownedTokens;

    /**
     * @notice Map of full operator approval for a particular address.
     * @dev Usually utilised for supporting marketplace proxy wallets.
     */
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Token data mapped by token id.
     */
    mapping(uint256 => TokenData) private _tokenData;

    /**
     * @dev Address of admin user. Primarily used as an additional recover address.
     */
    address private _admin;

    /**
     * @dev Address of contract owner. This address can run all onlyOwner functions.
     */
    address private _owner;

    /**
     * @dev Simple tracker of all minted (not-burned) tokens.
     */
    uint256 private _totalTokens;

    /**
     * @notice Event emitted when an token is minted, transfered, or burned.
     * @dev If from is empty, it's a mint. If to is empty, it's a burn. Otherwise, it's a transfer.
     * @param from Address from where token is being transfered.
     * @param to Address to where token is being transfered.
     * @param tokenId Token id that is being minted, Transfered, or burned.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @notice Event emitted when an address delegates power, for a token, to another address.
     * @dev Emits event that informs of address approving a third-party operator for a particular token.
     * @param wallet Address of the wallet configuring a token operator.
     * @param operator Address of the third-party operator approved for interaction.
     * @param tokenId A specific token id that is being authorised to operator.
     */
    event Approval(address indexed wallet, address indexed operator, uint256 indexed tokenId);

    /**
     * @notice Event emitted when an address authorises an operator (third-party).
     * @dev Emits event that informs of address approving/denying a third-party operator.
     * @param wallet Address of the wallet configuring it's operator.
     * @param operator Address of the third-party operator that interacts on behalf of the wallet.
     * @param approved A boolean indicating whether approval was granted or revoked.
     */
    event ApprovalForAll(address indexed wallet, address indexed operator, bool approved);

    /**
     * @notice Constructor is empty and not utilised.
     * @dev To make exact CREATE2 deployment possible, constructor is left empty. We utilize the "init" function instead.
     */
    constructor() {}

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "CXIP: caller not an owner");
        _;
    }

    /**
     * @notice Receive is purposefully left blank to not have any out-of-gas errors.
     */
    receive() external payable {}

    /**
     * @notice Enables royaltiy functionality at the ERC721 level no other function matches the call.
     * @dev See implementation of _royaltiesFallback.
     */
    fallback() external {
        _royaltiesFallback();
    }

    /**
     * @notice Gets the URI of the NFT on Arweave.
     * @dev Concatenates 2 sections of the arweave URI.
     * @param tokenId Id of the token.
     * @return string The URI.
     */
    function arweaveURI(uint256 tokenId) external view returns (string memory) {
        return
            string(abi.encodePacked("https://arweave.cxip.dev/", _tokenData[tokenId].arweave, _tokenData[tokenId].arweave2));
    }

    /**
     * @notice Gets the URI of the NFT backup from CXIP.
     * @dev Concatenates to https://nft.cxip.dev/.
     * @return string The URI.
     */
    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked("https://nft.cxip.dev/", Strings.toHexString(address(this)), "/"));
    }

    /**
     * @notice Gets the creator's address.
     * @dev If the token Id doesn't exist it will return zero address.
     * @param tokenId Id of the token.
     * @return address Creator's address.
     */
    function creator(uint256 tokenId) external view returns (address) {
        return _tokenData[tokenId].creator;
    }

    /**
     * @notice Gets the HTTP URI of the token.
     * @dev Concatenates to the baseURI.
     * @return string The URI.
     */
    function httpURI(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked(baseURI(), "/", Strings.toHexString(tokenId)));
    }

    /**
     * @notice Gets the IPFS URI
     * @dev Concatenates to the IPFS domain.
     * @param tokenId Id of the token.
     * @return string The URI.
     */
    function ipfsURI(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked("https://ipfs.cxip.dev/", _tokenData[tokenId].ipfs, _tokenData[tokenId].ipfs2));
    }

    /**
     * @notice Gets the name of the collection.
     * @dev Uses two names to extend the max length of the collection name in bytes
     * @return string The collection name.
     */
    function name() external view returns (string memory) {
        return string(abi.encodePacked(Bytes.trim(_collectionData.name), Bytes.trim(_collectionData.name2)));
    }

    /**
     * @notice Gets the hash of the NFT data used to create it.
     * @dev Payload is used for verification.
     * @param tokenId The Id of the token.
     * @return bytes32 The hash.
     */
    function payloadHash(uint256 tokenId) external view returns (bytes32) {
        return _tokenData[tokenId].payloadHash;
    }

    /**
     * @notice Gets the signature of the signed NFT data used to create it.
     * @dev Used for signature verification.
     * @param tokenId The Id of the token.
     * @return Verification a struct containing v, r, s values of the signature.
     */
    function payloadSignature(uint256 tokenId) external view returns (Verification memory) {
        return _tokenData[tokenId].payloadSignature;
    }

    /**
     * @notice Gets the address of the creator.
     * @dev The creator signs a payload while creating the NFT.
     * @param tokenId The Id of the token.
     * @return address The creator.
     */
    function payloadSigner(uint256 tokenId) external view returns (address) {
        return _tokenData[tokenId].creator;
    }

    /**
     * @notice Shows the interfaces the contracts support
     * @dev Must add new 4 byte interface Ids here to acknowledge support
     * @param interfaceId ERC165 style 4 byte interfaceId.
     * @return bool True if supported.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        if (
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            // || interfaceId == 0x780e9d63 // ERC721Enumerable
            interfaceId == 0x5b5e139f || // ERC721Metadata
            interfaceId == 0x150b7a02 || // ERC721TokenReceiver
            interfaceId == 0xe8a3d485 || // contractURI()
            IPA1D(getRegistry().getPA1D()).supportsInterface(interfaceId)
        ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Gets the collection's symbol.
     * @dev Trims the symbol.
     * @return string The symbol.
     */
    function symbol() external view returns (string memory) {
        return string(Bytes.trim(_collectionData.symbol));
    }

    /**
     * @notice Get's the URI of the token.
     * @dev Defaults the the Arweave URI
     * @param tokenId The Id of the token.
     * @return string The URI.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return
            string(abi.encodePacked("https://arweave.cxip.dev/", _tokenData[tokenId].arweave, _tokenData[tokenId].arweave2));
    }

    /**
     * @notice Get list of tokens owned by wallet.
     * @param wallet The wallet address to get tokens for.
     * @return uint256[] Returns an array of token ids owned by wallet.
     */
    function tokensOfOwner(address wallet) external view returns (uint256[] memory) {
        return _ownedTokens[wallet];
    }

    /**
     * @notice Checks if a given hash matches a payload hash.
     * @dev Uses sha256 instead of keccak.
     * @param hash The hash to check.
     * @param payload The payload prehashed.
     * @return bool True if the hashes match.
     */
    function verifySHA256(bytes32 hash, bytes calldata payload) external pure returns (bool) {
        bytes32 thePayloadHash = sha256(payload);
        return hash == thePayloadHash;
    }

    /**
     * @notice Adds a new address to the token's approval list.
     * @dev Requires the sender to be in the approved addresses.
     * @param to The address to approve.
     * @param tokenId The affected token.
     */
    function approve(address to, uint256 tokenId) public {
        address tokenOwner = _tokenOwner[tokenId];
        if (to != tokenOwner && _isApproved(msg.sender, tokenId)) {
            _tokenApprovals[tokenId] = to;
            emit Approval(tokenOwner, to, tokenId);
        }
    }

    /**
     * @notice Burns the token.
     * @dev The sender must be the owner or approved.
     * @param tokenId The token to burn.
     */
    function burn(uint256 tokenId) public {
        require(_isApproved(msg.sender, tokenId), "CXIP: not approved sender");
        address wallet = _tokenOwner[tokenId];
        _clearApproval(tokenId);
        _tokenOwner[tokenId] = address(0);
        emit Transfer(wallet, address(0), tokenId);
        _removeTokenFromOwnerEnumeration(wallet, tokenId);
    }

    /**
     * @notice Initializes the collection.
     * @dev Special function to allow a one time initialisation on deployment. Also configures and deploys royalties.
     * @param newOwner The owner of the collection.
     * @param collectionData The collection data.
     */
    function init(address newOwner, CollectionData calldata collectionData) public {
        require(Address.isZero(_admin), "CXIP: already initialized");
        _admin = msg.sender;
        // temporary set to self, to pass rarible royalties logic trap
        _owner = address(this);
        _collectionData = collectionData;
        IPA1D(address(this)).init(0, payable(collectionData.royalties), collectionData.bps);
        // set to actual owner
        _owner = newOwner;
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     * @param from cannot be the zero address.
     * @param to cannot be the zero address.
     * @param tokenId token must exist and be owned by `from`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     * @param from cannot be the zero address.
     * @param to cannot be the zero address.
     * @param tokenId token must exist and be owned by `from`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable {
        require(_isApproved(msg.sender, tokenId), "CXIP: not approved sender");
        _transferFrom(from, to, tokenId);
        if (Address.isContract(to)) {
            require(
                IERC165(to).supportsInterface(0x01ffc9a7) &&
                    IERC165(to).supportsInterface(0x150b7a02) &&
                    ICxipERC721(to).onERC721Received(address(this), from, tokenId, data) == 0x150b7a02,
                "CXIP: onERC721Received fail"
            );
        }
    }

    /**
     * @notice Adds a new approved operator.
     * @dev Allows platforms to sell/transfer all your NFTs. Used with proxy contracts like OpenSea/Rarible.
     * @param to The address to approve.
     * @param approved Turn on or off approval status.
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "CXIP: can't approve self");
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
     * @dev WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * @param from  cannot be the zero address.
     * @param to cannot be the zero address.
     * @param tokenId token must be owned by `from`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        transferFrom(from, to, tokenId, "");
    }

    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
     * @dev WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * @dev Since it's not being used, the _data variable is commented out to avoid compiler warnings.
     * @param from  cannot be the zero address.
     * @param to cannot be the zero address.
     * @param tokenId token must be owned by `from`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory /*_data*/
    ) public payable {
        require(_isApproved(msg.sender, tokenId), "CXIP: not approved sender");
        _transferFrom(from, to, tokenId);
    }

    /**
     * @notice Mints and NFT.
     * @dev Includes event with the Arwave token URI.
     * @param id The new tokenId.
     * @param tokenData The token data for the NFT.
     * @return uint256 The new tokenId.
     */
    function cxipMint(uint256 id, TokenData calldata tokenData) public onlyOwner returns (uint256) {
        if (id == 0) {
            while (_exists(_currentTokenId)) {
                _currentTokenId += 1;
            }
            id = _currentTokenId;
        }
        _mint(tokenData.creator, id);
        _tokenData[id] = tokenData;
        return id;
    }

    /**
     * @notice Sets a name for the collection.
     * @dev The name is split in two for gas optimization.
     * @param newName First part of name.
     * @param newName2 Second part of name.
     */
    function setName(bytes32 newName, bytes32 newName2) public onlyOwner {
        _collectionData.name = newName;
        _collectionData.name2 = newName2;
    }

    /**
     * @notice Set a symbol for the collection.
     * @dev This is the ticker symbol for smart contract that shows up on EtherScan.
     * @param newSymbol The ticker symbol to set for smart contract.
     */
    function setSymbol(bytes32 newSymbol) public onlyOwner {
        _collectionData.symbol = newSymbol;
    }

    /**
     * @notice Get total number of tokens owned by wallet.
     * @dev Used to see total amount of tokens owned by a specific wallet.
     * @param wallet Address for which to get token balance.
     * @return uint256 Returns an integer, representing total amount of tokens held by address.
     */
    function balanceOf(address wallet) public view returns (uint256) {
        return _ownedTokensCount[wallet];
    }

    /**
     * @notice Get a base URI for the token.
     * @dev Concatenates with the CXIP domain name.
     * @return string the token URI.
     */
    function baseURI() public view returns (string memory) {
        return string(abi.encodePacked("https://cxip.dev/nft/", Strings.toHexString(address(this))));
    }

    /**
     * @notice Gets the approved address for the token.
     * @dev Single operator set for a specific token. Usually used for one-time very specific authorisations.
     * @param tokenId Token id to get approved operator for.
     * @return address Approved address for token.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @notice Checks if the address is approved.
     * @dev Includes references to OpenSea and Rarible marketplace proxies.
     * @param wallet Address of the wallet.
     * @param operator Address of the marketplace operator.
     * @return bool True if approved.
     */
    function isApprovedForAll(address wallet, address operator) public view returns (bool) {
        return _operatorApprovals[wallet][operator];
    }

    /**
     * @notice Check if the sender is the owner.
     * @dev The owner could also be the admin or identity contract of the owner.
     * @return bool True if owner.
     */
    function isOwner() public view returns (bool) {
        return (msg.sender == _owner || msg.sender == _admin);
    }

    /**
     * @notice Check if the address is the owner.
     * @dev The owner could also be the admin or identity contract of the owner.
     * @return bool True if owner.
     */
    function isOwner(address wallet) public view returns (bool) {
        return (wallet == _owner || wallet == _admin);
    }

    /**
     * @notice Gets the owner's address.
     * @dev _owner is first set in init.
     * @return address Of ower.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Checks who the owner of a token is.
     * @dev The token must exist.
     * @param tokenId The token to look up.
     * @return address Owner of the token.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address tokenOwner = _tokenOwner[tokenId];
        require(!Address.isZero(tokenOwner), "ERC721: token does not exist");
        return tokenOwner;
    }

    /**
     * @notice Get token by index instead of token id.
     * @dev Helpful for token enumeration where token id info is not yet available.
     * @param index Index of token in array.
     * @return uint256 Returns the token id of token located at that index.
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "CXIP: index out of bounds");
        return _allTokens[index];
    }

    /**
     * @notice Get token from wallet by index instead of token id.
     * @dev Helpful for wallet token enumeration where token id info is not yet available. Use in conjunction with balanceOf function.
     * @param wallet Specific address for which to get token for.
     * @param index Index of token in array.
     * @return uint256 Returns the token id of token located at that index in specified wallet.
     */
    function tokenOfOwnerByIndex(address wallet, uint256 index) public view returns (uint256) {
        require(index < balanceOf(wallet), "CXIP: index out of bounds");
        return _ownedTokens[wallet][index];
    }

    /**
     * @notice Total amount of tokens in the collection.
     * @dev Ignores burned tokens.
     * @return uint256 Returns the total number of active (not burned) tokens.
     */
    function totalSupply() public view returns (uint256) {
        return _totalTokens;
    }

    /**
     * @notice Empty function that is triggered by external contract on NFT transfer.
     * @dev We have this blank function in place to make sure that external contract sending in NFTs don't error out.
     * @dev Since it's not being used, the _operator variable is commented out to avoid compiler warnings.
     * @dev Since it's not being used, the _from variable is commented out to avoid compiler warnings.
     * @dev Since it's not being used, the _tokenId variable is commented out to avoid compiler warnings.
     * @dev Since it's not being used, the _data variable is commented out to avoid compiler warnings.
     * @return bytes4 Returns the interfaceId of onERC721Received.
     */
    function onERC721Received(
        address, /*_operator*/
        address, /*_from*/
        uint256, /*_tokenId*/
        bytes calldata /*_data*/
    ) public pure returns (bytes4) {
        return 0x150b7a02;
    }

    /**
     * @notice Allows retrieval of royalties from the contract.
     * @dev This is a default fallback to ensure the royalties are available.
     */
    function _royaltiesFallback() internal {
        address _target = getRegistry().getPA1D();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Get the top-level CXIP Registry smart contract. Function must always be internal to prevent miss-use/abuse through bad programming practices.
     * @return ICxipRegistry The address of the top-level CXIP Registry smart contract.
     */
    function getRegistry() internal pure returns (ICxipRegistry) {
        return ICxipRegistry(0x5FbDB2315678afecb367f032d93F642f64180aa3);
    }

    /**
     * @dev Add a newly minted token into managed list of tokens.
     * @param to Address of token owner for which to add the token.
     * @param tokenId Id of token to add.
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokensCount[to];
        _ownedTokensCount[to]++;
        _ownedTokens[to].push(tokenId);
    }

    /**
     * @notice Deletes a token from the approval list.
     * @dev Removes from count.
     * @param tokenId T.
     */
    function _clearApproval(uint256 tokenId) private {
        delete _tokenApprovals[tokenId];
    }

    /**
     * @notice Mints an NFT.
     * @dev Can to mint the token to the zero address and the token cannot already exist.
     * @param to Address to mint to.
     * @param tokenId The new token.
     */
    function _mint(address to, uint256 tokenId) private {
        if (Address.isZero(to) || _exists(tokenId)) {
            assert(false);
        }
        _tokenOwner[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
        _totalTokens += 1;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Remove a token from managed list of tokens.
     * @param from Address of token owner for which to remove the token.
     * @param tokenId Id of token to remove.
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        _ownedTokensCount[from]--;
        uint256 lastTokenIndex = _ownedTokensCount[from];
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        if (lastTokenIndex == 0) {
            delete _ownedTokens[from];
        } else {
            delete _ownedTokens[from][lastTokenIndex];
        }
    }

    /**
     * @dev Primary internal function that handles the transfer/mint/burn functionality.
     * @param from Address from where token is being transferred. Zero address means it is being minted.
     * @param to Address to whom the token is being transferred. Zero address means it is being burned.
     * @param tokenId Id of token that is being transferred/minted/burned.
     */
    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) private {
        if (_tokenOwner[tokenId] == from && !Address.isZero(to)) {
            _clearApproval(tokenId);
            _tokenOwner[tokenId] = to;
            emit Transfer(from, to, tokenId);
            _removeTokenFromOwnerEnumeration(from, tokenId);
            _addTokenToOwnerEnumeration(to, tokenId);
        } else {
            assert(false);
        }
    }

    /**
     * @notice Checks if the token owner exists.
     * @dev If the address is the zero address no owner exists.
     * @param tokenId The affected token.
     * @return bool True if it exists.
     */
    function _exists(uint256 tokenId) private view returns (bool) {
        address tokenOwner = _tokenOwner[tokenId];
        return !Address.isZero(tokenOwner);
    }

    /**
     * @notice Checks if the address is an approved one.
     * @dev Uses inlined checks for different usecases of approval.
     * @param spender Address of the spender.
     * @param tokenId The affected token.
     * @return bool True if approved.
     */
    function _isApproved(address spender, uint256 tokenId) private view returns (bool) {
        require(_exists(tokenId));
        address tokenOwner = _tokenOwner[tokenId];
        return (spender == tokenOwner || getApproved(tokenId) == spender || isApprovedForAll(tokenOwner, spender));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

contract OpenSeaOwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OpenSeaOwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

import "../struct/CollectionData.sol";
import "../struct/TokenData.sol";
import "../struct/Verification.sol";

interface ICxipERC721 {
    function arweaveURI(uint256 tokenId) external view returns (string memory);

    function contractURI() external view returns (string memory);

    function creator(uint256 tokenId) external view returns (address);

    function httpURI(uint256 tokenId) external view returns (string memory);

    function ipfsURI(uint256 tokenId) external view returns (string memory);

    function name() external view returns (string memory);

    function payloadHash(uint256 tokenId) external view returns (bytes32);

    function payloadSignature(uint256 tokenId) external view returns (Verification memory);

    function payloadSigner(uint256 tokenId) external view returns (address);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function tokensOfOwner(address wallet) external view returns (uint256[] memory);

    function verifySHA256(bytes32 hash, bytes calldata payload) external pure returns (bool);

    function approve(address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function init(address newOwner, CollectionData calldata collectionData) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external payable;

    function setApprovalForAll(address to, bool approved) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external payable;

    function cxipMint(uint256 id, TokenData calldata tokenData) external returns (uint256);

    function setApprovalForAll(
        address from,
        address to,
        bool approved
    ) external;

    function setName(bytes32 newName, bytes32 newName2) external;

    function setSymbol(bytes32 newSymbol) external;

    function transferOwnership(address newOwner) external;

    function balanceOf(address wallet) external view returns (uint256);

    function baseURI() external view returns (string memory);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address wallet, address operator) external view returns (bool);

    function isOwner() external view returns (bool);

    function isOwner(address wallet) external view returns (bool);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address wallet, uint256 index) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

import "../struct/CollectionData.sol";
import "../struct/InterfaceType.sol";
import "../struct/Token.sol";
import "../struct/TokenData.sol";

interface ICxipProvenance {
    function createERC721Token(
        address collection,
        uint256 id,
        TokenData calldata tokenData,
        Verification calldata verification
    ) external returns (uint256);

    function createERC721Collection(
        bytes32 saltHash,
        address collectionCreator,
        Verification calldata verification,
        CollectionData calldata collectionData
    ) external returns (address);

    function createCustomERC721Collection(
        bytes32 saltHash,
        address collectionCreator,
        Verification calldata verification,
        CollectionData calldata collectionData,
        bytes32 slot,
        bytes memory bytecode
    ) external returns (address);

    function getCollectionById(uint256 index) external view returns (address);

    function getCollectionType(address collection) external view returns (InterfaceType);

    function isCollectionCertified(address collection) external view returns (bool);

    function isCollectionRegistered(address collection) external view returns (bool);

    function isTokenCertified(address collection, uint256 tokenId) external view returns (bool);

    function isTokenRegistered(address collection, uint256 tokenId) external view returns (bool);

    function listCollections(uint256 offset, uint256 length)
        external
        view
        returns (address[] memory);

    function totalCollections() external view returns (uint256);

    function isCollectionOpen(address collection) external pure returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

interface ICxipRegistry {
    function getCustomSource(bytes32 name) external view returns (address);

    function getCustomSourceFromString(string memory name) external view returns (address);

    function getERC1155CollectionSource() external view returns (address);

    function getERC721CollectionSource() external view returns (address);

    function getPA1D() external view returns (address);

    function getPA1DSource() external view returns (address);

    function getProvenance() external view returns (address);

    function getProvenanceSource() external view returns (address);

    function owner() external view returns (address);

    function setCustomSource(string memory name, address source) external;

    function setERC1155CollectionSource(address source) external;

    function setERC721CollectionSource(address source) external;

    function setPA1D(address proxy) external;

    function setPA1DSource(address source) external;

    function setProvenance(address proxy) external;

    function setProvenanceSource(address source) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

import "../library/Zora.sol";

interface IPA1D {
    function init(
        uint256 tokenId,
        address payable receiver,
        uint256 bp
    ) external;

    function configurePayouts(address payable[] memory addresses, uint256[] memory bps) external;

    function getPayoutInfo()
        external
        view
        returns (address payable[] memory addresses, uint256[] memory bps);

    function getEthPayout() external;

    function getTokenPayout(address tokenAddress) external;

    function getTokenPayoutByName(string memory tokenName) external;

    function getTokensPayout(address[] memory tokenAddresses) external;

    function getTokensPayoutByName(string[] memory tokenNames) external;

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    function setRoyalties(
        uint256 tokenId,
        address payable receiver,
        uint256 bp
    ) external;

    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);

    function getFeeBps(uint256 tokenId) external view returns (uint256[] memory);

    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);

    function getRoyalties(uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);

    function getFees(uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);

    function tokenCreator(address contractAddress, uint256 tokenId) external view returns (address);

    function calculateRoyaltyFee(
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) external view returns (uint256);

    function marketContract() external view returns (address);

    function tokenCreators(uint256 tokenId) external view returns (address);

    function bidSharesForToken(uint256 tokenId)
        external
        view
        returns (Zora.BidShares memory bidShares);

    function getStorageSlot(string calldata slot) external pure returns (bytes32);

    function getTokenAddress(string memory tokenName) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 &&
            codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }

    function isZero(address account) internal pure returns (bool) {
        return (account == address(0));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

library Bytes {
    function getBoolean(uint192 _packedBools, uint192 _boolNumber) internal pure returns (bool) {
        uint192 flag = (_packedBools >> _boolNumber) & uint192(1);
        return (flag == 1 ? true : false);
    }

    function setBoolean(
        uint192 _packedBools,
        uint192 _boolNumber,
        bool _value
    ) internal pure returns (uint192) {
        if (_value) {
            return _packedBools | (uint192(1) << _boolNumber);
        } else {
            return _packedBools & ~(uint192(1) << _boolNumber);
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");
        bytes memory tempBytes;
        assembly {
            switch iszero(_length)
            case 0 {
                tempBytes := mload(0x40)
                let lengthmod := and(_length, 31)
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)
                for {
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }
                mstore(tempBytes, _length)
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)
                mstore(0x40, add(tempBytes, 0x20))
            }
        }
        return tempBytes;
    }

    function trim(bytes32 source) internal pure returns (bytes memory) {
        uint256 temp = uint256(source);
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return slice(abi.encodePacked(source), 32 - length, length);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

library Strings {
    function toHexString(address account) internal pure returns (string memory) {
        return toHexString(uint256(uint160(account)));
    }

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

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = bytes16("0123456789abcdef")[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

import "./UriType.sol";

struct CollectionData {
    bytes32 name;
    bytes32 name2;
    bytes32 symbol;
    address royalties;
    uint96 bps;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

import "./Verification.sol";

struct TokenData {
    bytes32 payloadHash;
    Verification payloadSignature;
    address creator;
    bytes32 arweave;
    bytes11 arweave2;
    bytes32 ipfs;
    bytes14 ipfs2;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

struct Verification {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

// This is a 256 value limit (uint8)
enum UriType {
    ARWEAVE, // 0
    IPFS, // 1
    HTTP // 2
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

// This is a 256 value limit (uint8)
enum InterfaceType {
    NULL, // 0
    ERC20, // 1
    ERC721, // 2
    ERC1155 // 3
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

import "./InterfaceType.sol";

struct Token {
    address collection;
    uint256 tokenId;
    InterfaceType tokenType;
    address creator;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

library Zora {
    struct Decimal {
        uint256 value;
    }

    struct BidShares {
        // % of sale value that goes to the _previous_ owner of the nft
        Decimal prevOwner;
        // % of sale value that goes to the original creator of the nft
        Decimal creator;
        // % of sale value that goes to the seller (current owner) of the nft
        Decimal owner;
    }
}