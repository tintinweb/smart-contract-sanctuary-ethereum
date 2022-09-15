// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721.sol";

contract GCDD is Ownable, Pausable, ERC721 {
    uint256 private freeMax = 5000;
    uint256 public totalSupply = 5888;
    string private _name = "GuoChanDanDan";
    string private _symbol = "GCDD";
    uint256 private basePrice = 150000000000000000000;
    uint256 private mintedSupply = 0;
    string private _baseTokenURI;
    mapping(address => bool) private freeAccounts;

    constructor() ERC721(_name, _symbol) {
        pause();
    }
    function getAddress() public view returns(address){
        return msg.sender;
    }
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw(address addr) external onlyOwner {
        payable(addr).transfer(address(this).balance);
    }
    
    function devMint() external onlyOwner {
        require(mintedSupply <= totalSupply, "Max supply reached");
        require(mintedSupply + 10 <= totalSupply, "Exceeds max supply");
        mintInner(10);
    }
    function airDrop(address[] memory addrs) external onlyOwner {
        require(mintedSupply <= totalSupply, "Max supply reached");
        require(mintedSupply + addrs.length <= totalSupply, "Exceeds max supply");
        for (uint256 i = 0; i < addrs.length; i++) {
            _safeMint(addrs[i], mintedSupply + 1);
            mintedSupply++;
        }
    }
    function mint(uint256 amount) public payable whenNotPaused {
        require(mintedSupply  <= totalSupply, "Max supply reached");
        require(mintedSupply + amount  <= totalSupply, "Exceeds max supply");
        if (mintedSupply + amount <= freeMax) {
            require(!freeAccounts[msg.sender], "Repeat claim");
            require(amount == 1, "Only 1 at a time");
            mintInner(amount);
        } else {
            require(amount <= 20, "A maximum of 20 at a time");
            require(msg.value >= basePrice * amount, "Not enough ETH sent");
            mintInner(amount);
        }
    }

    function mintInner(uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, mintedSupply + 1);
            mintedSupply++;
            freeAccounts[msg.sender] = true;
        }
    }

    function setBasePrice(uint256 price) external onlyOwner {
        basePrice = price;
    }

    function setFreeMax(uint256 _freeMax) external onlyOwner {
        freeMax = _freeMax;
    }

    function getAllwance(address addr) public view returns (uint256[] memory) {
        uint256 count = 0;
        uint256[] memory arr = new uint256[](balanceOf(addr));
        for (uint256 i = 0; i < mintedSupply; i++) {
            address owner = getOwnnerOf(i);
            if (owner == addr) {
                arr[count] = i;
                count++;
            }
        }
        return arr;
    }

    function getStatus() public view returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](5);
        arr[0] = paused() ? 0 : 1;
        arr[1] = basePrice;
        arr[2] = totalSupply;
        arr[3] = mintedSupply;
        arr[4] = freeMax;
        return arr;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}