//         _            _               _           _       _          _   _      _
//        / /\         / /\            /\ \       /\ \     /\ \    _ / /\/_/\    /\ \
//       / /  \       / /  \          /  \ \     /  \ \    \ \ \  /_/ / /\ \ \   \ \_\
//      / / /\ \__   / / /\ \        / /\ \ \   / /\ \ \    \ \ \ \___\/  \ \ \__/ / /
//     / / /\ \___\ / / /\ \ \      / / /\ \_\ / / /\ \ \   / / /  \ \ \   \ \__ \/_/
//     \ \ \ \/___// / /\ \_\ \    / /_/_ \/_// / /  \ \_\  \ \ \   \_\ \   \/_/\__/\
//      \ \ \     / / /\ \ \___\  / /____/\  / / /    \/_/   \ \ \  / / /    _/\/__\ \
//  _    \ \ \   / / /  \ \ \__/ / /\____\/ / / /             \ \ \/ / /    / _/_/\ \ \
// /_/\__/ / /  / / /____\_\ \  / / /      / / /________       \ \ \/ /    / / /   \ \ \
// \ \/___/ /  / / /__________\/ / /      / / /_________\       \ \  /    / / /    /_/ /
//  \_____\/   \/_____________/\/_/       \/____________/        \_\/     \/_/     \_\/
//
// SPDX-License-Identifier: MIT
// sharkboyfightclub.com

pragma solidity ^0.8.7;

import "./ERC721A.sol";

interface NFTContract {
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function balanceOf(address owner) external view returns (uint256 balance);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

}

interface LOXContract {
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract SBFC_VX is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;


  uint256 public  PRICE_ETH_IN_PUBLICSALE = 15*10**16; //0.15 ether
  uint256 public  PRICE_ETH_IN_WHITELIST = 1*10**17; //0.1 ether

  uint256 public  PRICE_ETH_IN_PRESALE = 1*10**17; //0.1 ether
  uint256 public  PRICE_LOX_TILL_1_400 = 10*10**18; //10 lOX
  uint256 public  PRICE_LOX_401_2500 = 30*10**18; //30 lox
  uint256 public  PRICE_LOX_2501_8888 = 50*10**18; //50 lox

  uint256 private constant TotalCollectionSize_ = 8888;
  uint256 private constant MaxMintPerBatch_ = 50;

  string private _baseTokenURI;
  string private _URIExtension = ".json";

  bool public isPresaleOn = true;
  bool public isPublicSaleOn = false;
  bool public isWhitelistPriceOn = true;

  mapping(uint256=>uint256) public vxNftToSbfcNft;
  mapping(uint256=>bool) public isNftMintedForThisId;

  NFTContract private nftContract;
  LOXContract private loxContract;

  constructor(string memory _baseUri, address sbfcContractAddress, address loxContractAddress) ERC721A("Shark Boy Fight Club VX", "SBFCVX", MaxMintPerBatch_, TotalCollectionSize_) {
      _baseTokenURI = _baseUri;
      isPresaleOn = true;
      nftContract = NFTContract(sbfcContractAddress);
      loxContract = LOXContract(loxContractAddress);
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "Please mint at the official website");
    _;
  }


  function mintPresale(uint256[] memory sbfcNftIds,bool withLOX)
    external
    payable
    callerIsUser
  {
    require(isPresaleOn, "Minting will be starting shortly.");

    uint256 totalNft = totalSupply();
    for (uint256 i = 0; i < sbfcNftIds.length; i++) {
      require(nftContract.ownerOf(sbfcNftIds[i]) == msg.sender, "You don't own this NFT");
      require(!isNftMintedForThisId[sbfcNftIds[i]], "This Token ID is already minted");

      vxNftToSbfcNft[totalNft+i] = sbfcNftIds[i];
      isNftMintedForThisId[sbfcNftIds[i]] = true;

       if (withLOX) {
        if (sbfcNftIds[i] < 401) {
          require(loxContract.allowance(msg.sender, address(this)) >= PRICE_LOX_TILL_1_400);
          require(loxContract.transferFrom(msg.sender, address(this), PRICE_LOX_TILL_1_400));
        } else if (sbfcNftIds[i]  <= 2500) {
          require(loxContract.allowance(msg.sender, address(this)) >= PRICE_LOX_401_2500);
          require(loxContract.transferFrom(msg.sender, address(this), PRICE_LOX_401_2500));
        } else if (sbfcNftIds[i] <= 8888) {
          require(loxContract.allowance(msg.sender, address(this)) >= PRICE_LOX_2501_8888);
          require(loxContract.transferFrom(msg.sender, address(this), PRICE_LOX_2501_8888));
        }
      }

    }
    if (!withLOX) {
        require(msg.value >= PRICE_ETH_IN_PRESALE * sbfcNftIds.length, "You need more ETH to mint.");
      }
    _safeMint(msg.sender, sbfcNftIds.length);
  }


  function mintPublicSale(uint256[] memory sbfcNftIds)
    external
    payable
    callerIsUser
  {
    require(isPublicSaleOn, "Minting will be starting shortly.");

    uint256 totalNft = totalSupply();

    if (isWhitelistPriceOn) {
      require(msg.value >= PRICE_ETH_IN_WHITELIST * sbfcNftIds.length, "You need more ETH to mint.");
    } else {
      require(msg.value >= PRICE_ETH_IN_PUBLICSALE * sbfcNftIds.length, "You need more ETH to mint.");
    }
    for (uint256 i = 0; i < sbfcNftIds.length; i++) {
      require(!isNftMintedForThisId[sbfcNftIds[i]], "This Token ID is already minted");
      vxNftToSbfcNft[totalNft+i] = sbfcNftIds[i];
      isNftMintedForThisId[sbfcNftIds[i]] = true;
    }

    _safeMint(msg.sender, sbfcNftIds.length);
  }

   function mintPublicSaleDirect(uint256 howMuch)
    external
    payable
    callerIsUser
  {
    require(isPublicSaleOn, "Minting will be starting shortly.");

    if (isWhitelistPriceOn) {
      require(msg.value >= PRICE_ETH_IN_WHITELIST * howMuch, "You need more ETH to mint.");
    } else {
      require(msg.value >= PRICE_ETH_IN_PUBLICSALE * howMuch, "You need more ETH to mint.");
    }

    uint256 totalNft = totalSupply();
    uint256[] memory sbfcIdArray = getNotMintedIds(howMuch);
    for (uint256 i = 0; i < sbfcIdArray.length; i++) {
      require(!isNftMintedForThisId[sbfcIdArray[i]], "This Token ID is already minted");
      require(sbfcIdArray[i] > 0, "This Token ID is already minted");

      vxNftToSbfcNft[totalNft+i] = sbfcIdArray[i];
      isNftMintedForThisId[sbfcIdArray[i]] = true;
    }

    _safeMint(msg.sender, sbfcIdArray.length);
  }


  function getNotMintedIds(uint256 howMuch) public view returns(uint256[] memory) {
    uint256[] memory _a = new uint256[](howMuch);
    uint256 _id = 0;
    for (uint256 i = 1; i <= 8888; i++) {
      if (!isNftMintedForThisId[i]){
        _a[_id] = i;
        _id ++;
        if(_id >= howMuch){
          break;
        }
      }
    }
    return _a;
  }

  function getAllVxTokensIdOfUser(address _user) public view returns(uint256[] memory) {
    uint256 totalNftsUser = balanceOf(_user);
    uint256[] memory _allNftsArray = new uint256[](totalNftsUser);
    for (uint256 i = 0; i < totalNftsUser; i++) {
        uint256 _nft = tokenOfOwnerByIndex(_user,i);
        _allNftsArray[i] = _nft;
    }
    return _allNftsArray;
  }

  function getAllVxTokensSbfcIdOfUser(address _user) public view returns(uint256[] memory) {
    uint256 totalNftsUser = balanceOf(_user);
    uint256[] memory _allNftsArray = new uint256[](totalNftsUser);
    for (uint256 i = 0; i < totalNftsUser; i++) {
        uint256 _nft = tokenOfOwnerByIndex(_user,i);
        _allNftsArray[i] = vxNftToSbfcNft[_nft];
    }
    return _allNftsArray;
  }

   function getAllSbfcNftsUserHave(address _user) public view returns(uint256[] memory) {
    uint256 totalNftsUser = nftContract.balanceOf(_user);
    uint256[] memory _allNftsArray = new uint256[](totalNftsUser);
    for (uint256 i = 0; i < totalNftsUser; i++) {
        uint256 _nft = nftContract.tokenOfOwnerByIndex(_user,i);
        _allNftsArray[i] = _nft;
    }
    return _allNftsArray;
  }



  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, vxNftToSbfcNft[tokenId].toString(),_getUriExtension()))
        : "";
  }

  function _getUriExtension() internal view virtual override returns (string memory) {
    return _URIExtension;
  }

   function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
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

  function probablyNothing() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function LoxBack(LOXContract _tokenAddress, address _user,uint256 _amount) external onlyOwner nonReentrant {
    _tokenAddress.transfer(_user,_amount);
  }

    function FlipPublicSale() external onlyOwner
    {
        isPublicSaleOn = !isPublicSaleOn;
    }

    function FlipPreSale() external onlyOwner
    {
        isPresaleOn = !isPresaleOn;
    }

    function FlipWhitelistSystem() external onlyOwner
    {
        isWhitelistPriceOn = !isWhitelistPriceOn;
    }

     function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
  function setBaseURIExtension(NFTContract _address) external onlyOwner {
    nftContract = _address;
  }

  function setBaseURI(LOXContract  _address) external onlyOwner {
    loxContract = _address;
  }
}