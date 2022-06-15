// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';
// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol'; 

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";
// import "./Context.sol";
// import "./ERC721.sol";
// import "./ERC165.sol";
// import "./IERC721Metadata.sol";
// import "./ERC721Enumerable.sol";
// import "./IERC165.sol";
// import "./IERC721.sol";
// import "./IERC721Enumerable.sol";
// import "./IERC721Receiver.sol";
// import "./Pausable.sol";
// import "./SafeMath.sol";


contract ERC721NFT is  ERC721URIStorage, Ownable {


    mapping(address => bool) public whiteList;

    uint256 public preSaleStartDate;

    uint256 public preSaleEndDate;

    uint256 public preSalePrice;

    uint256 public publicSaleStartDate;

    uint256 public publicSaleEndDate;

    uint256 public publicSalePrice;
    
    uint256  public revealtime;

    uint256  public tokenId;

    
    

    constructor(string memory TokenName, string memory NFT721Symbol) ERC721(TokenName, NFT721Symbol) {}

    function setWhiteList(address _account) public onlyOwner {
        whiteList[_account] = true;
    }

    function isWhitelisted(address _account ) public view returns(bool) {
        return whiteList[_account];
    }

    function preSaleTimeSet(uint256 startTime ,uint256 endTime) public onlyOwner{
        preSaleStartDate = startTime;
        preSaleEndDate = endTime;
    }

    function publicSaleTimeSet(uint256 starttime,uint256 endtime) public onlyOwner{
        publicSaleStartDate = starttime;
        publicSaleEndDate = endtime;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    } 

    function setPresaleprice(uint256 setPresalePrice) public onlyOwner{
            preSalePrice = setPresalePrice;
    }


    function preSaleMint(uint256 count) public payable {

        require(preSaleStartDate <= block.timestamp && preSaleEndDate > block.timestamp,"No more Time");
        require(isWhitelisted(msg.sender), "There is no Token Exist");
        require(msg.value > preSalePrice * count,"Less Amount");
        for(uint256 i=1; i <= count;i++){
            tokenId++;
            _mint(msg.sender,tokenId);
        }
    }

    function setPublicSalePrice(uint256 setPublicPrice) public onlyOwner{
        publicSalePrice = setPublicPrice;
    }

    function publicSaleMint(uint256 count) public payable {

        require(publicSaleStartDate <= block.timestamp && publicSaleEndDate > block.timestamp,"Sale Time UP");
        require(msg.value >= publicSalePrice * count,"Less Amount");
        for(uint256 i = 1;i <= count;i++ ){
            tokenId++;
            _mint(msg.sender,tokenId);
        }
    }
   
    function revealNft(uint256 revealTime) public{
        revealtime = revealTime;
    }


    function tokenURI(uint256 _tokenId) public view  override returns (string memory )
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(block.timestamp > preSaleEndDate + revealtime){
            return super.tokenURI(_tokenId);
        }
        if(block.timestamp > publicSaleEndDate + revealtime){
            return super.tokenURI(_tokenId);
        }
    }
}