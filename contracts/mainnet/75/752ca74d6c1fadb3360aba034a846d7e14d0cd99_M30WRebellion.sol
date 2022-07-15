// SPDX-License-Identifier: MIT
// CONTRACT ACTUALLY WROTE BY OUR CAT SCIENTISTS
// JUST KIDDING, WROTE BY HUMANS LOVING CATS
// BUT YEAH, CATS HELPED A BIT
// MEEOW
/*
    dMMMMMMMMb  dMMMMMP .aMMMb  dMP dMP dMP         dMMMMb  dMMMMMP dMMMMb  dMMMMMP dMP     dMP     dMP .aMMMb  dMMMMb 
   dMP"dMP"dMP dMP     dMP"dMP dMP dMP dMP         dMP.dMP dMP     dMP"dMP dMP     dMP     dMP     amr dMP"dMP dMP dMP 
  dMP dMP dMP dMMMP   dMP dMP dMP dMP dMP         dMMMMK" dMMMP   dMMMMK" dMMMP   dMP     dMP     dMP dMP dMP dMP dMP  
 dMP dMP dMP dMP     dMP.aMP dMP.dMP.dMP         dMP"AMF dMP     dMP.aMF dMP     dMP     dMP     dMP dMP.aMP dMP dMP   
dMP dMP dMP dMMMMMP  VMMMP"  VMMMPVMMP"         dMP dMP dMMMMMP dMMMMP" dMMMMMP dMMMMMP dMMMMMP dMP  VMMMP" dMP dMP 

                      WE ARE READY, WE ARE UNITED, WE MEOW WE ARE A REBELLION
*/

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract M30WRebellion is ERC721A, Ownable {
    bytes32 public merkleRoot;
    uint256 public constant maxSupply = 5000;
    uint256 public price = 0.005 ether;
    uint256 public maxMintAmountPerTx = 7;
    uint256 public freeSupply = 1000;
    string public baseURI = "ipfs://QmTSTNnVEFQAfuQPuNBbxofRFLuS9sWYJmBinmdeuake3q/";
    bool public whitelistMintEnabled = true;
    bool public paused = false;
    
    mapping(address => bool) public whitelistClaimed;
    mapping(address => uint256) nftPerWallet;

    constructor() ERC721A("M30W Rebellion", "M30W") {}

    modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= price * _mintAmount, "Insufficient funds!");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function startMint() external onlyOwner {
        paused = false;
    }

    function pauseMint() external onlyOwner {
        paused = true;
    }
    
    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) { 
    // Verify whitelist requirements
    require(whitelistMintEnabled, "M30WLIST sale is not enabled!");
    require(!whitelistClaimed[_msgSender()], "Address already claimed!");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
    }


    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory _updatedURI) public onlyOwner {
        baseURI = _updatedURI;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        price = _newCost;
    }

    function setFreeSupply(uint256 _newFreeSupply) public onlyOwner {
        freeSupply = _newFreeSupply;
    }


    modifier checkMint(uint256 _mintAmount) {
        require(!paused, "M30WINT IS PAUSED!");
        require(_mintAmount > 0);
        require(totalSupply() + _mintAmount <= maxSupply, "M30WExceed Max Supply");
        require(_mintAmount <= maxMintAmountPerTx, "M30WExceed Max Per Tx");
        if(totalSupply() >= freeSupply){
            require(msg.value >= _mintAmount * price, "M30WWWW Error in code 80! You need to send MEOWre ETH!");
        }
        _;
    }


    function m30wMint(uint256 _mintAmount) public payable checkMint(_mintAmount) {
        _safeMint(msg.sender, _mintAmount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner { 
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner { 
        whitelistMintEnabled = _state;
    }
    
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

}