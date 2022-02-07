/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

interface IERC20 {
 function transfer(address _to, uint _value)external returns(bool success);

function transferFrom(address _from, address _to,uint _value)external returns(bool success);
}


contract Echangeur {

          address public comissionCompte=0xF6b7F5DF2746BcD724b8B96938521E070Ac0B7f4;
          uint256 public pourcentageCom=10;
          address public constant ETH=0x06D6C4EF47ab0471bE259D6Be6064D61384Ae28e;
          uint256 idIndex;
           mapping(address=>mapping(address=>uint256))public tokens;
           mapping(uint256=>ORDRE)public ordres;
           mapping(uint256=>bool) public annuls;
           mapping(uint256=>bool)public completed;
            event Deposer(address indexed token, address indexed user, uint256 montant, uint256 balance);
            event Withdraw(address indexed token, address indexed user, uint256 montant, uint256 balance);
             
              
              event  Annul (
              uint256 id,
              address user,
              address token1,
              uint256 montant1,
              address token2,
              uint256 montant2,
              uint256 temps
          );
              event  Order (
              uint256 id,
              address user,
              address token1,
              uint256 montant1,
              address token2,
              uint256 montant2,
              uint256 temps
          );
             event  Trade (
              uint256 id,
              address user,
              address token1,
              uint256 montant1,
              address token2,
              uint256 montant2,
              uint256 temps
          );
        
          struct ORDRE {
              uint256 id;
              address user;
              address token1;
              uint256 montant1;
              address token2;
              uint256 montant2;
              uint256 temps;
          }
         
         
         
          receive()external payable {
              revert("peut pas recevoir");
          }

      function deposerEth() external payable {
          tokens[ETH][msg.sender]+=msg.value;
           emit Deposer(ETH, msg.sender,msg.value,tokens[ETH][msg.sender]);
      }

      function deposertoken(address _token,uint256 _montant)external {
            require(_token!=ETH);
            require(IERC20(_token).transferFrom(msg.sender,address(this),_montant));
            tokens[_token][msg.sender]+=_montant;

            emit Deposer(_token,msg.sender,_montant,tokens[_token][msg.sender]);

      }

      function withdrawEther(uint256 _montant)external {
          require(tokens[ETH][msg.sender]>=_montant,"pas suffisant");
          tokens[ETH][msg.sender]-=_montant;
          payable(msg.sender).transfer(_montant);
        emit Withdraw(ETH,msg.sender,_montant,tokens[ETH][msg.sender]);
      }

      function withdrawToken(address _token,uint _montant)external{
          require(_token!=ETH);
          require(tokens[_token][msg.sender]>=_montant,"pas assez");
          tokens[_token][msg.sender]-=_montant;
          require(IERC20(_token).transfer(msg.sender,_montant));
         emit Withdraw(_token,msg.sender,_montant,tokens[_token][msg.sender]);

      }

      function faitOrdre(address _token1,uint256 _montant1, address _token2, uint256 _montant2)external {
       idIndex++;
       ordres[idIndex]=ORDRE(idIndex,msg.sender,_token1,_montant1,_token2,_montant2,block.timestamp);

      emit Order(idIndex,msg.sender,_token1,_montant1,_token2,_montant2,block.timestamp);
      }


      function annulerOrder(uint256 _id)external {
      require(msg.sender==ordres[_id].user,"pas toi");
      require(_id==ordres[_id].id," no existant");

      annuls[_id]=true;

     emit Annul(ordres[_id].id,ordres[_id].user,ordres[_id].token1,ordres[_id].montant1,ordres[_id].token2,ordres[_id].montant2,block.timestamp);

      }


        function completeOrdre(uint _id) external {
        require(_id>0 && _id<=idIndex);
        require(!annuls[_id],"c'est dja cancele");
        require(!completed[_id]);  
        _trade(ordres[_id].id,ordres[_id].user,ordres[_id].token1,ordres[_id].montant1,ordres[_id].token2,ordres[_id].montant2);
        
        completed[ordres[_id].id]=true;
    
    }


    function _trade(uint _id,address _user,address _token1,uint _montant1, address _token2, uint _montant2)internal {
          uint256 fee= (_montant1*pourcentageCom)/100;

          tokens[_token1][msg.sender]-=_montant1+fee;
          tokens[_token1][_user]+=_montant1;
          tokens[_token1][comissionCompte]+=fee;
          tokens[_token2][_user]-=_montant2;
          tokens[_token2][msg.sender]+=_montant2;
          emit Trade(_id,_user,_token1,_montant1,_token2,_montant2,block.timestamp); 

    }











}