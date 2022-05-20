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

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;
pragma abicoder v2;

import {IUnifarmNFTDescriptorUpgradeable} from './interfaces/IUnifarmNFTDescriptorUpgradeable.sol';
import {IUnifarmCohort} from './interfaces/IUnifarmCohort.sol';
import {NFTDescriptor} from './library/NFTDescriptor.sol';
import {IERC20TokenMetadata} from './interfaces/IERC20TokenMetadata.sol';
import {CheckPointReward} from './library/CheckPointReward.sol';
import {Initializable} from './proxy/Initializable.sol';
import {CohortHelper} from './library/CohortHelper.sol';
import {ConvertHexStrings} from './library/ConvertHexStrings.sol';

contract UnifarmNFTDescriptorUpgradeable is Initializable, IUnifarmNFTDescriptorUpgradeable {
    /// @notice registry contract address
    address public registry;

    /**
     * @notice construct a descriptor contract
     * @param registry_ registry address
     */

    function __UnifarmNFTDescriptorUpgradeable_init(address registry_) external initializer {
        __UnifarmNFTDescriptorUpgradeable_init_unchained(registry_);
    }

    /**
     * @dev internal function to set descriptor storage
     * @param registry_ registry address
     */

    function __UnifarmNFTDescriptorUpgradeable_init_unchained(address registry_) internal {
        registry = registry_;
    }

    /**
     * @dev get token ticker
     * @param farmToken farm token address
     * @return token ticker
     */

    function getTokenTicker(address farmToken) internal view returns (string memory) {
        return IERC20TokenMetadata(farmToken).symbol();
    }

    /**
     * @dev get Cohort details
     * @param cohortId cohort address
     * @param uStartBlock user start block
     * @param uEndBlock user End Block
     * @return cohortName cohort version
     * @return confirmedEpochs confirmed epochs
     */

    function getCohortDetails(
        address cohortId,
        uint256 uStartBlock,
        uint256 uEndBlock
    ) internal view returns (string memory cohortName, uint256 confirmedEpochs) {
        (string memory cohortVersion, , uint256 cEndBlock, uint256 epochBlocks, , , ) = CohortHelper.getCohort(registry, cohortId);
        cohortName = cohortVersion;
        confirmedEpochs = CheckPointReward.getCurrentCheckpoint(uStartBlock, (uEndBlock > 0 ? uEndBlock : cEndBlock), epochBlocks);
    }

    /**
     * @inheritdoc IUnifarmNFTDescriptorUpgradeable
     */

    function generateTokenURI(address cohortId, uint256 tokenId) public view override returns (string memory) {
        (uint32 fid, , uint256 stakedAmount, uint256 startBlock, uint256 sEndBlock, , , bool isBooster) = IUnifarmCohort(cohortId).viewStakingDetails(
            tokenId
        );

        (string memory cohortVersion, uint256 confirmedEpochs) = getCohortDetails(cohortId, startBlock, sEndBlock);

        (, address farmToken, , , , , ) = CohortHelper.getCohortToken(registry, cohortId, fid);

        return
            NFTDescriptor.createNftTokenURI(
                NFTDescriptor.DescriptionParam({
                    fid: fid,
                    cohortName: cohortVersion,
                    stakeTokenTicker: getTokenTicker(farmToken),
                    cohortAddress: ConvertHexStrings.addressToString(cohortId),
                    stakedBlock: startBlock,
                    tokenId: tokenId,
                    stakedAmount: stakedAmount,
                    confirmedEpochs: confirmedEpochs,
                    isBoosterAvailable: isBooster
                })
            );
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

abstract contract CohortFactory {
    /**
     * @notice factory owner
     * @return owner
     */
    function owner() public view virtual returns (address);

    /**
     * @notice derive storage contracts
     * @return registry contract address
     * @return nftManager contract address
     * @return rewardRegistry contract address
     */

    function getStorageContracts()
        public
        view
        virtual
        returns (
            address registry,
            address nftManager,
            address rewardRegistry
        );
}

// SPDX-License-Identifier: GNU GPLv3

// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

pragma solidity =0.8.9;

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
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: GNU GPLv3
pragma solidity =0.8.9;

interface IERC20TokenMetadata {
    /**
     * @dev returns name of the token
     * @return name - token name
     */
    function name() external view returns (string memory);

    /**
     * @dev returns symbol of the token
     * @return symbol - token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @dev returns decimals of the token
     * @return decimals - token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

/// @title IUnifarmCohort Interface
/// @author UNIFARM
/// @notice unifarm cohort external functions
/// @dev All function calls are currently implemented without any side effects

interface IUnifarmCohort {
    /**
    @notice stake handler
    @dev function called by only nft manager
    @param fid farm id where you want to stake
    @param tokenId NFT token Id
    @param account user wallet Address
    @param referralAddress referral address for this stake
   */

    function stake(
        uint32 fid,
        uint256 tokenId,
        address account,
        address referralAddress
    ) external;

    /**
     * @notice unStake handler
     * @dev called by nft manager only
     * @param user user wallet Address
     * @param tokenId NFT Token Id
     * @param flag 1, if owner is caller
     */

    function unStake(
        address user,
        uint256 tokenId,
        uint256 flag
    ) external;

    /**
     * @notice allow user to collect rewards before cohort end
     * @dev called by NFT manager
     * @param user user address
     * @param tokenId NFT Token Id
     */

    function collectPrematureRewards(address user, uint256 tokenId) external;

    /**
     * @notice purchase a booster pack for particular token Id
     * @dev called by NFT manager or owner
     * @param user user wallet address who is willing to buy booster
     * @param bpid booster pack id to purchase booster
     * @param tokenId NFT token Id which booster to take
     */

    function buyBooster(
        address user,
        uint256 bpid,
        uint256 tokenId
    ) external;

    /**
     * @notice set portion amount for particular tokenId
     * @dev called by only owner access
     * @param tokenId NFT token Id
     * @param stakedAmount new staked amount
     */

    function setPortionAmount(uint256 tokenId, uint256 stakedAmount) external;

    /**
     * @notice disable booster for particular tokenId
     * @dev called by only owner access.
     * @param tokenId NFT token Id
     */

    function disableBooster(uint256 tokenId) external;

    /**
     * @dev rescue Ethereum
     * @param withdrawableAddress to address
     * @param amount to withdraw
     * @return Transaction status
     */

    function safeWithdrawEth(address withdrawableAddress, uint256 amount) external returns (bool);

    /**
     * @dev rescue all available tokens in a cohort
     * @param tokens list of tokens
     * @param amounts list of amounts to withdraw respectively
     */

    function safeWithdrawAll(
        address withdrawableAddress,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    /**
     * @notice obtain staking details
     * @param tokenId - NFT Token id
     * @return fid the cohort farm id
     * @return nftTokenId the NFT token id
     * @return stakedAmount denotes staked amount
     * @return startBlock start block of particular user stake
     * @return endBlock end block of particular user stake
     * @return originalOwner wallet address
     * @return referralAddress the referral address of stake
     * @return isBooster denotes booster availability
     */

    function viewStakingDetails(uint256 tokenId)
        external
        view
        returns (
            uint32 fid,
            uint256 nftTokenId,
            uint256 stakedAmount,
            uint256 startBlock,
            uint256 endBlock,
            address originalOwner,
            address referralAddress,
            bool isBooster
        );

    /**
     * @notice emit on each booster purchase
     * @param nftTokenId NFT Token Id
     * @param user user wallet address who bought the booster
     * @param bpid booster pack id
     */

    event BoosterBuyHistory(uint256 indexed nftTokenId, address indexed user, uint256 bpid);

    /**
     * @notice emit on each claim
     * @param fid farm id.
     * @param tokenId NFT Token Id
     * @param userAddress NFT owner wallet address
     * @param referralAddress referral wallet address
     * @param rValue Aggregated R Value
     */

    event Claim(uint32 fid, uint256 indexed tokenId, address indexed userAddress, address indexed referralAddress, uint256 rValue);

    /**
     * @notice emit on each stake
     * @dev helps to derive referrals of unifarm cohort
     * @param tokenId NFT Token Id
     * @param referralAddress referral Wallet Address
     * @param stakedAmount user staked amount
     * @param fid farm id
     */

    event ReferedBy(uint256 indexed tokenId, address indexed referralAddress, uint256 stakedAmount, uint32 fid);
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;
pragma abicoder v2;

/// @title IUnifarmCohortRegistryUpgradeable Interface
/// @author UNIFARM
/// @notice All External functions of Unifarm Cohort Registry.

interface IUnifarmCohortRegistryUpgradeable {
    /**
     * @notice set tokenMetaData for a particular cohort farm
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param fid_ farm id
     * @param farmToken_ farm token address
     * @param userMinStake_ user minimum stake
     * @param userMaxStake_ user maximum stake
     * @param totalStakeLimit_ total stake limit
     * @param decimals_ token decimals
     * @param skip_ it can be skip or not during unstake
     */

    function setTokenMetaData(
        address cohortId,
        uint32 fid_,
        address farmToken_,
        uint256 userMinStake_,
        uint256 userMaxStake_,
        uint256 totalStakeLimit_,
        uint8 decimals_,
        bool skip_
    ) external;

    /**
     * @notice a function to set particular cohort details
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param cohortVersion_ cohort version
     * @param startBlock_ start block of a cohort
     * @param endBlock_ end block of a cohort
     * @param epochBlocks_ epochBlocks of a cohort
     * @param hasLiquidityMining_ true if lp tokens can be stake here
     * @param hasContainsWrappedToken_ true if wTokens exist in rewards
     * @param hasCohortLockinAvaliable_ cohort lockin flag
     */

    function setCohortDetails(
        address cohortId,
        string memory cohortVersion_,
        uint256 startBlock_,
        uint256 endBlock_,
        uint256 epochBlocks_,
        bool hasLiquidityMining_,
        bool hasContainsWrappedToken_,
        bool hasCohortLockinAvaliable_
    ) external;

    /**
     * @notice to add a booster pack in a particular cohort
     * @dev only called by owner access or multicall
     * @param cohortId_ cohort address
     * @param paymentToken_ payment token address
     * @param boosterVault_ booster vault address
     * @param bpid_ booster pack Id
     * @param boosterPackAmount_ booster pack amount
     */

    function addBoosterPackage(
        address cohortId_,
        address paymentToken_,
        address boosterVault_,
        uint256 bpid_,
        uint256 boosterPackAmount_
    ) external;

    /**
     * @notice update multicall contract address
     * @dev only called by owner access
     * @param newMultiCallAddress new multicall address
     */

    function updateMulticall(address newMultiCallAddress) external;

    /**
     * @notice lock particular cohort contract
     * @dev only called by owner access or multicall
     * @param cohortId cohort contract address
     * @param status true for lock vice-versa false for unlock
     */

    function setWholeCohortLock(address cohortId, bool status) external;

    /**
     * @notice lock particular cohort contract action. (`STAKE` | `UNSTAKE`)
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param actionToLock magic value STAKE/UNSTAKE
     * @param status true for lock vice-versa false for unlock
     */

    function setCohortLockStatus(
        address cohortId,
        bytes4 actionToLock,
        bool status
    ) external;

    /**
     * @notice lock the particular farm action (`STAKE` | `UNSTAKE`) in a cohort
     * @param cohortSalt mixture of cohortId and tokenId
     * @param actionToLock magic value STAKE/UNSTAKE
     * @param status true for lock vice-versa false for unlock
     */

    function setCohortTokenLockStatus(
        bytes32 cohortSalt,
        bytes4 actionToLock,
        bool status
    ) external;

    /**
     * @notice validate cohort stake locking status
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateStakeLock(address cohortId, uint32 farmId) external view;

    /**
     * @notice validate cohort unstake locking status
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateUnStakeLock(address cohortId, uint32 farmId) external view;

    /**
     * @notice get farm token details in a specific cohort
     * @param cohortId particular cohort address
     * @param farmId farmId of particular cohort
     * @return fid farm Id
     * @return farmToken farm Token Address
     * @return userMinStake amount that user can minimum stake
     * @return userMaxStake amount that user can maximum stake
     * @return totalStakeLimit total stake limit for the specific farm
     * @return decimals farm token decimals
     * @return skip it can be skip or not during unstake
     */

    function getCohortToken(address cohortId, uint32 farmId)
        external
        view
        returns (
            uint32 fid,
            address farmToken,
            uint256 userMinStake,
            uint256 userMaxStake,
            uint256 totalStakeLimit,
            uint8 decimals,
            bool skip
        );

    /**
     * @notice get specific cohort details
     * @param cohortId cohort address
     * @return cohortVersion specific cohort version
     * @return startBlock start block of a unifarm cohort
     * @return endBlock end block of a unifarm cohort
     * @return epochBlocks epoch blocks in particular cohort
     * @return hasLiquidityMining indicator for liquidity mining
     * @return hasContainsWrappedToken true if contains wrapped token in cohort rewards
     * @return hasCohortLockinAvaliable denotes cohort lockin
     */

    function getCohort(address cohortId)
        external
        view
        returns (
            string memory cohortVersion,
            uint256 startBlock,
            uint256 endBlock,
            uint256 epochBlocks,
            bool hasLiquidityMining,
            bool hasContainsWrappedToken,
            bool hasCohortLockinAvaliable
        );

    /**
     * @notice get booster pack details for a specific cohort
     * @param cohortId cohort address
     * @param bpid booster pack Id
     * @return cohortId_ cohort address
     * @return paymentToken_ payment token address
     * @return boosterVault booster vault address
     * @return boosterPackAmount booster pack amount
     */

    function getBoosterPackDetails(address cohortId, uint256 bpid)
        external
        view
        returns (
            address cohortId_,
            address paymentToken_,
            address boosterVault,
            uint256 boosterPackAmount
        );

    /**
     * @notice emit on each farm token update
     * @param cohortId cohort address
     * @param farmToken farm token address
     * @param fid farm Id
     * @param userMinStake amount that user can minimum stake
     * @param userMaxStake amount that user can maximum stake
     * @param totalStakeLimit total stake limit for the specific farm
     * @param decimals farm token decimals
     * @param skip it can be skip or not during unstake
     */

    event TokenMetaDataDetails(
        address indexed cohortId,
        address indexed farmToken,
        uint32 indexed fid,
        uint256 userMinStake,
        uint256 userMaxStake,
        uint256 totalStakeLimit,
        uint8 decimals,
        bool skip
    );

    /**
     * @notice emit on each update of cohort details
     * @param cohortId cohort address
     * @param cohortVersion specific cohort version
     * @param startBlock start block of a unifarm cohort
     * @param endBlock end block of a unifarm cohort
     * @param epochBlocks epoch blocks in particular unifarm cohort
     * @param hasLiquidityMining indicator for liquidity mining
     * @param hasContainsWrappedToken true if contains wrapped token in cohort rewards
     * @param hasCohortLockinAvaliable denotes cohort lockin
     */

    event AddedCohortDetails(
        address indexed cohortId,
        string indexed cohortVersion,
        uint256 startBlock,
        uint256 endBlock,
        uint256 epochBlocks,
        bool indexed hasLiquidityMining,
        bool hasContainsWrappedToken,
        bool hasCohortLockinAvaliable
    );

    /**
     * @notice emit on update of each booster pacakge
     * @param cohortId the cohort address
     * @param bpid booster pack id
     * @param paymentToken the payment token address
     * @param boosterPackAmount the booster pack amount
     */

    event BoosterDetails(address indexed cohortId, uint256 indexed bpid, address paymentToken, uint256 boosterPackAmount);
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;
pragma abicoder v2;

/// @title IUnifarmNFTDescriptorUpgradeable Interface
/// @author UNIFARM
/// @notice All External functions of Unifarm NFT Manager Descriptor

interface IUnifarmNFTDescriptorUpgradeable {
    /**
     * @notice construct the Token Metadata
     * @param cohortId cohort address
     * @param tokenId NFT Token Id
     * @return base64 encoded Token Metadata
     */
    function generateTokenURI(address cohortId, uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

interface IWETH {
    /**
     * @dev deposit eth to the contract
     */

    function deposit() external payable;

    /**
     * @dev transfer allows to transfer to a wallet or contract address
     * @param to recipient address
     * @param value amount to be transfered
     * @return Transfer status.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev allow to withdraw weth from contract
     */

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
// solhint-disable
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes internal constant TABLE_DECODE =
        hex'0000000000000000000000000000000000000000000000000000000000000000'
        hex'00000000000000000000003e0000003f3435363738393a3b3c3d000000000000'
        hex'00000102030405060708090a0b0c0d0e0f101112131415161718190000000000'
        hex'001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000';

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, 'IBDI');

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                        shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))
                    ),
                    add(shl(6, and(mload(add(tablePtr, and(shr(8, input), 0xFF))), 0xFF)), and(mload(add(tablePtr, and(input, 0xFF))), 0xFF))
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

/// @title CheckPointReward library
/// @author UNIFARM
/// @notice help to do a calculation of various checkpoints.
/// @dev all the functions are internally used in the protocol.

library CheckPointReward {
    /**
     * @dev help to find block difference
     * @param from from the blockNumber
     * @param to till the blockNumber
     * @return the blockDifference
     */

    function getBlockDifference(uint256 from, uint256 to) internal pure returns (uint256) {
        return to - from;
    }

    /**
     * @dev calculate number of checkpoint
     * @param from from blockNumber
     * @param to till blockNumber
     * @param epochBlocks epoch blocks length
     * @return checkpoint number of checkpoint
     */

    function getCheckpoint(
        uint256 from,
        uint256 to,
        uint256 epochBlocks
    ) internal pure returns (uint256) {
        uint256 blockDifference = getBlockDifference(from, to);
        return uint256(blockDifference / epochBlocks);
    }

    /**
     * @dev derive current check point in unifarm cohort
     * @dev it will be maximum to unifarm cohort endBlock
     * @param startBlock start block of a unifarm cohort
     * @param endBlock end block of a unifarm cohort
     * @param epochBlocks number of blocks in one epoch
     * @return checkpoint the current checkpoint in unifarm cohort
     */

    function getCurrentCheckpoint(
        uint256 startBlock,
        uint256 endBlock,
        uint256 epochBlocks
    ) internal view returns (uint256 checkpoint) {
        uint256 yfEndBlock = block.number;
        if (yfEndBlock > endBlock) {
            yfEndBlock = endBlock;
        }
        checkpoint = getCheckpoint(startBlock, yfEndBlock, epochBlocks);
    }

    /**
     * @dev derive start check point of user staking
     * @param startBlock start block
     * @param userStakedBlock block on user staked
     * @param epochBlocks number of block in epoch
     * @return checkpoint the start checkpoint of a user
     */

    function getStartCheckpoint(
        uint256 startBlock,
        uint256 userStakedBlock,
        uint256 epochBlocks
    ) internal pure returns (uint256 checkpoint) {
        checkpoint = getCheckpoint(startBlock, userStakedBlock, epochBlocks);
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import {CohortFactory} from '../abstract/CohortFactory.sol';
import {IERC20} from '../interfaces/IERC20.sol';
import {IUnifarmCohortRegistryUpgradeable} from '../interfaces/IUnifarmCohortRegistryUpgradeable.sol';
import {IWETH} from '../interfaces/IWETH.sol';

/// @title CohortHelper library
/// @author UNIFARM
/// @notice we have various util functions.which is used in protocol directly
/// @dev all the functions are internally used in the protocol.

library CohortHelper {
    /**
     * @dev getBlockNumber obtain current block from the chain.
     * @return current block number
     */

    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
     * @dev get current owner of the factory contract.
     * @param factory factory contract address.
     * @return factory owner address
     */

    function owner(address factory) internal view returns (address) {
        return CohortFactory(factory).owner();
    }

    /**
     * @dev validating the sender
     * @param factory factory contract address
     * @return registry registry contract address
     * @return nftManager nft Manager contract address
     * @return rewardRegistry reward registry contract address
     */

    function verifyCaller(address factory)
        internal
        view
        returns (
            address registry,
            address nftManager,
            address rewardRegistry
        )
    {
        (registry, nftManager, rewardRegistry) = getStorageContracts(factory);
        require(msg.sender == nftManager, 'ONM');
    }

    /**
     * @dev get cohort details
     * @param registry registry contract address
     * @param cohortId cohort contract address
     * @return cohortVersion specfic cohort version.
     * @return startBlock start block of a cohort.
     * @return endBlock end block of a cohort.
     * @return epochBlocks epoch blocks in particular cohort.
     * @return hasLiquidityMining indicator for liquidity mining.
     * @return hasContainsWrappedToken true if contains wrapped token in cohort rewards.
     * @return hasCohortLockinAvaliable denotes cohort lockin.
     */

    function getCohort(address registry, address cohortId)
        internal
        view
        returns (
            string memory cohortVersion,
            uint256 startBlock,
            uint256 endBlock,
            uint256 epochBlocks,
            bool hasLiquidityMining,
            bool hasContainsWrappedToken,
            bool hasCohortLockinAvaliable
        )
    {
        (
            cohortVersion,
            startBlock,
            endBlock,
            epochBlocks,
            hasLiquidityMining,
            hasContainsWrappedToken,
            hasCohortLockinAvaliable
        ) = IUnifarmCohortRegistryUpgradeable(registry).getCohort(cohortId);
    }

    /**
     * @dev obtain particular cohort farm token details
     * @param registry registry contract address
     * @param cohortId cohort contract address
     * @param farmId farm Id
     * @return fid farm Id
     * @return farmToken farm token Address
     * @return userMinStake amount that user can minimum stake
     * @return userMaxStake amount that user can maximum stake
     * @return totalStakeLimit total stake limit for the specfic farm
     * @return decimals farm token decimals
     * @return skip it can be skip or not during unstake
     */

    function getCohortToken(
        address registry,
        address cohortId,
        uint32 farmId
    )
        internal
        view
        returns (
            uint32 fid,
            address farmToken,
            uint256 userMinStake,
            uint256 userMaxStake,
            uint256 totalStakeLimit,
            uint8 decimals,
            bool skip
        )
    {
        (fid, farmToken, userMinStake, userMaxStake, totalStakeLimit, decimals, skip) = IUnifarmCohortRegistryUpgradeable(registry).getCohortToken(
            cohortId,
            farmId
        );
    }

    /**
     * @dev derive booster pack details available for a specfic cohort.
     * @param registry registry contract address
     * @param cohortId cohort contract Address
     * @param bpid booster pack id.
     * @return cohortId_ cohort address.
     * @return paymentToken_ payment token address.
     * @return boosterVault the booster vault address.
     * @return boosterPackAmount the booster pack amount.
     */

    function getBoosterPackDetails(
        address registry,
        address cohortId,
        uint256 bpid
    )
        internal
        view
        returns (
            address cohortId_,
            address paymentToken_,
            address boosterVault,
            uint256 boosterPackAmount
        )
    {
        (cohortId_, paymentToken_, boosterVault, boosterPackAmount) = IUnifarmCohortRegistryUpgradeable(registry).getBoosterPackDetails(
            cohortId,
            bpid
        );
    }

    /**
     * @dev calculate exact balance of a particular cohort.
     * @param token token address
     * @param totalStaking total staking of a token
     * @return cohortBalance current cohort balance
     */

    function getCohortBalance(address token, uint256 totalStaking) internal view returns (uint256 cohortBalance) {
        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        cohortBalance = contractBalance - totalStaking;
    }

    /**
     * @dev get all storage contracts from factory contract.
     * @param factory factory contract address
     * @return registry registry contract address
     * @return nftManager nftManger contract address
     * @return rewardRegistry reward registry address
     */

    function getStorageContracts(address factory)
        internal
        view
        returns (
            address registry,
            address nftManager,
            address rewardRegistry
        )
    {
        (registry, nftManager, rewardRegistry) = CohortFactory(factory).getStorageContracts();
    }

    /**
     * @dev handle deposit WETH
     * @param weth WETH address
     * @param amount deposit amount
     */

    function depositWETH(address weth, uint256 amount) internal {
        IWETH(weth).deposit{value: amount}();
    }

    /**
     * @dev validate stake lock status
     * @param registry registry address
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateStakeLock(
        address registry,
        address cohortId,
        uint32 farmId
    ) internal view {
        IUnifarmCohortRegistryUpgradeable(registry).validateStakeLock(cohortId, farmId);
    }

    /**
     * @dev validate unstake lock status
     * @param registry registry address
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateUnStakeLock(
        address registry,
        address cohortId,
        uint32 farmId
    ) internal view {
        IUnifarmCohortRegistryUpgradeable(registry).validateUnStakeLock(cohortId, farmId);
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

library ConvertHexStrings {
    /**
     * @dev Convert address to string
     * @param account - account hex address
     * @return string - hex string
     */
    function addressToString(address account) internal pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    /**
     * @dev convert bytes data to string
     * @param data - data is type of bytes
     * @return string - string of alphabet
     */

    function toString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = '0123456789abcdef';

        bytes memory str = new bytes(2 + data.length * 2);
        uint256 dataLength = data.length;
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < dataLength; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import {StringsUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';
import {Base64} from './Base64.sol';

/// @title NFTDescriptor library
/// @author UNIFARM
/// @notice create token metadata & onchain SVG

library NFTDescriptor {
    /// @notice for converting uint256 to string
    using StringsUpgradeable for uint256;

    /// @notice NFT Description Parameters
    struct DescriptionParam {
        // farm id
        uint32 fid;
        // cohort version
        string cohortName;
        // stake token ticker
        string stakeTokenTicker;
        // cohort address
        string cohortAddress;
        // owner staked  block
        uint256 stakedBlock;
        // nft token id
        uint256 tokenId;
        // owner stakedAmount
        uint256 stakedAmount;
        // owner confirmed epochs
        uint256 confirmedEpochs;
        // denotes booster availablity
        bool isBoosterAvailable;
    }

    /**
     * @dev construct the NFT name
     * @param cohortName cohort name
     * @param farmTicker farm token ticker
     * @return NFT name
     */

    function generateName(string memory cohortName, string memory farmTicker) internal pure returns (string memory) {
        return string(abi.encodePacked(farmTicker, ' ', '(', cohortName, ')'));
    }

    /**
     * @dev construct the first segment of description
     * @param tokenId farm token address
     * @param cohortName cohort name
     * @param stakeTokenTicker farm token ticker
     * @param cohortId cohort contract address
     * @return long description
     */

    function generateDescriptionSegment1(
        uint256 tokenId,
        string memory cohortName,
        string memory stakeTokenTicker,
        string memory cohortId
    ) internal pure returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    'This NFT denotes your staking on Unifarm. Owner of this nft can Burn or sell on any NFT marketplace. please check staking details below. \\n',
                    'Token Id :',
                    tokenId.toString(),
                    '\\n',
                    'Cohort Name :',
                    cohortName,
                    '\\n',
                    'Cohort Address :',
                    cohortId,
                    '\\n',
                    'Staked Token Ticker :',
                    stakeTokenTicker,
                    '\\n'
                )
            )
        );
    }

    /**
     * @dev construct second part of description
     * @param stakedAmount user staked amount
     * @param confirmedEpochs number of confirmed epochs
     * @param stakedBlock block on which user staked
     * @param isBoosterAvailable true, if user bought booster pack
     * @return long description
     */

    function generateDescriptionSegment2(
        uint256 stakedAmount,
        uint256 confirmedEpochs,
        uint256 stakedBlock,
        bool isBoosterAvailable
    ) internal pure returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    'Staked Amount :',
                    stakedAmount.toString(),
                    '\\n',
                    'Confirmed Epochs :',
                    confirmedEpochs.toString(),
                    '\\n',
                    'Staked Block :',
                    stakedBlock.toString(),
                    '\\n',
                    'Booster: ',
                    isBoosterAvailable ? 'Yes' : 'No'
                )
            )
        );
    }

    /**
     * @dev construct SVG with available information
     * @param svgParams it includes all the information of user staking
     * @return svg
     */

    function generateSVG(DescriptionParam memory svgParams) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg width="350" height="350" viewBox="0 0 350 350" fill="none" xmlns="http://www.w3.org/2000/svg">',
                    generateBoosterIndicator(svgParams.isBoosterAvailable),
                    generateRectanglesSVG(),
                    generateSVGTypography(svgParams),
                    generateSVGTypographyForRectangles(svgParams.tokenId, svgParams.stakedBlock, svgParams.confirmedEpochs),
                    '<text x="45" y="313" fill="#FFF" font-size=".75em" font-family="Arial, Helvetica, sans-serif">',
                    svgParams.stakedAmount.toString(),
                    '</text>',
                    generateSVGDefs()
                )
            );
    }

    /**
     * @dev generate svg rectangles
     * @return svg rectangles
     */

    function generateRectanglesSVG() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path d="M38 162a5 5 0 0 1 5-5h78a5 5 0 0 1 5 5v22a5 5 0 0 1-5 5H43a5 5 0 0 1-5-5v-22Zm0 38a5 5 0 0 1 5-5h147a5 5 0 0 1 5 5v22a5 5 0 0 1-5 5H43a5 5 0 0 1-5-5v-22Zm0 38a5 5 0 0 1 5-5h180a5 5 0 0 1 5 5v22a5 5 0 0 1-5 5H43a5 5 0 0 1-5-5v-22Zm0 42.969c0-4.401 2.239-7.969 5-7.969h210c2.761 0 5 3.568 5 7.969v35.062c0 4.401-2.239 7.969-5 7.969H43c-2.761 0-5-3.568-5-7.969v-35.062Z" fill="#293922" fill-opacity=".51"/>'
                )
            );
    }

    /**
     * @dev generate booster indicator
     * @param isBoosted true, if user bought the booster pack
     * @return booster indicator
     */

    function generateBoosterIndicator(bool isBoosted) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g clip-path="url(#a)">',
                    '<rect width="350" height="350" rx="37" fill="url(#b)"/>',
                    '<rect x="15.35" y="14.35" width="315.3" height="318.3" rx="29.65" stroke="#D6D6D6" stroke-opacity=".74" stroke-width=".7"/>',
                    generateRocketIcon(isBoosted),
                    '</g>'
                )
            );
    }

    /**
     * @dev generate rocket icon
     * @param isBoosted true, if user bought the booster pack
     * @return rocket icon
     */
    function generateRocketIcon(bool isBoosted) internal pure returns (string memory) {
        return
            isBoosted
                ? string(
                    abi.encodePacked(
                        '<path d="M49 75h62a5 5 0 0 1 5 5v12a5 5 0 0 1-5 5H49V75Z" fill="#C4C4C4"/>',
                        '<circle cx="49" cy="86" r="10.5" fill="#C4C4C4" stroke="#fff"/>',
                        '<path d="m43.832 90.407 4.284-4.284.758.757-4.285 4.284-.757-.757Z" fill="#fff"/>',
                        '<path d="M49.036 94a.536.536 0 0 1-.53-.46l-.536-3.75 1.072-.15.401 2.823 1.736-1.399v-4.028a.534.534 0 0 1 .155-.38l2.18-2.181a4.788 4.788 0 0 0 1.415-3.407v-.996h-.997a4.788 4.788 0 0 0-3.407 1.414l-2.18 2.18a.536.536 0 0 1-.38.156h-4.029l-1.398 1.746 2.823.402-.15 1.071-3.75-.536a.537.537 0 0 1-.342-.867l2.142-2.679a.536.536 0 0 1 .418-.209h4.066l2.02-2.025A5.85 5.85 0 0 1 53.932 79h.997A1.071 1.071 0 0 1 56 80.072v.996a5.853 5.853 0 0 1-1.725 4.168l-2.025 2.02v4.065a.537.537 0 0 1-.203.418l-2.679 2.143a.535.535 0 0 1-.332.118Z" fill="#fff"/>'
                    )
                )
                : '';
    }

    /**
     * @dev generate typography for NFTSVG with rectangle fields
     * @param tokenId NFT tokenId
     * @param stakedBlock user staked block
     * @param confirmedEpochs staking confirmed epochs
     * @return typography for NFTSVG
     */

    function generateSVGTypographyForRectangles(
        uint256 tokenId,
        uint256 stakedBlock,
        uint256 confirmedEpochs
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text x="45" y="177" fill="#FFF" font-size=".75em" font-family="Arial, Helvetica, sans-serif">'
                    'ID: ',
                    tokenId.toString(),
                    '</text>',
                    '<text x="45" y="216" fill="#FFF" font-size=".75em" font-family="Arial, Helvetica, sans-serif">',
                    'Staked block: ',
                    stakedBlock.toString(),
                    '</text>',
                    '<text x="45" y="254" fill="#FFF" font-size=".75em" font-family="Arial, Helvetica, sans-serif">',
                    'Confirmed epochs: ',
                    confirmedEpochs.toString(),
                    '</text>'
                    '<text x="45" y="292" fill="#FFF" font-size=".75em" font-family="Arial, Helvetica, sans-serif">',
                    'Staked Amount: ',
                    '</text>'
                )
            );
    }

    /**
     * @dev create typography for SVG header
     * @param params it includes all the information of user staking
     * @return typography for SVG header
     */

    function generateSVGTypography(DescriptionParam memory params) internal pure returns (string memory) {
        DescriptionParam memory svgParam = params;
        return
            string(
                abi.encodePacked(
                    '<text x="36" y="65" fill="#fff" font-size="1em" font-family="Arial, Helvetica, sans-serif">',
                    generateName(svgParam.cohortName, svgParam.stakeTokenTicker),
                    '</text>',
                    generateBoostedLabelText(svgParam.isBoosterAvailable),
                    '<text x="40" y="127" fill="#FFF" font-size=".75em" font-family="Arial, Helvetica, sans-serif">',
                    '<tspan x="40" dy="0">Cohort Address:</tspan>',
                    '<tspan x="40" dy="1.2em">',
                    svgParam.cohortAddress,
                    '</tspan>',
                    '</text>'
                )
            );
    }

    /**
     * @dev create boosted label text for NFT SVG
     * @param isBoosted true, if user bought the booster pack
     * @return boosted label text
     */

    function generateBoostedLabelText(bool isBoosted) internal pure returns (string memory) {
        return
            isBoosted
                ? string(
                    abi.encodePacked(
                        '<text x="64" y="90" fill="#fff" font-size=".75em" font-family="Arial, Helvetica, sans-serif">',
                        'Boosted',
                        '</text>'
                    )
                )
                : '';
    }

    /**
     * @dev create defs for NFT SVG
     * @return defs
     */
    function generateSVGDefs() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<defs>',
                    '<linearGradient id="b" x1="44.977" y1="326.188" x2="113.79" y2="-21.919" gradientUnits="userSpaceOnUse">',
                    '<stop stop-color="#730AAC"/>',
                    '<stop offset=".739" stop-color="#A2164A"/>',
                    '</linearGradient>',
                    '<clipPath id="a">',
                    '<rect width="350" height="350" rx="37" fill="#fff"/>',
                    '</clipPath>',
                    '</defs>',
                    '</svg>'
                )
            );
    }

    /**
     * @dev create NFT Token URI
     * @param descriptionParam it includes all the information of user staking
     * @return NFT Token URI
     */

    function createNftTokenURI(DescriptionParam memory descriptionParam) internal pure returns (string memory) {
        string memory name = generateName(descriptionParam.cohortName, descriptionParam.stakeTokenTicker);
        string memory description = string(
            abi.encodePacked(
                generateDescriptionSegment1(
                    descriptionParam.tokenId,
                    descriptionParam.cohortName,
                    descriptionParam.stakeTokenTicker,
                    descriptionParam.cohortAddress
                ),
                generateDescriptionSegment2(
                    descriptionParam.stakedAmount,
                    descriptionParam.confirmedEpochs,
                    descriptionParam.stakedBlock,
                    descriptionParam.isBoosterAvailable
                )
            )
        );
        string memory svg = Base64.encode(bytes(generateSVG(descriptionParam)));
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    string(
                        Base64.encode(
                            bytes(
                                abi.encodePacked(
                                    '{',
                                    '"name":',
                                    '"',
                                    name,
                                    '"',
                                    ',',
                                    '"description":',
                                    '"',
                                    description,
                                    '"',
                                    ',',
                                    '"image":',
                                    '"data:image/svg+xml;base64,',
                                    svg,
                                    '"',
                                    '}'
                                )
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity =0.8.9;

import '../utils/AddressUpgradeable.sol';

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
 * Avoid leaving a contract uninitialized
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
     * @dev Indicates that the contract has been initialized
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered
        require(_initializing ? _isConstructor() : !_initialized, 'CIAI');

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
     * {initializer} modifier, directly or indirectly
     */
    modifier onlyInitializing() {
        require(_initializing, 'CINI');
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity =0.8.9;

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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        require(isContract(target), 'Address: call to non-contract');

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
        return functionStaticCall(target, data, 'Address: low-level static call failed');
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
        require(isContract(target), 'Address: static call to non-contract');

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