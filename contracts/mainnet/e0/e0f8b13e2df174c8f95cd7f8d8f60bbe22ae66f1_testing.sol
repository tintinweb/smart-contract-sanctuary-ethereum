/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

pragma solidity ^0.8.11;

contract testing {
    bool public publicStatus = false;


    function mint() public {
       require(publicStatus, "Public sale is not active" );
    }

    function setP(bool _pstatus) public {
	    publicStatus = _pstatus;
	}
}