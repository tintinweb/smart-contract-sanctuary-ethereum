/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-06
*/

// File: contracts/evm/interfaces/ICORE.sol


pragma solidity ^0.8.0;

interface ICORE {
    function deposit() external payable;
    function withdraw(uint amount) external;
}

// File: contracts/evm/interfaces/IERC20.sol


pragma solidity ^0.8.0;

interface IERC20 {
    function mint(address _to, uint256 _amount) external;
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

// File: contracts/lib/ChainId.sol


pragma solidity ^0.8.0;

library ChainId {
    int256 public constant zyxChainId = 55;


    function getChainId() internal view returns (int256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// File: contracts/lib/Pausable.sol


pragma solidity ^0.8.0;

abstract contract Pausable is OwnableUpgradeable {
    bool public pause;

    modifier isPause() {
        require(!pause, "Pausable: paused");
        _;
    }

    function togglePause() public virtual onlyOwner {
        pause = !pause;
    }
}

// File: contracts/lib/Signature.sol


pragma solidity ^0.8.0;

library Signature {
    function getMessageHash(
        address token,
        address user,
        uint256 amount,
        uint256 fee,
        int256 chainIdTo,
        bytes32 hash,
        uint256 deadline
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, user, amount, fee, chainIdTo, hash, deadline));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(
        address _token,
        address _user,
        uint256 _amount,
        uint256 _fee,
        int256 _chainId,
        bytes32 _hash,
        uint256 _deadline,
        address _signer,
        bytes memory _signature
    ) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_token, _user, _amount, _fee,_chainId, _hash, _deadline);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, _signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v){
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

// File: contracts/evm/PandorumMainPeriphery.sol

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;


contract PandorumMainPeriphery is OwnableUpgradeable, Pausable {
    struct Token {
        bool isSupported;
        uint256 minLimit;
        uint256 balance;
    }

    int256 public chainId;

    /*** Stable Tokens ***/
    address public wzyx;
    address public icore;

    /*** Managing Accounts ***/
    address public oracle;
    address public migrator;
    address public feeTo;

    /*** map of tokenInfo ****/
    mapping(address => Token) public tokenInfo;
    /*** map of used hashes from zyx to chain ***/
    mapping(bytes32 => bool) public checkedHashes;

    function initialize(
        address _icore,
        address _wzyx,
        address _oracle,
        address[] calldata _tokens
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        chainId = ChainId.getChainId();
        icore = _icore;
        wzyx = _wzyx;

        addCoin(_icore, 100000000000000000, 0);
        addCoin(_wzyx, 10000000000000000000, 0);

        // setting system
        oracle = _oracle;

        for(uint i = 0; i < _tokens.length;i++){
            addCoin(_tokens[i],10000000000000000000,0);
        }
    }


    /**** Modifiers ****/
    modifier notZeroMigrator() {
        require(migrator != address(0), "PandorumMainPeriphery: Zero Migrator");
        _;
    }

    modifier supportedToken(address token) {
        require(tokenInfo[token].isSupported, "PandorumMainPeriphery: Not supported token");
        _;
    }

    modifier newHash(bytes32 hash) {
        require(!checkedHashes[hash], "PandorumMainPeriphery: Duplicated hash");
        _;
        checkedHashes[hash] = true;
    }

    /*** Events ****/
    event NewDeposit(
        address token,
        address indexed user,
        uint256 amount,
        int256 chainIdFrom,
        int256 chainIdTo
    );

    event NewTransfer(
        address token,
        address indexed user,
        address oracle,
        uint256 amount,
        uint256 fee,
        int256 chainIdFrom,
        int256 chainIdTo,
        bytes32 indexed hash,
        uint256 deadline
    );


    function redeemToken(
        address _token,
        address _user,
        uint256 _amount,
        uint256 _fee,
        int256 _chainId,
        bytes32 _hash,
        uint256 _deadline,
        bytes memory _signature
    ) external supportedToken(_token) newHash(_hash) isPause {
        require(chainId == _chainId, "PandorumMainPeriphery: not target network");
        require(Signature.verify(_token, _user, _amount, _fee, _chainId, _hash, _deadline, oracle, _signature), "PandorumMainPeriphery: Bad signature");
        require(_deadline >= block.timestamp, "PandorumMainPeriphery: Expired");
        require(msg.sender == _user, "PandorumMainPeriphery: not sender");


        if (_token == wzyx) {
            IERC20(_token).mint(_user, _amount);
            IERC20(_token).mint(feeTo, _fee);
        } else {
            require(tokenInfo[_token].balance >= (_amount + _fee));
            IERC20(_token).transfer(_user, _amount);
            IERC20(_token).transfer(feeTo, _fee);
            tokenInfo[_token].balance = tokenInfo[_token].balance - _amount;
            tokenInfo[_token].balance = tokenInfo[_token].balance - _fee;
        }

        emit NewTransfer(
            _token,
            _user,
            oracle,
            _amount,
            _fee,
            ChainId.zyxChainId,
            _chainId,
            _hash,
            _deadline
        );
    }

    function deposit() external payable isPause {
        address token = icore;
        // gas savings (copy use less gas)
        uint256 amount = msg.value;
        // gas savings (copy use less gas)
        Token storage currentBalance = tokenInfo[token];
        // for saving gas
        require(amount >= currentBalance.minLimit, "PandorumMainPeriphery: amount is too small");
        ICORE(token).deposit{value : amount}();
        currentBalance.balance = currentBalance.balance + amount;
        emit NewDeposit(token, msg.sender, amount, chainId, ChainId.zyxChainId);
    }

    function depositToken(address token, uint256 amount) external supportedToken(token) isPause {
        Token storage currentBalance = tokenInfo[token];
        require(amount >= currentBalance.minLimit, "PandorumMainPeriphery: amount is too small");
        if (token == wzyx) {
            IERC20(token).burnFrom(msg.sender, amount);
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
            currentBalance.balance = currentBalance.balance + amount;
        }
        emit NewDeposit(token, msg.sender, amount, chainId, ChainId.zyxChainId);
    }


    /***** Managing coins *****/
    function addCoin(address _token, uint256 _minSwap, uint256 _balance) public onlyOwner {
        Token storage token = tokenInfo[_token];
        token.isSupported = true;
        token.balance = _balance;
        updateCoin(_token, _minSwap);
    }

    function updateCoin(address _token, uint256 _minSwap) public onlyOwner supportedToken(_token) {
        tokenInfo[_token].minLimit = _minSwap;
    }

    function removeCoin(address _token) public onlyOwner {
        delete tokenInfo[_token];
    }

    /***** Managing contract operator *****/
    function setOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }

    function setMigrator(address _migrator) public onlyOwner {
        migrator = _migrator;
    }

    function setFeeTo(address _feeTo) public onlyOwner {
        feeTo = _feeTo;
    }

    /**** Setting Wrapped ZYX contract ****/
    function setWzyx(address _wzyx) public onlyOwner {
        wzyx = _wzyx;
    }

    /**** Setting Main Wrapped token such as WETH,WBNB ****/
    function setIcore(address _icore) public onlyOwner {
        icore = _icore;
    }

    /*** Admin function ***/
    function checkHash(bytes32 hash) public onlyOwner {
        checkedHashes[hash] = true;
    }

    function migrate(address _token) public onlyOwner notZeroMigrator {
        uint256 currentBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(migrator, currentBalance);
        delete tokenInfo[_token];
    }

    function migrateETH() public onlyOwner notZeroMigrator {
        payable(migrator).transfer(address(this).balance);
    }
}