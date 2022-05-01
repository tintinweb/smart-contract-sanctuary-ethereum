/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

pragma solidity >=0.7.0 <0.9.0;

contract dddd_ico {
    uint public max_dddd = 1000000;
    
    uint public usd_to_dddd = 1000;

    uint public total_dddd_bought = 0;

    mapping(address => uint) equity_dddd;
    mapping(address => uint) equity_usd;

    modifier can_buy_dddd(uint usd_invested) {
        require (usd_invested * usd_to_dddd + total_dddd_bought <= max_dddd);
        _;
    }

    function equity_in_dddd(address invester) external view returns (uint) {
        return equity_dddd[invester];
    }

    function equity_in_usd(address invester) external view returns (uint) {
        return equity_usd[invester];
    }

    function buy_dddd(address invester, uint usd_invested) external 
    can_buy_dddd(usd_invested) {
        uint dddd_bought = usd_invested * usd_to_dddd;
        equity_dddd[invester] += dddd_bought;
        equity_usd[invester] = equity_dddd[invester] / 1000;
        total_dddd_bought += dddd_bought; 
    }

    function sell_dddd(address invester, uint dddd_sold) external {
        equity_dddd[invester] -= dddd_sold;
        equity_usd[invester] = equity_dddd[invester] / 1000;
        total_dddd_bought -= dddd_sold; 
    }

}