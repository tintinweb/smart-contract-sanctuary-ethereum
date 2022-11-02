// SPDX-License-Identifier: MIT
// based on ERC721A Contracts v4.2.3 by Creators Chiru Labs

pragma solidity ^0.8.7;

import "./MerkleProof.sol";
import './ERC721ABurnable.sol';
import './Ownable.sol';

contract MEGAMOUNTAINEERS is ERC721A, ERC721ABurnable, Ownable {
    string  public              baseURI;
    string  public              provenance;
    bool    public              isReveal = false;
    
    address public              payee;

    bytes32 public              allowlistMerkleRoot;

    uint256 public              saleStatus          = 0; // 0 closed, 1 mega/paid, 2 al free, 3 PUBLIC_free
    uint256 public constant     MAX_SUPPLY          = 8888;
    uint256 public              MAX_GIVEAWAY        = 1111;

    uint256 public constant     MAX_PER_TX          = 3;
    uint256 public constant     priceInWei          = 0.07 ether;

    mapping(address => uint) public addressToMinted;
    mapping(uint => bool)    public mega;

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}
    
    event MegaMinted(address indexed to, uint256 indexed tokenId);

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setReveal(bool _isReveal) public onlyOwner {
        isReveal = _isReveal;
    }

    function setProvenance(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        if (isReveal) {

            if (mega[_tokenId]) {
                return string(abi.encodePacked(baseURI, "/reveal/mega/", _toString(_tokenId), ".json"));
            } 
            
            else {
                return string(abi.encodePacked(baseURI, "/reveal/meta/", _toString(_tokenId), ".json"));
            }

        } 
        else {
            return string(abi.encodePacked(baseURI, "/unrevealed.json"));
        }
    }

    function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot) external onlyOwner {
        // don't forget to prepend: 0x
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    function setSaleStatus(uint256 _status) external onlyOwner {
        require(saleStatus < 4 && saleStatus >= 0, "Invalid status.");
        saleStatus = _status;
    }

    function mint(uint256 count, bytes32[] calldata proof) public payable {
        require(totalSupply() + count < MAX_SUPPLY, "Excedes max supply.");
        require(count <= MAX_PER_TX, "Exceeds max per transaction.");
        require(saleStatus > 0, "Sale not started.");
        //require(msg.sender() != tx.origin, "No contracts allowed.");

        if (saleStatus == 1) {
            // public paid, mega mint  
            require(msg.value == priceInWei * count, "Incorrect value sent.");
            _safeMint(_msgSender(), count);
            for(uint i; i < count; i++) {     
                mega[totalSupply() + i] = true;
                emit MegaMinted(msg.sender, totalSupply() + i);
            }
        }

        

        else if (saleStatus == 2) {
            // allowlist, free
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(proof, allowlistMerkleRoot, leaf), 'Not on allowlist. Merkle Proof fail.');
            require(addressToMinted[_msgSender()] == 0, "Free allowlist already minted.");
            addressToMinted[_msgSender()] += 1;
            // one free mint
            _safeMint(_msgSender(), 1);
        } 

        else if (saleStatus == 3) {
            // public free
            require(addressToMinted[_msgSender()] == 0, "Free already minted.");
            addressToMinted[_msgSender()] += 1;
            // one free mint
            _safeMint(_msgSender(), 1);
            
        }
        
    }

    function promoMint(uint _qty, address _to) public onlyOwner {
        require(MAX_GIVEAWAY - _qty >= 0, "Exceeds max giveaway.");
        _safeMint(_to, _qty);
        MAX_GIVEAWAY -= _qty;
    }

    function withdraw() public  {
        (bool success, ) = payee.call{value: address(this).balance}("");
        require(success, "Failed to send to payee.");
    }

    function setPayee(address _payee) public onlyOwner {
        payee = _payee;
    }
}