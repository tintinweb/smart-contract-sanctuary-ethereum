// SPDX-License-Identifier: MIT
/*
Visit https://www.wagmiestates.com/ for project details.
Contract Developed by https://hcode.tech/
*/

pragma solidity ^0.8.2;
import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract WagmiBlueprint is ERC1155, Ownable, ERC1155Burnable {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    string public _tokenUri = "https://gateway.pinata.cloud/ipfs/QmNyWcDafngvXukB8fYYZ8LuLLCoKnMXLHFLPASaFvub9s";
    uint256 private maxSupply = 6000;
    uint256 public mintedCount = 0;
    uint256 private constant TOKEN_ID = 0;
    uint256 public publicSalePrice = 250000000000000000;
    uint256 public privateSalePrice = 200000000000000000;
    bool public privateSale = false;
    bool public publicSale = false;
    bytes32 private merkleRootHash =0xc38224bae8a2646e4f854bf642f5818b6fe01f00549932e3445bd536ff877c1e;
    address private wagmiExchangeContract;
    uint256 private privateMaxSupply = 1000; // setter only owner

    constructor() ERC1155(_tokenUri) {
        name = "WAGMI Estates";
        symbol = "WAG";
    }

    function pauseSale() public onlyOwner {
        privateSale = false;
        publicSale = false;
    }

    // toggle functions to change bool varibales
    function togglePrivateSale() public onlyOwner {
        privateSale = !privateSale;
        if (privateSale) {
            publicSale = false;
        }
    }

    function togglePublicSale() public onlyOwner {
        publicSale = !publicSale;
        if (publicSale) {
            privateSale = false;
        }
    }

    // setters for different limits

    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        maxSupply = maxSupply_;
    }

    function setPrivateMaxSupply(uint256 maxSupply_) public onlyOwner {
        privateMaxSupply = maxSupply_;
    }

    function setMerkleRoot(bytes32 rootHash) public onlyOwner {
        merkleRootHash = rootHash;
    }

    function setWagmi721Address(address wagmiContractAddress) public onlyOwner {
        wagmiExchangeContract = wagmiContractAddress;
    }

    function setPrivateSalePrice(uint256 price) public onlyOwner {
        require(price > 0, "price must be greater than 0");
        privateSalePrice = price;
    }

    function setPublicSalePrice(uint256 price) public onlyOwner {
        require(price > 0, "price must be greater than 0");
        publicSalePrice = price;
    }

    function mintBlueprintToken(uint256 amount, bytes32[] calldata _merkleProof)
        public
        payable
    {
        require(publicSale || privateSale, "Sale is not started");
        uint256 tokenPrice = publicSalePrice;
        require(
            amount <= 5 && amount >= 1,
            "Max mint per tras. exceeded"
        );
        require(amount.add(mintedCount) <= privateMaxSupply, "Sale Max Limit reached");
        require(amount.add(mintedCount) <= maxSupply, "Max Supply Limit reached");

        // handle private sale mint process
        if (privateSale) {
            tokenPrice = privateSalePrice;
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProof.verify(_merkleProof, merkleRootHash, leaf),
                "You are not whitelisted"
            );
            
        }
        //handle public sale process
        else {
            require(publicSale, "Public Sale is not live!");
        }

        

        require(msg.value >= tokenPrice.mul(amount), "Not enough ETH sent");

        _mint(msg.sender, TOKEN_ID, amount, "");
        mintedCount = mintedCount.add(amount);
    }

    function withdrawFunds() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


    function burnForRedeem(address account, uint256 amount) external {
        require(
            wagmiExchangeContract == msg.sender,
            "You are not allowed to redeem"
        );
        _burn(account, TOKEN_ID, amount);
    }

    function airdropGiveaway(address to, uint256 amountToMint)
        public
        onlyOwner
        returns (uint256 tokId)
    {
        require(amountToMint.add(mintedCount) <= maxSupply, "Limit reached");
        mintedCount = mintedCount.add(amountToMint);
        _mint(to, TOKEN_ID, amountToMint, "");
        return TOKEN_ID;
    }
}