// SDPX-Licence-Identifier: MIT
// This contract was designed and deployed by : Janis Heibel, Roy Hove and Vishwa Ratna on behalf of Synpulse.

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../Pausable.sol";

contract SynpulseToken is ERC20, Pausable {
    address[] public owner;
    address public masterContract;
    address SynpulseVault = 0x7eff474f44D384Ee5D48a89cD5A473AC6Fe24CE2; // Synpulse Vault address
    address administrator = 0xAfC3973ca0a79F94c476689c9e9e39cbF83131f4; // Administrator address

    constructor(uint256 initialSupply)
        ERC20("vSynpulse Token of 2021", "vSYN21")
    {
        _mint(SynpulseVault, initialSupply);
        masterContract = SynpulseVault; // Synpulse Vault address
        owner.push(administrator); // Wallet allowed to pause and unpause the contract
        owner.push(masterContract);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function isOwner(address pretentious_address) private returns (bool) {
        for (uint256 i = 0; i < owner.length; i++) {
            if (owner[i] == pretentious_address) {
                return true;
            }
        }
        return false;
    }

    // this function checks if something is in an array and returns "true" if yes, else "not"
    function isInArray(
        address address_to_check,
        address[] memory array_WeWant_ToCheck
    ) private view whenNotPaused returns (bool) {
        for (uint256 x = 0; x < array_WeWant_ToCheck.length; x++) {
            if (array_WeWant_ToCheck[x] == address_to_check) {
                return true;
            }
        }
        return false;
    }

    // this function has to look through an array of addresses and find the index of a desired element.
    function returnIndex(address toFind, address[] memory arrayToLookInto)
        private
        whenNotPaused
        returns (uint256)
    {
        for (uint256 i = 0; i < arrayToLookInto.length; i++) {
            if (arrayToLookInto[i] == toFind) {
                return i;
            }
        }
    }

    modifier onlyOwner() {
        require(
            isInArray(msg.sender, owner),
            "Only the owner can perform this action!"
        );
        _;
    }

    modifier onlyMaster() {
        require(
            msg.sender == masterContract,
            "Only the master contract can perform this action!"
        );
        _;
    }

    function setOwner(address owner_to_add)
        public
        onlyMaster
        whenNotPaused
        returns (bool)
    {
        for (uint256 i = 0; i < owner.length; i++) {
            if (owner[i] == owner_to_add) {
                return true;
            }
        }
        owner.push(owner_to_add);
        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        if (!(msg.sender == SynpulseVault)) {
            require(
                (to == SynpulseVault),
                "Nice try buddy, but you got caught. You cannot send those funds since the token is not vested!"
            );
        }
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override whenNotPaused returns (bool) {
        if (!(to == SynpulseVault)) {
            require(
                (to == SynpulseVault),
                "This was even better buddy, but we got you again. You cannot send those funds since the token is not vested!"
            );
        }
        address spender = _msgSender();
        _transfer(from, to, amount);

        return true;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // airdrop aka batch transfers should only be available by the master contract. The amount must be the same for each recipient.
    function sendTokensToMultipleAdresses(
        address[] memory listOfAddresses_ToSend_To,
        uint256 amountToSend
    ) public whenNotPaused onlyMaster {
        for (uint256 z = 0; z < listOfAddresses_ToSend_To.length; z++) {
            transfer(listOfAddresses_ToSend_To[z], amountToSend);
        }
    }

    // This function pauses the contract and preserves the current state of the holdings. It is to be called once the token will be vested.
    function vestAllTokens() public whenNotPaused onlyOwner {
        _pause();
    }

    function reactivateContract() public whenPaused onlyOwner {
        _unpause();
    }
}