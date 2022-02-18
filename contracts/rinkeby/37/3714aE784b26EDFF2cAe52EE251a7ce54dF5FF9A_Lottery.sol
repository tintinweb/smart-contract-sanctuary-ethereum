//SPDX-License-Identifier: UNLICENSED

// Definição da versão do compilador que será utilizada.
pragma solidity ^0.6.6;

// Importação dos módulos e interfaces necessárias.
// o AggregatorV3Interface é a interface que se comunica com os oracles que
// determinam o valor dos ativos no mercado.
import "AggregatorV3Interface.sol";
// O Ownable é uma classe proveniente do projeto openzeppelin, que concede a
// quem a herdar a capacidade de manipular a posse do contrato com grande
// controle e com maior facilidade.
import "Ownable.sol";
// O VRFConsumerBase é o contrato que permite a seus herdeiros a comunicação
// com os VRFCoordinators, assim tornando possível a solicitação de números
// aleatórios e verificáveis para os Oracles.
import "VRFConsumerBase.sol";

// o contrato Lottery é descendente dos contratos VRFConsumerBase e do Ownable
contract Lottery is VRFConsumerBase, Ownable {
    // A precisão dos números, ou seja, o tamanho mínimo para se sair de um
    // WEI para um ETHER.
    uint256 constant PRECISION = 10**18;
    // A definição da taxa de entrada na loteria, que é de $100.
    uint256 entranceFee = 100 * 10 ** 18;
    // Declaração da variável que irá armazenar a taxa em LINK necessária para
    // os processos realizados nesse contrato.
    uint256 linkFee;
    // O KeyHash, que determina qual rota será utilizada pelo VRFCoordinator
    // ,ou seja, especificando qual será o custo e a forma de se obter os
    // resultados desejados.
    bytes32 keyhash;
    // A declaração de uma variável que irá receber o retorno da função
    // fulfillRandomness, ou seja, ele vai conter os valores aleatórios.
    uint256 randomness;
    // A lista de pessoas que compraram tickets, cada índice é equivalente a
    // um único Ticket. Dessa forma, quando mais de um ticket é comprado a
    // quantidade de presenças da pessoa aumenta, e por consequência, suas
    // chances de vencer.
    address payable[] public tickets;
    // a Inteface que vai permitir a requisição das cotações de criptoativos
    // está sendo declarada. Ela será muito útil para o funcionamento desse
    // contrato inteligente.
    AggregatorV3Interface ethUsdPriceFeed;
    // Temos a declaração de um enum, uma classe que contém valores estáticos e
    // constantes. Estes valores serão utilizados para a definição dos estados
    // em que a loteria vai estar (OPEN, CLOSED, CALCULATING_WINNER). De forma
    // que serão responsáveis por controlar o fluxo do código.
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    // O lotteryState é uma variável pública que é do tipo LOTTERY_STATE, ou
    // seja, é um enum, e portanto, pode usufruir livremente dos três valores
    // definidos na declaração dessa estrutura.
    LOTTERY_STATE public lotteryState;


    address public recentWinner;

    event RequestRandomness(bytes32 requestId);


    // O constructor é que vai definir os valores que devem ser passados para
    // sua utilização na construção de uma instância desse contrato. Além dos
    // valores que iríamos utilizar para o funcionamento básico do código,
    // também é necessário consultar os construtores das classes que estamos
    // herdando, visto que é preciso satisfazer as demandas contidas em seus
    // construtores. Com isso adicionamos variáveis que serão responsáveis por
    // atender as demandas do constructor da classe VRFConsumerBase.
    constructor(
        address _priceFeedAddress,// Endereço o PriceFeed.
        address _vrfCoordinator,// Endereço do vrfCoordinator, ele vai receber a transação e retornar um número aleatório.
        address _link,// Endereço do Token LINK.
        uint256 _fee,// Quantidade de LINK necessária para pagar o Oracle.
        bytes32 _keyhash// Caminho que o VRFCoordinator irá realizar
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
      // Diferente de outras situações temos de passar os valores demandados
      // para o construtor do VRFConsumerBase diretamente pelos parâmetros.
      // O restante do código é a atribuição dos valores as variáveis que foram
      // declaradas previamente.

      // lotteryState recebe o valor CLOSED, ou seja, a loteria está fechada.
        lotteryState = LOTTERY_STATE.CLOSED;
      // keyhash recebe o caminho que deve realizar.
        keyhash = _keyhash;
      // linkFee recebe a taxa.
        linkFee = _fee;
      // o PriceFeed recebe o objeto AggregatorV3Interface com um PriceFeed
      // existente na rede em que estão.
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    }


    // Um modificador que determina o valor mínimo de Ether na transação
    modifier onlyMinimumEth() {
      // Require recebe como primeiro parâmetro uma condição booleana, e no
      // segundo parâmetro uma mensagem caso essa condição não seja atendida.
      // Se a condição não for atendida o código vai parar, e a transação que
      // foi feita vai falhar.
        require(
            convertEthToDollar(msg.value) >= entranceFee,
            "Minimum ETH not reached"
        );
      // _; determina que a função vai ser executada após a verificação.
        _;
    }

    // Um modificador que garante que a Loteria esteja aberta
    modifier onlyOpenLottery() {
    // O Require vai garantir que a condição booleana do primeiro parâmetro
    // seja cumprida, caso ela não seja, vai impedir a realização da transação
    // e retornar a mensagem do segundo parâmetro.
        require(
            lotteryState == LOTTERY_STATE.OPEN,
            "The lottery isn't open!"
        );
        _;
    }


    // Função que vai retornar um uint256 de no mínimo 18 casas, contendo
    // o valor atual de um Ether em dólares.
    function getLatestEthPrice() public view returns (uint256) {
    // O retorno da função latestRoundData() é uma tupla, nesse caso estamos
    // definindo o único elemento que temos interesse.
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
    // Para que o retorno siga a regra das 18 casas (onde um 1 ETHER é equivalente
    // a 1 * 10 ** 18) temos de realizar um incremento de casas.
        return uint256(price * 10 ** 10);
    }

    // Função que vai converter um valor em Ether para o equivalente em dólar
    // Ela recebe um uint256 com o valor em WEI, e retorna um uint256 com o
    // valor em dólar. Lembrando que 1 dólar é 1 * 10 ** 18.
    function convertEthToDollar(uint256 _wei) public view returns (uint256) {
    // Variável etherPrice recebe o mais recente valor em dólares da moeda.
        uint256 etherPrice = getLatestEthPrice();
    // Aqui temos o cálculo, comum para todas as conversões entre diferentes
    // ativos. Nesse caso, como as casas são representadas por zeros, temos de
    // garantir que as casas excedentes sejam retiradas na divisão.
        uint256 valueInDollar = (etherPrice * _wei) / 10 ** 18;
    // Retorno do valor em dólar, com a regras das 18 casas sendo respeitada.
        return valueInDollar;
    }

    // Função que faz o oposto da anterior, convertendo dólar para Ether.
    // Ela recebe um uint256 com o valor em dólares, e retorna um uint256 com o
    // valor em Ether.
    function convertDollarToEth(uint256 _dollar) public view returns (uint256) {
    // Variável etherPrice recebe o mais recente valor em dólares da moeda.
        uint256 etherPrice = getLatestEthPrice();
    // Essa operação é enganosa no Solidity, como não temos números decimais o
    // processo comum que utilizamos (a divisão do dólar pelo valor em dólares)
    // pode retornar algo menor que 1. Ou seja, em casos onde o valor em dólares
    // não é perfeitamente divisível pelo valor do Ether, casas decimais serão
    // perdidas. Para evitar isso é necessário que casas "decimais" sejam
    // acrescentadas. Nesse caso serão 18 casas, para garantir que o resultado
    // esteja dentro do padrão.
        uint256 valueInEther = ((_dollar * 10 ** 18) / etherPrice);
    // Retorno do valor em Ether.
        return valueInEther;
    }

    // Função que retorna o valor da entrada em Ether.
    // Ela retorna um uint256 com o valor em Wei necessário para a entrada na
    // loteria.
    function getEntranceFee() public view returns (uint256) {
    // A operação aqui é simplesmente converter o valor da taxa de entrada
    // com um pequeno acréscimo, isso vai garantir que as flutuações do valor do
    // par ETH/USD não evitem o sucesso da transação. Com isso em mente, ele vai
    // pagar uma taxa infimamente mais alta para garantir o sucesso de sua
    // transação. Lembrando que a taxa segue a regra das 18 casas.
        return convertDollarToEth(entranceFee + (0.02 * 10 ** 18));
    }

    // A função buyTicket() é payable, ou seja, pode receber valores, dessa forma
    // ela permite que a taxa de entrada na loteria seja paga. Ademais, ela possui
    // dois modificadores, o onlyOpenLottery vai aceitar essa transação apenas
    // quando o lotteryState for igual a LOTTERY_STATE.OPEN. E o onlyMinimumEth
    // vai determinar que apenas transações que paguem a taxa de entrada sejam
    // aceitas pela função.
    function buyTicket() public payable onlyOpenLottery onlyMinimumEth {
      // Caso as demandas dos modificadores sejam atendidas o remetente vai ser
      // colocado dentro da lista dos competidores.
        tickets.push(msg.sender);
    }

    // A função startLottery() vai permitir que o lotteryState seja alterado para
    // LOTTERY_STATE.OPEN, ou seja, vai abrir a loteria. Com isso em mente, o
    // modificador onlyOwner (herdado da classe Ownable) vai garantir que apenas
    // o atual proprietário do contrato possa realizar esse procedimento.
    function startLottery() public onlyOwner {
    // Atribuição de um novo valor para o lotteryState.
        lotteryState = LOTTERY_STATE.OPEN;
    }

    // a função endLottery() vai determinar que o período de entrada foi encerrado
    // e vai dar início aos procedimentos necessários para finalizar a loteria.
    // Isso inclui evitar que novas pessoa entrem (atribuindo um novo valor ao
    // lotteryState). E realizando uma solicitação de aleatoriedade para o
    // VRFCoordinator da rede. Ademais, a função possui o modificador onlyOwner
    // o que vai garantir que apenas o proprietário atual do contrato possa
    // chamar essa função com sucesso.
    function endLottery() public onlyOwner {
    // Atribuição ao enum lotteryState do estado CALCULATING_WINNER.
        lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
    // armazenamento do identificador da solicitação de aleatoriedade, que é
    // feita com o uso da função requestRandomness(keyhash, linkFee). Essa função
    // vai interagir com o VRFCoordinator, e com a função fulfillRandomness. O
    // processo é detalhado na própria função fulfillRandomness.
        bytes32 requestId = requestRandomness(keyhash, linkFee);
        emit RequestRandomness(requestId);
    }


    // Está é a função mais importante para a comunicação com o VRFCoordinator,
    // ela é herdada diretamente do VRFConsumerBase, e faz parte do modelo de
    // comunicação que existe na Blockchain.
    // Esse modelo é o request and receive, ele determina que em operações assíncronas
    // onde dependemos de um retorno com tempo variável, é necessário que a comunicação
    // e codificação seja feita pensando em uma função de envio, e outra de
    // recebimento. Ou seja, a função requestRandomness vai solicitar o recebimento
    // de um valor aleatório para o VRFCoordinator, esse por sua vez vai se comunicar
    // com o Oracle, e quando obter o valor terá de chamar a função fulfillRandomness.
    // Dessa forma, quem terá acesso a esse valor quando ele for entregue será essa
    // função.
    // Tudo isso acontece pela natureza da Blockchain, que é limitada a sua própria
    // lógica, então tudo que acontece nesse ambiente é determinístico e regrado.
    // Esse determinismo obriga as funções a serem executadas diretamente, sem permitir
    // a existência de processo assíncronos no código, dessa forma, o método de comunicação
    // opera de forma semelhante ao NodeJS, onde as funções de callback vai lidar com
    // o valor no futuro, sem que isso atrapalhe o funcionamento do código síncrono.
    // Com isso em mente esta função é interna, ou seja, só pode ser chamado pelo
    // código em si. E recebe dois parâmetros referentes ao retorno do VRFCoordinator
    // o requestId e o randomness (o número aleatório). Além disso, ela está sobescrevendo
    // uma outra função já presente no VRFConsumerBase, por isso o identificador override.

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
    // Temos duas requisições nesse ponto. a primeira é que o lotteryState esteja
    // no estado de LOTTERY_STATE.CALCULATING_WINNER, visto que é o único momento
    // onde o valor aleatório é requisitado.
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER, "You aren't there yet.");
    // A segunda é a confirmação que o valor aleatório não é zero. O que busca evitar
    // que um retorno incorreto seja aceito no código.
        require(_randomness > 0, "Random not found");

    // O vencedor é determinado pelo valor remanescente na divisão do _randomness
    // pela largura do array tickets. Com isso, ele vai retonar um número menor
    // que o número de participantes, e que vai premiar qualquer um dos presentes.
        uint256 winner = _randomness % tickets.length;
    // Nesse ponto estamos obtendo o endereço do vencedor, e fazendo o cast para
    // que ele seja um endereço payable, ou seja, aceite valores na transação.
        address payable winnnerAddress = tickets[winner];
    // Aqui obtemos o balanço atual desse contrato inteligente, convertendo o
    // this para um endereço, e utilizando a propriedade balance.
        uint256 balance = address(this).balance;
    // E finalmente o vencedor é premiado, com o uso da função transfer ele irá
    // receber todo o valor presente na loteria.
        winnnerAddress.transfer(balance);
        recentWinner = winnnerAddress;

    // Por fim, o processo de limpeza e preparo do contrato para novos sorteios.
    // Os tickets são limpos, e recebem um novo array de endereços com zero índices
    // e com nenhum endereço.
        tickets = new address payable[](0);
    // O estado da loteria se torna fechado.
        lotteryState = LOTTERY_STATE.CLOSED;
    // E a variável randomness armazena o retorno para futuras consultas.
        randomness = _randomness;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "SafeMathChainlink.sol";

import "LinkTokenInterface.sol";

import "VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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
library SafeMathChainlink {
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
    require(c >= a, "SafeMath: addition overflow");

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
    require(b <= a, "SafeMath: subtraction overflow");
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
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

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
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
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
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}