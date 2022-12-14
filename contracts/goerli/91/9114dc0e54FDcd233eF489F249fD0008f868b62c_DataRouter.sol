// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import './interfaces/IProfileContract.sol';
import './interfaces/IMaster.sol';

contract DataRouter {

    IMaster public immutable master;

    constructor(address _master) {
        master = IMaster(_master);
    }

    struct FloatUint {
        uint240 value;
        uint16 decimal;
    }

    struct FloatInt {
        int240 value;
        uint16 decimal;
    }

    function setUint(address _profile, bytes32 _nameId, uint _value) external {
        bytes32 data = bytes32(abi.encode(_value));
        _setBytes32(_profile, _nameId, data);
    }

    function setInt(address _profile, bytes32 _nameId, int _value) external {
        bytes32 data = bytes32(abi.encode(_value));
        _setBytes32(_profile, _nameId, data);
    }

    function setFloatUint(address _profile, bytes32 _nameId, FloatUint memory _object) external {
        bytes32 data = bytes32(abi.encodePacked(_object.value, _object.decimal));
        _setBytes32(_profile, _nameId, data);
    }

    function setFloatInt(address _profile, bytes32 _nameId, FloatInt memory _object) external {
        bytes32 data = bytes32(abi.encodePacked(_object.value, _object.decimal));
        _setBytes32(_profile, _nameId, data);
    }

    function setAddress(address _profile, bytes32 _nameId, address _value) external {
        bytes32 data = bytes32(abi.encode(_value));
        _setBytes32(_profile, _nameId, data);
    }

    function setBool(address _profile, bytes32 _nameId, bool _value) external {
        bytes32 data = bytes32(abi.encode(_value));
        _setBytes32(_profile, _nameId, data);
    }

    function setString(address _profile, bytes32 _nameId, string memory _value) external {
        _setString(_profile, _nameId, _value);
    }

    function getTypeMetricByName(string memory _name) external view returns(IMaster.TypeMetric) {
        bytes32 nameId = _stringToHash(_name);
        return master.getTypeMetricByNameId(nameId);
    }

    function getUint(address _profile, string memory _name) external view returns(uint value) {
        bytes32 data = _getBytes32(_profile, _stringToHash(_name));
        assembly {
            let fmp:= mload(0x40)
            mstore(fmp, data)
            value := mload(fmp)
        }
    }

    function getInt(address _profile, string memory _name) external view returns(int value) {
        bytes32 data = _getBytes32(_profile, _stringToHash(_name));
        assembly {
            let fmp:= mload(0x40)
            mstore(fmp, data)
            value := mload(fmp)
        }
    }

    function getFloatUint(address _profile, string memory _name) external view returns(FloatUint memory object) {
        bytes32 data = _getBytes32(_profile, _stringToHash(_name));
        uint240 value; 
        uint16 decimal;
        assembly {
            let fmp:= mload(0x40)
            mstore(fmp, 0x00)
            mstore(add(fmp, 0x20), data)
            value := mload(add(fmp, 0x01e))
            mstore(add(fmp, 0x01e), 0x00)
            decimal := mload(add(fmp, 0x20))
        }
        object.value = value;
        object.decimal = decimal;
    }

    function getFloatInt(address _profile, string memory _name) external view returns(FloatInt memory object) {
        bytes32 data = _getBytes32(_profile, _stringToHash(_name));
        int240 value; 
        uint16 decimal;
        assembly {
            let fmp:= mload(0x40)
            mstore(fmp, 0x00)
            mstore(add(fmp, 0x20), data)
            value := mload(add(fmp, 0x01e))
            mstore(add(fmp, 0x01e), 0x00)
            decimal := mload(add(fmp, 0x20))
        }
        object.value = value;
        object.decimal = decimal;
    }

    function getAddress(address _profile, string memory _name) external view returns(address value) {
        bytes32 data = _getBytes32(_profile, _stringToHash(_name));
        assembly {
            let fmp:= mload(0x40)
            mstore(fmp, data)
            value := mload(fmp)
        }
    }

    function getBool(address _profile, string memory _name) external view returns(bool value) {
        bytes32 data = _getBytes32(_profile, _stringToHash(_name));
        assembly {
            let fmp:= mload(0x40)
            mstore(fmp, data)
            value := mload(fmp)
        }
    }

    function getString(address _profile, string memory _name) external view returns(string memory value) {
        value = _getString(_profile, _stringToHash(_name));
    }
     
    function _setBytes32(address _profile, bytes32 _nameId, bytes32 _data) internal {
        IProfileContract(_profile).setBytes32(_nameId, _data);
    }

    function _setString(address _profile, bytes32 _nameId, string memory _data) internal {
        IProfileContract(_profile).setString(_nameId, _data);
    }

    function _getBytes32(address _profile, bytes32 _nameId) internal view returns(bytes32) {
        return IProfileContract(_profile).getBytes32(_nameId);
    }

    function _getString(address _profile, bytes32 _nameId) internal view returns(string memory) {
        return IProfileContract(_profile).getString(_nameId);
    }

    function _stringToHash(string memory _parameter) internal pure returns(bytes32 _hash) {
        _hash = keccak256(abi.encodePacked(_parameter));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IMaster {
    enum TypeOracle {
        Metric,
        KYC
    }

    enum TypeMetric {
        Unknown,
        Uint, 
        Int, 
        FloatUint, 
        FloatInt, 
        Address,
        Bool,
        String,
        KYC
    }

    struct OracleProposal {
        bytes32 votingId;
        string[] names;
        TypeMetric[] metricTypes;
        string description;
        address oracle;
        uint endTime;
        uint support;
        TypeOracle character;
    }

    struct MemberProposal {
        bytes32 votingId;
        address member;
        uint endTime;
        uint support;
    }

    function becomeOracle(string[] calldata _names, TypeMetric[] calldata _typeMetric, string calldata _description, TypeOracle _type) external; 

    function voteForOracle(uint _id) external;
    
    function finishOracleVoiting(uint _id) external;

    function becomeMember() external;

    function voteForMember(uint _id) external;

    function finishMemberVoiting(uint _id) external;

    function setProposalDuration(uint _duration) external;

    function removeOracle(address _oracle, bytes32 _id, bool _isOracleKYC) external;

    function removeCommunityMember(address _member) external;

    function getTypeMetricByNameId(bytes32 _nameId) external view returns(TypeMetric);

    function getNamesByProposalId(uint _id) external view returns(string[] memory);

    function getIsOracleToNameId(address _oracle, bytes32 _id) external view returns(bool);

    function getIsOracleKYC(address _oracle) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IProfileContract {

    function fullName() external view returns(string memory);

    function addressWallet() external view returns(address);

    function transferProfileOwnership(address _newAddress) external;

    function acceptProfileOwnership() external;

    function cancelTransferProfileOwnership() external returns(address newAddressWallet);

    function deleteProfile() external;

    function approveKYC(string memory _name) external;

    function registerNameIds(string[] memory _names) external;

    function setBytes32(bytes32 _id, bytes32 _data) external;

    function setString(bytes32 _id, string memory _data) external;

    function getBytes32(bytes32 _id) external view returns(bytes32);

    function getString(bytes32 _id) external view returns(string memory);

    function getLengthMetricNames() external view returns(uint);

    function getSliceMetricNames(uint _start, uint _end) external view returns(string[] memory slice);

    function getLengthConfirmations() external view returns(uint);

    function getSliceConfirmations(uint _start, uint _end) external view returns(string[] memory slice);
}