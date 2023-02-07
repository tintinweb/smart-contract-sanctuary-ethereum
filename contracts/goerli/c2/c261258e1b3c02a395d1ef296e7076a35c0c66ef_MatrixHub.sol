/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File contracts/libraries/DataTypes.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library DataTypes {
    struct ProfileStruct {
        string displayName;
        string avatarURL;
    }

    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct SetProfileWithSigData {
        address user;
        string displayName;
        string avatarURL;
        EIP712Signature sig;
    }

    struct SetServerNameWithSigData {
        address user;
        string serverName;
        EIP712Signature sig;
    }

    struct RegisterAccountWithSigData {
        address user;
        string serverName;
        string displayName;
        string avatarURL;
        EIP712Signature sig;
    }
}


// File contracts/libraries/Events.sol


library Events {
    event Registration(address user, uint256 timestamp);

    event ProfileSet(address user, DataTypes.ProfileStruct profile);

    event ServerNameSet(address user, string serverName);
}


// File contracts/libraries/Errors.sol


library Errors {
    error SignatureExpired();
    error SignatureInvalid();
    error AccountRegistered();
    error AccountUnregistered();
}


// File contracts/misc/MatrixPeriphery.sol


contract MatrixPeriphery {
    string public constant NAME = "MatrixPeriphery";
    bytes32 internal constant EIP712_REVISION_HASH = keccak256("1");
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    function validateRecoveredAddress(
        bytes32 digest,
        address expectedAddress,
        DataTypes.EIP712Signature memory sig
    ) internal view {
        if (sig.deadline < block.timestamp) revert Errors.SignatureExpired();
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        if (
            recoveredAddress == address(0) ||
            recoveredAddress != expectedAddress
        ) revert Errors.SignatureInvalid();
    }

    function calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(NAME)),
                    EIP712_REVISION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    function calculateDigest(bytes32 hashedMessage)
        internal
        view
        returns (bytes32)
    {
        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    calculateDomainSeparator(),
                    hashedMessage
                )
            );
        }

        return digest;
    }
}


// File contracts/storage/MatrixHubStorage.sol


contract MatrixHubStorage {
    bytes32 internal constant SET_PROFILE_WITH_SIG_TYPEHASH =
        keccak256(
            "SetProfileWithSig(string displayName,string avatarURL,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant SET_SERVERNAME_WITH_SIG_TYPEHASH =
        keccak256(
            "SetServerNameWithSig(string serverName,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant REGISTER_ACCOUNT_WITH_SIG_TYPEHASH =
        keccak256(
            "RegisterAccountWithSig(string serverName,string displayName,string avatarURL,uint256 nonce,uint256 deadline)"
        );

    mapping(address => uint256) public sigNonces;
    mapping(address => uint256) public registered;
    mapping(address => string) public serverNames;
    mapping(address => DataTypes.ProfileStruct) public profiles;

    modifier onlyRegistered(address user) {
        if (registered[user] == 0) {
            revert Errors.AccountUnregistered();
        }
        _;
    }

    modifier onlyUnregistered(address user) {
        if (registered[user] > 0) {
            revert Errors.AccountRegistered();
        }
        _;
    }
}


// File contracts/MatrixHub.sol


contract MatrixHub is MatrixHubStorage, MatrixPeriphery {
    function registerAccount(
        string calldata serverName,
        DataTypes.ProfileStruct calldata profile
    ) external onlyUnregistered(msg.sender) {
        profiles[msg.sender] = profile;
        serverNames[msg.sender] = serverName;
        registered[msg.sender] = block.timestamp;

        emit Events.Registration(msg.sender, block.timestamp);
        emit Events.ProfileSet(msg.sender, profile);
        emit Events.ServerNameSet(msg.sender, serverName);
    }

    function registerAccountWithSig(
        DataTypes.RegisterAccountWithSigData calldata vars
    ) external onlyUnregistered(vars.user) {
        unchecked {
            validateRecoveredAddress(
                calculateDigest(
                    keccak256(
                        abi.encode(
                            REGISTER_ACCOUNT_WITH_SIG_TYPEHASH,
                            keccak256(bytes(vars.serverName)),
                            keccak256(bytes(vars.displayName)),
                            keccak256(bytes(vars.avatarURL)),
                            sigNonces[vars.user]++,
                            vars.sig.deadline
                        )
                    )
                ),
                vars.user,
                vars.sig
            );
        }

        registered[vars.user] = block.timestamp;

        emit Events.Registration(vars.user, block.timestamp);

        DataTypes.ProfileStruct storage profile = profiles[vars.user];
        profile.displayName = vars.displayName;
        profile.avatarURL = vars.avatarURL;

        emit Events.ProfileSet(vars.user, profile);

        serverNames[vars.user] = vars.serverName;

        emit Events.ServerNameSet(vars.user, vars.serverName);
    }

    function setProfile(DataTypes.ProfileStruct calldata profile)
        external
        onlyRegistered(msg.sender)
    {
        profiles[msg.sender] = profile;

        emit Events.ProfileSet(msg.sender, profile);
    }

    function setProfileWithSig(DataTypes.SetProfileWithSigData calldata vars)
        external
        onlyRegistered(vars.user)
    {
        unchecked {
            validateRecoveredAddress(
                calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_PROFILE_WITH_SIG_TYPEHASH,
                            keccak256(bytes(vars.displayName)),
                            keccak256(bytes(vars.avatarURL)),
                            sigNonces[vars.user]++,
                            vars.sig.deadline
                        )
                    )
                ),
                vars.user,
                vars.sig
            );
        }

        DataTypes.ProfileStruct storage profile = profiles[vars.user];
        profile.displayName = vars.displayName;
        profile.avatarURL = vars.avatarURL;

        emit Events.ProfileSet(vars.user, profile);
    }

    function setServerName(string calldata serverName)
        external
        onlyRegistered(msg.sender)
    {
        serverNames[msg.sender] = serverName;

        emit Events.ServerNameSet(msg.sender, serverName);
    }

    function setServerNameWithSig(
        DataTypes.SetServerNameWithSigData calldata vars
    ) external onlyRegistered(vars.user) {
        unchecked {
            validateRecoveredAddress(
                calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_SERVERNAME_WITH_SIG_TYPEHASH,
                            keccak256(bytes(vars.serverName)),
                            sigNonces[vars.user]++,
                            vars.sig.deadline
                        )
                    )
                ),
                vars.user,
                vars.sig
            );
        }

        serverNames[vars.user] = vars.serverName;

        emit Events.ServerNameSet(vars.user, vars.serverName);
    }
}