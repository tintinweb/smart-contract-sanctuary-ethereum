// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

import "Ownable.sol";

contract RafPrice is Ownable{
    uint raf_price;
    uint gold_price;
    uint project_returns;
    uint raf_in_circulation;
    uint gold_investment_weight = 300000000000000000;
    uint projects_investment_weight = 600000000000000000;
    uint raf_holders_weight = 100000000000000000;
    uint decimals = 18;

    function set_raf_price(uint new_gold_price, uint project_returns_new_value, uint raf_in_circulation_new_value) external onlyOwner {
        raf_price = raf_price + (new_gold_price - gold_price)*gold_investment_weight + (raf_in_circulation_new_value - raf_in_circulation)*raf_holders_weight  + (project_returns_new_value - project_returns)*projects_investment_weight ;
        gold_price = new_gold_price;
        project_returns = project_returns_new_value;
        raf_in_circulation = raf_in_circulation_new_value;
    }

    function get_raf_price() public view returns (uint) {
        return raf_price;
    }

    function get_decimals() public view returns (uint) {
        return decimals;
    }

    function get_gold_price() public view returns (uint) {
        return gold_price;
    }

    function set_gold_price(uint new_gold_price) external onlyOwner {
        gold_price = new_gold_price;
    }

    function get_raf_in_circulation() public view returns (uint) {
        return raf_in_circulation;
    }

    function set_raf_in_circulation(uint raf_in_circulation_new_value) external onlyOwner {
        raf_in_circulation = raf_in_circulation_new_value;
    }

    function get_project_returns() public view returns (uint) {
        return project_returns;
    }

    function set_project_returns(uint project_returns_new_value) external onlyOwner {
        project_returns = project_returns_new_value;
    }

    function set_raf_initial_price(uint price_in_usd) external onlyOwner {
        raf_price = price_in_usd;
    }
}