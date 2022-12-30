/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;  
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
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
interface IERC165 { 
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 { 
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); 
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); 
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); 
    function balanceOf(address owner) external view returns (uint256 balance); 
    function ownerOf(uint256 tokenId) external view returns (address owner); 
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external; 
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external; 
    function approve(address to, uint256 tokenId) external;
 
    function getApproved(uint256 tokenId) external view returns (address operator); 
    function setApprovalForAll(address operator, bool _approved) external; 
    function isApprovedForAll(address owner, address operator) external view returns (bool); 
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }
   function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function stakeReward(address to, uint256 amount) external;
}

contract Ghostlers_Staking is Ownable{
    
    mapping(uint => mapping(string => uint)) public reward;
    function setReward(uint locking_months, string memory level, uint BOOCOINS_in_wei) public onlyOwner{
        require(locking_months == 1 || locking_months == 3 || locking_months == 6 || locking_months == 12, "Invalid months given.");
        reward[locking_months][level] = BOOCOINS_in_wei;
    }

    mapping(string => bytes32) public merkleRoot;
    function setMerkleRoot(string memory level, bytes32 m) public onlyOwner{
        require(keccak256(bytes(level)) == keccak256(bytes("Basic")) || 
                keccak256(bytes(level)) == keccak256(bytes("Ordinary")) || 
                keccak256(bytes(level)) == keccak256(bytes("ExtraOrdinary")) || 
                keccak256(bytes(level)) == keccak256(bytes("Legendary")) || 
                keccak256(bytes(level)) == keccak256(bytes("Rare")) || 
                keccak256(bytes(level)) == keccak256(bytes("SuperRare")), "Invalid level given.");
        merkleRoot[level] = m;
    }

    address public BOOCOIN_Address = 0xcA252612baE035b6D49c8FD8908B87723084fbC0;
    function set_BOOCOIN_Address(address a) public onlyOwner{
        BOOCOIN_Address = a;
    }
    
    address public GHOSTLERS_NFT = 0xdbE15A1DA3A58f96dE9C64233744F58F19adA1cE;
    function setGHOSTLERS_NFT(address a) public onlyOwner{
        GHOSTLERS_NFT = a;
    }

    uint public thirty_day_constant = 2592000;
    function set_thirty_day_constant(uint t) public onlyOwner {
        thirty_day_constant = t;
    }

    struct Stake {
        uint id;
        address address_;
        uint staked_time;
        uint locking_months;
        string level;
        bool staked;
    }
    
    mapping(uint => Stake) public STAKES;
    mapping(address => uint) public stakeBalanceOfUser;

////////////////////////////////////////////////////////////////////////////////////////

    function stake(uint256[] memory ids, bytes32[][] calldata merkleproof, uint[] memory locking_months, string[] memory levels) public {
                
        for(uint i=0 ; i<ids.length; i++) {
            require(locking_months[i] == 1 || locking_months[i] == 3 || locking_months[i] == 6 || locking_months[i] == 12, "Invalid months given.");
            require(keccak256(bytes(levels[i])) == keccak256(bytes("Basic")) || 
                    keccak256(bytes(levels[i])) == keccak256(bytes("Ordinary")) || 
                    keccak256(bytes(levels[i])) == keccak256(bytes("ExtraOrdinary")) || 
                    keccak256(bytes(levels[i])) == keccak256(bytes("Legendary")) || 
                    keccak256(bytes(levels[i])) == keccak256(bytes("Rare")) || 
                    keccak256(bytes(levels[i])) == keccak256(bytes("SuperRare")), "Invalid level given.");

            string memory indexNum = Strings.toString(ids[i]);
            require(MerkleProof.verify( merkleproof[i], merkleRoot[levels[i]], keccak256(abi.encodePacked(indexNum))), "Invalid level for Id!!");
            require(IERC721(GHOSTLERS_NFT).ownerOf(ids[i]) == msg.sender, "Invalid! id not found in user wallet!");
            require(STAKES[ids[i]].staked == false, "ID is alrady Staked!");
        
            IERC721(GHOSTLERS_NFT).transferFrom(msg.sender, address(this), ids[i]);
        
            STAKES[ids[i]].id = ids[i];
            STAKES[ids[i]].address_ = msg.sender;
            STAKES[ids[i]].staked_time = block.timestamp;
            STAKES[ids[i]].locking_months = locking_months[i];
            STAKES[ids[i]].level = levels[i];
            STAKES[ids[i]].staked = true;

            stakeBalanceOfUser[msg.sender] += 1;
        }
    }

    function claim_and_unstake(uint id) public {
        Stake memory s = STAKES[id];
        
        require(s.address_ == msg.sender, "Invalid! address does not match user!");
        require(s.staked == true, "ID is not Staked!");
        require(block.timestamp >= s.staked_time + (s.locking_months * thirty_day_constant), "Staking duration incomplete!");

        IERC20(BOOCOIN_Address).stakeReward(msg.sender, reward[s.locking_months][s.level]);
        IERC721(GHOSTLERS_NFT).transferFrom(address(this), msg.sender, id);

        stakeBalanceOfUser[msg.sender] -= 1;
        delete STAKES[id];
    }

    function batch_claim_and_unstake(uint[] memory ids) public {
        uint total = 0;

        for(uint i=0 ; i<ids.length ; i++) {        
            require(STAKES[ids[i]].address_ == msg.sender, "Invalid! address does not match user!");
            require(STAKES[ids[i]].staked == true, "ID is not Staked!");
            require(block.timestamp >= STAKES[ids[i]].staked_time + (STAKES[ids[i]].locking_months * thirty_day_constant), "Staking duration incomplete!");

            IERC721(GHOSTLERS_NFT).transferFrom(address(this), msg.sender, STAKES[ids[i]].id);

            total += reward[STAKES[ids[i]].locking_months][STAKES[ids[i]].level];
            
            STAKES[ids[i]].staked = false;
            delete STAKES[ids[i]];
        }
        IERC20(BOOCOIN_Address).stakeReward(msg.sender, total);
        stakeBalanceOfUser[msg.sender] -= ids.length;
    }

    function emergency_unstake(uint[]memory ids) public {
        uint total = 0;
        
        for(uint i=0 ; i<ids.length ; i++) {        
            require(STAKES[ids[i]].address_ == msg.sender, "Invalid! address does not match user!");
            require(STAKES[ids[i]].staked == true, "ID is not Staked!");

            IERC721(GHOSTLERS_NFT).transferFrom(address(this), msg.sender, STAKES[ids[i]].id);

            total += get_available_reward(STAKES[ids[i]].id);
            
            STAKES[ids[i]].staked = false;
            delete STAKES[ids[i]];
        }
        IERC20(BOOCOIN_Address).stakeReward(msg.sender, total / 2);
        stakeBalanceOfUser[msg.sender] -= ids.length;
    }
////////////////////////////////////////////////////////////////////////////////////////

    function stakesOfOwner(address a) public view returns(Stake[] memory){
        Stake[] memory s = new Stake[](stakeBalanceOfUser[a]);
        uint tokenIndex=0;
        for(uint i=1 ; tokenIndex!=stakeBalanceOfUser[a] ; i++) {
            if(STAKES[i].address_ == a)
                s[tokenIndex++] = STAKES[i];
        }
        return s;
    }

    function get_available_reward(uint id) public view returns(uint){
        Stake memory s = STAKES[id];
        require(s.staked, "Token not staked");
        uint r = reward[s.locking_months][s.level] / (s.locking_months * thirty_day_constant);
        uint currentTime = block.timestamp < s.staked_time + (s.locking_months * thirty_day_constant) ? block.timestamp : s.staked_time + (s.locking_months * thirty_day_constant);
        
        return r * (currentTime - s.staked_time);
    }

    function stakeIdsOfOwner(address a) public view returns(uint[] memory){
        uint[] memory s = new uint[](stakeBalanceOfUser[a]);
        uint tokenIndex=0;
        for(uint i=1 ; tokenIndex!=stakeBalanceOfUser[a] ; i++) {
            if(STAKES[i].address_ == a)
                s[tokenIndex++] = i;
        }
        return s;
    }

    constructor() {
        merkleRoot["Basic"] = 0x7bb81aa88595be0ff2df96e4a29faa2c541aaaaeed60e8a15e1ad5406e2d6c6c;
        merkleRoot["Ordinary"] = 0x84f82b17adbfac8c3b2a0a51276b637652e228c77678383dbf99828c421d735b;
        merkleRoot["ExtraOrdinary"] = 0xab0b230421c8f3fae8713f76c6281b72e276b3d6a791ac8326efa7514e42d44b;
        merkleRoot["Legendary"] = 0x91ea53917b70190d3fa658e0f8fa0d13d92473a33f3f23bdb3ae654772bc8ae1;
        merkleRoot["Rare"] = 0xa328d2c1384b0c3eff25881a408e984ec137a38318a78b4804ef87f5ddcd4570;
        merkleRoot["SuperRare"] = 0x69a688ee4a19248399a1ed719b7b7809e003857f1292f1ad6f2513d6f67341a1;

        setReward(1, "Basic", 2000000000000000000);
        setReward(1, "Ordinary", 5000000000000000000);
        setReward(1, "ExtraOrdinary", 8000000000000000000);
        setReward(1, "Legendary", 11000000000000000000);
        setReward(1, "Rare", 14000000000000000000);
        setReward(1, "SuperRare", 18000000000000000000);

        setReward(3, "Basic", 4000000000000000000);
        setReward(3, "Ordinary", 7000000000000000000);
        setReward(3, "ExtraOrdinary", 10000000000000000000);
        setReward(3, "Legendary", 13000000000000000000);
        setReward(3, "Rare", 16000000000000000000);
        setReward(3, "SuperRare", 21000000000000000000);

        setReward(6, "Basic", 6000000000000000000);
        setReward(6, "Ordinary", 9000000000000000000);
        setReward(6, "ExtraOrdinary", 12000000000000000000);
        setReward(6, "Legendary", 15000000000000000000);
        setReward(6, "Rare", 18000000000000000000);
        setReward(6, "SuperRare", 23000000000000000000);

        setReward(12, "Basic", 8000000000000000000);
        setReward(12, "Ordinary", 11000000000000000000);
        setReward(12, "ExtraOrdinary", 14000000000000000000);
        setReward(12, "Legendary", 17000000000000000000);
        setReward(12, "Rare", 20000000000000000000);
        setReward(12, "SuperRare", 25000000000000000000);
    }
}