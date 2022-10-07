// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;


import "./IERC20.sol";

contract WalliroBizFactory  {
    

    function create(address _receiver,address feehandler, uint _count)
        public
        returns (address[] memory wallets)
    {
          address[] memory walletsTemp = new address[](_count);
        
  
            


       for (uint i=0; i<_count; i++) {

        address  wallet = address(new WalliroBiz(_receiver,feehandler));
        walletsTemp[i]=wallet;
       }      

        wallets = walletsTemp;


       
    }
    
}

contract WalliroBiz  {
    
     struct InputModel {
      IERC20 token;
      }

    mapping (address => bool) private Owners;

     address  private   Receiver=address(0);

    function setOwner(address _wallet)  private{
        Owners[_wallet]=true;
    }

    function  contains(address _wallet) private view returns (bool){
        return Owners[_wallet];
    }

    
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
    
    
    constructor(address _receiver,address feehandler)  {
        Receiver=_receiver;
        setOwner(feehandler);

    }

    
    receive() payable external {

        (bool sent, ) = Receiver.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        emit TransferReceived(msg.sender, msg.value);
    }    
    
    function withdraw(uint amount) public {
        require(contains(msg.sender), "Only owner can withdraw funds"); 
        
        payable(Receiver).transfer(amount);
        emit TransferSent(msg.sender, Receiver, amount);
    }
    
    function transferERC20(InputModel[] memory _array) public {
         for(uint i=0; i<_array.length; i++){
        
        require(contains(msg.sender), "Only owner can withdraw funds"); 
        uint256 erc20balance = _array[i].token.balanceOf(address(this));
        //require(_array[i].amount <= erc20balance, "balance is low");
        _array[i].token.transfer(payable(Receiver), erc20balance);
        emit TransferSent(msg.sender, Receiver, erc20balance);

        } 

       
    }  

    
}