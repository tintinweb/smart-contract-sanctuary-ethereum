// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

contract Config {
    address public owner;
    address public dev;
    address public admin;
    address public team;

    event OwnerChanged(address indexed _user, address indexed _old, address indexed _new);
    event DevChanged(address indexed _user, address indexed _old, address indexed _new);
    event AdminChanged(address indexed _user, address indexed _old, address indexed _new);
    event TeamChanged(address indexed _user, address indexed _old, address indexed _new);

    constructor() {
        owner = msg.sender;
        dev = msg.sender;
        admin = msg.sender;
        team = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Config: Only Owner');
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner, "Config: FORBIDDEN");
        _;
    }
    
    modifier onlyDev() {
        require(msg.sender == dev || msg.sender == owner, "Config: FORBIDDEN");
        _;
    }

    function changeOwner(address _user) external onlyOwner {
        require(owner != _user, 'Config: NO CHANGE');
        emit OwnerChanged(msg.sender, owner, _user);
        owner = _user;
    }

    function changeDev(address _user) external onlyDev {
        require(dev != _user, 'Config: NO CHANGE');
        emit DevChanged(msg.sender, dev, _user);
        dev = _user;
    }

    function changeAdmin(address _user) external onlyAdmin {
        require(admin != _user, 'Config: NO CHANGE');
        emit AdminChanged(msg.sender, admin, _user);
        admin = _user;
    }

    function changeTeam(address _user) external onlyAdmin {
        require(team != _user, 'Config: NO CHANGE');
        emit TeamChanged(msg.sender, admin, _user);
        team = _user;
    }
}