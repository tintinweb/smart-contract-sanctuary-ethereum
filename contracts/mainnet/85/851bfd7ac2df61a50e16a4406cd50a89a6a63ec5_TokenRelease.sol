/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface ERC20 {
    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

contract TokenRelease {
    struct Release {
        uint48 start; // Start of release period  [timestamp]
        uint48 cliff; // The cliff date           [timestamp]
        uint48 end; // End of release period    [timestamp]
        uint256 amount; // Total release amount
        uint256 claimed; // Amount of release claimed
    }

    event Claim(address indexed beneficiary, uint256 indexed amt);

    //////////////////////////
    /////// Storage //////////
    //////////////////////////

    /// Mapping of release beneficiaries to releases
    mapping(address => Release) public s_releases;

    /// Owner of this contract
    address public s_owner;

    // The address of the token this contract releases
    address public immutable FUEL_TOKEN_ADDRESS;

    /// @notice The contract contructor
    /// @param tokenAddress :  The token this contract releases
    /// @dev Sets the owner
    constructor(address tokenAddress, address owner) {
        FUEL_TOKEN_ADDRESS = tokenAddress;
        s_owner = owner;
    }

    // Minimal SafeMath
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner, "sender-not-owner");
        _;
    }

    // --------------------------------- PERMISSIONED FUNCTIONS --------------------------------------

    /// @notice Create a new entity
    /// @param  beneficiary : The address of the payee
    /// @param release : The release struct
    /// @param overwrite : Boolean flag to set if intentionally overwriting a payee
    /// @dev Note that this function funds the contract with the total amount, so msg.sender must have done necessary approval before
    /// @dev WARNING : This function will overwrite an existing entity without checks if the overwrite flag is set
    function create(
        address beneficiary,
        Release memory release,
        bool overwrite
    ) public onlyOwner {
        require(s_releases[beneficiary].amount == 0 || overwrite, "Must use overwrite flag");
        s_releases[beneficiary] = release;
        ERC20(FUEL_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), release.amount);
    }

    /// @notice Owner can withdraw tokens
    /// @param amt: The amount to withdraw
    function withdrawTokens(uint256 amt) public onlyOwner {
        ERC20(FUEL_TOKEN_ADDRESS).transfer(msg.sender, amt);
    }

    /// @notice Transfer ownership of this contract
    /// @param newOwner: The new owner of the contract
    function transferOwnership(address newOwner) public onlyOwner {
        s_owner = newOwner;
    }

    // ------------------------------------------------------------------------------------------------

    /// @notice Change the beneficiary of a release
    /// @param newBeneficiary : The new beneficiary of the release
    /// @dev Only beneficiary can call
    function changeBeneficiary(address newBeneficiary) public {
        Release memory release = s_releases[msg.sender];
        delete s_releases[msg.sender];
        s_releases[newBeneficiary] = release;
    }

    ///@notice Claim tokens which are accrued but not yet claimed
    function claim() public {
        Release memory release = s_releases[msg.sender];
        uint256 amt =
            unpaidInternal(
                // solhint-disable-next-line not-rely-on-time
                block.timestamp,
                release.start,
                release.cliff,
                release.end,
                release.amount,
                release.claimed
            );
        s_releases[msg.sender].claimed = add(release.claimed, amt);
        ERC20(FUEL_TOKEN_ADDRESS).transfer(msg.sender, amt);
        emit Claim(msg.sender, amt);
    }

    ///@notice The total number of tokens accrued (paid and unpaid)
    ///@param beneficiary: The address of the beneficiary to check
    /// @return amt : The amount of tokens accrued
    function accrued(address beneficiary) public view returns (uint256 amt) {
        Release memory release = s_releases[beneficiary];
        // solhint-disable-next-line not-rely-on-time
        amt = accruedInternal(block.timestamp, release.start, release.end, release.amount);
    }

    ///@notice The number of accrued but unpaid tokens
    ///@param beneficiary: The address of the beneficiary to check
    /// @return amt : The amount of tokens unpaid
    function unpaid(address beneficiary) public view returns (uint256 amt) {
        Release memory release = s_releases[beneficiary];
        amt = unpaidInternal(
            // solhint-disable-next-line not-rely-on-time
            block.timestamp,
            release.start,
            release.cliff,
            release.end,
            release.amount,
            release.claimed
        );
    }

    /// @notice Calculates accrued tokens
    /// @param time: The timestamp up to which check unpaid tokens
    /// @param start : The start time of the release
    /// @param end : The end time of the release
    /// @param amount : The total amount of the release
    /// @return amt : The amount of tokens accrued
    function accruedInternal(
        uint256 time,
        uint48 start,
        uint48 end,
        uint256 amount
    ) internal pure returns (uint256 amt) {
        if (time < start) {
            amt = 0;
        } else if (time >= end) {
            amt = amount;
        } else {
            // accrued = total_amount * (time_so_far / total_time)
            amt = mul(amount, sub(time, start)) / sub(end, start);
        }
    }

    /// @notice Calculates unpaid tokens
    /// @param time: The timestamp up to which check unpaid tokens
    /// @param start : The start time of the release
    /// @param cliff : The cliff time of the release
    /// @param end : The end time of the release
    /// @param amount : The total amount of the release
    /// @param claimed: The amount of the release already claimed
    /// @return amt : The amount of tokens unpaid
    function unpaidInternal(
        uint256 time,
        uint48 start,
        uint48 cliff,
        uint48 end,
        uint256 amount,
        uint256 claimed
    ) internal pure returns (uint256 amt) {
        amt = time < cliff ? 0 : sub(accruedInternal(time, start, end, amount), claimed);
    }
}