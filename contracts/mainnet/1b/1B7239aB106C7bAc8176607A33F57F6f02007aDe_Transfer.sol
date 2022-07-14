/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

//SPDX-License-Identifier: Unlicense
//www.CosmosBridge.app Contracts

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function deposit() external payable;
}

contract Transfer {

    address token;
    address admin;

    event TokenTransfer(string _dest_address, address _deposit_address, uint256 amount);

    constructor(address _token) {
        admin = msg.sender;
        token = _token;
    }

    function exec(string memory _dest_address, address _deposit_address) public payable {

        require(address(msg.sender).balance >= msg.value, "Not Enough Balance");
        require(msg.value>0, 'Amount must be greater than zero');
        uint256 amount = msg.value;
        IERC20(token).deposit{value: msg.value}();
        IERC20(token).transfer(_deposit_address, amount);

        emit TokenTransfer(_dest_address, _deposit_address, amount);
    }

    function withdrawToken(address _to, address _token, uint256 amount) public {
        require(msg.sender==admin, "You are not the Admin");
        require(IERC20(_token).transfer(_to, amount), "Error, unable to transfer");
    } 

}