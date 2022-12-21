//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 internal favouriteNumber;

    struct Account {
        string name;
        uint256 accountNumber;
        uint256 balance;
    }

    Account[] public accounts;
    mapping(string => Account) internal mapNameToAccount;

    function addFavouriteNumber(uint256 _favNumber) external {
        favouriteNumber = _favNumber;
    }

    function getFavouriteNumber() external view returns (uint256) {
        return favouriteNumber;
    }

    function getUpdatedFavNumber() external view returns (uint256) {
        return favouriteNumber + 5;
    }

    function getAcctDetails(string memory _name)
        external
        view
        returns (
            string memory,
            uint256,
            uint256
        )
    {
        Account memory details = mapNameToAccount[_name];
        return (details.name, details.accountNumber, details.balance);
    }

    function addAccount(
        string memory _name,
        uint256 _accountNumber,
        uint256 _balance
    ) external {
        accounts.push(Account(_name, _accountNumber, _balance));
    }
}