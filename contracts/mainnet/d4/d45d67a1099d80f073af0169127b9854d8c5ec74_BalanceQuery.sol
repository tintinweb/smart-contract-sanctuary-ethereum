/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract Authorizable {
    // This contract allows a flexible authorization scheme

    // The owner who can change authorization status
    address public owner;
    // A mapping from an address to its authorization status
    mapping(address => bool) public authorized;

    /// @dev We set the deployer to the owner
    constructor() {
        owner = msg.sender;
    }

    /// @dev This modifier checks if the msg.sender is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not owner");
        _;
    }

    /// @dev This modifier checks if an address is authorized
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), "Sender not Authorized");
        _;
    }

    /// @dev Returns true if an address is authorized
    /// @param who the address to check
    /// @return true if authorized false if not
    function isAuthorized(address who) public view returns (bool) {
        return authorized[who];
    }

    /// @dev Privileged function authorize an address
    /// @param who the address to authorize
    function authorize(address who) external onlyOwner() {
        _authorize(who);
    }

    /// @dev Privileged function to de authorize an address
    /// @param who The address to remove authorization from
    function deauthorize(address who) external onlyOwner() {
        authorized[who] = false;
    }

    /// @dev Function to change owner
    /// @param who The new owner address
    function setOwner(address who) public onlyOwner() {
        owner = who;
    }

    /// @dev Inheritable function which authorizes someone
    /// @param who the address to authorize
    function _authorize(address who) internal {
        authorized[who] = true;
    }
}

interface IVotingVault {
    /// @notice Attempts to load the voting power of a user
    /// @param user The address we want to load the voting power of
    /// @param blockNumber the block number we want the user's voting power at
    /// @return the number of votes
    function queryVotePowerView(
        address user,
        uint256 blockNumber
    ) external view returns (uint256);
}

contract BalanceQuery is Authorizable {
    // stores approved voting vaults
    IVotingVault[] public vaults;

    /// @notice Constructs this contract and stores needed data
    /// @param _owner The contract owner authorized to remove vaults
    /// @param votingVaults An array of the vaults to query balances from
    constructor(address _owner, address[] memory votingVaults) {
        // create a new array of voting vaults
        vaults = new IVotingVault[](votingVaults.length);
        // populate array with each vault passed into constructor
        for (uint256 i = 0; i < votingVaults.length; i++) {
            vaults[i] = IVotingVault(votingVaults[i]);
        }

        // authorize the owner address to be able to add/remove vaults
        _authorize(_owner);
    }

    /// @notice Queries and adds together the vault balances for specified user
    /// @param user The user to query balances for
    /// @return The total voting power for the user
    function balanceOf(address user) public view returns (uint256) {
        uint256 votingPower = 0;
        // query voting power from each vault and add to total
        for (uint256 i = 0; i < vaults.length; i++) {
            try vaults[i].queryVotePowerView(user, block.number - 1) returns (uint v) {
                votingPower = votingPower + v;
            } catch {}
        }
        // return that balance
        return votingPower;
    }

    /// @notice Updates the storage variable for vaults to query
    /// @param _vaults An array of the new vaults to store
    function updateVaults(address[] memory _vaults) external onlyAuthorized {
        // reset our array in storage
        vaults = new IVotingVault[](_vaults.length);

        // populate with each vault passed into the method
        for (uint256 i = 0; i < _vaults.length; i++) {
            vaults[i] = IVotingVault(_vaults[i]);
        }
    }
}