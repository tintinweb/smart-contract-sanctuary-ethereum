//SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;
import "./ERC721.sol";

contract MunnaApe is ERC721{
    address public owner;
    uint private counter;
    bool private guard;

    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner can call this function!");
        _;
    }

    modifier reEntrancyGuard(){
        require(!guard,"No ReEntrancy allowed!");
        guard = true;
        _;
        guard = false;
    }

    constructor(string memory _name,string memory _symbol, string memory _tokenUrl) ERC721(_name,_symbol,_tokenUrl){
        owner = msg.sender;
        counter = 0;
    }

    function mintToken() public payable returns(uint tokenId){
        require(msg.value >= TOKEN_PRICE,"Insufficient Funds Provided!");
        super._mintToken(msg.sender,counter);
        tokenId = counter;
        counter++;
    }

    function mintTokenTo(address _to) public payable isValidAddress(_to) returns(uint tokenId){
        require(msg.value >= TOKEN_PRICE,"Insufficient Funds Provided!");
        super._mintToken(_to,counter);
        tokenId = counter;
        counter++;
    }

    function withdraw(address _to) public onlyOwner reEntrancyGuard isValidAddress(_to) {
        require(address(this).balance > 0,"Contract has no balance!");
        (bool sent,) = _to.call{value: address(this).balance}("");
        require(sent,"Failed to Withdraw amount!");
    }

    function setMetadata(string memory _meta) public onlyOwner {
        tokenUrl = _meta;
    }
}