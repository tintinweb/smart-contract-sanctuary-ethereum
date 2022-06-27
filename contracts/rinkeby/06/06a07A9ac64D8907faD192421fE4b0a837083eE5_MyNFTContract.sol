// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


contract MyNFTContract is ERC721A, Ownable, ReentrancyGuard {

    //Wallet mint counter
    address[] public whitelistedAddresses;
    mapping(address => uint256) public mintCounter;


    uint256 public constant reservedLimit = 200;
    uint256 public constant maxSupply = 6000;
    uint256 public constant cost = 0.01 ether;
    uint256 public reservedCounter;

    bool public revealed = false;
    bool public mintState = false;
    bool public whitelistMintState = true;

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

    function publicMint(uint256 _amount) external payable callerIsUser nonReentrant {
        require(mintState, "Mint is disabled");
        require(!whitelistMintState, "Only whitelisted addresses can mint");
        require(totalSupply() + _amount <= maxSupply, "Total supply exceeded");
        require(mintCounter[msg.sender] + _amount <= 2 , "Each wallet can only mint 2");

        //User have NOT mint before
        if(mintCounter[msg.sender] == 0) {
            require(msg.value == cost * (_amount-1), "Insufficient funds");
            mintCounter[msg.sender] += _amount;
            _mint(msg.sender, _amount);
        }

        //User has minted before
        else {
            require(msg.value == cost * _amount, "Insufficient Funds");
            mintCounter[msg.sender] += _amount;
             _mint(msg.sender, _amount);
        }

    }


    function whitelistMint(uint256 _amount) external payable callerIsUser nonReentrant {
        require(mintState, "Mint is disabled");
        require(whitelistMintState, "Whitelist minting has ended");
        require(totalSupply() + _amount <= maxSupply, "Total supply exceeded");
        require(isAddressWhitelisted(msg.sender), "Address is not whitelisted");
        require(mintCounter[msg.sender] + _amount <= 2, "Each wallet can only mint 2");

        //User has NOT minted before
        if(mintCounter[msg.sender] == 0) {
            require(msg.value == cost * (_amount-1), "Insufficient Funds");
            mintCounter[msg.sender] += _amount;
            _mint(msg.sender, _amount);
        }

        //User has minted before
        else {
            require(msg.value == cost * _amount, "Insufficient Funds");
            mintCounter[msg.sender] += _amount;
            _mint(msg.sender, _amount);
        }
    }


    //Check if a wallet address is whitelisted
    function isAddressWhitelisted(address _address) internal view returns(bool) {
        for(uint counter = 0; counter <= whitelistedAddresses.length; counter++) {
            if(whitelistedAddresses[counter] == _address) {
                return true;
            }
        }

        return false;
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

    function setWhitelistMintState() external onlyOwner {
        whitelistMintState = !whitelistMintState;
    }

    function setWhitelistedAddresses(address[] memory _addresses) external onlyOwner {
        whitelistedAddresses = _addresses;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }



}