/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
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

    event Create(address indexed beneficiary, Release indexed release);
    event Claim(address indexed beneficiary, uint256 indexed amt);
    event Modify(address indexed beneficiary, Release indexed release);

    //////////////////////////
    /////// Storage //////////
    //////////////////////////

    /// Mapping of release beneficiaries to releases
    mapping(address => Release) public s_releases;

    /// Owner of this contract
    address public s_owner;

    // The address of the token this contract releases
    address public immutable FUEL_TOKEN_ADDRESS;

    /// @notice The contract contructor. Sets the owner and release token
    /// @param tokenAddress :  The token this contract releases
    /// @param owner: The owner of the contract
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

    /// @notice Create a batch of new releases
    /// @param  beneficiaries : The addresss of the payee
    /// @param releases : The release structs
    /// @dev : createReleases cannot be used to overwrite existing releases (see `modify`)
    function createReleases(address[] memory beneficiaries, Release[] memory releases)
        public
        onlyOwner
    {
        require(beneficiaries.length == releases.length, "length-mismatch");
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < beneficiaries.length; i += 1) {
            require(s_releases[beneficiaries[i]].amount == 0, "no-batch-overwrite");
            require(releases[i].claimed == 0, "no-claimed-new-release");
            s_releases[beneficiaries[i]] = releases[i];
            totalAmount += releases[i].amount;
            emit Create(beneficiaries[i], releases[i]);
        }
        ERC20(FUEL_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), totalAmount);
    }

    /// @notice Modify an existing entity
    /// @param  beneficiary : The address of the entity
    /// @param release : The release struct
    /// @dev WARNING : This function will overwrite an existing entity without checks
    /// @dev WARNING : The owner is responsible for ensuring all releases are adequately funded
    function modifyRelease(address beneficiary, Release memory release) public onlyOwner {
        require(release.claimed <= release.amount, "no-overclaimed-release");
        s_releases[beneficiary] = release;
        emit Modify(beneficiary, release);
    }

    /// @notice Owner can withdraw tokens
    /// @param tokenAddress: The address of the token to withdraw.
    /// @param amt: The amount to withdraw
    /// @dev Contract should only hold `FUEL_TOKEN_ADDRESS` tokens, but we allow withdrawing any token for safety
    /// @dev WARNING : manually withdrawing tokens will leave the contract underfunded.
    function withdrawTokens(address tokenAddress, uint256 amt) public onlyOwner {
        ERC20(tokenAddress).transfer(msg.sender, amt);
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
        // Can only give to new address if that address has no active release
        require(s_releases[newBeneficiary].amount == 0, "not-new-beneficiary");
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