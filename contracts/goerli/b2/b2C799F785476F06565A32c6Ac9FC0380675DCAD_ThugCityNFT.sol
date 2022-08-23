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

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721Psi.sol";

contract ThugCityNFT is ERC721Psi, Ownable {
    
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.1 ether;
    uint256 public immutable maxSupply = 10001;
    uint256 public immutable maxMintAmount = 16;
    uint256 public immutable maxWhitelistSupply = 1001;
    uint256 public immutable devSupply = 101;
    mapping(address => bool) public managers;
    bool public paused = false;
    bool public whitelistOnly = true;
    mapping(uint256 => bool) private _isCop;
    bytes32 public merkleRoot;
    mapping(address => uint256) public whitelistClaimed;

    constructor() ERC721Psi("ThugCity", "THUGCITY") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    modifier callerIsUser() {
        require(msg.sender == tx.origin);
        _;
    }

    function whitelistMint(address _to, uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable callerIsUser {
        require(whitelistOnly && !paused);
        require(totalSupply() + _mintAmount < maxWhitelistSupply);
        require(_mintAmount + whitelistClaimed[msg.sender] < maxMintAmount, "Address already claimed maximum tokens!"); // Require user doesn't exceed max mint amount
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender)); // Encode sender address as leaf node
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!"); // Confirm leaf node on merkle tree
        whitelistClaimed[msg.sender] += _mintAmount; // Increment number of tokens claimed by whitelist user
        require(msg.value >= cost * _mintAmount, "Must send more ETH!"); // Require sufficient funds sent
        _safeMint(_to, _mintAmount);
    }

    function mint(address _to, uint256 _mintAmount) external payable callerIsUser {
        require(!whitelistOnly && !paused);
        require(_mintAmount < maxMintAmount,"You cannot mint this many NFTs!");
        require(totalSupply() + _mintAmount < maxSupply, "Not enough NFTs!");
        require(msg.value >= cost * _mintAmount, "Must send more ETH!");
        _safeMint(_to, _mintAmount);
    }

    function devMint(uint256 _mintAmount) external onlyOwner{
        require(totalSupply() < devSupply);
        require(totalSupply() + _mintAmount < devSupply);
        _safeMint(msg.sender, _mintAmount);
        
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

    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function isCop(uint256 id) public view returns (bool) {
        return _isCop[id];
    }

    function setCopIds(uint256[] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            _isCop[ids[i]] = true;
        }
    }

    function setThugIds(uint256[] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            _isCop[ids[i]] = false;
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

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
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