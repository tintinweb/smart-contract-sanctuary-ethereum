// SPDX-License-Identifier: LGPL-3.0
pragma solidity =0.8.10;

import "./Ownable.sol";

contract CommunityAcknowledgement is Ownable {

	/// @notice Recognised Community Contributor Acknowledgement Rate
	/// @dev Id is keccak256 hash of contributor address
	mapping (bytes32 => uint16) public rccar;

	/// @notice Emit when owner recognises contributor
	/// @param contributor Keccak256 hash of recognised contributor address
	/// @param previousAcknowledgementRate Previous contributor acknowledgement rate
	/// @param newAcknowledgementRate New contributor acknowledgement rate
	event ContributorRecognised(bytes32 indexed contributor, uint16 indexed previousAcknowledgementRate, uint16 indexed newAcknowledgementRate);

	/* solhint-disable-next-line no-empty-blocks */
	constructor(address _adoptionDAOAddress) Ownable(_adoptionDAOAddress) {

	}

	/// @notice Getter for Recognised Community Contributor Acknowledgement Rate
	/// @param _contributor Keccak256 hash of contributor address
	/// @return Acknowledgement Rate
	function getAcknowledgementRate(bytes32 _contributor) external view returns (uint16) {
		return rccar[_contributor];
	}

	/// @notice Getter for Recognised Community Contributor Acknowledgement Rate for msg.sender
	/// @return Acknowledgement Rate
	function senderAcknowledgementRate() external view returns (uint16) {
		return rccar[keccak256(abi.encodePacked(msg.sender))];
	}

	/// @notice Recognise community contributor and set its acknowledgement rate
	/// @dev Only owner can recognise contributor
	/// @dev Emits `ContributorRecognised` event
	/// @param _contributor Keccak256 hash of recognised contributor address
	/// @param _acknowledgementRate Contributor new acknowledgement rate
	function recogniseContributor(bytes32 _contributor, uint16 _acknowledgementRate) public onlyOwner {
		uint16 _previousAcknowledgementRate = rccar[_contributor];
		rccar[_contributor] = _acknowledgementRate;
		emit ContributorRecognised(_contributor, _previousAcknowledgementRate, _acknowledgementRate);
	}

	/// @notice Recognise list of contributors
	/// @dev Only owner can recognise contributors
	/// @dev Emits `ContributorRecognised` event for every contributor
	/// @param _contributors List of keccak256 hash of recognised contributor addresses
	/// @param _acknowledgementRates List of contributors new acknowledgement rates
	function batchRecogniseContributor(bytes32[] calldata _contributors, uint16[] calldata _acknowledgementRates) external onlyOwner {
		require(_contributors.length == _acknowledgementRates.length, "Lists do not match in length");

		for (uint256 i = 0; i < _contributors.length; i++) {
			recogniseContributor(_contributors[i], _acknowledgementRates[i]);
		}
	}

}

// SPDX-License-Identifier: MIT
// Adapted from OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)
// Using less gas and initiating the first owner to the provided multisig address

pragma solidity ^0.8.10;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one provided during the deployment of the contract. 
 * This can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {

    /**
     * @dev Address of the current owner. 
     */
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @param _firstOwner Initial owner
     * @dev Initializes the contract setting the initial owner.
     */
    constructor(address _firstOwner) {
        _transferOwnership(_firstOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(_newOwner != address(0), "Ownable: cannot be zero address");
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address _newOwner) internal virtual {
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}