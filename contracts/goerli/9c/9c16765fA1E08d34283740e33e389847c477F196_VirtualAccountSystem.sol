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
    modifier isAuthorizedAdmin() {
        if (!authorizedAdmins[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    /// @dev Modifier to ensure caller is authorized operator
    modifier isAuthorizedOperator() {
        if (!authorizedOperators[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    /// @inheritdoc IAuthorized
    function setAuthorizedAdmin(address _admin, bool status) public virtual isAuthorizedAdmin {
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
    function setAuthorizedOperator(address _operator, bool status) public virtual isAuthorizedAdmin {
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

pragma solidity ^0.8.9;


interface IAuthenticable {
    /// update virtual account system contract
    /// @param _virtualAccountContract the address of the virtual account system contract
    function updateVirtualAccountSystem(address _virtualAccountContract) external;

    /// @notice validate active session key for later usage
    /// @param _username the username of the virtual account
    /// @param _sessionKey the session key to be validated
    function validateSessionKey(string memory _username, bytes32 _sessionKey) external returns (bool);

    /// support interface
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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

pragma solidity ^0.8.9;

interface IVirtualAccountSystem {
    /// Errors

    /// @notice Error when a user attempts to create a virtual account that already exists
    error VirtualAccountAlreadyExists();

    /// @notice Error when the PIN is expired
    error PinExpired();
    
    /// @notice Error when Session Key is expired
    error SessionKeyExpired();

    /// Events

    /// @notice Event emitted when a new virtual account is created
    event CreateVirtualAccount(
        string indexed username,
        address operator,
        uint256 createdAt
    );

    /// @notice event when a selfCustodyWallet is connected to a virtual account
    event ConnectSelfCustodyWallet(
        string indexed username,
        address indexed selfCustodyWallet,
        address indexed operator,
        uint256 createdAt
    );

    /// @notice event when a selfCustodyWallet is updated
    event UpdateSelfCustodyWallet(
        string indexed username,
        address indexed selfCustodyWallet,
        address indexed operator,
        uint256 updatedAt
    );

    /// Structs

    /// @notice Struct to store the virtual account details
    struct VirtualAccount {
        /// @notice The email of the virtual account
        string email;
        /// @notice the phone number of the virtual account
        string phone;
        /// @notice The address of connected self custody account
        address account;
        /// @notice The address of the delegate operator
        address operator;
        /// @notice the master PIN
        uint256 masterPin;
        /// @notice the last time the master PIN was changed
        uint256 lastChangePin;
        /// @notice the last time the master PIN was used
        uint256 lastUsePin;
        /// @notice the time the virtual account was created
        uint256 createdAt;
    }

    /// @notice a structure that stores the active session key, the session key is used to sign the transaction, the session key is valid for 24 hours
    struct SessionKey {
        /// @notice the session key
        bytes32 sessionKey;
        /// @notice the time the session key was created
        uint256 createdAt;
    }

    /// @notice create a new virtual account only asking for the username, email, and master pin. Only the authorized operator can create a new virtual account
    /// @param _username username of the virtual account
    /// @param _email email of the virtual account
    /// @param _masterPin master pin of the virtual account
    function createVirtualAccount(string memory _username, string memory _email, uint256 _masterPin) external;

    /// @notice attach a new wallet to the virtual account only accessible by the operator and accepting the username, wallet address, and master pin
    /// @param _username username of the virtual account
    /// @param _wallet wallet address of the virtual account
    /// @param _masterPin master pin of the virtual account
    function attachWallet(string memory _username, address _wallet, uint256 _masterPin) external;
    /// update the attached wallet to the virtual account only accessible by the operator and accepting the username, wallet address, and master pin
    /// @param _username username of the virtual account
    /// @param _wallet wallet address of the virtual account
    /// @param _masterPin master pin of the virtual account
    function updateWallet(string memory _username, address _wallet, address oldWallet, uint256 _masterPin) external;

    /// @notice update the email of the virtual account only accessible by the operator and accepting the new email and the master pin
    /// @param _username username of the virtual account
    /// @param _email new email of the virtual account
    /// @param _masterPin master pin of the virtual account
    function updateEmail(string memory _username, string memory _email, uint256 _masterPin) external;

    /// @notice update the phone of the virtual account only accessible by the operator and accepting the new phone and the master pin
    /// @param _username username of the virtual account
    /// @param _phone new phone of the virtual account
    /// @param _masterPin master pin of the virtual account
    function updatePhone(string memory _username, string memory _phone, uint256 _masterPin) external;

    /// @notice update the expired PIN of the virtual account only accessible by the operator and accepting the new PIN and the master pin
    /// @param _username username of the virtual account
    /// @param _newPin new PIN of the virtual account
    /// @param _masterPin master pin of the virtual account
    function updatePin(string memory _username, uint256 _newPin, uint256 _masterPin) external;

    /// @notice update the account of the virtual account only accessible by the operator and accepting the new account and the master pin
    /// @param _username username of the virtual account
    /// @param _account new account of the virtual account
    /// @param _masterPin master pin of the virtual account
    function updateAccount(string memory _username, address _account, uint256 _masterPin) external;

    /// @notice generate a new unique session key for the virtual account
    /// @param _username username of the virtual account
    /// @param _masterPin master pin of the virtual account
    function generateSessionKey(string memory _username, uint256 _masterPin) external;

    /// @notice get the session key of the virtual account
    /// @param _username username of the virtual account
    function getSessionKey(string memory _username) external view returns (bytes32);

    /// @notice validate the session key of the virtual account
    /// @param _username username of the virtual account
    /// @param _sessionKey session key of the virtual account
    function validateSessionKey(string memory _username, bytes32 _sessionKey) external view returns (bool);
    
    /// support interface
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /// helpers

    /// get the email of the virtual account
    function getEmail(string memory _username) external view returns (string memory);
    
    /// get the phone of the virtual account
    function getPhone(string memory _username) external view returns (string memory);
    
    /// get the username of a wallet
    function getUsername(address _wallet) external view returns (string memory);
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

pragma solidity ^0.8.9;

contract VirtualAccountSystem is Authorized, IVirtualAccountSystem {
    
    constructor() {}

    /// variables
    
    ///@notice The minimum time between PIN changes
    uint256 private _minTimeChangePin = 1 days;

    /// @notice the expiration time for the PIN
    uint256 private _expirationTimePin = 30 days;

    /// @notice the expiration time for the session key
    uint256 private _expirationTimeSessionKey = 1 days;
    
    /// Mappings

    /// @notice A mapping storing authorized admins
    /// @dev admin address => authorized status
    mapping (address => bool) private authorizedAdmins;

    /// @notice A mapping of the authorized delegate operators
    /// @dev operator address => authorized status
    mapping (address => bool) private authorizedOperators;

    /// @notice mapping of the virtual accounts for each username
    /// @dev username => virtual account struct
    mapping (string => VirtualAccount) private virtualAccounts;

    /// @notice mapping of the session keys for each username
    /// @dev username => session key struct
    mapping (string => SessionKey) private sessionKeys;

    /// @notice mapping of the self custody wallets and usernames
    /// @dev self custody wallet => username
    mapping (address => string) private selfCustodyWallets;
    
    /// Modifiers
    
    /// @dev modifier to ensure the PIN is not expired
    modifier isPinExpired(string memory username) {
        if (block.timestamp - virtualAccounts[username].lastChangePin > _expirationTimePin) {
            revert PinExpired();
        }
        _;
    }

    /// @dev modidifier to ensure that session key is valid
    modifier isSessionKeyValid(string memory username) {
        if (block.timestamp - sessionKeys[username].createdAt > _expirationTimeSessionKey) {
            revert SessionKeyExpired();
        }
        _;
    }

    /// @inheritdoc Authorized
    function setAuthorizedOperator(address _operator, bool status) public override isAuthorizedAdmin {  
        uint32 size;
        assembly {
            size := extcodesize(_operator)
        }

        if(size > 0) {
            IAuthenticable authenticable = IAuthenticable(_operator);
            require(authenticable.supportsInterface(type(IAuthenticable).interfaceId), "VirtualAccountSystem: Operator must implement IAuthenticable");
        }

        super.setAuthorizedOperator(_operator, status);
    }

    /// @notice create a new virtual account only asking for the username, email, and master pin. Only the authorized operator can create a new virtual account
    /// @inheritdoc IVirtualAccountSystem
    function createVirtualAccount(string memory _username, string memory _email, uint256 _masterPin) external isAuthorizedOperator {
        /// check if the username is not empty
        require(bytes(_username).length > 0, "VirtualAccountSystem: Username cannot be empty");
        /// check if the email is not empty
        require(bytes(_email).length > 0, "VirtualAccountSystem: Email cannot be empty");
        /// check if the master pin is not empty
        require(_masterPin > 0, "VirtualAccountSystem: Master pin cannot be empty");
        /// check if the virtual account does not exist
        if(virtualAccounts[_username].createdAt != 0) {
            revert VirtualAccountAlreadyExists();
        }

        /// create the virtual account
        virtualAccounts[_username] = VirtualAccount({
            email: _email,
            phone: "",
            account: address(0),
            operator: msg.sender,
            masterPin: _masterPin,
            lastChangePin: block.timestamp,
            lastUsePin: block.timestamp,
            createdAt: block.timestamp
        });
        emit CreateVirtualAccount(_username, msg.sender, block.timestamp);
    }

    /// @notice attach a new wallet to the virtual account only accessible by the operator and accepting the username, wallet address, and master pin
    /// @inheritdoc IVirtualAccountSystem
    function attachWallet(string memory _username, address _wallet, uint256 _masterPin) external isAuthorizedOperator isPinExpired(_username) {
        /// check if the username is not empty
        require(bytes(_username).length > 0, "VirtualAccountSystem: Username cannot be empty");
        /// check if the wallet address is not empty
        require(_wallet != address(0), "VirtualAccountSystem: Wallet address cannot be empty");
        /// check if the master pin is not empty
        require(_masterPin > 0, "VirtualAccountSystem: Master pin cannot be empty");
        /// check if the virtual account exists
        require(virtualAccounts[_username].createdAt > 0, "VirtualAccountSystem: Virtual account does not exist");
        /// check if the wallet is not already attached to another virtual account
        /// compare two strings
        bytes32  username = keccak256(abi.encodePacked(selfCustodyWallets[_wallet]));
        bytes32  empty = keccak256(abi.encodePacked(""));
        require(username == empty, "VirtualAccountSystem: Wallet is already attached to another virtual account");
        /// check if the master pin is correct
        require(virtualAccounts[_username].masterPin == _masterPin, "VirtualAccountSystem: Master pin is incorrect");
        /// update the wallet address
        virtualAccounts[_username].account = _wallet;
        /// update the last change pin
        virtualAccounts[_username].lastChangePin = block.timestamp;
        /// update the last use pin
        virtualAccounts[_username].lastUsePin = block.timestamp;
        /// update the self custody wallet
        selfCustodyWallets[_wallet] = _username;

        emit ConnectSelfCustodyWallet(_username, _wallet, msg.sender, block.timestamp);
    }

    /// @notice update the attached wallet to the virtual account only accessible by the operator and accepting the username, wallet address, and master pin
    /// @inheritdoc IVirtualAccountSystem
    function updateWallet(string memory _username, address _wallet, address oldWallet, uint256 _masterPin) external isAuthorizedOperator isPinExpired(_username) {
        /// check if the username is not empty
        require(bytes(_username).length > 0, "VirtualAccountSystem: Username cannot be empty");
        /// check if the wallet address is not empty
        require(_wallet != address(0), "VirtualAccountSystem: Wallet address cannot be empty");
        /// check if the master pin is not empty
        require(_masterPin > 0, "VirtualAccountSystem: Master pin cannot be empty");
        /// check if the virtual account exists
        require(virtualAccounts[_username].createdAt > 0, "VirtualAccountSystem: Virtual account does not exist");
        /// check if the wallet is not already attached to another virtual account
        /// compare two strings
        bytes32  username = keccak256(abi.encodePacked(selfCustodyWallets[_wallet]));
        bytes32  empty = keccak256(abi.encodePacked(""));
        require(username == empty, "VirtualAccountSystem: Wallet is already attached to another virtual account");
        /// check if the master pin is correct
        require(virtualAccounts[_username].masterPin == _masterPin, "VirtualAccountSystem: Master pin is incorrect");
        /// update the wallet address
        virtualAccounts[_username].account = _wallet;
        /// update the last change pin
        virtualAccounts[_username].lastChangePin = block.timestamp;
        /// update the last use pin
        virtualAccounts[_username].lastUsePin = block.timestamp;
        /// update the self custody wallet
        selfCustodyWallets[_wallet] = _username;
        /// delete the old wallet
        delete selfCustodyWallets[oldWallet];

        emit UpdateSelfCustodyWallet(_username, _wallet, msg.sender, block.timestamp);
    }

    /// @notice update the email of the virtual account only accessible by the operator and accepting the new email and the master pin
    /// @inheritdoc IVirtualAccountSystem
    function updateEmail(string memory _username, string memory _email, uint256 _masterPin) external isAuthorizedOperator isPinExpired(_username) {
        /// check if the username is not empty
        require(bytes(_username).length > 0, "VirtualAccountSystem: Username cannot be empty");
        /// check if the email is not empty
        require(bytes(_email).length > 0, "VirtualAccountSystem: Email cannot be empty");
        /// check if the master pin is not empty
        require(_masterPin > 0, "VirtualAccountSystem: Master pin cannot be empty");
        /// check if the virtual account exists
        require(virtualAccounts[_username].createdAt > 0, "VirtualAccountSystem: Virtual account does not exist");
        /// check if the master pin is correct
        require(virtualAccounts[_username].masterPin == _masterPin, "VirtualAccountSystem: Master pin is incorrect");
    
        /// update the email
        virtualAccounts[_username].email = _email;
    }

    /// @notice update the phone of the virtual account only accessible by the operator and accepting the new phone and the master pin
    /// @inheritdoc IVirtualAccountSystem
    function updatePhone(string memory _username, string memory _phone, uint256 _masterPin) external isAuthorizedOperator isPinExpired(_username) {
        /// check if the username is not empty
        require(bytes(_username).length > 0, "VirtualAccountSystem: Username cannot be empty");
        /// check if the phone is not empty
        require(bytes(_phone).length > 0, "VirtualAccountSystem: Phone cannot be empty");
        /// check if the master pin is not empty
        require(_masterPin > 0, "VirtualAccountSystem: Master pin cannot be empty");
        /// check if the virtual account exists
        require(virtualAccounts[_username].createdAt > 0, "VirtualAccountSystem: Virtual account does not exist");
        /// check if the master pin is correct
        require(virtualAccounts[_username].masterPin == _masterPin, "VirtualAccountSystem: Master pin is incorrect");
    
        /// update the phone
        virtualAccounts[_username].phone = _phone;
    }

    /// @notice update the expired PIN of the virtual account only accessible by the operator and accepting the new PIN and the master pin
    /// @inheritdoc IVirtualAccountSystem
    function updatePin(string memory _username, uint256 _newPin, uint256 _masterPin) external isAuthorizedOperator {
        /// check if the username is not empty
        require(bytes(_username).length > 0, "VirtualAccountSystem: Username cannot be empty");
        /// check if the new pin is not empty
        require(_newPin > 0, "VirtualAccountSystem: New pin cannot be empty");
        /// check if the master pin is not empty
        require(_masterPin > 0, "VirtualAccountSystem: Master pin cannot be empty");
        /// check if the virtual account exists
        require(virtualAccounts[_username].createdAt > 0, "VirtualAccountSystem: Virtual account does not exist");
        /// check if the master pin is correct
        require(virtualAccounts[_username].masterPin == _masterPin, "VirtualAccountSystem: Master pin is incorrect");
    
        /// update the PIN
        virtualAccounts[_username].masterPin = _newPin;
        virtualAccounts[_username].lastChangePin = block.timestamp;
    }

    /// @notice update the account of the virtual account only accessible by the operator and accepting the new account and the master pin
    /// @inheritdoc IVirtualAccountSystem
    function updateAccount(string memory _username, address _account, uint256 _masterPin) external isAuthorizedOperator isPinExpired(_username) {
        /// check if the username is not empty
        require(bytes(_username).length > 0, "VirtualAccountSystem: Username cannot be empty");
        /// check if the account is not empty
        require(_account != address(0), "VirtualAccountSystem: Account cannot be empty");
        /// check if the master pin is not empty
        require(_masterPin > 0, "VirtualAccountSystem: Master pin cannot be empty");
        /// check if the virtual account exists
        require(virtualAccounts[_username].createdAt > 0, "VirtualAccountSystem: Virtual account does not exist");
        /// check if the master pin is correct
        require(virtualAccounts[_username].masterPin == _masterPin, "VirtualAccountSystem: Master pin is incorrect");

        /// check if the account is not already used
        
    
        /// update the account
        virtualAccounts[_username].account = _account;
    }

    /// @inheritdoc IVirtualAccountSystem
    function generateSessionKey(string memory _username, uint256 _masterPin) external isAuthorizedOperator isPinExpired(_username) {
        /// check if the username is not empty
        require(bytes(_username).length > 0, "VirtualAccountSystem: Username cannot be empty");
        /// check if the master pin is not empty
        require(_masterPin > 0, "VirtualAccountSystem: Master pin cannot be empty");
        /// check if the virtual account exists
        require(virtualAccounts[_username].createdAt > 0, "VirtualAccountSystem: Virtual account does not exist");
        /// check if the master pin is correct
        require(virtualAccounts[_username].masterPin == _masterPin, "VirtualAccountSystem: Master pin is incorrect");

        /// generate a new session key
        bytes32 sessionKey = keccak256(abi.encodePacked(_username, block.timestamp, _masterPin));
        /// update the session key
        sessionKeys[_username].sessionKey = sessionKey;
        /// update the last use session key
        sessionKeys[_username].createdAt = block.timestamp;
        /// update the last use pin
        virtualAccounts[_username].lastUsePin = block.timestamp;
    }

    /// @inheritdoc IVirtualAccountSystem
    function getSessionKey(string memory _username) external isAuthorizedOperator view returns (bytes32) {
        /// check if the username is not empty
        require(bytes(_username).length > 0, "VirtualAccountSystem: Username cannot be empty");
        /// check if the virtual account exists
        require(virtualAccounts[_username].createdAt > 0, "VirtualAccountSystem: Virtual account does not exist");
        /// check is the session key is not expired
        if(sessionKeys[_username].createdAt + _expirationTimeSessionKey <= block.timestamp) {
            revert SessionKeyExpired();
        }

        /// return the session key
        return sessionKeys[_username].sessionKey;
    }

    /// @inheritdoc IVirtualAccountSystem
    function validateSessionKey(string memory _username, bytes32 _sessionKey) external isAuthorizedOperator view returns (bool) {
        /// check if the username is not empty
        require(bytes(_username).length > 0, "VirtualAccountSystem: Username cannot be empty");
        /// check if the virtual account exists
        require(virtualAccounts[_username].createdAt > 0, "VirtualAccountSystem: Virtual account does not exist");
        /// check is the session key is not expired
        if(sessionKeys[_username].createdAt + _expirationTimeSessionKey <= block.timestamp) {
            revert SessionKeyExpired();
        }

        /// return the session key
        return sessionKeys[_username].sessionKey == _sessionKey;
    }

    /// @inheritdoc IVirtualAccountSystem
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IVirtualAccountSystem).interfaceId;
    }
    /// helpers

    /// get the email of the virtual account
    function getEmail(string memory _username) external isAuthorizedOperator view returns (string memory) {
        return virtualAccounts[_username].email;
    }
    
    /// get the phone of the virtual account
    function getPhone(string memory _username) external isAuthorizedOperator view returns (string memory) {
        return virtualAccounts[_username].phone;
    }

    /// get the username of a wallet
    function getUsername(address _wallet) external isAuthorizedOperator view returns (string memory) {
        return selfCustodyWallets[_wallet];
    }

}