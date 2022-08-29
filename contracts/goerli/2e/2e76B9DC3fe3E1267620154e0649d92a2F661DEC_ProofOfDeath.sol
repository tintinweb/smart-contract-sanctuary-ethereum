// SPDX-License-Identifier: MIT

// A: quien provee herencia
// B: quien hereda de A
// C1, C2, ..., Cn: quien puede decir que murio A
// X: smart-contract (token) ej: USDC

pragma solidity 0.8.4;

// import "./libraries/Address.sol";
// import "./interfaces/erc20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "hardhat/console.sol";

contract ProofOfDeath {
    // using Address for address payable;

    address private _operatorAddress;
    // uint256 private constant MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // permisos que tiene para retirar
    // A -> B -> X -> amount
    mapping(address => mapping(address => mapping(address => uint256))) private _allowances;

    // quien va a heredar de quien
    // A -> B
    mapping(address => address) private _heir;

    // personas de quienes hereda
    // B -> [A1, ..., An] (inverso de _heir)
    mapping(address => address[]) private _heredados;

    // smart contracts que tienen allowances puestos por parte de A
    // A -> [X1, X2, ..., Xn]
    mapping(address => address[]) private _inheritance;

    // lista de personas de confianza (quienes tiene que asegurar que A murio para que B reciba herencia)
    // A -> [C1, C2, ..., Cn]
    mapping(address => address[]) private _signers;

    // lista de firmas de las personas, asegurando que A murio
    // C -> A -> bool
    mapping(address => mapping(address => bool)) private _deathSignatures;

    // tiempo que debe transcurrir para que B pueda reclamar herencia (sin que Cs firmen muerte)
    // A -> timestamp (block)
    mapping(address => uint256) private _timeBomb;

    modifier onlyOperator() {
        require(
            msg.sender == _operatorAddress,
            "Caller is not the operator"
        );
        _;
    }

    error SignaturesNotComplete();

    constructor() {
        _operatorAddress = msg.sender;
    }

    function assignHeir(address wallet) external {
        // si ya tenia asignado otro, hay que quitarlo
        if (_heir[msg.sender] != address(0)) {
            for (uint256 index = 0; index < _heredados[wallet].length; index++) {
                if (_heredados[wallet][index] == msg.sender) {
                    _removeHeredados(wallet, index); // remove by shifting
                    break; // salir del loop porque se rompio integridad
                }
            }
        }
        _heir[msg.sender] = wallet;
        _heredados[wallet].push(msg.sender);
    }

    function signDeath(address wallet) external {
        _deathSignatures[msg.sender][wallet] = true;
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
        _allowances[msg.sender][to][smartContract] = amount;
    }

    function withdraw(
        address from,
        address smartContract,
        uint256 amount
    ) external {
        require(_allowances[from][msg.sender][smartContract] == amount, "Specified amount of withdrawal not allowed");
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

    function getHeir(address wallet) external view returns (address) {
        return _heir[wallet];
    }

    function getAllowances(address from, address to, address smartContract) external view returns (uint256) {
        return _allowances[from][to][smartContract];
    }

    function getHerencias(address wallet) external view returns (address[] memory) {
        return _heredados[wallet];
    }

    function _removeHeredados(address wallet, uint _index) internal {
        require(_index < _heredados[wallet].length, "index out of bound");
        for (uint i = _index; i < _heredados[wallet].length - 1; i++) {
            _heredados[wallet][i] = _heredados[wallet][i + 1];
        }
        _heredados[wallet].pop();
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