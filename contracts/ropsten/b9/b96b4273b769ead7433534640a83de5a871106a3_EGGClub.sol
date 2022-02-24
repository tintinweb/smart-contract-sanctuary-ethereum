// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721.sol";

contract EGGClub is Ownable, Pausable, ERC721 {
    string private baseURI;
    uint256 private freeMax = 800;
    uint256 public totalSupply = 10000;
    uint256 private basePrice = 150000000000000000;
    uint256 private persalePrice = 150000000000000000;
    uint256 private maxSupply = 10000;
    uint256 private mintedSupply = 0;
    uint256 private reservedTotal = 0;
    uint256 private freeTotal = 0;
    mapping(address => bool) private reservedAccounts;

    constructor(
        uint256 _totalSupply,
        uint256 _maxSupply,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        totalSupply = _totalSupply;
        maxSupply = _maxSupply;
        pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function withdraw(address addr) external onlyOwner {
        payable(addr).transfer(address(this).balance);
    }

    function mint(uint256 amount) public payable whenNotPaused {
        require(mintedSupply < maxSupply, "Max supply reached");
        require(mintedSupply + amount <= maxSupply, "Exceeds max supply");
        if (mintedSupply + amount <= freeMax) {
            require(amount == 1, "Only 1 at a time");
            mintInner(amount, true);
        } else {
            require(amount <= 20, "A maximum of 20 at a time");
            if (!reservedAccounts[msg.sender]) {
                require(msg.value >= basePrice * amount, "Not enough ETH sent");
            }
            mintInner(amount, false);
        }
    }

    function mintInner(uint256 amount, bool isFree) internal {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, mintedSupply);
            mintedSupply++;
            if (isFree) {
                freeTotal++;
            }
            if (reservedAccounts[msg.sender]) {
                reservedTotal++;
            }
        }
    }

    function setBasePrice(uint256 price) external onlyOwner {
        basePrice = price;
    }

    function setFreeMax(uint256 _freeMax) external onlyOwner {
        freeMax = _freeMax;
    }

    function addReservedAccounts(address[] memory addr) external onlyOwner {
        for (uint256 i = 0; i < addr.length; i++) {
            reservedAccounts[addr[i]] = true;
        }
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
        uint256[] memory arr = new uint256[](9);
        arr[0] = paused() ? 0 : 1;
        arr[1] = basePrice;
        arr[2] = maxSupply;
        arr[3] = mintedSupply;
        arr[4] = reservedTotal;
        arr[5] = freeMax;
        arr[5] = freeTotal;
        return arr;
    }

    function getAccount(address addr) public view returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](2);
        arr[0] = reservedAccounts[addr] ? 1 : 0;
        arr[1] = balanceOf(addr);
        return arr;
    }
}