// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;




// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
// import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./IERC721.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Enumerable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Context.sol";
import "./IERC165.sol";
import "./ERC165.sol";
import "./Ownable.sol";


contract MyNFTContract is ERC721, Ownable{
    using Strings for uint256;

    string private baseURI;
    string private previewURI;
    // string constant private baseExtension = ".json";

    uint256 public costPrice = 0.06 ether;
    uint256 public maxSupply = 10;
    uint256 public circulatingSupply = 0;
    uint256 public constant transactionLimit = 2;
    uint256 public constant whitelistWalletLimit = 2;
    uint256 private constant reserved = 50;




    bool public isContractActive = false;
    bool public isRevealed = false;
    bool public isWhitelistMintActive = true;

    mapping(address => uint256) public whitelistWalletCount; //TEMPORARY SOLUTION (NEED TO TRY MERKLE TREE TO STORE WHITELIST)

    address[] public whitelistedAddresses;

    constructor(string memory _name, string memory _symbol, string memory _initBaseURI, string memory _initPreviewUri) ERC721(_name, _symbol){
        previewURI = _initPreviewUri;
        setBaseURI(_initBaseURI);
        
        
        //Mint the reserved first
        //mint(reserved); 
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

// ********** PUBLIC FUNCTIONS **********

    function mint(uint256 _mintAmount) public payable {
        require(isContractActive, "Smart contract is currently not running");
        require(tx.origin == msg.sender, "Contract buying is not allowed");
        require(circulatingSupply + _mintAmount <= maxSupply, "Total supply exceeded");

        if(msg.sender != owner()) {
            require(_mintAmount > 0 && _mintAmount <= transactionLimit, "You can only mint 2 per transaction");
            //********** WHITELIST CHECKS **********
            if(isWhitelistMintActive){
                require(isUserWhiteListed(msg.sender), "You are not whitelisted"); 
                require(whitelistWalletCount[msg.sender] < whitelistWalletLimit, "You have reached the maximum whitelist minting limit");
                whitelistWalletCount[msg.sender] += _mintAmount;
            }

            require(msg.value >= costPrice * _mintAmount, "Insufficient fund in your wallet");
        }

        for (uint256 counter = 1; counter <= _mintAmount; counter++){
            circulatingSupply +=1;
            _safeMint(msg.sender, circulatingSupply);
        }

    }



    function tokenURI(uint256 tokenId) public view virtual override returns(string memory){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(!isRevealed){ //Art is not revealed yet.
            return previewURI;
        }

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

    function isUserWhiteListed(address _user) public view returns(bool) {
        for(uint256 counter = 0; counter<whitelistedAddresses.length; counter++){
            if(whitelistedAddresses[counter] == _user){
                return true;
            }
        }
        return false;
    }

// ********** OWNER FUNCTIONS (STANDARD CONTRACT SETTINGS) **********
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPreviewURI(string memory _newPreviewURI) public onlyOwner {
         previewURI = _newPreviewURI;
     }

    function setCostPrice(uint256 _newPrice) public onlyOwner {
        costPrice = _newPrice;
    }

    function setContractState() public onlyOwner {
        isContractActive = !isContractActive;
    }

    function reveal() public onlyOwner {
        isRevealed = true;
    }

    function setSupplyAmount(uint256 _newMaxSupply) public onlyOwner {
        require(_newMaxSupply <= 5500, "Invalid supply amount");
        maxSupply = _newMaxSupply;
    }

    function withdraw() public payable onlyOwner {
        (bool result,) = payable(owner()).call{value: address(this).balance}("");
        require(result, "Transaction failed");
    }

// ********** OWNER FUNCTIONS (STANDARD WHITELIST SETTINGS) **********
    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function setWhitelistOrPublicMint() public onlyOwner {
        isWhitelistMintActive = !isWhitelistMintActive;
    }



    
}