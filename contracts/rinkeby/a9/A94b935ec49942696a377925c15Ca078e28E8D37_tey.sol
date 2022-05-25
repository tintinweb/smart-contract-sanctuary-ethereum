// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";

contract tey is ERC721 {

    string public name = "testTEY";// ERC721Metadata 

    string public symbol= "TEY"; // ERC721Metadata

    uint256 MAX_TICKETS ;

    uint256 TicketPrice = 10000000000000000 wei;

    bool _saleOpen;

    modifier saleOpen ()
    {
        require(_saleOpen == true);
        _;
    }

    function mintTicket () public payable 
    {
        uint total = totalSupply();
        require(_saleOpen ==  true,"dev : It's not time to buy yet");
        require(msg.value == TicketPrice, "dev : Value is over or under price.");
        require(total <= MAX_TICKETS, "dev : You can not mint because the number of tickets is over");

        _mint(msg.sender,mintCount);
    }

    function ownerMint (string memory tokenUri_) public onlyOwner
    {
            uint total = totalSupply();
            require(total <= MAX_TICKETS, "dev : You can not mint because the number of tickets is over");

            _mint(_owner,mintCount);
            _tokenURIs [mintCount] = tokenUri_;
    }

    function setSaleStatus (bool status) public onlyOwner
    {
        _saleOpen = status;
    }

    function withdrawBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(_owner, balance);
    }
    
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    
    // Returns a URL that points to the metadata
    function tokenURI(uint256 tokenId) public view returns (string memory) { // ERC721Metadata
        require(_owners[tokenId] != address(0), "TokenId does not exist");
        return _tokenURIs[tokenId];
    }

    function setMaxTicket (uint256 _maxTicket) public onlyOwner
    {
        require(_maxTicket > 0 , "dev : The total number of tickets can not be less than 0");

        MAX_TICKETS = _maxTicket;
    }
    
    function supportsInterface(bytes4 interfaceId) public pure override returns(bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function totalSupply() public view returns (uint256) {
        return mintCount;
    }
}