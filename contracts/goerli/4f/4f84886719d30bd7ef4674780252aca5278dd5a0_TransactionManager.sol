/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// File: contracts/test/test2/testCall.sol


pragma solidity ^0.8.3;
contract TransactionManager { 


    mapping(uint256 => address) public wallets;


    constructor(address _wallet1) public {
        wallets[0] = _wallet1;
        wallets[1] = _wallet1;
        wallets[2] = _wallet1;
    }

    bool public success1;





    function execute(
        bytes calldata _data
    ) external {
        (bool success, bytes memory returnData) = address(this).call(_data);
    }


    function multiCall(
        bytes[] calldata _transactions_data
    )
        external
        returns (bytes[] memory)
    {
        bytes[] memory results = new bytes[](_transactions_data.length);
        for(uint i = 0; i < _transactions_data.length; i++) {
            // address(wallets[i]).call(_transactions_data[i]);
            results[i] = invokeWallet(wallets[i],_transactions_data[i]);
        }
        return results;
    }


    function invokeWallet(address wallet,bytes memory _data) internal returns (bytes memory _res) {
        (success1, _res) = address(wallet).call(_data);
    //    if (success1 && _res.length > 0) { //_res is empty if _wallet is an "old" BaseWallet that can't return output values
    //         (_res) = abi.decode(_res, (bytes));
    //     } else if (_res.length > 0) {
    //         // solhint-disable-next-line no-inline-assembly
    //         assembly {
    //             returndatacopy(0, 0, returndatasize())
    //             revert(0, returndatasize())
    //         }
    //     } else if (!success1) {
    //         revert("BM: wallet invoke reverted");
    //     }
        if (!success1) {
            revert("BM: wallet invoke reverted");
        }
    }
    



}