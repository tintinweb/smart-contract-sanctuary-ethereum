// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;


import "./libraries/Configable.sol";

contract ConverterRegistry is Configable {

    struct ConverstionDetails {
        uint256 id;
        bytes data;
    }

    struct Converter {
        address proxy;
        bool isLib;
        bool isActive;
    }

    Converter[] public converters;

    constructor(address[] memory proxies, bool[] memory isLibs) {
        owner = msg.sender;
        for (uint256 i = 0; i < proxies.length; i++) {
            converters.push(Converter(proxies[i], isLibs[i], true));
        }
    }

    function addConverter(address proxy, bool isLib) external onlyDev {
        converters.push(Converter(proxy, isLib, true));
    }

    function setConverterStatus(uint256 id, bool newStatus) external onlyDev {
        Converter storage converter = converters[id];
        converter.isActive = newStatus;
    }

    function setConverterProxy(uint256 id, address newProxy, bool isLib) external onlyDev {
        Converter storage converter = converters[id];
        converter.proxy = newProxy;
        converter.isLib = isLib;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

interface IConfig {
    function dev() external view returns (address);
    function admin() external view returns (address);
    function team() external view returns (address);
}

contract Configable {
    address public config;
    address public owner;

    event ConfigChanged(address indexed _user, address indexed _old, address indexed _new);
    event OwnerChanged(address indexed _user, address indexed _old, address indexed _new);
 
    function setupConfig(address _config) external onlyOwner {
        emit ConfigChanged(msg.sender, config, _config);
        config = _config;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'OWNER FORBIDDEN');
        _;
    }

    function admin() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).admin();
        }
        return owner;
    }

    function dev() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).dev();
        }
        return owner;
    }

    function team() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).team();
        }
        return owner;
    }

    function changeOwner(address _user) external onlyOwner {
        require(owner != _user, 'Owner: NO CHANGE');
        emit OwnerChanged(msg.sender, owner, _user);
        owner = _user;
    }
    
    modifier onlyDev() {
        require(msg.sender == dev() || msg.sender == owner, 'dev FORBIDDEN');
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin() || msg.sender == owner, 'admin FORBIDDEN');
        _;
    }
  
    modifier onlyManager() {
        require(msg.sender == dev() || msg.sender == admin() || msg.sender == owner, 'manager FORBIDDEN');
        _;
    }
}