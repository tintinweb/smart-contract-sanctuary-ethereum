//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../base/NFTBondMarketBase.sol";
import "@openzeppelin/contracts/utils/Address.sol";

//import "hardhat/console.sol";

/// @title Implementaion of the IMarket interface
contract Market is NFTBondMarketBase {
    using Address for address;
        
    /// @notice calculate position premium (in token amount)
    function premium(uint id) public view override returns (uint) {
        return IRiskCalculation(calc).premium(id,0);
    }

    /// @notice calculate position premium with penaulty (in token amount)
    function premiumWithPenaulty(uint id) public view override returns (uint) {
        return IRiskCalculation(calc).premiumWithPenaulty(id,0);
    }

    /// @notice calculate position yield
    function yield(uint id) public view override returns (int) {
        return IRiskCalculation(calc).yield(id,0);
    }

    /// @notice calculate position yield with penaulty (in stable tokens)
    function yieldWithPenaulty(uint id) public view override returns (int) {
        return IRiskCalculation(calc).yieldWithPenaulty(id,0);
    }

    /// @notice calculate fee for new maker position
    function calcNewMakerPosition(uint amount, uint16 term)
        public
        view
        override
        returns (uint fee)
    {
        fee = (amount * makerFee) / 10000;
    }

    /// @notice calculate fee for new taker position
    function calcNewTakerPosition(
        uint amount,
        uint risk,
        uint16 term
    ) public view override returns (uint fee, uint floor) {
        (int price, ,) = price();
        floor = uint(price) * risk/10000;
        fee = amount * takerFee/10000; 
    }     
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import "../base/ManagedMarketBase.sol";
import "../base/TransferableMarketBase.sol";

import "../interfaces/IPositionNFT.sol";

/// @title Implementaion of the IMarket interface
abstract contract NFTBondMarketBase is
    ManagedMarketBase,
    TransferableMarketBase
{
    using SafeERC20 for IERC20;

    /// @notice initialize the contract
    function initialize(
        address _token,
        address _stable,
        address _config,
        address _feed
    ) external override initializer {
        _initMarket(_token, _stable, _config, _feed);
    }

    /// @notice deposit with permit for bonding only
    function depositWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitStable,
        bytes memory permitBump
    ) external override returns (uint id) {
        _bumpBondPermit(bumpAmount, permitBump);

        (uint deadline, uint8 v, bytes32 r, bytes32 s) = _decodePermit(
            permitStable
        );

        return
            depositWithPermit(amount, risk, term, autorenew, deadline, v, r, s);
    }

    /// @notice deposit with permit for bonding only
    function protectWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitToken,
        bytes memory permitBump
    ) external override returns (uint id) {
        _bumpBondPermit(bumpAmount, permitBump);

        (uint deadline, uint8 v, bytes32 r, bytes32 s) = _decodePermit(
            permitToken
        );

        return
            protectWithPermit(amount, risk, term, autorenew, deadline, v, r, s);
    }

    /// @notice deposit with permit for bonding only
    function protectWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint id) {
        _bumpBondPermit(bumpAmount, deadline, v, r, s);

        return protect(amount, risk, term, autorenew);
    }

    /// @notice deposit with permit for bonding only
    function depositWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint id) {
        _bumpBondPermit(bumpAmount, deadline, v, r, s);
        return deposit(amount, risk, term, autorenew);
    }

    /// @notice deposit with permit
    function depositWithPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override returns (uint id) {
        IERC20Permit(address(stable)).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        return deposit(amount, risk, term, autorenew);
    }

    function protectWithPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override returns (uint id) {
        IERC20Permit(address(token)).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        return protect(amount, risk, term, autorenew);
    }

    /// @notice create new taker position (override with NFT mint)
    function protect(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) public virtual override returns (uint id) {
        // gas saving
        address _token = address(token);

        // lock BUMP tokens using Bond contract
        (uint bumpAmount, , uint reduceAmount) = bond.autoLockBondTakerPosition(
            msg.sender,
            address(this),
            amount,
            risk,
            term
        );
        amount -= reduceAmount;

        // open position and transfer tokens
        uint id = super.protect(amount, risk, term, autorenew);
        // update bumpAmount for position
        allTakerPositions[id].bumpAmount = bumpAmount;
        // mint token for position
        IPositionNFT(config.getNFTTaker(_token)).safeMint(msg.sender, id);

        return id;
    }

    /// @notice create new taker position using native token (override with NFT mint)
    function protectNative(
        uint16 risk,
        uint16 term,
        bool autorenew
    ) public payable virtual override returns (uint id) {
        // lock BUMP tokens using Bond contract
        (uint bumpAmount, , uint reduceAmount) = bond.autoLockBondTakerPosition(
            msg.sender,
            address(this),
            msg.value,
            risk,
            term
        );
        // open position and transfer tokens
        _wrapNativeToken();
        uint id = _protect(
            msg.sender,
            msg.value - reduceAmount,
            risk,
            term,
            autorenew
        );
        // update bumpAmount for position
        allTakerPositions[id].bumpAmount = bumpAmount;
        // mint token for position
        IPositionNFT(config.getNFTTaker(address(token))).safeMint(msg.sender, id);

        return id;
    }

    /// @notice close position (override with NFT burn)
    function close(uint id) public virtual override {
        // get locked BUMP token amount for this position
        uint bumpAmount = allTakerPositions[id].bumpAmount;
        // unlock BUMP tokens
        if (bumpAmount > 0) {
            bond.unlock(msg.sender, address(this), bumpAmount);
        }
        // Burn position NFT token
        IPositionNFT(config.getNFTTaker(address(token))).safeBurn(id);
        // close position
        super.close(id);
    }

    /// @notice cancel position (override with NFT burn)
    function cancel(uint id) public virtual override {
        // get locked BUMP token amount for this position
        uint bumpAmount = allTakerPositions[id].bumpAmount;
        // unlock BUMP tokens
        if (bumpAmount > 0) {
            bond.unlock(msg.sender, address(this), bumpAmount);
        }
        // Burn position NFT token
        IPositionNFT(config.getNFTTaker(address(token))).safeBurn(id);
        // close position
        super.cancel(id);
    }

    /// @notice create new maker position (override with NFT mint)
    function deposit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) public virtual override returns (uint id) {
        // gas saving
        address _token = address(token);
        // lock BUMP tokens using Bond contract
        (uint bumpAmount, , uint reduceAmount) = bond.autoLockBondMakerPosition(
            msg.sender,
            address(this),
            amount,
            risk,
            term
        );
        // deposit tokens and open position
        uint id = super.deposit(amount - reduceAmount, risk, term, autorenew);
        // set BUMP tokens for this position
        allMakerPositions[id].bumpAmount = bumpAmount;
        // mint position NFT token
        IPositionNFT(config.getNFTMaker(_token)).safeMint(
            msg.sender,
            id
        );

        return id;
    }

    /// @notice close maker position (override with NFT burn)
    function withdraw(uint id) public virtual override {
        // get locked BUMP tokens for this position
        uint bumpAmount = allMakerPositions[id].bumpAmount;
        // unlock BUMP tokens using Bond contract
        if (bumpAmount > 0) {
            bond.unlock(msg.sender, address(this), bumpAmount);
        }
        // burn position NFT token
        IPositionNFT(config.getNFTMaker(address(token))).safeBurn(id);
        // withdraw tokens and close position
        super.withdraw(id);
    }

    /// @notice cancel position (override with NFT burn)
    function abandon(uint id) public virtual override {
        // get locked BUMP token amount for this position
        uint bumpAmount = allTakerPositions[id].bumpAmount;
        // unlock BUMP tokens
        if (bumpAmount > 0) {
            bond.unlock(msg.sender, address(this), bumpAmount);
        }
        // Burn position NFT token
        IPositionNFT(config.getNFTMaker(address(token))).safeBurn(id);
        // close position
        super.abandon(id);
    }

    function _bumpBondPermit(
        uint amount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        IERC20Permit(address(bump)).permit(
            msg.sender,
            address(bond),
            amount,
            deadline,
            v,
            r,
            s
        );
    }

    function _bumpBondPermit(uint amount, bytes memory permitBump) private {
        (uint deadline, uint8 v, bytes32 r, bytes32 s) = _decodePermit(
            permitBump
        );
        _bumpBondPermit(amount, deadline, v, r, s);
    }

    function _decodePermit(bytes memory permitEncoded)
        private
        pure
        returns (
            uint deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        (deadline, v, r, s) = abi.decode(
            permitEncoded,
            (uint, uint8, bytes32, bytes32)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../base/MarketBase.sol";

import "../interfaces/IMarket.sol";
import "../interfaces/IMarketManagement.sol";
import "../interfaces/IProtocolConfig.sol";
import "../interfaces/IRebalanceCalculation.sol";
import "../interfaces/ISwap.sol";

/// @notice Implementaion of the IMarketManagement interface
abstract contract ManagedMarketBase is MarketBase, IMarketManagement {
    using SafeERC20 for IERC20;

    bytes32 public constant ARBITRAGER_ROLE = keccak256("ARBITRAGER_ROLE");

    bytes public buySwapEncodedPath;
    bytes public sellSwapEncodedPath;

    uint public makerFee;
    uint public takerFee;

    modifier onlyArbitrager() {
        require(bac.userHasRole(ARBITRAGER_ROLE, msg.sender), "!arbitrager");
        _;
    }

    // Events
    event Rebalanced();
    event Shortfall();

    /// @notice set fees in makers for takers and makers in percentage (1% = 100, 100% = 10000)
    function setFees(uint _takerFee, uint _makerFee)
        external
        override
        onlyGovernance
    {
        takerFee = _takerFee;
        makerFee = _makerFee;
    }

    // @notice minimal position size management function
    function setMinPositionSize(uint minMaker, uint minTaker)
        external
        override
        onlyGovernance
    {
        minTakerPositionSize = minTaker;
        minMakerPositionSize = minMaker;
    }

    // @notice update market state
    function update() external virtual override {}

    function isRebalanceNeeded() external view virtual override returns (bool) {
        (int quantity, uint discount) = IRebalanceCalculation(calc)
            .rebalanceAmount();
        return quantity != 0;
    }

    /// @notice rebalance flow implementation
    function rebalance() external virtual override onlyArbitrager {
        (int quantity, uint discount) = IRebalanceCalculation(calc)
            .rebalanceAmount();

        require(quantity != 0, "!rebalance");

        if (quantity > 0) {
            AP -= uint(quantity);
            CP += ISwap(swap).swapExactTokensForTokensMult(
                sellSwapEncodedPath,
                uint(quantity),
                0
            );
        } else if (quantity < 0) {
            CP -= (uint(-quantity));
            AP += ISwap(swap).swapExactTokensForTokensMult(
                buySwapEncodedPath,
                uint(-quantity),
                0
            );
        }

        emit Rebalanced();
    }

    /// @notice shortfall flow implementation
    function shortfall() external virtual override {
        emit Shortfall();
    }

    /// @notice Set swap smart contract and swap paths
    function setSwap(
        address _swap,
        bytes memory _buySwapEncodedPath,
        bytes memory _sellSwapEncodedPath
    ) external {
        swap = _swap;

        stable.approve(swap, 0);
        stable.approve(swap, type(uint).max);
        token.approve(swap, 0);
        token.approve(swap, type(uint).max);

        buySwapEncodedPath = _buySwapEncodedPath;
        sellSwapEncodedPath = _sellSwapEncodedPath;
    }

    /// @notice Withdraw for govenance
    function govWithdraw(
        address _token,
        address to,
        uint amount
    ) external virtual override onlyGovernance {
        IERC20(_token).safeTransfer(to, amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "../interfaces/IMarketPositionTransfer.sol";

import "../base/MarketBase.sol";

abstract contract TransferableMarketBase is IMarketPositionTransfer, MarketBase {

    /// @notice Get taker position owner
    function ownerOfTakerPosition(uint id) public view override returns (address) {  
        return allTakerPositions[id].owner;
    }

    /// @notice Transfer taker position from one owner to another
    /// @param from - current owner of the position NFT
    /// @param to - new owner of the position NFT
    function safeTransferTakerPosition(address from, address to, uint id) external override {
        require(allTakerPositions[id].owner == from, "!t-owner" );
        bond.transferLocked(address(token), from, to, allTakerPositions[id].bumpAmount );
        allTakerPositions[id].owner = to;
    }

    /// @notice Check if given taker position is exists
    function existsTakerPosition(uint id) external override view returns (bool) {
        return allTakerPositions[id].owner != address(0);
    }    

    /// @notice Get owner of maker position
    function ownerOfMakerPosition(uint id) public view override returns (address) {     
        return allMakerPositions[id].owner;
    }

    /// @notice Transfer maker position from one owner to another
    /// @param from - current owner of the position NFT
    /// @param to - new owner of the position NFT
    function safeTransferMakerPosition(address from, address to, uint id) external override {
        require(allMakerPositions[id].owner == from, "!m-owner" );
        bond.transferLocked(address(token), from, to, allMakerPositions[id].bumpAmount );
        allMakerPositions[id].owner = to;   
    }

    /// @notice Check if given maker position is exists
    function existsMakerPosition(uint id) external override view returns (bool) {
        return allMakerPositions[id].owner != address(0);
    }    

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";

/// @title Position NFT interface
interface IPositionNFT {
    function safeMint(address to, uint tokenId) external;
    function safeBurn(uint tokenId) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../base/MarketStorage.sol";

import "../access/BACUpgradable.sol";

import "../interfaces/IWETH9.sol";
import "../interfaces/IMarket.sol";
import "../interfaces/IMarketStates.sol";
import "../interfaces/IProtocolConfig.sol";
import "../interfaces/IRiskCalculation.sol";
import "../interfaces/ITakerPositionRate.sol";
import "../interfaces/IBond.sol";

/// @notice Implementaion of the IMarket interface
abstract contract MarketBase is
    MarketStorage,
    Initializable,
    BACUpgradable,
    IMarket
{
    using SafeERC20 for IERC20;

    uint public DIVIDER;
    uint public constant DIVIDER_ORACLE = 10**8;
    uint public constant DIVIDER_STABLE = 10**6;

    IBond public bond;

    /// @notice check if the given taker position is ended
    modifier takerTermEnds(uint id) {
        require(
            block.timestamp >
                (allTakerPositions[id].start + allTakerPositions[id].term),
            "!end"
        );
        _;
    }

    /// @notice check if the given maker position is ended
    modifier makerTermEnds(uint id) {
        require(
            block.timestamp >
                (allMakerPositions[id].start + allMakerPositions[id].term),
            "!end"
        );
        _;
    }

    /// @notice initialize the contract
    function _initMarket(
        address _token,
        address _stable,
        address _config,
        address _feed
    ) internal {
        token = IERC20(_token);
        stable = IERC20(_stable);
        config = IProtocolConfig(_config);
        bump = IERC20(IProtocolConfig(_config).getBump());
        bToken = IERC20(IProtocolConfig(_config).getBToken(_token));
        feed = _feed;

        DIVIDER = 10**IERC20Metadata(_token).decimals();

        _setGlobalAccessController(config.getGAC());
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice set bond contract
    function setBond(address _bond) external onlyGovernance {
        bond = IBond(_bond);
    }

    /// @notice set risk calculation contract
    function setRiskCalc(address _calc) external onlyGovernance {
        calc = _calc;
    }

    /// @notice get current risk calculation contract
    function getRiskCalc() public view override returns (address) {
        return calc;
    }    

    /// @notice get structure containing taker position information
    function getTakerPosition(uint id)
        public
        view
        virtual
        override
        returns (TakerPosition memory)
    {
        return allTakerPositions[id];
    }

    /// @notice get structure containing maker position information
    function getMakerPosition(uint id)
        public
        view
        virtual
        override
        returns (MakerPosition memory)
    {
        return allMakerPositions[id];
    }

    /// @notice protect native token (ETH for Etherium blockchain)
    function protectNative(
        uint16 risk,
        uint16 term,
        bool autorenew
    ) public payable virtual override returns (uint id) {
        _wrapNativeToken();
        return _protect(msg.sender, msg.value, risk, term, autorenew);
    }

    /// @notice create new maker position
    function protect(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) public virtual override returns (uint id) {
        require(amount >=  minTakerPositionSize, "!tminsize");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return _protect(msg.sender, amount, risk, term, autorenew);
    }

    /// @notice virtual function to calculate premium
    function premium(uint id) public view virtual override returns (uint);

    /// @notice virtual function to calculate yield
    function yield(uint id) public view virtual override returns (int);

    /// @notice virtual function to calculate premium with penaulty
    function premiumWithPenaulty(uint id)
        public
        view
        virtual
        override
        returns (uint);

    /// @notice virtual function to calculate yield with penaulty
    function yieldWithPenaulty(uint id)
        public
        view
        virtual
        override
        returns (int);

    /// @notice close taker position
    function close(uint id) public virtual override takerTermEnds(id) {
        TakerPosition storage pos = allTakerPositions[id];
        require(msg.sender == pos.owner, "!owner");

        uint posPremium = premium(id);
        uint rate = uint(int(ITakerPositionRate(calc).getRate(pos.risk, pos.term)));

        AP -= pos.assetAmount;
        RWAP -= pos.assetAmount * rate / DIVIDER;
        L -= (pos.floor * pos.assetAmount) / DIVIDER;
        B -= pos.assetAmount;
        AR += posPremium;

        uint amountToReturn = pos.assetAmount - posPremium;
        token.safeTransfer(pos.owner, amountToReturn);

        delete allTakerPositions[id];

        emit Closed(
            address(this),
            msg.sender,
            id,
            amountToReturn,
            posPremium
        );
    }

    /// @notice claim stable coins for opened position
    function claim(uint id) external virtual override takerTermEnds(id) {
        TakerPosition storage pos = allTakerPositions[id];
        require(msg.sender == pos.owner, "!owner");

        (int _price,, ) = price();
        require(uint(_price) < pos.floor, "!floor" );

        _price = int(DIVIDER_STABLE) * _price / int(DIVIDER_ORACLE);

        uint rate = uint(int(ITakerPositionRate(calc).getRate(pos.risk, pos.term)));

        uint p = premium(id);

        AP -= pos.assetAmount;
        AR += pos.assetAmount;
        RWAP -= pos.assetAmount * rate / DIVIDER;
        L -= (pos.floor * pos.assetAmount) / DIVIDER;
        B -= pos.assetAmount; 
        
        uint claimSizeInStable = (pos.assetAmount - p) * uint(_price) / DIVIDER;
        CP -= claimSizeInStable;

        stable.safeTransfer(
            pos.owner,
            claimSizeInStable
        );

        delete allTakerPositions[id];        

        emit Claimed(address(this), msg.sender, id, claimSizeInStable, pos.floor);
    }

    /// @notice close taker position
    function cancel(uint id) public virtual override takerTermEnds(id) {
        TakerPosition storage pos = allTakerPositions[id];
        require(msg.sender == pos.owner, "!owner");

        uint _premium = premiumWithPenaulty(id);

        AP -= pos.assetAmount;
        L -= (pos.floor * pos.assetAmount) / DIVIDER;
        B -= pos.assetAmount;
        AR += _premium;

        uint amountToReturn = pos.assetAmount - _premium;
        token.safeTransfer(pos.owner, amountToReturn);

        delete allTakerPositions[id];

        emit Canceled(
            address(this),
            msg.sender,
            id,
            amountToReturn,
            _premium
        );
    }

    /// @notice create new maker position
    function deposit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) public virtual override returns (uint id) {
        require(amount > minMakerPositionSize, "!mminsize");

        // transfer tokens from msg.sender to the contract
        IERC20(stable).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint fee = calcNewMakerPosition(amount, term);

        MakerPosition memory pos = MakerPosition({
            owner: msg.sender,
            stableAmount: amount - fee,
            start: block.timestamp,
            term: term,
            risk: risk,
            autorenew: autorenew,
            bumpAmount: 0, // BUMP amount will be set later
            ci: 0
        });

        allMakerPositions[makerPosIndex] = pos;

        CP += pos.stableAmount;
        CR += fee;
        D += pos.stableAmount;

        emit Deposited(
            address(this),
            msg.sender,
            makerPosIndex,
            amount,
            risk,
            term
        );

        return makerPosIndex++;
    }

    /// @notice close maker position
    function withdraw(uint id) public virtual override {
        MakerPosition storage pos = allMakerPositions[id];
        require(msg.sender == pos.owner, "!owner");

        int _yield = yield(id);

        uint amount = uint(int(pos.stableAmount) + _yield);

        D -= amount;
        CP -= amount;

        stable.safeTransfer(pos.owner, amount);

        emit Withdrawn(address(this), msg.sender, id, pos.stableAmount, _yield);

        delete allMakerPositions[id];
    }

    /// @notice cancel maker position with penaulty fee
    function abandon(uint id) public virtual override {
        MakerPosition storage pos = allMakerPositions[id];
        require(msg.sender == pos.owner, "!owner");

        int _yield = yieldWithPenaulty(id);
        stable.safeTransfer(pos.owner, uint(int(pos.stableAmount) + _yield));

        emit Withdrawn(address(this), msg.sender, id, pos.stableAmount, _yield);

        delete allMakerPositions[id];
    }

    /// @notice Get market state parameters
    function getState()
        public
        view
        virtual
        override
        returns (
            uint _AP,
            uint _AR,
            uint _CP,
            uint _CR,
            uint _B,
            uint _L,
            uint _D
        )
    {
        // balanceETH, balanceUSDC, B, D -> AP,AR,CP,CR
        return (
            AP,
            AR,
            CP,
            CR,
            B,
            L,
            D
        );
    }

    // INTERNAL
    /// @notice create new maker position
    function _protect(
        address account,
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) internal virtual returns (uint id) {
        (uint fee, uint floor) = calcNewTakerPosition(amount, risk, term);
        TakerPosition memory pos = TakerPosition({
            owner: account,
            assetAmount: amount - fee,
            risk: risk,
            start: block.timestamp,
            term: term,
            floor: floor,
            autorenew: autorenew,
            bumpAmount: 0, // BUMP amount will be set later
            ci: 0
        });

        allTakerPositions[takerPosIndex] = pos;

        // update market state variables
        AP += pos.assetAmount;
        AR += fee;
        RWAP += pos.assetAmount * uint(int(ITakerPositionRate(calc).getRate(pos.risk, pos.term))) / DIVIDER;
        L += pos.floor * pos.assetAmount / DIVIDER;
        B += pos.assetAmount;        

        emit Protected(
            address(this),
            account,
            takerPosIndex,
            floor,
            pos.assetAmount,
            risk,
            term,
            autorenew
        );

        return takerPosIndex++;
    }

    /// HELPERS
    /// @notice calculate fee for new taker position
    function calcNewTakerPosition(
        uint amount,
        uint risk,
        uint16 term
    ) public view virtual returns (uint fee, uint floor);

    /// @notice calculate fee for new maker position
    function calcNewMakerPosition(uint amount, uint16 term)
        public
        view
        virtual
        returns (uint fee);

    /// @notice Wrap native token
    function _wrapNativeToken() internal virtual {
        IWETH9(config.getWrappedNativeToken()).deposit{value: msg.value}();
    }

    /// @notice Get current price from oracle
    function price()
        public
        view
        virtual
        override
        returns (int _price, uint _updatedAt, uint80 _roundId)
    {
        (_roundId, _price, , _updatedAt, ) = AggregatorV3Interface(feed)
            .latestRoundData();
    }

    function priceAt(uint80 _roundId)
        public
        view
        virtual
        override
        returns (int _price, uint _updatedAt)
    {
        (, _price, , _updatedAt, ) = AggregatorV3Interface(feed)
            .getRoundData(_roundId);
    }    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";
import "./IMarketStorage.sol";
import "./IMakerPosition.sol";
import "./ITakerPosition.sol";

interface IMarket is IMarketStorage, IMakerPosition, ITakerPosition {
    
    function initialize(address token, address stable, address config, address feed) external;

    function price() external view returns (int _price, uint _updatedAt, uint80 _roundId);

    function priceAt(uint80 roundId) external view returns (int _price, uint _updatedAt);

    function getState()
        external
        view
        returns (
            uint AP,
            uint AR,
            uint CP,
            uint CR,
            uint B,
            uint L,
            uint D
        );

    function getRiskCalc() external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";

/// @notice Market management interface (onlyGovernance)
interface IMarketManagement {
    function setMinPositionSize( uint minMaker, uint minTaker ) external;
    
    function setFees(uint _takerFee, uint _makerFee) external;

    function update() external;

    function shortfall() external;

    function rebalance() external;
    
    function isRebalanceNeeded() external view returns(bool);

    function govWithdraw(
        address _token,
        address to,
        uint amount
    ) external;

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../configuration/MarketConfig.sol";

/// @notice Interface for accessing protocol configuration parameters
interface IProtocolConfig {
    /// @notice get Global access controller
    function getGAC() external view returns (address);

    /// @notice Version of the protocol
    function getVersion() external view returns (uint16);

    /// @notice Stable coin address
    function getStable() external view returns (address);

    /// @notice Configuration params of the given token market
    function getConfig(address token)
        external
        view
        returns (MarketConfig memory config);

    /// @notice Get address of NFT maker for given market
    function getNFTMaker(address token) external view returns (address);
    
    /// @notice Get address of NFT taker for given market
    function getNFTTaker(address token) external view returns (address);

    /// @notice Get address of B-token for given market
    function getBToken(address token) external view returns (address);

    /// @notice Get market contract address by token address
    function getMarket(address token) external view returns (address);

    /// @notice Get wrapped native market address
    function getWrappedNativeMarket() external view returns (address);

    /// @notice Get wrapped native token address
    function getWrappedNativeToken() external view returns (address);

    /// @notice Get BUMP token address
    function getBump() external view returns (address);

    /// @notice Get IMarketStates contract implementation address
    function getState() external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";

/// @notice Rebalance parameters calculation
interface IRebalanceCalculation {
    function rebalanceAmount()
        external
        view
        returns (int quantity, uint discount);

    function calculateRebalanceAmount(
        int AP,
        int AR,
        int CP,
        int CR,
        int B,
        int L,
        int D,
        int shock,
        int surge,
        int Pclaim
    ) external pure returns (int);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title ISwap.
interface ISwap {
    /// @notice emits when ETH -> ERC20 token swap executed.
    event SwappedExactEthForTokens(
        address indexed from,
        uint ethAmountIn,
        address indexed tokenOut,
        uint amountOut
    );

    /// @notice emits when ERC20 -> ETH token swap executed.
    event SwappedExactTokensForEth(
        address indexed from,
        address indexed tokenIn,
        uint amountIn,
        uint ethAmountOut
    );

    /// @notice emits when ERC20 -> ERC20 token swap executed.
    event SwappedExactTokensForTokens(
        address indexed from,
        address indexed tokenIn,
        uint amountIn,
        address indexed tokenOut,
        uint amountOut
    );

    /// @notice should be emitted on pair fee set
    event SetFee(address indexed token0, address indexed token1, uint24 fee);

    /// @notice returns router address.
    function router() external view returns (address);

    /// @notice returns wETH token address.
    // solhint-disable-next-line func-name-mixedcase
    function WETH() external view returns (address);

    /// @notice get pool fee for V3 LP
    /// @return fee - pool fee
    function poolFee(address tokenA, address tokenB) external returns (uint24 fee);

    /// @notice set swap pool fee
    /// @dev should be implemented only for V3 adapters
    /// @param tokenA one of two pool tokens
    /// @param tokenB another pool token
    /// @param fee V3 LP fee
    function setPoolFee(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external;

    /// @notice executes ETH -> ERC20 swap.
    /// @param tokenOut - address of output token.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output token.
    function swapExactEthForTokens(
        address tokenOut,
        uint amountOutMin,
        uint24 fee
    ) external payable returns (uint amountOut);

    /// @notice executes ERC20 -> ETH swap.
    /// @param tokenIn - address of input token.
    /// @param amountIn - amount of input token.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output ETH.
    function swapExactTokensForEth(
        address tokenIn,
        uint amountIn,
        uint amountOutMin,
        uint24 fee
    ) external returns (uint amountOut);

    /// @notice executes ERC20 -> ERC20 swap.
    /// @param tokenIn - address of input token.
    /// @param amountIn - amount of input token.
    /// @param tokenOut - address of input token.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output token.
    function swapExactTokensForTokens(
        address tokenIn,
        uint amountIn,
        address tokenOut,
        uint amountOutMin,
        uint24 fee
    ) external returns (uint amountOut);

    /// @notice executes any swap with some path
    /// @param path - encoded variant of path (for V2 - addresses, for V3 - addresses and fees)
    /// @param amountIn - amount of input token
    /// @param amountOutMin - min amount for transaction to not be reverted
    /// @return amountOut - amount of output token
    function swapExactTokensForTokensMult(
        bytes memory path,
        uint amountIn,
        uint amountOutMin
    ) external returns (uint amountOut);

    /// @notice executes any swap with some path
    /// @dev for v3 fees should be retrieved from adapter
    /// @param rawPath swap path
    /// @param amountIn - amount of input token
    /// @param amountOutMin - min amount for transaction to not be reverted
    /// @return amountOut - amount of output token
    function swapExactTokensForTokensMultRawPath(
        address[] memory rawPath,
        uint amountIn,
        uint amountOutMin
    ) external returns (uint amountOut);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "../interfaces/IMarketStorage.sol";
import "../interfaces/IProtocolConfig.sol";
import "../interfaces/IMarketStates.sol";

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";

/// @notice Market storage that contains takers and makers positions and market variables (AP,AR,CP,CR,L,B,D)
contract MarketStorage is IMarketStorage {
    // tokens
    IERC20 public override token;
    IERC20 public override bToken;
    IERC20 public override stable;
    IERC20 public override bump;

    IProtocolConfig public override config;
    IMarketStates public override state;

    // price feed address
    address public feed;

    // swapper address
    address public swap;

    // risk calculation address
    address public calc;

    uint public takerPosIndex; // counter of taker position id

    uint public override AP; // Asset pool (in tokens with DIVIDER precision)
    uint public override AR; // Asset reserve (in tokens with DIVIDER precision)
    uint public override B; // Book (in tokens with DIVIDER precision)
    uint public override L; // Liability in ORACLE precision
    uint public override RWAP;    
 
    // minimal position sizes
    uint public override minTakerPositionSize;
    uint public override minMakerPositionSize;

    // takers positions
    mapping(uint => TakerPosition) allTakerPositions;

    // MAKER DATA
    uint makerPosIndex;
    uint public override CP; // Capital pool
    uint public override CR; // Capital reserve
    uint public override D; // Debt

    // makers positions
    mapping(uint => MakerPosition) public allMakerPositions;

}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../interfaces/IGlobalAccessControl.sol";

/// @notice Bumper Access Control for upgradable contracts
abstract contract BACUpgradable is AccessControlUpgradeable {
    bytes32 public constant LOCAL_GOVERNANCE_ROLE =
        keccak256("LOCAL_GOVERNANCE_ROLE");
    bytes32 public constant GLOBAL_GOVERNANCE_ROLE =
        keccak256("GLOBAL_GOVERNANCE_ROLE");

    IGlobalAccessControl bac;

    function __BACUpgradable__init() internal onlyInitializing {}

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "!bacu-admin");
        _;
    }

    modifier onlyGovernance() {
        require(
            hasRole(LOCAL_GOVERNANCE_ROLE, msg.sender) ||
                bac.userHasRole(GLOBAL_GOVERNANCE_ROLE, msg.sender),
            "!bacu-governance"
        );
        _;
    }

    modifier onlyLocalGovernance() {
        require(hasRole(LOCAL_GOVERNANCE_ROLE, msg.sender), "!bacu-lgov");
        _;
    }

    modifier onlyGlobalGovernance() {
        require(
            bac.userHasRole(GLOBAL_GOVERNANCE_ROLE, msg.sender),
            "!bacu-ggov"
        );
        _;
    }

    function _setGlobalAccessController(address _bac) internal {
        bac = IGlobalAccessControl(_bac);
    }

    function grantRole(bytes32 role, address account)
        public
        override
        onlyAdmin
    {
        super.grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyAdmin
    {
        super.revokeRole(role, account);
    }

    function userHasRole(bytes32 role, address account)
        public
        view
        returns (bool)
    {
        return bac.userHasRole(role, account);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../struct/MarketState.sol";

/// @notice Interface for accessing and managing markets states/prices
interface IMarketStates {
    /// @notice get calculated average price in 64.64 format
    function getWeightedAvgPrice(address token) external view returns (int);

    /// @notice get current market state parameters
    function getCurrentState(address token)
        external
        view
        returns (MarketState memory data);

    /// @notice update market state for given tokens
    function updateStates(address[] memory tokens) external;

    /// @notice update prices, average and price components
    function updatePrices(address[] memory tokens) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IMarket.sol";

interface IRiskCalculation {

    function PAP(uint80 roundId) external view returns (int _PAP);

    function epsilon(uint ci) external view returns (int);

    function premium(uint id, uint ci) external view returns (uint);

    function premiumWithPenaulty(uint id, uint ci) external view returns (uint);

    function yield(uint id, uint ci) external view returns (int);

    function yieldWithPenaulty(uint id, uint ci) external view returns (int);
    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITakerPositionRate {
    function getRate(
        uint16 risk,
        uint16 term
    ) external pure returns (int128);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../struct/BondConfig.sol";

/// @title IBond
interface IBond {
    /// @return address of token which contract stores
    function bondToken() external view returns (address);

    /// @notice transfers amount from your address to contract
    /// @param depositTo - address on which tokens will be deposited
    /// @param amount - amount of token to store in contract
    function deposit(address depositTo, uint256 amount) external;

    function depositWithPermit(
        address depositTo,
        uint256 amount, 
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice transfers amount from your address to contract
    /// @param amount - amount of token to withdraw from contract
    function withdraw(uint256 amount) external;

    /// @notice locks amount of token in contract
    /// @param _owner - owner of the position
    /// @param market - market address
    /// @param amount - amount of token to lock
    /// @param risk - risk in percentage with 100 multiplier (9000 means 90%)
    /// @param term - term (in days) of protection
    /// @return bondAmount to lock based on taker position
    function lockForTaker(
        address _owner,
        address market,
        uint256 amount,
        uint16 risk,
        uint16 term
    ) external returns (uint256 bondAmount);

    /// @notice locks amount of token in contract
    /// @param _owner - owner of the position
    /// @param market - market address
    /// @param amount - amount of stable token to lock
    /// @param risk - risk number (1-5)
    /// @param term - term (in days) of protection
    /// @return bondAmount to lock based on maker position
    function lockForMaker(
        address _owner,
        address market,
        uint256 amount,
        uint16 risk,
        uint16 term
    ) external returns (uint256 bondAmount);

    /// @notice unlocks amount of token in contract
    /// @param market - market address
    /// @param _owner - owner of the position
    /// @param bondAmount - amount of bond token to unlock
    function unlock(
        address _owner,
        address market,
        uint256 bondAmount
    ) external;

    /// @notice calculates taker's bond to lock in contract
    /// @param market - market address
    /// @param amount - amount of asset token
    /// @param risk - risk in percentage with 100 multiplier (9000 means 90%)
    /// @param term - term (in days) of protection
    /// @return bondAmount to lock based on taker position
    function takerBond(
        address market,
        uint256 amount,
        uint16 risk,
        uint16 term
    ) external view returns (uint256 bondAmount);

    /// @notice calculates maker's bond to lock in contract
    /// @param market - market address
    /// @param amount - amount of stable token to lock
    /// @param risk - risk number (1-5)
    /// @param term - term (in days) of protection
    /// @return bondAmount to lock based on maker position
    function makerBond(
        address market,
        uint256 amount,
        uint16 risk,
        uint16 term
    ) external view returns (uint256 bondAmount);

    function takerToSwap(
        address market,
        uint bondAmount
    ) external view returns (uint amount);

    function makerToSwap(
        address market,
        uint bondAmount
    ) external view returns (uint amount);

    function autoLockBondTakerPosition(
        address recipient,
        address market, 
        uint amount, 
        uint16 risk, 
        uint16 term
    ) external returns (uint bondAmount, uint toTransfer, uint toReduce);

    function autoLockBondMakerPosition(
        address recipient,
        address market, 
        uint amount, 
        uint16 risk, 
        uint16 term
    ) external returns (uint bondAmount, uint toTransfer, uint toReduce);

    function calcBondSizeForTakerPosition(
        address recipient,
        address market, 
        uint amount, 
        uint16 risk, 
        uint16 term
    ) external view returns (uint toLock, uint toTransfer, uint toReduce);

    function calcBondSizeForMakerPosition(
        address recipient,
        address market, 
        uint amount, 
        uint16 risk, 
        uint16 term
    ) external view returns (uint toLock, uint toTransfer, uint toReduce);

    function lock(address market, address addr, uint amount) external;

    /// @param addr - address of user
    /// @return amount - locked amount of particular user
    function lockedOf(address addr) external view returns (uint256 amount);

    /// @param addr - address of user
    /// @return amount - deposited amount of particular user
    function balanceOf(address addr) external view returns (uint256 amount);

    /// @notice transfer locked bond between accounts
    function transferLocked(address market, address from, address to, uint amount) external; 
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "../interfaces/IProtocolConfig.sol";
import "../interfaces/IMarketStates.sol";

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";
import "./IMakerPosition.sol";
import "./ITakerPosition.sol";

interface IMarketStorage  {
    function minTakerPositionSize() external view returns (uint);
    function minMakerPositionSize() external view returns (uint);

    function AP() external view returns (uint);
    function AR() external view returns (uint);
    function B() external view returns (uint);
    function L() external view returns (uint);

    function CP() external view returns (uint);
    function CR() external view returns (uint);
    function D() external view returns (uint);

    function RWAP() external view returns (uint);

    function token() external view returns(IERC20);
    function bToken() external view returns(IERC20);
    function stable() external view returns(IERC20);
    function bump() external view returns(IERC20);

    function config() external view returns(IProtocolConfig);
    function state() external view returns(IMarketStates);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice Taker position representation structure
struct TakerPosition {
    address owner; // owner of the position
    uint assetAmount; // amount of tokens
    uint start; // timestamp when position was opened
    uint floor; // floor price of the protected tokens
    uint16 risk; // risk in percentage with 100 multiplier (9000 means 90%)
    uint16 term; // term (in days) of protection
    bool autorenew; // autorenew flag
    uint bumpAmount; // locked bump amount for this position
    uint ci; // start position cummulative index
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice Maker position representaion structure
struct MakerPosition {
    address owner; // owner of the position
    uint stableAmount; // amount of stable tokens
    uint start; // CI when position was opened
    uint16 term; // term (in days) of protection
    uint16 risk; // risk number (1-5)
    bool autorenew; // autorenew flag for the position
    uint bumpAmount; // locked bump amount for this position 
    uint ci; // start position cummulative index    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../struct/MakerPosition.sol";

interface IMakerPosition {
    // Events
    event Protected(
        address indexed market,
        address indexed account,
        uint id,
        uint amount,
        uint floor,
        uint16 risk,
        uint16 term,
        bool autorenew
    );
    event Claimed(
        address indexed market,
        address indexed account,
        uint id,
        uint amount,
        uint floor
    );
    event Closed(
        address indexed market,
        address indexed account,
        uint id,
        uint amount,
        uint premium
    );
    event Canceled(
        address indexed market,
        address indexed account,
        uint id,
        uint amount,
        uint premium
    );

    function getMakerPosition(uint id)
        external
        view
        returns (MakerPosition memory);

    function yield(uint id) external view returns (int);

    function yieldWithPenaulty(uint id) external view returns (int);

    function deposit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) external returns (uint id);

    function depositWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    function depositWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitStable,
        bytes memory permitBump
    ) external returns (uint id);

    function depositWithPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    function withdraw(uint id) external;

    function abandon(uint id) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";

interface ITakerPosition {
    event Deposited(
        address indexed market,
        address indexed account,
        uint id,
        uint amount,
        uint16 risk,
        uint16 term
    );
    event Withdrawn(
        address indexed market,
        address indexed account,
        uint id,
        uint amount,
        int reward
    );

    function getTakerPosition(uint id)
        external
        view
        returns (TakerPosition memory);

    function premium(uint id) external view returns (uint);

    function premiumWithPenaulty(uint id) external view returns (uint);

    function protect(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) external returns (uint id);

    function protectNative(
        uint16 risk,
        uint16 term,
        bool autorenew
    ) external payable returns (uint id);

    function protectWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    function protectWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitToken,
        bytes memory permitBump
    ) external returns (uint id);

    function protectWithPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    function close(uint id) external;

    function claim(uint id) external;

    function cancel(uint id) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/// @notice Market configuration settings
struct MarketConfig {
    // price risk factor calculation
    int128[4] U_Lambda; // used for price risk factor calculation
    int128[4] U_Ref; // reference values
    int128 Vel_Max; // max historical velocity
    int128 Acc_Max; // max historical acceleration
    // liquidity risk factor calculation
    int128[6] W_Lambda; // used for liquidity risk factor calculation
    int128 lambdaGamma; //
    int128 lambdaDelta; //
    int128 eps; // maker debt growing speed coefficient
    // premium and yield calculation
    int128[5][5] Yield_Mul; // multiplier for conversion base yield to individual maker premium using risk and term
    // price update trigger settings:
    int128 Min_Price_Change; //  min price change (in percent)
    int128 Min_Price_Period; // min update period
    // network fee
    int128 takerFee; // fee for takers (in %)
    int128 makerFee; // fee for makers (in %)
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

struct MarketState {
    int128 shock;
    int128 surge;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @notice Interface for shared access control
interface IGlobalAccessControl {
    function GLOBAL_GOVERNANCE_ROLE() external view returns (bytes32);

    function userHasRole(bytes32 role, address account)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title BondConfig
struct BondConfig {
    uint bumpPerAsset;
    uint bumpPerStable;
    uint assetPerBump;
    uint stablePerBump;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMarketPositionTransfer {
    function existsTakerPosition(uint id) external view returns (bool);
    function ownerOfTakerPosition(uint id) external view returns (address);
    function safeTransferTakerPosition(address from, address to, uint id) external;

    function existsMakerPosition(uint id) external view returns (bool);
    function ownerOfMakerPosition(uint id) external view returns (address);
    function safeTransferMakerPosition(address from, address to, uint id) external;
}