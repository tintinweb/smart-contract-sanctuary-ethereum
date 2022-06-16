// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**


    ██████╗ █████╗  ██╗     ██╗  ██╗   ██╗
    ██╔════╝██╔══██╗██║     ██║  ╚██╗ ██╔╝
    ██║     ███████║██║     ██║   ╚████╔╝ 
    ██║     ██╔══██║██║     ██║    ╚██╔╝  
    ╚██████╗██║  ██║███████╗███████╗██║   
     ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝   
                                      

    
    NFT & ERC20 covered call vaults.
    this is intended to be a public good.
    pog pog pog.
    

*/

import "solmate/utils/SafeTransferLib.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin/access/Ownable.sol";

import "./CallyNft.sol";

/// @title Cally - https://cally.finance
/// @author out.eth
/// @notice NFT & ERC20 covered call vaults
contract Cally is CallyNft, ReentrancyGuard, Ownable, ERC721TokenReceiver {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address payable;

    /// @notice Fires when a new vault has been created
    /// @param vaultId The newly minted vault NFT
    /// @param from The account that created the vault
    /// @param token The token address of the underlying asset
    event NewVault(uint256 indexed vaultId, address indexed from, address indexed token);

    /// @notice Fires when an option has been bought from a vault
    /// @param optionId The newly minted option NFT
    /// @param from The account that bought the option
    /// @param token The token address of the underlying asset
    event BoughtOption(uint256 indexed optionId, address indexed from, address indexed token);

    /// @notice Fires when an option is exercised
    /// @param optionId The option NFT which is being exercised
    /// @param from The account that exercised the option
    event ExercisedOption(uint256 indexed optionId, address indexed from);

    /// @notice Fires when someone harvests their ETH balance
    /// @param from The account that is harvesting
    /// @param amount The amount of ETH which was harvested
    event Harvested(address indexed from, uint256 amount);

    /// @notice Fires when someone initiates a withdrawal on their vault
    /// @param vaultId The vault NFT which is being withdrawn
    /// @param from The account that is initiating the withdrawal
    event InitiatedWithdrawal(uint256 indexed vaultId, address indexed from);

    /// @notice Fires when someone withdraws their vault
    /// @param vaultId The vault NFT which is being withdrawn
    /// @param from The account that is withdrawing
    event Withdrawal(uint256 indexed vaultId, address indexed from);

    /// @notice Fires when owner sets a new fee
    /// @param newFee The new feeRate
    event SetFee(uint256 indexed newFee);

    /// @notice Fires when a vault owner updates the vault beneficiary
    /// @param vaultId The vault NFT which is being updated
    /// @param from The vault owner
    /// @param to The new beneficiary
    event SetVaultBeneficiary(uint256 indexed vaultId, address indexed from, address indexed to);

    enum TokenType {
        ERC721,
        ERC20
    }

    struct Vault {
        uint256 tokenIdOrAmount;
        address token;
        uint8 premiumIndex; // indexes into `premiumOptions`
        uint8 durationDays; // days
        uint8 dutchAuctionStartingStrikeIndex; // indexes into `strikeOptions`
        uint32 currentExpiration;
        bool isExercised;
        bool isWithdrawing;
        TokenType tokenType;
        uint16 feeRate;
        uint256 currentStrike;
        uint256 dutchAuctionReserveStrike;
    }

    uint32 public constant AUCTION_DURATION = 24 hours;

    // prettier-ignore
    uint256[17] public premiumOptions = [0.01 ether, 0.025 ether, 0.05 ether, 0.075 ether, 0.1 ether, 0.25 ether, 0.5 ether, 0.75 ether, 1.0 ether, 2.5 ether, 5.0 ether, 7.5 ether, 10 ether, 25 ether, 50 ether, 75 ether, 100 ether];
    // prettier-ignore
    uint256[19] public strikeOptions = [1 ether, 2 ether, 3 ether, 5 ether, 8 ether, 13 ether, 21 ether, 34 ether, 55 ether, 89 ether, 144 ether, 233 ether, 377 ether, 610 ether, 987 ether, 1597 ether, 2584 ether, 4181 ether, 6765 ether];

    /// @notice the feeRate of the protocol, ex; 300 = 30%, 10 = 1%, 3 = 0.3% etc.
    uint16 public feeRate = 0;
    uint256 public protocolUnclaimedFees;

    /// @notice The current vault index. Used for determining which
    ///         tokenId to use when minting a new vault. Increments by
    ///         2 on each new mint.
    uint256 public vaultIndex = 1;

    /// @notice Mapping of vault tokenId -> vault information
    mapping(uint256 => Vault) private _vaults;

    /// @notice Mapping of vault tokenId -> vault beneficiary.
    ///         Beneficiary is credited the premium when option is
    ///         purchased or strike ETH when option is exercised.
    mapping(uint256 => address) private _vaultBeneficiaries;

    /// @notice The unharvested ethBalance of each account.
    mapping(address => uint256) public ethBalance;

    /*********************
        ADMIN FUNCTIONS
    **********************/

    /// @notice Sets the fee that is applied on exercise
    /// @param feeRate_ The new fee rate, ex: feeRate = 1% = 10.
    ///                 1000 is equal to 100% feeRate.
    function setFee(uint16 feeRate_) external payable onlyOwner {
        require(feeRate_ <= 300, "Fee cannot be larger than 30%");

        feeRate = feeRate_;

        emit SetFee(feeRate_);
    }

    /// @notice Withdraws the protocol fees and sends to current owner
    /// @return amount The amount of ETH that was withdrawn
    function withdrawProtocolFees() external payable onlyOwner returns (uint256 amount) {
        amount = protocolUnclaimedFees;
        protocolUnclaimedFees = 0;

        emit Harvested(msg.sender, amount);

        payable(msg.sender).safeTransferETH(amount);
    }

    /// @notice Sends any unclaimed ETH (premiums/strike) locked in the
    ///         contract to the current owner.
    /// @return amount The amount of ETH that was harvested
    function selfHarvest() external payable onlyOwner returns (uint256 amount) {
        // reset premiums
        amount = ethBalance[address(this)];
        ethBalance[address(this)] = 0;

        emit Harvested(address(this), amount);

        // transfer premiums to owner
        payable(msg.sender).safeTransferETH(amount);
    }

    /**************************
        MAIN LOGIC FUNCTIONS
    ***************************/

    /// @dev    A wrapper around createVault to allow for multiple
    ///         vault creations in a single transaction.
    function createVaults(
        uint256[] memory tokenIdOrAmounts,
        address[] memory tokens,
        uint8[] memory premiumIndexes,
        uint8[] memory durationDays,
        uint8[] memory dutchAuctionStartingStrikeIndexes,
        uint256[] memory dutchAuctionReserveStrikes,
        TokenType[] memory tokenTypes
    ) external returns (uint256[] memory vaultIds) {
        vaultIds = new uint256[](tokenIdOrAmounts.length);

        for (uint256 i = 0; i < tokenIdOrAmounts.length; i++) {
            uint256 vaultId = createVault(
                tokenIdOrAmounts[i],
                tokens[i],
                premiumIndexes[i],
                durationDays[i],
                dutchAuctionStartingStrikeIndexes[i],
                dutchAuctionReserveStrikes[i],
                tokenTypes[i]
            );

            vaultIds[i] = vaultId;
        }
    }

    /*
        standard life cycle:
            createVault
            buyOption (repeats)
            exercise
            initiateWithdraw
            withdraw

        [*] setVaultBeneficiary
        [*] harvest

        [*] can be called anytime in life cycle
    */

    /// @notice Creates a new vault that perpetually sells calls
    ///         on the underlying assets.
    /// @param tokenIdOrAmount The tokenId (NFT) or amount (ERC20) to vault
    /// @param token The address of the NFT or ERC20 contract to vault
    /// @param premiumIndex The index into the premiumOptions of each call that is sold
    /// @param durationDays The length/duration of each call that is sold in days
    /// @param dutchAuctionStartingStrikeIndex The index into the strikeOptions for the starting strike for each dutch auction
    /// @param dutchAuctionReserveStrike The reserve strike for each dutch auction
    /// @param tokenType The type of the underlying asset (NFT or ERC20)
    /// @return vaultId The tokenId of the newly minted vault NFT
    function createVault(
        uint256 tokenIdOrAmount,
        address token,
        uint8 premiumIndex,
        uint8 durationDays,
        uint8 dutchAuctionStartingStrikeIndex,
        uint256 dutchAuctionReserveStrike,
        TokenType tokenType
    ) public returns (uint256 vaultId) {
        require(premiumIndex < premiumOptions.length, "Invalid premium index");
        require(dutchAuctionStartingStrikeIndex < strikeOptions.length, "Invalid strike index");
        require(dutchAuctionReserveStrike < strikeOptions[dutchAuctionStartingStrikeIndex], "Reserve strike too large");
        require(durationDays > 0, "durationDays too small");
        require(token.code.length > 0, "token is not contract");
        require(token != address(this), "token cannot be Cally contract");
        require(tokenType == TokenType.ERC721 || tokenIdOrAmount > 0, "tokenIdOrAmount is 0");

        // vault index should always be odd
        unchecked {
            vaultIndex = vaultIndex + 2;
        }
        vaultId = vaultIndex;

        Vault storage vault = _vaults[vaultId];

        vault.token = token;
        vault.premiumIndex = premiumIndex;
        vault.durationDays = durationDays;
        vault.dutchAuctionStartingStrikeIndex = dutchAuctionStartingStrikeIndex;
        vault.currentExpiration = uint32(block.timestamp);
        vault.tokenType = tokenType;

        if (feeRate > 0) {
            vault.feeRate = feeRate;
        }

        if (dutchAuctionReserveStrike > 0) {
            vault.dutchAuctionReserveStrike = dutchAuctionReserveStrike;
        }

        // give msg.sender vault token
        _mint(msg.sender, vaultId);

        emit NewVault(vaultId, msg.sender, token);

        // transfer the NFTs or ERC20s to the contract
        if (tokenType == TokenType.ERC721) {
            vault.tokenIdOrAmount = tokenIdOrAmount;
            ERC721(token).safeTransferFrom(msg.sender, address(this), tokenIdOrAmount);
        } else {
            // check balance before and after to handle fee-on-transfer tokens
            uint256 balanceBefore = ERC20(token).balanceOf(address(this));
            ERC20(token).safeTransferFrom(msg.sender, address(this), tokenIdOrAmount);
            vault.tokenIdOrAmount = ERC20(token).balanceOf(address(this)) - balanceBefore;
        }
    }

    /// @notice Buys an option from a vault at a fixed premium and variable strike
    ///         which is dependent on the dutch auction. Premium is credited to
    ///         vault beneficiary.
    /// @param vaultId The tokenId of the vault to buy the option from
    /// @return optionId The token id of the associated option NFT for the vaultId
    function buyOption(uint256 vaultId) external payable returns (uint256 optionId) {
        // vaultId should always be odd
        require(vaultId % 2 != 0, "Not vault type");

        // check vault exists
        require(ownerOf(vaultId) != address(0), "Vault does not exist");

        Vault storage vault = _vaults[vaultId];

        // check that the vault still has the NFTs or ERC20s as collateral
        require(!vault.isExercised, "Vault already exercised");

        // check that the vault is not in the withdrawing state
        require(!vault.isWithdrawing, "Vault is being withdrawn");

        // check enough ETH was sent to cover the premium
        uint256 premium = premiumOptions[vault.premiumIndex];
        require(msg.value == premium, "Incorrect ETH amount sent");

        // check option associated with the vault has expired
        uint32 auctionStartTimestamp = vault.currentExpiration;
        require(block.timestamp >= auctionStartTimestamp, "Auction not started");

        // set new currentStrike based on the dutch auction curve
        vault.currentStrike = getDutchAuctionStrike(
            strikeOptions[vault.dutchAuctionStartingStrikeIndex],
            auctionStartTimestamp + AUCTION_DURATION,
            vault.dutchAuctionReserveStrike
        );

        // set new expiration
        vault.currentExpiration = uint32(block.timestamp) + uint32(vault.durationDays) * 1 days;

        // force transfer the vault's associated option from old owner to new owner.
        // option id for a respective vault is always vaultId + 1.
        optionId = vaultId + 1;
        _forceTransfer(msg.sender, optionId);

        // increment vault beneficiary's unclaimed premiums
        address beneficiary = getVaultBeneficiary(vaultId);
        ethBalance[beneficiary] += msg.value;

        emit BoughtOption(optionId, msg.sender, vault.token);
    }

    /// @notice Exercises a call option and sends the underlying assets to the
    ///         exerciser and credits the strike ETH to the vault beneficiary.
    /// @param optionId The tokenId of the option to exercise
    function exercise(uint256 optionId) external payable {
        // optionId should always be even
        require(optionId % 2 == 0, "Not option type");

        // check owner
        require(msg.sender == ownerOf(optionId), "You are not the owner");

        // vault id for a respective option is always optionId - 1.
        uint256 vaultId = optionId - 1;
        Vault storage vault = _vaults[vaultId];

        // check option hasn't expired
        require(block.timestamp < vault.currentExpiration, "Option has expired");

        // check correct ETH amount was sent to pay the strike
        require(msg.value == vault.currentStrike, "Incorrect ETH sent for strike");

        // burn the option token
        _burn(optionId);

        // mark the vault as exercised
        vault.isExercised = true;

        // collect protocol fee
        uint256 fee = 0;
        if (vault.feeRate > 0) {
            // ex: 5% fees means vault.feeRate == 50
            fee = (msg.value * vault.feeRate) / 1000;
            protocolUnclaimedFees += fee;
        }

        // increment vault beneficiary's ETH balance
        ethBalance[getVaultBeneficiary(vaultId)] += msg.value - fee;

        emit ExercisedOption(optionId, msg.sender);

        // transfer the NFTs or ERC20s to the exerciser
        vault.tokenType == TokenType.ERC721
            ? ERC721(vault.token).safeTransferFrom(address(this), msg.sender, vault.tokenIdOrAmount)
            : ERC20(vault.token).safeTransfer(msg.sender, vault.tokenIdOrAmount);
    }

    /// @notice Initiates a withdrawal so that the vault will no longer sell
    ///         another call once the currently active call option has expired.
    /// @param vaultId The tokenId of the vault to initiate a withdrawal on
    function initiateWithdraw(uint256 vaultId) external {
        // vaultId should always be odd
        require(vaultId % 2 != 0, "Not vault type");

        // check msg.sender owns the vault
        require(msg.sender == ownerOf(vaultId), "You are not the owner");

        // check vault is not already withdrawing
        require(!_vaults[vaultId].isWithdrawing, "Vault is already withdrawing");

        _vaults[vaultId].isWithdrawing = true;

        emit InitiatedWithdrawal(vaultId, msg.sender);
    }

    /// @notice Sends the underlying assets back to the vault owner and claims any
    ///         unharvested premiums for the owner. The vault NFT and it's associated
    ///         option NFT are burned.
    /// @param vaultId The tokenId of the vault to withdraw
    function withdraw(uint256 vaultId) external nonReentrant {
        // vaultId should always be odd
        require(vaultId % 2 != 0, "Not vault type");

        // check owner
        require(msg.sender == ownerOf(vaultId), "You are not the owner");

        Vault storage vault = _vaults[vaultId];

        // check vault can be withdrawn
        require(!vault.isExercised, "Vault already exercised");
        require(vault.isWithdrawing, "Vault not in withdrawable state");
        require(block.timestamp > vault.currentExpiration, "Option still active");

        // burn option and vault
        uint256 optionId = vaultId + 1;
        _burn(optionId);
        _burn(vaultId);

        emit Withdrawal(vaultId, msg.sender);

        // claim any ETH still in the account
        harvest();

        // transfer the NFTs or ERC20s back to the owner
        vault.tokenType == TokenType.ERC721
            ? ERC721(vault.token).safeTransferFrom(address(this), msg.sender, vault.tokenIdOrAmount)
            : ERC20(vault.token).safeTransfer(msg.sender, vault.tokenIdOrAmount);
    }

    /// @notice Sets the vault beneficiary that will receive premiums/strike ETH from the vault
    /// @param vaultId The tokenId of the vault to update
    /// @param beneficiary The new vault beneficiary
    function setVaultBeneficiary(uint256 vaultId, address beneficiary) external {
        // vaultIds should always be odd
        require(vaultId % 2 != 0, "Not vault type");
        require(msg.sender == ownerOf(vaultId), "Not owner");

        _vaultBeneficiaries[vaultId] = beneficiary;

        emit SetVaultBeneficiary(vaultId, msg.sender, beneficiary);
    }

    /// @notice Sends any unclaimed ETH (premiums/strike) to the msg.sender
    /// @return amount The amount of ETH that was harvested
    function harvest() public returns (uint256 amount) {
        // reset premiums
        amount = ethBalance[msg.sender];
        ethBalance[msg.sender] = 0;

        emit Harvested(msg.sender, amount);

        // transfer premiums to msg.sender
        payable(msg.sender).safeTransferETH(amount);
    }

    /**********************
        GETTER FUNCTIONS
    ***********************/

    /// @notice Get the current beneficiary for a vault
    /// @param vaultId The tokenId of the vault to fetch the beneficiary for
    /// @return beneficiary The beneficiary for the vault
    function getVaultBeneficiary(uint256 vaultId) public view returns (address beneficiary) {
        address currentBeneficiary = _vaultBeneficiaries[vaultId];

        // return the current owner if vault beneficiary is not set
        beneficiary = currentBeneficiary == address(0) ? ownerOf(vaultId) : currentBeneficiary;
    }

    /// @notice Get details for a vault
    /// @param vaultId The tokenId of the vault to fetch the details for
    /// @return vault The vault details for the vaultId
    function vaults(uint256 vaultId) external view returns (Vault memory) {
        return _vaults[vaultId];
    }

    /// @notice Get the current dutch auction strike for a starting strike, auction
    ///         end timestamp, and reserve strike. Strike decreases quadratically
    ///         to reserveStrike over time starting at startingStrike. Minimum
    ///         value returned is reserveStrike.
    /// @param startingStrike The starting strike value
    /// @param auctionEndTimestamp The unix timestamp when the auction ends
    /// @param reserveStrike The minimum value for the strike
    /// @return strike The strike
    function getDutchAuctionStrike(
        uint256 startingStrike,
        uint32 auctionEndTimestamp,
        uint256 reserveStrike
    ) public view returns (uint256 strike) {
        /*
            delta = max(auctionEnd - currentTimestamp, 0)
            progress = delta / auctionDuration
            strike = (progress^2 * (startingStrike - reserveStrike)) + reserveStrike
        */
        uint256 delta = auctionEndTimestamp > block.timestamp ? auctionEndTimestamp - block.timestamp : 0;
        uint256 progress = (1e18 * delta) / AUCTION_DURATION;
        strike = (((progress * progress * (startingStrike - reserveStrike)) / 1e18) / 1e18) + reserveStrike;
    }

    /*************************
        OVERRIDES FUNCTIONS
    **************************/

    /// @dev Resets the beneficiary address when transferring vault NFTs.
    ///      The new beneficiary will be the account receiving the vault NFT.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        require(from == _ownerOf[id], "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // reset the beneficiary
        bool isVaultToken = id % 2 != 0;
        if (isVaultToken) {
            _vaultBeneficiaries[id] = address(0);
        }

        _ownerOf[id] = to;
        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf[tokenId] != address(0), "URI query for NOT_MINTED token");

        bool isVaultToken = tokenId % 2 != 0;
        uint256 vaultId = isVaultToken ? tokenId : tokenId - 1;
        Vault memory vault = _vaults[vaultId];

        string memory jsonStr = renderJson(
            vault.token,
            vault.tokenIdOrAmount,
            premiumOptions[vault.premiumIndex],
            vault.durationDays,
            strikeOptions[vault.dutchAuctionStartingStrikeIndex],
            vault.currentExpiration,
            vault.currentStrike,
            vault.isExercised,
            isVaultToken
        );

        return string.concat("data:application/json;base64,", Base64.encode(bytes(jsonStr)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "solmate/tokens/ERC721.sol";
import "openzeppelin/utils/Strings.sol";
import "hot-chain-svg/SVG.sol";
import "base64/base64.sol";

// removes balanceOf modifications
// questionable tradeoff but given our use-case it's reasonable
// saves 20k gas when minting which about 30% gas on buys/vault creations
abstract contract CallyNft is ERC721("Cally", "CALL") {
    // remove balanceOf modifications
    function _mint(address to, uint256 id) internal override {
        require(to != address(0), "INVALID_RECIPIENT");
        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    // burns a token without checking owner address is not 0
    // and removes balanceOf modifications
    function _burn(uint256 id) internal override {
        address owner = _ownerOf[id];

        delete _ownerOf[id];
        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    // set balanceOf to max for all users
    function balanceOf(address owner) public pure override returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");
        return type(uint256).max;
    }

    // forceTransfer option position NFT out of owner's wallet and give to new buyer
    function _forceTransfer(address to, uint256 id) internal {
        require(to != address(0), "INVALID_RECIPIENT");

        address from = _ownerOf[id];
        _ownerOf[id] = to;
        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function renderJson(
        address token_,
        uint256 tokenIdOrAmount_,
        uint256 premium_,
        uint256 durationDays_,
        uint256 dutchAuctionStartingStrike_,
        uint256 currentExpiration_,
        uint256 currentStrike_,
        bool isExercised_,
        bool isVault_
    ) public pure returns (string memory) {
        string memory token = addressToString(token_);
        string memory tokenIdOrAmount = Strings.toString(tokenIdOrAmount_);
        string memory premium = Strings.toString(premium_);
        string memory durationDays = Strings.toString(durationDays_);
        string memory dutchAuctionStartingStrike = Strings.toString(dutchAuctionStartingStrike_);
        string memory currentExpiration = Strings.toString(currentExpiration_);
        string memory currentStrike = Strings.toString(currentStrike_);
        string memory isExercised = Strings.toString(isExercised_ ? 1 : 0);
        string memory nftType = isVault_ ? "Vault" : "Option";

        string memory svgStr = renderSvg(
            token,
            tokenIdOrAmount,
            premium,
            durationDays,
            dutchAuctionStartingStrike,
            currentExpiration,
            currentStrike,
            isExercised,
            nftType
        );

        string memory json = string.concat(
            /* solhint-disable quotes */
            '{"name":"',
            "Cally",
            '","description":"',
            "NFT and ERC20 covered call vaults",
            '","image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svgStr)),
            '","attributes": [',
            '{ "trait_type": "token",',
            '"value": "',
            token,
            '"},',
            '{ "trait_type": "tokenIdOrAmount",',
            '"value": "',
            tokenIdOrAmount,
            '"},',
            '{ "trait_type": "premium",',
            '"value": "',
            premium,
            '"},',
            '{ "trait_type": "durationDays",',
            '"value": "',
            durationDays,
            '"},',
            '{ "trait_type": "dutchAuctionStartingStrike",',
            '"value": "',
            dutchAuctionStartingStrike,
            '"},',
            '{ "trait_type": "currentExpiration",',
            '"value": "',
            currentExpiration,
            '"},',
            '{ "trait_type": "currentStrike",',
            '"value": "',
            currentStrike,
            '"},',
            '{ "trait_type": "isExercised",',
            '"value": "',
            isExercised,
            '"},',
            '{ "trait_type": "nftType",',
            '"value": "',
            nftType,
            '"}',
            "]}"
            /* solhint-enable quotes */
        );

        return json;
    }

    function renderSvg(
        string memory token,
        string memory tokenIdOrAmount,
        string memory premium,
        string memory durationDays,
        string memory dutchAuctionStartingStrike,
        string memory currentExpiration,
        string memory currentStrike,
        string memory isExercised,
        string memory nftType
    ) public pure returns (string memory) {
        return
            string.concat(
                // solhint-disable-next-line quotes
                '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" style="background:#000">',
                svg.text(
                    string.concat(
                        svg.prop("x", "10"),
                        svg.prop("y", "20"),
                        svg.prop("font-size", "12"),
                        svg.prop("fill", "white")
                    ),
                    string.concat(svg.cdata("Token: "), token)
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "10"),
                        svg.prop("y", "40"),
                        svg.prop("font-size", "12"),
                        svg.prop("fill", "white")
                    ),
                    string.concat(svg.cdata("Token ID or Amount: "), tokenIdOrAmount)
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "10"),
                        svg.prop("y", "60"),
                        svg.prop("font-size", "12"),
                        svg.prop("fill", "white")
                    ),
                    string.concat(svg.cdata("Premium (WEI): "), premium)
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "10"),
                        svg.prop("y", "80"),
                        svg.prop("font-size", "12"),
                        svg.prop("fill", "white")
                    ),
                    string.concat(svg.cdata("Duration (days): "), durationDays)
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "10"),
                        svg.prop("y", "100"),
                        svg.prop("font-size", "12"),
                        svg.prop("fill", "white")
                    ),
                    string.concat(svg.cdata("Starting strike (WEI): "), dutchAuctionStartingStrike)
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "10"),
                        svg.prop("y", "120"),
                        svg.prop("font-size", "12"),
                        svg.prop("fill", "white")
                    ),
                    string.concat(svg.cdata("Expiration (UNIX): "), currentExpiration)
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "10"),
                        svg.prop("y", "140"),
                        svg.prop("font-size", "12"),
                        svg.prop("fill", "white")
                    ),
                    string.concat(svg.cdata("Strike (WEI): "), currentStrike)
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "10"),
                        svg.prop("y", "160"),
                        svg.prop("font-size", "12"),
                        svg.prop("fill", "white")
                    ),
                    string.concat(svg.cdata("Exercised (y/n): "), isExercised)
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "10"),
                        svg.prop("y", "180"),
                        svg.prop("font-size", "12"),
                        svg.prop("fill", "white")
                    ),
                    string.concat(svg.cdata("Type: "), nftType)
                ),
                "</svg>"
            );
    }

    function addressToString(address account) public pure returns (string memory) {
        bytes memory data = abi.encodePacked(account);

        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }

        return string(str);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import './Utils.sol';

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('g', _props, _children);
    }

    function path(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('path', _props, _children);
    }

    function text(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('text', _props, _children);
    }

    function line(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('line', _props, _children);
    }

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props, _children);
    }

    function rect(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('filter', _props, _children);
    }

    function cdata(string memory _content)
        internal
        pure
        returns (string memory)
    {
        return string.concat('<![CDATA[', _content, ']]>');
    }

    /* GRADIENTS */
    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('radialGradient', _props, _children);
    }

    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('linearGradient', _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                'stop',
                string.concat(
                    prop('stop-color', stopColor),
                    ' ',
                    prop('offset', string.concat(utils.uint2str(offset), '%')),
                    ' ',
                    _props
                )
            );
    }

    function animateTransform(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('animateTransform', _props);
    }

    function image(string memory _href, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return
            el(
                'image',
                string.concat(prop('href', _href), ' ', _props)
            );
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '>',
                _children,
                '</',
                _tag,
                '>'
            );
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(
        string memory _tag,
        string memory _props
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '/>'
            );
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, '=', '"', _val, '" ');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = '';

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('--', _key, ':', _val, ';');
    }

    // formats getting a css variable
    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat('var(--', _key, ')');
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat('url(#', _id, ')');
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
    function rgba(
        uint256 _r,
        uint256 _g,
        uint256 _b,
        uint256 _a
    ) internal pure returns (string memory) {
        string memory formattedA = _a < 100
            ? string.concat('0.', utils.uint2str(_a))
            : '1';
        return
            string.concat(
                'rgba(',
                utils.uint2str(_r),
                ',',
                utils.uint2str(_g),
                ',',
                utils.uint2str(_b),
                ',',
                formattedA,
                ')'
            );
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}