// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Percentages.sol";
import "./MerkleProof.sol";

contract Photosynthesis is ERC721A, Ownable, ReentrancyGuard, Percentages {
    bytes32 public merkleRoot;

    string public PS143_PROVENANCE = "32662m6w333d34312z5o4n0z1u431g1g153q1i07642t085r0u293d2s0f4f1w0m";

    IERC721 public ProbablyNothing;

    // Price Per NFT
    uint256 public price;
    uint256 public alPrice;

    // Max Supply
    uint256 maxSupply;

    // Sale States
    bool public saleOpen;
    bool public alOnly;

    // Mint Count Mapping
    mapping(address => uint256) public mints;
    uint256 public mintsPerPN = 2; 
    uint256 public mintsPerAL = 2;
    uint256 public maxPerTx = 10;

    // Events
    event minted(address minter, uint256 price, address recipient, uint256 amount);
    event burned(address from, address to, uint256 id);

    // wallet splits for withdrawals 
    struct Wallets {
        uint256 percentage;
        address wallet;
    }
    Wallets[] public wallets;

    constructor(
        string memory name,     // Photosynthesis
        string memory symbol,   // PS143
        uint256 _price,         // 70000000000000000 Wei
        uint256 _alPrice,       // 60000000000000000 Wei
        uint256 _maxSupply,     // 8888
        string memory _uri,     // https://us-central1-photosynthesis2.cloudfunctions.net/get-photosynthesis-metadata?token_id=
        address PN,             // 0xB9aEcB63908c13b6167aD2eab9bAcD7e0DaBa78A
        address payout1,        // Receives 8% pay split  0x19Dd9264c30c9271D301aa1b4Df9a1Ec52BdEe67
        address payout2         // Receives 92% pay split 0xb43eebac012cb2f12e1ec258a6ece20a7aa4712f
    ) 
    ERC721A(name, symbol, 100, _maxSupply) 
    {
        maxSupply = _maxSupply;
        price = _price;
        alPrice = _alPrice;
        URI = _uri;
        ProbablyNothing = IERC721(PN);

        // add payout wallets
        wallets.push(Wallets(8, payout1));
        wallets.push(Wallets(92, payout2));
        alOnly = true;
    }

    function isAllowListed(address _recipient, bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_recipient));
        bool isal = MerkleProof.verify(_merkleProof, merkleRoot, leaf);
        return isal;
    }
    
    function mint(uint256 amount, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(saleOpen, "Sale is closed");
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        require(amount <= maxPerTx, "Exceeds maximum per transaction");

        uint256 mintPrice = price;

        if(ProbablyNothing.balanceOf(_msgSender()) > 0 && ((mints[_msgSender()] + amount) <= (mintsPerPN * ProbablyNothing.balanceOf(_msgSender())))) {
            mints[_msgSender()] += amount;
            mintPrice = alPrice;
        } else if(isAllowListed(_msgSender(), _merkleProof) && (mints[_msgSender()] + amount <= mintsPerAL)) {
                require(mints[_msgSender()] + amount <= mintsPerAL, "Amount exceeds max per allow list");
                mints[_msgSender()] += amount;
                mintPrice = alPrice;
        } else {
            require(!alOnly, "Allow list only");
        }

        require(msg.value == mintPrice * amount, "Incorrect amount of ETH sent");

        _safeMint(_msgSender(), amount);
        emit minted(_msgSender(), mintPrice * amount, _msgSender(), amount);
    }

    function burn(uint256 tokenId) external {
        transferFrom(_msgSender(), address(0), tokenId);
        emit burned(_msgSender(), address(0), tokenId);
    }

    function ownerMint(uint amount, address _recipient) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Not enough left to mint");
        _safeMint(_recipient, amount);
        emit minted(_msgSender(), 0, _recipient, amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = _msgSender().call{value: balance}("");
        require(success, "Transfer fail");
    }

    function splitWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        uint256 payout1 = percentageOf(balance, wallets[0].percentage);
        (bool success1,) = wallets[0].wallet.call{value: payout1 }("");
        require(success1, 'Transfer fail');
        uint256 payout2 = percentageOf(balance, wallets[1].percentage);
        (bool success2,) = wallets[1].wallet.call{value: payout2 }("");
        require(success2, 'Transfer fail');
    }

    function setURI(string memory _uri) external onlyOwner {
        URI = _uri;
    }

    function flipSaleState() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function flipALState() external onlyOwner {
        alOnly = !alOnly;
    }

    function setPN(address _PN) external onlyOwner {
        ProbablyNothing = IERC721(_PN);
    }

    function setALPrice(uint256 _alPrice) external onlyOwner {
        alPrice = _alPrice;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMintsPerPN(uint256 _mintsPerPN) external onlyOwner {
        mintsPerPN = _mintsPerPN;
    }

    function setMintsPerAL(uint256 _mintsPerAL) external onlyOwner {
        mintsPerAL = _mintsPerAL;
    }

    function setMaxPerTX(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function changePaySplits(uint256 indexToChange, uint256 _percentage, address payable _wallet) external onlyOwner {
        wallets[indexToChange].percentage = _percentage;
        wallets[indexToChange].wallet = _wallet;
    }

    function pay() external payable {

    }

}