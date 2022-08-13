// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;
pragma abicoder v2;


import { ERC20 } from "./solmate/ERC20.sol";
import { ERC721 } from "./solmate/ERC721.sol";
import { Owned } from "./solmate/Owned.sol";
import { SafeTransferLib } from "./solmate/SafeTransferLib.sol";


contract InvestStartup is ERC721, Owned(msg.sender) {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error TotalCaptureMade();
    error NotAcceptfromBothAddresses();
    error OutofTime();
    error Morethanthestartupneeds();
    error OnlyMutuante();
    error OnlyMutuario();
    error OnlyAuthorized();
    error GreaterThanNegotiated();
    error OnlyafterInvestmentFunding();
    error paused();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event FundsWithdrawn();

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    address payable immutable ownerOmnes;

    //startup
    struct Mutuario {
        string nameStartup;
        uint256 cnpj;
        bool captation; //captação total alcançada
        uint256 minValue; //valor minimo
        uint256 targetValue;
        uint256 investedAmount;
        ERC20 quotas;
        uint256 numInvest;
        address payable mutuario;
    } //endereço que vai chamar na função que vai pagar

    mapping(address => Mutuario) public mutuarios;

    //Investidor
    struct Mutuante {
        string nome;
        uint64 cnpjoucpf;
        uint256 numInvestment;
        address payable mutuante;
        bool lookingFor;
    }

    mapping(address => Mutuante) public mutuantes;

    //definições do investimeto lançadas pela startup com o valor minimo e máximo
    struct startInvestment {
        uint256 value; //valor aceito
        uint256 finalTimeInvest;
        bool acceptStartup; //aceite da startup
        bool acceptInvestor; //aceite da empresa
    }
    mapping(address => mapping(address => startInvestment)) public whoInvWhatStartup;

    mapping(address => uint256) public timeforAccept;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    uint256 public totalInvestment;
    uint256 public numStartups;
    uint256 public numInvestors;
    uint256 initContract;
    uint256 public DURATION = 0; //aprox 2 years 730 days
    uint256 public timmeAccpet = 48 hours; //48 horas para aceitar
    bool pause;
    //permissions e termination

    mapping(address => bool) public authorizedAddress;
    mapping(address => bool) public authorizedQuota;

    //modifiers

    modifier pausedcontract(){
        if(!pause)revert paused();
        _;
    }

    modifier onlyMutuante() {
        if (msg.sender != mutuantes[msg.sender].mutuante) revert OnlyMutuante();
        _;
    }

    modifier onlyMutuario() {
        if (msg.sender != mutuarios[msg.sender].mutuario) revert OnlyMutuario();
        _;
    }

    modifier onlyAuthorized() {
        if (!authorizedAddress[msg.sender]) revert OnlyAuthorized();
        _;
    }

    modifier authorizeWithdrawalQuotas() {
        if (!authorizedQuota[msg.sender]) revert OnlyAuthorized();
        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() ERC721("Omnes-Mutuo", "OMBm") {
        ownerOmnes = payable(msg.sender);
        initContract = block.timestamp;
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "https://ipfs.io/ipfs/QmWCbaw4vp4m6QKqrkxtQe7A7tsir9WGMgVvZaagMzSe9W";
    }
    //private
    function tokenQ() private view returns (ERC20 quota) {
        return mutuarios[msg.sender].quotas;
    }

    /// -----------------------------------------------------------------------
    /// externals and registers e authorization
    /// -----------------------------------------------------------------------

    //quantidade de tokens que vc tem no contrato
    function balanceOfcontractQuotas() external view returns (uint256) {
        return tokenQ().balanceOf(address(this));
    }

    //autorizar retirada de quotas como garantia
    function authorizewhidrawQuotas(address _startup, bool _authorization) external onlyOwner {
        authorizedQuota[_startup] = _authorization;
    }

    //autorizando ou desutorizando endereço, caso haja alguma infração favor desabilitar a autorização
    function authorizeDisallowAddress(address _startupOrInvestor, bool _authorization)
        external
        onlyOwner
        returns (string memory, address)
    {
        authorizedAddress[_startupOrInvestor] = _authorization;
        return (
            "the address authorized or unauthorized of the startup or registered investor is:",
            _startupOrInvestor
        );
    }

    function registerMutuante(string memory _nome, uint64 _cnpjoucpf) external onlyAuthorized {
        mutuantes[msg.sender] = Mutuante(_nome, _cnpjoucpf, 0, payable(msg.sender), true);
        unchecked {
            numInvestors++;
        }
    }

    function IdontWanttoInvest() external onlyAuthorized {
        require(msg.sender == mutuantes[msg.sender].mutuante, "you are not a Mutuante");
        mutuantes[msg.sender].lookingFor = false;
    }

    //vai mandar sempre 10 tokens que representam 10% das quotas da empresa como garantia
    function registerMutuario(
        string memory _nameStartup,
        uint256 _cnpj,
        uint256 _targetValue,
        ERC20 _quotas,
        uint256 _minValue
    ) external onlyAuthorized {
        require(_targetValue <= 10000000000000000000, "the target cannot exceed 10 ether");
        require(_minValue >= 1000000000000000000, "minimum value cannot be less 1 ether");
        mutuarios[msg.sender] = Mutuario(
            _nameStartup,
            _cnpj,
            false,
            _minValue,
            _targetValue,
            0,
            _quotas,
            0,
            payable(msg.sender)
        );
        unchecked {
            numStartups++;
        }
        //para transferir ele vai precisar ter os tokens na wallet
        //vai ficar na custódia do contrato 10% como garantia
        //antes aprovar no contrato token nos testes
        tokenQ().safeTransferFrom(msg.sender, address(this), 10);
    }

    //o investidor quer investir em uma determinada startup e estipulando o valor
    function InvestorWantsToInvest(address _startup, uint256 _value) external onlyMutuante {
        whoInvWhatStartup[msg.sender][_startup] = startInvestment(_value, 0, false, true);
        timeforAccept[_startup] = block.timestamp;
    }

    //only mutuaria Startup que executa e tempo começou quando o investidor sugeriu
    function accepetStartupInvestor(address _investor) external onlyMutuario {
        if (timeforAccept[msg.sender] + timmeAccpet <= block.timestamp) revert OutofTime();
        whoInvWhatStartup[_investor][msg.sender].acceptStartup = true;
    }

    //tem que ser do endereço certo na hora do accept
    function checkAccepts(address _investor, address _startup) external view returns (bool, bool) {
        return (
            whoInvWhatStartup[_investor][_startup].acceptInvestor,
            whoInvWhatStartup[_investor][_startup].acceptStartup
        );
    }

    /// -----------------------------------------------------------------------
    /// Investment and Pay Investment
    /// -----------------------------------------------------------------------

    function Invest(address _startup,uint _iddoc) external payable returns (bool sucess) {
        //se o valor de captação já foi atingido revert
        //require(mutuarios[msg.sender].targetValue <= msg.value, "value exceeds what the startup needs");
        //inserir depois ===>
        if (mutuarios[_startup].captation != false) revert TotalCaptureMade();
        //o valor inserido deve ser igual ao acordado entre a negociação
        require(
            whoInvWhatStartup[msg.sender][_startup].value == msg.value,
            "value must be the same as agreed"
        );
        //se o aceite do investidor ou da startup estiver negativa revert que não foi aceito a proposta ainda
        if (
            !whoInvWhatStartup[msg.sender][_startup].acceptInvestor ||
            !whoInvWhatStartup[msg.sender][_startup].acceptStartup
        ) revert NotAcceptfromBothAddresses();
        whoInvWhatStartup[msg.sender][_startup].finalTimeInvest = block.timestamp + DURATION;

        //atualização dos dados da struct investimento e referente ao mutuante
        unchecked {
            mutuantes[msg.sender].numInvestment++;
            //atualização mutuário:
            mutuarios[_startup].numInvest++;
            mutuarios[_startup].targetValue -= msg.value;
            //atualização do total de todas as rodadas
            mutuarios[_startup].investedAmount += msg.value;
            //atualização do valor total de todas as empresas
            totalInvestment += msg.value;

            //se o valor alvo chegar a zero a captação será concluida
            if (mutuarios[_startup].targetValue == 0) {
                mutuarios[_startup].captation = true;
            }
        }

        //distribuição dos percentuais
        uint256 feeOmnes = (msg.value * 10) / 1000; //1% para a Omnes
        uint256 smartcontractvalue = (msg.value * 49) / 100; //49% contrato
        uint256 firstInvestment = (msg.value * 50) / 100; //50% para a conta direto da Startup
        payable(ownerOmnes).transfer(feeOmnes);
        payable(address(this)).transfer(smartcontractvalue);
        payable(_startup).transfer(firstInvestment);

        _mint(msg.sender, _iddoc);

        return sucess;
    }

    //investidor manda a segunda parte
    function restOftheInvestment(address _startup) external payable onlyMutuante {
        uint256 rest = (whoInvWhatStartup[msg.sender][_startup].value * 49) / 100; //49% contrato
        payable(_startup).transfer(rest);
    }

    //pagamento da startup para a empresa, caso depois do prazo final multa de 20%
    function payInvestor(address _investor) external payable {
        //multa de 20% do valor da proposta do prazo final, ou seja 12 ether
        uint256 LatepaymentFee = (whoInvWhatStartup[_investor][msg.sender].value * 20) / 100;

        uint256 latevalue = whoInvWhatStartup[_investor][msg.sender].value + LatepaymentFee;

        unchecked {
            mutuarios[msg.sender].investedAmount -= msg.value;
        }

        if (block.timestamp > whoInvWhatStartup[_investor][msg.sender].finalTimeInvest) {
            require(msg.value == latevalue, "amount must be paid with the late fee more 20%");
            payable(_investor).transfer(latevalue);
        } else {
            payable(_investor).transfer(msg.value);
        }
    }

    //só pode retirar as quotas de garantia quando
    function withdrawQuotas() external authorizeWithdrawalQuotas {
        if (!mutuarios[msg.sender].captation) revert OnlyafterInvestmentFunding();
        uint256 quotas = tokenQ().balanceOf(address(this));
        tokenQ().safeTransfer(msg.sender, quotas);
    }

    receive() external payable {}

    /// -----------------------------------------------------------------------
    /// Returns
    /// -----------------------------------------------------------------------

    //Mutuario consegue acompanhar peloa endereço da startup o valor de aceite e o tempo que foi estipulado para pagar
    function seeInvestinYouStartup(address _startup)
        public
        view
        onlyAuthorized
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (
            whoInvWhatStartup[msg.sender][_startup].value,
            whoInvWhatStartup[msg.sender][_startup].finalTimeInvest,
            mutuarios[_startup].captation
        );
    }

    //conseguimos ver qual investidor esta busacando investir e com os valores e se está procurando ou não investimento
    function returnInvestors(address _investor)
        public
        view
        onlyAuthorized
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (
            mutuantes[_investor].numInvestment,
            mutuantes[_investor].cnpjoucpf,
            mutuantes[_investor].lookingFor
        );
    }

    //conseguimos ver a startup que quer ivestimento e se ela já alcançou o valor solicitado
    function returnStartupWantInvest(address _startup)
        public
        view
        onlyAuthorized
        returns (
            bool,
            uint256,
            uint256,
            ERC20,
            uint256
        )
    {
        return (
            mutuarios[_startup].captation,
            mutuarios[_startup].targetValue,
            mutuarios[_startup].numInvest,
            mutuarios[_startup].quotas,
            mutuarios[_startup].minValue
        );
    }

    /// -----------------------------------------------------------------------
    /// WithdrawERC20 and withdrawETH
    /// -----------------------------------------------------------------------

    function withdrawETH() external onlyOwner {
        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);

        emit FundsWithdrawn();
    }

    function withdrawERC20(ERC20 tokene) external onlyOwner {
        uint256 balance = tokene.balanceOf(address(this));
        SafeTransferLib.safeTransferFrom(tokene, address(this), msg.sender, balance);

        emit FundsWithdrawn();
    }

    function pausedoff()onlyOwner external{
        pause = true;
    }

    function mintOmnesParticipation(uint id)external pausedcontract{
        _mint(msg.sender, id);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        //adaptation
        _beforeTokenTransfer(from, to, id);
        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }
        
        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
        
        _afterTokenTransfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        //adaptation 
        _beforeTokenTransfer(address(0), to, id);
        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
        _afterTokenTransfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");
        
        //adaptation
         _beforeTokenTransfer(owner, address(0), id);

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);

        _afterTokenTransfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
    

}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.9;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(
        address indexed user,
        address indexed newOwner
    );

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner)
        public
        virtual
        onlyOwner
    {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
    /// @dev Returns the address of the current owner.
    function returnowner() public view virtual returns (address) {
        return owner;
    }


}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

import {ERC20} from "./ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}