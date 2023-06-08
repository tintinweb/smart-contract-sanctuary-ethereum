/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0;

contract Token{
      event Transfer(address indexed _from, address indexed _to, uint256 _value);
      event Approval(address indexed _owner, address indexed _spender, uint256 _value);

      string public name = "PodToken";
      string public symbol = "Pods";
      uint8 public decimals = 18;
      uint256 public totalSupply;
     address public OwnerOfToken;
     uint256 public userID;

     struct TokenHolderInfo{
          uint256 userId;
          address From;
          address TO;
          uint256 Ammount;
          bool TokenHodl;
     }
    
     mapping (address => TokenHolderInfo) internal getHoldersInfo;
     mapping(address => uint256) public balanceOf;
     mapping(address => mapping(address => uint256)) public allowance; 
     
     address[] internal TokenHolders;
     TokenHolderInfo[] public History;

      constructor(uint256 _total){
          totalSupply = (_total * (10 ** decimals));
          balanceOf[msg.sender] = totalSupply;
          OwnerOfToken = msg.sender;
      }

      function transfer(address _to, uint256 _value) public returns (bool success){
          require(balanceOf[msg.sender] >= _value,"insuffient balance");
          balanceOf[msg.sender] -= _value;
          balanceOf[_to] += _value;
          
          
          TokenHolderInfo storage g1 = getHoldersInfo[_to];

          if(g1.TokenHodl == false){
              TokenHolders.push(_to);
          }

          g1.userId = ++userID;
          g1.From = msg.sender;
          g1.TO = _to;
          g1.Ammount = _value;
          g1.TokenHodl =true;

          History.push(g1);

          emit Transfer(msg.sender, _to, _value);
          return true;
      }
      
      function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
          require(balanceOf[_from] >= _value,"insuffient balance");
          balanceOf[_from] -= _value;
          balanceOf[_to] += _value;
          allowance[_from][msg.sender] -=_value;
          
          
          TokenHolderInfo storage g1 = getHoldersInfo[_to];

          if(g1.TokenHodl == false){
            TokenHolders.push(_to);
          }

          g1.userId = ++userID;
          g1.From = msg.sender;
          g1.TO = _to;
          g1.Ammount = _value;
          g1.TokenHodl = true;
          History.push(g1);

          emit Transfer(msg.sender, _to, _value);
          return true;
      }
       
      function approve(address _spender, uint256 _value) public returns (bool success){
             allowance[msg.sender][_spender] = _value;
             emit Approval(msg.sender, _spender, _value);
             return true;
      }

     function getInfo() public view returns(TokenHolderInfo[] memory){
          return History;
     }
     
     function getHoldersList() public view returns(address[] memory holders){
         return(TokenHolders);
     } 
}