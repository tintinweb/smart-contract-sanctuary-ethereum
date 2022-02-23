//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Mint {
    string greet;
    address public owner = msg.sender;
    bool isMint;
    uint totalTransfers;
    uint priceMint = 0.1 ether;
    bool public isMintOpen;

    struct Whitelist {
        uint mintNumber;
        bool isWL;
    }

    event MintIsOpen();
    event ReceiveFunds(address _addr, uint _sum); 

    mapping (address => Whitelist) public whitelist;

    // The Ownable constructor sets the original `owner` of the contract to the sender account.
    constructor(){
        owner = msg.sender;
    }    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    } 

    function withdrawTo(address payable _to) public onlyOwner{
        _to.transfer(address(this).balance);
    }

    function addToWhitelist(address _addrWhitelist, uint _maxMint) public onlyOwner{
        whitelist[ _addrWhitelist].mintNumber = _maxMint;
        whitelist[ _addrWhitelist].isWL = true;
    }

    function removeFromWhitelist(address _addrWhitelist) public onlyOwner{
        delete(whitelist[ _addrWhitelist]);
    }

    function openMint() public onlyOwner{
        isMintOpen = true;
        emit MintIsOpen();
    }


    receive() external payable{
        require(isMintOpen && whitelist[msg.sender].isWL && msg.value % 100000000000000000 == 0 && msg.value <= priceMint * whitelist[msg.sender].mintNumber, "Send only Mint price");
        emit ReceiveFunds(msg.sender, msg.value);
        totalTransfers++;
    }
}