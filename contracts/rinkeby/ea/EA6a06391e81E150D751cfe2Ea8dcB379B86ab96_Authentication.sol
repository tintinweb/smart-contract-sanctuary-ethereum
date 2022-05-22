// SPDX-License-Identifier: MIT

pragma solidity >=0.4.6;
import "UserStruct.sol";
pragma experimental ABIEncoderV2;

contract Authentication is UserStruct {
    User[] private users; // one user per account

    address owner;

    mapping(address => bool) private isUserExists;

    mapping(address => bool) private permissions;

    mapping(address => bool) private isCanUpdateStatus;

    constructor() public {
        owner = msg.sender;
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
        User storage user = users.push();

        user.publicAddress = msg.sender;
        user.email = _email;
        user.firstName = _firstName;
        user.lastName = _lastName;
        user.password = _password;
        user.id = _id;
        user.status = "pending";

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
    function addFacility(
        address userAddress,
        string memory _facilityName,
        string memory _description
    ) public permissionModifier {
        require(checkUser(userAddress), "User dose not exists");
        require(
            !checkUserInFacility(userAddress, msg.sender),
            "user already has this facility"
        );

        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].publicAddress == userAddress)
                users[i].facilities.push(
                    UserFacilities({
                        facilityAddress: msg.sender,
                        facilityName: _facilityName,
                        description: _description
                    })
                );
        }
    }

    function deleteFacility(address userAddress) external permissionModifier {
        require(checkUser(userAddress), "User dose not exists");
        require(
            checkUserInFacility(userAddress, msg.sender),
            "user dose not in this facility"
        );
        uint256 deleteIndex;
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].publicAddress == userAddress) {
                for (uint256 j = 0; j < users[i].facilities.length; j++) {
                    if (users[i].facilities[j].facilityAddress == msg.sender) {
                        deleteIndex = j;
                        break;
                    }
                }
                delete users[i].facilities[deleteIndex];
            }
        }
    }

    function addPermision() public onlyOwner {
        permissions[msg.sender] = true;
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
                    if (
                        users[i].facilities[j].facilityAddress ==
                        facilityAddress
                    ) return true;
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
        returns (UserFacilities[] memory)
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
    modifier onlyOwner() {
        require(owner == msg.sender, "not authorized");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.6;
pragma experimental ABIEncoderV2;

interface UserStruct {
    struct UserFacilities {
        address facilityAddress;
        string facilityName;
        string description;
    }

    struct User {
        address publicAddress;
        string email;
        string firstName;
        string lastName;
        string password;
        string status;
        string id;
        UserFacilities[] facilities;
    }
}