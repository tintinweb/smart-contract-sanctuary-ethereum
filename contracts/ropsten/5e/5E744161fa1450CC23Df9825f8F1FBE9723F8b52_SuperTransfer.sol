// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.16;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

contract Ownable {
  address public  owner;

    constructor() public {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract SuperTransfer is Ownable  {
    bytes32 public merkleRoot;
    uint256 index;
  
    event Withdrawed(address indexed token,uint256 indexed index, address indexed account, uint256 amount);
    event Deposit(address indexed token,address indexed account, uint256 amount);
    // This is a packed array of booleans.
    mapping(address => uint256) private WithdrawedBitMap;

    constructor() Ownable()
    public {
    }

    function setAccountsMerkleRoot(bytes32  _merkleRoot,uint256 _index)  external onlyOwner {
        merkleRoot=_merkleRoot;
        require(index!=_index,"index must be different");
        index=_index;
    }

    //Please approve first
    function deposit(address token, address account, uint256 amount) external {
        require(IERC20(token).transferFrom(account,address(this), amount), 'MerkleDistributor: Transfer failed.');

        emit Deposit(token, account, amount);
    }
    
    
    function blockTimestamp() public view returns (uint256) {
       return block.timestamp;
   }

    function isWithdrawed(address account) public view  returns (bool) {

        if(WithdrawedBitMap[account]==index){
            return true;
        }else{
            return false;
        }

    }

    function _setWithdrawed(address _account) private {

        WithdrawedBitMap[_account] = index;
    }

    function withdraw(address token,uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external  {
        require(!isWithdrawed(account), 'MerkleDistributor: already Withdrawed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(token,index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it Withdrawed and send the token.
        _setWithdrawed(account);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Withdrawed(token,index, account, amount);
    }
}