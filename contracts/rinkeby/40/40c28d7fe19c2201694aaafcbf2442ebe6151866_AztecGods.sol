// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract AztecGods is Ownable, ERC721 {
    using Strings for uint256;

    address private verificationAddr;
    string public baseURI = "ipfs://";
    string public baseExtension = ".json";
    mapping(uint256 => bool) public DNAexists;
    mapping(uint256 => string) public CID;
    mapping(string => uint256) public CIDToTokenId;
    bytes32 public MERKLE_ROOT_FREE;
    bytes32 public MERKLE_ROOT_PAID;
    mapping(uint256 => bool) internal claimedBitMapFree;
    mapping(uint256 => bool) internal claimedBitMapPaid;
    uint256 public cost = 0.05 ether;
    uint256 public totalSupply = 0;
    uint256 public maxSupply = 1000;
    bool public paused = false;
    bool public openMintPaused = false;
    bool public metadataFreezed = false;


    constructor(address _verificationAddr, bytes32 _MERKLE_ROOT_FREE, bytes32 _MERKLE_ROOT_PAID) ERC721("AztecGods", "AZGODS") {
        verificationAddr = _verificationAddr;
        MERKLE_ROOT_FREE = _MERKLE_ROOT_FREE;
        MERKLE_ROOT_PAID = _MERKLE_ROOT_PAID;
    }

    function mint(address _to, string calldata ipfsCID, uint256 dna, bytes calldata signature) external payable {
        require(!paused);
        require(!openMintPaused);
        require(!DNAexists[dna]);
        require(totalSupply + 1 <= maxSupply);
        require(recover(_to, ipfsCID, dna, signature));

        if(msg.sender != owner()) {
            require(msg.value >= cost);
        }

        CID[totalSupply + 1] = ipfsCID;
        CIDToTokenId[ipfsCID] = totalSupply + 1;
        DNAexists[dna] = true;
        _mint(_to, totalSupply + 1);
        totalSupply++;
    }

    function mintMultiple(address _to, string[] calldata ipfsCIDs, uint256[] calldata dnas, bytes[] calldata signatures) external payable {
        require(!paused);
        require(!openMintPaused);
        require(totalSupply + ipfsCIDs.length <= maxSupply);

        if(msg.sender != owner()) {
            require(msg.value >= cost * ipfsCIDs.length );
        }

        for (uint i = 0; i < ipfsCIDs.length; i++) {
            require(!DNAexists[dnas[i]]);
            require(recover(_to, ipfsCIDs[i], dnas[i], signatures[i]));
            CID[totalSupply + 1] = ipfsCIDs[i];
            CIDToTokenId[ipfsCIDs[i]] = totalSupply + 1;
            _mint(_to, totalSupply + 1);
            DNAexists[dnas[i]] = true;
            totalSupply++;         
        }
    }

    function whitelistMint(address _to, string[] calldata ipfsCIDs, uint256[] calldata dnas, bytes[] calldata signatures, uint256 _mintAmount, uint256 index, bytes32[] calldata proof) external payable {
        require(!paused);
        require(totalSupply + _mintAmount <= maxSupply);
        require(!claimedBitMapPaid[index]);
        require(ipfsCIDs.length == _mintAmount);

        if(msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
        }

        bytes32 node = keccak256(abi.encodePacked(index, _to, _mintAmount));
        require(MerkleProof.verify(proof, MERKLE_ROOT_PAID, node), 'MerkleDistributor: Invalid proof.');
        claimedBitMapPaid[index] = true;

        for (uint256 i = 0; i < _mintAmount; i++) {
            require(recover(_to, ipfsCIDs[i], dnas[i], signatures[i]));
            require(!DNAexists[dnas[i]]);
            CID[totalSupply + 1] = ipfsCIDs[i];
            CIDToTokenId[ipfsCIDs[i]] = totalSupply + 1;
            _mint(_to, totalSupply + 1);
            DNAexists[dnas[i]] = true;
            totalSupply++;
        }
    }

    function freeMint(address _to, string[] calldata ipfsCIDs, uint256[] calldata dnas, bytes[] calldata signatures, uint256 _mintAmount, uint256 index, bytes32[] calldata proof) external {
        require(!paused);
        require(totalSupply + _mintAmount <= maxSupply);
        require(!claimedBitMapFree[index]);
        require(ipfsCIDs.length == _mintAmount);

        bytes32 node = keccak256(abi.encodePacked(index, _to, _mintAmount));
        require(MerkleProof.verify(proof, MERKLE_ROOT_FREE, node), 'MerkleDistributor: Invalid proof.');
        claimedBitMapFree[index] = true;

        for (uint256 i = 0; i < _mintAmount; i++) {
            require(recover(_to, ipfsCIDs[i], dnas[i], signatures[i]));
            require(!DNAexists[dnas[i]]);
            CID[totalSupply + 1] = ipfsCIDs[i];
            CIDToTokenId[ipfsCIDs[i]] = totalSupply + 1;
            _mint(_to, totalSupply + 1);
            DNAexists[dnas[i]] = true;
            totalSupply++;
        }
    }

    function recover(address user, string memory ipfsCID, uint256 dna, bytes memory signature) public view returns (bool) {
        require(signature.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        bytes32 hash =  keccak256(abi.encodePacked(user, ipfsCID, dna));
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hash));
        address signer = ecrecover(signedHash, v, r, s);
        return (signer == verificationAddr);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function checkClaimedFree(uint256 index) public view returns (bool){
        return claimedBitMapFree[index];
    }

    function checkClaimedPaid(uint256 index) public view returns (bool){
        return claimedBitMapPaid[index];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(!metadataFreezed) {
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, CID[tokenId]))
                : "";
        } else {
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
        }
        
    }

    function setTokenURI(uint256 tokenId, string calldata _newURI) external onlyOwner {
        CID[tokenId] = _newURI;
    }

    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function pauseOpenMint(bool _state) external onlyOwner {
        openMintPaused = _state;
    }

    function setVerificationAddr(address _newVerificationAddr) external onlyOwner{
        verificationAddr = _newVerificationAddr;
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setMerkleRootFree(bytes32 _newMerkleRoot) external onlyOwner {
        MERKLE_ROOT_FREE = _newMerkleRoot;
    }

    function setMerkleRootPaid(bytes32 _newMerkleRoot) external onlyOwner {
        MERKLE_ROOT_PAID = _newMerkleRoot;
    }

    function freezeMetadata(bool _state) external onlyOwner {
        metadataFreezed = _state;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string calldata _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setDNAExists(uint256[] calldata _dnas, bool _state) external onlyOwner {
        for (uint i = 0; i < _dnas.length; i++) {
            DNAexists[_dnas[i]] = _state;
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}