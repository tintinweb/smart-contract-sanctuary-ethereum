/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

pragma solidity 0.4.24;

contract dad {
    address _owner;
    constructor() public payable{
       
    }

       function getETH()public{
	    require(
	            address(this).balance>=0.01 ether,
                "没钱了"
	            );
        // address _owner = msg.sender;
        _owner.transfer(address(this).balance);
    }

    function newson(address _dad) public payable returns(address) {
        son i= new son(_dad);
        address(i).transfer(0.01 ether);
        return address(i);
    }


    function() external payable{}
}


contract son  {
    address _dad;

    constructor(address ldad) public payable{
        _dad = ldad;
        
    }

        // 取当前合约的地址
	function getAddress() public view returns (address) {
		return address(this);
	}

    function() external payable{}
}