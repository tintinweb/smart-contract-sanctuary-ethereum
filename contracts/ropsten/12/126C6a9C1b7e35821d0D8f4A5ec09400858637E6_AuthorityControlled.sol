// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

import "./IAuthority.sol";

contract AuthorityControlled {
    
    event AuthorityUpdated(address indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    IAuthority public authority;

    constructor(address _authority) {
        _setAuthority(_authority);
    }

    modifier onlyOwner() {
        require(msg.sender == authority.owner(), UNAUTHORIZED);
        _;
    }

    modifier onlyManager() {
        (bool isManager, uint256 idx) = authority.checkIsManager(msg.sender);
        require(isManager, UNAUTHORIZED);
        _;
    }

    function setAuthority(address _newAuthority) external onlyManager {
        _setAuthority(_newAuthority);
    }

    function _setAuthority(address _newAuthority) private {
        authority = IAuthority(_newAuthority);
        emit AuthorityUpdated(_newAuthority);
    }
}