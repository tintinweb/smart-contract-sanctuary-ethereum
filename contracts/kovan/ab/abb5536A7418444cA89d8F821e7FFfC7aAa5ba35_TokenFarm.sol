// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    // mapping token address -> staker address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    address[] public allowedTokens;
    address[] public stakers;
    IERC20 public dappToken;

    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        // Issue (emitir) tokens to all stakers
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            // Send them (each recipient/user) a token reward based on their total value locked.
            uint256 userTotalValue = getUserTotalValue(recipient);
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        // Price of the token * stakingBalance[_token][_user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // Getting priceFeedAddress
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "Amount must be more than 0");
        require(tokenIsAllowed(_token), "Token is currently not allowed!");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public view returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }
}

// EXPLICACI??N C??DIGO.

// MIN: 12:56:11
// PUES BIEN, una vez creado y compilado el contrato que crea nuestro token DAPP (DappToken.sol),
// vamos a crear el contrato Token Farm. Para esto lo creamos en la carpeta: contracts, y nos
// dirigimos hacia all??.

// ENTONCES, lo que vamos a hacer capaces de hacer con este contrato va ser:
//  - StakeTokens, es decir, hacer staking con tokens que almacenemos en la farm.
//  - unStakeTokens, es decir, ser capaces de retirar los tokens que hemos puesto en staking.
//  - issueTokens, los cuales se van a encargar de emitir los tokens rewards, es decir, los tokens
//    que vamos a dar como ganancia a los usuarios que nos den sus tokens para hacer staking.
//  - addAllowedTokens, los cuales nos permitir??n a??adir m??s tokens que ser??n permitidos (allowed)
//    para que los usuarios hagan staking en nuestro contrato (farm).
//  - getEthValue, esta funci??n nos permitir?? obtener el valor de los tokens de participaci??n (stake)
//    subyacentes (underlying) en la plataforma.

// L??nea 7: Creamos el contrato: TokenFarm.

// ENTONCES, vamos a comenzar con el staking de los tokens, la cual va a ser la pieza m??s importante
// de nuestra aplicaci??n.

// MIN: 12:57:21

// L??nea 10: Vamos a crear la funci??n: stakeTokens. Como primer par??metro la vamos a pasar: _amount, la cual
// hace referencia a la cantidad de tokens que deseamos stake. Como segundo par??metro le pasamos: _token,
// el cual hace referencia a la address desde la cual vamos a stake la cantidad de tokens almacenados en
// _amount.

// AHORA BIEN, lo primero que nos tenemos que preguntar para poder crear esta funci??n es:
//  - ??Con cuales tokens pueden los usuarios de mi aplicaci??n hacer staking?
//  - ??Cu??nto pueden ellos stake, es decir, la cantidad que pueden stake?

// ENTONCES, para nuestra aplicaci??n vamos a decir que podemos stake cualquier cantidad mayor a cero. Para
// esto vamos a utilizar un require().

// L??nea 14: Se requiere (require) que la cantidad de tokens que deseamos stake (_amount) sea mayor a cero (> 0),
// para que el c??digo contin??e ejecut??ndose. Si esta no es mayor a cero, entonces emita el siguiente mensaje:
// "Amount must be more than 0", y detenga la ejecuci??n del c??digo.
// NOTA. Como estamos utilizando la versi??n 8 de solidity: ^0.8.0, no tenemos que preocuparnos de safemath.

// AHORA BIEN, como ya tenemos la cantidad de tokens que podemos stake, vamos a deteminar cuales tokens son
// aquellos que nuestros usuarios podr??n stake en nuestra aplicaci??n.
// Para esto vamos a crear una funci??n llamada: tokenIsAllowed.

// MIN: 12:58:36
// L??nea 19: Creamos la funci??n: tokenIsAllowed(), la cual de encargar?? de determinar y especificar cuales tokens
// son permitidos por la aplicaci??n para que nuestros usuarios puedan stake.
// Como par??metro paso: _token, el cual hace referencia a la address desde la cual se toman los tokens.
// Esta funci??n returns, es decir, devuelve como valor un booleano (bool), ya que, devuelve True, si el token es
// permitido para stake, o devuelve False, si el token no es permitido.

// AHORA, vamos a crear una lista llamada: allowedTokens, la cual contendr?? todos los tokens (sus address) que
// van a ser permitidos (allowed) para stake en esta aplicaci??n.

// L??nea 8: Creamos la lista: allowedTokens, la cual contendr?? todos los tokens (sus address) que van a ser
// permitidos (allowed) para stake en esta aplicaci??n.

// AHORA BIEN, vamos a utilizar un for loop, para pasar por cada token en la lista: allowedTokens, para ver si
// el token que nuestros usuarios pretenden utilizar se encuentra en dicha lista.

// L??nea 20-24: Con el loop for, pasamos por por cada token en la lista: allowedTokens, para ver si el token que
// nuestros usuarios pretenden utilizar se encuentra en dicha lista.

// L??nea 25-26: Si (if) el token que est?? tratando de utilizar el usuario (_token), se encuentra en la lista:
// allowedTokens[allowedTokensIndex], entonces devuelva (return) true, ya que es un token permitido para
// hacer staking en nuestra aplicaci??n.

// L??nea 29: Devuelva (return) false, si una vez hemos ido con el for loop por toda la lista allowedTokens,
// y no hemos encontrado el token que nuestro usuario pretende utilizar, ya que en este caso ese token
// no estar??a permitido para hacer stake en esta aplicaci??n.

// AHORA, vamos a crear la funci??n: addAllowedTokens, la cual, permitir?? a??adir los tokens que ser??n
// permitidos.

// L??nea 15-16: Creamos la funci??n: addAllowedTokens, la cual permitir?? a??adir los tokens que ser??n permitidos.
// Pasamos onlyOwner, ya que vamos a querer que ??nicamente el due??o, o mejor, la wallet del due??o/propietario
// de este contrato pueda a??adir las tokens que son permitidas para hacer staking en esta aplicaci??n.
// Estos tokens permitidos (_token) los a??adimos con el m??todo .push() al array: allowedTokens.

// AHORA BIEN, como este contrato s??lo puede ser utilizado por el due??o de la wallet, en parte debido a la
// funci??n: addAllowedTokens, debemos hacer que este contrato sea Ownable, es decir, un contrato propiedad.
// Recordemos que, algunas funciones como el caso de: addAllowedTokens, s??lo pueden ser utilizadas por el
// due??o del contrato ya que de hacersen p??blicas, podr??an utilizarse de forma fraudulenta, malintencionada
// o err??nea, raz??n por la cual, tenemos que restringir el uso de dichas funciones, y por ende, el uso del
// contrato en s??, a ??nicamente addresses seleccionadas (normalmente, el address del propietario, como es
// el caso presente). Para esto, se crearon los contratos propiedad o Ownable Contracts.
// EN ESTE SENTIDO, vamos a crear uno ac??.

// L??nea 5: Vamos a volver nuestro contrato: TokenFarm, un contrato Ownable, adicionando la palabra clave:
// Ownable.

// COMO volvimos nuestro contrato Ownable, vamos a tener que importar el paquete Ownable de OpenZeppelin.

// L??nea 7: Convertimos el contrato: TokenFarm, Ownable, es decir, contrato propiedad, con el fin de restringir
// el uso de algunas funciones como: addAllowedTokens, a la wallet del propietario, y evitar hacer p??blico el
// uso de dicha funci??n, para prevenir el uso indebido, fraudulento o err??neo de dicha funci??n, y por ende, de
// este contrato.

// L??nea 5: Importamos el paquete: Ownable.sol, de openzeppelin.

// Guardamos y compilamos: brownie compile.

// MIN: 13:01:16
// AHORA BIEN, como ya hemos constru??do nuestras dos funciones: addAllowedTokens y stakeTokens, podemos
// comenzar a verificar si los tokens que los stakers (nuestros usuarios) van a utilizar para stake, son
// realmente permitidos.
// Para hacer esto, vamos a utilizar un require().

// L??nea 12: Si el token (_token) que utilizan nuestros usuarios para stake es permitido (funci??n: tokenIsAllowed),
// entonces, el require permitir?? que el c??digo contin??e ejecut??ndose, de lo contrario, el require detendr?? el
// c??digo, y devolver?? un mensaje: "Token is currently not allowed".

// MIN 13:02:16
// AHORA, lo que tenemos que hacer es llamar (call) la funci??n: transferFrom desde el contrato: ERC20.
// NOTA. Recordemos que, el contrato: ERC20, tiene 2 funciones del tipo transfer: transfer y transferFrom.
// Transfer, s??lo funciona si es llamada (call) desde la wallet que es due??a de los tokens. Si nosotros
// no somos los due??os de los tokens utilizamos: transferFrom.
// Ver: https://eips.ethereum.org/EIPS/eip-20

// ENTONCES, vamos a llamar (call) la funci??n: transferFrom, del contrato ERC20, ya que nuestro contrato
// TokenFarm, no es el due??o del ERC20.
// Tambi??n tenemos que tener el abi, que es el que realmente llama (call) la funci??n: transferFrom. PARA ESTO,
// vamos a necesitar tener la interface: IERC20.
// EN ESTE SENTIDO, vamos a importarla:

// L??nea 7: Importamos el paquete que contiene la interface: IERC20.sol, desde OpenZeppelin.
// NOTA. En este caso la importamos de openzeppelin, por lo cual, no tuvimos que crear una en la carpeta:
// interfaces.

// L??nea 17: Con el c??digo: IERC(_token), estamos obteniendo la ABI, desde la interface: IERC20, y su address:
// _token.
// Luego, llamamos (call) la funci??n: transferFrom(). Funci??n que llamamos desde el msg.sender. Y vamos a
// enviar o transferir, a este farm contract, es decir, address(this), una cantidad de tokens permitidos:
// _amount.
// EN OTRAS PALABRAS, en esta l??nea de c??digo, estamos transfiriendo una cantidad de tokens permitidos que
// nuestros usuarios quieren stake. Transferimos estos tokens permitidos a la address de este contrato que
// viene siendo el contrato Farm, donde se va a hacer el staking (address(this)).
// NOTA. Recordemos que, msg.sender, es la address que ha llamado una funci??n o creado una transacci??n, en
// este caso es la address que llama (call) la funci??n transferFrom, es decir, la address de nuestra wallet.
// O tambi??n podr??amos decir, que es la address que realiza la transferencia de los tokens desde su address
// o wallet, hacia la address de este contrato Farm (address(this)).

// MIN: 13:04:30
// AHORA BIEN, vamos a tener que hacer un seguimiento de cuantos de estos tokens, realmente, que se han transferido
// o enviado con la funci??n: transferFrom (l??nea 14), por parte de los usuarios que van a hacer staking. Es decir,
// cuantos de esos tokens realmente se nos han enviado.
// Para esto, vamos a crear un mapping.
// Este mapping va a asignar: el token address -> al staker address, y este a su vez lo va a asignar -> a la amount
// (cantidad de token). De esta forma, podremos tener seguimiento de cuanto de cada token cada staker ha staked.

// L??nea 11: Creamos el mapping llamado: stakingBalance, el cual es el mapping del token address (address), el
// cual va a ser asignado (mapped) a otro mapping de las addresses de los usuarios (address), el cual tambi??n
// va a ser asignado (mapped) a un valor del tipo uint256.
// Es decir, estamos asignando (mapping) la address del token, a la address del staker, que a su vez la estamos
// asignando (mapping) a la amount que es del tipo uint256.

// AHORA BIEN, como ya tenemos este mapping en nuestra funci??n: stakeToken(), podemos decir:

// L??nea 18-21: El stakingBalance (el mapping), del token que los usuarios est??n stake (_token), que est?? siendo
// enviado desde el msg.sender, es AHORA igual a, cual sea el balance que ellos (los usuarios) ten??an antes, mas
// la cantidad: _amount.
// EN OTRAS PALABRAS, lo que est?? diciendo la l??nea de c??digo es: el balance de staking del usuario que est??
// stakeando (es decir, el msg.sender) con su moneda (_token), va a ser igual a, ese mismo balance del mismo
// usuario, m??s la cantidad de token que ese usuario stakea, es decir, mete a la farm para el staking.
// La idea de escribir esta l??nea de c??digo, es precisamente, llevar un seguimiento o control de los token que
// se han a??adido para el staking, y de cual es la address del usuario que los est?? poniendo para el staking, el
// cual es en este caso el: msg.sender, ya que este es el que reqliza la transacci??n de env??o de los tokens (_token)
// hacia la address del contrato de esta farm (address(this)), tal como se aprecia en la anterior l??nea de c??digo.

// MIN: 13:05:45
// AHORA BIEN, vamos a crear nuestras issueTokens, las cuales vienen siendo una ganancia que nosotros damos a nuestros
// usuarios por utilizar nuestra plataforma, es decir, por hacer staking en nuestra Farm.

// ENTONCES, nosotros vamos a querer emitir (to issue) algunos tokens basados en el valor del token subyacente que ellos
// nos han dado.

// POR EJEMPLO, supongamos que un usuario nos da 100 ETH, y nosotros establecemos las ganancias a un ratio de 1:1, es decir,
// que por cada 1 ETH nosotros vamos a dar 1 DappToken de ganancia.
// AHORA, supongamos que otro usuario nos da para staking, 50 ETH y 50 DAI, y nosotros estamos dando 1 DAPP por 1 DAI, en
// este sentido, nosotros vamos a querer convertir todos los ETH en DAI.

// PARA ESTO, vamos a crear una funci??n llamada: issueTokens().

// L??nea 14: Creamos la funci??n: issueTokens(), la cual va a determinar y conceder el ratio de ganancias (rewards) para nuestros
// usuarios que utilicen nuestra plataforma.
// Establecemos que esta funci??n va a ser utilizada ??nicamente por el due??o o admin de este contrato con la key: onlyOwner.

// ENTONCES, ??c??mo emitimos (issue) los tokens? Pues bien, vamos a tener que ir a trav??s de una lista con un loop for, una lista
// de todos los stakers que tenemos. Por lo cual, vamos a tener que, primero, crear dicha lista.
// NOTA 1. Hasta el momento tenemos un mapping de stakers: stakingBalance; y, tenemos una lista de tokens permitidos: allowedTokens.
// NOTA 2. Recordemos que nosotros NO podemos ir a trav??s de un mapping con un for loop, por eso creamos una lista.

// L??nea 13: Creamos la lista: stakers. La cual, contiene todos los stakers que tenemos, es decir, los usuarios que nos dan sus
// diferentes tokens para hacer staking en nuestra plataforma.

// AHORA BIEN, cada vez que un usuario stake un token, vamos a tener que actualizar esta lista llamada: stakers.
// RESULTA IMPORTANTE, asegurarnos de S??LO a??adir a dicho usuario si no est?? previamente a??adido en la lista. Luego, en orden de
// poder hacer esto, nosotros deber??amos hacernos una idea de cuantos tokens ??nicos tiene dicho usuario. Para esto, vamos a
// crear una funci??n llamada: updateUniqueTokensStaked().

// L??nea 27: Creamos la funci??n: updateUniqueTokensStaked(), la cual nos va a mostrar la cantidad de tokens ??nicos que tiene un
// usuario. ENTONCES, si ese usuario tiene un token ??nico, vamos a a??adir al usuario a la lista: stakers. Si llegase a tener m??s
// de un token ??nico, entonces nosotros vamos a saber que ese usuario ha sido a??adido previamente a la lista, y no tendremos
// que a??adirlo nuevamente.
// Como par??metros pasamos: la address del usuario: _user; y la address del token: _token. Vamos a establecer la funci??n de tipo:
// internal, es decir, ??nicamente este contrato puede llamar (call) esta funci??n.

// L??nea 28-29: Si (if) el balance (stakingBalance) de los tokens (_token) que ha enviado el usuario (_user) para hacer staking en
// nuestra plataforma, es menor o igual (<=) a cero [l??nea 28]; ENTONCES, vamos a actualizar el mapping: uniqueTokensStaked del
// usuario (_user), por eso le sumamos: 1.

// ENTONCES, como hemos llamado ese mapping: uniqueTokensStaked dentro de la funci??n, pues vamos a crearlo.

// L??nea 11: Creamos el mapping: uniqueTokensStaked. Con este mapping, sabremos cuantos tokens diferentes o ??nicos han staked
// las diferentes addresses, es decir, los diferentes usuarios.

// AHORA BIEN, teniendo una mejor idea de los tokens ??nicos que cada uno de los usuarios han stake, lo que podemos hacer es
// descubrir o determinar si o no, deber??amos almacenarlos en la lista: stakers. Lista en la cual se encuentran los usuarios
// que est??n utilizando nuestra plataforma, y a los cuales vamos a recompensar con DAPP.

// L??nea 25-26: S?? (if) los tokens ??nicos (uniqueTokensStaked) del usuario (msg.sender) son iguales a 1, es decir, si es el
// primer token ??nico (uniqueTokensStaked) del usuario, ENTONCES, nosotros vamos a a??adir a ese usuario a la lista: stakers
// (stakers.push(msg.sender)).

// MIN: 13:10:30
// AHORA BIEN, como tenemos la lista stakers actualizada, podemos hacer el loop for en la funci??n: issueTokens().

// L??nea 17-20: Pasamos con el loop for a traves de la lista stakers. Repasar el loop for en Solidity.

// AHORA, vamos a emitir (issue) algunos tokens.

// L??nea 22: Creamos el objeto tipo address: recipient, el cual, contiene cada uno de los stakers. Es decir, cada vez que Yo
// paso con el loop for por la lista stakers, esta me devuelve uno por uno, cada staker. Toma un s??lo staker y lo almacena
// en el objeto recipent. Luego, el recipient contiene un staker.

// AHORA BIEN, como ya tengo cada recipient, es decir, cada address de cada usuario por separado, voy a tomar cada recipient
// y enviarle el token de ganancia DAPP, basados en el valor total bloqueado.

// AS?? LAS COSAS, vamos a crear un constructor, ya que. cuando despleguemos (deploy) el contrato nosotros necesitamos saber
// cual es la address del token DAPP, es decir, del token que vamos a dar como ganancia a los usuarios de nuestra plataforma.

// L??nea 16: Creamos el constructor, y le vamos a pasar como par??metro la address del token DAPP (_dappTokenAddress).

// L??nea 14: Almacenamos esta token DAPP, como una variable global llamada: dappToken.
// NOTA. Cuando me refiero a la DAPP Token, hago referencia a la que creamos con el contrato: DappToken.sol

// L??nea 17: Establecemos la dappToken, y la asociamos a su address.

// AHORA BIEN, como ya tenemos la token dapp asociada a su address, lo que podemos hacer ahora es llamar (call) funciones en
// ella.

// L??nea : Llamamos (call) la funci??n: transfer. Lo podemos hacer ac?? ya que nuestro contrato Farm va a ser el contrato que
// realmente posea todos esos DAPP tokens, es decir, el due??o.
// Como par??metro paso, primero, hacia donde voy a transferir esos dappToken, lo cual en este caso es: recipient. Es decir,
// a la address (wallet) del usuario que est?? haciendo staking en nuestra plataforma.
// Como segundo par??metro voy a pasar la cantidad de tokens que vamos a enviar. Para esto, vamos a crear una funci??n, ya que
// necesitamos determinar el valor total a enviar.

// MIN: 13:13:26

// L??nea 40: Creamos la funci??n: getUserTotalValue(), la cual, va a determinar el valor o cantidad de tokens totales que posee
// el usuario en la plataforma (), es decir, que los tiene en staking, con el fin de, con base en ese valor, poder determinar los
// tokens de ganancia, es decir, de DAPP Tokens, que vamos a enviar a los usuarios que utilicen nuestra palataforma.
// NOTA, Cuando nos referimos a tokens totales, hacemos referencia a la cantidad de todos los diferentes tokens que ha stakeado,
// ya que puede haber enviado a la plataforma: 50 ETH, 100 DAI, 75 SOL, etc. Ese getUserTotalValue, es la cantidad total de
// TODOS los diferentes tipos de tokens.
// ENTONCES, como sabemos, el env??o de cada token emitido conlleva un costo de gas fee que se paga a la blockchain, por lo cual,
// en vez de enviar y emitir los tokens, lo que muchos protocolos hacen es tener un m??odo interno que permita a los usuarios ir
// a la plataforma y reclamar sus tokens. Esto es debido a que es m??s econ??mico y eficiente que los usuarios vayan a la plataforma
// y reclamen sus aridrops (tokens) a que la plataforma o aplicaci??n los emita y env??e a sus usuarios.
// POR LO TANTO, con base en lo anterior, vamos a hacer esta funci??n de tipo view (consulta), la cual va a devolver (returns) un
// valor del tipo: uint256.

// L??nea 33: Creamos una variable llamada: totalValue, la cual la estableceremos para que inicie en 0.

// L??nea 34: Determinamos mediante un require que, si los tokens ??nicos (uniqueTokensStaked) del usuario (_user) son mayores a cero,
// entonces, el c??digo puede continuar ejecut??ndose; de no ser as??, se detiene el c??digo y se emite el mensaje: "No tokens staked!"
// EN OTRAS PALABRAS, si el usuario no tiene ning??n token ??nico, entonces el valor va a ser nada, por eso no se puede dar continuaidad
// al c??digo.

// ENTONCES, si el require se cumple, es decir, si el usuario tiene alg??n/nos tokens staked (en la plataforma haciendo staking), pues
// con un loop for vamos a ir por la lista: allowedTokens.

// L??nea 35-39: Con el loop for vamos a trav??s de la lista: allowedTokens.

// L??nea 40-45: Entonces, cada ve que pase el loop for, vamos a a??adir el totalValue. Es decir, el totalValue va a ser igual al totalValue
// m??s, cualquiera que sea el valor que este usuario tiene en tokens.
// Como sabemos, la funci??n getUserTotalValue, determina la cantidad TOTAL de todos los tipos diferentes de todos los tokens que el
// usuario est?? staking. En este caso, la funci??n: getUserSingleTokenValue(), determina la cantidad total de 1 s??lo token que el usuario
// est?? staking en nuestra plataforma.
// Por Ejemplo, si un usuario ha enviado a la aplicaci??n: 100 ETH, 50 DAI, 75 SOL, para staking, por un lado, la funci??n:
// getUserTotalValue, determina la cantidad TOTAL de TODOS los diferentes tipos de tokens que el usuario tiene staking. Mientras que
// por otro lado, la funci??n: getUserSingleTokenValue(), va a determinar la cantidad total de 1 s??lo token, por ejemplo, la cantidad
// total del token ETH que el usuario tiene staking en nuestra plataforma.
// ES POR ESTA RAZ??N QUE, el valor total: totalValue, va a ser igual al valor total (totalValue) que ya se tiene previamente, m??s
// el valor que arroje la funci??n: getUserSingleTokenValue, el cual hace referencia al valor total de 1 s??lo tipo de token que el
// usuario tiene en staking. En esta l??nea de c??digo lo que estamos haciendo es actualizar el valor total: totalValue.

// AHORA BIEN, como hemos llamado una nueva funci??n: getUserSingleTokenValue, y no la hemos creado, vamos a crearla.

// MIN: 13:16:10

// L??nea 49-52: Creamos la funci??n: getUserSingleTokenValue(). Como par??metros le pasamos: _user y _token: ambos de tipos address.
// La hacemos de tipo view, es decir, de tipo consulta. Y va a devolver (returns) un valor del tipo: uint256.
// LO QUE VA A HACER ESTA FUNCI??N ES, mostrarnos o devolvernos el valor de la cantidad total de un s??lo tipo de token (_token), que el
// usuario (_user) est?? staking. Es decir, nos devuelve cu??nta cantidad de determinado token ha stake ese usuario en nuestra
// aplicaci??n.
// Por ejemplo, si un usuario tiene en nuestra plataforma 1 ETH, y ese 1 ETH vale $2000 en ese momento, pues vamos a asegurarnos de
// que esta funci??n me devuelva como valor los $2000 d??lares. Lo mismo en el caso de otros tokens como DAI, etc.

// L??nea 54-55: S?? (if) la cantidad de tokens ??nicos que ha stake (uniqueTokensStaked) el usuario (_user) es menor o igual a cero, entonces
// que la funci??n nos devuelva: cero.
// NOTA: En este caso utilizamos un if statement y no utilizamos un require ya que, si no se cumple la condici??n, igual vamos a
// querer que el c??digo se siga ejecutando, y el require no lo permitir??a.

// AHORA, vamos a obtener el valor de un s??lo token. Para esto vamos a necesitar el staking balance, y tambi??n, vamos a necesitar el precio
// de dicho token. Es decir, vamos a obtener el precio del token y multiplicarlo por el staking balance del token del usuario
// (stakingBalance[_token][_user]).
// Para hacer esto, vamos a crear una nueva funci??n llamada: getTokenValue()

// MIN: 13:17:51

// L??nea 61: Creamos la funci??n: getTokenValue(), la cual nos va a devolver el valor de un s??lo token.

// AHORA BIEN, como vamos a tener que obtener los precios reales de los diferentes tokens para poder obtener su valor, vamos a tener que
// trabajar con el nodo Chainlink Price Feeds, es decir, vamos a tener que obtener el priceFeedAddress.
// Vamos a tener que mappear (asignar con mapping) cada token a cada uno de sus price feed addresses. Para esto, vamos a crear un
// mapping llamado: tokenPriceFeedMapping.

// L??nea 12: Creamos el mapping: tokenPriceFeedMapping, el cual va a mappear (asignar) cada token a su respectivo price feed address; price
// feed address que obtendremos del nodo Chainlink.
// N??tese que el mapping asigna una address a una address, es decir, va a asignar el token a su price feed address asociada.

// MIN:13:18:59
// AHORA BIEN, con lo anterior, vamos a tener que crear otra funci??n: setPriceFeedContract(), con la cual, vamos a configurar o establecer
// el price feed address asociado con el respectivo token.

// L??nea 21-23: Creamos la funci??n: setPriceFeedContract(). N??tese que establecemos onlyOwner, esto debido a que no queremos que nadie, a parte
// de nosotros (el admin y due??o del contrato) pueda ser capaz de configurar o establecer estos price feeds addresses.

// L??nea 25: El tokenPriceFeedMapping del token (_token), va a ser igual al price feed: _priceFeed.
// De esta forma, nosotros tenemos una forma de configurar o establecer el price feed contracts, es decir, tenemos una forma de mappear (asignar)
// los tokens a su respectivos price feeds address.

// AHORA BIEN, vamos a continuar creando la funci??n: getTokenValue(). Vamos ahora a tomar ese price feed address.

// L??nea 71: Con esta l??nea de c??digo tomamos el price feed token.

// PUES BIEN, como tenemos el priceFeedAddress del token, podemos utilizar este en un Aggregator V3 Interface.

// ENTONCES, nos dirigimos a: https://docs.chain.link/docs/get-the-latest-price/, y copiamos la l??nea de c??digo que importa el paquete del
// AggregatorV3Interface.sol

// L??nea 6: Pegamos la l??nea de c??digo que importa el paquete: AggregatorV3Interface. La copiamos de:
// https://docs.chain.link/docs/get-the-latest-price/

// RECORDEMOS QUE, como estamos importando el paquete AggregatorV3Interface desde chainlink debemos ir a nuestro brownie-config para
// configurar las dependencies y los remappings (MIN:13:20:50).

// AHORA BIEN, como ya hemos importado correctamente el AggregatorV3Interface, pordemos tomarlo en nuestro c??digo.

// L??nea 72-73: El AggregatorV3Interface del priceFeed, va a ser igual al, AggregatorV3Interface de dicho priceFeedAddress; es decir, estamos
// tomando el price feed contract, que es la interfaz que importamos del AggregatorV3Interface.sol.

// ENTONCES, como tenemos el contrato priceFeed, podemos llamar a la funci??n: latestRoundData(). Podemos ver lo que devuelve esta funci??n
// en: https://docs.chain.link/docs/get-the-latest-price/

// L??nea 75: Llamo (call) la funci??n: latestRoundData(), desde el contrato priceFeed que he obtenido del AggregatorV3Interface. Esta funci??n
// me devuelve varios valores, como podemos observar en: https://docs.chain.link/docs/get-the-latest-price/, sin embargo, en este caso,
// tan s??lo vamos a necesitar el valor price, por eso, s??lo coloco: int256 price. Los dem??s espacios los dejo vac??os.

// TAMBI??N debemos tener en cuenta los decimales, es decir, tenemos que saber cuantos decimales tiene el contrato priceFeed. Esto con el
// fin de poder tener tods en las mismas unidades.

// L??nea 76: Llamamos (call) la funci??n decimals(), desde el contrato priceFeed, y almacenamos lo devuelto en una variable llamada: decimals.

// L??nea 77: ENTONCES, establecemos que la funci??n nos va a devolver valores uint256, por un lado: price, y por el otro, decimals.

// NOTA. En la cabeza de la funci??n: getTokenValue, a??adimos un: uint256, porque realmente esta funci??n est?? devolviendo 2 valores uint256,
// el price y decimals, y esta funci??n s??lo ten??a que devolv??a (returns) un valor uint256, por eso a??adimos otro valor uint256 a returns.

// POR LO TANTO, regresamos a la funci??n: getUserSingleTokenValue(), y a??adimos estos dos valores que me retorna la funci??n: getTokenValue,
// es decir, price y decimals.

// L??nea 66: Con la funci??n: getTokenValue(), obtenemos el valor de un s??lo token, en este caso, del token que le estamos pasando con: _token.
// En este caso, la funci??n nos va a devolver 2 valores tipo uint256: price y decimals, donde price es el valor del token, y los decimals, son
// los decimales del valor.

// L??nea 67: La funci??n va a devolver la cantidad de token que el usuario ha stake. En c??digo: el balance (stakingBalance) del token (token)
// del usuario (user), multiplicado por el price que viene siendo el valor de un s??lo token en d??lares, multiplicado por 10 elevado (**) a
// los decimales del token (decimals).
// NOTA. Recordemos que, la funci??n: getUserSingleTokenValue(), va a devolver el valor o la cantidad de 1 s??lo token que el usuario tiene en
// staking en nuestra aplicaci??n.
// POR EJEMPLO, el usuario tiene en staking: 10 ETH. Entonces, nosotros vamos a obtener todos esos tokens (contratos) ETH convertidos a USD,
// es decir, nuestro priceFeed contract va a ser: ETH/USD, ya que es el que nos convierte esos tokens (contratos) ETH a USD.
// Entonces supongamos que el precio de 1 ETH en USD es 100, es decir, ETH/USD = 100. POR LO TANTO, podemos decir que:
// stakingBalance[token][user] * price ---> es lo mismo que ---> 10 * 100, donde 10 son los 10 ETH que el usuario tiene en staking, y 100 es
// el precio de un ETH es USD, es decir, ETH/USD = 100.
// AHORA BIEN, como sabemos, Solidity no reconoce valores en ETH sino en WEI, por lo cual, esos 10 ETH realmente van a ser: 10 * 10**18, es
// decir, 10000000000000000000. Y el precio de 1 ETH en USD, es decir, ETH/USD, no va a ser 100, sino 100 * 10**8, es decir,
// 10000000000.
// Esos dos valores se multiplican primero, y luego se dividen por los decimales, es decir, por: 10**decimals

// NOTA. Esta es una funci??n a la que S?? O S?? hay que realizarle un TEST, para verificar si est?? realizando bien las operaciones y devolviendo
// correctamente los valores.

// MIN: 13:25:11

// AHORA BIEN, como ya tenemos el valor: getUserSingleTokenValue, vamos regresar a la funci??n: getUserTotalValue.

// L??nea 55: Establecemos que la funci??n devuelva: return totalValue.
// NOTA. Como ya tenemos definida la funci??n: getUserSingleTokenValue, y ya podemos obtener el valor que esta nos devuelve, entonces podemos
// terminar esta funci??n sencillamente al colocar esta l??nea de c??digo de: return totalValue

// EN EL MISMO SENTIDO, como ya obtenemos el valor devuelto por: getUserTotalValue, nos dirigimos a la funci??n: issueTokens().

// ENTONCES, como ya tenemos el valor o cantidad total de tokens que posee el usuario en la plataforma (getUserTotalValue), es decir, que
// tiene en staking, ahora s?? podremos determinar y transferir la cantidad de tokens de ganancia, es decir, de DAPP tokens.

// L??nea 37: Con la funci??n getUserTotalValue, obtenemos el valor o cantidad total de tokens que posee el usuario en la plataforma, es decir,
// que esta en staking. Como par??metro pasamos: recipient, el cual, como lo vemos en la anterior l??nea de c??digo, contiene un s??lo staker, es
// decir, un s??lo usuario. M??s precisamente, la address de un s??lo usuario, ya que recipient es un objeto de tipo: address.
// EN OTRAS PALABRAS, getUserTotalValue(recipient), va a devolver la cantidad o valor total de tokens que posee el usuario/staker/address
// que se encuentra almacenado en recipient.
// Lo que devuelva esto, vamos a almacenarlo en: userTotalValue, que va a representar: el valor total de tokens de dicho usuario/address.

// L??nea 38: Ac?? estamos transfiriendo al usuario de nuestra plataforma, el token de ganancia por hacer staking en nuestra plataforma, es
// decir, dappToken.
// ENTONCES, lo que dice la l??nea es: transfiera (.tranfer()) el token/contrato llamado: dappToken, al recipient, el cual como sabemos
// contiene el staker o usuario  o m??s precisamente, su address. La cantidad de token DAPP que le vamos a pasar va a ser igual a la cantidad
// de token que represente el valor almacenado en: userTotalValue. Recordemos que estamos dando una ganancia de 1:1, es decir, por cada
// token que el usuario tenga en staking en nuestra plataforma, por ejemplo, ETH vamos a dar 1 DAPP. Por lo cual, si el usuario ha depositado
// 10 ETH para hacer staking en nuestra aplicaci??n, pues la ganancia va a ser de 10 DAPPS.

// MIN: 13:26:28

// PUES BIEN, hasta este moment ya tenemos: stakeTokens, issueTokens, addAllowedTokens, and getValue; lo que nos falta es: unstakeTokens, es
// decir, a??adir la forma en la cual nuestros usuarios puedan sacar sus tokens de nuestra aplicaci??n (dejar de hacer staking).

// L??nea 96: Creamos la funci??n: unstakeTokens(), la cual permitir?? a nuestros usuarios sacar sus tokens de nuestra aplicaci??n, es decir,
// dejar de hacer staking en nuestra aplicaci??n.
// Como par??metro pasamos el token (_token).

// ENTONCES, lo primero que vamos a querer hacer es buscar (fetch) el staking balance, con el fin de determinar cu??nto de este token tiene
// este usuario.

// L??nea 97: Ac?? estamos obteniendo el balance (stakingBalance) del token (_token) del usuario (msg.sender), y lo almacenamos en una variable
// llamada: balance.

// L??nea 98: Creamos un require en donde establecemos que s??, el balance del token de ese usuario es mayor que 0, entonces el c??digo puede
// seguir ejecut??ndose, de no ser as??, es decir, de no haber balance, significar??a que el usuario no tiene ning??n token haciendo staking
// en nuestra aplicaci??n, por lo cual, el c??digo se detendr??a, y se emitir??a el siguiente mensaje: "Staking balance cannot be 0".

// L??nea 99: Ac?? estamos haciendo una transferencia del token (_token) al usuario (msg.sender). La cantidad que estamos transfiriendo va a
// ser igual al balance. EN OTRAS PALABRAS, estamos transfiriendo los fondos (tokens) que este usuario tiene en staking (balance) a dicho
// usuario (msg.sender).

// L??nea 100: En esta l??nea de c??digo estamos actualizando el stakingBalance del token del usuario (msg.sender) a cero, ya que, en la
// anterior l??nea de c??digo hemos enviado el balance de todos los tokens de regreso a la cartera de este usuario.

// AHORA BIEN, vamos a actualizar cu??ntos de esos tokens ??nicos tiene el usuario.

// L??nea 101: Actualizamos la cantidad de tokens ??nicos que el usuario tiene al colocar -1.

// NOTA. En este punto: ??Puede ser este punto del c??digo una puerta a un ataque de re-entrada (re-entrancy attack)?

// AHORA, lo que deber??amos hacer es actualizar nuestro staker array, ya que el usuario ha sacado sus tokens de nuestra aplicaci??n de staking,
// por lo cual, ya no es un staker, y tenemos que removerlo de nuestra l??sta stakers.
// NO OBSTANTE, en este caso no lo hacen en el video ya que la funci??n: issueTokens(), siempre verifica la cantidad de tokens que el usuario
// tiene en staking, por lo cual, aunque se encuentre en la lista stakers, pues si no tiene tokens en staking, no se le van a emitir token
// de ganancia. SIN EMBARGO, m??s adelante cuando terminemos el curso, deber??amos volver y crear esta funci??n para dejar tods pulido.

// GUARDAMOS, Y COMPILAMOS: brownie compile

// MIN: 13:29:45
// AHORA BIEN, vamos a proceder y crear nuestro archivo: deploy.py, y de una vez creamos el: __init__.py, en la carpeta: scripts.

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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