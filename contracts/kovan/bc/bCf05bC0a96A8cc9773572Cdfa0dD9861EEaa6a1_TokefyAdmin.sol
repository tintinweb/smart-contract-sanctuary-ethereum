//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./interfaces/ITokefyAdmin.sol";
import "./TokefyAdminModifier.sol";

contract TokefyAdmin is ITokefyAdmin, TokefyAdminModifier {
    address[] private _admins;

    constructor() TokefyAdminModifier(address(this)){
        _admins.push(msg.sender);
    }

    function grant(address admin) public onlyAdmin override returns (bool) {
        _admins.push(admin);
        return true;
    }

    function revoke(address admin) public onlyAdmin override returns (bool) {
        require(admin != msg.sender, "Admin cannot revoke itself");

        for (uint256 i = 0; i < _admins.length; i++) {
            if (_admins[i] == admin) {
                _admins[i] = address(0);
            }
        }

        return true;
    }

    function isAdmin(address admin) public view override returns (bool) {
        return exists(admin);
    }

    function getAdmins() public view override returns (address[] memory) {
        return _admins;
    }

    function exists(address admin) private view returns (bool) {
        for (uint256 i = 0; i < _admins.length; i++) {
            if (_admins[i] == admin) {
                return true;
            }
        }
        return false;
    }

    function push(address admin) private returns (bool) {
        bool inserted = false;
        for (uint256 i = 0; i < _admins.length; i++) {
            if (_admins[i] == address(0)) {
                _admins[i] = admin;
                inserted = true;
            }
        }
        if (!inserted) {
            _admins.push(admin);
        }

        return true;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;


interface ITokefyAdmin {

    function grant(address admin) external returns(bool);

    function revoke(address admin) external returns(bool);

    function isAdmin(address admin) external view returns(bool);

    function getAdmins() external view returns(address[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./interfaces/ITokefyAdmin.sol";

contract TokefyAdminModifier {
    address _tokefyAdminContractAddress;

    constructor(address adminContract){
        _tokefyAdminContractAddress = adminContract;
    }

    modifier onlyAdmin {
        ITokefyAdmin adminContract = ITokefyAdmin(_tokefyAdminContractAddress);
        require(adminContract.isAdmin(msg.sender), "Only admins are allowed to call this method.");
        _;
    }
}