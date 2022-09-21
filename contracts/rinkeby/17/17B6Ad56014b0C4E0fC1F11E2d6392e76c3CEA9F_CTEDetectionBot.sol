/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

interface IForta {
    function setDetectionBot(address detectionBotAddress) external;
    function notify(address user, bytes calldata msgData) external;
    function raiseAlert(address user) external;
}

contract Forta is IForta {
  mapping(address => IDetectionBot) public usersDetectionBots;
  mapping(address => uint256) public botRaisedAlerts;

  function setDetectionBot(address detectionBotAddress) external override {
      require(address(usersDetectionBots[msg.sender]) == address(0), "DetectionBot already set");
      usersDetectionBots[msg.sender] = IDetectionBot(detectionBotAddress);
  }

  function notify(address user, bytes calldata msgData) external override {
    if(address(usersDetectionBots[user]) == address(0)) return;
    try usersDetectionBots[user].handleTransaction(user, msgData) {
        return;
    } catch {}
  }

  function raiseAlert(address user) external override {
      if(address(usersDetectionBots[user]) != msg.sender) return;
      botRaisedAlerts[msg.sender] += 1;
  } 
}

contract CTEDetectionBot is IDetectionBot{
    event HandleMessage(address user, bytes msgData);
    event MessageData(bytes msgData);

    address public FortaAddr;
    address public crypteAddr;

    bytes public calldataAtHandleTransaction;
    bytes public parameterAtHandleTransaction;
    function handleTransaction(address user, bytes calldata msgData) external override {
        // emit HandleMessage(user, msgData);

        address calldatamsg;
        assembly {
            calldatamsg := calldataload(0xa8)
        }

        if(calldatamsg == crypteAddr) {
            raiseAl(user);
        }
    }

    function setCryptoAddr(address addr) public {
        crypteAddr = addr;
    }

    function exampleData(bytes calldata msgData) external {
        calldataAtHandleTransaction = msg.data;
        parameterAtHandleTransaction = msgData;
    }

    function setForta(address addr) public {
        FortaAddr = addr;
        IForta forta = IForta(FortaAddr);
        forta.setDetectionBot(address(this));
    }

    function raiseAl(address user) public {
        IForta forta = IForta(FortaAddr);
        forta.raiseAlert(user);
    }
}

contract TestDet {
  address botAddress;

  function setBotAddr(address addr) public {
    botAddress = addr;
  }

  function delegateTransfer(
    address addr1, // 0x1111111111111111111111111111111111111111
    uint256 val1,  // 10
    address addr2  // 0x2222222222222222222222222222222222222222
  ) external {
    CTEDetectionBot(botAddress).exampleData(msg.data);
  }
}

// Forta = await contract.forta()
// CryptoVault = await contract.cryptoVault()
// DelegatedFrom = await contract.delegatedFrom()
// cteaddr = '0x69759514f4913918a5b8d7470e2fD01769c952EF'

// funSetDetect = {
//     name:'setDetectionBot',
//     type:'function',
//     inputs:[
//         {
//             name:"detectionBotAddress",
//             type:"address"
//         }
//         ]
// }

// paSet = [cteaddr]
// dataSet = web3.eth.abi.encodeFunctionCall(funSetDetect, paSet)
// await web3.eth.sendTransaction({from:player, to:Forta, data:dataSet})

// funSweep = {
//     name:'sweepToken',
//     type:'function',
//     inputs:[
//         {
//             name:"token",
//             type:"address"
//         }
//         ]
// }

// paSweep = [DelegatedFrom]
// dataSweep = web3.eth.abi.encodeFunctionCall(funSweep, paSweep)
// await web3.eth.sendTransaction({from:player, to:CryptoVault, data:dataSweep})

// 00000000
// 0000000000000000000000000000000000000000000000000000004000000000
// 000000000000000000000000000000000000000000000000000000649cd1a121
// 0000000000000000000000008491cf503dc1c6f0c7375fb6dc7e9a3402adb430
// 0000000000000000000000000000000000000000000000056bc75e2d63100000
// 00000000000000000000000087b7693b4081181536161a40458060acff7a23c0
// 00000000000000000000000000000000000000000000000000000000



// 0x220ab6aa
// // user
// 0000000000000000000000008491cf503dc1c6f0c7375fb6dc7e9a3402adb430
// // msg_data
// 0000000000000000000000000000000000000000000000000000000000000040
// 0000000000000000000000000000000000000000000000000000000000000064
// 9cd1a121
// 0000000000000000000000008491cf503dc1c6f0c7375fb6dc7e9a3402adb430
// 0000000000000000000000000000000000000000000000056bc75e2d63100000
// 00000000000000000000000080e665df23197dc3fe435e9ff72ed398379c97fd
// 00000000000000000000000000000000000000000000000000000000

// 0x9cd1a121
// 0000000000000000000000008491cf503dc1c6f0c7375fb6dc7e9a3402adb430
// 0000000000000000000000000000000000000000000000056bc75e2d63100000
// 000000000000000000000000c6c8841add1341c1eadac6b10520a8a4b7a7fdf3