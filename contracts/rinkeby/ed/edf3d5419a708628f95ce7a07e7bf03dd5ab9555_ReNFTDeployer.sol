// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "../contracts/Resolver.sol";
import "../contracts/ReNFT.sol";


contract ReNFTDeployer {

    event ResolverDeployed(address resolverAddress, address deployer, address[] paymentTokenAddresses, uint8[] paymentTokens);

    event ReNFTDeployed(address ReNFTAddress, address resolver, address beneficiary, uint256 rentFee, address deployer);

    constructor(
        address beneficiary, 
        uint256 rentFee, 
        address[] memory paymentTokenAddresses,
        uint8[] memory paymentTokens
    ){
        require(rentFee <= 10000, "ReNFTDeployer::rentFee must be in range [0,10000]");
        require(paymentTokenAddresses.length == paymentTokens.length, "ReNFTDeployer::paymentTokenAddresses.length does not match paymentTokens.length");
        require(beneficiary != address(0), "ReNFTDeployer::beneficiary cannot be zero address");

        Resolver resolver = new Resolver(tx.origin);
        for (uint i = 0; i < paymentTokenAddresses.length; i++) {
            resolver.setPaymentToken(paymentTokens[i], paymentTokenAddresses[i]);
        }
        emit ResolverDeployed(address(resolver), tx.origin, paymentTokenAddresses, paymentTokens);

        ReNFT reNFT = new ReNFT(address(resolver), payable(beneficiary));
        reNFT.setRentFee(rentFee);

        emit ReNFTDeployed(address(reNFT), address(resolver), beneficiary, rentFee, tx.origin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "./interfaces/IResolver.sol";

//              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
//              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
//         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
//    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
//         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
//         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
//              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
//              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@

// todo: docs here

contract Resolver is IResolver {

    error CannotResetAddress();

    error NotAdmin();

    error CannotSetSentinel();

    address private admin;
    mapping(uint8 => address) private addresses;

    constructor(address newAdmin) {
        admin = newAdmin;
    }

    function getPaymentToken(PaymentToken paymentToken)
        external
        view
        override
        returns (address)
    {
        return addresses[uint8(paymentToken)];
    }

    function setPaymentToken(uint8 paymentToken, address paymentTokenAddress)
        external
        override
    {
        if (paymentToken == 0) {
            revert CannotSetSentinel();
        }
        if (addresses[paymentToken] != address(0)) {
            revert CannotResetAddress();
        }
        if (tx.origin != admin) {
            revert NotAdmin();
        }
        addresses[paymentToken] = paymentTokenAddress;
    }
}

/*
 *
 *              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
 *              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
 *         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
 *    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
 *         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
 *         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
 *              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
 *              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@ *
 *
 * Resolver: Resolver.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 reNFT Labs Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./interfaces/IResolver.sol";
import "./interfaces/IReNFT.sol";

import "./lib/NFTCommon.sol";
import "./lib/LendingChecks.sol";
import "./lib/RentingChecks.sol";

/// Main Differences with v1
/// 1. No price packing. Instead of supplying bytes4, supply uint24 and uint8.
/// The former signifies the whole number, while the latter signifies the decimal.
/// 2. Edit lending function. To change the collateral / daily rent price,
/// you don't need to cancel and create a new listing anymore.
/// 3. Supports the NFTs that support both the 721 and 1155 standards at the same
/// time.
/// 4. Allows for zero daily rent price.
/// 5. Allows for zero collateral.
/// 6. Timestamps were removed from events, because the block.timestamp can be
/// pulled during indexing.
/// 7. ! Collateral is now specified for all the lent NFTs, and not 1 qty of the NFT.
/// Used to be confusing before.

//              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
//              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
//         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
//    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
//         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
//         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
//              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
//              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@


/// @notice Emitted when NFT transfer fails
error NftTransferFailed();

/// @notice Emitted when the caller is not an admin.
error NotAdmin(address caller);

/// @notice Emitted when the paused function is called.
error Paused();

/// @notice Emitted when no NFT(s) have been passed to bundleCall.
error NoNfts();

/// @notice Emitted when the scale of the token is less than 10000.
error PaymentTokenScaleNotAllowed();

/// @notice Emitted when the NFT supports purely ERC721 standard, but the lend amount is not zero.
/// @param amount Actual amount lender is attempting to lend.
error InvalidAmountToLend(uint256 amount);

/// @notice Emitted when non-lender attempts to edit the existing lending.
error NotAllowedToEdit();

/// @notice Emitted when the item cannot lent or an existing lending item cannot be edited.
error NotLendable();

/// @notice ReNFT
/// @author reNFT
contract ReNFT is IReNFT, ERC721Holder, ERC1155Receiver, ERC1155Holder {
    using SafeERC20 for ERC20;
    using NFTCommon for INFTContract;
    using LendingChecks for Lending;
    using RentingChecks for Renting;

    IResolver private resolver;
    address private admin;
    address payable private beneficiary;

    uint256 private lendingId = 1;
    uint256 private constant SECONDS_IN_DAY = 86400;

    bool public paused = false;
    // In basis points. So 1_000 means 1%.
    // Can't be greater or equal than 10_000
    uint256 public rentFee = 0;

    mapping(bytes32 => LendingRenting) public lendingRentings;

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert NotAdmin(msg.sender);
        }
        _;
    }

    modifier notPaused() {
        if (paused) {
            revert Paused();
        }
        _;
    }

    constructor(address newResolver, address payable newBeneficiary) {
        resolver = IResolver(newResolver);
        beneficiary = newBeneficiary;
        admin = address(msg.sender);
    }

    /// @dev This function executes handler function on calldata. Helps to keep code DRY
    /// and avoid stack too deep error.
    /// @param handler Function that transitions the contract's state.
    /// @param cd      CallData encapsulates params that are required for handler execution.
    /// Helps with stack too deep errors.
    function bundleCall(function(CallData memory) handler, CallData memory cd)
        private
    {
        if (cd.nfts.nft.length == 0) {
            revert NoNfts();
        }

        while (cd.right != cd.nfts.nft.length) {
            if (
                (cd.nfts.nft[cd.left] == cd.nfts.nft[cd.right]) &&
                (cd.nfts.nft[cd.right].is1155())
            ) {
                // batch functions can be used on 1155s
                // therefore we extend the range of selection here
                cd.right++;
            } else {
                // each 721 needs to be sent separately, even
                // when they belong to the same collection (address)
                handler(cd);
                cd.left = cd.right;
                cd.right++;
            }
        }

        handler(cd);
    }

    /// USER ENTRYPOINTS ///

    /// @inheritdoc IReNFT
    function lend(
        Nfts calldata nfts,
        uint256[] memory lendAmounts,
        uint8[] memory maxRentDurations,
        Price[] memory dailyRentPrices,
        Price[] memory collaterals,
        bytes32[] memory whitelistMerkleRoots,
        IResolver.PaymentToken[] memory paymentTokens
    ) external override notPaused {
        bundleCall(
            handleLend,
            createCallData(
                nfts,
                lendAmounts,
                maxRentDurations,
                new uint8[](0),
                dailyRentPrices,
                collaterals,
                whitelistMerkleRoots,
                new bytes32[][](0),
                paymentTokens
            )
        );
    }

    /// @inheritdoc IReNFT
    function editLend(
        Nfts calldata nfts,
        uint8[] calldata maxRentDurations,
        Price[] calldata dailyRentPrices,
        Price[] calldata collaterals,
        bytes32[] calldata whitelistMerkleRoots,
        IResolver.PaymentToken[] calldata paymentTokens
    ) external override notPaused {
        /// Unlike other entrypoints, here we are required to make
        /// modifications to **every** NFT. Thus, no bundleCall.
        handleEditLend(
            nfts,
            maxRentDurations,
            dailyRentPrices,
            collaterals,
            whitelistMerkleRoots,
            paymentTokens
        );
    }

    /// @inheritdoc IReNFT
    function stopLend(Nfts calldata nfts) external override notPaused {
        bundleCall(
            handleStopLend,
            createCallData(
                nfts,
                new uint256[](0),
                new uint8[](0),
                new uint8[](0),
                new Price[](0),
                new Price[](0),
                new bytes32[](0),
                new bytes32[][](0),
                new IResolver.PaymentToken[](0)
            )
        );
    }

    /// @inheritdoc IReNFT
    function rent(
        Nfts calldata nfts, 
        bytes32[][] calldata whitelistMerkleProofs, 
        uint8[] memory rentDurations
    )
        external
        override
        notPaused
    {
        bundleCall(
            handleRent,
            createCallData(
                nfts,
                new uint256[](0),
                new uint8[](0),
                rentDurations,
                new Price[](0),
                new Price[](0),
                new bytes32[](0),
                whitelistMerkleProofs,
                new IResolver.PaymentToken[](0)
            )
        );
    }

    /// @inheritdoc IReNFT
    function stopRent(Nfts calldata nfts) external override notPaused {
        bundleCall(
            handleStopRent,
            createCallData(
                nfts,
                new uint256[](0),
                new uint8[](0),
                new uint8[](0),
                new Price[](0),
                new Price[](0),
                new bytes32[](0),
                new bytes32[][](0),
                new IResolver.PaymentToken[](0)
            )
        );
    }

    /// @inheritdoc IReNFT
    function claim(Nfts calldata nfts) external override notPaused {
        bundleCall(
            handleClaim,
            createCallData(
                nfts,
                new uint256[](0),
                new uint8[](0),
                new uint8[](0),
                new Price[](0),
                new Price[](0),
                new bytes32[](0),
                new bytes32[][](0),
                new IResolver.PaymentToken[](0)
            )
        );
    }

    /// FINANCIAL ///

    /// @notice Takes protocol fee from the realised rent amounts.
    /// @param rentAmount Once renting is concluded, this is how much the renter
    /// owes the lender. This amount will be sent to the lender.
    /// @param paymentToken Index of the token from the Resolver. The `rentAmount`
    /// will be sent denominated in this token.
    function takeFee(uint256 rentAmount, IResolver.PaymentToken paymentToken)
        private
        returns (uint256 fee)
    {
        fee = (rentAmount * rentFee) / 10000;

        if (fee == 0) {
            return 0;
        }

        ERC20(resolver.getPaymentToken(paymentToken)).safeTransfer(
            beneficiary,
            fee
        );
    }

    /// @notice On rent end, the renter receives the unused amount of their initial
    /// rent lump payment. The lender, receives how much they are owed, which is
    /// proportional to the amount of time the renter rented the NFT(s).
    /// @param lendingRenting Parameter used to track the lending and the corresponding
    /// renting. This is a storage parameter.
    function distributePayments(LendingRenting storage lendingRenting) private {
        address paymentToken = resolver.getPaymentToken(
            lendingRenting.lending.paymentToken
        );

        uint256 collateral = toUint256(
            lendingRenting.lending.collateral,
            paymentToken
        );
        uint256 rentPrice = toUint256(
            lendingRenting.lending.dailyRentPrice,
            paymentToken
        );

        uint256 secondsRenting = block.timestamp -
            lendingRenting.renting.rentedAt;

        uint256 rentPaid = rentPrice * lendingRenting.renting.rentDuration;
        uint256 sendLenderAmt = (secondsRenting * rentPrice) / SECONDS_IN_DAY;
        uint256 sendRenterAmt = rentPaid - sendLenderAmt;

        uint256 takenFee = takeFee(
            sendLenderAmt,
            lendingRenting.lending.paymentToken
        );

        sendLenderAmt -= takenFee;
        sendRenterAmt += collateral;

        if (sendLenderAmt != 0) {
            ERC20(paymentToken).safeTransfer(
                lendingRenting.lending.lenderAddress,
                sendLenderAmt
            );
        }
        if (sendRenterAmt != 0) {
            ERC20(paymentToken).safeTransfer(
                lendingRenting.renting.renterAddress,
                sendRenterAmt
            );
        }
    }

    /// @notice Send the rent lump sum, along with the collateral to the lender.
    /// This can only be called if the renter failed to return the NFT(s) in time.
    /// Thus, defaulting on the said NFT(s).
    /// @param lendingRenting Paremter used to track the lending and the corresponding
    /// renting.
    function distributeClaimPayment(LendingRenting memory lendingRenting)
        private
    {
        address paymentToken = resolver.getPaymentToken(
            lendingRenting.lending.paymentToken
        );

        uint256 collateral = toUint256(
            lendingRenting.lending.collateral,
            paymentToken
        );
        uint256 rentPrice = toUint256(
            lendingRenting.lending.dailyRentPrice,
            paymentToken
        );

        uint256 rentPaid = rentPrice * lendingRenting.renting.rentDuration;
        uint256 takenFee = takeFee(
            rentPaid,
            lendingRenting.lending.paymentToken
        );
        uint256 claimable = rentPaid + collateral - takenFee;

        if (claimable != 0) {
            ERC20(paymentToken).safeTransfer(
                lendingRenting.lending.lenderAddress,
                claimable
            );
        }
    }

    /// EFFECTS - MAIN LOGIC ///

    /// @dev Creates new lendings.
    /// @param cd CallData that gets created in the lend function. This is used to avoid
    /// stack too deep issues.
    function handleLend(CallData memory cd) private {
        bool isPure721 = false;
        if (cd.nfts.nft[cd.left].is721() && !cd.nfts.nft[cd.left].is1155()) {
            isPure721 = true;
        }

        for (uint256 i = cd.left; i < cd.right; i++) {
            // Before writing to storage, check that arguments are OK
            checkIsLendable(cd, i);

            if (isPure721 && (uint8(cd.lentAmounts[i]) != 1)) {
                revert InvalidAmountToLend(cd.lentAmounts[i]);
            }

            LendingRenting storage item = getLendingRenting(
                        cd.nfts.nft[cd.left],
                        cd.nfts.tokenIds[i],
                        lendingId
                    );

            item.lending.checkIsEmpty();
            item.renting.checkIsEmpty();

            item.lending = Lending({
                lenderAddress: payable(msg.sender),
                lentAmount: uint8(cd.lentAmounts[i]),
                maxRentDuration: cd.maxRentDurations[i],
                dailyRentPrice: cd.dailyRentPrices[i],
                collateral: cd.collaterals[i],
                whitelistMerkleRoot: cd.whitelistMerkleRoots[i],
                paymentToken: cd.paymentTokens[i]
            });

            address paymentToken = resolver.getPaymentToken(
                item.lending.paymentToken
            );

            emit Lent({
                nftAddress: address(cd.nfts.nft[cd.left]),
                tokenId: cd.nfts.tokenIds[i],
                lentAmount: uint8(cd.lentAmounts[i]),
                lendingId: lendingId,
                lenderAddress: msg.sender,
                maxRentDuration: cd.maxRentDurations[i],
                dailyRentPrice: toUint256(cd.dailyRentPrices[i], paymentToken),
                collateral: toUint256(cd.collaterals[i], paymentToken),
                whitelistMerkleRoot: cd.whitelistMerkleRoots[i],
                paymentToken: cd.paymentTokens[i]
            });

            lendingId++;
        }

        bool success = cd.nfts.nft[cd.left].safeTransferFrom_(
            msg.sender,
            address(this),
            sliceArr(cd.nfts.tokenIds, cd.left, cd.right, 0),
            sliceArr(cd.lentAmounts, cd.left, cd.right, 0),
            new bytes(0)
        );

        if (!success) {
            revert NftTransferFailed();
        }
    }

    /// @dev Edits an existing lending. The only properties of the lending that can be changed
    /// are: maxRentDuration, dailyRentPrice, collateral, paymentToken.
    /// @param nfts             NFT(s) to be edited.
    /// @param maxRentDurations New max rent durations on the lendings.
    /// @param dailyRentPrices  New daily rent prices on the lendings.
    /// @param collaterals      New collaterals on the lendings.
    /// @param whitelistMerkleRoots New merkle roots for address whitelisting.
    /// @param paymentTokens    New payment tokens on the lendings.
    function handleEditLend(
        Nfts calldata nfts,
        uint8[] calldata maxRentDurations,
        Price[] calldata dailyRentPrices,
        Price[] calldata collaterals,
        bytes32[] calldata whitelistMerkleRoots,
        IResolver.PaymentToken[] calldata paymentTokens
    ) private {
        for (uint256 i = 0; i < nfts.nft.length; i++) {
            if (maxRentDurations[i] == 0) {
                revert NotLendable();
            }
            if (paymentTokens[i] == IResolver.PaymentToken.SENTINEL) {
                revert NotLendable();
            }

            LendingRenting storage item = getLendingRenting(
                        nfts.nft[i],
                        nfts.tokenIds[i],
                        nfts.lendingIds[i]
                    );

            item.lending.checkIsNotEmpty();
            /// Check that lender on the item is editor (i.e. msg.sender)
            if (item.lending.lenderAddress != msg.sender) {
                revert NotAllowedToEdit();
            }
            item.renting.checkIsEmpty();

            item.lending.maxRentDuration = maxRentDurations[i];
            item.lending.dailyRentPrice = dailyRentPrices[i];
            item.lending.collateral = collaterals[i];
            item.lending.whitelistMerkleRoot = whitelistMerkleRoots[i];
            item.lending.paymentToken = paymentTokens[i];

            address paymentToken = resolver.getPaymentToken(
                item.lending.paymentToken
            );

            emit LendingEdited({
                lendingId: nfts.lendingIds[i],
                maxRentDuration: item.lending.maxRentDuration,
                dailyRentPrice: toUint256(
                    item.lending.dailyRentPrice,
                    paymentToken
                ),
                collateral: toUint256(item.lending.collateral, paymentToken),
                whitelistMerkleRoot: item.lending.whitelistMerkleRoot,
                paymentToken: item.lending.paymentToken
            });
        }
    }

    /// @dev Creates a new renting from an existing lending that is not being rented currently.
    /// @param cd CallData that gets created in the lend function. This is used to avoid
    /// stack too deep issues.
    function handleRent(CallData memory cd) private {
        uint256[] memory lentAmounts = new uint256[](cd.right - cd.left);

        for (uint256 i = cd.left; i < cd.right; i++) {
            LendingRenting storage item = lendingRentings[
                keccak256(
                    abi.encodePacked(
                        cd.nfts.nft[cd.left],
                        cd.nfts.tokenIds[i],
                        cd.nfts.lendingIds[i]
                    )
                )
            ];

            item.lending.checkIsNotEmpty();
            item.renting.checkIsEmpty();
            item.lending.checkIsRentable(cd, i, msg.sender);

            address paymentToken = resolver.getPaymentToken(
                item.lending.paymentToken
            );

            {
                uint256 rentPayable = cd.rentDurations[i] *
                    toUint256(item.lending.dailyRentPrice, paymentToken);
                uint256 collateralPayable = toUint256(
                    item.lending.collateral,
                    paymentToken
                );
                uint256 totalPayable = rentPayable + collateralPayable;

                if (totalPayable != 0) {
                    ERC20(paymentToken).safeTransferFrom(
                        msg.sender,
                        address(this),
                        totalPayable
                    );
                }
            }

            // i >= cd.left. When i = cd.left, index is 0, and so on
            lentAmounts[i - cd.left] = item.lending.lentAmount;

            item.renting.renterAddress = payable(msg.sender);
            item.renting.rentDuration = cd.rentDurations[i];
            item.renting.rentedAt = uint32(block.timestamp);

            emit Rented({
                lendingId: cd.nfts.lendingIds[i],
                renterAddress: msg.sender,
                rentDuration: cd.rentDurations[i]
            });
        }

        bool success = cd.nfts.nft[cd.left].safeTransferFrom_(
            address(this),
            msg.sender,
            sliceArr(cd.nfts.tokenIds, cd.left, cd.right, 0),
            sliceArr(lentAmounts, cd.left, cd.right, cd.left),
            new bytes(0)
        );

        if (!success) {
            revert NftTransferFailed();
        }
    }

    /// @dev Returns the rented NFT(s) if before the deadline.
    /// @param cd CallData that gets created in the lend function. This is used to avoid
    /// stack too deep issues.
    function handleStopRent(CallData memory cd) private {
        uint256[] memory lentAmounts = new uint256[](cd.right - cd.left);

        for (uint256 i = cd.left; i < cd.right; i++) {
            LendingRenting storage item = lendingRentings[
                keccak256(
                    abi.encodePacked(
                        cd.nfts.nft[cd.left],
                        cd.nfts.tokenIds[i],
                        cd.nfts.lendingIds[i]
                    )
                )
            ];

            item.lending.checkIsNotEmpty();
            item.renting.checkIsReturnable();

            distributePayments(item);

            // i >= cd.left
            lentAmounts[i - cd.left] = item.lending.lentAmount;

            emit Returned({lendingId: cd.nfts.lendingIds[i]});

            delete item.renting;
        }

        bool success = cd.nfts.nft[cd.left].safeTransferFrom_(
            msg.sender,
            address(this),
            sliceArr(cd.nfts.tokenIds, cd.left, cd.right, 0),
            sliceArr(lentAmounts, cd.left, cd.right, cd.left),
            new bytes(0)
        );

        if (!success) {
            revert NftTransferFailed();
        }
    }

    /// @dev Stops existing lending. Lending must not have an active renting attached to it.
    /// If it does, it can only be stopped after the renting ends.
    /// @param cd CallData that gets created in the lend function. This is used to avoid
    /// stack too deep issues.
    function handleStopLend(CallData memory cd) private {
        uint256[] memory lentAmounts = new uint256[](cd.right - cd.left);

        for (uint256 i = cd.left; i < cd.right; i++) {
            LendingRenting storage item = lendingRentings[
                keccak256(
                    abi.encodePacked(
                        cd.nfts.nft[cd.left],
                        cd.nfts.tokenIds[i],
                        cd.nfts.lendingIds[i]
                    )
                )
            ];

            item.lending.checkIsNotEmpty();
            item.renting.checkIsEmpty();
            item.lending.checkIsStoppable();

            lentAmounts[i - cd.left] = item.lending.lentAmount;

            emit LendingStopped({lendingId: cd.nfts.lendingIds[i]});

            delete item.lending;
        }

        bool success = cd.nfts.nft[cd.left].safeTransferFrom_(
            address(this),
            msg.sender,
            sliceArr(cd.nfts.tokenIds, cd.left, cd.right, 0),
            sliceArr(lentAmounts, cd.left, cd.right, cd.left),
            new bytes(0)
        );

        if (!success) {
            revert NftTransferFailed();
        }
    }

    /// @dev If the renting was not returned on time, the lender can claim the collateral plus
    /// the full rent amount accrued during the renting period.
    /// @param cd CallData that gets created in the lend function. This is used to avoid
    /// stack too deep issues.
    function handleClaim(CallData memory cd) private {
        for (uint256 i = cd.left; i < cd.right; i++) {
            LendingRenting storage item = lendingRentings[
                keccak256(
                    abi.encodePacked(
                        cd.nfts.nft[cd.left],
                        cd.nfts.tokenIds[i],
                        cd.nfts.lendingIds[i]
                    )
                )
            ];

            item.lending.checkIsNotEmpty();
            item.renting.checkIsNotEmpty();
            item.renting.checkIsClaimable();

            distributeClaimPayment(item);

            emit CollateralClaimed({lendingId: cd.nfts.lendingIds[i]});

            delete item.lending;
            delete item.renting;
        }
    }

    /// UTILS ///

    function getLendingRenting(
        INFTContract _nft, 
        uint256 _tokenId, 
        uint256 _lendingId
    ) private view returns (LendingRenting storage){
        return lendingRentings[
                keccak256(
                    abi.encodePacked(
                        _nft,
                        _tokenId,
                        _lendingId
                    )
                )
            ];
    }

    function createCallData(
        Nfts calldata nfts,
        uint256[] memory lentAmounts,
        uint8[] memory maxRentDurations,
        uint8[] memory rentDurations,
        Price[] memory dailyRentPrices,
        Price[] memory collaterals,
        bytes32[] memory whitelistMerkleRoots,
        bytes32[][] memory whitelistMerkleProofs,
        IResolver.PaymentToken[] memory paymentTokens
    ) private pure returns (CallData memory) {
        return
            CallData({
                left: 0,
                right: 1,
                nfts: nfts,
                lentAmounts: lentAmounts,
                maxRentDurations: maxRentDurations,
                rentDurations: rentDurations,
                dailyRentPrices: dailyRentPrices,
                collaterals: collaterals,
                whitelistMerkleRoots: whitelistMerkleRoots,
                whitelistMerkleProofs: whitelistMerkleProofs,
                paymentTokens: paymentTokens
            });
    }

    function sliceArr(
        uint256[] memory arr,
        uint256 fromIx,
        uint256 toIx,
        uint256 arrOffset
    ) private pure returns (uint256[] memory r) {
        r = new uint256[](toIx - fromIx);
        for (uint256 i = fromIx; i < toIx; i++) {
            r[i - fromIx] = arr[i - arrOffset];
        }
    }

    /// @dev To fit each lending in a single storage slot, the prices need
    /// to be packed. This function allows to get back a uint256 from Price type.
    /// @param p            Price type value of the price.
    /// @param paymentToken Used to apply the correct scale to the price. Different
    /// tokens will have different decimal places.
    function toUint256(Price memory p, address paymentToken)
        private
        view
        returns (uint256)
    {
        uint256 decimals = ERC20(paymentToken).decimals();
        uint256 scale = 10**decimals;

        uint256 decimalPart = p.decimal < 100 ? p.decimal : 99;
        return p.whole * scale + (decimalPart * (scale / 100));
    }

    /// CHECKS ///

    function checkIsLendable(CallData memory cd, uint256 i) private pure {
        if (cd.lentAmounts[i] == 0) {
            revert NotLendable();
        }
        /// receiving uint256 for lent amounts, but storing as uint8 to
        ///     Tightly pack into a single storage slot
        /// Not using uint8 cd.lentAmounts, because NFT transfer functions expect
        /// a uint256
        if (cd.lentAmounts[i] > type(uint8).max) {
            revert NotLendable();
        }
        if (cd.maxRentDurations[i] == 0) {
            revert NotLendable();
        }
        if (cd.paymentTokens[i] == IResolver.PaymentToken.SENTINEL) {
            revert NotLendable();
        }
    }

    /// ADMIN ///

    function setRentFee(uint256 newFee) external onlyAdmin {
        rentFee = newFee;
    }

    function setBeneficiary(address payable newBeneficiary) external onlyAdmin {
        beneficiary = newBeneficiary;
    }

    function setPaused(bool newPaused) external onlyAdmin {
        paused = newPaused;
    }
}

/*
 *
 *              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
 *              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
 *         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
 *    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
 *         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
 *         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
 *              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
 *              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@ *
 *
 * ReNFT: IReNFT.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 reNFT Labs Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

//              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
//              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
//         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
//    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
//         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
//         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
//              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
//              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@

interface IResolver {
    /// ENUMS ///

    enum PaymentToken {
        SENTINEL,
        WETH,
        DAI,
        USDC,
        USDT,
        TUSD,
        RENT
    }

    /// CONSTANT FUNCTIONS ///

    function getPaymentToken(PaymentToken paymentToken)
        external
        view
        returns (address);

    /// NON-CONSTANT FUNCTIONS ///

    function setPaymentToken(uint8 paymentToken, address value) external;
}

/*
 *
 *              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
 *              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
 *         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
 *    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
 *         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
 *         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
 *              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
 *              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@ *
 *
 * Resolver: IResolver.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 reNFT Labs Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IResolver.sol";
import "./INFTContract.sol";

//              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
//              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
//         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
//    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
//         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
//         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
//              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
//              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@

interface IReNFT is IERC721Receiver, IERC1155Receiver {
    /// STRUCTS ///

    struct Nfts {
        INFTContract[] nft;
        uint256[] tokenIds;
        uint256[] lendingIds;
    }

    /// @dev double storage slot: address - 160 bits, 192, 224, 232, 240, 248, 504
    struct Lending {
        address payable lenderAddress;
        Price dailyRentPrice;
        Price collateral;
        uint8 maxRentDuration;
        uint8 lentAmount;
        IResolver.PaymentToken paymentToken;
        bytes32 whitelistMerkleRoot;
    }

    /// @dev single storage slot: 160 bits, 168, 200
    struct Renting {
        address payable renterAddress;
        uint8 rentDuration;
        uint32 rentedAt;
    }

    struct LendingRenting {
        Lending lending;
        Renting renting;
    }

    struct Price {
        uint24 whole;
        uint8 decimal;
    }

    struct CallData {
        uint256 left;
        uint256 right;
        Nfts nfts;
        uint256[] lentAmounts;
        uint8[] maxRentDurations;
        uint8[] rentDurations;
        Price[] dailyRentPrices;
        Price[] collaterals;
        IResolver.PaymentToken[] paymentTokens;
        bytes32[] whitelistMerkleRoots;
        bytes32[][] whitelistMerkleProofs;
    }

    /// EVENTS ///

    event Lent(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint8 lentAmount,
        uint256 lendingId,
        address indexed lenderAddress,
        uint8 maxRentDuration,
        uint256 dailyRentPrice,
        uint256 collateral,
        bytes32 whitelistMerkleRoot,
        IResolver.PaymentToken paymentToken
    );

    event LendingEdited(
        uint256 indexed lendingId,
        uint8 maxRentDuration,
        uint256 dailyRentPrice,
        uint256 collateral,
        bytes32 whitelistMerkleRoot,
        IResolver.PaymentToken paymentToken
    );

    event Rented(
        uint256 indexed lendingId,
        address indexed renterAddress,
        uint8 rentDuration
    );

    event Returned(uint256 indexed lendingId);

    event CollateralClaimed(uint256 indexed lendingId);

    event LendingStopped(uint256 indexed lendingId);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sends your NFT(s) to ReNFT contract, which acts as an escrow
    /// between the lender and the renter. Called by lender.
    /// @param nfts NFT(s) to be lent.
    /// @param lendAmounts In case that some of the NFTs are 1155s, amount to be
    /// lent.
    /// @param maxRentDuration Max allowed rent duration per NFT.
    /// @param dailyRentPrice  Daily rent price payable to rent.
    /// @param collateral      Collateral payable by renter. In case the NFT is  not
    /// returned by the renter, this amount is claimable by lender.
    /// @param whitelistMerkleRoots Merkle root of the address whitelist
    /// @param paymentToken    Index of the payment token with which to pay the
    /// collateral and daily rent price.
    function lend(
        Nfts calldata nfts,
        uint256[] calldata lendAmounts,
        uint8[] calldata maxRentDuration,
        Price[] calldata dailyRentPrice,
        Price[] calldata collateral,
        bytes32[] calldata whitelistMerkleRoots,
        IResolver.PaymentToken[] calldata paymentToken
    ) external;

    /// @notice Edit your lendings.
    /// @param nfts lending(s) to be edited.
    /// @param maxRentDuration Max allowed rent duration per NFT.
    /// @param dailyRentPrice Daily rent price payable to rent.
    /// @param collateral Collateral payable by renter. In case the NFT is  not returned
    /// by the renter, this amount is claimable by lender.
    /// @param whitelistMerkleRoots Merkle root of the address whitelist
    /// @param paymentToken Index of the payment token with which to pay the collateral
    /// and daily rent price.
    function editLend(
        Nfts calldata nfts,
        uint8[] calldata maxRentDuration,
        Price[] calldata dailyRentPrice,
        Price[] calldata collateral,
        bytes32[] calldata whitelistMerkleRoots,
        IResolver.PaymentToken[] calldata paymentToken
    ) external;

    /// @notice Renter sends the collateral and rent payments, and receives
    /// the NFT(s) in return. Called by renter.
    /// @param nfts NFT(s) to be rented.
    /// @param whitelistMerkleProofs Merkle proofs for the address whitelist.
    /// @param rentDurations Number of days that the renter wishes to rent the NFT for.
    /// It is possible to return the NFT prior to this. In which case, the renter
    /// receives the unused balance.
    function rent(
        Nfts calldata nfts,
        bytes32[][] calldata whitelistMerkleProofs, 
        uint8[] calldata rentDurations
        ) external;

    /// @notice Renters call this to return the rented NFT before the
    /// deadline. If they fail to do so, they will lose the posted
    /// collateral. Called by renter.
    /// @param nfts NFT(s) to be returned.
    function stopRent(Nfts calldata nfts) external;

    /// @notice Claim collateral on rentals that are past their due date.
    /// Called by lender.
    /// @param nfts NFT(s) to claim collateral on.
    function claim(Nfts calldata nfts) external;

    /// @notice Stop lending releases the NFT(s) from escrow and sends it back
    /// to the lender. Called by lender.
    /// @param nfts NFT(s) to stop lending.
    function stopLend(Nfts calldata nfts) external;
}

/*
 *
 *              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
 *              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
 *         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
 *    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
 *         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
 *         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
 *              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
 *              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@ *
 *
 * ReNFT: IReNFT.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 reNFT Labs Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

//SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "../interfaces/INFTContract.sol";

library NFTCommon {
    /// @notice Transfers the NFT tokenID from to.
    /// @dev safeTransferFrom_ name to avoid collision with the interface signature definitions. The reason it is implemented the way it is,
    /// is because some NFT contracts implement both the 721 and 1155 standard at the same time. Sometimes, 721 or 1155 function does not work.
    /// So instead of relying on the user's input, or asking the contract what interface it implements, it is best to just make a good assumption
    /// about what NFT type it is (here we guess it is 721 first), and if that fails, we use the 1155 function to tranfer the NFT.
    /// @param nft     NFT address
    /// @param from    Source address
    /// @param to      Target address
    /// @param tokenID ID of the token type
    /// @param amount  Quantity, in case of the ERC1155, to send
    /// @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    /// @return        true = transfer successful, false = transfer not successful
    function safeTransferFrom_(
        INFTContract nft,
        address from,
        address to,
        uint256[] memory tokenID,
        uint256[] memory amount,
        bytes memory data
    ) internal returns (bool) {
        bool supports721 = is721(nft);
        bool supports1155 = is1155(nft);

        if (supports721 && !supports1155) {
            try nft.safeTransferFrom(from, to, tokenID[0], data) {
                return true;
            } catch (bytes memory) {
                return false;
            }
        }

        if (!supports1155) {
            return false;
        }

        // Supports 1155. May or May not support 721 at the same time
        try nft.safeBatchTransferFrom(from, to, tokenID, amount, data) {
            return true;
        } catch (bytes memory) {
            return false;
        }
    }

    function is721(INFTContract nft) internal view returns (bool) {
        return nft.supportsInterface(0x80ac58cd);
    }

    function is1155(INFTContract nft) internal view returns (bool) {
        return nft.supportsInterface(0xd9b67a26);
    }
}

/*
 *
 *              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
 *              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
 *         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
 *    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
 *         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
 *         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
 *              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
 *              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@ *
 *
 * NFTCommon: NFTCommon.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 reNFT Labs Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

//SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "../interfaces/IReNFT.sol";
import "../interfaces/IResolver.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @notice Emitted when the item cannot be rented.
error NotRentable();

/// @notice Emitted when the lending should be non-initiated, but is in fact initiated.
error LendingNotEmpty();

/// @notice Empitted when the lending should be initiated, but is in fact non-initiated.
error LendingEmpty();

/// @notice Emitted when the address stopping the lending is not the lender.
error StopperNotLender(address lender, address msgSender);

/// @notice Emitted when rent duration exceed max rent duration.
/// @param rentDuration Rent duration.
/// @param maxRentDuration Max allowed rent duration.
error RentDurationExceedsMaxRentDuration(
    uint8 rentDuration,
    uint8 maxRentDuration
);

/// @notice Emitted when the address is not whitelisted to rent the lending.
/// @param notWhitelisted The address that is not whitelisted to rent.
/// @param merkleProof The merkle proof
/// @param merkleRoot The whitelist merkle root
error AddressNotWhitelisted(address notWhitelisted, bytes32[] merkleProof, bytes32 merkleRoot);

library LendingChecks {
    function checkIsEmpty(IReNFT.Lending storage lending) internal view {
        if (lending.lenderAddress != address(0)) {
            revert LendingNotEmpty();
        }
        // if (lending.maxRentDuration != 0) {
        //     revert LendingNotEmpty();
        // }
        // if (lending.lentAmount != 0) {
        //     revert LendingNotEmpty();
        // }
        // if (lending.paymentToken != IResolver.PaymentToken.SENTINEL) {
        //     revert LendingNotEmpty();
        // }
    }

    function checkIsNotEmpty(IReNFT.Lending storage lending) internal view {
        if (lending.lenderAddress == address(0)) {
            revert LendingEmpty();
        }
        /// * Below checks are performed at lending
        // if (lending.maxRentDuration == 0) {
        //     revert LendingEmpty();
        // }
        // if (lending.lentAmount == 0) {
        //     revert LendingEmpty();
        // }
        // if (lending.paymentToken == IResolver.PaymentToken.SENTINEL) {
        //     revert LendingEmpty();
        // }
        // Not checking the collateral and daily rent prices here for zeros
        // because they are allowed in v2
    }

    function checkIsRentable(
        IReNFT.Lending storage lending,
        IReNFT.CallData memory cd,
        uint256 i,
        address msgSender
    ) internal pure {
        IReNFT.Lending memory _lending = lending;

        if (msgSender == _lending.lenderAddress) {
            revert NotRentable();
        }
        if (cd.rentDurations[i] == 0) {
            revert NotRentable();
        }
        if (cd.rentDurations[i] > _lending.maxRentDuration) {
            revert RentDurationExceedsMaxRentDuration(
                cd.rentDurations[i],
                _lending.maxRentDuration
            );
        }
        if(_lending.whitelistMerkleRoot != 0 && !MerkleProof.verify(cd.whitelistMerkleProofs[i], _lending.whitelistMerkleRoot, keccak256(abi.encodePacked(msgSender)))){
            revert AddressNotWhitelisted(
                msgSender,
                cd.whitelistMerkleProofs[i],
                _lending.whitelistMerkleRoot
            );
        }
    }

    function checkIsStoppable(IReNFT.Lending storage lending) internal view {
        if (lending.lenderAddress != msg.sender) {
            revert StopperNotLender(lending.lenderAddress, msg.sender);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "../interfaces/IReNFT.sol";

/// @notice Emitted when the renting should be non-initiated, but is in fact initiated.
error RentingNotEmpty();

/// @notice Emitted when the renting should be initiated, but is in fact non-initiated.
error RentingEmpty();

/// @notice Emitted when NFT(s) can't be returned, because they are past their
/// return date.
/// @param nowTimestamp Current block's  timestamp.
/// @param rentedAt Rented at timestamp.
/// @param rentDuration Rent duration in days.
error PastReturnDate(uint256 nowTimestamp, uint32 rentedAt, uint8 rentDuration);

/// @notice Emitted when someone tried to claim the collateral on the NFT that is not past its
/// return date.
/// @param nowTimestamp      Block timestamp of the transaction.
/// @param rentedAtTimestamp Timestamp when the NFT was rented.
/// @param rentDuration      How many days the NFT was rented for.
error NotPastReturnDate(
    uint256 nowTimestamp,
    uint256 rentedAtTimestamp,
    uint256 rentDuration
);

/// @dev Emitted when isPastReturnDate is called with `now` which is on or before `rentedAt`.
/// @param nowTimestamp      Block timestamp of the transaction.
/// @param rentedAtTimestamp Timestamp when the NFT was rented.
error NowBeforeRentedAt(uint256 nowTimestamp, uint256 rentedAtTimestamp);

/// @notice Emitted when the returner is not the renter.
error ReturnerNotRenterNotAllowed(address renter, address msgSender);

library RentingChecks {
    function checkIsEmpty(IReNFT.Renting storage renting) internal view {
        if (renting.renterAddress != address(0)) {
            revert RentingNotEmpty();
        }
        /// * Only check the address, other attributes are set, if the
        /// address was set.
        // if (renting.rentDuration != 0) {
        //     revert RentingNotEmpty();
        // }
        // if (renting.rentedAt != 0) {
        //     revert RentingNotEmpty();
        // }
    }

    function checkIsNotEmpty(IReNFT.Renting storage renting) internal view {
        if (renting.renterAddress == address(0)) {
            revert RentingEmpty();
        }
        // if (renting.rentDuration == 0) {
        //     revert RentingEmpty();
        // }
        // if (renting.rentedAt == 0) {
        //     revert RentingEmpty();
        // }
    }

    function checkIsReturnable(IReNFT.Renting storage renting) internal view {
        if (renting.renterAddress != msg.sender) {
            revert ReturnerNotRenterNotAllowed(
                renting.renterAddress,
                msg.sender
            );
        }
        bool rentingPastReturnDate = isPastReturnDate(renting);
        if (rentingPastReturnDate) {
            revert PastReturnDate(
                block.timestamp,
                renting.rentedAt,
                renting.rentDuration
            );
        }
    }

    function checkIsClaimable(IReNFT.Renting storage renting) internal view {
        bool rentingPastReturnDate = isPastReturnDate(renting);
        if (!rentingPastReturnDate) {
            revert NotPastReturnDate(
                block.timestamp,
                renting.rentedAt,
                renting.rentDuration
            );
        }
    }

    function isPastReturnDate(IReNFT.Renting storage renting)
        internal
        view
        returns (bool)
    {
        if (block.timestamp <= renting.rentedAt) {
            revert NowBeforeRentedAt(block.timestamp, renting.rentedAt);
        }
        /// 86400 seconds in a day
        return
            block.timestamp - renting.rentedAt > renting.rentDuration * 86400;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

//SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

interface INFTContract {
    /// ERC1155 ///

    /// @notice Get the balance of an account's tokens.
    /// @param owner  The address of the token holder
    /// @param id     ID of the token
    /// @return        The owner's balance of the token type requested
    function balanceOf(address owner, uint256 id)
        external
        view
        returns (uint256);

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param operator  Address to add to the set of authorized operators
    /// @param approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Transfers `value` amount of an `id` from the `from` address to the `to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
    /// MUST revert if `to` is the zero address.
    /// MUST revert if balance of holder for token `id` is lower than the `value` sent.
    /// MUST revert on any other error.
    /// MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    /// After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param from    Source address
    /// @param to      Target address
    /// @param id      ID of the token type
    /// @param value   Transfer amount
    /// @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /// @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
    /// MUST revert if `to` is the zero address.
    /// MUST revert if length of `ids` is not the same as length of `values`.
    /// MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
    /// MUST revert on any other error.
    /// MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    /// Balance changes and events MUST follow the ordering of the arrays (ids[0]/values[0] before ids[1]/values[1], etc).
    /// After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param from    Source address
    /// @param to      Target address
    /// @param ids     IDs of each token type (order and length must match values array)
    /// @param values  Transfer amounts per token type (order and length must match ids array)
    /// @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /// ERC721 ///

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an NFT
    /// @return owner  The address of the owner of the NFT
    function ownerOf(uint256 tokenId) external view returns (address owner);

    // function setApprovalForAll(address operator, bool approved) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param approved The new approved NFT controller
    /// @param tokenId The NFT to approve
    function approve(address approved, uint256 tokenId) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `from` is
    ///  not the current owner. Throws if `to` is the zero address. Throws if
    ///  `tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `to`
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /// ERC165 ///

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

    // -------------------------------------------------------------------------------
}

/*
 *
 *              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
 *              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
 *         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
 *    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
 *         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
 *         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
 *              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
 *              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@ *
 *
 * INFTContract: INFTContract.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 reNFT Labs Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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