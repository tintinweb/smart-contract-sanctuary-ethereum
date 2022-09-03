// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import "./ERC721.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./libGambler.sol";
/**
 * @title Gambler
 * @author Razzor (https://ciphershastra.com/Gambler)
 */
contract Gambler is ERC721("Gambler", "$$$"){
    using Counters for Counters.Counter;
    using SafeMath for uint8;
    using libGambler for uint;

    Counters.Counter private _chipIdCounter;
    address account;
    uint64 public constant CHIP_PRICE = 576460752303423488; 
    uint public constant MAX_CHIP_REQUEST = 20; 

    bool public isSaleActive;
    mapping(address => bool) internal chipsOwned;
    mapping(address=> bool) internal hasPaid;
    mapping(address => uint[]) public allIds;
    mapping(address=>bool) public Gambler;
    constructor(){
        account = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == account, "Not Owner");
        _;
    }
    function buyChips(uint numChips) external{
        require(isSaleActive, "Optimistic Sale has not yet started");
        require(numChips <= MAX_CHIP_REQUEST, "MAX_CHIP_REQUEST per transaction exceeded");
        require(!chipsOwned[msg.sender], "Already Requested");
        for (uint256 i = 0; i < numChips; ++i) {
            uint256 chipId = _chipIdCounter.current();
            _chipIdCounter.increment();
            _safeMint(msg.sender, chipId);
            allIds[msg.sender].push(chipId);

        }
        chipsOwned[msg.sender] = true;

    }

    function getVerified() external payable{
        uint8 userBalance = balanceOf(msg.sender);
        require(userBalance > 15, "You could have read the code first, instead of blindly buying NFTs");
        require(msg.value == userBalance.mul(CHIP_PRICE) , "Need Chips? Pay Money. Strategy 101");
        hasPaid[msg.sender] = true;
    } 

    function doubleOrNothing(address acount, uint bet) external{
        require(hasPaid[msg.sender],"No Money, No Fun");
        address to;
        uint8 numChips = balanceOf(msg.sender);

        if(!bet.rollDice(acount)){
            for (uint256 i = 0; i < numChips; ++i) {
            uint256 chipId = allIds[msg.sender][i];
            require(msg.sender == ERC721.ownerOf(chipId),"Not Owner"); //Sanity Check
            _burn(chipId);
            }
            delete allIds[msg.sender];
            hasPaid[msg.sender]=false;
            chipsOwned[msg.sender] = false;

        }
        else{
            if(acount!=address(0x0)){
                to = account;
            }
            else{
                to = msg.sender;
            }

            _balances[to] = _balances[to].add(numChips);
            for(uint256 i = 0; i< numChips; ++i){
                uint256 chipId = _chipIdCounter.current();
                require(!_exists(chipId), "ERC721: chip already minted");
                _chipIdCounter.increment();
                _owners[chipId] = to;
                allIds[to].push(chipId);
                emit Transfer(address(0), to, chipId);
                }
            Gambler[to]=true;
        }
    }

    function toggleSale() external onlyOwner{
        isSaleActive = !isSaleActive;
    }

    function recoverFunds() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
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
        return "https://ciphershastra.com/Gambler";
    }

    function transferOwnership(address newOwner) external onlyOwner{
        account = newOwner;
    }

    fallback() external payable{

    }
    
        
}