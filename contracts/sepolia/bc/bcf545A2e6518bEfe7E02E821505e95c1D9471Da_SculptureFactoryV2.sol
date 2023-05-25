// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SculptureLibraryV2.sol";
import "./UserAuthorizationV2.sol";

contract SculptureFactoryV2 {
    // Mapping from a sculptureId to a Sculpture struct with all its data
    mapping(uint256 sculptureId => SculptureLibrary.Sculpture sculpture) sculptures;

    // UserAuthorization instance
    UserAuthorizationV2 userAuthorizationInstance;

    event SculptureCreated(
        uint256 indexed sculptureId,
        uint256 timestamp,
        address whoCreates,
        string originalTitle
    );

    event SculptureUpdated(
        uint256 indexed sculptureId,
        uint256 timestamp,
        address whoUpdates,
        string originalTitle
    );

    constructor(address _userAuthorizationAddress) {
        userAuthorizationInstance = UserAuthorizationV2(
            _userAuthorizationAddress
        );

        // Checks if the user to deploy this SC is an admin user
        require(
            userAuthorizationInstance.isAuthorizedToCreate(msg.sender),
            "You are not authorized to deploy this SC"
        );
    }

    function searchSculpture(
        uint256 _sculptureId
    ) external view returns (SculptureLibrary.Sculpture memory) {
        require(
            sculptures[_sculptureId].isSculptureInitialized == true,
            "A sculpture with this ID does not exist!"
        );
        return sculptures[_sculptureId];
    }

    function createSculpture(
        uint256 _sculptureId,
        SculptureLibrary.Sculpture memory _sculpture
    ) external {
        // Checks if the user is an Admin user
        require(
            userAuthorizationInstance.isAuthorizedToCreate(msg.sender),
            "Your are not authorized to create a record."
        );

        // Checks if the sculptureId already exists
        require(
            sculptures[_sculptureId].isSculptureInitialized == false,
            "This sculptureId already exists! Use updateSculpture to modify it."
        );

        // Check sculpture data ? And only write those values that change ?

        // Making sure boolean isInitialized when creation always set to true
        _sculpture.isSculptureInitialized = true;

        // Add the sculpture to the mapping
        sculptures[_sculptureId] = _sculpture;

        // Emit the structure of this new Scultpure
        emit SculptureCreated(
            _sculptureId,
            block.timestamp,
            msg.sender,
            _sculpture.originalTitle
        );
    }

    function updateSculpture(
        uint256 _sculptureId,
        SculptureLibrary.Sculpture memory _sculpture
    ) external {
        // Check sculpture Data ? 

        sculptures[_sculptureId] = _sculpture;

        // Update all strings if they change
        // if (bytes(_sculpture.originalTitle).length > 0) {
        //     sculptures[_sculptureId].originalTitle = _sculpture.originalTitle;
        // }

        // if (bytes(_sculpture.descriptiveTitle).length > 0) {
        //     sculptures[_sculptureId].descriptiveTitle = _sculpture
        //         .descriptiveTitle;
        // }

        // if (bytes(_sculpture.subsequentTitle).length > 0) {
        //     sculptures[_sculptureId].subsequentTitle = _sculpture
        //         .subsequentTitle;
        // }

        // if (bytes(_sculpture.artist).length > 0) {
        //     sculptures[_sculptureId].artist = _sculpture.artist;
        // }

        // if (bytes(_sculpture.criticalCatalogNumber).length > 0) {
        //     sculptures[_sculptureId].originalTitle = _sculpture
        //         .criticalCatalogNumber;
        // }

        // if (bytes(_sculpture.date).length > 0) {
        //     sculptures[_sculptureId].date = _sculpture.date;
        // }

        // if (bytes(_sculpture.technique).length > 0) {
        //     sculptures[_sculptureId].technique = _sculpture.technique;
        // }

        // if (bytes(_sculpture.dimensions).length > 0) {
        //     sculptures[_sculptureId].dimensions = _sculpture.dimensions;
        // }

        // if (bytes(_sculpture.subsequentDimensions).length > 0) {
        //     sculptures[_sculptureId].subsequentDimensions = _sculpture.subsequentDimensions;
        // }

        // if (bytes(_sculpture.location).length > 0) {
        //     sculptures[_sculptureId].location = _sculpture.location;
        // }

        // if (bytes(_sculpture.owner).length > 0) {
        //     sculptures[_sculptureId].owner = _sculpture.owner;
        // }

        // if (bytes(_sculpture.editionExecutor).length > 0) {
        //     sculptures[_sculptureId].editionExecutor = _sculpture.editionExecutor;
        // }

        // if (bytes(_sculpture.conservationExecutor).length > 0) {
        //     sculptures[_sculptureId].conservationExecutor = _sculpture.conservationExecutor;
        // }

        // // Update all the uints if they change
        // if (sculptures[_sculptureId].diameter != _sculpture.diameter) {
        //     sculptures[_sculptureId].diameter = _sculpture.diameter;
        // }

        // if (sculptures[_sculptureId].weight != _sculpture.weight) {
        //     sculptures[_sculptureId].weight = _sculpture.weight;
        // }

        // if (sculptures[_sculptureId].subsequentDiameter != _sculpture.subsequentDiameter) {
        //     sculptures[_sculptureId].subsequentDiameter = _sculpture.subsequentDiameter;
        // }

        // if (sculptures[_sculptureId].owningArtistsCounter != _sculpture.owningArtistsCounter) {
        //     sculptures[_sculptureId].owningArtistsCounter = _sculpture.owningArtistsCounter;
        //     sculptures[_sculptureId].owningArtists = _sculpture.owningArtists;
        // }

        // if (sculptures[_sculptureId].totalEditionNumber != _sculpture.totalEditionNumber) {
        //     sculptures[_sculptureId].totalEditionNumber = _sculpture.totalEditionNumber;
        // }

        // if (sculptures[_sculptureId].sculptureEditionNumber != _sculpture.sculptureEditionNumber) {
        //     sculptures[_sculptureId].sculptureEditionNumber = _sculpture.sculptureEditionNumber;
        // }

        // if (sculptures[_sculptureId].categorizationLabel != _sculpture.categorizationLabel) {
        //     sculptures[_sculptureId].categorizationLabel = _sculpture.categorizationLabel;
        // }

        // if (sculptures[_sculptureId].conservationLabel != _sculpture.conservationLabel) {
        //     sculptures[_sculptureId].conservationLabel = _sculpture.conservationLabel;
        // }

        // // Update all the booleans isVariable, isCoownership, isConservation
        // sculptures[_sculptureId].isVariableSize = _sculpture.isVariableSize;
        // sculptures[_sculptureId].isCoOwnership = _sculpture.isCoOwnership;
        // sculptures[_sculptureId].isConservation = _sculpture.isConservation;

        // Emit the structure of this updated Scultpure
        emit SculptureCreated(
            _sculptureId,
            block.timestamp,
            msg.sender,
            _sculpture.originalTitle
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library SculptureLibrary {

    struct Sculpture {
        string originalTitle;
        string descriptiveTitle;
        string subsequentTitle;
        string artist;
        string criticalCatalogNumber;
        string date;
        string technique;
        string dimensions;
        uint256 diameter;
        uint256 weight;
        string subsequentDimensions;
        uint256 subsequentDiameter;
        string location;
        uint256 owningArtistsCounter;
        string[] owningArtists;
        string owner;
        uint256 totalEditionNumber;
        string editionExecutor;
        uint256 sculptureEditionNumber;
        string conservationExecutor;
        bool isVariableSize;
        bool isCoOwnership;
        bool isConservation;
        bool isSculptureInitialized;
        CategorizationLabel categorizationLabel;
        ConservationLabel conservationLabel;
        // string images;
    }

    enum CategorizationLabel { 
        NONE,
        PREPARATORY_WORK,
        AUTHORIZED_UNIQUE_WORK, 
        AUTHORIZED_UNIQUE_WORK_VARIATION, 
        AUTHORIZED_WORK, 
        AUTHORIZED_MULTIPLE, 
        AUTHORIZED_CAST, 
        POSTHUMOUS_WORK_AUTHORIZED_BY_ARTIST, 
        POSTHUMOUS_WORK_AUTHORIZED_BY_RIGHTSHOLDERS, 
        AUTHORIZED_REPRODUCTION, 
        AUTHORIZED_EXHIBITION_COPY, 
        AUTHORIZED_TECHNICAL_COPY, 
        AUTHORIZED_DIGITAL_COPY,
        REPRODUCTION_UNDER_PUBLIC_DOMAIN,
        EXHIBITION_COPY_UNDER_PUBLIC_DOMAIN,
        TECHNICAL_COPY_UNDER_PUBLIC_DOMAIN,
        DIGITAL_COPY_UNDER_PUBLIC_DOMAIN
    }

    enum ConservationLabel {
        NONE,
        AUTHORISED_EPHEMERAL_WORK,
        AUTHORIZED_REASSEMBLED_WORK,
        AUTHORIZED_RECONSTRUCTURED_WORK,
        AUTHORIZED_RESTORED_WORK
    }

    function isCategorizationLabelValid(uint8 label) internal pure returns (bool) {
        return (label >= uint8(CategorizationLabel.PREPARATORY_WORK) && label <= uint8(CategorizationLabel.DIGITAL_COPY_UNDER_PUBLIC_DOMAIN));
    }

    function isConservationLabelValid(uint8 label) internal pure returns (bool) {
        return (label >= uint8(ConservationLabel.AUTHORISED_EPHEMERAL_WORK) && label <= uint8(ConservationLabel.AUTHORIZED_RESTORED_WORK));
    }

    function getCategorizationLabelAsString(uint8 _enum) internal pure returns (string memory) {
        CategorizationLabel _label = CategorizationLabel(_enum);

        if (_label == CategorizationLabel.PREPARATORY_WORK) {
            return "Preparatory Work";
        } else if (_label == CategorizationLabel.AUTHORIZED_UNIQUE_WORK) {
            return "Authorized unique work";
        } else if (_label == CategorizationLabel.AUTHORIZED_UNIQUE_WORK_VARIATION) {
            return "Authorized unique work variation";
        } else if (_label == CategorizationLabel.AUTHORIZED_WORK) {
            return "Authorized work";
        } else if (_label == CategorizationLabel.AUTHORIZED_MULTIPLE) {
            return "Authorized multiple";
        } else if (_label == CategorizationLabel.AUTHORIZED_CAST) {
            return "Authorized cast";
        } else if (_label == CategorizationLabel.POSTHUMOUS_WORK_AUTHORIZED_BY_ARTIST) {
            return "Posthumous work authorized by artist";
        } else if (_label == CategorizationLabel.POSTHUMOUS_WORK_AUTHORIZED_BY_RIGHTSHOLDERS) {
            return "Posthumous work authorized by rightsholders";
        } else if (_label == CategorizationLabel.AUTHORIZED_REPRODUCTION) {
            return "Authorized reproduction";
        } else if (_label == CategorizationLabel.AUTHORIZED_EXHIBITION_COPY) {
            return "Authorized exhibition copy";
        } else if (_label == CategorizationLabel.AUTHORIZED_TECHNICAL_COPY) {
            return "Authorized technical copy";
        } else if (_label == CategorizationLabel.AUTHORIZED_DIGITAL_COPY) {
            return "Authorized digital copy";
        } else if (_label == CategorizationLabel.REPRODUCTION_UNDER_PUBLIC_DOMAIN) {
            return "Authorized reproduction under public domain";
        } else if (_label == CategorizationLabel.EXHIBITION_COPY_UNDER_PUBLIC_DOMAIN) {
            return "Authorized exhibition copy under public domain";
        } else if (_label == CategorizationLabel.TECHNICAL_COPY_UNDER_PUBLIC_DOMAIN) {
            return "Authorized technical copy under public domain";
        } else if (_label == CategorizationLabel.DIGITAL_COPY_UNDER_PUBLIC_DOMAIN) {
            return "Authorized digital copy under public domain";
        }

        revert("Invalid Categorization Label or Categorization label not set");
    }

    function getConservationLabelAsString(uint8 _enum) internal pure returns (string memory) {
        ConservationLabel _label = ConservationLabel(_enum);

        if (_label == ConservationLabel.AUTHORISED_EPHEMERAL_WORK) {
            return "Ephemeral work.";
        } else if (_label == ConservationLabel.AUTHORIZED_REASSEMBLED_WORK) {
            return "Reassembled work.";
        } else if (_label == ConservationLabel.AUTHORIZED_RECONSTRUCTURED_WORK) {
            return "Reconstructed work.";
        } else if (_label == ConservationLabel.AUTHORIZED_RESTORED_WORK) {
            return "Restored work.";
        }

        revert("Invalid Conservation Label or Conservation label not set");
    }

    // Check if Date is Valid but I think date should be save as string and validations of this type should be checked
    // frontend
    // function isValidDate(string memory _date) internal pure returns (bool) {
    //     bytes memory strBytes = bytes(_date);
    //     if (strBytes.length == 6) {
    //         // Parse data for a Date value such as "c.1993". "c." means aproximately
    //         for (uint i = 0; i < strBytes.length; i++) {
    //             if ((i == 0 && strBytes[i] != "c") || (i == 1 && strBytes[i] != ".") || (i > 2 && (uint8(strBytes[i]) < 48 || uint8(strBytes[i]) > 57))) {
    //                 return false;
    //             }
    //         }
    //     } else if (strBytes.length == 4) {
    //         // Parse data for a Date value such as "1993" without "c."
    //         for (uint i = 0; i < strBytes.length; i++) {
    //             if (i > 0 && (uint8(strBytes[i]) < 48 || uint8(strBytes[i]) > 57)) {
    //                 return false;
    //             }
    //         }
    //     } else {
    //         return false;
    //     }

    //     // If all checks passed, return true
    //     return true;
    // }

    function checkSculptureMandatoryData(
        Sculpture memory _sculpture
    ) internal pure returns (bool) {
        require(
            checkMaxStringLength(_sculpture.originalTitle) == true,
            "The Original Title field exceeds the maximum string length!"
        );
        require(
            checkMaxStringLength(_sculpture.descriptiveTitle) == true,
            "The Descriptive Title field exceeds the maximum string length!"
        );
        require(
            checkMaxStringLength(_sculpture.subsequentTitle) == true,
            "The Subsequent Title field exceeds the maximum string length!"
        );
        require(
            checkMaxStringLength(_sculpture.artist) == true,
            "The Artist field exceeds the maximum string length!"
        );
        require(
            checkMaxStringLength(_sculpture.criticalCatalogNumber) == true,
            "The Critical Catalog Number field exceeds the maximum string length!"
        );
        // require(
        //     isValidDate(_sculpture.date) == true,
        //     "The Date field is wrong. Two different options are possible, example:'c.1990' for an aproximate date or just 1990!"
        // );
        require(
            checkMaxStringLength(_sculpture.technique) == true,
            "The Technique field exceeds the maximum string length!"
        );
        require(
            checkMaxStringLength(_sculpture.dimensions) == true,
            "The Dimensions field exceeds the maximum string length!"
        );
        require(
            checkMaxStringLength(_sculpture.location) == true,
            "The Location field exceeds the maximum string length!"
        );
        require(
            checkMaxStringLength(_sculpture.owner) == true,
            "The Owner field exceeds the maximum string length!"
        );
        require(
            checkMaxStringLength(_sculpture.editionExecutor) == true,
            "The Edition Excutor field exceeds the maximum string length!"
        );
        require(
            checkMaxStringLength(_sculpture.conservationExecutor) == true,
            "The Conservation Excutor field exceeds the maximum string length!"
        );
        require(
            SculptureLibrary.isCategorizationLabelValid(
                uint8(_sculpture.categorizationLabel)
            ) == true,
            "The Categorizatoin Label is not a valid value!"
        );
        require(
            SculptureLibrary.isConservationLabelValid(
                uint8(_sculpture.conservationLabel)
            ) == true,
            "The Conservation Label is not a valid value!"
        );

        return true;
    }

    function checkMaxStringLength(string memory _str) internal pure returns (bool) {      
        // Maximum string length accepted to be stored in the SC
        return bytes(_str).length <= 64;
    }

    function stringIsEmpty(string memory _str) internal pure returns (bool) {
        return bytes(_str).length == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Smart Contract to store the privileges of those users that can create Sculpture Records and updates
contract UserAuthorizationV2 {
    // Enum for different privilege levels
    enum PrivilegeLevel {
        NONE,
        USER,
        ADMIN
    }

    // Count the number of admin users
    uint256 public numOfAdmins;

    // Mapping from user address to privilege level
    mapping(address user => PrivilegeLevel role) usersRoles;

    // Event for logging user authorization
    event UserAuthorized(address indexed userAddress, string privilegeLevel);

    // Event for logging privilege modifications
    event UserPrivilegeUpdated(
        address indexed userAddress,
        string newPrivilegeLevel
    );

    // Event for logging user deletion
    event UserRemoved(address indexed userAddress, string info);

    constructor() {
        // Increse the number of admins
        numOfAdmins++;

        // Add this user that deploys this contract with Admin privileges
        usersRoles[msg.sender] = PrivilegeLevel.ADMIN;
    }

    modifier isAdmin() {
        require(
            usersRoles[msg.sender] == PrivilegeLevel.ADMIN,
            "You are not authorized to perform this action!"
        );
        _;
    }

    modifier isPrivilegeValid(uint8 _privilege) {
        require(
            _privilege >= uint8(PrivilegeLevel.NONE) &&
                _privilege <= uint8(PrivilegeLevel.ADMIN),
            "Invalid Privilege value"
        );
        _;
    }

    modifier isUser(address _userAddress) {
        // Checks if the user exists
        require(
            usersRoles[_userAddress] != PrivilegeLevel.NONE,
            "The user does not exist!"
        );
        _;
    }

    // Authorizes a new user
    function authorizeUser(
        address _userAddress,
        uint8 _privilegeLevel
    ) public isAdmin isPrivilegeValid(_privilegeLevel) {
        PrivilegeLevel privilegeLevel = PrivilegeLevel(_privilegeLevel);

        // Check if the privilege to be set is not NONE
        require(
            privilegeLevel != PrivilegeLevel.NONE,
            "Setting privilege to None is the same as not authorizing the user"
        );

        // Checks if the user is not already registered
        require(
            usersRoles[_userAddress] == PrivilegeLevel.NONE,
            "User is already created and authorized"
        );

        if (privilegeLevel == PrivilegeLevel.ADMIN) {
            numOfAdmins++;
        }

        // Stores the user privilege
        usersRoles[_userAddress] = privilegeLevel;

        // Emits the event for logging the user authorization
        emit UserAuthorized(
            _userAddress,
            getPrivilegeAsString(_privilegeLevel)
        );
    }

    // Changes the user privileges
    function changeUserPrivilege(
        address _userAddress,
        uint8 _newPrivilegeLevel
    ) public isAdmin isUser(_userAddress) isPrivilegeValid(_newPrivilegeLevel) {
        PrivilegeLevel newLevel = PrivilegeLevel(_newPrivilegeLevel);

        require(
            newLevel != usersRoles[_userAddress],
            "Action reverted since the user has already the new privilege level"
        );

        if (newLevel == PrivilegeLevel.ADMIN) {
            numOfAdmins++;
        } else if (usersRoles[_userAddress] == PrivilegeLevel.ADMIN) {
            require(
                numOfAdmins > 1,
                "This admin cannot reduce its privileges since there must be at least one Admin user"
            );
            numOfAdmins--;
        }

        // Stores the new Privilege level
        usersRoles[_userAddress] = newLevel;

        // Emits the event for logging the user authorization
        emit UserPrivilegeUpdated(
            _userAddress,
            getPrivilegeAsString(_newPrivilegeLevel)
        );
    }

    // Removes an Authorized User
    function removeAuthorizedUser(
        address _userAddress
    ) public isAdmin isUser(_userAddress) {
        if (usersRoles[_userAddress] == PrivilegeLevel.ADMIN) {
            require(
                numOfAdmins > 1,
                "This admin cannot reduce its privileges since there must be at least one Admin user"
            );
            numOfAdmins--;
        }

        // Removes the user privileges
        delete usersRoles[_userAddress];

        // Emits the event for logging the user removal
        emit UserRemoved(_userAddress, "Authorized user removed!");
    }

    // Checks if a user has the minimum privileges to create a Record
    function isAuthorizedToCreate(
        address _userAddress
    ) public view returns (bool) {
        return usersRoles[_userAddress] == PrivilegeLevel.ADMIN;
    }

    // Check if a user is an Admin
    function isUserAdmin (
        address _userAddress
    ) public view returns (bool) {
        return isAuthorizedToCreate(_userAddress);
    }

    // Checks if a user has the minimum privileges to update a Record
    function isAuthorizedToUpdate(
        address _userAddress
    ) public view returns (bool) {
        return usersRoles[_userAddress] >= PrivilegeLevel.USER;
    }

    // Checks if a user is registered
    function isUserRegistered(
        address _userAddress
    ) public view returns (bool) {
        return isAuthorizedToUpdate(_userAddress);
    }

    function getPrivilegeAsString(
        uint8 _privilege
    ) private pure returns (string memory) {
        PrivilegeLevel privilegeLevel = PrivilegeLevel(_privilege);

        if (privilegeLevel == PrivilegeLevel.NONE) {
            return "User without any privileges";
        } else if (privilegeLevel == PrivilegeLevel.USER) {
            return "User with privileges to update an existing record";
        } else if (privilegeLevel == PrivilegeLevel.ADMIN) {
            return "User with privileges to create or update records";
        }

        return "Invalid Privilege Level";
    }
}