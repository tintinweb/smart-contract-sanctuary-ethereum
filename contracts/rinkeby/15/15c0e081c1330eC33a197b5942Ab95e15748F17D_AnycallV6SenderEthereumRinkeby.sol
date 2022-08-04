// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface CallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external;
}

error AnycallV6SenderEthereumRinkeby_NotOwner();

contract AnycallV6SenderEthereumRinkeby {
    address private immutable OWNER_ADDRESS;

    // Multichain anycall contract on Rinkeby
    address private constant ANYCALL_CONTRACT_RINKEBY =
        0x273a4fFcEb31B8473D51051Ad2a2EdbB7Ac8Ce02;

    // Destination contract on Fantom testnet
    address private receiver_contract_fantom;

    uint256 public constant TEMP = 51;

    event NewMsgRequest(string msg);
    event NewMsgReceived(string msg);
    event AnycallRequest(
        address indexed anycallContract,
        address indexed _to,
        bytes _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    );

    modifier onlyOwner() {
        if (msg.sender != OWNER_ADDRESS) {
            revert AnycallV6SenderEthereumRinkeby_NotOwner();
        }
        _;
    }

    constructor(address _receiver_contract_fantom) {
        OWNER_ADDRESS = msg.sender;
        receiver_contract_fantom = _receiver_contract_fantom;
    }

    function initiateAnycallSimple(string calldata _msg) external onlyOwner {
        emit NewMsgRequest(_msg);

        CallProxy callProxy = CallProxy(ANYCALL_CONTRACT_RINKEBY);

        emit AnycallRequest(
            ANYCALL_CONTRACT_RINKEBY,
            receiver_contract_fantom,
            abi.encode(_msg),
            address(0),
            4002,
            0
        );

        callProxy.anyCall(
            receiver_contract_fantom,
            abi.encode(_msg),
            address(0), // Placeholder fallback
            4002, // Fantom testnet chain ID
            0 // Fee paid on destination chain (Fantom)
        );
    }

    function anyExecute(bytes calldata _data)
        external
        returns (bool success, bytes memory result)
    {
        string memory _msg = abi.decode((_data), (string));
        emit NewMsgReceived(_msg);
        return (true, "");
    }

    function setReceiverAddress(address _receiver_address) external onlyOwner {
        receiver_contract_fantom = _receiver_address;
    }
}