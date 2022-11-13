/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract User {

     mapping(address => UserData) public users;
     mapping(address => Prism[]) public prisms;

     event AccountCreated(address sender);
     event PrismCreated(address sender);

     struct UserData {
         bytes32 id;
         string username;
         string email;
         address [] accounts;
     }

     struct Prism {
         bytes32 id; 
         string name;
         string fileUrl;
     }

    /**
     * @dev Store userInfo in UserData mapping 
     */
    function createUser(
        address sender, 
        bytes32 _id, 
        string calldata _email, 
        string calldata _username, 
        address[] calldata _accounts
        ) external {
        users[sender] = UserData(_id,_username,_email,_accounts);
        emit AccountCreated(sender);
    }

    function deleteUser(address sender) public {
        delete users[sender];
    }

    function deletePrism(address sender, uint256 index) public {
        delete prisms[sender][index];
    }

    /**
    * @dev Store prism in prisms mapping 
    */
    function createPrism(
        address sender,
        bytes32 _id,
        string calldata _name,
        string calldata _fileUrl
    ) external {
        prisms[sender].push(Prism(_id,_name,_fileUrl));
        emit PrismCreated(sender);
    }

    function getUsers(address sender) public view returns (UserData memory) {
        return users[sender];
    }

}