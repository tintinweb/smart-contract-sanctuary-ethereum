pragma solidity 0.8.12;

/**
 * @title Registry
 * @author @InsureDAO
 * @notice Pool Registry
 * SPDX-License-Identifier: GPL-3.0
 */

import "./interfaces/IOwnership.sol";
import "./interfaces/IRegistry.sol";

contract Registry is IRegistry {
    event ExistenceSet(address indexed template, address indexed target);
    event NewMarketRegistered(address market);
    event FactorySet(address factory);
    event ReserveSet(address indexed target, address reserve);

    address public factory;

    mapping(address => address) reserve; //index => reserve
    mapping(address => bool) pools; //true if the pool is registered
    mapping(address => mapping(address => bool)) existence; //true if the certain id is already registered in market
    address[] poolList;

    IOwnership public immutable ownership;

    modifier onlyOwner() {
        require(ownership.owner() == msg.sender, "Caller is not allowed to operate");
        _;
    }

    constructor(address _ownership) {
        require(_ownership != address(0), "ERROR: ZERO_ADDRESS");
        ownership = IOwnership(_ownership);
    }

    /**
     * @notice Set the factory address and allow it to regiser a new market
     * @param _factory factory address
     */
    function setFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "ERROR: ZERO_ADDRESS");

        factory = _factory;
        emit FactorySet(_factory);
    }

    /**
     * @notice Register a new market.
     * @param _pool pool address to register
     */
    function addPool(address _pool) external {
        require(!pools[_pool], "ERROR: ALREADY_REGISTERED");
        require(msg.sender == factory || msg.sender == ownership.owner(), "ERROR: UNAUTHORIZED_CALLER");
        require(_pool != address(0), "ERROR: ZERO_ADDRESS");

        poolList.push(_pool);
        pools[_pool] = true;
        emit NewMarketRegistered(_pool);
    }

    /**
     * @notice Register a new target address id and template address set.
     * @param _template template address
     * @param _target target address
     */
    function setExistence(address _template, address _target) external {
        require(msg.sender == factory || msg.sender == ownership.owner(), "ERROR: UNAUTHORIZED_CALLER");

        existence[_template][_target] = true;
        emit ExistenceSet(_template, _target);
    }

    /**
     * @notice Register the reserve address for a particular address
     * @param _address address to set Reserve
     * @param _reserve Reserve contract address
     */
    function setReserve(address _address, address _reserve) external onlyOwner {
        require(_reserve != address(0), "ERROR: ZERO_ADDRESS");

        reserve[_address] = _reserve;
        emit ReserveSet(_address, _reserve);
    }

    /**
     * @notice Get the reserve address for a particular address
     * @param _address address covered by Reserve
     * @return Reserve contract address
     */
    function getReserve(address _address) external view returns (address) {
        address _addr = reserve[_address];
        if (_addr == address(0)) {
            return reserve[address(0)];
        } else {
            return _addr;
        }
    }

    /**
     * @notice Get whether the target address and id set exists
     * @param _template template address
     * @param _target target address
     * @return true if the id within the market already exists
     */
    function confirmExistence(address _template, address _target) external view returns (bool) {
        return existence[_template][_target];
    }

    /**
     * @notice Get whether market is registered
     * @param _market market address to inquire
     * @return true if listed
     */
    function isListed(address _market) external view returns (bool) {
        return pools[_market];
    }

    /**
     * @notice Get all market
     * @return all pools
     */
    function getAllPools() external view returns (address[] memory) {
        return poolList;
    }
}

pragma solidity 0.8.12;

interface IRegistry {
    function isListed(address _market) external view returns (bool);

    function getReserve(address _address) external view returns (address);

    function confirmExistence(address _template, address _target) external view returns (bool);

    //onlyOwner
    function setFactory(address _factory) external;

    function addPool(address _market) external;

    function setExistence(address _template, address _target) external;

    function setReserve(address _address, address _reserve) external;
}

pragma solidity 0.8.12;

//SPDX-License-Identifier: MIT

interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
}