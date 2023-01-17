// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

import "Ownable.sol";

contract RafPrice is Ownable{

    int raf_price;
    int gold_price;
    int project_returns;
    int raf_in_circulation;
    int gold_investment_weight = 30;
    int projects_investment_weight = 60;
    int raf_holders_weight = 10;
    uint decimals = 36;
    int raf_in_circulation_variation;
    int gold_variation;
    int project_returns_variation;

    function set_raf_price(int new_gold_price, int project_returns_new_value, int raf_in_circulation_new_value) external onlyOwner {
        int project_returns_variation_divisor=1;
        if(project_returns > 0){
            project_returns_variation_divisor = project_returns;
        }
        raf_in_circulation_variation = (((raf_in_circulation_new_value - raf_in_circulation)*10e36/raf_in_circulation)*raf_holders_weight)/100;
        gold_variation = (((new_gold_price - gold_price)*10e36/gold_price)*gold_investment_weight)/100;
        project_returns_variation = (((project_returns_new_value - project_returns)*10e36/project_returns_variation_divisor)*projects_investment_weight)/100;
        raf_price = (raf_price*10e36 + raf_in_circulation_variation + gold_variation + project_returns_variation)/10e36 ;
        gold_price = new_gold_price;
        project_returns = project_returns_new_value;
        raf_in_circulation = raf_in_circulation_new_value;
    }

    function get_raf_price() public view returns (int) {
        return raf_price;
    }

    function get_gold_variation() public view returns (int) {
        return gold_variation;
    }

    function get_decimals() public view returns (uint) {
        return decimals;
    }

    function get_gold_price() public view returns (int) {
        return gold_price;
    }

    function set_gold_price(int new_gold_price) external onlyOwner {
        gold_price = new_gold_price;
    }

    function get_raf_in_circulation() public view returns (int) {
        return raf_in_circulation;
    }

    function set_raf_in_circulation(int raf_in_circulation_new_value) external onlyOwner {
        raf_in_circulation = raf_in_circulation_new_value;
    }

    function get_project_returns() public view returns (int) {
        return project_returns;
    }

    function set_project_returns(int project_returns_new_value) external onlyOwner {
        project_returns = project_returns_new_value;
    }

    function set_raf_initial_price(int price_in_usd) external onlyOwner {
        raf_price = price_in_usd;
    }
}