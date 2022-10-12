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
pragma solidity ^0.8.4;

// we need some information from token contract
// we also need ability to transfer tokens from/to this contract
interface IERC20Fixed {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract SignatureVerify {
    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../utils/signatures/SignatureVerify.sol";
import "../../utils/interfaces/IERC20Fixed.sol";
import "../UniqOperator/IUniqOperator.sol";

contract UniqRedeemPayment is Ownable, SignatureVerify {
    // ----- EVENTS ----- //

    event RedeemedRequested(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _redeemerAddress,
        uint256 _networkId,
        string _redeemerName,
        uint256 _purpose
    );

    // ----- VARIABLES ----- //
    mapping(bytes => bool) internal _isSignatureUsed;
    uint256 internal _transactionOffset;
    uint256 internal _networkId;
    IUniqOperator public operator;
    uint256 internal constant TREASURY_INDEX = 0;

    // ----- CONSTRUCTOR ----- //
    constructor(uint256 _pnetworkId, IUniqOperator uniqOperator) {
        _transactionOffset = 3 minutes;
        _networkId = _pnetworkId;
        operator = uniqOperator;
    }

    // ----- MESSAGE SIGNATURE ----- //
    function getMessageHashRequester(
        address _contractAddress,
        uint256 _redeemNetworkId,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _tokenId,
        uint256 _price,
        address _paymentTokenAddress,
        uint256 _timestamp,
        address _requesterAddress,
        string memory _redeemerName,
        uint256 _purpose
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _networkId,
                    _contractAddress,
                    _redeemNetworkId,
                    _sellerAddress,
                    _percentageForSeller,
                    _tokenId,
                    _price,
                    _paymentTokenAddress,
                    _timestamp,
                    _requesterAddress,
                    _redeemerName,
                    _purpose
                )
            );
    }

    function verifySignatureRequester(
        address _contractAddress,
        uint256 _redeemNetworkId,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _tokenId,
        uint256 _price,
        address _paymnetTokenAddress,
        uint256 _timestamp,
        string memory _redeemerName,
        uint256 _purpose,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHashRequester(
            _contractAddress,
            _redeemNetworkId,
            _sellerAddress,
            _percentageForSeller,
            _tokenId,
            _price,
            _paymnetTokenAddress,
            _timestamp,
            msg.sender,
            _redeemerName,
            _purpose
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    // ----- PUBLIC METHODS ----- //
    function requestRedeem(
        address _contractAddress,
        uint256 _redeemNetworkId,
        address _sellerAddress,
        uint256 _percentageForSeller,
        uint256 _tokenId,
        uint256 _price,
        address _paymnetTokenAddress,
        uint256 _timestamp,
        address _requesterAddress,
        string memory _redeemerName,
        uint256 _purpose,
        bytes memory _signature
    ) external payable {
        require(
            _timestamp + _transactionOffset >= block.timestamp,
            "Transaction timed out"
        );
        require(!_isSignatureUsed[_signature], "Signature already used");
        require(
            verifySignatureRequester(
                _contractAddress,
                _redeemNetworkId,
                _sellerAddress,
                _percentageForSeller,
                _tokenId,
                _price,
                _paymnetTokenAddress,
                _timestamp,
                _redeemerName,
                _purpose,
                _signature
            ),
            "Signature mismatch"
        );
        _isSignatureUsed[_signature] = true;
        uint256 sellerFee = (_price * _percentageForSeller) / 100;
        if (_price != 0) {
            address treasury = operator.uniqAddresses(TREASURY_INDEX);
            if (_paymnetTokenAddress == address(0)) {
                require(msg.value >= _price, "Not enough ether");
                if (_price < msg.value) {
                    payable(msg.sender).transfer(msg.value - _price);
                }
                payable(_sellerAddress).transfer(sellerFee);
                payable(treasury).transfer(_price - sellerFee);
            } else {
                IERC20Fixed(_paymnetTokenAddress).transferFrom(
                    msg.sender,
                    _sellerAddress,
                    sellerFee
                );
                IERC20Fixed(_paymnetTokenAddress).transferFrom(
                    msg.sender,
                    treasury,
                    _price - sellerFee
                );
            }
        }
        emit RedeemedRequested(
            _contractAddress,
            _tokenId,
            _requesterAddress,
            _networkId,
            _redeemerName,
            _purpose
        );
    }

    // ----- OWNERS METHODS ----- //

    function withdrawTokens(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val != 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        IERC20Fixed(token).transfer(msg.sender, val);
    }

    function setTransactionOffset(uint256 _newOffset) external onlyOwner {
        _transactionOffset = _newOffset;
    }

    receive() external payable {}

    function wthdrawETH() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IUniqOperator {
    function isOperator(uint256 operatorType, address operatorAddress)
        external
        view
        returns (bool);

    function uniqAddresses(uint256 index) external view returns (address);
}