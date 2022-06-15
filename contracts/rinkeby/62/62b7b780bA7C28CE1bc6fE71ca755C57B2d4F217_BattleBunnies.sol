// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Percentages.sol";
contract BattleBunnies is ERC721A, Ownable, ReentrancyGuard, Percentages {
    // Max supply 
    uint256 public maxSupply;

    // Merkle Root
    bytes32 public alRoot;
    bytes32 public holderRoot;

    uint256 public price;
    uint256 public alPrice;
    uint256 public holderPrice;

    uint256 maxPerTx = 10;
    uint256 maxPerHolder = 5;
    uint256 maxPerAL = 5;

    bool public alOnly = true;
    bool public saleOpen = false;
    bool public holderOnly = true;
    
    mapping(address => uint256) public holderMints;
    mapping(address => uint256) public alMints;

    event minted(address minter, uint256 price, address recipient, uint256 amount);

    struct Wallets {
        uint256 percentage;
        address wallet;
    }
    Wallets[] public wallets;

    constructor(
        string memory name,     // The Battle Bunnies
        string memory symbol,   // TBB
        uint256 _maxSupply,     // 5000
        uint256 _price,         // tbd
        uint256 _alPrice,       // tbd
        uint256 _holderPrice    // tbd

    ) 
    ERC721A(name, symbol, 50, _maxSupply) 
    {
        maxSupply = _maxSupply;
        price = _price;
        alPrice = _alPrice;
        holderPrice = _holderPrice;

        //wallets.push(Wallets(xx, <address>)); //Receives xx% pay split <address>
        //wallets.push(Wallets(xx, <address>)); //Receives xx% pay split <address>
    }

    function isAllowListed(address _recipient, bytes32[] calldata _merkleProof, bytes32 _root) public pure returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_recipient));
        bool isal = MerkleProof.verify(_merkleProof, _root, leaf);
        return isal;
    }
    
    function mint(uint256 amount, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(saleOpen, "Sale is closed");
        require(totalSupply() + amount <= maxSupply, "exceeds max supply");
        require(amount <= maxPerTx, "exceeds max per tx");

        uint256 mintPrice = price;
        
        bool isal = isAllowListed(_msgSender(), _merkleProof, alRoot);
        bool isHolder = isAllowListed(_msgSender(), _merkleProof, holderRoot);
        if(isHolder && holderMints[_msgSender()] < maxPerHolder) {
            require(holderMints[_msgSender()] + amount <= maxPerHolder, 'exceeds max per holder');
            holderMints[_msgSender()] += amount;
            mintPrice = holderPrice;
        } else if(isal && alMints[_msgSender()] < maxPerAL) {
            require(!holderOnly, 'holders only');
            require(alMints[_msgSender()] + amount <= maxPerAL, 'exceeds max per allow list');
            alMints[_msgSender()] += amount;
            mintPrice = alPrice;
        } else {
            require(!alOnly, "allow list only");
        }

        require(msg.value == mintPrice * amount, "incorrect amount of ETH sent");
        
        _safeMint(_msgSender(), amount);
        emit minted(_msgSender(), msg.value, _msgSender(), amount);
    }

    function ownerMint(uint amount, address _recipient) external onlyOwner {
        require(totalSupply() + amount <= maxSupply,  "exceeds max supply");
        _safeMint(_recipient, amount);
        emit minted(_msgSender(), 0, _recipient, amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = _msgSender().call{value: balance}("");
        require(success, "Transfer fail");
    }

    function setURI(string memory _uri) external onlyOwner {
        URI = _uri;
    }

    function flipALState() external onlyOwner {
        alOnly = !alOnly;
    }

    function flipSaleState() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function flipHolderState() external onlyOwner {
        holderOnly = !holderOnly;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    } 

    function setALPrice(uint256 _alPrice) external onlyOwner {
        alPrice = _alPrice;
    }

    function setHolderPrice(uint256 _holderPrice) external onlyOwner {
        holderPrice = _holderPrice;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxPerHolder(uint256 _maxPerHolder) external onlyOwner {
        maxPerHolder = _maxPerHolder;
    }

    function setMaxPerAL(uint256 _maxPerAL) external onlyOwner {
        maxPerAL = _maxPerAL;
    }

    function setALRoot(bytes32 root) external onlyOwner {
        alRoot = root;
    }

    function setHolderRoot(bytes32 _holderRoot) external onlyOwner {
        holderRoot = _holderRoot;
    }

    function splitWithdraw() external onlyOwner nonReentrant{
        uint256 balance = address(this).balance;

        uint256 payout1 = percentageOf(balance, wallets[0].percentage);
        
        (bool success1,) = wallets[0].wallet.call{value: payout1 }("");
        require(success1, 'Transfer fail');
        
        uint256 payout2 = percentageOf(balance, wallets[1].percentage);
        
        (bool success2,) = wallets[1].wallet.call{value: payout2 }("");
        require(success2, 'Transfer fail');
    }

    function changePaySplits(uint256 indexToChange, uint256 _percentage, address payable _wallet) external onlyOwner {
        wallets[indexToChange].percentage = _percentage;
        wallets[indexToChange].wallet = _wallet;
    }
}