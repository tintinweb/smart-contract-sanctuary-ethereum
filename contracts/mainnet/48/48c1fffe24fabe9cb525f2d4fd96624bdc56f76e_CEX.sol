// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
contract CEX is ERC721A, Ownable, ReentrancyGuard {
    // Max supply 
    uint256 public maxSupply;
    uint256 public maxPerTx;

    // Merkle Root
    bytes32 public merkleRoot;

    // Price Per NFT
    uint256 public alPrice;
    
    // The address to receive payment from sales
    address payable payee;

    // Boolean value, if true only allowlist can buy, if false public can buy
    bool public alOnly;
    bool public saleOpen;
    
    // allowlist mapping
    mapping(address => bool) public hasMinted;

    // Events
    event minted(address minter, uint256 price, address recipient, uint256 amount);
    event burned(address from, address to, uint256 id);

    uint256[] public quarters = [750000000000000000, 750000000000000000, 1000000000000000000, 1250000000000000000];

    constructor(
        string memory name,     // CEX Never Ending Tickets
        string memory symbol,   // CNET
        uint256 _alPrice,       // 750000000000000000
        uint256 _maxSupply,     // 100
        uint256 _maxPerTx,      // 10
        address payable _payee, // 0x81FE0aDB11c01D3ab91F0a478B9De71083e48067
        string memory _uri      // https://us-central1-cex1-332319.cloudfunctions.net/get-ipfs?tokenid=
    ) 
    ERC721A(name, symbol, 50, _maxSupply) 
    {
        maxSupply = _maxSupply;
        maxPerTx = _maxPerTx;
        alPrice = _alPrice;
        payee = _payee;
        URI = _uri;

        alOnly = false;
        saleOpen = true;
    }

    function currentPrice() public view returns(uint256) {
        return quarters[totalSupply() / 25];
    }

    function isAllowListed(address _recipient, bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_recipient));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }
    
    function mint(uint256 amount, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(saleOpen, "Sale is closed");
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        require(amount <= maxPerTx, "Exceeds transaction maximum");
        
        // Check if allowListed
        if(isAllowListed(_msgSender(), _merkleProof) && !hasMinted[_msgSender()]) {
            // Restrict to one transaction per whitelisted account
            require(msg.value == alPrice * amount, "Incorrect amount of ETH sent");
            
            hasMinted[_msgSender()] = true;
        } else {
            require(!alOnly, "Purchasing only available for whitelisted addresses");
            require(msg.value == currentPrice() * amount, "Incorrect amount of ETH sent");
        }
        // Pay payee
        (bool success,) = payee.call{value: msg.value}("");
        require(success, "Transfer fail");
        
        // Mint NFT to user wallet
        _safeMint(_msgSender(), amount);
        emit minted(_msgSender(), msg.value, _msgSender(), amount);
    }

    function burn(uint256 tokenId) external {
        transferFrom(_msgSender(), address(0), tokenId);
        emit burned(_msgSender(), address(0), tokenId);
    }

    function ownerMint(uint amount, address _recipient) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _safeMint(_recipient, amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = _msgSender().call{value: balance}("");
        require(success, "Transfer fail");
    }

    function setURI(string memory _uri) public onlyOwner {
        URI = _uri;
    }

    function resetWhitelists(address[] memory whitelistedAddress) external onlyOwner {
        for(uint256 i = 0; i < whitelistedAddress.length; i++){
            hasMinted[whitelistedAddress[i]] = false;
        }
    }

    function flipALState() external onlyOwner {
        alOnly = !alOnly;
    }

    function flipSaleState() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function setRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setPrice(uint256 quarterToChange, uint256 newPrice) external onlyOwner {
        quarters[quarterToChange] = newPrice;
    }

    function addPriceBracket(uint256 newPrice) external onlyOwner {
        quarters.push(newPrice);
    }

    function changePayee(address payable _payee) external onlyOwner {
        payee = _payee;
    }

    function setMaxPerTX(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setALPrice(uint256 _alPrice) external onlyOwner {
        alPrice = _alPrice;
    }

    function pay() public payable {

    }

}