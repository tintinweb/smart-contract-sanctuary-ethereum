// SPDX-License-Identifier: GPL-3.0


/*                                                                                                                                                                                                        
            __                       __                  __ 
 /  |     |/  |              |     |/  |                /   
(   | ___ |   | ___  ___  ___|     |   | ___       ___ (___ 
|   )|   )|   )|___)|   )|   )     |   )|___) \  )|   )    )
|__/ |  / |__/ |__  |__/||__/      |__/ |__    \/ |__/| __/ 
                                                                     
 */                                                                                                

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";

contract UNDeadDevaS is ERC721A {
    address _deployer;
    uint256 _price = 0.001 ether;
    uint256 _maxSupply = 777; // max supply
    uint256 _maxPerTx = 10;

    
    modifier onlyOwner {
        require(_deployer == msg.sender, "No Permission");
        _;
    }
    constructor() ERC721A("UNDeadDevaS", "UDS") {
        _deployer = msg.sender;
    }
    
    function undead(uint256 amount) payable public {
        require(amount <= _maxPerTx, "Exceed Deads");
        uint256 cost = amount * _price;
        require(msg.value >= cost, "Deva Need Ether");
        require(totalSupply() + amount <= _maxSupply, "Alive All");
        _safeMint(msg.sender, amount);
    }

    function dead(uint256 tokenid) public {
        require(ownerOf(tokenid) == msg.sender, "Not Your Deva");
        _burn(tokenid);
        _safeMint(msg.sender, 1);
    }

    function setcost(uint256 cost, uint8 maxper) public onlyOwner {
        _price = cost;
        _maxPerTx = maxper;
    }

    function maxSupply() public view returns (uint256){
        return _maxSupply;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        if (bytes(_baseURI()).length == 0) {
            return "ipfs://QmYMy2msZ9oWumf842dh6c8sNeQczazy4fkdsj2Bd6CQYN";
        }
        return string(abi.encodePacked(_baseURI(), _toString(tokenId)));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}