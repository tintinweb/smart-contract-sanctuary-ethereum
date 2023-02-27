// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error SplitFee__InvalidOwnerFeePercentage(uint8 ownerFeePercentage);
error SplitFee__ZeroAddressProhibited();

/**
 * @title Split Fee
 * @author DeployLabs.io
 *
 * @dev The purpose of this contract is to split the fee between the owner and the artist.
 */
contract SplitFee {
	address payable private i_owner;
	address payable private i_artist;

	uint8 private i_ownerFeePercentage;

	constructor(address payable owner, address payable artist, uint8 ownerFeePercentage) {
		if (owner == address(0) || artist == address(0)) revert SplitFee__ZeroAddressProhibited();
		i_owner = owner;
		i_artist = artist;

		if (ownerFeePercentage > 100) revert SplitFee__InvalidOwnerFeePercentage(ownerFeePercentage);
		i_ownerFeePercentage = ownerFeePercentage;
	}

	receive() external payable {
		uint256 ownerFee = (msg.value * i_ownerFeePercentage) / 100;
		uint256 artistFee = msg.value - ownerFee;

		i_owner.transfer(ownerFee);
		i_artist.transfer(artistFee);
	}
}