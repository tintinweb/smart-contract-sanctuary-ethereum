//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract RoomTemp {
    mapping(address => address) internal _pending;
    mapping(address => address) internal _hotToCold;

    mapping(address => address[]) internal _coldToAllHot;
     
    fallback() external payable {}
    receive() external payable {}

    function createPendingPairWithHot ( address cold ) public {
        require( _pending[msg.sender] == address(0), "createPendingPair: Existing sender pending request." ); 
        require( _hotToCold[msg.sender] == address(0), "createPendingPair: Existing sender hotToCold link." ); 
        _pending[msg.sender] = cold;
    }

    function confirmPairWithCold ( address hot ) public {
        require( _pending[hot] == msg.sender, "VerifyPair: Invalid pending pair." );
        _hotToCold[hot] = msg.sender;
        _pending[hot] = address(0);

        _coldToAllHot[msg.sender].push(hot);
    }

    function hotToPending () public view returns ( address ) {
        if ( _pending[msg.sender] != address(0) ) {
            return _pending[msg.sender];
        }
        return address(0);
    }

    function hotToCold ( address hot ) public view returns ( address ) {
        if ( _hotToCold[hot] != address(0) ) {
            return _hotToCold[hot];
        }
        return hot;
    }

    function coldToHotArr ( address cold ) public view returns ( address[] memory ) {
        return _coldToAllHot[cold];
    }

    function deleteConnection ( address hot ) public {
        require( _hotToCold[hot] != address(0), "deleteConnection: No existing sender hotToCold link." );
        require( msg.sender == hot || msg.sender == _hotToCold[hot], "deleteConnection: Must be owner of either hot or cold wallet." );
        deleteConnectionHotArr(_coldToAllHot[_hotToCold[hot]], hot); 
        _hotToCold[hot] = address(0);
    }

    function deleteConnectionHotArr ( address[] storage hots, address toDelete ) internal {
        for (uint i; i < hots.length; ++i) {
            if (hots[i] == toDelete) {
                hots[i] = hots[hots.length - 1];
                hots.pop();
            }
        }
    }
}