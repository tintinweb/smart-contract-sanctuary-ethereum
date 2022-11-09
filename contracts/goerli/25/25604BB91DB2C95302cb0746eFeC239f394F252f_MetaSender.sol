// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

/// @title Metasender Protocol a MULTI-TRANSFER proyect
/// @notice A protocol to send bulk of Transaction compatible with ERC20 and ERC721

contract MetaSender is Ownable {

    /**************************************************************/
    /******************** PALCO MEMBERS and FEEs ********************/

    //// @notice PALCO members ( free Transactions )
    mapping(address => bool) public PALCO;

    //// @notice cost per transaction
    uint256 public txFee = 0.0075 ether;

    //// @notice cost to become a PALCO Member
    uint256 public PALCOPass = 0.5 ether;

    /**************************************************************/
    /*************************** EVENTS ***************************/

    /// @param  newPALCOMember address of the new PALCO member
    event NewPALCOMember( address newPALCOMember );

    /// @param  addressToRemove address of a PALCO member
    event RemoveToPALCO( address addressToRemove );

    /// @param  newPALCOPass value of new transaction Fee
    event SetPALCOPass( uint256 newPALCOPass );

    /// @param  newTxFee value of new transaction Fee
    event SetTxFee( uint256 newTxFee );

    /// @param  from address of the user
    /// @param  amount transferred amount
    event LogNativeTokenBulkTransfer( address from, uint256 amount);

    /// @param  contractAddress token contract address
    /// @param  amount transferred amount
    event LogTokenBulkTransfer( address contractAddress, uint amount);

    /// @param  contractAddress token contract address
    /// @param  amount withdraw amount
    event WithDrawIRC20( address contractAddress, uint256 amount );

    /// @param  owner owner address
    /// @param  amount withdrawn value
    event WithdrawTxFee( address owner, uint256 amount );

    constructor() {}

    /**************************************************************/
    /************************ SET AND GET *************************/

    //// @notice returns a boolean
    //// @param _address the address of the required user
    function isOnPALCO( address _address) private view returns (bool) {

        return PALCO[ _address ];

    }

    //// @notice it adds a new PALCO member
    //// @param _address the address of the new PALCO Member
    function addToPALCO( address _address) external payable {

        require(msg.value >= PALCOPass, "Can't add: Value must be equal or superior of current PALCO fee");

        require( !PALCO[_address] , "Can't add: The address is already and PALCO member");

        PALCO[_address] = true;

        emit NewPALCOMember( _address );

    }

    //// @notice it remove a PALCO Member only owner can access
    //// @param _address address of PALCO Member
    function removeToPALCO( address _address) onlyOwner external {

        require( PALCO[_address], "Can't Delete: User not exist");

        delete PALCO[_address];

        emit RemoveToPALCO( _address );
        
    }

    //// @notice change PALCO membership cost
    //// @param _newTxFee the new PALCO membership cost
    function setPALCOPass( uint256 _newPALCOPass ) onlyOwner external  {

        PALCOPass = _newPALCOPass;

        emit SetPALCOPass( _newPALCOPass );
        
    }

    //// @notice change the Transaction cost
    //// @param _newTxFee the new Transaction cost
    function setTxFee( uint256 _newTxFee ) onlyOwner external  {

        txFee = _newTxFee;

        emit SetTxFee( _newTxFee );

    }

    //// @notice returns total value of passed amount array
    //// @param _value a array with transfer amounts
    function getTotalValue(uint256[] memory _value) private pure returns (uint256) {

        uint256 _amount;

        for (uint256 i = 0; i < _value.length; i++) {

            _amount += _value[i];

        }

        require(_amount > 0);

        return _amount;

    }

    //// @notice returns the required transfer Bulk cost
    //// @param _value the initial value
    //// @param _requiredValue value depending of transaction fee
    function getTransactionCost( uint256 _value, uint256 _requiredValue) private view returns(uint256) {

        uint remainingValue = _value;

        if ( isOnPALCO( msg.sender )) require( remainingValue >= _requiredValue, "The value is less than required");

        else {

            require( remainingValue >= _requiredValue + txFee, "The value is less than required");

            remainingValue -= txFee;

        }

        return remainingValue;

    }

    /*************************************************************/
    /*************** MULTI-TRANSFER FUNCTIONS ********************/

    //// @notice ETH MULTI-TRANSFER transactions with same value
    //// @param _to array of receiver addresses
    //// @param _value amount to transfer
    function sendNativeTokenSameValue(address[] memory _to, uint256 _value) external payable{

        require(_to.length <= 255, "Invalid Arguments: Max 255 transactions by batch");

        uint256 totalValue = _to.length * _value;

        uint256 remainingValue = getTransactionCost( msg.value, totalValue );

        for (uint256 i = 0; i < _to.length; i++) {

            remainingValue -= _value;

            require(payable(_to[i]).send(_value), "Transfer failed");

        }

        if (remainingValue > 0) payable(msg.sender).transfer(remainingValue);

        emit LogNativeTokenBulkTransfer( msg.sender, totalValue );

    }

    //// @notice ETH MULTI-TRANSFER transaction with different value
    //// @param _to array of receiver addresses
    //// @param _value array of amounts to transfer
    function sendNativeTokenDifferentValue( address[] memory _to, uint256[] memory _value) external payable {

        require( _to.length == _value.length, "Invalid Arguments: Addresses and values most be equal" );

        require( _to.length <= 255, "Invalid Arguments: Max 255 transactions by batch" );

        uint256 totalValue = getTotalValue( _value );

        uint256 remainingValue = getTransactionCost( msg.value, totalValue );

        for (uint256 i = 0; i < _to.length; i++) {

            remainingValue -= _value[i];

            require( payable(_to[i]).send(_value[i]), "Transfer failed" );

        }

        if (remainingValue > 0) payable(msg.sender).transfer(remainingValue);

        emit LogNativeTokenBulkTransfer( msg.sender, totalValue);
    }

    //// @notice MULTI-TRANSFER ERC20 Tokens with different value
    //// @param _contractAddress Token contract address
    //// @param _to array of receiver addresses
    //// @param _value amount to transfer
    function sendIERC20SameValue( address _contractAddress, address[] memory _to, uint256 _value) payable external{

        require( _to.length <= 255, "Invalid Arguments: Max 255 transactions by batch" );

        getTransactionCost( msg.value, 0);

        IERC20 Token = IERC20(_contractAddress);

        for(uint256 i = 0; i < _to.length; i++){

            require(Token.transferFrom(msg.sender, _to[i], _value), 'Transfer failed');

        }

        emit LogTokenBulkTransfer( _contractAddress, _to.length * _value);

    }

    //// @notice MULTI-TRANSFER ERC20 Tokens with different value
    //// @param _contractAddress Token contract address
    //// @param _to array of receiver addresses
    //// @param _value array of amounts to transfer
    function sendIERC20DifferentValue( address _contractAddress, address[] memory _to, uint256[] memory _value) payable external{

        require( _to.length == _value.length, "Invalid Arguments: Addresses and values most be equal" );

        require( _to.length <= 255, "Invalid Arguments: Max 255 transactions by batch" );

        getTransactionCost( msg.value, 0);

        IERC20 Token = IERC20(_contractAddress);

        for(uint256 i = 0; i < _to.length; i++){

            require(Token.transferFrom(msg.sender, _to[i], _value[i]), 'Transfer failed');

        }

        emit LogTokenBulkTransfer( _contractAddress, getTotalValue(_value));

    }

    //// @notice MULTI-TRANSFER ERC721 Tokens with different value
    //// @param _contractAddress Token contract address
    //// @param _to array of receiver addresses
    //// @param _tokenId array of token Ids to transfer
    function sendIERC721( address _contractAddress, address[] memory _to, uint256[] memory _tokenId) payable external{

        require( _to.length == _tokenId.length, "Invalid Arguments: Addresses and values most be equal" );

        require( _to.length <= 255, "Invalid Arguments: Max 255 transactions by batch" );

        getTransactionCost( msg.value, 0);

        IERC721 Token = IERC721(_contractAddress);

        for(uint256 i = 0; i < _to.length; i++){

            Token.transferFrom(msg.sender, _to[i], _tokenId[i]);
            
        }

        emit LogTokenBulkTransfer( _contractAddress, _tokenId.length );

    }

    /**************************************************************/
    /********************* WITHDRAW FUNCTIONS *********************/

    //// @notice withdraw a ERC20 tokens
    //// @param _address token contract address
    function withDrawIRC20( address _address ) onlyOwner external  {

        IERC20 Token = IERC20( _address );

        uint256 balance = Token.balanceOf(address(this));

        require(balance > 0, "Can't withDraw: insufficient founds");

        Token.transfer(owner(), balance);

        emit WithDrawIRC20( _address, balance );

    } 

    //// @notice withdraw Fees and membership
    //// @dev pass Zero Address if want to withdraw only ETH
    function withdrawTxFee() onlyOwner external{

        uint256 balance = address(this).balance;

        require(balance > 0, "Can't withDraw: insufficient founds");

        payable(owner()).transfer(balance);

        emit WithdrawTxFee( owner(), balance );

    }

}