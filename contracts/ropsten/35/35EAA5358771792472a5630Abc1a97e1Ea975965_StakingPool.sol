/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-03
*/

// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/utils/Strings.sol

pragma solidity ^0.8.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


contract StakingPool is Ownable{
    //last time that tokens where retrieved
    mapping(uint => uint256) public checkpoints;

    //see how many nfts are being staked
    mapping(address => uint256[]) public stakedTokens;

    IERC721Enumerable public NFTCollection;
    IERC20 public Token;

    uint public rewardPerDayBronze = 100000;
    uint public rewardPerDaySilver = 200000;
    uint public rewardPerDayGold = 300000;
    uint public rewardPerDayPlatinum = 400000;

    //dummy address that we use to sign the mint transaction to make sure it is valid
    address private dummy = 0x80E4929c869102140E69550BBECC20bEd61B080c;

    constructor() {
        NFTCollection = IERC721Enumerable(0x6Fa4DfC050b7286665cc20fA26C1070577D02ecb);
        Token = IERC20(0x81fec34C55709D8149c3250f55cda8441BE72AD1);
    }

    modifier onlyValidAccess(uint8 _v, bytes32 _r, bytes32 _s) {
        // require( isValidAccessMessage(msg.sender,_v,_r,_s), 'Invalid Signature' );
        _;
    }

    //set ERC721Enumerable
    function setNFTInterface(address newInterface) public onlyOwner {
        NFTCollection = IERC721Enumerable(newInterface);
    }

    //set ERC20
    function setTokenInterface(address newInterface) public onlyOwner {
        Token = IERC20(newInterface);
    }
 
    /* 
    * @dev Verifies if message was signed by owner to give access to _add for this contract.
    *      Assumes Geth signature prefix.
    * @param _add Address of agent with access
    * @param _v ECDSA signature parameter v.
    * @param _r ECDSA signature parameters r.
    * @param _s ECDSA signature parameters s.
    * @return Validity of access message for a given address.
    */
    function isValidAccessMessage(address _add, uint8 _v, bytes32 _r, bytes32 _s) view public returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(address(this), _add));
        return dummy == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _v, _r, _s);
    }

    function depositAll() external {
        uint balance = NFTCollection.balanceOf(msg.sender);
        require(balance > 0, "No tokens to stake!");

        uint tid;
        for (uint i = 0; i < balance; i++) {
            tid = NFTCollection.tokenOfOwnerByIndex(msg.sender, i);
            _deposit(tid);
        }
    }

    function deposit(uint tokenId) public {
        //they have to be the owner of tokenID
        require(msg.sender == NFTCollection.ownerOf(tokenId), 'Sender must be owner');
        _deposit(tokenId);
        
    }

    function _deposit(uint tokenId) internal {
        //set the time of staking to now
        checkpoints[tokenId] = block.timestamp;

        //transfer NFT to contract
        NFTCollection.transferFrom(msg.sender, address(this), tokenId);

        //add to their staked tokens
        stakedTokens[msg.sender].push(tokenId);
    }

    function withdrawAll(uint[] memory types_, uint8 _v, bytes32 _r, bytes32 _s) onlyValidAccess(_v,  _r, _s) external {
        require(stakedTokens[msg.sender].length > 0, "No tokens staked");
        require(types_.length == stakedTokens[msg.sender].length, "Types and Tokens Staked do not match!");
        for (uint i = 0; i < stakedTokens[msg.sender].length; i++) {
            _withdraw(stakedTokens[msg.sender][i], types_[i]);
            popFromStakedTokens(stakedTokens[msg.sender][i]);
        }
    }

    function emergencyWithdrawAll() external {
        require(stakedTokens[msg.sender].length > 0, "No tokens staked");
        for (uint i = 0; i < stakedTokens[msg.sender].length; i++) {
            NFTCollection.transferFrom(address(this), msg.sender, stakedTokens[msg.sender][i]);
            popFromStakedTokens(stakedTokens[msg.sender][i]);
            checkpoints[stakedTokens[msg.sender][i]] = block.timestamp; 
        }
    }

    function withdraw(uint tokenId, uint type_, uint8 _v, bytes32 _r, bytes32 _s) onlyValidAccess(_v,  _r, _s)  public {
        bool check = false;
        for (uint i = 0; i < stakedTokens[msg.sender].length; i++) {
            if (stakedTokens[msg.sender][i] == tokenId) {
                check = true;
                break;
            }
        }
        require(check == true, 'You have not staked this token!');

        _withdraw(tokenId, type_);
        popFromStakedTokens(tokenId);
        
    }

    function emergencyWithdraw(uint tokenId) external {
        bool check = false;
        for (uint i = 0; i < stakedTokens[msg.sender].length; i++) {
            if (stakedTokens[msg.sender][i] == tokenId) {
                check = true;
                break;
            }
        }
        require(check == true, 'You have not staked this token!');

        NFTCollection.transferFrom(address(this), msg.sender, tokenId);
        popFromStakedTokens(tokenId);
        checkpoints[tokenId] = block.timestamp; 
    }

    function popFromStakedTokens(uint tokenId) internal {
        uint pos = positionInStakedTokens(tokenId);
        
        uint firstValue = stakedTokens[msg.sender][pos];
        uint secondValue = stakedTokens[msg.sender][stakedTokens[msg.sender].length - 1];
        stakedTokens[msg.sender][pos] = secondValue;
        stakedTokens[msg.sender][stakedTokens[msg.sender].length - 1] = firstValue;
        stakedTokens[msg.sender].pop();
    }

    function positionInStakedTokens(uint tokenId) internal view returns(uint) {
        uint index;
        for (uint i = 0; i < stakedTokens[msg.sender].length; i++) {
            if (stakedTokens[msg.sender][i] == tokenId) {
                index = i;
                break;
            }
        }
        return index;
    }

    function _withdraw(uint tokenId, uint type_) internal {
        collect(tokenId, type_);
        NFTCollection.transferFrom(address(this), msg.sender, tokenId);
    }

    function getReward(uint tokenId, uint type_, uint8 _v, bytes32 _r, bytes32 _s) onlyValidAccess(_v,  _r, _s) public {
        bool check = false;
        for (uint i = 0; i < stakedTokens[msg.sender].length; i++) {
            if (stakedTokens[msg.sender][i] == tokenId) {
                check = true;
                break;
            }
        }
        require(check == true, 'You have not staked this token!');

        collect(tokenId, type_);
    }

    function getAllRewards(uint[] memory types_, uint8 _v, bytes32 _r, bytes32 _s) onlyValidAccess(_v,  _r, _s) public {
        require(stakedTokens[msg.sender].length > 0, "No tokens staked");
        require(types_.length == stakedTokens[msg.sender].length, "Types and Tokens Staked do not match!");

        for (uint i = 0; i < types_.length; i++) {
            collect(stakedTokens[msg.sender][i], types_[i]);
        }
    }


    function collect(uint tokenId, uint type_) internal {
        uint256 reward = calculateReward(tokenId, type_);     
        //_mint(msg.sender, reward);
        require(reward <= Token.balanceOf(address(this)), "Staking Contract does not have sufficient funds");
        // Token.transferFrom(address(this), msg.sender, reward);
        Token.transfer(msg.sender, reward);

        checkpoints[tokenId] = block.timestamp; 
    }

    function calculateReward(uint tokenId, uint type_) public view returns(uint256) {
        require(type_ >= 0 && type_ < 5, "Invalid Type of Token!");
        uint256 checkpoint = checkpoints[tokenId];

        if (type_ == 0) {
            return 0;
        }
        else if (type_ == 1) {
            return rewardPerDayBronze * ((block.timestamp-checkpoint) / 400);
        }
        else if (type_ == 2) {
            return rewardPerDaySilver * ((block.timestamp-checkpoint) / 86400);
        }
        else if (type_ == 3) {
            return rewardPerDayGold * ((block.timestamp-checkpoint) / 86400);
        }
        else {
            return rewardPerDayPlatinum * ((block.timestamp-checkpoint) / 86400);
        }
        
    }



    function seeStakedTokens(address who) public view returns(uint256[] memory) {
        return stakedTokens[who];
    }
    
}