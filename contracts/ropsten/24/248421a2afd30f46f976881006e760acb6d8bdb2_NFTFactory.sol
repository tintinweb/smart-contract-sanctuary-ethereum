// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import "./Ownable.sol";
import "./NFTTradable.sol";
contract NFTFactory is Ownable {
    // Events of the contract
    event ContractCreated(address creator, address nft);
    event ContractDisabled(address caller, address nft);
    //  auction contract address;
    address public auction;
    //  marketplace contract address;
    address public marketplace;
    //  bundle marketplace contract address;
    address public bundleMarketplace;
    //  NFT mint fee
    uint256 public mintFee = 0.01 ether;
    //  Platform fee for deploying new NFT contract
    uint256 public platformFee = 0.01 ether;
    //  Platform fee recipient
    address payable public feeRecipient = payable(0xC5C65074064e5283C9D40403208Af004c8960b95);
    //   NFT Address => Bool
    mapping(address => bool) public exists;
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    //   Contract constructor
    constructor(address _auction,address _marketplace,address _bundleMarketplace) {
        auction = _auction;
        marketplace = _marketplace;
        bundleMarketplace = _bundleMarketplace;
    }
    function updateAuction(address _auction) external onlyOwner {
        auction = _auction;
    }
    function updateMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }
    function updateBundleMarketplace(address _bundleMarketplace)external onlyOwner{
        bundleMarketplace = _bundleMarketplace;
    }
    function updateMintFee(uint256 _mintFee) external onlyOwner {
        mintFee = _mintFee;
    }
    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
    }
    function updateFeeRecipient(address payable _feeRecipient)external onlyOwner{
        feeRecipient = _feeRecipient;
    }

    //   Method for deploy new NFTTradable contract
    //  _name Name of NFT contract
    //  _symbol Symbol of NFT contract
    function createNFTContract(string memory _name, string memory _symbol)external payable returns (address){
        _name = "USMAN";
        _symbol= "USK";
        require(msg.value >= platformFee, "Insufficient funds.");
        (bool success,) = feeRecipient.call{value: msg.value}("");
        require(success, "Transfer failed");
        NFTTradable nft = new NFTTradable(auction,marketplace,bundleMarketplace);
        exists[address(nft)] = true;
        nft.transferOwnership(_msgSender());
        emit ContractCreated(_msgSender(), address(nft));
        return address(nft);
    }
    //   Method for registering existing NFTTradable contract
    //   tokenContractAddress Address of NFT contract
    function registerTokenContract(address tokenContractAddress)external onlyOwner{
        require(!exists[tokenContractAddress], "NFT contract already registered");
        require(IERC165(tokenContractAddress).supportsInterface(INTERFACE_ID_ERC721), "Not an ERC721 contract");
        exists[tokenContractAddress] = true;
        emit ContractCreated(_msgSender(), tokenContractAddress);
    }
    //   Method for disabling existing NFTTradable contract
    //   tokenContractAddress Address of NFT contract
    function disableTokenContract(address tokenContractAddress) external onlyOwner{
        require(exists[tokenContractAddress], "NFT contract is not registered");
        exists[tokenContractAddress] = false;
        emit ContractDisabled(_msgSender(), tokenContractAddress);
    }
}