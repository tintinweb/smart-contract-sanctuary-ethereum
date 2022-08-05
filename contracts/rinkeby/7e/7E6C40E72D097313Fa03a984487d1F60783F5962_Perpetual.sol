pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Users.sol";
import "./Deposits.sol";
import "./Withdrawals.sol";
import "./updateState.sol";
import "./globalConfig.sol";
import "./dac.sol";

/// @title main contract
contract Perpetual is Users, Deposits, Withdrawals, UpdateState, GlobalConfig, Dac {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct perpetualParams {
        I_Verifier verifierAddress;
        bytes32 accountRoot;
        bytes32 orderStateHash;
        IERC20Upgradeable collateralToken;
        uint8 innerDecimal;
        address userAdmin;
        address genesisGovernor;
        address genesisValidator;
        address[] dacMembers;
        uint32 dac_reg_timelock;
        uint32 global_config_change_timelock;
        uint32 funding_validity_period;
        uint32 price_validity_period;
        uint64 max_funding_rate;
        uint16 max_asset_num;
        uint16 max_oracle_num;
        SyntheticAssetInfo[] synthetic_assets;
        uint256 deposit_cancel_timelock;
        uint256 forced_action_expire_time;
    }

    function initialize(
        perpetualParams calldata param
	) external {
        initializeReentrancyGuard();

        // genesis block state
        accountRoot      = param.accountRoot;
        orderStateHash   = param.orderStateHash;

        // verifier
        verifier = param.verifierAddress;

        // governor/validator/UserAdmin
        initGovernor(param.genesisGovernor, param.genesisValidator);
        userAdmin = param.userAdmin;

        // DAC
        MIN_DAC_MEMBER = 6;
        TIMELOCK_DAC_REG = param.dac_reg_timelock;
        for (uint256 i = 0; i < param.dacMembers.length; ++i) {
            addDac(param.dacMembers[i]);
        }
        require(dacNum >= MIN_DAC_MEMBER, "idmu");


        // global config
        MAX_ASSETS_COUNT = param.max_asset_num;
        MAX_NUMBER_ORACLES = param.max_oracle_num;
        TIMELOCK_GLOBAL_CONFIG_CHANGE = param.global_config_change_timelock;

        globalConfigHash = initGlobalConfig(
            param.synthetic_assets,
            param.funding_validity_period,
            param.price_validity_period,
            param.max_funding_rate,
            MAX_ASSETS_COUNT,
            MAX_NUMBER_ORACLES
            );
        resetGlobalConfigValidBlockNum();

        // system Token Config
        collateralToken = param.collateralToken;
        innerDecimal = param.innerDecimal;
        (bool success, bytes memory returndata) = address(collateralToken).call(abi.encodeWithSignature("decimals()"));
        require(success);
        systemTokenDecimal = abi.decode(returndata, (uint8));

        DEPOSIT_CANCEL_TIMELOCK = param.deposit_cancel_timelock;
        FORCED_ACTION_EXPIRE_TIME = param.forced_action_expire_time;

    }

    // function upgrade(bytes calldata args) onlyGovernor external {
    // }

    function registerAndDeposit(
        address ethAddr,
        uint256[] memory l2Keys,
        bytes calldata signature,
        uint32[] memory depositId,
        uint256[] memory amount
	) external payable {
        registerUser(ethAddr, l2Keys, signature);
        require(depositId.length == amount.length, "rad0");
        for (uint256 i = 0; i < depositId.length; ++i) {
            deposit(l2Keys[depositId[i]], amount[i]);
        }
    }

    event TokenRecovery(
        address token,
        uint256 amount
    );


    receive() external payable {
    }

    // allow to recovery wrong token sent to the contract
    function recoverWrongToken(address token, uint256 amount) external onlyGovernor nonReentrant {
        require(token != address(collateralToken), "cbrst");  // "Cannot be system token"
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20Upgradeable(token).safeTransfer(address(msg.sender), amount);
        }
        emit TokenRecovery(token, amount);
    }

}

pragma solidity >= 0.8.12;

// SPDX-License-Identifier: Apache-2.0.


import "./Storage.sol";
import "./libs/Bytes.sol";

abstract contract Users is Storage {
    event LogUserRegistered(address ethAddr, uint256[] l2Keys, address sender);
    
    function registerUser(
        address ethAddr,
        uint256[] memory l2Keys,
        bytes calldata signature
    ) public {
	    for (uint32 i = 0; i < l2Keys.length; ++i) {
            require(ethKeys[l2Keys[i]] == address(0), "l2Key already registered");
        }

        bytes32 concatKeyHash = EMPTY_STRING_KECCAK;
        for (uint256 i = 0; i < l2Keys.length; ++i) {
            concatKeyHash = keccak256(abi.encodePacked(concatKeyHash, l2Keys[i]));
        }

        bytes memory orig_msg = bytes.concat(
                abi.encode(ethAddr),
                concatKeyHash);

        bytes memory message = bytes.concat(
                "\x19Ethereum Signed Message:\n130",  // 10-th 130
                "0x",
                Bytes.bytesToHexASCIIBytes(orig_msg)
        );

        address signer = ECDSA.recover(keccak256(message), signature);
        require(signer == userAdmin, "User Register Sinature Invalid");

	    for (uint32 i = 0; i < l2Keys.length; ++i) {
 	        ethKeys[l2Keys[i]] = ethAddr;
	    }
        emit LogUserRegistered(ethAddr, l2Keys, msg.sender);
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0.


import "./Storage.sol";

abstract contract Deposits is Storage {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    event LogDeposit(
        address ethAddr,
        uint256 l2Key,
        uint256 amount
    );

    event LogDepositCancel(uint256 l2Key);

    event LogDepositCancelReclaimed(
        uint256 l2Key,
        uint256 amount
    );

    function depositERC20(
        IERC20Upgradeable token,
        uint256 l2Key,
        uint256 amount
    ) internal {
        pendingDeposits[l2Key] += amount;

        // Disable the cancellationRequest timeout when users deposit into their own account.
        if (cancellationRequests[l2Key] != 0 && ethKeys[l2Key] == msg.sender)
        {
            delete cancellationRequests[l2Key];
        }

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit LogDeposit(msg.sender, l2Key, amount);
    }

    function deposit(
        uint256 l2Key,
        uint256 amount
    ) public nonReentrant {
        require(ethKeys[l2Key] != address(0), "need reg");
        depositERC20(collateralToken, l2Key, amount);
    }

    function depositCancel(
        uint256 l2Key
    ) external onlyKeyOwner(l2Key) {
        cancellationRequests[l2Key] = block.timestamp;
        emit LogDepositCancel(l2Key);
    }

    function depositReclaim(
        uint256 l2Key
    ) external onlyKeyOwner(l2Key) nonReentrant {
        uint256 requestTime = cancellationRequests[l2Key];
        require(requestTime != 0, "drnc");  // DEPOSIT_NOT_CANCELED
        uint256 freeTime = requestTime + DEPOSIT_CANCEL_TIMELOCK;
        require(block.timestamp >= freeTime, "dl"); // "DEPOSIT_LOCKED"

        // Clear deposit.
        uint256 amount = pendingDeposits[l2Key];
        delete pendingDeposits[l2Key];
        delete cancellationRequests[l2Key];

        collateralToken.safeTransfer(ethKeys[l2Key], amount); 
        emit LogDepositCancelReclaimed(l2Key, amount);
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0.


import "./Storage.sol";

abstract contract Withdrawals is Storage {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event LogWithdrawalPerformed(
        uint256 ownerKey,
        uint256 amount,
        address recipient
    );

    function withdrawERC20(IERC20Upgradeable token, uint256 ownerKey, address payable recipient) internal {
        require(recipient != address(0), "w0");
        uint256 amount = pendingWithdrawals[ownerKey];
        pendingWithdrawals[ownerKey] = 0;

        token.safeTransfer(recipient, amount); 

        emit LogWithdrawalPerformed(
            ownerKey,
            amount,
            recipient
        );
    }

    function withdraw(uint256 ownerKey) external nonReentrant {
        address payable recipient = payable(ethKeys[ownerKey]);
        withdrawERC20(collateralToken, ownerKey, recipient);
    }

    function withdrawTo(
        uint256 ownerKey, address payable recipient)
        external onlyKeyOwner(ownerKey) nonReentrant
    {
        withdrawERC20(collateralToken, ownerKey, recipient);
    }

}

pragma solidity >= 0.8.12;

// SPDX-License-Identifier: MIT OR Apache-2.0


import "./Storage.sol";
import "./Config.sol";

abstract contract UpdateState is Config, Storage {

    event LogWithdrawalAllowed(
        uint256 l2Key,
        uint256 amount
    );

    event BlockUpdate(uint32 firstBlock, uint32 lastBlock);

    struct GlobalFunding {
        uint64[] index;      // per asset when block have funding_tick transaction
        uint256 indexHashOrTimeStamp;  // if index.length==0, = bytes32 hash, else uint32 timestamp
    }

    struct CommitBlockInfo {
        uint32 blockNumber;
        uint32 timestamp;

        bytes32 accountRoot;                // root hash of account
        bytes32 validiumAccountRoot;        // for rollup merkle path, rollupAccount could be restore from pubData
        bytes32 orderRoot;

        GlobalFunding globalFunding;
        bytes32 oraclePriceHash;
        bytes32 orderStateHash;             // include funding index, oracle price, orderRoot
        bytes32 all_data_commitment;        // account Full Data Hash

        uint32 blockChunkSize;              // per pubdata type(balance/position/onchain) padding zero
        bytes collateralBalancePubData;     // per account [accountId, collateral_balance]
        bytes positonPubData;               // per account [accountId, asset_id, balance]
        bytes onchainPubData;               // per onchain operation (deposit/withdraw/...) [op_type, ...]
    }

    struct ProofInput {
        uint256[] recursiveInput;
        uint256[] proof;
        uint256[] commitments;
        uint8[] vkIndexes;
        uint256[16] subproofsLimbs;
    }

    function getPadLen(
        uint256 realSize,
        uint32 alignSize
    ) internal pure returns (uint256 padLen) {
        padLen = realSize % alignSize;
        if (padLen != 0) {
            padLen = alignSize - padLen;
        } else if (realSize == 0) {
            padLen = alignSize;
        }
    }

    function pubdataPadCommitment(
        bytes calldata pubdata,
        uint32 alignSize
    ) internal pure returns (bytes32 commitment) {
        uint256 padLen = getPadLen(pubdata.length, alignSize);
        if (padLen != 0) {
            bytes memory padZero = new bytes(padLen);
            commitment = sha256(bytes.concat(pubdata, padZero));
        } else {
            commitment = sha256(pubdata);
        }
    }

    function createBlockCommitment(
        bytes32 oldAccountRoot,
        bytes32 oldOrderStateHash,
        bytes32 newOrderStateHash,
        CommitBlockInfo calldata newBlock
    ) internal view returns (bytes32 commitment) {
        bytes32 h = sha256(abi.encodePacked(uint256(newBlock.blockNumber), oldAccountRoot));
        h = sha256(bytes.concat(h, newBlock.accountRoot));
        h = sha256(bytes.concat(h, oldOrderStateHash));
        h = sha256(bytes.concat(h, newOrderStateHash));
        h = sha256(bytes.concat(h, globalConfigHash));
        h = sha256(bytes.concat(h, newBlock.validiumAccountRoot));

        uint32 alignSize = newBlock.blockChunkSize * Operations.ACCOUNT_COLLATERAL_BALANCE_PUBDATA_BYTES;
        bytes32 rollup_col_commitment = pubdataPadCommitment(newBlock.collateralBalancePubData, alignSize);

        alignSize = newBlock.blockChunkSize * Operations.ACCOUNT_POSITION_PUBDATA_BYTES;
        bytes32 rollup_assets_commitment = pubdataPadCommitment(newBlock.positonPubData, alignSize);

        bytes32 rollup_data_commitment = sha256(bytes.concat(rollup_col_commitment, rollup_assets_commitment));
        bytes32 account_data_commitment = sha256(bytes.concat(rollup_data_commitment, newBlock.all_data_commitment));
        h = sha256(bytes.concat(h, account_data_commitment));

        alignSize = newBlock.blockChunkSize * Operations.DEPOSIT_WITHDRAW_PUBDATA_BYTES;
        bytes32 onchain_commitment = pubdataPadCommitment(newBlock.onchainPubData, alignSize);
        commitment = sha256(bytes.concat(h, onchain_commitment));
    }

    function postProcess(
        bytes calldata pubData
    ) internal {
        uint256 offset = 0;
        uint256 factor = 10 ** (systemTokenDecimal - innerDecimal);

        while (offset < pubData.length) {

            Operations.DepositOrWithdraw memory op = Operations.readDepositOrWithdrawPubdata(pubData, offset);
            if (op.amount > DEPOSIT_LOWER_BOUND) {
                uint256 innerAmount = (uint256(op.amount) - DEPOSIT_LOWER_BOUND);
                pendingDeposits[op.l2Key] -= innerAmount * factor;
            } else {
                uint256 innerAmount = (DEPOSIT_LOWER_BOUND - uint256(op.amount));
                uint256 externalAmount = innerAmount * factor;
                pendingWithdrawals[op.l2Key] += externalAmount;
                emit LogWithdrawalAllowed(op.l2Key, externalAmount);
            }
            
            offset += Operations.DEPOSIT_WITHDRAW_PUBDATA_BYTES;
        }
    }

    function encodePackU64Array(
        uint64[] memory a, uint start, uint padLen, uint64 padValue
    ) internal pure returns(bytes memory data) {
        for(uint i = start; i< start + padLen; i++){
            if (i < a.length) {
                data = abi.encodePacked(data, a[i]);
            } else {
                data = abi.encodePacked(data, padValue);
            }
        }
    }

    function getOrderStateHash(
        CommitBlockInfo calldata b,
        uint64[] memory oracle_price
    ) internal view returns (bytes32 newOrderStateHash) {
        if (oracle_price.length == 0 && b.globalFunding.index.length == 0) {
            return b.orderStateHash;
        }

        bytes32 oraclePriceHash = b.oraclePriceHash;
        if (oracle_price.length != 0) {
            bytes memory encode_data = encodePackU64Array(oracle_price, 0, MAX_ASSETS_COUNT, 0);
            oraclePriceHash = sha256(encode_data);
        }

        bytes32 globalFundingIndexHash;
        if (b.globalFunding.index.length != 0) {
            uint32 timestamp = uint32(b.globalFunding.indexHashOrTimeStamp);
            bytes memory encode_data = abi.encodePacked(timestamp, encodePackU64Array(b.globalFunding.index, 0, MAX_ASSETS_COUNT, 1 << 63));
            globalFundingIndexHash = sha256(encode_data);
        } else {
            globalFundingIndexHash = bytes32(b.globalFunding.indexHashOrTimeStamp);
        }

        bytes32 global_state_hash = sha256(abi.encodePacked(uint32(b.timestamp), globalFundingIndexHash, oraclePriceHash));
        newOrderStateHash = sha256(bytes.concat(b.orderRoot, global_state_hash));
    }

    function verifyProofCommitment(
        CommitBlockInfo[] calldata _newBlocks,
        uint256[] calldata proof_commitments,
        uint64[] calldata lastestOraclePrice
    ) internal returns (bytes32 curOrderStateHash) {
        bytes32 curAccountRoot = accountRoot;
        curOrderStateHash = orderStateHash;
        for (uint256 i = 0; i < _newBlocks.length; ++i) {
            if (is_pending_global_config() && _newBlocks[i].blockNumber == newGlobalConfigValidBlockNum) {
                resetGlobalConfigValidBlockNum();
                globalConfigHash = newGlobalConfigHash;
                emit LogNewGlobalConfigHash(_newBlocks[i].blockNumber, newGlobalConfigHash);
            }

            // Create block commitment, and check with proof commitment
            uint64[] memory oraclePrice;
            if (i == _newBlocks.length - 1) {
                oraclePrice = lastestOraclePrice;
            }
            bytes32 newOrderStateHash = getOrderStateHash(_newBlocks[i], oraclePrice);
            bytes32 commitment = createBlockCommitment(curAccountRoot, curOrderStateHash, newOrderStateHash, _newBlocks[i]);
            require(proof_commitments[i] & INPUT_MASK == uint256(commitment) & INPUT_MASK, "proof commitment invalid");

            curAccountRoot = _newBlocks[i].accountRoot;
            curOrderStateHash = newOrderStateHash;
        }
    }

    function verifyValidiumSignature(
        CommitBlockInfo[] calldata newBlocks,
        bytes[] calldata validium_signature
    ) internal view {
        bytes32 concatValdiumHash = EMPTY_STRING_KECCAK;
        for (uint256 i = 0; i < newBlocks.length; ++i) {
            concatValdiumHash = keccak256(bytes.concat(concatValdiumHash, newBlocks[i].all_data_commitment));
        }

        bytes memory message = bytes.concat(
                "\x19Ethereum Signed Message:\n66",
                "0x",
                Bytes.bytesToHexASCIIBytes(abi.encodePacked(concatValdiumHash))
        );
        bytes32 msgHash = keccak256(message);

        uint32 sig_dac_num = 0;
        address[MIN_SIGNATURE_MEMBER] memory signers;
        for (uint256 i = 0; i < validium_signature.length; ++i) {
            address signer = ECDSA.recover(msgHash, validium_signature[i]);
            require(dacs[signer], "notDac");

            uint256 j;
            for (j = 0; j < sig_dac_num; ++j) {
                if (signers[j] == signer) {
                    break;
                }
            }

            if (j != sig_dac_num) { // ignore same signer
                continue;
            }


            signers[sig_dac_num++] = signer;
            if (sig_dac_num == MIN_SIGNATURE_MEMBER) {
                // ignore additional signature.
                break;
            }
        }
        require(sig_dac_num >= MIN_SIGNATURE_MEMBER, "sig3");
    }

    function updateBlocks(
        CommitBlockInfo[] calldata _newBlocks,
        bytes[] calldata validium_signature,
        ProofInput calldata _proof,
        uint64[] calldata lastestOraclePrice
    ) external onlyValidator onlyActive nonReentrant {

        require (_newBlocks.length >= 1);
        verifyValidiumSignature(_newBlocks, validium_signature);
        bytes32 newOrderStateHash = verifyProofCommitment(_newBlocks, _proof.commitments, lastestOraclePrice);

        // block prove
        require(verifier.verifyAggregatedBlockProof(
                            _proof.subproofsLimbs,
                            _proof.recursiveInput,
                            _proof.proof,
                            _proof.vkIndexes,
                            _proof.commitments), "p");

        //postprocess onchain operation
        for (uint256 i = 0; i < _newBlocks.length; ++i) {
            postProcess(_newBlocks[i].onchainPubData);
        }

        // update block status
        accountRoot = _newBlocks[_newBlocks.length - 1].accountRoot;
        orderStateHash = newOrderStateHash;
        emit BlockUpdate(_newBlocks[0].blockNumber,
                         _newBlocks[_newBlocks.length - 1].blockNumber);
    }

}

pragma solidity >= 0.8.12;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Storage.sol";

abstract contract GlobalConfig is Storage {
    uint256 constant GLOBAL_CONFIG_KEY = ~uint256(0);
    event LogGlobalConfigChangeReg(bytes32 configHash);
    event LogGlobalConfigChangeApplied(bytes32 configHash, uint256 valid_layer2_block_num);
    event LogGlobalConfigChangeRemoved(bytes32 configHash);

    function encodeSyntheticAssets (
        SyntheticAssetInfo[] calldata synthetic_assets,
        uint16 _max_oracle_num
    ) internal pure returns (bytes memory config) {
        for (uint32 i=0; i< synthetic_assets.length; ++i) {
            uint256 real_oracle_num = synthetic_assets[i].oracle_price_signers_pubkey_hash.length / 20; // TODO
            bytes memory padZero = new bytes((_max_oracle_num - real_oracle_num) * 20);
            config = bytes.concat(config, 
                    abi.encodePacked(
                        synthetic_assets[i].resolution,
                        synthetic_assets[i].risk_factor,
                        synthetic_assets[i].asset_name,
                        synthetic_assets[i].oracle_price_signers_pubkey_hash
                    ), padZero);
        }
    }

    function initGlobalConfig(
        SyntheticAssetInfo[] calldata synthetic_assets,
        uint32 funding_validity_period,
        uint32 price_validity_period,
        uint64 max_funding_rate,
        uint16 _max_asset_count,
        uint16 _max_oracle_num
    ) internal pure returns (bytes32) {
        bytes memory padAsset = new bytes((_max_asset_count - synthetic_assets.length) * (24 + _max_oracle_num * 20));

        bytes memory globalConfig =bytes.concat(
            abi.encodePacked(
                uint16(synthetic_assets.length),
                funding_validity_period,
                price_validity_period,
                max_funding_rate
            ),
            encodeSyntheticAssets(synthetic_assets, _max_oracle_num),
            padAsset
        );

        return sha256(globalConfig);
        // event
    }

    function encodeOracleSigners (
        bytes20[] memory signers
    ) internal pure returns (bytes memory config) {
        for (uint32 i=0; i< signers.length; ++i) {
            config = bytes.concat(config, signers[i]);
        }
    }

    function addSyntheticAssets (
        SyntheticAssetInfo[] calldata synthetic_assets,
        bytes calldata oldGlobalConfig,
        uint256 valid_layer2_block_num
    ) external onlyGovernor {
        require(globalConfigHash == sha256(oldGlobalConfig), "iog");  // "invalid oldGlobalConfig"
        require(!is_pending_global_config(), "pgcce1"); // "PENDING_GLOBAL_CONFIG_CHANGE_EXIST"
        uint16 old_n_synthetic_assets_info = Bytes.bytesToUInt16(oldGlobalConfig[0:2], 0);
        require(old_n_synthetic_assets_info + synthetic_assets.length <= MAX_ASSETS_COUNT, "aml");   // "asset max limit"

        uint256 old_pad_zero_num = (MAX_ASSETS_COUNT - old_n_synthetic_assets_info) * (24 + MAX_NUMBER_ORACLES * 20);
        bytes memory newPadding = new bytes((MAX_ASSETS_COUNT - old_n_synthetic_assets_info - synthetic_assets.length) * (24 + MAX_NUMBER_ORACLES * 20));
        bytes memory newGlobalConfig = bytes.concat(
            bytes2(old_n_synthetic_assets_info + uint16(synthetic_assets.length)),
            oldGlobalConfig[2:oldGlobalConfig.length-old_pad_zero_num],
            encodeSyntheticAssets(synthetic_assets, MAX_NUMBER_ORACLES),
            newPadding
        );
        newGlobalConfigHash = sha256(newGlobalConfig);

        newGlobalConfigValidBlockNum = valid_layer2_block_num;
        emit LogGlobalConfigChangeApplied(newGlobalConfigHash, valid_layer2_block_num);
    }

    function regGlobalConfigChange(bytes32 configHash) external onlyGovernor
    {
        bytes32 actionKey = keccak256(bytes.concat(bytes32(GLOBAL_CONFIG_KEY), configHash));
        actionsTimeLock[actionKey] = block.timestamp + TIMELOCK_GLOBAL_CONFIG_CHANGE;
        emit LogGlobalConfigChangeReg(configHash);
    }

    function applyGlobalConfigChange(
        bytes32 configHash,
        uint256 valid_layer2_block_num)
        external onlyGovernor
    {
        bytes32 actionKey = keccak256(abi.encode(GLOBAL_CONFIG_KEY, configHash));
        uint256 activationTime = actionsTimeLock[actionKey];
        require(!is_pending_global_config(), "pgcce2"); // "PENDING_GLOBAL_CONFIG_CHANGE_EXIST"
        require(activationTime > 0, "cng0"); // "CONFIGURATION_NOT_REGSITERED"
        require(activationTime <= block.timestamp, "cney"); // "CONFIGURATION_NOT_ENABLE_YET"
        newGlobalConfigHash = configHash;
        newGlobalConfigValidBlockNum = valid_layer2_block_num;
        emit LogGlobalConfigChangeApplied(configHash, valid_layer2_block_num);
    }

    function removeGlobalConfigChange(bytes32 configHash)
        external onlyGovernor
    {
        bytes32 actionKey = keccak256(bytes.concat(bytes32(GLOBAL_CONFIG_KEY), configHash));
        require(actionsTimeLock[actionKey] > 0, "cnr0"); // "CONFIGURATION_NOT_REGSITERED"
        delete actionsTimeLock[actionKey];
        emit LogGlobalConfigChangeRemoved(configHash);
    }

}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Storage.sol";

abstract contract Dac is Storage {

    function regDac(address member) external onlyGovernor {
        // TimeLock : User not trust the feeder, will be able to withdraw
        require(!DacRegisterActive, "dir");     // "dac in register"
        require(!dacs[member], "dae");    // "dac already exist"
        DacRegisterActive = true;
        DacRegisterTime = block.timestamp;
        pendingDacMember = member;
    }

    function updateDac() external onlyGovernor {
        require(DacRegisterActive, "dnr"); // "dac not register"
        require(block.timestamp > DacRegisterTime + TIMELOCK_DAC_REG, "drit"); // "dac register still in timelock"
        DacRegisterActive = false;

        addDac(pendingDacMember);
    }

    function cancelDacReg() external onlyGovernor {
        DacRegisterActive = false;
    }

    function addDac(address member) internal {
        require(member != address(0), "da0");
        dacs[member] = true;
        dacNum += 1;
    }
    
    function deleteDac(address member) external onlyGovernor {
        // Time-Lock ?
        require(dacs[member] != false, "dane"); // "dac member not exist"
        require(dacNum > MIN_DAC_MEMBER, "dmu");  // "dac memeber underflow"
        delete dacs[member];
        dacNum -= 1;
    }

}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { SafeERC20Upgradeable, IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./verifier/I_Verifier.sol";
import "./libs/ReentrancyGuard.sol";


import "./Operations.sol";
import "./Governance.sol";


bytes32 constant EMPTY_STRING_KECCAK = keccak256("");
uint64 constant DEPOSIT_LOWER_BOUND = (1 << 63);

struct SyntheticAssetInfo {
    uint64 resolution;
    uint32 risk_factor;
    bytes12 asset_name;
    bytes oracle_price_signers_pubkey_hash;
}

/// @title Storage Contract
contract Storage is Governance, ReentrancyGuard {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    event LogNewGlobalConfigHash(uint32 blockNumber, bytes32 configHash);

    /* block chain root hash */
    bytes32 public accountRoot;
    bytes32 public orderStateHash;

    mapping(address => bool) public dacs;
    uint32 public dacNum;
    uint32 constant MIN_SIGNATURE_MEMBER = 3;
    uint256 public DacRegisterTime;
    address pendingDacMember;
    bool public DacRegisterActive;

    bytes32 public globalConfigHash;

    // Mapping from layer2 public key to the Ethereum public key of its owner.
    // 1. used to valid withdraw request
    // 2. allows registering many different l2keys to same eth address ?
    //     2.1 user might wanna both validum and rollup account.
    //     2.2 API user might wanna multiple account.
    address userAdmin;
    mapping(uint256 => address) public ethKeys;
    modifier onlyKeyOwner(uint256 ownerKey) {
        require(msg.sender == ethKeys[ownerKey], "Not ethKey Owner");
        _;
    }

    I_Verifier public verifier;

    IERC20Upgradeable public collateralToken;
    uint8 public innerDecimal;
    mapping(uint256 => uint256) public pendingDeposits;
    mapping(uint256 => uint256) public pendingWithdrawals;

    // map l2 key => timestamp.
    mapping(uint256 => uint256) public cancellationRequests;

    // map forced Action Request Hash => timestatmp
    mapping(bytes32 => uint256) forcedActionRequests;

    bool stateFrozen;
    I_Verifier public escapeVerifier;
    mapping(uint256 => bool) escapesUsed;

    function addForceRequest(bytes32 req) internal {
		require(forcedActionRequests[req] == 0, "rap0"); // REQUEST_ALREADY_PENDING
		forcedActionRequests[req] = block.timestamp;
    }

    function cancelForceRequest(bytes32 req) internal {
        delete forcedActionRequests[req];
    }

    function freeze(bytes32 req) public {
		require(forcedActionRequests[req] != 0 && forcedActionRequests[req] + FORCED_ACTION_EXPIRE_TIME > block.timestamp, "ftne0");  // "freeze timestamp not expired!"
		stateFrozen = true;
    }

    modifier onlyFrozen() {
        require(stateFrozen, "STATE_NOT_FROZEN");
        _;
    }

    modifier onlyActive() {
        require(!stateFrozen, "STATE_FROZEN");
        _;
    }

    mapping(address => bool) operators;

    // for conditional transfer
    mapping(bytes32 => bool) proofRegister;

    uint16 MAX_ASSETS_COUNT;
    
    bytes32 public newGlobalConfigHash;
    uint256 public newGlobalConfigValidBlockNum;
    function resetGlobalConfigValidBlockNum() internal {
        newGlobalConfigValidBlockNum = ~uint256(0);
    }
    function is_pending_global_config() internal view returns (bool) {
        return newGlobalConfigValidBlockNum != ~uint256(0);
    }

    // Mapping for timelocked actions.
    // A actionKey => activation time.
    mapping (bytes32 => uint256) actionsTimeLock;

    uint8 systemTokenDecimal;

    uint16 public MAX_NUMBER_ORACLES;
    uint32 TIMELOCK_GLOBAL_CONFIG_CHANGE;
    uint256 DEPOSIT_CANCEL_TIMELOCK;
    uint256 FORCED_ACTION_EXPIRE_TIME;

    uint32 public MIN_DAC_MEMBER;
    uint32 TIMELOCK_DAC_REG;
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



// Functions named bytesToX, except bytesToBytes20, where X is some type of size N < 32 (size of one word)
// implements the following algorithm:
// f(bytes memory input, uint offset) -> X out
// where byte representation of out is N bytes from input at the given offset
// 1) We compute memory location of the word W such that last N bytes of W is input[offset..offset+N]
// W_address = input + 32 (skip stored length of bytes) + offset - (32 - N) == input + offset + N
// 2) We load W from memory into out, last N bytes of W are placed into out

library Bytes {

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x2)
    function bytesToUInt16(bytes memory _bytes, uint256 _start) internal pure returns (uint16 r) {
        uint256 offset = _start + 0x2;
        require(_bytes.length >= offset, "T");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x3)
    function bytesToUInt24(bytes memory _bytes, uint256 _start) internal pure returns (uint24 r) {
        uint256 offset = _start + 0x3;
        require(_bytes.length >= offset, "U");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt32(bytes memory _bytes, uint256 _start) internal pure returns (uint32 r) {
        uint256 offset = _start + 0x4;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt64(bytes memory _bytes, uint256 _start) internal pure returns (uint64 r) {
        uint256 offset = _start + 0x8;
        require(_bytes.length >= offset, "V64");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128(bytes memory _bytes, uint256 _start) internal pure returns (uint128 r) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "W");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x14)
    function bytesToUInt160(bytes memory _bytes, uint256 _start) internal pure returns (uint160 r) {
        uint256 offset = _start + 0x14;
        require(_bytes.length >= offset, "X");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x20)
    function bytesToBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32 r) {
        uint256 offset = _start + 0x20;
        require(_bytes.length >= offset, "Y");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_offset + 2)
    function readUInt16(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint16 r) {
        new_offset = _offset + 2;
        r = bytesToUInt16(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 3)
    function readUInt24(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint24 r) {
        new_offset = _offset + 3;
        r = bytesToUInt24(_data, _offset);
    }

    function readUInt64(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint64 r) {
        new_offset = _offset + 8;
        r = bytesToUInt64(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readUInt160(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint160 r) {
        new_offset = _offset + 20;
        r = bytesToUInt160(_data, _offset);
    }

    // Convert bytes to ASCII hex representation
    function bytesToHexASCIIBytes(bytes memory _input) internal pure returns (bytes memory _output) {
        bytes memory outStringBytes = new bytes(_input.length * 2);

        // code in `assembly` construction is equivalent of the next code:
        // for (uint i = 0; i < _input.length; ++i) {
        //     outStringBytes[i*2] = halfByteToHex(_input[i] >> 4);
        //     outStringBytes[i*2+1] = halfByteToHex(_input[i] & 0x0f);
        // }
        assembly {
            let input_curr := add(_input, 0x20)
            let input_end := add(input_curr, mload(_input))

            for {
                let out_curr := add(outStringBytes, 0x20)
            } lt(input_curr, input_end) {
                input_curr := add(input_curr, 0x01)
                out_curr := add(out_curr, 0x02)
            } {
                let curr_input_byte := shr(0xf8, mload(input_curr))
            // here outStringByte from each half of input byte calculates by the next:
            //
            // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
            // outStringByte = byte (uint8 (0x66656463626139383736353433323130 >> (uint8 (_byteHalf) * 8)))
                mstore(
                out_curr,
                shl(0xf8, shr(mul(shr(0x04, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
                mstore(
                add(out_curr, 0x01),
                shl(0xf8, shr(mul(and(0x0f, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
            }
        }
        return outStringBytes;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
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
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
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

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



interface I_Verifier {

    function verifyAggregatedBlockProof(
        uint256[16] memory _subproofs_limbs,
        uint256[] memory _recursiveInput,
        uint256[] memory _proof,
        uint8[] memory _vkIndexes,
        uint256[] memory _individual_vks_inputs
    ) external view returns (bool);
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    /// @dev Address of lock flag variable.
    /// @dev Flag is placed at random memory location to not interfere with Storage contract.
    uint256 private constant LOCK_FLAG_ADDRESS = 0x8e94fed44239eb2314ab7a406345e6c5a8f0ccedf3b600de3d004e672c33abf4; // keccak256("ReentrancyGuard") - 1;

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/566a774222707e424896c0c390a84dc3c13bdcb2/contracts/security/ReentrancyGuard.sol
    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    function initializeReentrancyGuard() internal {
        uint256 lockSlotOldValue;

        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange every call to nonReentrant
        // will be cheaper.
        assembly {
            lockSlotOldValue := sload(LOCK_FLAG_ADDRESS)
            sstore(LOCK_FLAG_ADDRESS, _NOT_ENTERED)
        }

        // Check that storage slot for reentrancy guard is empty to rule out possibility of slot conflict
        require(lockSlotOldValue == 0, "1B");
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        uint256 _status;
        assembly {
            _status := sload(LOCK_FLAG_ADDRESS)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(_status == _NOT_ENTERED);

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(LOCK_FLAG_ADDRESS, _ENTERED)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(LOCK_FLAG_ADDRESS, _NOT_ENTERED)
        }
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./libs/Bytes.sol";

library Operations {
    /// @notice operation type
    enum OpType {
        Noop,    // 0
        Deposit,
        ForceTrade,
        ForceWithdraw,
        Withdraw,
        Trade,
        Transfer,
        ConditionalTransfer,
        FundingTick,
        OraclePriceTick,
        Liquidate,
        Deleverage
    }

    struct DepositOrWithdraw {
        uint24 accountId;
        uint160 l2Key;
        uint64 amount;
    }

    function readDepositOrWithdrawPubdata(bytes memory _data, uint256 offset) internal pure returns (DepositOrWithdraw memory parsed) {
        (offset, parsed.accountId) = Bytes.readUInt24(_data, offset);   // accountId
        (offset, parsed.l2Key) = Bytes.readUInt160(_data, offset);      // l2Key
        (offset, parsed.amount) = Bytes.readUInt64(_data, offset);      // amount
    }

    uint256 constant FORCED_WITHDRAWAL_PUBDATA_BYTES = 33;
    uint256 constant CONDITIONAL_TRANSFER_PUBDATA_BYTES = 54;
    uint32 constant DEPOSIT_WITHDRAW_PUBDATA_BYTES = 31 ;

    uint32 constant ACCOUNT_COLLATERAL_BALANCE_PUBDATA_BYTES = 11 ;
    uint32 constant ACCOUNT_POSITION_PUBDATA_BYTES = 13 ;

    uint8 constant OP_TYPE_BYTES = 1;

    // Withdraw pubdata
    struct Withdraw {
        uint8 opType;    // 0x04
        uint24 accountId;
        uint160 l2Key;
        uint64 amount;
    }

    // ForcedWithdrawal pubdata
    struct ForcedWithdrawal {
        uint8 opType;    // 0x03
        uint24 accountId;
        uint160 l2Key;
        uint64 amount;
        uint8 isSuccess;
    }

    /// Deserialize forcedWithdrawal pubdata
    function readForcedWithdrawalPubdata(bytes memory _data, uint256 offset) internal pure returns (ForcedWithdrawal memory parsed) {
        offset += OP_TYPE_BYTES;
        (offset, parsed.accountId) = Bytes.readUInt24(_data, offset);   // accountId
        (offset, parsed.l2Key) = Bytes.readUInt160(_data, offset);      // l2Key
        (offset, parsed.amount) = Bytes.readUInt64(_data, offset);      // amount
        parsed.isSuccess = uint8(_data[offset++]);
    }

    struct ConditionalTransfer {
        uint8 opType;    // 0x07
        uint24 fromAccountId;
        uint24 toAccountId;
        uint64 collateralAmount;
        uint64 fee;
        bytes31 condition;
    }

    function readConditionalTransferPubdata(bytes memory _data, uint256 offset) internal pure returns (ConditionalTransfer memory parsed) {
        offset += OP_TYPE_BYTES;
        (offset, parsed.fromAccountId) = Bytes.readUInt24(_data, offset);   // accountId
        (offset, parsed.toAccountId) = Bytes.readUInt24(_data, offset);   // accountId
        (offset, parsed.collateralAmount) = Bytes.readUInt64(_data, offset);      // amount
        (offset, parsed.fee) = Bytes.readUInt64(_data, offset);      // amount
        parsed.condition = bytes31(_data[offset++]);    // TODO : fix
    }


}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Governance Contract
abstract contract Governance {
    /// @notice Governor changed
    event NewGovernor(address newGovernor);
    event ValidatorStatusUpdate(address validatorAddress, bool isActive);

    address public networkGovernor;
    mapping(address => bool) public validators;

    function initGovernor(address governor, address validator) internal {
        networkGovernor = governor;
        validators[validator] = true;
    }

    modifier onlyGovernor() {
        require(msg.sender == networkGovernor, "require Governor");
        _;
    }

    /// @notice Change current governor
    /// @param _newGovernor Address of the new governor
    function changeGovernor(address _newGovernor) external onlyGovernor {
        if (networkGovernor != _newGovernor) {
            networkGovernor = _newGovernor;
            emit NewGovernor(_newGovernor);
        }
    }

    function setValidator(address _validator, bool _active) external onlyGovernor {
        if (validators[_validator] != _active) {
            validators[_validator] = _active;
            emit ValidatorStatusUpdate(_validator, _active);
        }
    }

    modifier onlyValidator() {
        require(validators[msg.sender] == true, "require Validator");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title configuration constants
contract Config {
    /// @dev Bit mask to apply for verifier public input before verifying.
    uint256 constant INPUT_MASK = (~uint256(0) >> 3);
}