/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

pragma solidity >=0.7.0 <0.9.0;

contract EmptyEmit {
    event Deposit(bytes32 destination, uint amount, address token, bytes32 sidechainAsset);
    
    
    receive() external payable {
        bytes32 empty;
        emit Deposit(0xee5c871afdb5a17dcb3f9826cfb0c552d03a40bd23394030e71a52f2e2765e66, 8285434860000000000, address(0x0), empty);
    }

}