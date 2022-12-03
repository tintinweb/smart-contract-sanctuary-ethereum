/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: None
// File: contracts/AnyswapV6ERC20.sol



pragma solidity ^0.8.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract AnyswapV6ERC20 is IERC20 {
    using SafeERC20 for IERC20;
    string public name;
    string public symbol;
    uint8  public immutable override decimals;

    address public immutable underlying;
    bool public constant underlyingIsMinted = false;

    /// @dev Records amount of AnyswapV6ERC20 token owned by account.
    mapping (address => uint256) public override balanceOf;
    uint256 private _totalSupply;

    // init flag for setting immediate vault, needed for CREATE2 support
    bool private _init;

    // flag to enable/disable swapout vs vault.burn so multiple events are triggered
    bool private _vaultOnly;

    // delay for timelock functions
    uint public constant DELAY = 2 days;

    // set of minters, can be this bridge or other bridges
    mapping(address => bool) public isMinter;
    address[] public minters;

    // primary controller of the token contract
    address public vault;

    address public pendingMinter;
    uint public delayMinter;

    address public pendingVault;
    uint public delayVault;

    modifier onlyAuth() {
        require(isMinter[msg.sender], "AnyswapV6ERC20: FORBIDDEN");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "AnyswapV6ERC20: FORBIDDEN");
        _;
    }

    function owner() external view returns (address) {
        return vault;
    }

    function mpc() external view returns (address) {
        return vault;
    }

    function setVaultOnly(bool enabled) external onlyVault {
        _vaultOnly = enabled;
    }

    function initVault(address _vault) external onlyVault {
        require(_init);
        _init = false;
        vault = _vault;
        isMinter[_vault] = true;
        minters.push(_vault);
    }

    function setVault(address _vault) external onlyVault {
        require(_vault != address(0), "AnyswapV6ERC20: address(0)");
        pendingVault = _vault;
        delayVault = block.timestamp + DELAY;
    }

    function applyVault() external onlyVault {
        require(pendingVault != address(0) && block.timestamp >= delayVault);
        vault = pendingVault;

        pendingVault = address(0);
        delayVault = 0;
    }

    function setMinter(address _auth) external onlyVault {
        require(_auth != address(0), "AnyswapV6ERC20: address(0)");
        pendingMinter = _auth;
        delayMinter = block.timestamp + DELAY;
    }

    function applyMinter() external onlyVault {
        require(pendingMinter != address(0) && block.timestamp >= delayMinter);
        isMinter[pendingMinter] = true;
        minters.push(pendingMinter);

        pendingMinter = address(0);
        delayMinter = 0;
    }

    // No time delay revoke minter emergency function
    function revokeMinter(address _auth) external onlyVault {
        isMinter[_auth] = false;
    }

    function getAllMinters() external view returns (address[] memory) {
        return minters;
    }

    function changeVault(address newVault) external onlyVault returns (bool) {
        require(newVault != address(0), "AnyswapV6ERC20: address(0)");
        emit LogChangeVault(vault, newVault, block.timestamp);
        vault = newVault;
        pendingVault = address(0);
        delayVault = 0;
        return true;
    }

    function mint(address to, uint256 amount) external onlyAuth returns (bool) {
        _mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) external onlyAuth returns (bool) {
        _burn(from, amount);
        return true;
    }

    function Swapin(bytes32 txhash, address account, uint256 amount) external onlyAuth returns (bool) {
        if (underlying != address(0) && IERC20(underlying).balanceOf(address(this)) >= amount) {
            IERC20(underlying).safeTransfer(account, amount);
        } else {
            _mint(account, amount);
        }
        emit LogSwapin(txhash, account, amount);
        return true;
    }

    function Swapout(uint256 amount, address bindaddr) external returns (bool) {
        require(!_vaultOnly, "AnyswapV6ERC20: vaultOnly");
        require(bindaddr != address(0), "AnyswapV6ERC20: address(0)");
        if (underlying != address(0) && balanceOf[msg.sender] < amount) {
            IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        } else {
            _burn(msg.sender, amount);
        }
        emit LogSwapout(msg.sender, bindaddr, amount);
        return true;
    }

    /// @dev Records number of AnyswapV6ERC20 token that account (second) will be allowed to spend on behalf of another account (first) through {transferFrom}.
    mapping (address => mapping (address => uint256)) public override allowance;

    event LogChangeVault(address indexed oldVault, address indexed newVault, uint indexed effectiveTime);
    event LogSwapin(bytes32 indexed txhash, address indexed account, uint amount);
    event LogSwapout(address indexed account, address indexed bindaddr, uint amount);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _underlying, address _vault) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        underlying = _underlying;
        if (_underlying != address(0)) {
            require(_decimals == IERC20(_underlying).decimals());
        }

        // Use init to allow for CREATE2 accross all chains
        _init = true;

        // Disable/Enable swapout for v1 tokens vs mint/burn for v3 tokens
        _vaultOnly = false;

        vault = _vault;
    }

    /// @dev Returns the total supply of AnyswapV6ERC20 token as the ETH held in this contract.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function deposit() external returns (uint) {
        uint _amount = IERC20(underlying).balanceOf(msg.sender);
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), _amount);
        return _deposit(_amount, msg.sender);
    }

    function deposit(uint amount) external returns (uint) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        return _deposit(amount, msg.sender);
    }

    function deposit(uint amount, address to) external returns (uint) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        return _deposit(amount, to);
    }

    function depositVault(uint amount, address to) external onlyVault returns (uint) {
        return _deposit(amount, to);
    }

    function _deposit(uint amount, address to) internal returns (uint) {
        require(!underlyingIsMinted);
        require(underlying != address(0) && underlying != address(this));
        _mint(to, amount);
        return amount;
    }

    function withdraw() external returns (uint) {
        return _withdraw(msg.sender, balanceOf[msg.sender], msg.sender);
    }

    function withdraw(uint amount) external returns (uint) {
        return _withdraw(msg.sender, amount, msg.sender);
    }

    function withdraw(uint amount, address to) external returns (uint) {
        return _withdraw(msg.sender, amount, to);
    }

    function withdrawVault(address from, uint amount, address to) external onlyVault returns (uint) {
        return _withdraw(from, amount, to);
    }

    function _withdraw(address from, uint amount, address to) internal returns (uint) {
        require(!underlyingIsMinted);
        require(underlying != address(0) && underlying != address(this));
        _burn(from, amount);
        IERC20(underlying).safeTransfer(to, amount);
        return amount;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 balance = balanceOf[account];
        require(balance >= amount, "ERC20: burn amount exceeds balance");

        balanceOf[account] = balance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's AnyswapV6ERC20 token.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    function approve(address spender, uint256 value) external override returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    /// @dev Moves `value` AnyswapV6ERC20 token from caller's account to account (`to`).
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` AnyswapV6ERC20 token.
    function transfer(address to, uint256 value) external override returns (bool) {
        require(to != address(0) && to != address(this));
        uint256 balance = balanceOf[msg.sender];
        require(balance >= value, "AnyswapV6ERC20: transfer amount exceeds balance");

        balanceOf[msg.sender] = balance - value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);

        return true;
    }

    /// @dev Moves `value` AnyswapV6ERC20 token from account (`from`) to account (`to`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - `from` account must have at least `value` balance of AnyswapV6ERC20 token.
    ///   - `from` account must have approved caller to spend at least `value` of AnyswapV6ERC20 token, unless `from` and caller are the same account.
    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        require(to != address(0) && to != address(this));
        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "AnyswapV6ERC20: request exceeds allowance");
                uint256 reduced = allowed - value;
                allowance[from][msg.sender] = reduced;
                emit Approval(from, msg.sender, reduced);
            }
        }

        uint256 balance = balanceOf[from];
        require(balance >= value, "AnyswapV6ERC20: transfer amount exceeds balance");

        balanceOf[from] = balance - value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);

        return true;
    }
}
// File: contracts/6_trasury.sol



pragma solidity ^0.8.0;

/**
 * Multi-sig ERC20 token treasury for Illuminate
 */


/// three level architecture
/// top level is the `AnycallClient` which the users interact with (through UI or tools)
/// middle level is `AnyswapToken` which works as handlers and vaults for tokens
/// bottom level is the `AnycallProxy` which complete the cross-chain interaction

interface IApp {
    function anyExecute(bytes calldata _data)
        external
        returns (bool success, bytes memory result);
}

interface IAnyswapToken {
    function mint(address to, uint256 amount) external returns (bool);

    function burn(address from, uint256 amount) external returns (bool);

    function withdraw(uint256 amount, address to) external returns (uint256);
}

interface IAnycallExecutor {
    function context()
        external
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );
}

interface IAnycallV6Proxy {
    function executor() external view returns (address);

    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;
}

abstract contract IlluminateERC20TreasuryBase is IApp {
    address public callProxy;
    address public executor;
    address public Kevin;
    address public Lumo;
    address public Daniel;

    // associated client app on each chain
    mapping(uint256 => address) public clientPeers; // key is chainId

    modifier onlyExecutor() {
        require(msg.sender == executor, "AnycallClient: onlyExecutor");
        _;
    }
    
    // Only core team has certain privileges
    modifier onlyCoreTeam() {
        require(
            msg.sender == Kevin || msg.sender == Lumo || msg.sender == Daniel,
            "IlluminateERC20Treasury: only core team allowed"
        );
        _;
    }

    constructor(address _callProxy) {
        require(_callProxy != address(0));
        Kevin = 0x6f1a558DEc5F483848C3D87aC4EB1C2Bd46Ee1bE;
        Lumo = 0xAc3D881683c74d81e872cB458C229C588d3c6cc4;
        Daniel = 0xAC3651bBd481d975f17d601F40168a92de2556BA;
        callProxy = _callProxy;
        executor = IAnycallV6Proxy(callProxy).executor();
    }

    receive() external payable {
        require(
            msg.sender == callProxy,
            "AnycallClient: receive from forbidden sender"
        );
    }

    function setCallProxy(address _callProxy) external onlyCoreTeam {
        require(_callProxy != address(0));
        callProxy = _callProxy;
        executor = IAnycallV6Proxy(callProxy).executor();
    }

    function setClientPeers(
        uint256[] calldata _chainIds,
        address[] calldata _peers
    ) external onlyCoreTeam {
        require(_chainIds.length == _peers.length);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            clientPeers[_chainIds[i]] = _peers[i];
        }
    }

    function setKevin(address newKevin)
        external
    {
        require(
            msg.sender == Kevin,
            "IlluminateERC20Treasury: only Kevin allowed"
        );
        Kevin = newKevin;
    }

    function setLumo(address newLumo)
        external
    {
        require(
            msg.sender == Lumo,
            "IlluminateERC20Treasury: only Lumo allowed"
        );
        Lumo = newLumo;
    }

    function setDaniel(address newDaniel)
        external
    {
        require(
            msg.sender == Daniel,
            "IlluminateERC20Treasury: only Daniel allowed"
        );
        Daniel = newDaniel;
    }
}

contract IlluminateERC20Treasury_v1 is IlluminateERC20TreasuryBase {
    using SafeERC20 for IERC20;

    // associated tokens on each chain
    mapping(address => mapping(uint256 => address)) public tokenPeers;

    struct _transaction {
        uint8 approvals; // votes from core team
        address token; // address of token being sent
        address to; // to address
        uint256 amount; // token amount
    }

    struct _mintOrBurn {
        uint8 approvals; // votes from core team
        bool mint; // true means mint, false means burn
        address to; // address to mint/burn at
        uint256 amount; // token amount
    }

    mapping(uint256 => _transaction) public transactions; // map of transactions by ID

    mapping(uint256 => _mintOrBurn) public mintOrBurns; // map of mints and burns by ID
    
    uint256 public numTransactions; // only increases each transaction created

    uint256 public numMintOrBurns; // only increases with each request

    address public ILMaddress;

    AnyswapV6ERC20 public ILM;

    mapping(address => uint8) public votes; // number of votes held by treasury member

    mapping(address => mapping(uint256 => bool)) public votedOnTransaction; // has member voted
                                                                            // on transaction

    mapping(address => mapping(uint256 => bool)) public votedOnMintOrBurn; // has member voted
                                                                            // on mint/burn

    mapping(address => mapping(address 
    => uint256)) public totalTokenTransferred; // total of token sent from treasury to address

    mapping(address => mapping(address =>
        mapping(uint256 => uint256))) public userTokenPaidPurpose; // token paid by user towards a Purpose

    uint256 public currentPurposeNum; // latest Purpose id, user cannot burn towards future Purposes

    mapping(address => uint256) public totalTokenPaid; // total of token paid by all users

    uint256 public tokensMinted; // ILM created by treasury so far

    uint256 public SUPPLY_CAP = 6666666000000000000000000; // Max ILM that can ever be created.
 
    event transactionSent(address indexed _token, address indexed _to, uint256 indexed _amount);

    event treasuryPaid(address indexed _user, address indexed _token,
        uint256 indexed _purpose, uint256 _amount);
    
    event purposeNumSet(uint256 indexed _num);

    event LogSwapout(
        address indexed token, address indexed sender, address indexed receiver, uint256 amount, uint256 toChainId
    );
    event LogSwapin(
        address indexed token, address indexed sender, address indexed receiver, uint256 amount, uint256 fromChainId
    );
    event LogSwapoutFail(
        address indexed token, address indexed sender, address indexed receiver, uint256 amount, uint256 toChainId
    );

    constructor(address _callProxy) 
        IlluminateERC20TreasuryBase(_callProxy) 
    {
        votes[Kevin] = 2;
        votes[Lumo] = 1;
        votes[Daniel] = 1;
    }

    function setTokenPeers(
        address srcToken,
        uint256[] calldata chainIds,
        address[] calldata dstTokens
    ) external onlyCoreTeam {
        require(chainIds.length == dstTokens.length);
        for (uint256 i = 0; i < chainIds.length; i++) {
            tokenPeers[srcToken][chainIds[i]] = dstTokens[i];
        }
    }

    /// @dev Call by the user to submit a request for a cross chain interaction
    function swapout(
        address token,
        uint256 amount,
        address receiver,
        uint256 toChainId,
        uint256 flags
    ) external payable {
        address clientPeer = clientPeers[toChainId];
        require(clientPeer != address(0), "AnycallClient: no dest client");

        address dstToken = tokenPeers[token][toChainId];
        require(dstToken != address(0), "AnycallClient: no dest token");

        uint256 oldCoinBalance;
        if (msg.value > 0) {
            oldCoinBalance = address(this).balance - msg.value;
        }

        address _underlying = _getUnderlying(token);

        if (
            _underlying != address(0) &&
            IERC20(token).balanceOf(msg.sender) < amount
        ) {
            uint256 old_balance = IERC20(_underlying).balanceOf(token);
            IERC20(_underlying).safeTransferFrom(msg.sender, token, amount);
            uint256 new_balance = IERC20(_underlying).balanceOf(token);
            require(
                new_balance >= old_balance &&
                    new_balance <= old_balance + amount
            );
            // update amount to real balance increasement (some token may deduct fees)
            amount = new_balance - old_balance;
        } else {
            assert(IAnyswapToken(token).burn(msg.sender, amount));
        }

        bytes memory data = abi.encodeWithSelector(
            this.anyExecute.selector,
            token,
            dstToken,
            amount,
            msg.sender,
            receiver,
            toChainId
        );
        IAnycallV6Proxy(callProxy).anyCall{value: msg.value}(
            clientPeer,
            data,
            address(this),
            toChainId,
            flags
        );

        if (msg.value > 0) {
            uint256 newCoinBalance = address(this).balance;
            if (newCoinBalance > oldCoinBalance) {
                // return remaining fees
                (bool success, ) = msg.sender.call{
                    value: newCoinBalance - oldCoinBalance
                }("");
                require(success);
            }
        }

        emit LogSwapout(token, msg.sender, receiver, amount, toChainId);
    }

    /// @notice Call by `AnycallProxy` to execute a cross chain interaction on the destination chain
    function anyExecute(bytes calldata data)
        external
        override
        onlyExecutor
        returns (bool success, bytes memory result)
    {
        bytes4 selector = bytes4(data[:4]);
        if (selector == this.anyExecute.selector) {
            (
                address srcToken,
                address dstToken,
                uint256 amount,
                address sender,
                address receiver, //uint256 toChainId

            ) = abi.decode(
                    data[4:],
                    (address, address, uint256, address, address, uint256)
                );

            (address from, uint256 fromChainId, ) = IAnycallExecutor(executor)
                .context();
            require(
                clientPeers[fromChainId] == from,
                "AnycallClient: wrong context"
            );
            require(
                tokenPeers[dstToken][fromChainId] == srcToken,
                "AnycallClient: mismatch source token"
            );

            address _underlying = _getUnderlying(dstToken);

            if (
                _underlying != address(0) &&
                (IERC20(_underlying).balanceOf(dstToken) >= amount)
            ) {
                IAnyswapToken(dstToken).mint(address(this), amount);
                IAnyswapToken(dstToken).withdraw(amount, receiver);
            } else {
                assert(IAnyswapToken(dstToken).mint(receiver, amount));
            }

            emit LogSwapin(dstToken, sender, receiver, amount, fromChainId);
        } else if (selector == 0xa35fe8bf) {
            // bytes4(keccak256('anyFallback(address,bytes)'))
            (address _to, bytes memory _data) = abi.decode(
                data[4:],
                (address, bytes)
            );
            anyFallback(_to, _data);
        } else {
            return (false, "unknown selector");
        }
        return (true, "");
    }

    /// @dev Call back by `AnycallProxy` on the originating chain if the cross chain interaction fails
    function anyFallback(address to, bytes memory data)
        internal
    {
        (address _from, , ) = IAnycallExecutor(executor).context();
        require(_from == address(this), "AnycallClient: wrong context");

        (
            bytes4 selector,
            address srcToken,
            address dstToken,
            uint256 amount,
            address from,
            address receiver,
            uint256 toChainId
        ) = abi.decode(
                data,
                (bytes4, address, address, uint256, address, address, uint256)
            );

        require(
            selector == this.anyExecute.selector,
            "AnycallClient: wrong fallback data"
        );
        require(
            clientPeers[toChainId] == to,
            "AnycallClient: mismatch dest client"
        );
        require(
            tokenPeers[srcToken][toChainId] == dstToken,
            "AnycallClient: mismatch dest token"
        );

        address _underlying = _getUnderlying(srcToken);

        if (
            _underlying != address(0) &&
            (IERC20(srcToken).balanceOf(address(this)) >= amount)
        ) {
            IERC20(_underlying).safeTransferFrom(address(this), from, amount);
        } else {
            assert(IAnyswapToken(srcToken).mint(from, amount));
        }

        emit LogSwapoutFail(srcToken, from, receiver, amount, toChainId);
    }

    function _getUnderlying(address token) internal returns (address) {
        (bool success, bytes memory returndata) = token.call(
            abi.encodeWithSelector(0x6f307dc3)
        );
        if (success && returndata.length > 0) {
            address _underlying = abi.decode(returndata, (address));
            return _underlying;
        }
        return address(0);
    }

    function setILM(address ilmtoken)
        external
        onlyCoreTeam
    {
        ILMaddress = ilmtoken;
        ILM = AnyswapV6ERC20(ILMaddress);
    }

    ////////////////////////////////////////////
    // sending transactions
    ////////////////////////////////////////////

    function createTransaction(address token, address payable to, uint256 amount)
        external
        onlyCoreTeam
    {
        require(amount > 0, "IlluminateERC20Treasury: transaction amount must be > 0");
        if (token == address(0)) { // zero address means FTM
            require(
                amount <= address(this).balance,
                "IlluminateERC20Treasury: transaction amount exceeds FTM balance"
            );
        } else {
            IERC20 TokenToSend = IERC20(token);
            require(
                amount <= TokenToSend.balanceOf(address(this)),
                "IlluminateERC20Treasury: transaction amount exceeds token balance"
            );
        }

        numTransactions += 1;
        transactions[numTransactions].token = token;
        transactions[numTransactions].to = to;
        transactions[numTransactions].amount = amount;
        transactions[numTransactions].approvals = votes[msg.sender];
        votedOnTransaction[msg.sender][numTransactions] = true;
        if (transactions[numTransactions].approvals >= 2) {
            sendTransaction(numTransactions);
        }
    }

    function approveTransaction(uint256 transactionID) 
        external
        onlyCoreTeam
    {   
        require(
            transactions[transactionID].approvals == 1,
            "IlluminateERC20Treasury: transaction sent, canceled, or does not exist"
        );
        require(
            !votedOnTransaction[msg.sender][transactionID],
            "IlluminateERC20Treasury: you already voted on this transaction"
        );
        transactions[transactionID].approvals += votes[msg.sender];
        votedOnTransaction[msg.sender][transactionID] = true;
        if (transactions[transactionID].approvals >= 2) {
            sendTransaction(transactionID);
        }
    }

    function sendTransaction(uint256 transactionID)
        internal
    {
        address token = transactions[transactionID].token;
        address to = transactions[transactionID].to;
        uint256 amount = transactions[transactionID].amount;

        if (token == address(0)) { // zero address means chain native token
            require(
                amount <= address(this).balance,
                "IlluminateERC20Treasury: transaction amount exceeds native token balance"
            );
            payable(to).transfer(amount);           
        } else {
            IERC20 TokenToSend = IERC20(token);
            require(
                amount <= TokenToSend.balanceOf(address(this)),
                "IlluminateERC20Treasury: transaction amount exceeds token balance"
            );
            TokenToSend.transfer(to, amount);
        }

        totalTokenTransferred[token][to] += amount;

        emit transactionSent(token, to, amount);
    }

    function findTransaction(uint256 transactionID)
        external
        view
        returns(_transaction memory)
    {
        return transactions[transactionID];
    }

    function cancelTransaction(uint256 transactionID)
        external
        onlyCoreTeam
    {
        require(
            transactions[transactionID].approvals == 1,
            "IlluminateERC20Treasury: transaction sent, canceled, or does not exist"
        );
        transactions[transactionID].approvals += 100; // 101 votes means canceled
    }

 
    ////////////////////////////////////////////
    // token payments to treasury ("burning")
    ////////////////////////////////////////////

    function payToTreasury(address tokenToPay, uint256 amount, uint256 purpose)
        external
        payable
    {
        if (tokenToPay == address(0)) {
            amount = msg.value;
            require(
                amount > 0,
                "IlluminateERC20Treasury: invalid pay amount"
            );
        } else {
            require(
                amount > 0,
                "IlluminateERC20Treasury: invalid pay amount"
            );
            IERC20 token = IERC20(tokenToPay);
            require(
                token.allowance(msg.sender, address(this)) >= amount,
                "IlluminateERC20Treasury: insufficient allowance to pay"
            );
            require(
                token.balanceOf(msg.sender) >= amount,
                "IlluminateERC20Treasury: not enough tokens in wallet to pay"
            );
            token.transferFrom(msg.sender, address(this), amount);
        }
        
        if (purpose != 0) {
            userTokenPaidPurpose[msg.sender][tokenToPay][purpose] += amount; // pay to specific Purpose
        } 
        userTokenPaidPurpose[msg.sender][tokenToPay][0] += amount; // 0th index is total token paid by user

        totalTokenPaid[tokenToPay] += amount;

        emit treasuryPaid(msg.sender, tokenToPay, purpose, amount);
    }

    // fallback() external payable {}
    // receive() external payable {}

    function getUserPaymentToPurpose(address user, address token, uint256 purpose)
        external
        view
        returns (uint256)
    {
        return userTokenPaidPurpose[user][token][purpose];
    }

    function getTotalTokenTransferred(address token, address to)
        external
        view
        returns (uint256)
    {
        return totalTokenTransferred[token][to];
    }

    //////////////////////////////////////
    // Minting and burning with approvals
    //////////////////////////////////////
    
    function createMintorBurn(bool mint, address to, uint256 amount)
        external
        onlyCoreTeam
    {
        require(amount > 0, "IlluminateERC20Treasury: amount must be > 0");
        
        if (mint) {
            uint256 totalSupply = ILM.totalSupply();        
            require(
                amount + totalSupply <= SUPPLY_CAP,
                "IlluminateERC20Treasury: cannot mint above 6,666,666 ILM total"
            );
        }
        numMintOrBurns += 1;
        mintOrBurns[numMintOrBurns].mint = mint;
        mintOrBurns[numMintOrBurns].to = to;
        mintOrBurns[numMintOrBurns].amount = amount;
        mintOrBurns[numMintOrBurns].approvals = votes[msg.sender];
        votedOnMintOrBurn[msg.sender][numMintOrBurns] = true;
        if (mintOrBurns[numMintOrBurns].approvals >= 2) {
            if (mint) {
                mintILM(amount, to);
            } else {
                burnILM(amount, to);
            }
        }        
    }

    function approveMintOrBurn(uint256 mintOrBurnID) 
        external
        onlyCoreTeam
    {   
        require(
            mintOrBurns[mintOrBurnID].approvals == 1,
            "IlluminateERC20Treasury: mintOrBurn sent, canceled, or does not exist"
        );
        require(
            !votedOnMintOrBurn[msg.sender][mintOrBurnID],
            "IlluminateERC20Treasury: you already voted on this mintOrBurn"
        );
        mintOrBurns[mintOrBurnID].approvals += votes[msg.sender];
        votedOnMintOrBurn[msg.sender][mintOrBurnID] = true;
        if (mintOrBurns[mintOrBurnID].approvals >= 2) {
            uint256 amount = mintOrBurns[mintOrBurnID].amount;
            address to = mintOrBurns[mintOrBurnID].to;
            if (mintOrBurns[mintOrBurnID].mint) {
                mintILM(amount, to);
            } else {
                burnILM(amount, to);
            }     
        }
    }

    function mintILM(uint256 amount, address to) 
        internal
    {
        IAnyswapToken(ILMaddress).mint(to, amount);
    }

    function burnILM(uint256 amount, address from)
        internal
    {
        IAnyswapToken(ILMaddress).burn(from, amount);
    }

    function findMintOrBurn(uint256 mintOrBurnID)
        external
        view
        returns(_mintOrBurn memory)
    {
        return mintOrBurns[mintOrBurnID];
    }

    function cancelMintOrBurn(uint256 mintOrBurnID)
        external
        onlyCoreTeam
    {
        require(
            mintOrBurns[mintOrBurnID].approvals == 1,
            "IlluminateERC20Treasury: mintOrBurn sent, canceled, or does not exist"
        );
        mintOrBurns[mintOrBurnID].approvals += 100; // 101 votes means canceled
    }

    // To remove Kevin elevated votes
    function setKevinVotesToOne()
        external
    {
        require(
            msg.sender == Kevin,
            "IlluminateERC20Treasury: only Kevin allowed"
        );
        votes[Kevin] = 1;
    }
}