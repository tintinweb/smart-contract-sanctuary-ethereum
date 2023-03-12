/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * ERRORS
 */

/// @notice Unauthorized sender `sender`
/// @param sender Transaction sender
error Unauthorized(address sender);
/// @notice Invalid number of accounts `accountsLength`, must have at least 2
/// @param accountsLength Length of accounts array
error InvalidSplit__TooFewAccounts(uint256 accountsLength);
/// @notice Array lengths of accounts & percentAllocations don't match (`accountsLength` != `allocationsLength`)
/// @param accountsLength Length of accounts array
/// @param allocationsLength Length of percentAllocations array
error InvalidSplit__AccountsAndAllocationsMismatch(
  uint256 accountsLength,
  uint256 allocationsLength
);
/// @notice Invalid percentAllocations sum `allocationsSum` must equal `PERCENTAGE_SCALE`
/// @param allocationsSum Sum of percentAllocations array
error InvalidSplit__InvalidAllocationsSum(uint32 allocationsSum);
/// @notice Invalid accounts ordering at `index`
/// @param index Index of out-of-order account
error InvalidSplit__AccountsOutOfOrder(uint256 index);
/// @notice Invalid percentAllocation of zero at `index`
/// @param index Index of zero percentAllocation
error InvalidSplit__AllocationMustBePositive(uint256 index);
/// @notice Invalid distributorFee `distributorFee` cannot be greater than 10% (1e5)
/// @param distributorFee Invalid distributorFee amount
error InvalidSplit__InvalidDistributorFee(uint32 distributorFee);
/// @notice Invalid hash `hash` from split data (accounts, percentAllocations, distributorFee)
/// @param hash Invalid hash
error InvalidSplit__InvalidHash(bytes32 hash);
/// @notice Invalid new controlling address `newController` for mutable split
/// @param newController Invalid new controller
error InvalidNewController(address newController);


interface ISplit {
function getHash() external view returns (bytes32);
function getAccounts() external view returns (address payable[] memory);
function getPercentAllocations() external view returns (uint32[] memory);
function getDistributorFee() external view returns (uint32);
function getController() external view returns (address);
}

interface SplitWallet {
function sendETHToMain(uint256 amount) external;
}

contract SplitCheck {
address payable[] public splitAddresses;
mapping(address => bool) public isSplitAddress;
mapping(address => uint) public splitAddressCreationTimestamp;
mapping(bytes32 => bool) public isSplitHash;
mapping(address => uint256) public ethBalances;
bool public firstSplitAddressCreated;

struct Split {
bytes32 hash;
address controller;
}

mapping(address => Split) public splits;

event DistributeETH(address indexed split, uint256 amount, address indexed distributor);

uint256 constant PERCENTAGE_SCALE = 1e6;

function createSplit(ISplit split, address payable distributorAddress) external payable {
    address payable[] memory accounts = split.getAccounts();
    uint32[] memory percentAllocations = split.getPercentAllocations();
    uint32 distributorFee = split.getDistributorFee();
    bytes32 splitHash = split.getHash();
    address controller = split.getController();

    require(accounts.length == percentAllocations.length, "Array length mismatch");
    require(accounts.length > 0, "Empty array");
    require(msg.value > 0, "Zero value");

    // Convert accounts array to address array
    address[] memory accountsAddr = new address[](accounts.length);
    for (uint i = 0; i < accounts.length; i++) {
        accountsAddr[i] = accounts[i];
    }

    _validSplitHash(address(this), accountsAddr, percentAllocations, distributorFee);

    uint32 totalPercentAllocations = _getSum(percentAllocations);
    require(totalPercentAllocations == 100, "Percentages do not add up to 100");

    uint distributorAmount = (msg.value * distributorFee) / 100;
    uint amountPerAccount = (msg.value - distributorAmount) / accounts.length;
    for (uint i = 0; i < accounts.length; i++) {
        accounts[i].transfer(amountPerAccount);
        ethBalances[accounts[i]] += amountPerAccount;
    }
    payable(distributorAddress).transfer(distributorAmount);

    // Capture the creation timestamp of the first split address created
    if (!firstSplitAddressCreated && isSplitHash[splitHash]) {
        for (uint i = 0; i < accounts.length; i++) {
            addSplitAddress(accounts[i]);
        }
        firstSplitAddressCreated = true;
    }

    splits[address(this)] = Split({
        hash: splitHash,
        controller: controller
    });
}

function _getSum(uint32[] memory values) internal pure returns (uint32 sum) {
    for (uint i = 0; i < values.length; i++) {
        sum += values[i];
    }
}

function _hashSplit(
    address[] memory accounts,
    uint32[] memory percentAllocations,
    uint32 distributorFee
) internal pure returns (bytes32) {
    bytes32 hash = keccak256(abi.encode(accounts, percentAllocations, distributorFee));
    return hash;
}

function _validSplitHash(
address split,
address[] memory accounts,
uint32[] memory percentAllocations,
uint32 distributorFee
) internal view {
bytes32 hash = _hashSplit(accounts, percentAllocations, distributorFee);
if (splits[split].hash != hash) revert InvalidSplit__InvalidHash(hash);
}

function addSplitAddress(address payable _splitAddress) public {
require(!isSplitAddress[_splitAddress], "Address is already a split address");
splitAddresses.push(_splitAddress);
isSplitAddress[_splitAddress] = true;
splitAddressCreationTimestamp[_splitAddress] = block.timestamp;
}
}