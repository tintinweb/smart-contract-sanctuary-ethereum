// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract Social {
    struct User {
        string username;
        string name;
        string imageUrl;
    }

    User[] private users;

    constructor() {
        users.push(
            User(
                "vbuterin",
                "Vitalik Buterin",
                "https://assets.coingecko.com/app/public/ckeditor_assets/pictures/3626/content_vitalik_buterin.jpeg"
            )
        );

        users.push(
            User(
                "cz_binance",
                "Changpeng Zhao",
                "https://assets.bwbx.io/images/users/iqjWHBFdfxIU/i17A8XQaAl.4/v0/1200x-1.jpg"
            )
        );
        users.push(
            User(
                "moshaikhs",
                "Mo Shaikh",
                "https://media.bizj.us/view/img/12218971/aptos-labs-ceo-mo-shaikh*1200xx3142-3142-0-0.jpg"
            )
        );
    }

    function addUser(
        string calldata _username,
        string calldata _name,
        string calldata _imageUrl
    ) public {
        users.push(User(_username, _name, _imageUrl));
    }

    function length() public view returns (uint256) {
        return users.length;
    }

    function username(uint256 _index) public view returns (string memory) {
        return users[_index].username;
    }

    function name(uint256 _index) public view returns (string memory) {
        return users[_index].name;
    }

    function imageUrl(uint256 _index) public view returns (string memory) {
        return users[_index].imageUrl;
    }
}