// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

import "./interfaces/IPixelMushrohmAuthority.sol";
import "./types/PixelMushrohmAccessControlled.sol";

contract PixelMushrohmAuthority is IPixelMushrohmAuthority, PixelMushrohmAccessControlled {
    /* ========== STATE VARIABLES ========== */

    address public override owner;

    address public override policy;

    address public override vault;

    bool public override paused;

    address public newOwner;

    address public newPolicy;

    address public newVault;

    /* ========== Constructor ========== */

    constructor(
        address _owner,
        address _policy,
        address _vault
    ) PixelMushrohmAccessControlled(IPixelMushrohmAuthority(address(this))) {
        owner = _owner;
        emit OwnerPushed(address(0), owner, true);
        policy = _policy;
        emit PolicyPushed(address(0), policy, true);
        vault = _vault;
        emit VaultPushed(address(0), vault, true);
        _pause();
    }

    /* ========== OWNER ONLY ========== */

    function pushOwner(address _newOwner, bool _effectiveImmediately) external onlyOwner {
        if (_effectiveImmediately) owner = _newOwner;
        newOwner = _newOwner;
        emit OwnerPushed(owner, newOwner, _effectiveImmediately);
    }

    function pushPolicy(address _newPolicy, bool _effectiveImmediately) external onlyOwner {
        if (_effectiveImmediately) policy = _newPolicy;
        newPolicy = _newPolicy;
        emit PolicyPushed(policy, newPolicy, _effectiveImmediately);
    }

    function pushVault(address _newVault, bool _effectiveImmediately) external onlyOwner {
        if (_effectiveImmediately) vault = _newVault;
        newVault = _newVault;
        emit VaultPushed(vault, newVault, _effectiveImmediately);
    }

    function togglePause() external onlyOwner {
        if (paused) {
            _unpause();
        } else {
            _pause();
        }
    }

    /* ========== PENDING ROLE ONLY ========== */

    function pullOwner() external {
        require(msg.sender == newOwner, "!newOwner");
        emit OwnerPulled(owner, newOwner);
        owner = newOwner;
    }

    function pullPolicy() external {
        require(msg.sender == newPolicy, "!newPolicy");
        emit PolicyPulled(policy, newPolicy);
        policy = newPolicy;
    }

    function pullVault() external {
        require(msg.sender == newVault, "!newVault");
        emit VaultPulled(vault, newVault);
        vault = newVault;
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _pause() internal {
        paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal {
        paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

interface IPixelMushrohmAuthority {
    /* ========== EVENTS ========== */

    event OwnerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event OwnerPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    event Paused(address by);
    event Unpaused(address by);

    /* ========== VIEW ========== */

    function owner() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

import "../interfaces/IPixelMushrohmAuthority.sol";

abstract contract PixelMushrohmAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IPixelMushrohmAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas
    string PAUSED = "PAUSED";
    string UNPAUSED = "UNPAUSED";

    /* ========== STATE VARIABLES ========== */

    IPixelMushrohmAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IPixelMushrohmAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOwner() {
        require(msg.sender == authority.owner(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    modifier whenNotPaused() {
        require(!authority.paused(), PAUSED);
        _;
    }

    modifier whenPaused() {
        require(authority.paused(), UNPAUSED);
        _;
    }

    /* ========== OWNER ONLY ========== */

    function setAuthority(IPixelMushrohmAuthority _newAuthority) external onlyOwner {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}