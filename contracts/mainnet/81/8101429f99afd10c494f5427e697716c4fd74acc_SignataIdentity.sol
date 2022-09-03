/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// File: contracts/SignataIdentity.sol





pragma solidity ^0.8.11;



contract SignataIdentity {

    uint256 public constant MAX_UINT256 = type(uint256).max;

    

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")

    bytes32 public constant EIP712DOMAINTYPE_DIGEST = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

    

    // keccak256("Signata")

    bytes32 public constant NAME_DIGEST = 0xfc8e166e81add347414f67a8064c94523802ae76625708af4cddc107b656844f;

    

    // keccak256("1")

    bytes32 public constant VERSION_DIGEST = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    

    bytes32 public constant SALT = 0x233cdb81615d25013bb0519fbe69c16ddc77f9fa6a9395bd2aecfdfc1c0896e3;

    

    // keccak256("create(uint8 identityV, bytes32 identityR, bytes32 identityS, address delegateAddress, address securityKey)")

    bytes32 public constant TXTYPE_CREATE_DIGEST = 0x087280f638c5afab2bc9df90375624dfabc18c6dcec33665afdc2db6ad4048b1;

    

    // keccak256("destroy(address identity, uint8 delegateV, bytes32 delegateR, bytes32 delegateS, uint8 securityV, bytes32 securityR, bytes32 securityS)");

    bytes32 public constant TXTYPE_DESTROY_DIGEST = 0x9b364f015edab2a56fcadebbd609a6626a0612d05dd5d0b2203e1b1317d70ef7;

    

    // keccak256("lock(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS)")

    bytes32 public constant TXTYPE_LOCK_DIGEST = 0x703ed461c8d1c12e6e8b4708e8034e12d743b6221f0dbc5d301224713022c204;



    // keccak256("unlock(address identity, uint8 securityV, bytes32 securityR, bytes32 securityS)")

    bytes32 public constant TXTYPE_UNLOCK_DIGEST = 0x8364584c57b345e5810179c75cd470a8b1bd71cc8ee2c05074a1ffe55b48b865;



    // keccak256("rollover(address identity, uint8 delegateV, bytes32 delegateR, bytes32 delegateS, uint8 securityV, bytes32 securityR, bytes32 securityS, address newDelegateAddress, address newSecurityAddress)")

    bytes32 public constant TXTYPE_ROLLOVER_DIGEST = 0x7c62ea77dc835faa5b9bff6fd0f00c7b793acdd94960f48e7c9f47e28462085f;

    

    bytes32 public immutable _domainSeparator;

    

    // storage

    mapping(address => address) public _delegateKeyToIdentity;

    mapping(address => uint256) public _identityLockCount;

    mapping(address => uint256) public _identityRolloverCount;

    mapping(address => address) public _identityToSecurityKey;

    mapping(address => address) public _identityToDelegateKey;

    mapping(address => bool) public _identityDestroyed;

    mapping(address => bool) public _identityExists;

    mapping(address => bool) public _identityLocked;

    

    constructor(uint256 chainId) {

        _domainSeparator = keccak256(

            abi.encode(

                EIP712DOMAINTYPE_DIGEST,

                NAME_DIGEST,

                VERSION_DIGEST,

                chainId,

                this,

                SALT

            )

        );

    }

    

    event Create(address indexed identity, address indexed delegateKey, address indexed securityKey);

    event Destroy(address indexed identity);

    event Lock(address indexed identity);

    event Rollover(address indexed identity, address indexed delegateKey, address indexed securityKey);

    event Unlock(address indexed identity);

    

    function create(

        uint8 identityV, 

        bytes32 identityR, 

        bytes32 identityS,

        address identityAddress,

        address delegateAddress, 

        address securityAddress

    )

        external

    {

        require(

            _delegateKeyToIdentity[delegateAddress] == address(0),

            "SignataIdentity: Delegate key must not already be in use."

        );

        

        bytes32 digest = keccak256(

            abi.encodePacked(

                "\x19\x01",

                _domainSeparator,

                keccak256(

                    abi.encode(

                        TXTYPE_CREATE_DIGEST,

                        delegateAddress,

                        securityAddress

                    )

                )

            )

        );

        

        address identity = ecrecover(digest, identityV, identityR, identityS);



        require(identity == identityAddress, "SignataIdentity: Invalid signature for identity");

        

        require(

            identity != delegateAddress && identity != securityAddress && delegateAddress != securityAddress,

            "SignataIdentity: Keys must be unique."

        );

        

        require(

            !_identityExists[identity],

            "SignataIdentity: The identity must not already exist."

        );

        

        _delegateKeyToIdentity[delegateAddress] = identity;

        _identityToDelegateKey[identity] = delegateAddress;

        _identityExists[identity] = true;

        _identityToSecurityKey[identity] = securityAddress;

        

        emit Create(identity, delegateAddress, securityAddress);

    }



    function destroy(

        address identity,

        uint8 delegateV,

        bytes32 delegateR, 

        bytes32 delegateS,

        uint8 securityV,

        bytes32 securityR, 

        bytes32 securityS

    )

        external

    {

        require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has already been destroyed."

        );

        

        bytes32 digest = keccak256(

            abi.encodePacked(

                "\x19\x01",

                _domainSeparator,

                keccak256(

                    abi.encode(

                        TXTYPE_DESTROY_DIGEST

                    )

                )

            )

        );

        

        address delegateAddress = ecrecover(digest, delegateV, delegateR, delegateS);

        

        require(

            _identityToDelegateKey[identity] == delegateAddress,

            "SignataIdentity: Invalid delegate key signature provided."

        );

        

        address securityAddress = ecrecover(digest, securityV, securityR, securityS);

        

        require(

            _identityToSecurityKey[identity] == securityAddress,

            "SignataIdentity: Invalid security key signature provided."

        );

        

        _identityDestroyed[identity] = true;

        

        delete _delegateKeyToIdentity[delegateAddress];

        delete _identityLockCount[identity];

        delete _identityRolloverCount[identity];

        delete _identityToSecurityKey[identity];

        delete _identityToDelegateKey[identity];

        delete _identityLocked[identity];

        

        emit Destroy(identity);

    }



    function lock(

        address identity,

        uint8 sigV,

        bytes32 sigR,

        bytes32 sigS

    )

        external

    {

        require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has been destroyed."

        );

        

        require(

            !_identityLocked[identity],

            "SignataIdentity: The identity has already been locked."

        );

                

        bytes32 digest = keccak256(

            abi.encodePacked(

                "\x19\x01",

                _domainSeparator,

                keccak256(

                    abi.encode(

                        TXTYPE_LOCK_DIGEST,

                        _identityLockCount[identity]

                    )

                )

            )

        );

        

        address recoveredAddress = ecrecover(digest, sigV, sigR, sigS);

        

        require(

            _identityToDelegateKey[identity] == recoveredAddress || _identityToSecurityKey[identity] == recoveredAddress,

            "SignataIdentity: Invalid key signature provided."

        );



        _identityLocked[identity] = true;

        _identityLockCount[identity] += 1;

        

        emit Lock(identity);

    }



    function unlock(

        address identity,

        uint8 securityV,

        bytes32 securityR,

        bytes32 securityS

    ) 

        external 

    {

        require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has been destroyed."

        );

        

        require(

            _identityLocked[identity],

            "SignataIdentity: The identity is already unlocked."

        );

        

        require(

            _identityLockCount[identity] != MAX_UINT256,

            "SignataIdentity: The identity is permanently locked."

        );

        

        bytes32 digest = keccak256(

            abi.encodePacked(

                "\x19\x01",

                _domainSeparator,

                keccak256(

                    abi.encode(

                        TXTYPE_UNLOCK_DIGEST,

                        _identityLockCount[identity]

                    )

                )

            )

        );

        

        address securityAddress = ecrecover(digest, securityV, securityR, securityS);

        

        require(

            _identityToSecurityKey[identity] == securityAddress,

            "SignataIdentity: Invalid security key signature provided."

        );

        

        _identityLocked[identity] = false;

        

        emit Unlock(identity);

    }

    

    function rollover(

        address identity,

        uint8 delegateV,

        bytes32 delegateR,

        bytes32 delegateS,

        uint8 securityV,

        bytes32 securityR,

        bytes32 securityS,

        address newDelegateAddress,

        address newSecurityAddress

    ) 

        external 

    {

        require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has been destroyed."

        );

        

        require(

            identity != newDelegateAddress && identity != newSecurityAddress && newDelegateAddress != newSecurityAddress,

            "SignataIdentity: The keys must be unique."

        );

        

        require(

            _delegateKeyToIdentity[newDelegateAddress] == address(0),

            "SignataIdentity: The new delegate key must not already be in use."

        );

        

        require(

            _identityRolloverCount[identity] != MAX_UINT256,

            "SignataIdentity: The identity has already reached the maximum number of rollovers allowed."

        );



        bytes32 digest = keccak256(

            abi.encodePacked(

                "\x19\x01",

                _domainSeparator,

                keccak256(

                    abi.encode(

                        TXTYPE_ROLLOVER_DIGEST,

                        newDelegateAddress,

                        newSecurityAddress,

                        _identityRolloverCount[identity]

                    )

                )

            )

        );

        

        address delegateAddress = ecrecover(digest, delegateV, delegateR, delegateS);

        

        require(

            _identityToDelegateKey[identity] == delegateAddress,

            "SignataIdentity: Invalid delegate key signature provided."

        );

        

        address securityAddress = ecrecover(digest, securityV, securityR, securityS);

        

        require(

            _identityToSecurityKey[identity] == securityAddress,

            "SignataIdentity: Invalid delegate key signature provided."

        );

        

        delete _delegateKeyToIdentity[delegateAddress];

        

        _delegateKeyToIdentity[newDelegateAddress] = identity;

        _identityToDelegateKey[identity] = newDelegateAddress;

        _identityToSecurityKey[identity] = newSecurityAddress;

        _identityRolloverCount[identity] += 1;

        

        emit Rollover(identity, newDelegateAddress, newSecurityAddress);

    }

    

    function getDelegate(address identity)

        external

        view

        returns (address)

    {

        require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has been destroyed."

        );

        

        return _identityToDelegateKey[identity];

    }

    

    function getIdentity(address delegateKey) 

        external

        view 

        returns (address) 

    {

        address identity = _delegateKeyToIdentity[delegateKey];

        

        require(

            identity != address(0),

            "SignataIdentity: The delegate key provided is not linked to an existing identity."

        );

        

        return identity;

    }



    function getLockCount(address identity)

        external

        view

        returns (uint256) 

    {

         require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has been destroyed."

        );

        

        return _identityLockCount[identity];

    }    

    

    function getRolloverCount(address identity)

        external

        view

        returns (uint256) 

    {

        require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has been destroyed."

        );

        

        return _identityRolloverCount[identity];

    }

    

    function isLocked(address identity)

        external

        view

        returns (bool) 

    {

        require(

            _identityExists[identity],

            "SignataIdentity: The identity must exist."

        );

        

        require(

            !_identityDestroyed[identity],

            "SignataIdentity: The identity has been destroyed."

        );

        

        return _identityLocked[identity];

    }

}