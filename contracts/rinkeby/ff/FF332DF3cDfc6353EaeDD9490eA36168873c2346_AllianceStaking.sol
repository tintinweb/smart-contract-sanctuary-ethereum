//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./LibLazyStaking.sol";
import "./Managable.sol";
import "./IAllianceChecker.sol";

contract AllianceStaking is Managable, Pausable {
    using ECDSA for bytes32;

    struct Stake {
        uint256 allianceId;
        uint256 amount;
        address payer;
        address owner;
    }

    // Options
    uint256 public pricePerSeat;
    uint256 public pricePerCreation;
    uint32 public allianceMaxSeats;
    bytes32 private domainSeparator;
    address public tokenAddress;
    address public allianceCheckerAddress;
    address public signerAddress;

    // Storage - Stakes
    mapping(uint256 => address) public allianceOwners;
    mapping(uint256 => address[]) public allianceMembers;
    mapping(address => Stake) public addressStakings;

    // Events
    event ChangedPricePerSeat(uint256 _price);
    event ChangedPricePerCreation(uint256 _price);
    event ChangedTokenAddress(address _token);
    event ChangedAllianceMaxSeats(uint32 _maxSeats);
    event ChangedAllianceCheckerAddress(address _allianceChecker);
    event ChangedSignerAddress(address _signer);

    event CreatedAlliance(address indexed _owner, uint256 indexed _allianceId, uint256 indexed _serialId);
    event DestroyedAlliance(uint256 indexed _allianceId);
    event LeavedAlliance(uint256 indexed _allianceId, address indexed _addr);
    event JoinedAlliance(uint256 indexed _allianceId, address indexed _addr, address _staker);

    event Transfer(uint256 indexed _allianceId, address indexed _from, address indexed _to);

    constructor(
        uint256 _pricePerSeat,
        uint256 _pricePerCreation,
        address _token,
        uint32 _allianceMaxSeats,
        address _allianceChecker,
        address _signerAddress,
        string memory _appName,
        string memory _version           
    ) {        
        _setPricePerSeat(_pricePerSeat);
        _setPricePerCreation(_pricePerCreation);
        _setTokenAddress(_token);
        _setSignerAddress(_signerAddress);
        _setAllianceMaxSeats(_allianceMaxSeats);
        _setAllianceCheckerAddress(_allianceChecker);

        _addManager(msg.sender);

        domainSeparator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(_appName)),
            keccak256(bytes(_version)),
            block.chainid,
            address(this)
        ));                
    }

    function setPricePerSeat(uint256 _price) external onlyManager {
        _setPricePerSeat(_price);
    }

    function setPricePerCreation(uint256 _price) external onlyManager {
        _setPricePerCreation(_price);
    }

    function setTokenAddress(address _token) external onlyManager {
        _setTokenAddress(_token);
    }

    function setAllianceMaxSeats(uint32 _maxSeats) external onlyManager {
        _setAllianceMaxSeats(_maxSeats);
    }

    function setAllianceCheckerAddress(address _allianceChecker) external onlyManager {
        _setAllianceCheckerAddress(_allianceChecker);
    }

    function setSignerAddress(address _signerAddress) external onlyManager {
        _setSignerAddress(_signerAddress);
    } 

    function togglePause() external onlyManager {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }   

    //
    // Helpers functions
    // 
    function getMembers(uint256 _allianceId) public view returns(address[] memory) {
        return allianceMembers[_allianceId];
    }

    function ownerOf(uint256 _allianceId) public view returns(address) {
        return allianceOwners[_allianceId];
    }

    function stakesByAlliance(uint256 _allianceId) public view returns(Stake[] memory) {
        uint256 _len = allianceMembers[_allianceId].length;
        Stake[] memory _stakes = new Stake[](_len);
        for(uint256 i = 0; i < _len; i++) {
            address _addr = allianceMembers[_allianceId][i];
            _stakes[i] = addressStakings[_addr];
        }

        return _stakes;
    }

    //
    // Working functions
    //
    function createAlliance(LibLazyStaking.Stake calldata _data, bytes calldata _signature) external whenNotPaused returns(uint256) {
        address _sender = msg.sender;

        require(verifyTypedDataHash(domainSeparator, _data, _signature, signerAddress), "bad sig");
        require(allianceOwners[_data.id] == address(0), "alliance exists");
        require(_data.owner == _sender, "address missmatch");
        require(addressStakings[_sender].amount == 0, "you have stake");

        uint256 _price = pricePerCreation;
        require(IERC20(tokenAddress).transferFrom(_sender, address(this), _price), "can't transfer tokens");
        
        Stake memory _stake = Stake({
            payer: _sender,
            owner: _sender,
            allianceId: _data.id,
            amount: _price
        });

        addressStakings[_sender] = _stake;
        allianceMembers[_stake.allianceId].push(_sender);
        allianceOwners[_stake.allianceId] = _sender;

        emit CreatedAlliance(_sender, _stake.allianceId, _stake.allianceId);

        return _stake.allianceId;
    }

    function removeMember(uint256 _allianceId, address _member) external whenNotPaused onlyAllianceOwner(_allianceId) {
        address _sender = msg.sender;
        require(_sender != _member, "removing self");

        Stake memory _stake = addressStakings[_member];
        require(_stake.allianceId == _allianceId, "not a member");
        delete(addressStakings[_member]);
        removeAllianceMember(_allianceId, _member);

        require(IERC20(tokenAddress).transfer(_stake.payer, _stake.amount), "transfer failed");
        emit LeavedAlliance(_allianceId, _member);
    }

    function destroyAlliance(uint256 _allianceId) external whenNotPaused onlyAllianceOwner(_allianceId) {
        address _sender = msg.sender;

        require(allianceMembers[_allianceId].length <= 1, "alliance with members");
        require(IAllianceChecker(allianceCheckerAddress).canDisband(_allianceId), "alliance can't be destroyed");

        Stake memory _stake = addressStakings[_sender];
        delete(addressStakings[_sender]);
        delete(allianceMembers[_allianceId]);
        delete(allianceOwners[_allianceId]);

        if (_stake.amount > 0) {
            require(IERC20(tokenAddress).transfer(_sender, _stake.amount), "transfer failed");
        }

        emit DestroyedAlliance(_allianceId);
    }

    function createStake(uint256 _allianceId, address _owner) external whenNotPaused {
        address _sender = msg.sender;
        Stake memory _stake = addressStakings[_owner];
        require(_stake.amount == 0, "already staked");

        if (_owner != _sender) {
            require(allianceOwners[_allianceId] == _sender, "not alliance owner");
        }

        require(allianceMembers[_allianceId].length < allianceMaxSeats, "max capacity");

        Stake memory _newStake = Stake({
            payer: _sender,
            owner: _owner,
            allianceId: _allianceId,
            amount: pricePerSeat
        });

        require(IERC20(tokenAddress).transferFrom(_sender, address(this), _newStake.amount), "transfer failed");
        addressStakings[_owner] = _newStake;
        allianceMembers[_allianceId].push(_owner);

        emit JoinedAlliance(_allianceId, _owner, _sender);
    }

    function removeStake() external whenNotPaused {
        address _sender = msg.sender;
        Stake memory _stake = addressStakings[_sender];

        require(_stake.owner == _sender, "not in alliance");
        require(allianceOwners[_stake.allianceId] != _sender, "called by owner");

        delete(addressStakings[_sender]);
        require(IERC20(tokenAddress).transfer(_stake.payer, _stake.amount), "transfer failed");

        removeAllianceMember(_stake.allianceId, _sender);
        emit LeavedAlliance(_stake.allianceId, _sender);
    }

    function transfer(uint256 _allianceId, address _to) external whenNotPaused onlyAllianceOwner(_allianceId) {
        address _sender = msg.sender;

        require(addressStakings[_to].amount == 0, "already have stake");

        Stake memory _stake = addressStakings[_sender];
        delete(addressStakings[_sender]);

        _stake.owner = _to;
        _stake.payer = _to;
        addressStakings[_to] = _stake;
        allianceOwners[_allianceId] = _to;

        emit Transfer(_allianceId, _sender, _to);
    }

    //
    // Internal functions
    //
    function removeAllianceMember(uint256 _allianceId, address _addr) internal {
        uint256 _memberIdx = 0;
        for(uint256 i = 0; i < allianceMembers[_allianceId].length; i++) {
            if (allianceMembers[_allianceId][i] == _addr) {
                _memberIdx = i;
                break;
            }
        }                

        if(_memberIdx != allianceMembers[_allianceId].length - 1) {
            allianceMembers[_allianceId][_memberIdx] = allianceMembers[_allianceId][allianceMembers[_allianceId].length - 1];
        }
        allianceMembers[_allianceId].pop();        
    }

    function verifyTypedDataHash(bytes32 _domainSeparator, LibLazyStaking.Stake calldata _stake, bytes calldata _signature, address _owner) internal pure returns (bool) {
        bytes32 digest = ECDSA.toTypedDataHash(_domainSeparator, LibLazyStaking.hash(_stake));
        address signer = ECDSA.recover(digest, _signature);

        return signer == _owner;
    }        

    modifier onlyAllianceOwner(uint256 _allianceId) {
        require(msg.sender == allianceOwners[_allianceId], "not owner");
        _;
    }

    function _setPricePerSeat(uint256 _price) internal {
        require(_price > 0, "zero price");
        pricePerSeat = _price;
        emit ChangedPricePerSeat(_price);
    }

    function _setPricePerCreation(uint256 _price) internal {
        require(_price > 0, "zero price");
        pricePerCreation = _price;
        emit ChangedPricePerCreation(_price);
    }

    function _setTokenAddress(address _addr) internal {
        require(_addr != address(0), "zero address");
        tokenAddress = _addr;
        emit ChangedTokenAddress(_addr);
    }

    function _setAllianceMaxSeats(uint32 _maxSeats) internal {
        require(_maxSeats > 0, "zero maxSeats");
        allianceMaxSeats = _maxSeats;
        emit ChangedAllianceMaxSeats(_maxSeats);
    }

    function _setAllianceCheckerAddress(address _addr) internal {
        require(_addr != address(0), "zero address");
        allianceCheckerAddress = _addr;
        emit ChangedAllianceCheckerAddress(_addr);
    }  

    function _setSignerAddress(address _addr) internal {
        require(_addr != address(0), "zero address");
        signerAddress = _addr;
        emit ChangedSignerAddress(_addr);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibLazyStaking {
    bytes32 public constant TYPE_HASH = keccak256("Stake(uint256 id,address owner)");

    struct Stake {
        uint256 id;
        address owner;
    }

    function hash(Stake memory _stake) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, _stake.id, _stake.owner));
    }    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Managable {
    mapping(address => bool) private managers;
    address[] private managersAddresses;

    event AddedManager(address _address);
    event RemovedManager(address _address);

    modifier onlyManager() {
        require(managers[msg.sender], "caller is not manager");
        _;
    }

    function getManagers() public view returns (address[] memory) {
        return managersAddresses;
    }

    function addManager(address _manager) external onlyManager {
        _addManager(_manager);
    }

    function removeManager(address _manager) external onlyManager {
        uint index;
        for(uint i = 0; i < managersAddresses.length; i++) {
            if(managersAddresses[i] == _manager) {
                index = i;
                break;
            }
        }

        managersAddresses[index] = managersAddresses[managersAddresses.length - 1];
        managersAddresses.pop();

        _removeManager(_manager);
    }

    function _addManager(address _manager) internal {
        managers[_manager] = true;
        managersAddresses.push(_manager);
        emit AddedManager(_manager);
    }

    function _removeManager(address _manager) internal {
        managers[_manager] = false;
        emit RemovedManager(_manager);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAllianceChecker {
    function canDisband(uint256 _allianceId) external returns(bool);
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