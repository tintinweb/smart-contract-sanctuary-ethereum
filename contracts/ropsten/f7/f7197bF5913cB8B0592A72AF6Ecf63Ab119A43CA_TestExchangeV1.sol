// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Lib/LibOrder.sol";
import "./Lib/LibSignature.sol";
import "./Lib/LibFee.sol";
import "./Lib/BpLibrary.sol";
import "./Lib/LibFeeManager.sol";
import "./Lib/LibRoyaltiesManager.sol";
import "./Validator/Validator.sol";
import "./TransferManager.sol";
import "./Interface/IERC1155.sol";
import "./Interface/IERC20.sol";
import "./Interface/IERC721.sol";
import "./Interface/ITransferProxy.sol";

/**
 * @title ExchangeV1
 * @dev Implements NFT sell process
 * @author development team
 */

contract TestExchangeV1 is Validator, TransferManager {
    modifier pauseControl() {
        require(pause != true, "CONTRACT_PAUSED");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "NOT_MINTER_ADDRESS");
        _;
    }

    constructor(ITransferProxy _transferProxy) {
        minter = msg.sender;
        transferProxy = _transferProxy;
        pause = false;
    }

    using SafeMath for uint;
    using BpLibrary for uint;
   
    event Cancel(bytes32 indexed  orderHash, address indexed  makerAddress, address makeToken, uint makeTokenId, LibAsset.AssetType makeAssetType, address takeToken, uint takeTokenId, LibAsset.AssetType takeAssetType);
    event Match(bytes32 buyHash, bytes32 sellHash, address indexed  buyMakerAddress, address indexed sellMakerAddress, LibAsset.AssetType buyAssetType, LibAsset.AssetType sellAssetType, uint buyNewFill, uint sellNewFill, bool isBuyFilled, bool isSellFilled);

    address public minter;
    uint public defaultFee;
    ITransferProxy public transferProxy;
    address public feeSignerAddress;
    bool public pause;

    uint256 private constant UINT256_MAX = 2 ** 256 - 1;

    mapping(bytes32 => uint) public filledOrders;

    function placeOrder(LibOrder.Order memory order)
        public
        pauseControl
        view
        returns (bytes32)
    {
        //Order  Validator
        Validator.validateOrder(order);
        bytes32 orderKey = LibOrder.orderHash(order);
        require(UINT256_MAX != filledOrders[orderKey] , "ORDER_HAS_EXPIRED");
        return orderKey;
    }

    function getFee(LibFee.Fee memory fee)
        public
        pauseControl
        view
        returns (bytes32)
    {
        bytes32 feeKey = LibFee.feeHash(fee);
        return feeKey;
    }

    function matchOrder(LibOrder.Order memory buyOrder, LibOrder.Order memory sellOrder, LibFee.Fee[] memory fee)
        public payable
        pauseControl
    {
        //Order  Validator
        bytes32 buyOrderKey = LibOrder.orderHash(buyOrder);
        bytes32 sellOrderKey = LibOrder.orderHash(sellOrder);
        require(LibSignature.verify(buyOrder.makerAddress, buyOrderKey, buyOrder.signature) == true, "BUYORDER_SIGNATURE_ERROR");
        require(LibSignature.verify(sellOrder.makerAddress, sellOrderKey, sellOrder.signature) == true, "SELLORDER_SIGNATURE_ERROR");
        require(UINT256_MAX != filledOrders[buyOrderKey], "BUYORDER_HAS_EXPIRED");
        require(UINT256_MAX != filledOrders[sellOrderKey], "SELLORDER_HAS_EXPIRED");    
        Validator.validateMatchOrder(buyOrder,sellOrder);
        if(buyOrder.makeAsset.assetType == LibAsset.AssetType.PLATFORM_TOKEN ){
            require(SafeMath.mul(sellOrder.makeAsset.value, sellOrder.takeAsset.value) <= msg.value, "BID_PRICE_CAN_NOT_BE_ZERO");
       }

        LibFeeManager.FeeSide feeSide = LibFeeManager.getFeeSide(buyOrder, sellOrder);
        uint remainingValue = royaltiesManage(buyOrder, sellOrder, feeSide);
        remainingValue = transferFee(buyOrder, sellOrder, fee, feeSide, remainingValue);
        transferAsset(buyOrder, sellOrder, feeSide, remainingValue);  
        (uint sellRemainingMakeValue, uint buyRemainingMakeValue) = fillOrders(buyOrderKey, sellOrderKey);
         
        emit Match(buyOrderKey, sellOrderKey, buyOrder.makerAddress, sellOrder.makerAddress, buyOrder.makeAsset.assetType, sellOrder.makeAsset.assetType, buyRemainingMakeValue, sellRemainingMakeValue, true, true);
    }

    function transferAsset (LibOrder.Order memory buyOrder, LibOrder.Order memory sellOrder, LibFeeManager.FeeSide feeSide, uint remainingValue) internal  {
        if(feeSide == LibFeeManager.FeeSide.BUYSIDE){
            TransferManager.transfer(transferProxy, buyOrder.makeAsset, buyOrder.makerAddress, sellOrder.makerAddress, remainingValue);
            TransferManager.transfer(transferProxy, sellOrder.makeAsset, sellOrder.makerAddress, buyOrder.makerAddress, sellOrder.makeAsset.value);
        }
        if(feeSide == LibFeeManager.FeeSide.SELLSIDE){
            TransferManager.transfer(transferProxy, buyOrder.makeAsset, buyOrder.makerAddress, sellOrder.makerAddress, buyOrder.makeAsset.value );
            TransferManager.transfer(transferProxy, sellOrder.makeAsset, sellOrder.makerAddress, buyOrder.makerAddress,  remainingValue);
        }
        if(feeSide == LibFeeManager.FeeSide.NOFEE){
            TransferManager.transfer(transferProxy, buyOrder.makeAsset, buyOrder.makerAddress, sellOrder.makerAddress, buyOrder.makeAsset.value);
            TransferManager.transfer(transferProxy, sellOrder.makeAsset, sellOrder.makerAddress, buyOrder.makerAddress,  sellOrder.makeAsset.value);
        }
    }

    function royaltiesManage(LibOrder.Order memory buyOrder, LibOrder.Order memory sellOrder, LibFeeManager.FeeSide feeSide ) internal returns(uint newValue)  {
        LibRoyaltiesManager.DeservingOfRoyaltiesSide deservingOfRoyaltiesSide = LibRoyaltiesManager.getDeservingOfRoyaltiesSide(buyOrder, sellOrder);
        uint remainingValue = 0;
        if(deservingOfRoyaltiesSide == LibRoyaltiesManager.DeservingOfRoyaltiesSide.BUYSIDE ){
           remainingValue = transferRoyalties(buyOrder, sellOrder);
        }
        if(deservingOfRoyaltiesSide == LibRoyaltiesManager.DeservingOfRoyaltiesSide.SELLSIDE ){
           remainingValue = transferRoyalties(sellOrder, buyOrder);
        }
        if(deservingOfRoyaltiesSide == LibRoyaltiesManager.DeservingOfRoyaltiesSide.NOROYALTIES ){
           if(feeSide == LibFeeManager.FeeSide.BUYSIDE){
               remainingValue = buyOrder.makeAsset.value;
           }
           if(feeSide == LibFeeManager.FeeSide.SELLSIDE){
                remainingValue = sellOrder.makeAsset.value;
           }
        }
        return remainingValue;
    }

    function transferRoyalties (LibOrder.Order memory deservingOfRoyaltiesOrder, LibOrder.Order memory payingRoyaltiesOrder) internal  returns(uint newValue)  {
        uint256 price = payingRoyaltiesOrder.makeAsset.value;
        address royaltyAddress = IERC1155(deservingOfRoyaltiesOrder.makeAsset.token)
            .getRoyaltyAddress(deservingOfRoyaltiesOrder.makeAsset.tokenId);
        if(royaltyAddress != address(0)){
            uint royaltRate = IERC1155(deservingOfRoyaltiesOrder.makeAsset.token)
                            .getRoyaltyRate(deservingOfRoyaltiesOrder.makeAsset.tokenId);
        
        (uint newTotal, uint calculatedRoyaltyPrice) = subFeeInBp(price, price, royaltRate);
            if(royaltRate != 0){
                TransferManager.transfer(transferProxy, payingRoyaltiesOrder.makeAsset, payingRoyaltiesOrder.makerAddress, royaltyAddress, calculatedRoyaltyPrice);
            }   
        
            return newTotal;
        }
        return price;
    }

    function transferFee (LibOrder.Order memory buyOrder, LibOrder.Order memory sellOrder, LibFee.Fee[] memory fee, LibFeeManager.FeeSide feeSide, uint remainingPrice) internal returns(uint newValue)  {
        if(fee.length > uint(0) ){
            for (uint256 i = 0; i < fee.length; i++) {
                    bytes32 feeOrderHash = LibFee.feeHash(fee[i]);
                    require(LibSignature.verify(feeSignerAddress, feeOrderHash, fee[i].feeSignature) == true, "FEE_SIGNATURE_ERROR");
                    if(feeSide == LibFeeManager.FeeSide.BUYSIDE){
                        if (fee[i].feeType == LibFee.FeeType.BuyerFee) {
                             require(buyOrder.makerAddress == fee[i].feeAddress,"BUYORDER_FEE_SIGNATURE_ERROR");
                            (uint newPrice, uint feePrice) = subFeeInBp(remainingPrice, buyOrder.makeAsset.value, fee[i].feeValue);
                            newValue = newPrice;
                            TransferManager.transfer(transferProxy, buyOrder.makeAsset, buyOrder.makerAddress, fee[i].feeSendAddress, feePrice);
                        }
                    }
                    if(feeSide == LibFeeManager.FeeSide.SELLSIDE){
                        if (fee[i].feeType == LibFee.FeeType.SellerFee) {
                            require(sellOrder.makerAddress == fee[i].feeAddress,"SELLORDER_FEE_SIGNATURE_ERROR");
                            (uint newPrice, uint feePrice) = subFeeInBp(remainingPrice, sellOrder.makeAsset.value, fee[i].feeValue);
                            newValue = newPrice;
                            TransferManager.transfer(transferProxy, sellOrder.takeAsset, sellOrder.makerAddress, fee[i].feeSendAddress, feePrice);
                        }
                    }
                }
            }
            else{
                 if(feeSide == LibFeeManager.FeeSide.BUYSIDE){
                    (uint newPrice, uint feePrice) = subFeeInBp(remainingPrice, buyOrder.makeAsset.value, defaultFee);
                    newValue = newPrice;
                    TransferManager.transfer(transferProxy, buyOrder.makeAsset, buyOrder.makerAddress, feeSignerAddress, feePrice);
                    }
                   if(feeSide == LibFeeManager.FeeSide.SELLSIDE){
                       (uint newPrice, uint feePrice) = subFeeInBp(remainingPrice, sellOrder.makeAsset.value,  defaultFee);
                        newValue = newPrice;
                        TransferManager.transfer(transferProxy, sellOrder.takeAsset, sellOrder.makerAddress, feeSignerAddress, feePrice);
                    }
            }
        return newValue;
    }

    function subFeeInBp(uint value, uint total, uint feeInBp) public pure returns (uint newValue, uint realFee) {
        return subFee(value, total.bp(feeInBp));
    }

    function subFee(uint value, uint fee) internal pure returns (uint newValue, uint realFee) {
        if (value > fee) {
            newValue = value.sub(fee);
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        } 
    }

    function fillOrders(bytes32 buyOrderHash, bytes32 sellOrderHash) 
     internal returns (uint sellRemainingMakeValue, uint buyRemainingMakeValue)   {
          sellRemainingMakeValue = filledOrders[sellOrderHash];
          buyRemainingMakeValue = filledOrders[buyOrderHash];

        filledOrders[buyOrderHash] = UINT256_MAX;
        filledOrders[sellOrderHash] = UINT256_MAX;
        return (sellRemainingMakeValue, buyRemainingMakeValue);
    }

    function cancel(LibOrder.Order memory order) external {
        require(msg.sender == order.makerAddress, "NOT_MAKER");
        
        bytes32 orderKeyHash = LibOrder.orderHash(order);
        require(LibSignature.verify(order.makerAddress, orderKeyHash, order.signature) == true, "SIGNATURE_ERROR");

        filledOrders[orderKeyHash] = UINT256_MAX;

       emit Cancel(orderKeyHash, order.makerAddress, order.makeAsset.token, order.makeAsset.tokenId, order.makeAsset.assetType,order.takeAsset.token, order.takeAsset.tokenId, order.takeAsset.assetType);
    }
    

    function setTransferProxy(ITransferProxy _transferProxy)
        public
        pauseControl
        onlyMinter
    {
        transferProxy = _transferProxy;
    }

    function setFeeSignerAddress(address _feeSigner)
        public
        pauseControl
        onlyMinter
    {
        feeSignerAddress = _feeSigner;
    }

        function setDefaultFee(uint fee)
        public
        pauseControl
        onlyMinter
    {
        defaultFee = fee;
    }

    function pauseContract() public onlyMinter {
        pause = true;
    }

    function unPauseContract() public onlyMinter {
        pause = false;
    }

    function getBalance() public view pauseControl returns (uint256) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "../Lib/LibOrder.sol";
import "../Lib/LibAsset.sol";
/**
 * @title Validator
 * @dev Implements HebysTestExchangeV1
 * @author development team
 **/

contract Validator  {

    function validateOrder(LibOrder.Order memory order) internal view {
        require(msg.sender == order.makerAddress,"NOT_TOKEN_OWNER");
        require(uint256(0) != order.makeAsset.value,"VALUE_CAN_NOT_BE_ZERO");
        if(order.makeAsset.assetType != LibAsset.AssetType.PLATFORM_TOKEN){
            require(address(0) != order.makeAsset.token, "MAKEASSET_TOKEN_CAN_NOT_BE_ZERO");
        }
        require(order.endTime > block.timestamp,"ORDER_END_DATE_EXPIRED");
    } 

    function validateMatchOrder(LibOrder.Order memory buyOrder, LibOrder.Order memory sellOrder) internal view  {
        require(buyOrder.makeAsset.value != uint256(0),"VALUE_CAN_NOT_BE_ZERO");
        require(buyOrder.endTime > block.timestamp,"BUYORDER_END_DATE_EXPIRED");
        require(sellOrder.endTime > block.timestamp,"SELLORDER_END_DATE_EXPIRED");
        if(buyOrder.takerAddress != address(0)){
            require(buyOrder.takerAddress == sellOrder.makerAddress,"BUYORDER_TAKER_ADDRESS_AND_SELLORDER_MAKER_ADDRESS_DONT_MATCH");
       }
        if(sellOrder.takeAsset.token != address(0)){
            require(buyOrder.takeAsset.token == sellOrder.makeAsset.token,"BUYORDER_TAKER_ADDRESS_AND_SELLORDER_MAKER_ADDRESS_DONT_MATCH");
        }
        if(sellOrder.takerAddress != address(0) ){
            require(buyOrder.makerAddress == sellOrder.takerAddress,"SELLORDER_TAKER_ADDRESS_AND_BUYORDER_MAKER_ADDRESS_DONT_MATCH");
            require(buyOrder.takeAsset.token == sellOrder.makeAsset.token,"SELLORDER_TAKEASSET_AND_BUYORDER_MAKEASSET_DONT_MATCH");
        }
        require(sellOrder.takeAsset.assetType == buyOrder.makeAsset.assetType,"SELLORDER_TAKE_ASSET_AND_BUYORDER_MAKE_ASSET_DONT_MATCH");
        require(buyOrder.takeAsset.assetType == sellOrder.makeAsset.assetType,"BUYORDER_TAKE_ASSET_AND_SELLORDER_MAKE_ASSET_DONT_MATCH");
        require(sellOrder.makeAsset.value >= buyOrder.takeAsset.value,"SELLORDER_MAKE_VALUE_AND_BUYORDER_TAKE_VALUE_DONT_MATCH");
        require(buyOrder.takeAsset.value <= sellOrder.makeAsset.value,"BUYORDER_TAKE_VALUE_AND_SELLORDER_MAKE_VALUE_DONT_MATCH");
    } 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Lib/LibOrder.sol";
import "./Lib/LibAsset.sol";
import "./Lib/LibSignature.sol";
import "./Lib/LibFeeManager.sol";
import "./Validator/Validator.sol";
import "./Interface/IERC1155.sol";
import "./Interface/IERC721.sol";
import "./Interface/IERC20.sol";
import "./Interface/ITransferProxy.sol";

/**
 * @title ExchangeV1
 * @dev Implements NFT sell process
 * @author development team
 */

contract TransferManager  {

    function transfer(ITransferProxy transferProxyAddress, LibAsset.Asset memory asset, address from, address to, uint value)
        internal
      
    {
        if (asset.assetType == LibAsset.AssetType.PLATFORM_TOKEN) {
            safeSendPlatformToken(to, value);
        } else if (asset.assetType == LibAsset.AssetType.ERC20) {
            ITransferProxy(transferProxyAddress).erc20safeTransferFrom(IERC20(asset.token), from, to, value);
        } else if (asset.assetType == LibAsset.AssetType.ERC721) {
            ITransferProxy(transferProxyAddress).erc721safeTransferFrom(IERC721(asset.token), from, to, asset.tokenId);
        } else if (asset.assetType == LibAsset.AssetType.ERC1155) {
            ITransferProxy(transferProxyAddress).erc1155safeTransferFrom(IERC1155(asset.token), from, to, asset.tokenId, value, "");
        } 
    }

    function safeSendPlatformToken(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "PLATFORM_TOKEN_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

library LibSignature {

    function verify(
        address _signer,
        bytes32  _hashedData,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(_hashedData);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

        function splitSignature(bytes memory sig) public pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

        function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./LibOrder.sol";
import "./LibAsset.sol";

library LibRoyaltiesManager {

    enum DeservingOfRoyaltiesSide { NOROYALTIES, BUYSIDE, SELLSIDE}

    function getDeservingOfRoyaltiesSide(LibOrder.Order memory buyOrder, LibOrder.Order memory sellOrder) internal pure returns (DeservingOfRoyaltiesSide) {
        if (buyOrder.makeAsset.assetType == LibAsset.AssetType.ERC1155 && sellOrder.makeAsset.assetType == LibAsset.AssetType.ERC1155) {
            return DeservingOfRoyaltiesSide.NOROYALTIES;
        }
        else if (buyOrder.makeAsset.assetType == LibAsset.AssetType.ERC1155) {
            return DeservingOfRoyaltiesSide.BUYSIDE;
        }
        else if (sellOrder.makeAsset.assetType == LibAsset.AssetType.ERC1155) {
            return DeservingOfRoyaltiesSide.SELLSIDE;
        }

        return DeservingOfRoyaltiesSide.NOROYALTIES;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LibAsset.sol";

library LibOrder {
    using SafeMath for uint;

    enum AssetType { ERC20,ERC721, ERC1155, PLATFORM_TOKEN}

    struct Order {
        address makerAddress;
        LibAsset.Asset makeAsset;
        address takerAddress;
        LibAsset.Asset takeAsset;
        uint startTime;
        uint endTime;
        bytes salt;
        bytes signature;
    }

    function orderKeyHash(Order memory order) internal pure returns (bytes32) {
            return keccak256(abi.encode(
                order.makerAddress,
                LibAsset.assetHash(order.makeAsset),
                LibAsset.assetHash(order.takeAsset),
                order.startTime,
                order.endTime,
                order.salt
            ));
        }
    
    function orderHash(Order memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                orderKeyHash(order),
                LibAsset.assetHash(order.makeAsset),
                order.takerAddress,
                LibAsset.assetHash(order.takeAsset),
                order.startTime,
                order.endTime,
                order.salt
            ));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./LibOrder.sol";
import "./LibAsset.sol";

library LibFeeManager {

    enum FeeSide { NOFEE, BUYSIDE, SELLSIDE}

    function getFeeSide(LibOrder.Order memory buyOrder, LibOrder.Order memory sellOrder) internal pure returns (FeeSide ) {
        if (buyOrder.makeAsset.assetType == LibAsset.AssetType.PLATFORM_TOKEN) {
            return FeeSide.BUYSIDE;
        }
        if (sellOrder.makeAsset.assetType == LibAsset.AssetType.PLATFORM_TOKEN) {
            return FeeSide.SELLSIDE;
        }
        if (buyOrder.makeAsset.assetType == LibAsset.AssetType.ERC20) {
            return FeeSide.BUYSIDE;
        }
        if (sellOrder.makeAsset.assetType == LibAsset.AssetType.ERC20) {
            return FeeSide.SELLSIDE;
        }
        return FeeSide.NOFEE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

library LibFee {

    enum FeeType { BuyerFee, SellerFee }

    struct Fee {
        address feeAddress;
        address feeSendAddress;
        uint feeValue;
        FeeType feeType;
        uint startTime;
        uint endTime;
        bytes feeSignature;
    }

    function feeHash(Fee memory fee) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                fee.feeAddress,
                fee.feeValue,
                fee.feeType,
                fee.startTime,
                fee.endTime
            ));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

library LibAsset {

    enum AssetType { ERC20,ERC721, ERC1155, PLATFORM_TOKEN}

    struct Asset {
        address token;
        uint tokenId;
        AssetType assetType;
        uint value;
    }

    function assetHash(Asset memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                asset.token,
                asset.tokenId,
                asset.assetType,
                asset.value
            ));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


/**
 * @title IERC1155
 * @dev Implements NFT sell process
 * @author development team
 **/

library BpLibrary {
    using SafeMath for uint;

    function bp(uint value, uint bpValue) internal pure returns (uint) {
        return value.mul(bpValue).div(10000);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

/**
 * @title ITransferProxy
 * @dev Implements NFT sell process
 * @author development team
 **/
 
interface ITransferProxy {

    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external;

    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) external;
    
    function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 value, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/**
 * @title IERC721
 * @dev Implements NFT sell process
 * @author development team
 **/
 
interface IERC721 {

    function getApproved(uint256 tokenId) external view returns (address operator);
    
    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address owner);
    
    function balanceOf(address owner) external view returns (uint256 balance);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/**
 * @title IERC20
 * @dev Implements NFT sell process
 * @author development team
 **/
 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/**
 * @title IERC1155
 * @dev Implements NFT sell process
 * @author development team
 **/
 
interface IERC1155 {

    function isApprovedForAll(address _tokenOwnerAddress ,address _proxyContractAddress) external  returns (bool);

    function balanceOf(address _tokenOwnerAddress,uint256 _tokenId) external  view returns (uint256) ;
    
    function getRoyaltyAddress( uint256 _tokenId)  external view  returns (address) ;
  
    function getRoyaltyRate(uint256 _tokenId ) external view returns (uint256) ;

    function safeTransferFrom(address _fromAddress,address _toAdress,uint256 _tokenId,uint256 _amount, bytes memory data) external  ;
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}