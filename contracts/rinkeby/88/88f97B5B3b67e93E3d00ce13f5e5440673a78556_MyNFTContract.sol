// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


contract MyNFTContract is ERC721A, Ownable, ReentrancyGuard {

    //Wallet mint counter
    mapping(address => uint256) public mintCounter;


    uint256 public constant reservedLimit = 200;
    uint256 public constant maxSupply = 6000;
    uint256 public constant cost = 0.01 ether;
    uint256 public reservedCounter;

    bool public revealed = false;
    bool public mintState = false;

    string private baseURI;
    string private previewURI;


    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(string memory _initPreviewURI) ERC721A("My NFT Name", "MNN"){
        previewURI = _initPreviewURI;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns(string memory){
        require(_exists(tokenId), "ERC 721Metadata: URI query for nonexistent token");

        if(!revealed) {
            return previewURI;
        }

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), ".json")): "";
    }


    /*///////////////////////////////////////////////////////////////
                            USER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function mint(uint256 _amount) external payable callerIsUser nonReentrant {
        require(mintState, "Mint is disabled");
        require(totalSupply() + _amount <= maxSupply, "Total supply exceeded");
        require(mintCounter[msg.sender] + _amount <= 5 , "Each wallet can only mint 5");

        //User minted before
        if(mintCounter[msg.sender] >= 1) {
            require(msg.value == _amount * cost, "Insufficient funds");
            mintCounter[msg.sender] += _amount;
            _mint(msg.sender, _amount);
        }

        //User yet to mint
        else {
            require(msg.value == cost * (_amount-1), "Insufficient funds");
            mintCounter[msg.sender] += _amount;
             _mint(msg.sender, _amount);
        }

    }


    /*///////////////////////////////////////////////////////////////
                            ADMIN UTILITIES
    //////////////////////////////////////////////////////////////*/

    function reservedMint(uint256 _amount) external onlyOwner {
        require(reservedCounter + _amount <= reservedLimit, "Reserved limit exceeded");
        reservedCounter += _amount;
        _mint(msg.sender, _amount);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner{
        baseURI = _newBaseURI;
    }

    function setPreviewURI(string memory _newPreviewURI) external onlyOwner {
        previewURI = _newPreviewURI;
    }

    function setMintState() external onlyOwner { 
        mintState = !mintState;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }


    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }



}