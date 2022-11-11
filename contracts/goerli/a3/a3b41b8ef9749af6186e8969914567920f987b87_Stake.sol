// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IStarknetCore.sol";

contract Stake {

  ///////////////////////////////////////////////////////////////////////////////////   
 //                                   Constantes                                  //                         
///////////////////////////////////////////////////////////////////////////////////

    // El selector del "depósito" l1_handler.
    uint256 constant DEPOSIT_SELECTOR = 352040181584456735608515580760888541466059565068553383579463728554843487745;

    // Índice de retirada de mensajes
    uint256 constant WITHDRAWAL_INDEX = 1;

  /////////////////////////////////////////////////////////////////////////////////     
 //                                   Almacenamiento                            //                              
/////////////////////////////////////////////////////////////////////////////////

    /// El contrato principal de StarkNet
    IStarknetCore immutable public starknetCore;

    /// Dirección del contrato de participación L2
    uint256 public stakeL2Address;

  ///////////////////////////////////////////////////////////////////////////////////   
 //                                   Constructor                                 //                         
///////////////////////////////////////////////////////////////////////////////////

    /// @param starknetCore_ Dirección de contrato de StarknetCore utilizada para mensajería L1 a L2
    /// @param stakeL2Address_ Dirección del contrato de Stake L2
    constructor(
        IStarknetCore starknetCore_,
        uint256 stakeL2Address_
    ) {
        require(address(starknetCore_) != address(0));

        starknetCore = starknetCore_;
        stakeL2Address = stakeL2Address_;
    }

  /////////////////////////////////////////////////////////////////////////////////     
 //                                Funciones Externas                           //                              
/////////////////////////////////////////////////////////////////////////////////

    // @dev Función para depositar ETH en el contrato Stake
    function stake()
        external
        payable
    {

        uint256 senderAsUint256 = uint256(uint160(msg.sender));

        uint256[] memory payload = new uint256[](2);
        payload[0] = senderAsUint256;
        payload[1] = msg.value;

        starknetCore.sendMessageToL2(
            stakeL2Address,
            DEPOSIT_SELECTOR,
            payload
        );
    }

    // @dev función para retirar fondos de un contrato de Cuenta L2
    // @param amount_ - La cantidad de tokens a retirar
    function withdraw(
        uint256 amount_
    ) external {
        uint256 senderAsUint256 = uint256(uint160(msg.sender));

        uint256[] memory payload = new uint256[](3);
        payload[0] = WITHDRAWAL_INDEX;
        payload[1] = senderAsUint256;
        payload[2] = amount_;

        // La llamada consumida se revertirá si no existe ningún mensaje coincidente
        starknetCore.consumeMessageFromL2(
            stakeL2Address,
            payload
        );

        payable(msg.sender).transfer(amount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Starts the cancellation of an L1 to L2 message.
      A message can be canceled messageCancellationDelay() seconds after this function is called.
      Note: This function may only be called for a message that is currently pending and the caller
      must be the sender of the that message.
    */
    function startL1ToL2MessageCancellation(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external;

    /**
      Cancels an L1 to L2 message, this function should be called messageCancellationDelay() seconds
      after the call to startL1ToL2MessageCancellation().
    */
    function cancelL1ToL2Message(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external;
}