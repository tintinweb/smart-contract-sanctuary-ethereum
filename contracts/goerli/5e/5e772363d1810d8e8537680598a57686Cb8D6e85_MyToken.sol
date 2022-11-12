// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Address.sol";
import "./Strings.sol";
import "./AccessControl.sol";
import "./Initializable.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";
import "./Base64.sol";
import "./ERC1155Supply.sol";


contract MyToken is ERC1155,ERC2981, AccessControl, Initializable,ERC1155Supply {

    using Address for address payable;
    using Strings for uint256;

     /// Fixed at deployment time
    struct DeploymentConfig {
        // Name of the NFT contract.
        string name;
        // Symbol of the NFT contract.
        string symbol;
        // The contract owner address. If you wish to own the contract, then set it as your wallet address.
        // This is also the wallet that can manage the contract on NFT marketplaces. Use `transferOwnership()`
        // to update the contract owner.
        address owner;
        // The maximum number of tokens that can be minted in this collection.
        uint256 maxSupply;
        // The number of free token mints reserved for the contract owner
        uint256 reservedSupply;
        /// The maximum number of tokens the user can mint per transaction.
        uint256 tokensPerMint;
        /// Tokens per person
        uint256 tokenPerPerson;
        // Treasury address is the address where minting fees can be withdrawn to.
        // Use `withdrawFees()` to transfer the entire contract balance to the treasury address.
        address payable treasuryAddress;
    }

    /// Updatable by admins and owner
    struct RuntimeConfig {
        // Metadata base URI for tokens, NFTs minted in this contract will have metadata URI of `baseURI` + `tokenID`.
        // Set this to reveal token metadata.
        string baseURI;
        // If true, the base URI of the NFTs minted in the specified contract can be updated after minting (token URIs
        // are not frozen on the contract level). This is useful for revealing NFTs after the drop. If false, all the
        // NFTs minted in this contract are frozen by default which means token URIs are non-updatable.
        bool metadataUpdatable;
        // Minting price per token for public minting
        uint256 publicMintPrice;
        // Flag for freezing the public mint price
        bool publicMintPriceFrozen;
        // Minting price per token for presale minting
        uint256 presaleMintPrice;
        // Flag for freezing the presale mint price
        bool presaleMintPriceFrozen;
        // Starting timestamp for public minting.
        uint256 publicMintStart;
        // Starting timestamp for whitelisted/presale minting.
        uint256 presaleMintStart;
        // Pre-reveal token URI for placholder metadata. This will be returned for all token IDs until a `baseURI`
        // has been set.
        string prerevealTokenURI;
        // Root of the Merkle tree of whitelisted addresses. This is used to check if a wallet has been whitelisted
        // for presale minting.
        bytes32 presaleMerkleRoot;
        // Secondary market royalties in basis points (100 bps = 1%)
        uint256 royaltiesBps;
        // Address for royalties
        address royaltiesAddress;
    }

    struct ContractInfo {
        uint256 version;
        DeploymentConfig deploymentConfig;
        RuntimeConfig runtimeConfig;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /*************
     * Constants *
     *************/

    /// Contract version, semver-style uint X_YY_ZZ
    uint256 public constant VERSION = 1_03_00;

    /// Admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Basis for calculating royalties.
    // This has to be 10k for royaltiesBps to be in basis points.
    uint16 public constant ROYALTIES_BASIS = 10000;

    /// The number of tokens remaining in the reserve
    /// @dev Managed by the contract
    uint256 public reserveRemaining;

    uint256 public currentSupply;

    mapping(address=>uint256)public userTokensNFTPublicSale;

    constructor() ERC1155("") {
        _preventInitialization = false;
    }

    /// Contract initializer
    function initialize(
        DeploymentConfig memory deploymentConfig,
        RuntimeConfig memory runtimeConfig
    ) public initializer {
        require(!_preventInitialization, "Cannot be initialized");
        _validateDeploymentConfig(deploymentConfig);

        _grantRole(ADMIN_ROLE, msg.sender);
        _transferOwnership(deploymentConfig.owner);

        _deploymentConfig = deploymentConfig;
        _runtimeConfig = runtimeConfig;

        reserveRemaining = deploymentConfig.reservedSupply;
        _preventInitialization = true;
    }

        /****************
     * User actions *
     ****************/

    /// Mint tokens
    function mint(uint256 amount,uint256 id, bytes memory data)
        external
        payable
        paymentProvided(amount * _runtimeConfig.publicMintPrice)
    {
        require(mintingActive(), "Minting has not started yet");
        require(userTokensNFTPublicSale[msg.sender] + amount <= _deploymentConfig.tokenPerPerson, "You can't buy more tokens");
        userTokensNFTPublicSale[msg.sender] += amount;
        _mintTokens(msg.sender, id, amount, data);
    }

    /// Mint tokens if the wallet has been whitelisted
    function presaleMint(uint256 amount, uint256 id, bytes32[] calldata proof)
        external
        payable
        paymentProvided(amount * _runtimeConfig.presaleMintPrice)
    {
        require(presaleActive(), "Presale has not started yet");
        require(
            isWhitelisted(msg.sender, proof),
            "Not whitelisted for presale"
        );

        _presaleMinted[msg.sender] = true;
        _mintTokens(msg.sender, id, amount, "");
    }



    /******************
     * View functions *
     ******************/

    /// Check if public minting is active
    function mintingActive() public view returns (bool) {
        // We need to rely on block.timestamp since it's
        // asier to configure across different chains
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _runtimeConfig.publicMintStart;
    }

    /// Check if presale minting is active
    function presaleActive() public view returns (bool) {
        // We need to rely on block.timestamp since it's
        // easier to configure across different chains
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _runtimeConfig.presaleMintStart;
    }

    /// Get the number of tokens still available for minting
    function availableSupply() public view returns (uint256) {
        return _deploymentConfig.maxSupply - reserveRemaining;
    }

    /// Check if the wallet is whitelisted for the presale
    function isWhitelisted(address wallet, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        require(!_presaleMinted[wallet], "Already minted");

        bytes32 leaf = keccak256(abi.encodePacked(wallet));

        return
            MerkleProof.verify(proof, _runtimeConfig.presaleMerkleRoot, leaf);
    }

     /*******************
     * Access controls *
     *******************/

    /// Transfer contract ownership
    function transferOwnership(address newOwner)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newOwner != _deploymentConfig.owner, "Already the owner");
        _transferOwnership(newOwner);
    }

    /// Transfer contract ownership
    function transferAdminRights(address to) external onlyRole(ADMIN_ROLE) {
        require(!hasRole(ADMIN_ROLE, to), "Already an admin");
        require(msg.sender != _deploymentConfig.owner, "Use transferOwnership");

        _revokeRole(ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, to);
    }

    /*****************
     * Admin actions *
    *****************/

    /// Mint a token from the reserve
    function reserveMint(address to, uint256 amount, uint256 id)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(amount <= reserveRemaining, "Not enough reserved");
        reserveRemaining -= amount;
        _mintTokens(to, id ,amount, "");
    }

    /// Get full contract information
    /// @dev Convenience helper
    function getInfo() external view returns (ContractInfo memory info) {
        info.version = VERSION;
        info.deploymentConfig = _deploymentConfig;
        info.runtimeConfig = _runtimeConfig;
    }

    /// Update contract configuration
    /// @dev Callable by admin roles only
    function updateConfig(RuntimeConfig calldata newConfig)
        external
        onlyRole(ADMIN_ROLE)
    {
        _validateRuntimeConfig(newConfig);
        _runtimeConfig = newConfig;
    }

    /// Withdraw minting fees to the treasury address
    /// @dev Callable by admin roles only
    function withdrawFees() external onlyRole(ADMIN_ROLE) {
        _deploymentConfig.treasuryAddress.sendValue(address(this).balance);
    }

     /// Contract configuration
    RuntimeConfig internal _runtimeConfig;
    DeploymentConfig internal _deploymentConfig;

    /// Flag for disabling initalization for template contracts
    bool internal _preventInitialization;

    /// Mapping for tracking presale mint status
    mapping(address => bool) internal _presaleMinted;

    /// @dev Internal function for performing token mints
    function _mintTokens(address to, uint256 id, uint256 amount, bytes memory data) internal {
        require(amount <= _deploymentConfig.tokensPerMint, "Amount too large");       
        require(currentSupply + amount <= availableSupply(),"exceeds max supply");
        currentSupply = currentSupply + amount;
        _mint(to, id, amount, data);
    }
    
    /// Validate deployment config
    function _validateDeploymentConfig(DeploymentConfig memory config)
        internal
        pure
    {
        require(config.maxSupply > 0, "Maximum supply must be non-zero");
        require(config.tokensPerMint > 0, "Tokens per mint must be non-zero");
        require(
            config.treasuryAddress != address(0),
            "Treasury address cannot be null"
        );
        require(config.owner != address(0), "Contract must have an owner");
        require(
            config.reservedSupply <= config.maxSupply,
            "Reserve greater than supply"
        );
    }

    /// Validate a runtime configuration change
    function _validateRuntimeConfig(RuntimeConfig calldata config)
        internal
        view
    {
        // Can't set royalties to more than 100%
        require(config.royaltiesBps <= ROYALTIES_BASIS, "Royalties too high");

        // Validate mint price changes
        _validatePublicMintPrice(config);
        _validatePresaleMintPrice(config);

        // Validate metadata changes
        _validateMetadata(config);
    }

    function _validatePublicMintPrice(RuntimeConfig calldata config)
        internal
        view
    {
        // As long as public mint price is not frozen, all changes are valid
        if (!_runtimeConfig.publicMintPriceFrozen) return;

        // Can't change public mint price once frozen
        require(
            _runtimeConfig.publicMintPrice == config.publicMintPrice,
            "publicMintPrice is frozen"
        );

        // Can't unfreeze public mint price
        require(
            config.publicMintPriceFrozen,
            "publicMintPriceFrozen is frozen"
        );
    }

    function _validatePresaleMintPrice(RuntimeConfig calldata config)
        internal
        view
    {
        // As long as presale mint price is not frozen, all changes are valid
        if (!_runtimeConfig.presaleMintPriceFrozen) return;

        // Can't change presale mint price once frozen
        require(
            _runtimeConfig.presaleMintPrice == config.presaleMintPrice,
            "presaleMintPrice is frozen"
        );

        // Can't unfreeze presale mint price
        require(
            config.presaleMintPriceFrozen,
            "presaleMintPriceFrozen is frozen"
        );
    }

    function _validateMetadata(RuntimeConfig calldata config) internal view {
        // If metadata is updatable, we don't have any other limitations
        if (_runtimeConfig.metadataUpdatable) return;

        // If it isn't, we can't allow the flag to change anymore
        require(!config.metadataUpdatable, "Cannot unfreeze metadata");

        // We also can't allow base URI to change
        require(
            keccak256(abi.encodePacked(_runtimeConfig.baseURI)) ==
                keccak256(abi.encodePacked(config.baseURI)),
            "Metadata is frozen"
        );
    }

    /// Internal function without any checks for performing the ownership transfer
    function _transferOwnership(address newOwner) internal {
        address previousOwner = _deploymentConfig.owner;
        _revokeRole(ADMIN_ROLE, previousOwner);
        _revokeRole(DEFAULT_ADMIN_ROLE, previousOwner);

        _deploymentConfig.owner = newOwner;
        _grantRole(ADMIN_ROLE, newOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl, ERC2981)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _deploymentConfig.maxSupply;
    }

    /// Get the token metadata URI
    function uri(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        return
            bytes(_runtimeConfig.baseURI).length > 0
                ? string(
                    abi.encodePacked(_runtimeConfig.baseURI, tokenId.toString())
                )
                : _runtimeConfig.prerevealTokenURI;
    }


    /// @dev Need name() to support setting it in the initializer instead of constructor
    function name() public view  returns (string memory) {
        return _deploymentConfig.name;
    }

    /// @dev Need symbol() to support setting it in the initializer instead of constructor
    function symbol() public view  returns (string memory) {
        return _deploymentConfig.symbol;
    }

    /// @dev ERC2981 token royalty info
    function royaltyInfo(uint256, uint256 salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _runtimeConfig.royaltiesAddress;
        royaltyAmount =
            (_runtimeConfig.royaltiesBps * salePrice) /
            ROYALTIES_BASIS;
    }

    /// @dev OpenSea contract metadata
    function contractURI() external view returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"seller_fee_basis_points": ', // solhint-disable-line quotes
                        _runtimeConfig.royaltiesBps.toString(),
                        ', "fee_recipient": "', // solhint-disable-line quotes
                        uint256(uint160(_runtimeConfig.royaltiesAddress))
                            .toHexString(20),
                        '"}' // solhint-disable-line quotes
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    

    /// Check if enough payment was provided
    modifier paymentProvided(uint256 payment) {
        require(msg.value >= payment, "Payment too small");
        _;
    }

    /***********************
     * Convenience getters *
    ***********************/

    function maxSupply() public view returns (uint256) {
        return _deploymentConfig.maxSupply;
    }

    function reservedSupply() public view returns (uint256) {
        return _deploymentConfig.reservedSupply;
    }

    function publicMintPrice() public view returns (uint256) {
        return _runtimeConfig.publicMintPrice;
    }

    function presaleMintPrice() public view returns (uint256) {
        return _runtimeConfig.presaleMintPrice;
    }

    function tokensPerMint() public view returns (uint256) {
        return _deploymentConfig.tokensPerMint;
    }

    function tokensPerPerson() public view returns (uint256){
        return _deploymentConfig.tokenPerPerson;
    }

    function treasuryAddress() public view returns (address) {
        return _deploymentConfig.treasuryAddress;
    }

    function publicMintStart() public view returns (uint256) {
        return _runtimeConfig.publicMintStart;
    }

    function presaleMintStart() public view returns (uint256) {
        return _runtimeConfig.presaleMintStart;
    }

    function presaleMerkleRoot() public view returns (bytes32) {
        return _runtimeConfig.presaleMerkleRoot;
    }

    function baseURI() public view returns (string memory) {
        return _runtimeConfig.baseURI;
    }

    function metadataUpdatable() public view returns (bool) {
        return _runtimeConfig.metadataUpdatable;
    }

    function prerevealTokenURI() public view returns (string memory) {
        return _runtimeConfig.prerevealTokenURI;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}