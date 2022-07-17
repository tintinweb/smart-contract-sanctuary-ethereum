// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./ECDSA.sol";

contract SCTest is Ownable, ERC721A, ReentrancyGuard {
  using ECDSA for bytes32;
  
  uint256 public maxMintPerWallet;
  uint256 public maxMintPerTx;
  uint256 public totalFreeMints;
  uint256 public freeMintPerWallet;
  uint256 public freeMintPerTx;

  // owner signer
  address public _adminSigner;

  // // metadata URI
  string private _baseTokenURI;

  struct SaleConfig {
    uint64 publicPrice;
  }

  SaleConfig public saleConfig;

  constructor(
    uint256 maxMintPerWallet_,
    uint256 collectionSize_
  ) ERC721A("SCTest", "SCTEST", maxMintPerWallet_, collectionSize_) {
    maxMintPerTx = 10;
    maxMintPerWallet = maxMintPerWallet_;
    freeMintPerTx = 2;
    freeMintPerWallet = 2;
    totalFreeMints = 1500;
    saleConfig = SaleConfig(
      0.005 ether
    );
    require(
      freeMintPerWallet <= collectionSize_,
      "larger collection size needed"
    );
    require(
      freeMintPerTx <= freeMintPerWallet,
      "larger free mint per wallet needed"
    );
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function setMaxMintPerTx(uint256 quantity) external onlyOwner {
    maxMintPerTx = quantity;
  }

  function setMaxMintPerWallet(uint256 quantity) external onlyOwner {
    maxMintPerWallet = quantity;
  }

  function setFreeMintPerWallet(uint256 quantity) external onlyOwner {
    freeMintPerWallet = quantity;
  }

  function Mint(uint256 quantity)
    external
    payable
    callerIsUser
  {
    SaleConfig memory config = saleConfig;
    uint256 publicPrice = uint256(config.publicPrice);

    require(totalSupply() + quantity <= collectionSize, "reached max supply");

    if(totalSupply() + quantity > totalFreeMints || quantity > freeMintPerTx || numberMinted(msg.sender) >= freeMintPerWallet ){
        require(
            (publicPrice * quantity) <= msg.value,
            "Insufficient ETH sent"
        );
    }
  
    _safeMint(msg.sender, quantity);
  }

  function authorizedMint(uint quantity, uint allowquantity, bytes calldata signature ) public payable callerIsUser{
        //require(salesStage > 1 && salesStage < 9, "Mint not active");
        require(isAllowListAuthorized(msg.sender,  allowquantity, signature), "Auth failed");
        //require(totalSupply() + quantity <= quantityForMint, "Minted Out");
        //require(authorizedMinteds[salesStage][msg.sender] + quantity <= maxPerAddress, "Wallet Max Reached");
        //require(tokenPrice * quantity <= msg.value, "Insufficient Eth");

        _safeMint(msg.sender, quantity);
    }

  function isAllowListAuthorized(
        address sender, 
        uint allowAmount,
        bytes calldata signature
    ) private view returns (bool) {
        bytes32 messageDigest = keccak256(abi.encodePacked(allowAmount, sender));
        bytes32 ethHashMessage = ECDSA.toEthSignedMessageHash(messageDigest);
        return ECDSA.recover(ethHashMessage, signature) == _adminSigner;

    }

  function setSigner(address newSigner) external onlyOwner {
       _adminSigner = newSigner;
    }  

  function setPublicPrice(
    uint64 publicPriceWei
  ) external onlyOwner {
    saleConfig = SaleConfig(
      publicPriceWei
    );
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}