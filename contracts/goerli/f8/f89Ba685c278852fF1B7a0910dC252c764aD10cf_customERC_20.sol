// SPDX-License-Identifier: MIT

// Version
pragma solidity ^0.8.4;

import "./ERC_20_Roles.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Context.sol";
import "./AccessControl.sol";
import "./Blacklist.sol";

contract customERC_20 is Ownable, Blacklist, ERC20, Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant TIMELOCKER_ROLE = keccak256("TIMELOCKER_ROLE");

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) ERC20(_name, _symbol){
        address _newOwner = 0x68905da737e5a11E3A93AB6CeC2eA8b145fce961;
        uint256 _cap = 1111111111 *(uint256(10) ** 18);
        _capped(_cap);
        _mint(_msgSender(), _totalSupply * (uint256(10) ** 18));
        _transferOwnership(_newOwner);
        _transfer(_msgSender(), _newOwner, _totalSupply * (uint256(10) ** 18));

        _setupRole(DEFAULT_ADMIN_ROLE, _newOwner);

        _setupRole(MINTER_ROLE, _newOwner);
        _setupRole(PAUSER_ROLE, _newOwner);
        _setupRole(BLACKLISTER_ROLE, _newOwner);
        _setupRole(BURNER_ROLE, _newOwner);
        _setupRole(TIMELOCKER_ROLE, _newOwner);
    }

    function mint(uint256 _amount) public{
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC20: must have minter role to mint"
        );
        _mint(_msgSender(), _amount);
    }

    function burn(uint256 _amount) public {
        require(
            hasRole(BURNER_ROLE, _msgSender()),
            "ERC20: must have burner role to burn"
        );
        _burn(_msgSender(), _amount);
    }

    function pause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC20: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC20: must have pauser role to unpause"
        );
        _unpause();
    }

    function blacklistAddress(address account) public {
        require(
            hasRole(BLACKLISTER_ROLE, _msgSender()),
            "ERC20: must have blacklister role to blacklist"
        );
        _blacklistAddress(account);
    }

    function unBlacklistAddress(address account) public {
        require(
            hasRole(BLACKLISTER_ROLE, _msgSender()),
            "ERC20: must have blacklister role to unblacklist"
        );
        _unBlacklistAddress(account);
    }

    function timeLock(address _account, uint _time) public{
        require(
            hasRole(TIMELOCKER_ROLE, _msgSender()),
            "ERC20: must have timelocker role to timelock"
        );
        _timeLock(_account, _time);
    }

    function transferOwnership(address _newOwner) public override onlyOwner{
        _transferOwnership(_newOwner);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}