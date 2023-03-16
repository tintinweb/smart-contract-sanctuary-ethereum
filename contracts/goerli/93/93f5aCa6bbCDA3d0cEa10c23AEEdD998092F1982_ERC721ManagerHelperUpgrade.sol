// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

import { ERC721ManagerAutoProxy } from '../eRC721Manager/ERC721ManagerAutoProxy.sol';
import { NonReentrant } from '../NonReentrant.sol';
import { StorageBaseExtension } from '../StorageBaseExtension.sol';
import { Pausable } from '../Pausable.sol';

import { ICollectionProxy_ManagerFunctions } from '../interfaces/ICollectionProxy_ManagerFunctions.sol';
import { IERC721ManagerHelperUpgrade } from './interfaces/IERC721ManagerHelperUpgrade.sol';
import { IERC721ManagerHelperProxy } from '../interfaces/IERC721ManagerHelperProxy.sol';
import { IERC721ManagerStorage } from '../eRC721Manager/IERC721ManagerStorage.sol';
import { ICollectionStorage } from '../interfaces/ICollectionStorage.sol';
import { IERC721Receiver } from '../interfaces/IERC721Receiver.sol';
import { IGovernedProxy } from '../interfaces/IGovernedProxy.sol';
import { IStorageBase } from '../interfaces/IStorageBase.sol';
import { IERC20 } from '../interfaces/IERC20.sol';

import { Address } from '../libraries/Address.sol';

pragma solidity 0.8.0;

contract ERC721ManagerHelperUpgrade is Pausable, NonReentrant, ERC721ManagerAutoProxy {
    using Address for address;

    IERC721ManagerStorage public eRC721ManagerStorage;
    address public weth;

    constructor(address _proxy, address _weth) ERC721ManagerAutoProxy(_proxy, address(0)) {
        // Re-using ERC721ManagerAutoProxy contract for proxy deployment
        weth = _weth;
    }

    modifier requireCollectionProxy() {
        require(
            address(eRC721ManagerStorage.getCollectionStorage(msg.sender)) != address(0),
            'ERC721ManagerHelper: FORBIDDEN, not a Collection proxy'
        );
        _;
    }

    /**
     * @dev Governance functions
     */
    // This function is called in order to upgrade to a new ERC721Manager implementation
    function destroy(address _newImpl) external requireProxy {
        IStorageBase(address(eRC721ManagerStorage)).setOwnerHelper(address(_newImpl));
        // Self destruct
        _destroy(_newImpl);
    }

    // This function will be called on the new implementation if necessary for the upgrade
    function migrate(address _oldImpl) external requireProxy {
        eRC721ManagerStorage = IERC721ManagerStorage(
            IERC721ManagerHelperUpgrade(address(_oldImpl)).eRC721ManagerStorage()
        );
        _migrate(_oldImpl);
    }

    /**
     * @dev safeMint function
     */
    function safeMint(
        address collectionProxy,
        address minter,
        address to,
        uint256 quantity,
        bool payWithWETH // If set to true, minting fee will be paid in WETH in case msg.value == 0, otherwise minting
    )
        external
        payable
        // fee will be paid in mintFeeERC20Asset
        noReentry
        requireCollectionProxy
        whenNotPaused
    {
        require(quantity > 0, 'ERC721ManagerHelper: mint at least one NFT');
        // Whitelist mint and public mint phases can be open at the same time.
        // First try to evaluate if the user met the conditions for a whitelist mint then check if the user met the conditions for a public mint.
        if (
            block.number > eRC721ManagerStorage.getBlockStartWhitelistPhase(collectionProxy) &&
            block.number < eRC721ManagerStorage.getBlockEndWhitelistPhase(collectionProxy) &&
            eRC721ManagerStorage.isWhitelisted(collectionProxy, minter) &&
            quantity <=
            (eRC721ManagerStorage.getMAX_WHITELIST_MINT_PER_ADDRESS(collectionProxy) -
                eRC721ManagerStorage.getWhitelistMintCount(collectionProxy, minter))
        ) {
            // Whitelist phase (whitelisted users can mint for free)
            require(
                msg.value == 0,
                'ERC721ManagerHelper: msg.value should be 0 for whitelist mint'
            );
            processSafeMint(collectionProxy, minter, to, quantity, false, false);
            // Update whitelistMintCount for minter
            eRC721ManagerStorage.setWhitelistMintCount(
                collectionProxy,
                minter,
                eRC721ManagerStorage.getWhitelistMintCount(collectionProxy, minter) + quantity
            );
        } else if (
            // If whitelist mint conditions are not met, default to public mint
            block.number > eRC721ManagerStorage.getBlockStartPublicPhase(collectionProxy) &&
            block.number < eRC721ManagerStorage.getBlockEndPublicPhase(collectionProxy)
        ) {
            // Public-sale phase (anyone can mint)
            require(
                quantity <=
                    eRC721ManagerStorage.getMAX_PUBLIC_MINT_PER_ADDRESS(collectionProxy) -
                        eRC721ManagerStorage.getPublicMintCount(collectionProxy, minter),
                'ERC721ManagerHelper: quantity exceeds address allowance'
            );
            processSafeMint(collectionProxy, minter, to, quantity, true, payWithWETH);
            // Update publicMintCount for minter
            eRC721ManagerStorage.setPublicMintCount(
                collectionProxy,
                minter,
                eRC721ManagerStorage.getPublicMintCount(collectionProxy, minter) + quantity
            );
        } else if (
            // If only whitelist mint is open, but the user did not meet the conditions, return an error message
            block.number > eRC721ManagerStorage.getBlockStartWhitelistPhase(collectionProxy) &&
            block.number < eRC721ManagerStorage.getBlockEndWhitelistPhase(collectionProxy)
        ) {
            require(
                eRC721ManagerStorage.isWhitelisted(collectionProxy, minter),
                'ERC721ManagerHelper: address not whitelisted'
            );
            require(
                quantity <=
                    (eRC721ManagerStorage.getMAX_WHITELIST_MINT_PER_ADDRESS(collectionProxy) -
                        eRC721ManagerStorage.getWhitelistMintCount(collectionProxy, minter)),
                'ERC721ManagerHelper: quantity exceeds address allowance'
            );
        } else {
            // If minting is not open, return an error message
            revert('ERC721ManagerHelper: minting is not open');
        }
    }

    /**
     * @dev Private functions (safeMint logic)
     */
    function processSafeMint(
        address collectionProxy,
        address minter,
        address to,
        uint256 quantity,
        bool publicPhase,
        bool payWithWETH
    ) private {
        ICollectionStorage collectionStorage = eRC721ManagerStorage.getCollectionStorage(
            collectionProxy
        );
        // Make sure mint won't exceed max supply
        uint256 _totalSupply = collectionStorage.getTotalSupply();
        require(
            _totalSupply + quantity <= eRC721ManagerStorage.getMAX_SUPPLY(collectionProxy),
            'ERC721ManagerHelper: purchase would exceed max supply'
        );
        if (publicPhase) {
            // Process mint fee payment for public mints
            processMintFee(collectionProxy, minter, quantity, payWithWETH);
        } else {
            // Emit MintFee event
            IERC721ManagerHelperProxy(proxy).emitMintFee(
                collectionProxy,
                minter,
                quantity,
                address(0), // mintFeeRecipient is set to address(0) for whitelist phase MintFee events
                address(0), // mintFeeAsset is set to address(0) for whitelist phase MintFee events
                0 // mintFee is set to 0 for whitelist phase MintFee events
            );
        }
        // Mint
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(collectionProxy, collectionStorage, minter, to, '');
        }
    }

    function processMintFee(
        address collectionProxy,
        address minter,
        uint256 quantity,
        bool payWithWETH
    ) private {
        if (msg.value > 0 || payWithWETH) {
            // If msg.value > 0 or payWithWETH == true, we attempt to process ETH/WETH mint fee payment
            // Calculate total ETH/WETH mint fee to mint quantity
            (
                uint256 totalMintFeeETH,
                uint256 lastETHMintFeeAboveThreshold,
                uint256 ethMintsCount
            ) = getTotalMintFeeETH(collectionProxy, quantity);
            // Record lastETHMintFeeAboveThreshold into collection storage
            if (lastETHMintFeeAboveThreshold > 0) {
                eRC721ManagerStorage.setLastETHMintFeeAboveThreshold(
                    collectionProxy,
                    lastETHMintFeeAboveThreshold
                );
            }
            // Update collection's eth mints count
            eRC721ManagerStorage.setETHMintsCount(collectionProxy, ethMintsCount + quantity);
            // Get mintFeeRecipient
            address mintFeeRecipient = eRC721ManagerStorage.getMintFeeRecipient();
            if (msg.value > 0) {
                // Attempt to process ETH mint fee payment
                // Transfer mint fee
                if (msg.value >= totalMintFeeETH) {
                    // Transfer totalMintFeeETH to mintFeeRecipient
                    (bool _success, bytes memory _data) = mintFeeRecipient.call{
                        value: totalMintFeeETH
                    }('');
                    require(
                        _success && (_data.length == 0 || abi.decode(_data, (bool))),
                        'ERC721ManagerHelper: failed to transfer ETH mint fee'
                    );
                    // Emit MintFee event
                    IERC721ManagerHelperProxy(proxy).emitMintFee(
                        collectionProxy,
                        minter,
                        quantity,
                        mintFeeRecipient,
                        address(0), // mintFeeAsset is set to address(0) when mint fee is paid with ETH
                        totalMintFeeETH
                    );
                } else {
                    revert('ERC721ManagerHelper: msg.value is too small to pay mint fee');
                }
                // Resend excess funds to user
                uint256 balance = address(this).balance;
                (bool success, bytes memory data) = minter.call{ value: balance }('');
                require(
                    success && (data.length == 0 || abi.decode(data, (bool))),
                    'ERC721ManagerHelper: failed to transfer excess ETH back to minter'
                );
            } else {
                // Attempt to process ERC20 mint fee payment using WETH
                IERC721ManagerHelperProxy(proxy).safeTransferERC20From(
                    weth,
                    minter,
                    mintFeeRecipient,
                    totalMintFeeETH
                );
                // Emit MintFee event
                IERC721ManagerHelperProxy(proxy).emitMintFee(
                    collectionProxy,
                    minter,
                    quantity,
                    mintFeeRecipient,
                    weth,
                    totalMintFeeETH
                );
            }
        } else {
            // While ethMintsCount < ethMintsCountThreshold, users can only mint one token per transaction
            uint256 ethMintsCount = eRC721ManagerStorage.getETHMintsCount(collectionProxy);
            uint256 ethMintsCountThreshold = eRC721ManagerStorage.getETHMintsCountThreshold(
                collectionProxy
            );
            if (ethMintsCount < ethMintsCountThreshold) {
                require(
                    quantity == 1,
                    'ERC721ManagerHelper: cannot mint more than one token per call'
                );
            }
            // Attempt to process ERC20 mint fee payment using mintFeeERC20Asset
            address mintFeeERC20AssetProxy = eRC721ManagerStorage.getMintFeeERC20AssetProxy(
                collectionProxy
            );
            uint256 mintFeeERC20 = eRC721ManagerStorage.getMintFeeERC20(collectionProxy) * quantity;
            // Burn mintFeeERC20Asset from minter
            IERC20(IGovernedProxy(payable(address(uint160(mintFeeERC20AssetProxy)))).impl()).burn(
                minter,
                mintFeeERC20
            );
            // Emit MintFee event
            IERC721ManagerHelperProxy(proxy).emitMintFee(
                collectionProxy,
                minter,
                quantity,
                address(0), // mintFeeRecipient is set to address(0) when mint fee is paid by burning mintFeeERC20 token
                mintFeeERC20AssetProxy,
                mintFeeERC20
            );
        }
    }

    function getTotalMintFeeETH(
        address collectionProxy,
        uint256 quantity
    )
        public
        view
        returns (
            uint256 totalMintFeeETH,
            uint256 lastETHMintFeeAboveThreshold,
            uint256 ethMintsCount
        )
    {
        ethMintsCount = eRC721ManagerStorage.getETHMintsCount(collectionProxy);
        uint256 ethMintsCountThreshold = eRC721ManagerStorage.getETHMintsCountThreshold(
            collectionProxy
        );
        if (ethMintsCount >= ethMintsCountThreshold) {
            (totalMintFeeETH, lastETHMintFeeAboveThreshold) = calculateOverThresholdMintFeeETH(
                collectionProxy,
                quantity
            );
        } else {
            // While ethMintsCount < ethMintsCountThreshold, users can only mint one token per transaction
            require(quantity == 1, 'ERC721ManagerHelper: cannot mint more than one token per call');
            uint256 baseMintFeeETH = eRC721ManagerStorage.getBaseMintFeeETH(collectionProxy);
            uint256 ethMintFeeIncreaseInterval = eRC721ManagerStorage.getETHMintFeeIncreaseInterval(
                collectionProxy
            );
            totalMintFeeETH = calculateSubThresholdMintFeeETH(
                baseMintFeeETH,
                ethMintFeeIncreaseInterval,
                ethMintsCount
            );
            lastETHMintFeeAboveThreshold = 0;
        }
    }

    function calculateSubThresholdMintFeeETH(
        uint256 baseMintFeeETH,
        uint256 ethMintFeeIncreaseInterval,
        uint256 ethMintsCount
    ) private pure returns (uint256 mintFeeETH) {
        // ETH minting starts at { baseMintFeeETH } and increases by { baseMintFeeETH * ethMintFeeIncreaseInterval }
        // every { ethMintFeeIncreaseInterval } ETH mint for the first { ethMintsCountThreshold } tokens minted with ETH
        if ((ethMintsCount + 1) < ethMintFeeIncreaseInterval) {
            mintFeeETH = baseMintFeeETH;
        } else {
            mintFeeETH =
                baseMintFeeETH *
                ethMintFeeIncreaseInterval *
                ((ethMintsCount + 1) / ethMintFeeIncreaseInterval);
        }
    }

    function calculateOverThresholdMintFeeETH(
        address collectionProxy,
        uint256 quantity
    ) private view returns (uint256 totalMintFeeETH, uint256 lastETHMintFeeAboveThreshold) {
        // After ethMintCountThreshold ETH mints, the ETH mint price will increase by ethMintFeeGrowthRateBps bps
        // for every mint
        uint256 ethMintFeeGrowthRateBps = eRC721ManagerStorage.getETHMintFeeGrowthRateBps(
            collectionProxy
        );
        uint256 feeDenominator = eRC721ManagerStorage.getFeeDenominator();
        totalMintFeeETH = 0;
        lastETHMintFeeAboveThreshold = eRC721ManagerStorage.getLastETHMintFeeAboveThreshold(
            collectionProxy
        );
        for (uint256 i = 1; i <= quantity; i++) {
            uint256 mintFeeETHAtIndex = (lastETHMintFeeAboveThreshold *
                (feeDenominator + ethMintFeeGrowthRateBps)) / feeDenominator;
            totalMintFeeETH = totalMintFeeETH + mintFeeETHAtIndex;
            lastETHMintFeeAboveThreshold = mintFeeETHAtIndex;
        }
    }

    function _safeMint(
        address collectionProxy,
        ICollectionStorage collectionStorage,
        address minter,
        address to,
        bytes memory _data
    ) private {
        uint256 tokenId = _mint(collectionProxy, collectionStorage, to);
        require(
            _checkOnERC721Received(minter, address(0), to, tokenId, _data),
            'ERC721ManagerHelper: transfer to non ERC721Receiver implementer'
        );
    }

    function _mint(
        address collectionProxy,
        ICollectionStorage collectionStorage,
        address to
    ) internal virtual returns (uint256) {
        require(to != address(0), 'ERC721ManagerHelper: mint to the zero address');
        // Calculate tokenId
        uint256 tokenId = collectionStorage.getTokenIdsCount() + 1;
        // Register tokenId
        collectionStorage.pushTokenId(tokenId);
        // Update totalSupply
        collectionStorage.setTotalSupply(collectionStorage.getTotalSupply() + 1);
        // Register tokenId ownership
        collectionStorage.pushTokenOfOwner(to, tokenId);
        collectionStorage.setOwner(tokenId, to);
        // Emit Transfer event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitTransfer(address(0), to, tokenId);

        return tokenId;
    }

    function _checkOnERC721Received(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msgSender, from, tokenId, _data) returns (
                bytes4 retval
            ) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721ManagerHelper: transfer to non ERC721Receiver implementer');
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Owner-restricted functions
     */
    function airdrop(
        address collectionProxy,
        address[] calldata recipients,
        uint256[] calldata numbers
    ) external onlyOwner {
        require(
            recipients.length == numbers.length,
            'ERC721ManagerHelper: recipients and numbers arrays must have the same length'
        );
        ICollectionStorage collectionStorage = eRC721ManagerStorage.getCollectionStorage(
            collectionProxy
        );
        for (uint256 j = 0; j < recipients.length; j++) {
            for (uint256 i = 0; i < numbers[j]; i++) {
                _safeMint(collectionProxy, collectionStorage, msg.sender, recipients[j], '');
            }
        }
    }

    function setManagerStorage(address _eRC721ManagerStorage) external onlyOwner {
        eRC721ManagerStorage = IERC721ManagerStorage(_eRC721ManagerStorage);
    }

    function setSporkProxy(address payable _sporkProxy) external onlyOwner {
        IERC721ManagerHelperProxy(proxy).setSporkProxy(_sporkProxy);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IERC721ManagerHelperUpgrade {
    function eRC721ManagerStorage() external view returns (address);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{ value: amount }('');
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
        return
            functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
        require(isContract(target), 'Address: delegate call to non-contract');

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

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

/**
 * Interface of UpgradeProposal
 */
interface IUpgradeProposal is IProposal {
    function implementation() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IStorageBase {
    function setOwner(address _newOwner) external;

    function setOwnerHelper(address _newOwnerHelper) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IProposal {
    function parent() external view returns (address);

    function created_block() external view returns (uint256);

    function deadline() external view returns (uint256);

    function fee_payer() external view returns (address payable);

    function fee_amount() external view returns (uint256);

    function accepted_weight() external view returns (uint256);

    function rejected_weight() external view returns (uint256);

    function total_weight() external view returns (uint256);

    function quorum_weight() external view returns (uint256);

    function isFinished() external view returns (bool);

    function isAccepted() external view returns (bool);

    function withdraw() external;

    function destroy() external;

    function collect() external;

    function voteAccept() external;

    function voteReject() external;

    function setFee() external payable;

    function canVote(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface IGovernedProxy {
    event UpgradeProposal(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    function spork_proxy() external view returns (address);

    function impl() external returns (address);

    function implementation() external view returns (IGovernedContract);

    function initialize(address _implementation) external;

    function proposeUpgrade(
        IGovernedContract _newImplementation,
        uint256 _period
    ) external payable returns (IUpgradeProposal);

    function upgrade(IUpgradeProposal _proposal) external;

    function upgradeProposalImpl(
        IUpgradeProposal _proposal
    ) external view returns (IGovernedContract newImplementation);

    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory);

    function collectUpgradeProposal(IUpgradeProposal _proposal) external;

    fallback() external;

    receive() external payable;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

/**
 * @dev ERC721 token receiver interface for any contract that wants to support safeTransfers from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IERC721ManagerHelperProxy {
    function setSporkProxy(address payable _sporkProxy) external;

    function safeTransferERC20From(address token, address from, address to, uint256 value) external;

    function emitMintFee(
        address collectionProxy,
        address minter,
        uint256 quantity,
        address mintFeeRecipient,
        address mintFeeAsset,
        uint256 mintFee
    ) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IERC20 {
    function burn(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface ICollectionStorage {
    // Getter functions
    //
    function getName() external view returns (string memory);

    function getSymbol() external view returns (string memory);

    function getBaseURI() external view returns (string memory);

    function getCollectionMoved() external view returns (bool);

    function getMovementNoticeURI() external view returns (string memory);

    function getTotalSupply() external view returns (uint256);

    function getTokenIdsCount() external view returns (uint256);

    function getTokenIdByIndex(uint256 _index) external view returns (uint256);

    function getOwner(uint256 tokenId) external view returns (address);

    function getBalance(address _address) external view returns (uint256);

    function getTokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);

    function getTokenApproval(uint256 _tokenId) external view returns (address);

    function getOperatorApproval(address _owner, address _operator) external view returns (bool);

    function getRoyaltyReceiver() external view returns (address);

    function getRoyaltyFraction() external view returns (uint96);

    function getRoyaltyInfo() external view returns (address, uint96);

    function getCollectionManagerProxyAddress() external view returns (address);

    function getCollectionManagerHelperProxyAddress() external view returns (address);

    // Setter functions
    //
    function setName(string calldata _name) external;

    function setSymbol(string calldata _symbol) external;

    function setBaseURI(string calldata _baseURI) external;

    function setCollectionMoved(bool _collectionMoved) external;

    function setMovementNoticeURI(string calldata _movementNoticeURI) external;

    function setTotalSupply(uint256 _value) external;

    function setTokenIdByIndex(uint256 _tokenId, uint256 _index) external;

    function pushTokenId(uint256 _tokenId) external;

    function popTokenId() external;

    function setOwner(uint256 tokenId, address owner) external;

    function setTokenOfOwnerByIndex(address _owner, uint256 _index, uint256 _tokenId) external;

    function pushTokenOfOwner(address _owner, uint256 _tokenId) external;

    function popTokenOfOwner(address _owner) external;

    function setTokenApproval(uint256 _tokenId, address _address) external;

    function setOperatorApproval(address _owner, address _operator, bool _approved) external;

    function setRoyaltyInfo(address receiver, uint96 fraction) external;

    function setCollectionManagerProxyAddress(address _collectionManagerProxyAddress) external;

    function setCollectionManagerHelperProxyAddress(
        address _collectionManagerHelperProxyAddress
    ) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface ICollectionProxy_ManagerFunctions {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    function emitTransfer(address from, address to, uint256 tokenId) external;

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    function emitApproval(address owner, address approved, uint256 tokenId) external;

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    function emitApprovalForAll(address owner, address operator, bool approved) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { ICollectionStorage } from '../interfaces/ICollectionStorage.sol';

interface IERC721ManagerStorage {
    // Getter functions
    //
    function getCollectionStorage(
        address collectionProxy
    ) external view returns (ICollectionStorage);

    function getCollectionProxy(uint256 index) external view returns (address);

    function getCollectionsCount() external view returns (uint256);

    function getMAX_SUPPLY(address collectionProxy) external view returns (uint256);

    function getMAX_WHITELIST_MINT_PER_ADDRESS(
        address collectionProxy
    ) external view returns (uint256);

    function getMAX_PUBLIC_MINT_PER_ADDRESS(
        address collectionProxy
    ) external view returns (uint256);

    function getBlockStartWhitelistPhase(address collectionProxy) external view returns (uint256);

    function getBlockEndWhitelistPhase(address collectionProxy) external view returns (uint256);

    function getBlockStartPublicPhase(address collectionProxy) external view returns (uint256);

    function getBlockEndPublicPhase(address collectionProxy) external view returns (uint256);

    function isWhitelisted(address collectionProxy, address _user) external view returns (bool);

    function getWhitelistIndex(
        address collectionProxy,
        address _user
    ) external view returns (uint256);

    function getWhitelistedUsersCount(address collectionProxy) external view returns (uint256);

    function getWhitelistedUserByIndex(
        address collectionProxy,
        uint256 _index
    ) external view returns (address _whitelistedUser);

    function getWhitelistMintCount(
        address collectionProxy,
        address _address
    ) external view returns (uint256);

    function getPublicMintCount(
        address collectionProxy,
        address _address
    ) external view returns (uint256);

    function getMintFeeERC20AssetProxy(address collectionProxy) external view returns (address);

    function getMintFeeERC20(address collectionProxy) external view returns (uint256);

    function getBaseMintFeeETH(address collectionProxy) external view returns (uint256);

    function getETHMintFeeIncreaseInterval(address collectionProxy) external view returns (uint256);

    function getETHMintFeeGrowthRateBps(address collectionProxy) external view returns (uint256);

    function getETHMintsCountThreshold(address collectionProxy) external view returns (uint256);

    function getETHMintsCount(address collectionProxy) external view returns (uint256);

    function getLastETHMintFeeAboveThreshold(
        address collectionProxy
    ) external view returns (uint256);

    function getMintFeeRecipient() external view returns (address _mintFeeRecipient);

    function getFeeDenominator() external view returns (uint96);

    // Setter functions
    //
    function setCollectionStorage(address collectionProxy, address _collectionStorage) external;

    function pushCollectionProxy(address collectionProxy) external;

    function popCollectionProxy() external;

    function setCollectionProxy(uint256 index, address collectionProxy) external;

    function setMAX_SUPPLY(address collectionProxy, uint256 _value) external;

    function setMAX_WHITELIST_MINT_PER_ADDRESS(address collectionProxy, uint256 _value) external;

    function setMAX_PUBLIC_MINT_PER_ADDRESS(address collectionProxy, uint256 _value) external;

    function setWhitelistPhase(
        address collectionProxy,
        uint256 _blockStartWhitelistPhase,
        uint256 _blockEndWhitelistPhase
    ) external;

    function setPublicPhase(
        address collectionProxy,
        uint256 _blockStartPublicPhase,
        uint256 _blockEndPublicPhase
    ) external;

    function setWhitelisted(address collectionProxy, address _user, bool _isWhitelisted) external;

    function setWhitelistMintCount(
        address collectionProxy,
        address _address,
        uint256 _amount
    ) external;

    function setPublicMintCount(
        address collectionProxy,
        address _address,
        uint256 _amount
    ) external;

    function setMintFeeERC20AssetProxy(
        address collectionProxy,
        address _mintFeeERC20AssetProxy
    ) external;

    function setMintFeeERC20(address collectionProxy, uint256 _mintFeeERC20) external;

    function setMintFeeETH(address collectionProxy, uint256[] memory _mintFeeETH) external;

    function setBaseMintFeeETH(address collectionProxy, uint256 _baseMintFeeETH) external;

    function setETHMintFeeIncreaseInterval(
        address collectionProxy,
        uint256 _ethMintFeeIncreaseInterval
    ) external;

    function setETHMintFeeGrowthRateBps(
        address collectionProxy,
        uint256 _ethMintFeeGrowthRateBps
    ) external;

    function setETHMintsCountThreshold(
        address collectionProxy,
        uint256 _ethMintsCountThreshold
    ) external;

    function setETHMintsCount(address collectionProxy, uint256 _ethMintsCount) external;

    function setLastETHMintFeeAboveThreshold(
        address collectionProxy,
        uint256 _lastETHMintFeeAboveThreshold
    ) external;

    function setMintFeeRecipient(address _mintFeeRecipient) external;

    function setFeeDenominator(uint96 value) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { GovernedContract } from '../GovernedContract.sol';
import { IGovernedProxy } from '../interfaces/IGovernedProxy.sol';

/**
 * ERC721ManagerAutoProxy is a version of GovernedContract which initializes its own proxy.
 * This is useful to avoid a circular dependency between GovernedContract and GovernedProxy
 * wherein they need each other's address in the constructor.
 */

contract ERC721ManagerAutoProxy is GovernedContract {
    constructor(address _proxy, address _implementation) GovernedContract(_proxy) {
        proxy = _proxy;
        IGovernedProxy(payable(proxy)).initialize(_implementation);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * This is an extension of the original StorageBase contract, allowing for a second ownerHelper address to access
 * owner-restricted functions
 */

contract StorageBaseExtension {
    address payable internal owner;
    address payable internal ownerHelper;

    modifier requireOwner() {
        require(
            msg.sender == address(owner) || msg.sender == address(ownerHelper),
            'StorageBase: Not owner or ownerHelper!'
        );
        _;
    }

    constructor(address _ownerHelper) {
        owner = payable(msg.sender);
        ownerHelper = payable(_ownerHelper);
    }

    function setOwner(address _newOwner) external requireOwner {
        owner = payable(_newOwner);
    }

    function setOwnerHelper(address _newOwnerHelper) external requireOwner {
        ownerHelper = payable(_newOwnerHelper);
    }

    function kill() external requireOwner {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { Context } from './Context.sol';
import { Ownable } from './Ownable.sol';

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Context, Ownable {
    /**
     * @dev Emitted when pause() is called.
     * @param account of contract owner issuing the event.
     * @param unpauseBlock block number when contract will be unpaused.
     */
    event Paused(address account, uint256 unpauseBlock);

    /**
     * @dev Emitted when pause is lifted by unpause() by
     * @param account.
     */
    event Unpaused(address account);

    /**
     * @dev state variable
     */
    uint256 public blockNumberWhenToUnpause = 0;

    /**
     * @dev Modifier to make a function callable only when the contract is not
     *      paused. It checks whether the current block number
     *      has already reached blockNumberWhenToUnpause.
     */
    modifier whenNotPaused() {
        require(
            block.number >= blockNumberWhenToUnpause,
            'Pausable: Revert - Code execution is still paused'
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(
            block.number < blockNumberWhenToUnpause,
            'Pausable: Revert - Code execution is not paused'
        );
        _;
    }

    /**
     * @dev Triggers or extends pause state.
     *
     * Requirements:
     *
     * - @param blocks needs to be greater than 0.
     */
    function pause(uint256 blocks) external onlyOwner {
        require(
            blocks > 0,
            'Pausable: Revert - Pause did not activate. Please enter a positive integer.'
        );
        blockNumberWhenToUnpause = block.number + blocks;
        emit Paused(_msgSender(), blockNumberWhenToUnpause);
    }

    /**
     * @dev Returns to normal code execution.
     */
    function unpause() external onlyOwner {
        blockNumberWhenToUnpause = block.number;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of 'user permissions'.
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: Not owner');
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: Zero address not allowed');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

/**
 * A little helper to protect contract from being re-entrant in state
 * modifying functions.
 */

contract NonReentrant {
    uint256 private entry_guard;

    modifier noReentry() {
        require(entry_guard == 0, 'NonReentrant: Reentry');
        entry_guard = 1;
        _;
        entry_guard = 0;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Genesis version of GovernedContract common base.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
contract GovernedContract {
    address public proxy;

    constructor(address _proxy) {
        proxy = _proxy;
    }

    modifier requireProxy() {
        require(msg.sender == proxy, 'Governed Contract: Not proxy');
        _;
    }

    function getProxy() internal view returns (address _proxy) {
        _proxy = proxy;
    }

    // solium-disable-next-line no-empty-blocks
    function _migrate(address) internal {}

    function _destroy(address _newImpl) internal {
        selfdestruct(payable(_newImpl));
    }

    function _callerAddress() internal view returns (address payable) {
        if (msg.sender == proxy) {
            // This is guarantee of the GovernedProxy
            // solium-disable-next-line security/no-tx-origin
            return payable(tx.origin);
        } else {
            return payable(msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _txOrigin() internal view returns (address payable) {
        return payable(tx.origin);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}