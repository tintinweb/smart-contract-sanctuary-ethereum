// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract TDC is ERC721A, Ownable, ReentrancyGuard  {
    string public baseTokenURI;
    bool public isPaused = false;

    uint256 public constant maxSupply = 5555;
    
    bytes32 public merkleRoot = 0x9db6fccf86cd6b84d01d32673a8cce2e7e9aaa6667109823fa4e2fc32777c464;

    uint256 public constant price = 0.089 ether;
    uint256 public constant wlPrice = 0.069 ether;
    
    uint256 public wlSaleStartTime = 1666890000;
    uint256 public wlSaleEndTime = 1666897200;
    
    uint256 public publicSaleStartTime = 1666900800;
    uint256 public publicSaleEndTime = 1674849600;
    
    uint8 public amountPerAddr = 3;
    uint8 public wlAmountPerAddr = 2;
    uint16 public customDropMaxSupply = 51;
    uint8 public totalCustomDrop = 0;

    mapping(address => uint8) public holdedNumAry;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721A(_name, _symbol) {
        baseTokenURI = _uri;
    }

    function publicSale(uint8 _purchaseNum)
        external
        payable
        onlyUser
        nonReentrant
    {
        require(!isPaused, "3DCNFT: currently paused");
        require(
            block.timestamp >= publicSaleStartTime,
            "3DCNFT: public sale is not started yet"
        );
        require(
            block.timestamp < publicSaleEndTime,
            "3DCNFT: public sale is ended"
        );
        require(
            (holdedNumAry[_msgSender()] + _purchaseNum) <= amountPerAddr,
            "3DCNFT: Each Address can only purchase 3"
        );
        uint256 supply = totalSupply();
        require(
            (supply + _purchaseNum) <= maxSupply,
            "3DCNFT: reached max supply"
        );
        require(
            msg.value >= (price * _purchaseNum),
            "3DCNFT: price is incorrect"
        );

        _safeMint(_msgSender(), _purchaseNum);
        holdedNumAry[_msgSender()] = holdedNumAry[_msgSender()] + _purchaseNum;
    }

    function whiteListSale(bytes32[] calldata _merkleProof, uint8 _purchaseNum)
        external
        payable
        onlyUser
        nonReentrant
    {
        require(!isPaused, "3DCNFT: currently paused");
        require(
            block.timestamp >= wlSaleStartTime,
            "3DCNFT: WhiteList sale is not started yet"
        );
        require(
            block.timestamp < wlSaleEndTime,
            "3DCNFT: WhiteList sale is ended"
        );
        require(verifyAddress(_merkleProof), 
        "3DCNFT: You are not on WhiteList"
        );
        require(
            (holdedNumAry[_msgSender()] + _purchaseNum) <= wlAmountPerAddr,
            "3DCNFT: Each Address during presale can only purchase 2"
        );
        uint256 supply = totalSupply();
        require(
            (supply + _purchaseNum) <= maxSupply,
            "3DCNFT: reached max supply"
        );
        require(
            msg.value >= (wlPrice * _purchaseNum),
            "3DCNFT: price is incorrect"
        );

        _safeMint(_msgSender(), _purchaseNum);
        holdedNumAry[_msgSender()] = holdedNumAry[_msgSender()] + _purchaseNum;
    }

    function ownerMint(address _addr, uint8 _amount) external onlyOwner {
        uint256 supply = totalSupply();
        require(
            (supply + _amount) <= maxSupply,
            "3DCNFT: reached max supply"
        );

        _safeMint(_addr, _amount);
    }

    function ownerBatchMint(address[] memory _addrs, uint8[] memory _amount, uint256 _total) external onlyOwner {
        uint256 supply = totalSupply();

        require(
            (supply + _total) <= maxSupply,
            "3DCNFT: reached max supply"
        );

        for (uint256 i = 0; i < _addrs.length; i++) {
            _safeMint(_addrs[i], _amount[i]);
        }
    }

    function ownerCustomMint(address _addr, uint8 _amount) external onlyOwner {
        require(
            totalCustomDrop + _amount <= customDropMaxSupply,
            "3DCNFT: reached max custom drop supply"
        );

        _safeMint(_addr, _amount);
        totalCustomDrop = totalCustomDrop + _amount;
    }
    

    function ownerBatchTransfer(address[] memory _addrs, uint256[] memory _ids) external onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            transferFrom(_msgSender(), _addrs[i], _ids[i]);
        }
    }

    modifier onlyUser() {
        require(_msgSender() == tx.origin, "3DCNFT: no contract mint");
        _;
    }

    function verifyAddress(bytes32[] calldata _merkleProof) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseTokenURI = _baseURI;
    }

    function setMerkleRoot(bytes32 merkleRootHash) external onlyOwner
    {
        merkleRoot = merkleRootHash;
    }

    function setPause(bool _isPaused) external onlyOwner returns (bool) {
        isPaused = _isPaused;

        return true;
    }

    function setWlStartTime(uint256 _time) external onlyOwner {
        wlSaleStartTime = _time;
    }

    function setWlEndTime(uint256 _time) external onlyOwner {
        wlSaleEndTime = _time;
    }

    function setPublicStartTime(uint256 _time) external onlyOwner {
        publicSaleStartTime = _time;
    }

    function setPublicEndTime(uint256 _time) external onlyOwner {
        publicSaleEndTime = _time;
    }

    function setCustomDropMaxSupply(uint16 _amount) external onlyOwner {
        require(
            _amount >= totalCustomDrop,
            "3DCNFT: amount less than dropped"
        );
        customDropMaxSupply = _amount;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}