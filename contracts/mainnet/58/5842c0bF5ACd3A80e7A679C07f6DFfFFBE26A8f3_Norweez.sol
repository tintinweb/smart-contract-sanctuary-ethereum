//███    ██  ██████  ██████  ██     ██ ███████ ███████ ███████ 
//████   ██ ██    ██ ██   ██ ██     ██ ██      ██         ███  
//██ ██  ██ ██    ██ ██████  ██  █  ██ █████   █████     ███   
//██  ██ ██ ██    ██ ██   ██ ██ ███ ██ ██      ██       ███    
//██   ████  ██████  ██   ██  ███ ███  ███████ ███████ ███████ 

// @title: NORWEEZ
// @desc: 1st NFT Community Saving the Oceans & Seas an underwater metaverse 
// @url: http://norweez.com/
// @twitter: https://twitter.com/norweez
// @instagram: https://www.instagram.com/norweez                                                 
                                                            
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import './ERC721A.sol';
import './Ownable.sol';

contract Norweez is ERC721A, Ownable {  
    using Strings for uint256;
    string public _narwhalslink;
    uint256 public narwhals = 499;
    uint256 public max_per_wallet = 2;
   	constructor() ERC721A("Norweez", "NRWZ") {}

    address public a1;
    address public a2;
    address public a3;

    function setMaxperWallet(uint256 newLimit) public onlyOwner {
        max_per_wallet = newLimit;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _narwhalslink;
    }

    function NarwhalLink(string memory parts) external onlyOwner {
        _narwhalslink = parts;
    }

    function norweezofOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    function mintNorweez(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        require( _amount > 0 && _amount <= max_per_wallet, "Can only mint between 1 and 2 tokens at once" );
        require( supply + _amount <= narwhals,            "Can't mint more than max supply" );
        require((balanceOf(msg.sender) + _amount) <= max_per_wallet, "You exceed the Norweez minting per wallet");

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