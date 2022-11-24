// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IAddressBook } from "./interfaces/IAddressBook.sol";

contract AddressBook is IAddressBook {
    /**
     * The id of the last registered address.
     */
    uint40 private _lastId;

    /**
     * The address to id map.
     */
    mapping(address => uint40) private _id;

    /**
     * The id to address map.
     */
    mapping(uint40 => address) private _addr;

    function register() external returns (uint40) {
        if (_id[msg.sender] != 0) {
            revert AlreadyRegistered();
        }

        uint40 id_ = _lastId + 1;
        _lastId = id_;

        _id[msg.sender] = id_;
        _addr[id_] = msg.sender;

        emit Registered(msg.sender, id_);

        return id_;
    }

    function lastId() external view returns (uint40) {
        return _lastId;
    }

    function id(address addr_) external view returns (uint40) {
        return _id[addr_];
    }

    function addr(uint40 id_) external view returns (address) {
        return _addr[id_];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Contract that keeps an address book.
 *
 * The address book maps addresses to 32 bits ids so that they can be used to reference
 * an address using less data.
 */
interface IAddressBook {
    /**
     * Event emitted when an address is registered in the address book.
     *
     * @param addr  the address
     * @param id    the id
     */
    event Registered(address indexed addr, uint40 indexed id);

    /**
     * Error thrown when an address has already been registered.
     */
    error AlreadyRegistered();

    /**
     * Register the address of the caller in the address book.
     *
     * @return  the id
     */
    function register() external returns (uint40);

    /**
     * The id of the last registered address.
     *
     * @return  the id of the last registered address
     */
    function lastId() external view returns (uint40);

    /**
     * The id matching an address.
     *
     * @param  addr the address
     * @return      the id
     */
    function id(address addr) external view returns (uint40);

    /**
     * The address matching an id.
     *
     * @param  id   the id
     * @return      the address
     */
    function addr(uint40 id) external view returns (address);
}