// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721AQueryable.sol';
import './Ownable.sol';
import './Strings.sol';

contract MyToken is  ERC721AQueryable,Ownable {
    using Strings for uint256;

    bool public active = true;
    bool public open = false;

    uint256 public mintTime = 1673974052;

    string baseURI; 
    string public baseExtension = ".json"; 

    string public NotRevealedUri = "https://cdn.ceshi.xyz/meta/mh544853b692ca0061eb0d5526e7c/anthills.json";


    uint256 public constant MAX_SUPPLY = 10; 
    uint256 public maxMintAmountPerTx = 5; 
    uint256 public price = 0.0001 ether; 


    mapping(uint256 => string) private _tokenURIs;

    address public OD = 0xBC0b6782181361b88dEcC8B4C3A50053B6a033ff;

    event CostLog(address indexed _from,uint256 indexed _amount, uint256 indexed _payment);

    constructor()
        ERC721A("MyToken", "MT")
    {
        setNotRevealedURI(NotRevealedUri);
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (open == false) {
            return NotRevealedUri;
        }

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

       
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        NotRevealedUri = _notRevealedURI;
    }

    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function flipOpen() public onlyOwner {
        open = !open;
    }

    function flipActive() public onlyOwner {
        active = !active;
    }

    function mint(uint256 _amount) external payable{
        require(active && block.timestamp >= mintTime, "Minting has not started");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Exceeded maximum supply");
        require(_amount <= maxMintAmountPerTx, "xceeds max per transaction");
        require(_amount * price <= msg.value,"Not enough ether sent");

        _safeMint(msg.sender, _amount);
        emit CostLog(msg.sender, _amount, msg.value);
    }


    function getTime() public view returns(uint256){
        return block.timestamp;
    }


    function setPrice(uint256 _amount) public onlyOwner {
        price = _amount;
    } 

    function setPerCostMint(uint256 _amount) public onlyOwner {
        maxMintAmountPerTx = _amount;
    }    

    function setMintTime(uint256 _mintTime) public onlyOwner {
        mintTime = _mintTime;
    }
 

    function setOD(address _address) public onlyOwner {
        OD = _address;
    } 

    function withdraw() public onlyOwner {
        (bool success, ) = payable(OD).call{value: address(this).balance}('');
        require(success);
    }

}