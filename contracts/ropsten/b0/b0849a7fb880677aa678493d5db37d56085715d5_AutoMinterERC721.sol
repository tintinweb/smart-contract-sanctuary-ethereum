// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

// import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "./OwnableUpgradable.sol";
import "./ECDSA.sol";
import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./Strings.sol";
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
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}


contract AutoMinterERC721 is Initializable, ERC721Upgradeable, OwnableUpgradeable, IERC2981Upgradeable
{
    string private baseURI;
    address constant public shareAddress = 0xE28564784a0f57554D8beEc807E8609b40A97241;
    uint256 public mintFee = 0.05 ether;
    bool private mintSelectionEnabled;
    bool private mintRandomEnabled;
    
    uint256 public remaining;
    mapping(uint256 => uint256) public cache;
    mapping(uint256 => uint256) public cachePosition;
    mapping(address => uint256) public accountMintCount;

    address private whiteListSignerAddress;
    uint256 public mintLimit;
    uint256 public royaltyBasis = 1000;
    uint256 public ammountWithdrawn = 0;

    constructor(){}

    function initialize(string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address ownerAddress_,
        uint256 mintFee_,
        uint256 size_,
        bool mintSelectionEnabled_,
        bool mintRandomEnabled_,
        address whiteListSignerAddress_,
        uint256 mintLimit_,
        uint256 royaltyBasis_) public initializer  {

        __ERC721_init(name_, symbol_);
        baseURI = baseURI_;
        mintSelectionEnabled = mintSelectionEnabled_;
        mintRandomEnabled = mintRandomEnabled_;
        _transferOwnership(ownerAddress_);
        remaining = size_;
        whiteListSignerAddress = whiteListSignerAddress_;
        mintLimit = mintLimit_;
        royaltyBasis = royaltyBasis_;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    /* Mint specific token if individual token selection is enabled */
    function mintToken(uint256 tokenID) payable public
    {
        require(mintSelectionEnabled == true, 'Specific token minting is not enabled for this contract');
        require(msg.value == mintFee, 'Eth sent does not match the mint fee');
        
        _updateUserMintCount(msg.sender);

        // _splitPayment();
        
        _drawIndex(tokenID);
        
        _safeMint(msg.sender, tokenID);
    }
    
    /* Mint random token if random minting is enabled */
    function mintRandom() payable public
    {
        require(mintRandomEnabled == true, 'Random minting is not enabled for this contract');
        require(msg.value == mintFee, 'Eth sent does not match the mint fee');
        
        _updateUserMintCount(msg.sender);
        
        // _splitPayment();
        
        uint256 tokenID = _drawRandomIndex();
        
        _safeMint(msg.sender, tokenID);
    }
    
    /* Mint if have been pre-approved using signature of the owner */
    function mintWithSignature(bool isFree, address to, uint256 tokenID, bool isRandom, uint256 customFee, bytes calldata signature) payable public
    {
        _updateUserMintCount(to);

        /* Hash the content (isFree, to, tokenID) and verify the signature from the owner address */
        address signer = ECDSA.recover(
                ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(isFree, to, tokenID, isRandom, customFee))),
                signature);
            
        require(signer == owner() || signer == whiteListSignerAddress, "The signature provided does not match");
        
        /* If isFree then do not splitPayment, else splitPayment */
        if(!isFree){

            /* If custom fee is not provided use, mint fee */
            if(customFee == 0){
                require(msg.value == mintFee, 'Eth sent does not match the mint fee');
            }
            /* If custom fee is provided use, the custom fee */
            else{
                require(msg.value == customFee, 'Eth sent does not match the mint fee');
            }

            // _splitPayment();
        }
        
        /* Mint the token for the provided to address */
        if(isRandom){
            tokenID = _drawRandomIndex();
        }
        else{
            _drawIndex(tokenID);
        }
        
        _safeMint(to, tokenID);
    }
    
    /* Mint a token to a specific address */
    function mintToAccount(address to, uint256 tokenID) onlyOwner() public
    {
        _drawIndex(tokenID);
        _safeMint(to, tokenID);
    }
    
    // function _splitPayment() internal
    // {
    //     if(msg.value != 0){
    //         uint256 splitValue = msg.value / 10;
    //         uint256 remainingValue = msg.value - splitValue;
            
    //         payable(shareAddress).transfer(splitValue);
    //         payable(owner()).transfer(remainingValue);
    //     }
    // }
    
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
    
    function isTokenAvailable(uint256 tokenID) external view returns (bool)
    {
        return !_exists(tokenID);
    }

    function toggleRandomPublicMinting() onlyOwner() public
    {
        mintRandomEnabled = !mintRandomEnabled;
    }

    function changeMintFee(uint256 mintFee_) onlyOwner() public
    {
        mintFee = mintFee_;
    }

    function royaltyInfo(uint _tokenId, uint _salePrice) external view override returns (address receiver, uint royaltyAmount) {
        return (address(this), uint((_salePrice * royaltyBasis)/10000));
    }
    
    /* Transfer balance of this contract to an account */
    function transferBalance(address payable to, uint256 ammount) onlyOwner() public{
        
        if(address(this).balance != 0){
            require(address(this).balance <= ammount, "Not enought Balance to Transfer");

            uint256 splitValue = ammount / 10;
            uint256 remainingValue = ammount - splitValue;
            
            payable(shareAddress).transfer(splitValue);
            payable(to).transfer(remainingValue);
            ammountWithdrawn += ammount;
        }
    }
    
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string(abi.encodePacked('{"name":"', name(), '","seller_fee_basis_points":', Strings.toString(royaltyBasis), ',"fee_recipient":"', "0x", toAsciiString(address(this)), '"}' ))
                )
            )
        ));
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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
    
    function version() external pure returns (string memory)
    {
        return "1.0.3";
    }

    receive() external payable {}
}