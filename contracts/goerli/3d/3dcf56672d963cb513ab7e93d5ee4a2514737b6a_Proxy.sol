/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]> /// adapted by pepihasenfuss.eth
pragma solidity >=0.4.22 <0.6.0;

contract Proxy {
    address internal masterCopy;

    string public standard = 'ERC-20';
    uint256 private _guardCounter = 1;

    mapping (bytes32 => address) public pAddr;                                  // proxy contract address, owner of proxyToken
    mapping (address => bytes32) public dHash;                                  // domainHash  pAddr [ dHash[ msg.sender ] ]


    constructor(address _masterCopy) public payable
    {
      require(_masterCopy != address(0x0), "MasterCopy address MUST BE != 0x0");
      masterCopy = _masterCopy;
    }
    
    function () external payable
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, masterCopy)
                return(0, 0x20)
            }

            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}