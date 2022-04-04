// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import "./Helpers.sol";

contract MainNFTMarketplace is ReentrancyGuard, Ownable {

  RoyaltiesRegistry internal royaltiesRegistry;
  uint256 public marketPlaceFee = 5; // %

    struct NftItem {
      address nftContract;
      uint256 nftTokenId;
      address seller;
      uint256 price;
      bool isOnSale;
    }

    // store with bytes => bytes=(address+id)
    mapping(bytes32 => NftItem) private NftItemsOfid;

    event NftPutOnSell(
      address indexed nftContract,
      uint256 indexed nftTokenId,
      address seller,
      uint256 price,
      uint256 time
    );

    event NftSold(
      address indexed nftContract,
      uint256 indexed nftTokenId,
      address seller,
      address buyer,
      uint256 price,
      uint256 time
    );

    event NftSellCanceled(
      address indexed nftContract,
      uint256 indexed nftTokenId,
      address seller,
      uint256 price,
      uint256 time
    );


  constructor(address _royaltiesRegistry) {
    royaltiesRegistry = RoyaltiesRegistry(_royaltiesRegistry);
  }
  
  /* Put an NFt item to sell on the marketplace */
  function PutNftOnSell(
    address nftContract,
    uint256 nftId,
    uint256 price
  ) public  nonReentrant {
    IERC721 _nftContract = IERC721(nftContract);

    require(_nftContract.ownerOf(nftId) == msg.sender, "Your are not the owner of this nft");
    require(price > 0, "Price must be at least 1 wei");

    _nftContract.transferFrom(msg.sender, address(this), nftId);
    bytes32 itemBytes = getCombinatedBytes(nftContract,nftId);
    NftItemsOfid[itemBytes] =  NftItem(
        nftContract,
        nftId,
        msg.sender,
        price,
        true
      );

    emit NftPutOnSell(
      nftContract,
      nftId,
      msg.sender,
      price,
      block.timestamp
    );
  }

  /* Put an NFt item for sale on the marketplace */
  function CancelNftSale(
    address nftContract,
    uint256 nftId
  ) public  nonReentrant {
    bytes32 itemBytes = getCombinatedBytes(nftContract,nftId);

    NftItem memory nftItem = NftItemsOfid[itemBytes];

    require(nftItem.seller == msg.sender, "Your are not the owner of this nft");
    require(nftItem.isOnSale == true, "Your are not the owner of this nft");

    NftItemsOfid[itemBytes].seller = address(0);
    NftItemsOfid[itemBytes].price =  0;
    NftItemsOfid[itemBytes].isOnSale =  false;

    IERC721 _nftContract = IERC721(nftItem.nftContract);
    _nftContract.transferFrom(address(this), msg.sender, nftItem.nftTokenId);

    emit NftSellCanceled(
      nftItem.nftContract,
      nftItem.nftTokenId,
      nftItem.seller,
      nftItem.price,
      block.timestamp
    );
  }

  /* sell marketplace item to buyer */
  /* Transfers ownership of the item, as well as funds between parties */
  function BuyNftItem(address nftContract, uint256 nftId) public payable nonReentrant {

    bytes32 itemBytes = getCombinatedBytes(nftContract,nftId);
    NftItem memory _nft = NftItemsOfid[itemBytes];
    require(_nft.isOnSale,"nft is not on sale");
    require(_nft.seller != address(0),"this nft item is canceled");

    require(msg.value >= _nft.price,"send full price");
    // require(tokenContract.allowance(msg.sender,address(this)) >= _nft.price,"Allow tokens to spend");
    // require(tokenContract.transferFrom(msg.sender,_nft.seller, _nft.price),"Please pay full fee");

    uint256 _percent1000 = royaltiesRegistry.getRoyaltiesOf(_nft.nftContract).percent1000;
    address _user = royaltiesRegistry.getRoyaltiesOf(_nft.nftContract).user;
    uint256 _royaltiesAmount = ((_nft.price*_percent1000)/1000); 

    // send royaltie
    (bool sent,) = _user.call{value: _royaltiesAmount}("");
    require(sent, "Failed to send Ether");

    //send money to user
    uint256 _userAmount = ((_nft.price*(100-marketPlaceFee))/100); 
    (bool sent2,) = _nft.seller.call{value: _userAmount}("");
    require(sent2, "Failed to send Ether");

    IERC721 _nftContract = IERC721(_nft.nftContract);
    _nftContract.transferFrom(address(this), msg.sender, _nft.nftTokenId);

    NftItemsOfid[itemBytes].seller = address(0);
    NftItemsOfid[itemBytes].price =  0;
    NftItemsOfid[itemBytes].isOnSale =  false;
    
    emit NftSold(
      _nft.nftContract,
      _nft.nftTokenId,
      _nft.seller,
      msg.sender,
      _nft.price,
      block.timestamp
    );
  }

  function getCombinatedBytes(address _address,uint256 _id) public pure returns (bytes32) 
    {
        bytes32 _added = keccak256(abi.encodePacked(_address, _id));
        return _added;
    }

  function loadNftItem(address _address,uint256 _nftId) public view returns(NftItem memory){
    return NftItemsOfid[getCombinatedBytes(_address,_nftId)];
  }

  function loadNftItems(address[] memory _address, uint256[] memory _nftIds) public view returns(NftItem[] memory){
      require(_address.length == _nftIds.length,"Address and ids must equal");
    NftItem[] memory _items = new NftItem[](_nftIds.length);
    for (uint256 i = 0; i < _nftIds.length; i++) {
      _items[i] = NftItemsOfid[getCombinatedBytes(_address[i],_nftIds[i])];
    }
    return _items;
  }
  function withdrawBalance(address _to) public onlyOwner {
        (bool os, ) = (_to).call{value: address(this).balance}("");
        require(os);
  }
  function withdrawBalanceToken(TokenContract tokenContract,address _to) public onlyOwner {
    require(tokenContract.transfer(_to,tokenContract.balanceOf(address(this))),"Not Able to Send");
  }
  function adminBalance() public view onlyOwner returns(uint256) {
    return  address(this).balance;
  }
}