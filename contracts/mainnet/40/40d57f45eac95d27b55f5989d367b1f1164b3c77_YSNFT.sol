// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

contract YSNFT is Ownable, ReentrancyGuard, ERC721Enumerable {
    using Strings for uint256;

    string public baseTokenURI;
    bool public isPaused = false;

    uint256 public constant maxSupply = 1670;
    uint256 public constant price = 0.067 ether;
    uint256 public constant wlPrice = 0.06 ether;
    uint256 public constant mbPrice = 0.033 ether;
    address constant metaBoomAddr = 0x4C22D3B875437D43402F5B81aE4f61b8F764E1b1;

    uint256 public mbSaleStartTime = 1649674800;
    uint256 public mbSaleEndTime = 1649761199;

    uint256 public wlSaleStartTime = 1649764800;
    uint256 public wlSaleEndTime = 1649851199;

    uint256 public publicSaleStartTime = 1649854800;

    uint8 public mbAmountPerAddr = 3;
    uint8 public wlAmountPerAddr = 8;
    uint8 public amountPerAddr = 20;
    uint8 public amountPerTx = 5;
    uint16 public mbMaxSupply = 200;
    uint8 public airDropMaxSupply = 20;
    uint8 public totalAirdrop = 0;

    mapping(address => uint8) public holdedNumAry;
    mapping(address => bool) public whiteList;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) {
        baseTokenURI = _uri;
    }

    function publicSale(uint8 _purchaseNum)
        external
        payable
        onlyUser
        nonReentrant
    {
        require(!isPaused, "YSNFT: currently paused");
        require(
            block.timestamp >= publicSaleStartTime,
            "YSNFT: public sale is not started yet"
        );
        require(
            _purchaseNum <= amountPerTx,
            "YSNFT: can not purchase more than 5 each time"
        );
        require(
            (holdedNumAry[_msgSender()] + _purchaseNum) <= amountPerAddr,
            "YSNFT: Each Address can only purchase 20"
        );
        uint256 supply = totalSupply();
        require(
            (supply + _purchaseNum) <= (maxSupply - airDropMaxSupply),
            "YSNFT: reached max supply"
        );
        require(
            msg.value >= (price * _purchaseNum),
            "YSNFT: price is incorrect"
        );

        for (uint8 i = 1; i <= _purchaseNum; i++) {
            _safeMint(_msgSender(), supply + i);
        }
        holdedNumAry[_msgSender()] = holdedNumAry[_msgSender()] + _purchaseNum;
    }

    function whiteListSale(uint8 _purchaseNum)
        external
        payable
        onlyWhiteList
        onlyUser
        nonReentrant
    {
        require(!isPaused, "YSNFT: currently paused");
        require(
            block.timestamp >= wlSaleStartTime,
            "YSNFT: WhiteList sale is not started yet"
        );
        require(
            block.timestamp < wlSaleEndTime,
            "YSNFT: WhiteList sale is ended"
        );
        require(
            (holdedNumAry[_msgSender()] + _purchaseNum) <= wlAmountPerAddr,
            "YSNFT: Each Address can only hold 5"
        );
        uint256 supply = totalSupply();
        require(
            (supply + _purchaseNum) <= (maxSupply - airDropMaxSupply),
            "YSNFT: reached max supply"
        );
        require(
            msg.value >= (wlPrice * _purchaseNum),
            "YSNFT: price is incorrect"
        );
        for (uint8 i = 1; i <= _purchaseNum; i++) {
            _safeMint(_msgSender(), supply + i);
        }
        holdedNumAry[_msgSender()] = holdedNumAry[_msgSender()] + _purchaseNum;
    }

    function mbHolderSale(uint8 _purchaseNum)
        external
        payable
        onlyUser
        nonReentrant
    {
        require(!isPaused, "YSNFT: currently paused");
        require(
            block.timestamp >= mbSaleStartTime,
            "YSNFT: MB holder sale is not started yet"
        );
        require(
            block.timestamp < mbSaleEndTime,
            "YSNFT: MB holder sale is ended"
        );
        require(
            (holdedNumAry[_msgSender()] + _purchaseNum) <= mbAmountPerAddr,
            "YSNFT: Each Address can only hold 3"
        );
        uint256 supply = totalSupply();
        require(
            (supply + _purchaseNum) <= mbMaxSupply,
            "YSNFT: reached max supply"
        );
        require(
            msg.value >= (mbPrice * _purchaseNum),
            "YSNFT: price is incorrect"
        );
        ERC721 MetaBoom = ERC721(metaBoomAddr);
        require(
            MetaBoom.balanceOf(_msgSender()) > 0,
            "YSNFT: caller not Metaboom Holder"
        );

        for (uint8 i = 1; i <= _purchaseNum; i++) {
            _safeMint(_msgSender(), supply + i);
        }
        holdedNumAry[_msgSender()] = holdedNumAry[_msgSender()] + _purchaseNum;
    }

    function ownerMInt(address _addr, uint8 _amount) external onlyOwner {
        uint256 supply = totalSupply();
        require(
            (supply + _amount) <= (maxSupply - airDropMaxSupply),
            "YSNFT: reached max supply"
        );
        require(
            (holdedNumAry[_addr] + _amount) <= amountPerAddr,
            "YSNFT: Each Address can only hold 20"
        );

        for (uint8 i = 1; i <= _amount; i++) {
            _safeMint(_addr, supply + i);
        }
        holdedNumAry[_addr] = holdedNumAry[_addr] + _amount;
    }

    function ownerAirdropMInt(address _addr, uint8 _amount) external onlyOwner {
        require(
            (totalAirdrop + _amount) <= airDropMaxSupply,
            "YSNFT: reached max airdrop"
        );
        require(
            (holdedNumAry[_addr] + _amount) <= amountPerAddr,
            "YSNFT: Each Address can only hold 20"
        );
        uint256 supply = totalSupply();
        for (uint8 i = 1; i <= _amount; i++) {
            _safeMint(_addr, supply + i);
        }
        holdedNumAry[_addr] = holdedNumAry[_addr] + _amount;
        totalAirdrop = totalAirdrop + _amount;
    }

    modifier onlyWhiteList() {
        require(whiteList[_msgSender()], "YSNFT: caller not in WhiteList");
        _;
    }

    modifier onlyUser() {
        require(_msgSender() == tx.origin, "YSNFT: no contract mint");
        _;
    }

    function addBatchWhiteList(address[] memory _accounts) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            whiteList[_accounts[i]] = true;
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseTokenURI = _baseURI;
    }

    function setPause(bool _isPaused) external onlyOwner returns (bool) {
        isPaused = _isPaused;
        return isPaused;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }
}