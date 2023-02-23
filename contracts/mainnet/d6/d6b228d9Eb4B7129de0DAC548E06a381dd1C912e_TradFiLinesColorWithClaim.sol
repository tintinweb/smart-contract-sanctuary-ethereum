// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "./OperatorFilterer.sol";
import "./ERC2981.sol";

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

interface TradFiRenderer {
    function renderFromSeed(uint256 seed, uint256 extraCount, uint256 tokenId) external view returns(string memory svg);
}

contract TradFiLinesColorWithClaim is ERC721, ERC721Enumerable, Ownable, ERC2981, OperatorFilterer {
    using BokkyPooBahsDateTimeLibrary for uint;
    mapping (uint => uint) public tokenIdToCount;
    mapping (uint => uint) public tokenIdToSeed;
    mapping (uint => uint) public colorTokenIdToSeed;
    mapping (uint => uint) public tokenIdToPlacement;
    mapping (uint => uint) public dayToPlace;
    mapping (uint => string) public btcAddresses;
    mapping (uint => bool) public classicMode;
    address public tradFiRenderer;
    TradFiRenderer public tfr;
    TradFiLines public tfl;
    TradFiRendererColor public tfrc;
    bool public operatorFilteringEnabled;
    bool public renderersLocked = false;

    constructor(address tradFiRenderer, address tradFiLines, address tradFiRendererColor) ERC721("TradFiLines-C", "TFL-C") {
        tfr = TradFiRenderer(tradFiRenderer);
        tfl = TradFiLines(tradFiLines);
        tfrc = TradFiRendererColor(tradFiRendererColor);
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
    }

    function swapTFR(address tradFiRenderer) public onlyOwner {
        require(!renderersLocked, "Can't swap renderers anymore");
        tfr = TradFiRenderer(tradFiRenderer);
    }

    function swapTFRC(address tradFiRendererColor) public onlyOwner {
        require(!renderersLocked, "Can't swap renderers anymore");
        tfrc = TradFiRendererColor(tradFiRendererColor);
    }

    function lockRenderers() public onlyOwner {
        renderersLocked = true;
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

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721, IERC721) onlyAllowedOperator(from) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        require(isWithinOpeningHours(), "Outside regular trading hours");
        tokenIdToCount[tokenId] += 1;
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
    
    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }    

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function getAdjustedTimestamp() public view returns(uint timestamp) {
        return subHours(block.timestamp, hoursToSub);
    } 
    function isWithinOpeningHours() public view returns(bool){
        uint timestamp = getAdjustedTimestamp();
        bool weekend = BokkyPooBahsDateTimeLibrary.isWeekEnd(timestamp);
        if(weekend) {
           return false;
        }

        uint hour = BokkyPooBahsDateTimeLibrary.getHour(timestamp);
        uint minute = BokkyPooBahsDateTimeLibrary.getMinute(timestamp);

        if(hour < 9 || hour > 15) {
            return false;
        }

        if(hour == 9 && minute < 30) {
            return false;
        }

        return true;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
   
    function subHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.subHours(timestamp, _hours);
    }

    receive() external payable {}
    
    function wrapClaim(uint tokenToWrap, string memory btcAddress) external {
        require(tfl.ownerOf(tokenToWrap) == msg.sender,"Sender is not the owner of the NFT.");
        uint timestamp = getAdjustedTimestamp();
        uint year;
        uint month;
        uint day;
        (year, month, day, , , ) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
        tokenIdToCount[tokenToWrap] = tfl.tokenIdToCount(tokenToWrap);
        tfl.safeTransferFrom(msg.sender, address(this), tokenToWrap);
        colorTokenIdToSeed[tokenToWrap] = uint(keccak256(abi.encodePacked(blockhash(block.number-1))));
        uint place = dayToPlace[day + month * 100 + year * 10000] += 1;
        tokenIdToPlacement[tokenToWrap] = place;
        _mint(msg.sender, tokenToWrap);
        btcAddresses[tokenToWrap] = btcAddress;
    }

     function toggleClassicMode(uint tokenId, bool on) external {
        require(ownerOf(tokenId) == msg.sender,"Sender is not the owner of the NFT.");
        classicMode[tokenId] = on;
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
        if(classicMode[_tokenId]){
            return
                string(
                    abi.encodePacked(
                        tfr.renderFromSeed(seed, tokenIdToCount[_tokenId], _tokenId)
                    )
                );
        }

        return
            string(
                abi.encodePacked(
                    tfrc.renderFromSeed(seed, colorSeed, tokenIdToCount[_tokenId], _tokenId, tokenIdToPlacement[_tokenId])
                )
            );
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}