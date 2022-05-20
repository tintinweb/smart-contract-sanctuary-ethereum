// SPDX-License-Identifier: MIT

pragma solidity >=0.4.6;
pragma experimental ABIEncoderV2;

contract Authentication {
    struct User {
        address publicAddress;
        string email;
        string firstName;
        string lastName;
        string password;
        string status;
        string id;
        address[] facilities;
    }

    User[] private users; // one user per account

    mapping(address => bool) private isUserExists;

    mapping(address => bool) private permissions;

    mapping(address => bool) private isCanUpdateStatus;

    constructor() public {
        permissions[msg.sender] = true;
        isCanUpdateStatus[msg.sender] = true;
    }

    //-----------------------------------signup & signIn----------------------------------------

    function signup(
        string memory _email,
        string memory _firstName,
        string memory _lastName,
        string memory _password,
        string memory _id
    ) public signUpModifier {
        users.push(
            User({
                publicAddress: msg.sender,
                email: _email,
                firstName: _firstName,
                lastName: _lastName,
                password: _password,
                id: _id,
                status: "pending",
                facilities: new address[](0)
            })
        );
        isUserExists[msg.sender] = true;
    }

    function loginMob(string memory _email, string memory _password)
        public
        view
        loginModifier
        returns (bool)
    {
        for (uint256 i = 0; i < users.length; i++) {
            if (
                users[i].publicAddress == msg.sender &&
                keccak256(abi.encodePacked(users[i].email)) ==
                keccak256(abi.encodePacked(_email)) &&
                keccak256(abi.encodePacked(users[i].password)) ==
                keccak256(abi.encodePacked(_password))
            ) return true;
        }
        return false;
    }

    function loginDashboards(
        string memory _email,
        string memory _password,
        address _facilityAddress
    ) public view loginModifier returns (bool) {
        for (uint256 i = 0; i < users.length; i++) {
            if (
                users[i].publicAddress == msg.sender &&
                keccak256(abi.encodePacked(users[i].email)) ==
                keccak256(abi.encodePacked(_email)) &&
                keccak256(abi.encodePacked(users[i].password)) ==
                keccak256(abi.encodePacked(_password))
            ) return checkUserInFacility(msg.sender, _facilityAddress);
        }
        return false;
    }

    function loginToUserManagement(
        string memory _email,
        string memory _password
    ) public view loginModifier returns (bool) {
        require(isCanUpdateStatus[msg.sender] == true, "Not authorized");
        for (uint256 i = 0; i < users.length; i++) {
            if (
                users[i].publicAddress == msg.sender &&
                keccak256(abi.encodePacked(users[i].email)) ==
                keccak256(abi.encodePacked(_email)) &&
                keccak256(abi.encodePacked(users[i].password)) ==
                keccak256(abi.encodePacked(_password))
            ) return true;
        }
        return false;
    }

    //-------------------------------------------------------------------------------------------------------//
    //----------------------------------------------PermisionsActivites--------------------------------------------
    function addFacility(address userAddress, address facilityAddress)
        external
        permissionModifier
    {
        require(checkUser(userAddress), "User dose not exists");
        require(
            !checkUserInFacility(userAddress, facilityAddress),
            "user already has this facility"
        );

        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].publicAddress == userAddress)
                users[i].facilities.push(facilityAddress);
        }
    }

    function addPermision(address permissionAddress) public permissionModifier {
        permissions[permissionAddress] = true;
    }

    function addUpdateStatusUserPermision(address updateStatusAddress)
        public
        isCanUpdateStatusModifier
    {
        isCanUpdateStatus[updateStatusAddress] = true;
    }

    function approveOrRejectUser(address userAddress, bool isApprove)
        public
        isCanUpdateStatusModifier
    {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].publicAddress == userAddress) {
                if (isApprove) users[i].status = "approve";
                else {
                    delete users[i];
                    break;
                }
            }
        }
    }

    function getPendingUsers()
        public
        view
        isCanUpdateStatusModifier
        returns (User[] memory)
    {
        uint256 cnt = 0;

        for (uint256 i = 0; i < users.length; i++) {
            if (
                keccak256(abi.encodePacked(users[i].status)) ==
                keccak256(abi.encodePacked("pending"))
            ) cnt++;
        }
        User[] memory pendingUsers = new User[](cnt);
        uint256 curent = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if (
                keccak256(abi.encodePacked(users[i].status)) ==
                keccak256(abi.encodePacked("pending"))
            ) pendingUsers[curent] = users[i];
        }
        return pendingUsers;
    }

    //--------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------helpers---------------------------------------------------
    function checkUser(address userAddress) public view returns (bool) {
        return isUserExists[userAddress];
    }

    function checkUserInFacility(address userAddress, address facilityAddress)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].publicAddress == userAddress) {
                for (uint256 j = 0; j < users[i].facilities.length; j++) {
                    if (users[i].facilities[j] == facilityAddress) return true;
                }
            }
        }
        return false;
    }

    //--------------------------------------------------------------------------------------------------------------

    //-------------------------------------------------------------get------------------------------------------------

    function getUserByAddress(address userAddress)
        public
        view
        returns (User memory)
    {
        require(checkUser(userAddress), "User dose not exists");
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].publicAddress == userAddress) return users[i];
        }
    }

    function getAllUsers() public view returns (User[] memory) {
        return users;
    }

    function getUserfacilities(address userAddress)
        public
        view
        returns (address[] memory)
    {
        return getUserByAddress(userAddress).facilities;
    }

    function getMyProfile() public view returns (User memory) {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].publicAddress == msg.sender) return users[i];
        }
    }

    //-------------------------------------------------------------------update----------------------------------------
    function updateUserProfile(
        string memory _firstName,
        string memory _lastName,
        string memory _password
    ) public {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].publicAddress == msg.sender) {
                users[i].firstName = _firstName;
                users[i].lastName = _lastName;
                users[i].password = _password;
            }
        }
    }

    ////---------------------------------modifier----------------------------------------------
    modifier permissionModifier() {
        require(permissions[msg.sender] == true, "not authorized");
        _;
    }

    modifier loginModifier() {
        require(isUserExists[msg.sender] == true, "User dose not exists");
        _;
    }

    modifier signUpModifier() {
        require(isUserExists[msg.sender] == false, "You Are Already Signed Up");
        _;
    }

    modifier isCanUpdateStatusModifier() {
        require(isCanUpdateStatus[msg.sender] == true, "not authorized");
        _;
    }
}