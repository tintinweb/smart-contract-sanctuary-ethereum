/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// File contracts/ERC735.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ERC735 {

    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed claimType, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);    event ClaimAdded(bytes32 indexed claimId, uint256 indexed claimType, address indexed issuer, uint256 signatureType, bytes32 signature, bytes claim, string uri);
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed claimType, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed claimType, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed claimType, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    struct Claim {
        uint256 claimType;
        uint256 scheme;
        address issuer; // msg.sender
        bytes signature; // this.address + claimType + data
        bytes data;
        string uri;
    }

    function getClaim(bytes32 _claimId) public virtual returns(uint256 claimType, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri);
    function getClaimIdsByType(uint256 _claimType) public virtual returns(bytes32[] memory claimIds);
    function addClaim(uint256 _claimType, uint256 _scheme, address issuer, bytes memory _signature, bytes memory _data, string memory _uri) public virtual returns (bytes32 claimRequestId);
    function removeClaim(bytes32 _claimId) public virtual returns (bool success);
}


// File contracts/ERC725.sol


pragma solidity ^0.8.0;

abstract contract ERC725 {

    uint256 constant MANAGEMENT_KEY = 1;
    uint256 constant ACTION_KEY = 2;
    uint256 constant CLAIM_SIGNER_KEY = 3;
    uint256 constant ENCRYPTION_KEY = 4;

    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Approved(uint256 indexed executionId, bool approved);

    struct Key {
        uint256 purpose; //e.g., MANAGEMENT_KEY = 1, ACTION_KEY = 2, etc.
        uint256 keyType; // e.g. 1 = ECDSA, 2 = RSA, etc.
        bytes32 key;
    }

    function getKey(bytes32 _key) public virtual returns(uint256 purpose, uint256 keyType, bytes32 key);
    function getKeyPurpose(bytes32 _key) public virtual returns(uint256 purpose);
    function getKeysByPurpose(uint256 _purpose) public virtual returns(bytes32[] memory keys);
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public virtual returns (bool success);
    function execute(address _to, uint256 _value, bytes memory _data) public virtual returns (uint256 executionId);
    function approve(uint256 _id, bool _approve) public virtual returns (bool success);
}


// File contracts/KeyHolder.sol

pragma solidity ^0.8.0;

contract KeyHolder is ERC725 {

    uint256 executionNonce;

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }

    mapping (bytes32 => Key) keys;
    mapping (uint256 => bytes32[]) keysByPurpose;
    mapping (uint256 => Execution) executions;

    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    constructor() {
        bytes32 _key = keccak256(abi.encodePacked(msg.sender));
        keys[_key].key = _key;
        keys[_key].purpose = 1;
        keys[_key].keyType = 1;
        keysByPurpose[1].push(_key);
        emit KeyAdded(_key, keys[_key].purpose, 1);
    }

    function getKey(bytes32 _key)
        public
        override
        view
        returns(uint256 purpose, uint256 keyType, bytes32 key)
    {
        return (keys[_key].purpose, keys[_key].keyType, keys[_key].key);
    }

    function getKeyPurpose(bytes32 _key)
        public
        override
        view
        returns(uint256 purpose)
    {
        return (keys[_key].purpose);
    }

    function getKeysByPurpose(uint256 _purpose)
        public
        override
        view
        returns(bytes32[] memory _keys)
    {
        return keysByPurpose[_purpose];
    }

    function addKey(bytes32 _key, uint256 _purpose, uint256 _type)
        public
        override
        returns (bool success)
    {
        require(keys[_key].key != _key, "Key already exists"); // Key should not already exist
        if (msg.sender != address(this)) {
          require(keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key"); // Sender has MANAGEMENT_KEY
        }

        keys[_key].key = _key;
        keys[_key].purpose = _purpose;
        keys[_key].keyType = _type;

        keysByPurpose[_purpose].push(_key);

        emit KeyAdded(_key, _purpose, _type);

        return true;
    }

    function approve(uint256 _id, bool _approve)
        public
        override
        returns (bool success)
    {
        require(keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), 2), "Sender does not have action key");

        emit Approved(_id, _approve);

        if (_approve == true) {
            executions[_id].approved = true;
            (success, ) = executions[_id].to.call(executions[_id].data);
            if (success) {
                executions[_id].executed = true;
                emit Executed(
                    _id,
                    executions[_id].to,
                    executions[_id].value,
                    executions[_id].data
                );
                return true;
            } else {
                emit ExecutionFailed(
                    _id,
                    executions[_id].to,
                    executions[_id].value,
                    executions[_id].data
                );
                return false;
            }
        } else {
            executions[_id].approved = false;
        }
        return true;
    }

    function execute(address _to, uint256 _value, bytes memory _data)
        public
        override
        returns (uint256 executionId)
    {
        require(!executions[executionNonce].executed, "Already executed");
        executions[executionNonce].to = _to;
        executions[executionNonce].value = _value;
        executions[executionNonce].data = _data;

        emit ExecutionRequested(executionNonce, _to, _value, _data);

        if (keyHasPurpose(keccak256(abi.encodePacked(msg.sender)),1) || keyHasPurpose(keccak256(abi.encodePacked(msg.sender)),2)) {
            approve(executionNonce, true);
        }

        executionNonce++;
        return executionNonce-1;
    }

    function removeKey(bytes32 _key)
        public
        returns (bool success)
    {
        require(keys[_key].key == _key, "No such key");
        emit KeyRemoved(keys[_key].key, keys[_key].purpose, keys[_key].keyType);

        /* uint index;
        (index,) = keysByPurpose[keys[_key].purpose.indexOf(_key);
        keysByPurpose[keys[_key].purpose.removeByIndex(index); */

        delete keys[_key];

        return true;
    }

    function keyHasPurpose(bytes32 _key, uint256 _purpose)
        public
        view
        returns(bool result)
    {
        bool isThere;
        if (keys[_key].key == 0) return false;
        isThere = keys[_key].purpose <= _purpose;
        return isThere;
    }

    function addrToKey(address addr) public pure returns (bytes32) {
        bytes32 _tempKey = keccak256(abi.encodePacked(addr));
        return _tempKey;
    }

}


// File contracts/ClaimHolder.sol

pragma solidity ^0.8.0;


contract ClaimHolder is KeyHolder, ERC735 {

    mapping (bytes32 => Claim) claims;
    mapping (uint256 => bytes32[]) claimsByType;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function addClaim(
        uint256 _claimType,
        uint256 _scheme,
        address _issuer,
        bytes memory _signature,
        bytes memory _data,
        string memory _uri
    )
        public
        override
        returns (bytes32 claimRequestId)
    {
        bytes32 claimId = keccak256(abi.encodePacked(_issuer, _claimType));

        if (msg.sender != address(this)) {
          require(keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), 3), "Sender does not have claim signer key");
        }

        if (claims[claimId].issuer != _issuer) {
            claimsByType[_claimType].push(claimId);
        }

        claims[claimId].claimType = _claimType;
        claims[claimId].scheme = _scheme;
        claims[claimId].issuer = _issuer;
        claims[claimId].signature = _signature;
        claims[claimId].data = _data;
        claims[claimId].uri = _uri;

        emit ClaimAdded(
            claimId,
            _claimType,
            _scheme,
            _issuer,
            _signature,
            _data,
            _uri
        );

        return claimId;
    }

    function removeClaim(bytes32 _claimId) public override returns (bool success) {
        if (msg.sender != address(this)) {
          require(keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key");
        }

        /* uint index; */
        /* (index, ) = claimsByType[claims[_claimId].claimType].indexOf(_claimId);
        claimsByType[claims[_claimId].claimType].removeByIndex(index); */

        emit ClaimRemoved(
            _claimId,
            claims[_claimId].claimType,
            claims[_claimId].scheme,
            claims[_claimId].issuer,
            claims[_claimId].signature,
            claims[_claimId].data,
            claims[_claimId].uri
        );

        delete claims[_claimId];
        return true;
    }

    function getClaim(bytes32 _claimId)
        public
        override
        view
        returns(
            uint256 claimType,
            uint256 scheme,
            address issuer,
            bytes memory signature,
            bytes memory data,
            string memory uri
        )
    {
        return (
            claims[_claimId].claimType,
            claims[_claimId].scheme,
            claims[_claimId].issuer,
            claims[_claimId].signature,
            claims[_claimId].data,
            claims[_claimId].uri
        );
    }

    function getClaimIdsByType(uint256 _claimType)
        public
        override
        view
        returns(bytes32[] memory claimIds)
    {
        return claimsByType[_claimType];
    }

}


// File contracts/ClaimVerifier.sol

pragma solidity ^0.8.0;

contract ClaimVerifier {

  event ClaimValid(ClaimHolder _identity, uint256 claimType);
  event ClaimInvalid(ClaimHolder _identity, uint256 claimType);

  ClaimHolder public trustedClaimHolder;

  constructor(address _trustedClaimHolder) {
    trustedClaimHolder = ClaimHolder(_trustedClaimHolder);
  }

  function checkClaim(ClaimHolder _identity, uint256 claimType)
    public
    returns (bool claimValid)
  {
    if (claimIsValid(_identity, claimType)) {
      emit ClaimValid(_identity, claimType);
      return true;
    } else {
      emit ClaimInvalid(_identity, claimType);
      return false;
    }
  }

  function claimIsValid(ClaimHolder _identity, uint256 claimType)
    public
    view
    returns (bool claimValid)
  {
    uint256 foundClaimType;
    uint256 scheme;
    address issuer;
    bytes memory sig;
    bytes memory data;

    // Construct claimId (identifier + claim type)
    bytes32 claimId = keccak256(abi.encodePacked(trustedClaimHolder, claimType));

    // Fetch claim from user
    ( foundClaimType, scheme, issuer, sig, data, ) = _identity.getClaim(claimId);

    bytes32 dataHash = keccak256(abi.encodePacked(_identity, claimType, data));
    bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash));

    // Recover address of data signer
    address recovered = getRecoveredAddress(sig, prefixedHash);

    // Take hash of recovered address
    bytes32 hashedAddr = keccak256(abi.encodePacked(recovered));

    // Does the trusted identifier have they key which signed the user's claim?
    return trustedClaimHolder.keyHasPurpose(hashedAddr, 3);
  }

  function getRecoveredAddress(bytes memory sig, bytes32 dataHash)
      public
      pure
      returns (address addr)
  {
      bytes32 ra;
      bytes32 sa;
      uint8 va;

      // Check the signature length
      require(sig.length == 65, "Signature not valid!");

      // Divide the signature in r, s and v variables
      assembly {
        ra := mload(add(sig, 32))
        sa := mload(add(sig, 64))
        va := byte(0, mload(add(sig, 96)))
      }

      if (va < 27) {
        va += 27;
      }

      address recoveredAddress = ecrecover(dataHash, va, ra, sa);

      return (recoveredAddress);
  }
}