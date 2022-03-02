// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

abstract contract Balance {
    function balanceOf(address account) external virtual view returns (uint256);
}

contract ElfPrincessMintPass is ERC1155, Ownable {

    string public name; 

    string public symbol;

    Balance balance;

    uint256[] counters=[5,20,50];
    uint256[] rates=[0.25 ether,0.1 ether,0.05 ether];
    string baseURI;

    constructor(string memory _baseURI,string memory _name,string memory _symbol,address _address) ERC1155("https://d1rmz20ryvv1im.cloudfront.net/{id}.json") {
        baseURI=_baseURI;
        name=_name;
        symbol=_symbol;
        balance = Balance(_address);
    }

    function setURI(string memory _baseURI) public onlyOwner {
        baseURI=_baseURI;
    }

    function uri(uint256 tokenId) override public view returns (string memory)
    {
        return (string(abi.encodePacked(baseURI,Strings.toString(tokenId), '.json')));
    }

    function mint(uint256 id) public payable
    {
        require(id>0 && id<=counters.length,"Token id doesn't exists");
        uint256 index=id-1;
        require(counters[index]>0 , "Pass unavailable");

        uint256 amount=balance.balanceOf(msg.sender);
        if(amount>0)
        {
            if(amount>=2500000000000000000000000)
            {
                id=1;
            }else if(amount>=1000000000000000000000000)
            {
                id=2;
            }else if(amount>=100000000000000000000000)
            {
                id=3;
            }else{
                require(msg.value>=rates[index],"Not enough eth");
            }
        }else{
             require(msg.value>=rates[index],"Not enough eth");
        }
        counters[index] -=1;
        _mint(msg.sender, id, 1, "");
    }

    function getPassAvailable(uint256 id) public view returns(uint256)
    {
        require(id>0 && id<=counters.length,"Token id doesn't exists");
        uint256 index=id-1;
        return counters[index];
    }

    function withdrawFund() public onlyOwner
    {
        payable(msg.sender).transfer(address(this).balance);
    }
}