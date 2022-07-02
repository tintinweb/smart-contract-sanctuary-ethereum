// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

// import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "./OwnableUpgradeable.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";
import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IERC20.sol";
import "./Base64.sol";


// import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
}

contract PB1 is Initializable, ERC721Upgradeable, OwnableUpgradeable, IERC2981Upgradeable
{
    string private baseURI;
    uint256 public mintFee = 0.005 ether;
    bool private mintRandomEnabled = true;
    
    uint256 public remaining = 10000;
    mapping(uint256 => uint256) public cache;
    mapping(uint256 => uint256) public cachePosition;
    mapping(address => uint256) public accountMintCount;

    uint256 public mintLimit = 2;
    uint256 public amountWithdrawn = 0;
    string public placeholderImage;

    bool public lockBaseUri;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    bool public whitelistMintEnabled = false;

    constructor()  {}

    function initialize(
        string memory baseURI_,
        address ownerAddress_,
        string memory placeholderImage_) public initializer  {

        __ERC721_init("PB1", "PB1");
        baseURI = baseURI_;
        _transferOwnership(ownerAddress_);
        placeholderImage = placeholderImage_;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    /* Mint 'n' random tokens if random minting is enabled */
    function mintRandom(uint256 count) payable public
    {
        require(count > 0, 'Count must be greater than zero');
        require(mintRandomEnabled == true, 'Random minting is not enabled for this contract');
        require(msg.value == mintFee * count, 'Eth sent does not match the mint fee');
        
        _updateUserMintCount(msg.sender, count);

        for(uint256 i=0; i < count; i++){
            uint256 tokenID = _drawRandomIndex();
            _safeMint(msg.sender, tokenID);
        }
    }
    
    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) payable public {
        _updateUserMintCount(msg.sender);
        // Verify whitelist requirements
        require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
        require(!whitelistClaimed[msg.sender], 'Address already claimed!');
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

        whitelistClaimed[msg.sender] = true;
        for(uint256 i=0; i < _mintAmount; i++){
            /* Mint the token for the provided to address */
            uint256 tokenID = _drawRandomIndex();
            _safeMint(msg.sender, tokenID);
        }
    }
    
    /* Mint a token to a specific address */
    function airDropRandomToAccounts(address[] calldata to) onlyOwner() public
    {
        for (uint i=0; i<to.length; i++) {
            uint256 tokenID = _drawRandomIndex();
            _safeMint(to[i], tokenID);
        }
    }
    
    function _drawRandomIndex() internal returns (uint256 index) {
        //RNG
        uint256 i = uint(keccak256(abi.encodePacked(block.timestamp))) % remaining;

        // if there's a cache at cache[i] then use it
        // otherwise use i itself
        index = cache[i] == 0 ? i : cache[i];

        // grab a number from the tail
        cache[i] = cache[remaining - 1] == 0 ? remaining - 1 : cache[remaining - 1];
        
        // store the position of moved token in cache to be looked up (add 1 to avoid 0, remove when recovering)
        cachePosition[cache[i]] = i + 1;
        
        remaining = remaining - 1;
    }
    
    function _drawIndex(uint256 tokenID) internal {
        // recover the index, subtract 1 from cachePosition as an additional 1 was added to avoid 0 conflict
        uint256 i = cachePosition[tokenID] == 0 ? tokenID : cachePosition[tokenID] - 1;
        
        require(i <= remaining);
        
        // grab a number from the tail
        cache[i] = cache[remaining - 1] == 0 ? remaining - 1 : cache[remaining - 1];
        
        // store the position of moved token in cache to be looked up (add 1 to avoid 0, remove when recovering)
        cachePosition[cache[i]] = i + 1;
        
        remaining = remaining - 1;
    }
    
    function _updateUserMintCount(address account) internal {
        // increment a mapping for user on how many mints they have
        uint256 count = accountMintCount[account];

        require(count < mintLimit || mintLimit == 0, "Mint limit for this account has been exceeded");

        accountMintCount[account] = count + 1;
    }
    
    function _updateUserMintCount(address account, uint256 quantity) internal {
        // increment a mapping for user on how many mints they have
        uint256 count = accountMintCount[account];

        require(count + quantity <= mintLimit || mintLimit == 0, "Mint limit for this account has been exceeded");

        accountMintCount[account] = count + quantity;
    }
    
    function _updateUserMintCount(address account, uint256 quantity, uint256 customLimit) internal {
        // increment a mapping for user on how many mints they have
        uint256 count = accountMintCount[account];

        if(customLimit == 0){
            require(count + quantity <= mintLimit || mintLimit == 0, "Mint limit for this account has been exceeded");
        }
        else{
            require(count + quantity <= customLimit, "Mint limit for this account has been exceeded");
        }

        accountMintCount[account] = count + quantity;
    }
    
    function isTokenAvailable(uint256 tokenID) external view returns (bool)
    {
        return !_exists(tokenID);
    }

    function toggleRandomPublicMinting() onlyOwner() public
    {
        mintRandomEnabled = !mintRandomEnabled;
    }

    function toggleWhitelistMinting() onlyOwner() public
    {
        whitelistMintEnabled = !whitelistMintEnabled;
    }
    function changeMintFee(uint256 mintFee_) onlyOwner() public
    {
        mintFee = mintFee_;
    }

    function changeMintLimit(uint256 mintLimit_) onlyOwner() public
    {
        mintLimit = mintLimit_;
    }

    function changePlaceholderImage(string memory placeholderImage_) onlyOwner() public
    {
        require(bytes(placeholderImage).length != 0, "Metadata has already been revealed");
        require(bytes(placeholderImage_).length != 0, "Placeholder image cannot be empty");

        placeholderImage = placeholderImage_;
    }

    /* Transfer balance of this contract to an account */
    function transferBalance(address payable to, uint256 amount) onlyOwner() public{
        if(address(this).balance != 0){
            require(address(this).balance <= amount, "Not enought Balance to Transfer");
            payable(to).transfer(amount);
            amountWithdrawn += amount;
        }
    }
    
    /* Transfer any ERC20 balance of this contract to an account */
    function transferERC20Balance(address erc20ContractAddress, address payable to, uint256 amount) onlyOwner() public{
        IERC20(erc20ContractAddress).transfer(to, amount);
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function isPublicMintingEnabled() external view returns (bool){
        return mintRandomEnabled;
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory __baseURI = _baseURI();

        if(bytes(placeholderImage).length > 0){
            return placeholderImage;
        }
        else{
            return bytes(__baseURI).length > 0 ? string(abi.encodePacked(__baseURI, Strings.toString(tokenId))) : "";
        }

    }

    function reveal() onlyOwner() public {
        placeholderImage = "";
    }

    function changeBaseUri(string memory baseURI_) onlyOwner() public {
        require(!lockBaseUri, "Base URI is locked, it cannot be edited");

        baseURI = baseURI_;
    }

    function permanentlyLockBaseUri() onlyOwner() public {
        lockBaseUri = true;
    }

    function getMintsUsed(address account) external view returns (uint256) {
        return accountMintCount[account];
    }
    
    function version() external pure returns (string memory)
    {
        return "1.0.6";
    }

    receive() external payable {}
}