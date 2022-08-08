/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: contracts/MonsterHole.sol


pragma solidity ^0.8.0;




interface ICheck {
    function verification(address _address,uint256 _amount,string memory signedMessage) external view returns (bool);

    function check(address _address,uint256[] memory _tokenId,string memory signedMessage) external view returns (bool);

}

contract MyHole is Ownable{
    IERC721 public Token721;
    IERC20 public Token20;
    ICheck private Simple;

    bool public _isActiveRecharge = true;
    bool public _isActiveWithdrawal = true;
    bool public _isActiveStake = true;
    bool public _isActiveExtract = true;

    address public receiver;

    mapping(address => string) private Signature;
    mapping(address => uint256[]) public StakingNumber; 

    event stakeEvent(address indexed from, address indexed to,uint256 indexed tokenId); 
    event withdrawEvent(address indexed from, address indexed to,uint256 indexed tokenId); 

    constructor(address _Token721, address _token, address _check) {
        Token721 = IERC721(_Token721);
        Token20 = IERC20(_token);
        Simple = ICheck(_check);
        receiver = msg.sender;
    }

    function rechargeTorch(uint256 _amount) public {
        require(
            _isActiveRecharge,
            "Recharge must be active"
        );

        require(
            _amount > 0,
            "Recharge torch must be greater than 0"
        );

        Token20.transferFrom(msg.sender, address(this), _amount);

    }
    

    function withdrawTorch(uint256 _amount, string memory _signature) public {
        require(
            _isActiveWithdrawal,
            "Withdraw must be active"
        );

         require(
            _amount > 0,
            "Recharge torch must be greater than 0"
        );

        require(
            keccak256(abi.encodePacked(_signature)) != keccak256(abi.encodePacked(Signature[msg.sender])),
            "Can only withdraw 1 times at 1 hour"
        );

        require(
            Simple.verification(msg.sender, _amount, _signature) == true,
            "Audit error"
        );

        // require(
        //     Token20.allowance(receiver, address(this)) > _amount,
        //     "Torch must be approve required"
        // );

        require(
            Token20.balanceOf(address(this)) >= _amount,
            "Torch credit is running low"
        );

        Signature[msg.sender] = _signature;

        Token20.transfer(msg.sender, _amount);

    }

    function stake(uint256[] memory _tokenId) public {
        require(
            _isActiveStake,
            "Stake must be active"
        );

        uint256  tokenIdLength  = _tokenId.length;
        require(tokenIdLength > 0, "Tokens must be greater than 0");

        for(uint i = 0;i < tokenIdLength;i++){
            require(Token721.ownerOf(_tokenId[i]) ==  msg.sender, "Insufficient balance");

            Token721.transferFrom(msg.sender,address(this),_tokenId[i]);
            StakingNumber[msg.sender].push(_tokenId[i]);

            emit stakeEvent(msg.sender, address(this), _tokenId[i] );
        }

    }


   
    function withdrawStake(uint256[] memory _tokenId, string memory _signature) public {
        require(
            _isActiveExtract,
            "Withdraw staking must be active"
        );

        require(
            Simple.check(msg.sender, _tokenId, _signature) == true,
            "Audit error"
        );

 
        uint256  tokenIdLength  = _tokenId.length;
    
        for(uint i = 0;i < tokenIdLength;i++){
            require(getAddressStakingNumberbool(_tokenId[i]), "No collateral found");

            Token721.transferFrom(address(this), msg.sender, _tokenId[i]);

            (bool respond, uint256 _num)  = getAddressStakingNumberkey(_tokenId[i]);
            if(respond == true)
                deleteAddressStakingNumber(_num);

            emit withdrawEvent(address(this), msg.sender, _tokenId[i]);
        }

    }

    function getAddressStakingNumberlength(address _addr) public view returns(uint256){
        return StakingNumber[_addr].length;
    }

    function getAddressStakingNumberbool(uint256 _tokenId) public view returns(bool){
        uint256 popNum = getAddressStakingNumberlength(msg.sender);
        for(uint i = 0; i < popNum; i++){
            if(StakingNumber[msg.sender][i] == _tokenId){
                return true;
            }
        }
        return false;
    }

    function deleteAddressStakingNumber(uint256 _num) private {
        uint256 popNum = getAddressStakingNumberlength(msg.sender) -1;
        StakingNumber[msg.sender][_num] = StakingNumber[msg.sender][popNum];
        StakingNumber[msg.sender].pop();
    }

    function getAddressStakingNumberkey(uint256 _tokenId) public view returns(bool,uint){
        uint256 popNum = getAddressStakingNumberlength(msg.sender);
        for(uint i = 0; i < popNum; i++){
            if(StakingNumber[msg.sender][i] == _tokenId){
                return (true,i);
            }
        }
        return (false,0);
    }

    function getStakeTokenIds(address _addr) public view returns(uint256[] memory){
        return StakingNumber[_addr];
    }

    function setReceiver(address _addr) public onlyOwner{
        receiver = _addr;
    }

    function withdraw(uint256 _amount) public onlyOwner{
        Token20.transferFrom(address(this), receiver, _amount);
    }

}