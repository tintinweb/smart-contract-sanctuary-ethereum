// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
contract implementation {

   string  greetings="k1";
   address sender;

    function setstr(string memory _newstr) public {
      sender=msg.sender;
      greetings=_newstr;
    }
    function getstr() public view returns (string memory){
      return greetings;
    }
    function call(string memory _newstr,address _addr) public payable{
      (bool success, bytes memory data)=_addr.call{value: msg.value, gas: 55000}(
            abi.encodeWithSignature("setstr(string)", _newstr)
        );
    }

    function delegate(string memory _newstr,address _contract) public payable{
  (bool success, bytes memory data) = _contract.delegatecall(
             abi.encodeWithSignature("setstr(string)", _newstr)
        );
    }

}