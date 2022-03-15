// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Oracle {
    Request[] requests;
    uint currentId = 0;

    struct Request {
        uint id;                            // Request id
        string urlToQuery;                  // API url
        string attributeToFetch;            // Request params
        string agreedValue;                 // The result of the request
        uint headOffset;                    // The head offset for agreedValue
        uint tailOffset;                    // The tail offset for agreedValue
        address requesterAddress;           // Address that request the call
    }

    event NewRequest (
        uint id,
        string urlToQuery,
        string attributeToFetch,
        uint headOffset,
        uint tailOffset,
        address requesterAddress
    );

    event UpdatedRequest (
        uint id,
        string urlToQuery,
        string attributeToFetch,
        string agreedValue
    );

    function createRequest (
        string memory _urlToQuery,
        string memory _attributeToFetch,
        uint headOffset,
        uint tailOffset
    )
    public
    {
        requests.push(
            Request(
                currentId,
                _urlToQuery,
                _attributeToFetch,
                "",
                headOffset,
                tailOffset,
                address( msg.sender )
            )
        );

        emit NewRequest (
            currentId,
            _urlToQuery,
            _attributeToFetch,
            headOffset,
            tailOffset,
            address( msg.sender )
        );

        currentId++;
    }

    function updateRequest (
        uint _id,
        string memory _valueRetrieved
    ) public {

        Request storage request = requests[_id];
        request.agreedValue = _valueRetrieved;

        emit UpdatedRequest (
            request.id,
            request.urlToQuery,
            request.attributeToFetch,
            request.agreedValue
        );
    }

    function _getRequest ( uint _id ) public view returns (
        uint id,
        string memory urlToQuery,
        string memory attributeToFetch,
        string memory agreedValue,
        address requesterAddress
    ) {
        Request storage request = requests[_id];
        return (
            request.id,
            request.urlToQuery,
            request.attributeToFetch,
            request.agreedValue,
            request.requesterAddress
        );
    }

    function _getResult ( uint _requestId ) public view returns ( string memory agreedValue ) {
        return _substring(
            requests[_requestId].agreedValue,
            requests[_requestId].headOffset,
            requests[_requestId].tailOffset
        );
    }

    function _strLength( string memory s ) public pure returns ( uint256 ) {
        return bytes(s).length;
    }

    function _substring( string memory _base, uint _length, uint _offset  ) internal pure returns ( string memory ) {
        bytes memory _baseBytes = bytes(_base);

        require( uint(_offset + _length) <= _baseBytes.length,
            "The sum of _length and _offset should be less of _strLength( _base )");

        string memory _tmp = new string( uint(_length) );
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for ( uint i = uint(_offset); i < uint(_offset + _length); i++ ) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string( _tmpBytes );
    }

    function stringToUint( string memory _str ) public pure returns( uint256 res ) {

        for ( uint256 i = 0; i < bytes(_str).length; i++ ) {
            if (( uint8( bytes(_str)[i] ) - 48 ) < 0 || ( uint8( bytes(_str)[i] ) - 48 ) > 9) {
                return (0);
            }
            res += ( uint8( bytes(_str)[i] ) - 48 ) * 10**( bytes(_str).length - i - 1 );
        }

        return ( res );
    }

    function testOffset ( uint _id, uint headOffset, uint tailOffset ) public view returns ( string memory result ) {
        uint length = _strLength( requests[_id].agreedValue );
        result = _substring( requests[_id].agreedValue, uint(length - tailOffset - headOffset), headOffset );
        return result;
    }
}