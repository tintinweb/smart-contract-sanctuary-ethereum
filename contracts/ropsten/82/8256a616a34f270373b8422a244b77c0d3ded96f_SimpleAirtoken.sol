/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

pragma solidity ^0.4.18;

//Made to Stackexchange question

contract ERC20 {
    function transfer(address _to, uint256 _value)public returns(bool);
    function balanceOf(address tokenOwner)public view returns(uint balance);
    function transferFrom(address from, address to, uint tokens)public returns(bool success);

}

contract SimpleAirtoken {

      ERC20 public token;

        function SimpleAirtoken(address _tokenAddr) public {
        token = ERC20(_tokenAddr);
}

  function getAirdrop() public {
    token.transfer(msg.sender, 100000000000000000000); //18 decimals token
  
    }
}