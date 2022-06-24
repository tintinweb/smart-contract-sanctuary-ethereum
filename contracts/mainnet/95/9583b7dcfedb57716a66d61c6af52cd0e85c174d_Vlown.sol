// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

import "./ERC721.sol";
import "./AccessControl.sol";

contract Vlown is ERC721, AccessControl {
    string[] private claimArray;
    uint256 private stakePrice;
    uint256 private transferFee;
    mapping (string => uint256) private claimStringToTokenId;
    mapping (uint256 => uint256) private tokenToPrice;

    constructor(uint256 sp) ERC721("Vlown", "VLN") { 
        stakePrice = sp; //300000000000000; //0.0003 ether;
        transferFee = 100; //1%
    }

    function isTokenOwner(uint256 tokenId, address msgSender) external view returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return msgSender == owner;
    } 

    function isClaimAvailable(string memory _lat, string memory _lng) external view returns (bool) {
        bytes memory plotBytes = abi.encodePacked(_lat, ",", _lng);
        string memory claimString = string(plotBytes);
        return claimStringToTokenId[claimString] == uint256(0);
    }

    function getTokenId(string memory _lat, string memory _lng) external view returns (uint256) {
        bytes memory plotBytes = abi.encodePacked(_lat, ",", _lng);
        string memory claimString = string(plotBytes);
        require(claimStringToTokenId[claimString] != uint256(0), "Vlown: There is no claim therefore no tokenId.");
        return claimStringToTokenId[claimString];
    }

    function getSalePrice(string memory _lat, string memory _lng) external view returns (uint256) {
        bytes memory plotBytes = abi.encodePacked(_lat, ",", _lng);
        string memory claimString = string(plotBytes);
        uint256 tokenId = claimStringToTokenId[claimString];
        return tokenToPrice[tokenId];
    }

    function stakeClaim(string memory _lat, string memory _lng, uint256 _price) whenNotPaused external payable {
        require(msg.value == stakePrice, "Vlown: Cost to claim land must equal stake price.");
        validateInputs(_lat,_lng);
        //mint
        bytes memory plotBytes = abi.encodePacked(_lat, ",", _lng);
        string memory claimString = string(plotBytes);
        require(claimStringToTokenId[claimString] == uint256(0));

        claimArray.push(claimString);
        uint256 id = claimArray.length;
        claimStringToTokenId[claimString] = id;
        tokenToPrice[id] = _price;
        _safeMint(msg.sender, id);
        _setTokenURI(id,claimString);

        financialOfficerAddress.transfer(msg.value);
    }

    function purchaseLand(string memory _lat, string memory _lng, uint256 _price) whenNotPaused external payable {
        validateInputs(_lat,_lng);
        require(msg.value > 0, "Vlown: Purchase price cannot be zero. Use transfer for no cost ownership changes.");
        bytes memory plotBytes = abi.encodePacked(_lat, ",", _lng);
        string memory claimString = string(plotBytes);
        uint256 tokenId = claimStringToTokenId[claimString];

        require(msg.value >= tokenToPrice[tokenId], "Vlown: Amount offered must be >= price set by owner.");
        require((msg.value / 10000) * 10000 == msg.value, 'too small');
        uint256 toContract = msg.value * transferFee / 10000;
        uint256 toOwner = msg.value - toContract;

        address payable owner = payable(ERC721.ownerOf(tokenId));
        financialOfficerAddress.transfer(toContract);
        owner.transfer(toOwner);
        approveInternal(msg.sender, tokenId);
        transferFrom(owner, msg.sender, tokenId);
        tokenToPrice[tokenId] = _price;
        emit SaleComplete(claimString, toOwner, toContract);
    }

    function validateInputs(string memory _val, string memory _val2) internal pure returns(bool){ //9,true  10,false
        require(bytes(_val).length < 9, "value too large.");
        require(bytes(_val2).length < 10, "value too large.");
        uint s = bytes(_val)[0] == 0x2D ? 1 : 0; //-
        uint dPos = 0;
        bytes memory out = new bytes(bytes(_val).length);
        for(uint i = s; i < bytes(_val).length; i++){
            out[i] = bytes(_val)[i];
            if(out[i] < 0x2F || out[i] > 0x3A){
                if(out[i] == 0x2E){
                    dPos = i;
                } else {
                    require(false, "value contains invalid character.");
                }
            } 
            if(dPos > 0){
                require(out.length - 5 == dPos, "too much percision.");
                require(bytes(_val)[bytes(_val).length-1] == 0x35, "precision ends incorrectly.");
                uint len = dPos - s;
                require(len <= 2, "lat base too large, len > 2");
                if(len == 2){
                    if(out[s] == 0x39)
                        require(out[s+1] == 0x30, "lat base too large, 2nd pos not 0 when 1st is 9");
                }
            }
        }
        require(dPos != 0, "decimal place not found");

        s = bytes(_val2)[0] == 0x2D ? 1 : 0; //-
        dPos = 0;
        out = new bytes(bytes(_val2).length);
        for(uint i = s; i < bytes(_val2).length; i++){
            out[i] = bytes(_val2)[i];
            if(out[i] < 0x2F || out[i] > 0x3A){
                if(out[i] == 0x2E){
                    dPos = i;
                } else {
                    require(false, "value contains invalid character.");
                }
            } 
            if(dPos > 0){
                require(out.length - 5 == dPos, "too much percision.");
                require(bytes(_val2)[bytes(_val2).length-1] == 0x35, "precision ends incorrectly.");
                uint len = dPos - s;
                if(len == 3){
                    require(out[s] == 0x31, "lng base too large, 1st pos != 1");
                    require(out[s+1] > 0x2F && out[s+1] < 0x39, "lng base too large, 2nd pos not 0-8");
                    if(out[s] == 0x31 && out[s+1] == 0x38)
                        require(out[s+2] == 0x30, "lng base too large, 3rd pos not 0 when start with 18");
                }
            }
        }
        require(dPos != 0, "decimal place not found.");
        return true;
    }
    
    /*function calculateTransferFee(uint amount) external view returns(uint){
        require((amount / 10000) * 10000 == amount, 'too small');
        return amount * transferFee / 10000;
    }*/

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;
            uint256 vlownId;
            for (vlownId = 1; vlownId <= total; vlownId++) {
                if(ownerOf(vlownId) == _owner){
                    result[resultIndex] = vlownId;
                    resultIndex++;
                    //if(resultIndex == tokenCount)
                    //    return result;
                }
            }
            return result;
        }
    }

    function setTransferFee(uint amount) external onlyExecutiveOfficer {
        transferFee = amount;
    }

    function setStakePrice(uint256 amount) external onlyExecutiveOfficer {
        stakePrice = amount;
    }

    function setSalePrice(uint256 tokenId, uint256 price) external {
        address owner = ERC721.ownerOf(tokenId);
        require(_msgSender() == owner, "ERC721: approve caller is not owner.");
        require(price >= 0, "Vlown: Price must be positive number.");
        tokenToPrice[tokenId] = price;
        require(tokenToPrice[tokenId] == price, "Vlown: Price must be properly set.");
        approveInternal(financialOfficerAddress, tokenId);
        emit PriceSet(address(this), tokenToPrice[tokenId]);
    }

    event PriceSet(address indexed owner, uint256 price);
    event SaleComplete(string claim, uint256 price, uint256 fee);
}