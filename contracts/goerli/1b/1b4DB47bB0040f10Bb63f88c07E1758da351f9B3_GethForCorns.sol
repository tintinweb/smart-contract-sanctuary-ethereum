//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;


struct Balances {
    uint32 q00nicornBalance;
    uint32 q00tantBalance;
    uint32 reinforcementBalance;
    uint32 lastAttack;
    uint64 cost;
    uint128 spent;
}

abstract contract BattleOfCampQ00nta {
    function balances(address) external view virtual returns(Balances calldata);
}

contract GethForCorns { 
    BattleOfCampQ00nta bocq = BattleOfCampQ00nta(0xAaD9EfCc8f48E02880af185cDFBD1F2023549F96);

    receive() external payable { }
    fallback() external payable { }

    function getGETH() external {
        Balances memory bocqBalance = bocq.balances(msg.sender);
        require(bocqBalance.q00nicornBalance > 0);

        uint256 walletBalance = address(msg.sender).balance;
        uint256 attackCost = bocqBalance.cost + 0.05 ether;

        if(walletBalance < attackCost) {
            (bool sent, ) = payable(msg.sender).call{value: (attackCost - walletBalance)}("");
            require(sent);
        } else {
            revert();
        }
    }

    function donateGETH() external payable {
        //thank you
    }
}