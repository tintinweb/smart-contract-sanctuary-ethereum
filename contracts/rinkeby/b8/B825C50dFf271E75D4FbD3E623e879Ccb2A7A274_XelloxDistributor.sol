/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

//SPDX-License-Identifier: MIT
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
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}



/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
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

contract XelloxDistributor is Context, ReentrancyGuard, Ownable {
    enum SaleStage {
        NotStart,
        RoundInvestor,
        RoundA,
        RoundB,
        RoundC
    }

    uint256 _initial_setting;
    uint256 public constant INVESTOR_DURATION = 180 days;
    uint256 public constant ROUND_A_DURATION = 365 days;
    uint256 public constant ROUND_B_DURATION = 365 days;
    uint256 public constant PERCENTAGE_FOR_FOUNDERS = 15;
    uint256 public constant PERCENTAGE_FOR_INVESTORS = 20;
    uint256 public constant PERCENTAGE_FOR_ROUND_A = 30;
    uint256 public constant PERCENTAGE_FOR_ROUND_B = 20;
    uint256 public constant PERCENTAGE_FOR_ROUND_C = 10;
    uint256 public constant PERCENTAGE_FOR_EXTRA = 5;
    uint256 public constant PERCENTAGE_FOR_TOTAL = 100;
    uint256 public _investor_price;
    uint256 public _rounda_price;
    uint256 public _roundb_price;
    uint256 public _roundc_price;
    uint256 public _distributedTokenAmount;
    address public _token_address;
    uint256 _sale_start;
    uint256 internal _wei_raised;
    bytes32 public investors_root;
    mapping(address => uint256) public holders;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, uint256 value, uint256 amount);

    function initial_setting (
        address token_address,
        uint256 investor_price,
        uint256 rounda_price,
        uint256 roundb_price,
        uint256 roundc_price,
        uint256 sale_start
    ) public onlyOwner {
        require(_initial_setting == 0, "Xellox Distributor: Already setted");
        require(_token_address != address(0), "Xellox Distributor: Token is Zero Address");
        _token_address = address(token_address);
        _investor_price = investor_price;
        _rounda_price = rounda_price;
        _roundb_price = roundb_price;
        _roundc_price = roundc_price;
        _sale_start = sale_start;
        _distributedTokenAmount = IERC20(_token_address).totalSupply() * PERCENTAGE_FOR_FOUNDERS / PERCENTAGE_FOR_TOTAL; // For 3 founders
        _initial_setting = 1;
    }

    function getTokenPrice() public view returns (uint256 price) {
        if(block.timestamp < _sale_start)
            return 0;
        else if((block.timestamp >= _sale_start) && (block.timestamp < (_sale_start + INVESTOR_DURATION)))
            return _investor_price;
        else if((block.timestamp >= (_sale_start + INVESTOR_DURATION)) && (block.timestamp < (_sale_start + INVESTOR_DURATION + ROUND_A_DURATION)))
            return _rounda_price;
        else if((block.timestamp >= (_sale_start + INVESTOR_DURATION + ROUND_A_DURATION)) && (block.timestamp < (_sale_start + INVESTOR_DURATION + ROUND_A_DURATION + ROUND_B_DURATION)))
            return _roundb_price;
        else if(block.timestamp >= (_sale_start + INVESTOR_DURATION + ROUND_A_DURATION + ROUND_B_DURATION))
            return _roundc_price;
    }

    function getSaleStage() public view returns (SaleStage stage) {
        if(block.timestamp < _sale_start)
            return SaleStage.NotStart;
        else if((block.timestamp >= _sale_start) && (block.timestamp < (_sale_start + INVESTOR_DURATION)))
            return SaleStage.RoundInvestor;
        else if((block.timestamp >= (_sale_start + INVESTOR_DURATION)) && (block.timestamp < (_sale_start + INVESTOR_DURATION + ROUND_A_DURATION)))
            return SaleStage.RoundA;
        else if((block.timestamp >= (_sale_start + INVESTOR_DURATION + ROUND_A_DURATION)) && (block.timestamp < (_sale_start + INVESTOR_DURATION + ROUND_A_DURATION + ROUND_B_DURATION)))
            return SaleStage.RoundB;
        else if(block.timestamp >= (_sale_start + INVESTOR_DURATION + ROUND_A_DURATION + ROUND_B_DURATION))
            return SaleStage.RoundC;
    }

    function getLimitPercentage() public view returns (uint256 limit) {
       if(block.timestamp < _sale_start)
            return PERCENTAGE_FOR_FOUNDERS;
        else if((block.timestamp >= _sale_start) && (block.timestamp < (_sale_start + INVESTOR_DURATION)))
            return PERCENTAGE_FOR_FOUNDERS + PERCENTAGE_FOR_INVESTORS;
        else if((block.timestamp >= (_sale_start + INVESTOR_DURATION)) && (block.timestamp < (_sale_start + INVESTOR_DURATION + ROUND_A_DURATION)))
            return PERCENTAGE_FOR_FOUNDERS + PERCENTAGE_FOR_INVESTORS + PERCENTAGE_FOR_ROUND_A;
        else if((block.timestamp >= (_sale_start + INVESTOR_DURATION + ROUND_A_DURATION)) && (block.timestamp < (_sale_start + INVESTOR_DURATION + ROUND_A_DURATION + ROUND_B_DURATION)))
            return PERCENTAGE_FOR_FOUNDERS + PERCENTAGE_FOR_INVESTORS + PERCENTAGE_FOR_ROUND_A + PERCENTAGE_FOR_ROUND_B;
        else if(block.timestamp >= (_sale_start + INVESTOR_DURATION + ROUND_A_DURATION + ROUND_B_DURATION))
            return PERCENTAGE_FOR_FOUNDERS + PERCENTAGE_FOR_INVESTORS + PERCENTAGE_FOR_ROUND_A + PERCENTAGE_FOR_ROUND_B + PERCENTAGE_FOR_ROUND_C;
    }

    /**
     * Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send tokens.
     * @param _proof Address receiving the tokens
     */
    function buyTokens(bytes32[] calldata _proof) public nonReentrant payable {
        uint256 wei_amount = msg.value;
        address buyer_addr = msg.sender;

        _preValidatePurchase(buyer_addr, wei_amount, _proof);
        // Calculate token amount to be created
        uint256 token_amount = _getTokenAmount(wei_amount);

        _validatePurchase(buyer_addr, token_amount);
        // Update wei state
         _wei_raised = _wei_raised + wei_amount;
        _processPurchase(buyer_addr, token_amount);

        emit TokensPurchased(buyer_addr, wei_amount, token_amount);

        holders[buyer_addr] = holders[buyer_addr] + token_amount;
        _distributedTokenAmount = _distributedTokenAmount + token_amount;
        // _updatePurchasingState(tokens);
        // _postValidatePurchase(beneficiary, weiAmount);
    }

    function _preValidatePurchase(address buyer_addr, uint256 wei_amount, bytes32[] calldata _proof) internal view {
        require(buyer_addr != address(0), "Xellox Distributor: buyer is the zero address");
        require(wei_amount != 0, "Xellox Distributor: wei amount is 0");
        if(getSaleStage() == SaleStage.RoundInvestor) {
            require(MerkleProof.verify(_proof, investors_root, keccak256(abi.encodePacked(msg.sender))), "Xellox Distributor: Address does not exist in investors list");
        }
        this;
    }

    function _getTokenAmount(uint256 wei_amount) internal view returns (uint256) {
        uint256 current_price = getTokenPrice();
        return wei_amount / current_price;
    }

    function _validatePurchase(address buyer_addr, uint256 token_amount) internal view {
        require(!Address.isContract(buyer_addr), "Xellox Distributor: Buyer must be wallet");
        require(token_amount <= IERC20(_token_address).balanceOf(address(this)), "Xellox Distributor: Not enough Xellox Tokens on the contract for purchasing");
        require(isPurchasable(token_amount), "Xellox Distributor: Purchasing amount exceeds the limit of current round");
        this;
    }

    function isInvestor(address buyer_address, bytes32[] calldata _proof) public view returns (bool flag) {
        return MerkleProof.verify(_proof, investors_root, keccak256(abi.encodePacked(buyer_address)));
    }

    function isPurchasable(uint256 token_amount) public view returns (bool flag) {
        uint256 token_total_supply = IERC20(_token_address).totalSupply();
        if (((_distributedTokenAmount + token_amount) / token_total_supply * 100) > getLimitPercentage()) {
            return false;
        }
        return true;
    }

    /**
     * @param buyer_addr Address performing the token purchase
     * @param token_amount Number of tokens to be emitted
     */
    function _deliverTokens(address buyer_addr, uint256 token_amount) internal {
        IERC20(_token_address).transfer(buyer_addr, token_amount);
    }

    /**
     * Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send tokens.
     * @param buyer_addr Address receiving the tokens
     * @param token_amount Number of tokens to be purchased
     */
    function _processPurchase(address buyer_addr, uint256 token_amount) internal {
        _deliverTokens(buyer_addr, token_amount);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Xellox Distributor: No funds to withdraw");
        uint256 contract_balance = address(this).balance;
        _withdraw(msg.sender, contract_balance);
    }
}