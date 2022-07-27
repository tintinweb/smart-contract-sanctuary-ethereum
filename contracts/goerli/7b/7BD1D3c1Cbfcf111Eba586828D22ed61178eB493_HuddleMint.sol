// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

//Import of the interfaces 
import "IERC20.sol";
import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Enumerable.sol";

//Import of Contract for use of the internal functions
import "ERC721Holder.sol";
import "ERC165.sol";

import "Strings.sol";


import "HuddleCore.sol";

contract HuddleMint is IERC721Receiver, ERC165, ERC721Holder, HuddleCore {

    mapping (address => bool) private _addedContract;
    mapping (address => string) public _contractMethod;

    constructor(address feeWallet, address WETH, address _uniswapRouter) HuddleCore(feeWallet, WETH, _uniswapRouter) {}

    /*
        Adds the method that will be used for this contract
        Input
            - NFT Contract Address (address)
            - Method Name (string)
    */
    function _addContractMethod(address _contractAddress, string  calldata _methodName) external onlyOwner{
        require(_contractAddress != address(0), "Cannot be Null Address");
        _contractMethod[_contractAddress] = _methodName;
        _addedContract[_contractAddress] = true;
    }

    /*
        Removes the method that was used for this contract
        Input
            - NFT Contract Address (address)
            - Method Name (string)
    */
    function _removeContractMethod(address _contractAddress) external onlyOwner{
        require(_contractAddress != address(0), "Cannot be Null Address");
        _contractMethod[_contractAddress] = "";
        _addedContract[_contractAddress] = false;
    }


    /*
        Mass mints token for several users
        Input
            _contractAddress - NFT Contract Address (address)
            _mintPrice - Prices of minting for this given Contract Address(uint256)
            _minter - Array of address of the User (address [])
            _data - Enconded Data Array for the Method (bytes[])
            _quantity - Quantity of Tokens that will be minted per user (uint[])
    */
    function huddleUserMint(address _contractAddress, uint256 _mintPrice ,address[] calldata _minter, uint[] calldata _quantity , bytes[] calldata _data) external onlyOwner{

        require(_addedContract[_contractAddress], "This Contract is not registed in the System");

        uint256 _totalFee;
        bool[] memory successTransfer;
        successTransfer = new bool[](_minter.length);

        //Transfer Tokens and Unwrap Weth to pay for the Token Mint
        (successTransfer,_totalFee) = _transferPayment(_minter,_mintPrice);

        uint i;
        //Mint the NFT 
        for(i = 0 ; i < _minter.length; i++){
            if(successTransfer[i])  _executeMint(_contractAddress, _minter[i], _data[i], _mintPrice, _quantity[i]);
        }        

        delete successTransfer;
        delete i;

        if(_totalFee != 0) _sendFee();

        delete _totalFee;
    }


    /*
        Mass mints token for several users
        Input
            _minter - Array of address of the User (address [])
            _totalAmount - Value of the total amount of Mint Price + Fee Value(uint256)
            _contractAddress - NFT Contract Address Array (address[])
            _data - Enconded Data Array for the Method (bytes[])
            _quantity - Quantity of Tokens that will be minted per user (uint[])
    */

    function huddleTokenMint(address _minter,uint256 totalAmount, uint256[] calldata _mintPrice ,address[] calldata _contractAddress, uint[] calldata _quantity , bytes[] calldata _data) external onlyOwner{

        //require(_addedContract[_contractAddress], "This Contract is not registed in the System");
        uint256 _fee;

        //Transfer Tokens and Unwrap Weth to pay for the Token Mint
        _fee =  0; //todo johnny, before -> huddleCore.getChargedFee(address(this), _minter, totalAmount);
        require(transferTokenFrom(WETH, _minter, address(this), totalAmount), "Token Transfer Failed");

        uint i;
        //Mint the NFT
        for(i = 0 ; i < _contractAddress.length; i++){
           _executeMint(_contractAddress[i], _minter, _data[i], _mintPrice[i], _quantity[i]);
        }
        delete i;

        if(_fee != 0) _sendFee();

        delete _fee;
    }

    /*
        Transfer the WETH token from the User and then Unwraps it to Eth to execute the payment of the MINT

        Input
            _minter - Array with the address of the users (address[])
            _mintPrice - Cost of the Mint (uint256)
    
    */
    function _transferPayment(address[] calldata _minter, uint256 _mintPrice) private returns(bool[] memory, uint256){
        uint i;
        uint256 _totalAmount;
        uint256 _totalFee;
        uint256 _fee;
        bool[] memory successTransfer;
        successTransfer = new bool[](_minter.length);
        
        //Transfer the WETH from the Minter so that we can Mint the NFT     
        for(i= 0 ; i < _minter.length; i++){
            _fee =  0; //todo johnny -> huddleCore.getChargedFee(address(this), _minter[i],_mintPrice);
            successTransfer[i] = transferTokenFrom(WETH, _minter[i], address(this), _mintPrice + _fee);
            if(successTransfer[i]){
                _totalFee = (_totalFee + _fee);
                _totalAmount = _totalAmount + _mintPrice ;
            }
            delete _fee;   
        }
        //Unwrap WETH to obtain the ETH necessary for the MINT
        withdrawWETH(_totalAmount);

        //Delete variables to save gas after they are used
        delete _fee;
        delete _totalAmount;
        delete i;

        return (successTransfer, _totalFee);
        
    }

    /*
        Executes the Mint and in case it fails returns the price of the Mint back to the user
        if the executions succeds it sends the nft to the user

        Input
            _contractAddress - Address of the contract that will minted from (address)
            _minter - Address of the Wallet of the user which we will mint for (address)
            _data - Byte data with the necessary information to execute the function (bytes)
            _mintPrice - Price of the Mint for the token (uint256)
            _quantity - Amount of token that will be minted (uint)
    */
    function _executeMint(address _contractAddress, address _minter, bytes calldata _data, uint256 _mintPrice, uint _quantity  ) private {
        if(!_contractMint(_contractAddress, _data, _mintPrice)){
            transferTokenFrom(WETH, address(this) ,_minter, _mintPrice);
            emit LogString("NFT Failed to Mint");
        } else{
            _nftTransfer(_contractAddress,address(this),_minter,_quantity);
        }
    }

    /*
        Mints for only one user
        Input
        _contractAddress - NFT Contract Address (address)
        _data - Enconded Data Array for the Method (bytes[])
        _mintPrice - Cost of the Mint without the gas fees (uint256) 
    */
    function _contractMint(address _contractAddress, bytes calldata _data, uint256 _mintPrice) private returns (bool){
        (bool success, bytes memory result) = _contractAddress.call{value: _mintPrice}(_selectorEncoder(_contractAddress,_data));
        return success;
    }

    /*
        This functions concatenates the necessary information for the dynamic calling of a contract
        Input
            _contractAddress - NFT Contract Address (address)
            _data - Enconded Data Array for the Method (bytes)

        NOTE
        For ideal performance please use the functions web3.eth.abi.encodeParameters
        to encode the _data parameter
    */
    function _selectorEncoder(address _contractAddress, bytes calldata _data) private view returns(bytes memory){
        return bytes.concat(abi.encodeWithSelector(bytes4(keccak256(bytes(_contractMethod[_contractAddress])))),_data);
        
    }

    /*
        This functions call a method to obtain the token ID necessary for the transfer
        Input
            _contractAddr - Enconded Data Array from the Contract Call (bytes)
            _index - Value to confirm in the Balance of the Token Array (uint256)
    */
    function _obtainTokenID(address _contractAddr,uint256 _index) public returns (uint256){
        try IERC721Enumerable(_contractAddr).tokenOfOwnerByIndex(address(this), _index) returns (uint256 tokenID)
        { 
          return tokenID;
        }catch{
          emit LogString("Failed to Obtain TokenID");
          return 0;
        }
    }

    /*
    */
    function _nftTransfer(address _contractAddr, address _from, address _to, uint256 _quantity) private {
        for(;_quantity > 0; _quantity--){

            try IERC721(_contractAddr).transferFrom(address(this), _to, _obtainTokenID(_contractAddr, _quantity -1)){

            }catch Error(string memory reason){
                emit LogString(reason);
            }
            catch {
                emit LogString("NFT Transfer Fail");
            }
        }
    }


    /*
        Sends the fee back to the Wallet defined in the Huddle Core
    */
    function _sendFee() private{
        payable(feeWallet).transfer(address(this).balance);
    }   

}

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "HuddleLib.sol";
import "IUniswapV2Router02.sol";


contract HuddleCore is HuddleLib {

    address internal  feeWallet;
    IUniswapV2Router02 internal uniswapRouter;

    struct Order {
        uint256 amount;
        uint256 fee;
        uint256 gasCost;
    }


    constructor (address feeWalletAddress, address WETH, address UNISWAP_ROUTER) HuddleLib(WETH) {
        feeWallet = feeWalletAddress;
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER);
    }


    /*
        Send fee or exchange based on the input token
    */
    function feePayment(address _tokenIn, uint256 _totalFee, bool _isSafeToken) internal {
         if (_totalFee > 0){
            if (_tokenIn == WETH) {
                sendWETHFee();
            } else {
                if(_isSafeToken) transfer(_tokenIn, feeWallet, _totalFee);
                else sendUnsafeFee(_tokenIn, _totalFee);
            }
        }
    }


    /*
        Send WETH Fee to input wallet
    */
    function sendWETHFee() internal {
        withdrawWETH(IWETH.balanceOf(address(this)));
        payable(feeWallet).transfer(address(this).balance);
    }


    /*
        Swap Unsafe Token to Eth and Send to Wallet
    */
    function sendUnsafeFee(address _tokenIn, uint256 _totalFee) internal{
        approval(_tokenIn, _totalFee, address(uniswapRouter));
        address[] memory path = new address[](2);

        path[0] = _tokenIn;
        path[1] = WETH;

        try uniswapRouter.swapExactTokensForETH(
            _totalFee,
            0,
            path,
            feeWallet,
            block.timestamp
        )returns (uint256[] memory _returnAmounts)
        {
           emit SuccessfulTransfer(address(0), address(this), feeWallet, _returnAmounts[1]);
        } catch Error(string memory reason){
            emit FailedTransfer(address(0), address(this), feeWallet, 0);
        } catch{
            emit FailedTransfer(address(0), address(this), feeWallet, 0);
        }
    }


    /*
      Updates the address of the fee pay wallet
        Input
          newPayWallet - Address of the new wallet for
    */
    function updateFeeWallet(address newFeeWallet) public onlyOwner {
        feeWallet = newFeeWallet;
    }


    /*
      Returns the sum of all of the elements of an order
      Input
      _order - Order Structure
    */
    function totalOrderValue(Order calldata _order) internal pure returns (uint256){
        return _order.amount + _order.fee + _order.gasCost;
    }


    /*
      Returns the sum of all of the GasCost and Fee elements of an Order
      Input
      _order - Order Structure
    */
    function sumOfGasAndFee(Order calldata _order) internal pure returns (uint256){
        return _order.fee + _order.gasCost;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


//import the ERC20 interface

import "IERC20Metadata.sol";
import "IWETH9.sol";
import "Ownable.sol";


contract HuddleLib is Ownable {

    event LogString(string);

    // Transfer Event
    event SuccessfulTransfer(address token, address from, address to, uint256 amount);
    event FailedTransfer(address token, address from, address to, uint256 amount);

    // Approval Event
    event SuccessfulApproval(address token, address from, address spender, uint256 amount);
    event FailedApproval(address token, address from, address spender, uint256 amount);

    // Withdraw Event
    event SuccessfulWETHWithdraw(uint256 amount);
    event FailedWETHWithdraw(uint256 amount);

    // Swap Event
    event SuccessfulSwap(address path0, address path1, uint256 amount);
    event FailedSwap(address path0, address path1, uint256 amount);

    // Donation Event
    event ReceivedDonation(address from, uint256 amount);

    address internal WETH;
    IWETH9 internal IWETH;

    constructor (address _WETH) {
        WETH = _WETH;
        IWETH = IWETH9(_WETH);
    }


    /*
    Create a approval so that the destination is able to use the token.
    Input
        _tokenIn - Address of token to be sent (address)
        _amount - Amount to Transfer (uint256)   
        _approveTo - Address where the token will be sent (address)
    */
    function approval(address _tokenIn, uint256 _amount, address _approveTo) internal returns (bool) {
        try IERC20(_tokenIn).approve(_approveTo, _amount) {
            emit SuccessfulApproval(_tokenIn, address(this), _approveTo, _amount);
            return true;
        } catch {
            emit FailedApproval(_tokenIn, address(this), _approveTo, _amount);
        }
        return false;
    }


    /*
    Allow for the transfer of Tokens the current address to another
    Input
        _recipient - Address where the token will be sent (address)
        _amount - Amount to Transfer (uint256)   
        _tokenAddress - Address of token to be sent (address)
    */
    function transfer(address _tokenAddress, address _to, uint256 _amount) internal returns (bool) {
        try IERC20(_tokenAddress).transfer(_to, _amount){
            emit SuccessfulTransfer(_tokenAddress, address(this), _to, _amount);
            return true;
        } catch {
            emit FailedTransfer(_tokenAddress, address(this), _to, _amount);
        }
        return false;
    }


    /*
    Allow for the transfer of Tokens from one location to another
    Input
        _tokenAddress - Address of token to be sent (address)
        _from - Address from where the transfer originates (address)
        _to - Address where the token will be sent (address)
        _amount - Amount to Transfer (uint256)   
    */
    function transferTokenFrom(address _tokenAddress, address _from, address _to, uint256 _amount) internal returns (bool){// todo discuss low level call (lower gas) or instantiating the IERC20 interface only once

        try IERC20(_tokenAddress).transferFrom(_from, _to, _amount){
            emit SuccessfulTransfer(_tokenAddress, _from, _to, _amount);
            return true;
        }
        catch {
            emit FailedTransfer(_tokenAddress, _from, _to, _amount);
        }
        return false;
    }


    /*
    This function withdraws WETH and converts it to ETH to adequatly use in the in the payable Mint Function
    The reason for this is that multiples transfer cannot be requested from a waller without using a ERC20 Token
    Input
     -NULL
    */
    function withdrawWETH(uint256 amount) internal {
        if (amount > 0) {
            try IWETH.withdraw(amount) {
                emit SuccessfulWETHWithdraw(amount);
            } catch {
                emit FailedWETHWithdraw(amount);
            }
        }
    }

    function withdrawLockedFunds(address token, uint256 amount, address to) public onlyOwner {
        if (token == address(0)) { // Assuming address 0 for ETH balance
            if (amount == 0) { // Assuming amount 0 for all balance
                payable(to).transfer(address(this).balance);
            } else {
                payable(to).transfer(amount);
            }
        } else {
            if (amount == 0) {
                IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
            } else {
                IERC20(token).transfer(to, amount);
            }
        }
    }

    receive() external payable {
        emit ReceivedDonation(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


import "IERC20.sol";

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


interface IWETH9 {

    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

pragma solidity ^0.8.3;


interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);


    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline) external view returns (uint[] memory amounts);


}