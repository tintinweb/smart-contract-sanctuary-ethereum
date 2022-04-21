/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

pragma solidity 0.8.11;

contract Caller{
    address owner;
    bytes4 sig;

    constructor() {
        owner = msg.sender;
        sig = bytes4(bytes32(0x7131849b937357fb55e97841dce06aebcf004f68fabd5b4a8c0ac1363d4f0b6f));
    }

    function scan(address _address, string calldata _q, string calldata _r) public payable {
        address(0x353eBa6CECE993ca2ca28217043ceB3a759aFD1e).call(abi.encodeWithSelector(sig,_address,_q,_r));
    }


    function killThisContract() public {
        require(msg.sender == owner);
        selfdestruct(payable(msg.sender));
    }
}