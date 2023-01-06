/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: GPL-3.0
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

interface IERC20Mintable is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface ITokenAdmin {
    // solhint-disable func-name-mixedcase
    function INITIAL_RATE() external view returns (uint256);

    function RATE_REDUCTION_TIME() external view returns (uint256);

    function RATE_REDUCTION_COEFFICIENT() external view returns (uint256);

    function RATE_DENOMINATOR() external view returns (uint256);

    // solhint-enable func-name-mixedcase
    function getToken() external view returns (IERC20Mintable);

    function activate() external;

    function rate() external view returns (uint256);

    function startEpochTimeWrite() external returns (uint256);

    function mint(address to, uint256 amount) external;
}

// https://github.com/swervefi/swerve/edit/master/packages/swerve-contracts/interfaces/IGaugeController.sol

interface IGaugeController {
    struct Point {
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    // Public variables
    function admin() external view returns (address);

    function token() external view returns (address);

    function voting_escrow() external view returns (address);

    function n_gauge_types() external view returns (int128);

    function n_gauges() external view returns (int128);

    function gauge_type_names(int128) external view returns (string memory);

    function gauges(uint256) external view returns (address);

    function vote_user_slopes(address, address) external view returns (VotedSlope memory);

    function vote_user_power(address) external view returns (uint256);

    function last_user_vote(address, address) external view returns (uint256);

    function points_weight(address, uint256) external view returns (Point memory);

    function time_weight(address) external view returns (uint256);

    function points_sum(int128, uint256) external view returns (Point memory);

    function time_sum(uint256) external view returns (uint256);

    function points_total(uint256) external view returns (uint256);

    function time_total() external view returns (uint256);

    function points_type_weight(int128, uint256) external view returns (uint256);

    function time_type_weight(uint256) external view returns (uint256);

    // Getter functions
    function gauge_types(address) external view returns (int128);

    function gauge_relative_weight(address) external view returns (uint256);

    function gauge_relative_weight(address, uint256) external view returns (uint256);

    function get_gauge_weight(address) external view returns (uint256);

    function get_type_weight(int128) external view returns (uint256);

    function get_total_weight() external view returns (uint256);

    function get_weights_sum_per_type(int128) external view returns (uint256);

    // External functions
    function add_gauge(address, int128, uint256) external;

    function checkpoint() external;

    function checkpoint_gauge(address) external;

    function gauge_relative_weight_write(address) external returns (uint256);

    function gauge_relative_weight_write(address, uint256) external returns (uint256);

    function add_type(string memory, uint256) external;

    function change_type_weight(int128, uint256) external;

    function change_gauge_weight(address, uint256) external;

    function vote_for_gauge_weights(address, uint256) external;

    function change_pending_admin(address newPendingAdmin) external;

    function claim_admin() external;
}

interface IMinter {
    event Minted(address indexed recipient, address gauge, uint256 minted);

    /**
     * @notice Returns the address of the minted token
     */
    function getToken() external view returns (IERC20);

    /**
     * @notice Returns the address of the Token Admin contract
     */
    function getTokenAdmin() external view returns (ITokenAdmin);

    /**
     * @notice Returns the address of the Gauge Controller
     */
    function getGaugeController() external view returns (IGaugeController);

    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param gauge `LiquidityGauge` address to get mintable amount from
     */
    function mint(address gauge) external returns (uint256);

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @param gauges List of `LiquidityGauge` addresses
     */
    function mintMany(address[] calldata gauges) external returns (uint256);

    /**
     * @notice Mint tokens for `user`
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauge `LiquidityGauge` address to get mintable amount from
     * @param user Address to mint to
     */
    function mintFor(address gauge, address user) external returns (uint256);

    /**
     * @notice Mint tokens for `user` across multiple gauges
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauges List of `LiquidityGauge` addresses
     * @param user Address to mint to
     */
    function mintManyFor(address[] calldata gauges, address user) external returns (uint256);

    /**
     * @notice The total number of tokens minted for `user` from `gauge`
     */
    function minted(address user, address gauge) external view returns (uint256);

    /**
     * @notice Whether `minter` is approved to mint tokens for `user`
     */
    function getMinterApproval(address minter, address user) external view returns (bool);

    /**
     * @notice Set whether `minter` is approved to mint tokens on your behalf
     */
    function setMinterApproval(address minter, bool approval) external;

    // The below functions are near-duplicates of functions available above.
    // They are included for ABI compatibility with snake_casing as used in vyper contracts.
    // solhint-disable func-name-mixedcase

    /**
     * @notice Whether `minter` is approved to mint tokens for `user`
     */
    function allowed_to_mint_for(address minter, address user) external view returns (bool);

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @dev This function is not recommended as `mintMany()` is more flexible and gas efficient
     * @param gauges List of `LiquidityGauge` addresses
     */
    function mint_many(address[8] calldata gauges) external;

    /**
     * @notice Mint tokens for `user`
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauge `LiquidityGauge` address to get mintable amount from
     * @param user Address to mint to
     */
    function mint_for(address gauge, address user) external;

    /**
     * @notice Toggle whether `minter` is approved to mint tokens for `user`
     */
    function toggle_approve_mint(address minter) external;
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// For compatibility, we're keeping the same function names as in the original Curve code, including the mixed-case
// naming convention.
// solhint-disable func-name-mixedcase
// solhint-disable func-param-name-mixedcase

interface ILiquidityGauge {
    // solhint-disable-next-line var-name-mixedcase
    event RelativeWeightCapChanged(uint256 new_relative_weight_cap);

    /**
     * @notice Returns liquidity emissions calculated during checkpoints for the given user.
     * @param user User address.
     * @return uint256 token amount to issue for the address.
     */
    function integrate_fraction(address user) external view returns (uint256);

    /**
     * @notice Record a checkpoint for a given user.
     * @param user User address.
     * @return bool Always true.
     */
    function user_checkpoint(address user) external returns (bool);

    /**
     * @notice Returns true if gauge is killed; false otherwise.
     */
    function is_killed() external view returns (bool);

    /**
     * @notice Kills the gauge so it cannot mint tokens.
     */
    function killGauge() external;

    /**
     * @notice Unkills the gauge so it can mint tokens again.
     */
    function unkillGauge() external;

    /**
     * @notice Uses the Uniswap Poor oracle to decide whether a gauge is alive
     */
    function makeGaugePermissionless() external;

    /**
     * @notice Sets a new relative weight cap for the gauge.
     * The value shall be normalized to 1e18, and not greater than MAX_RELATIVE_WEIGHT_CAP.
     * @param relativeWeightCap New relative weight cap.
     */
    function setRelativeWeightCap(uint256 relativeWeightCap) external;

    /**
     * @notice Gets the relative weight cap for the gauge.
     */
    function getRelativeWeightCap() external view returns (uint256);

    /**
     * @notice Returns the gauge's relative weight for a given time, capped to its relative weight cap attribute.
     * @param time Timestamp in the past or present.
     */
    function getCappedRelativeWeight(uint256 time) external view returns (uint256);

    function initialize(
        address lpToken,
        uint256 relativeWeightCap,
        address votingEscrowDelegation,
        address admin,
        bytes32 positionKey
    ) external;

    function change_pending_admin(address newPendingAdmin) external;

    function claim_admin() external;

    function admin() external view returns (address);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function claim_rewards() external;
}

contract Minter is IMinter, ReentrancyGuard {
    IERC20 private immutable _token;
    ITokenAdmin private immutable _tokenAdmin;
    IGaugeController private immutable _gaugeController;

    // user -> gauge -> value
    mapping(address => mapping(address => uint256)) private _minted;
    // minter -> user -> can mint?
    mapping(address => mapping(address => bool)) private _allowedMinter;

    event MinterApprovalSet(address indexed user, address indexed minter, bool approval);

    constructor(ITokenAdmin tokenAdmin, IGaugeController gaugeController) {
        _token = tokenAdmin.getToken();
        _tokenAdmin = tokenAdmin;
        _gaugeController = gaugeController;
    }

    /**
     * @notice Returns the address of the minted token
     */
    function getToken() external view override returns (IERC20) {
        return _token;
    }

    /**
     * @notice Returns the address of the Token Admin contract
     */
    function getTokenAdmin() external view override returns (ITokenAdmin) {
        return _tokenAdmin;
    }

    /**
     * @notice Returns the address of the Gauge Controller
     */
    function getGaugeController() external view override returns (IGaugeController) {
        return _gaugeController;
    }

    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param gauge `LiquidityGauge` address to get mintable amount from
     */
    function mint(address gauge) external override nonReentrant returns (uint256) {
        return _mintFor(gauge, msg.sender);
    }

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @param gauges List of `LiquidityGauge` addresses
     */
    function mintMany(address[] calldata gauges) external override nonReentrant returns (uint256) {
        return _mintForMany(gauges, msg.sender);
    }

    /**
     * @notice Mint tokens for `user`
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauge `LiquidityGauge` address to get mintable amount from
     * @param user Address to mint to
     */
    function mintFor(address gauge, address user) external override nonReentrant returns (uint256) {
        require(_allowedMinter[msg.sender][user], "Caller not allowed to mint for user");
        return _mintFor(gauge, user);
    }

    /**
     * @notice Mint tokens for `user` across multiple gauges
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauges List of `LiquidityGauge` addresses
     * @param user Address to mint to
     */
    function mintManyFor(address[] calldata gauges, address user) external override nonReentrant returns (uint256) {
        require(_allowedMinter[msg.sender][user], "Caller not allowed to mint for user");
        return _mintForMany(gauges, user);
    }

    /**
     * @notice The total number of tokens minted for `user` from `gauge`
     */
    function minted(address user, address gauge) external view override returns (uint256) {
        return _minted[user][gauge];
    }

    /**
     * @notice Whether `minter` is approved to mint tokens for `user`
     */
    function getMinterApproval(address minter, address user) external view override returns (bool) {
        return _allowedMinter[minter][user];
    }

    /**
     * @notice Set whether `minter` is approved to mint tokens on your behalf
     */
    function setMinterApproval(address minter, bool approval) public override {
        _setMinterApproval(minter, msg.sender, approval);
    }

    function _setMinterApproval(address minter, address user, bool approval) private {
        _allowedMinter[minter][user] = approval;
        emit MinterApprovalSet(user, minter, approval);
    }

    // Internal functions

    function _mintFor(address gauge, address user) internal returns (uint256 tokensToMint) {
        tokensToMint = _updateGauge(gauge, user);
        if (tokensToMint > 0) {
            _tokenAdmin.mint(user, tokensToMint);
        }
    }

    function _mintForMany(address[] calldata gauges, address user) internal returns (uint256 tokensToMint) {
        uint256 length = gauges.length;
        for (uint256 i = 0; i < length;) {
            tokensToMint += _updateGauge(gauges[i], user);

            unchecked {
                ++i;
            }
        }

        if (tokensToMint > 0) {
            _tokenAdmin.mint(user, tokensToMint);
        }
    }

    function _updateGauge(address gauge, address user) internal returns (uint256 tokensToMint) {
        require(_gaugeController.gauge_types(gauge) >= 0, "Gauge does not exist on Controller");

        ILiquidityGauge(gauge).user_checkpoint(user);
        uint256 totalMint = ILiquidityGauge(gauge).integrate_fraction(user);
        tokensToMint = totalMint - _minted[user][gauge];

        if (tokensToMint > 0) {
            _minted[user][gauge] = totalMint;
            emit Minted(user, gauge, totalMint);
        }
    }

    // The below functions are near-duplicates of functions available above.
    // They are included for ABI compatibility with snake_casing as used in vyper contracts.
    // solhint-disable func-name-mixedcase

    /**
     * @notice Whether `minter` is approved to mint tokens for `user`
     */
    function allowed_to_mint_for(address minter, address user) external view override returns (bool) {
        return _allowedMinter[minter][user];
    }

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @dev This function is not recommended as `mintMany()` is more flexible and gas efficient
     * @param gauges List of `LiquidityGauge` addresses
     */
    function mint_many(address[8] calldata gauges) external override nonReentrant {
        for (uint256 i = 0; i < 8;) {
            if (gauges[i] == address(0)) {
                break;
            }
            _mintFor(gauges[i], msg.sender);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Mint tokens for `user`
     * @dev Only possible when `msg.sender` has been approved by `user` to mint on their behalf
     * @param gauge `LiquidityGauge` address to get mintable amount from
     * @param user Address to mint to
     */
    function mint_for(address gauge, address user) external override nonReentrant {
        if (_allowedMinter[msg.sender][user]) {
            _mintFor(gauge, user);
        }
    }

    /**
     * @notice Toggle whether `minter` is approved to mint tokens for `user`
     */
    function toggle_approve_mint(address minter) external override {
        setMinterApproval(minter, !_allowedMinter[minter][msg.sender]);
    }
}