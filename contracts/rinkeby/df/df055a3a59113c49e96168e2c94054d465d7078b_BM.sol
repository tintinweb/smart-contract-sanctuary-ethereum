//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//imports
import "./ERC1155.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
//import '@openzeppelin/contracts/utils/Strings.sol';
//import "@openzeppelin/contracts/access/Ownable.sol";

contract BM is ERC1155, Ownable{
    using Strings for uint256;

    uint256[3] public MAX_SUPPLY = [100, 50, 25];
    uint256[3] public MAX_MINTS = [1, 1, 1];
    uint256[3] public pointsPerId = [1, 2, 4];

    bool public isPublicSale = false; 
    bool public isWhiteListSale = false;

    string public baseURI = "ipfs://QmUhLK6qyR6E8S3Q6QuDELoTbiVwkgtXytqpvcDi9E13zT/";  //change

    bytes32[3] public WLMerkleRoots;

    mapping(address => bool) public approvedContractsToOperate;

    mapping(address => uint256) public pointBalance;
    mapping(address => uint256) public previousSpentPoints;


    constructor() ERC1155(""){}

    modifier callerIsUser(){
        require(tx.origin == _msgSender(), "Only users can interact with this contract!");
        _;
    }

    modifier canOperate(address to){
        require(approvedContractsToOperate[_msgSender()] || _msgSender() == owner() || _msgSender() == to);
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    function setWhitelistRoots(bytes32 bronze, bytes32 silver, bytes32 gold) external onlyOwner{
        WLMerkleRoots[0] = bronze;
        WLMerkleRoots[1] = silver;
        WLMerkleRoots[2] = gold;
    }

    function changeMintAmounts(uint256 bronze, uint256 silver, uint256 gold) external onlyOwner{
        MAX_MINTS[0] = bronze;
        MAX_MINTS[1] = silver;
        MAX_MINTS[2] = gold;
    }

    function increaseSupply(uint256 bronze, uint256 silver, uint256 gold) external onlyOwner{
        MAX_SUPPLY[0] += bronze;
        MAX_SUPPLY[1] += silver;
        MAX_SUPPLY[2] += gold;
    }

    function changePointAmount(uint256 bronze, uint256 silver, uint256 gold) external onlyOwner{
        pointsPerId[0] = bronze;
        pointsPerId[1] = silver;
        pointsPerId[2] = gold;
    }

    function cutSupply() external onlyOwner{
        for(uint256 i = 0; i < MAX_SUPPLY.length; i++){
            MAX_SUPPLY[i] = totalSupply[i];
        }
    }

    //call after all new drops
    function reset() external onlyOwner{
        _resetNumberMinted();
    }

    function availableToMint(uint256 id) external view returns(uint256){
        return MAX_MINTS[id] - _numberMinted(_msgSender(), id);
    }

    function totalBurned(uint256 id) external view returns(uint256){
        return _numberBurned(_msgSender(), id);
    }

    function totalOwned(uint256 id) external view returns(uint256){
        return balanceOf(_msgSender(), id);
    }

    // id
    // 0 = bronze
    // 1 = silver
    // 2 = gold
    function publicMint(uint256 quantity, uint256 id) external callerIsUser{
        require(isPublicSale);
        require(quantity + _numberMinted(_msgSender(), id) <= MAX_MINTS[id], "Exceeded max mints");
        require(totalSupply[id] + quantity <= MAX_SUPPLY[id], "Not enough Tokens");
        _mint(_msgSender(), id, quantity, '');
    }

    // id
    // 0 = bronze
    // 1 = silver
    // 2 = gold
    function whitelistMint(uint256 quantity, bytes32[] calldata proof, uint256 id) external callerIsUser isValidMerkleProof(proof, WLMerkleRoots[id]){
        require(isWhiteListSale);
        require(quantity + _numberMinted(_msgSender(), id) <= MAX_MINTS[id], "Exceeded max mints");
        _mint(_msgSender(), id, quantity, '');
        MAX_SUPPLY[id] += quantity;
    }


    function ownerMint(uint256 quantity, uint256 id) external onlyOwner{
        _mint(_msgSender(), id, quantity, '');
        MAX_SUPPLY[id] += quantity;
    }

    function setBaseURI(string memory newURI) public onlyOwner{
        baseURI = newURI;
    }

    function uri(uint256 tokenId) public override view returns(string memory){
        uint256 realId = tokenId + 1;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, realId.toString(), ".json")) : "";
    }

    function setPublicSale(bool shouldStartPublicSale) public onlyOwner{
        isPublicSale = shouldStartPublicSale;
    }

    function setWhiteListSale(bool shouldStartWhiteListSale) public onlyOwner{
        isWhiteListSale = shouldStartWhiteListSale;
    }

    function burnToken(address to, uint256 id, uint256 amount) external { 
        require(to == _msgSender());
        _burn(to, id, amount);
        pointBalance[to] += (pointsPerId[id] * amount);
    }

    function spendPoints(address to, uint256 amount) external canOperate(to){
        pointBalance[to] -= amount;
        previousSpentPoints[to] += amount;
    }

    function addOperatorContract(address contractAddress) public onlyOwner{
        approvedContractsToOperate[contractAddress] = true;
    }
}