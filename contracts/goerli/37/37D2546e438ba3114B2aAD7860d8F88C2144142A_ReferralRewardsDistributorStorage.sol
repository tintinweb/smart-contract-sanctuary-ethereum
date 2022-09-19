// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

import { Pausable } from './Pausable.sol';
import { StorageBase } from './StorageBase.sol';
import { NonReentrant } from './NonReentrant.sol';
import { ReferralRewardsDistributorAutoProxy } from './ReferralRewardsDistributorAutoProxy.sol';

import { LibClaim } from './libraries/LibClaim.sol';

import { IStorageBase } from './interfaces/IStorageBase.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IReferralRewardsDistributor } from './interfaces/IReferralRewardsDistributor.sol';
import { IReferralRewardsDistributorStorage } from './interfaces/IReferralRewardsDistributorStorage.sol';
import { IReferralRewardsDistributorGovernedProxy } from './interfaces/IReferralRewardsDistributorGovernedProxy.sol';

contract ReferralRewardsDistributorStorage is StorageBase, IReferralRewardsDistributorStorage {
    address private operations;

    address private referralService;

    mapping(address => uint256) private lastClaimNonce;

    constructor(address _operations, address _referralService) public {
        operations = _operations;
        referralService = _referralService;
    }

    // Getter functions
    //
    function getOperations() external view returns (address) {
        return operations;
    }

    function getReferralService() external view returns (address) {
        return referralService;
    }

    function getLastClaimNonce(address _user) external view returns (uint256) {
        return lastClaimNonce[_user];
    }

    // Setter functions
    //
    function setOperations(address _operations) external requireOwner {
        operations = _operations;
    }

    function setReferralService(address _referralService) external requireOwner {
        referralService = _referralService;
    }

    function setLastClaimNonce(address _user, uint256 _lastClaimNonce) external requireOwner {
        lastClaimNonce[_user] = _lastClaimNonce;
    }
}

contract ReferralRewardsDistributor is
    NonReentrant,
    Pausable,
    ReferralRewardsDistributorAutoProxy,
    IReferralRewardsDistributor
{
    // Storage
    ReferralRewardsDistributorStorage public _storage;

    modifier onlyOwnerOrOperations() {
        require(
            msg.sender == owner || msg.sender == _storage.getOperations(),
            'ReferralRewardsDistributor: FORBIDDEN, not owner or operations'
        );
        _;
    }

    constructor(
        address _proxy,
        address _nftExchangeProxy,
        address payable _sporkProxy,
        address _operations,
        address _referralService
    )
        public
        ReferralRewardsDistributorAutoProxy(_proxy, _nftExchangeProxy, _sporkProxy, address(this))
    {
        _storage = new ReferralRewardsDistributorStorage(_operations, _referralService);
    }

    // Governance functions
    //
    // This function is called in order to upgrade to a new ReferralRewardsDistributor implementation
    function destroy(IGovernedContract _newImpl) external requireProxy {
        IStorageBase(address(_storage)).setOwner(address(_newImpl));
        // Self destruct
        _destroy(_newImpl);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    function withdrawETH(address _recipient, uint256 _amount) external onlyOwnerOrOperations {
        IReferralRewardsDistributorGovernedProxy(proxy).transfer(
            address(uint160(_recipient)),
            _amount
        );
    }

    function withdrawERC20(
        address _token,
        address _recipient,
        uint256 _amount
    ) external onlyOwnerOrOperations {
        IReferralRewardsDistributorGovernedProxy(proxy).transferERC20(_token, _recipient, _amount);
    }

    function claimRewards(
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata referralServiceSignature
    ) external whenNotPaused noReentry {
        // Get rewards recipient address
        address recipient = _callerAddress();
        // Make sure claim has not been processed yet
        require(
            lastClaimNonce == _storage.getLastClaimNonce(recipient),
            'ReferralRewardsDistributor: invalid lastClaimNonce value'
        );
        // Check that claimNonce > lastClaimNonce
        require(
            lastClaimNonce < claimNonce,
            'ReferralRewardsDistributor: claimNonce must be larger than lastClaimNonce'
        );
        // Validate referral Rewards claim
        LibClaim.validateClaim(
            recipient, // Referral rewards claim recipient address
            claimAmountReferral1, // Claim amount corresponding to first level of referral rewards
            claimAmountReferral2, // Claim amount corresponding to second level of referral rewards
            claimAmountReferral3, // Claim amount corresponding to third level of referral rewards
            lastClaimNonce, // Recipient's last claim nonce
            claimNonce, // Recipient's current claim nonce
            referralServiceSignature, // Referral rewards claim signature from Referral backend service
            proxy, // Verifying contract address
            _storage.getReferralService() // Referral backend service address
        );
        // Update recipient's last claim nonce to current claim nonce
        _storage.setLastClaimNonce(recipient, claimNonce);
        // Transfer claim amount to recipient
        transferRewardsClaim(
            recipient,
            claimAmountReferral1,
            claimAmountReferral2,
            claimAmountReferral3
        );
        // Emit ReferralRewardsClaimed event
        IReferralRewardsDistributorGovernedProxy(proxy).emitReferralRewardsClaimed(
            recipient,
            claimAmountReferral1,
            claimAmountReferral2,
            claimAmountReferral3,
            lastClaimNonce,
            claimNonce,
            referralServiceSignature
        );
    }

    function transferRewardsClaim(
        address recipient,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3
    ) private {
        // Calculate total claim amount
        uint256 totalClaimAmount = claimAmountReferral1.add(claimAmountReferral2).add(
            claimAmountReferral3
        );
        // Transfer total claim amount to recipient
        IReferralRewardsDistributorGovernedProxy(proxy).transfer(
            address(uint160(recipient)),
            totalClaimAmount
        );
    }

    // Setter functions

    function setSporkProxy(address _sporkProxy) external onlyOwner {
        IReferralRewardsDistributorGovernedProxy(proxy).setSporkProxy(
            address(uint160(_sporkProxy))
        );
    }

    function setNftExchangeProxy(address _newNftExchangeProxy) external onlyOwner {
        IReferralRewardsDistributorGovernedProxy(proxy).setNftExchangeProxy(_newNftExchangeProxy);
    }

    function setOperations(address _operations) external onlyOwner {
        _storage.setOperations(_operations);
    }

    function setReferralService(address _referralService) external onlyOwner {
        _storage.setReferralService(_referralService);
    }

    // Getter functions
    function getOperations() external view returns (address) {
        return _storage.getOperations();
    }

    function getReferralService() external view returns (address) {
        return _storage.getReferralService();
    }

    function getLastClaimNonce(address _user) external view returns (uint256) {
        return _storage.getLastClaimNonce(_user);
    }

    // Payable fallback function (forwards received ETH to proxy)
    function() external payable {
        // Transfer msg.value to proxy
        IReferralRewardsDistributorGovernedProxy(proxy).receiveEth.value(msg.value)();
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

library LibSignature {
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
        // Check the signature length
        if (signature.length != 65) {
            revert('LibSignature: invalid ECDSA signature length');
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            'LibSignature: invalid ECDSA signature `s` value'
        );

        // If the signature is valid (and not malleable), return the signer address
        // v > 30 is a special case, we need to adjust hash with '\x19Ethereum Signed Message:\n32'
        // and v = v - 4
        address signer;
        if (v > 30) {
            require(v - 4 == 27 || v - 4 == 28, 'LibSignature: invalid ECDSA signature `v` value');
            signer = ecrecover(toEthSignedMessageHash(hash), v - 4, r, s);
        } else {
            require(v == 27 || v == 28, 'LibSignature: invalid ECDSA signature `v` value');
            signer = ecrecover(hash, v, r, s);
        }

        require(signer != address(0), 'LibSignature: invalid ECDSA signature');

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

library LibEIP712 {
    // Calculates EIP712 encoding for a hash struct in this EIP712 Domain.
    // Note that we use the verifying contract's proxy address here instead of the verifying contract's address,
    // so that users signatures remain valid when we upgrade the ReferralRewardsDistributor contract
    function hashEIP712Message(bytes32 hashStruct, address verifyingContractProxy)
        internal
        pure
        returns (bytes32 result)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                ),
                keccak256(bytes('Energi')),
                keccak256(bytes('1')),
                chainId,
                verifyingContractProxy
            )
        );

        result = keccak256(abi.encodePacked('\x19\x01', eip712DomainHash, hashStruct));
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

import { LibEIP712 } from './LibEIP712.sol';
import { LibSignature } from './LibSignature.sol';

library LibClaim {
    bytes32 constant CLAIM_TYPEHASH =
        keccak256(
            'Claim(address recipient,uint256 claimAmountReferral1,uint256 claimAmountReferral2,uint256 claimAmountReferral3,uint256 lastClaimNonce,uint256 claimNonce)'
        );

    function hashClaim(
        address recipient,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        uint256 lastClaimNonce,
        uint256 claimNonce
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIM_TYPEHASH,
                    recipient,
                    claimAmountReferral1,
                    claimAmountReferral2,
                    claimAmountReferral3,
                    lastClaimNonce,
                    claimNonce
                )
            );
    }

    function validateClaim(
        address recipient,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes memory referralServiceSignature,
        address verifyingContractProxy,
        address referralService
    ) internal pure {
        // Generate EIP712 hashStruct of airdropClaim
        bytes32 hashStruct = hashClaim(
            recipient,
            claimAmountReferral1,
            claimAmountReferral2,
            claimAmountReferral3,
            lastClaimNonce,
            claimNonce
        );
        // Verify claim EIP712 hashStruct signature
        if (
            LibSignature.recover(
                LibEIP712.hashEIP712Message(hashStruct, verifyingContractProxy),
                referralServiceSignature
            ) != referralService
        ) {
            revert('LibClaim: EIP-712 referral service signature verification error');
        }
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

/**
 * Interface of UpgradeProposal
 */
contract IUpgradeProposal is IProposal {
    function impl() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

interface IStorageBase {
    function setOwner(address _newOwner) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface ISporkRegistry {
    function createUpgradeProposal(
        IGovernedContract _impl,
        uint256 _period,
        address payable _fee_payer
    ) external payable returns (IUpgradeProposal);

    function consensusGasLimits() external view returns (uint256 callGas, uint256 xferGas);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

interface IReferralRewardsDistributorStorage {
    // Getter functions
    //
    function getOperations() external view returns (address);

    function getReferralService() external view returns (address);

    function getLastClaimNonce(address _user) external view returns (uint256);

    // Setter functions
    //
    function setOperations(address _operations) external;

    function setReferralService(address _referralService) external;

    function setLastClaimNonce(address _user, uint256 _lastClaimNonce) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

interface IReferralRewardsDistributorGovernedProxy {
    event ReferralRewardsClaimed(
        address indexed recipient,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes referralServiceSignature
    );

    function setSporkProxy(address payable _sporkProxy) external;

    function setNftExchangeProxy(address _newNftExchangeProxy) external;

    function receiveEth() external payable;

    function transfer(address payable _recipient, uint256 _amount) external;

    function transferERC20(
        address _token,
        address _recipient,
        uint256 _amount
    ) external;

    function emitReferralRewardsClaimed(
        address recipient,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata referralServiceSignature
    ) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

interface IReferralRewardsDistributor {
    function withdrawETH(address _recipient, uint256 _amount) external;

    function withdrawERC20(
        address _token,
        address _recipient,
        uint256 _amount
    ) external;

    function claimRewards(
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata referralServiceSignature
    ) external;

    function setSporkProxy(address _sporkProxy) external;

    function setNftExchangeProxy(address _newNftExchangeProxy) external;

    function setOperations(address _operations) external;

    function setReferralService(address _referralService) external;

    // Getter functions
    function getOperations() external view returns (address);

    function getReferralService() external view returns (address);

    function getLastClaimNonce(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

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

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

/**
 * Genesis version of IGovernedProxy interface.
 *
 * Base Consensus interface for upgradable contracts proxy.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
interface IGovernedProxy {
    event UpgradeProposal(IGovernedContract indexed impl, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed impl, IUpgradeProposal proposal);

    function impl() external view returns (IGovernedContract);

    function spork_proxy() external view returns (IGovernedProxy);

    function proposeUpgrade(IGovernedContract _newImpl, uint256 _period)
        external
        payable
        returns (IUpgradeProposal);

    function upgrade(IUpgradeProposal _proposal) external;

    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract new_impl);

    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals);

    function collectUpgradeProposal(IUpgradeProposal _proposal) external;

    function() external payable;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

/**
 * Genesis version of GovernedContract interface.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);

    // It must check that the caller is the proxy
    // and copy all required data from the old address.
    function migrate(IGovernedContract _oldImpl) external;

    // It must check that the caller is the proxy
    // and self destruct to the new address.
    function destroy(IGovernedContract _newImpl) external;

    // function () external payable; // This line (from original Energi IGovernedContract) is commented because it
    // makes truffle migrations fail
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

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

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Base for contract storage (SC-14).
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

contract StorageBase {
    address payable internal owner;

    modifier requireOwner() {
        require(msg.sender == address(owner), 'StorageBase: Not owner!');
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(IGovernedContract _newOwner) external requireOwner {
        owner = address(uint160(address(_newOwner)));
    }

    function kill() external requireOwner {
        selfdestruct(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { NonReentrant } from './NonReentrant.sol';

import { IERC20 } from './interfaces/IERC20.sol';
import { IGovernedProxy } from './interfaces/IGovernedProxy.sol';
import { ISporkRegistry } from './interfaces/ISporkRegistry.sol';
import { IUpgradeProposal } from './interfaces/IUpgradeProposal.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract ReferralRewardsDistributorGovernedProxy is
    NonReentrant,
    IGovernedContract,
    IGovernedProxy
{
    modifier senderOrigin() {
        // Internal calls are expected to use impl directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        require(
            tx.origin == msg.sender,
            'ReferralRewardsDistributorGovernedProxy: Only direct calls are allowed!'
        );
        _;
    }

    modifier senderOriginOrNFTExchangeProxy() {
        // Internal calls are expected to use impl directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        require(
            tx.origin == msg.sender || msg.sender == nftExchangeProxy,
            'ReferralRewardsDistributorGovernedProxy: Only direct calls or calls from nftExchangeProxy are allowed!'
        );
        _;
    }

    modifier onlyImpl() {
        require(
            msg.sender == address(impl),
            'ReferralRewardsDistributorGovernedProxy: Only calls from impl are allowed!'
        );
        _;
    }
    address public nftExchangeProxy;
    IGovernedContract public impl;
    IGovernedProxy public spork_proxy;
    mapping(address => IGovernedContract) public upgrade_proposals;
    IUpgradeProposal[] public upgrade_proposal_list;

    event ReferralRewardsClaimed(
        address indexed recipient,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes referralServiceSignature
    );

    constructor(
        address _nftExchangeProxy,
        address payable _sporkProxy,
        address _impl
    ) public {
        nftExchangeProxy = _nftExchangeProxy;
        spork_proxy = IGovernedProxy(_sporkProxy);
        impl = IGovernedContract(_impl);
    }

    // only used for block explorers to detect contract as a proxy
    function implementation() external view returns (address) {
        return address(impl);
    }

    function setSporkProxy(address payable _sporkProxy) external onlyImpl {
        spork_proxy = IGovernedProxy(_sporkProxy);
    }

    function setNftExchangeProxy(address _newNftExchangeProxy) external onlyImpl {
        nftExchangeProxy = _newNftExchangeProxy;
    }

    // This function is called by implementation to transfer protocol fee
    function receiveEth() external payable noReentry {}

    function transfer(address payable _recipient, uint256 _amount) external noReentry onlyImpl {
        // Transfer amount to recipient
        // call is preferred over send/transfer (2,300 gas stipend) since the execution gas might increase for opcodes
        // making some fallback functions unable to execute in the future
        (bool success, bytes memory data) = _recipient.call.value(_amount)(new bytes(0));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'ReferralRewardsDistributorGovernedProxy: failed to transfer amount'
        );
    }

    function transferERC20(
        address _token,
        address _recipient,
        uint256 _amount
    ) external noReentry onlyImpl {
        IERC20(_token).transfer(_recipient, _amount);
    }

    function emitReferralRewardsClaimed(
        address recipient,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata referralServiceSignature
    ) external onlyImpl {
        emit ReferralRewardsClaimed(
            recipient,
            claimAmountReferral1,
            claimAmountReferral2,
            claimAmountReferral3,
            lastClaimNonce,
            claimNonce,
            referralServiceSignature
        );
    }

    /**
     * Pre-create a new contract first.
     * Then propose upgrade based on that.
     */
    function proposeUpgrade(IGovernedContract _newImpl, uint256 _period)
        external
        payable
        senderOrigin
        noReentry
        returns (IUpgradeProposal)
    {
        require(_newImpl != impl, 'ReferralRewardsDistributorGovernedProxy: Already active!');
        require(
            _newImpl.proxy() == address(this),
            'ReferralRewardsDistributorGovernedProxy: Wrong proxy!'
        );

        ISporkRegistry spork_reg = ISporkRegistry(address(spork_proxy.impl()));
        IUpgradeProposal proposal = spork_reg.createUpgradeProposal.value(msg.value)(
            _newImpl,
            _period,
            msg.sender
        );

        upgrade_proposals[address(proposal)] = _newImpl;
        upgrade_proposal_list.push(proposal);

        emit UpgradeProposal(_newImpl, proposal);

        return proposal;
    }

    /**
     * Once proposal is accepted, anyone can activate that.
     */
    function upgrade(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract new_impl = upgrade_proposals[address(_proposal)];
        require(new_impl != impl, 'ReferralRewardsDistributorGovernedProxy: Already active!');
        // in case it changes in the flight
        require(
            address(new_impl) != address(0),
            'ReferralRewardsDistributorGovernedProxy: Not registered!'
        );
        require(_proposal.isAccepted(), 'ReferralRewardsDistributorGovernedProxy: Not accepted!');

        IGovernedContract old_impl = impl;

        new_impl.migrate(old_impl);
        impl = new_impl;
        old_impl.destroy(new_impl);

        // SECURITY: prevent downgrade attack
        _cleanupProposal(_proposal);

        // Return fee ASAP
        _proposal.destroy();

        emit Upgraded(new_impl, _proposal);
    }

    /**
     * Map proposal to implementation
     */
    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract new_impl)
    {
        new_impl = upgrade_proposals[address(_proposal)];
    }

    /**
     * Lists all available upgrades
     */
    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals) {
        uint256 len = upgrade_proposal_list.length;
        proposals = new IUpgradeProposal[](len);

        for (uint256 i = 0; i < len; ++i) {
            proposals[i] = upgrade_proposal_list[i];
        }

        return proposals;
    }

    /**
     * Once proposal is reject, anyone can start collect procedure.
     */
    function collectUpgradeProposal(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract new_impl = upgrade_proposals[address(_proposal)];
        require(
            address(new_impl) != address(0),
            'ReferralRewardsDistributorGovernedProxy: Not registered!'
        );
        _proposal.collect();
        delete upgrade_proposals[address(_proposal)];

        _cleanupProposal(_proposal);
    }

    function _cleanupProposal(IUpgradeProposal _proposal) internal {
        delete upgrade_proposals[address(_proposal)];

        uint256 len = upgrade_proposal_list.length;
        for (uint256 i = 0; i < len; ++i) {
            if (upgrade_proposal_list[i] == _proposal) {
                upgrade_proposal_list[i] = upgrade_proposal_list[len - 1];
                upgrade_proposal_list.pop();
                break;
            }
        }
    }

    /**
     * Related to above
     */
    function proxy() external view returns (address) {
        return address(this);
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function migrate(IGovernedContract) external {
        revert('ReferralRewardsDistributorGovernedProxy: Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function destroy(IGovernedContract) external {
        revert('ReferralRewardsDistributorGovernedProxy: Good try');
    }

    /**
     * Proxy all other calls to implementation.
     */
    function() external payable senderOriginOrNFTExchangeProxy {
        // SECURITY: senderOrigin() modifier is mandatory
        IGovernedContract impl_m = impl;

        // A dummy delegatecall opcode in the fallback function is necessary for
        // block explorers to pick up the Energi proxy-implementation pattern
        if (false) {
            (bool success, bytes memory data) = address(0).delegatecall(
                abi.encodeWithSignature('')
            );
            require(
                success && !success && data.length == 0 && data.length != 0,
                'ReferralRewardsDistributorGovernedProxy: delegatecall cannot be used'
            );
        }

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)

            let res := call(sub(gas, 10000), impl_m, callvalue, ptr, calldatasize, 0, 0)
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize)

            switch res
            case 0 {
                revert(ptr, returndatasize)
            }
            default {
                return(ptr, returndatasize)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

import { GovernedContract } from './GovernedContract.sol';
import { ReferralRewardsDistributorGovernedProxy } from './ReferralRewardsDistributorGovernedProxy.sol';

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

contract ReferralRewardsDistributorAutoProxy is GovernedContract {
    constructor(
        address _proxy,
        address _nftExchangeProxy,
        address payable _sporkProxy,
        address _impl
    ) public GovernedContract(_proxy) {
        if (_proxy == address(0)) {
            _proxy = address(
                new ReferralRewardsDistributorGovernedProxy(_nftExchangeProxy, _sporkProxy, _impl)
            );
        }
        proxy = _proxy;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

import { Context } from './Context.sol';
import { Ownable } from './Ownable.sol';
import { SafeMath } from './libraries/SafeMath.sol';

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Context, Ownable {
    using SafeMath for uint256;

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
        blockNumberWhenToUnpause = block.number.add(blocks);
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

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

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
    constructor() public {
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

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

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

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

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
contract GovernedContract is IGovernedContract {
    address public proxy;

    constructor(address _proxy) public {
        proxy = _proxy;
    }

    modifier requireProxy() {
        require(msg.sender == proxy, 'Governed Contract: Not proxy');
        _;
    }

    function getProxy() internal view returns (address _proxy) {
        _proxy = proxy;
    }

    // Function overridden in child contract
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    // Function overridden in child contract
    function destroy(IGovernedContract _newImpl) external requireProxy {
        _destroy(_newImpl);
    }

    // solium-disable-next-line no-empty-blocks
    function _migrate(IGovernedContract) internal {}

    function _destroy(IGovernedContract _newImpl) internal {
        selfdestruct(address(uint160(address(_newImpl))));
    }

    function _callerAddress() internal view returns (address payable) {
        if (msg.sender == proxy) {
            // This is guarantee of the GovernedProxy
            // solium-disable-next-line security/no-tx-origin
            return tx.origin;
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.5.16;

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
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _txOrigin() internal view returns (address payable) {
        return tx.origin;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}