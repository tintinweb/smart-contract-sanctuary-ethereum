/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Transaction{

    string public transaction_no;
    struct Buyer{
        string buy_id;
        string buy_name;
    }
    struct Seller{
        string sell_id;
        string sell_name;
    }
    struct Commodity{
        string com_id;
        string com_name;
        uint com_price;
        uint com_amount;
    }
    mapping(uint=>Commodity) public commodity_hash;

    //輸入訂單編號
    function setNO(string memory no) public{
        transaction_no=no;
    }

    //輸入買家資訊
    Buyer public b1;
    function setBuyer(string memory _buy_id,string memory _buy_name) public{
        b1=Buyer({buy_id:_buy_id,buy_name:_buy_name});
    }

    //輸入賣家資訊
    Seller public s1;
    function setSeller(string memory _sell_id,string memory _sell_name) public{
        s1=Seller({sell_id:_sell_id,sell_name:_sell_name});
    }

    //輸入商品資訊
    uint x=0;   //有幾樣商品
    function setCommodity( string memory _com_id,string memory _com_name,uint _com_price,uint _com_amount) public{
        
        commodity_hash[x]=Commodity({com_id:_com_id,com_name:_com_name,com_price:_com_price,com_amount:_com_amount});
        x++;
    }
    
    

    //顯示資料

}