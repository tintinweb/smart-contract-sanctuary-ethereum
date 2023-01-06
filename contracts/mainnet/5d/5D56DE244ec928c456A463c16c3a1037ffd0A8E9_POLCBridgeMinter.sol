/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Managed {
  mapping(address => bool) public managers;
  modifier onlyManagers() {
    require(managers[msg.sender] == true, "Caller is not manager");
    _;
  }
  constructor() {
    managers[msg.sender] = true;
  }
  function setManager(address _wallet, bool _manager) public onlyManagers {
    require(_wallet != msg.sender, "Not allowed");
    managers[_wallet] = _manager;
  }
}

interface IBridgeLog {
  function outgoing(address _wallet, uint256 _amount, uint256 _fee, uint256 _chainID, uint256 _bridgeIndex) external;
  function incoming(address _wallet, uint256 _amount, uint256 _fee, uint256 _chainID, uint256 _logIndex, bytes32 _txHash) external;
  function withdrawalCompleted(bytes32 _withdrawalId) external view returns (bool completed);
}

interface IERC20Token {
    function mint(address account, uint256 value) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

library ECDSA {
  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;
    if (signature.length == 65) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
      }
    } else if (signature.length == 64) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        let vs := mload(add(signature, 0x40))
        r := mload(add(signature, 0x20))
        s := and(
          vs,
          0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        )
        v := add(shr(255, vs), 27)
      }
    } else {
      revert("ECDSA: invalid signature length");
    }

    return recover(hash, v, r, s);
  }

  function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
    require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
    require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

    // If the signature is valid (and not malleable), return the signer address
    address signer = ecrecover(hash, v, r, s);
    require(signer != address(0), "ECDSA: invalid signature");
    return signer;
  }

  function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
  }
}

contract POLCBridgeMinter is Managed {
  IERC20Token private polcToken;
  IBridgeLog private logger;
  address signer;
  uint256 chainID;
  address platformWallet;
  address banksWallet;
  address polcVault;
  uint256 txMode; // 0 minting, 1 transfer
  bool paused;
  
  constructor() {
    polcToken = IERC20Token(0xaA8330FB2B4D5D07ABFE7A72262752a8505C6B37);
    logger = IBridgeLog(0x923076A69B52f5E98C95D8C61EfA20CD46F15062);
    chainID = 1;
    polcVault = 0xf7A9F6001ff8b499149569C54852226d719f2D76;
    platformWallet = 0x00d6E1038564047244Ad37080E2d695924F8515B;
    banksWallet = 0x57379373df97B21d5cDCdA4A718432704Bd0c2A6;
    signer = 0xa4C03a9B4f1c67aC645A990DDB7B8A27D4D9e7af;
    managers[0x00d6E1038564047244Ad37080E2d695924F8515B] = true;
  }

  function verifyTXCall(bytes32 _taskHash, bytes memory _sig) public view returns (bool valid) {
    address mSigner = ECDSA.recover(ECDSA.toEthSignedMessageHash(_taskHash), _sig);
    if (mSigner == signer) {
      return true;
    } else {
      return false;
    }
  }

  function withdraw(address _wallet, uint256 _amount, uint256 _fee, uint256 _chainFrom, uint256 _chainTo, uint256 _logIndex, bytes memory _sig) public {
    require(!paused, "Contract is paused");
    require(_chainTo == chainID, "Invalid chain");
    bytes32 txHash = keccak256(abi.encode(_wallet, _amount, _fee, _chainFrom, _chainTo, _logIndex));
    bool txv = verifyTXCall(txHash, _sig);
    require (txv == true, "Invalid signature");
    require(logger.withdrawalCompleted(txHash) == false, "Withdrawal already completed");
    logger.incoming(_wallet, _amount, _fee, _chainFrom, _logIndex, txHash);
    uint256 platformFees;
    if (_fee > 0) {
      platformFees = (_fee * 75) / 100;
    }
    if (txMode == 0) {
      polcToken.mint(_wallet, _amount-_fee);
      if (platformFees > 0) {
        polcToken.mint(platformWallet, platformFees);
        polcToken.mint(banksWallet, _fee - platformFees);
      }
    } else {
      require(polcToken.transferFrom(polcVault, _wallet, (_amount - _fee)), "ERC20 transfer error");
        if (platformFees > 0) {
        require(polcToken.transferFrom(polcVault, platformWallet, platformFees), "ERC20 transfer error");
        require(polcToken.transferFrom(polcVault, banksWallet, (_fee - platformFees)), "ERC20 transfer error");
      }
    }
  }

  function setLogger (address _logger) public onlyManagers {
    logger = IBridgeLog(_logger);
  }
  
  function setSigner (address _signer) public onlyManagers {
    signer = _signer;
  }

  function setBanksWallet(address _wallet) public onlyManagers {
    banksWallet = _wallet;
  }

  function setVault(address _wallet) public onlyManagers {
    polcVault = _wallet;
  }

  function setPlatformWallet(address _wallet) public onlyManagers {
    platformWallet = _wallet;
  }
  
  function pauseContract(bool _paused) public onlyManagers {
    paused = _paused;
  }

  function setMode(uint256 _mode) public onlyManagers {
    txMode = _mode;
  }
}