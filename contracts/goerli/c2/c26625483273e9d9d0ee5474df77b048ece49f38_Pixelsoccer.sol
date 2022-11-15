//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Pixelsoccer is Ownable, ERC721A, ReentrancyGuard {
    string private _tokenBaseURI = "https://ipfs.io/ipfs/QmVN6ULVipVGMF6qvovnT15UVviLL7KQYBGtB5hbfhTG4p/";

    constructor() ERC721A("Pixelsoccer", "PIXELSOCCER") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function setBaseURI(string memory newURI) external onlyOwner {
        _tokenBaseURI = newURI;
    }

    function requireErrorKey(string memory key) internal pure returns (string memory){
        return string(abi.encodePacked('errorKey', key, 'errorKeyEnd'));
    }

    modifier checkOverflow(uint amount, uint value){
        require(amount + value >= amount, 'value can\'t overflow');
        _;
    }
    uint public startTime = block.timestamp;// + 5 minutes;

    function setStartTime(uint start) public onlyOwner {
        startTime = start;
    }

    uint public teamCurrentSupply = 232;

    uint public teamSoldSupply = 0;

    function setTeamCurrentSupply(uint count) public onlyOwner {
        teamCurrentSupply = count;
    }

    mapping(address => uint) public freeWhiteList;

    uint public freeCurrentSupply = 120;

    uint public freeSoldSupply = 0;

    function setFreeCurrentSupply(uint count) public onlyOwner {
        freeCurrentSupply = count;
    }

    uint public freeWhiteListPrice = 0 ether;

    uint public freeWhiteListStart = 1668654000;// 1668654000;
    uint public freeWhiteListEnd = 1668740400;// 1668740400;

    function setFreeWhiteListTime(uint start, uint end) public onlyOwner {
        freeWhiteListStart = start;
        freeWhiteListEnd = end;
    }

    event AddFreeWhiteList(address to, uint quota);

    function addFreeWhiteList(address[] memory addresses, uint[] memory tokenCounts) public onlyOwner returns (bool){
        for (uint i = 0; i < addresses.length; i++) {
            address to = addresses[i];
            uint tokenCount = tokenCounts[i];
            freeWhiteList[to] += tokenCount;
            emit AddFreeWhiteList(to, tokenCount);
        }
        return true;
    }

    mapping(address => uint) public payWhiteList;

    uint public payCurrentSupply = 4259;

    uint public paySoldSupply = 0;

    function setPayCurrentSupply(uint count) public onlyOwner {
        payCurrentSupply = count;
    }

    uint public payWhiteListPrice = 0.02 ether;

    function setPayWhiteListPrice(uint price) public onlyOwner {
        payWhiteListPrice = price;
    }

    uint public payWhiteListStart = 1668740400;// 1668740400;
    uint public payWhiteListEnd = 1668826800;// 1668826800;

    function setPayWhiteListTime(uint start, uint end) public onlyOwner {
        payWhiteListStart = start;
        payWhiteListEnd = end;
    }

    event AddPayWhiteList(address to, uint quota);

    function addPayWhiteList(address[] memory addresses, uint[] memory tokenCounts) public onlyOwner returns (bool){
        for (uint i = 0; i < addresses.length; i++) {
            address to = addresses[i];
            uint tokenCount = tokenCounts[i];
            payWhiteList[to] += tokenCount;
            emit AddPayWhiteList(to, tokenCount);
        }
        return true;
    }

    uint public publicPrice = 0.04 ether;

    uint public publicCurrentSupply = 1383;

    uint public publicSoldSupply = 0;

    function setPublicCurrentSupply(uint count) public onlyOwner {
        publicCurrentSupply = count;
    }

    function setPublicPrice(uint price) public onlyOwner {
        publicPrice = price;
    }

    uint public publicStart = 1668826800;// 1668826800;
    uint public publicEnd = 1668913200;//1668913200;

    function setPublicTime(uint start, uint end) public onlyOwner {
        publicStart = start;
        publicEnd = end;
    }

    function mint(address to, uint soldSupply, uint tokenCount) internal checkOverflow(soldSupply, tokenCount) {
        _safeMint(to, tokenCount);
    }

    function teamMint(address to, uint tokenCount) public onlyOwner {
        require(teamCurrentSupply > 0, requireErrorKey('Sold out'));
        require(teamCurrentSupply >= tokenCount, requireErrorKey('Remaining insufficient'));
        teamCurrentSupply -= tokenCount;
        teamSoldSupply += tokenCount;
        mint(to, teamSoldSupply, tokenCount);
    }

    function userMint(uint tokenCount) external payable {
        uint currentTime = block.timestamp;
        bool isSoldOut = currentTime > publicEnd;
        require(!isSoldOut, requireErrorKey('Sold out'));
        require(tokenCount > 0, requireErrorKey('Quantity cannot be 0'));
        bool isFree = currentTime >= freeWhiteListStart && currentTime <= freeWhiteListEnd;
        bool isPay = currentTime >= payWhiteListStart && currentTime <= payWhiteListEnd;
        bool isPublic = currentTime >= publicStart && !isSoldOut;
        require(isFree || isPay || isPublic, requireErrorKey('Not on sale'));
        uint cost = tokenCount * (isPublic ? publicPrice : (isFree ? freeWhiteListPrice : payWhiteListPrice));
        uint totalPrice = msg.value;
        require(cost <= totalPrice, requireErrorKey('Insufficient fees'));
        address sender = msg.sender;

        if (cost < totalPrice)
            payable(sender).transfer(totalPrice - cost);
        if (cost > 0)
            payable(owner()).transfer(cost);
        require(isPublic || (!isPublic && (isFree ? freeWhiteList : payWhiteList)[sender] >= tokenCount), requireErrorKey('Maximum number of purchases exceeded!'));
        if (!isPublic)
            (isFree ? freeWhiteList : payWhiteList)[sender] -= tokenCount;
        if (isPublic) {
            require(publicCurrentSupply > 0, requireErrorKey('Sold out'));
            require(publicCurrentSupply >= tokenCount, requireErrorKey('Remaining insufficient'));
            publicCurrentSupply -= tokenCount;
            publicSoldSupply += tokenCount;
            mint(sender, publicSoldSupply, tokenCount);
        } else if (isFree) {
            require(freeCurrentSupply > 0, requireErrorKey('Sold out'));
            require(freeCurrentSupply >= tokenCount, requireErrorKey('Remaining insufficient'));
            freeCurrentSupply -= tokenCount;
            freeSoldSupply += tokenCount;
            mint(sender, freeSoldSupply, tokenCount);
        } else {
            require(payCurrentSupply > 0, requireErrorKey('Sold out'));
            require(payCurrentSupply >= tokenCount, requireErrorKey('Remaining insufficient'));
            payCurrentSupply -= tokenCount;
            paySoldSupply += tokenCount;
            mint(sender, paySoldSupply, tokenCount);
        }
    }
}