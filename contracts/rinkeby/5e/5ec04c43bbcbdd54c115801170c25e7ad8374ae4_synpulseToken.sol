// SPDX-License-Identifier: MIT
// This contract was designed and deployed by : HEJCH, HORCH and ANAUK on behalf of Synpulse.
// This is the deployment contract of the Synpulse Global Token where mints and contract specific functions are defined. 

pragma solidity ^0.8.0;

import "./synERC777.sol";

contract synpulseToken is synERC777 {
    constructor(uint256 initialSupply, address[] memory defaultOperators)
        synERC777("Synpulse Token", "SYN", defaultOperators) {
        require(defaultOperators[0] != defaultOperators[1], "The masterContract cannot be the administrator");
        masterContract = defaultOperators[0]; // companyName Vault, set in deploy function.
        administrator = defaultOperators[1]; // CFO, set in deploy function.

        _mint(masterContract, initialSupply, "", "");
    }

    event Payout (
        uint256 date,
        address indexed from,
        uint256 amount,
        bytes data
    );

    // This function is called by the masterContract in order 
    //to remove the old administrator and add a new one.
    function setAdministrator(address administrator_to_set
    ) public onlyMaster returns (bool) {
        require(
            administrator_to_set != masterContract,
            "The masterContract cannot be the adminstrator"
        );
        revokeOperator(administrator);
        authorizeOperator(administrator_to_set);
        administrator = administrator_to_set;
        return true;
    }

    // This function is called by the masterContract in order 
    //to remove the old masterContract and add a new one.
    function setMaster(address master_to_set
    ) public onlyMaster returns (bool) {
        require(
            master_to_set != administrator,
            "The masterContract cannot be the adminstrator"
        );
        revokeOperator(masterContract);
        authorizeOperator(master_to_set);
        masterContract = master_to_set;
        return true;
    }

    // This function is called by an operator in order to mint tokens to the masterContract.
    function mintTokensToVault(uint256 amount
    ) public whenNotPaused {
        require(
            isOperatorFor(_msgSender(), _msgSender()),
            "ERC777: Caller is not an operator"
        );
        _mint(masterContract, amount, "", "");
    }

    // This function is called by the masterContract or administrator in order to airdrop tokens via batch transfer.
    // The amount must be the same for each recipient.
    // This uses the _send() function that does not require the whitelistEnabled flag to be true.
    function sendTokensToMultipleAddresses(
        address[] memory listOfAddresses_ToSend_To,
        uint256 amountToSend,
        bytes memory data
    ) public whenNotPaused {
        // Ensure that the total amount of tokens to send are present in the wallet sending.
        require(
            _msgSender() == administrator || _msgSender() == masterContract, 
            "Only the administrator or master can perform this action!"
        );
        require(
            balanceOf(masterContract) >= listOfAddresses_ToSend_To.length * amountToSend,
            "Insufficient tokens"
        );
        for (uint256 z = 0; z < listOfAddresses_ToSend_To.length; z++) {
            _send(
                masterContract,
                listOfAddresses_ToSend_To[z],
                amountToSend,
                data,
                "",
                true
            );
        }
    }

    // This function is called by the masterContract or administrator in order to send tokens to an individual address.
    // This uses the _send() function that does not require the whitelistEnabled flag to be true.
    function sendTokensToIndividualAddress(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public whenNotPaused {
        require(
            _msgSender() == administrator || _msgSender() == masterContract, 
            "Only the administrator or master can perform this action!"
        );
        _send(masterContract, recipient, amount, data, "", true);
    }

    // This function is public and sends tokens directly to the masterContract.
    // Emits payout event for linking automated requests to finance teams.
    function requestPayout(uint256 amount, bytes memory data
    ) public whenNotPaused {
        _send(_msgSender(), masterContract, amount, data, "", true);
        emit Payout(block.timestamp, _msgSender(), amount, data);
    }

    // This function is called by defaultOperators in order to remove tokens from individuals.
    // It can only send tokens to the masterContract.
    // Emits payout event for linking automated requests to finance teams.
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override whenNotPaused {
        require(
            isOperatorFor(_msgSender(), sender),
            "ERC777: Caller is not an operator"
        );
        require(
            recipient == masterContract,
            "An operator can only send tokens to the masterContract"
        );
        _send(sender, recipient, amount, data, operatorData, true);
        emit Payout(block.timestamp, sender, amount, data);
    }

    // This functions is called by defaultOperators in order to burn tokens.
    // It can only burn tokens in the masterContract.
    function operatorBurn(
        address account,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override whenNotPaused {
        require(
            isOperatorFor(_msgSender(), account),
            "ERC777: Caller is not an operator"
        );
        require(
            account == masterContract,
            "An operator can only burn tokens in the masterContract"
        );
        _burn(account, amount, data, operatorData);
    }

    // This function is called by defaultOperators in order to whitelist all listed addresses.
    // It works by changing the isWhitelistedAddress flag -> true.
    // It only changes the boolean flag for addresses in the listed input.
    function whitelistUsers(address[] memory arr
    ) public {
        require(
            isOperatorFor(_msgSender(), _msgSender()),
            "ERC777: Caller is not an operator"
        );
        for (uint256 i = 0; i < arr.length; i++) {
            isWhitelistedAddress[arr[i]] = true;
        }
    }

    // This function is called by defaultOperators in order to un-whitelist all listed addresses.
    // It works by changing the isWhitelistedAddress flag -> false.
    // It only changes the boolean flag for addresses in the listed input.
    function removeFromWhitelist(address[] memory arr)
        public
    {
        require(
            isOperatorFor(_msgSender(), _msgSender()),
            "ERC777: Caller is not an operator"
        );
        for (uint256 i = 0; i < arr.length; i++) {
            isWhitelistedAddress[arr[i]] = false;
            if (balanceOf(arr[i]) > 0) {
                operatorSend(arr[i], masterContract, balanceOf(arr[i]), "", "");
            }
        }
    }
}