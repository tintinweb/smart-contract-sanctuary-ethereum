// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITheopetraAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event ManagerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event SignerPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event ManagerPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);
    event SignerPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function manager() external view returns (address);

    function vault() external view returns (address);

    function whitelistSigner() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IYieldReporter {
    event ReportYield(uint256 indexed id, int256 yield);

    function lastYield() external view returns (int256);

    function currentYield() external view returns (int256);

    function getYieldById(uint256 id) external view returns (int256);

    function reportYield(int256 _amount) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "../Types/TheopetraAccessControlled.sol";
import "../Interfaces/IYieldReporter.sol";

/**
 * @title Theopetra Yield Reorter
 * @notice
 */

contract TheopetraYieldReporter is IYieldReporter, TheopetraAccessControlled {
    /* ======== STATE VARIABLES ======== */

    /**
     * @notice Theopetra reported yields by index
     */
    mapping(uint256 => int256) private yields;
    /**
     * @notice current yield ID
     */
    uint256 private currentIndex = 0;

    /* ======== CONSTANTS ======== */

    string private OUT_OF_BOUNDS = "OUT_OF_BOUNDS";

    /* ======== CONSTRUCTOR ======== */

    constructor(ITheopetraAuthority _authority) TheopetraAccessControlled(_authority) {
        // initialize yield 0 to 0
        yields[currentIndex] = 0;
    }

    /**
     * @notice return the number of decimals expect in the fixed point yield representation (9)
     * @return uint256  number of decimals (9)
     */
    function decimals() external pure returns (int256) {
        return 9;
    }

    /**
     * @notice returns the previous yield value or 0 if no previous yield
     * @return int256  previous yield value
     * @dev If there is only 1 yield reported, the current yield is returned
     */
    function lastYield() external view returns (int256) {
        if (currentIndex == 0) return 0;
        return currentIndex == 1 ? yields[1] : yields[currentIndex - 1];
    }

    /**
     * @notice returns the current index value
     * @return uint256  current index value
     */
    function getCurrentIndex() external view returns (uint256) {
        return currentIndex;
    }

    /**
     * @notice returns the current yield value
     * @return int256  current yield value
     */
    function currentYield() external view returns (int256) {
        // constructor and solidity defaults allow this to return 0 before
        // any yields are reported
        return yields[currentIndex];
    }

    /**
     * @notice returns the yield value for a given index
     * @param  _id  index of yield to return
     * @return int256  yield value
     * @dev reverts if id is out of bounds
     */
    function getYieldById(uint256 _id) external view returns (int256) {
        // don't allow requiring a yield past the current index
        require(_id <= currentIndex, OUT_OF_BOUNDS);
        return yields[_id];
    }

    /**
     * @notice reports a yield value
     * @param  _amount  yield value to report
     * @return uint256  index of the reported yield
     * @dev reverts if called by a non-policy address
     * @dev emits a ReportYield event
     */
    function reportYield(int256 _amount) external onlyPolicy returns (uint256) {
        yields[++currentIndex] = _amount;
        emit ReportYield(currentIndex, _amount);
        return currentIndex;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../Interfaces/ITheopetraAuthority.sol";

abstract contract TheopetraAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(ITheopetraAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    ITheopetraAuthority public authority;

    /* ========== Constructor ========== */

    constructor(ITheopetraAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == authority.manager(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(ITheopetraAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}