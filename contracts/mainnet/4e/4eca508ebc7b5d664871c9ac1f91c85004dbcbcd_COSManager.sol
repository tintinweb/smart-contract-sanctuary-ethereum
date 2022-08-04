/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

pragma solidity ^0.4.26;

contract Ownable {
	address public owner;

	constructor() public {
		owner = msg.sender;
	}

	/**
	 * check is owner
	 */
	modifier onlyOwner () {
		require(msg.sender == owner);
		_;
	}
}


contract IManageCOS {
        function mint(uint256 _value) public returns(bool);
        function transfer(address _to, uint256 _value) public returns (bool success);
        function finish() public;
}


contract COSManager is Ownable {
   IManageCOS stub = IManageCOS(0x589891a198195061cb8ad1a75357a3b7dbadd7bc);
   
   function mint(uint256 _value) onlyOwner public returns(bool)  {
       return stub.mint(_value);
   }

   function transfer(address _to, uint256 _value) onlyOwner public returns (bool success){
       return stub.transfer(_to, _value);
   }

   /*
   Only Modify this Contract's owner, COS Contract owner cant be modified
   */
   function transferOfPower(address _to) onlyOwner public returns(bool)  {
       owner = _to;
   }

    function finish() onlyOwner public {
        stub.finish();
    }

   /*
   DO NOTHING, COS Contract's freeze/unfreeze method can't be call anymore
   */
   function freeze() onlyOwner public {

   }
   function unfreeze() onlyOwner public {

   }
}