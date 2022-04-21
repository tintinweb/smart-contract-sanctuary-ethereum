/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
    constructor() {
        _setOwner(_msgSender());
    }
	
    function owner() public view virtual returns (address) {
        return _owner;
    }
	
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
	
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
	
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract LBNFT {
   function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
   function balanceOf(address owner) public virtual view returns (uint256);
   function safeTransferFrom(address from, address to, uint256 tokenId)  public virtual;
}

contract AirDrop is Ownable{
	LBNFT public LBNFTContractInstance = LBNFT(0x3A1c8bCd828A1058A0953F0Cc4302D418399a150);
	
	function airdrop(address[] memory _recipients, uint256[] memory _amount) public onlyOwner{
		require(_recipients.length == _amount.length, "Incorrect Length");
		uint256 index;
		for (uint256 i = 0; i < _recipients.length; i++) {
		    require(LBNFTContractInstance.balanceOf(address(this)) >= _amount[i], "Insufficient balance");
			for (uint256 j = 0; i < _amount[i]; j++) 
			{
			    LBNFTContractInstance.safeTransferFrom(address(this), _recipients[i], LBNFTContractInstance.tokenOfOwnerByIndex(address(this),index));
				index++;
			}
        }
    }
	
	function airdrop(address[] memory _recipients, uint256 _amount) public onlyOwner{
		uint256 index;
		for (uint256 i = 0; i < _recipients.length; i++) {
		    require(LBNFTContractInstance.balanceOf(address(this)) >= _amount, "Insufficient balance");
			for (uint256 j = 0; i < _amount; j++) 
			{
			    LBNFTContractInstance.safeTransferFrom(address(this), _recipients[i], LBNFTContractInstance.tokenOfOwnerByIndex(address(this), index));
				index++;
			}
        }
    }
}