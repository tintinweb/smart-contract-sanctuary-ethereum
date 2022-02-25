/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

pragma solidity 0.6.0;
    contract feesum{

        struct Acount{
        uint256 id;
        address payable member;
        uint256 invest;
        }
     //address public owner;
    address payable public owner;
    uint256 public balance;
    address  public investor;



    uint256 Acountcode=0;
    mapping(uint256=>Acount) public Acounts;
    event joined(address indexed addr,uint256 amount,uint256 id);

     constructor()public{
      owner=msg.sender;
     }
     receive() payable external{
      balance += msg.value;
      investor=msg.sender;

     }

    function Join() public payable returns(uint256 ){
       // require(msg.value>0);
              //require(msg.value==0.1 ether);
     //  require(block.timestamp<startDate +(day*84600));
      //  owner.transfer(msg.value/10);
      //  ticketCode++;
     //   invested+=(msg.value*90)/100;
     Acountcode++;
     balance += msg.value;
        Acounts[Acountcode]=Acount(Acountcode,msg.sender,msg.value);
        emit joined(msg.sender,msg.value,Acountcode);
        return Acountcode;
    }



     function withdraw(uint256 amunt,address payable destaddr) public{
     require (msg.sender == owner,"only owner can withdraw");
     //require (amunt <= balance , "insufficient funds");
     require (amunt <= balance , "insufficient funds");

     destaddr.transfer(amunt);
     balance -= amunt;
     }
    }