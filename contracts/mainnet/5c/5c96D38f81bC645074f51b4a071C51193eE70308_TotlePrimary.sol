// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./lib/Withdrawable.sol";
import "./lib/TokenTransferProxy.sol";
import "./lib/Utils.sol";
import "./lib/Partner.sol";
import "./lib/TokenBalanceLibrary.sol";
import "./exchange_handlers/ExchangeHandler.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title The primary contract for Totle
contract TotlePrimary is Withdrawable, Pausable {
    /*
     *   State Variables
     */

    TokenTransferProxy public tokenTransferProxy;

    /*
     *   Types
     */

    // Structs
    struct Order {
        address payable exchangeHandler;
        bytes encodedPayload;
    }

    struct Trade {
        address sourceToken;
        address destinationToken;
        uint256 amount;
        Order[] orders;
    }

    struct Swap {
        Trade[] trades;
        uint256 minimumDestinationAmount;
        uint256 minimumExchangeRate;
        uint256 sourceAmount;
        uint256 tradeToTakeFeeFrom;
        bool takeFeeFromSource; //Takes the fee before the trade if true, takes it after if false
        address payable redirectAddress;
    }

    struct SwapCollection {
        Swap[] swaps;
        uint256 expirationBlock;
        bytes32 id;
        uint256 maxGasPrice;
        address payable partnerContract;
        uint8 tokenCount;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /*
     *   Events
     */

    event LogSwapCollection(
        bytes32 indexed id,
        address indexed partnerContract,
        address indexed user
    );

    event LogSwap(
        bytes32 indexed id,
        address sourceAsset,
        address destinationAsset,
        uint256 sourceAmount,
        uint256 destinationAmount,
        address feeAsset,
        uint256 feeAmount
    );

    /// @notice Constructor
    /// @param _tokenTransferProxy address of the TokenTransferProxy
    /// @param _signer the suggester's address that signs the payloads. More can be added with add/removeSigner functions
    constructor(address _tokenTransferProxy, address _signer) {
        tokenTransferProxy = TokenTransferProxy(_tokenTransferProxy);
    }

    /*
     *   Public functions
     */

    /// @notice Performs the requested set of swaps
    /// @param swaps The struct that defines the collection of swaps to perform
    function performSwapCollection(SwapCollection memory swaps)
        public
        payable
        whenNotPaused
    {
        // Initialize token balances
        TokenBalanceLibrary.TokenBalance[]
            memory balances = new TokenBalanceLibrary.TokenBalance[](
                swaps.tokenCount
            );
        // Set the ETH balance to what was given with the function call
        balances[0] = TokenBalanceLibrary.TokenBalance(
            address(Utils.eth_address()),
            msg.value
        );
        // Iterate over swaps and execute individually
        for (
            uint256 swapIndex = 0;
            swapIndex < swaps.swaps.length;
            swapIndex++
        ) {
            performSwap(
                swaps.id,
                swaps.swaps[swapIndex],
                balances,
                swaps.partnerContract
            );
        }
        emit LogSwapCollection(swaps.id, swaps.partnerContract, msg.sender);
        // Transfer all assets from swap to user
        transferAllTokensToUser(balances);
    }

    /*
     *   Internal functions
     */

    function performSwap(
        bytes32 swapCollectionId,
        Swap memory swap,
        TokenBalanceLibrary.TokenBalance[] memory balances,
        address payable partnerContract
    ) internal {
        // Get the asset for the swap from the user if not already available
        transferFromSenderDifference(
            balances,
            swap.trades[0].sourceToken,
            swap.sourceAmount
        );

        uint256 amountSpentFirstTrade = 0;
        uint256 amountReceived = 0;
        uint256 feeAmount = 0;
        // Iterated over and execute the trades in this swap
        for (
            uint256 tradeIndex = 0;
            tradeIndex < swap.trades.length;
            tradeIndex++
        ) {
            // If we are supposed to take the trade from the input of this trade, then collect it now
            if (
                tradeIndex == swap.tradeToTakeFeeFrom && swap.takeFeeFromSource
            ) {
                feeAmount = takeFee(
                    balances,
                    swap.trades[tradeIndex].sourceToken,
                    partnerContract,
                    tradeIndex == 0 ? swap.sourceAmount : amountReceived
                );
            }
            uint256 tempSpent;
            (tempSpent, amountReceived) = performTrade(
                swap.trades[tradeIndex],
                balances,
                Utils.min(
                    tradeIndex == 0 ? swap.sourceAmount : amountReceived,
                    balances[
                        TokenBalanceLibrary.findToken(
                            balances,
                            swap.trades[tradeIndex].sourceToken
                        )
                    ].balance
                )
            );
            // If this is the first trade in the swap then we need to initialize
            if (tradeIndex == 0) {
                amountSpentFirstTrade = tempSpent + feeAmount;
                if (feeAmount != 0) {
                    amountSpentFirstTrade += feeAmount;
                }
            }
            // If we are supposed to take the trade from the output of this trade, then collect it now
            if (
                tradeIndex == swap.tradeToTakeFeeFrom && !swap.takeFeeFromSource
            ) {
                feeAmount = takeFee(
                    balances,
                    swap.trades[tradeIndex].destinationToken,
                    partnerContract,
                    amountReceived
                );
                amountReceived -= feeAmount;
            }
        }
        emit LogSwap(
            swapCollectionId,
            swap.trades[0].sourceToken,
            swap.trades[swap.trades.length - 1].destinationToken,
            amountSpentFirstTrade,
            amountReceived,
            swap.takeFeeFromSource
                ? swap.trades[swap.tradeToTakeFeeFrom].sourceToken
                : swap.trades[swap.tradeToTakeFeeFrom].destinationToken,
            feeAmount
        );
        // Validate the swap got a better rate and destination amount than the minimums defined in swap
        require(
            amountReceived >= swap.minimumDestinationAmount,
            "Get less than minimumDestinationAmount"
        );
        require(
            !minimumRateFailed(
                swap.trades[0].sourceToken,
                swap.trades[swap.trades.length - 1].destinationToken,
                swap.sourceAmount,
                amountReceived,
                swap.minimumExchangeRate
            ),
            "minimumExchangeRate not met"
        );
        // Handle forwarding assets if needed
        if (
            swap.redirectAddress != msg.sender &&
            swap.redirectAddress != address(0x0)
        ) {
            uint256 destinationTokenIndex = TokenBalanceLibrary.findToken(
                balances,
                swap.trades[swap.trades.length - 1].destinationToken
            );
            uint256 amountToSend = Math.min(
                amountReceived,
                balances[destinationTokenIndex].balance
            );
            transferTokens(
                balances,
                destinationTokenIndex,
                swap.redirectAddress,
                amountToSend
            );
            TokenBalanceLibrary.removeBalance(
                balances,
                swap.trades[swap.trades.length - 1].destinationToken,
                amountToSend
            );
        }
    }

    function performTrade(
        Trade memory trade,
        TokenBalanceLibrary.TokenBalance[] memory balances,
        uint256 availableToSpend
    ) internal returns (uint256 totalSpent, uint256 totalReceived) {
        uint256 tempSpent = 0;
        uint256 tempReceived = 0;
        // Iterate over orders and execute consecutively
        for (
            uint256 orderIndex = 0;
            orderIndex < trade.orders.length;
            orderIndex++
        ) {
            if (tempSpent >= trade.amount) {
                break;
            }
            (tempSpent, tempReceived) = performOrder(
                trade.orders[orderIndex],
                availableToSpend - totalSpent,
                trade.sourceToken,
                balances
            );
            totalSpent += tempSpent;
            totalReceived += tempReceived;
        }
        // Update balances after performing order
        TokenBalanceLibrary.addBalance(
            balances,
            trade.destinationToken,
            totalReceived
        );
        TokenBalanceLibrary.removeBalance(
            balances,
            trade.sourceToken,
            totalSpent
        );
    }

    function performOrder(
        Order memory order,
        uint256 targetAmount,
        address tokenToSpend,
        TokenBalanceLibrary.TokenBalance[] memory balances
    ) internal returns (uint256 spent, uint256 received) {
        // Hand off order settlement to handler, handling both tokens and ETH as the from asset
        if (tokenToSpend == Utils.eth_address()) {
            (spent, received) = ExchangeHandler(order.exchangeHandler)
                .performOrder{value: targetAmount}(
                order.encodedPayload,
                targetAmount,
                targetAmount
            );
        } else {
            transferTokens(
                balances,
                TokenBalanceLibrary.findToken(balances, tokenToSpend),
                order.exchangeHandler,
                targetAmount
            );
            (spent, received) = ExchangeHandler(order.exchangeHandler)
                .performOrder(order.encodedPayload, targetAmount, targetAmount);
        }
    }

    function minimumRateFailed(
        address sourceToken,
        address destinationToken,
        uint256 sourceAmount,
        uint256 destinationAmount,
        uint256 minimumExchangeRate
    ) internal returns (bool failed) {
        uint256 sourceDecimals = sourceToken == Utils.eth_address()
            ? 18
            : Utils.getDecimals(sourceToken);
        uint256 destinationDecimals = destinationToken == Utils.eth_address()
            ? 18
            : Utils.getDecimals(destinationToken);
        uint256 rateGot = Utils.calcRateFromQty(
            sourceAmount,
            destinationAmount,
            sourceDecimals,
            destinationDecimals
        );
        return rateGot < minimumExchangeRate;
    }

    function takeFee(
        TokenBalanceLibrary.TokenBalance[] memory balances,
        address token,
        address payable partnerContract,
        uint256 amountTraded
    ) internal returns (uint256 feeAmount) {
        Partner partner = Partner(partnerContract);
        uint256 feePercentage = partner.getTotalFeePercentage();
        feeAmount = calculateFee(amountTraded, feePercentage);
        uint256 tokenIndex = TokenBalanceLibrary.findToken(balances, token);
        TokenBalanceLibrary.removeBalance(
            balances,
            tokenIndex,
            feeAmount
        );
        transferTokens(
            balances,
            tokenIndex,
            partnerContract,
            feeAmount
        );
        return feeAmount;
    }

    function transferFromSenderDifference(
        TokenBalanceLibrary.TokenBalance[] memory balances,
        address token,
        uint256 sourceAmount
    ) internal {
        if (token == Utils.eth_address()) {
            require(
                sourceAmount >= balances[0].balance,
                "Not enough ETH to perform swap"
            );
        } else {
            uint256 tokenIndex = TokenBalanceLibrary.findToken(balances, token);
            if (sourceAmount > balances[tokenIndex].balance) {
                uint256 transferAmount = sourceAmount - balances[tokenIndex].balance;
                tokenTransferProxy.transferFrom(
                    token,
                    msg.sender,
                    address(this),
                    transferAmount
                );
                TokenBalanceLibrary.addBalance(balances, token, transferAmount);
            }
        }
    }

    function transferAllTokensToUser(
        TokenBalanceLibrary.TokenBalance[] memory balances
    ) internal {
        for (
            uint256 balanceIndex = 0;
            balanceIndex < balances.length;
            balanceIndex++
        ) {
            if (
                balanceIndex != 0 &&
                balances[balanceIndex].tokenAddress == address(0x0)
            ) {
                return;
            }
            transferTokens(
                balances,
                balanceIndex,
                payable(msg.sender),
                balances[balanceIndex].balance
            );
        }
    }

    function transferTokens(
        TokenBalanceLibrary.TokenBalance[] memory balances,
        uint256 tokenIndex,
        address payable destination,
        uint256 tokenAmount
    ) internal {
        if (tokenAmount > 0) {
            if (balances[tokenIndex].tokenAddress == Utils.eth_address()) {
                destination.transfer(tokenAmount);
            } else {
                SafeERC20.safeTransfer(
                    IERC20(balances[tokenIndex].tokenAddress),
                    destination,
                    tokenAmount
                );
            }
        }
    }

    // @notice Calculates the fee amount given a fee percentage and amount
    // @param amount the amount to calculate the fee based on
    // @param fee the percentage, out of 1 eth (e.g. 0.01 ETH would be 1%)
    function calculateFee(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return SafeMath.div(SafeMath.mul(amount, fee), 1 * (10**18));
    }

    /*
     *   Payable receive function
     */

    /// @notice payable receive to allow handler or exchange contracts to return ether
    /// @dev only accounts containing code (ie. contracts) can send ether to contract
    receive() external payable whenNotPaused {
        // Check in here that the sender is a contract! (to stop accidents)
        uint256 size;
        address sender = msg.sender;
        assembly {
            size := extcodesize(sender)
        }
        if (size == 0) {
            revert("EOA cannot send ether to primary receive function");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A contract which allows its owner to withdraw any ether which is contained inside
contract Withdrawable is Ownable {

    /// @notice Withdraw ether contained in this contract and send it back to owner
    /// @dev onlyOwner modifier only allows the contract owner to run the code
    /// @param _token The address of the token that the user wants to withdraw
    /// @param _amount The amount of tokens that the caller wants to withdraw
    function withdrawToken(address _token, uint256 _amount) external onlyOwner {
        SafeERC20.safeTransfer(IERC20(_token), owner(), _amount);
    }

    /// @notice Withdraw ether contained in this contract and send it back to owner
    /// @dev onlyOwner modifier only allows the contract owner to run the code
    /// @param _amount The amount of ether that the caller wants to withdraw
    function withdrawETH(uint256 _amount) external onlyOwner {
        payable(owner()).transfer(_amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
    Modified Util contract as used by Kyber Network
*/

library Utils {

    uint256 constant internal PRECISION = (10**18);
    uint256 constant internal MAX_QTY   = (10**28); // 10B tokens
    uint256 constant internal MAX_RATE  = (PRECISION * 10**6); // up to 1M tokens per ETH
    uint256 constant internal MAX_DECIMALS = 18;
    uint256 constant internal ETH_DECIMALS = 18;
    uint256 constant internal MAX_UINT = 2**256-1;
    address constant internal ETH_ADDRESS = address(0x0);

    // Currently constants can't be accessed from other contracts, so providing functions to do that here
    function precision() internal pure returns (uint256) { return PRECISION; }
    function max_qty() internal pure returns (uint256) { return MAX_QTY; }
    function max_rate() internal pure returns (uint256) { return MAX_RATE; }
    function max_decimals() internal pure returns (uint256) { return MAX_DECIMALS; }
    function eth_decimals() internal pure returns (uint256) { return ETH_DECIMALS; }
    function max_uint() internal pure returns (uint256) { return MAX_UINT; }
    function eth_address() internal pure returns (address) { return ETH_ADDRESS; }

    /// @notice Retrieve the number of decimals used for a given ERC20 token
    /// @dev As decimals are an optional feature in ERC20, this contract uses `call` to
    /// ensure that an exception doesn't cause transaction failure
    /// @param token the token for which we should retrieve the decimals
    /// @return decimals the number of decimals in the given token
    function getDecimals(address token)
        internal
        returns (uint256 decimals)
    {
        bytes4 functionSig = bytes4(keccak256("decimals()"));

        /// @dev Using assembly due to issues with current solidity `address.call()`
        /// implementation: https://github.com/ethereum/solidity/issues/2884
        assembly {
            // Pointer to next free memory slot
            let ptr := mload(0x40)
            // Store functionSig variable at ptr
            mstore(ptr,functionSig)
            let functionSigLength := 0x04
            let wordLength := 0x20

            let success := call(
                                gas(), // Amount of gas
                                token, // Address to call
                                0, // ether to send
                                ptr, // ptr to input data
                                functionSigLength, // size of data
                                ptr, // where to store output data (overwrite input)
                                wordLength // size of output data (32 bytes)
                               )

            switch success
            case 0 {
                decimals := 0 // If the token doesn't implement `decimals()`, return 0 as default
            }
            case 1 {
                decimals := mload(ptr) // Set decimals to return data from call
            }
            mstore(0x40,add(ptr,0x04)) // Reset the free memory pointer to the next known free location
        }
    }

    /// @dev Checks that a given address has its token allowance and balance set above the given amount
    /// @param tokenOwner the address which should have custody of the token
    /// @param tokenAddress the address of the token to check
    /// @param tokenAmount the amount of the token which should be set
    /// @param addressToAllow the address which should be allowed to transfer the token
    /// @return bool true if the allowance and balance is set, false if not
    function tokenAllowanceAndBalanceSet(
        address tokenOwner,
        address tokenAddress,
        uint256 tokenAmount,
        address addressToAllow
    )
        internal
        view
        returns (bool)
    {
        return (
            IERC20(tokenAddress).allowance(tokenOwner, addressToAllow) >= tokenAmount &&
            IERC20(tokenAddress).balanceOf(tokenOwner) >= tokenAmount
        );
    }

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns (uint) {
        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(uint dstQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns (uint) {

        //source quantity is rounded up. to avoid dest quantity being too low.
        uint numerator;
        uint denominator;
        if (srcDecimals >= dstDecimals) {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator; //avoid rounding down errors
    }

    function calcDestAmount(IERC20 src, IERC20 dest, uint srcAmount, uint rate) internal returns (uint) {
        return calcDstQty(srcAmount, getDecimals(address(src)), getDecimals(address(dest)), rate);
    }

    function calcSrcAmount(IERC20 src, IERC20 dest, uint destAmount, uint rate) internal returns (uint) {
        return calcSrcQty(destAmount, getDecimals(address(src)), getDecimals(address(dest)), rate);
    }

    function calcRateFromQty(uint srcAmount, uint destAmount, uint srcDecimals, uint dstDecimals)
        internal pure returns (uint)
    {
        require(srcAmount <= MAX_QTY);
        require(destAmount <= MAX_QTY);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION / ((10 ** (dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION * (10 ** (srcDecimals - dstDecimals)) / srcAmount);
        }
    }

    /// @notice Bringing this in from the Math library as we've run out of space in TotlePrimary (see EIP-170)
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: UNLICENSED
/*

  Copyright 2018 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title TokenTransferProxy - Transfers tokens on behalf of contracts that have been approved via decentralized governance.
/// @author Amir Bandeali - <[email protected]>, Will Warren - <[email protected]>
contract TokenTransferProxy is Ownable {

    /// @dev Only authorized addresses can invoke functions with this modifier.
    modifier onlyAuthorized {
        require(authorized[msg.sender]);
        _;
    }

    modifier targetAuthorized(address target) {
        require(authorized[target]);
        _;
    }

    modifier targetNotAuthorized(address target) {
        require(!authorized[target]);
        _;
    }

    mapping (address => bool) public authorized;

    event LogAuthorizedAddressAdded(address indexed target, address indexed caller);
    event LogAuthorizedAddressRemoved(address indexed target, address indexed caller);

    /*
     * Public functions
     */

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target)
        public
        onlyOwner
        targetNotAuthorized(target)
    {
        authorized[target] = true;
        emit LogAuthorizedAddressAdded(target, msg.sender);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target)
        public
        onlyOwner
        targetAuthorized(target)
    {
        authorized[target] = false;

        emit LogAuthorizedAddressRemoved(target, msg.sender);
    }

    /// @dev Calls into ERC20 Token contract, invoking transferFrom.
    /// @param token Address of token to transfer.
    /// @param from Address to transfer token from.
    /// @param to Address to transfer token to.
    /// @param value Amount of token to transfer.
    function transferFrom(
        address token,
        address from,
        address to,
        uint value)
        public
        onlyAuthorized
    {
        SafeERC20.safeTransferFrom(IERC20(token), from, to, value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

library TokenBalanceLibrary {
    struct TokenBalance {
        address tokenAddress;
        uint256 balance;
    }

    /*
     * Internal functions
     */
     
    /// @dev Finds token entry in balances array
    /// @param balances Array of token balance entries
    /// @param token The address of the token to find the entry for. If it's not found, it will create a new entry and return that index
    /// @return tokenEntry The index that this tokens entry can be found at

    function findToken(TokenBalance[] memory balances, address token)
        internal
        pure
        returns (uint256 tokenEntry)
    {
        for (uint256 index = 0; index < balances.length; index++) {
            if (balances[index].tokenAddress == token) {
                return index;
            } else if (
                index != 0 && balances[index].tokenAddress == address(0x0)
            ) {
                balances[index] = TokenBalance(token, 0);
                return index;
            }
        }
    }

    /// @dev Adds an amount of a token to the balances array by token address. Automatically adds entry if it doesn't exist
    /// @param balances Array of token balances to add to
    /// @param token The address of the token to add balance to
    /// @param amountToAdd Amount of the token to add to balance
    function addBalance(
        TokenBalance[] memory balances,
        address token,
        uint256 amountToAdd
    ) internal pure {
        uint256 tokenIndex = findToken(balances, token);
        addBalance(balances, tokenIndex, amountToAdd);
    }

    /// @dev Adds an amount of a token to the balances array by token index
    /// @param balances Array of token balances to add to
    /// @param tokenIndex The index of the token to add balance to
    /// @param amountToAdd Amount of the token to add to balance
    function addBalance(
        TokenBalance[] memory balances,
        uint256 tokenIndex,
        uint256 amountToAdd
    ) internal pure {
        balances[tokenIndex].balance += amountToAdd;
    }

    /// @dev Removes an amount of a token from the balances array by token address
    /// @param balances Array of token balances to remove from
    /// @param token The address of the token to remove balance from
    /// @param amountToRemove Amount of the token to remove from balance
    function removeBalance(
        TokenBalance[] memory balances,
        address token,
        uint256 amountToRemove
    ) internal pure {
        uint256 tokenIndex = findToken(balances, token);
        removeBalance(balances, tokenIndex, amountToRemove);
    }

    /// @dev Removes an amount of a token from the balances array by token index
    /// @param balances Array of token balances to remove from
    /// @param tokenIndex The index of the token to remove balance from
    /// @param amountToRemove Amount of the token to remove from balance
    function removeBalance(
        TokenBalance[] memory balances,
        uint256 tokenIndex,
        uint256 amountToRemove
    ) internal pure {
        balances[tokenIndex].balance -= amountToRemove;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./Partner.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PartnerRegistry is Ownable, Pausable {
    address target;
    mapping(address => bool) partnerContracts;
    address payable public companyBeneficiary;
    uint256 public basePercentage;
    PartnerRegistry public previousRegistry;

    event PartnerRegistered(
        address indexed creator,
        address indexed beneficiary,
        address partnerContract
    );

    constructor(
        PartnerRegistry _previousRegistry,
        address _target,
        address payable _companyBeneficiary,
        uint256 _basePercentage
    ) {
        previousRegistry = _previousRegistry;
        target = _target;
        companyBeneficiary = _companyBeneficiary;
        basePercentage = _basePercentage;
    }

    /*
     * Public functions
     */

    /// @dev registers a partner and deploys a partner contract
    /// @param partnerBeneficiary The address that the partner will receive payments to - NON-CHANGEABLE
    /// @param partnerPercentage The percentage fee the partner wants to take - this is out of 1**18, so 1**16 would be 1% fee
    function registerPartner(
        address payable partnerBeneficiary,
        uint256 partnerPercentage
    ) external whenNotPaused {
        Partner newPartner = Partner(createClone());
        newPartner.init(
            this,
            payable(0x0),
            0,
            partnerBeneficiary,
            partnerPercentage
        );
        partnerContracts[address(newPartner)] = true;
        emit PartnerRegistered(
            address(msg.sender),
            partnerBeneficiary,
            address(newPartner)
        );
    }

    /// @dev registers a partner and deploys a partner contract with custom company values, only usable by owner
    /// @param _companyBeneficiary The address that the company will receive payments to - NON-CHANGEABLE
    /// @param _companyPercentage The percentage fee the company wants to take - this is out of 1**18, so 1**16 would be 1% fee
    /// @param partnerBeneficiary The address that the partner will receive payments to - NON-CHANGEABLE
    /// @param partnerPercentage The percentage fee the partner wants to take - this is out of 1**18, so 1**16 would be 1% fee
    function overrideRegisterPartner(
        address payable _companyBeneficiary,
        uint256 _companyPercentage,
        address payable partnerBeneficiary,
        uint256 partnerPercentage
    ) external onlyOwner {
        Partner newPartner = Partner(createClone());
        newPartner.init(
            PartnerRegistry(0x0000000000000000000000000000000000000000),
            _companyBeneficiary,
            _companyPercentage,
            partnerBeneficiary,
            partnerPercentage
        );
        partnerContracts[address(newPartner)] = true;
        emit PartnerRegistered(
            address(msg.sender),
            partnerBeneficiary,
            address(newPartner)
        );
    }

    /// @dev Marks a partner contract as no longer valid
    /// @param partnerContract The partner contract address to disable
    function deletePartner(address partnerContract) external onlyOwner {
        partnerContracts[partnerContract] = false;
    }

    /*
     * Internal functions
     */

    /// @dev Creates a clone of contract - from EIP-1167
    /// @param result The address of the contract that was created
    function createClone() internal returns (address payable result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }
    /// @dev Used to tell whether a given address is a valid partner contract, i.e. it was created on this contract or a historic registry, and it hasn't been disabled
    /// @param partnerContract The partner contract address to validate

    function isValidPartner(address partnerContract)
        external
        view
        returns (bool)
    {
        return
            partnerContracts[partnerContract] ||
            previousRegistry.isValidPartner(partnerContract);
    }

    /// @dev Updates the beneficiary and default percentage for the company
    /// @param newCompanyBeneficiary New beneficiary address for company
    /// @param newBasePercentage New base percentage for company
    function updateCompanyInfo(
        address payable newCompanyBeneficiary,
        uint256 newBasePercentage
    ) external onlyOwner {
        companyBeneficiary = newCompanyBeneficiary;
        basePercentage = newBasePercentage;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./Utils.sol";
import "./PartnerRegistry.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Partner is ReentrancyGuard {
    address payable public partnerBeneficiary;
    uint256 public partnerPercentage; //This is out of 1 ETH, e.g. 0.5 ETH is 50% of the fee

    uint256 public overrideCompanyPercentage;
    address payable public overrideCompanyBeneficiary;

    PartnerRegistry public registry;

    event LogPayout(address[] tokens, uint256[] amount);

    function init(
        PartnerRegistry _registry,
        address payable _overrideCompanyBeneficiary,
        uint256 _overrideCompanyPercentage,
        address payable _partnerBeneficiary,
        uint256 _partnerPercentage
    ) public {
        require(
            registry ==
                PartnerRegistry(0x0000000000000000000000000000000000000000) &&
                overrideCompanyBeneficiary == address(0x0) &&
                partnerBeneficiary == address(0x0)
        );
        overrideCompanyBeneficiary = _overrideCompanyBeneficiary;
        overrideCompanyPercentage = _overrideCompanyPercentage;
        partnerBeneficiary = _partnerBeneficiary;
        partnerPercentage = _partnerPercentage;
        overrideCompanyPercentage = _overrideCompanyPercentage;
        registry = _registry;
    }

    function payout(address[] memory tokens) public nonReentrant {
        uint256 totalFeePercentage = getTotalFeePercentage();
        address payable _companyBeneficiary = companyBeneficiary();
        uint256[] memory amountsPaidOut = new uint256[](tokens.length);
        // Payout both the partner and the company at the same time
        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 balance = tokens[index] == Utils.eth_address()
                ? address(this).balance
                : IERC20(tokens[index]).balanceOf(address(this));
            amountsPaidOut[index] = balance;
            uint256 partnerAmount = SafeMath.div(
                SafeMath.mul(balance, partnerPercentage),
                totalFeePercentage
            );
            uint256 companyAmount = balance - partnerAmount;
            if (tokens[index] == Utils.eth_address()) {
                bool success;
                (success,) = partnerBeneficiary.call{value: partnerAmount, gas: 5000}("");
                require(success,"Transfer failed");
                (success,) =_companyBeneficiary.call{value: companyAmount, gas: 5000}("");
                require(success,"Transfer failed");

            } else {
                SafeERC20.safeTransfer(
                    IERC20(tokens[index]),
                    partnerBeneficiary,
                    partnerAmount
                );
                SafeERC20.safeTransfer(
                    IERC20(tokens[index]),
                    _companyBeneficiary,
                    companyAmount
                );
            }
        }
        emit LogPayout(tokens, amountsPaidOut);
    }

    function getTotalFeePercentage() public view returns (uint256) {
        return partnerPercentage + companyPercentage();
    }

    function companyPercentage() public view returns (uint256) {
        if (
            registry !=
            PartnerRegistry(0x0000000000000000000000000000000000000000)
        ) {
            return Math.max(registry.basePercentage(), partnerPercentage);
        } else {
            return overrideCompanyPercentage;
        }
    }

    function companyBeneficiary() public view returns (address payable) {
        if (
            registry !=
            PartnerRegistry(0x0000000000000000000000000000000000000000)
        ) {
            return registry.companyBeneficiary();
        } else {
            return overrideCompanyBeneficiary;
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../lib/Withdrawable.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for all exchange handler contracts
abstract contract ExchangeHandler is Withdrawable {
    /*
     *   Public functions
     */

    /// @dev Fills the input order.
    /// @param genericPayload Encoded data for this order. This is specific to exchange and is done by encoding a per-exchange struct
    /// @param availableToSpend The amount of assets that are available for the handler to spend.
    /// @param targetAmount The target for amount of assets to spend - it may spend less than this and return the change.
    /// @return amountSpentOnOrder The amount of source asset spent on this order.
    /// @return amountReceivedFromOrder The amount of destination asset received from this order.

    function performOrder(
        bytes memory genericPayload,
        uint256 availableToSpend,
        uint256 targetAmount
    )
        external
        payable
        virtual
        returns (uint256 amountSpentOnOrder, uint256 amountReceivedFromOrder);


    /// @notice payable receive  to block EOA sending eth
    /// @dev this should fail if an EOA (or contract with 0 bytecode size) tries to send ETH to this contract
    receive() external payable {
        // Check in here that the sender is a contract! (to stop accidents)
        uint256 size;
        address sender = msg.sender;
        assembly {
            size := extcodesize(sender)
        }
        require(size > 0);
    }
    /* 
     *   Internal functions
     */

    /// @dev Gets the max to spend by taking min of targetAmount and availableToSpend.
    /// @param targetAmount The amount the primary wants this handler to spend
    /// @param availableToSpend The amount the exchange handler has available to spend.
    /// @return max The maximum amount the handler can spend

    function getMaxToSpend(uint256 targetAmount, uint256 availableToSpend)
        internal
        pure
        returns (uint256 max)
    {
        max = Math.min(availableToSpend, targetAmount);
        return max;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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