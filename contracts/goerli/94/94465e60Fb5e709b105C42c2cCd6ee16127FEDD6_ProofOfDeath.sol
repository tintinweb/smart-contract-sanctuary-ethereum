// SPDX-License-Identifier: MIT

// A: quien provee herencia
// B: quien hereda de A
// C1, C2, ..., Cn: quien puede decir que murio A
// X: smart-contract (token) ej: USDC

pragma solidity 0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

contract ProofOfDeath is Ownable {
    // permisos que tiene para retirar
    // A -> B -> X -> amount
    mapping(address => mapping(address => mapping(address => uint256))) private _allowances;

    // quien va a heredar de quien
    // A -> B
    mapping(address => address) private _heir;

    // personas de quienes hereda
    // B -> [A1, ..., An] (inverso de _heir)
    mapping(address => address[]) private _heredados;

    // smart contracts que tienen allowances puestos por parte de A en B
    // A -> [X1, X2, ..., Xn]
    mapping(address => mapping(address => address[])) private _inheritance;

    // lista de personas de confianza (quienes tiene que asegurar que A murio para que B reciba herencia)
    // A -> [C1, C2, ..., Cn]
    mapping(address => address[]) private _signers;

    // lista de firmas de las personas, asegurando que A murio
    // C -> A -> bool
    mapping(address => mapping(address => bool)) private _deathSignatures;

    // tiempo que debe transcurrir para que B pueda reclamar herencia (sin que Cs firmen muerte)
    // A -> timestamp (block)
    mapping(address => uint256) private _timeBomb;

    error SignaturesNotComplete();

    event HeirAssignment(address indexed testator, address indexed heir);
    event WithdrawalMade(address indexed withdrawer, address indexed testator, address indexed contractAddress, uint256 amount);
    event AllowAsset(address indexed testator, address indexed withdrawer, address indexed contractAddress, uint256 amount);
    event DeathSignature(address indexed deceased, address indexed signer);

    function assignHeir(address wallet, uint256 timebomb, address[] memory signers) external {
        // si ya tenia asignado otro, hay que quitarlo
        if (_heir[msg.sender] != address(0)) {
            // quitamos los firmantes
            delete _signers[msg.sender];
            // quitamos de la lista de quien hereda a esta persona
            for (uint256 index = 0; index < _heredados[wallet].length; index++) {
                if (_heredados[wallet][index] == msg.sender) {
                    _removeHeredados(wallet, index); // remove by shifting
                    break; // salir del loop porque se rompio integridad
                }
            }
        }
        emit HeirAssignment(msg.sender, wallet);
        _heir[msg.sender] = wallet;
        _heredados[wallet].push(msg.sender);
        // tambien se deben pasar los firmantes
        _signers[msg.sender] = signers;
        // tambien timebomb
        _timeBomb[msg.sender] = timebomb;
    }

    function assignHeir(address wallet, address[] memory signers) external {
        // si ya tenia asignado otro, hay que quitarlo
        if (_heir[msg.sender] != address(0)) {
            // quitamos los firmantes
            delete _signers[msg.sender];
            // quitamos de la lista de quien hereda a esta persona
            for (uint256 index = 0; index < _heredados[wallet].length; index++) {
                if (_heredados[wallet][index] == msg.sender) {
                    _removeHeredados(wallet, index); // remove by shifting
                    break; // salir del loop porque se rompio integridad
                }
            }
        }
        emit HeirAssignment(msg.sender, wallet);
        _heir[msg.sender] = wallet;
        _heredados[wallet].push(msg.sender);
        // tambien se deben pasar los firmantes
        _signers[msg.sender] = signers;
    }

    // goerli usdc 0x07865c6E87B9F70255377e024ace6630C1Eaa37F
    // A setea allowances para que B retire
    function allowInheritance(
        address to,
        address smartContract,
        uint256 amount
    ) external {
        // despues vemos de usar permit, si o si necesito web3 para esto
        // IERC20(smartContract).permit(from, address(this), amount, MAX_INT); 
        // tratemos de usar allowances por ahora (consumen gas)
        // IERC20(smartContract).approve(to, amount); 
        
        // si no tiene permitido previamente ese scs
        if (_allowances[msg.sender][to][smartContract] == 0) {
            _inheritance[msg.sender][to].push(smartContract);
        }
        emit AllowAsset(msg.sender, to, smartContract, amount);

        _allowances[msg.sender][to][smartContract] += amount;
    }

    error TransferError();
    error NotAllowedAmount();

    function withdraw(
        address from,
        address smartContract,
        uint256 amount
    ) external {
        if (_allowances[from][msg.sender][smartContract] < amount) {
            revert NotAllowedAmount();
        }
        _allowances[from][msg.sender][smartContract] -= amount;
        emit WithdrawalMade(msg.sender, from, smartContract, amount);

        // if has timebomb setup first check it and transfer
        if (_timeBomb[from] != 0) {
            if (block.timestamp >= _timeBomb[from]) {
                bool success = IERC20(smartContract).transferFrom(from, msg.sender, amount);
                if (!success) {
                    revert TransferError();
                }
                return;
            }
        }
        // check that all desingnated signers have signed
        for (uint256 index = 0; index < _signers[from].length; index++) {
            address signer = _signers[from][index];
            if (!_deathSignatures[signer][from]) {
                revert SignaturesNotComplete();
            }
        }
        // transfer to heir the funds
        IERC20(smartContract).transferFrom(from, msg.sender, amount);
    }

    function signDeath(address deceased) external {
        _deathSignatures[msg.sender][deceased] = true;
        emit DeathSignature(deceased, msg.sender);
    }

    function isDead(address signer, address deceased) external view returns (bool) {
        return _deathSignatures[signer][deceased];
    }

    function isDead(address wallet) external view returns (bool) {
        if (_signers[wallet].length == 0) return false;
        for (uint256 index = 0; index < _signers[wallet].length; index++) {
            address signer = _signers[wallet][index];
            if (!_deathSignatures[signer][wallet]) {
                return false;
            }
        }
        return true;
    }

    function getHeir(address wallet) external view returns (address) {
        return _heir[wallet];
    }

    function getSigners(address wallet) external view returns (address[] memory) {
        return _signers[wallet];
    }

    function getAllowances(address from, address to, address smartContract) external view returns (uint256) {
        return _allowances[from][to][smartContract];
    }

    function getHerencias(address wallet) external view returns (address[] memory) {
        return _heredados[wallet];
    }

    function getHerenciasSmartContracts(address from, address to) external view returns (address[] memory) {
        return _inheritance[from][to];
    }

    error IndexOOB();

    function _removeHeredados(address wallet, uint _index) internal {
        if (_index >= _heredados[wallet].length) {
            revert IndexOOB();
        }
        for (uint i = _index; i < _heredados[wallet].length - 1; i++) {
            _heredados[wallet][i] = _heredados[wallet][i + 1];
        }
        _heredados[wallet].pop();
    }

    // function _removeInheritance(address from, address to, uint _index) internal {
    //     require(_index < _inheritance[from][to].length, "index out of bound");
    //     for (uint i = _index; i < _inheritance[from][to].length - 1; i++) {
    //         _inheritance[from][to][i] = _inheritance[from][to][i + 1];
    //     }
    //     _inheritance[from][to].pop();
    // }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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