// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./AggregatorV3Interface.sol";

contract InfinityNFT is ERC721, Ownable {
using Address for address payable;

    enum Status {
        Pause,
        Presale,
        WhitelistSale,
        PublicSale
    }

    Status public contractStatus;

    //PRICES AND WITHDRAW ADDRESS

    AggregatorV3Interface private usdByEthFeed;

    AggregatorV3Interface private usdByEuroFeed;

    address public fundsReceiver = 0x8900a924E4B942F64F23b014687cB2b2B1624FAB;

    uint256 public priceInEuro = 1000;

    uint256 public maxMintPerAddress = 3;

    //SUPPLIES

    uint256 public preSaleSupply;

    uint256 public PRE_SALE_MAX_SUPPLY = 499;

    uint256 public artistSupply;

    uint256 public ARTIST_MAX_SUPPLY = 1;

    uint256 public saleSupply;

    uint256 public SALE_MAX_SUPPLY = 4500;

    uint256 public MAX_SUPPLY = SALE_MAX_SUPPLY + PRE_SALE_MAX_SUPPLY + ARTIST_MAX_SUPPLY;

    //MERKLE ROOT FOR WHITELIST MINTS

    bytes32 public merkleRoot;

    //metadatas
    string public baseURI = "ipfs://Qmb2egjx8rQFzSk9fEpbdsT3ezPCeuF5RbiQKtTzgyzWDf/";

    //string public contractURI = "https://server.wagmi-studio.com/metadata/test/infTest/collection.json";

    /*
     * @param - usdByEthFeedAddress : chainlink usd/eth converter address
     * @param – usdByEuroFeedAddress: chainlink usd/euro converter address
     */
    constructor(address usdByEthFeedAddress, address usdByEuroFeedAddress)
    ERC721("InfTest 6", "INFF")
        {
            usdByEthFeed = AggregatorV3Interface(usdByEthFeedAddress);
            usdByEuroFeed = AggregatorV3Interface(usdByEuroFeedAddress);
        }

    //PRE SALE MINT FUNCTIONS

    function preSaleMint(address to, uint256 quantity) external payable {
        require(contractStatus == Status.Presale, "Pre sale not enabled");
        require(balanceOf(to)+quantity<=maxMintPerAddress, "Mint limit reached");
        _checkPreSaleSupply(quantity);
        _checkPayment(quantity);
        _preSaleMint(to, quantity);
    }

    function presaleGiftDrop(address to, uint256 quantity) external onlyOwner {
        _checkPreSaleSupply(quantity);
        _preSaleMint(to, quantity);
    }

    function _checkPreSaleSupply(uint256 quantity) private view {
        require(quantity>0, "quantity must be positive");
        require(quantity+preSaleSupply<=PRE_SALE_MAX_SUPPLY, "sale max supply reached");
    }

    function _preSaleMint(address to, uint256 quantity) private {
        unchecked {
            for(uint256 i=1;i<=quantity;i++){
                 _mint(to, preSaleSupply + i);
            }
            preSaleSupply = preSaleSupply + quantity;
        }
    }

    //ARTIST DROP FUNCTIONS

    function artistDrop(address to) external onlyOwner {
        _checkArtistSupply(1);
        _artistMint(to);
    }

    function _checkArtistSupply(uint256 quantity) private view {
        require(quantity>0, "quantity must be positive");
        require(quantity+artistSupply<=ARTIST_MAX_SUPPLY, "sale max supply reached");
    }

    function _artistMint(address to) private {
        unchecked {
            _mint(to, PRE_SALE_MAX_SUPPLY + (++artistSupply));
        }
    }

     //WHITELIST AND PUBLIC SALE MINT FUNCTIONS

    function whiteListMint(uint256 quantity, bytes32[] calldata _proof) external payable {
        require(contractStatus == Status.WhitelistSale, "Whitelist sale not enabled");
        require(isWhitelistedAddress(msg.sender, _proof), "Invalid merkle proof");
        require(balanceOf(msg.sender)+quantity<=maxMintPerAddress, "Mint limit reached");
        _checkSaleSupply(quantity);
        _checkPayment(quantity);
        _saleMint(msg.sender, quantity);
    }

    function publicMint(address to, uint256 quantity) external payable {
        require(contractStatus == Status.PublicSale, "Public sale not enabled");
        require(balanceOf(to)+quantity<=maxMintPerAddress, "Mint limit reached");
        _checkSaleSupply(quantity);
        _checkPayment(quantity);
        _saleMint(to, quantity);
    }

    function saleGiftDrop(address to, uint256 quantity) external onlyOwner {
        _checkSaleSupply(quantity);
        _saleMint(to, quantity);
    }

    function _checkSaleSupply(uint256 quantity) private view {
        require(quantity>0, "quantity must be positive");
        require(quantity+saleSupply<=SALE_MAX_SUPPLY, "sale max supply reached");
    }

    function _saleMint(address to, uint256 quantity) private {
        unchecked {
            for(uint256 i = 1;i<=quantity;i++){
                 _mint(to, PRE_SALE_MAX_SUPPLY + ARTIST_MAX_SUPPLY + saleSupply + i);
            }
            saleSupply = saleSupply + quantity;
        }
    }

    //PAYMENT CHECKER
    
    function _checkPayment(uint256 quantity) private view {
        uint256 priceInWei = getNftWeiPrice() * quantity;
        uint256 minPrice = (priceInWei * 995) / 1000;
        uint256 maxPrice = (priceInWei * 1005) / 1000;
        require(msg.value >= minPrice, "Not enough ETH");
        require(msg.value <= maxPrice, "Too much ETH");
    }

    //TOTAL SUPPLY REQUIRED FUNCTION
        
    function totalSupply() external view returns(uint256) {
        return preSaleSupply+saleSupply+artistSupply;
    }

    //ADMIN SETTERS
 
    function setStatus(uint256 step) external onlyOwner {
        contractStatus = Status(step);
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }
    
    function setPriceInEuro(uint256 price) external onlyOwner {
        priceInEuro = price;
    }

    function setUsdByEthFeed(address usdByEthFeedAddress) external onlyOwner {
        usdByEthFeed = AggregatorV3Interface(usdByEthFeedAddress);
    }

    function setUsdByEuroFeed(address usdByEuroFeedAddress) external onlyOwner {
        usdByEuroFeed = AggregatorV3Interface(usdByEuroFeedAddress);
    }

    //METADATA URI BUILDER

    function tokenURI(uint256 tokenId) public view override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    //PRICE CALCULATOR FUNCTIONS

    function getUsdByEth() private view returns (uint256) {
        (, int256 price, , , ) = usdByEthFeed.latestRoundData();
        return uint256(price);
    }

    function getUsdByEuro() private view returns (uint256) {
        (, int256 price, , , ) = usdByEuroFeed.latestRoundData();
        return uint256(price);
    }

    function getNftWeiPrice() public view returns (uint256) {
        uint256 priceInDollar = (priceInEuro * getUsdByEuro() * 10**18) / 10**usdByEuroFeed.decimals();
        uint256 weiPrice = (priceInDollar * 10**usdByEthFeed.decimals()) / getUsdByEth();
        return weiPrice;
    }

    //MERKLE TREE FUNCTIONS
    
    function isWhitelistedAddress(address _address, bytes32[] calldata _proof) private view returns(bool) {
        bytes32 addressHash = keccak256(abi.encodePacked(_address));
        return MerkleProof.verifyCalldata(_proof, merkleRoot, addressHash);
    }

    //FUNDS WITHDRAW FUNCTION

    function setFundsReceiver(address _fundsReceiver) external onlyOwner{
        fundsReceiver = _fundsReceiver;
    }

    function retrieveFunds() external {
        require(
            msg.sender == owner() ||
            msg.sender == fundsReceiver,
            "Not allowed"
        );
        payable(fundsReceiver).sendValue(address(this).balance);
    }
}