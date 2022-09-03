// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

contract AztecGods is Initializable, OwnableUpgradeable, ERC721Upgradeable {
    using StringsUpgradeable for uint256;
    using AddressUpgradeable for address;

    address private verificationAddr;
    string public baseURI;
    string public baseExtension;
    mapping(uint256 => bool) public DNAexists;
    mapping(uint256 => string) public CID;
    mapping(string => uint256) public CIDToTokenId;
    bytes32 public MERKLE_ROOT_FREE;
    bytes32 public MERKLE_ROOT_PAID;
    mapping(uint256 => uint256) public claimedBitMapFree;
    mapping(uint256 => uint256) public claimedBitMapPaid;
    uint256 public cost;
    uint256 public whitelistCost;
    uint256 public totalSupply;
    uint256 public maxSupply;
    bool public paused;
    bool public freeMintPaused;
    bool public wlMintPaused;
    bool public metadataFrozen;

    event minted(address user, uint256 dna, uint256 id);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _verificationAddr, bytes32 _MERKLE_ROOT_FREE, bytes32 _MERKLE_ROOT_PAID) initializer public {
        __ERC721_init("AztecGods", "AZGODS");
        __Ownable_init();
        verificationAddr = _verificationAddr;
        MERKLE_ROOT_FREE = _MERKLE_ROOT_FREE;
        MERKLE_ROOT_PAID = _MERKLE_ROOT_PAID;

        cost = 0.04 ether;
        whitelistCost = 0.02 ether;
        maxSupply = 3500;
        baseURI = "ipfs://";
        baseExtension = ".json";
    }

    function mint(address _to, string calldata ipfsCID, uint256 dna, bytes calldata signature) external payable {
        require(!paused);
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
        emit minted(_to, dna, totalSupply);
    }

    function mintMultiple(address _to, string[] calldata ipfsCIDs, uint256[] calldata dnas, bytes[] calldata signatures) external payable {
        require(!paused);
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
            emit minted(_to, dnas[i], totalSupply);       
        }
    }

    function whitelistMint(address _to, string[] calldata ipfsCIDs, uint256[] calldata dnas, bytes[] calldata signatures, uint256 _allowedAmount, uint256 _mintAmount, uint256 index, bytes32[] calldata proof) external payable {
        require(!wlMintPaused);
        require(totalSupply + _mintAmount <= maxSupply);
        require(claimedBitMapPaid[index] + _mintAmount <= _allowedAmount);
        require(ipfsCIDs.length == _mintAmount);

        if(msg.sender != owner()) {
            require(msg.value >= whitelistCost * _mintAmount);
        }

        bytes32 node = keccak256(abi.encodePacked(index, _to, _allowedAmount));
        require(MerkleProofUpgradeable.verify(proof, MERKLE_ROOT_PAID, node), 'MerkleDistributor: Invalid proof.');
        claimedBitMapPaid[index] += _mintAmount;

        for (uint256 i = 0; i < _mintAmount; i++) {
            require(recover(_to, ipfsCIDs[i], dnas[i], signatures[i]));
            require(!DNAexists[dnas[i]]);
            CID[totalSupply + 1] = ipfsCIDs[i];
            CIDToTokenId[ipfsCIDs[i]] = totalSupply + 1;
            _mint(_to, totalSupply + 1);
            DNAexists[dnas[i]] = true;
            totalSupply++;
            emit minted(_to, dnas[i], totalSupply);
        }
    }

    function freeMint(address _to, string[] calldata ipfsCIDs, uint256[] calldata dnas, bytes[] calldata signatures, uint256 _allowedAmount, uint256 _mintAmount, uint256 index, bytes32[] calldata proof) external {
        require(!freeMintPaused);
        require(totalSupply + _mintAmount <= maxSupply);
        require(claimedBitMapFree[index] + _mintAmount <= _allowedAmount);
        require(ipfsCIDs.length == _mintAmount);

        bytes32 node = keccak256(abi.encodePacked(index, _to, _allowedAmount));
        require(MerkleProofUpgradeable.verify(proof, MERKLE_ROOT_FREE, node), 'MerkleDistributor: Invalid proof.');
        claimedBitMapFree[index] += _mintAmount;

        for (uint256 i = 0; i < _mintAmount; i++) {
            require(recover(_to, ipfsCIDs[i], dnas[i], signatures[i]));
            require(!DNAexists[dnas[i]]);
            CID[totalSupply + 1] = ipfsCIDs[i];
            CIDToTokenId[ipfsCIDs[i]] = totalSupply + 1;
            _mint(_to, totalSupply + 1);
            DNAexists[dnas[i]] = true;
            totalSupply++;
            emit minted(_to, dnas[i], totalSupply);
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
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(!metadataFrozen) {
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

    function setWhitelistCost(uint256 _newWhitelistCost) external onlyOwner {
        whitelistCost = _newWhitelistCost;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function pauseFreeMint(bool _state) external onlyOwner {
        freeMintPaused = _state;
    }

    function pauseWlMint(bool _state) external onlyOwner {
        wlMintPaused = _state;
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
        metadataFrozen = _state;
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