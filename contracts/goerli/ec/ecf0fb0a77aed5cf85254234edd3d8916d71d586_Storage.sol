/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.7.0 < 0.9.0;
/**
* @title Storage
* @dev store or retrieve variable value
*/


contract Storage {

	uint256 value;

    enum Status {
        Pending,
        Shipped,
        Accepted,
        Rejected,
        Canceled
    }

	Status public status;

    function testEnum(Status __status) public pure returns (Status __returnStatus){
        if (__status == Status.Pending){
            return Status.Shipped;
        }

        if (__status == Status.Shipped){
            return Status.Accepted;
        }

        if (__status == Status.Accepted){
            return Status.Rejected;
        }

        if (__status == Status.Rejected){
            return Status.Canceled;
        }

        if (__status == Status.Canceled){
            return Status.Pending;
        }
    }

	function addup(string memory name,uint8 number) public pure returns (uint8,string memory){
		return (number+1, string(bytes.concat(bytes(name),bytes("_taubyte"))));
	}

	function noparamsnoout()public{}

	function testbytes(address add,bytes memory buf) public pure returns(bytes memory,address){
		return (buf, add);
	} 

	function store(uint256 number) public{
		value = number;
	}

	function retrieve() public view returns (uint256){
		return value;
	}
}