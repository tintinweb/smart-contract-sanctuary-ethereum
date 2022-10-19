// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC721OnlyTransfer {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155Balance {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract AxoloClaim {

    address private constant NFTCONTRACT = 0xE654c573B1858Ca16d7E4CFd7EB549085C003b36;
    address private constant PITBOSSCONTRACT = 0x15f34505793B434B61BB1918a8f5d422Ca03abef;
    
    bool private claimActive = true;

    IERC721OnlyTransfer nftToken = IERC721OnlyTransfer(NFTCONTRACT);
    IERC1155Balance pitboss = IERC1155Balance(PITBOSSCONTRACT);

    address private _owner;
    address private _manager;

    uint256 private tokenId = 1000;
    uint256 private immutable totalTokens = 2000;

    mapping(address => bool) private claims;

    constructor(address manager) {
        _owner = msg.sender;
        _manager = manager;
    }

    function toogleSale() public  {
        require(msg.sender == _owner, "Only the owner can toggle the claim");
        claimActive = !claimActive;
    }

    function getAmountToClaim(address account) public view returns (uint256 amount) {
        require(claimActive, "Claim is not active");
        require(tokenId <= totalTokens, "Claim is over");

        amount = pitboss.balanceOf(account, 0);
      
        require(amount > 0 && claims[account] == false, "No PitBoss to Claim.");
        
        return amount;
      
    }

  function claim() external {
        uint256 i;
        uint256 amount = pitboss.balanceOf(msg.sender, 0);
        
        do {
            nftToken.safeTransferFrom(_manager, msg.sender, tokenId);
            tokenId++;
            i++;
        } while (i < amount);
       
     
    }
}