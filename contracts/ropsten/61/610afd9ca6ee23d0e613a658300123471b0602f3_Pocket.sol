// SPDX-License-Identifier: MIT
// ERC721S Contracts v1.0 Created by StarBit
pragma solidity ^0.8.4;

import "./ERC721S.sol";

contract Pocket is ERC721S {

    error NotFounder();
    error RefundProcessing();
    error RufundEnded();
    error FailToSendEther();
    error EtherNotEnough();
    error ZeroAmount();
    error NoRefund();
    
    address public immutable founder;
    uint256 public dutchAuctionPrice = 0.05 ether;
    uint256 public dutchAuctionTime = 200 minutes; 
    uint256 public discountRate = 0.001 ether;
    uint256 public minimumPrice;
    uint256 private constant fees = 0.001 ether;
    uint256 private immutable publicSaleStart = 1654916400; // 2022/6/11 11:00
    uint256 private immutable publicSaleEnd = 1655276400;   // 2022/6/15 15:00
    uint256 private immutable refundEnd = 1655280000;       // 2022/6/15 16:00

    string private _baseURI;
    string private JSON = ".json";

    mapping (address => uint) private buyerPrice;

    constructor() ERC721S("POCKET", "pocket", 10) {
        founder = _msgSender();

    }
    
    modifier onlyOwner() {
        if (_msgSender() != founder)
            revert NotFounder();
        _;
    }

    function getPrice() public view returns (uint256) {
        uint discount = (block.timestamp - publicSaleStart) / dutchAuctionTime;
        return (dutchAuctionPrice - (discount * discountRate) < 0) ? 0 : dutchAuctionPrice - (discount * discountRate);
    }

    function claimFunds() public onlyOwner {
        if (block.timestamp < refundEnd)
            revert RefundProcessing();
        sendValue(payable(founder), address(this).balance);
    }

    function mint(uint amount) public payable {
        uint price = getPrice();

        if (amount == 0)
            revert ZeroAmount();
        if (msg.value < price * amount)
            revert EtherNotEnough(); 
        if (price < minimumPrice) 
            minimumPrice = price;

        buyerPrice[_msgSender()] = price;
        _safeMint(_msgSender(), amount);

    }

    function processRefunds() public {
        if (block.timestamp > refundEnd)
            revert RufundEnded();
        uint refunds = buyerPrice[_msgSender()] - minimumPrice;
        if (refunds == 0)
            revert NoRefund();
        sendValue(payable(_msgSender()), refunds+fees);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        if (success == false)
            revert FailToSendEther();
    }

    function setBaseURI(string calldata baseURI) public override {
        _baseURI = baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_requireMinted(tokenId) == false) 
            revert TokenDoesNotExist();
    
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, _toString(tokenId), JSON)) : "";
    }
    
}