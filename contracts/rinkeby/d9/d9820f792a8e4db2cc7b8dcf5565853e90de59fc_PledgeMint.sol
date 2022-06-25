/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
        _transferOwnership(_msgSender());
    }
	
    function owner() public view virtual returns (address) {
        return _owner;
    }
	
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }
}

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract PledgeMint is Ownable, ReentrancyGuard {

    struct PhaseConfig {
	   address admin;
       uint256 mintPrice;
	   uint256 mintPriceWhiteList;
       uint8 maxPerWallet;
	   bytes32 merkleRoot;
	   bool saleEnable;
    }
	
	ERC20 public USDC = ERC20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7); // USDC
	
    mapping(uint16 => address[]) public pledgers;
    mapping(uint16 => mapping(address => uint8)) public pledges;

    PhaseConfig[] public phases;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _; 
    }
	
    modifier onlyAdminOrOwner(uint16 phaseId) {
        require(owner() == _msgSender() || phases[phaseId].admin == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
	
    constructor() {}
	
    function addPhase(address admin, uint256 mintPrice, uint256 mintPriceWhiteList, uint8 maxPerWallet, bytes32 merkleRoot) external onlyOwner {
        phases.push(PhaseConfig(admin, mintPrice, mintPriceWhiteList, maxPerWallet, merkleRoot, false));
    }
	
    function pledge(uint16 phaseId, uint8 number) external callerIsUser {
        PhaseConfig memory phase = phases[phaseId];
		
		require(phase.saleEnable, "Sale is not enable");
        require(number <= phase.maxPerWallet, "Cannot buy that many NFTs");
        require(number > 0, "Need to buy at least one");
		require(USDC.balanceOf(msg.sender) >= phase.mintPrice * number, "USDC balance is not available for pledge");
        require(pledges[phaseId][msg.sender] == 0, "Already pledged");
        
		pledgers[phaseId].push(msg.sender);
        pledges[phaseId][msg.sender] = number;
		USDC.transferFrom(address(msg.sender), address(this), phase.mintPrice * number);
    }
	
	function pledge(uint16 phaseId, uint8 number, bytes32[] calldata merkleProof) external callerIsUser {
        PhaseConfig memory phase = phases[phaseId];
		bytes32 node = keccak256(abi.encodePacked(msg.sender));
		
		require(phase.saleEnable, "Sale is not enable");
        require(number <= phase.maxPerWallet, "Cannot buy that many NFTs");
        require(number > 0, "Need to buy at least one");
		require(USDC.balanceOf(msg.sender) >= phase.mintPriceWhiteList * number, "USDC balance is not available for pledge");
        require(pledges[phaseId][msg.sender] == 0, "Already pledged");
		require(MerkleProof.verify(merkleProof, phase.merkleRoot, node), "Invalid Proof");
		
		pledgers[phaseId].push(msg.sender);
        pledges[phaseId][msg.sender] = number;
		USDC.transferFrom(address(msg.sender), address(this), phase.mintPriceWhiteList * number);
    }
	
	function withdraw() external onlyOwner nonReentrant{
       USDC.transfer(address(msg.sender), USDC.balanceOf(address(this)));
    }
	
	function withdrawETH() external onlyOwner nonReentrant{
        payable(msg.sender).transfer(address(this).balance);
    }
	
	function migrateTokens(address token, uint256 amount) external onlyOwner nonReentrant{
       ERC20(token).transfer(address(msg.sender), amount);
    }
	
	function updateMerkleRoot(uint16 phaseId, bytes32 newMerkleRoot) external onlyAdminOrOwner(phaseId) nonReentrant{
	   PhaseConfig memory phase = phases[phaseId];
	   phase.merkleRoot = newMerkleRoot;
	}
	
	function saleStatus(uint16 phaseId, bool status) external onlyAdminOrOwner(phaseId) nonReentrant{
	   PhaseConfig memory phase = phases[phaseId];
	   phase.saleEnable = status;
	}
	
	function updatePrice(uint16 phaseId, uint256 mintPrice, uint256 mintPriceWhiteList) external onlyAdminOrOwner(phaseId) nonReentrant{
	   PhaseConfig memory phase = phases[phaseId];
	   phase.mintPrice = mintPrice;
	   phase.mintPriceWhiteList = mintPriceWhiteList;
	}
	
	function updateMintLimit(uint16 phaseId, uint8 maxPerWallet) external onlyAdminOrOwner(phaseId) nonReentrant{
	   PhaseConfig memory phase = phases[phaseId];
	   phase.maxPerWallet = maxPerWallet;
	}
}