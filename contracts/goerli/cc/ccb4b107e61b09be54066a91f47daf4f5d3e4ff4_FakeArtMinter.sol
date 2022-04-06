/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

pragma solidity 0.8.13;


contract FakeArtMinter {
    event FakeArtMinted(address sender, uint256 tokenId);
    uint256 constant COST_OF_ART = 0.003 ether;
    bool public isMintable;
    uint public mintCount;
    mapping(address => uint) public tokenBalance;
    address payable public owner;
    constructor() {
        owner = payable(msg.sender);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "INSUFFICIENT_PERMISSIONS");
        _;
    }
    function toggleMintable() external onlyOwner
    {
        isMintable = !isMintable;
    }
    function mint() external payable {
        require(msg.value == COST_OF_ART);
        require(isMintable, "COLLECTION_NOT_MINTABLE");
        tokenBalance[msg.sender]++;
        mintCount++;
        owner.transfer(msg.value);
    }

    function transferFrom(uint _amount, address _to) external {
        require(tokenBalance[msg.sender] >= _amount);
        tokenBalance[msg.sender] -= _amount;
        tokenBalance[_to] += _amount;
    }
}