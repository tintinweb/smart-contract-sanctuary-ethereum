//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*$$$$$$$ /$$                            /$$$$$$  /$$   /$$              
|__  $$__/| $$                           /$$__  $$|__/  | $$              
   | $$   | $$$$$$$  /$$   /$$  /$$$$$$ | $$  \__/ /$$ /$$$$$$   /$$   /$$
   | $$   | $$__  $$| $$  | $$ /$$__  $$| $$      | $$|_  $$_/  | $$  | $$
   | $$   | $$  \ $$| $$  | $$| $$  \ $$| $$      | $$  | $$    | $$  | $$
   | $$   | $$  | $$| $$  | $$| $$  | $$| $$    $$| $$  | $$ /$$| $$  | $$
   | $$   | $$  | $$|  $$$$$$/|  $$$$$$$|  $$$$$$/| $$  |  $$$$/|  $$$$$$$
   |__/   |__/  |__/ \______/  \____  $$ \______/ |__/   \___/   \____  $$
                               /$$  \ $$                         /$$  | $$
                              |  $$$$$$/                        |  $$$$$$/
                               \______/                          \______*/

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract ThugCityNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.0001 ether;
    uint256 public maxSupply = 500;
    uint256 public maxMintAmount = 50;
    uint256 public maxWhitelistSupply = 100;
    mapping(address => bool) public managers;
    bool public paused = false;
    bool public whitelistOnly = false;
    mapping(uint256 => bool) private _isCop;
    bytes32 public merkleRoot = 0x58b1883e836262d7f20bdf141d83c33b2ef1557f4ae81d10b9954df7bb3a0142;
    mapping(address => uint256) public whitelistClaimed;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function whitelistMint(address _to, uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable nonReentrant {
        uint256 supply = totalSupply();
        require(!paused); // Require not paused
        require(whitelistOnly);
        require(_mintAmount > 0); // Require minting at least 1
        require(supply + _mintAmount <= maxWhitelistSupply); // Require whitelist supply not met

        if(msg.sender != owner()){
            require(msg.sender == _to); // Require sender minting to own address
            require(_mintAmount + whitelistClaimed[msg.sender] <= maxMintAmount, "Address already claimed maximum tokens!"); // Require user doesn't exceed max mint amount
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender)); // Encode sender address as leaf node
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!"); // Confirm leaf node on merkle tree
            whitelistClaimed[msg.sender] += _mintAmount; // Increment number of tokens claimed by whitelist user
            require(msg.value >= cost * _mintAmount, "Must send more ETH!"); // Require sufficient funds sent
            for (uint256 i = 1; i <= _mintAmount; i++) {
                _safeMint(_to, supply + i);
            }
        }else{
            for (uint256 i = 1; i <= _mintAmount; i++) {
                _safeMint(_to, supply + i);
            }
        }
    }

    function mint(address _to, uint256 _mintAmount) public payable nonReentrant {
        require(!whitelistOnly);
        uint256 supply = totalSupply();
        require(_mintAmount <= maxMintAmount,"You cannot mint this many NFTs!");
        require(supply + _mintAmount <= maxSupply, "Not enough NFTs!");
        if(msg.sender != owner()){
            require(msg.value >= cost * _mintAmount, "Must send more ETH!");
            for (uint256 i = 1; i <= _mintAmount; i++) {
                _safeMint(_to, supply + i);
            }
        }else{
            for (uint256 i = 1; i <= _mintAmount; i++) {
                _safeMint(_to, supply + i);
            }
        }
    }

    function setWhitelistOnly(bool _status) public onlyOwner {
        whitelistOnly = _status;
    }



    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function isCop(uint256 id) public view returns (bool) {
        return _isCop[id];
    }

    function setCopId(uint256 id, bool special) external onlyOwner {
        _isCop[id] = special;
    }

    function setCopIds(uint256[] calldata ids) public onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            _isCop[ids[i]] = true;
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        if (!managers[msg.sender])
            require(_isApprovedOrOwner(_msgSender(), tokenId),"ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function addManager(address _addr) external onlyOwner{
        managers[_addr] = true;
    }

    function removeManager(address _addr) external onlyOwner {
        managers[_addr] = false;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}