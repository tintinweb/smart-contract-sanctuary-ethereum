/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: BUSL-1.1

/*
Business Source License 1.1

License text copyright © 2017 MariaDB Corporation Ab, All Rights Reserved.
"Business Source License" is a trademark of MariaDB Corporation Ab.

Terms

The Licensor hereby grants you the right to copy, modify, create derivative
works, redistribute, and make non-production use of the Licensed Work. The
Licensor may make an Additional Use Grant, above, permitting limited
production use.

Effective on the Change Date, or the fourth anniversary of the first publicly
available distribution of a specific version of the Licensed Work under this
License, whichever comes first, the Licensor hereby grants you rights under
the terms of the Change License, and the rights granted in the paragraph
above terminate.

If your use of the Licensed Work does not comply with the requirements
currently in effect as described in this License, you must purchase a
commercial license from the Licensor, its affiliated entities, or authorized
resellers, or you must refrain from using the Licensed Work.

All copies of the original and modified Licensed Work, and derivative works
of the Licensed Work, are subject to this License. This License applies
separately for each version of the Licensed Work and the Change Date may vary
for each version of the Licensed Work released by Licensor.

You must conspicuously display this License on each original or modified copy
of the Licensed Work. If you receive the Licensed Work in original or
modified form from a third party, the terms and conditions set forth in this
License apply to your use of that work.

Any use of the Licensed Work in violation of this License will automatically
terminate your rights under this License for the current and all other
versions of the Licensed Work.

This License does not grant you any right in any trademark or logo of
Licensor or its affiliates (provided that you may use a trademark or logo of
Licensor as expressly required by this License).

TO THE EXTENT PERMITTED BY APPLICABLE LAW, THE LICENSED WORK IS PROVIDED ON
AN “AS IS” BASIS. LICENSOR HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS,
EXPRESS OR IMPLIED, INCLUDING (WITHOUT LIMITATION) WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, AND
TITLE.

MariaDB hereby grants you permission to use this License’s text to license
your works, and to refer to it using the trademark “Business Source License”,
as long as you comply with the Covenants of Licensor below.

Covenants of Licensor

In consideration of the right to use this License’s text and the “Business
Source License” name and trademark, Licensor covenants to MariaDB, and to all
other recipients of the licensed work to be provided by Licensor:

1. To specify as the Change License the GPL Version 2.0 or any later version,
   or a license that is compatible with GPL Version 2.0 or a later version,
   where “compatible” means that software provided under the Change License can
   be included in a program with software provided under GPL Version 2.0 or a
   later version. Licensor may specify additional Change Licenses without
   limitation.

2. To either: (a) specify an additional grant of rights to use that does not
   impose any additional restriction on the right granted in this License, as
   the Additional Use Grant; or (b) insert the text “None”.

3. To specify a Change Date.

4. Not to modify this License in any other way.
*/

pragma solidity ^0.8.12;
interface ICerbyTokenMinterBurner {
    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);
    function totalSupply()
        external
        view
        returns (uint256);
    function mintHumanAddress(
        address _to,
        uint256 _desiredAmountToMint
    )
        external;
    function burnHumanAddress(
        address _from,
        uint256 _desiredAmountToBurn
    )
        external;
    function transferCustom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external;
    function getUtilsContractAtPos(
        uint256 pos
    )
        external
        view
        returns (address);
}
pragma solidity ^0.8.10;
struct TransactionInfo {
    bool isBuy;
    bool isSell;
}
interface ICerbyBotDetection {
    function checkTransactionInfo(
        address _tokenAddr,
        address _sender,
        address _recipient,
        uint256 _recipientBalance,
        uint256 _transferAmount
    )
        external
        returns (TransactionInfo memory output);
    function isBotAddress(
        address _addr
    )
        external
        view
        returns (bool);
    function executeCronJobs()
        external;
    function detectBotTransaction(
        address _tokenAddr,
        address _addr
    )
        external
        returns (bool);
    function registerTransaction(
        address _tokenAddr,
        address _addr
    )
        external;
}
pragma solidity ^0.8.12;
struct AccessSettings {
    bool isMinter;
    bool isBurner;
    bool isTransferer;
    bool isModerator;
    bool isTaxer;
    address addr;
}
interface ICerbyToken {
    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256);
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);
    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);
    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool success);
    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);
    function totalSupply()
        external
        view
        returns (uint256);
    function mintHumanAddress(
        address _to,
        uint256 _desiredAmountToMint
    )
        external;
    function burnHumanAddress(
        address _from,
        uint256 _desiredAmountToBurn
    )
        external;
    function mintByBridge(
        address _to,
        uint256 _realAmountToMint
    )
        external;
    function burnByBridge(
        address _from,
        uint256 _realAmountBurn
    )
        external;
    function getUtilsContractAtPos(
        uint256 _pos
    )
        external
        view
        returns (address);
    function updateUtilsContracts(
        AccessSettings[] calldata accessSettings
    )
        external;
    function transferCustom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external;
}
pragma solidity ^0.8.12;
abstract contract CerbyCronJobsExecution {
    uint256 constant CERBY_BOT_DETECTION_CONTRACT_ID = 3;
    ICerbyToken constant CERBY_TOKEN_INSTANCE = ICerbyToken(
        0xdef1fac7Bf08f173D286BbBDcBeeADe695129840
    );
    error CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();
    modifier detectBotTransactionThenRegisterTransactionAndExecuteCronJobsAfter(
        address _tokenIn,
        address _from,
        address _tokenOut,
        address _to
    ) {
        ICerbyBotDetection iCerbyBotDetection = ICerbyBotDetection(
            getUtilsContractAtPos(
                CERBY_BOT_DETECTION_CONTRACT_ID
            )
        );
        if (iCerbyBotDetection.detectBotTransaction(_tokenIn, _from)) {
            revert CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();
        }
        iCerbyBotDetection.registerTransaction(
            _tokenOut,
            _to
        );
        _;
        iCerbyBotDetection.executeCronJobs();
    }
    modifier checkForBotsAndExecuteCronJobsAfter(
        address _from
    ) {
        ICerbyBotDetection iCerbyBotDetection = ICerbyBotDetection(
            getUtilsContractAtPos(
                CERBY_BOT_DETECTION_CONTRACT_ID
            )
        );
        if (iCerbyBotDetection.isBotAddress(_from)) {
            revert CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();
        }
        _;
        iCerbyBotDetection.executeCronJobs();
    }
    function getUtilsContractAtPos(
        uint256 _pos
    )
        public
        view
        virtual
        returns (address)
    {
        return CERBY_TOKEN_INSTANCE.getUtilsContractAtPos(_pos);
    }
}
pragma solidity ^0.8.0;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
pragma solidity ^0.8.0;
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}
pragma solidity ^0.8.0;
interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
pragma solidity ^0.8.0;
interface IERC1155 is IERC165 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);
}
pragma solidity ^0.8.12;
abstract contract ERC1155 {
    mapping(uint256 => mapping(address => uint256)) erc1155Balances;
    mapping(address => mapping(address => bool)) erc1155OperatorApprovals;
    mapping(uint256 => uint256) erc1155TotalSupply;
    address constant BURN_ADDRESS = address(0);
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );
    event ApprovalForAll(
        address indexed _account,
        address indexed _operator,
        bool _approved
    );
    error ERC1155_CallerIsNotOwnerNorApproved();
    error ERC1155_IdsLengthMismatch();
    error ERC1155_InsufficientBalanceForTransfer();
    error ERC1155_BurnAmountExceedsBalance();
    error ERC1155_ERC1155ReceiverRejectsTokens();
    error ERC1155_TransferToNonERC1155ReceiverImplementer();
    modifier addressIsApproved(address _addr) {
        if (_addr == msg.sender && isApprovedForAll(_addr, msg.sender)) {
            revert ERC1155_CallerIsNotOwnerNorApproved();
        }
        _;
    }
    modifier idsLengthMismatch(
        uint256 _idsLength,
        uint256 _accountsLength
    ) {
        if (_idsLength != _accountsLength) {
            revert ERC1155_IdsLengthMismatch();
        }
        _;
    }
    function balanceOf(
        address _account,
        uint256 _id
    )
        public
        view
        returns (uint256)
    {
        return erc1155Balances[_id][_account];
    }
    function isApprovedForAll(
        address _account,
        address _operator
    )
        public
        view
        returns (bool)
    {
        return erc1155OperatorApprovals[_account][_operator];
    }
    function balanceOfBatch(
        address[] calldata _accounts,
        uint256[] calldata _ids
    )
        external
        view
        idsLengthMismatch(_ids.length, _accounts.length)
        returns (uint256[] memory)
    {
        uint256[] memory batchBalances = new uint256[](_accounts.length);
        for (uint256 i = 0; i < _ids.length; ++i) {
            batchBalances[i] = balanceOf(_accounts[i], _ids[i]);
        }
        return batchBalances;
    }
    function totalSupply(uint256 _id)
        external
        view
        returns (uint256)
    {
        return erc1155TotalSupply[_id];
    }
    function exists(uint256 _id)
        external
        view
        returns (bool)
    {
        return erc1155TotalSupply[_id] > 0;
    }
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    )
        internal
    {
        address operator = msg.sender;
        uint256 fromBalance = erc1155Balances[_id][_from];
        if (fromBalance < _amount) {
            revert ERC1155_InsufficientBalanceForTransfer();
        }
        unchecked {
            erc1155Balances[_id][_from] = fromBalance - _amount;
            erc1155Balances[_id][_to] += _amount;
        }
        emit TransferSingle(
            operator,
            _from,
            _to,
            _id,
            _amount
        );
        _doSafeTransferAcceptanceCheck(operator, _from, _to, _id, _amount, "");
    }
    function _mint(
        address _to,
        uint256 _id,
        uint256 _amount
    )
        internal
    {
        if (_amount == 0) {
            return;
        }
        address operator = msg.sender;
        erc1155TotalSupply[_id] += _amount;
        unchecked {
            erc1155Balances[_id][_to] += _amount;
        }
        emit TransferSingle(operator, BURN_ADDRESS, _to, _id, _amount);
        _doSafeTransferAcceptanceCheck(
            operator,
            BURN_ADDRESS,
            _to,
            _id,
            _amount,
            ""
        );
    }
    function _burn(
        address _from,
        uint256 _id,
        uint256 _amount
    )
        internal
    {
        address operator = msg.sender;
        uint256 fromBalance = erc1155Balances[_id][_from];
        if (fromBalance < _amount) {
            revert ERC1155_BurnAmountExceedsBalance();
        }
        unchecked {
            erc1155Balances[_id][_from] = fromBalance - _amount;
            erc1155TotalSupply[_id] -= _amount;
        }
        emit TransferSingle(operator, _from, BURN_ADDRESS, _id, _amount);
    }
    function _setApprovalForAll(
        address _owner,
        address _operator,
        bool _approved
    )
        internal
    {
        erc1155OperatorApprovals[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }
    function _doSafeTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    )
        private
    {
        if (isContract(_to)) {
            try
                IERC1155Receiver(_to).onERC1155Received(
                    _operator,
                    _from,
                    _id,
                    _amount,
                    _data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert ERC1155_ERC1155ReceiverRejectsTokens();
                }
            } catch {
                revert ERC1155_TransferToNonERC1155ReceiverImplementer();
            }
        }
    }
    function isContract(address _account)
        private
        view
        returns (bool)
    {
        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        return size > 0;
    }
}
pragma solidity ^0.8.12;
abstract contract CerbySwapV1_ERC1155 is ERC1155, CerbyCronJobsExecution {
    string contractName = "CerbySwapV1";
    string contractSymbol = "CS1";
    string urlPrefix = "https://data.cerby.fi/CerbySwap/v1/";
    function name()
        external
        view
        returns (string memory)
    {
        return contractName;
    }
    function symbol()
        external
        view
        returns (string memory)
    {
        return contractSymbol;
    }
    function decimals()
        external
        pure
        returns (uint256)
    {
        return 18;
    }
    function totalSupply()
        external
        view
        returns (uint256)
    {
        uint256 i;
        uint256 totalSupplyAmount;
        while (erc1155TotalSupply[++i] > 0) {
            totalSupplyAmount += erc1155TotalSupply[i];
        }
        return totalSupplyAmount;
    }
    function uri(
        uint256 _id
    )
        external
        view
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                urlPrefix,
                _uint2str(_id), ".json"
            )
        );
    }
    function setApprovalForAll(
        address _operator,
        bool _approved
    )
        external
        checkForBotsAndExecuteCronJobsAfter(msg.sender)
    {
        _setApprovalForAll(
            msg.sender,
            _operator,
            _approved
        );
    }
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata
    )
        external
        checkForBotsAndExecuteCronJobsAfter(_from)
        addressIsApproved(_from)
    {
        _safeTransferFrom(
            _from,
            _to,
            _id,
            _amount
        );
    }
    function _uint2str(
        uint256 _i
    )
        private
        pure
        returns (string memory str)
    {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }
}
pragma solidity ^0.8.12;
abstract contract CerbySwapV1_Math {
    function sqrt(
        uint256 _y
    )
        internal
        pure
        returns (uint256 z)
    {
        if (_y > 3) {
            z = _y;
            uint256 x = _y / 2 + 1;
            while (x < z) {
                z = x;
                x = (_y / x + x) / 2;
            }
        } else if (_y != 0) {
            z = 1;
        }
    }
}
pragma solidity ^0.8.12;
interface ICerbySwapV1_Vault {
    function initialize(
        address _token
    )
        external;
    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);
    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool success);
    function withdrawEth(
        address _to,
        uint256 _value
    )
        external;
    function withdrawTokens(
        address _token,
        address _to,
        uint256 _value
    )
        external;
}
pragma solidity ^0.8.12;
interface IBasicERC20 {
    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);
    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool success);
}
pragma solidity ^0.8.12;
abstract contract CerbySwapV1_EventsAndErrors {
    event PoolCreated(
        address _token,
        address _vaultAddress,
        uint256 _poolId
    );
    event LiquidityAdded(
        address _token,
        uint256 _amountTokensIn,
        uint256 _amountCerUsdToMint,
        uint256 _lpAmount
    );
    event LiquidityRemoved(
        address _token,
        uint256 _amountTokensOut,
        uint256 _amountCerUsdToBurn,
        uint256 _amountLpTokensBalanceToBurn
    );
    event Swap(
        address _token,
        address _sender,
        uint256 _amountTokensIn,
        uint256 _amountCerUsdIn,
        uint256 _amountTokensOut,
        uint256 _amountCerUsdOut,
        uint256 _currentFee,
        address _transferTo
    );
    event Sync(
        address _token,
        uint256 _newBalanceToken,
        uint256 _newBalanceCerUsd,
        uint256 _newCreditCerUsd
    );
    error CerbySwapV1_TokenAlreadyExists();
    error CerbySwapV1_TokenDoesNotExist();
    error CerbySwapV1_TransactionIsExpired();
    error CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
    error CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
    error CerbySwapV1_OutputCerUsdAmountIsLowerThanMinimumSpecified();
    error CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
    error CerbySwapV1_InputCerUsdAmountIsLargerThanMaximumSpecified();
    error CerbySwapV1_InputTokensAmountIsLargerThanMaximumSpecified();
    error CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
    error CerbySwapV1_InvariantKValueMustBeSameOrIncreasedOnAnySwaps();
    error CerbySwapV1_SafeTransferNativeFailed();
    error CerbySwapV1_SafeTransferFromFailed();
    error CerbySwapV1_AmountOfCerUsdOrTokensInMustBeLargerThanOne();
    error CerbySwapV1_FeeIsWrong();
    error CerbySwapV1_TvlMultiplierIsWrong();
    error CerbySwapV1_MintFeeMultiplierMustNotBeLargerThan50Percent();
    error CerbySwapV1_CreditCerUsdMustNotBeBelowZero();
    error CerbySwapV1_CreditCerUsdIsAlreadyMaximum();
}
pragma solidity ^0.8.12;
abstract contract CerbySwapV1_Declarations is CerbySwapV1_EventsAndErrors {
    Pool[] pools;
    mapping(address => TokenCache) cachedTokenValues;
    uint256 constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 constant BSC_MAINNET_CHAIN_ID = 56;
    uint256 constant POLYGON_MAINNET_CHAIN_ID = 137;
    uint256 constant AVALANCHE_MAINNET_CHAIN_ID = 43114;
    uint256 constant FANTOM_MAINNET_CHAIN_ID = 250;
    address constant CER_USD_TOKEN = 0x333333f9E4ba7303f1ac0BF8fE1F47d582629194;
    address constant VAULT_IMPLEMENTATION = 0xc0DE7771A6F7029d62E8071e331B36136534D70D;
    address NATIVE_TOKEN;
    uint256 constant MINT_FEE_DENORM = 10000;
    uint256 constant MAX_CER_USD_CREDIT = type(uint128).max;
    uint256 constant FEE_DENORM = 10000;
    uint256 constant FEE_DENORM_SQUARED = FEE_DENORM * FEE_DENORM;
    uint256 constant TRADE_VOLUME_DENORM = 1e18;
    uint256 constant TVL_MULTIPLIER_DENORM = 1e10;
    uint256 constant NUMBER_OF_TRADE_PERIODS = 6;
    uint256 constant NUMBER_OF_TRADE_PERIODS_MINUS_ONE = NUMBER_OF_TRADE_PERIODS - 1;
    uint256 constant ONE_PERIOD_IN_SECONDS = 288 minutes;
    uint256 constant MINIMUM_LIQUIDITY = 1000;
    address constant DEAD_ADDRESS = address(0xdead);
    Settings settings;
    struct TokenCache {
        address vaultAddress;
        uint96 poolId;
    }
    struct Settings {
        address mintFeeBeneficiary;
        uint32 mintFeeMultiplier;
        uint8 feeMinimum;
        uint8 feeMaximum;
        uint64 tvlMultiplierMinimum;
        uint64 tvlMultiplierMaximum;
    }
    struct Pool {
        uint40[NUMBER_OF_TRADE_PERIODS] tradeVolumePerPeriodInCerUsd;
        uint8 lastCachedFee;
        uint8 lastCachedTradePeriod;
        uint128 lastSqrtKValue;
        uint128 creditCerUsd;
    }
    struct PoolBalances {
        uint256 balanceToken;
        uint256 balanceCerUsd;
    }
}
pragma solidity ^0.8.12;
contract CerbySwapV1_MinimalProxy is CerbySwapV1_Declarations {
    function cloneVault(
        address _token
    )
        internal
        returns (address)
    {
        bytes32 salt = _getSaltByToken(_token);
        bytes20 vaultImplementationBytes = bytes20(
            VAULT_IMPLEMENTATION
        );
        address resultVaultAddress;
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), vaultImplementationBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            resultVaultAddress := create2(
                0,
                clone,
                0x37,
                salt
            )
        }
        return resultVaultAddress;
    }
    function _getCachedVaultCloneAddressByToken(
        address _token
    )
        internal
        returns(address)
    {
        address vault = cachedTokenValues[_token].vaultAddress;
        if (vault == address(0)) {
            vault = _generateVaultAddressByToken(
                _token
            );
            cachedTokenValues[_token].vaultAddress = vault;
        }
        return vault;
    }
    function _generateVaultAddressByToken(
        address _token
    )
        internal
        view
        returns (address)
    {
        bytes32 salt = _getSaltByToken(_token);
        address factory = address(this);
        address vaultCloneAddress;
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, VAULT_IMPLEMENTATION))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, factory))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            vaultCloneAddress := keccak256(add(ptr, 0x37), 0x55)
        }
        return vaultCloneAddress;
    }
    function _getSaltByToken(
        address _token
    )
        internal
        view
        returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _token,
                address(this)
            )
        );
    }
}
pragma solidity ^0.8.12;
abstract contract CerbySwapV1_SafeFunctions is
    CerbySwapV1_EventsAndErrors,
    CerbySwapV1_MinimalProxy
{
    function _getPoolBalances(
        address _token
    )
        internal
        view
        returns (PoolBalances memory)
    {
        address vault = cachedTokenValues[_token].vaultAddress == address(0)
            ? _generateVaultAddressByToken(_token)
            : cachedTokenValues[_token].vaultAddress;
        return PoolBalances(
            _getTokenBalance(_token, vault),
            _getTokenBalance(CER_USD_TOKEN, vault)
        );
    }
    function _getTokenBalance(
        address _token,
        address _vault
    )
        internal
        view
        returns (uint256)
    {
        return _token == NATIVE_TOKEN
            ? _vault.balance
            : IBasicERC20(_token).balanceOf(_vault);
    }
    function _safeTransferFromHelper(
        address _token,
        address _from,
        address _to,
        uint256 _amountTokens
    )
        internal
    {
        if (_from == msg.sender) {
            if (_token != NATIVE_TOKEN) {
                _safeCoreTransferFrom(
                    _token,
                    _from,
                    _to,
                    _amountTokens
                );
                return;
            }
            uint256 nativeBalance = address(this).balance;
            if (nativeBalance > _amountTokens) {
                _safeCoreTransferNative(
                    msg.sender,
                    nativeBalance - _amountTokens
                );
            }
            _safeCoreTransferNative(
                _to,
                _amountTokens
            );
            return;
        }
        if (_token != NATIVE_TOKEN) {
            ICerbySwapV1_Vault(_from).withdrawTokens(
                _token,
                _to,
                _amountTokens
            );
            return;
        }
        ICerbySwapV1_Vault(_from).withdrawEth(
            _to,
            _amountTokens
        );
    }
    function _safeCoreTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                0x23b872dd,
                _from,
                _to,
                _value
            )
        );
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert CerbySwapV1_SafeTransferFromFailed();
        }
    }
    function _safeCoreTransferNative(
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        if (!success) {
            revert CerbySwapV1_SafeTransferNativeFailed();
        }
    }
}
pragma solidity ^0.8.12;
abstract contract CerbySwapV1_Modifiers is CerbySwapV1_Declarations {
    modifier tokenMustExistInPool(
        address _token
    ) {
        if (cachedTokenValues[_token].poolId == 0 || _token == CER_USD_TOKEN) {
            revert CerbySwapV1_TokenDoesNotExist();
        }
        _;
    }
    modifier transactionIsNotExpired(
        uint256 _expireTimestamp
    ) {
        if (block.timestamp > _expireTimestamp) {
            revert CerbySwapV1_TransactionIsExpired();
        }
        _;
    }
}
pragma solidity ^0.8.12;
abstract contract CerbySwapV1_GetFunctions is
    CerbySwapV1_Modifiers,
    CerbySwapV1_SafeFunctions
{
    function getTokenToPoolId(
        address _token
    )
        external
        view
        returns (uint256)
    {
        return cachedTokenValues[_token].poolId;
    }
    function getSettings()
        external
        view
        returns (Settings memory)
    {
        return settings;
    }
    function getPoolsByTokens(
        address[] calldata _tokens
    )
        external
        view
        returns (Pool[] memory)
    {
        Pool[] memory outputPools = new Pool[](_tokens.length);
        for (uint256 i; i < _tokens.length; i++) {
            address token = _tokens[i];
            outputPools[i] = pools[cachedTokenValues[token].poolId];
        }
        return outputPools;
    }
    function getPoolsBalancesByTokens(
        address[] calldata _tokens
    )
        external
        view
        returns (PoolBalances[] memory)
    {
        PoolBalances[] memory outputPools = new PoolBalances[](_tokens.length);
        for (uint256 i; i < _tokens.length; i++) {
            address token = _tokens[i];
            outputPools[i] = _getPoolBalances(token);
        }
        return outputPools;
    }
    function getCurrentFeeBasedOnTrades(
        address _token
    )
        external
        view
        returns (uint256 fee)
    {
        Pool storage pool = pools[cachedTokenValues[_token].poolId];
        PoolBalances memory poolBalances = _getPoolBalances(
            _token
        );
        return _getCurrentFeeBasedOnTrades(
            pool,
            poolBalances
        );
    }
    function getOutputExactTokensForTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountTokensIn
    )
        external
        view
        returns (uint256)
    {
        if (_tokenOut == CER_USD_TOKEN) {
            return _getOutputExactTokensForCerUsd(
                _getPoolBalances(_tokenIn),
                _tokenIn,
                _amountTokensIn
            );
        }
        if (_tokenIn == CER_USD_TOKEN) {
            return _getOutputExactCerUsdForTokens(
                _getPoolBalances(_tokenOut),
                _amountTokensIn
            );
        }
        uint256 amountCerUsdOut = _getOutputExactTokensForCerUsd(
            _getPoolBalances(_tokenIn),
            _tokenIn,
            _amountTokensIn
        );
        return _getOutputExactCerUsdForTokens(
            _getPoolBalances(_tokenOut),
            amountCerUsdOut
        );
    }
    function getInputTokensForExactTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountTokensOut
    )
        external
        view
        returns (uint256)
    {
        if (_tokenOut == CER_USD_TOKEN) {
            return _getInputTokensForExactCerUsd(
                _getPoolBalances(_tokenIn),
                _tokenIn,
                _amountTokensOut
            );
        }
        if (_tokenIn == CER_USD_TOKEN) {
            return _getInputCerUsdForExactTokens(
                _getPoolBalances(_tokenOut),
                _amountTokensOut
            );
        }
        uint256 amountCerUsdOut = _getInputCerUsdForExactTokens(
            _getPoolBalances(_tokenOut),
            _amountTokensOut
        );
        return _getInputTokensForExactCerUsd(
            _getPoolBalances(_tokenIn),
            _tokenIn,
            amountCerUsdOut
        );
    }
    function _getCurrentPeriod()
        internal
        view
        returns (uint256)
    {
        return block.timestamp
            / ONE_PERIOD_IN_SECONDS
            % NUMBER_OF_TRADE_PERIODS;
    }
    function _getCurrentFeeBasedOnTrades(
        Pool storage _pool,
        PoolBalances memory _poolBalances
    )
        internal
        view
        returns (uint256)
    {
        uint256 currentPeriod = _getCurrentPeriod();
        uint256 volume;
        for (uint256 i; i < NUMBER_OF_TRADE_PERIODS; i++) {
            if (i == currentPeriod) continue;
            volume += _pool.tradeVolumePerPeriodInCerUsd[i];
        }
        volume = (volume - NUMBER_OF_TRADE_PERIODS_MINUS_ONE) * TRADE_VOLUME_DENORM;
        uint256 tvlMin = _poolBalances.balanceCerUsd
            * uint256(settings.tvlMultiplierMinimum)
            / TVL_MULTIPLIER_DENORM;
        uint256 tvlMax = _poolBalances.balanceCerUsd
            * uint256(settings.tvlMultiplierMaximum)
            / TVL_MULTIPLIER_DENORM;
        if (volume <= tvlMin) {
            return uint256(settings.feeMaximum);
        }
        if (volume >= tvlMax) {
            return uint256(settings.feeMinimum);
        }
        return uint256(settings.feeMaximum)
            - (uint256(settings.feeMaximum) - uint256(settings.feeMinimum))
            * (volume - tvlMin)
            / (tvlMax - tvlMin);
    }
    function _getOutputExactTokensForCerUsd(
        PoolBalances memory poolBalances,
        address _token,
        uint256 _amountTokensIn
    )
        internal
        view
        returns (uint256)
    {
        Pool storage pool = pools[cachedTokenValues[_token].poolId];
        return _getOutput(
            _amountTokensIn,
            uint256(poolBalances.balanceToken),
            uint256(poolBalances.balanceCerUsd),
            _getCurrentFeeBasedOnTrades(
                pool,
                poolBalances
            )
        );
    }
    function _getOutputExactCerUsdForTokens(
        PoolBalances memory poolBalances,
        uint256 _amountCerUsdIn
    )
        internal
        pure
        returns (uint256)
    {
        return _getOutput(
            _amountCerUsdIn,
            uint256(poolBalances.balanceCerUsd),
            uint256(poolBalances.balanceToken),
            0
        );
    }
    function _getOutput(
        uint256 _amountIn,
        uint256 _reservesIn,
        uint256 _reservesOut,
        uint256 _fee
    )
        internal
        pure
        returns (uint256)
    {
        uint256 amountInWithFee = _amountIn
            * (FEE_DENORM - _fee);
        return amountInWithFee
            * _reservesOut
            / (_reservesIn * FEE_DENORM + amountInWithFee);
    }
    function _getInputTokensForExactCerUsd(
        PoolBalances memory poolBalances,
        address _token,
        uint256 _amountCerUsdOut
    )
        internal
        view
        returns (uint256)
    {
        Pool storage pool = pools[cachedTokenValues[_token].poolId];
        return _getInput(
            _amountCerUsdOut,
            uint256(poolBalances.balanceToken),
            uint256(poolBalances.balanceCerUsd),
            _getCurrentFeeBasedOnTrades(
                pool,
                poolBalances
            )
        );
    }
    function _getInputCerUsdForExactTokens(
        PoolBalances memory poolBalances,
        uint256 _amountTokensOut
    )
        internal
        pure
        returns (uint256)
    {
        return _getInput(
            _amountTokensOut,
            uint256(poolBalances.balanceCerUsd),
            uint256(poolBalances.balanceToken),
            0
        );
    }
    function _getInput(
        uint256 _amountOut,
        uint256 _reservesIn,
        uint256 _reservesOut,
        uint256 _fee
    )
        internal
        pure
        returns (uint256)
    {
        return _reservesIn
            * _amountOut
            * FEE_DENORM
            / (FEE_DENORM - _fee)
            / (_reservesOut - _amountOut)
            + 1;
    }
}
pragma solidity ^0.8.12;
abstract contract CerbySwapV1_LiquidityFunctions is
    CerbySwapV1_Modifiers,
    CerbySwapV1_Math,
    CerbySwapV1_ERC1155,
    CerbySwapV1_GetFunctions
{
    function increaseCerUsdCreditInPool(
        address _token,
        uint256 _amountCerUsdCredit
    )
        external
    {
        Pool storage pool = pools[cachedTokenValues[_token].poolId];
        if (pool.creditCerUsd == MAX_CER_USD_CREDIT) {
            revert CerbySwapV1_CreditCerUsdIsAlreadyMaximum();
        }
        pool.creditCerUsd += uint128(
            _amountCerUsdCredit
        );
        ICerbyTokenMinterBurner(CER_USD_TOKEN).burnHumanAddress(
            msg.sender,
            _amountCerUsdCredit
        );
        PoolBalances memory poolBalances = _getPoolBalances(
            _token
        );
        emit Sync(
            _token,
            poolBalances.balanceToken,
            poolBalances.balanceCerUsd,
            pool.creditCerUsd
        );
    }
    function createPool(
        address _token,
        uint256 _amountTokensIn,
        uint256 _amountCerUsdToMint,
        address _transferTo
    )
        external
        payable
        detectBotTransactionThenRegisterTransactionAndExecuteCronJobsAfter(_token, msg.sender, _token, _transferTo)
    {
        _createPool(
            _token,
            _amountTokensIn,
            _amountCerUsdToMint,
            0,
            _transferTo
        );
    }
    function _createPool(
        address _token,
        uint256 _amountTokensIn,
        uint256 _amountCerUsdToMint,
        uint256 _creditCerUsd,
        address _transferTo
    )
        internal
    {
        if (cachedTokenValues[_token].poolId > 0) {
            revert CerbySwapV1_TokenAlreadyExists();
        }
        address vaultAddress = cloneVault(
            _token
        );
        ICerbySwapV1_Vault(vaultAddress).initialize(
            _token
        );
        _safeTransferFromHelper(
            _token,
            msg.sender,
            vaultAddress,
            _amountTokensIn
        );
        ICerbyTokenMinterBurner(CER_USD_TOKEN).mintHumanAddress(
            vaultAddress,
            _amountCerUsdToMint
        );
        _amountTokensIn = _getTokenBalance(
            _token,
            vaultAddress
        );
        if (_amountTokensIn <= 1) {
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }
        uint40[NUMBER_OF_TRADE_PERIODS] memory tradeVolumePerPeriodInCerUsd;
        for (uint256 i; i < NUMBER_OF_TRADE_PERIODS; i++) {
            tradeVolumePerPeriodInCerUsd[i] = 1;
        }
        uint256 newSqrtKValue = sqrt(
            _amountTokensIn * _amountCerUsdToMint
        );
        Pool memory pool = Pool({
            tradeVolumePerPeriodInCerUsd: tradeVolumePerPeriodInCerUsd,
            lastCachedFee: uint8(settings.feeMaximum),
            lastCachedTradePeriod: uint8(_getCurrentPeriod()),
            lastSqrtKValue: uint128(newSqrtKValue),
            creditCerUsd: uint128(_creditCerUsd)
        });
        uint256 poolId = pools.length;
        pools.push(pool);
        cachedTokenValues[_token].poolId = uint96(poolId);
        _mint(
            DEAD_ADDRESS,
            poolId,
            MINIMUM_LIQUIDITY
        );
        uint256 lpAmount = newSqrtKValue
            - MINIMUM_LIQUIDITY;
        _mint(
            _transferTo,
            poolId,
            lpAmount
        );
        emit PoolCreated(
            _token,
            vaultAddress,
            poolId
        );
        emit LiquidityAdded(
            _token,
            _amountTokensIn,
            _amountCerUsdToMint,
            lpAmount
        );
        emit Sync(
            _token,
            _amountTokensIn,
            _amountCerUsdToMint,
            _creditCerUsd
        );
    }
    function addTokenLiquidity(
        address _token,
        uint256 _amountTokensIn,
        uint256 _expireTimestamp,
        address _transferTo
    )
        external
        payable
        detectBotTransactionThenRegisterTransactionAndExecuteCronJobsAfter(_token, msg.sender, _token, _transferTo)
        tokenMustExistInPool(_token)
        transactionIsNotExpired(_expireTimestamp)
        returns (uint256)
    {
        return _addTokenLiquidity(
            _token,
            _amountTokensIn,
            _transferTo
        );
    }
    function _addTokenLiquidity(
        address _token,
        uint256 _amountTokensIn,
        address _transferTo
    )
        private
        returns (uint256)
    {
        uint256 poolId = cachedTokenValues[_token].poolId;
        Pool storage pool = pools[poolId];
        address vaultInAddress = _getCachedVaultCloneAddressByToken(
            _token
        );
        PoolBalances memory poolBalancesBefore = _getPoolBalances(
            _token
        );
        _safeTransferFromHelper(
            _token,
            msg.sender,
            vaultInAddress,
            _amountTokensIn
        );
        uint256 tokenBalanceAfter = _getTokenBalance(
            _token,
            vaultInAddress
        );
        _amountTokensIn = tokenBalanceAfter
            - poolBalancesBefore.balanceToken;
        if (_amountTokensIn <= 1) {
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }
        uint256 amountLpTokensToMintAsFee = _getMintFeeLiquidityAmount(
            uint256(pool.lastSqrtKValue),
            sqrt(poolBalancesBefore.balanceToken * poolBalancesBefore.balanceCerUsd),
            erc1155TotalSupply[poolId]
        );
        _mint(
            settings.mintFeeBeneficiary,
            poolId,
            amountLpTokensToMintAsFee
        );
        uint256 amountCerUsdToMint = _amountTokensIn
            * poolBalancesBefore.balanceCerUsd
            / poolBalancesBefore.balanceToken;
        if (amountCerUsdToMint <= 1) {
            revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
        }
        pool.lastSqrtKValue = uint128(
            sqrt(
                tokenBalanceAfter
                * (poolBalancesBefore.balanceCerUsd + amountCerUsdToMint)
            )
        );
        ICerbyTokenMinterBurner(CER_USD_TOKEN).mintHumanAddress(
            vaultInAddress,
            amountCerUsdToMint
        );
        uint256 lpAmount = _amountTokensIn
            * erc1155TotalSupply[poolId]
            / poolBalancesBefore.balanceToken;
        _mint(
            _transferTo,
            poolId,
            lpAmount
        );
        emit LiquidityAdded(
            _token,
            _amountTokensIn,
            amountCerUsdToMint,
            lpAmount
        );
        emit Sync(
            _token,
            tokenBalanceAfter,
            poolBalancesBefore.balanceCerUsd + amountCerUsdToMint,
            pool.creditCerUsd
        );
        return lpAmount;
    }
    function removeTokenLiquidity(
        address _token,
        uint256 _amountLpTokensBalanceToBurn,
        uint256 _expireTimestamp,
        address _transferTo
    )
        external
        detectBotTransactionThenRegisterTransactionAndExecuteCronJobsAfter(_token, msg.sender, _token, _transferTo)
        tokenMustExistInPool(_token)
        transactionIsNotExpired(_expireTimestamp)
        returns (uint256)
    {
        return _removeTokenLiquidity(
            _token,
            _amountLpTokensBalanceToBurn,
            _transferTo
        );
    }
    function _removeTokenLiquidity(
        address _token,
        uint256 _amountLpTokensBalanceToBurn,
        address _transferTo
    )
        private
        returns (uint256)
    {
        uint256 poolId = cachedTokenValues[_token].poolId;
        Pool storage pool = pools[poolId];
        PoolBalances memory poolBalancesBefore = _getPoolBalances(
            _token
        );
        uint256 amountLpTokensToMintAsFee = _getMintFeeLiquidityAmount(
            uint256(pool.lastSqrtKValue),
            sqrt(poolBalancesBefore.balanceToken * poolBalancesBefore.balanceCerUsd),
            erc1155TotalSupply[poolId]
        );
        _mint(
            settings.mintFeeBeneficiary,
            poolId,
            amountLpTokensToMintAsFee
        );
        uint256 amountTokensOut = poolBalancesBefore.balanceToken
            * _amountLpTokensBalanceToBurn
            / erc1155TotalSupply[poolId];
        uint256 amountCerUsdToBurn = poolBalancesBefore.balanceCerUsd
            * _amountLpTokensBalanceToBurn
            / erc1155TotalSupply[poolId];
        PoolBalances memory poolBalancesAfter = PoolBalances(
            poolBalancesBefore.balanceToken - amountTokensOut,
            poolBalancesBefore.balanceCerUsd - amountCerUsdToBurn
        );
        pool.lastSqrtKValue = uint128(
            sqrt(poolBalancesAfter.balanceToken * poolBalancesAfter.balanceCerUsd)
        );
        _burn(
            msg.sender,
            poolId,
            _amountLpTokensBalanceToBurn
        );
        address vaultOutAddress = _getCachedVaultCloneAddressByToken(
            _token
        );
        ICerbyTokenMinterBurner(CER_USD_TOKEN).burnHumanAddress(
            vaultOutAddress,
            amountCerUsdToBurn
        );
        _safeTransferFromHelper(
            _token,
            vaultOutAddress,
            _transferTo,
            amountTokensOut
        );
        emit LiquidityRemoved(
            _token,
            amountTokensOut,
            amountCerUsdToBurn,
            _amountLpTokensBalanceToBurn
        );
        emit Sync(
            _token,
            poolBalancesAfter.balanceToken,
            poolBalancesAfter.balanceCerUsd,
            pool.creditCerUsd
        );
        return amountTokensOut;
    }
    function _getMintFeeLiquidityAmount(
        uint256 _oldSqrtKValue,
        uint256 _newSqrtKValue,
        uint256 _totalLPSupply
    )
        private
        view
        returns (uint256)
    {
        uint256 mintFeePercentage = uint256(
            settings.mintFeeMultiplier
        );
        if (
            mintFeePercentage == 0 ||
            _newSqrtKValue <= _oldSqrtKValue
        ) {
            return 0;
        }
        return _totalLPSupply
            * mintFeePercentage
            * (_newSqrtKValue - _oldSqrtKValue)
            / (
                _newSqrtKValue
                * (MINT_FEE_DENORM - mintFeePercentage)
                    + _oldSqrtKValue * mintFeePercentage
            );
    }
}
pragma solidity ^0.8.12;
abstract contract CerbySwapV1_SwapFunctions is CerbySwapV1_LiquidityFunctions {
    function swapExactTokensForTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountTokensIn,
        uint256 _minAmountTokensOut,
        uint256 _expireTimestamp,
        address _transferTo
    )
        external
        payable
        detectBotTransactionThenRegisterTransactionAndExecuteCronJobsAfter(_tokenIn, msg.sender, _tokenOut, _transferTo)
        transactionIsNotExpired(_expireTimestamp)
        returns (uint256[] memory)
    {
        return _swapExactTokensForTokens(
            _tokenIn,
            _tokenOut,
            _amountTokensIn,
            _minAmountTokensOut,
            _transferTo
        );
    }
    function _swapExactTokensForTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountTokensIn,
        uint256 _minAmountTokensOut,
        address _transferTo
    )
        private
        returns (uint256[] memory)
    {
        if (_tokenIn == _tokenOut) {
            revert CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
        }
        address vaultAddressIn = _getCachedVaultCloneAddressByToken(
            _tokenIn
        );
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _amountTokensIn;
        PoolBalances memory poolInBalancesBefore;
        if (_tokenOut == CER_USD_TOKEN) {
            poolInBalancesBefore = _getPoolBalances(
                _tokenIn
            );
            amounts[1] = _getOutputExactTokensForCerUsd(
                poolInBalancesBefore,
                _tokenIn,
                _amountTokensIn
            );
            if (amounts[1] < _minAmountTokensOut) {
                revert CerbySwapV1_OutputCerUsdAmountIsLowerThanMinimumSpecified();
            }
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                vaultAddressIn,
                _amountTokensIn
            );
            _swap(
                _tokenIn,
                poolInBalancesBefore,
                0,
                amounts[1],
                _transferTo
            );
            return amounts;
        }
        address vaultAddressOut = _getCachedVaultCloneAddressByToken(
            _tokenOut
        );
        PoolBalances memory poolOutBalancesBefore;
        if (_tokenIn == CER_USD_TOKEN) {
            poolOutBalancesBefore = _getPoolBalances(
                _tokenOut
            );
            amounts[1] = _getOutputExactCerUsdForTokens(
                poolOutBalancesBefore,
                _amountTokensIn
            );
            if (amounts[1] < _minAmountTokensOut) {
                revert CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
            }
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                vaultAddressOut,
                _amountTokensIn
            );
            _swap(
                _tokenOut,
                poolOutBalancesBefore,
                amounts[1],
                0,
                _transferTo
            );
            return amounts;
        }
        poolInBalancesBefore = _getPoolBalances(
            _tokenIn
        );
        uint256 amountCerUsdOut = _getOutputExactTokensForCerUsd(
            poolInBalancesBefore,
            _tokenIn,
            _amountTokensIn
        );
        poolOutBalancesBefore = _getPoolBalances(
            _tokenOut
        );
        amounts[1] = _getOutputExactCerUsdForTokens(
            poolOutBalancesBefore,
            amountCerUsdOut
        );
        if (amounts[1] < _minAmountTokensOut) {
            revert CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
        }
        _safeTransferFromHelper(
            _tokenIn,
            msg.sender,
            vaultAddressIn,
            _amountTokensIn
        );
        _swap(
            _tokenIn,
            poolInBalancesBefore,
            0,
            amountCerUsdOut,
            vaultAddressOut
        );
        _swap(
            _tokenOut,
            poolOutBalancesBefore,
            amounts[1],
            0,
            _transferTo
        );
        return amounts;
    }
    function swapTokensForExactTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountTokensOut,
        uint256 _maxAmountTokensIn,
        uint256 _expireTimestamp,
        address _transferTo
    )
        external
        payable
        detectBotTransactionThenRegisterTransactionAndExecuteCronJobsAfter(_tokenIn, msg.sender, _tokenOut, _transferTo)
        transactionIsNotExpired(_expireTimestamp)
        returns (uint256[] memory)
    {
        return _swapTokensForExactTokens(
            _tokenIn,
            _tokenOut,
            _amountTokensOut,
            _maxAmountTokensIn,
            _transferTo
        );
    }
    function _swapTokensForExactTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountTokensOut,
        uint256 _maxAmountTokensIn,
        address _transferTo
    )
        private
        returns (uint256[] memory)
    {
        if (_tokenIn == _tokenOut) {
            revert CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
        }
        address vaultAddressIn = _getCachedVaultCloneAddressByToken(
            _tokenIn
        );
        uint256[] memory amounts = new uint256[](2);
        amounts[1] = _amountTokensOut;
        PoolBalances memory poolInBalancesBefore;
        if (_tokenOut == CER_USD_TOKEN) {
            poolInBalancesBefore = _getPoolBalances(
                _tokenIn
            );
            amounts[0] = _getInputTokensForExactCerUsd(
                poolInBalancesBefore,
                _tokenIn,
                _amountTokensOut
            );
            if (amounts[0] > _maxAmountTokensIn) {
                revert CerbySwapV1_InputTokensAmountIsLargerThanMaximumSpecified();
            }
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                vaultAddressIn,
                amounts[0]
            );
            _swap(
                _tokenIn,
                poolInBalancesBefore,
                0,
                _amountTokensOut,
                _transferTo
            );
            return amounts;
        }
        address vaultAddressOut = _getCachedVaultCloneAddressByToken(
            _tokenOut
        );
        PoolBalances memory poolOutBalancesBefore;
        if (_tokenIn == CER_USD_TOKEN) {
            poolOutBalancesBefore = _getPoolBalances(
                _tokenOut
            );
            amounts[0] = _getInputCerUsdForExactTokens(
                poolOutBalancesBefore,
                _amountTokensOut
            );
            if (amounts[0] > _maxAmountTokensIn) {
                revert CerbySwapV1_InputCerUsdAmountIsLargerThanMaximumSpecified();
            }
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                vaultAddressOut,
                amounts[0]
            );
            _swap(
                _tokenOut,
                poolOutBalancesBefore,
                _amountTokensOut,
                0,
                _transferTo
            );
            return amounts;
        }
        poolOutBalancesBefore = _getPoolBalances(
            _tokenOut
        );
        uint256 amountCerUsdOut = _getInputCerUsdForExactTokens(
            poolOutBalancesBefore,
            _amountTokensOut
        );
        if (amountCerUsdOut <= 1) {
            revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
        }
        poolInBalancesBefore = _getPoolBalances(
            _tokenIn
        );
        amounts[0] = _getInputTokensForExactCerUsd(
            poolInBalancesBefore,
            _tokenIn,
            amountCerUsdOut
        );
        if (amounts[0] > _maxAmountTokensIn) {
            revert CerbySwapV1_InputTokensAmountIsLargerThanMaximumSpecified();
        }
        _safeTransferFromHelper(
            _tokenIn,
            msg.sender,
            vaultAddressIn,
            amounts[0]
        );
        _swap(
            _tokenIn,
            poolInBalancesBefore,
            0,
            amountCerUsdOut,
            vaultAddressOut
        );
        _swap(
            _tokenOut,
            poolOutBalancesBefore,
            _amountTokensOut,
            0,
            _transferTo
        );
        return amounts;
    }
    function _swap(
        address _token,
        PoolBalances memory _poolBalancesBefore,
        uint256 _amountTokensOut,
        uint256 _amountCerUsdOut,
        address _transferTo
    )
        private
    {
        PoolBalances memory poolBalancesAfter = _getPoolBalances(
            _token
        );
        uint256 amountCerUsdIn = poolBalancesAfter.balanceCerUsd
            - _poolBalancesBefore.balanceCerUsd;
        uint256 amountTokensIn = poolBalancesAfter.balanceToken
            - _poolBalancesBefore.balanceToken;
        if (amountTokensIn + amountCerUsdIn <= 1) {
            revert CerbySwapV1_AmountOfCerUsdOrTokensInMustBeLargerThanOne();
        }
        Pool storage pool = pools[cachedTokenValues[_token].poolId];
        if (
            pool.creditCerUsd < MAX_CER_USD_CREDIT &&
            uint256(pool.creditCerUsd) + amountCerUsdIn < _amountCerUsdOut
        ) {
            revert CerbySwapV1_CreditCerUsdMustNotBeBelowZero();
        }
        uint256 currentPeriod = _getCurrentPeriod();
        uint256 fee;
        {
            if (amountCerUsdIn <= 1 && amountTokensIn > 1) {
                uint256 lastPeriodI = uint256(
                    pool.lastCachedTradePeriod
                );
                if (lastPeriodI != currentPeriod) {
                    uint256 endPeriod = currentPeriod < lastPeriodI
                        ? currentPeriod + NUMBER_OF_TRADE_PERIODS
                        : currentPeriod;
                    while(++lastPeriodI <= endPeriod) {
                        pool.tradeVolumePerPeriodInCerUsd[lastPeriodI % NUMBER_OF_TRADE_PERIODS] = 1;
                    }
                    pool.lastCachedFee = uint8(
                        _getCurrentFeeBasedOnTrades(
                            pool,
                            _poolBalancesBefore
                        )
                    );
                    pool.lastCachedTradePeriod = uint8(
                        currentPeriod
                    );
                }
                fee = uint256(pool.lastCachedFee);
            }
            uint256 beforeKValueDenormed = _poolBalancesBefore.balanceToken
                * _poolBalancesBefore.balanceCerUsd
                * FEE_DENORM_SQUARED;
            uint256 afterKValueDenormed = (
                    poolBalancesAfter.balanceCerUsd
                    * FEE_DENORM
                        - amountCerUsdIn
                        * fee
                )
                * (
                    poolBalancesAfter.balanceToken
                    * FEE_DENORM
                        - amountTokensIn
                        * fee
                );
            if (afterKValueDenormed < beforeKValueDenormed) {
                revert CerbySwapV1_InvariantKValueMustBeSameOrIncreasedOnAnySwaps();
            }
            if (pool.creditCerUsd < MAX_CER_USD_CREDIT) {
                pool.creditCerUsd = uint128(
                    uint256(pool.creditCerUsd)
                        + amountCerUsdIn
                        - _amountCerUsdOut
                );
            }
            if (_amountCerUsdOut > TRADE_VOLUME_DENORM) {
                uint256 updatedTradeVolume = _amountCerUsdOut
                    / TRADE_VOLUME_DENORM
                    + uint256(pool.tradeVolumePerPeriodInCerUsd[currentPeriod]);
                pool.tradeVolumePerPeriodInCerUsd[currentPeriod] = updatedTradeVolume < type(uint40).max
                    ? uint40(updatedTradeVolume)
                    : type(uint40).max;
            }
        }
        address vault = _getCachedVaultCloneAddressByToken(
            _token
        );
        _safeTransferFromHelper(
            CER_USD_TOKEN,
            vault,
            _transferTo,
            _amountCerUsdOut
        );
        _safeTransferFromHelper(
            _token,
            vault,
            _transferTo,
            _amountTokensOut
        );
        emit Swap(
            _token,
            msg.sender,
            amountTokensIn,
            amountCerUsdIn,
            _amountTokensOut,
            _amountCerUsdOut,
            fee,
            _transferTo
        );
        emit Sync(
            _token,
            poolBalancesAfter.balanceToken,
            poolBalancesAfter.balanceCerUsd,
            pool.creditCerUsd
        );
    }
}
pragma solidity ^0.8.0;
abstract contract Ownable {
    address private contractOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    error Ownable_CallerIsNotOwner();
    error Ownable_NewOwnerIsNotTheZeroAddress();
    constructor() {}
    function owner() public view virtual returns (address) {
        return contractOwner;
    }
    modifier onlyOwner() {
        if (contractOwner != msg.sender) {
            revert Ownable_CallerIsNotOwner();
        }
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address _newOwner) public virtual onlyOwner {
        if (_newOwner == address(0)) {
            revert Ownable_NewOwnerIsNotTheZeroAddress();
        }
        _transferOwnership(_newOwner);
    }
    function _transferOwnership(address _newOwner) internal virtual {
        address oldOwner = contractOwner;
        contractOwner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}
pragma solidity ^0.8.12;
abstract contract CerbySwapV1_AdminFunctions is
    CerbySwapV1_SwapFunctions,
    Ownable
{
    function adminSetUrlPrefix(
        string calldata _newUrlPrefix
    )
        external
        onlyOwner
    {
        urlPrefix = _newUrlPrefix;
    }
    function adminUpdateNameAndSymbol(
        string memory _newContractName,
        string memory _newContractSymbol
    )
        external
        onlyOwner
    {
        contractName = _newContractName;
        contractSymbol = _newContractSymbol;
    }
    function adminUpdateSettings(
        Settings calldata _settings
    )
        external
        onlyOwner
    {
        if (
            _settings.feeMinimum == 0 ||
            _settings.feeMinimum > _settings.feeMaximum
        ) {
            revert CerbySwapV1_FeeIsWrong();
        }
        if (_settings.tvlMultiplierMinimum > _settings.tvlMultiplierMaximum) {
            revert CerbySwapV1_TvlMultiplierIsWrong();
        }
        if (_settings.mintFeeMultiplier >= MINT_FEE_DENORM / 2) {
            revert CerbySwapV1_MintFeeMultiplierMustNotBeLargerThan50Percent();
        }
        settings = _settings;
    }
    function adminCreatePool(
        address _token,
        uint256 _amountTokensIn,
        uint256 _amountCerUsdToMint,
        address _transferTo
    )
        external
        payable
        onlyOwner
    {
        _createPool(
            _token,
            _amountTokensIn,
            _amountCerUsdToMint,
            MAX_CER_USD_CREDIT,
            _transferTo
        );
    }
    function adminChangeCerUsdCreditInPool(
        address _token,
        uint256 _amountCerUsdCredit
    )
        external
        onlyOwner
        tokenMustExistInPool(_token)
    {
        PoolBalances memory poolBalances = _getPoolBalances(
            _token
        );
        Pool storage pool = pools[cachedTokenValues[_token].poolId];
        pool.creditCerUsd = uint128(
            _amountCerUsdCredit
        );
        emit Sync(
            _token,
            poolBalances.balanceToken,
            poolBalances.balanceCerUsd,
            _amountCerUsdCredit
        );
    }
}
pragma solidity ^0.8.12;
contract CerbySwapV1 is CerbySwapV1_AdminFunctions {
    constructor() {
        _transferOwnership(
            msg.sender
        );
        if (block.chainid == ETH_MAINNET_CHAIN_ID) {
            NATIVE_TOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else if (block.chainid == BSC_MAINNET_CHAIN_ID) {
            NATIVE_TOKEN = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        } else if (block.chainid == POLYGON_MAINNET_CHAIN_ID) {
            NATIVE_TOKEN = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        } else if (block.chainid == AVALANCHE_MAINNET_CHAIN_ID) {
            NATIVE_TOKEN = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
        } else if (block.chainid == FANTOM_MAINNET_CHAIN_ID) {
            NATIVE_TOKEN = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
        }
        uint40[NUMBER_OF_TRADE_PERIODS] memory tradeVolumePerPeriodInCerUsd;
        pools.push(
            Pool({
                tradeVolumePerPeriodInCerUsd: tradeVolumePerPeriodInCerUsd,
                lastCachedTradePeriod: 0,
                lastCachedFee: 0,
                lastSqrtKValue: 0,
                creditCerUsd: 0
            })
        );
    }
    receive() external payable {}
}