// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./console.sol";

contract TestAWP3 is Ownable, ERC721A, ReentrancyGuard {
    bytes32 private _ogMerkleRoot;
    bytes32 private _wlMerkleRoot;
    uint256 private _collectionSize;
    bool private _isMintActive = false;
    bool private _isRevealed = false;
    string private _baseTokenURI;
    address private _vaultAddress;
    address private _ownerAddress1;
    address private _ownerAddress2;
    address private _ownerAddress3;
    uint256 private _paidMintCost = 5000000000000000; // .005 Eth

    enum MintStateOptions{OG, WL, Public}
    MintStateOptions _mintState = MintStateOptions.OG;

    constructor(
        uint256 collectionSize,
        address vaultAddress,
        address ownerAddress1,
        address ownerAddress2,
        address ownerAddress3
        ) ERC721A("TestAWP3", "TestAWP3") {
            _collectionSize = collectionSize;
            _vaultAddress = vaultAddress;
            _ownerAddress1 = ownerAddress1;
            _ownerAddress2 = ownerAddress2;
            _ownerAddress3 = ownerAddress3;
    }

    mapping (address => uint) _ownerCount;
    mapping (address => uint) _ogOwnerTransactionCount;
    mapping (address => uint) _wlOwnerTransactionCount;
    mapping (address => uint) _freePublicMintOwnerTransactionCount;

    function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setIsMintActive(bool isMintActive) public onlyOwner {
        _isMintActive = isMintActive;
    }

    function getIsMintActive() public view returns (bool) {
        return _isMintActive;
    }

    function setIsRevealed(bool isRevealed) public onlyOwner {
        _isRevealed = isRevealed;
    }

    function getIsRevealed() public view returns (bool) {
        return _isRevealed;
    }

    function setMintState(MintStateOptions newMintState) public onlyOwner {
        _mintState = newMintState;
    }

    function getMintState() public view returns (MintStateOptions) {
        return _mintState;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPaidMintCost(uint256 newCost) public onlyOwner() 
    {
        _paidMintCost = newCost;
    }

    function setOGMerkleRoot(bytes32 ogMerkleRoot) external onlyOwner {
        _ogMerkleRoot = ogMerkleRoot;
    }

    function setWLMerkleRoot(bytes32 wlMerkleRoot) external onlyOwner {
        _wlMerkleRoot = wlMerkleRoot;
    }

    function isUserOG(bytes32[] calldata ogMerkleProof) public view returns (bool) {
        return MerkleProof.verify(ogMerkleProof, _ogMerkleRoot, toBytes32(msg.sender));
    }

    function didUserMintOG() public view returns (bool) {
        return _ogOwnerTransactionCount[msg.sender] == 1;
    }

    function isUserWL(bytes32[] calldata wlMerkleProof) public view returns (bool) {
        return MerkleProof.verify(wlMerkleProof, _wlMerkleRoot, toBytes32(msg.sender));
    }

    function didUserMintWL() public view returns (bool) {
        return _wlOwnerTransactionCount[msg.sender] == 1;
    }

    function didUserMintFreePublic() public view returns (bool) {
        return _freePublicMintOwnerTransactionCount[msg.sender] == 1;
    }

    function ownerMint(uint256 quantity) external payable callerIsUser {
        require(quantity > 0);
        require(
            totalSupply() + quantity <= _collectionSize,
            "sold out"
        );
        require(msg.sender == _vaultAddress || msg.sender == _ownerAddress1|| msg.sender == _ownerAddress2|| msg.sender == _ownerAddress3, "You're not an owner. Let's not try that again.");

        _safeMint(msg.sender, quantity);
    }

    function OGMint(uint256 quantity, bytes32[] calldata ogMerkleProof) external payable callerIsUser {
        require(isUserOG(ogMerkleProof) == true, "You are not an OG");
        require(_isMintActive, "Mint is not available at this time");
        require(_mintState == MintStateOptions.OG, "OG mint is not available at this time");
        require(_ogOwnerTransactionCount[msg.sender] < 1, "Each address may only perform one transaction in this phase of the mint");
        require(quantity > 0);
        require(quantity <= 3, "You cannot mint more than 3 TestAWP3 at this stage in the mint");
        require(
            totalSupply() + quantity <= _collectionSize,
            "sold out"
        );
        
        _safeMint(msg.sender, quantity);
        _ownerCount[msg.sender] += quantity;

        _ogOwnerTransactionCount[msg.sender] += 1;
        if (quantity > 1) {
            _wlOwnerTransactionCount[msg.sender] += 1;
        }
        if (quantity > 2) {
            _freePublicMintOwnerTransactionCount[msg.sender] += 1;
        }
    }

    function WLMint(uint256 quantity, bytes32[] calldata wlMerkleProof) external payable callerIsUser {
        require(isUserWL(wlMerkleProof) == true, "You are not a WL member");
        require(_isMintActive, "Mint is not available at this time");
        require(_mintState == MintStateOptions.WL, "WL mint is not available at this time");
        require(_wlOwnerTransactionCount[msg.sender] < 1, "Each address may only perform one transaction in this phase of the mint");
        require(quantity > 0);
        require(quantity <= 2, "You cannot mint more than 2 TestAWP3 at this stage in the mint");
        require(
            totalSupply() + quantity <= _collectionSize,
            "sold out"
        );
        
        _safeMint(msg.sender, quantity);
        _ownerCount[msg.sender] += quantity;
        _wlOwnerTransactionCount[msg.sender] += 1;
        if (quantity > 1) {
            _freePublicMintOwnerTransactionCount[msg.sender] += 1;
        }
    }

    function FreePublicMint(uint256 quantity) external payable callerIsUser {
        require(_isMintActive, "Mint is not available at this time");
        require(_mintState == MintStateOptions.Public, "Free Public mint is not available at this time");
        require(quantity > 0);
        require(quantity <= 1, "you cannot mint more than one Free TestAWP3. You can mint as many as you like through the PublicMint method.");
        require(
            totalSupply() + quantity <= _collectionSize,
            "sold out"
        );

        _safeMint(msg.sender, quantity);
        _ownerCount[msg.sender] += quantity;
        _freePublicMintOwnerTransactionCount[msg.sender] += 1;
    }

    function PublicMint(uint256 quantity) external payable callerIsUser {
        require(_isMintActive, "Mint is not available at this time");
        require(_mintState == MintStateOptions.Public, "Public mint is not available at this time");
        require(quantity > 0);
        require(quantity <= 10, "You cannot mint more than 10 TestAWP3 in a single transaction");
        require(
            totalSupply() + quantity <= _collectionSize,
            "sold out"
        );
        require(msg.value >= _paidMintCost * quantity, "not enough funds");

        _safeMint(msg.sender, quantity);
        _ownerCount[msg.sender] += quantity;
    }

     function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721A.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (bytes(_baseTokenURI).length == 0) {
            return "";
        }

        string memory tokenIdString = Strings.toString(tokenId);

        if (!_isRevealed) {
            return string(abi.encodePacked(_baseTokenURI, "/pre-reveal.json"));
        } else {
            return string(abi.encodePacked(_baseTokenURI, "/", tokenIdString));
        }
    }
}