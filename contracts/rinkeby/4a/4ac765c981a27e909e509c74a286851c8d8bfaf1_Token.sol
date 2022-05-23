/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

pragma solidity ^0.4.17;
 contract Token {
/// Fields:
    string public constant name = "Flexsin";
    string public constant symbol = "FLX";
    uint public constant decimals = 18;
    uint256  totalSupply_ = 1000000000000000000000000000;
    uint256  circulatingSupply_ = 110551965000000000000000000;
    event Transfer(address indexed from, address indexed to, uint256 _value);
    mapping (address => uint256) private balance;
    //@dev Constructor
     function Token(address _Seedsale, address _PrivateSale, address _Team_Advisor, address _Operations_Marketing, address _IDO_Liquidity, address _Community ) public {
         uint _fundSeedsale = (totalSupply_/100)*6;
           balance[msg.sender] -= _fundSeedsale;
           emit Transfer(msg.sender, _Seedsale,  _fundSeedsale);
           balance[_Seedsale] += _fundSeedsale;

         uint _fundprivatesale = (totalSupply_/100)*10;
           balance[msg.sender] -= _fundprivatesale;
           emit Transfer(msg.sender, _PrivateSale,  _fundprivatesale);
           balance[_PrivateSale] += _fundprivatesale;

         uint _fundteamadvisor = (totalSupply_/100)*15;
           balance[msg.sender] -= _fundteamadvisor;
           emit Transfer(msg.sender, _Team_Advisor,  _fundteamadvisor);
           balance[_Team_Advisor] += _fundteamadvisor;

         uint _fundoperationsMark = (totalSupply_/100)*8;
           balance[msg.sender] -= _fundoperationsMark;
           emit Transfer(msg.sender, _Operations_Marketing,  _fundoperationsMark);
           balance[_Operations_Marketing] += _fundoperationsMark;
        
         uint _fundIDOLiquidity = (totalSupply_/100)*1;
           balance[msg.sender] -= _fundIDOLiquidity;
           emit Transfer(msg.sender, _IDO_Liquidity,  _fundIDOLiquidity);
           balance[_IDO_Liquidity] += _fundIDOLiquidity;
        
          uint _fundCommunity = (totalSupply_/100)*60;
           balance[msg.sender] -= _fundCommunity;
           emit Transfer(msg.sender, _Community,  _fundCommunity);
           balance[_Community] += _fundCommunity;

     }

      //Tranfer Function
    function transfer(address receiver, uint numTokens) public returns (bool) {
    address owner = msg.sender;
    balance[owner] = circulatingSupply_;
    require(numTokens <= balance[owner]);
    balance[owner] -= numTokens;
    balance[receiver] += numTokens;
    emit Transfer(owner, receiver, numTokens);
    return true;
    }


       /// @dev Returns number of tokens owned by given address.
/// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256) {
    return balance[_owner];
    }
 }