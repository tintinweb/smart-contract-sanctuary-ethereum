// SPDX-License-Identifier: MIT

/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity ^0.8.0;

contract RouteConfigs {
    address public owner;
    address public governance;

    struct Dynamic {
        bool isExist;
        uint256 value;
    }

    mapping(string => uint256[]) public rules;
    mapping(string => uint256) public configs;
    mapping(address => mapping(string => Dynamic)) public dynamics;

    event SetOwner(address owner);
    event SetGovernance(address governance);
    event UpdateConfig(string key, uint256 oldValue, uint256 newValue);

    modifier onlyOwner() {
        require(owner == msg.sender, "DepegShieldConfig: caller is not the owner");
        _;
    }

    modifier onlyGovernance() {
        require(governance == msg.sender, "DepegShieldConfig: caller is not the governance");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
        governance = _owner;

        rules["MAX_OVERFLOW_BALANCE"] = [100, 200];
        rules["MAX_OVERFLOW_RATIO"] = [10, 100];

        _updateConfig("MAX_OVERFLOW_BALANCE", 120);
        _updateConfig("MAX_OVERFLOW_RATIO", 85);
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    function setGovernance(address _governance) public onlyOwner {
        governance = _governance;

        emit SetGovernance(_governance);
    }

    function updateRule(string memory _key, uint256[2] calldata _rules) public onlyGovernance {
        require(bytes(_key).length > 0, "!_key");
        require(_rules[0] != _rules[1], "!_rules");

        if (_rules[0] == 0 && _rules[1] == 0) {
            delete rules[_key];

            return;
        }

        rules[_key] = _rules;
    }

    function _updateConfig(string memory _key, uint256 _value) internal {
        emit UpdateConfig(_key, configs[_key], _value);

        delete configs[_key];

        configs[_key] = _value;
    }

    function updateConfig(string memory _key, uint256 _value) public onlyGovernance {
        require(bytes(_key).length > 0, "!_key");
        require(rules[_key].length > 0, "!Need to add rules first");

        if (rules[_key].length > 0) {
            require((_value >= rules[_key][0]) && (_value <= rules[_key][1]), "!value");
        }

        _updateConfig(_key, _value);
    }

    function updateDynamicConfig(
        address _target,
        string memory _key,
        uint256 _value
    ) public onlyGovernance {
        require(_target != address(0), "!_target");
        require(bytes(_key).length > 0, "!_key");
        require(rules[_key].length > 0, "!Need to add rules first");

        if (rules[_key].length > 0) {
            require((_value >= rules[_key][0]) && (_value <= rules[_key][1]), "!value");
        }

        dynamics[msg.sender][_key].isExist = true;
        dynamics[msg.sender][_key].value = _value;
    }

    function removeConfig(string memory _key) public onlyGovernance {
        require(bytes(_key).length > 0, "!_key");

        delete configs[_key];
        delete rules[_key];
    }

    function removeDynamicConfig(address _target, string memory _key) public onlyGovernance {
        require(_target != address(0), "!_target");
        require(bytes(_key).length > 0, "!_key");

        delete dynamics[msg.sender][_key];
    }

    function getConfig(string memory _key) external view returns (uint256) {
        if (dynamics[msg.sender][_key].isExist) return dynamics[msg.sender][_key].value;

        return configs[_key];
    }
}