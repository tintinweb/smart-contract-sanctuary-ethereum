pragma solidity 0.8.12;

/**
 * @title Ownership
 * @author @InsureDAO
 * @notice Ownership management contract
 * SPDX-License-Identifier: GPL-3.0
 */

import "./interfaces/IOwnership.sol";

contract Ownership is IOwnership {
    address private _owner;
    address private _futureOwner;

    event CommitNewOwnership(address indexed futureOwner);
    event AcceptNewOwnership(address indexed owner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit AcceptNewOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    function futureOwner() external view returns (address) {
        return _futureOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not allowed to operate");
        _;
    }

    modifier onlyFutureOwner() {
        require(_futureOwner == msg.sender, "Caller is not allowed to operate");
        _;
    }

    function commitTransferOwnership(address newOwner) external onlyOwner {
        /***
         *@notice Transfer ownership of GaugeController to `newOwner`
         *@param newOwner Address to have ownership transferred to
         */
        _futureOwner = newOwner;
        emit CommitNewOwnership(newOwner);
    }

    function acceptTransferOwnership() external onlyFutureOwner {
        /***
         *@notice Accept a transfer of ownership
         */
        _owner = msg.sender;
        _futureOwner = address(0);
        emit AcceptNewOwnership(msg.sender);
    }
}

pragma solidity 0.8.12;

//SPDX-License-Identifier: MIT

interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
}