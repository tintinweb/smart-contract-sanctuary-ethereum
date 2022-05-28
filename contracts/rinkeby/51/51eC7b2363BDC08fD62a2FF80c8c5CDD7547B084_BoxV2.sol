// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 private value;

    event ValueChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }

    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }
}

// EXPLICACIÃ“N CÃ“DIGO.

// Como podemos observar, este contrato: BoxV2.sol, es exactamente igual al contrato: Box.sol, salvo
// que este contrato tiene aÃ±adida la funciÃ³n: increment(), en la lÃ­nea 19 de este cÃ³digo.

// LÃ­nea 5: Cambiamos el nombre del contrato de: Box a BoxV2.

// AHORA BIEN, de lo que se trata este proyecto es de estudiar las Upgrades (actualizaciones) de los
// contratos.
// En este sentido, vamos a verificar si un contrato ha sido actualizado.

// ENTONCES, si nosotros podemos llamar (call) la funciÃ³n: increment() en la misma address en la cual,
// hemos desplegado (deploy) originalmente el contrato: Box.sol, esto significarÃ­a que el contrato ha
// sido actualizado (upgraded).

// GETTING THE PROXY CONTRACTS (MIN: 12:06:01)

// AHORA BIEN, para poder trabajar con los proxies y con el transparent proxy, nosotros vamos a necesitar
// aÃ±adirlos a nuestro proyecto brownie.
// Para esto, vamos a crear una carpeta en la carpeta contracts llamada: transparent_proxy. Dentro de esta
// carpeta, voy a crear dos archivos: ProxyAdmin.sol, y TransparentUpgradeableProxy.sol
// Para el ProxyAdmin.sol, copiamos tods el cÃ³igo de:
// https://github.com/PatrickAlphaC/upgrades-mix/blob/main/contracts/transparent_proxy/ProxyAdmin.sol
// y lo pegamos en dicho contrato: ProxyAdmin.sol

// COMO PODEMOS OBSERVAR, en la lÃ­neas 5-6 del cÃ³digo del contrato: ProxyAdmin.sol, el cÃ³digo es directamente
// extraÃ­do del paquete de Open Zeppelin, nosotros tenemos que llenar ese import. Como sabemos, lo vamos
// a hacer con las dependencies, desde nuestro brownie-config, por lo cual lo vamos a crear. El resto de la
// configuraciÃ³n la podemos ver en el MIN: 12:06:51

// El cÃ³digo de l archivo que tambiÃ©n creamos y copiamos llamado: TransparentUpgradeableProxy.sol, lo encontramos en:
// https://github.com/PatrickAlphaC/upgrades-mix/blob/main/contracts/transparent_proxy/TransparentUpgradeableProxy.sol

// Relizado esto: brownie compile

// COMO PODEMOS OBSERVAR, ya tenemos nuestro contrato Box.sol, al igual que nuestro contrato, BoxV2.sol. TambiÃ©n,
// tenemos nuestros Proxy contracts en la carpeta: transparent_proxy, los cuales podemos utilizar para actualizar
// el contrato Box.sol a una nueva versiÃ³n. (MIN: 12:09:11)

// AHORA BIEN, vamos a crear el archivo: 01_deploy_box.sol, en nuestra carpeta: scripts. En este archivo,
// es donde vamos a desplegar (deploy) el contrato box.sol

//