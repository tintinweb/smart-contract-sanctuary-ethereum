/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;



contract food{
    int pizza_love = 0;
    int hambuger_love = 0;
    int pizza_dont = 0;
    int hambuger_dont = 0;


    function love_hambuger() public returns(int){
        hambuger_love = hambuger_love + 1;
        return hambuger_love;
    }
        
    function love_pizza() public returns(int){
        pizza_love = pizza_love + 1;
        return pizza_love;
    }
    
    function dont_like_hambuger() public returns(int){
        hambuger_dont = hambuger_dont + 1;
        return hambuger_dont;
    }
    
    function dont_like_pizza() public returns(int){
        pizza_dont = pizza_dont + 1;
        return pizza_dont;
    }
    

    function like_ham_piz() public view returns(string memory,int,string memory,int){
        return (("hambuger_love_count:"),hambuger_love,("pizza_love_count: "),pizza_love);
    }

    function hate_ham_piz() public view returns(string memory,int,string memory,int){
        return (("hambuger_hate_count: "),hambuger_dont, ("pizza_hate_count: "),pizza_dont);
    }
}