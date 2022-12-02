// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

import "./EnumerableSet.sol";
import "./LibString.sol";

/// @title Cross-chain main contract
contract EthCrossChainContractApp {

  using EnumerableSet for EnumerableSet.UintSet;

  enum TxResultEnum {
    INIT,
    ACK_SUCCESS,
    ACK_FAIL,
    ACK_TIMEOUT
  }

  /// @dev Store refund results of cross-chain transactions
  /// @dev Three states: no refund required, to be refunded, refunded
  enum TxRefundedEnum {
    NONE,
    TODO,
    REFUNDED
  }

  /// @dev Role of chain: Source chain, target chain and relay chain
  enum TxOriginEnum {
    SRC,
    DEST,
    RELAY
  }

  /// @notice Event emitted when gateway is set
  event setGatewayEvent(string operation, string chainCode, string crossContract, address[] gateway_Address);

  /// @notice Event emitted when erc20 address is set
  event setERC20AddressEvent(string operation, address addr);

  /// @notice Event emitted when erc721 address is set
  event setERC721AddressEvent(string operation, address addr);

  /// @notice Event emitted when user sent cross-chain transaction
  event startTxEvent(string operation, string cross_TxNo, uint8 payloadType);

  /// @notice Event emitted when gateway submitted cross-chain transaction
  event sendTxEvent(string operation, string cross_TxNo, uint8 payloadType);

  /// @notice Event emitted when gateway submitted cross-chain transaction confirmation
  event sendAckedEvent(string operation, string cross_TxNo, uint8 payloadType);

  event logEvent(string operation, string para1, string para2, string para3);

  event equalEvent(string operation, bool bEqual, uint leftData, uint rightData);

  /// @notice Event emitted when the main chain points are cast
  event AssetMintEvent(
    string operation,
    address from,
    address to,
    uint256 value
  );

  /// @notice Event emitted when the main chain points is transferred
  event transferEvent(string operation, uint256 value);

  /// @notice Event emitted when assets withdrawn
  event takeOutEvent(string operation, address to);

  struct _CrossTxObj {
    string CrossTxNo;
    string SrcChainCode;
    string DestChainCode;
    string SrcCrossContract;
    string DestCrossContract;
    string SrcAddress;
    string DestAddress;
    uint8 PayloadType;
    bytes Payload;
    string Remark;
    TxResultEnum Result;
    TxRefundedEnum Refunded;
    string Extension;
    _SendProof SendProofs;
    _AckProof AckProofs;
    string Version;
    TxOriginEnum Origin;
  }

  /// @notice SendTx proof information
  /// @member block number where the transaction is located
  /// @member hash of transaction
  /// @member verifier of startTx transactions
  struct _SendProof {
    uint256 LedgerSeq;
    string TxHash;
    address verifieraddr;
  }

  /// @notice SendAcked proof information
  /// @member block number where the transaction is located
  /// @member hash of transaction
  /// @member verifier of sendTx and sendAcked transactions
  struct _AckProof {
    uint256 LedgerSeq;
    string TxHash;
    address verifieraddr;
  }

  /// @dev The person who deployed the contract
  address internal _Owner;

  /// @dev Store AC code
  string internal _ChainCode;

  /// @dev ERC20 Address
  address internal _erc20Address;

  /// @dev ERC721 Address
  address internal _erc721Address;

  /// @dev Gateway node list
  mapping(bytes => address[]) internal _GatewayList;

  /// @dev managers list
  address[] internal _ManagersList;

  /// @dev Contract version information
  string internal _Version;

  mapping(bytes => _CrossTxObj) internal _CrossTxObject;

  /// @dev Number of main chain points
  mapping(bytes => uint256) internal _Asset;

  // erc721 Mapping from holder address to their (enumerable) set of owned tokens
  mapping(bytes => EnumerableSet.UintSet) private _HolderTokens;

  /// @dev Used to calculate cross-chain transaction number
  uint256 internal _CrossTxNum;

  bool private _Init;

  string constant _ERC20 = "_erc20_";

  string constant _ERC721 = "_erc721_";

  constructor(string memory chainCode, address[] memory managersList) {
    _initialize(chainCode, managersList);
  }

  /// @notice Check whether it is a gateway node
  function checkSenderApprove(address[] memory accountList) internal view returns (bool) {
    for (uint256 i = 0; i < accountList.length; i++) {
      if (accountList[i] == msg.sender) {
        return true;
      }
    }
    return false;
  }


  /// @notice Cross-chain contract initialization. Can be executed once.
  function _initialize(string memory chainCode, address[] memory managersList) internal {
    require(_Init == false, "contract initialized");
    _Owner = msg.sender;
    _Version = "1.0.0";
    require(managersList.length != 0, "managersList is  null");
    _ManagersList = managersList;
    _ChainCode = chainCode;
    _Init = true;
    _CrossTxNum = 0;
  }


  modifier onlyManager() {
    require(
      checkSenderApprove(_ManagersList) == true,
      "This function need manager"
    );
    _;

  }


  /// @notice Check whether it is a gateway node
  /// @notice crossContract not contain chainCode!!!!
  function checkGateNode(string memory chainCode, string memory crossContract) internal view returns (bool) {
    if (LibString.equal(chainCode, _ChainCode) != true) {
      return false;
    }
    address[] memory gateWayList = _GatewayList[abi.encodePacked(chainCode, crossContract)];
    return checkSenderApprove(gateWayList);

  }

  /// @notice Set subchain cross-chain gateway. Can only be executed by the contract owner.
  function setGateway(string memory chainCode, address[] memory gatewayList, string memory crossContract) external onlyManager {
    // require(crossContract == address(this), "gatewayList is null");
    require(gatewayList.length != 0, "gatewayList is null");
    _GatewayList[abi.encodePacked(chainCode, crossContract)] = gatewayList;

    emit setGatewayEvent("setGateway", chainCode, crossContract, gatewayList);
  }

  /// @notice Set erc20 address. Can only be executed by the contract owner.
  function setERC20Address(address addr) external onlyManager {

    _erc20Address = addr;

    emit setERC20AddressEvent("setERC20Address", addr);
  }

  /// @notice Set erc721 address. Can only be executed by the contract owner.
  function setERC721Address(address addr) external onlyManager {

    _erc721Address = addr;

    emit setERC721AddressEvent("setERC721Address", addr);
  }

  /// @notice Get erc721 address.
  function getERC721Address() external view returns (address) {
    return _erc721Address;
  }

  /// @notice Get erc20 address.
  function getERC20Address() external view returns (address) {
    return _erc20Address;
  }


  /// @notice Generate cross-chain transaction number
  /// @notice srcChainCode + ':' + destChainCode + ':' + keccak256(msg.sender, _CrossTxNum, "1").substr(0, 32).
  function createCrossTxNo(
    string memory srcChainCode,
    string memory destChainCode
  ) internal returns (string memory) {
    //string memory senderStr = LibString.addressToString(msg.sender);
    string memory dataStr = LibString.concat(
      LibString.concat(
        LibString.addressToString(msg.sender),
        LibString.uint2str(block.number)
      ),
      LibString.uint2str(_CrossTxNum)
    );
    _CrossTxNum++;

    return
    LibString.concat(
      LibString.concat(
        LibString.concat(
          LibString.concat(srcChainCode, ":"),
          destChainCode
        ),
        ":"
      ),
      dataStr
    );
  }

  /// @notice Generate cross-chain transaction object
  function createCrossTx(
    string memory srcAddress,
    string memory destAddress,
    string memory srcChainCode,
    string memory destChainCode,
    uint8 payloadType,
    bytes memory payload,
    TxOriginEnum origin,
    string memory crossTxNo
  ) internal returns (_CrossTxObj memory) {
    if (LibString.equal(crossTxNo, "") == true) {
      crossTxNo = createCrossTxNo(srcChainCode, destChainCode);
    }
    _CrossTxObj memory crossTxTemp;

    crossTxTemp.CrossTxNo = crossTxNo;
    crossTxTemp.SrcChainCode = srcChainCode;
    crossTxTemp.DestChainCode = destChainCode;
    crossTxTemp.SrcAddress = srcAddress;
    crossTxTemp.DestAddress = destAddress;
    crossTxTemp.PayloadType = payloadType;
    crossTxTemp.Payload = payload;
    crossTxTemp.Result = TxResultEnum.INIT;
    crossTxTemp.Refunded = TxRefundedEnum.NONE;
    crossTxTemp.Origin = origin;

    return crossTxTemp;
  }

  /// @notice Subchain user sends contract interoperability
  function subStartTxCommon(
    address srcAddress,
    string memory srcChainCode
  ) internal view {
    require(
      srcAddress == msg.sender,
      "srcAddress =! sender "
    );
    require(
      LibString.equal(_ChainCode, srcChainCode) == true,
      "Chaincode is different"
    );

  }

  /// @notice Subchain user sends subchain points exchange
  /// @notice Contract locked subchain points
  function subStartTxTransferSgas(
    address srcAddress,
    string memory srcChainCode,
    bytes memory payload,
    address srcContractAddress
  ) internal {
    subStartTxCommon(srcAddress, srcChainCode);

    (uint8  assetType, uint256 amount, string memory contractAddress, uint256  tokenId) = abi.decode(
      payload,
      (uint8, uint256, string, uint256)
    );

    if (assetType == 4 || assetType == 5) {
      erc20TransferFrom(srcAddress, address(this), amount, srcContractAddress);
    } else if (assetType == 6) {
      erc721TransferFrom(srcAddress, address(this), tokenId, srcContractAddress);
    }
  }

  /// @notice Users of the subchain initiate cross-chain transactions
  function startTx(
    address payable srcAddress,
    address payable srcContractAddress,
    string memory destAddress,
    string memory srcChainCode,
    string memory destChainCode,
    string memory destCrossContract,
    uint8 payloadType,
    bytes memory payload,
    string memory extension,
    string memory remark,
    string memory version
  ) external payable {
    require(
      LibString.equal(_Version, version) == true,
      "Version is different"
    );
    require(
      payloadType == 2 || payloadType == 3 || payloadType == 4,
      "Wrong transaction type"
    );

    /// @notice There are three types of cross-chain transactions
    if (payloadType == 2) {
      subStartTxCommon(srcAddress, srcChainCode);
    } else if (payloadType == 3) {
      subStartTxCommon(srcAddress, srcChainCode);
    } else if (payloadType == 4) {
      subStartTxTransferSgas(srcAddress, srcChainCode, payload, srcContractAddress);
    }

    //string memory srcAddr = LibString.addressToString(srcAddress);
    _CrossTxObj memory crossTxObj = createCrossTx(
      LibString.addressToString(srcAddress),
      destAddress,
      srcChainCode,
      destChainCode,
      payloadType,
      payload,
      TxOriginEnum.SRC,
      ""
    );
    crossTxObj.SrcCrossContract = LibString.addressToString(address(this));
    crossTxObj.DestCrossContract = destCrossContract;
    crossTxObj.Extension = extension;
    crossTxObj.Remark = remark;
    crossTxObj.Version = version;
    _CrossTxObject[
    abi.encodePacked(crossTxObj.CrossTxNo)
    ] = crossTxObj;

    emit startTxEvent("startTx", crossTxObj.CrossTxNo, payloadType);
  }

  /// @notice Casting main chain points
  function assetErc20Mint(address destAddress, address contractAddress, uint256 amount) internal {

    string memory _method = "transfer(address,uint256)";
    (bool success,) = contractAddress.call(abi.encodeWithSignature(_method, destAddress, amount));

    emit AssetMintEvent("assetErc20Mint", address(this), destAddress, amount);
  }

  /// @notice Casting main chain points
  function assetErc721Mint(address destAddress, address contractAddress, uint256 tokenId) internal {

    string memory _method = "transfer(address,uint256)";
    (bool success,) = contractAddress.call(abi.encodeWithSignature(_method, destAddress, tokenId));
    emit AssetMintEvent("assetErc721Mint", address(this), destAddress, tokenId);
  }

  /// @notice The subchain gateway submits the main chain points transfer transaction
  function subSendTxTransferSgas(address destAddress, string memory srcChainCode, bytes memory payload) internal {
    //uint amount = abi.decode(payload, (uint));

    (uint8  assetType, uint256 srcAmount, string memory contractAddress, uint256  tokenId) = abi.decode(
      payload,
      (uint8, uint256, string, uint256)
    );
    if (assetType == 4 || assetType == 5) {
      assetErc20Mint(destAddress, payable(LibString.toAddress(contractAddress)), srcAmount);
    } else if (assetType == 6) {
      assetErc721Mint(destAddress, payable(LibString.toAddress(contractAddress)), tokenId);
    }
    //
  }

  /// @notice Subchain gateway submits contract interoperability transaction
  function subSendTxCall(address payable destAddress, bytes memory payload)
  internal
  {
    (, bytes memory contractCallEncode,) = abi.decode(payload, (string, bytes, string));
    //(bool success, ) = destAddress.call(abi.encodeWithSignature(_method, _params));
    (bool success,) = destAddress.call(contractCallEncode);
    require(success, "Contract call failed");

  }

  /// @notice Subchain gateway submits contract interoperability transaction
  function subSendTxTransferData(address payable destAddress, bytes memory payload)
  internal
  {
    string memory _params = abi.decode(payload, (string));

    string memory _method = "storeCrossData(string)";
    (bool success,) = destAddress.call(abi.encodeWithSignature(_method, _params));

    require(success, "Transfer data failed");
  }

  /// @notice erc20 asset transferFrom
  function erc20TransferFrom(address fromAddress, address toAddress, uint256 amount, address ercContractAddress)
  internal
  {
    string memory _method = "transferFrom(address,address,uint256)";
    (bool success,) = ercContractAddress.call(abi.encodeWithSignature(_method, fromAddress, toAddress, amount));
    require(success, "Contract20 call failed");

  }
  /// @notice erc721 asset transferFrom
  function erc721TransferFrom(address fromAddress, address toAddress, uint256 tokenId, address ercContractAddress)
  internal
  {
    string memory _method = "transferFrom(address,address,uint256)";
    (bool success,) = ercContractAddress.call(abi.encodeWithSignature(_method, fromAddress, toAddress, tokenId));
    require(success, "Contract721 call failed");

  }

  /// @notice erc20 asset transfer
  function erc20Transfer(address toAddress, uint256 amount, address ercContractAddress)
  internal
  {
    //string memory _method = "transfer(address,uint256)";
    (bool success,) = ercContractAddress.call(abi.encodeWithSignature("transfer(address,uint256)", toAddress, amount));
    require(success, "Contract20Transfer call failed");

  }

  /// @notice Gateway node submits cross-chain transaction
  function sendTx(
    string memory srcAddress,
    address payable destAddress,
    string memory srcChainCode,
    string memory destChainCode,
    string memory srcCrossContract,
    string memory destCrossContract,
    uint8 payloadType,
    string memory crossTxNo,
    bytes memory payload,
    string memory extension,
  //string memory remark,
    string memory version,
    bytes memory proof
  ) external payable {
    require(
      LibString.equal(crossTxNo, "") != true,
      "crossTxNo is null"
    );
    _CrossTxObj memory crossTxObj = _CrossTxObject[
    abi.encodePacked(crossTxNo)
    ];
    //跨链交易必须之前不存在
    require(
      LibString.equal(crossTxObj.Version, "") == true,
      "CrossTx already exist"
    );
    require(checkGateNode(destChainCode, destCrossContract), "This function is not the gateway");

    require(
      LibString.equal(_Version, version) == true,
      "Version is different"
    );
    require(
      payloadType == 2 || payloadType == 3 || payloadType == 4,
      "Wrong transaction type"
    );

    //string memory destAddr = addressToString(destAddress);
    //TxOriginEnum origin = TxOriginEnum.DEST;
    crossTxObj = createCrossTx(
      srcAddress,
      LibString.addressToString(destAddress),
      srcChainCode,
      destChainCode,
      payloadType,
      payload,
      TxOriginEnum.DEST,
      crossTxNo
    );
    crossTxObj.SrcCrossContract = srcCrossContract;
    crossTxObj.DestCrossContract = destCrossContract;
    crossTxObj.Extension = extension;
    //crossTxObj.Remark = remark;
    crossTxObj.Version = version;

    /// @notice There are three types of cross-chain transactions

    if (payloadType == 2) {
      subSendTxCall(destAddress, payload);

    } else if (payloadType == 3) {
      subSendTxTransferData(destAddress, payload);

    } else if (payloadType == 4) {
      subSendTxTransferSgas(destAddress, srcChainCode, payload);

    }

    (uint256 ledgerSeq, string memory txHash) = abi.decode(
      proof,
      (uint256, string)
    );
    _SendProof memory sendProof = _SendProof({
    LedgerSeq : ledgerSeq,
    TxHash : txHash,
    verifieraddr : msg.sender
    });
    crossTxObj.SendProofs = sendProof;
    _CrossTxObject[abi.encodePacked(crossTxNo)] = crossTxObj;

    emit sendTxEvent("sendTx", crossTxNo, payloadType);
  }

  /// @notice The subchain gateway submits the subchain point exchange confirmation transaction
  function subSendAckSrcCommon(
    _CrossTxObj memory crossTx_Obj,
    TxResultEnum result
  ) internal pure returns (_CrossTxObj memory) {
    if (result != TxResultEnum.ACK_SUCCESS) {
      crossTx_Obj.Refunded = TxRefundedEnum.TODO;
    }

    return crossTx_Obj;
  }

  /// @notice Gateway node submits cross-chain confirmation transaction
  function sendAcked(
    string memory crossTxNo,
    TxResultEnum result,
    string memory version,
    bytes memory proof
  ) external {
    require(
      result == TxResultEnum.ACK_SUCCESS ||
      result == TxResultEnum.ACK_FAIL ||
      result == TxResultEnum.ACK_TIMEOUT,
      "Invalid result"
    );
    require(
      LibString.equal(_Version, version) == true,
      "Version is different"
    );

    _CrossTxObj memory crossTxObj = _CrossTxObject[
    abi.encodePacked(crossTxNo)
    ];
    TxOriginEnum origin = crossTxObj.Origin;
    if (origin == TxOriginEnum.SRC) {
      //require(checkGateNode(crossTxObj.SrcChainCode,crossTxObj.SrcCrossContract), "This function is restricted to the gateway");
    } else {
      // require(checkGateNode(crossTxObj.DestChainCode,crossTxObj.DestCrossContract), "This function is restricted to the gateway");
    }

    require(
      crossTxObj.Result == TxResultEnum.INIT,
      "CrossTx result is not init"
    );

    if (origin == TxOriginEnum.SRC) {
      crossTxObj = subSendAckSrcCommon(crossTxObj, result);
    }

    crossTxObj.Result = TxResultEnum(result);
    (uint256 ledgerSeq, string memory txHash) = abi.decode(
      proof,
      (uint256, string)
    );
    crossTxObj.AckProofs = _AckProof({
    LedgerSeq : ledgerSeq,
    TxHash : txHash,
    verifieraddr : msg.sender
    });
    _CrossTxObject[abi.encodePacked(crossTxNo)] = crossTxObj;

    emit sendAckedEvent(
      "sendAcked",
      crossTxObj.CrossTxNo,
      crossTxObj.PayloadType
    );
  }


  /// @notice Withdraw subchain points
  function takeOutSgas(bytes memory payload, address payable to) internal {

    (uint8  assetType, uint256 srcAmount, address  contractAddress,uint256  tokenId) = abi.decode(
      payload,
      (uint8, uint256, address, uint256)
    );

    if (assetType == 1) {
      to.transfer(srcAmount);
    } else if (assetType == 2) {
      erc20Transfer(to, srcAmount, contractAddress);
    } else if (assetType == 3) {
      erc721TransferFrom(address(this), to, tokenId, contractAddress);
    }
  }

  /// @notice Withdrawal of abnormal cross-chain assets
  function takeOut(string memory crossTxNo, address payable toAddress) external {
    _CrossTxObj memory crossTxObj = _CrossTxObject[
    abi.encodePacked(crossTxNo)
    ];
    require(crossTxObj.Origin == TxOriginEnum.SRC, "Not src");
    require(
      crossTxObj.Result == TxResultEnum.ACK_TIMEOUT ||
      crossTxObj.Result == TxResultEnum.ACK_FAIL,
      "Result is not timeout or fail"
    );
    //string memory str = LibString.addressToString(msg.sender);
    require(
      LibString.equal(LibString.addressToString(msg.sender), crossTxObj.SrcAddress) == true,
      "Not your asset"
    );
    require(
      crossTxObj.Refunded == TxRefundedEnum.TODO,
      "The asset has been returned"
    );

    if (crossTxObj.PayloadType == 4) {
      takeOutSgas(crossTxObj.Payload, toAddress);
    }

    crossTxObj.Refunded = TxRefundedEnum.REFUNDED;
    _CrossTxObject[abi.encodePacked(crossTxNo)] = crossTxObj;

    emit takeOutEvent("takeOut", toAddress);
  }

}