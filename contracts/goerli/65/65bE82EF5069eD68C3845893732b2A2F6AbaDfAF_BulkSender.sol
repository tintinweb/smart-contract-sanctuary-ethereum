/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BulkSender {
    function bulkTransfer(
        IERC20 token,
        address[] memory _toAddresses,
        uint256[] memory _values
    ) public payable {
        require(
            (_toAddresses.length > 0) && (_toAddresses.length == _values.length)
        );

        // IERC20 token = IERC20(_address);

        for (uint256 i = 0; i < _toAddresses.length; i++) {
            token.transfer(
                _toAddresses[i],
                _values[i] * (uint256(10)**token.decimals())
            );
        }
    }

    function sendMultiTransfer(
        address payable[] memory _toAddresses,
        uint256[] memory _values
    ) public payable {
        require(
            (_toAddresses.length > 0) && (_toAddresses.length == _values.length)
        );

        uint256 sum = 0;
        for (uint256 i = 0; i < _values.length; i++) {
            sum = sum + _values[i];
        }
        require(msg.value == sum);

        for (uint256 i = 0; i < _toAddresses.length; i++) {
            _toAddresses[i].transfer(_values[i]);
        }
    }
}