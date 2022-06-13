// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "../lib/math/SafeMath.sol";
import "../lib/interface/IERC1155.sol";
import "../lib/utils/StringLibrary.sol";
import "../lib/utils/BytesLibrary.sol";
import "../lib/interface/IERC721Mintable.sol";
import "../exchange/ERC20TransferProxy.sol";
import "../exchange/TransferProxy.sol";
import "./CopyERC721.sol";
import "./BlindState.sol";
import "./BlindDomain.sol";
import "../exchange/TransferProxyForDeprecated.sol";
import "../lib/contracts/HasSecondarySaleFees.sol";
import "../lib/utils/Ownable.sol";

contract BlindBox is Ownable, BlindDomain {
  using SafeMath for uint;
  using UintLibrary for uint;
  using StringLibrary for string;
  using BytesLibrary for bytes32;

  event Open(
    address indexed owner,
    address buyToken, uint256 buyTokenId, uint256 buyValue,
    address buyer,
    uint256 amount,
    uint256 salt
  );

  event OpenIndex(
    uint index
  );
  
  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
  uint256 private constant UINT256_MAX = 2 ** 256 - 1;

  address payable public beneficiary;
  address public buyerFeeSigner;
  address public constant blackHole = 0x0000000000000000000000000000000000000001;
  
  uint public constant limitPerAddress = 1;
  uint public constant ownerLimit = 3;
  uint public constant openLimit = 1440;
  uint public totalOpen = 0;
  mapping (address => uint) internal openPerAddress;
  mapping (address => uint) internal whiteList;


  TransferProxy public transferProxy;
  TransferProxyForDeprecated public transferProxyForDeprecated;
  ERC20TransferProxy public erc20TransferProxy;
  BlindState public state;
  CopyERC721 copyERC721;

  constructor(
    TransferProxy _transferProxy,
    TransferProxyForDeprecated _transferProxyForDeprecated,
    ERC20TransferProxy _erc20TransferProxy,
    BlindState _state,
    CopyERC721 _copyERC721,
    address payable _beneficiary,
    address _buyerFeeSigner
  ) {
    transferProxy = _transferProxy;
    transferProxyForDeprecated = _transferProxyForDeprecated;
    erc20TransferProxy = _erc20TransferProxy;
    copyERC721 = _copyERC721;
    state = _state;
    beneficiary = _beneficiary;
    buyerFeeSigner = _buyerFeeSigner;
  }

  function setBeneficiary(address payable newBeneficiary) external onlyOwner{
    beneficiary = newBeneficiary;
  }

  function setBuyerFeeSigner(address newBuyerFeeSigner) external onlyOwner {
    buyerFeeSigner = newBuyerFeeSigner;
  }


  function open(
    BlindBox calldata blindbox,
    Sig calldata sig,
    uint buyerFee,
    Sig calldata buyerFeeSig,
    uint amount,
    address buyer
  ) payable external {
    if(buyer == owner())
    {
      amount = ownerLimit;
    }
    validateTime(blindbox,whiteList[buyer] > 0);
    validateBlindBoxSig(blindbox, sig);
    validateBuyerFeeSig(blindbox, buyerFee, buyerFeeSig);
    validateLimitPerAddress(buyer);
    openPerAddress[buyer]++;
    totalOpen ++;
    verifyState(blindbox.key, blindbox.assetAmounts, blindbox.opening, amount);
    if(buyer == address(0x0)){
      buyer = msg.sender;
    }
    compute(blindbox, amount, buyer, buyerFee);

    emitOpen(blindbox, amount, buyer);
  }


  function validateEthTransfer(uint value, uint buyerFee) internal view {
    uint256 buyerFeeValue = value.bp(buyerFee);
    require(msg.value == value.add(buyerFeeValue), "msg.value is incorrect");
  }


  function validateTime(
    BlindBox memory blindbox,
    bool isWhiteList
  ) internal view {
    if(isWhiteList)
    {
      require((blindbox.startTime - 30 minutes < block.timestamp && block.timestamp < blindbox.endTime ), "incorrect time");
    }
    else
    {
      require((blindbox.startTime < block.timestamp && block.timestamp < blindbox.endTime ), "incorrect time");
    }
  }


  function validateBlindBoxSig(
    BlindBox memory blindbox,
    Sig memory sig
  ) internal pure {
    require(prepareMessage(blindbox).recover(sig.v, sig.r, sig.s) == blindbox.key.owner, "incorrect signature");
  }


  function validateBuyerFeeSig(
    BlindBox memory blindbox,
    uint buyerFee,
    Sig memory sig
  ) internal view {
    require(prepareBuyerFeeMessage(blindbox, buyerFee).recover(sig.v, sig.r, sig.s) == buyerFeeSigner, "incorrect buyer fee signature");
  }


  function verifyState(BlindKey memory key, uint[] memory assetAmounts, uint opening, uint amount) internal view {
    uint[] memory completed = state.getCompleted(key);
    if(completed.length == 0) return;
    uint total = 0;
    uint completedTotal = 0;
    for(uint i = 0; i < assetAmounts.length; i++){
      total = total.add(assetAmounts[i]);
      completedTotal = completedTotal.add(completed[i]);
    }
    uint newCompleted = completedTotal.add( amount.mul(opening) );
    require(newCompleted <= total, "not enough stock of blindbox for buying");
  }


  function compute(BlindBox memory blindbox, uint256 amount, address buyer, uint buyerFee) internal{
    uint total = totalAmounts(blindbox);
    
    uint paying = blindbox.buying.mul(amount).div(total.div(blindbox.opening));
    if(blindbox.key.buyAsset.assetType == AssetType.ETH){
      validateEthTransfer(paying, buyerFee);
    }

    for(uint i = 0; i < amount; i++){
      (uint[] memory amounts, uint stock) = remainAmounts(blindbox);
      require(stock != 0, "incorrect stock");
      openBox(blindbox, stock, amounts, buyer, buyerFee);
    }

    if(blindbox.key.buyAsset.assetType == AssetType.ERC1155 || 
        blindbox.key.buyAsset.assetType == AssetType.ERC721 ){
      transferWithFeesPossibility(blindbox.key.buyAsset, paying, msg.sender, blackHole, true, blindbox.sellerFee, buyerFee, "");
    } else {
      transferWithFeesPossibility(blindbox.key.buyAsset, paying, msg.sender, blindbox.key.owner, true, blindbox.sellerFee, buyerFee, "");
    }
  }

  function totalAmounts(BlindBox memory blindbox) internal pure returns (uint total){
    total = 0;
    for(uint i = 0; i < blindbox.assetAmounts.length; i++){
      require(blindbox.key.sellAssets[i].assetType != AssetType.ETH && 
          blindbox.key.sellAssets[i].assetType != AssetType.ERC20, "incorrect sellAsset");
      total = total.add(blindbox.assetAmounts[i]);
    }
  }


  function remainAmounts(BlindBox memory blindbox) internal view returns (uint[] memory amounts, uint stock){
    uint[] memory completed = state.getCompleted(blindbox.key);
    amounts = new uint[](blindbox.assetAmounts.length);
    stock = 0;
    for(uint i = 0; i < blindbox.assetAmounts.length; i++){
      amounts[i] = blindbox.assetAmounts[i];
      if(completed.length > 0){
        amounts[i] = amounts[i].sub(completed[i]);
      }
      stock = stock.add(amounts[i]);
    }
  }


  function rewardIndex(uint[] memory amounts, uint stock) internal view returns (uint index) {
    uint256 luckyNumber = random(1, stock + 1, stock);
    index = 0;
    uint total = 0;
    for(uint z = 0; z < amounts.length; z++){
      total = total.add(amounts[z]);
      if(luckyNumber <= total){
        index = z;
        break;
      }
    }
 
    /*
    bool finished = false;
    for(uint z = 0; z < amounts.length; z++){
      total = total.add(amounts[z]);
      if(!finished && luckyNumber <= total){
        index = z;
        finished = true;
      }
    }
    */
  }


  function openBox(BlindBox memory blindbox, uint stock, uint[] memory amounts, address buyer, uint buyerFee) internal {
    for(uint j = 0; j < blindbox.opening; j++){
      uint index = rewardIndex(amounts, stock);
      transferBox(blindbox, index, buyer, buyerFee);
      if(blindbox.repeat){
        stock = stock.sub(1);
        amounts[index] = amounts[index].sub(1);
      }else{
        stock = stock.sub(amounts[index]);
        amounts[index] = 0;
      }
      emit OpenIndex(index);
    }
  }
  
  function transferBox(BlindBox memory blindbox, uint index, address buyer, uint buyerFee) internal {
    transferWithFeesPossibility(blindbox.key.sellAssets[index], 1, blindbox.key.owner, buyer, false, buyerFee, blindbox.sellerFee, blindbox.uris[index]);
    state.setCompleted(blindbox.key, index);
  }


  function random(uint256 from, uint256 to, uint256 salty) internal view returns (uint256){
    uint256 seed = uint256(
      keccak256(
        abi.encodePacked(
          block.timestamp + block.difficulty + block.gaslimit,
          ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
          block.gaslimit + 
          ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) + 
          block.number + 
          salty
        )
      )
    );
    return seed.mod(to - from) + from;
  }


  function prepareBuyerFeeMessage(BlindBox memory blindbox, uint fee) public pure returns(string memory ){
    return keccak256(abi.encode(blindbox, fee)).toString();
  }


  function prepareMessage(BlindBox memory blindbox) public pure returns (string memory){
    return keccak256(abi.encode(blindbox)).toString();
  }


  function transferWithFeesPossibility(Asset memory firstType, uint value, address from, address to, bool hasFee, uint256 sellerFee, uint256 buyerFee, string memory uri) internal {
    if (!hasFee || 
        (firstType.assetType != AssetType.ETH && firstType.assetType != AssetType.ERC20)) {
      transfer(firstType, value, from, to, uri);
    } else {
      transferWithFees(firstType, value, from, to, sellerFee, buyerFee);
    }
  }


  function transfer(Asset memory asset, uint value, address from, address to, string memory uri) internal {
    if (asset.assetType == AssetType.ETH) {
      address payable toPayable = payable(to);
      toPayable.transfer(value);
    } else if (asset.assetType == AssetType.ERC20) {
      require(asset.tokenId == 0, "tokenId  be 0");
      erc20TransferProxy.erc20safeTransferFrom(IERC20(asset.token), from, to, value);
    } else if (asset.assetType == AssetType.ERC721) {
      require(value == 1, "value  be 1 for ERC-721");
      transferProxy.erc721safeTransferFrom(IERC721(asset.token), from, to, asset.tokenId);
    } else if (asset.assetType == AssetType.ERC721Deprecated) {
      require(value == 1, "value  be 1 for ERC-721");
      transferProxyForDeprecated.erc721TransferFrom(IERC721(asset.token), from, to, asset.tokenId);
    }else if(asset.assetType == AssetType.ERC721COPY){
      require(value == 1, "value be 1 for ERC-721-COPY");
      require(bytes(uri).length != 0, "uri be empty for ERC-721");
      copyERC721.safeMint(IERC721Mintable(asset.token), to, uri);
    } else {
      transferProxy.erc1155safeTransferFrom(IERC1155(asset.token), from, to, asset.tokenId, value, "");
    }
  }


  function transferWithFees(Asset memory firstType, uint value, address from, address to, uint256 sellerFee, uint256 buyerFee) internal {
    uint restValue = transferFeeToBeneficiary(firstType, from, value, sellerFee, buyerFee);
    address payable toPayable = payable(to);
    transfer(firstType, restValue, from, toPayable, "");
  }


  function transferFeeToBeneficiary(Asset memory asset, address from, uint total, uint sellerFee, uint buyerFee) internal returns (uint) {
    (uint restValue, uint sellerFeeValue) = subFeeInBp(total, total, sellerFee);
    uint buyerFeeValue = total.bp(buyerFee);
    uint beneficiaryFee = buyerFeeValue.add(sellerFeeValue);
    if (beneficiaryFee > 0) {
      transfer(asset, beneficiaryFee, from, beneficiary, "");
    }
    return restValue;
  }


  function emitOpen(BlindBox memory blindbox, uint amount, address buyer) internal {
    emit Open(
      blindbox.key.owner,
      blindbox.key.buyAsset.token,
      blindbox.key.buyAsset.tokenId, blindbox.buying,
      buyer,
      amount,
      blindbox.key.salt
    );
  }


  function subFeeInBp(uint value, uint total, uint feeInBp) internal pure returns (uint newValue, uint realFee) {
    return subFee(value, total.bp(feeInBp));
  }


  function subFee(uint value, uint fee) internal pure returns (uint newValue, uint realFee) {
    if (value > fee) {
      newValue = value - fee;
      realFee = fee;
    } else {
      newValue = 0;
      realFee = value;
    }
  }

  function validateLimitPerAddress(address buyer) internal view {
    require(openPerAddress[buyer] < limitPerAddress, "already reached the limit per address");
    require(totalOpen < openLimit, "Token limit reached");
  }

  function addToWhiteList(address[] memory newAddress,uint256 limit) public onlyOwner {
    for (uint256 i=0; i< newAddress.length; i++)
    {
        whiteList[newAddress[i]] = limit;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;


import "./Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./ERC165.sol";

abstract contract HasSecondarySaleFees is ERC165 {

    event SecondarySaleFees(uint256 tokenId, address[] recipients, uint[] bps);

    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    constructor() {
        _registerInterface(_INTERFACE_ID_FEES);
    }

    function getFeeRecipients(uint256 id) public view virtual returns (address payable[] memory);
    function getFeeBps(uint256 id) public view virtual returns (uint[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "../lib/interface/IERC721.sol";
import "./OwnableOperatorRole.sol";

contract TransferProxyForDeprecated is OwnableOperatorRole {

    function erc721TransferFrom(IERC721 token, address from, address to, uint256 tokenId) external onlyOperator {
        token.transferFrom(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;


contract BlindDomain {

  enum AssetType {ETH, ERC20, ERC1155, ERC721, ERC721Deprecated, ERC721COPY}

  struct Asset {
    address token;
    uint tokenId;
    AssetType assetType;
  }

  struct BlindKey {
    /* who signed the order */
    address owner;
    /* random number */
    uint salt;

    Asset[] sellAssets;
    Asset buyAsset;
  }

  struct BlindBox {
    BlindKey key;

    uint opening;
    bool repeat;
    uint startTime;
    uint endTime;

    uint buying;

    uint[] assetAmounts;

    uint sellerFee;
    string[] uris;
  }

  struct Sig {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./BlindDomain.sol";
import "../exchange/OwnableOperatorRole.sol";


contract BlindState is OwnableOperatorRole {

    // keccak256(BlindKey) => completed
    mapping(bytes32 => uint[]) public completed;

    function getCompleted(BlindDomain.BlindKey calldata key) view external returns (uint[] memory) {
        return completed[getCompletedKey(key)];
    }

    function setCompleted(BlindDomain.BlindKey calldata key, uint index) external onlyOperator {
      bytes32 _key = getCompletedKey(key);
      if(completed[_key].length == 0){
        completed[_key] = new uint[](key.sellAssets.length);
      }
      completed[_key][index] = completed[_key][index] + 1;
    }

    function getCompletedKey(BlindDomain.BlindKey memory key) pure public returns (bytes32) {
        return keccak256(abi.encode(key));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "../lib/math/SafeMath.sol";
import "../lib/interface/IERC721Mintable.sol";
import "../exchange/OwnableOperatorRole.sol";


contract CopyERC721 is OwnableOperatorRole {
  using SafeMath for uint;

  mapping (address => uint256) public tokenIds;

  function safeMint(IERC721Mintable token, address to, string memory tokenURI) external onlyOperator {
    uint256 tokenId = tokenIds[address(token)].add(1);
    tokenIds[address(token)] = tokenId;
    token.safeMint(to, tokenId, tokenURI);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "../lib/interface/IERC721.sol";
import "../lib/interface/IERC1155.sol";

import "./OwnableOperatorRole.sol";

contract TransferProxy is OwnableOperatorRole {

    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) external onlyOperator {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 value, bytes calldata data) external onlyOperator {
        token.safeTransferFrom(from, to, id, value, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../lib/interface/IERC20.sol";

import "./OwnableOperatorRole.sol";

contract ERC20TransferProxy is OwnableOperatorRole {

    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external onlyOperator {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title ERC721 token mint interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Mintable {
  function mint(uint256 tokenId, string memory tokenURI) external;
  function safeMint(address to, uint256 tokenId, string memory tokenURI) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

library BytesLibrary {
    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(value[i] >> 4)];
            str[1+i*2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "../math/SafeMath.sol";

library UintLibrary {
    using SafeMath for uint;
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);

        uint256 index = digits;
        temp = value;
        while (temp != 0) {
            index = index - 1;
            buffer[index] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }

    function bp(uint value, uint bpValue) internal pure returns (uint) {
        return value.mul(bpValue).div(10000);
    }
}

library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function append(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory bbb = new bytes(_ba.length + _bb.length + _bc.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bbb[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bbb[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) bbb[k++] = _bc[i];
        return string(bbb);
    }

    function recover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(bytes memory _ba, bytes memory _bb, bytes memory _bc, bytes memory _bd, bytes memory _be, bytes memory _bf, bytes memory _bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(_ba.length + _bb.length + _bc.length + _bd.length + _be.length + _bf.length + _bg.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];
        return resultBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IERC165.sol";

abstract contract IERC1155 is IERC165 {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external virtual;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external virtual;

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view virtual returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view virtual returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external virtual;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;


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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;


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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "../interface/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "../lib/utils/Ownable.sol";
import "./OperatorRole.sol";

contract OwnableOperatorRole is Ownable, OperatorRole {
    function addOperator(address account) external onlyOwner {
        _addOperator(account);
    }

    function removeOperator(address account) external onlyOwner {
        _removeOperator(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
abstract contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual;
    function approve(address to, uint256 tokenId) public virtual;
    function getApproved(uint256 tokenId) public view virtual returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public virtual;
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "../lib/utils/Context.sol";
import "../lib/utils/Roles.sol";

contract OperatorRole is Context {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private _operators;

    constructor () {
    }

    modifier onlyOperator() {
        require(isOperator(_msgSender()), "OperatorRole: caller does not have the Operator role");
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators.has(account);
    }

    function _addOperator(address account) internal {
        _operators.add(account);
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        _operators.remove(account);
        emit OperatorRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}