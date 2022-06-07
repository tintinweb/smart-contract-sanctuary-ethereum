//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Ambient {
    mapping(address => address) internal _pending;
    mapping(address => address) internal _hotToCold;

    mapping(address => address[]) internal _coldToAllHot;
    mapping(address => address[]) internal _coldToAllPending;
     
    fallback() external payable {}
    receive() external payable {}

    function createPendingPairWithHot ( address cold ) public {
        require( _pending[msg.sender] == address(0), "createPendingPair: Existing sender pending request." ); 
        require( _hotToCold[msg.sender] == address(0), "createPendingPair: Existing sender hotToCold link." ); 
        require( cold != msg.sender, "createPendingPair: Hot and Cold must be different." );
        _pending[msg.sender] = cold;
        _coldToAllPending[cold].push(msg.sender);
    }

    function confirmPairWithCold ( address hot ) public {
        require( _pending[hot] == msg.sender, "VerifyPair: Invalid pending pair." );
        deletePending(hot);
        _pending[hot] = address(0);

        _hotToCold[hot] = msg.sender;
        _coldToAllHot[msg.sender].push(hot);
    }

    function hotToPending ( address hot ) public view returns ( address ) {
        if ( _pending[hot] != address(0) ) {
            return _pending[hot];
        }
        return address(0);
    }

    function hotToCold ( address hot ) public view returns ( address ) {
        if ( _hotToCold[hot] != address(0)) {
            return _hotToCold[hot];
        }
        return hot;
    }

    function coldToHotArr ( address cold ) public view returns ( address[] memory ) {
        return _coldToAllHot[cold];
    }

    function coldToPendingArr ( address cold ) public view returns ( address[] memory ) {
        return _coldToAllPending[cold];
    }

    function deletePending ( address hot ) public {
        if (msg.sender == hot) {
            require( hotToPending(msg.sender) != address(0), "deletePending: No existing sender hotToPending link." );
            deleteConnectionPendingArr(_coldToAllPending[_pending[msg.sender]], msg.sender);
            _pending[msg.sender] = address(0);
        } else if (hotToPending(hot) == msg.sender) {
            deleteConnectionPendingArr(_coldToAllPending[msg.sender], hot);
            _pending[hot] = address(0);
        }
    }

    function deleteConnectionPendingArr ( address[] storage pendings, address toDelete ) internal {
        for (uint i; i < pendings.length; ++i) {
            if (pendings[i] == toDelete) {
                pendings[i] = pendings[pendings.length - 1];
                pendings.pop();
            }
        }
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