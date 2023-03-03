// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { IAuthorized } from "../interfaces/IAuthorized.sol";

contract Authorized is IAuthorized {
    constructor() {
        /// @notice Add the deployer as an authorized admin
        authorizedAdmins[msg.sender] = true;
    }

    /// @notice A mapping storing authorized admins
    /// @dev admin address => authorized status
    mapping (address => bool) private authorizedAdmins;

    /// @notice A mapping of the authorized delegate operators
    /// @dev operator address => authorized status
    mapping (address => bool) private authorizedOperators;

    /// @dev Modifier to ensure caller is authorized admin
    modifier onlyAuthorizedAdmin() {
        if (!authorizedAdmins[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    /// @dev Modifier to ensure caller is authorized operator
    modifier onlyAuthorizedOperator() {
        if (!authorizedOperators[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    /// @inheritdoc IAuthorized
    function setAuthorizedAdmin(address _admin, bool status) public virtual onlyAuthorizedAdmin {
        /// check if address is not null
        require(_admin != address(0), "Authorized System: Admin address cannot be null");
        /// check if address is not the same as operator
        require(!authorizedOperators[_admin], "Authorized System: Admin cannot be an operator");
        /// check if address is human
        /// require(_admin == tx.origin, "Authorized System: Admin address must be human");
        /// update the admin status
        authorizedAdmins[_admin] = status;
        emit SetAdmin(_admin);
    }

    /// @inheritdoc IAuthorized
    function setAuthorizedOperator(address _operator, bool status) public virtual onlyAuthorizedAdmin {
        /// check if address is not null
        require(_operator != address(0), "Authorized System: Operator address cannot be null");
        /// check if address is not the same as admin
        require(!authorizedAdmins[_operator], "Authorized System: Operator cannot be an admin");
        
        /// update the operator status
        authorizedOperators[_operator] = status;
        emit SetOperator(_operator);
    }

    /// @inheritdoc IAuthorized
    function getAuthorizedAdmin(address _admin) external view virtual returns (bool) {
        return authorizedAdmins[_admin];
    }

    /// @inheritdoc IAuthorized
    function getAuthorizedOperator(address _operator) external view virtual returns (bool) {
        return authorizedOperators[_operator];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


interface IAuthenticable {

    /// errors
    error SessionExpired();
    
    /// update virtual account system contract
    /// @param _virtualAccountContract the address of the virtual account system contract
    function updateVirtualAccountSystem(address _virtualAccountContract) external;

    /// @notice validate active session key for later usage
    /// @param user the user address of the virtual account
    function validateSession(address user) external returns (bool);

    /// support interface
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IAuthorized {

    /// @notice Generic error when a user attempts to access a feature/function without proper access
    error Unauthorized();

    /// @notice Event emitted when a new admin is added
    event SetAdmin(address indexed admin);

    /// @notice Event emitted when a new operator is added
    event SetOperator(address indexed operator);

    /// @notice Event emmited when a new authOperator is added
    event SetAuthOperator(address indexed authOperator);

    /// @notice Add an authorized admin
    /// @param _admin address of the admin
    /// @param status status of the admin
    function setAuthorizedAdmin(address _admin, bool status) external;

    /// @notice Add an authorized Operator
    /// @param _operator address of the operator
    /// @param status status of the operator
    function setAuthorizedOperator(address _operator, bool status) external;

    /// @notice Get the status of an admin
    /// @param _admin address of the admin
    /// @return status of the admin
    function getAuthorizedAdmin(address _admin) external view returns (bool);

    /// @notice Get the status of an operator
    /// @param _operator address of the operator
    /// @return status of the operator
    function getAuthorizedOperator(address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IVirtualAccountSystem {
    /// Errors

    /// @notice Error when a user attempts to create a virtual account that already exists
    error VirtualAccountAlreadyExists();
   
    /// @notice Error when Session Key is expired
    error SessionExpired();

    /// @notice Error when the is banned
    error VirtualAccountBanned();

    /// Events

    /// @notice Event emitted when a new virtual account is created
    event CreateVirtualAccount(
        address username,
        address operator,
        uint256 createdAt
    );


    /// Structs

    /// @notice Struct to store the virtual account details
    /// @dev An expanded version of an address, with additional features.
    struct VirtualAccount {
         /// @notice The current primary address of the virtual account.
        address primaryAddress;
        
        /// @notice The time the virtual account was created
        uint256 createdAt;
        
        /// @notice The current session duration of the virtual account (time to expiry), refreshed upon touch
        uint256 sessionTimeToExpiry;

        /// @notice The last-seen interaction block of the virtual account
        uint256 lastSeen;

        /// @notice The ban status of the virtual account (admin-only)
        bool banned;
    }

    /// @notice a structure that stores the active session key, the session key is used to sign the transaction, the session key is valid for 24 hours
    struct SessionKey {
        /// @notice the session key
        bytes32 sessionKey;
        /// @notice the time the session key was created
        uint256 createdAt;
    }

    /// @notice create a new virtual account only asking for the username, email, and master pin. Only the authorized operator can create a new virtual account
    /// @param _address address of the virtual account
    function createVirtualAccount(address _address) external;

    /// @notice create a new virtual account only asking for the username, email, and master pin. Only the authorized operator can create a new virtual account
    /// @param _address address of the virtual account
    /// @return VirtualAccount memory
    function getVirtualAccount(address _address) external view returns (VirtualAccount memory);

    /// @param _address address of the virtual account
    function deleteVirtualAccount(address _address) external;

    /// @notice Sets the primary address of a virtual account
    /// @param _oldAddress Address to set primary address for
    /// @param _newAddress Primary address to set
    function updateVirtualAccount(address _oldAddress, address _newAddress) external;

    /// @notice Gets the primary address of a virtual account
    /// @param _address Address to check
    /// @return address Primary address of the virtual account
    function getPrimaryAddress(address _address) external view returns (address);

    /// @notice Refreshes a current address's session.
    /// @param _address Address to refresh
    function refreshSession(address _address) external;

    /// @notice Invalidates/expires a current address's session.
    /// @param _address Address to invalidate
    function expireSession(address _address) external;

    /// sets lastSeen block for an address
    /// @param _address Address to set lastSeen block for
    function setLastSeen(address _address) external;

    /// @notice Sets the ban status of a virtual account address
    /// @param _address Address to set ban status for
    /// @param status Ban status to set
    function setBanStatus(address _address, bool status) external;

    /// helpers

    /// @notice Gets the last-seen block of a virtual account address
    /// @param _address Address to check
    /// @return uint256 Last-seen block of the virtual account address
    function getLastSeen(address _address) external view returns (uint256);

    /// @notice Gets the ban status of a virtual account address
    /// @param _address Address to check
    /// @return bool Ban status of the virtual account address
    function getBanStatus(address _address) external view returns (bool);

    //// @notice Checks a current address for session validity.
    /// @param _address Address to check
    /// @return bool Whether the address has a valid session
    function isSessionValid(address _address) external view returns (bool);

    /// support interface
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

}

// SPDX-License-Identifier: MIT

/*
:::     ::: ::::::::::: :::::::::  ::::::::::: :::    :::     :::     :::        
:+:     :+:     :+:     :+:    :+:     :+:     :+:    :+:   :+: :+:   :+:        
+:+     +:+     +:+     +:+    +:+     +:+     +:+    +:+  +:+   +:+  +:+        
+#+     +:+     +#+     +#++:++#:      +#+     +#+    +:+ +#++:++#++: +#+        
 +#+   +#+      +#+     +#+    +#+     +#+     +#+    +#+ +#+     +#+ +#+        
  #+#+#+#       #+#     #+#    #+#     #+#     #+#    #+# #+#     #+# #+#        
    ###     ########### ###    ###     ###      ########  ###     ### ########## 
    :::      ::::::::   ::::::::   ::::::::  :::    ::: ::::    ::: :::::::::::  
  :+: :+:   :+:    :+: :+:    :+: :+:    :+: :+:    :+: :+:+:   :+:     :+:      
 +:+   +:+  +:+        +:+        +:+    +:+ +:+    +:+ :+:+:+  +:+     +:+      
+#++:++#++: +#+        +#+        +#+    +:+ +#+    +:+ +#+ +:+ +#+     +#+      
+#+     +#+ +#+        +#+        +#+    +#+ +#+    +#+ +#+  +#+#+#     +#+      
#+#     #+# #+#    #+# #+#    #+# #+#    #+# #+#    #+# #+#   #+#+#     #+#      
###     ###  ########   ########   ########   ########  ###    ####     ###      
 ::::::::  :::   :::  ::::::::  ::::::::::: :::::::::: ::::    ::::              
:+:    :+: :+:   :+: :+:    :+:     :+:     :+:        +:+:+: :+:+:+             
+:+         +:+ +:+  +:+            +:+     +:+        +:+ +:+:+ +:+             
+#++:++#++   +#++:   +#++:++#++     +#+     +#++:++#   +#+  +:+  +#+             
       +#+    +#+           +#+     +#+     +#+        +#+       +#+             
#+#    #+#    #+#    #+#    #+#     #+#     #+#        #+#       #+#             
 ########     ###     ########      ###     ########## ###       ###                                 
 
@title Virtual Account System
@notice This contract is intented to create and manage virtual accounts
@dev This contract will create a "virtual account" for each user using delegate operators to interact with other contracts
@author: @aurealarcon
@author: Michael(lofi)
*/

import { IVirtualAccountSystem }  from "./interfaces/IVirtualAccountSystem.sol";
import { IAuthenticable } from "./interfaces/IAuthenticable.sol";
import { Authorized } from "./extensions/Authorized.sol";

pragma solidity ^0.8.17;

contract VirtualAccountSystem is Authorized, IVirtualAccountSystem {
    constructor() {}

    /// variables

    /// @notice the expiration time for the session key
    uint256 private _sessionDuration = 1 days;

    /// Mappings

    /// @notice mapping of the virtual accounts for each username
    /// @dev address => virtual account struct
    mapping(address => VirtualAccount) private virtualAccounts;

    /// @inheritdoc Authorized
    function setAuthorizedOperator(
        address _operator,
        bool status
    ) public override onlyAuthorizedAdmin {
        uint32 size;
        assembly {
            size := extcodesize(_operator)
        }

        if (size > 0) {
            IAuthenticable authenticable = IAuthenticable(_operator);
            require(
                authenticable.supportsInterface(
                    type(IAuthenticable).interfaceId
                ),
                "VirtualAccountSystem: Operator must implement IAuthenticable"
            );
        }

        super.setAuthorizedOperator(_operator, status);
    }

    /// @notice create a new virtual account only asking for the username, email, and master pin. Only the authorized operator can create a new virtual account
    /// @inheritdoc IVirtualAccountSystem
    function createVirtualAccount(
        address _newUser
    ) external onlyAuthorizedOperator {
        /// check if the virtual account does not exist
        if (virtualAccounts[_newUser].primaryAddress != address(0)) {
            revert VirtualAccountAlreadyExists();
        }

        /// create the virtual account
        virtualAccounts[_newUser] = VirtualAccount({
            primaryAddress: _newUser,
            createdAt: block.timestamp,
            sessionTimeToExpiry: block.timestamp + _sessionDuration,
            lastSeen: block.timestamp,
            banned: false
        });
        emit CreateVirtualAccount(_newUser, msg.sender, block.timestamp);
    }

    /// @inheritdoc IVirtualAccountSystem
    function getVirtualAccount(
        address user
    ) external onlyAuthorizedOperator view returns (VirtualAccount memory) {
        return virtualAccounts[user];
    }

    /// @inheritdoc IVirtualAccountSystem
    function deleteVirtualAccount(address user) external onlyAuthorizedOperator {
        /// TODO: requires som form of signature built from users confirmation
        delete virtualAccounts[user];
    }

    /// @notice this works to attach user's own wallet and users update values.
    /// @inheritdoc IVirtualAccountSystem
    function updateVirtualAccount(
        address _oldAddress,
        address _newAddress
    ) external onlyAuthorizedOperator {
        /// check if the virtual account does not exist
        if (virtualAccounts[_newAddress].primaryAddress != address(0)) {
            revert VirtualAccountAlreadyExists();
        }

        /// @dev Instantiate a new virtual account with the same values as the old one, except with a new address
        VirtualAccount memory newVirtualAccount = VirtualAccount({
            primaryAddress: _newAddress,
            createdAt: virtualAccounts[_oldAddress].createdAt,
            sessionTimeToExpiry: virtualAccounts[_oldAddress]
                .sessionTimeToExpiry,
            lastSeen: virtualAccounts[_oldAddress].lastSeen,
            banned: virtualAccounts[_oldAddress].banned
        });

        /// @dev Register the new VAS Virtual Account to the passed address
        virtualAccounts[_newAddress] = newVirtualAccount;

        /// @dev Delete the old VAS Virtual Account
        delete virtualAccounts[_oldAddress];
    }

    // Sets the session time to current time + SESSION_DURATION
    /// @inheritdoc IVirtualAccountSystem
    function refreshSession(address user) external onlyAuthorizedOperator {
        if (virtualAccounts[user].banned == true) {
            revert VirtualAccountBanned();
        }
        virtualAccounts[user].sessionTimeToExpiry =
            block.timestamp +
            _sessionDuration;
        /// TODO: emit an event?
    }

    // Hard-expires the session by setting the session time to current time - 1 day
    /// @inheritdoc IVirtualAccountSystem
    function expireSession(address user) external onlyAuthorizedOperator {
        virtualAccounts[user].sessionTimeToExpiry = block.timestamp - 1 days;
    }

    /// @inheritdoc IVirtualAccountSystem
    function setLastSeen(address user) external onlyAuthorizedOperator {
        virtualAccounts[user].lastSeen = block.timestamp;
    }

    // This is an admin function required to ban a user from the VAS. It is intended to be cautiously used in the event of publicly-verified user abuse or address-level compromise.
    /// @inheritdoc IVirtualAccountSystem
    function setBanStatus(
        address user,
        bool status
    ) external onlyAuthorizedAdmin {
        virtualAccounts[user].banned = status;
    }

    /// Helpers

    // Checks if the session is expired
    /// @inheritdoc IVirtualAccountSystem
    function isSessionValid(address _address) external onlyAuthorizedOperator view returns (bool) {
        // If the session time is greater than or equal to the current block timestamp, the session is valid
        return virtualAccounts[_address].sessionTimeToExpiry >= block.timestamp;
    }

    /// @inheritdoc IVirtualAccountSystem
    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return interfaceId == type(IVirtualAccountSystem).interfaceId;
    }

    /// helpers

    /// @inheritdoc IVirtualAccountSystem
    function getPrimaryAddress(address user) external onlyAuthorizedOperator view returns (address) {
        return virtualAccounts[user].primaryAddress;
    }

    /// @inheritdoc IVirtualAccountSystem
    function getLastSeen(address _address) external onlyAuthorizedOperator view returns (uint256) {
        return virtualAccounts[_address].lastSeen;
    }

    /// @inheritdoc IVirtualAccountSystem
    function getBanStatus(address _address) external onlyAuthorizedOperator view returns (bool) {
        return virtualAccounts[_address].banned;
    }
}