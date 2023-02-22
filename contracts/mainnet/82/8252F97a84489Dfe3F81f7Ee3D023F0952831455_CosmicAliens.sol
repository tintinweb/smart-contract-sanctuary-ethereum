// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./ERC721A.sol";
import "./Ownable.sol";
/*

▄█▄    ████▄    ▄▄▄▄▄   █▀▄▀█ ▄█ ▄█▄        ██   █    ▄█ ▄███▄      ▄      ▄▄▄▄▄   
█▀ ▀▄  █   █   █     ▀▄ █ █ █ ██ █▀ ▀▄      █ █  █    ██ █▀   ▀      █    █     ▀▄ 
█   ▀  █   █ ▄  ▀▀▀▀▄   █ ▄ █ ██ █   ▀      █▄▄█ █    ██ ██▄▄    ██   █ ▄  ▀▀▀▀▄   
█▄  ▄▀ ▀████  ▀▄▄▄▄▀    █   █ ▐█ █▄  ▄▀     █  █ ███▄ ▐█ █▄   ▄▀ █ █  █  ▀▄▄▄▄▀    
▀███▀                      █   ▐ ▀███▀         █     ▀ ▐ ▀███▀   █  █ █            
                          ▀                   █                  █   ██            
                                             ▀                                     
*/
contract CosmicAliens is ERC721A,Ownable{
    string private _baseURIstr;
    uint256 private _maxSupply;

    uint constant NUMBER_OF_TOKENS_ALLOWED_PER_TX = 10;
    uint constant NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS = 20;
    // 
    address FOUNDER_1 = 0xd5ab0F722ac6278eBA2a0f8a362b75A9995e271c;
    address ARTIST = 0x6E13C20049b417f74aD6ded8E7dF6Fc6cB3ff7C2;
    address TEAM_1 = 0x61A11f49073193528C22CA10E291C02C125892d9;
    address TEAM_2 = 0xDaA9399d0d2Ca03b6BBccd7e67B1e9567fCcbDD5;
    address TEAM_3 = 0x86B29FCAb81bD24e78a2E94d9484fA07ba1cb164;
    //1st sale
    uint256 private _startTimestamp;

    constructor(
        uint256 startTimestamp,
        uint256 maxSupply,
        string memory baseURIstr
    ) ERC721A("NFT_721ATimeLimited", "TL721A") {
        _startTimestamp = startTimestamp;
        _maxSupply = maxSupply;
        _baseURIstr = baseURIstr;
    }
    
    receive() external payable {    }

    function mint(address to, uint256 quantity)external payable{
        require(totalSupply() < _maxSupply,"Max supply");
        require(totalSupply() + quantity < _maxSupply, "Exceeds total supply");
        require(_startTimestamp < block.timestamp,"Sale haven't started");
        require(msg.value >= getPrice()*quantity,"Insufficient funds");
        require(quantity <= NUMBER_OF_TOKENS_ALLOWED_PER_TX,"Too many requested");
        require(balanceOf(msg.sender) + quantity <= NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS,"Exceeds allowance");
        return _safeMint(to,quantity);
    }
    function getPrice()public view returns(uint256){
        if(totalSupply()<500){
            return 5e14;//000 0000 0000 0000;
        }else if(totalSupply()<5000){
            return 5e15;
        }
        return 1e16;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),'.json')) : '';
    }
    function _baseURI() internal view override returns (string memory) {
        return _baseURIstr;
    }
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(FOUNDER_1, (balance * 65) / 100);
        _withdraw(ARTIST, (balance * 10) / 100);
        _withdraw(TEAM_1, (balance * 7) / 100);
        _withdraw(TEAM_2, (balance * 7) / 100);
        _withdraw(TEAM_3, (balance * 7) / 100);
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}