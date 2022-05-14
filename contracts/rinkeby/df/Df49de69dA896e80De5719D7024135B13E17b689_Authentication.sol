// SPDX-License-Identifier: MIT

pragma solidity >=0.4.6;

import "Test.sol";

contract Authentication {
    struct User {
        address publicAddress; // the sender of the signup transaction is the user
        string email;
        string userName;
        string password; // the password is entered by the user
    }
    Test myTest;

    constructor() public {
        myTest = new Test(msg.sender);
    }

    User[] private users; // one user per account

    mapping(address => bool) private usersExistence;

    modifier newlySignedUp() {
        require(
            usersExistence[msg.sender] == false,
            "You Are Already Signed Up"
        );
        _;
    }

    function signup(
        string memory _email,
        string memory _userName,
        string memory _password
    ) public newlySignedUp {
        users.push(
            User({
                publicAddress: msg.sender,
                email: _email,
                userName: _userName,
                password: _password
            })
        );
        usersExistence[msg.sender] = true;
    }

    function viewMyTest() public view returns (address) {
        return address(myTest);
    }

    function addOne() public returns (int256) {
        return myTest.addOne();
    }

    modifier signedUp() {
        require(usersExistence[msg.sender] == true, "You Are Not Signed Up");
        _;
    }

    function login(string memory _email, string memory _password)
        public
        view
        signedUp
        returns (bool)
    {
        bool successfulLogin = false;

        for (uint256 i = 0; i < users.length; i++) {
            User memory user = users[i];
            if (
                msg.sender == user.publicAddress &&
                keccak256(bytes(_password)) ==
                keccak256(bytes(user.password)) &&
                keccak256(bytes(_email)) == keccak256(bytes(user.email))
            ) {
                successfulLogin = true;
                break;
            }
        }
        return successfulLogin;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.6;

contract Test {
    address userAddress;
    int256 cnt;

    constructor(address user) public {
        // the address must change after the Receiver contract is deployed
        userAddress = user;
    }

    function show() public view returns (address) {
        return userAddress;
    }

    function addOne() public returns (int256) {
        cnt = cnt + 1;

        return cnt;
    }
}