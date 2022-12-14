/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


error onlySuperAdminAccess();
error vaultIsLocked(uint closingTime);
error accessDenied(bool access);

contract VaultContract {

    uint256 amount;
    address user;
    address admin;
    bool access;
    uint timeStamp;
    uint end;
    uint closingTime;

    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);
   
    mapping (address => bool) whiteListedAddresses;
    mapping (address => bool) accessValid;
    mapping(bytes32 => mapping(address => bool)) public roles;

    struct Account {
        address userAddress;
        bytes32 role;
        bool status;
        uint256 timeAdded;
    }

    struct TransferLog{
        address contractAddress;
        uint256 amount;
        uint256 time;
    }

    Account[] accounts;
    TransferLog[] transferLogs;
 
    //0xe4041c13a985afece8aab653f7b77a1e7f312381bd7738ead7806eee6c03bb1a
    bytes32 private constant SUPERADMIN = keccak256(abi.encodePacked("SUPERADMIN"));

       constructor() {
        admin = msg.sender;
        whiteListedAddresses[msg.sender] = true;
        _grantRole(SUPERADMIN, msg.sender);
    }

      modifier onlyOwner {
        if(msg.sender != admin) {
            revert onlySuperAdminAccess();
        }
        _;
    }

     modifier accessGrant {
        if(!whiteListedAddresses[msg.sender]) {
            revert accessDenied(access);
        }
        _;
    }


    modifier vaultKey {
        if(block.timestamp > closingTime) {
            revert vaultIsLocked(closingTime);
        }
        _;
    }

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "Not authorized");
        _;
    }

    receive() external accessGrant payable {}
    fallback() external accessGrant payable {}
   
    function getVaultBalance() public onlyRole(SUPERADMIN)  view returns (uint) {
        return address(this).balance;
    }

     function transferEthToBank(address payable _to, uint256 _amount) public onlyRole(SUPERADMIN) vaultKey payable {
        (bool sent,) = _to.call{value: _amount * 1e18}("");
        require(sent, "Failed to send Ether");
        transferLogs.push(TransferLog({
            contractAddress: _to,
            amount: _amount,
            time: block.timestamp
        }));
    }
    // TIMELOCK
   
    function unlockVault(uint256 time) public onlyRole(SUPERADMIN) {
        closingTime = block.timestamp + time;
    }

    function getOpenTimeLeft() public onlyRole(SUPERADMIN)  view returns(uint256) {
        require(closingTime >= block.timestamp , "Sorry, vault is locked!");
        return closingTime - block.timestamp;
    }

    function lockVault() public onlyRole(SUPERADMIN) {
        closingTime = block.timestamp * 0;
    }

    // WHITELIST

    function addToWhitelist (address _addressToWhitelist) public onlyRole(SUPERADMIN) {
        whiteListedAddresses[_addressToWhitelist] = true;
    }

    function removeToWhitelist (address _addressToWhitelist) public onlyRole(SUPERADMIN) {
        whiteListedAddresses[_addressToWhitelist] = false;
    }

    function verifyWhitelistedAddress(address _address) public onlyRole(SUPERADMIN) view returns (bool) {
        bool isUserWhiteListed = whiteListedAddresses[_address];
        return isUserWhiteListed;
    }

    //ACCESS_CONTROL
    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }
   
    function grantRole(bytes32 _role, address _account) external onlyOwner{
        _grantRole(_role, _account);
        accounts.push(Account({
            userAddress: _account,
            role: _role,
            timeAdded: block.timestamp,
            status: true
        }));
    }

    function revokeRole(bytes32 _role, address _account) external onlyOwner{
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }

    function getAllAccounts() public view returns(Account[] memory){
        return accounts;
    } 

    function geTransferLogs() public view returns(TransferLog[] memory) {
        return transferLogs;
    } 
}