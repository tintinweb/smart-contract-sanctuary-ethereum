// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import "./ERC721.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
/**
 * @title Unstoppable
 * @author Razzor (https://twitter.com/razzor_tweet)
 */
contract Unstoppable is ERC721("Unstoppable", "UNS"){
    using Counters for Counters.Counter;
    using SafeMath for uint8;
    Counters.Counter private _tokenIdCounter;
    address public owner;
    address public winner;
    bool winnerAnnounced;
    uint64 public constant TOKEN_PRICE = 576460752303423488; 
    uint public constant MAX_TOKEN_REQUEST = 20; 
    IERC20 public token;

    bool public isSaleActive;
    mapping(address => bool) internal tokensOwned;
    mapping(address=> bool) internal hasPaid;
    mapping(address=> bool) internal hasExecuted;

    constructor(address _token){
        owner = msg.sender;
        token = IERC20(_token);

    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }
    function buyNFTs(uint numtokens) external{
        require(isSaleActive, "Optimistic Sale has not yet started");
        require(numtokens <= MAX_TOKEN_REQUEST, "MAX_TOKEN_REQUEST per transaction exceeded");
        require(!tokensOwned[msg.sender], "Already Requested");
        for (uint256 i = 0; i < numtokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
        tokensOwned[msg.sender] = true;

    }

    function getVerified() external payable{
        uint userBalance = balanceOf(msg.sender);
        require(userBalance > 15, "You could have read the code first, instead of blindly buying NFTs");
        require(msg.value == balanceOf(msg.sender).mul(TOKEN_PRICE) , "Need verification token? Pay Money. Strategy 101");
        hasPaid[msg.sender] = true;
    } 


    function execute(address to) external{
        require(hasPaid[msg.sender], "Everything comes with a price");
        require(!hasExecuted[msg.sender], "Already executed");
        uint balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, balance);
        hasExecuted[msg.sender] = true;
        if(!winnerAnnounced){
            winner = msg.sender;
            winnerAnnounced = true;
        }
        
    }

    function fundsAvailable() external view returns(uint){
        return token.balanceOf(address(this));
    }

    function toggleSale() external onlyOwner{
        isSaleActive = !isSaleActive;
    }

    function toggleWinnerAnnounced() external onlyOwner{
        winnerAnnounced = !winnerAnnounced;
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
        //Say Hi to me!
        return "https://twitter.com/razzor_tweet";
    }

    function transferOwnership(address newOwner) external onlyOwner{
        owner = newOwner;
    }

    function recoverFunds(address payable to) external onlyOwner{
        uint ethers = address(this).balance;
        to.transfer(ethers);
        uint usdc = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, usdc);
        
    }

    fallback() external payable{

    }
    
        
}