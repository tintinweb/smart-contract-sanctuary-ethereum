/**
 *Submitted for verification at Etherscan.io on 2022-06-29
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

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
	
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
  
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
   
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
	
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;
	
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
	
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
	
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract PledgeMint is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20; 
	
	struct PhaseConfig {
       uint256 mintPrice;
	   uint256 mintPriceWhiteList;
       uint256 maxPerWallet;
	   uint256 maxSupply;
	   uint256 minted;
	   bytes32 merkleRoot;
	   bool saleEnable;
    }
	
	IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC
    mapping(uint256 => address[]) public pledgers;
    mapping(uint256 => mapping(address => uint256)) public pledges;

    PhaseConfig[] public phases;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _; 
    }
	
    constructor() {}
	
    function addPhase(uint256 mintPrice, uint256 mintPriceWhiteList, uint256 maxPerWallet, uint256 maxSupply, bytes32 merkleRoot) external onlyOwner {
        phases.push(PhaseConfig(mintPrice, mintPriceWhiteList, maxPerWallet, maxSupply, 0, merkleRoot, false));
    }
	
    function pledge(uint256 phaseId, uint256 number) external callerIsUser nonReentrant{
        PhaseConfig storage phase = phases[phaseId];
		
		require(phases.length > phaseId, "PhaseID not found");
		require(phase.saleEnable, "Sale is not enable");
        require(number <= phase.maxPerWallet, "Cannot buy that many NFTs");
        require(number > 0, "Need to buy at least one");
		require(USDC.balanceOf(msg.sender) >= phase.mintPrice * number, "USDC balance is not available for pledge");
		require(pledges[phaseId][msg.sender] + number <= phase.maxPerWallet, "Already pledged");
		require(phase.minted + number <= phase.maxSupply, "Max supply reached");
		
		if(pledges[phaseId][msg.sender]==0)
		{
		   pledgers[phaseId].push(msg.sender);
		}
		
		phase.minted = phase.minted + number;
        pledges[phaseId][msg.sender] = pledges[phaseId][msg.sender] + number;
		USDC.safeTransferFrom(address(msg.sender), address(this), phase.mintPrice * number);
    }
	
	function pledge(uint256 phaseId, uint256 number, bytes32[] calldata merkleProof) external callerIsUser nonReentrant{
        PhaseConfig storage phase = phases[phaseId];
		bytes32 node = keccak256(abi.encodePacked(msg.sender));
		
		require(phases.length > phaseId, "PhaseID not found");
		require(phase.saleEnable, "Sale is not enable");
        require(number <= phase.maxPerWallet, "Cannot buy that many NFTs");
        require(number > 0, "Need to buy at least one");
		require(USDC.balanceOf(msg.sender) >= phase.mintPriceWhiteList * number, "USDC balance is not available for pledge");
        require(pledges[phaseId][msg.sender] + number <= phase.maxPerWallet, "Already pledged");
		require(MerkleProof.verify(merkleProof, phase.merkleRoot, node), "Invalid Proof");
		require(phase.minted + number <= phase.maxSupply, "Max supply reached");
		
		if(pledges[phaseId][msg.sender]==0)
		{
		   pledgers[phaseId].push(msg.sender);
		}
		
		phase.minted = phase.minted + number;
		pledges[phaseId][msg.sender] = pledges[phaseId][msg.sender] + number;
		USDC.safeTransferFrom(address(msg.sender), address(this), phase.mintPriceWhiteList * number);
    }
	
	function withdraw() external onlyOwner nonReentrant{
       USDC.safeTransfer(address(msg.sender), USDC.balanceOf(address(this)));
    }
	
	function withdrawETH() external onlyOwner nonReentrant{
        payable(msg.sender).transfer(address(this).balance);
    }
	
	function migrateTokens(address token, uint256 amount) external onlyOwner nonReentrant{
       IERC20(token).safeTransfer(address(msg.sender), amount);
    }
	
	function updateMerkleRoot(uint256 phaseId, bytes32 newMerkleRoot) external onlyOwner {
	   require(phases.length > phaseId, "PhaseID not found");
	   phases[phaseId].merkleRoot = newMerkleRoot;
	}
	
	function saleStatus(uint256 phaseId, bool status) external onlyOwner {
	   require(phases.length > phaseId, "PhaseID not found");
	   phases[phaseId].saleEnable = status;
	}
	
	function updatePrice(uint256 phaseId, uint256 mintPrice, uint256 mintPriceWhiteList) external onlyOwner {
	   require(phases.length > phaseId, "PhaseID not found");
	   phases[phaseId].mintPrice = mintPrice;
	   phases[phaseId].mintPriceWhiteList = mintPriceWhiteList;
	}
	
	function updateMintLimit(uint256 phaseId, uint256 maxPerWallet) external onlyOwner {
	   require(phases.length > phaseId, "PhaseID not found");
	   require(maxPerWallet >= 0, "Incorrect value");
	   phases[phaseId].maxPerWallet = maxPerWallet;
	}
	
	function updateSupply(uint256 phaseId, uint256 supplyLimit) external onlyOwner {
	   require(phases.length > phaseId, "PhaseID not found");
	   require(supplyLimit >= phases[phaseId].minted, "Incorrect value");
	   phases[phaseId].maxSupply = supplyLimit;
	}
}