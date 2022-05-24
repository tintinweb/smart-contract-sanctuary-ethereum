/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Multitransfer -- Multiple ERC20 token transfers in one transaction
/// @author Robert May <[email protected]>

interface ERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract Multitransfer {
    event TransactionCompleted(
        address From,
        address Token,
        address[] Receivers,
        uint256[] Amounts,
        string Invoice
    );

    address owner;

    constructor() {
        owner = msg.sender;
    }

    function send(
        address[] calldata _receivers,
        uint256[] calldata _amounts,
        string calldata _invoice
    ) external payable {
        require(
            _receivers.length == _amounts.length,
            "0xMLT: Receiver count does not match amount count."
        );

        uint256 total;
        for (uint8 i; i < _receivers.length; i++) {
            total += _amounts[i];
        }
        require(
            total == msg.value,
            "0xMLT: Total payment value does not match ether sent"
        );

        for (uint8 i; i < _receivers.length; i++) {
            (bool sent, ) = _receivers[i].call{value: _amounts[i]}("");
            require(sent, "0xMLT: Transfer failed.");
        }

        emit TransactionCompleted(
            msg.sender,
            0x0000000000000000000000000000000000000000,
            _receivers,
            _amounts,
            _invoice
        );
    }

    function transfer(
        address _from,
        address _token,
        address[] calldata _receivers,
        uint256[] calldata _amounts,
        string calldata _invoice
    ) public virtual {
        require(
            msg.sender == owner,
            "0xMLT: Only Hyper provider may call this contract."
        );
        require(
            _receivers.length == _amounts.length,
            "0xMLT: Receiver count does not match amount count."
        );

        ERC20 tokenInterface = ERC20(_token);

        for (uint8 i; i < _receivers.length; i++) {
            require(
                tokenInterface.transferFrom(_from, _receivers[i], _amounts[i]),
                "0xMLT: Transfer failed."
            );
        }

        emit TransactionCompleted(
            _from,
            _token,
            _receivers,
            _amounts,
            _invoice
        );
    }
}