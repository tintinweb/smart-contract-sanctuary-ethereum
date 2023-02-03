// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC721Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";

import "./UUPSUpgradeable.sol";

import "./KeevoRoleUpgradeable.sol";

/**
 * @title KeevoMain contract
 * @author Keevo
 * @dev This contract is implementation of NON transferable ERC721 tokens
 * - Contract support:
 *   # Admin and Minter roles. See KeevoRoleUpgradeable.sol
 *     Admin is able to manage roles and contract uri
 *     Minter is able to mint tokens, (un)mark tokens as disabled and manage token uris
 *   # Mutable contract metadata in opensea format
 *     See https://docs.opensea.io/docs/contract-level-metadata
 *   # Mint non transferable tokens with mutable custom uri
 *   # Switch between custom and auto generated token uri
 *   # Mark or unmark token as disabled
 *   # Only one token per eth account allowed
 **/
contract KeevoMain is
    Initializable, ERC721Upgradeable, KeevoRoleUpgradeable, OwnableUpgradeable, UUPSUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenId;

    bytes32 constant KEEVO_BURN_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant KEEVO_BURN_TOKEN_APPROVAL_TYPEHASH = keccak256("BurnTokenApproval(address owner,uint256 lifetime)");
    bytes32 constant KEEVO_EIP712_BURN_DOMAIN_NAME_HASH = keccak256("Burn KVP token");
    bytes32 constant KEEVO_EIP712_BURN_DOMAIN_VERSION_HASH = keccak256("1.0.0");

    /**
     * @dev Structure of EIP712 message for burn KVP token.
     * Message be signed by customer and used as proof for token burning.
     * - owner is address of token owner. Message should be signed by this address
     * - lifetime is time when approval become invalid. In seconds since the epoch
     **/
    struct BurnTokenApproval{
        address owner;
        uint256 lifetime;
    }

    string private openseaContractUri;

    /**
     * @dev map tokenId to tokenInfo struct
     **/
    mapping(uint256 => tokenInfo) private tokensList;

    /**
     * @dev map Owner address to tokenIDs - for cheaper loops
     **/
    mapping(address => uint256) private clientTokens;

    /**
     * @dev additional storage space for change contract in future
     **/
    uint256[47] private _gap; 

    /**
     * @dev struct to hold extra token data
     **/
    struct tokenInfo {
        bool isDisabled;
        string uri;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _contractUri
    ) public virtual initializer onlyProxy() {
        __KeevoMain_init(_name, _symbol, _contractUri);
    }

    function __KeevoMain_init(
        string memory _name,
        string memory _symbol,
        string memory _contractUri
    ) public virtual initializer onlyProxy() {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Ownable_init_unchained();
        __ERC721_init_unchained(_name, _symbol);
        __KeevoRoleUpgradeable_init_unchained();

        __KeevoMain_init_unchained(_contractUri);
    }

    /**
     * @dev constructor function
     */
    function __KeevoMain_init_unchained(
        string memory _contractUri
    ) internal onlyInitializing {
        openseaContractUri = _contractUri;
        addAdmin(_msgSender());
        addMinter(_msgSender());
    }

    /**
     * @dev Allow upgrades only for OWNER accounts. See openzeppelin's {UUPSUpgradeable}
     */
    function _authorizeUpgrade(address newImplementation)
        internal override onlyOwner() {}


    /**
     * @dev Set URI for contract description.
     *  See https://docs.opensea.io/docs/contract-level-metadata
     * @param uri New URI
     */
    function setContractUri(string memory uri) public onlyAdmin() {
        openseaContractUri = uri;
    }

    /**
     * @dev See https://docs.opensea.io/docs/contract-level-metadata
     * @return String of the uri of contract level metadata
     */
    function contractURI() public view returns (string memory) {
        return openseaContractUri;
    }

    function safeMint(
        address _beneficiary,
        uint256 _id
    ) internal {
        _mint(_beneficiary, _id);
    }

    /**
     * @dev Mint a NFT to specified address and store data in tokenInfo struct onchain
     * @param _beneficiary address of future token owner
     * @param _uri uri of metadata stored in place differ from base uri
     * @return `tokenId` of minted NFT
     */
    function mint(
        address _beneficiary,
        string memory _uri
    ) external onlyMinter returns (uint256) {
        require(bytes(_uri).length != 0, "Hash and uri must not be empty");
        require(clientTokens[_beneficiary] == 0, "User already has token");
        _tokenId.increment();
        uint256 tokenId = _tokenId.current();
        safeMint(_beneficiary, tokenId);
        tokensList[tokenId] = tokenInfo(
            false,
            _uri
        );
        clientTokens[_beneficiary] = tokenId;
        return tokenId;
    }

    /**
     * @dev Override of _beforeTokenTransfer hook
     * restrict NFT transfer
     * allow:
     * - MINT if address from is 0
     * - BURN if address to is 0
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        require(
            (from == address(0) || to == address(0)),
            "Token is not transferable!"
        );
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev Function to (un)mark token as disabled
     * @param _id Token Id
     */
    function toggleTokenActive(uint256 _id) external onlyMinter {
        tokenInfo storage tokenItem = tokensList[_id];
        if (tokenItem.isDisabled == true) {
            tokenItem.isDisabled = false;
        } else {
            tokenItem.isDisabled = true;
        }
    }

    /**
     * @dev Function to change token metadata uri
     * @param id Token Id
     * @param newUri uri of metadata stored in place differ from base uri
     */
    function changeTokenMetadata(uint256 id, string memory newUri) external onlyMinter {
        require(id > 0 && id < _tokenId.current() + 1, "Token not minted!");
        require(bytes(newUri).length != 0);

        tokenInfo storage tokenItem = tokensList[id];
        tokenItem.uri = newUri;
    }

    /**
     * @dev Calculate EIP712 hash for BurnTokenApproval
     * @param approval is structure with owner address and approval lifetime 
     */
    function getBurnTokenApprovalHash(BurnTokenApproval memory approval) private view returns (bytes32 hash) {
        bytes32 eip712DomainHash = keccak256(abi.encode(
            KEEVO_BURN_DOMAIN_TYPEHASH,
            KEEVO_EIP712_BURN_DOMAIN_NAME_HASH,
            KEEVO_EIP712_BURN_DOMAIN_VERSION_HASH,
            block.chainid,
            address(this)
        ));

        bytes32 hashStruct =  keccak256(abi.encode(
            KEEVO_BURN_TOKEN_APPROVAL_TYPEHASH,
            approval.owner,
            approval.lifetime
        ));

        return keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
    }

    /**
     * @dev Collect deposit for contract owner
     * @param approval is structure with owner address and approval lifetime signed by owner
     * @param v is v part of owner signature
     * @param r is r part of owner signature
     * @param s is s part of owner signature
     */
    function burn(BurnTokenApproval memory approval, uint8 v, bytes32 r, bytes32 s)
        external
        onlyMinter
    {
        uint256 tokenId = clientTokens[approval.owner];
        require(tokenId != 0, "User has no token");
        require(block.timestamp <= approval.lifetime, "Offer expired");

        bytes32 hash = getBurnTokenApprovalHash(approval);

        address signer = ecrecover(hash, v, r, s);
        require(signer == approval.owner, "Signature incorrect");

        _burn(tokenId);
        clientTokens[approval.owner] = 0;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *  Generated URI format: baseUri + "/" + contract address + "/" + tokenId + "/meta"
     *  Contract address is 20 bytes lowcase hex string without prefix
     *  tokenId is 32 bytes lowcase hex string without prefix
     */
    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(id > 0 && id < _tokenId.current() + 1, "Token not minted!");
        require(tokensList[id].isDisabled == false, "Token was disabled");
        return tokensList[id].uri;
    }

    /**
     * @dev Returns last tokenID
     * @return `token ID`
     */
    function getLastTokenId() public view returns (uint256) {
        uint256 tokenCount = _tokenId.current();
        return tokenCount;
    }

   /**
     * @dev Returns token info that is onchain
     * @param _id tokenId
     * @return `tokenInfo` _token struct with NFT data
     */
    function getTokenInfo(uint256 _id)
        public
        view
        returns (tokenInfo memory)
    {
        require(_id > 0 && _id < _tokenId.current() + 1, "Token not minted!");
        return tokensList[_id];
    }

    /**
     * @dev Returns tokens info that is onchain per one user
     * @param _tokenOwner address of NFT owner
     * @return `tokenInfo` struct with NFT data
     */
    function getUserTokenInfo(address _tokenOwner)
        public
        view
        returns (tokenInfo memory)
    {
        require(_tokenOwner != address(0), "Only valid owners allowed");
        uint256 id = clientTokens[_tokenOwner];
        require(id != 0, "User doesn't have token");
        return tokensList[id];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public view virtual 
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}