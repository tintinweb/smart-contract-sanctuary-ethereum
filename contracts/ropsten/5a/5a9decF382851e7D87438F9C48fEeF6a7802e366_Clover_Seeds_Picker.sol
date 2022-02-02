pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./IContract.sol";
import "./SafeMath.sol";

contract Clover_Seeds_Picker is Ownable {
    using SafeMath for uint256;

    uint256 public totalCloverFieldCarbonCanMint = 990; // 33% for total Clover Field
    uint256 public totalCloverFieldPearlCanMint = 990; // 33% for total Clover Field
    uint256 public totalCloverFieldRubyCanMint = 990; // 33% for total Clover Field
    uint256 public totalCloverFieldDiamondCanMint = 30; // 1% for total Clover Field

    uint256 public totalCloverYardCarbon = 9900; // 33% for total Clover Yard
    uint256 public totalCloverYardPearl = 9900; // 33% for total Clover Yard
    uint256 public totalCloverYardRuby = 9900; // 33% for total Clover Yard
    uint256 public totalCloverYardDiamond = 300; // 1% for total Clover Yard

    uint256 public totalCloverPotCarbon = 99000; // 33% for total Clover Pot
    uint256 public totalCloverPotPearl = 99000; // 33% for total Clover Pot
    uint256 public totalCloverPotRuby = 99000; // 33% for total Clover Pot
    uint256 public totalCloverPotDiamond = 3000; // 1% for total Clover Pot

    uint256 public totalCloverFieldCarbonMinted;
    uint256 public totalCloverFieldPearlMinted;
    uint256 public totalCloverFieldRubyMinted;
    uint256 public totalCloverFieldDiamondMinted;

    uint256 public totalCloverYardCarbonMinted;
    uint256 public totalCloverYardPearlMinted;
    uint256 public totalCloverYardRubyMinted;
    uint256 public totalCloverYardDiamondMinted;

    uint256 public totalCloverPotCarbonMinted;
    uint256 public totalCloverPotPearlMinted;
    uint256 public totalCloverPotRubyMinted;
    uint256 public totalCloverPotDiamondMinted;

    uint256[] private layersCarbon;
    uint256[] private layersPearl;
    uint256[] private layersRuby;

    uint256[] private percentage;

    address public Clover_Seeds_Controller;
    address public Clover_Seeds_NFT_Token;

    constructor(address _Seeds_NFT_Token, address _Clover_Seeds_Controller) {
        Clover_Seeds_Controller = _Clover_Seeds_Controller;
        Clover_Seeds_NFT_Token = _Seeds_NFT_Token;

        addCarbonLayers(0);
        addCarbonLayers(1);
        addCarbonLayers(2);
        addCarbonLayers(3);
        
        addParts2(1);
        addParts2(2);
        addParts2(3);
        
        addParts3(2);
        addParts3(3);
    }

    function setPercentage(uint256[] memory _per) public onlyOwner {
        
        for (uint256 i = 0; i < _per.length; i++) {
            percentage.push(i);
        }
    }

    function reSetPercentage() public onlyOwner {
        percentage = new uint256[](0);
    }

    function randomNumber() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, percentage)));
    }

    function getLuckyNumber() public view returns (uint256) {
        uint256 luckyNumber = randomNumber() % percentage.length;
        return luckyNumber;
    }

    function addCarbonLayers(uint256 id) private {
        layersCarbon.push(id);
    }

    function addParts2(uint256 id) private {
        layersPearl.push(id);
    }

    function addParts3(uint256 id) private {
        layersRuby.push(id);
    }

    function random() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, layersCarbon)));
    }

    function random2() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, layersPearl)));
    }

    function random3() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, layersRuby)));
    }

    function setSeeds_NFT_Token(address _Seeds_NFT_Token) public onlyOwner {
        Clover_Seeds_NFT_Token = _Seeds_NFT_Token;
    }

    function setClover_Seeds_Controller(address _Clover_Seeds_Controller) public onlyOwner {
        Clover_Seeds_Controller = _Clover_Seeds_Controller;
    }

    function randomLayer(uint256 tokenId) public returns (bool) {
        require(msg.sender == Clover_Seeds_NFT_Token, "Clover_Seeds_Picker: You are not Clover_Seeds_NFT_Token..");
        uint256 index = random() % layersCarbon.length;

        if (tokenId <= 3e3 && index == 0 && totalCloverFieldCarbonMinted == totalCloverFieldCarbonCanMint) {
            index = random2() % layersPearl.length;
        }

        if (tokenId <= 3e3 && index == 1 && totalCloverFieldPearlMinted == totalCloverFieldPearlCanMint) {
            index = random3() % layersRuby.length;
        }

        if (tokenId <= 3e3 && index == 2 && totalCloverFieldRubyMinted == totalCloverFieldRubyCanMint) {
            index = 3;
        }

        if (tokenId > 3e3 && tokenId <= 33e3 && index == 0 && totalCloverYardCarbonMinted == totalCloverYardCarbon) {
            index = random2() % layersPearl.length;
        }

        if (tokenId > 3e3 && tokenId <= 33e3 && index == 1 && totalCloverYardPearlMinted == totalCloverYardPearl) {
            index = random3() % layersRuby.length;
        }

        if (tokenId > 3e3 && tokenId <= 33e3 && index == 2 && totalCloverYardRubyMinted == totalCloverYardRuby) {
            index = 3;
        }

        if (tokenId > 33e3 && tokenId <= 333e3 && index == 0 && totalCloverPotCarbonMinted == totalCloverPotCarbon) {
            index = random2() % layersPearl.length;
        }

        if (tokenId > 33e3 && tokenId <= 333e3 && index == 1 && totalCloverPotPearlMinted == totalCloverPotPearl) {
            index = random3() % layersRuby.length;
        }

        if (tokenId > 33e3 && tokenId <=333e3 && index == 2 && totalCloverPotRubyMinted == totalCloverPotRuby) {
            index = 3;
        }
        
        if (tokenId <= 3e3 && index == 0 && totalCloverFieldCarbonMinted < totalCloverFieldCarbonCanMint) {
            totalCloverFieldCarbonMinted = totalCloverFieldCarbonMinted.add(1);
            require(IContract(Clover_Seeds_Controller).addAsCloverFieldCarbon(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverFieldCarbon..");
        }

        if (tokenId <= 3e3 && index == 1 && totalCloverFieldPearlMinted < totalCloverFieldPearlCanMint) {
            totalCloverFieldPearlMinted = totalCloverFieldPearlMinted.add(1);
            require(IContract(Clover_Seeds_Controller).addAsCloverFieldPearl(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverFieldPearl..");
        }

        if (tokenId <= 3e3 && index == 2 && totalCloverFieldRubyMinted < totalCloverFieldRubyCanMint) {
            totalCloverFieldRubyMinted = totalCloverFieldRubyMinted.add(1);
            require(IContract(Clover_Seeds_Controller).addAsCloverFieldRuby(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverFieldCarbon..");
        }

        if (tokenId <= 3e3 && index == 3 && totalCloverFieldDiamondMinted < totalCloverFieldDiamondCanMint) {
            totalCloverFieldDiamondMinted = totalCloverFieldDiamondMinted.add(1);
            require(IContract(Clover_Seeds_Controller).addAsCloverFieldDiamond(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverFieldDiamond..");
        }

        if (tokenId > 3e3 && tokenId <= 33e3 && index == 0 && totalCloverYardCarbonMinted < totalCloverYardCarbon) {
            totalCloverYardCarbonMinted = totalCloverYardCarbonMinted.add(1);
            require(IContract(Clover_Seeds_Controller).addAsCloverYardCarbon(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverYardCarbon..");
        }

        if (tokenId > 3e3 && tokenId <= 33e3 && index == 1 && totalCloverYardPearlMinted < totalCloverYardPearl) {
            totalCloverYardPearlMinted = totalCloverYardPearlMinted.add(1);
            require(IContract(Clover_Seeds_Controller).addAsCloverYardPearl(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverYardPearl..");
        }

        if (tokenId > 3e3 && tokenId <= 33e3 && index == 2 && totalCloverYardRubyMinted < totalCloverYardRuby) {
            totalCloverYardRubyMinted = totalCloverYardRubyMinted.add(1);
            require(IContract(Clover_Seeds_Controller).addAsCloverYardRuby(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverYardRuby..");
        }

        if (tokenId > 3e3 && tokenId <= 33e3 && index == 3 && totalCloverYardDiamondMinted < totalCloverYardDiamond) {
            totalCloverYardDiamondMinted = totalCloverYardDiamondMinted.add(1);
            require(IContract(Clover_Seeds_Controller).addAsCloverYardDiamond(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverYardDiamond..");
        }

        if (tokenId > 33e3 && tokenId <= 333e3 && index == 0 && totalCloverPotCarbonMinted < totalCloverPotCarbon) {
            totalCloverPotCarbonMinted = totalCloverPotCarbonMinted.add(1);
            require(IContract(Clover_Seeds_Controller).addAsCloverPotCarbon(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverPotCarbon..");
        }

        if (tokenId > 33e3 && tokenId <= 333e3 && index == 1 && totalCloverPotPearlMinted < totalCloverPotPearl) {
            totalCloverPotPearlMinted = totalCloverPotPearlMinted.add(1);
            require(IContract(Clover_Seeds_Controller).addAsCloverPotPearl(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverPotPearl..");
        }

        if (tokenId > 33e3 && tokenId <=333e3 && index == 2 && totalCloverPotRubyMinted < totalCloverPotRuby) {
            totalCloverPotRubyMinted = totalCloverPotRubyMinted.add(1);
            require(IContract(Clover_Seeds_Controller).addAsCloverPotRuby(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverPotRuby..");
        }

        if (tokenId > 33e3 && tokenId <=333e3 && index == 3 && totalCloverPotDiamondMinted < totalCloverPotDiamond) {
            totalCloverPotDiamondMinted = totalCloverPotDiamondMinted.add(1);
            require(IContract(Clover_Seeds_Controller).addAsCloverPotDiamond(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverPotDiamond..");
        }

        return true;
    }
    
    // function to allow admin to transfer *any* BEP20 tokens from this contract..
    function transferAnyBEP20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "SEED$ Picker: amount must be greater than 0");
        require(recipient != address(0), "SEED$ Picker: recipient is the zero address");
        IContract(tokenAddress).transfer(recipient, amount);
    }
}