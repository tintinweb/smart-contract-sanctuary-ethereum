// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";


contract digi is Ownable, ERC721A, ReentrancyGuard {
    uint256 public  maxPer;
    mapping(uint256 => string) public OneSentence;
    uint256 public currentCollectSize;
    uint256 public oldCollectSize = 6;
    uint256 public firstMintSize = 6;
    constructor(uint256 maxBatchSize_, uint256 collectionSize_)
        ERC721A("OneSentence", "OneSentence", maxBatchSize_, collectionSize_)
    {
        maxPer = maxBatchSize_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    // uint256 price = 5000000000000000;
    // uint256 resetPrice = 500000000000000;
    uint256 price = 10000000000000000;
    uint256 resetPrice = 1000000000000000;
    uint256 secondPrice ;
    bool isOpen = false;
    bool isSecond = false;

    function publicSaleMint(string memory _data) external payable callerIsUser {
        require(totalSupply() + 1 <= firstMintSize, "reached max current supply");
        require(
            numberMinted(msg.sender) + 1 <= maxPer,
            "can not mint this many"
        );
        uint256 tid = _safeMint(msg.sender, 1);
        OneSentence[tid] = _data;
        refundIfOver(price);
    }

    function checkData(uint256 _tokenId) public view returns (string memory) {
        return OneSentence[_tokenId];
    }

    function resetData(uint256 _tokenId, string memory _data)
        external
        payable
        callerIsUser
    {
        require(ownerOf(_tokenId) == msg.sender, "not owner");
        require(isOpen == true, "can not reset data now");
        OneSentence[_tokenId] = _data;
        refundIfOver(resetPrice);
    }
    function setSecondPrice(uint256 _price) external onlyOwner {
        secondPrice = _price;
    }
    function startReset() external onlyOwner {
        isOpen = !isOpen;
    }
    function startSecondMint() external onlyOwner{
        isSecond = !isSecond;
    }
    function setCurrentCollectSize(uint256 number) external onlyOwner{
      require(number> currentCollectSize,"can not be smaller then currentCollectSize");
      oldCollectSize = currentCollectSize;
      currentCollectSize = number;
      maxPer++;

    }
    function secondMint(string memory _data) external payable callerIsUser returns(uint256) {
        require(isSecond == true,'not start');
        require(totalSupply() + 1 <= currentCollectSize, "reached max supply");
        require(
            numberMinted(msg.sender) + 1 <= maxPer,
            "can not mint this many"
        );
        uint256 tid = _safeMint(msg.sender, 1);
        uint256 tokenIdOwner = tid - oldCollectSize;
        require(ownerOf(tokenIdOwner) !=address(0),'can not mint now');
        address payable _owner = payable(ownerOf(tokenIdOwner));
        OneSentence[tid] = _data;
        refundIfOver2(secondPrice,_owner);
        return tid ;
    }

    function refundIfOver(uint256 cost) private {
        require(msg.value >= cost, "Need to send more ETH.");
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }
    function refundIfOver2(uint256 cost,address payable _owner) private {
        require(msg.value >= cost, "Need to send more ETH.");
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
        _owner.transfer(cost);
    }
    // // metadata URI
    string private _baseTokenURI;

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