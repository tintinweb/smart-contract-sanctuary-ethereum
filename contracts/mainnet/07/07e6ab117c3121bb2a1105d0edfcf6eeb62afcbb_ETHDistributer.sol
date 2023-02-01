/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ETHDistributer {
    address public admin;

    event AdminChanged(address admin, address newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Accessble: caller is not an Admin");
        _;
    }
    constructor(address _admin) {
        admin = _admin;
    }

    function distributeETH(address[] calldata accounts) external onlyAdmin payable {
        require(msg.value > 0 && accounts.length !=0, "invalid values");
        uint256 amountPerAccount = msg.value / accounts.length;
        for( uint256 i =0; i < accounts.length; i++) {
            payable(accounts[i]).transfer(amountPerAccount);
        }
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    fallback() external {}
    receive() external payable{}

}