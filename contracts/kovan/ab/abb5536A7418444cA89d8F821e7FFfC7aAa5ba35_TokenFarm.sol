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

// EXPLICACIÓN CÓDIGO.

// MIN: 12:56:11
// PUES BIEN, una vez creado y compilado el contrato que crea nuestro token DAPP (DappToken.sol),
// vamos a crear el contrato Token Farm. Para esto lo creamos en la carpeta: contracts, y nos
// dirigimos hacia allá.

// ENTONCES, lo que vamos a hacer capaces de hacer con este contrato va ser:
//  - StakeTokens, es decir, hacer staking con tokens que almacenemos en la farm.
//  - unStakeTokens, es decir, ser capaces de retirar los tokens que hemos puesto en staking.
//  - issueTokens, los cuales se van a encargar de emitir los tokens rewards, es decir, los tokens
//    que vamos a dar como ganancia a los usuarios que nos den sus tokens para hacer staking.
//  - addAllowedTokens, los cuales nos permitirán añadir más tokens que serán permitidos (allowed)
//    para que los usuarios hagan staking en nuestro contrato (farm).
//  - getEthValue, esta función nos permitirá obtener el valor de los tokens de participación (stake)
//    subyacentes (underlying) en la plataforma.

// Línea 7: Creamos el contrato: TokenFarm.

// ENTONCES, vamos a comenzar con el staking de los tokens, la cual va a ser la pieza más importante
// de nuestra aplicación.

// MIN: 12:57:21

// Línea 10: Vamos a crear la función: stakeTokens. Como primer parámetro la vamos a pasar: _amount, la cual
// hace referencia a la cantidad de tokens que deseamos stake. Como segundo parámetro le pasamos: _token,
// el cual hace referencia a la address desde la cual vamos a stake la cantidad de tokens almacenados en
// _amount.

// AHORA BIEN, lo primero que nos tenemos que preguntar para poder crear esta función es:
//  - ¿Con cuales tokens pueden los usuarios de mi aplicación hacer staking?
//  - ¿Cuánto pueden ellos stake, es decir, la cantidad que pueden stake?

// ENTONCES, para nuestra aplicación vamos a decir que podemos stake cualquier cantidad mayor a cero. Para
// esto vamos a utilizar un require().

// Línea 14: Se requiere (require) que la cantidad de tokens que deseamos stake (_amount) sea mayor a cero (> 0),
// para que el código continúe ejecutándose. Si esta no es mayor a cero, entonces emita el siguiente mensaje:
// "Amount must be more than 0", y detenga la ejecución del código.
// NOTA. Como estamos utilizando la versión 8 de solidity: ^0.8.0, no tenemos que preocuparnos de safemath.

// AHORA BIEN, como ya tenemos la cantidad de tokens que podemos stake, vamos a deteminar cuales tokens son
// aquellos que nuestros usuarios podrán stake en nuestra aplicación.
// Para esto vamos a crear una función llamada: tokenIsAllowed.

// MIN: 12:58:36
// Línea 19: Creamos la función: tokenIsAllowed(), la cual de encargará de determinar y especificar cuales tokens
// son permitidos por la aplicación para que nuestros usuarios puedan stake.
// Como parámetro paso: _token, el cual hace referencia a la address desde la cual se toman los tokens.
// Esta función returns, es decir, devuelve como valor un booleano (bool), ya que, devuelve True, si el token es
// permitido para stake, o devuelve False, si el token no es permitido.

// AHORA, vamos a crear una lista llamada: allowedTokens, la cual contendrá todos los tokens (sus address) que
// van a ser permitidos (allowed) para stake en esta aplicación.

// Línea 8: Creamos la lista: allowedTokens, la cual contendrá todos los tokens (sus address) que van a ser
// permitidos (allowed) para stake en esta aplicación.

// AHORA BIEN, vamos a utilizar un for loop, para pasar por cada token en la lista: allowedTokens, para ver si
// el token que nuestros usuarios pretenden utilizar se encuentra en dicha lista.

// Línea 20-24: Con el loop for, pasamos por por cada token en la lista: allowedTokens, para ver si el token que
// nuestros usuarios pretenden utilizar se encuentra en dicha lista.

// Línea 25-26: Si (if) el token que está tratando de utilizar el usuario (_token), se encuentra en la lista:
// allowedTokens[allowedTokensIndex], entonces devuelva (return) true, ya que es un token permitido para
// hacer staking en nuestra aplicación.

// Línea 29: Devuelva (return) false, si una vez hemos ido con el for loop por toda la lista allowedTokens,
// y no hemos encontrado el token que nuestro usuario pretende utilizar, ya que en este caso ese token
// no estaría permitido para hacer stake en esta aplicación.

// AHORA, vamos a crear la función: addAllowedTokens, la cual, permitirá añadir los tokens que serán
// permitidos.

// Línea 15-16: Creamos la función: addAllowedTokens, la cual permitirá añadir los tokens que serán permitidos.
// Pasamos onlyOwner, ya que vamos a querer que únicamente el dueño, o mejor, la wallet del dueño/propietario
// de este contrato pueda añadir las tokens que son permitidas para hacer staking en esta aplicación.
// Estos tokens permitidos (_token) los añadimos con el método .push() al array: allowedTokens.

// AHORA BIEN, como este contrato sólo puede ser utilizado por el dueño de la wallet, en parte debido a la
// función: addAllowedTokens, debemos hacer que este contrato sea Ownable, es decir, un contrato propiedad.
// Recordemos que, algunas funciones como el caso de: addAllowedTokens, sólo pueden ser utilizadas por el
// dueño del contrato ya que de hacersen públicas, podrían utilizarse de forma fraudulenta, malintencionada
// o errónea, razón por la cual, tenemos que restringir el uso de dichas funciones, y por ende, el uso del
// contrato en sí, a únicamente addresses seleccionadas (normalmente, el address del propietario, como es
// el caso presente). Para esto, se crearon los contratos propiedad o Ownable Contracts.
// EN ESTE SENTIDO, vamos a crear uno acá.

// Línea 5: Vamos a volver nuestro contrato: TokenFarm, un contrato Ownable, adicionando la palabra clave:
// Ownable.

// COMO volvimos nuestro contrato Ownable, vamos a tener que importar el paquete Ownable de OpenZeppelin.

// Línea 7: Convertimos el contrato: TokenFarm, Ownable, es decir, contrato propiedad, con el fin de restringir
// el uso de algunas funciones como: addAllowedTokens, a la wallet del propietario, y evitar hacer público el
// uso de dicha función, para prevenir el uso indebido, fraudulento o erróneo de dicha función, y por ende, de
// este contrato.

// Línea 5: Importamos el paquete: Ownable.sol, de openzeppelin.

// Guardamos y compilamos: brownie compile.

// MIN: 13:01:16
// AHORA BIEN, como ya hemos construído nuestras dos funciones: addAllowedTokens y stakeTokens, podemos
// comenzar a verificar si los tokens que los stakers (nuestros usuarios) van a utilizar para stake, son
// realmente permitidos.
// Para hacer esto, vamos a utilizar un require().

// Línea 12: Si el token (_token) que utilizan nuestros usuarios para stake es permitido (función: tokenIsAllowed),
// entonces, el require permitirá que el código continúe ejecutándose, de lo contrario, el require detendrá el
// código, y devolverá un mensaje: "Token is currently not allowed".

// MIN 13:02:16
// AHORA, lo que tenemos que hacer es llamar (call) la función: transferFrom desde el contrato: ERC20.
// NOTA. Recordemos que, el contrato: ERC20, tiene 2 funciones del tipo transfer: transfer y transferFrom.
// Transfer, sólo funciona si es llamada (call) desde la wallet que es dueña de los tokens. Si nosotros
// no somos los dueños de los tokens utilizamos: transferFrom.
// Ver: https://eips.ethereum.org/EIPS/eip-20

// ENTONCES, vamos a llamar (call) la función: transferFrom, del contrato ERC20, ya que nuestro contrato
// TokenFarm, no es el dueño del ERC20.
// También tenemos que tener el abi, que es el que realmente llama (call) la función: transferFrom. PARA ESTO,
// vamos a necesitar tener la interface: IERC20.
// EN ESTE SENTIDO, vamos a importarla:

// Línea 7: Importamos el paquete que contiene la interface: IERC20.sol, desde OpenZeppelin.
// NOTA. En este caso la importamos de openzeppelin, por lo cual, no tuvimos que crear una en la carpeta:
// interfaces.

// Línea 17: Con el código: IERC(_token), estamos obteniendo la ABI, desde la interface: IERC20, y su address:
// _token.
// Luego, llamamos (call) la función: transferFrom(). Función que llamamos desde el msg.sender. Y vamos a
// enviar o transferir, a este farm contract, es decir, address(this), una cantidad de tokens permitidos:
// _amount.
// EN OTRAS PALABRAS, en esta línea de código, estamos transfiriendo una cantidad de tokens permitidos que
// nuestros usuarios quieren stake. Transferimos estos tokens permitidos a la address de este contrato que
// viene siendo el contrato Farm, donde se va a hacer el staking (address(this)).
// NOTA. Recordemos que, msg.sender, es la address que ha llamado una función o creado una transacción, en
// este caso es la address que llama (call) la función transferFrom, es decir, la address de nuestra wallet.
// O también podríamos decir, que es la address que realiza la transferencia de los tokens desde su address
// o wallet, hacia la address de este contrato Farm (address(this)).

// MIN: 13:04:30
// AHORA BIEN, vamos a tener que hacer un seguimiento de cuantos de estos tokens, realmente, que se han transferido
// o enviado con la función: transferFrom (línea 14), por parte de los usuarios que van a hacer staking. Es decir,
// cuantos de esos tokens realmente se nos han enviado.
// Para esto, vamos a crear un mapping.
// Este mapping va a asignar: el token address -> al staker address, y este a su vez lo va a asignar -> a la amount
// (cantidad de token). De esta forma, podremos tener seguimiento de cuanto de cada token cada staker ha staked.

// Línea 11: Creamos el mapping llamado: stakingBalance, el cual es el mapping del token address (address), el
// cual va a ser asignado (mapped) a otro mapping de las addresses de los usuarios (address), el cual también
// va a ser asignado (mapped) a un valor del tipo uint256.
// Es decir, estamos asignando (mapping) la address del token, a la address del staker, que a su vez la estamos
// asignando (mapping) a la amount que es del tipo uint256.

// AHORA BIEN, como ya tenemos este mapping en nuestra función: stakeToken(), podemos decir:

// Línea 18-21: El stakingBalance (el mapping), del token que los usuarios están stake (_token), que está siendo
// enviado desde el msg.sender, es AHORA igual a, cual sea el balance que ellos (los usuarios) tenían antes, mas
// la cantidad: _amount.
// EN OTRAS PALABRAS, lo que está diciendo la línea de código es: el balance de staking del usuario que está
// stakeando (es decir, el msg.sender) con su moneda (_token), va a ser igual a, ese mismo balance del mismo
// usuario, más la cantidad de token que ese usuario stakea, es decir, mete a la farm para el staking.
// La idea de escribir esta línea de código, es precisamente, llevar un seguimiento o control de los token que
// se han añadido para el staking, y de cual es la address del usuario que los está poniendo para el staking, el
// cual es en este caso el: msg.sender, ya que este es el que reqliza la transacción de envío de los tokens (_token)
// hacia la address del contrato de esta farm (address(this)), tal como se aprecia en la anterior línea de código.

// MIN: 13:05:45
// AHORA BIEN, vamos a crear nuestras issueTokens, las cuales vienen siendo una ganancia que nosotros damos a nuestros
// usuarios por utilizar nuestra plataforma, es decir, por hacer staking en nuestra Farm.

// ENTONCES, nosotros vamos a querer emitir (to issue) algunos tokens basados en el valor del token subyacente que ellos
// nos han dado.

// POR EJEMPLO, supongamos que un usuario nos da 100 ETH, y nosotros establecemos las ganancias a un ratio de 1:1, es decir,
// que por cada 1 ETH nosotros vamos a dar 1 DappToken de ganancia.
// AHORA, supongamos que otro usuario nos da para staking, 50 ETH y 50 DAI, y nosotros estamos dando 1 DAPP por 1 DAI, en
// este sentido, nosotros vamos a querer convertir todos los ETH en DAI.

// PARA ESTO, vamos a crear una función llamada: issueTokens().

// Línea 14: Creamos la función: issueTokens(), la cual va a determinar y conceder el ratio de ganancias (rewards) para nuestros
// usuarios que utilicen nuestra plataforma.
// Establecemos que esta función va a ser utilizada únicamente por el dueño o admin de este contrato con la key: onlyOwner.

// ENTONCES, ¿cómo emitimos (issue) los tokens? Pues bien, vamos a tener que ir a través de una lista con un loop for, una lista
// de todos los stakers que tenemos. Por lo cual, vamos a tener que, primero, crear dicha lista.
// NOTA 1. Hasta el momento tenemos un mapping de stakers: stakingBalance; y, tenemos una lista de tokens permitidos: allowedTokens.
// NOTA 2. Recordemos que nosotros NO podemos ir a través de un mapping con un for loop, por eso creamos una lista.

// Línea 13: Creamos la lista: stakers. La cual, contiene todos los stakers que tenemos, es decir, los usuarios que nos dan sus
// diferentes tokens para hacer staking en nuestra plataforma.

// AHORA BIEN, cada vez que un usuario stake un token, vamos a tener que actualizar esta lista llamada: stakers.
// RESULTA IMPORTANTE, asegurarnos de SÓLO añadir a dicho usuario si no está previamente añadido en la lista. Luego, en orden de
// poder hacer esto, nosotros deberíamos hacernos una idea de cuantos tokens únicos tiene dicho usuario. Para esto, vamos a
// crear una función llamada: updateUniqueTokensStaked().

// Línea 27: Creamos la función: updateUniqueTokensStaked(), la cual nos va a mostrar la cantidad de tokens únicos que tiene un
// usuario. ENTONCES, si ese usuario tiene un token único, vamos a añadir al usuario a la lista: stakers. Si llegase a tener más
// de un token único, entonces nosotros vamos a saber que ese usuario ha sido añadido previamente a la lista, y no tendremos
// que añadirlo nuevamente.
// Como parámetros pasamos: la address del usuario: _user; y la address del token: _token. Vamos a establecer la función de tipo:
// internal, es decir, únicamente este contrato puede llamar (call) esta función.

// Línea 28-29: Si (if) el balance (stakingBalance) de los tokens (_token) que ha enviado el usuario (_user) para hacer staking en
// nuestra plataforma, es menor o igual (<=) a cero [línea 28]; ENTONCES, vamos a actualizar el mapping: uniqueTokensStaked del
// usuario (_user), por eso le sumamos: 1.

// ENTONCES, como hemos llamado ese mapping: uniqueTokensStaked dentro de la función, pues vamos a crearlo.

// Línea 11: Creamos el mapping: uniqueTokensStaked. Con este mapping, sabremos cuantos tokens diferentes o únicos han staked
// las diferentes addresses, es decir, los diferentes usuarios.

// AHORA BIEN, teniendo una mejor idea de los tokens únicos que cada uno de los usuarios han stake, lo que podemos hacer es
// descubrir o determinar si o no, deberíamos almacenarlos en la lista: stakers. Lista en la cual se encuentran los usuarios
// que están utilizando nuestra plataforma, y a los cuales vamos a recompensar con DAPP.

// Línea 25-26: Sí (if) los tokens únicos (uniqueTokensStaked) del usuario (msg.sender) son iguales a 1, es decir, si es el
// primer token único (uniqueTokensStaked) del usuario, ENTONCES, nosotros vamos a añadir a ese usuario a la lista: stakers
// (stakers.push(msg.sender)).

// MIN: 13:10:30
// AHORA BIEN, como tenemos la lista stakers actualizada, podemos hacer el loop for en la función: issueTokens().

// Línea 17-20: Pasamos con el loop for a traves de la lista stakers. Repasar el loop for en Solidity.

// AHORA, vamos a emitir (issue) algunos tokens.

// Línea 22: Creamos el objeto tipo address: recipient, el cual, contiene cada uno de los stakers. Es decir, cada vez que Yo
// paso con el loop for por la lista stakers, esta me devuelve uno por uno, cada staker. Toma un sólo staker y lo almacena
// en el objeto recipent. Luego, el recipient contiene un staker.

// AHORA BIEN, como ya tengo cada recipient, es decir, cada address de cada usuario por separado, voy a tomar cada recipient
// y enviarle el token de ganancia DAPP, basados en el valor total bloqueado.

// ASÍ LAS COSAS, vamos a crear un constructor, ya que. cuando despleguemos (deploy) el contrato nosotros necesitamos saber
// cual es la address del token DAPP, es decir, del token que vamos a dar como ganancia a los usuarios de nuestra plataforma.

// Línea 16: Creamos el constructor, y le vamos a pasar como parámetro la address del token DAPP (_dappTokenAddress).

// Línea 14: Almacenamos esta token DAPP, como una variable global llamada: dappToken.
// NOTA. Cuando me refiero a la DAPP Token, hago referencia a la que creamos con el contrato: DappToken.sol

// Línea 17: Establecemos la dappToken, y la asociamos a su address.

// AHORA BIEN, como ya tenemos la token dapp asociada a su address, lo que podemos hacer ahora es llamar (call) funciones en
// ella.

// Línea : Llamamos (call) la función: transfer. Lo podemos hacer acá ya que nuestro contrato Farm va a ser el contrato que
// realmente posea todos esos DAPP tokens, es decir, el dueño.
// Como parámetro paso, primero, hacia donde voy a transferir esos dappToken, lo cual en este caso es: recipient. Es decir,
// a la address (wallet) del usuario que está haciendo staking en nuestra plataforma.
// Como segundo parámetro voy a pasar la cantidad de tokens que vamos a enviar. Para esto, vamos a crear una función, ya que
// necesitamos determinar el valor total a enviar.

// MIN: 13:13:26

// Línea 40: Creamos la función: getUserTotalValue(), la cual, va a determinar el valor o cantidad de tokens totales que posee
// el usuario en la plataforma (), es decir, que los tiene en staking, con el fin de, con base en ese valor, poder determinar los
// tokens de ganancia, es decir, de DAPP Tokens, que vamos a enviar a los usuarios que utilicen nuestra palataforma.
// NOTA, Cuando nos referimos a tokens totales, hacemos referencia a la cantidad de todos los diferentes tokens que ha stakeado,
// ya que puede haber enviado a la plataforma: 50 ETH, 100 DAI, 75 SOL, etc. Ese getUserTotalValue, es la cantidad total de
// TODOS los diferentes tipos de tokens.
// ENTONCES, como sabemos, el envío de cada token emitido conlleva un costo de gas fee que se paga a la blockchain, por lo cual,
// en vez de enviar y emitir los tokens, lo que muchos protocolos hacen es tener un méodo interno que permita a los usuarios ir
// a la plataforma y reclamar sus tokens. Esto es debido a que es más económico y eficiente que los usuarios vayan a la plataforma
// y reclamen sus aridrops (tokens) a que la plataforma o aplicación los emita y envíe a sus usuarios.
// POR LO TANTO, con base en lo anterior, vamos a hacer esta función de tipo view (consulta), la cual va a devolver (returns) un
// valor del tipo: uint256.

// Línea 33: Creamos una variable llamada: totalValue, la cual la estableceremos para que inicie en 0.

// Línea 34: Determinamos mediante un require que, si los tokens únicos (uniqueTokensStaked) del usuario (_user) son mayores a cero,
// entonces, el código puede continuar ejecutándose; de no ser así, se detiene el código y se emite el mensaje: "No tokens staked!"
// EN OTRAS PALABRAS, si el usuario no tiene ningún token único, entonces el valor va a ser nada, por eso no se puede dar continuaidad
// al código.

// ENTONCES, si el require se cumple, es decir, si el usuario tiene algún/nos tokens staked (en la plataforma haciendo staking), pues
// con un loop for vamos a ir por la lista: allowedTokens.

// Línea 35-39: Con el loop for vamos a través de la lista: allowedTokens.

// Línea 40-45: Entonces, cada ve que pase el loop for, vamos a añadir el totalValue. Es decir, el totalValue va a ser igual al totalValue
// más, cualquiera que sea el valor que este usuario tiene en tokens.
// Como sabemos, la función getUserTotalValue, determina la cantidad TOTAL de todos los tipos diferentes de todos los tokens que el
// usuario está staking. En este caso, la función: getUserSingleTokenValue(), determina la cantidad total de 1 sólo token que el usuario
// está staking en nuestra plataforma.
// Por Ejemplo, si un usuario ha enviado a la aplicación: 100 ETH, 50 DAI, 75 SOL, para staking, por un lado, la función:
// getUserTotalValue, determina la cantidad TOTAL de TODOS los diferentes tipos de tokens que el usuario tiene staking. Mientras que
// por otro lado, la función: getUserSingleTokenValue(), va a determinar la cantidad total de 1 sólo token, por ejemplo, la cantidad
// total del token ETH que el usuario tiene staking en nuestra plataforma.
// ES POR ESTA RAZÓN QUE, el valor total: totalValue, va a ser igual al valor total (totalValue) que ya se tiene previamente, más
// el valor que arroje la función: getUserSingleTokenValue, el cual hace referencia al valor total de 1 sólo tipo de token que el
// usuario tiene en staking. En esta línea de código lo que estamos haciendo es actualizar el valor total: totalValue.

// AHORA BIEN, como hemos llamado una nueva función: getUserSingleTokenValue, y no la hemos creado, vamos a crearla.

// MIN: 13:16:10

// Línea 49-52: Creamos la función: getUserSingleTokenValue(). Como parámetros le pasamos: _user y _token: ambos de tipos address.
// La hacemos de tipo view, es decir, de tipo consulta. Y va a devolver (returns) un valor del tipo: uint256.
// LO QUE VA A HACER ESTA FUNCIÓN ES, mostrarnos o devolvernos el valor de la cantidad total de un sólo tipo de token (_token), que el
// usuario (_user) está staking. Es decir, nos devuelve cuánta cantidad de determinado token ha stake ese usuario en nuestra
// aplicación.
// Por ejemplo, si un usuario tiene en nuestra plataforma 1 ETH, y ese 1 ETH vale $2000 en ese momento, pues vamos a asegurarnos de
// que esta función me devuelva como valor los $2000 dólares. Lo mismo en el caso de otros tokens como DAI, etc.

// Línea 54-55: Sí (if) la cantidad de tokens únicos que ha stake (uniqueTokensStaked) el usuario (_user) es menor o igual a cero, entonces
// que la función nos devuelva: cero.
// NOTA: En este caso utilizamos un if statement y no utilizamos un require ya que, si no se cumple la condición, igual vamos a
// querer que el código se siga ejecutando, y el require no lo permitiría.

// AHORA, vamos a obtener el valor de un sólo token. Para esto vamos a necesitar el staking balance, y también, vamos a necesitar el precio
// de dicho token. Es decir, vamos a obtener el precio del token y multiplicarlo por el staking balance del token del usuario
// (stakingBalance[_token][_user]).
// Para hacer esto, vamos a crear una nueva función llamada: getTokenValue()

// MIN: 13:17:51

// Línea 61: Creamos la función: getTokenValue(), la cual nos va a devolver el valor de un sólo token.

// AHORA BIEN, como vamos a tener que obtener los precios reales de los diferentes tokens para poder obtener su valor, vamos a tener que
// trabajar con el nodo Chainlink Price Feeds, es decir, vamos a tener que obtener el priceFeedAddress.
// Vamos a tener que mappear (asignar con mapping) cada token a cada uno de sus price feed addresses. Para esto, vamos a crear un
// mapping llamado: tokenPriceFeedMapping.

// Línea 12: Creamos el mapping: tokenPriceFeedMapping, el cual va a mappear (asignar) cada token a su respectivo price feed address; price
// feed address que obtendremos del nodo Chainlink.
// Nótese que el mapping asigna una address a una address, es decir, va a asignar el token a su price feed address asociada.

// MIN:13:18:59
// AHORA BIEN, con lo anterior, vamos a tener que crear otra función: setPriceFeedContract(), con la cual, vamos a configurar o establecer
// el price feed address asociado con el respectivo token.

// Línea 21-23: Creamos la función: setPriceFeedContract(). Nótese que establecemos onlyOwner, esto debido a que no queremos que nadie, a parte
// de nosotros (el admin y dueño del contrato) pueda ser capaz de configurar o establecer estos price feeds addresses.

// Línea 25: El tokenPriceFeedMapping del token (_token), va a ser igual al price feed: _priceFeed.
// De esta forma, nosotros tenemos una forma de configurar o establecer el price feed contracts, es decir, tenemos una forma de mappear (asignar)
// los tokens a su respectivos price feeds address.

// AHORA BIEN, vamos a continuar creando la función: getTokenValue(). Vamos ahora a tomar ese price feed address.

// Línea 71: Con esta línea de código tomamos el price feed token.

// PUES BIEN, como tenemos el priceFeedAddress del token, podemos utilizar este en un Aggregator V3 Interface.

// ENTONCES, nos dirigimos a: https://docs.chain.link/docs/get-the-latest-price/, y copiamos la línea de código que importa el paquete del
// AggregatorV3Interface.sol

// Línea 6: Pegamos la línea de código que importa el paquete: AggregatorV3Interface. La copiamos de:
// https://docs.chain.link/docs/get-the-latest-price/

// RECORDEMOS QUE, como estamos importando el paquete AggregatorV3Interface desde chainlink debemos ir a nuestro brownie-config para
// configurar las dependencies y los remappings (MIN:13:20:50).

// AHORA BIEN, como ya hemos importado correctamente el AggregatorV3Interface, pordemos tomarlo en nuestro código.

// Línea 72-73: El AggregatorV3Interface del priceFeed, va a ser igual al, AggregatorV3Interface de dicho priceFeedAddress; es decir, estamos
// tomando el price feed contract, que es la interfaz que importamos del AggregatorV3Interface.sol.

// ENTONCES, como tenemos el contrato priceFeed, podemos llamar a la función: latestRoundData(). Podemos ver lo que devuelve esta función
// en: https://docs.chain.link/docs/get-the-latest-price/

// Línea 75: Llamo (call) la función: latestRoundData(), desde el contrato priceFeed que he obtenido del AggregatorV3Interface. Esta función
// me devuelve varios valores, como podemos observar en: https://docs.chain.link/docs/get-the-latest-price/, sin embargo, en este caso,
// tan sólo vamos a necesitar el valor price, por eso, sólo coloco: int256 price. Los demás espacios los dejo vacíos.

// TAMBIÉN debemos tener en cuenta los decimales, es decir, tenemos que saber cuantos decimales tiene el contrato priceFeed. Esto con el
// fin de poder tener tods en las mismas unidades.

// Línea 76: Llamamos (call) la función decimals(), desde el contrato priceFeed, y almacenamos lo devuelto en una variable llamada: decimals.

// Línea 77: ENTONCES, establecemos que la función nos va a devolver valores uint256, por un lado: price, y por el otro, decimals.

// NOTA. En la cabeza de la función: getTokenValue, añadimos un: uint256, porque realmente esta función está devolviendo 2 valores uint256,
// el price y decimals, y esta función sólo tenía que devolvía (returns) un valor uint256, por eso añadimos otro valor uint256 a returns.

// POR LO TANTO, regresamos a la función: getUserSingleTokenValue(), y añadimos estos dos valores que me retorna la función: getTokenValue,
// es decir, price y decimals.

// Línea 66: Con la función: getTokenValue(), obtenemos el valor de un sólo token, en este caso, del token que le estamos pasando con: _token.
// En este caso, la función nos va a devolver 2 valores tipo uint256: price y decimals, donde price es el valor del token, y los decimals, son
// los decimales del valor.

// Línea 67: La función va a devolver la cantidad de token que el usuario ha stake. En código: el balance (stakingBalance) del token (token)
// del usuario (user), multiplicado por el price que viene siendo el valor de un sólo token en dólares, multiplicado por 10 elevado (**) a
// los decimales del token (decimals).
// NOTA. Recordemos que, la función: getUserSingleTokenValue(), va a devolver el valor o la cantidad de 1 sólo token que el usuario tiene en
// staking en nuestra aplicación.
// POR EJEMPLO, el usuario tiene en staking: 10 ETH. Entonces, nosotros vamos a obtener todos esos tokens (contratos) ETH convertidos a USD,
// es decir, nuestro priceFeed contract va a ser: ETH/USD, ya que es el que nos convierte esos tokens (contratos) ETH a USD.
// Entonces supongamos que el precio de 1 ETH en USD es 100, es decir, ETH/USD = 100. POR LO TANTO, podemos decir que:
// stakingBalance[token][user] * price ---> es lo mismo que ---> 10 * 100, donde 10 son los 10 ETH que el usuario tiene en staking, y 100 es
// el precio de un ETH es USD, es decir, ETH/USD = 100.
// AHORA BIEN, como sabemos, Solidity no reconoce valores en ETH sino en WEI, por lo cual, esos 10 ETH realmente van a ser: 10 * 10**18, es
// decir, 10000000000000000000. Y el precio de 1 ETH en USD, es decir, ETH/USD, no va a ser 100, sino 100 * 10**8, es decir,
// 10000000000.
// Esos dos valores se multiplican primero, y luego se dividen por los decimales, es decir, por: 10**decimals

// NOTA. Esta es una función a la que SÍ O SÍ hay que realizarle un TEST, para verificar si está realizando bien las operaciones y devolviendo
// correctamente los valores.

// MIN: 13:25:11

// AHORA BIEN, como ya tenemos el valor: getUserSingleTokenValue, vamos regresar a la función: getUserTotalValue.

// Línea 55: Establecemos que la función devuelva: return totalValue.
// NOTA. Como ya tenemos definida la función: getUserSingleTokenValue, y ya podemos obtener el valor que esta nos devuelve, entonces podemos
// terminar esta función sencillamente al colocar esta línea de código de: return totalValue

// EN EL MISMO SENTIDO, como ya obtenemos el valor devuelto por: getUserTotalValue, nos dirigimos a la función: issueTokens().

// ENTONCES, como ya tenemos el valor o cantidad total de tokens que posee el usuario en la plataforma (getUserTotalValue), es decir, que
// tiene en staking, ahora sí podremos determinar y transferir la cantidad de tokens de ganancia, es decir, de DAPP tokens.

// Línea 37: Con la función getUserTotalValue, obtenemos el valor o cantidad total de tokens que posee el usuario en la plataforma, es decir,
// que esta en staking. Como parámetro pasamos: recipient, el cual, como lo vemos en la anterior línea de código, contiene un sólo staker, es
// decir, un sólo usuario. Más precisamente, la address de un sólo usuario, ya que recipient es un objeto de tipo: address.
// EN OTRAS PALABRAS, getUserTotalValue(recipient), va a devolver la cantidad o valor total de tokens que posee el usuario/staker/address
// que se encuentra almacenado en recipient.
// Lo que devuelva esto, vamos a almacenarlo en: userTotalValue, que va a representar: el valor total de tokens de dicho usuario/address.

// Línea 38: Acá estamos transfiriendo al usuario de nuestra plataforma, el token de ganancia por hacer staking en nuestra plataforma, es
// decir, dappToken.
// ENTONCES, lo que dice la línea es: transfiera (.tranfer()) el token/contrato llamado: dappToken, al recipient, el cual como sabemos
// contiene el staker o usuario  o más precisamente, su address. La cantidad de token DAPP que le vamos a pasar va a ser igual a la cantidad
// de token que represente el valor almacenado en: userTotalValue. Recordemos que estamos dando una ganancia de 1:1, es decir, por cada
// token que el usuario tenga en staking en nuestra plataforma, por ejemplo, ETH vamos a dar 1 DAPP. Por lo cual, si el usuario ha depositado
// 10 ETH para hacer staking en nuestra aplicación, pues la ganancia va a ser de 10 DAPPS.

// MIN: 13:26:28

// PUES BIEN, hasta este moment ya tenemos: stakeTokens, issueTokens, addAllowedTokens, and getValue; lo que nos falta es: unstakeTokens, es
// decir, añadir la forma en la cual nuestros usuarios puedan sacar sus tokens de nuestra aplicación (dejar de hacer staking).

// Línea 96: Creamos la función: unstakeTokens(), la cual permitirá a nuestros usuarios sacar sus tokens de nuestra aplicación, es decir,
// dejar de hacer staking en nuestra aplicación.
// Como parámetro pasamos el token (_token).

// ENTONCES, lo primero que vamos a querer hacer es buscar (fetch) el staking balance, con el fin de determinar cuánto de este token tiene
// este usuario.

// Línea 97: Acá estamos obteniendo el balance (stakingBalance) del token (_token) del usuario (msg.sender), y lo almacenamos en una variable
// llamada: balance.

// Línea 98: Creamos un require en donde establecemos que sí, el balance del token de ese usuario es mayor que 0, entonces el código puede
// seguir ejecutándose, de no ser así, es decir, de no haber balance, significaría que el usuario no tiene ningún token haciendo staking
// en nuestra aplicación, por lo cual, el código se detendría, y se emitiría el siguiente mensaje: "Staking balance cannot be 0".

// Línea 99: Acá estamos haciendo una transferencia del token (_token) al usuario (msg.sender). La cantidad que estamos transfiriendo va a
// ser igual al balance. EN OTRAS PALABRAS, estamos transfiriendo los fondos (tokens) que este usuario tiene en staking (balance) a dicho
// usuario (msg.sender).

// Línea 100: En esta línea de código estamos actualizando el stakingBalance del token del usuario (msg.sender) a cero, ya que, en la
// anterior línea de código hemos enviado el balance de todos los tokens de regreso a la cartera de este usuario.

// AHORA BIEN, vamos a actualizar cuántos de esos tokens únicos tiene el usuario.

// Línea 101: Actualizamos la cantidad de tokens únicos que el usuario tiene al colocar -1.

// NOTA. En este punto: ¿Puede ser este punto del código una puerta a un ataque de re-entrada (re-entrancy attack)?

// AHORA, lo que deberíamos hacer es actualizar nuestro staker array, ya que el usuario ha sacado sus tokens de nuestra aplicación de staking,
// por lo cual, ya no es un staker, y tenemos que removerlo de nuestra lísta stakers.
// NO OBSTANTE, en este caso no lo hacen en el video ya que la función: issueTokens(), siempre verifica la cantidad de tokens que el usuario
// tiene en staking, por lo cual, aunque se encuentre en la lista stakers, pues si no tiene tokens en staking, no se le van a emitir token
// de ganancia. SIN EMBARGO, más adelante cuando terminemos el curso, deberíamos volver y crear esta función para dejar tods pulido.

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