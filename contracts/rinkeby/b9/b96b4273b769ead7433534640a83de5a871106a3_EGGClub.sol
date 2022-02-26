// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721.sol";

contract EGGClub is Ownable, Pausable, ERC721 {
    uint256 private freeMax = 2888;
    uint256 public totalSupply = 2888;
    string private _name = "EGGS-Club";
    string private _symbol = "EGG";
    uint256 private basePrice = 15000000000000000;
    uint256 private mintedSupply = 1;
    mapping(address => bool) private reservedAccounts;
    mapping(address => bool) private freeAccounts;

    constructor() ERC721(_name, _symbol) {
      pause();
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

    function mint(uint256 amount) public payable whenNotPaused {
        require(mintedSupply <= totalSupply, "Max supply reached");
        require(mintedSupply + amount - 1 <= totalSupply, "Exceeds max supply");
        if (mintedSupply + amount - 1 <= freeMax) {
            if (!reservedAccounts[msg.sender]) {
                require(!freeAccounts[msg.sender], "Repeat claim");
                require(amount == 1, "Only 1 at a time");
            }
            mintInner(amount);
        } else {
            require(amount <= 20, "A maximum of 20 at a time");
            if (!reservedAccounts[msg.sender]) {
                require(msg.value >= basePrice * amount, "Not enough ETH sent");
            }
            mintInner(amount);
        }
    }

    function mintInner(uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, mintedSupply);
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
        arr[2] = totalSupply;
        arr[3] = mintedSupply;
        arr[4] = freeMax;
        return arr;
    }

    function getAccount(address addr) public view returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](2);
        arr[0] = reservedAccounts[addr] ? 1 : 0;
        arr[1] = balanceOf(addr);
        return arr;
    }
}