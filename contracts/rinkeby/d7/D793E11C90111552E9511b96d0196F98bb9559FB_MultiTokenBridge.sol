// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.12;
pragma abicoder v2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBridgeVault.sol";
import "./TransferHelper.sol";

contract MultiTokenBridge is Ownable, ReentrancyGuard {
    uint256 public chainId;
    address public governance;
    address public verifier;
    address public vault;
    address public treasury;

    event ERC20Transfer(
        address _token,
        address _to,
        uint256 _howmuch,
        uint256 _when
    );
    event ETHTransfer(address _to, uint256 _howmuch, uint256 _when);
    event TreasuryUpdated(address _old, address _new, uint256 _when);

    mapping(address => address) public supportedTokens;
    mapping(address => uint256) public depositFee;
    mapping(address => uint256) public withdrawalFee;

    constructor(
        address _verifier,
        address _governance,
        address _vault
    ) {
        chainId = block.chainid;
        verifier = _verifier;
        governance = _governance;
        vault = _vault;
    }

    event BridgeFeeUpdated(
        address _token,
        uint256 _oldDepositFee,
        uint256 _oldWithdrawFee,
        uint256 _newDepositFee,
        uint256 _newWithdrawFee
    );
    event Deposited(
        address account,
        uint256 amount,
        uint256 chainId,
        uint256 nonce,
        address sourceToken,
        address targetToken
    );
    event Withdrawal(
        address account,
        uint256 amount,
        uint256 nonce,
        bytes32 txHash,
        uint256 chainId,
        address token
    );
    event VerifierChanged(
        address _oldVerifier,
        address _newVerifier,
        uint256 _when
    );
    event GovernanceChanged(
        address _oldGovernance,
        address _newGovernance,
        uint256 _when
    );

    // deposit index of other chain  => withdrawal in current chain
    mapping(uint256 => bool) public claimedWithdrawalsByOtherChainDepositId;

    // deposit nonce for current chain
    uint256 public txNonce;

    modifier onlyGovernance() {
        require(governance == msg.sender, "Bridge:: Unauthorized Access");
        _;
    }

    function withdrawERC20(address _token, address _to)
        external
        onlyGovernance
    {
        uint256 _total = IERC20(_token).balanceOf(address(this));
        TransferHelper.safeTransfer(_token, _to, _total);
        emit ERC20Transfer(_token, _to, _total, block.timestamp);
    }

    function withdrawETH(address _to) external onlyGovernance {
        uint256 _total = address(this).balance;
        TransferHelper.safeTransferETH(_to, _total);
        emit ETHTransfer(_to, _total, block.timestamp);
    }

    function updateTreasury(address _newTreasury) external onlyGovernance {
        require(
            _newTreasury != address(0),
            "MasterBridge :: updateTreasury :: Invalid address"
        );
        emit TreasuryUpdated(treasury, _newTreasury, block.timestamp);
        treasury = _newTreasury;
    }

    function updateERC20Tokens(address _newToken, address _pairedToken)
        external
        onlyGovernance
    {
        require(
            supportedTokens[_newToken] != address(0),
            "Something Already Exisit"
        );
        supportedTokens[_newToken] = _pairedToken;
    }

    function updateGovernance(address _newGovernance) external onlyGovernance {
        require(
            _newGovernance != address(0),
            "Bridge :: updateGovernance :: Invalid _newGovernance"
        );
        emit GovernanceChanged(governance, _newGovernance, block.timestamp);
        governance = _newGovernance;
    }

    function updateVerifier(address _newVerifierAddress)
        external
        onlyGovernance
    {
        require(
            _newVerifierAddress != address(0),
            "Bridge :: setVerifyAddress :: Invalid _newVerifierAddress"
        );
        emit VerifierChanged(verifier, _newVerifierAddress, block.timestamp);
        verifier = _newVerifierAddress;
    }

    function updateBridgeFee(
        address _depositToken,
        uint256 _newDepositFee,
        uint256 _newWithdrawFee
    ) external onlyGovernance {
        emit BridgeFeeUpdated(
            _depositToken,
            depositFee[_depositToken],
            _newDepositFee,
            withdrawalFee[_depositToken],
            _newWithdrawFee
        );
        depositFee[_depositToken] = _newDepositFee;
        withdrawalFee[_depositToken] = _newWithdrawFee;
    }

    function deposit(address _token, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Bridge:: deposit:: Invalid _amount");
        txNonce = txNonce + 1;
        TransferHelper.safeTransferFrom(_token, msg.sender, vault, _amount);
        if (depositFee[_token] > 0) transferFee(_token, depositFee[_token]);
        emit Deposited(
            msg.sender,
            _amount,
            chainId,
            txNonce,
            _token,
            supportedTokens[_token]
        );
    }

    function transferFee(address _token, uint256 _fee) internal {
        TransferHelper.safeTransferFrom(_token, msg.sender, treasury, _fee);
    }

    // _data is an array of 3 items
    // _data[0] is amount
    // _data[1] is chainID
    // _data[2] is nonce
    // _data[3] is _v
    // _data[4] is tokenContract to release
    // _hashData
    // _hashData[0] is _txHash
    // _hashData[1] is _r
    // _hashData[2] is _s

    function withdraw(uint256[5] calldata _data, bytes32[3] calldata _hashData)
        external
        nonReentrant
    {
        require(chainId == _data[1], "Bridge:: Withdraw :: Invalid _chainId");
        require(
            !claimedWithdrawalsByOtherChainDepositId[_data[2]],
            "Bridge:: Withdraw :: Already Withdrawn!"
        );
        claimedWithdrawalsByOtherChainDepositId[_data[2]] = true;
        bytes32 messageHash = generateMessage(
            address(uint160(_data[4])),
            msg.sender,
            _data[0],
            _data[1],
            _data[2],
            _hashData[0],
            address(this)
        );
        require(
            recoverSigner(
                getEthSignedMessageHash(messageHash),
                uint8(_data[3]),
                _hashData[1],
                _hashData[2]
            ) == verifier,
            "Bridge:: Withdraw :: Invalid Signature"
        );
        if (withdrawalFee[address(uint160(_data[4]))] > 0)
            transferFee(
                address(uint160(_data[4])),
                withdrawalFee[address(uint160(_data[4]))]
            );
        IBridgeVault(vault).bridgeWithdrawal(
            address(uint160(_data[4])),
            msg.sender,
            _data[0]
        );
        emit Withdrawal(
            msg.sender,
            _data[0],
            _data[2],
            _hashData[0],
            chainId,
            address(uint160(_data[4]))
        );
    }

    function generateMessage(
        address _token,
        address _account,
        uint256 _amount,
        uint256 _chainId,
        uint256 _nonce,
        bytes32 _txHash,
        address _bridgeAddress
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _token,
                    _account,
                    _amount,
                    _chainId,
                    _nonce,
                    _txHash,
                    _bridgeAddress
                )
            );
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
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
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        return ecrecover(_ethSignedMessageHash, v, r, s);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.12;

interface IBridgeVault {
    function bridgeWithdrawal(address token, address to, uint256 amount) external returns (address);
}