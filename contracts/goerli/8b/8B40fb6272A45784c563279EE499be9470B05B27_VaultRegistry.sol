//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";
import { Vault } from "./Vault.sol";

contract VaultRegistry {
    address kresusAdmin; // Contract maintainer
    address genesisVaultAddress;
    modifier onlyAdmin { assert(kresusAdmin == msg.sender); _;}

    event GenesisVaultDeployed(address genesisVaultAddress, address kresusAdminAddress);
    event CloneCreated(address newCloneAddress, address indexed owner);

    constructor() {
        kresusAdmin = msg.sender;
        deployGenesisVault(msg.sender);
    }

    function deployGenesisVault(address _admin) public {
        Vault deployedAddress = new Vault();
        genesisVaultAddress = address(deployedAddress);
        deployedAddress.initialize(_admin, address(this));
        emit GenesisVaultDeployed(genesisVaultAddress, msg.sender);
    }

    function createMinimalClone() public returns(address payable _cloneVaultAddress) {
        _cloneVaultAddress = payable(Clones.clone(genesisVaultAddress));
        Vault(_cloneVaultAddress).initialize(msg.sender,address(this));
        emit CloneCreated(_cloneVaultAddress, msg.sender);
    }

    function blockUserVault(address payable userVaultAddress) public onlyAdmin {
        Vault userVaultInstance = Vault(userVaultAddress);
        userVaultInstance.blockVault(userVaultAddress);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./EthDKG.sol";
import "./Registry.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Todo: contract would be an Upgradeable Proxy => https://docs.openzeppelin.com/learn/upgrading-smart-contracts#how-upgrades-work

contract Vault is ETHDKG {

    event EtherReceived(address from, uint amount);
    event GuardianAuthorization(address guardian, bool authorized);
    event CloneBlocked(address vault);
    // Todo: event Withdrawal(uint amount, address to);

    modifier onlyOwner { require(msg.sender == owner, "not vault owner"); _; }
    modifier onlyInit { require(initialized, "Contract instance has not been initialized"); _;}
    modifier notBlocked { require(!blocked, "This vault is blocked, request your guardians to unblock it"); _;}

    bool public blocked = false;
    bool public initialized = false;
    address private owner; // owner of the Vault
    address private registry;

    VaultRegistry public vr; // deployed instance of registry contract. Set when registry contract deploys new Vault
    
    constructor() ETHDKG() {}

    function initialize(address _owner, address _registry) public {
        require(!initialized, "Contract instance has already been initialized");
        owner = _owner;
        registry = _registry;
        initialized = true;
    }

    /**
       @dev Regsiter the vault owner in ethdkg contract
     */
    function registerOwner(uint256[2] memory _owner_public_key) onlyOwner public {
        require(initialized, "Contract instance has not been initialized");
        register(_owner_public_key);
        emit GuardianAuthorization(msg.sender, true);
    }

    // Todo: Assert the function caller is part of the participant list addresses before allowing registration
    function regsiterGuardian(uint256[2] memory _mpc_public_key) public {
        require(!blocked, "Vault blocked");
        require(initialized, "Contract instance has not been initialized");
        register(_mpc_public_key);
        emit GuardianAuthorization(msg.sender, true);
    }

    function blockVault(address selfAddress) external {
        require(msg.sender == registry, "Only registry contract can block vaults");
        require(selfAddress == address(this), "Cannot block other vaults");
        blocked = true;
        emit CloneBlocked(address(this));
    }

    // Todo: check mpc client was able to generate msk, by sending the signature as proof
    // signature is verifiable against the mpk
    // function withdrawEther(datatype? _msg, datatype? _sig) onlyOwner public {
    //  verified = verifyAggregatedSignature(_msg, _sig, master_public_key)
    //  require(verified, "invalid master public key") 
    //  ...
    // }

    receive() external payable onlyOwner {
        emit EtherReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;
/*
    Author: Philipp Schindler
    Source code and documentation available on Github: https://github.com/PhilippSchindler/ethdkg

    Copyright 2020 Philipp Schindler

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

contract ETHDKG {

    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// CRYPTOGRAPHIC CONSTANTS

    uint256 constant GROUP_ORDER   = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant FIELD_MODULUS = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // definition of two indepently selected generator for the groups G1 and G2 over
    // the bn128 elliptic curve
    // TODO: maybe swap generators G and H
    uint256 constant G1x  = 1;
    uint256 constant G1y  = 2;
    uint256 constant H1x  = 9727523064272218541460723335320998459488975639302513747055235660443850046724;
    uint256 constant H1y  = 5031696974169251245229961296941447383441169981934237515842977230762345915487;

    // For the generator H, we need an corresponding generator in the group G2.
    // Notice that generator H2 is actually given in its negated form,
    // because the bn128_pairing check in Solidty is different from the Python variant.
    uint256 constant H2xi = 14120302265976430476300156362541817133873389322564306174224598966336605751189;
    uint256 constant H2x  =  9110522554455888802745409460679507850660709404525090688071718755658817738702;
    uint256 constant H2yi = 337404400665185879215756363144893538418066400846800837504021992006027281794;
    uint256 constant H2y  = 13873181274231081108062283139528542484285035428387832848088103558524636808404;



    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// EVENTS

    // We could trigger an event for registration as well.
    // However the data must be stored by the contract anyway, we can query it directly from client.
    event ShareDistribution(
        address issuer,
        uint256[] encrypted_shares,
        uint256[2][] commitments
    );
    event Dispute(
        address issuer,
        address disputer,
        uint256[2] shared_key,
        uint256[2] shared_key_correctness_proof
    );
    event KeyShareSubmission(
        address issuer,
        uint256[2] key_share_G1,
        uint256[2] key_share_G1_correctness_proof,
        uint256[4] key_share_G2
    );
    event KeyShareRecovery(
        address recoverer,
        address[] recovered_nodes,
        uint256[2][] shared_keys,
        uint256[2][] shared_key_correctness_proofs
    );



    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// STORAGE

    // list of all registered account addresses
    address[] public addresses;

    // maps storing information required to perform in-contract validition for each registered node
    mapping (address => uint256[2]) public public_keys;
    mapping (address => bytes32) public share_distribution_hashes;
    mapping (address => uint256[2]) public commitments_1st_coefficient;
    mapping (address => uint256[2]) public key_shares;

    function num_nodes() public view returns(uint256)
    {
        return addresses.length;
    }

    // public output of the DKG protocol
    uint256[4] master_public_key;



    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// INITIALIZATION AND TIME_BOUNDS FOR PROTOCOL PHASES

    // block numbers of different points in time during the protcol execution
    // initialized at time of contract deployment
    uint256 public T_REGISTRATION_END;
    uint256 public T_SHARE_DISTRIBUTION_END;
    uint256 public T_DISPUTE_END;
    uint256 public T_KEY_SHARE_SUBMISSION_END;

    // number of blocks to ensure that a transaction with proper fees gets included in a block
    // needs to be appropriately set for the production system
    uint256 public constant DELTA_INCLUDE = 300;

    // number of confirmations to wait to ensure that a transaction cannot be reverted
    // needs to be appropriately set for the production system
    uint256 public constant DELTA_CONFIRM = 5;


    constructor() {
        uint256 T_CONTRACT_CREATION = block.number;
        T_REGISTRATION_END = T_CONTRACT_CREATION + DELTA_INCLUDE;
        T_SHARE_DISTRIBUTION_END = T_REGISTRATION_END + DELTA_CONFIRM + DELTA_INCLUDE;
        T_DISPUTE_END = T_SHARE_DISTRIBUTION_END + DELTA_CONFIRM + DELTA_INCLUDE;
        T_KEY_SHARE_SUBMISSION_END = T_DISPUTE_END + DELTA_CONFIRM + DELTA_INCLUDE;
    }



    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// MAIN CONTRACT FUNCTIONS

    function register(uint256[2] memory public_key)
    internal
    {
        require(
            block.number <= T_REGISTRATION_END,
            "registration failed (contract is not in registration phase)"
        );
        require(
            public_keys[msg.sender][0] == 0,
            "registration failed (account already registered a public key)"
        );
        require(
            bn128_is_on_curve(public_key),
            "registration failed (public key not on elliptic curve)"
        );

        addresses.push(msg.sender);
        public_keys[msg.sender] = public_key;
    }


    function distribute_shares(uint256[] memory encrypted_shares, uint256[2][] memory commitments)
    public
    {
        uint256 n = addresses.length;
        uint256 t = n / 2;
        if (n & 1 == 0) {
            t -= 1;
        }

        require(
            (T_REGISTRATION_END < block.number) && (block.number <= T_SHARE_DISTRIBUTION_END),
            "share distribution failed (contract is not in share distribution phase)"
        );
        require(
            public_keys[msg.sender][0] != 0,
            "share distribution failed (ethereum account has not registered)"
        );
        require(
            encrypted_shares.length == n - 1,
            "share distribution failed (invalid number of encrypted shares provided)"
        );
        require(
            commitments.length == t + 1,
            "key sharing failed (invalid number of commitments provided)"
        );
        for (uint256 k = 0; k <= t; k += 1) {
            require(
                bn128_is_on_curve(commitments[k]),
                "key sharing failed (commitment not on elliptic curve)"
            );
        }

        share_distribution_hashes[msg.sender] = keccak256(
            abi.encodePacked(encrypted_shares, commitments)
        );
        commitments_1st_coefficient[msg.sender] = commitments[0];

        emit ShareDistribution(msg.sender, encrypted_shares, commitments);
    }


    function submit_dispute(
        address issuer,
        uint256 issuer_list_idx,
        uint256 disputer_list_idx,
        uint256[] memory encrypted_shares,
        uint256[2][] memory commitments,
        uint256[2] memory shared_key,
        uint256[2] memory shared_key_correctness_proof
    )
    public
    {
        require(
            (T_SHARE_DISTRIBUTION_END < block.number) && (block.number <= T_DISPUTE_END),
            "dispute failed (contract is not in dispute phase)"
        );
        require(
            addresses[issuer_list_idx] == issuer &&
            addresses[disputer_list_idx] == msg.sender,
            "dispute failed (invalid list indices)"
        );

        // Check if a other node already submitted a dispute against the same issuer.
        // In this case the issuer is already disqualified and no further actions are required here.
        if (share_distribution_hashes[issuer] == 0) {
            return;
        }

        require(
            share_distribution_hashes[issuer] == keccak256(
                abi.encodePacked(encrypted_shares, commitments)
            ),
            "dispute failed (invalid replay of sharing transaction)"
        );
        require(
            dleq_verify(
                [G1x, G1y], public_keys[msg.sender], public_keys[issuer], shared_key, shared_key_correctness_proof
            ),
            "dispute failed (invalid shared key or proof)"
        );

        // Since all provided data is valid so far, we load the share and use the verified shared
        // key to decrypt the share for the disputer.
        uint256 share;
        uint256 disputer_idx = uint(uint160(msg.sender));
        if (disputer_list_idx < issuer_list_idx) {
            share = encrypted_shares[disputer_list_idx];
        }
        else {
            share = encrypted_shares[disputer_list_idx - 1];
        }
        uint256 decryption_key = uint256(keccak256(
            abi.encodePacked(shared_key[0], disputer_idx)
        ));
        share ^= decryption_key;

        // Verify the share for it's correctness using the polynomial defined by the commitments.
        // First, the polynomial (in group G1) is evaluated at the disputer's idx.
        uint256 x = disputer_idx;
        uint256[2] memory result = commitments[0];
        uint256[2] memory tmp = bn128_multiply([commitments[1][0], commitments[1][1], x]);
        result = bn128_add([result[0], result[1], tmp[0], tmp[1]]);
        for (uint256 j = 2; j < commitments.length; j += 1) {
            x = mulmod(x, disputer_idx, GROUP_ORDER);
            tmp = bn128_multiply([commitments[j][0], commitments[j][1], x]);
            result = bn128_add([result[0], result[1], tmp[0], tmp[1]]);
        }
        // Then the result is compared to the point in G1 corresponding to the decrypted share.
        tmp = bn128_multiply([G1x, G1y, share]);
        require(
            result[0] != tmp[0] || result[1] != tmp[1],
            "dispute failed (the provided share was valid)"
        );

        // We mark the nodes as disqualified by setting the distribution hash to 0. This way the
        // case of not proving shares at all and providing invalid shares can be handled equally.
        share_distribution_hashes[issuer] = 0;
        emit Dispute(issuer, msg.sender, shared_key, shared_key_correctness_proof);
    }


    function submit_key_share(
        address issuer,
        uint256[2] memory key_share_G1,
        uint256[2] memory key_share_G1_correctness_proof,
        uint256[4] memory key_share_G2
    )
    public
    {
        require(
            (T_DISPUTE_END < block.number),
            "key share submission failed (contract is not in key derivation phase)"
        );
        if (key_shares[issuer][0] != 0) {
            // already submitted, no need to resubmit
            return;
        }
        require(
            share_distribution_hashes[issuer] != 0,
            "key share submission failed (issuer not qualified)"
        );
        require(
            dleq_verify(
                [H1x, H1y],
                key_share_G1,
                [G1x, G1y],
                commitments_1st_coefficient[issuer],
                key_share_G1_correctness_proof
            ),
            "key share submission failed (invalid key share (G1))"
        );
        require(
            bn128_check_pairing([
                key_share_G1[0], key_share_G1[1],
                H2xi, H2x, H2yi, H2y,
                H1x, H1y,
                key_share_G2[0], key_share_G2[1], key_share_G2[2], key_share_G2[3]
            ]),
            "key share submission failed (invalid key share (G2))"
        );

        key_shares[issuer] = key_share_G1;
        emit KeyShareSubmission(issuer, key_share_G1, key_share_G1_correctness_proof, key_share_G2);
    }


    function recover_key_shares(
        address[] memory recovered_nodes,
        uint256[2][] memory shared_keys,
        uint256[2][] memory shared_key_correctness_proofs
    )
    public
    {
        // this function is only used as message broadcast channel
        // full checks are performed in the local client software
        require(
            (T_KEY_SHARE_SUBMISSION_END < block.number),
            "key share recovery failed (contract is not in key derivation phase)"
        );
        require(
            share_distribution_hashes[msg.sender] != 0,
            "key share recovery failed (recoverer not qualified)"
        );

        emit KeyShareRecovery(
            msg.sender,
            recovered_nodes,
            shared_keys,
            shared_key_correctness_proofs
        );
    }


    function submit_master_public_key(
        uint256[4] memory _master_public_key
    )
    public
    {
        require(
            (T_DISPUTE_END < block.number),
            "master key submission failed (contract is not in key derivation phase)"
        );
        if (master_public_key[0] != 0) {
            return;
        }

        uint256 n = addresses.length;

        // find first (i.e. lowest index) node contributing to the final key
        uint256 i = 0;
        address addr;

        do {
            addr = addresses[i];
            i += 1;
        } while(i < n && share_distribution_hashes[addr] == 0);

        uint256[2] memory tmp = key_shares[addr];
        require(tmp[0] != 0, 'master key submission failed (key share missing)');
        uint256[2] memory mpk_G1 = key_shares[addr];

        for (; i < n; i += 1) {
            addr = addresses[i];
            if (share_distribution_hashes[addr] == 0) {
                continue;
            }
            tmp = key_shares[addr];
            require(tmp[0] != 0, 'master key submission failed (key share missing)');
            mpk_G1 = bn128_add([mpk_G1[0], mpk_G1[1], tmp[0], tmp[1]]);
        }
        require(
            bn128_check_pairing([
                mpk_G1[0], mpk_G1[1],
                H2xi, H2x, H2yi, H2y,
                H1x, H1y,
                _master_public_key[0], _master_public_key[1],
                _master_public_key[2], _master_public_key[3]
            ]),
            'master key submission failed (pairing check failed)'
        );

        master_public_key = _master_public_key;
    }



    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// HELPER FUNCTIONS

    function dleq_verify(
        uint256[2] memory x1, uint256[2] memory y1,
        uint256[2] memory x2, uint256[2] memory y2,
        uint256[2] memory proof
    )
    private returns (bool proof_is_valid)
    {
        uint256[2] memory tmp1;
        uint256[2] memory tmp2;

        tmp1 = bn128_multiply([x1[0], x1[1], proof[1]]);
        tmp2 = bn128_multiply([y1[0], y1[1], proof[0]]);
        uint256[2] memory a1 = bn128_add([tmp1[0], tmp1[1], tmp2[0], tmp2[1]]);

        tmp1 = bn128_multiply([x2[0], x2[1], proof[1]]);
        tmp2 = bn128_multiply([y2[0], y2[1], proof[0]]);
        uint256[2] memory a2 = bn128_add([tmp1[0], tmp1[1], tmp2[0], tmp2[1]]);

        uint256 challenge = uint256(keccak256(abi.encodePacked(a1, a2, x1, y1, x2, y2)));
        proof_is_valid = challenge == proof[0];
    }


    function bn128_is_on_curve(uint256[2] memory point)
    private pure returns(bool)
    {
        // check if the provided point is on the bn128 curve (y**2 = x**3 + 3)
        return
            mulmod(point[1], point[1], FIELD_MODULUS) ==
            addmod(
                mulmod(
                    point[0],
                    mulmod(point[0], point[0], FIELD_MODULUS),
                    FIELD_MODULUS
                ),
                3,
                FIELD_MODULUS
            );
    }

    function bn128_add(uint256[4] memory input)
    public returns (uint256[2] memory result) {
        // computes P + Q
        // input: 4 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) x-coordinate of point Q
        //  *) y-coordinate of point Q

        bool success;
        assembly {
            // 0x06     id of precompiled bn256Add contract
            // 0        number of ether to transfer
            // 128      size of call parameters, i.e. 128 bytes total
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            success := call(not(0), 0x06, 0, input, 128, result, 64)
        }
        require(success, "elliptic curve addition failed");
    }

    function bn128_multiply(uint256[3] memory input)
    public returns (uint256[2] memory result) {
        // computes P*x
        // input: 3 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) scalar x

        bool success;
        assembly {
            // 0x07     id of precompiled bn256ScalarMul contract
            // 0        number of ether to transfer
            // 96       size of call parameters, i.e. 96 bytes total (256 bit for x, 256 bit for y, 256 bit for scalar)
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            success := call(not(0), 0x07, 0, input, 96, result, 64)
        }
        require(success, "elliptic curve multiplication failed");
    }

    function bn128_check_pairing(uint256[12] memory input)
    public returns (bool) {
        uint256[1] memory result;
        bool success;
        assembly {
            // 0x08     id of precompiled bn256Pairing contract     (checking the elliptic curve pairings)
            // 0        number of ether to transfer
            // 384       size of call parameters, i.e. 12*256 bits == 384 bytes
            // 32        size of result (one 32 byte boolean!)
            success := call(sub(gas(), 2000), 0x08, 0, input, 384, result, 32)
        }
        require(success, "elliptic curve pairing failed");
        return result[0] == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
interface IERC20Permit {
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