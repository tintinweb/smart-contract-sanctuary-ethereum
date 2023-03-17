// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { StorageBase } from './StorageBase.sol';
import { NonReentrant } from './NonReentrant.sol';
import { ERC20TokenAutoProxy } from './ERC20TokenAutoProxy.sol';

import { LibClaimAirdrop } from './libraries/LibClaimAirdrop.sol';

import { IERC20Token } from './interfaces/IERC20Token.sol';
import { IGovernedProxy } from './interfaces/IGovernedProxy.sol';
import { IERC20TokenStorage } from './interfaces/IERC20TokenStorage.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IERC20TokenGovernedProxy } from './interfaces/IERC20TokenGovernedProxy.sol';

contract ERC20TokenStorage is StorageBase, IERC20TokenStorage {
    string private name;

    string private symbol;

    uint8 private decimals;

    address private airdropService; // Signs ERC20 airdrop rewards claims

    address private eRC721ManagerProxy; // Can burn tokens

    // ERC20 airdrops lastClaimNonce mappings are stored by airdropId
    mapping(bytes4 => mapping(address => uint256)) private airdropLastClaimNonce;

    constructor(
        address _airdropService,
        address _eRC721ManagerProxy,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public {
        airdropService = _airdropService;
        eRC721ManagerProxy = _eRC721ManagerProxy;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function getName() external view returns (string memory _name) {
        _name = name;
    }

    function getSymbol() external view returns (string memory _symbol) {
        _symbol = symbol;
    }

    function getDecimals() external view returns (uint8 _decimals) {
        _decimals = decimals;
    }

    function getAirdropService() external view returns (address _airdropService) {
        _airdropService = airdropService;
    }

    function getERC721ManagerProxy() external view returns (address _eRC721ManagerProxy) {
        _eRC721ManagerProxy = eRC721ManagerProxy;
    }

    function getAirdropLastClaimNonce(bytes4 airdropId, address _user)
        external
        view
        returns (uint256 _lastClaimNonce)
    {
        _lastClaimNonce = airdropLastClaimNonce[airdropId][_user];
    }

    function setName(string calldata _name) external requireOwner {
        name = _name;
    }

    function setSymbol(string calldata _symbol) external requireOwner {
        symbol = _symbol;
    }

    function setDecimals(uint8 _decimals) external requireOwner {
        decimals = _decimals;
    }

    function setAirdropService(address _airdropService) external requireOwner {
        airdropService = _airdropService;
    }

    function setERC721ManagerProxy(address _eRC721ManagerProxy) external requireOwner {
        eRC721ManagerProxy = _eRC721ManagerProxy;
    }

    function setAirdropLastClaimNonce(
        bytes4 airdropId,
        address _user,
        uint256 _lastClaimNonce
    ) external requireOwner {
        airdropLastClaimNonce[airdropId][_user] = _lastClaimNonce;
    }
}

contract ERC20Token is NonReentrant, ERC20TokenAutoProxy, IERC20Token {
    // Data for migration
    //---------------------------------
    ERC20TokenStorage public eRC20TokenStorage;
    //---------------------------------

    modifier onlyERC20TokenOwner() {
        require(_callerAddress() == owner, 'ERC20Token: FORBIDDEN');
        _;
    }

    modifier onlyERC20TokenOwnerOrERC721Manager() {
        require(
            _callerAddress() == owner ||
                msg.sender ==
                address(
                    IGovernedProxy(address(uint160(eRC20TokenStorage.getERC721ManagerProxy())))
                        .impl()
                ),
            'ERC20Token: FORBIDDEN'
        );
        _;
    }

    constructor(
        address _proxy, // If set to address(0), ERC20TokenGovernedProxy will be deployed by ERC20TokenAutoProxy
        address _airdropService,
        address _eRC721ManagerProxy,
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20TokenAutoProxy(_proxy, this, _owner) {
        // Deploy ERC20 Token storage
        eRC20TokenStorage = new ERC20TokenStorage(
            _airdropService,
            _eRC721ManagerProxy,
            _name,
            _symbol,
            _decimals
        );
    }

    // Governance functions
    //
    // This function allows to set sporkProxy address after deployment in order to enable upgrades
    function setSporkProxy(address payable _sporkProxy) public onlyERC20TokenOwner {
        IERC20TokenGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // This function is called in order to upgrade to a new implementation
    function destroy(IGovernedContract _newImpl) external requireProxy {
        eRC20TokenStorage.setOwner(_newImpl);
        _destroyERC20(_newImpl);
        _destroy(_newImpl);
    }

    // This function would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrateERC20(address(_oldImpl));
        _migrate(_oldImpl);
    }

    // Getter functions
    //
    function name() external view returns (string memory _name) {
        _name = eRC20TokenStorage.getName();
    }

    function symbol() external view returns (string memory _symbol) {
        _symbol = eRC20TokenStorage.getSymbol();
    }

    function decimals() external view returns (uint8 _decimals) {
        _decimals = eRC20TokenStorage.getDecimals();
    }

    function getAirdropService() external view returns (address _airdropService) {
        _airdropService = eRC20TokenStorage.getAirdropService();
    }

    function getAirdropLastClaimNonce(bytes4 airdropId, address _user)
        external
        view
        returns (uint256 _lastClaimNonce)
    {
        _lastClaimNonce = eRC20TokenStorage.getAirdropLastClaimNonce(airdropId, _user);
    }

    // Setter functions
    //
    function setName(string calldata _name) external onlyERC20TokenOwner {
        eRC20TokenStorage.setName(_name);
    }

    function setSymbol(string calldata _symbol) external onlyERC20TokenOwner {
        eRC20TokenStorage.setSymbol(_symbol);
    }

    function setDecimals(uint8 _decimals) external onlyERC20TokenOwner {
        eRC20TokenStorage.setDecimals(_decimals);
    }

    function setAirdropService(address _airdropService) external onlyERC20TokenOwner {
        eRC20TokenStorage.setAirdropService(_airdropService);
    }

    function setERC721ManagerProxy(address _eRC721ManagerProxy) external onlyERC20TokenOwner {
        eRC20TokenStorage.setERC721ManagerProxy(_eRC721ManagerProxy);
    }

    // Mint/burn functions
    //
    function mint(address recipient, uint256 amount) external onlyERC20TokenOwner {
        _mint(recipient, amount);
        IERC20TokenGovernedProxy(proxy).emitTransfer(address(0x0), recipient, amount);
    }

    function burn(address account, uint256 amount) external onlyERC20TokenOwnerOrERC721Manager {
        _burn(account, amount);
        IERC20TokenGovernedProxy(proxy).emitTransfer(account, address(0x0), amount);
    }

    // ERC20 airdrop and airdrop referral rewards claim function
    function claimAirdrop(
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        bytes4 airdropId,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata airdropServiceSignature
    ) external noReentry {
        // Get rewards recipient address
        address recipient = _callerAddress();
        // Make sure claim has not been processed yet
        require(
            lastClaimNonce == eRC20TokenStorage.getAirdropLastClaimNonce(airdropId, recipient),
            'ERC20Token: invalid lastClaimNonce value'
        );
        // Check that claimNonce > lastClaimNonce
        require(
            lastClaimNonce < claimNonce,
            'ERC20Token: claimNonce must be larger than lastClaimNonce'
        );
        // Validate airdrop claim
        LibClaimAirdrop.validateClaim(
            recipient, // Referral rewards claim recipient address
            claimAmountAirdrop, // Claim amount corresponding to ERC20 airdrop
            claimAmountReferral1, // Claim amount corresponding to first level of ERC20 airdrop referral rewards
            claimAmountReferral2, // Claim amount corresponding to second level of ERC20 airdrop referral rewards
            claimAmountReferral3, // Claim amount corresponding to third level of ERC20 airdrop referral rewards
            airdropId, // Airdrop campaign Id
            lastClaimNonce, // Recipient's last claim nonce
            claimNonce, // Recipient's current claim nonce
            airdropServiceSignature, // Claim signature from ERC20 airdrop service
            proxy, // Verifying contract address
            eRC20TokenStorage.getAirdropService() // Airdrop service address
        );
        // Update recipient's last claim nonce to current claim nonce
        eRC20TokenStorage.setAirdropLastClaimNonce(airdropId, recipient, claimNonce);
        // Mint total claim amount to recipient
        mintAirdropClaim(
            recipient,
            claimAmountAirdrop,
            claimAmountReferral1,
            claimAmountReferral2,
            claimAmountReferral3
        );
        // Emit AirdropRewardsClaimed event
        IERC20TokenGovernedProxy(proxy).emitAirdropRewardsClaimed(
            recipient,
            claimAmountAirdrop,
            claimAmountReferral1,
            claimAmountReferral2,
            claimAmountReferral3,
            airdropId,
            lastClaimNonce,
            claimNonce,
            airdropServiceSignature
        );
    }

    function mintAirdropClaim(
        address recipient,
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3
    ) private {
        // Calculate total claim amount
        uint256 totalClaimAmount = claimAmountAirdrop
            .add(claimAmountReferral1)
            .add(claimAmountReferral2)
            .add(claimAmountReferral3);
        // Mint total claim amount to recipient
        _mint(recipient, totalClaimAmount);
        // Emit Transfer event
        IERC20TokenGovernedProxy(proxy).emitTransfer(address(0x0), recipient, totalClaimAmount);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

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

// Copyright 2023 Energi Core

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

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

library LibEIP712 {
    // Calculates EIP712 encoding for a hash struct in this EIP712 Domain.
    // Note that we use the verifying contract's proxy address here instead of the verifying contract's address,
    // so that users signatures remain valid when we upgrade the ERC20Token contract
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

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { LibEIP712 } from './LibEIP712.sol';
import { LibSignature } from './LibSignature.sol';

library LibClaimAirdrop {
    bytes32 constant AIRDROP_CLAIM_TYPEHASH =
        keccak256(
            'ERC20Claim(address recipient,uint256 claimAmountAirdrop,uint256 claimAmountReferral1,uint256 claimAmountReferral2,uint256 claimAmountReferral3,bytes4 airdropId,uint256 lastClaimNonce,uint256 claimNonce)'
        );

    function hashClaim(
        address recipient,
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        bytes4 airdropId,
        uint256 lastClaimNonce,
        uint256 claimNonce
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    AIRDROP_CLAIM_TYPEHASH,
                    recipient,
                    claimAmountAirdrop,
                    claimAmountReferral1,
                    claimAmountReferral2,
                    claimAmountReferral3,
                    airdropId,
                    lastClaimNonce,
                    claimNonce
                )
            );
    }

    function validateClaim(
        address recipient,
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        bytes4 airdropId,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes memory airdropServiceSignature,
        address verifyingContractProxy,
        address airdropService
    ) internal pure {
        // Generate EIP712 hashStruct of airdropClaim
        bytes32 hashStruct = hashClaim(
            recipient,
            claimAmountAirdrop,
            claimAmountReferral1,
            claimAmountReferral2,
            claimAmountReferral3,
            airdropId,
            lastClaimNonce,
            claimNonce
        );
        // Verify claim EIP712 hashStruct signature
        if (
            LibSignature.recover(
                LibEIP712.hashEIP712Message(hashStruct, verifyingContractProxy),
                airdropServiceSignature
            ) != airdropService
        ) {
            revert('LibClaimAirdrop: EIP-712 airdrop service signature verification error');
        }
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

contract IUpgradeProposal is IProposal {
    function impl() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

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

// Copyright 2023 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

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

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IOwnedERC20 {
    function owner() external view returns (address _owner);

    function setOwner(address _owner) external;

    function mint(address recipient, uint256 amount) external;

    function burn(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface IGovernedProxy {
    event UpgradeProposal(IGovernedContract indexed impl, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed impl, IUpgradeProposal proposal);

    function impl() external view returns (IGovernedContract);

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

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IGovernedERC20Storage {
    function setBalance(address _owner, uint256 _amount) external;

    function setAllowance(
        address _owner,
        address _spender,
        uint256 _amount
    ) external;

    function setTotalSupply(uint256 _amount) external;

    function getBalance(address _account) external view returns (uint256 balance);

    function getAllowance(address _owner, address _spender)
        external
        view
        returns (uint256 allowance);

    function getTotalSupply() external view returns (uint256 totalSupply);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IGovernedERC20 {
    function erc20Storage() external view returns (address _erc20Storage);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function increaseAllowance(
        address sender,
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function decreaseAllowance(
        address sender,
        address spender,
        uint256 subtractedValue
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

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

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IERC20TokenStorage {
    function getName() external view returns (string memory _name);

    function getSymbol() external view returns (string memory _symbol);

    function getDecimals() external view returns (uint8 _decimals);

    function getAirdropService() external view returns (address _airdropService);

    function getAirdropLastClaimNonce(bytes4 airdropId, address _user)
        external
        view
        returns (uint256 _lastClaimNonce);

    function getERC721ManagerProxy() external view returns (address _eRC721ManagerProxy);

    function setName(string calldata _name) external;

    function setSymbol(string calldata _symbol) external;

    function setDecimals(uint8 _decimals) external;

    function setAirdropService(address _airdropService) external;

    function setAirdropLastClaimNonce(
        bytes4 airdropId,
        address _user,
        uint256 _lastClaimNonce
    ) external;

    function setERC721ManagerProxy(address _eRC721ManagerProxy) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IERC20TokenGovernedProxy {
    event AirdropRewardsClaimed(
        address indexed recipient,
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        bytes4 airdropId,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes airdropServiceSignature
    );

    // ERC20 events
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setSporkProxy(address payable _sporkProxy) external;

    function emitAirdropRewardsClaimed(
        address recipient,
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        bytes4 airdropId,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata airdropServiceSignature
    ) external;

    function emitTransfer(
        address from,
        address to,
        uint256 value
    ) external;

    // ERC20 standard interface
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function decimals() external view returns (uint256 _decimals);

    function balanceOf(address account) external view returns (uint256 _balance);

    function allowance(address owner, address spender) external view returns (uint256 _allowance);

    function totalSupply() external view returns (uint256 _totalSupply);

    function approve(address spender, uint256 value) external returns (bool result);

    function transfer(address to, uint256 value) external returns (bool result);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool result);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool result);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool result);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IERC20Token {
    function eRC20TokenStorage() external view returns (address _eRC20TokenStorage);

    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function decimals() external view returns (uint8 _decimals);

    function getAirdropService() external view returns (address _airdropService);

    function getAirdropLastClaimNonce(bytes4 airdropId, address _user)
        external
        view
        returns (uint256 _lastClaimNonce);

    // Setter functions
    //
    function setName(string calldata _name) external;

    function setSymbol(string calldata _symbol) external;

    function setDecimals(uint8 _decimals) external;

    function setAirdropService(address _airdropService) external;

    function setERC721ManagerProxy(address _eRC721ManagerProxy) external;

    // Mint/burn functions
    //
    function mint(address recipient, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    // ERC20 airdrop and airdrop referral rewards claim function
    function claimAirdrop(
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        bytes4 airdropId,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata airdropServiceSignature
    ) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

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
        require(msg.sender == address(owner), 'Not owner!');
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

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

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

    constructor(address _owner) public Ownable(_owner) {}

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
    constructor(address _owner) public {
        owner = _owner;
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

pragma solidity 0.5.16;

/**
 * A little helper to protect contract from being re-entrant in state
 * modifying functions.
 */

contract NonReentrant {
    uint256 private entry_guard;

    modifier noReentry() {
        require(entry_guard == 0, 'Reentry');
        entry_guard = 1;
        _;
        entry_guard = 0;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { Pausable } from './Pausable.sol';
import { GovernedContract } from './GovernedContract.sol';
import { StorageBase } from './StorageBase.sol';
import { Context } from './Context.sol';

import { IGovernedERC20 } from './interfaces/IGovernedERC20.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IGovernedERC20Storage } from './interfaces/IGovernedERC20Storage.sol';
import { SafeMath } from './libraries/SafeMath.sol';

/**
 * Permanent storage of GovernedERC20 data.
 */

contract GovernedERC20Storage is StorageBase, IGovernedERC20Storage {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function setBalance(address _owner, uint256 _amount) external requireOwner {
        _balances[_owner] = _amount;
    }

    function setAllowance(
        address _owner,
        address _spender,
        uint256 _amount
    ) external requireOwner {
        _allowances[_owner][_spender] = _amount;
    }

    function setTotalSupply(uint256 _amount) external requireOwner {
        _totalSupply = _amount;
    }

    function getBalance(address _account) external view returns (uint256 balance) {
        balance = _balances[_account];
    }

    function getAllowance(address _owner, address _spender)
        external
        view
        returns (uint256 allowance)
    {
        allowance = _allowances[_owner][_spender];
    }

    function getTotalSupply() external view returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }
}

contract GovernedERC20 is Pausable, GovernedContract, IGovernedERC20 {
    using SafeMath for uint256;

    // Data for migration
    //---------------------------------
    GovernedERC20Storage public erc20Storage;

    //---------------------------------

    constructor(address _proxy, address _owner) public Pausable(_owner) GovernedContract(_proxy) {
        erc20Storage = new GovernedERC20Storage();
    }

    // IGovernedContract
    //---------------------------------
    // This function would be called by GovernedProxy on an old implementation to replace it with a new one
    function _destroyERC20(IGovernedContract _newImpl) internal {
        erc20Storage.setOwner(_newImpl);
    }

    //---------------------------------
    // This function would be called on the new implementation if necessary for the upgrade
    function _migrateERC20(address _oldImpl) internal {
        erc20Storage = GovernedERC20Storage(IGovernedERC20(_oldImpl).erc20Storage());
    }

    // ERC20
    //---------------------------------
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
        return erc20Storage.getTotalSupply();
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view returns (uint256) {
        return erc20Storage.getBalance(account);
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return erc20Storage.getAllowance(owner, spender);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address sender,
        address recipient,
        uint256 amount
    ) external requireProxy returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address owner,
        address spender,
        uint256 amount
    ) external requireProxy returns (bool) {
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external requireProxy returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 approveAmount = erc20Storage.getAllowance(sender, spender).sub(
            amount,
            'ERC20Token ERC20: transfer amount exceeds allowance'
        );
        _approve(sender, spender, approveAmount);
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
    function increaseAllowance(
        address owner,
        address spender,
        uint256 addedValue
    ) external requireProxy returns (bool) {
        uint256 approveAmount = erc20Storage.getAllowance(owner, spender).add(addedValue);
        _approve(owner, spender, approveAmount);
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
    function decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) external requireProxy returns (bool) {
        uint256 approveAmount = erc20Storage.getAllowance(owner, spender).sub(
            subtractedValue,
            'ERC20Token ERC20: decreased allowance below zero'
        );
        _approve(owner, spender, approveAmount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal whenNotPaused {
        require(sender != address(0), 'ERC20Token ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20Token ERC20: transfer to the zero address');

        erc20Storage.setBalance(
            sender,
            erc20Storage.getBalance(sender).sub(
                amount,
                'ERC20Token ERC20: transfer amount exceeds balance'
            )
        );
        erc20Storage.setBalance(recipient, erc20Storage.getBalance(recipient).add(amount));
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal whenNotPaused {
        require(account != address(0), 'ERC20Token ERC20: mint to the zero address');

        erc20Storage.setTotalSupply(erc20Storage.getTotalSupply().add(amount));
        erc20Storage.setBalance(account, erc20Storage.getBalance(account).add(amount));
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal whenNotPaused {
        require(account != address(0), 'ERC20Token ERC20: burn from the zero address');

        erc20Storage.setBalance(
            account,
            erc20Storage.getBalance(account).sub(
                amount,
                'ERC20Token ERC20: burn amount exceeds balance'
            )
        );
        erc20Storage.setTotalSupply(erc20Storage.getTotalSupply().sub(amount));
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    ) internal whenNotPaused {
        require(owner != address(0), 'ERC20Token ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20Token ERC20: approve to the zero address');

        erc20Storage.setAllowance(owner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

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

// Copyright 2023 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { NonReentrant } from './NonReentrant.sol';

import { SafeMath } from './libraries/SafeMath.sol';

import { IERC20TokenGovernedProxy } from './interfaces/IERC20TokenGovernedProxy.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IGovernedProxy } from './interfaces/IGovernedProxy.sol';
import { IUpgradeProposal } from './interfaces/IUpgradeProposal.sol';
import { ISporkRegistry } from './interfaces/ISporkRegistry.sol';
import { IGovernedERC20 } from './interfaces/IGovernedERC20.sol';
import { IOwnedERC20 } from './interfaces/IOwnedERC20.sol';
import { IERC20Token } from './interfaces/IERC20Token.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract ERC20TokenGovernedProxy is IERC20TokenGovernedProxy, IGovernedProxy, NonReentrant {
    using SafeMath for uint256;

    IGovernedContract public impl;
    IGovernedContract public implementation; // only used for block explorers to detect contract as a proxy

    IGovernedProxy public spork_proxy;

    mapping(address => IGovernedContract) public upgrade_proposals;

    IUpgradeProposal[] public upgrade_proposal_list;

    modifier senderOrigin() {
        // Internal calls are expected to use impl directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(tx.origin == msg.sender, 'Only direct calls are allowed!');
        _;
    }

    modifier onlyImpl() {
        require(msg.sender == address(impl), 'Only calls from impl are allowed!');
        _;
    }

    constructor(IGovernedContract _impl) public {
        impl = _impl;
        implementation = _impl; // to allow block explorers to find the impl contract
    }

    function setSporkProxy(address payable _sporkProxy) external onlyImpl {
        spork_proxy = IGovernedProxy(_sporkProxy);
    }

    function emitAirdropRewardsClaimed(
        address recipient,
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        bytes4 airdropId,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata airdropServiceSignature
    ) external onlyImpl {
        emit AirdropRewardsClaimed(
            recipient,
            claimAmountAirdrop,
            claimAmountReferral1,
            claimAmountReferral2,
            claimAmountReferral3,
            airdropId,
            lastClaimNonce,
            claimNonce,
            airdropServiceSignature
        );
    }

    function emitTransfer(
        address from,
        address to,
        uint256 value
    ) external onlyImpl {
        emit Transfer(from, to, value);
    }

    function emitApproval(
        address owner,
        address spender,
        uint256 value
    ) external onlyImpl {
        emit Approval(owner, spender, value);
    }

    // ERC20 standard functions
    //
    function name() external view returns (string memory _name) {
        _name = IERC20Token(address(uint160(address(impl)))).name();
    }

    function symbol() external view returns (string memory _symbol) {
        _symbol = IERC20Token(address(uint160(address(impl)))).symbol();
    }

    function decimals() external view returns (uint256 _decimals) {
        _decimals = IERC20Token(address(uint160(address(impl)))).decimals();
    }

    function balanceOf(address account) external view returns (uint256 _balance) {
        _balance = IGovernedERC20(address(uint160(address(impl)))).balanceOf(account);
    }

    function allowance(address owner, address spender) external view returns (uint256 _allowance) {
        _allowance = IGovernedERC20(address(uint160(address(impl)))).allowance(owner, spender);
    }

    function totalSupply() external view returns (uint256 _totalSupply) {
        _totalSupply = IGovernedERC20(address(uint160(address(impl)))).totalSupply();
    }

    function approve(address spender, uint256 value) external returns (bool result) {
        result = IGovernedERC20(address(uint160(address(impl)))).approve(
            msg.sender,
            spender,
            value
        );
        emit Approval(msg.sender, spender, value);
    }

    function transfer(address to, uint256 value) external returns (bool result) {
        result = IGovernedERC20(address(uint160(address(impl)))).transfer(msg.sender, to, value);
        emit Transfer(msg.sender, to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool result) {
        result = IGovernedERC20(address(uint160(address(impl)))).transferFrom(
            msg.sender,
            from,
            to,
            value
        );
        emit Transfer(from, to, value);
        uint256 newApproveAmount = IGovernedERC20(address(uint160(address(impl)))).allowance(
            from,
            msg.sender
        );
        emit Approval(from, msg.sender, newApproveAmount);
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool result) {
        result = IGovernedERC20(address(uint160(address(impl)))).increaseAllowance(
            msg.sender,
            spender,
            addedValue
        );
        uint256 newApproveAmount = IGovernedERC20(address(uint160(address(impl)))).allowance(
            msg.sender,
            spender
        );
        emit Approval(msg.sender, spender, newApproveAmount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool result)
    {
        result = IGovernedERC20(address(uint160(address(impl)))).decreaseAllowance(
            msg.sender,
            spender,
            subtractedValue
        );
        uint256 newApproveAmount = IGovernedERC20(address(uint160(address(impl)))).allowance(
            msg.sender,
            spender
        );
        emit Approval(msg.sender, spender, newApproveAmount);
    }

    // OwnedERC20 functions
    //
    function mint(address recipient, uint256 amount) external {
        IOwnedERC20(address(uint160(address(impl)))).mint(recipient, amount);
    }

    function burn(address recipient, uint256 amount) external {
        IOwnedERC20(address(uint160(address(impl)))).burn(recipient, amount);
    }

    // Governance functions
    //
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
        require(_newImpl != impl, 'Already active!');
        require(_newImpl.proxy() == address(this), 'Wrong proxy!');

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
        require(new_impl != impl, 'Already active!'); // in case it changes in the flight
        require(address(new_impl) != address(0), 'Not registered!');
        require(_proposal.isAccepted(), 'Not accepted!');

        IGovernedContract old_impl = impl;

        new_impl.migrate(old_impl);
        impl = new_impl;
        implementation = new_impl;
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
        require(address(new_impl) != address(0), 'Not registered!');
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
    function transferFrom(
        address,
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function increaseAllowance(
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function decreaseAllowance(
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function transfer(
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function approve(
        address,
        address,
        uint256
    ) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function migrate(IGovernedContract) external pure {
        revert('Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function destroy(IGovernedContract) external pure {
        revert('Good try');
    }

    /**
     * Proxy all other calls to implementation.
     */
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory

        // A dummy delegatecall opcode in the fallback function is necessary for
        // block explorers to pick up the Energi proxy-implementation pattern
        if (false) {
            (bool success, bytes memory data) = address(0).delegatecall(
                abi.encodeWithSignature('')
            );
            require(
                success && !success && data.length == 0 && data.length != 0,
                'ERC20TokenGovernedProxy: delegatecall cannot be used'
            );
        }

        IGovernedContract impl_m = impl;

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

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { GovernedERC20 } from './GovernedERC20.sol';
import { ERC20TokenGovernedProxy } from './ERC20TokenGovernedProxy.sol';

contract ERC20TokenAutoProxy is GovernedERC20 {
    constructor(
        address _proxy,
        IGovernedContract _impl,
        address _owner
    ) public GovernedERC20(_proxy, _owner) {
        if (_proxy == address(0)) {
            _proxy = address(new ERC20TokenGovernedProxy(_impl));
        }
        proxy = _proxy;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

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