// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Percentages.sol";
contract BattleBunnies is ERC721A, Ownable, ReentrancyGuard, Percentages {
    // Max supply 
    uint256 public maxSupply;
    IERC721 public TBB_GENESIS;

    // Merkle Root
    bytes32 public alRoot;

    uint256 public price;
    uint256 public alPrice;
    uint256 public holderPrice;

    uint256 maxPerTx = 10;
    uint256 maxPerAL = 5;

    bool public alMint = true;
    bool public saleOpen = false;
    bool public holderMint = true;
    
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
        TBB_GENESIS = IERC721(0x3267FDc614C6948BfbF1a9B88FC9edB2c1Ad2FDF); // 0xF8e9776840639b0fFEa1EcB31fADF974Cf48A435 - mainnet

        wallets.push(Wallets(10, 0x1Dd7134A77f5e3E2E63162bBdcFD494140908270)); //Receives xx% pay split <address>
        wallets.push(Wallets(90, 0x007FB487100f74Bf425B7AdE9Ca0Ae1916f54f11)); //Receives xx% pay split <address>
    }

    function isAllowListed(address _recipient, bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_recipient));
        bool isal = MerkleProof.verify(_merkleProof, alRoot, leaf);
        return isal;
    }

    function mint(uint256 amount, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(saleOpen, "Sale is closed");
        require(totalSupply() + amount <= maxSupply, "exceeds max supply");
        require(amount <= maxPerTx, "exceeds max per tx");

        uint256 mintPrice = price;

        if(holderMint) {
            require(TBB_GENESIS.balanceOf(_msgSender()) > 0, "Must hold a genesis NFT");
            mintPrice = holderPrice;
        } else {
            if(alMint) {
                bool isal = isAllowListed(_msgSender(), _merkleProof);
                require(isal, "Allow list only");
                require(alMints[_msgSender()] + amount <= maxPerAL, 'exceeds max per allow list');
                alMints[_msgSender()] += amount;
                mintPrice = alPrice;
            }
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
        alMint = !alMint;
    }

    function flipSaleState() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function flipHolderState() external onlyOwner {
        holderMint = !holderMint;
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

    function setMaxPerAL(uint256 _maxPerAL) external onlyOwner {
        maxPerAL = _maxPerAL;
    }

    function setALRoot(bytes32 root) external onlyOwner {
        alRoot = root;
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

    function setGenesis(address _genesis) external onlyOwner {
        TBB_GENESIS = ERC721A(_genesis);
    }

    function changePaySplits(uint256 indexToChange, uint256 _percentage, address payable _wallet) external onlyOwner {
        wallets[indexToChange].percentage = _percentage;
        wallets[indexToChange].wallet = _wallet;
    }
}