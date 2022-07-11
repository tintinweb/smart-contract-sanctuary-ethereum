// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase

pragma solidity 0.6.6;

interface IERC20 {
    function transfer(address, uint256) external;

    function balanceOf(address) external view returns (uint256);
}

contract RewardsMinter {
    IERC20 public immutable token;
    address public minter;
    address public admin;

    constructor(address _token) public {
        token = IERC20(_token);
        admin = msg.sender;
    }

    /**
     * @notice Sets the address of the minter contract
     * @dev can only be set once
     * @param _minter The address of the minter
     */
    function setMinter(address _minter) external {
        require(minter == address(0), "minter");
        require(_minter != address(0), "!_minter");
        minter = _minter;
    }

    /**
     * @notice Mints the given amount to the given account
     * @dev Requires this contract to be funded with the reward token
     * @param _account The address to receive the reward tokens
     * @param _amount The amount of tokens to send the receiver
     */
    function mint(address _account, uint256 _amount) external {
        require(msg.sender == minter, "!minter");
        token.transfer(_account, _amount);
    }

    /**
     * @notice Sets new admin for the contract
     * @param _admin The address of the new admin
     */
    function setAdmin(address _admin) external {
        require(_admin != address(0), "Zero address");
        require(msg.sender == admin, "!Permission");
        admin = _admin;
    }

    /**
     * @notice Admin transfers reward tokens out of this contract
     * @dev Watch for total pending rewards before calling this
     */
    function pullRewards() external {
        require(msg.sender == admin, "!Permission");
        token.transfer(admin, token.balanceOf(address(this)));
    }
}