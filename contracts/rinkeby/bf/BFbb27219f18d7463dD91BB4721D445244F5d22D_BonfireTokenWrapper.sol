// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../token/IBonfireTokenWrapper.sol";
import "../token/IBonfireProxyToken.sol";
import "../token/IBonfireTokenTracker.sol";
import "../token/IReflectionReceiver.sol";

/**
 * The idea here is for this contract to receive any IERC20 Token, keep it and
 * send a share amount to a given address, upon request from this address it
 * can then again be withdrawn.
 * The share amounts are computed at each withdraw/deposit transaction.
 * Particularly for UniswapV2Pair.swap() calls we need a two step version.
 * Receivers need to implement the IBonfireProxyToken interface.
 * Multichain ProxyTokens (IMultichainToken interface) can mint
 * BonfireTokenWrapper on chains that are not their source chain.
 * The intention is that holders of the wrapped Tokens are Token contracts
 * only. That way the wrapped Token logic and the wrapping logic are
 * independent from each other and easier to verify.
 *
 * Withdraw and withdrawFrom use the same burnShares(from, amount, to)
 * proxyToken function. Proxy tokens need to make sure that allowances are
 * matched if sender and from addresses differ.
 *
 * The BonfireTokenTracker is a contract that for the purpose of this wrapper
 * contract returns a burn wallet address receiving reflection Tokens. The
 * purpose of the tracker is to make sure such observer wallets are referenced
 * in a decentralized way. We use observer wallets to track life reflection
 * instead of percentage values, because it's harder to manipulate and does not
 * require monitoring of excluded wallets.
 * Noteworthy, this technique only works post transaction.
 * For regular Tokens (fixed taxes) an attacker could additionally burn Tokens
 * to the observer wallet for an announced deposit to increase the shares
 * attributed to the current holders. But the attacker cannot decrease the
 * amount received by the observer and can thus not decrease the reflections
 * being attributed to previous proxy Token holders.
 *
 * Deposits and Withdrawals
 * ------------------------
 *
 * Withdrawals from the wrapper are the easy part. We burn wrapped Tokens and
 * release Tokens according to the shares to the recipient. This works (almost)
 * seamless also for allowances. The only minor trouble there is that we need
 * to forward the caller and the assumed sender (msg.sender and sender in
 * _withdrawShares) to the IBonfireProxyToken of interest, since
 * wrapping/unwrapping has to be handled by the BonfireTokenWrapper, while
 * approvals are handled by the IBonfireProxyToken.
 *
 * Deposits are in the general use case a bit more complicated, in particular
 * for Tokens that have more interesting Tokenomics. Common wrapped Tokens,
 * such as wBNB can do this process on the fly, for instance have an account
 * submit BNB to a DEX, have the DEX contract send the BNB to the WBNB contract
 * in exchange for wBNB, have the DEX swap the wBNB for some ExemplaryToken
 * (ET) via sending it to an LP; the ET are now in the calling contracts
 * holdings, the calling contract can now send the ET to a wrapping contract
 * and receive wET in return. Noteworthy, this has two ET transfers happening.
 *
 * For taxed Tokens we want as little as possible Token transfers, so actually
 * only one. In above scenario with two ET transfers we otherwise receive an
 * unfortunate outcome.
 *
 * DEXes built in the shape of Uniswap do allow function calls for the
 * receiver, which would allow to build the functionality for taxed Tokens. But
 * for reflection Tokens this approach does not suffice. For reflection Tokens
 * we have to assume that Token balances increase even if there is no
 * interaction with the TokenWrapper.
 *
 * Before and after each transaction intended for wrapping Tokens we need to
 * track the Token balances of the TokenWrapper contract by the TokenWrapper
 * contract.
 *
 * There are two possible scenarios to deal with this. The first one and more
 * direct is to have the TokenWrapper initiate the swap. This would either
 * require to allow arbitrary external function calls from the TokenWrapper or
 * have knowledge over DEX contracts. Aribtrary external function calls we want
 * to avoid for security concerns, specialised DEX knowledge is very specific
 * and not future proof. The second possibility is to have two-step deposits
 * as implemented in this contract First, announceDeposit to check a
 * beforeBalance, and then executeDeposit, to check afterBalance and finalise
 * the deposit.
 *
 * The intended use of announceDeposit() and executeDeposit() is not only to
 * happen in the same block, but actually within the very same transaction.
 * Hence the described scenario with a hacker executing an attack in between is
 * only possible if a contract implementing a two-step deposit is designed out
 * of the assumed scope.
 *
 * Noteworthy here is an attack someone might be thinking about when reading
 * this. A miner could initiate an announceDeposit() at the beginning of a
 * block containing a huge Token transfer (of some reflection Token) and close
 * the block with an executeDeposit() call. On first sight this seems to imply
 * the reflection gains of that very Token transfer to be solely distributed to
 * that miner. However, by the computations of this contract (and Tokens that
 * have set up a correct observer wallet in BonfireTokenTracker) we are able to
 * distinguish correctly between reflections and incoming transfers. That's
 * sort of the whole point of the construction.
 *
 * Note on Multichain Tokens
 * -------------------------
 *
 * At the time of writing there is no fullfledged solution to ensure that
 * bridges can verifiy Token addresses across blockchains. This becomes
 * especially evident when considering non-EVM-based blockchains. If it was
 * EVM-based blockchains only, we could simply require that contract addresses
 * be the same. The secureBridge variable is dedicated to future solutions that
 * fulfill this requirement.
 * Until then, we need to handle bridgeAllowances. This means that wrapped
 * Multichain Tokens (as intended by this contract) have to create the
 * Token contracts, apply to the bridges and apply to the Bonfire network in
 * order to enable cross-chain transfers.
 *
 * For the time being the Bonfire network is likely to approve only one
 * Multichain Token for each wrapped sourceToken. Given the moveShares function
 * this already allows arbitrary proxyTokens to indirectly move from chain to
 * chain (via conversion to that dedicated multichain token that is).
 *
 * The MultichainToken contract as created by the MultichainTokenFactory does
 * its best to ensure plausible cross-chain activity, but it does not need to
 * be "the" dedicated cross-chain proxy Token contract for all projects. Other
 * Token contracts however need some extended form of auditing. In particular,
 * for each mint we require calling of the reportMint function, for each burn
 * we require calling of the reportBurn function. Obviously the function
 * calling the reportBurn is of particular interest here.
 *
 * Also note, that there is an intended backdoor to making other proxyTokens
 * more cross-chainy. That is, the MultichainToken.burn function does not
 * require bridge access rights, and even increases the corresponding
 * bridgeAllowance. For one, users who accidentally (or intentionally burn
 * their standard MultichainToken tokens, can at a later stage mint the same
 * amount. For another, if a third party ProxyToken (derived from an approved
 * MultichainTokenFactory) dedicates liquidity on the sourceChain to be locked
 * in a bridge contract and liquidity on a different chain to be burned
 * (different form of lock), it can effectively serve to allow cross-chain
 * transfers (in line with the locked liquidity) for this proxyToken directly.
 */

struct PendingDeposit {
    address sourceToken;
    uint256 beforeBalanceObserver;
    uint256 beforeBalanceContract;
    uint256 beforeTotalTokenShares;
    uint256 blockNumber;
}

contract BonfireTokenWrapper is
    Ownable,
    ERC1155Supply,
    IBonfireTokenWrapper,
    IReflectionReceiver
{
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 private constant MAX_INT = 2**256 - 1;

    bool public constant override receiveReflection = true;

    bool private locked;
    PendingDeposit private _pendingDeposit;
    address public constant tokenTracker =
        address(0xBFac04803249F4C14f5d96427DA22a814063A5E1);

    mapping(address => bool) public secureBridge;
    mapping(address => mapping(address => uint256)) public bridgeAllowance;
    mapping(address => bool) public override factory;
    mapping(address => bool) public override multichainToken;

    modifier certifiedToken(address token) {
        require(
            multichainToken[token] == true,
            "BonfireTokenWrapper: token not registered"
        );
        require(
            IBonfireProxyToken(token).chainid() != block.chainid,
            "BonfireTokenWrapper: token is native to the chain"
        );
        _;
    }

    constructor(address _owner) ERC1155("") Ownable() {
        transferOwnership(_owner);
    }

    function setSecureBridge(address account, bool enabled) external onlyOwner {
        secureBridge[account] = enabled;
        emit SecureBridgeUpdate(account, enabled);
    }

    function approveBridge(
        address bridge,
        address proxyToken,
        uint256 allowanceShares
    ) external onlyOwner {
        bridgeAllowance[proxyToken][bridge] = allowanceShares;
        emit BridgeUpdate(
            bridge,
            proxyToken,
            IBonfireProxyToken(proxyToken).sourceToken(),
            IBonfireProxyToken(proxyToken).chainid(),
            allowanceShares
        );
    }

    function addFactory(address account) external onlyOwner {
        factory[account] = true;
        emit FactoryUpdate(account, true);
    }

    function removeFactory(address account) external onlyOwner {
        factory[account] = false;
        emit FactoryUpdate(account, false);
    }

    function addMultichainToken(address target) external override {
        require(
            msg.sender == owner() || factory[msg.sender],
            "BonfireTokenWrapper: not authorised to add MultichainToken"
        );
        multichainToken[target] = true;
        emit MultichainTokenUpdate(target, true);
    }

    function removeMultichainToken(address target) external onlyOwner {
        multichainToken[target] = false;
        emit MultichainTokenUpdate(target, false);
    }

    function reportMint(address bridge, uint256 _shares)
        external
        lock
        certifiedToken(msg.sender)
    {
        if (!secureBridge[bridge]) {
            require(
                bridgeAllowance[msg.sender][bridge] >= _shares,
                "BonfireTokenWrapper: bad bridge"
            );
            unchecked {
                bridgeAllowance[msg.sender][bridge] -= _shares;
            }
        }
        _mint(
            msg.sender,
            tokenid(
                IBonfireProxyToken(msg.sender).sourceToken(),
                IBonfireProxyToken(msg.sender).chainid()
            ),
            _shares,
            new bytes(0)
        );
    }

    function reportBurn(address bridge, uint256 _shares)
        external
        lock
        certifiedToken(msg.sender)
    {
        _burn(
            msg.sender,
            tokenid(
                IBonfireProxyToken(msg.sender).sourceToken(),
                IBonfireProxyToken(msg.sender).chainid()
            ),
            _shares
        );
        bridgeAllowance[msg.sender][bridge] += _shares;
    }

    function tokenid(address token, uint256 chain)
        public
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(token, chain)));
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory metadata)
    {
        metadata = IBonfireTokenTracker(tokenTracker).getURI(_tokenId);
    }

    modifier twoStepLock() {
        require(
            !locked,
            "BonfireTokenWrapper: reentrency detected in two-step deposit"
        );
        require(
            msg.sender.isContract(),
            "BonfireTokenWrapper: two-step deposit allowed only for contracts"
        );
        _;
        delete locked;
    }

    modifier lock() {
        require(!locked, "BonfireTokenWrapper: reentrency detected");
        if (_pendingDeposit.blockNumber > 0) {
            deletePendingDeposit();
        }
        locked = true;
        _;
        delete locked;
    }

    function _multiplier(address sourceToken)
        internal
        view
        returns (uint256 multiplier)
    {
        uint256 balance = IERC20(sourceToken).balanceOf(address(this));
        if (balance != 0) {
            multiplier =
                totalSupply(tokenid(sourceToken, block.chainid)) /
                balance;
        }
        if (multiplier == 0) {
            uint256 MAX_TOKEN = IERC20Metadata(sourceToken).totalSupply();
            uint256 MAX_SHARES = (MAX_INT - (MAX_INT % MAX_TOKEN));
            multiplier = MAX_SHARES / MAX_TOKEN;
        }
    }

    function sharesToToken(address sourceToken, uint256 sharesAmount)
        public
        view
        override
        returns (uint256 tokenAmount)
    {
        uint256 multiplier = _multiplier(sourceToken);
        require(multiplier > 0, "BonfireTokenWrapper: zilch multiplier");
        tokenAmount = sharesAmount / _multiplier(sourceToken);
    }

    function tokenToShares(address sourceToken, uint256 tokenAmount)
        public
        view
        override
        returns (uint256 sharesAmount)
    {
        sharesAmount = tokenAmount * _multiplier(sourceToken);
    }

    function tokenBalanceOf(address sourceToken, address account)
        external
        view
        override
        returns (uint256)
    {
        return
            sharesToToken(
                sourceToken,
                balanceOf(account, tokenid(sourceToken, block.chainid))
            );
    }

    function sharesBalanceOf(uint256 sourceTokenId, address account)
        external
        view
        override
        returns (uint256)
    {
        return balanceOf(account, sourceTokenId);
    }

    function lockedTokenTotal(address sourceToken)
        external
        view
        override
        returns (uint256)
    {
        return
            sharesToToken(
                sourceToken,
                totalSupply(tokenid(sourceToken, block.chainid))
            );
    }

    function moveShares(
        address oldProxy,
        address newProxy,
        uint256 sharesAmount,
        address from,
        address to
    )
        external
        override
        lock
        returns (uint256 tokenAmountOut, uint256 sharesAmountOut)
    {
        IBonfireProxyToken p1 = IBonfireProxyToken(oldProxy);
        IBonfireProxyToken p2 = IBonfireProxyToken(newProxy);
        require(
            p2.wrapper() == address(this),
            "BonfireTokenWrapper: Not the right wrapper"
        );
        require(
            p1.sourceToken() == p2.sourceToken(),
            "BonfireTokenWrapper: Token mismatch"
        );
        require(
            p1.wrapper() == p2.wrapper(),
            "BonfireTokenWrapper: Wrapper mismatch"
        );
        require(
            p1.chainid() == p2.chainid(),
            "BonfireTokenWrapper: Chain mismatch"
        );
        require(
            p1.balanceOf(from) >= p1.sharesToToken(sharesAmount),
            "BonfireTokenWrapper: conversion amount exceeds balance"
        );
        p1.burnShares(from, sharesAmount, msg.sender);
        p2.mintShares(to, sharesAmount);
        _safeTransferFrom(
            oldProxy,
            newProxy,
            tokenid(p2.sourceToken(), p2.chainid()),
            sharesAmount,
            new bytes(0)
        );
        return (p2.sharesToToken(sharesAmountOut), sharesAmountOut);
    }

    function depositToken(
        address proxyToken,
        address recipient,
        uint256 tokenAmount
    ) external lock returns (uint256 tokenGains, uint256 shareGains) {
        address sourceToken = address(
            IBonfireProxyToken(proxyToken).sourceToken()
        );
        address observer = IBonfireTokenTracker(tokenTracker).getObserver(
            sourceToken
        );
        uint256 beforeBalanceObserver = observer == address(0)
            ? uint256(0)
            : IERC20(sourceToken).balanceOf(observer);
        uint256 beforeBalanceContract = IERC20(sourceToken).balanceOf(
            address(this)
        );
        IERC20(sourceToken).safeTransferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );
        uint256 afterBalanceObserver = observer == address(0)
            ? uint256(0)
            : IERC20(sourceToken).balanceOf(observer);
        uint256 afterBalanceContract = IERC20(sourceToken).balanceOf(
            address(this)
        );
        return
            _deposit(
                proxyToken,
                recipient,
                beforeBalanceObserver,
                beforeBalanceContract,
                afterBalanceObserver,
                afterBalanceContract
            );
    }

    function _deposit(
        address proxyToken,
        address recipient,
        uint256 beforeBalanceObserver,
        uint256 beforeBalanceContract,
        uint256 afterBalanceObserver,
        uint256 afterBalanceContract
    ) internal returns (uint256, uint256) {
        address sourceToken = IBonfireProxyToken(proxyToken).sourceToken();
        require(
            IBonfireProxyToken(proxyToken).chainid() == block.chainid,
            "BonfireTokenWrapper: chainid not matching"
        );
        require(
            afterBalanceContract > beforeBalanceContract,
            "BonfireTokenWrapper: Bad deposit"
        );
        uint256 tokenGains;
        if (afterBalanceObserver != beforeBalanceObserver) {
            //in case of reflection adjust reference balance accordingly
            beforeBalanceContract =
                (beforeBalanceContract * afterBalanceObserver) /
                beforeBalanceObserver;
        }
        tokenGains = afterBalanceContract - beforeBalanceContract;
        uint256 shareTotal;
        if (
            beforeBalanceContract > 0 &&
            totalSupply(tokenid(sourceToken, block.chainid)) > 0
        ) {
            uint256 multiplier = totalSupply(
                tokenid(sourceToken, block.chainid)
            ) / beforeBalanceContract;
            shareTotal = tokenGains * multiplier;
        } else {
            //pair initialization
            shareTotal = tokenToShares(sourceToken, tokenGains);
        }
        tokenGains = sharesToToken(sourceToken, shareTotal);
        IBonfireProxyToken(proxyToken).mintShares(recipient, shareTotal);
        _mint(
            proxyToken,
            tokenid(sourceToken, block.chainid),
            shareTotal,
            new bytes(0)
        );
        return (tokenGains, shareTotal);
    }

    function announceDeposit(address sourceToken) external twoStepLock {
        /*
         * Advise for Developers:
         * Make sure to always call executeDeposit() within the same
         * transaction of any announceDeposit() call. You wouldn't be able to
         * do it in the next block anyway (executeDeposit() requirement), and
         * most people don't control transaction orderings in the blocks.
         * Meaning, if you split those two functions into separate
         * transactions, you open the doors for (admittedly very unlikely) MEV
         * attacks.
         *
         * The twoStepLock also checks if the caller is a contract, preventing
         * regular users to call announce and execute functions. It does not
         * verify (1) whether the caller is the same for both functions, and it
         * does neither verify (2) whether already another announceDeposit call
         * might be in progress.
         *
         * (1) This means, that the execute call is allowed to come from a
         * different contract. This check seems unecessary since correct calls
         * are from within the same transaction anyway, so an attack here would
         * require the initial caller to call malicious contracts in the first
         * place, and even give these malicious contracts sufficiant allowance
         * over their funds.
         *
         * (2) Since malicious contracts could announce a deposit and never
         * execute it, any other behaviour would
         * - either restrict the calling capabilities (and allow attackers to
         * prevent other 2-step deposits in the same block),
         * - or unnecessarily bloat this contract's storage (and introduce
         * something like mapping(mapping) structures to handle deposits more
         * specifically. In particular it would make 2-step deposits for all
         * users quite a bit more expensive.
         * The specific implementation thus does not allow to announce a second
         * deposit before executing the first. Upon closer inspection, such an
         * endeavor would only be necessary for the case for things like
         * depositing a taxed token tT in exchange for a taxed proxy token tPtT
         * that immediately is deposited again in exchange for a proxy proxy
         * token PtPtT. By design of this contract the same behaviour can be
         * achieved by using an untaxed proxy Token PtT instead of tPtT, which
         * for the second part (wrapping into PtPtT) would be announced and
         * converted via the moveShares function, still requiring only one
         * transfer for tT and tPtT each.
         */
        _pendingDeposit.sourceToken = sourceToken;
        _pendingDeposit.beforeBalanceObserver = IERC20(sourceToken).balanceOf(
            IBonfireTokenTracker(tokenTracker).getObserver(sourceToken)
        );
        _pendingDeposit.beforeBalanceContract = IERC20(sourceToken).balanceOf(
            address(this)
        );
        _pendingDeposit.beforeTotalTokenShares = totalSupply(
            tokenid(sourceToken, block.chainid)
        );
        _pendingDeposit.blockNumber = block.number;
    }

    function executeDeposit(address proxyToken, address recipient)
        external
        twoStepLock
        returns (uint256 tokenAmount, uint256 sharesAmount)
    {
        require(
            _pendingDeposit.blockNumber == block.number,
            "BonfireTokenWrapper: Deposit needs to be finished within the same block"
        );
        require(
            _pendingDeposit.beforeTotalTokenShares ==
                totalSupply(
                    tokenid(_pendingDeposit.sourceToken, block.chainid)
                ),
            "BonfireTokenWrapper: No other transactions are allowed within deposit"
        );
        uint256 afterBalanceObserver = IERC20(_pendingDeposit.sourceToken)
            .balanceOf(
                IBonfireTokenTracker(tokenTracker).getObserver(
                    _pendingDeposit.sourceToken
                )
            );
        uint256 afterBalanceContract = IERC20(_pendingDeposit.sourceToken)
            .balanceOf(address(this));
        deletePendingDeposit();
        (tokenAmount, sharesAmount) = _deposit(
            proxyToken,
            recipient,
            _pendingDeposit.beforeBalanceObserver,
            _pendingDeposit.beforeBalanceContract,
            afterBalanceObserver,
            afterBalanceContract
        );
    }

    function deletePendingDeposit() internal {
        //delete _pendingDeposit.sourceToken;
        //delete _pendingDeposit.proxyToken;
        //delete _pendingDeposit.recipient;
        //delete _pendingDeposit.sender;
        _pendingDeposit.blockNumber = 1;
        //delete _pendingDeposit.beforeBalance;
        //delete _pendingDeposit.beforeTotalTokenShares;
    }

    function currentDeposit() external view override returns (address) {
        return _pendingDeposit.sourceToken;
    }

    function withdrawShares(
        address proxyToken,
        address recipient,
        uint256 sharesOut
    ) external lock returns (uint256 tokenAmount, uint256 sharesAmount) {
        return _withdrawShares(proxyToken, msg.sender, recipient, sharesOut);
    }

    function withdrawSharesFrom(
        address proxyToken,
        address sender,
        address recipient,
        uint256 sharesOut
    ) external lock returns (uint256 tokenAmount, uint256 sharesAmount) {
        return _withdrawShares(proxyToken, sender, recipient, sharesOut);
    }

    function _withdrawShares(
        address proxyToken,
        address sender,
        address recipient,
        uint256 sharesOut
    ) internal returns (uint256, uint256) {
        require(
            IBonfireProxyToken(proxyToken).chainid() == block.chainid,
            "BonfireTokenWrapper: chainid not matching"
        );
        address sourceToken = address(
            IBonfireProxyToken(proxyToken).sourceToken()
        );
        uint256 tokenAmount = sharesToToken(sourceToken, sharesOut);
        require(
            IBonfireProxyToken(proxyToken).balanceOf(sender) >=
                IBonfireProxyToken(proxyToken).sharesToToken(sharesOut),
            "BonfireTokenWrapper: withdraw amount exceeds balance"
        );
        IBonfireProxyToken(proxyToken).burnShares(
            sender,
            sharesOut,
            msg.sender
        );
        _burn(proxyToken, tokenid(sourceToken, block.chainid), sharesOut);
        IERC20(sourceToken).safeTransfer(recipient, tokenAmount);
        return (tokenAmount, sharesOut);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC1155)
        returns (bool)
    {
        return
            interfaceId == type(IReflectionReceiver).interfaceId ||
            interfaceId == type(IBonfireTokenWrapper).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IBonfireTokenWrapper is IERC1155 {
    event SecureBridgeUpdate(address bridge, bool enabled);
    event BridgeUpdate(
        address bridge,
        address proxyToken,
        address sourceToken,
        uint256 sourceChain,
        uint256 allowanceShares
    );
    event FactoryUpdate(address factory, bool enabled);
    event MultichainTokenUpdate(address token, bool enabled);

    function factory(address account) external view returns (bool approved);

    function multichainToken(address account)
        external
        view
        returns (bool verified);

    function tokenid(address token, uint256 chain)
        external
        pure
        returns (uint256);

    function addMultichainToken(address target) external;

    function reportMint(address bridge, uint256 shares) external;

    function reportBurn(address bridge, uint256 shares) external;

    function tokenBalanceOf(address sourceToken, address account)
        external
        view
        returns (uint256 tokenAmount);

    function sharesBalanceOf(uint256 sourceTokenId, address account)
        external
        view
        returns (uint256 sharesAmount);

    function lockedTokenTotal(address sourceToken)
        external
        view
        returns (uint256);

    function tokenToShares(address sourceToken, uint256 tokenAmount)
        external
        view
        returns (uint256 sharesAmount);

    function sharesToToken(address sourceToken, uint256 sharesAmount)
        external
        view
        returns (uint256 tokenAmount);

    function moveShares(
        address oldProxy,
        address newProxy,
        uint256 sharesAmountIn,
        address from,
        address to
    ) external returns (uint256 tokenAmountOut, uint256 sharesAmountOut);

    function depositToken(
        address proxyToken,
        address to,
        uint256 amount
    ) external returns (uint256 tokenAmount, uint256 sharesAmount);

    function announceDeposit(address sourceToken) external;

    function executeDeposit(address proxyToken, address to)
        external
        returns (uint256 tokenAmount, uint256 sharesAmount);

    function currentDeposit() external view returns (address sourceToken);

    function withdrawShares(
        address proxyToken,
        address to,
        uint256 amount
    ) external returns (uint256 tokenAmount, uint256 sharesAmount);

    function withdrawSharesFrom(
        address proxyToken,
        address from,
        address to,
        uint256 amount
    ) external returns (uint256 tokenAmount, uint256 sharesAmount);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "../token/IBonfireTokenWrapper.sol";

interface IBonfireProxyToken is IERC20, IERC1155Receiver {
    function sourceToken() external view returns (address);

    function chainid() external view returns (uint256);

    function wrapper() external view returns (address);

    function circulatingSupply() external view returns (uint256);

    function transferShares(address to, uint256 amount) external returns (bool);

    function transferSharesFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mintShares(address to, uint256 shares) external;

    function burnShares(
        address from,
        uint256 shares,
        address burner
    ) external;

    function tokenToShares(uint256 amount) external view returns (uint256);

    function sharesToToken(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

interface IBonfireTokenTracker {
    function getObserver(address token) external view returns (address o);

    function getTotalTaxP(address token) external view returns (uint256 p);

    function getReflectionTaxP(address token) external view returns (uint256 p);

    function getTaxQ(address token) external view returns (uint256 q);

    function reflectingSupply(address token, uint256 transferAmount)
        external
        view
        returns (uint256 amount);

    function includedSupply(address token)
        external
        view
        returns (uint256 amount);

    function excludedSupply(address token)
        external
        view
        returns (uint256 amount);

    function storeTokenReference(address token, uint256 chainid) external;

    function tokenid(address token, uint256 chainid)
        external
        pure
        returns (uint256);

    function getURI(uint256 _tokenid) external view returns (string memory);

    function getProperties(address token)
        external
        view
        returns (string memory properties);

    function registerToken(address proxy) external;

    function registeredTokens(uint256 index)
        external
        view
        returns (uint256 tokenid);

    function registeredProxyTokens(uint256 sourceTokenid, uint256 index)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

interface IReflectionReceiver {
    function receiveReflection() external returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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