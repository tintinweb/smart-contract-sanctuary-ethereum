// SDPX-Licence-Identifier: MIT
// This contract was designed and deployed by : HEJCH, HORCH and ANAUK on behalf of companyName.

pragma solidity ^0.8.0;

import "../synERC777.sol";

contract synpulseToken is synERC777 {
    constructor(uint256 initialSupply, address[] memory defaultOperators)
        synERC777("Company Token 2021_t7", "ticker6", defaultOperators)
    {
        // require(defaultOperators[0] != defaultOperators[1], "The masterContract cannot be the administrator");  paused for testing
        masterContract = defaultOperators[0]; // companyName Vault, set in deploy function
        administrator = defaultOperators[1]; // CFO, set in deploy
      
        owner.push(masterContract);
        owner.push(administrator); // Wallet allowed to pause and unpause the contract

        _mint(masterContract, initialSupply, "", "");
    }

    function setOwner(address owner_to_add)
        public
        onlyAdministrator
        returns (bool)
    {
        if (isInArray(owner_to_add, owner)) {
            return true;
        } else {
            owner.push(owner_to_add);
            authorizeOperator(owner_to_add);
            return true;
        }
    }

    function removeOwner(address owner_to_remove)
        public
        onlyAdministrator
        returns (bool)
    {
        removeAddress(owner_to_remove, owner);
        revokeOperator(owner_to_remove);
        return true;
    }

    function setAdministrator(address administrator_to_set)
        public
        onlyMaster
        returns (bool)
    {
        require(
            administrator_to_set != masterContract,
            "The masterContract cannot be the adminstrator"
        );
        // to add a new admin we have to remove the old one first and then add the new one.
        // This is required e.g. in case the administrator (i.e. CFO) needs to change.
        removeOwner(administrator);
        setOwner(administrator_to_set);
        administrator = administrator_to_set;
        return true;
    }

    // In case the companyVault address needs to change
    function setMaster(address master_to_set) public onlyMaster returns (bool) {
        removeOwner(masterContract);
        setOwner(master_to_set);
        masterContract = master_to_set;
        return true;
    }

    function mintTokensToVault(uint256 amount) public onlyOwner whenNotPaused {
        _mint(masterContract, amount, "", "");
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // airdrop aka batch transfers should only be available by the master contract. The amount must be the same for each recipient.
    function sendTokensToMultipleAddresses(
        address[] memory listOfAddresses_ToSend_To,
        uint256 amountToSend,
        bytes memory data
    ) public whenNotPaused onlyMaster {
        // making sure that the total amount of tokens to send are present in the wallet sending.
        require(
            balanceOf(_msgSender()) >=
                listOfAddresses_ToSend_To.length * amountToSend,
            "Insufficient tokens"
        );
        // this uses a send function (_send) that does not require the whitelistEnabled flag to be true.
        for (uint256 z = 0; z < listOfAddresses_ToSend_To.length; z++) {
            _send(
                _msgSender(),
                listOfAddresses_ToSend_To[z],
                amountToSend,
                data,
                "",
                true
            );
        }
    }

    // send tokens to an individual address
    function sendTokensToIndividualAddress(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public whenNotPaused onlyMaster {
        _send(_msgSender(), recipient, amount, data, "", true);
    }

    // function could send automated request to finance teams + emit request payout event to make them easy to recognize.
    function requestPayout(uint256 amount, bytes memory data)
        public
        whenNotPaused
    {
        _send(_msgSender(), masterContract, amount, data, "", true);
    }

    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override onlyOwner {
        // the isOperatorFor function does not actually check if an address is an operator for another address but
        // it checks if the _msgSender is an operator. so it could be renamed to "IsOperator" but to keep the ERC777
        // standard, the name has to stay the same.
        require(
            isOperatorFor(_msgSender(), sender),
            "ERC777: Caller is not an operator"
        );
        require(
            recipient == masterContract,
            "An operator can only send tokens to the masterContract"
        );
        _send(sender, recipient, amount, data, operatorData, true);
    }

    function operatorBurn(
        address account,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override onlyOwner {
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

    function whitelistUsers(address[] memory arr)
        public
        whenNotPaused
        onlyOwner
    {
        for (uint256 i = 0; i < arr.length; i++) {
            isWhitelistedAddress[arr[i]] = true;
        }
    }

    //
    function removeFromWhitelist(address[] memory arr)
        public
        whenNotPaused
        onlyOwner
    {
        for (uint256 i = 0; i < arr.length; i++) {
            isWhitelistedAddress[arr[i]] = false;
            if (balanceOf(arr[i]) > 0) {
                operatorSend(arr[i], masterContract, balanceOf(arr[i]), "", "");
            }
        }
    }
}