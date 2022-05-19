/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

pragma solidity ^0.4.17;
 contract Token {
/// Fields:
    string public constant name = "Flexsin";
    string public constant symbol = "FLX";
    uint public constant decimals = 18;
    uint256  totalSupply_ = 1000000000000000000000000000;
    event Transfer(address indexed from, address indexed to, uint256 _value);
    mapping (address => uint256) private balance;
    //@dev Constructor
     function Token(address _Seedsale, address _PrivateSale, address _Team_Advisor, address _Operations_Marketing, address _IDO_Liquidity, address _Community ) public {
         uint _fundSeedsale = (totalSupply_/100)*6;
           balance[_Seedsale] += _fundSeedsale;
           balance[msg.sender] -= _fundSeedsale;
           Transfer(msg.sender, _Seedsale,  _fundSeedsale);

         uint _fundprivatesale = (totalSupply_/100)*10;
           balance[_PrivateSale] += _fundprivatesale;
           balance[msg.sender] -= _fundprivatesale;
           Transfer(msg.sender, _PrivateSale,  _fundprivatesale);

         uint _fundteamadvisor = (totalSupply_/100)*15;
           balance[_Team_Advisor] += _fundteamadvisor;
           balance[msg.sender] -= _fundteamadvisor;
           Transfer(msg.sender, _Team_Advisor,  _fundteamadvisor);

         uint _fundoperationsMark = (totalSupply_/100)*8;
           balance[_Operations_Marketing] += _fundoperationsMark;
           balance[msg.sender] -= _fundoperationsMark;
           Transfer(msg.sender, _Operations_Marketing,  _fundoperationsMark);
        
         uint _fundIDOLiquidity = (totalSupply_/100)*1;
           balance[_IDO_Liquidity] += _fundIDOLiquidity;
           balance[msg.sender] -= _fundIDOLiquidity;
           Transfer(msg.sender, _IDO_Liquidity,  _fundIDOLiquidity);
        
          uint _fundCommunity = (totalSupply_/100)*60;
           balance[_Community] += _fundCommunity;
           balance[msg.sender] -= _fundCommunity;
           Transfer(msg.sender, _Community,  _fundCommunity);

     }
 }