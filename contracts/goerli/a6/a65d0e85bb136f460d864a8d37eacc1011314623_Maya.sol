//creator: @razzor_tweet
pragma solidity ^0.8.0;

import "./Address.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";
import "./SafeERC20.sol";
import "./ERC721.sol";
import "./Counters.sol";
contract Maya is ERC721("MAYA", "MAYA"){
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    IERC20 public token;
    uint public price;
    address public owner;

    mapping(address => uint[]) public allIds;

    constructor(address _token, uint _price){
        token = IERC20(_token);
        price = _price;
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Not the Owner");
        _;
    }

    function buy() external{
        require(token.balanceOf(msg.sender)>=price, "Insufficient balance");
        require(token.allowance(msg.sender, address(this)) >= price, "Insufficient Allowance");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);
        allIds[msg.sender].push(tokenId);
        token.safeTransferFrom(msg.sender, address(this), price);
    }

    function burnMaya() external {
        require(balanceOf(msg.sender)>0,"No Ids to burn");
        uint length = allIds[msg.sender].length;
        for(uint i=0;i<length;++i){
            uint tokenId = allIds[msg.sender][i];
            _burn(tokenId);
        }

        delete allIds[msg.sender];
        
    }

    function setPrice(uint _price) external onlyOwner{
        price = _price;
    }

    function hunter() external view returns(string memory){
        uint balance = balanceOf(msg.sender);
        if (balance > 2){
            return "Seems like you have figured it out? Hunter!";
        }

        else if(balance > 0){
            return "Oh wow! You got Maya!";
        }
        else {
            return "Buy one at least?";
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        revert("Don't cheat the system!");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        revert("Don't cheat the system!");

    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "https://ciphershastra.com/Maya.html";
    }

    function transferOwnership(address newOwner) external onlyOwner{
        owner = newOwner;
    }    
}