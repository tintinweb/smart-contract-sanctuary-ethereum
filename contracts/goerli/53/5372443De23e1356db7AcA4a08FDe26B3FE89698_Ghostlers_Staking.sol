/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;  
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
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}
contract Ghostlers_Staking is Ownable{
    
    mapping(uint => uint) public reward;
    function setReward(uint locking_months, uint BOOCOINS_in_wei) public onlyOwner{
        require(locking_months == 1 || locking_months == 3 || locking_months == 6 || locking_months == 12, "Invalid months given.");
        reward[locking_months] = BOOCOINS_in_wei;
    }

    address public BOOCOIN_Address = 0x555CcF88E3B9220D7BDCa800b9b2d9A6b45BDEEb;
    function set_BOOCOIN_Address(address a) public onlyOwner{
        BOOCOIN_Address = a;
    }

    address public GHOSTLERS_NFT = 0xc168abf1cadE312776e476E6A58704F39Fcb070c;
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
        bool staked;
    }
    
    mapping(uint => Stake) public STAKES;
    mapping(address => uint) public _stakeBalanceOfUser;

////////////////////////////////////////////////////////////////////////////////////////

    function stake(uint256[] memory ids, uint[] memory locking_months) public {
                
        for(uint i=0 ; i<ids.length; i++) {
            require(locking_months[i] == 1 || locking_months[i] == 3 || locking_months[i] == 6 || locking_months[i] == 12, "Invalid months given.");
            require(IERC721A(GHOSTLERS_NFT).ownerOf(ids[i]) == msg.sender, "Invalid! id not found in user wallet!");
            require(STAKES[ids[i]].staked == false, "ID is alrady Staked!");
        
            IERC721A(GHOSTLERS_NFT).transferFrom(msg.sender, address(this), ids[i]);
        
            STAKES[ids[i]].id = ids[i];
            STAKES[ids[i]].address_ = msg.sender;
            STAKES[ids[i]].staked_time = block.timestamp;
            STAKES[ids[i]].locking_months = locking_months[i];
            STAKES[ids[i]].staked = true;
            _stakeBalanceOfUser[msg.sender] += 1;
        }
    }

    function claim_and_unstake(uint id) public {
        Stake memory s = STAKES[id];
        
        require(s.address_ == msg.sender, "Invalid! address does not match user!");
        require(s.staked == true, "ID is not Staked!");
        require(block.timestamp >= s.staked_time + (s.locking_months * thirty_day_constant), "Staking duration incomplete!");

        IERC20(BOOCOIN_Address).stakeReward(msg.sender, reward[s.locking_months]);
        IERC721A(GHOSTLERS_NFT).transferFrom(address(this), msg.sender, id);

        _stakeBalanceOfUser[msg.sender] -= 1;
        delete STAKES[id];

        _total_reward += reward[s.locking_months];
        _total_earnings_of_owner[msg.sender] += reward[s.locking_months];
    }

    function batch_claim_and_unstake(uint[] memory ids) public {
        uint total = 0;

        for(uint i=0 ; i<ids.length ; i++) {        
            require(STAKES[ids[i]].address_ == msg.sender, "Invalid! address does not match user!");
            require(STAKES[ids[i]].staked == true, "ID is not Staked!");
            require(block.timestamp >= STAKES[ids[i]].staked_time + (STAKES[ids[i]].locking_months * thirty_day_constant), "Staking duration incomplete!");

            IERC721A(GHOSTLERS_NFT).transferFrom(address(this), msg.sender, STAKES[ids[i]].id);

            total += reward[STAKES[ids[i]].locking_months];
            
            STAKES[ids[i]].staked = false;
            delete STAKES[ids[i]];
        }
        IERC20(BOOCOIN_Address).stakeReward(msg.sender, total);
        _stakeBalanceOfUser[msg.sender] -= ids.length;

        _total_reward += total;
        _total_earnings_of_owner[msg.sender] += total;
    }

    function emergency_unstake(uint[]memory ids) public {
        uint total = 0;
        
        for(uint i=0 ; i<ids.length ; i++) {        
            require(STAKES[ids[i]].address_ == msg.sender, "Invalid! address does not match user!");
            require(STAKES[ids[i]].staked == true, "ID is not Staked!");

            IERC721A(GHOSTLERS_NFT).transferFrom(address(this), msg.sender, STAKES[ids[i]].id);

            total += get_available_reward(STAKES[ids[i]].id);
            
            STAKES[ids[i]].staked = false;
            delete STAKES[ids[i]];
        }
        IERC20(BOOCOIN_Address).stakeReward(msg.sender, total / 2);
        _stakeBalanceOfUser[msg.sender] -= ids.length;

        _total_reward += total/2;
        _total_earnings_of_owner[msg.sender] += total/2;
    }
////////////////////////////////////////////////////////////////////////////////////////

    function stakesOfOwner(address a) public view returns(Stake[] memory){
        Stake[] memory s = new Stake[](_stakeBalanceOfUser[a]);
        uint tokenIndex=0;
        for(uint i=1 ; tokenIndex!=_stakeBalanceOfUser[a] ; i++) {
            if(STAKES[i].address_ == a)
                s[tokenIndex++] = STAKES[i];
        }
        return s;
    }

    function get_available_reward(uint id) public view returns(uint){
        Stake memory s = STAKES[id];
        require(s.staked, "Token not staked");
        uint r = reward[s.locking_months] / (s.locking_months * thirty_day_constant);
        uint currentTime = block.timestamp < s.staked_time + (s.locking_months * thirty_day_constant) ? block.timestamp : s.staked_time + (s.locking_months * thirty_day_constant);
        return r * (currentTime - s.staked_time);
    }

    function stakeIdsOfOwner(address a) public view returns(uint[] memory){
        uint[] memory s = new uint[](_stakeBalanceOfUser[a]);
        uint tokenIndex=0;
        for(uint i=1 ; tokenIndex!=_stakeBalanceOfUser[a] ; i++) {
            if(STAKES[i].address_ == a)
                s[tokenIndex++] = i;
        }
        return s;
    }

    function _totalStakes() public view returns(uint){
        return IERC721A(GHOSTLERS_NFT).balanceOf(address(this));
    }

    function _getAllStakeIds() public view returns(uint[] memory){
        return IERC721AQueryable(GHOSTLERS_NFT).tokensOfOwner(address(this));
    }

    uint public _total_reward = 0;
    mapping(address => uint) public _total_earnings_of_owner;

    constructor() {
        setReward(1, 150000000000000000000);
        setReward(3, 720000000000000000000);
        setReward(6, 1980000000000000000000);
        setReward(12, 5040000000000000000000);
        }
}