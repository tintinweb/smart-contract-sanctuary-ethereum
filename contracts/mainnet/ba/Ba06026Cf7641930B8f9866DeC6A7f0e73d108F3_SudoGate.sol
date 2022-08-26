// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;


import {IERC165} from "IERC165.sol";

import {IERC721} from "IERC721.sol";

import {IERC721Enumerable} from "IERC721Enumerable.sol";

import {ILSSVMPairFactoryLike} from "ILSSVMPairFactoryLike.sol";
import {LSSVMPair, CurveErrorCodes} from "LSSVMPair.sol";

contract SudoGate {
    address private SUDO_PAIR_FACTORY_ADDRESS = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;
    address private owner; 

    uint256 private minBalanceForTransfer = 0.1 ether;
    uint256 private contributorFeePerThousand = 2;
    uint256 private protocolFeePerThousand = 1;
    address payable private protocolFeeAddress;

    /* 
    to avoid transferring eth on every small fee, 
    keep track of balances in this mapping and then 
    send eth in larger batches 
    */
    mapping (address => uint256) public balances;
    uint256 public totalBalance = 0;


    // mapping from NFT addresses to array of known pools
    mapping (address => address[]) public pools;

    mapping (address => bool) public knownPool;

    // who contributed each pool
    mapping (address => address) public poolContributors;

    constructor() { 
        owner = msg.sender; 
        protocolFeeAddress = payable(msg.sender);
    }
    
    function setPairFactoryAddress(address addr) public {
        require(msg.sender == owner, "Only owner allowed to call setPairFactoryAddress");
        SUDO_PAIR_FACTORY_ADDRESS = addr;
    }

    function setProtocolFeeAddress(address payable addr) public {
        require(msg.sender == owner, "Only owner allowed to call setProtocolFeeAddress");
        protocolFeeAddress = addr;
    }
    
    function setProtocolFee(uint256 fee) public {
        /* 
            set fee (in 1/10th of a percent) which gets sent to protocol
            for every transaction
        */
        require(msg.sender == owner, "Only owner allowed to call setProtocolFee");
        protocolFeePerThousand = fee;
    }

    function setContributorFee(uint256 fee) public {
        /* 
            set fee (in 1/10th of a percent) which gets sent to whoever 
            contributed the pool address to SudoGate
        */
        require(msg.sender == owner, "Only owner allowed to call setContributorFee");
        contributorFeePerThousand = fee;
    }

    function setMinBalanceForTransfer(uint256 minVal) public {
        /* 
            set fee (in 1/10th of a percent) which gets sent to whoever 
            contributed the pool address to SudoGate
        */
        require(msg.sender == owner, "Only owner allowed to call setMinBalanceForTransfer");
        minBalanceForTransfer = minVal;
    }


    function totalFeesPerThousand() public view returns (uint256) {
        return protocolFeePerThousand + contributorFeePerThousand;
    }

    function registerPool(address sudoswapPool) public returns (bool) {
        require(!knownPool[sudoswapPool], "Pool already known");
        if (!ILSSVMPairFactoryLike(SUDO_PAIR_FACTORY_ADDRESS).isPair(sudoswapPool, ILSSVMPairFactoryLike.PairVariant.ENUMERABLE_ETH)) {
            require(ILSSVMPairFactoryLike(SUDO_PAIR_FACTORY_ADDRESS).isPair(sudoswapPool, ILSSVMPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ETH), "Not a sudoswap ETH pool");
        }
        knownPool[sudoswapPool] = true;
        poolContributors[sudoswapPool] = msg.sender;
        address nft = address(LSSVMPair(sudoswapPool).nft());
        pools[nft].push(sudoswapPool); 
    }
    
    function adjustBuyPrice(uint256 price, uint256 slippagePerThousand) public view returns (uint256 adjustedPrice) {
        /* add fees to the price so you know how much ETH to send when you call a buy function */
        adjustedPrice = price * (1000 + contributorFeePerThousand) / 1000; 
        adjustedPrice *= (1000 + protocolFeePerThousand) / 1000;
        if (slippagePerThousand > 0) {
            adjustedPrice *= (1000 + slippagePerThousand) / 1000;
        }
    }
    
    function adjustSellPrice(uint256 price, uint256 slippagePerThousand) public view returns (uint256 adjustedPrice) {
        require(contributorFeePerThousand <= 1000, "contributorFeePerThousand must be between 0 and 1000");
        require(protocolFeePerThousand <= 1000, "protocolFeePerThousand must be between 0 and 1000");
        require(slippagePerThousand <= 1000, "slippagePerThousand must be between 0 and 1000");
        /* remove fees from the price so you know how much ETH you'll get when you call a sell function */
        adjustedPrice = price * (1000 - contributorFeePerThousand) / 1000; 
        adjustedPrice *= (1000 - protocolFeePerThousand) / 1000;
        if (slippagePerThousand > 0) {
            adjustedPrice *= (1000 - slippagePerThousand) / 1000;
        }
    }
    

    function addFee(address payable recipient, uint256 fee) internal {
        balances[recipient] += fee;
        totalBalance += fee;

        uint256 currentBalance = balances[recipient];
        if (currentBalance >= minBalanceForTransfer) {
            require(address(this).balance >= currentBalance, "Not enough ETH on contract");
            require(totalBalance >= currentBalance, "Don't lose track of how much ETH we have!");
            totalBalance -= currentBalance;
            balances[recipient] = 0;
            recipient.transfer(currentBalance);
        }
    }

    function buyFromPool(address pool) public payable returns (uint256 tokenID) {
        /* returns token ID of purchased NFT */
        IERC721 nft = LSSVMPair(pool).nft();
        require(nft.balanceOf(pool) > 0, "Pool has no NFTs");
        uint256[] memory tokenIDs = LSSVMPair(pool).getAllHeldIds();
        tokenID = tokenIDs[tokenIDs.length - 1];

        uint256 maxContributorFee = msg.value * contributorFeePerThousand / 1000; 
        uint256 maxProtocolFee = msg.value * protocolFeePerThousand / 1000; 
        uint256 maxCombinedFees = maxContributorFee + maxProtocolFee;
        require(maxCombinedFees < msg.value, "Fees cannot exceed ETH sent");
        uint256 maxAllowedSpend = msg.value - maxCombinedFees;

        uint256 usedAmt = LSSVMPair(pool).swapTokenForAnyNFTs{value: maxAllowedSpend}(
            1, 
            maxAllowedSpend, 
            msg.sender, 
            false, 
            address(0));
        require(usedAmt < msg.value, "Can't use more ETH than was originally sent");
        require(usedAmt > 0, "There ain't no such thing as a free lunch");
        
        // compute actual fees based on what got spent by sudoswap
        uint256 contributorFee = usedAmt * contributorFeePerThousand / 1000; 
        uint256 protocolFee = usedAmt * protocolFeePerThousand / 1000; 
        uint256 combinedFees = protocolFee + contributorFee;
        uint256 amtWithFees = usedAmt + combinedFees;
        require(amtWithFees <= msg.value, "Can't spend more than we were originally sent");
        
        addFee(payable(poolContributors[pool]), contributorFee);
        addFee(protocolFeeAddress, protocolFee);
        uint256 diff = msg.value - amtWithFees;
        // send back unused ETH
        if (diff > 0) { payable(msg.sender).transfer(diff); }
    }

    function buy(address nft) public payable returns (uint256 tokenID) {
        uint256 bestPrice;
        address bestPool;
        (bestPrice, bestPool) = buyQuote(nft);
        require(bestPool != address(0), "No pool found");
        require(bestPrice != type(uint256).max, "Invalid price");
        uint256 adjustedPrice = adjustBuyPrice(bestPrice, 5);
        require(adjustedPrice <= msg.value, "Not enough ETH for price of NFT");
        tokenID = buyFromPool(bestPool);
    }

    function buyQuote(address nft) public view returns (uint256 bestPrice, address bestPool) {
        /* 
        Returns best price for an NFT and the pool to buy it from. 
        Does not include SudoGate fees, see buyQuoteWithFees
        */
        address[] storage nftPools = pools[nft];
        uint256 numPools = nftPools.length;
        require(numPools > 0, "No pools registered for given NFT");

        CurveErrorCodes.Error err;
        uint256 inputAmount;
        bestPrice = type(uint256).max;
        bestPool = address(0);

        address poolAddr;
        uint256 i = 0;
        for (; i < numPools; ++i) {
            poolAddr = nftPools[i];
            if (IERC721(nft).balanceOf(poolAddr) == 0) {
                // check if pool actually has any NFTs
                continue;
            } else {
                (err, , , inputAmount, ) = LSSVMPair(poolAddr).getBuyNFTQuote(1);
                if (err == CurveErrorCodes.Error.OK) {
                    if (inputAmount < bestPrice) {
                        bestPool = poolAddr;
                        bestPrice = inputAmount;
                    }
                }
            }
        }
        require(bestPool != address(0), "Could not find a pool to buy from");
    }

    function buyQuoteWithFees(address nft) public view returns (uint256 bestPrice, address bestPool) {
        /* 
        Returns best price for an NFT and the pool to buy it from. 
        Price is adjusted for SudoGate fees but assumes 0 slippage.
        */ 
        (bestPrice, bestPool) = buyQuote(nft);
        // include a small 0.5% slippage 
        bestPrice = adjustBuyPrice(bestPrice, 5);
    }

    function sell(address nft, uint256 tokenId) public {
        uint256 bestPrice;
        address bestPool;
        (bestPrice, bestPool) = sellQuote(nft);
        
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = tokenId;

        uint256 outputAmount = LSSVMPair(bestPool).swapNFTsForToken(
            nftIds,
            bestPrice,
            payable(address(this)),
            false,
            address(0));
        require(outputAmount > 0, "Didn't get any ETH back");

        // compute actual fees based on what got sent by sudoswap
        uint256 contributorFee = outputAmount * contributorFeePerThousand / 1000; 
        uint256 protocolFee = outputAmount * protocolFeePerThousand / 1000; 
        uint256 combinedFees = contributorFee + protocolFee;
        require(combinedFees < outputAmount, "Fees can't exceed ETH received for selling");
        
        addFee(payable(poolContributors[bestPool]), contributorFee);
        addFee(protocolFeeAddress, protocolFee);
        
        uint256 diff = outputAmount - combinedFees;
        
        // send back ETH after fees
        if (diff > 0) { payable(msg.sender).transfer(diff); }
    }

    function sellQuote(address nft) public view returns (uint256 bestPrice, address bestPool) {
        address[] storage nftPools = pools[nft];
        uint256 numPools = nftPools.length;
        require(numPools > 0, "No pools registered for given NFT");

        CurveErrorCodes.Error err;
        uint256 outputAmount;
        bestPrice = 0;
        bestPool = address(0);

        address poolAddr;
        uint256 i = 0;
        for (; i < numPools; ++i) {
            poolAddr = nftPools[i];
            if (poolAddr.balance < bestPrice) {
                // check if pool actually has enough ETH to potentially give us a better price
                continue;
            } else {
                (err, , , outputAmount, ) = LSSVMPair(poolAddr).getSellNFTQuote(1);
                // make sure the pool has enough ETH to cover its own better offer
                if ((err == CurveErrorCodes.Error.OK) && 
                        (outputAmount > bestPrice) && 
                        (poolAddr.balance >= outputAmount)) { 
                    bestPool = poolAddr;
                    bestPrice = outputAmount;
                }
            }
        }
        require(bestPool != address(0), "Could not find a pool to buy from");
    }   

    
    function sellQuoteWithFees(address nft) public view returns (uint256 bestPrice, address bestPool) {
        /* 
        Returns best sell price for an NFT and the pool to sell it to. 
        Price is adjusted for SudoGate fees but assumes 0 slippage.
        */ 
        (bestPrice, bestPool) = sellQuote(nft);
        // include a small 0.5% slippage 
        bestPrice = adjustSellPrice(bestPrice, 5);
    }

    
    // make it possible to receive ETH on this contract
    receive() external payable { }

    function rescueETH() public {
        // in case ETH gets trapped on this contract for some reason,
        // allow owner to manually withdraw it
        require(msg.sender == owner, "Only owner allowed to call rescueETH");
        require(address(this).balance >= totalBalance, "Not enough ETH on contract for balances");
        uint256 extraETH = address(this).balance - totalBalance;
        payable(owner).transfer(extraETH);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

interface ILSSVMPairFactoryLike {
    enum PairVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    function protocolFeeMultiplier() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address payable);

    function callAllowed(address target) external view returns (bool);
    /*
    function routerStatus(LSSVMRouter router)
        external
        view
        returns (bool allowed, bool wasEverAllowed);
    */

    function isPair(address potentialPair, PairVariant variant)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC721} from "IERC721.sol";
import {ILSSVMPairFactoryLike} from "ILSSVMPairFactoryLike.sol";

contract CurveErrorCodes {
    enum Error {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        SPOT_PRICE_OVERFLOW // The updated spot price doesn't fit into 128 bits
    }
}

interface LSSVMPair {

    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    function factory() external pure returns (ILSSVMPairFactoryLike);
    
    function nft() external pure returns (IERC721);
    
    function poolType() external pure returns (PoolType);
    
    function getBuyNFTQuote(uint256 numNFTs) external view returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 inputAmount,
            uint256 protocolFee
        );

    function getSellNFTQuote(uint256 numNFTs) external view returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 outputAmount,
            uint256 protocolFee
        );

      /**
        @notice Sends token to the pair in exchange for any `numNFTs` NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
        This swap function is meant for users who are ID agnostic
        @param numNFTs The number of NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @param isRouter True if calling from LSSVMRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable  returns (uint256 inputAmount);

     function swapNFTsForToken(
        uint256[] calldata nftIds,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external returns (uint256 outputAmount);

    function getAllHeldIds() external view returns (uint256[] memory);

}