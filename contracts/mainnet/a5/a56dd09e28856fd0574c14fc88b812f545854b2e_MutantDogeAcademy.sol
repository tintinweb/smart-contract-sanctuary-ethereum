// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721Enumerable.sol";

contract MutantDogeAcademy is ERC721Enumerable,Ownable{
    string public baseURI;
    uint256 public constant MAX_QUANTITY = 5555;
    uint256 private constant GOLD_FREE_COUNT = 2;
    uint256 private constant PRSALE_MINT_PRICE = 0.05 * 10**18;
    uint256 private constant PRSALE_FEE_AMOUNT = 10;
    uint256 private mintPrice = 0.1 * 10**18;
    uint256 private silverMintPrice = 0.05 * 10**18;
    uint256 private goldMintPrice = 0.03 * 10**18;
    uint256 private silverOGMintPrice = 0.01 * 10**18;
    address public onwer;
    bytes32 public goldWlMerkleRoot;
    bytes32 public silverWlMerkleRoot;
    bytes32 public goldOGMerkleRoot;
    bytes32 public silverOGMerkleRoot;
    enum Status { PRESALE_LIVE, SALE_LIVE }
    Status public state;
    mapping(address => uint256) preSalemintedAmount;
    mapping(address => uint256) public mintedTotal;


    constructor(string memory _baseInitURI,bytes32 _merkleRootGoldWL,bytes32 _merkleRootSilverdWL,bytes32 _merkleRootGoldOG,bytes32 _merkleRootSilverOG) ERC721("Mutant Doge Academy", "MDA") {
            baseURI=_baseInitURI;
            onwer=msg.sender;
            goldWlMerkleRoot=_merkleRootGoldWL;
            silverWlMerkleRoot=_merkleRootSilverdWL;
            goldOGMerkleRoot=_merkleRootGoldOG;
            silverOGMerkleRoot=_merkleRootSilverOG;
            _internalMint(address(this), 1 );
    }


    function mint(address to,uint256 amount,bytes32[] memory proof)public payable{
        require(amount >= 1,"The parameter you passed in is incorrect");
        if(state == Status.PRESALE_LIVE){
            require(preSalemintedAmount[to] + amount <= 1,"you exceeded the pre-sale volume");
            require(msg.value >= PRSALE_MINT_PRICE * amount , "You must pay enough to complete the minting");
            preSalemintedAmount[to]+=amount;
        }else if(preSalemintedAmount[to] == 1){
            if(_verify(to,goldOGMerkleRoot,proof)){
                if(mintedTotal[to] >= PRSALE_FEE_AMOUNT + GOLD_FREE_COUNT + preSalemintedAmount[to] ){
                require(msg.value >= silverOGMintPrice * amount, "You must pay enough to complete the minting"); 
                }else if(mintedTotal[to]  + amount > PRSALE_FEE_AMOUNT + GOLD_FREE_COUNT + preSalemintedAmount[to]){
                require(msg.value >= silverOGMintPrice * (mintedTotal[to]  + amount - PRSALE_FEE_AMOUNT - GOLD_FREE_COUNT - preSalemintedAmount[to]), "You must pay enough to complete the minting");
                }
            }else if(mintedTotal[to] >= PRSALE_FEE_AMOUNT + preSalemintedAmount[to]){
                 require(msg.value >= silverOGMintPrice * amount,"You must pay enough to complete the minting");
            }else if(mintedTotal[to] + amount > PRSALE_FEE_AMOUNT + preSalemintedAmount[to]){
                 require(msg.value >= silverOGMintPrice * (mintedTotal[to] + amount - PRSALE_FEE_AMOUNT - preSalemintedAmount[to]),"You must pay enough to complete the minting");
            }
        }else if(_verify(to,goldOGMerkleRoot,proof)){
            if(mintedTotal[to] >= GOLD_FREE_COUNT){
            require(msg.value >= silverOGMintPrice * amount, "You must pay enough to complete the minting");
            }else if(mintedTotal[to]  + amount > GOLD_FREE_COUNT){
            require(msg.value >= silverOGMintPrice * (mintedTotal[to]  + amount - GOLD_FREE_COUNT), "You must pay enough to complete the minting");
            }
        }else if(_verify(to,silverOGMerkleRoot,proof)){
            require(msg.value >= silverOGMintPrice,"You must pay enough to complete the minting");
        }else if(_verify(to,goldWlMerkleRoot,proof)){
            require(msg.value >= goldMintPrice * amount, "You must pay enough to complete the minting");
        }else if(_verify(to,silverWlMerkleRoot,proof)){
            require(msg.value >= silverMintPrice * amount, "You must pay enough to complete the minting");
        }else{
            require(msg.value >= mintPrice * amount, "You must pay enough to complete the minting");
        }
            _internalMint(to,amount);
    }

    
    function _verify(address to,bytes32 root,bytes32[] memory proof)
    internal pure returns (bool)
    {
        bytes32 leaf= keccak256(abi.encodePacked(to));
        return MerkleProof.verify(proof, root, leaf);
    }

    function onlyOwnerMint(address to,uint256 amount) public onlyOwner{
       _internalMint(to,amount);
    }

    function _internalMint(address to,uint256 amount) private {
        require(totalSupply()+amount <= MAX_QUANTITY,"The casting quantity has been completed");
        payable(onwer).transfer(msg.value);
        uint256 tokenId = totalSupply();
        for(uint256 i =1; i <= amount; i++){
            tokenId++;
            mintedTotal[to]+=1;
            _safeMint(to,tokenId);
        }
    }

    function presaleOf(address to) public view returns(uint256){
        return preSalemintedAmount[to];
    }


    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function withdrawToAddress(address recipient) external onlyOwner{
        Address.sendValue(payable(recipient), address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setGoldWLmerkleRoot(bytes32 _goldWLmerkleRoot)public onlyOwner{
        goldWlMerkleRoot = _goldWLmerkleRoot;
    }

    function setSilverWLmerkleRoot(bytes32 _silverWLmerkleRoot)public onlyOwner{
        silverWlMerkleRoot = _silverWLmerkleRoot;
    }

    function setGoldOGmerkleRoot(bytes32 _goldOGmerkleRoot)public onlyOwner{
        goldOGMerkleRoot = _goldOGmerkleRoot;
    }

    function setSilverOGmerkleRoot(bytes32 _silverOGmerkleRoot)public onlyOwner{
        silverOGMerkleRoot = _silverOGmerkleRoot;
    }

    function setAllMerkleRott(bytes32 _merkleRootGoldWL,bytes32 _merkleRootSilverdWL,bytes32 _merkleRootGoldOG,bytes32 _merkleRootSilverOG)public onlyOwner{
            goldWlMerkleRoot=_merkleRootGoldWL;
            silverWlMerkleRoot=_merkleRootSilverdWL;
            goldOGMerkleRoot=_merkleRootGoldOG;
            silverOGMerkleRoot=_merkleRootSilverOG;
    }

    function setSaleState(Status _state) external onlyOwner {
        state = _state;
    }


}