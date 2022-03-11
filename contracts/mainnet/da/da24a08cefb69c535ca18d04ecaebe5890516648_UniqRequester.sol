// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SignatureVerify.sol";
import "../../utils/uniq/Ierc20.sol";

contract UniqRequester is Ownable, SignatureVerify {
    // ----- EVENTS ----- //
    event TokensRequested(address indexed _requester, address indexed _mintAddress, uint256[] _tokenIds, uint256 _bundleId); 


    // ----- VARIABLES ----- //
    uint256 internal _transactionOffset;
    mapping(address => mapping(uint256 => bool)) internal _tokenAlreadyRequested;

    // ----- CONSTRUCTOR ----- //
    constructor() {
        _transactionOffset = 3 minutes;
    }

    // ----- MESSAGE SIGNATURE ----- //
    function getMessageHash(
        address _mintContractAddress,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymnetTokenAddress,
        uint256 _timestamp,
        address _requesterAddress
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_mintContractAddress,_bundleId,_tokenIds, _price, _paymnetTokenAddress, _timestamp, _requesterAddress)
            );
    }

    function verifySignature(
        address _mintContractAddress,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(
            _mintContractAddress,
            _bundleId,
            _tokenIds,
            _price,
            _paymentTokenAddress,
            _timestamp,
            msg.sender
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    // ----- PUBLIC METHODS ----- //
    function requestTokens(
        address _mintContractAddress,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _priceForPackage,
        address _paymentToken,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable {
        require(_timestamp + _transactionOffset >= block.timestamp, "Transaction timed out");
        require(
            verifySignature(
                _mintContractAddress, 
                _bundleId,
                _tokenIds,
                _priceForPackage,
                _paymentToken,
                _signature,
                _timestamp
            ),
            "Signature mismatch"
        );
        for(uint256 i=0; i<_tokenIds.length; i++){
            require(!_tokenAlreadyRequested[_mintContractAddress][_tokenIds[i]], "Token already requested in this network");
            _tokenAlreadyRequested[_mintContractAddress][_tokenIds[i]] = true;
        }
        if (_priceForPackage != 0) {
            if (_paymentToken == address(0)) {
                require(msg.value >= _priceForPackage, "Not enough ether");
                if (_priceForPackage < msg.value) {
                    payable(msg.sender).transfer(msg.value - _priceForPackage);
                }
            } else {
                require(
                    IERC20(_paymentToken).transferFrom(
                        msg.sender,
                        address(this),
                        _priceForPackage
                    )
                );
            }
        }
        emit TokensRequested(msg.sender, _mintContractAddress, _tokenIds, _bundleId);
    }

    receive() external payable {}

    // ----- OWNERS METHODS ----- //

    function withdrawTokens(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        Ierc20(token).transfer(owner(), val);
    }

    function setTransactionOffset(uint256 _newOffset) external onlyOwner{
        _transactionOffset = _newOffset;
    }

    function withdrawETH() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract SignatureVerify{

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
pragma solidity ^0.8.4;

// we need some information from token contract
// we also need ability to transfer tokens from/to this contract
interface Ierc20 {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
    function transferFrom(
        address sender,
        address recipient,
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
}