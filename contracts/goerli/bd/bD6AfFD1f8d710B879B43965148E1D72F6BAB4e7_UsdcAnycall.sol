// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

abstract contract AdminControl {
    address public admin;
    address public pendingAdmin;

    event ChangeAdmin(address indexed _old, address indexed _new);
    event ApplyAdmin(address indexed _old, address indexed _new);

    constructor(address _admin) {
        require(_admin != address(0), "AdminControl: address(0)");
        admin = _admin;
        emit ChangeAdmin(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "AdminControl: not admin");
        _;
    }

    function changeAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "AdminControl: address(0)");
        pendingAdmin = _admin;
        emit ChangeAdmin(admin, _admin);
    }

    function applyAdmin() external {
        require(msg.sender == pendingAdmin, "AdminControl: Forbidden");
        emit ApplyAdmin(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import "../../../access/AdminControl.sol";
import "../interfaces/IAnycallProxy.sol";
import "../interfaces/IAnycallExecutor.sol";
import "../interfaces/IFeePool.sol";

abstract contract AppBase is AdminControl {
    address public callProxy;

    // associated client app on each chain
    mapping(uint256 => address) public clientPeers; // key is chainId

    modifier onlyExecutor() {
        require(
            msg.sender == IAnycallProxy(callProxy).executor(),
            "AppBase: onlyExecutor"
        );
        _;
    }

    constructor(address _admin, address _callProxy) AdminControl(_admin) {
        require(_callProxy != address(0));
        callProxy = _callProxy;
    }

    receive() external payable {}

    function withdraw(address _to, uint256 _amount) external onlyAdmin {
        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function setCallProxy(address _callProxy) external onlyAdmin {
        require(_callProxy != address(0));
        callProxy = _callProxy;
    }

    function setClientPeers(
        uint256[] calldata _chainIds,
        address[] calldata _peers
    ) external onlyAdmin {
        require(_chainIds.length == _peers.length);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            clientPeers[_chainIds[i]] = _peers[i];
        }
    }

    function _getAndCheckPeer(uint256 chainId) internal view returns (address) {
        address clientPeer = clientPeers[chainId];
        require(clientPeer != address(0), "AppBase: peer not exist");
        return clientPeer;
    }

    function _getAndCheckContext()
        internal
        view
        returns (
            address from,
            uint256 fromChainId,
            uint256 nonce
        )
    {
        address _executor = IAnycallProxy(callProxy).executor();
        (from, fromChainId, nonce) = IAnycallExecutor(_executor).context();
        require(clientPeers[fromChainId] == from, "AppBase: wrong context");
    }

    // if the app want to support `pay fee on destination chain`,
    // we'd better wrapper the interface `IFeePool` functions here.

    function depositFee() external payable {
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).deposit{value: msg.value}(address(this));
    }

    function withdrawFee(address _to, uint256 _amount) external onlyAdmin {
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).withdraw(_amount);

        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function withdrawAllFee(address _pool, address _to) external onlyAdmin {
        uint256 _amount = IFeePool(_pool).executionBudget(address(this));
        IFeePool(_pool).withdraw(_amount);

        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function executionBudget() external view returns (uint256) {
        address _pool = IAnycallProxy(callProxy).config();
        return IFeePool(_pool).executionBudget(address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import "../interfaces/IApp.sol";
import "../interfaces/AnycallFlags.sol";

import "./AppBase.sol";

interface CircleBridge {

    function depositForBurnWithCaller(
uint256 _amount,
uint32 _destinationDomain,
bytes32 _mintRecipient,
address _burnToken,
bytes32 _destinationCaller
) external returns (uint64 _nonce);

}

interface USDCMessageTransmitter {

   function receiveMessage(
        bytes memory _message,
        bytes calldata _attestation
    ) external returns (uint64 _nonce);

}

interface IERC20 {
    
    function balanceOf(address account) external view returns (uint256);



    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


    


contract UsdcAnycall is IApp, AppBase {
    event LogCallin(
        address sender,
        address receiver,
        uint amount,
        uint256 fromChainId,
        bytes sourcehash
    );

     // event for bridging out usdc
    event LogCallout(
        address sender,
        uint256 amount,
       
        address receiver,
        uint256 toChainId
    );

   
    event LogCalloutFail(
        string message,
        address sender,
        address receiver,
        uint256 toChainId
    );
    address usdcBridge;
    address usdcMessageTransmitter;
    address USDCtoken;
    constructor(address _admin, address _callProxy,address _usdcBridge, address _USDCMessageTransmitter,address _USDCtoken)  

        AppBase(_admin, _callProxy)
             {usdcBridge = _usdcBridge;
            usdcMessageTransmitter = _USDCMessageTransmitter;
            USDCtoken = _USDCtoken;}


    function bytesToAddress(bytes32 _input) internal pure returns (address) {
        return address(uint160(uint256(_input)));
    }

    function toBytes(address a) internal pure returns (bytes memory) {
    return abi.encodePacked(a);
}
    mapping(uint256 => bytes32) public clientPeersBytes32; // key is chainId

    function setClientPeersBytes32(
        uint256 _chainId,
        bytes32 _peer
    ) external onlyAdmin {

        clientPeersBytes32[_chainId] = _peer;

    }

    function _getAndCheckPeerBytes32(uint256 chainId) internal view returns (bytes32) {
        bytes32 clientPeer = clientPeersBytes32[chainId];
        require(clientPeer != 0x0000000000000000000000000000000000000000000000000000000000000000, "AppBase: bytes32 peer not exist");
        return clientPeer;
    }

    function callout(
        uint256 _amount,
        uint32 _destinationDomain,
        bytes32 _mintRecipient,
        address _burnToken,
        uint256 toChainId,
        uint256 anyCallflags
    ) external payable {
        address clientPeer = _getAndCheckPeer(toChainId);
        bytes32 clientPeerBytes=_getAndCheckPeerBytes32(toChainId);
        uint256 oldCoinBalance;

        if (msg.value > 0) {
            oldCoinBalance = address(this).balance - msg.value;
        }
        // transfer usdc from msg.sender to this contract
        IERC20(USDCtoken).transferFrom(msg.sender, address(this), _amount);

        // approve usdc to usdcBridge
        IERC20(USDCtoken).approve(usdcBridge, _amount);

        // call depositForBurnWithCaller
        CircleBridge(usdcBridge).depositForBurnWithCaller(
            _amount,
            _destinationDomain,
            _mintRecipient,
            _burnToken,
            clientPeerBytes);




        // encode the function inputs

        bytes memory data = abi.encode(
            _amount,
            bytesToAddress(_mintRecipient)
        );
        IAnycallProxy(callProxy).anyCall{value: msg.value}(
            clientPeer,
            data,
            toChainId,
            anyCallflags,
            "usdc"
        );

        if (msg.value > 0) {
            uint256 newCoinBalance = address(this).balance;
            if (newCoinBalance > oldCoinBalance) {
                // return remaining fees
                (bool success, ) = msg.sender.call{
                    value: newCoinBalance - oldCoinBalance
                }("");
                require(success);
            }
        }

        emit LogCallout(msg.sender,_amount, bytesToAddress(_mintRecipient) ,  toChainId);
    }

    /// @notice Call by `AnycallProxy` to execute a cross chain interaction on the destination chain
    function anyExecute(bytes calldata data)
        external
        override
        onlyExecutor
        returns (bool success, bytes memory result)
    {
        (address sender, uint256 fromChainId, ) = _getAndCheckContext();


        (uint _amount,address _mintRecipient,bytes memory _sourcehash,bytes memory _message,bytes memory _attestation) = abi
            .decode(data, (uint, address, bytes, bytes, bytes));
        
        // use the message transmitter by circle to claim usdc 
        USDCMessageTransmitter(usdcMessageTransmitter).receiveMessage(_message,_attestation);


        // add source chain hash
        emit LogCallin(sender, _mintRecipient, _amount,fromChainId,_sourcehash);
        return (true, "");
    }




}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

library AnycallFlags {
    uint256 public constant FLAG_NONE = 0x0;
    uint256 public constant FLAG_MERGE_CONFIG_FLAGS = 0x1;
    uint256 public constant FLAG_PAY_FEE_ON_DEST = 0x1 << 1;
    uint256 public constant FLAG_ALLOW_FALLBACK = 0x1 << 2;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

/// IAnycallExecutor interface of the anycall executor
interface IAnycallExecutor {
    function context()
        external
        view
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );

    function execute(
        address _to,
        bytes calldata _data,
        address _from,
        uint256 _fromChainID,
        uint256 _nonce,
        bytes calldata _extdata
    ) external returns (bool success, bytes memory result);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

/// IAnycallProxy interface of the anycall proxy
interface IAnycallProxy {
    function executor() external view returns (address);

    function config() external view returns (address);

    function anyCall(
        address _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;

    function anyCall(
        string calldata _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

/// IApp interface of the application
interface IApp {
    /// (required) call on the destination chain to exec the interaction
    function anyExecute(bytes calldata _data)
        external
        returns (bool success, bytes memory result);

    /// (optional,advised) call back on the originating chain if the cross chain interaction fails
    /// `_data` is the orignal interaction arguments exec on the destination chain
    // function anyFallback(bytes calldata _data)
    //     external
    //     returns (bool success, bytes memory result);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

interface IFeePool {
    function deposit(address _account) external payable;

    function withdraw(uint256 _amount) external;

    function executionBudget(address _account) external view returns (uint256);
}