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

    function addAccount(
        string memory _name,
        uint256 _accountNumber,
        uint256 _balance
    ) external {
        accounts.push(Account(_name, _accountNumber, _balance));
        mapNameToAccount[_name] = Account(_name, _accountNumber, _balance);
    }

    function getAccount(string memory _name)
        external
        view
        returns (uint256, uint256)
    {
        Account memory account = mapNameToAccount[_name];
        return (account.accountNumber, account.balance);
    }
}