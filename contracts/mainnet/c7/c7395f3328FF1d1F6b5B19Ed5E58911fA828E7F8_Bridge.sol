// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/Upgradeable.sol";

contract Bridge is Upgradeable {
    using SignatureUtils for TransferData;

    constructor(address _proxy) Upgradeable(_proxy) {}

    /**
     * @dev To approve or revoke a token from acceptance list
     * @param _tokenAddress the token address
     * @param _value true/false
     */
    function setTokenApproval(address _tokenAddress, bool _value)
        public
        onlyOwner
    {
        isApprovedToken[_tokenAddress] = _value;
    }

    /**
     * @dev To approve or revoke a signer from list
     * @param _newSigner the address of new signer
     */
    function setSigner(address _newSigner) public onlyOwner {
        require(_newSigner != address(0), "Bridge: signer is zero address");
        require(
            _newSigner != signer,
            "Bridge: cannot transfer to current signer"
        );
        signer = _newSigner;
        emit SetSignerEvent(_newSigner);
    }

    /**
     * @dev To add or remove an account from blacklist
     * @param _account the address of account
     * @param _value true/false
     */
    function setBlacklist(address _account, bool _value) public onlyOwner {
        require(_account != address(0), "Bridge: receive zero address");
        blacklist[_account] = _value;
    }

    /**
     * @dev To check an account blacklisted or not
     * @param _account the account to check
     */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklist[_account];
    }

    /**
     * @dev Call when the user swap from chain A to chain B
     * @notice The user will burn the token, then it will return the other token on other chain

     * @param _addr (0) fromToken, (1) toToken, (2) fromAddress, (3) toAddress
     * @param _data (0) amount
     * @param _internalTxId the transaction id
     */
    function burnToken(
        address[] memory _addr,
        uint256[] memory _data,
        string memory _internalTxId
    ) public notBlacklisted nonReentrant {
        TransferData memory transferData = TransferData(
            _addr[0],
            _addr[1],
            _addr[2],
            _addr[3],
            _data[0],
            _internalTxId
        );

        _execute(transferData, 0, "", address(0));
    }

    /**
     * @dev Call when the user claim on chain B when swapping from chain A to chain B
     * @param _addr (0) fromToken, (1) toToken, (2) fromAddress, (3) toAddress, (4) signer
     * @param _data (0) amount
     * @param _internalTxId the transaction id
     * @param _signature the transaction's signature created by the signer
     */
    function mintToken(
        address[] memory _addr,
        uint256[] memory _data,
        string memory _internalTxId,
        bytes memory _signature
    ) public notBlacklisted nonReentrant {
        TransferData memory transferData = TransferData(
            _addr[0],
            _addr[1],
            _addr[2],
            _addr[3],
            _data[0],
            _internalTxId
        );

        _execute(transferData, 1, _signature, _addr[4]);
    }

    /**
     * @dev Internal function to execute the lock/unlock request
     * @param _transferData the transfer data
     * @param _type 0: lock , 1: unlock
     * @param _signature the transaction's signature created by the signer
     */
    function _execute(
        TransferData memory _transferData,
        uint8 _type,
        bytes memory _signature,
        address _signer
    ) internal {
        {
            require(
                _transferData.amount > 0,
                "Diamond Alpha Bridge: Amount must be greater than 0"
            );
            require(
                _transferData.toAddress != address(0),
                "Diamond Alpha Bridge: To address is zero address"
            );
            require(
                _transferData.fromAddress != address(0),
                "Diamond Alpha Bridge: From address is zero address"
            );
            require(
                _transferData.fromToken != address(0),
                "Diamond Alpha Bridge: Token address is zero address"
            );
            require(
                _transferData.toToken != address(0),
                "Diamond Alpha Bridge: Token address is zero address"
            );
        }

        if (_type == 0) {
            // 0: Lock --> Burn, 1: Unlock --> Mint
            require(
                msg.sender == _transferData.fromAddress,
                "Diamond Alpha Bridge: Cannot lock token"
            );

            require(
                isApprovedToken[_transferData.fromToken],
                "Diamond Alpha Bridge: Token is not supported"
            );

            IERC20(_transferData.fromToken).burnFrom(
                _transferData.fromAddress,
                _transferData.amount
            );
        } else {
            require(
                _transferData.toAddress == msg.sender,
                "Diamond Alpha Bridge: You are not recipient"
            );

            require(_signer == signer, "Diamond Alpha Bridge: Only signer");

            require(
                isApprovedToken[_transferData.toToken],
                "Diamond Alpha Bridge: Token is not supported"
            );

            require(
                _transferData.verify(_signature, _signer),
                "Diamond Alpha Bridge: Verify transfer data failed"
            );

            require(
                !isExecutedTransaction[_signature],
                "Diamond Alpha Bridge: Transfer data has been processed before"
            );

            IERC20(_transferData.toToken).mint(
                _transferData.toAddress,
                _transferData.amount
            );

            isExecutedTransaction[_signature] = true;
        }

        emit MintOrBurnEvent(
            _transferData.internalTxId,
            _transferData.toAddress,
            _transferData.fromAddress,
            _transferData.fromToken,
            _transferData.toToken,
            _transferData.amount,
            _type
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "../utils/SignatureUtils.sol";
import "./Structs.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IProxy.sol";

contract Upgradeable is ReentrancyGuard {
    address public immutable proxy;
    address public signer;
    mapping(address => bool) public isApprovedToken;
    mapping(bytes => bool) public isExecutedTransaction;
    mapping(address => bool) blacklist;

    constructor(address _proxy) {
        proxy = _proxy;
    }

    modifier onlyOwner() {
        require(
            msg.sender == IProxy(proxy).proxyOwner(),
            "Diamond Alpha Bridge: Only owner"
        );
        _;
    }

    modifier notBlacklisted() {
        require(
            !blacklist[msg.sender],
            "Diamond Alpha Bridge: This address is blacklisted"
        );
        _;
    }

    event MintOrBurnEvent(
        string internalTxId,
        address indexed toAddress,
        address indexed fromAddress,
        address indexed fromToken,
        address toToken,
        uint256 amount,
        uint8 eventType
    );

    event SetSignerEvent(address indexed newSigner);
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
pragma solidity ^0.8.0;

import "../common/Structs.sol";

library SignatureUtils {
    
    /**
     * @dev To hash the transfer data into bytes32 
     * @param _data the transfer data
     * @return hash the hash of transfer data
     */
    function getMessageHash(TransferData memory _data)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    _data.fromToken,
                    _data.toToken,
                    _data.fromAddress,
                    _data.toAddress,
                    _data.amount,
                    _data.internalTxId
                )
            );
    }

    /**
     * @dev To get the eth-signed message of hash
     * @param _messageHash the hash of transfer data
     * @return ethSignedMessage the eth signed message hash
     */
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

    /**
     * @dev To verify the transfer data and transfer signature
     * @param _data the transfer data
     * @param _signature the signature of transfer
     * @return result true/false
     */
    function verify(TransferData memory _data, bytes memory _signature, address _signer)
        internal
        pure
        returns (bool)
    {
        bytes32 messageHash = getMessageHash(_data);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == _signer;
    }

    /**
     * @dev To recover the signer from signature and hash
     * @param _hash the hash of transfer data
     * @param _signature the signature which was signed by the admin
     * @return signer the address of signer
     */
    function recoverSigner(bytes32 _hash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (_signature.length != 65) {
            return (address(0));
        }

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(_hash, v, r, s);
        }
    }
}
// ["0xeDb21A5bAdc10a5233767e6019C1a92AE6D14793", "0x577f0d8EE0e2C570fbC4f1f98beB85A848ef7556", "0xa781bc9ef3dc0d1e13f973264ff49531a1c84577", "0xa781bc9ef3dc0d1e13f973264ff49531a1c84577", 100000000, "62329a1cabac1e4302f4a07f"]

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct TransferData {
    address fromToken;
    address toToken;
    address fromAddress;
    address toAddress;
    uint256 amount;
    string internalTxId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Create `amount` tokens and assigns them to `account``, increasing the total supply
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply
     */
    function burnFrom(address account, uint256 amount) external;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxy {
    function proxyOwner() external view returns (address);
}