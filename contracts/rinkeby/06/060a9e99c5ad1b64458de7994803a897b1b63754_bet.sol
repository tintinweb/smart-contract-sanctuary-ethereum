/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

pragma solidity ^0.4.24;
contract bet{
        uint256 public integer_1 = 1;
        uint256 public integer_2 = 2;
        string public string_1;
    
        event setNumber(string _from);
        // 事件 事件名稱 你要記錄的東西

        event eventHandler(string _info);
  
        function function_3(string x)public {
            string_1 = x;
            emit setNumber(string_1);
        }
    

    function getMarket() public  returns (string memory) {
        emit eventHandler("event is came from getMarket");
        return "getMarket success";
        
    }

    function settle1x2() public  returns (string memory){
        emit eventHandler("event is came from settle1x2");
        return "settle success";
    }

    function placeBet(uint256 marketId, uint256 stake)public  returns (string memory) {
        emit eventHandler("event is came from placeBet");
        return "placeBet success";
    }

    function claim() public  returns (string memory) {
        emit eventHandler("event is came from claim");
        return "claim success";
    }
}