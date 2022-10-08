// SPDX-License-Identifier: MIT
/*
 * 
░█████╗░███╗░░██╗██╗░░░██╗███╗░░░███╗░█████╗░██╗░░░░░░██████╗
██╔══██╗████╗░██║╚██╗░██╔╝████╗░████║██╔══██╗██║░░░░░██╔════╝
███████║██╔██╗██║░╚████╔╝░██╔████╔██║███████║██║░░░░░╚█████╗░
██╔══██║██║╚████║░░╚██╔╝░░██║╚██╔╝██║██╔══██║██║░░░░░░╚═══██╗
██║░░██║██║░╚███║░░░██║░░░██║░╚═╝░██║██║░░██║███████╗██████╔╝
╚═╝░░╚═╝╚═╝░░╚══╝░░░╚═╝░░░╚═╝░░░░░╚═╝╚═╝░░╚═╝╚══════╝╚═════╝░
█▓▓▓▀▀▀▓▓▓▓▓▓▓▓▀▀▀▓▓▓█    
▓▓█▌▒▒░░▀▀▀▀▀▀░░▒▒▐█▓▓
▓███▒░░▄╮░░░░▄╮░▒███▓
▓██▌▒░░▀╯░░░░▀╯░▒▐██▓
▓██▌▒░░░░░▄░░░░░░▒▐██▓
▓███▄▒░░╰───╯░░▒▄███▓


 */                                                                                                

pragma solidity >=0.7.0 <0.9.0;
import "./ERC721A.sol";

contract ss22 is ERC721A {
    address owner;
  
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    uint256 maxPerTx = 10;
    uint256 public cost = 0.003 ether;
    uint256 public maxSupply = 2222; // max supply
    mapping(address => uint256) public addrMinted;
    
    modifier onlyOwner {
        require(owner == msg.sender, "No Permission");
        _;
    }

    modifier verify(uint256 amount) {
        uint256 need;
        if (addrMinted[msg.sender] > 1 ) {
            need = amount * cost;
        } else {
            need = (amount - 2) * cost;
        } 
        require(msg.value >= need, "Not enough ether");
        _;
    }

    constructor() ERC721A("ANYMAL2", "ANYM2") {
        owner = msg.sender;
        _mint(msg.sender, 2222);
    }

    function mint(uint256 amount) payable public verify(amount) {
        require(totalSupply() + amount <= maxSupply, "SoldOut");
        require(amount <= maxPerTx, "MaxPerTx");
        addrMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

   function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked("ipfs://bafybeicyzliage2jscwrsw6bslcliml4hzfzysyxbvmp7esve3d4sqflf4/", _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}