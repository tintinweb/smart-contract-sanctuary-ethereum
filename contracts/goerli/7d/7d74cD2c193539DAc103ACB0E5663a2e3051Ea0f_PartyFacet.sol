// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IPartyFacet} from "../interfaces/IPartyFacet.sol";
import {IERC20} from "../interfaces/IERC20.sol";

import {LibParty} from "../libraries/LibParty.sol";
import {LibSignatures} from "../libraries/LibSignatures.sol";
import {Modifiers, PartyInfo} from "../libraries/LibAppStorage.sol";

/// "Party manager is not kickable"
error OwnerNotKickable();
/// "Non-member user is not kickable"
error UserNotKickable();
/// "Manager user is not kickable. Need to remove role first"
error ManagerNotKickable();
/// "User needs invitation to join private party"
error NeedsInvitation();

/**
 * @title PartyFacet
 * @author PartyFinance
 * @notice Facet that contains the main actions to interact with a Party
 */
contract PartyFacet is Modifiers, IPartyFacet, IERC20 {
    /***************
    PARTY STATE GETTER
    ***************/
    // @inheritdoc IERC20
    function name() external view override returns (string memory) {
        return s.name;
    }

    // @inheritdoc IERC20
    function symbol() external view override returns (string memory) {
        return s.symbol;
    }

    // @inheritdoc IERC20
    function decimals() external pure override returns (uint8) {
        return 18;
    }

    // @inheritdoc IERC20
    function totalSupply() external view override returns (uint256) {
        return s.totalSupply;
    }

    // @inheritdoc IERC20
    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return s.balances[account];
    }

    // @inheritdoc IPartyState
    function denominationAsset() external view override returns (address) {
        return s.denominationAsset;
    }

    // @inheritdoc IPartyState
    function creator() external view override returns (address) {
        return s.creator;
    }

    // @inheritdoc IPartyState
    function members(address account) external view override returns (bool) {
        return s.members[account];
    }

    // @inheritdoc IPartyState
    function managers(address account) external view override returns (bool) {
        return s.managers[account];
    }

    // @inheritdoc IPartyState
    function getTokens() external view override returns (address[] memory) {
        return s.tokens;
    }

    // @inheritdoc IPartyState
    function partyInfo() external view override returns (PartyInfo memory) {
        return s.partyInfo;
    }

    // @inheritdoc IPartyState
    function closed() external view override returns (bool) {
        return s.closed;
    }

    /***************
    ACCESS ACTIONS
    ***************/
    // @inheritdoc IPartyCreatorActions
    function handleManager(address manager, bool setManager) external override {
        if (s.creator == address(0)) {
            // Patch for Facet upgrade
            require(s.managers[msg.sender], "Only Party Managers allowed");
            /// @dev Previously, parties didn't have the `creator` state, so for those parties the state will be zero address.
            s.creator = msg.sender;
        }
        require(s.creator == msg.sender, "Only Party Creator allowed");
        s.managers[manager] = setManager;
        // Emit Party managers change event
        emit PartyManagersChange(manager, setManager);
    }

    /***************
    PARTY ACTIONS
    ***************/
    // @inheritdoc IPartyActions
    function joinParty(
        address user,
        uint256 amount,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    ) external override notMember isAlive {
        // Handle request for private parties
        if (!s.partyInfo.isPublic) {
            if (!s.acceptedRequests[user]) {
                revert NeedsInvitation();
            }
            delete s.acceptedRequests[user];
        }

        // Add user as member
        s.members[user] = true;

        // Deposit, collect fees and mint party tokens
        (uint256 fee, uint256 mintedPT) = LibParty.mintPartyTokens(
            user,
            amount,
            allocation,
            approval
        );

        // Emit Join event
        emit Join(user, s.denominationAsset, amount, fee, mintedPT);
    }

    // @inheritdoc IPartyMemberActions
    function deposit(
        address user,
        uint256 amount,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    ) external override isAlive {
        require(s.members[user], "Only Party Members allowed");
        // Deposit, collect fees and mint party tokens
        (uint256 fee, uint256 mintedPT) = LibParty.mintPartyTokens(
            user,
            amount,
            allocation,
            approval
        );
        // Emit Deposit event
        emit Deposit(user, s.denominationAsset, amount, fee, mintedPT);
    }

    // @inheritdoc IPartyMemberActions
    function withdraw(
        uint256 amountPT,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        bool liquidate
    ) external override onlyMember {
        // Withdraw, collect fees and burn party tokens
        LibParty.redeemPartyTokens(
            amountPT,
            msg.sender,
            allocation,
            approval,
            liquidate
        );
        // Emit Withdraw event
        emit Withdraw(msg.sender, amountPT);
    }

    // @inheritdoc IPartyManagerActions
    function swapToken(
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    ) external override onlyManager {
        // Swap token
        (uint256 soldAmount, uint256 boughtAmount, uint256 fee) = LibParty
            .swapToken(allocation, approval);

        // Emit SwapToken event
        emit SwapToken(
            msg.sender,
            address(allocation.sellTokens[0]),
            address(allocation.buyTokens[0]),
            soldAmount,
            boughtAmount,
            fee
        );
    }

    // @inheritdoc IPartyManagerActions
    function kickMember(
        address kickingMember,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        bool liquidate
    ) external override onlyManager {
        if (kickingMember == msg.sender) revert OwnerNotKickable();
        if (!s.members[kickingMember]) revert UserNotKickable();
        if (s.managers[kickingMember]) revert ManagerNotKickable();
        // Get total PT from kicking member
        uint256 kickingMemberPT = s.balances[kickingMember];
        LibParty.redeemPartyTokens(
            kickingMemberPT,
            kickingMember,
            allocation,
            approval,
            liquidate
        );
        // Remove user as a member
        delete s.members[kickingMember];
        // Emit Kick event
        emit Kick(msg.sender, kickingMember, kickingMemberPT);
    }

    // @inheritdoc IPartyMemberActions
    function leaveParty(
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        bool liquidate
    ) external override onlyMember {
        // Get total PT from member
        uint256 leavingMemberPT = s.balances[msg.sender];
        LibParty.redeemPartyTokens(
            leavingMemberPT,
            msg.sender,
            allocation,
            approval,
            liquidate
        );
        // Remove user as a member
        delete s.members[msg.sender];
        // Emit Leave event
        emit Leave(msg.sender, leavingMemberPT);
    }

    // @inheritdoc IPartyCreatorActions
    function closeParty() external override onlyCreator isAlive {
        s.closed = true;
        // Emit Close event
        emit Close(msg.sender, s.totalSupply);
    }

    // @inheritdoc IPartyCreatorActions
    function editPartyInfo(
        PartyInfo memory _partyInfo
    ) external override onlyCreator {
        s.partyInfo = _partyInfo;
        emit PartyInfoEdit(
            _partyInfo.name,
            _partyInfo.bio,
            _partyInfo.img,
            _partyInfo.model,
            _partyInfo.purpose,
            _partyInfo.isPublic,
            _partyInfo.minDeposit,
            _partyInfo.maxDeposit
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IPartyActions} from "./party/IPartyActions.sol";
import {IPartyEvents} from "./party/IPartyEvents.sol";
import {IPartyMemberActions} from "./party/IPartyMemberActions.sol";
import {IPartyManagerActions} from "./party/IPartyManagerActions.sol";
import {IPartyCreatorActions} from "./party/IPartyCreatorActions.sol";
import {IPartyState} from "./party/IPartyState.sol";

/**
 * @title Interface for PartyFacet
 * @dev The party interface is broken up into smaller chunks
 */
interface IPartyFacet is
    IPartyActions,
    IPartyEvents,
    IPartyCreatorActions,
    IPartyManagerActions,
    IPartyMemberActions,
    IPartyState
{

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library LibSignatures {
    /**
     * @notice A struct containing the recovered Signature
     */
    struct Sig {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }
    /**
     * @notice A struct containing the Allocation info
     * @dev For the array members, need to have the same length.
     * @param sellTokens Array of ERC-20 token addresses to sell
     * @param sellAmounts Array of ERC-20 token amounts to sell
     * @param buyTokens Array of ERC-20 token addresses to buy
     * @param spenders Array of the spenders addresses
     * @param swapTargets Array of the targets to interact with (0x Exchange Proxy)
     * @param swapsCallDAta Array of bytes containing the calldata
     * @param partyValueDA Current value of the Party in denomination asset
     * @param partyTotalSupply Current total supply of the Party
     * @param expiresAt Block timestamp expiration date
     */
    struct Allocation {
        address[] sellTokens;
        uint256[] sellAmounts;
        address[] buyTokens;
        address[] spenders;
        address payable[] swapsTargets;
        bytes[] swapsCallData;
        uint256 partyValueDA;
        uint256 partyTotalSupply;
        uint256 expiresAt;
    }

    /**
     * @notice Returns the address that signed a hashed message with a signature
     */
    function recover(bytes32 _hash, bytes calldata _signature)
        internal
        pure
        returns (address)
    {
        return ECDSA.recover(_hash, _signature);
    }

    /**
     * @notice Returns an Ethereum Signed Message.
     * @dev Produces a hash corresponding to the one signed with the
     * [eth_sign JSON-RPC method](https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]) as part of EIP-191.
     */
    function getMessageHash(bytes memory _abiEncoded)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(_abiEncoded)
                )
            );
    }

    /**
     * @notice Verifies the tx signature against the PartyFi Sentinel address
     * @dev Used by the deposit, join, kick, leave and swap actions
     * @param user The user involved in the allocation
     * @param signer The PartyFi Sentinel singer address
     * @param allocation The allocation struct to verify
     * @param rsv The values for the transaction's signature
     */
    function isValidAllocation(
        address user,
        address signer,
        Allocation memory allocation,
        Sig memory rsv
    ) internal view returns (bool) {
        // 1. Checks if the allocation hasn't expire
        if (allocation.expiresAt < block.timestamp) return false;

        // 2. Hashes the allocation struct to get the allocation hash
        bytes32 allocationHash = getMessageHash(
            abi.encodePacked(
                address(this),
                user,
                allocation.sellTokens,
                allocation.sellAmounts,
                allocation.buyTokens,
                allocation.spenders,
                allocation.swapsTargets,
                allocation.partyValueDA,
                allocation.partyTotalSupply,
                allocation.expiresAt
            )
        );

        // 3. Validates if the recovered signer is the PartyFi Sentinel
        return ECDSA.recover(allocationHash, rsv.v, rsv.r, rsv.s) == signer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    /**
     * @notice Queries the Party ERC-20 token name
     * @return Token name metadata
     */
    function name() external view returns (string memory);

    /**
     * @notice Queries the Party ERC-20 token symbol
     * @return Token symbol metadata
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Queries the Party ERC-20 token decimals
     * @return Token decimals metadata
     */
    function decimals() external pure returns (uint8);

    /**
     * @notice Queries the Party ERC-20 total minted supply
     * @return Token total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Queries the Party ERC-20 balance of a given account
     * @param account Address
     * @return Token balance of a given ccount
     */
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {LibERC20} from "./LibERC20.sol";
import {LibSignatures} from "./LibSignatures.sol";
import {LibSharedStructs} from "./LibSharedStructs.sol";
import {LibAddressArray} from "./LibAddressArray.sol";

/// "Deposit is not enough"
error DepositNotEnough();
/// "Deposit exceeds maximum required"
error DepositExceeded();
/// "User balance is not enough"
error UserBalanceNotEnough();
/// "Failed approve reset"
error FailedAproveReset();
/// "Failed approving sellToken"
error FailedAprove();
/// "0x Protocol: SWAP_CALL_FAILED"
error ZeroXFail();
/// "Invalid approval signature"
error InvalidSignature();
/// "Only one swap at a time"
error InvalidSwap();

library LibParty {
    /**
     * @notice Emitted when quotes are filled by 0x for allocation of funds
     * @dev SwapToken is not included on this event, since its have the same information
     * @param member Address of the user
     * @param sellTokens Array of sell tokens
     * @param buyTokens Array of buy tokens
     * @param soldAmounts Array of sold amount of tokens
     * @param boughtAmounts Array of bought amount of tokens
     * @param partyValueDA The party value in denomination asset prior to the allocation
     */
    event AllocationFilled(
        address member,
        address[] sellTokens,
        address[] buyTokens,
        uint256[] soldAmounts,
        uint256[] boughtAmounts,
        uint256 partyValueDA
    );

    /**
     * @notice Emitted when a member redeems shares from a party
     * @param member Address of the user
     * @param burnedPT Burned party tokens for redemption
     * @param liquidate Redemption by liquitating shares into denomination asset
     * @param redeemedAssets Array of asset addresses
     * @param redeemedAmounts Array of asset amounts
     * @param redeemedFees Array of asset fees
     * @param redeemedNetAmounts Array of net asset amounts
     */
    event RedeemedShares(
        address member,
        uint256 burnedPT,
        bool liquidate,
        address[] redeemedAssets,
        uint256[] redeemedAmounts,
        uint256[] redeemedFees,
        uint256[] redeemedNetAmounts
    );

    /***************
    PLATFORM COLLECTOR
    ***************/
    /**
     * @notice Retrieves the Platform fee to be taken from an amount
     * @param amount Base amount to calculate fees
     */
    function getPlatformFee(uint256 amount, uint256 feeBps)
        internal
        pure
        returns (uint256 fee)
    {
        fee = (amount * feeBps) / 10000;
    }

    /**
     * @notice Transfers a fee amount of an ERC20 token to the platform collector address
     * @param amount Base amount to calculate fees
     * @param token ERC-20 token address
     */
    function collectPlatformFee(uint256 amount, address token)
        internal
        returns (uint256 fee)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        fee = getPlatformFee(amount, s.platformFee);
        IERC20Metadata(token).transfer(s.platformFeeCollector, fee);
    }

    /***************
    PARTY TOKEN FUNCTIONS
    ***************/
    /**
     * @notice Swap a token using 0x Protocol
     * @param allocation The swap allocation
     * @param approval The platform signature approval for the allocation
     */
    function swapToken(
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    )
        internal
        returns (
            uint256 soldAmount,
            uint256 boughtAmount,
            uint256 fee
        )
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (allocation.sellTokens.length != 1) revert InvalidSwap();
        // -> Validate authenticity of assets allocation
        if (
            !LibSignatures.isValidAllocation(
                msg.sender,
                s.platformSentinel,
                allocation,
                approval
            )
        ) {
            revert InvalidSignature();
        }
        // Fill 0x Quote
        LibSharedStructs.FilledQuote memory filledQuote = fillQuote(
            allocation.sellTokens[0],
            allocation.sellAmounts[0],
            allocation.buyTokens[0],
            allocation.spenders[0],
            allocation.swapsTargets[0],
            allocation.swapsCallData[0]
        );
        soldAmount = filledQuote.soldAmount;
        boughtAmount = filledQuote.boughtAmount;
        // Collect fees
        fee = collectPlatformFee(
            filledQuote.boughtAmount,
            allocation.buyTokens[0]
        );
        // Check if bought asset is new
        if (!LibAddressArray.contains(s.tokens, allocation.buyTokens[0])) {
            // Adding new asset to list
            s.tokens.push(allocation.buyTokens[0]);
        }
    }

    /**
     * @notice Mints PartyTokens in exchange for a deposit
     * @param user User address
     * @param amountDA The deposit amount in DA
     * @param allocation The deposit allocation
     * @param approval The platform signature approval for the allocation
     */
    function mintPartyTokens(
        address user,
        uint256 amountDA,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    ) internal returns (uint256 fee, uint256 mintedPT) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // 1) Handle deposit amount is between min-max range
        if (amountDA < s.partyInfo.minDeposit) revert DepositNotEnough();
        if (s.partyInfo.maxDeposit > 0 && amountDA > s.partyInfo.maxDeposit)
            revert DepositExceeded();

        // 2) Calculate Platform Fee
        fee = getPlatformFee(amountDA, s.platformFee);

        // 3) Transfer DA from user (deposit + fees)
        IERC20Metadata(s.denominationAsset).transferFrom(
            user,
            address(this),
            amountDA + fee
        );

        // 4) Collect protocol fees
        collectPlatformFee(amountDA, s.denominationAsset);

        // 5) Allocate deposit assets
        allocateAssets(user, allocation, approval, s.platformSentinel);

        // 6) Mint PartyTokens to user
        if (s.totalSupply == 0 || allocation.partyTotalSupply == 0) {
            mintedPT =
                amountDA *
                10**(18 - IERC20Metadata(s.denominationAsset).decimals());
        } else {
            uint256 adjPartyValueDA = allocation.partyValueDA;
            /// Handle any totalSupply changes
            /// @dev Which will indicate the the allocated partyValueDA was updated in the same block by another tx
            if (allocation.partyTotalSupply != s.totalSupply) {
                // Since there has been a change in the totalSupply, we need to get the adjusted party value in DA
                /// @dev Example case:
                //          - allocation.totalSupply: 500
                //          - allocation.partyValueDA is 1000
                //          - totalSupply is 750
                //       This means that the current partyValueDA is no longer 1000, since there was a change in the totalSupply.
                //       The totalSupply delta is 50%. So the current partyValueDA should be 1500.
                adjPartyValueDA =
                    (adjPartyValueDA * s.totalSupply) /
                    allocation.partyTotalSupply;
            }
            mintedPT = (s.totalSupply * amountDA) / adjPartyValueDA;
        }
        LibERC20._mint(user, mintedPT);
    }

    /**
     * @notice Redeems funds in exchange for PartyTokens
     * @param amountPT The PartyTokens amount
     * @param _memberAddress The member's address to redeem PartyTokens in
     * @param allocation The withdraw allocation
     * @param approval The platform signature approval for the allocation
     * @param liquidate Whether to withdraw by swapping funds into DA or not
     */
    function redeemPartyTokens(
        uint256 amountPT,
        address _memberAddress,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        bool liquidate
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // 1) Check if user has PartyTokens balance to redeem
        if (amountPT > s.balances[_memberAddress])
            revert UserBalanceNotEnough();

        // 2) Get the total supply of PartyTokens
        uint256 totalSupply = s.totalSupply;

        // 3) Burn PartyTokens
        LibERC20._burn(_memberAddress, amountPT);

        if (amountPT > 0) {
            // 4) Handle holdings redemption: liquidate holdings or redeem as it is
            if (liquidate) {
                liquidateHoldings(
                    amountPT,
                    totalSupply,
                    _memberAddress,
                    allocation,
                    approval,
                    s.denominationAsset,
                    s.platformSentinel
                );
            } else {
                redeemHoldings(amountPT, totalSupply, _memberAddress, s.tokens);
            }
        }
    }

    /***************
    HELPER FUNCTIONS
    ***************/
    /**
     * @notice Redeems assets without liquidating them
     * @param amountPT The PartyTokens amount
     * @param totalSupply The current totalSupply of the PartyTokens
     * @param _memberAddress The member's address to redeem PartyTokens in
     * @param tokens Current tokens in the party
     */
    function redeemHoldings(
        uint256 amountPT,
        uint256 totalSupply,
        address _memberAddress,
        address[] storage tokens
    ) private {
        uint256[] memory redeemedAmounts = new uint256[](tokens.length);
        uint256[] memory redeemedFees = new uint256[](tokens.length);
        uint256[] memory redeemedNetAmounts = new uint256[](tokens.length);

        // 1) Handle token holdings
        for (uint256 i = 0; i < tokens.length; i++) {
            // 2) Get token amount to redeem
            uint256 tBalance = IERC20Metadata(tokens[i]).balanceOf(
                address(this)
            );
            redeemedAmounts[i] = ((tBalance * amountPT) / totalSupply);

            if (redeemedAmounts[i] > 0) {
                // 3) Collect fees
                redeemedFees[i] = collectPlatformFee(
                    redeemedAmounts[i],
                    tokens[i]
                );
                redeemedNetAmounts[i] = (redeemedAmounts[i] - redeemedFees[i]);

                // 4) Transfer relative asset funds to user
                IERC20Metadata(tokens[i]).transfer(
                    _memberAddress,
                    redeemedNetAmounts[i]
                );
            }
        }
        emit RedeemedShares(
            _memberAddress,
            amountPT,
            false,
            tokens,
            redeemedAmounts,
            redeemedFees,
            redeemedNetAmounts
        );
    }

    /**
     * @notice Redeems assets by liquidating them into DA
     * @param amountPT The PartyTokens amount
     * @param totalSupply The current totalSupply of the PartyTokens
     * @param _memberAddress The member's address to redeem PartyTokens in
     * @param allocation The liquidation allocation
     * @param approval The platform signature approval for the allocation
     * @param denominationAsset The party's denomination asset address
     * @param sentinel The platform sentinel address
     */
    function liquidateHoldings(
        uint256 amountPT,
        uint256 totalSupply,
        address _memberAddress,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        address denominationAsset,
        address sentinel
    ) private {
        uint256[] memory redeemedAmounts = new uint256[](1);
        uint256[] memory redeemedFees = new uint256[](1);
        uint256[] memory redeemedNetAmounts = new uint256[](1);

        // 1) Get the portion of denomination asset to withdraw (before allocation)
        uint256 daBalance = IERC20Metadata(denominationAsset).balanceOf(
            address(this)
        );
        redeemedAmounts[0] = ((daBalance * amountPT) / totalSupply);

        // 2) Swap member's share of other assets into the denomination asset
        LibSharedStructs.Allocated memory allocated = allocateAssets(
            _memberAddress,
            allocation,
            approval,
            sentinel
        );

        // 3) Iterate through allocation and accumulate pending withdrawal for the user
        for (uint256 i = 0; i < allocated.boughtAmounts.length; i++) {
            // Double check that bought tokens are same as DA
            if (allocated.buyTokens[i] == denominationAsset) {
                redeemedAmounts[0] += allocated.boughtAmounts[i];
            }
        }

        // 4) Collect fees
        redeemedFees[0] = collectPlatformFee(
            redeemedAmounts[0],
            denominationAsset
        );

        // 5) Transfer relative DA funds to user
        redeemedNetAmounts[0] = redeemedAmounts[0] - redeemedFees[0];
        IERC20Metadata(denominationAsset).transfer(
            _memberAddress,
            redeemedNetAmounts[0]
        );

        emit RedeemedShares(
            _memberAddress,
            amountPT,
            true,
            allocated.sellTokens,
            redeemedAmounts,
            redeemedFees,
            redeemedNetAmounts
        );
    }

    /**
     * @notice Allocates multiple 0x quotes
     * @param sender The user's address
     * @param allocation The allocation
     * @param approval The platform signature approval for the allocation
     * @param sentinel The platform sentinel address
     */
    function allocateAssets(
        address sender,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        address sentinel
    ) private returns (LibSharedStructs.Allocated memory allocated) {
        if (
            !LibSignatures.isValidAllocation(
                sender,
                sentinel,
                allocation,
                approval
            )
        ) {
            revert InvalidSignature();
        }

        // Declaring array with a known length
        allocated.sellTokens = new address[](allocation.sellTokens.length);
        allocated.buyTokens = new address[](allocation.sellTokens.length);
        allocated.soldAmounts = new uint256[](allocation.sellTokens.length);
        allocated.boughtAmounts = new uint256[](allocation.sellTokens.length);
        for (uint256 i = 0; i < allocation.sellTokens.length; i++) {
            LibSharedStructs.FilledQuote memory filledQuote = fillQuote(
                allocation.sellTokens[i],
                allocation.sellAmounts[i],
                allocation.buyTokens[i],
                allocation.spenders[i],
                allocation.swapsTargets[i],
                allocation.swapsCallData[i]
            );
            allocated.sellTokens[i] = address(allocation.sellTokens[i]);
            allocated.buyTokens[i] = address(allocation.buyTokens[i]);
            allocated.soldAmounts[i] = filledQuote.soldAmount;
            allocated.boughtAmounts[i] = filledQuote.boughtAmount;
        }

        // Emit AllocationFilled
        emit AllocationFilled(
            sender,
            allocated.sellTokens,
            allocated.buyTokens,
            allocated.soldAmounts,
            allocated.boughtAmounts,
            allocation.partyValueDA
        );
    }

    /**
     * @notice Swap a token held by this contract using a 0x-API quote.
     * @param sellToken The token address to sell
     * @param sellAmount The token amount to sell
     * @param buyToken The token address to buy
     * @param spender The spender address
     * @param swapTarget The swap target to interact (0x Exchange Proxy)
     * @param swapCallData The swap calldata to pass
     */
    function fillQuote(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        address spender,
        address payable swapTarget,
        bytes memory swapCallData
    ) private returns (LibSharedStructs.FilledQuote memory filledQuote) {
        if (!IERC20Metadata(sellToken).approve(spender, 0))
            revert FailedAproveReset();
        if (!IERC20Metadata(sellToken).approve(spender, sellAmount))
            revert FailedAprove();

        // Track initial balance of the sellToken to determine how much we've sold.
        filledQuote.initialSellBalance = IERC20Metadata(sellToken).balanceOf(
            address(this)
        );

        // Track initial balance of the buyToken to determine how much we've bought.
        filledQuote.initialBuyBalance = IERC20Metadata(buyToken).balanceOf(
            address(this)
        );
        // Execute 0xSwap
        (bool success, ) = swapTarget.call{value: msg.value}(swapCallData);
        if (!success) revert ZeroXFail();

        // Get how much we've sold.
        filledQuote.soldAmount =
            filledQuote.initialSellBalance -
            IERC20Metadata(sellToken).balanceOf(address(this));

        // Get how much we've bought.
        filledQuote.boughtAmount =
            IERC20Metadata(buyToken).balanceOf(address(this)) -
            filledQuote.initialBuyBalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibMeta} from "./LibMeta.sol";

/**
 * @notice A struct containing the Party info tracked in storage.
 * @param name Name of the Party
 * @param bio Description of the Party
 * @param img Image URL of the Party (path to storage without protocol/domain)
 * @param model Model of the Party: "Democracy", "Monarchy", "WeightedDemocracy", "Republic"
 * @param purpose Purpose of the Party: "Trading", "YieldFarming", "LiquidityProviding", "NFT"
 * @param isPublic Visibility of the Party. (Private parties requires an accepted join request)
 * @param minDeposit Minimum deposit allowed in denomination asset
 * @param maxDeposit Maximum deposit allowed in denomination asset
 */
struct PartyInfo {
    string name;
    string bio;
    string img;
    string model;
    string purpose;
    bool isPublic;
    uint256 minDeposit;
    uint256 maxDeposit;
}

/**
 * @notice A struct containing the Announcement info tracked in storage.
 * @param title Title of the Announcement
 * @param bio Content of the Announcement
 * @param img Any external URL to include in the Announcement
 * @param model Model of the Party: "Democracy", "Monarchy", "WeightedDemocracy", "Republic"
 * @param created Block timestamp date of the Announcement creation
 * @param updated Block timestamp date of any Announcement edition
 */
struct Announcement {
    string title;
    string content;
    string url;
    string img;
    uint256 created;
    uint256 updated;
}

struct AppStorage {
    //
    // Party vault token
    //
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    //
    // Denomination token asset for deposit/withdraws
    //
    address denominationAsset;
    //
    // Party info
    //
    PartyInfo partyInfo;
    bool closed; // Party life status
    //
    // Party access
    //
    mapping(address => bool) managers; // Maping to get if address is a manager
    mapping(address => bool) members; // Maping to get if address is a member
    //
    // Party ERC-20 holdings
    //
    address[] tokens; // Array of current party tokens holdings
    //
    // Party Announcements
    //
    Announcement[] announcements;
    //
    // Party Join Requests
    //
    address[] joinRequests; // Array of users that requested to join the party
    mapping(address => bool) acceptedRequests; // Mapping of requests accepted by a manager
    //
    // PLATFORM
    //
    uint256 platformFee; // Platform fee (in bps, 50 bps -> 0.5%)
    address platformFeeCollector; // Platform fee collector
    address platformSentinel; // Platform sentinel
    address platformFactory; // Platform factory
    //
    // Extended Party access
    //
    address creator; // Creator of the Party
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyCreator() {
        require(s.creator == LibMeta.msgSender(), "Only Party Creator allowed");
        _;
    }

    modifier onlyManager() {
        require(s.managers[LibMeta.msgSender()], "Only Party Managers allowed");
        _;
    }

    modifier onlyMember() {
        require(s.members[LibMeta.msgSender()], "Only Party Members allowed");
        _;
    }

    modifier notMember() {
        require(
            !s.members[LibMeta.msgSender()],
            "Only non Party Members allowed"
        );
        _;
    }

    modifier onlyFactory() {
        require(
            LibMeta.msgSender() == s.platformFactory,
            "Only Factory allowed"
        );
        _;
    }

    modifier isAlive() {
        require(!s.closed, "Party is closed");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Libraries
import {LibSignatures} from "../../libraries/LibSignatures.sol";

/**
 * @notice Contains party methods that can be called by any member of the party
 * @dev Permissioned Party actions
 */
interface IPartyMemberActions {
    /**
     * @notice Deposits into the party
     * @dev The user must be a member and the party must be opened
     * @param user User address that will be making the deposit
     * @param amount Deposit amount in denomination asset
     * @param allocation Desired allocation of the deposit
     * @param approval Verified sentinel signature of the desired deposit
     */
    function deposit(
        address user,
        uint256 amount,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    ) external;

    /**
     * @notice Withdraw funds from the party
     * @dev The user must be a member
     * @param amountPT Amount of PartyTokens of the requester to withdraw
     * @param allocation Desired allocation of the withdraw
     * @param approval Verified sentinel signature of the desired withdraw
     * @param liquidate Whether to liquidate assets (convert all owned assets into denomination asset) or to withdraw assets as it is
     */
    function withdraw(
        uint256 amountPT,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        bool liquidate
    ) external;

    /**
     * @notice Leave the party (withdraw all funds and remove membership)
     * @dev The user must be a member
     * @param allocation Desired allocation of the withdraw
     * @param approval Verified sentinel signature of the desired withdraw
     * @param liquidate Whether to liquidate assets (convert all owned assets into denomination asset) or to withdraw assets as it is
     */
    function leaveParty(
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        bool liquidate
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Libraries
import {LibSignatures} from "../../libraries/LibSignatures.sol";

/**
 * @notice Contains party methods that can be called by anyone
 * @dev Permissionless Party actions
 */
interface IPartyActions {
    /**
     * @notice Joins and deposits into the party
     * @dev For private parties, the joiner must have an accepted join request by a manager.
     *      The user must not be a member and the party must be opened
     * @param user User address that will be joining the party
     * @param amount Deposit amount in denomination asset
     * @param allocation Desired allocation of the deposit
     * @param approval Verified sentinel signature of the desired deposit
     */
    function joinParty(
        address user,
        uint256 amount,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Libraries
import {LibSignatures} from "../../libraries/LibSignatures.sol";
import {PartyInfo} from "../../libraries/LibAppStorage.sol";

/**
 * @notice Contains party methods that can be called by any manager of the Party
 * @dev Permissioned Party actions
 */
interface IPartyManagerActions {
    /**
     * @notice Swap a token with the party's fund
     * @dev The user must be a manager. Only swaps a single asset.
     * @param allocation Desired allocation of the swap
     * @param approval Verified sentinel signature of the desired swap
     */
    function swapToken(
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval
    ) external;

    /**
     * @notice Kick a member from the party
     * @dev The user must be a manager
     * @param kickingMember address of the member to be kicked
     * @param allocation desired allocation of the withdraw
     * @param approval verified sentinel signature of the desired kick
     * @param liquidate whether to liquidate assets (convert all owned assets into denomination asset) or to transfer assets as it is
     */
    function kickMember(
        address kickingMember,
        LibSignatures.Allocation memory allocation,
        LibSignatures.Sig memory approval,
        bool liquidate
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Libraries
import {LibSignatures} from "../../libraries/LibSignatures.sol";
import {PartyInfo} from "../../libraries/LibAppStorage.sol";

/**
 * @notice Contains party methods that can be called by the creator of the Party
 * @dev Permissioned Party actions
 */
interface IPartyCreatorActions {
    /**
     * @notice Close the party
     * @dev The user must be a creator and the party must be opened
     */
    function closeParty() external;

    /**
     * @notice Edits the party information
     * @dev The user must be a creator
     * @param _partyInfo PartyInfo struct
     */
    function editPartyInfo(PartyInfo memory _partyInfo) external;

    /**
     * @notice Handles the managers for the party
     * @dev The user must be the creator of the party
     * @param manager Address of the user
     * @param setManager Whether to set the user as manager or remove it
     */
    function handleManager(address manager, bool setManager) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {PartyInfo} from "../../libraries/LibAppStorage.sol";

/**
 * @notice Methods that compose the party and that are mutable
 */
interface IPartyState {
    /**
     * @notice Queries the Party denomination asset (ERC-20)
     * @dev The denomination asset is used for depositing into the party, which is an ERC-20 stablecoin
     * @return Denomination asset address
     */
    function denominationAsset() external view returns (address);

    /**
     * @notice Queries the Party's creator address
     * @return The address of the user who created the Party
     */
    function creator() external view returns (address);

    /**
     * @notice Queries the Party's member access of given address
     * @param account Address
     * @return Whether if the given address is a member
     */
    function members(address account) external view returns (bool);

    /**
     * @notice Queries the Party's manager access of given address
     * @param account Address
     * @return Whether if the given address is a manager
     */
    function managers(address account) external view returns (bool);

    /**
     * @notice Queries the ERC-20 tokens held in the Party
     * @dev Will display the tokens that were acquired through a Swap/LimitOrder method
     * @return Array of ERC-20 addresses
     */
    function getTokens() external view returns (address[] memory);

    /**
     * @notice Queries the party information
     * @return PartyInfo struct
     */
    function partyInfo() external view returns (PartyInfo memory);

    /**
     * @notice Queries if the Party is closed
     * @return Whether if the Party is already closed or not
     */
    function closed() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice Contains all events emitted by the party
 * @dev Events emitted by a party
 */
interface IPartyEvents {
    /**
     * @notice Emitted exactly once by a party when #initialize is first called
     * @param partyCreator Address of the user that created the party
     * @param partyName Name of the party
     * @param isPublic Visibility of the party
     * @param dAsset Address of the denomination asset for the party
     * @param minDeposit Minimum deposit of the party
     * @param maxDeposit Maximum deposit of the party
     * @param mintedPT Minted party tokens for creating the party
     * @param bio Bio of the party
     * @param img Img url of the party
     * @param model Model of party created
     * @param purpose Purpose of party created
     */
    event PartyCreated(
        address partyCreator,
        string partyName,
        bool isPublic,
        address dAsset,
        uint256 minDeposit,
        uint256 maxDeposit,
        uint256 mintedPT,
        string bio,
        string img,
        string model,
        string purpose
    );

    /**
     * @notice Emitted when a user joins a party
     * @param member Address of the user
     * @param asset Address of the denomination asset
     * @param amount Amount of the deposit
     * @param fee Collected fee
     * @param mintedPT Minted party tokens for joining
     */
    event Join(
        address member,
        address asset,
        uint256 amount,
        uint256 fee,
        uint256 mintedPT
    );

    /**
     * @notice Emitted when a member deposits denomination assets into a party
     * @param member Address of the user
     * @param asset Address of the denomination asset
     * @param amount Amount of the deposit
     * @param fee Collected fee
     * @param mintedPT Minted party tokens for depositing
     */
    event Deposit(
        address member,
        address asset,
        uint256 amount,
        uint256 fee,
        uint256 mintedPT
    );

    /**
     * @notice Emitted when quotes are filled by 0x for allocation of funds
     * @dev SwapToken is not included on this event, since its have the same information
     * @param member Address of the user
     * @param sellTokens Array of sell tokens
     * @param buyTokens Array of buy tokens
     * @param soldAmounts Array of sold amount of tokens
     * @param boughtAmounts Array of bought amount of tokens
     * @param partyValueDA The party value in denomination asset prior to the allocation
     */
    event AllocationFilled(
        address member,
        address[] sellTokens,
        address[] buyTokens,
        uint256[] soldAmounts,
        uint256[] boughtAmounts,
        uint256 partyValueDA
    );

    /**
     * @notice Emitted when a member redeems shares from a party
     * @param member Address of the user
     * @param burnedPT Burned party tokens for redemption
     * @param liquidate Redemption by liquitating shares into denomination asset
     * @param redeemedAssets Array of asset addresses
     * @param redeemedAmounts Array of asset amounts
     * @param redeemedFees Array of asset fees
     * @param redeemedNetAmounts Array of net asset amounts
     */
    event RedeemedShares(
        address member,
        uint256 burnedPT,
        bool liquidate,
        address[] redeemedAssets,
        uint256[] redeemedAmounts,
        uint256[] redeemedFees,
        uint256[] redeemedNetAmounts
    );

    /**
     * @notice Emitted when a member withdraws from a party
     * @param member Address of the user
     * @param burnedPT Burned party tokens of member
     */
    event Withdraw(address member, uint256 burnedPT);

    /**
     * @notice Emitted when quotes are filled by 0x in the same tx
     * @param member Address of the user
     * @param sellToken Sell token address
     * @param buyToken Buy token address
     * @param soldAmount Sold amount of token
     * @param boughtAmount Bought amount of token
     * @param fee fee collected
     */
    event SwapToken(
        address member,
        address sellToken,
        address buyToken,
        uint256 soldAmount,
        uint256 boughtAmount,
        uint256 fee
    );

    /**
     * @notice Emitted when a member gets kicked from a party
     * @param kicker Address of the kicker (owner)
     * @param kicked Address of the kicked member
     * @param burnedPT Burned party tokens of member
     */
    event Kick(address kicker, address kicked, uint256 burnedPT);

    /**
     * @notice Emitted when a member leaves a party
     * @param member Address of the user
     * @param burnedPT Burned party tokens for withdrawing
     */
    event Leave(address member, uint256 burnedPT);

    /**
     * @notice Emitted when the owner closes a party
     * @param member Address of the user (should be party owner)
     * @param supply Total supply of party tokens when the party closed
     */
    event Close(address member, uint256 supply);

    /**
     * @notice Emitted when the party information changes after creation
     * @param name Name of the party
     * @param bio Bio of the party
     * @param img Img url of the party
     * @param model Model of party created
     * @param purpose Purpose of party created
     * @param isPublic Visibility of the party
     * @param minDeposit Minimum deposit of the party
     * @param maxDeposit Maximum deposit of the party
     */
    event PartyInfoEdit(
        string name,
        string bio,
        string img,
        string model,
        string purpose,
        bool isPublic,
        uint256 minDeposit,
        uint256 maxDeposit
    );

    /**
     * @notice Emitted when the party creator adds or remove a party manager
     * @param manager Address of the user
     * @param isManager Whether to set the user was set as manager or removed from it
     */
    event PartyManagersChange(address manager, bool isManager);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LibMeta {
    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LibSharedStructs {
    struct Allocation {
        address[] sellTokens;
        uint256[] sellAmounts;
        address[] buyTokens;
        address[] spenders;
        address payable[] swapsTargets;
        bytes[] swapsCallData;
        uint256 partyValueDA;
        uint256 partyTotalSupply;
        uint256 expiresAt;
    }

    struct FilledQuote {
        address sellToken;
        address buyToken;
        uint256 soldAmount;
        uint256 boughtAmount;
        uint256 initialSellBalance;
        uint256 initialBuyBalance;
    }

    struct Allocated {
        address[] sellTokens;
        address[] buyTokens;
        uint256[] soldAmounts;
        uint256[] boughtAmounts;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LibAddressArray {
    function contains(address[] memory self, address _address)
        internal
        pure
        returns (bool contained)
    {
        for (uint256 i; i < self.length; i++) {
            if (_address == self[i]) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";

library LibERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice Mint tokens for a given account
     * @param account Address recipient
     * @param amount Amount of tokens to be minted
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        AppStorage storage s = LibAppStorage.diamondStorage();
        s.totalSupply += amount;
        s.balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Burn tokens held by given account
     * @param account Address of burned tokens
     * @param amount Amount of tokens to be burnt
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 balance = s.balances[account];
        require(balance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            s.balances[account] = balance - amount;
        }
        s.totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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