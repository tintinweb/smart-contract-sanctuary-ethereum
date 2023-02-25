//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AccountSale {
    address payable public seller;

    address payable internal buyer;

    uint public Price;

    function setAddress(address _address) public payable {
        seller = payable(_address);

        seller = payable(msg.sender);
    }

    mapping(uint => Account) public GetAccount;

    Account[] public account;

    struct Account {
        uint Cost;
        uint Id;
        uint TownHall;
        uint BarbKing;
        uint ArchQueen;
        uint Warden;
        uint RoyalChamp;
    }

    function addAccount(
        uint _cost,
        uint _Id,
        uint _TownHall,
        uint _BarbKing,
        uint _ArchQueen,
        uint _Warden,
        uint _RoyalChamp
    ) public onlySeller {
        account.push(Account(_cost, _Id, _TownHall, _BarbKing, _ArchQueen, _Warden, _RoyalChamp));

        Account memory accounts = Account(
            _cost,
            _Id,
            _TownHall,
            _BarbKing,
            _ArchQueen,
            _Warden,
            _RoyalChamp
        );

        GetAccount[_Id] = accounts;
    }

    function setPrice(uint price) public onlySeller {
        Price = price;
    }

    function buyAccount(uint _Id) public payable {
        Account memory accounts = GetAccount[_Id];

        require(msg.value >= accounts.Cost, "Not Enough");

        buyer = payable(msg.sender);

        payable(seller).transfer(msg.value);
    }

    string internal LoginId;

    uint internal Password;

    function setInfo(string memory _LoginId, uint _Password) public onlySeller {
        LoginId = _LoginId;

        Password = _Password;
    }

    function getInfo() public view onlyBuyer returns (string memory, uint) {
        return (LoginId, Password);
    }

    modifier onlySeller() {
        require(msg.sender == seller);

        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer);

        _;
    }
}