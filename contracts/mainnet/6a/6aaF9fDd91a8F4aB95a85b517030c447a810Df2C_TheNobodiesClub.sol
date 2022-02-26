// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";



//  ________  __                        __    __            __                        __  __                             ______   __            __       
// /        |/  |                      /  \  /  |          /  |                      /  |/  |                           /      \ /  |          /  |      
// $$$$$$$$/ $$ |____    ______        $$  \ $$ |  ______  $$ |____    ______    ____$$ |$$/   ______    _______       /$$$$$$  |$$ | __    __ $$ |____  
//    $$ |   $$      \  /      \       $$$  \$$ | /      \ $$      \  /      \  /    $$ |/  | /      \  /       |      $$ |  $$/ $$ |/  |  /  |$$      \ 
//    $$ |   $$$$$$$  |/$$$$$$  |      $$$$  $$ |/$$$$$$  |$$$$$$$  |/$$$$$$  |/$$$$$$$ |$$ |/$$$$$$  |/$$$$$$$/       $$ |      $$ |$$ |  $$ |$$$$$$$  |
//    $$ |   $$ |  $$ |$$    $$ |      $$ $$ $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |$$    $$ |$$      \       $$ |   __ $$ |$$ |  $$ |$$ |  $$ |
//    $$ |   $$ |  $$ |$$$$$$$$/       $$ |$$$$ |$$ \__$$ |$$ |__$$ |$$ \__$$ |$$ \__$$ |$$ |$$$$$$$$/  $$$$$$  |      $$ \__/  |$$ |$$ \__$$ |$$ |__$$ |
//    $$ |   $$ |  $$ |$$       |      $$ | $$$ |$$    $$/ $$    $$/ $$    $$/ $$    $$ |$$ |$$       |/     $$/       $$    $$/ $$ |$$    $$/ $$    $$/ 
//    $$/    $$/   $$/  $$$$$$$/       $$/   $$/  $$$$$$/  $$$$$$$/   $$$$$$/   $$$$$$$/ $$/  $$$$$$$/ $$$$$$$/         $$$$$$/  $$/  $$$$$$/  $$$$$$$/  
                                                                                                                                                      
                                                                                                                                                      
                                                                                                                                                      

                                                                                        


contract TheNobodiesClub is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    
    string private baseURI;
    string private previewURI;
    string constant private baseExtension = ".json";
    
    uint256 public reservedCounter;
    uint256 public maxSupply = 5500;
    uint256 public constant cost = 0.06 ether;
    uint256 public constant reservedLimit = 100; 
    uint256 public constant transactionLimit = 2;
    uint256 public constant whitelistLimit = 2;

    bool private contractState = false;
    bool private revealed = false;
    bool private whitelistMintState = true; 

    bytes32 private whitelistRootHash; 


    //whitelist mint
    mapping(address => uint256) public whitelistMintCounter;

    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }


    constructor(bytes32 _initWhitelistRootHash,string memory _initBaseURI, string memory _initPreviewURI) ERC721A("The Nobodies Club", "TNC"){
        whitelistRootHash = _initWhitelistRootHash;
        baseURI = _initBaseURI;
        previewURI = _initPreviewURI;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getTotalSupply() public view returns(uint256) {
        return totalSupply();
    }

    function getContractState() public view returns(bool) {
        return contractState;
    }

    function getRevealedState() public view returns(bool){
        return revealed;
    }

    function getWhitelistMintState() public view returns(bool) {
        return whitelistMintState;
    }



    //PUBLIC FUNCTIONS 
    //Whitelist mint
    function whitelistMint (bytes32[] calldata _merkleProof, uint256 _mintAmount) external payable callerIsUser {
        require(contractState, "Contract is disabled");
        require(whitelistMintState, "Whitelist minting period is already over");
        require(_mintAmount <= transactionLimit, "Each transaction only allowed up to 2 mints.");
        require(totalSupply() + _mintAmount <= maxSupply, "Total Supply Exceeded");

        //Perform checks to see if the whitelisted user has mint before (<2) [during presale]
        require(whitelistMintCounter[msg.sender] + _mintAmount <= whitelistLimit, "Each whitelist is only entitled to 2 mints.");

        //Verify if the user is whitelisted
        require(MerkleProof.verify(_merkleProof, whitelistRootHash, keccak256(abi.encodePacked(msg.sender))), "You are not eligible for pre-sale!");

        require(msg.value >= cost * _mintAmount, "Insufficient fund in your wallet");
        whitelistMintCounter[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    //Public mint
    function publicMint(uint256 _mintAmount) external payable callerIsUser {
        require(contractState, "Contract is disabled");
        require(!whitelistMintState, "Whitelist minting period is NOT over yet");
        require(_mintAmount <= transactionLimit, "Each transaction only allowed up to 2 mints");
        require(totalSupply() + _mintAmount <= maxSupply, "Total Supply Exceeded");

        require(msg.value >= cost * _mintAmount, "Insufficient fund in your wallet");
        _safeMint(msg.sender, _mintAmount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if(!revealed){
            return previewURI;
        }
        
        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }


    //OWNER FUNCTIONS
    //Reserved mint
    function reservedMint(uint256 _mintAmount) external payable callerIsUser onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "Total Supply Exceeded");
        require(reservedCounter + _mintAmount <= reservedLimit, "Reserved Limit Exceeded");
        reservedCounter += _mintAmount;
        _safeMint(msg.sender, _mintAmount);

    }


    //SET FUNCTIONS 
    function setRootHash(bytes32 _newWhitelistRootHash) external onlyOwner{
        whitelistRootHash = _newWhitelistRootHash;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPreviewURI(string memory _newPreviewURI) external onlyOwner{
        previewURI = _newPreviewURI;
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setWhitelistMint() external onlyOwner {
        whitelistMintState = true;
    }

    function setPublicMint() external onlyOwner {
        whitelistMintState = false;
    }


    //TOGGLE FUNCTION
    function toggleContract() external onlyOwner {
        contractState = !contractState;
    }

    //REVEAL FUNCTION
    function reveal() external onlyOwner {
        revealed = true;
    }


    function withdraw() external payable onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }



}