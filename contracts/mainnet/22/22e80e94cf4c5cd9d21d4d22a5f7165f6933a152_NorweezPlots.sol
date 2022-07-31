//  ______     ______     ______     ______     __   __        ______   __         ______     ______   ______        ______     __  __        __   __     ______     ______     __     __     ______     ______     ______    
// /\  __ \   /\  ___\   /\  ___\   /\  __ \   /\ "-.\ \      /\  == \ /\ \       /\  __ \   /\__  _\ /\  ___\      /\  == \   /\ \_\ \      /\ "-.\ \   /\  __ \   /\  == \   /\ \  _ \ \   /\  ___\   /\  ___\   /\___  \   
// \ \ \/\ \  \ \ \____  \ \  __\   \ \  __ \  \ \ \-.  \     \ \  _-/ \ \ \____  \ \ \/\ \  \/_/\ \/ \ \___  \     \ \  __<   \ \____ \     \ \ \-.  \  \ \ \/\ \  \ \  __<   \ \ \/ ".\ \  \ \  __\   \ \  __\   \/_/  /__  
//  \ \_____\  \ \_____\  \ \_____\  \ \_\ \_\  \ \_\\"\_\     \ \_\    \ \_____\  \ \_____\    \ \_\  \/\_____\     \ \_____\  \/\_____\     \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \__/".~\_\  \ \_____\  \ \_____\   /\_____\ 
//   \/_____/   \/_____/   \/_____/   \/_/\/_/   \/_/ \/_/      \/_/     \/_____/   \/_____/     \/_/   \/_____/      \/_____/   \/_____/      \/_/ \/_/   \/_____/   \/_/ /_/   \/_/   \/_/   \/_____/   \/_____/   \/_____/      

// @title: NORWEEZ OCEAN PLOTS part of Norweez Collection
// @desc: 1st NFT Community Saving the Oceans & Seas an underwater metaverse 
// @url: http://norweez.com/
// @twitter: https://twitter.com/norweez
// @instagram: https://www.instagram.com/norweez                                                 
                                                            
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import './ERC721A.sol';
import './Ownable.sol';

contract NorweezPlots is ERC721A, Ownable {  
    using Strings for uint256;
    string public _oceanplotURI;
    uint256 public oceanplot = 10000;
    uint256 public price = 0.055 ether;
    uint256 public max_per_wallet = 50;

    address public a1;
    address public a2;
    address public a3;


    constructor() ERC721A("NorweezPlots", "NWOCP") {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _oceanplotURI;
    }

    function OceanPlotLink(string memory parts) external onlyOwner {
        _oceanplotURI = parts;
    }

    function morePerWallet(uint256 newMax ) external onlyOwner {
        max_per_wallet = newMax;
    }


    function UpdatePrice(uint256 nowprice) external onlyOwner {
        price = nowprice;
    }


    function PlotofOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    function getPlot(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        require((balanceOf(msg.sender) + _amount) <= max_per_wallet, "You exceed the Norweez minting per wallet");
        require( _amount > 0 && _amount <= max_per_wallet, "Too many mints at once" );
        require( supply + _amount <= oceanplot,  "Can't mint more than max supply" );
        require( msg.value == price * _amount, "Wrong amount of ETH sent" );
        _safeMint(msg.sender, _amount);
    }


    function setTeamAddresses(address[] memory _a) public onlyOwner {
        a1 = _a[0];
        a2 = _a[1];
        a3 = _a[2];
    }

    function withdrawTeam(uint256 amount) public payable onlyOwner {
        uint256 percent = amount / 100;
        require(payable(a1).send(percent * 40));
        require(payable(a2).send(percent * 30));
        require(payable(a3).send(percent * 30));
    }
}