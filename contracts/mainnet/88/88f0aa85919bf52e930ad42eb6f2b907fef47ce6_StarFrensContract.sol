// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract StarFrensContract is Ownable, ERC721A, ReentrancyGuard {
    uint256 private constant _PUBLIC_PRICE = 0.04 ether;
    uint256 private constant _PRESALE_PRICE = 0.03 ether;
    uint256 private constant MAX_PURCHASE_DURING_WL = 3;
    uint256 private constant MAX_BATCH_SIZE = 20;
    uint256 private _MAX_MINT = 3000;
    address private _TEAM = 0xbE077Af70845347b4dA8063649F4e425CC41F6D5;

    uint256 public constant wlStart = 1649517600; // 11:30am ET 2022-04-09
    uint256 public constant publicStart = 1649532600; //3:30pm ET 2022-04-09
    uint256 public paused; // default is 0 which means not paused

    bytes32 public merkleRoot = 0x25704d847756554bb78c4d553e2f338d7fb16ab6a908c7fbcd2405f5165b2bfe;
    mapping(address => uint256) public presaleAddressMintCount;

    string private _baseTokenURI = "";

    constructor() ERC721A("StarFrens", "STARFRENS", MAX_BATCH_SIZE, _MAX_MINT) {
    }

    modifier mintGuard(uint256 tokenCount) {
        // easy checks
        require(paused == 0, "Sale is not available");
        require(tokenCount > 0 && tokenCount <= MAX_BATCH_SIZE, "Purchase must be for 1-20 tokens");
        require(msg.sender == tx.origin, "No buying on behalf of others");
        // only use public sale price after the public sale start time
        if (block.timestamp > publicStart) {
            require(_PUBLIC_PRICE * tokenCount <= msg.value, "Insufficient Funds");
        } else {
            require(_PRESALE_PRICE * tokenCount <= msg.value, "Insufficient Funds");
        }

        // math-y checks
        // tokens start a 0, with 0 being a fake one, so allow (limit+1) mints
        // to allow [0, limit] inclusive for limit worth of real tokens
        require(totalSupply() + tokenCount <= _MAX_MINT+1, "Not enough supply remaining");
        _;
    }

    function mint(uint256 amount) external payable mintGuard(amount) {
        require(block.timestamp > publicStart, "Sale not live");
        _safeMint(msg.sender, amount);
    }

    function mintPresale(bytes32[] calldata proof, uint256 amount) external payable mintGuard(amount) {
        require(block.timestamp > wlStart, "Presale not live");
        require(presaleAddressMintCount[msg.sender] + amount <= MAX_PURCHASE_DURING_WL, "At most 3 may be purchased in presale.");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not eligible for presale");

        presaleAddressMintCount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    // Mints a value-less token 0 that will be discarded so that listing on opensea can occur
    // before the mint is live
    function mintZeroForOpenSea() external onlyOwner {
        // this can only be done once
        require(totalSupply() == 0);
        _safeMint(msg.sender, 1);
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function pause() external onlyOwner {
        paused = 1;
    }

    function unpause() external onlyOwner {
        paused = 0;
    }

    function setMaxMint(uint256 maxMint) external onlyOwner {
        require(maxMint <= 6789);
        _MAX_MINT = maxMint;
    }


    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function cashout() external onlyOwner {
        payable(_TEAM).transfer(address(this).balance);
    }

    function setCashout(address addr) external onlyOwner returns(address) {
        _TEAM = addr;
        return addr;
    }

}