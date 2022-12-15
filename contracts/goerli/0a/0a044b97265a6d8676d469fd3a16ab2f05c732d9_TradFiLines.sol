// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

interface TradFiRenderer {
    function renderFromSeed(uint256 seed, uint256 extraCount, uint256 tokenId) external view returns(string memory svg);
}
contract TradFiLines is ERC721, ERC721Enumerable, Ownable {
    using BokkyPooBahsDateTimeLibrary for uint;
    string private _baseURIextended;
    uint256 public constant MAX_SUPPLY = 500;
    uint256 public constant MAX_PUBLIC_MINT = 10;
    bool public openForMinting = false;
 
    //Base Extension
    string public constant baseExtension = ".json";

    mapping(uint => uint) numberIndexes;
    mapping (uint => uint) started;
    mapping (uint => uint) public tokenIdToCount;
    mapping (uint => uint) public tokenIdToSeed;
    address public timestampContractAddress;
    uint256 public constant salePrice = 0.01 ether;
    address public tradFiRenderer;
    TradFiRenderer public tfr;


    constructor(address tradFiRenderer) ERC721("TradFiLines", "TFL") {
        tfr = TradFiRenderer(tradFiRenderer);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    bool public isDST = false;
    uint public hoursToSub = 5;
    function adjustDST() external {
        uint timestamp = subHours(block.timestamp, hoursToSub);
        uint month = getMonth(timestamp);
        if(month > 3 && month < 11) {
            isDST = true;
        } else {
            uint day = getDayOfWeek(timestamp);
            uint dayOfMonth = getDay(timestamp);
            if(month == 3) {
                if(dayOfMonth > 14) {
                    isDST = true;
                } else if(dayOfMonth < 8) {
                    isDST = false;
                } else {
                    if((dayOfMonth - day - 7) < 1) {
                        isDST = false;
                    } else {
                        isDST = true;
                    }
                }
            }
            if(month == 11) {
                if(dayOfMonth > 7) {
                    isDST = false;
                } else {
                    if((dayOfMonth - day) < 1) {
                        isDST = true;
                    } else {
                        isDST = false;
                    }
                }
            }
        }
        if(isDST) {
            hoursToSub = 4;
        } else {
            hoursToSub = 5;
        }
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721, IERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        uint timestamp = subHours(block.timestamp, hoursToSub);
        bool weekend = isWeekEnd(timestamp);
        uint hour = getHour(timestamp);
        uint minute = getMinute(timestamp);
        require(weekend == false, "Trading is closed on weekends");
        require(hour >= 9 && hour < 16, string(abi.encodePacked("Outside regular trading hours")));
        if(hour == 9) {
            require(minute > 29, "Outside regular trading hours");
        }
        tokenIdToCount[tokenId] += 1;
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function isWithinOpeningHours() public view returns(bool){
        uint timestamp = subHours(block.timestamp, hoursToSub);
        bool weekend = isWeekEnd(timestamp);
        uint hour = getHour(timestamp);
        uint minute = getMinute(timestamp);
        bool isWithinOpeningHours = true;
        if(weekend == true) {
            isWithinOpeningHours = false;
        }
        if(hour < 9 || hour > 16) {
            isWithinOpeningHours = false;
        }
        if(hour == 9 && minute < 30) {
            isWithinOpeningHours = false;
        }
        return isWithinOpeningHours;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      require(supply + n <= MAX_SUPPLY, "Would exceed max tokens");
      for (uint i = 0; i < n; i++) {
        uint seed = supply + i + uint(keccak256(abi.encodePacked(blockhash(block.number-1))));
        tokenIdToSeed[supply + i] = seed;
        _safeMint(msg.sender, supply + i);
      }
    }
    function openMint() public onlyOwner() {
        openForMinting = true;
    }
    
    function getHour(uint timestamp) public pure returns (uint hour) {
        hour = BokkyPooBahsDateTimeLibrary.getHour(timestamp);
    }
    function getMinute(uint timestamp) public pure returns (uint minute) {
        minute = BokkyPooBahsDateTimeLibrary.getMinute(timestamp);
    }
    function getDayOfWeek(uint timestamp) public pure returns (uint dayOfWeek) {
        dayOfWeek = BokkyPooBahsDateTimeLibrary.getDayOfWeek(timestamp);
    }
    function getMonth(uint timestamp) public pure returns (uint month) {
        month = BokkyPooBahsDateTimeLibrary.getMonth(timestamp);
    }
    function isWeekEnd(uint timestamp) public pure returns (bool weekEnd) {
        weekEnd = BokkyPooBahsDateTimeLibrary.isWeekEnd(timestamp);
    }
    function getDay(uint timestamp) public pure returns (uint day) {
        day = BokkyPooBahsDateTimeLibrary.getDay(timestamp);
    }
    function subHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subHours(timestamp, _hours);
    }
    
    function mint(uint numberOfTokens) payable public {
        uint256 supply = totalSupply();
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(supply + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(msg.value / numberOfTokens == salePrice, "Not the correct amount of ether");
        require(openForMinting == true, "Minting has not started yet");
        for (uint i = 0; i < numberOfTokens; i++) {
            uint seed = supply + i + uint(keccak256(abi.encodePacked(blockhash(block.number-1))));
            tokenIdToSeed[supply + i] = seed;
            _safeMint(msg.sender, supply + i);
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        ); 
        uint256 seed = tokenIdToSeed[_tokenId];
        return
            string(
                abi.encodePacked(
                    tfr.renderFromSeed(seed, tokenIdToCount[_tokenId], _tokenId)
                )
            );
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}