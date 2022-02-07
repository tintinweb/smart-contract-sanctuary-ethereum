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

abstract contract WagmiExchangeInterface {
    function mint721(address to, uint256 tokenId)
        public
        payable
        virtual
        returns (uint256[] memory minttokenId);
}

contract WagmiBlueprint is ERC1155, Ownable, ERC1155Burnable {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    string public _tokenUri = "https://gateway.pinata.cloud/ipfs/QmYoQVMqCNMCthGjUqBPgehoexwsACBqKq5X9Le5GXYDTX";
    uint256 private maxSupply = 6000;
    uint256 private mintedCount = 0;
    uint256 private constant TOKEN_ID = 0;
    uint256 public publicSalePrice = 250000000000000000;
    uint256 public privateSalePrice = 200000000000000000;
    bool public privateSale = false;
    bool public publicSale = false;
    bool public exchangeStarted = false;
    uint256 private maxMintPerTransactionPublicSale = 5;
    uint256 private maxMintPerTransactionPrivateSale = 5;
    bytes32 private merkleRootHash =
        0x4bb51f8b86c3d881bfa6722c50220f33cdafb66903a92d1e72fbaa83b006e0b7;
    address private wagmiExchangeContract;
    uint256 private privateMaxSupply = 1000; // setter only owner

    constructor() ERC1155(_tokenUri) {
        name = "WAGMI";
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

    function toggleExchangeStarted() public onlyOwner {
        exchangeStarted = !exchangeStarted;
    }

    // setters for different limits

    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        maxSupply = maxSupply_;
    }

    function setMaxMintPerTransactionPublicSale(uint256 limit)
        public
        onlyOwner
    {
        maxMintPerTransactionPublicSale = limit;
    }

    function setMaxMintPerTransactionPrivateSale(uint256 limit)
        public
        onlyOwner
    {
        maxMintPerTransactionPrivateSale = limit;
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
        uint256 maxMintPerTransaction = maxMintPerTransactionPublicSale;
        require(amount.add(mintedCount) <= maxSupply, "Limit reached");
        // handle private sale mint process
        if (privateSale) {
            tokenPrice = privateSalePrice;
            maxMintPerTransaction = maxMintPerTransactionPrivateSale;
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProof.verify(_merkleProof, merkleRootHash, leaf),
                "You are not whitelisted"
            );
            require(
                amount.add(mintedCount) <= privateMaxSupply,
                "Private Sale Max Limit reached"
            );
        }
        //handle public sale process
        else {
            require(publicSale, "Public Sale is not live!");
        }

        require(
            amount <= maxMintPerTransaction && amount >= 1,
            "Max mint per tras. exceeded"
        );

        require(
            msg.value >= tokenPrice.mul(amount),
            "Not enough ETH sent"
        );

        _mint(msg.sender, TOKEN_ID, amount, "");
        mintedCount = mintedCount.add(amount);
    }

    function withdrawFunds() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function exchangeBlueprint(uint256 amount)
        public
        returns (uint256[] memory new721TokenId)
    {
        require(exchangeStarted, "Exchange not started yet");
        _burn(msg.sender, TOKEN_ID, amount);
        WagmiExchangeInterface wagmiExchange = WagmiExchangeInterface(
            wagmiExchangeContract
        );
        new721TokenId = wagmiExchange.mint721(msg.sender, amount);
        return new721TokenId;
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