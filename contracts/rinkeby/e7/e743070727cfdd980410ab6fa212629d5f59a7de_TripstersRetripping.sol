/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
    constructor() {
        _transferOwnership(msg.sender);
    }
	
    function owner() public view virtual returns (address) {
        return _owner;
    }
	
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
	
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
	
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
	
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
	
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract baggie {
    function ownerOfToken(uint256 tokenId) public view virtual returns (address);
	function safeTransferFrom(address from, address to, uint256 tokenId) external virtual;
}

abstract contract triproom {
    function ownerOfToken(uint256 tokenId) public view virtual returns (address);
}

contract TripstersRetripping is Ownable, ReentrancyGuard {
    bool public mintEnable;
	
	baggie public immutable Baggie = baggie(0x838E22EBfbEBCa7301feAe22ea18fB6a9c275917);
	triproom public immutable TripRoom = triproom(0x8b01Bb00063717b8bC691C6A63E904078039F47d);
	address public immutable DEAD = address(0x000000000000000000000000000000000000dEaD);
	
    uint256[2][] public upgradeL2;
	uint256[2][] public upgradeL3;
	
	mapping (uint256 => bool) public isUpgradedToL2;
	mapping (uint256 => bool) public isUpgradedToL3;
	
	function upgradeNFTToL2(uint256 baggieID, uint256 triproomID) public nonReentrant{
		require(
			mintEnable, 
			"TripstersRetripping: Mint is not enable"
		);
		require(
			!isUpgradedToL2[triproomID], 
			"TripstersRetripping: TripRoom NFT already upgraded to L2"
		);
		require(
            Baggie.ownerOfToken(baggieID) == msg.sender,
            "TripstersRetripping: Incorrect owner"
        );
		require(
            TripRoom.ownerOfToken(triproomID) == msg.sender,
            "TripstersRetripping: Incorrect owner"
        );
		
		isUpgradedToL2[triproomID] = true;
		upgradeL2.push([baggieID,triproomID]);
		Baggie.safeTransferFrom(msg.sender, DEAD, baggieID);
    }
	
	function upgradeNFTToL3(uint256 baggieID, uint256 triproomID) public nonReentrant{
		require(
			mintEnable, 
			"TripstersRetripping: Mint is not enable"
		);
		require(
			isUpgradedToL2[triproomID], 
			"TripstersRetripping: TripRoom NFT is not upgraded to L2"
		);
		require(
			!isUpgradedToL3[triproomID], 
			"TripstersRetripping: TripRoom NFT already upgraded to L3"
		);
		require(
            Baggie.ownerOfToken(baggieID) == msg.sender,
            "TripstersRetripping: Incorrect owner"
        );
		require(
            TripRoom.ownerOfToken(triproomID) == msg.sender,
            "TripstersRetripping: Incorrect owner"
        );
		
		isUpgradedToL3[triproomID] = true;
		upgradeL3.push([baggieID,triproomID]);
		Baggie.safeTransferFrom(msg.sender, DEAD, baggieID);
    }
	
	function upgradeNFTToL2L3(uint256 baggieIDOne, uint256 baggieIDTwo, uint256 triproomID) public nonReentrant{
		require(
			mintEnable, 
			"TripstersRetripping: Mint is not enable"
		);
		require(
			!isUpgradedToL3[triproomID], 
			"TripstersRetripping: TripRoom NFT already upgraded to L3"
		);
		require(
			!isUpgradedToL2[triproomID], 
			"TripstersRetripping: TripRoom NFT already upgraded to L2"
		);
		require(
            Baggie.ownerOfToken(baggieIDOne) == msg.sender,
            "TripstersRetripping: Incorrect owner `baggieIDOne`"
        );
		require(
            Baggie.ownerOfToken(baggieIDTwo) == msg.sender,
            "TripstersRetripping: Incorrect owner `baggieIDTwo`"
        );
		require(
            TripRoom.ownerOfToken(triproomID) == msg.sender,
            "TripstersRetripping: Incorrect owner `triproomID`"
        );
		
		isUpgradedToL2[triproomID] = true;
		isUpgradedToL3[triproomID] = true;
		
		upgradeL2.push([baggieIDOne,triproomID]);
		upgradeL3.push([baggieIDTwo,triproomID]);
		
		Baggie.safeTransferFrom(msg.sender, DEAD, baggieIDOne);
		Baggie.safeTransferFrom(msg.sender, DEAD, baggieIDTwo);
    }
	
	function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
	
	function setMintingStatus(bool status) public onlyOwner {
        require(mintEnable != status);
		mintEnable = status;
    }
	
	function getL2Details(uint256 index) public view returns(uint256[2] memory L2List) {
        return(upgradeL2[index]);
    }
	
	function getL3Details(uint256 index) public view returns(uint256[2] memory L3List) {
        return(upgradeL3[index]);
    }
}