// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

// PERSISTENCE ALONE IS OMNIPOTENT!

// S: CHIPAPIMONANO
// A: EMPATHETIC
// F: Pex-Pef
// E: ETHICAL

// ABOUT CREATIVERSE  https://nft.protoverse.ai
// CreatiVerse is a complete, “any-currency” NFT mintpad
// and management platform. It provides creators with sophisticated
// tools to mint, monetize, and fairly distribute NFTs.
// The platform also empowers users with automated
// peer-to-peer NFT scholarships and fixed rental escrows.

// ABOUT PROTOVERSE
// ProtoVerse fulfills projects’ wildest
// NFT and Play-To-Earn game development dreams.

// ProtoVerse’s dApps are custom-built in-house and
// certified by CertiK to ensure the utmost privacy, transparency, and security.
// They can be offered cost-effectively as whitelabel solutions to any qualified project.

// Website: ProtoVerse.ai

//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.,,,,,,,,,,,,,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@@##*.......,,,,,,,,,,,,,,,,,,,,,,*#@@@@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@..............,,,,,,,,,,,,,,,,,,,,,,,,,,,,#@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@%..............                   ..,,,,,,,,,,,,,#@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@(...........                               .,,,,,,,,,,,*@@@@@@@@@@@@
//    @@@@@@@@@&,.........                            ............,,,,,,,***%@@@@@@@@@
//    @@@@@@@@,........                      ........................,,,,*****@@@@@@@@
//    @@@@@@(........               ...................................,,******/@@@@@@
//    @@@@#.......           . .........................,/###(,,,,,,,,,,,,,******/@@@@
//    @@@%.......     .............*(#(*..............,(%%#/%%%(,,,,,,,,,,,*******(@@@
//    @@(....... ................*#%%%%%%*.......,,,,,#&&(,,,#&&#,,,,,,,,,*********,@@
//    @#.........................*%&&&&&%*.,,,,,,,,,,/&@%*,,,*%@@/,,,,,,,***********/@
//    @............................,*/*,,,,,,,,,,,,,,%&@/,,,,,(@@%,,,,,,,************%
//    ........................,(&@@@@&%*,,,,,,,,,,,/@@&,,,,,,,&@@*,,,,,,*************
//    .....................,%@@@@@@@@&@@&/,,,,,,,,,#@&%,,,,,,,#@@(,,,,,,*************
//    .....................&@@&(&@@@@@&&&@@@&*,,,,,,%@@(,,,,,,,(@@%,,,,,,*************
//    ...................*&@&&,,&@&@&@&/.,(&&@&%,,,,%@&(,,,,,,,(&@%,,,,,,*,***********
//    .....................*,../@@@@@@#,,,,,,,,,,,,,#@@#,,,,,,,#@@#,,,,,,*************
//    .........................*%&@@@%*,,,,,,,,,,,,(@&%,,,,,,,&@@(,,,,,,*************
//    @.......................*&&*,/&@&@&(,,,,,,,,,,*@@@*,,,,,/@@@*,,,,,,************#
//    @*......................%@@@&..,%&@@&*,,,,,,,,,#&@(,,,,,#@@#,,,,,,,************&
//    @#....................*&@@@%,...,#@@@%*,,,,,,,,*&@&*,,,*&@&*,,,,,,,***********/@
//    @@@................../&@@@%,.....,&@@@(,,,,,,,,,(&@&*,*&@&(,,,,,,,,***********@@
//    @@@&................#@@@&/.......,*&@@&,,,,,,,,,,*&@&&&@&*,,,,,,,,,*********(@@@
//    @@@@@................/#(.........,,*##*,,,,,,,,,,,,*(%#*,,,,,,,,,,,*,*****,@@@@@
//    @@@@@@%..........................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,******/@@@@@@
//    @@@@@@@@@........................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,****#@@@@@@@@
//    @@@@@@@@@@%......................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,**#@@@@@@@@@@
//    @@@@@@@@@@@@@,...................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@(................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@/,...........,,,,,,,,,,,,,,,,,,,,,,,,,,*@@@@@@@@@@@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@@@@@@%(......,,,,,,,,,,,,,,,,,,,,/#%@@@@@@@@@@@@@@@@@@@@@@@@

import "./AppType.sol";
import "./App.sol";
import "./Batch.sol";

/// @custom:security-contact [email protected]
contract CreatiVerse {
    using App for AppType.State;
    using BatchFactory for AppType.State;
    AppType.State internal state;

    constructor(
        address dao,
        address feeWallet,
        uint256 chainId
    ) {
        state.initialize(dao, feeWallet, chainId);
    }

    function safeMint(
        AppType.NFT calldata nft,
        AppType.Pass calldata pass,
        AppType.Proof calldata proof
    ) external payable {
        uint256 newTokenId = state.authorizeMint(nft, pass, proof);
        INFT(state.batches[nft.batchId].collection).safeMint(
            msg.sender,
            newTokenId,
            nft.uri
        );
    }

    function setTierSwapAmount(
        uint256 tierId,
        address[] calldata swapTokens,
        uint256[] calldata swapAmounts
    ) external {
        state.setTierSwapAmount(tierId, swapTokens, swapAmounts);
    }

    function getTierSwapAmount(uint256 tierId, address swapToken)
        external
        view
        returns (uint256)
    {
        return state.tierSwapAmounts[tierId][swapToken];
    }

    function changeConfig(
        AppType.IConfigKey calldata key,
        AppType.IConfigValue calldata value
    ) external {
        state.changeConfig(key, value);
    }

    function getConfig(
        AppType.AddressConfig addressConfig,
        AppType.UintConfig uintConfig,
        AppType.BoolConfig boolConfig,
        AppType.StringConfig stringConfig
    )
        external
        view
        returns (
            address addressValue,
            uint256 uintValue,
            bool boolValue,
            string memory stringValue
        )
    {
        return
            state.getConfig(
                addressConfig,
                uintConfig,
                boolConfig,
                stringConfig
            );
    }

    function createBatch(
        AppType.BatchKind kind,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    ) external {
        state.createBatch(kind, isOpenAt, disabled, root, collection);
    }

    function updateBatch(
        uint256 batchId,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    ) external {
        state.updateBatch(batchId, isOpenAt, disabled, root, collection);
    }

    function readBatch(uint256 batchId)
        external
        view
        returns (
            AppType.BatchKind kind,
            uint256 isOpenAt,
            bool disabled,
            bytes32 root
        )
    {
        return state.readBatch(batchId);
    }

    function excludeNFTLeaf(AppType.NFT calldata nft, bool isExcluded)
        external
    {
        state.excludeNFTLeaf(nft, isExcluded);
    }

    function excludePassLeaf(AppType.Pass calldata pass, bool isExcluded)
        external
    {
        state.excludePassLeaf(pass, isExcluded);
    }

    function name() public view returns (string memory) {
        return state.config.strings[AppType.StringConfig.APP_NAME];
    }

    function withdrawDAO(address token, uint256 amount) external {
        state.safeWithdraw(token, amount);
    }
}

interface INFT {
    function safeMint(
        address to,
        uint256 newTokenId,
        string calldata uri
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

library AppType {
    enum BatchKind {
        PASS,
        NFT
    }

    enum Model {
        BATCH
    }

    enum AddressConfig {
        NONE,
        DAO,
        FEE_WALLET
    }

    enum UintConfig {
        NONE,
        CHAIN_ID
    }

    enum BoolConfig {
        NONE,
        ALLOW_MINT_WITHOUT_PASS,
        PAUSED
    }

    enum StringConfig {
        NONE,
        APP_NAME
    }

    struct IConfigKey {
        AddressConfig addressK;
        UintConfig uintK;
        BoolConfig boolK;
        StringConfig stringK;
    }

    struct IConfigValue {
        address addressV;
        uint256 uintV;
        bool boolV;
        string stringV;
    }

    struct Config {
        mapping(AddressConfig => address) addresses;
        mapping(UintConfig => uint256) uints;
        mapping(BoolConfig => bool) bools;
        mapping(StringConfig => string) strings;
    }

    struct NFT {
        uint256 batchId;
        uint256 tierId;
        string uri;
        address swapToken;
        uint96 royaltyPercent;
    }

    struct Pass {
        uint256 batchId;
        uint256 balance;
    }

    struct Proof {
        bytes32[] pass;
        bytes32[] nft;
    }

    struct Batch {
        BatchKind kind;
        uint256 id;
        uint256 isOpenAt;
        bool disabled;
        bytes32 root;
        address collection;
    }

    struct State {
        mapping(Model => uint256) id;
        mapping(uint256 => Batch) batches;
        mapping(bytes32 => bool) excludedLeaves;
        mapping(bytes32 => uint256) usedLeaves;
        mapping(uint256 => mapping(address => uint256)) tierSwapAmounts;
        Config config;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./AppType.sol";

library App {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    event AppInitialized(uint256 chainId, string appName);
    event TierSwapAmountSet(
        uint256 tierId,
        address swapToken,
        uint256 swapAmount
    );
    event ConfigChanged(
        AppType.AddressConfig addressConfig,
        AppType.UintConfig uintConfig,
        AppType.BoolConfig boolConfig,
        AppType.StringConfig stringConfig,
        address addressValue,
        uint256 uintValue,
        bool boolValue,
        string stringValue
    );
    event WithdrawDAO(
        uint256 chainId,
        address token,
        uint256 amount,
        address account
    );

    function initialize(
        AppType.State storage state,
        address dao,
        address feeWallet,
        uint256 chainId
    ) public {
        state.config.addresses[AppType.AddressConfig.DAO] = dao;
        state.config.addresses[AppType.AddressConfig.FEE_WALLET] = feeWallet;
        state.config.uints[AppType.UintConfig.CHAIN_ID] = chainId;
        state.config.strings[AppType.StringConfig.APP_NAME] = "CreatiVerse";

        emit AppInitialized(
            state.config.uints[AppType.UintConfig.CHAIN_ID],
            state.config.strings[AppType.StringConfig.APP_NAME]
        );
    }

    function setTierSwapAmount(
        AppType.State storage state,
        uint256 tierId,
        address[] calldata swapTokens,
        uint256[] calldata swapAmounts
    ) external {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        for (uint256 i = 0; i < swapTokens.length; i++) {
            state.tierSwapAmounts[tierId][swapTokens[i]] = swapAmounts[i];
            emit TierSwapAmountSet(tierId, swapTokens[i], swapAmounts[i]);
        }
    }

    function changeConfig(
        AppType.State storage state,
        AppType.IConfigKey calldata key,
        AppType.IConfigValue calldata value
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        state.config.addresses[key.addressK] = value.addressV;
        state.config.uints[key.uintK] = value.uintV;
        state.config.bools[key.boolK] = value.boolV;
        state.config.strings[key.stringK] = value.stringV;
        emit ConfigChanged(
            key.addressK,
            key.uintK,
            key.boolK,
            key.stringK,
            value.addressV,
            value.uintV,
            value.boolV,
            value.stringV
        );
    }

    function getConfig(
        AppType.State storage state,
        AppType.AddressConfig addressConfig,
        AppType.UintConfig uintConfig,
        AppType.BoolConfig boolConfig,
        AppType.StringConfig stringConfig
    )
        public
        view
        returns (
            address addressValue,
            uint256 uintValue,
            bool boolValue,
            string memory stringValue
        )
    {
        return (
            state.config.addresses[addressConfig],
            state.config.uints[uintConfig],
            state.config.bools[boolConfig],
            state.config.strings[stringConfig]
        );
    }

    function safeWithdraw(
        AppType.State storage state,
        address token,
        uint256 amount
    ) external {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        if (token == address(0)) {
            payable(state.config.addresses[AppType.AddressConfig.FEE_WALLET])
                .transfer(amount);
        } else {
            IERC20Upgradeable(token).safeTransfer(
                state.config.addresses[AppType.AddressConfig.FEE_WALLET],
                amount
            );
        }

        emit WithdrawDAO(
            state.config.uints[AppType.UintConfig.CHAIN_ID],
            token,
            amount,
            state.config.addresses[AppType.AddressConfig.FEE_WALLET]
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AppType.sol";
import "./Utils.sol";

library BatchFactory {
    using LeafUtils for AppType.NFT;
    using LeafUtils for AppType.Pass;
    using MerkleProof for bytes32[];

    event BatchCreated(
        uint256 batchId,
        AppType.BatchKind kind,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    );
    event BatchUpdated(
        uint256 batchId,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    );
    event ExcludedLeaf(bytes32 leaf, uint256 batchId, bool isExcluded);
    event AuthorizedMint(
        uint256 nftBatchId,
        uint256 passBatchId,
        string nftUri,
        uint256 tierId,
        address swapToken,
        uint256 swapAmount,
        address account,
        uint256 newTokenId
    );

    function createBatch(
        AppType.State storage state,
        AppType.BatchKind kind,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );
        uint256 newBatchId = ++state.id[AppType.Model.BATCH];
        state.batches[newBatchId] = AppType.Batch({
            id: newBatchId,
            kind: kind,
            isOpenAt: isOpenAt,
            disabled: disabled,
            root: root,
            collection: collection
        });
        emit BatchCreated(
            newBatchId,
            kind,
            isOpenAt,
            disabled,
            root,
            collection
        );
    }

    function updateBatch(
        AppType.State storage state,
        uint256 batchId,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        require(state.batches[batchId].id == batchId, "E001");
        AppType.Batch storage batch = state.batches[batchId];
        batch.isOpenAt = isOpenAt;
        batch.disabled = disabled;
        batch.root = root;
        batch.collection = collection;
        emit BatchUpdated(batchId, isOpenAt, disabled, root, collection);
    }

    function readBatch(AppType.State storage state, uint256 batchId)
        public
        view
        returns (
            AppType.BatchKind kind,
            uint256 isOpenAt,
            bool disabled,
            bytes32 root
        )
    {
        require(state.batches[batchId].id == batchId, "E001");
        return (
            state.batches[batchId].kind,
            state.batches[batchId].isOpenAt,
            state.batches[batchId].disabled,
            state.batches[batchId].root
        );
    }

    function excludeNFTLeaf(
        AppType.State storage state,
        AppType.NFT memory nft,
        bool isExcluded
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        bytes32 leaf = nft.nftLeaf(state);
        state.excludedLeaves[leaf] = isExcluded;
        emit ExcludedLeaf(leaf, nft.batchId, isExcluded);
    }

    function excludePassLeaf(
        AppType.State storage state,
        AppType.Pass memory pass,
        bool isExcluded
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        bytes32 leaf = pass.passLeaf(state);
        state.excludedLeaves[leaf] = isExcluded;
        emit ExcludedLeaf(leaf, pass.batchId, isExcluded);
    }

    function authorizeMint(
        AppType.State storage state,
        AppType.NFT memory nft,
        AppType.Pass memory pass,
        AppType.Proof memory proof
    ) public returns (uint256 newTokenId) {
        require(!state.config.bools[AppType.BoolConfig.PAUSED], "E013");

        if (!state.config.bools[AppType.BoolConfig.ALLOW_MINT_WITHOUT_PASS]) {
            AppType.Batch storage passBatch = state.batches[pass.batchId];

            require(
                passBatch.id == pass.batchId &&
                    passBatch.kind == AppType.BatchKind.PASS &&
                    passBatch.isOpenAt <= block.timestamp &&
                    !passBatch.disabled,
                "E002"
            );

            bytes32 passLeaf = pass.passLeaf(state);
            require(state.usedLeaves[passLeaf] < pass.balance, "E003");

            require(proof.pass.verify(passBatch.root, passLeaf), "E004");
            require(state.excludedLeaves[passLeaf] == false, "E005");
            ++state.usedLeaves[passLeaf];
        }

        {
            AppType.Batch storage nftBatch = state.batches[nft.batchId];

            require(
                nftBatch.id == nft.batchId &&
                    nftBatch.kind == AppType.BatchKind.NFT &&
                    nftBatch.isOpenAt <= block.timestamp &&
                    !nftBatch.disabled,
                "E006"
            );

            bytes32 nftLeaf = nft.nftLeaf(state);
            require(state.usedLeaves[nftLeaf] == 0, "E007");
            require(proof.nft.verify(nftBatch.root, nftLeaf), "E008");
            require(state.excludedLeaves[nftLeaf] == false, "E009");
            ++state.usedLeaves[nftLeaf];
        }

        uint256 swapAmount = state.tierSwapAmounts[nft.tierId][nft.swapToken];

        {
            require(swapAmount > 0, "E010");

            if (nft.swapToken == address(0)) {
                require(msg.value >= swapAmount, "E011");
                payable(
                    state.config.addresses[AppType.AddressConfig.FEE_WALLET]
                ).transfer(swapAmount);
            } else {
                IERC20(nft.swapToken).transferFrom(
                    msg.sender,
                    state.config.addresses[AppType.AddressConfig.FEE_WALLET],
                    swapAmount
                );
            }
        }

        newTokenId = uint256(keccak256(abi.encode(nft.uri)));

        emit AuthorizedMint(
            nft.batchId,
            pass.batchId,
            nft.uri,
            nft.tierId,
            nft.swapToken,
            swapAmount,
            msg.sender,
            newTokenId
        );
    }
}

// Error Codes

// E001 - Batch not found
// E002 - Pass Batch not found
// E003 - Pass already used
// E004 - Pass not found
// E005 - Pass is excluded
// E006 - NFT Batch not found
// E007 - NFT already Minted
// E008 - NFT not found
// E009 - NFT is excluded
// E010 - swapAmount is 0
// E011 - Insufficient swap amount sent to mint
// E012 - Only DAO can perform this operation
// E013 - Minting is PAUSED

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "./AppType.sol";

library LeafUtils {
    function nftLeaf(AppType.NFT memory nft, AppType.State storage state)
        public
        view
        returns (bytes32 leaf)
    {
        leaf = keccak256(
            abi.encodePacked(
                nft.batchId,
                uint256(AppType.BatchKind.NFT),
                nft.uri,
                nft.royaltyPercent,
                nft.tierId,
                state.config.strings[AppType.StringConfig.APP_NAME],
                state.config.uints[AppType.UintConfig.CHAIN_ID]
            )
        );
        return leaf;
    }

    function passLeaf(AppType.Pass memory pass, AppType.State storage state)
        public
        view
        returns (bytes32 leaf)
    {
        leaf = keccak256(
            abi.encodePacked(
                pass.batchId,
                uint256(AppType.BatchKind.PASS),
                msg.sender,
                pass.balance,
                state.config.strings[AppType.StringConfig.APP_NAME],
                state.config.uints[AppType.UintConfig.CHAIN_ID]
            )
        );
        return leaf;
    }
}