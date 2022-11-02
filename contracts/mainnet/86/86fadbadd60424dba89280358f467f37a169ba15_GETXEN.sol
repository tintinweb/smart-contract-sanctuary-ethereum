/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IXEN1{
    function claimRank(uint256 term) external;
    function claimMintReward() external;
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IXEN2{
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract GET{
    IXEN1 private constant xen = IXEN1(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8);

    constructor() {
        xen.approve(msg.sender,~uint256(0));
    }
    
    function claimRank(uint256 term) public {
        xen.claimRank(term);
    }

    function claimMintReward() public {
        xen.claimMintReward();
        selfdestruct(payable(tx.origin));
    }
}

contract GETXEN {
    mapping (address=>mapping (uint256=>address[])) public userContracts;
    IXEN2 private constant xen = IXEN2(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8);

    function claimRank(uint256 times, uint256 term) external {
        address user = tx.origin;
        for(uint256 i; i<times; ++i){
            GET get = new GET();
            get.claimRank(term);
            userContracts[user][term].push(address(get));
        }
    }

    function claimMintReward(uint256 times, uint256 term) external {
        address user = tx.origin;
        for(uint256 i; i<times; ++i){
            uint256 count = userContracts[user][term].length;
            address get = userContracts[user][term][count - 1];
            GET(get).claimMintReward();
            address owner = tx.origin;
            uint256 balance = xen.balanceOf(get);
            xen.transferFrom(get, owner, balance);
            userContracts[user][term].pop();
        }
    }
}