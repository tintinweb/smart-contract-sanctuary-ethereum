/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity >=0.7.0 <0.9.0;

contract Seal {

    event Sealed(bytes data);

    function seal(bytes calldata data) public {
        emit Sealed(data);
    }
}