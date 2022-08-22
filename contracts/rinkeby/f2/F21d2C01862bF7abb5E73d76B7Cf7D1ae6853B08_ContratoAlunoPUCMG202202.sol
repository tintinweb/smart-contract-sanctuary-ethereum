// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./PucCoin.sol";
import "./Contrato_Aluno.sol";

/** 
 * @title  DisciplinaPlataformaEthereumPUCMG202202
 * @dev Define regras de partcipação na disciplina Plataforma Ethereum, PUCMG
 * @author Carlos Leonardo dos S. Mendes
 */
contract DisciplinaPlataformaEthereumPUCMG202202 {

    address private professor;      // conta do professor na Ethereum
    PucCoin private token;          // token PUC

    // modificador para verificar se é professor
    modifier apenasProfessor() {
        require(msg.sender == professor, unicode"Apenas o professor pode realizar essa operação.");
        _;
    }

    // Aluno
    struct Aluno {
        string nome;            // nome do aluno
        address contrato;       // contrato de recebimento de token na Ethereum
        bool registrado;        // se já está registrado na disciplina
        bool verificado;        // se já foi verificado pelo professor
        bool resgateLiberado;   // se o resgate já foi liberado para o aluno
        bool checkinAula01;     // checkin aula01, aula02....
        bool checkinAula02;
        bool checkinAula03;
        bool checkinAula04;
        bool checkinAula05;
    }

    // Flags para indicar checkin aberto para as aulas
    bool[] private sessaoAulaAberta;

    // Alunos da disciplina 
    mapping(address => Aluno) private alunos;
    address[] private alunosRegistrados;

    // Evento de registro na disciplina
    event Registro(string nome, address aluno, address contrato);

    // Construtor 
    constructor(PucCoin coin) {
        professor = msg.sender;
        token = coin;

        for (uint aula = 0; aula < 5; aula++) {
            sessaoAulaAberta.push(false);
        }
    }

    /* Operação de registro na disciplina */
    function registra(string memory nome, address contrato) public {
        Aluno memory aluno = alunos[msg.sender];
        require(!aluno.registrado, unicode"Aluno já está registrado na disciplina.");
        
        ContratoAlunoPUCMG202202 contratoAluno = ContratoAlunoPUCMG202202(contrato);
        address owner = contratoAluno.getProprietario();
        require(owner == msg.sender, unicode"O contrato informado não pertence ao aluno.");

        alunos[msg.sender] = Aluno({
            nome: nome,
            contrato: contrato,
            registrado: true,
            verificado: false,
            resgateLiberado: false,
            checkinAula01: false,
            checkinAula02: false,
            checkinAula03: false,
            checkinAula04: false,
            checkinAula05: false
        });

        contratoAluno.registra(token, professor);
        alunosRegistrados.push(msg.sender);

        emit Registro(nome, msg.sender, contrato);
    }

    /* Operação para cancelar o registro do aluno da disciplina */
    function cancelaRegistro(address addAluno) public apenasProfessor {
        Aluno storage aluno = alunos[addAluno];
        require(aluno.registrado, unicode"Aluno não está registrado na disciplina.");
        require(!aluno.resgateLiberado, unicode"Não é possível cancelar o registro. O resgate já foi liberado.");
 
        aluno.registrado = false;
        ContratoAlunoPUCMG202202 contratoAluno = ContratoAlunoPUCMG202202(aluno.contrato);
        contratoAluno.cancelaRegistro();

        // Retira do arranjo de alunos registrados
        for (uint i=0; i<alunosRegistrados.length; i++) {
            if (alunosRegistrados[i] == addAluno) {
                alunosRegistrados[i] = alunosRegistrados[alunosRegistrados.length-1];
                alunosRegistrados.pop();
                break;
            }
        }
    }

    /* Retorna alunos registrados na disciplina */
    function retornaAlunosRegistrados() public view returns(Aluno[] memory) {
        Aluno[] memory _alunos = new Aluno[](alunosRegistrados.length);
        for (uint i=0; i<alunosRegistrados.length; i++) {
             address addAluno = alunosRegistrados[i];
             Aluno memory aluno = alunos[addAluno];
             _alunos[i] = aluno;
        }
        return _alunos;
    }

    /* Confirma o aluno na disciplina */
    function confirmaAluno(address addAluno) public apenasProfessor {
        Aluno storage aluno = alunos[addAluno];
        require(aluno.registrado, unicode"Aluno não está registrado na disciplina.");
        require(!aluno.verificado, unicode"O aluno já foi confirmado na disciplina.");

        aluno.verificado = true;
    }

    /* Confirma todos os alunos registrados */
    function confirmaTodosAlunos() public apenasProfessor {
        for (uint i=0; i<alunosRegistrados.length; i++) {
            address addAluno = alunosRegistrados[i];
            Aluno storage aluno = alunos[addAluno];
            aluno.verificado = true;
        }        
    }

    /* Libera resgate de tokens no contrato do aluno */
    function liberaResgate(address addAluno) public apenasProfessor {
        Aluno memory aluno = alunos[addAluno];
        require(aluno.registrado, unicode"Aluno não está registrado na disciplina.");
        require(!aluno.resgateLiberado, unicode"O resgate já foi liberado.");

        ContratoAlunoPUCMG202202 contratoAluno = ContratoAlunoPUCMG202202(aluno.contrato);
        contratoAluno.liberaResgate();
    }

    /* Transfere PUCs para o contrato do aluno */
    function transferePucs(uint256 qtde, address addAluno) public apenasProfessor {
        Aluno memory aluno = alunos[addAluno];
        if (aluno.registrado && aluno.verificado) {
            token.transferFrom(professor, aluno.contrato, qtde);
        }
    }

    /* Transfere PUCs para os contratos de todos os alunos */
    function transferePucs(uint256 qtde) public apenasProfessor {
        for (uint i=0; i<alunosRegistrados.length; i++) {
            transferePucs(qtde, alunosRegistrados[i]);
        }        
    }

    /* Abre sessão da aula para checkin */
    function abrirSessaoDeAula(uint aula) public apenasProfessor {
        require(aula < 5, unicode"Número inválido para a aula.");
        sessaoAulaAberta[aula] = true;
    }

    /* Fechar sessão da aula para checkin */
    function fecharSessaoDeAula(uint aula) public apenasProfessor {
        require(aula < 5, unicode"Número inválido para a aula.");
        sessaoAulaAberta[aula] = false;
    }

    /* Realiza checkin na aula */
    function checkin(uint aula) private {
        require(aula < 5, unicode"Número inválido para a aula.");

        Aluno storage  aluno = alunos[msg.sender];
        require(aluno.registrado, unicode"Aluno não está registrado na disciplina.");
        require(aluno.verificado, unicode"Aluno ainda não foi verificado pelo professor.");
        require(sessaoAulaAberta[aula], unicode"Sessão de aula não está aberta para checkin.");
        
        if (aula == 0) {
            require(!aluno.checkinAula01, unicode"Aluno já fez checkin.");
            aluno.checkinAula01 = true;
        }
        else if (aula == 1) {
            require(!aluno.checkinAula02, unicode"Aluno já fez checkin.");
            aluno.checkinAula02 = true;
        }
        else if (aula == 2) {
            require(!aluno.checkinAula03, unicode"Aluno já fez checkin."); 
            aluno.checkinAula03 = true;
        }
        else if (aula == 3) {
            require(!aluno.checkinAula04, unicode"Aluno já fez checkin.");
            aluno.checkinAula04 = true;
        }
        else if (aula == 4) {
            require(!aluno.checkinAula05, unicode"Aluno já fez checkin.");
            aluno.checkinAula05 = true;
        }

        // Transfere 1 PUC para o contrato do aluno
        token.transferFrom(professor, aluno.contrato, 1 * (10**uint256(token.decimals())));
    }

    /* Checkin aula 01 */
    function checkinAula01() public {
        checkin(0);
    }

    /* Checkin aula 02 */
    function checkinAula02() public {
        checkin(1);
    }

    /* Checkin aula 03 */
    function checkinAula03() public {
        checkin(2);
    }

    /* Checkin aula 04 */
    function checkinAula04() public {
        checkin(3);
    }   

    /* Checkin aula 05 */
    function checkinAula05() public {
        checkin(4);
    }           
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./PucCoin.sol";

/** 
 * @title  Contrato do aluno
 * @dev Armazena os tokens PUC
 * @author Carlos Leonardo dos S. Mendes
 */
contract ContratoAlunoPUCMG202202 {

    PucCoin private token;                  // contrato do PUC token
    address private aluno;                  // conta do aluno
    address private professor;              // conta do professor na Ethereum
    address private contratoDisciplina;     // conta do contrato da disciplina

    // indica se o resgate está liberado
    bool private resgateLiberado = false;

    /* modificador para verificar se é o contrato da disciplina */
    modifier apenasContratoDisciplina() {
        require(msg.sender == contratoDisciplina, unicode"Apenas o contrato da disciplina pode realizar essa operação.");
        _;
    }

    /* modificador para verificar se é aluno */
    modifier apenasAluno() {
        require(msg.sender == aluno, unicode"Apenas o aluno dono do contrato pode realizar essa operação.");
        _;
    }

    /* Construtor. Recebe como parâmetro o endereço do contrato da disciplina */
    constructor(address _contratoDisciplina) {
        aluno = msg.sender;
        contratoDisciplina = _contratoDisciplina;
    }

    /* Registra na disciplina */
    function registra(PucCoin _token, address _professor) public apenasContratoDisciplina {
        token = _token;
        professor = _professor;
    }

    /* Cancela registro na disciplina */
    function cancelaRegistro() public apenasContratoDisciplina {
        uint256 saldo = token.balanceOf(address(this));
        token.transfer(contratoDisciplina, saldo);
    }

    /* Libera resgate dos tokens */
    function liberaResgate() public apenasContratoDisciplina {
        resgateLiberado = true;
    }

    /* Resgata os tokens do contrato */
    function resgate() public apenasAluno {
        require(resgateLiberado, unicode"O resgate não foi liberado pelo professor.");

        uint256 saldo = token.balanceOf(address(this));
        token.transfer(aluno, saldo);
    }

    /* Retorna endereço do proprietário do contrato */
    function getProprietario() public view returns (address _owner) {
        _owner = aluno;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PucCoin is Context, ERC20, Ownable {
    constructor() ERC20("Popular User Coin", "PUC") {
        _mint(_msgSender(), 1000 * (10**uint256(decimals())));
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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