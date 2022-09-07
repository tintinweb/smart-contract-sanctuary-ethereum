/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// File: contracts/zeppelin/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts/zeppelin/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: contracts/IBridge.sol

pragma solidity ^0.5.0;


interface IBridge {
    function version() external pure returns (string memory);

    //function getFeePercentage() external view returns(uint);

    //function calcMaxWithdraw() external view returns (uint);

    /**
     * ERC-20 tokens approve and transferFrom pattern
     * See https://eips.ethereum.org/EIPS/eip-20#transferfrom
     */
    function receiveTokens(address tokenToUse, uint256 amount) external returns(bool);

    /**
     * ERC-20 tokens approve and transferFrom pattern
     * See https://eips.ethereum.org/EIPS/eip-20#transferfrom
     */
    function receiveTokensAt(
        address tokenToUse,
        uint256 amount,
        address receiver,
        bytes calldata extraData
    ) external returns(bool);

    /**
     * ERC-777 tokensReceived hook allows to send tokens to a contract and notify it in a single transaction
     * See https://eips.ethereum.org/EIPS/eip-777#motivation for details
     */
    function tokensReceived (
        address operator,
        address from,
        address to,
        uint amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;

    /**
     * Accepts the transaction from the other chain that was voted and sent by the federation contract
     */
    function acceptTransfer(
        address originalTokenAddress,
        address receiver,
        uint256 amount,
        string calldata symbol,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex,
        uint8 decimals,
        uint256 granularity
    ) external returns(bool);

    function acceptTransferAt(
        address originalTokenAddress,
        address receiver,
        uint256 amount,
        string calldata symbol,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex,
        uint8 decimals,
        uint256 granularity,
        bytes calldata userData
    ) external returns(bool);

    function receiveEthAt(address _receiver, bytes calldata _extraData) external payable;

    function setRevokeTransaction(bytes32 _revokeTransactionID) external;
    function setErc777Converter(address _erc777Converter) external;
    //function getErc777Converter() external view returns(address erc777Addr);

    event Cross(address indexed _tokenAddress, address indexed _to, uint256 _amount, string _symbol, bytes _userData,
        uint8 _decimals, uint256 _granularity);
    event NewSideToken(address indexed _newSideTokenAddress, address indexed _originalTokenAddress, string _newSymbol, uint256 _granularity);
    event AcceptedCrossTransfer(address indexed _tokenAddress, address indexed _to, uint256 _amount, uint8 _decimals, uint256 _granularity,
        uint256 _formattedAmount, uint8 _calculatedDecimals, uint256 _calculatedGranularity, bytes _userData);
    //event FeePercentageChanged(uint256 _amount);
    event ErrorTokenReceiver(bytes _errorData);
    //event AllowTokenChanged(address _newAllowToken);
    //event PrefixUpdated(bool _isPrefix, string _prefix);

}

// File: contracts/zeppelin/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/zeppelin/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/zeppelin/cryptography/ECDSA.sol

pragma solidity ^0.5.2;

/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// File: contracts/Federation.sol

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;




contract Federation is Ownable {
    struct SignatureInfo {
        bytes signature;
        uint256 deadline;
    }

    uint256 public constant MAX_MEMBER_COUNT = 50;
    address private constant NULL_ADDRESS = address(0);

    IBridge public bridge;
    address[] public members;
    uint256 public required;

    bytes32 private constant NULL_HASH = bytes32(0);
    bool public initStageDone;

    mapping(address => bool) public isMember;
    mapping(bytes32 => mapping(address => bool)) public votes;
    mapping(bytes32 => bool) public processed;
    // solium-disable-next-line max-len
    event Voted(
        address indexed sender,
        bytes32 indexed transactionId,
        address originalTokenAddress,
        address receiver,
        uint256 amount,
        string symbol,
        bytes32 blockHash,
        bytes32 indexed transactionHash,
        uint32 logIndex,
        uint8 decimals,
        uint256 granularity,
        bytes userData
    );
    event Signed(bytes32 indexed transactionId, address validator);
    event Executed(bytes32 indexed transactionId);
    event MemberAddition(address indexed member);
    event MemberRemoval(address indexed member);
    event RequirementChange(uint256 required);
    event BridgeChanged(address bridge);
    event RevokeTxAndVote(bytes32 tx_revoked);
    event StoreFormerFederationExecutedTx(bytes32[] tx_stored);

    modifier onlyMember() {
        require(isMember[_msgSender()], "Federation: Caller not a Federator");
        _;
    }

    modifier validRequirement(uint256 membersCount, uint256 _required) {
        // solium-disable-next-line max-len
        require(
            _required <= membersCount && _required != 0 && membersCount != 0,
            "Federation: Invalid requirements"
        );
        _;
    }

    constructor(address[] memory _members, uint256 _required)
        public
        validRequirement(_members.length, _required)
    {
        require(_members.length <= MAX_MEMBER_COUNT, "Federation: Members larger than max allowed");
        members = _members;
        for (uint256 i = 0; i < _members.length; i++) {
            require(
                !isMember[_members[i]] && _members[i] != NULL_ADDRESS,
                "Federation: Invalid members"
            );
            isMember[_members[i]] = true;
            // members.push(_members[i]);

            emit MemberAddition(_members[i]);
        }
        required = _required;
        emit RequirementChange(required);
    }

    function setBridge(address _bridge) external onlyOwner {
        require(_bridge != NULL_ADDRESS, "Federation: Empty bridge");
        bridge = IBridge(_bridge);
        emit BridgeChanged(_bridge);
    }

    function voteTransaction(
        address originalTokenAddress,
        address receiver,
        uint256 amount,
        string calldata symbol,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex,
        uint8 decimals,
        uint256 granularity
    ) external returns (bool) {
        return
            _voteTransaction(
                originalTokenAddress,
                receiver,
                amount,
                symbol,
                blockHash,
                transactionHash,
                logIndex,
                decimals,
                granularity,
                ""
            );
    }

    function voteTransactionAt(
        address originalTokenAddress,
        address receiver,
        uint256 amount,
        string memory symbol,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex,
        uint8 decimals,
        uint256 granularity,
        bytes memory userData
    ) public returns (bool) {
        return
            _voteTransaction(
                originalTokenAddress,
                receiver,
                amount,
                symbol,
                blockHash,
                transactionHash,
                logIndex,
                decimals,
                granularity,
                userData
            );
    }

    function _voteTransaction(
        address originalTokenAddress,
        address receiver,
        uint256 amount,
        string memory symbol,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex,
        uint8 decimals,
        uint256 granularity,
        bytes memory userData
    ) internal onlyMember returns (bool) {
        // solium-disable-next-line max-len
        require(
            initStageDone == true,
            "Federation: Cannot process TX while initStageDone == false"
        );

        bytes32 transactionId = getTransactionId(
            originalTokenAddress,
            receiver,
            amount,
            symbol,
            blockHash,
            transactionHash,
            logIndex,
            decimals,
            granularity
        );
        if (processed[transactionId]) return true;

        // Bug fix //
        // UserData is not included in transactionId hash.
        // In order to keep backward competability, since transctions that were already processed are marked as processed[transactionId],
        // We keep the transactionId and adding transactionIdU (that includes userData hashing)
        // Assuming  processed[transactionId) == false from this line
        // Depreciating transactionId for unprocessed transaction.
        // Using transactionIdU instead.
        // This should be updated in Federator BE as well.
        // Function processTransaction() created to solve EVM stack to deep error
        if (
            processTransaction(
                originalTokenAddress,
                receiver,
                amount,
                symbol,
                blockHash,
                transactionHash,
                logIndex,
                decimals,
                granularity,
                userData
            )
        ) {
            // No need to update processed[transactionId], since it is used only for backward competability
            // processed[transactionId] = true;
            return true;
        }
        return true;
    }

    function processTransaction(
        address originalTokenAddress,
        address receiver,
        uint256 amount,
        string memory symbol,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex,
        uint8 decimals,
        uint256 granularity,
        bytes memory userData
    ) internal returns (bool) {
        bytes32 transactionIdU = getTransactionIdU(
            originalTokenAddress,
            receiver,
            amount,
            symbol,
            blockHash,
            transactionHash,
            logIndex,
            decimals,
            granularity,
            userData
        );

        if (processed[transactionIdU]) return true;

        if (votes[transactionIdU][_msgSender()]) return true;

        votes[transactionIdU][_msgSender()] = true;
        // solium-disable-next-line max-len
        emit Voted(
            _msgSender(),
            transactionIdU,
            originalTokenAddress,
            receiver,
            amount,
            symbol,
            blockHash,
            transactionHash,
            logIndex,
            decimals,
            granularity,
            userData
        );

        uint256 transactionCount = getTransactionCount(transactionIdU);
        if (transactionCount >= required && transactionCount >= members.length / 2 + 1) {
            processed[transactionIdU] = true;
            bool acceptTransfer = bridge.acceptTransferAt(
                originalTokenAddress,
                receiver,
                amount,
                symbol,
                blockHash,
                transactionHash,
                logIndex,
                decimals,
                granularity,
                userData
            );
            require(acceptTransfer, "Federation: Bridge acceptTransfer error");
            emit Executed(transactionIdU);
            return true;
        }
    }

    function executeTransaction(
        address originalTokenAddress,
        address receiver,
        uint256 amount,
        string memory symbol,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex,
        uint8 decimals,
        uint256 granularity,
        SignatureInfo[] memory signaturesInfos
    ) public returns (bool) {
        return
            _executeTransaction(
                originalTokenAddress,
                receiver,
                amount,
                symbol,
                blockHash,
                transactionHash,
                logIndex,
                decimals,
                granularity,
                "",
                signaturesInfos
            );
    }

    function executeTransactionAt(
        address originalTokenAddress,
        address receiver,
        uint256 amount,
        string memory symbol,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex,
        uint8 decimals,
        uint256 granularity,
        bytes memory userData,
        SignatureInfo[] memory signaturesInfos
    ) public returns (bool) {
        return
            _executeTransaction(
                originalTokenAddress,
                receiver,
                amount,
                symbol,
                blockHash,
                transactionHash,
                logIndex,
                decimals,
                granularity,
                userData,
                signaturesInfos
            );
    }

    function _executeTransaction(
        address originalTokenAddress,
        address receiver,
        uint256 amount,
        string memory symbol,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex,
        uint8 decimals,
        uint256 granularity,
        bytes memory userData,
        SignatureInfo[] memory signaturesInfos
    ) internal onlyMember returns (bool) {
        // solium-disable-next-line max-len
        require(
            initStageDone == true,
            "Federation: Cannot process TX while initStageDone == false"
        );

        bytes32 transactionId = getTransactionId(
            originalTokenAddress,
            receiver,
            amount,
            symbol,
            blockHash,
            transactionHash,
            logIndex,
            decimals,
            granularity
        );
        if (processed[transactionId]) return true;

        // Bug fix //
        // UserData is not included in transactionId hash.
        // In order to keep backward competability, since transctions that were already processed are marked as processed[transactionId],
        // We keep the transactionId and adding transactionIdU (that includes userData hashing)
        // Assuming  processed[transactionId) == false from this line
        // Depreciating transactionId for unprocessed transaction.
        // Using transactionIdU instead.
        // This should be updated in Federator BE as well.
        // Function processTransaction() created to solve EVM stack to deep error
        if (
            processSignedTransaction(
                originalTokenAddress,
                receiver,
                amount,
                symbol,
                blockHash,
                transactionHash,
                logIndex,
                decimals,
                granularity,
                userData,
                signaturesInfos
            )
        ) {
            // No need to update processed[transactionId], since it is used only for backward competability
            // processed[transactionId] = true;
            return true;
        }
        return true;
    }

    function processSignedTransaction(
        address originalTokenAddress,
        address receiver,
        uint256 amount,
        string memory symbol,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex,
        uint8 decimals,
        uint256 granularity,
        bytes memory userData,
        SignatureInfo[] memory signaturesInfos
    ) internal returns (bool) {
        bytes32 transactionIdU = getTransactionIdU(
            originalTokenAddress,
            receiver,
            amount,
            symbol,
            blockHash,
            transactionHash,
            logIndex,
            decimals,
            granularity,
            userData
        );
        if (processed[transactionIdU]) return true;

        // Sender implicitly accepts
        votes[transactionIdU][_msgSender()] = true;
        uint256 memberValidations = 1;
        emit Signed(transactionIdU, _msgSender());

        for (uint256 i; i < signaturesInfos.length; i += 1) {
            require(
                signaturesInfos[i].deadline > block.timestamp,
                "Some signature is not valid anymore"
            );

            uint256 chainId;
            assembly {
                chainId := chainid()
            }
            bytes32 hash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n116",
                    abi.encodePacked(
                        transactionIdU,
                        chainId,
                        address(this),
                        signaturesInfos[i].deadline
                    )
                )
            );
            address signer = ECDSA.recover(hash, signaturesInfos[i].signature);

            require(isMember[signer], "Signature doesn't match any member");
            if (!votes[transactionIdU][signer]) {
                votes[transactionIdU][signer] = true;
                memberValidations += 1;
                emit Signed(transactionIdU, signer);
            }
        }

        require(
            memberValidations >= required && memberValidations >= members.length / 2 + 1,
            "Not enough validations"
        );

        processed[transactionIdU] = true;

        releaseTokensOnBridge(
            transactionIdU,
            originalTokenAddress,
            receiver,
            amount,
            symbol,
            blockHash,
            transactionHash,
            logIndex,
            decimals,
            granularity,
            userData
        );
        emit Executed(transactionIdU);

        return true;
    }

    function releaseTokensOnBridge(
        bytes32 transactionIdU,
        address originalTokenAddress,
        address receiver,
        uint256 amount,
        string memory symbol,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex,
        uint8 decimals,
        uint256 granularity,
        bytes memory userData
    ) private {
        emit Voted(
            _msgSender(),
            transactionIdU,
            originalTokenAddress,
            receiver,
            amount,
            symbol,
            blockHash,
            transactionHash,
            logIndex,
            decimals,
            granularity,
            userData
        );
        bool acceptTransfer = bridge.acceptTransferAt(
            originalTokenAddress,
            receiver,
            amount,
            symbol,
            blockHash,
            transactionHash,
            logIndex,
            decimals,
            granularity,
            userData
        );
        require(acceptTransfer, "Federation: Bridge acceptTransfer error");
    }

    function getTransactionCount(bytes32 transactionId) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < members.length; i++) {
            if (votes[transactionId][members[i]]) count += 1;
        }
        return count;
    }

    function hasVoted(bytes32 transactionId) external view returns (bool) {
        return votes[transactionId][_msgSender()];
    }

    function transactionWasProcessed(bytes32 transactionId) external view returns (bool) {
        return processed[transactionId];
    }

    function getTransactionId(
        address originalTokenAddress,
        address receiver,
        uint256 amount,
        string memory symbol,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex,
        uint8 decimals,
        uint256 granularity
    ) public pure returns (bytes32) {
        // solium-disable-next-line max-len
        return
            keccak256(
                abi.encodePacked(
                    originalTokenAddress,
                    receiver,
                    amount,
                    symbol,
                    blockHash,
                    transactionHash,
                    logIndex,
                    decimals,
                    granularity
                )
            );
    }

    function getTransactionIdU(
        address originalTokenAddress,
        address receiver,
        uint256 amount,
        string memory symbol,
        bytes32 blockHash,
        bytes32 transactionHash,
        uint32 logIndex,
        uint8 decimals,
        uint256 granularity,
        bytes memory userData
    ) public pure returns (bytes32) {
        // solium-disable-next-line max-len
        return
            keccak256(
                abi.encodePacked(
                    originalTokenAddress,
                    receiver,
                    amount,
                    symbol,
                    blockHash,
                    transactionHash,
                    logIndex,
                    decimals,
                    granularity,
                    userData
                )
            );
    }

    function addMember(address _newMember) external onlyOwner {
        require(_newMember != NULL_ADDRESS, "Federation: Empty member");
        require(!isMember[_newMember], "Federation: Member already exists");
        require(members.length < MAX_MEMBER_COUNT, "Federation: Max members reached");

        isMember[_newMember] = true;
        members.push(_newMember);
        emit MemberAddition(_newMember);
    }

    function removeMember(address _oldMember) external onlyOwner {
        require(_oldMember != NULL_ADDRESS, "Federation: Empty member");
        require(isMember[_oldMember], "Federation: Member doesn't exists");
        require(members.length > 1, "Federation: Can't remove all the members");
        require(
            members.length - 1 >= required,
            "Federation: Can't have less than required members"
        );

        isMember[_oldMember] = false;
        for (uint256 i = 0; i < members.length - 1; i++) {
            if (members[i] == _oldMember) {
                members[i] = members[members.length - 1];
                break;
            }
        }
        members.length -= 1;
        emit MemberRemoval(_oldMember);
    }

    function getMembers() external view returns (address[] memory) {
        return members;
    }

    function changeRequirement(uint256 _required)
        external
        onlyOwner
        validRequirement(members.length, _required)
    {
        require(_required >= 2, "Federation: Requires at least 2");
        required = _required;
        emit RequirementChange(_required);
    }

    // Revoke state of txID (from true to false), to enable multiSig release of stucked txID on the bridge
    // setRevokeTransaction() should be called on the bridge as well to enable revoke of txID
    function setRevokeTransactionAndVote(bytes32 _revokeTransactionID) external onlyOwner {
        require(
            _revokeTransactionID != NULL_HASH,
            "Federation: _revokeTransactionID cannot be NULL"
        );
        require(
            processed[_revokeTransactionID] == true,
            "Federation: cannot revoke unprocessed TX"
        );
        processed[_revokeTransactionID] = false;
        for (uint256 i = 0; i < members.length; i++) {
            votes[_revokeTransactionID][members[i]] = false;
        }
        emit RevokeTxAndVote(_revokeTransactionID);
    }

    // Store former Federation contract version processed[] state
    // Can be used only at deployment stage. Cannot _voteTransaction txID while this stage is active (initStageDone is false)
    function initStoreOldFederation(bytes32[] calldata _TransactionIDs) external onlyOwner {
        require(
            initStageDone == false,
            "Federation: initStoreOldFederation enabled only during deployment setup Stage"
        );
        for (uint256 i = 0; i < _TransactionIDs.length; i++) {
            require(
                _TransactionIDs[i] != NULL_HASH,
                "Federation: _storeTransactionID cannot be NULL"
            );
            processed[_TransactionIDs[i]] = true;
        }
        emit StoreFormerFederationExecutedTx(_TransactionIDs);
    }

    // Finish stage of store of former Federation contract version
    // Must be set to true before _voteTransaction is called
    function endDeploymentSetup() external onlyOwner {
        initStageDone = true;
    }
}