// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.7;

import "./Helpers.sol";

contract MainNFTMarketplace is ReentrancyGuard, Ownable {

  RoyaltiesRegistry internal royaltiesRegistry;
  uint256 public marketPlaceFee = 5; // %

    struct NftItem {
      address nftContract;
      uint256 nftTokenId;
      address payable seller;
      address payable buyer;
      uint256 price;
      bool sold;
      bool canceled;
    }

    // store with bytes => bytes=(address+id)
    mapping(bytes32 => NftItem) private NftItemsOfid;

    event NftPutOnSell(
      address indexed nftContract,
      uint256 indexed nftTokenId,
      address payable seller,
      address payable buyer,
      uint256 price
    );

    event NftSold(
      address indexed nftContract,
      uint256 indexed nftTokenId,
      address payable seller,
      address payable buyer,
      uint256 price
    );

    event NftSellCanceled(
      address indexed nftContract,
      uint256 indexed nftTokenId,
      address payable seller,
      address payable buyer,
      uint256 price
    );


  constructor(address _royaltiesRegistry) {
    royaltiesRegistry = RoyaltiesRegistry(_royaltiesRegistry);
  }
  
  /* Put an NFt item to sell on the marketplace */
  function PutNftOnSell(
    address nftContract,
    uint256 nftId,
    uint256 price
  ) public payable nonReentrant {
    IERC721 _nftContract = IERC721(nftContract);

    require(_nftContract.ownerOf(nftId) == msg.sender, "Your are not the owner of this nft");
    require(price > 0, "Price must be at least 1 wei");

    _nftContract.transferFrom(msg.sender, address(this), nftId);
    bytes32 itemBytes = getCombinatedBytes(nftContract,nftId);
    NftItemsOfid[itemBytes] =  NftItem(
        nftContract,
        nftId,
        payable(msg.sender),
        payable(address(0)),
        price,
        false,
        false
      );
    emit NftPutOnSell(
      nftContract,
      nftId,
      payable(msg.sender),
      payable(address(0)),
      price
    );
  }

  /* Put an NFt item for sale on the marketplace */
  function CancelNftSale(
    bytes32 itemBytes
  ) public payable nonReentrant {
    NftItem memory nftItem = NftItemsOfid[itemBytes];

    require(nftItem.seller == msg.sender, "Your are not the owner of this nft");
    require(nftItem.buyer == address(0), "nft is already sold");
    require(nftItem.canceled == false, "nft is already sold");

    IERC721 _nftContract = IERC721(nftItem.nftContract);
    NftItemsOfid[itemBytes].canceled =  true;
    _nftContract.transferFrom(address(this), msg.sender, nftItem.nftTokenId);

    emit NftSellCanceled(
      nftItem.nftContract,
      nftItem.nftTokenId,
      nftItem.seller,
      nftItem.buyer,
      nftItem.price
    );
  }

  /* sell marketplace item to buyer */
  /* Transfers ownership of the item, as well as funds between parties */
  function BuyNftItem(bytes32 itemBytes) public payable nonReentrant {
    NftItem memory _nft = NftItemsOfid[itemBytes];
    require(!_nft.sold,"this nft item is already sold");
    require(!_nft.canceled,"this nft item is canceled");

    require(msg.value >= _nft.price,"send full price");
    // require(tokenContract.allowance(msg.sender,address(this)) >= _nft.price,"Allow tokens to spend");
    // require(tokenContract.transferFrom(msg.sender,_nft.seller, _nft.price),"Please pay full fee");

    uint256 _percent1000 = royaltiesRegistry.getRoyaltiesOf(_nft.nftContract).percent1000;
    address _user = royaltiesRegistry.getRoyaltiesOf(_nft.nftContract).user;
    uint256 _royaltiesAmount = ((_nft.price*_percent1000)/1000); 

    // send royaltie
    (bool sent, bytes memory data) = _user.call{value: _royaltiesAmount}("");
    require(sent, "Failed to send Ether");

    //send money to user
    uint256 _userAmount = ((_nft.price*(100-marketPlaceFee))/100); 
    (bool sent2,) = _nft.seller.call{value: _userAmount}("");
    require(sent2, "Failed to send Ether");

    IERC721 _nftContract = IERC721(_nft.nftContract);
    _nftContract.transferFrom(address(this), msg.sender, _nft.nftTokenId);

    NftItemsOfid[itemBytes].buyer = payable(msg.sender);
    NftItemsOfid[itemBytes].sold = true;

    emit NftSold(
      _nft.nftContract,
      _nft.nftTokenId,
      payable(_nft.seller),
      payable(_nft.buyer),
      _nft.price
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
        (bool os, ) = payable(_to).call{value: address(this).balance}("");
        require(os);
  }
  function withdrawBalanceToken(TokenContract tokenContract,address _to) public onlyOwner {
    require(tokenContract.transfer(_to,tokenContract.balanceOf(address(this))),"Not Able to Send");
  }
  function adminBalance() public view onlyOwner returns(uint256) {
    return  address(this).balance;
  }
}