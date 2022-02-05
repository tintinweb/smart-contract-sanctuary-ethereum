// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";



abstract contract WagmiExchangeInterface{
    function mint721(address to ,uint tokenId) public payable virtual returns(uint256[] memory minttokenId);
}

contract WagmiBlueprint is ERC1155 , Ownable , ERC1155Burnable {
    using SafeMath for uint256;
    string public constant name = "WAGMI";
    string public constant symbol = "WAG";
    string public constant _tokenUri = "ipfs://QmYS4BxwcEDY2EC1GiCd5oWBP4wHm2xbhFJHJguV4sfrFU";
    uint256 maxSupply = 6000;
    uint256 mintedCount = 0;
    uint256 TOKEN_ID = 0;
    uint public publicSalePrice = 250000000000000000;
    uint public privateSalePrice = 250000000000000000;
    bool public privateSale = false;
    bool public publicSale = false;
    bool public exchangeStarted = false;
    uint256 maxMintPerTransactionPublicSale=5;
    uint256 maxMintPerTransactionPrivateSale=5;
    bytes32 merkleRootHash = 0x36b69b1d655496588284f906441b1c2a32a0a5b6153d3d11bf20d4dc1fc45e91;
    address private wagmiExchangeContract;
  
    constructor() ERC1155(_tokenUri){        
    }


    function pauseSale() public onlyOwner{
        privateSale=false;
        publicSale=false;
    }


// toggle functions to change bool varibales
    function togglePrivateSale() public onlyOwner{
        privateSale = !privateSale;
        if(privateSale){
            publicSale=false;
        }
        
    }

    function togglePublicSale() public onlyOwner{
        publicSale = !publicSale;
        if(publicSale){
            privateSale=false;
        }
    }

    function toggleExchangeStarted() public onlyOwner{
        exchangeStarted = !exchangeStarted;
    }

    function setMaxSupply(uint256 max_supply) public onlyOwner{
        maxSupply = max_supply;
    }

    // setters for different limits
    function setMaxMintPerTransactionPublicSale(uint256 limit) public onlyOwner{
        maxMintPerTransactionPublicSale = limit;
    }

    function setMaxMintPerTransactionPrivateSale(uint256 limit) public onlyOwner{
        maxMintPerTransactionPrivateSale = limit;
    }

    function setMerkleRoot(bytes32 rootHash) public onlyOwner {
        merkleRootHash = rootHash;
    }

    function setWagmi721Address(address addr) public onlyOwner{
        wagmiExchangeContract = addr;
    }

    function setPrivateSalePrice(uint256 price) public onlyOwner{
        require(price > 0,"price must be greater than 0");
        privateSalePrice = price;
    }

        function setPublicSalePrice(uint256 price) public onlyOwner{
        require(price > 0,"price must be greater than 0");
        publicSalePrice = price;
    }



    function mintBlueprintToken(uint256 amount , bytes32[] calldata _merkleProof) public payable returns(uint256) {
        
        require(publicSale || privateSale,"Sale is not started");
        uint256 tokenPrice = publicSalePrice;
        uint256 maxMintPerTransaction = maxMintPerTransactionPublicSale;
        require(amount + mintedCount <= maxSupply,"Limit reached");
        // handle private sale mint process
        if(privateSale){
            tokenPrice = privateSalePrice;
            maxMintPerTransaction = maxMintPerTransactionPrivateSale;
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));            
            require(MerkleProof.verify(_merkleProof,merkleRootHash,leaf),"You are not whitelisted");
        }
        //handle public sale process
        else{
            require(publicSale,"Public Sale is not live!");
        }
        
        require(amount <= maxMintPerTransaction && amount >=1,
                string(abi.encodePacked("You have to mint between ",
                Strings.toString(1) ,
                " to ",
                Strings.toString(maxMintPerTransaction),
                " at a time")
            ));

        require(msg.value >=tokenPrice.mul(amount),
            string(abi.encodePacked("Not enough ETH sent. Minimum required is ",
            Strings.toString(tokenPrice), " ETH"
            )));
            
        _mint(msg.sender, TOKEN_ID, amount, "");
        mintedCount += amount;
        return TOKEN_ID;
    }

    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function exchangeBlueprint(uint256 amount) public returns(uint256[] memory new721TokeId){
        require(exchangeStarted,"Exchange Program is not started yet");
        require(this.balanceOf(msg.sender, TOKEN_ID) >= amount ,"You don't own {} amount of this tokenId");
        _burn(msg.sender, TOKEN_ID, amount);
        WagmiExchangeInterface wagmiExchange = WagmiExchangeInterface(wagmiExchangeContract);
        new721TokeId =  wagmiExchange.mint721(msg.sender, amount);
        return new721TokeId;
}

function airdropGiveaway(address to, uint256 amountToMint) public onlyOwner returns(uint256 tokId) {
        require(amountToMint + mintedCount <= maxSupply, "Limit reached");
        mintedCount = mintedCount + amountToMint;
        _mint(to, TOKEN_ID, amountToMint, "");
        return TOKEN_ID;
    }

}