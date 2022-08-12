// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./AbstractGoatorade.sol";

contract Goatorade is AbstractGoatorade {

    using SafeMath for uint256;
    using Counters for Counters.Counter;
	
    Counters.Counter private TierCounter; 
    mapping(uint256 => Tier) public Tiers;
    event Mint(address indexed account, uint amount);
	
    struct Tier {
        uint256 airdropSupply;
		uint256 reservedSupply;
        uint256 airdropMinted;
		uint256 reservedMinted;
        string ipfsMetadataHash;
    }
	
    constructor() ERC1155("ipfs://ipfs/") {}
	
    function addTier(
		uint256 _airdropSupply, 
		uint256 _reservedSupply, 
		string memory _ipfsMetadataHash
	) external onlyOwner {
        Tier storage tier = Tiers[TierCounter.current()];
        tier.airdropSupply = _airdropSupply;
		tier.reservedSupply = _reservedSupply;
		tier.ipfsMetadataHash = _ipfsMetadataHash;
        TierCounter.increment();
    }
	
	function editTier (
		uint256 _airdropSupply, 
		uint256 _reservedSupply, 
		string memory _ipfsMetadataHash, 
		uint256 _tierIndex
	) external onlyOwner {
        require(_airdropSupply >= Tiers[_tierIndex].airdropMinted, "Incorrect airdrop supply");
		require(_reservedSupply >= Tiers[_tierIndex].reservedMinted, "Incorrect reserved supply");
        Tiers[_tierIndex].airdropSupply = _airdropSupply;
		Tiers[_tierIndex].reservedSupply = _reservedSupply;
		Tiers[_tierIndex].ipfsMetadataHash = _ipfsMetadataHash;
    }
	
	function mintAirdropNFT(uint256[] calldata _count, address[] calldata _to, uint256 _tierIndex) external onlyOwner{
	    require(
			_to.length == _count.length,
			"Mismatch between Address and count"
		);
		require(
		   !paused(), 
		   "contract is paused"
		);
        require(
			Tiers[_tierIndex].airdropSupply != 0, 
			"Tier does not exist"
		);
		
		for(uint i=0; i < _to.length; i++){
		   require(
			  Tiers[_tierIndex].airdropMinted.add(_count[i]) <= Tiers[_tierIndex].airdropSupply, 
			  "Exceeds airdrop supply limit"
		   );
		   Tiers[_tierIndex].airdropMinted = Tiers[_tierIndex].airdropMinted.add(_count[i]);
		   _mint(_to[i], _tierIndex, _count[i], "");
		}
    }
	
	function mintReservedNFT(uint256[] calldata _count, address[] calldata _to, uint256 _tierIndex) external onlyOwner{
	    require(
			_to.length == _count.length,
			"Mismatch between Address and count"
		);
		require(
		   !paused(), 
		   "contract is paused"
		);
        require(
			Tiers[_tierIndex].reservedSupply != 0, 
			"Tier does not exist"
		);
		
		for(uint i=0; i < _to.length; i++){
		   require(
			  Tiers[_tierIndex].reservedMinted.add(_count[i]) <= Tiers[_tierIndex].reservedSupply, 
			  "Exceeds reserved supply limit"
		   );
		   Tiers[_tierIndex].reservedMinted = Tiers[_tierIndex].reservedMinted.add(_count[i]);
		   _mint(_to[i], _tierIndex, _count[i], "");
		}
    }
	
	function burnBatchNFT(uint256[] calldata _count, address[] calldata _holder, uint256 _tierIndex) external onlyOwner{
	    require(
			_holder.length == _count.length,
			"Mismatch between Address and count"
		);
		require(
		   !paused(), 
		   "contract is paused"
		);
		for(uint i=0; i < _holder.length; i++){
		   _burn(_holder[i], _tierIndex, _count[i]);
		}
    }
	
    function withdrawEther(address payable _to) public onlyOwner{
	    uint256 balance = address(this).balance;
        _to.transfer(balance);
    }
	
    function uri(uint256 _id) public view override returns (string memory) {
       require(totalSupply(_id) > 0, "URI: nonexistent token");
       return string(abi.encodePacked(super.uri(_id), Tiers[_id].ipfsMetadataHash));
    }    
}