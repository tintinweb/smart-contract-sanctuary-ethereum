// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

interface TradFiRendererColor {
    function renderFromSeed(uint256 seed, uint256 colorSeed, uint256 extraCount, uint256 tokenId, uint256 place) external view returns(string memory svg);
}

interface TradFiLines {
    function ownerOf(uint256 tokenId) external view returns(address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function tokenIdToSeed(uint256 seed) external view returns(uint256);
    function tokenIdToCount(uint256 seed) external view returns(uint256);
}

contract TradFiLinesColor is ERC721, ERC721Enumerable, Ownable {
    using BokkyPooBahsDateTimeLibrary for uint;
    bool public limitedWrapping = true;
    mapping (uint => uint) public tokenIdToCount;
    mapping (uint => uint) public tokenIdToSeed;
    mapping (uint => uint) public colorTokenIdToSeed;
    mapping (uint => uint) public tokenIdToPlacement;
    mapping (uint => mapping(uint => bool)) public validWrapWindows;
    mapping (uint => uint) public dayToPlace;
    address public tradFiRenderer;
    TradFiRendererColor public tfr;
    TradFiLines public tfl;


    constructor(address tradFiRenderer, address tradFiLines) ERC721("TradFiLines-C", "TFL-C") {
        tfr = TradFiRendererColor(tradFiRenderer);
        tfl = TradFiLines(tradFiLines);
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
        uint month = BokkyPooBahsDateTimeLibrary.getMonth(timestamp);
        if(month > 3 && month < 11) {
            isDST = true;
        } else {
            uint day = BokkyPooBahsDateTimeLibrary.getDayOfWeek(timestamp);
            uint dayOfMonth = BokkyPooBahsDateTimeLibrary.getDay(timestamp);
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
        require(isWithinOpeningHours(), "Outside regular trading hours");
        tokenIdToCount[tokenId] += 1;
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getAdjustedTimestamp() public view returns(uint timestamp) {
        return subHours(block.timestamp, hoursToSub);
    } 
    function isWithinOpeningHours() public view returns(bool){
        uint timestamp = getAdjustedTimestamp();
        bool weekend = BokkyPooBahsDateTimeLibrary.isWeekEnd(timestamp);
        if(weekend) {
            // return false;
        }

        uint hour = BokkyPooBahsDateTimeLibrary.getHour(timestamp);
        uint minute = BokkyPooBahsDateTimeLibrary.getMinute(timestamp);

        if(hour < 0 || hour > 24) {
            return false;
        }
        if(hour == 9 && minute < 30) {
            return false;
        }

        return true;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function toggleWrapping(bool limited) public onlyOwner() {
        limitedWrapping = limited;
    }
   
    function subHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subHours(timestamp, _hours);
    }

    function validateWrapWindow(uint hour, uint minute) public view {
        require(validWrapWindows[hour][minute], 'Not within any wrapping window');
    }

    function addWrapWindow(uint hour, uint minute) public onlyOwner {
        validWrapWindows[hour][minute] = true;
    }
    
    receive() external payable {}
    
    function wrap(uint tokenToWrap) external {
        uint timestamp = getAdjustedTimestamp();
        uint hour;
        uint minute;
        uint year;
        uint month;
        uint day;
        (year, month, day, hour, minute, ) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);

        if(limitedWrapping) {
            validateWrapWindow(hour, minute);
        }

        tfl.safeTransferFrom(msg.sender, address(this), tokenToWrap);
        tokenIdToCount[tokenToWrap] = tfl.tokenIdToCount(tokenToWrap);
        if(colorTokenIdToSeed[tokenToWrap] == 0 ) {
            colorTokenIdToSeed[tokenToWrap] = uint(keccak256(abi.encodePacked(blockhash(block.number-1))));
        }
        if(tokenIdToPlacement[tokenToWrap] == 0) {
            uint place = dayToPlace[day + month * 100 + year * 10000] += 1;
            tokenIdToPlacement[tokenToWrap] = place;
            if(place < 3) {
                if(place == 1) {
                    if(address(this).balance >= 0.10 ether) {
                        (bool sent, bytes memory data) = payable(msg.sender).call{value: 0.10 ether}("");
                        require(sent, "Failed to send Ether");
                    }
                } else if(place == 2) {
                    if(address(this).balance >= 0.05 ether) {
                        (bool sent, bytes memory data) = payable(msg.sender).call{value: 0.05 ether}("");
                        require(sent, "Failed to send Ether");
                    }
                }
            }
        }
        _mint(msg.sender, tokenToWrap);
    }

    function unwrap(uint tokenToUnwrap) public {
        require(msg.sender == ownerOf(tokenToUnwrap), "Not the owner of the token");
        tfl.safeTransferFrom(address(this), msg.sender, tokenToUnwrap);
        _burn(tokenToUnwrap);
        require(msg.sender == tfl.ownerOf(tokenToUnwrap), "Did not receive back the original TFL");
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
        uint256 seed = tfl.tokenIdToSeed(_tokenId);
        uint256 colorSeed = colorTokenIdToSeed[_tokenId];
        return
            string(
                abi.encodePacked(
                    tfr.renderFromSeed(seed, colorSeed, tokenIdToCount[_tokenId], _tokenId, tokenIdToPlacement[_tokenId])
                )
            );
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}