// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./MyERC.sol";
import "./Ownable.sol";

contract BombPark is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public price;
    uint256 public startNum=0;
    MyERC private usdt;
    MyERC private usdc;
    bool public isPaused = false;
    bool public isRevealed = true;
    address public ownerAddress;
    string public notRevealedUri;
    struct TokenBuyer {
        uint256 id;
        uint256 memberId;
        uint256 num;
        uint256 amount;
        uint256 buyType;
        address  buyer;
        uint256 createTime;
    }
    TokenBuyer[] public orderList;
    event itemBuy(uint256 id, address addrss, uint256 num);
    constructor(
        uint256 _price,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        MyERC _usdt,
        MyERC _usdc
    ) ERC721("BombParkNFT","BombParkNFT") {

        price = _price;
        ownerAddress=msg.sender;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        usdt = _usdt;
        usdc = _usdc;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _num,uint256  _id,uint256 _type) public payable  {
        uint256 payNum=_num*price*(10 ** 6);
        uint256 newItemId = orderList.length;
        orderList.push(TokenBuyer({
        id: newItemId,
        memberId: _id,
        num  : _num,
        amount  : _num*price,
        buyType  : _type,
        buyer: msg.sender,
        createTime: block.timestamp
        }));
        if(_type==1){
            require(usdc.balanceOf(msg.sender) >=payNum , "Not enough USDC sent");
            usdc.transferFrom(msg.sender,ownerAddress,payNum);
        }else{
            require(usdt.balanceOf(msg.sender) >=payNum , "Not enough USDT sent");
            usdt.transferFrom(msg.sender,ownerAddress,payNum);
        }
        _mintToOthers(msg.sender, _num);
        emit itemBuy(_id, msg.sender, _num);
    }
    function _mintToOthers(address _other,uint256 _mintAmount) private {
        for (uint256 i = 0; i <_mintAmount; i++) {
            startNum=startNum+1;
//            require(startNum < totalNum,"Sold Out!");

            _safeMint(_other, startNum);
        }
    }
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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
        if (isRevealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
        bytes(currentBaseURI).length > 0
        ? string(
            abi.encodePacked(
                currentBaseURI,
                tokenId.toString(),
                baseExtension
            )
        )
        : "";
    }

    // Only Owner Functions
    function setIsRevealed(bool _state) public onlyOwner {
        isRevealed = _state;
    }
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setOwnerAddress(address _address) public onlyOwner{
        ownerAddress = _address;
    }
    function setIsPaused(bool _state) public onlyOwner {
        isPaused = _state;
    }
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

}