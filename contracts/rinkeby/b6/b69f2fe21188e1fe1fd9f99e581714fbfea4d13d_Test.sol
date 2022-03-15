/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Test{
    struct Commodity{
        string com_id;
        string com_name;
        uint com_price;
        uint com_amount;
    }
    mapping(uint=>Commodity) private commodity_hash;

    event ComEvent(string _com_id,string _com_name,uint _com_price,uint _com_amount);

    uint x=0;   //有幾樣商品
    function setCommodity(string memory _com_id,string memory _com_name,uint _com_price,uint _com_amount) public{
        commodity_hash[x]=Commodity({com_id:_com_id,com_name:_com_name,com_price:_com_price,com_amount:_com_amount});
        x++;
        emit ComEvent(_com_id,_com_name,_com_price,_com_amount);
    }

}