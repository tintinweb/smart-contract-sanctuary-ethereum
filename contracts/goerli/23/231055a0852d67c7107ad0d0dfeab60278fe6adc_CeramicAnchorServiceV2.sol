// SPDX-License-Identifier: GPL
pragma solidity ^0.8.13;

import "./Ownable.sol";


contract CeramicAnchorServiceV2 is Ownable {

    //the list of addresses
    mapping (address => bool) allowList;

    //when a service is added to allow list 
    event DidAddCas(address indexed _service);

    //when a service was removed from allow list
    event DidRemoveCas(address indexed _service);

    //upon successful anchor
    event DidAnchor(address indexed _service, bytes32 _root);

    // Only addresses in the allow list is allowed to anchor
    modifier onlyAllowed() {
        require(
            ( allowList[ msg.sender ] || msg.sender == owner() ), 
            "Allow List: caller is not allowed");
        _;
    }

    constructor(){}

    /*
        @name addCas
        @param address _service - the service to be added
        @desc add an address to the allow list
        @note Only owner can add to the allowlist
    */
    function addCas(address _service) public onlyOwner {
        allowList[_service] = true;
        emit DidAddCas(_service);
    }
        
    /*
        @name removeCas
        @param address _service - service to be removed
        @desc Removal can be performed by the owner or the service itself
    */
    function removeCas(address _service) public {
        // require((owner() == _msgSender()) || (allowList[_msgSender()].allowed && _msgSender() == _service), "Caller is not allowed or the owner");
        require((owner() == _msgSender()) || (allowList[_msgSender()] && _msgSender() == _service), "Caller is not allowed or the owner");
        delete allowList[_service];
        emit DidRemoveCas(_service);
    }

    /*
        @name isServiceAllowed
        @param address _service - address to check
        @desc check if a service/address is allowed
    */
    function isServiceAllowed(address _service) public view returns(bool) {
        return allowList[_service];
    }

    /* 
        @name anchor
        @param calldata _root
        @desc Here _root is a byte representation of Merkle root CID.
    */
    function anchorDagCbor(bytes32 _root) public onlyAllowed {
        emit DidAnchor(msg.sender, _root);
    }
    
}