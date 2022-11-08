// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

contract AOM_FANSI_LOFIHIFI_001 is Ownable, ReentrancyGuard, ERC721Enumerable {
    using Strings for uint256;

    string public baseTokenURI;
    bool public isPaused = false;

    uint256 public constant maxSupply = 95;
    uint256 public constant price = 0.15 ether;
    uint256 public constant wlPrice = 0.12 ether;
    
    address constant metaBoomAddr = 0x4C22D3B875437D43402F5B81aE4f61b8F764E1b1;
    
    uint256 public wlSaleStartTime = 1667914200;
    uint256 public wlSaleEndTime = 1668083400;
    
    uint256 public publicSaleStartTime = 1668087000;
    uint256 public publicSaleEndTime = 1668605400;
    
    uint8 public amountPerAddr = 3;
    uint8 public wlAmountPerAddr = 1;
    uint8 public bonusDrop = 0;
    uint8 public curSold = 0;
    uint16 public totalSold = 0;

    mapping(uint8 => bool) public bonusList;
    mapping(uint8 => mbBonus) public mbBonusList;
    mapping(address => uint8) public holdedNumAry;
    mapping(address => bool) public whiteList;

    struct mbBonus {
        address bonusHolder;
        uint16 bonusNo;
    }

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
        require(!isPaused, "Abel: currently paused");
        require(
            block.timestamp >= publicSaleStartTime,
            "Abel: public sale is not started yet"
        );
        require(
            (holdedNumAry[_msgSender()] + _purchaseNum) <= amountPerAddr,
            "Abel: Each Address can only purchase 3 sets"
        );
        require(
            (totalSold + _purchaseNum*3) <= maxSupply,
            "Abel: reached max supply"
        );
        require(
            msg.value >= (price * _purchaseNum),
            "Abel: price is incorrect"
        );

        for (uint8 i = 1; i <= _purchaseNum*3; i++) {
            _safeMint(_msgSender(), totalSold + i);
        }

        ERC721 MB = ERC721(metaBoomAddr);
        for (uint8 i = 0; i < _purchaseNum; i++) {
            if(bonusList[curSold + i + 1]){
                _safeMint(_msgSender(), maxSupply - bonusDrop);
                bonusDrop = bonusDrop + 1;
            }

            MB.safeTransferFrom(mbBonusList[curSold + i].bonusHolder, _msgSender(), mbBonusList[curSold + i].bonusNo);
        }
        holdedNumAry[_msgSender()] = holdedNumAry[_msgSender()] + _purchaseNum;
        curSold = curSold + _purchaseNum;
        totalSold = totalSold + _purchaseNum*3;
    }

    function whiteListSale(uint8 _purchaseNum)
        external
        payable
        onlyWhiteList
        onlyUser
        nonReentrant
    {
        require(!isPaused, "Abel: currently paused");
        require(
            block.timestamp >= wlSaleStartTime,
            "Abel: WhiteList sale is not started yet"
        );
        require(
            block.timestamp < wlSaleEndTime,
            "Abel: WhiteList sale is ended"
        );
        require(
            (holdedNumAry[_msgSender()] + _purchaseNum) <= wlAmountPerAddr,
            "Abel: Each Address can only hold 1 set"
        );
        require(
            (totalSold + _purchaseNum*3) <= maxSupply,
            "Abel: reached max supply"
        );
        require(
            msg.value >= (wlPrice * _purchaseNum),
            "Abel: price is incorrect"
        );
        for (uint8 i = 1; i <= _purchaseNum*3; i++) {
            _safeMint(_msgSender(), totalSold + i);
        }

        ERC721 MB = ERC721(metaBoomAddr);
        for (uint8 i = 0; i < _purchaseNum; i++) {
            if(bonusList[curSold + i + 1]){
                _safeMint(_msgSender(), maxSupply - bonusDrop);
                bonusDrop = bonusDrop + 1;
            }

            MB.safeTransferFrom(mbBonusList[curSold + i].bonusHolder, _msgSender(), mbBonusList[curSold + i].bonusNo);
        }
        holdedNumAry[_msgSender()] = holdedNumAry[_msgSender()] + _purchaseNum;
        curSold = curSold + _purchaseNum;
        totalSold = totalSold + _purchaseNum*3;
    }

    function ownerMInt(address _addr, uint8 _amount) external onlyOwner {
        require(
            (totalSold + _amount) <= maxSupply,
            "Abel: reached max supply"
        );

        for (uint8 i = 1; i <= _amount; i++) {
            _safeMint(_addr, totalSold + i);
        }
    }

    modifier onlyWhiteList() {
        require(whiteList[_msgSender()], "Abel: caller not on WhiteList");
        _;
    }

    modifier onlyUser() {
        require(_msgSender() == tx.origin, "Abel: no contract mint");
        _;
    }

    function addBatchWhiteList(address[] memory _accounts) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            whiteList[_accounts[i]] = true;
        }
    }

    function addBonusList(uint8[] memory _bonus) external onlyOwner {
        for (uint8 i = 0; i < _bonus.length; i++) {
            bonusList[_bonus[i]] = true;
        }
    }

    function setMBBonusList(address[] memory _bonusHolder, uint16[] memory _bonusNo) external onlyOwner {
        for (uint8 i = 0; i < _bonusHolder.length; i++) {
            mbBonusList[i].bonusHolder = _bonusHolder[i];
            mbBonusList[i].bonusNo = _bonusNo[i];
        }
    }

    function setWlStartTime(uint256 _time) external onlyOwner {
        wlSaleStartTime = _time;
    }

    function setWlEndTime(uint256 _time) external onlyOwner {
        wlSaleEndTime = _time;
    }

    function setPublicStartTime(uint256 _time) external onlyOwner {
        publicSaleStartTime = _time;
    }

    function setPublicEndTime(uint256 _time) external onlyOwner {
        publicSaleEndTime = _time;
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
            string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId),".json"));
    }
}