// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;
import "./ERC721AL.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Percentages.sol";

contract KushKriminals is ERC721A, Ownable, ReentrancyGuard, Percentages {
bytes32 public merkleRoot;

    // Price Per NFT
    uint256 public price;
    uint256 public alPrice;

    // Max Supply
    uint256 maxSupply;

    // Sale State
    uint256 public state;

    // Mint Count Mapping
    mapping(address => uint256) public mints;
    uint256 public mintsPerAL = 2;
    uint256 public maxPerTx = 10;

    // Admin Mapping
    mapping(address => bool) private _isAdmin;

    // Events
    event minted(address minter, uint256 price, address recipient, uint256 amount);
    event burned(address from, address to, uint256 id);
    event stakeStarted(uint256 tokenId, uint256 timestamp, address owner, uint256 index);
    event stakeEnded(uint256 tokenId, uint256 totalTime, address owner, uint256 index);

    // wallet splits for withdrawals 
    struct Wallets {
        uint256 percentage;
        address wallet;
    }
    Wallets[] public wallets;

    constructor() 
    ERC721A("Kush Kriminals", "KUSH", 10420, 10420) 
    {
        maxSupply = 10420;
        price = 1000000000000000;   // must update
        alPrice = 1000000000000000; // must update
        URI = "";                   // must update
        _isAdmin[_msgSender()] = true;
        //_safeMint(_msgSender(), 100);
    }

    modifier onlyAdmin {
        require(isAdmin(_msgSender()), "onlyAdmin: caller is not admin");
        _;
    }

    function isAllowListed(address _recipient, bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_recipient));
        bool isal = MerkleProof.verify(_merkleProof, merkleRoot, leaf);
        return isal;
    }

    function setAdmin(address _operator, bool _approved) external onlyOwner {
        _isAdmin[_operator] = _approved;
    }

    function isAdmin(address _operator) internal view returns( bool ) {
        return _isAdmin[_operator];
    }
    
    function mint(uint256 _amount, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(totalSupply() + _amount <= maxSupply, "Exceeds max supply");
        require(_amount <= maxPerTx, "Exceeds max per tx");
        require(state != 0, "Minting is closed");

        uint256 mintPrice = price;

        bool isAL = isAllowListed(_msgSender(), _merkleProof);
        if(isAL) {
            require(mints[_msgSender()] + _amount <= mintsPerAL, 'Exceeds max per allow-list wallet');
            mints[_msgSender()] += _amount;
            mintPrice = alPrice;
        }

        if(state == 1) {
            require(isAL, "allow list only");
        }

        require(msg.value == mintPrice * _amount, "Incorrect amount of ETH sent");

        _safeMint(_msgSender(), _amount);
        emit minted(_msgSender(), mintPrice * _amount, _msgSender(), _amount);
    }

    function startStake(uint256 token) external {
        require(_msgSender() == ownerOf(token),"sender does not own token");
        require(!isStaked[token], "token ID already staked");
        isStaked[token] = true;
        stakeIndex[token] = stake.length;
        stake.push(Stake(token, block.timestamp, _msgSender()));

        emit stakeStarted(token, block.timestamp, _msgSender(), stakeIndex[token]);
    }

    function endStake(uint256 token) external {
        require(_msgSender() == ownerOf(token), "sender does not own token");
        require(isStaked[token], "token ID not staked");
        isStaked[token] = false;

        uint256 totalTime = block.timestamp - stake[stakeIndex[token]].lock_timestamp;

        emit stakeEnded(token, totalTime, _msgSender(), stakeIndex[token]);
    }

    function burn(uint256 tokenId) external {
        transferFrom(_msgSender(), address(0), tokenId);
        emit burned(_msgSender(), address(0), tokenId);
    }

    function ownerMint(address _recipient, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Not enough left to mint");
        _safeMint(_recipient, amount);
        emit minted(_msgSender(), 0, _recipient, amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = _msgSender().call{value: balance}("");
        require(success, "Transfer fail");
    }

    function splitWithdraw() external onlyAdmin {
        uint256 balance = address(this).balance;

        uint256 payout1 = percentageOf(balance, wallets[0].percentage);
        (bool success1,) = wallets[0].wallet.call{value: payout1 }("");
        require(success1, 'Transfer fail');
        uint256 payout2 = percentageOf(balance, wallets[1].percentage);
        (bool success2,) = wallets[1].wallet.call{value: payout2 }("");
        require(success2, 'Transfer fail');
    }

    function setURI(string memory _uri) external onlyAdmin {
        URI = _uri;
    }

    function setState(uint256 _state) external onlyAdmin {
        state = _state;
    }

    function setALPrice(uint256 _alPrice) external onlyAdmin {
        alPrice = _alPrice;
    }

    function setPrice(uint256 _price) external onlyAdmin {
        price = _price;
    }

    function setMaxPerAL(uint256 _mintsPerAL) external onlyAdmin {
        mintsPerAL = _mintsPerAL;
    }

    function setMaxPerTX(uint256 _maxPerTx) external onlyAdmin {
        maxPerTx = _maxPerTx;
    }

    function setRoot(bytes32 root) external onlyAdmin {
        merkleRoot = root;
    }

    function changePaySplits(uint256 indexToChange, uint256 _percentage, address payable _wallet) external onlyOwner {
        wallets[indexToChange].percentage = _percentage;
        wallets[indexToChange].wallet = _wallet;
    }

    function pay() external payable {

    }

    function currentTime() external view returns(uint256) {
        return block.timestamp;
    }

    function stakeTime(uint256 token) external view returns(uint256) {
        uint256 total = block.timestamp - stake[stakeIndex[token]].lock_timestamp;
        return isStaked[token] ? total : 0;
    }
}