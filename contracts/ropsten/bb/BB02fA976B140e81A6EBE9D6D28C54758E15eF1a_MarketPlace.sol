/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return;
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    function recover(bytes32 hash,uint8 v,bytes32 r,bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) external returns (bytes4);
}

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
}

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator,address indexed from,address indexed to,uint256[] ids,uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes calldata data) external;
    function safeBatchTransferFrom(address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external;
}

abstract contract ERC721Holder is IERC721Receiver {
    function onERC721Received(address,address,uint256,bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

abstract contract Context  {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Revert {
    error notOwner(string message);

    modifier zeroAddress(address _address){
        require(_address != address(0), 'ZERO_ADDRESS');
        _;  
    }
}

abstract contract Ownable is Context, Revert{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        if(_msgSender() != owner()) revert notOwner('NOT_AN_OWNER');
        _;
    }

    function renounceOwnership() public onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address _newOwner) public onlyOwner zeroAddress(_newOwner){
        _setOwner(_newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Beneficiary is Ownable {
    
    address private _beneficiary;
    uint256 private _beneficiaryFees = 1000000000000000;

    event BeneficiaryTransferred(address indexed oldBeneficiary, address indexed newBeneficiary);

    constructor(address _newBeneficiary) {
        _transferBeneficiary(_newBeneficiary);
    }

    function setBeneficiaryFees(uint256 _fees) external onlyOwner returns(bool){
        _beneficiaryFees = _fees;
        return true;
    }

    function transferBeneficiary(address _newBeneficiary) external onlyOwner zeroAddress(_newBeneficiary){
        _transferBeneficiary(_newBeneficiary);
    }

    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    function beneficiaryFees() public view returns(uint){
        return _beneficiaryFees;
    }

    function _transferBeneficiary(address _newBeneficiary) private {
        address oldBeneficiary = _beneficiary;
        _beneficiary = _newBeneficiary;
        emit BeneficiaryTransferred(oldBeneficiary, _newBeneficiary);
    }

}

contract MarketPlace is Beneficiary, ERC721Holder{

    IERC20 private token;

    constructor(address beneficiary_) Beneficiary(beneficiary_){

    }

    enum asset{
        ERC20,
        ERC721,
        ERC1155
    }

    struct order {
        asset Asset;
        address token;
        uint256 numTokens;
        uint256 tokenId;
        uint256 tokenQuantity;
    }

    struct orderBook {
        uint256 sequenceId;
        address user;
        order Order;
        order ExchangeFor;
        uint256 expiry;
        uint256 nonce;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping(uint256 => orderBook) private _orderDetails;
    mapping(uint256 => uint256) private _sequenceIsExist;
    mapping(address => uint256) private _nonce;
    mapping(bytes32 => bool) private isHashExsit;

    function Exchange(
        orderBook calldata makerOrder,
        orderBook calldata takerOrder
    ) external {
        orderValidation(makerOrder, takerOrder);

        token.transferFrom(makerOrder.user, beneficiary(), beneficiaryFees());
        token.transferFrom(takerOrder.user, beneficiary(), beneficiaryFees());

        _sequenceIsExist[makerOrder.sequenceId]++;
        _orderDetails[makerOrder.sequenceId] = makerOrder;
        _sequenceIsExist[takerOrder.sequenceId]++;
        _orderDetails[takerOrder.sequenceId] = takerOrder;

        IERC20 ERC20Token;
        IERC721 ERC721Token;
        IERC1155 ERC1155Token;
        address ERC20Receiver;
        address ERC721Receiver;
        address ERC1155Receiver;
        uint256 numTokens;
        uint256 tokenId721;
        uint256 tokenId1155;
        uint256 tokenQuantity;

        if((makerOrder.Order.Asset == asset.ERC20 && 
        takerOrder.ExchangeFor.Asset == asset.ERC20 &&
        takerOrder.Order.Asset == asset.ERC721 && 
        makerOrder.ExchangeFor.Asset == asset.ERC721) || 
        (makerOrder.Order.Asset == asset.ERC721 && 
        takerOrder.ExchangeFor.Asset == asset.ERC721 &&
        takerOrder.Order.Asset == asset.ERC20 && 
        makerOrder.ExchangeFor.Asset == asset.ERC20)
        ){
            if((makerOrder.Order.Asset == asset.ERC20 && 
            takerOrder.ExchangeFor.Asset == asset.ERC20 &&
            takerOrder.Order.Asset == asset.ERC721 && 
            makerOrder.ExchangeFor.Asset == asset.ERC721)
            ){
                ERC20Token = IERC20(takerOrder.ExchangeFor.token);
                ERC20Receiver = takerOrder.user;
                numTokens = takerOrder.ExchangeFor.numTokens;

                ERC721Token = IERC721(makerOrder.ExchangeFor.token);
                ERC721Receiver = makerOrder.user;
                tokenId721 = makerOrder.ExchangeFor.tokenId;
            } else {
                ERC20Token = IERC20(makerOrder.ExchangeFor.token);
                ERC20Receiver = makerOrder.user;
                numTokens = makerOrder.ExchangeFor.numTokens;

                ERC721Token = IERC721(takerOrder.ExchangeFor.token);
                ERC721Receiver = takerOrder.user;
                tokenId721 = takerOrder.ExchangeFor.tokenId;
            }

            ERC20Token.transferFrom(ERC721Receiver, ERC20Receiver, numTokens);
            ERC721Token.transferFrom(ERC20Receiver, ERC721Receiver, tokenId721);
        }

        if((makerOrder.Order.Asset == asset.ERC721 && 
        takerOrder.ExchangeFor.Asset == asset.ERC721 &&
        takerOrder.Order.Asset == asset.ERC1155 && 
        makerOrder.ExchangeFor.Asset == asset.ERC1155) || 
        (makerOrder.Order.Asset == asset.ERC1155 && 
        takerOrder.ExchangeFor.Asset == asset.ERC1155 &&
        takerOrder.Order.Asset == asset.ERC721 && 
        makerOrder.ExchangeFor.Asset == asset.ERC721)
        ){
            if(makerOrder.Order.Asset == asset.ERC721 && 
            takerOrder.ExchangeFor.Asset == asset.ERC721 &&
            takerOrder.Order.Asset == asset.ERC1155 && 
            makerOrder.ExchangeFor.Asset == asset.ERC1155
            ){
                ERC721Token = IERC721(takerOrder.ExchangeFor.token);
                ERC721Receiver = takerOrder.user;
                tokenId721 = takerOrder.ExchangeFor.tokenId;

                ERC1155Token = IERC1155(makerOrder.ExchangeFor.token);
                ERC1155Receiver = makerOrder.user;
                tokenId1155 = makerOrder.ExchangeFor.tokenId;
                tokenQuantity = makerOrder.ExchangeFor.tokenQuantity;
            } else {
                ERC721Token = IERC721(makerOrder.ExchangeFor.token);
                ERC721Receiver = makerOrder.user;
                tokenId721 = makerOrder.ExchangeFor.tokenId;

                ERC1155Token = IERC1155(takerOrder.ExchangeFor.token);
                ERC1155Receiver = takerOrder.user;
                tokenId1155 = takerOrder.ExchangeFor.tokenId;
                tokenQuantity = takerOrder.ExchangeFor.tokenQuantity;
            }

            ERC721Token.transferFrom(ERC1155Receiver, ERC721Receiver, tokenId721);
            ERC1155Token.safeTransferFrom(ERC721Receiver, ERC1155Receiver, tokenId1155, tokenQuantity, bytes('success'));
        }

        if((makerOrder.Order.Asset == asset.ERC20 && 
        takerOrder.ExchangeFor.Asset == asset.ERC20 &&
        takerOrder.Order.Asset == asset.ERC1155 && 
        makerOrder.ExchangeFor.Asset == asset.ERC1155) || 
        (makerOrder.Order.Asset == asset.ERC1155 && 
        takerOrder.ExchangeFor.Asset == asset.ERC1155 &&
        takerOrder.Order.Asset == asset.ERC20 && 
        makerOrder.ExchangeFor.Asset == asset.ERC20)
        ){
            if(makerOrder.Order.Asset == asset.ERC20 && 
            takerOrder.ExchangeFor.Asset == asset.ERC20 &&
            takerOrder.Order.Asset == asset.ERC1155 && 
            makerOrder.ExchangeFor.Asset == asset.ERC1155
            ){
                ERC20Token = IERC20(takerOrder.ExchangeFor.token);
                ERC20Receiver = takerOrder.user;
                numTokens = takerOrder.ExchangeFor.numTokens;

                ERC1155Token = IERC1155(makerOrder.ExchangeFor.token);
                ERC1155Receiver = makerOrder.user;
                tokenId1155 = makerOrder.ExchangeFor.tokenId;
                tokenQuantity = makerOrder.ExchangeFor.tokenQuantity;
            } else {
                ERC20Token = IERC20(makerOrder.ExchangeFor.token);
                ERC20Receiver = makerOrder.user;
                numTokens = makerOrder.ExchangeFor.numTokens;

                ERC1155Token = IERC1155(takerOrder.ExchangeFor.token);
                ERC1155Receiver = takerOrder.user;
                tokenId1155 = takerOrder.ExchangeFor.tokenId;
                tokenQuantity = takerOrder.ExchangeFor.tokenQuantity;
            }

            ERC20Token.transferFrom(ERC1155Receiver, ERC20Receiver, numTokens);
            ERC1155Token.safeTransferFrom(ERC20Receiver, ERC1155Receiver, tokenId1155, tokenQuantity, bytes('success'));
        }

    }

    function orderValidation(
        orderBook calldata makerOrder, 
        orderBook calldata takerOrder
    ) private {
        require(_sequenceIsExist[makerOrder.sequenceId] == 0,'MAKER SEQUENCE ID IS AVAILABLE');
        require(_sequenceIsExist[takerOrder.sequenceId] == 0, 'TAKER SEQUENCE ID IS AVAILABLE');

        require(makerOrder.expiry >= block.timestamp,'MAKER: ORDER EXPIRED');
        require(takerOrder.expiry >= block.timestamp,'TAKER: ORDER EXPIRED');

        require(makerOrder.user == validateSig(makerOrder), 'MAKER: INVALID V R S');
        require(takerOrder.user == validateSig(takerOrder), 'TAKER: INVALID V R S');

        require(makerOrder.Order.Asset == takerOrder.ExchangeFor.Asset,'MAKER: MISS MATCH IN ASSET REQUIREMENT');
        require(makerOrder.Order.token == takerOrder.ExchangeFor.token,'MAKER: MISS MATCH IN REQUIREMENT TOKEN');
        require(makerOrder.Order.numTokens == takerOrder.ExchangeFor.numTokens,'MAKER: MISS MATCH IN REQUIREMENT NUMTOKENS');
        require(makerOrder.Order.tokenId == takerOrder.ExchangeFor.tokenId,'MAKER: MISS MATCH IN REQUIREMENT TOKENID');
        require(makerOrder.Order.tokenQuantity == takerOrder.ExchangeFor.tokenQuantity,'MAKER: MISS MATCH IN REQUIREMENT QUANTITY');

        require(takerOrder.Order.Asset == makerOrder.ExchangeFor.Asset,'TAKER: MISS MATCH IN ASSET REQUIREMENT');
        require(takerOrder.Order.token == makerOrder.ExchangeFor.token,'TAKER: MISS MATCH IN REQUIREMENT TOKEN');
        require(takerOrder.Order.numTokens == makerOrder.ExchangeFor.numTokens,'TAKER: MISS MATCH IN REQUIREMENT NUMTOKENS');
        require(takerOrder.Order.tokenId == makerOrder.ExchangeFor.tokenId,'TAKER: MISS MATCH IN REQUIREMENT TOKENID');
        require(takerOrder.Order.tokenQuantity == makerOrder.ExchangeFor.tokenQuantity,'TAKER: MISS MATCH IN REQUIREMENT QUANTITY');
    }

    function validateSig(orderBook calldata orders) private returns(address){
        bytes32 messageHash = createMessageHash(orders);
        messageHash = ECDSA.toEthSignedMessageHash(messageHash);
        require(!isHashExsit[messageHash], 'validateSig : HASH EXIST');
        isHashExsit[messageHash] = true;
        _nonce[orders.user]++;
        return ECDSA.recover(messageHash, orders.v, orders.r, orders.s);
    }

    function createMessageHash(orderBook calldata orders) private pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                orders.sequenceId,
                orders.user,
                orders.expiry,
                orders.nonce,
                abi.encodePacked(
                    orders.Order.Asset,
                    orders.Order.token,
                    orders.Order.numTokens,
                    orders.Order.tokenId,
                    orders.Order.tokenQuantity
                ),
                abi.encodePacked(
                    orders.ExchangeFor.Asset,
                    orders.ExchangeFor.token,
                    orders.ExchangeFor.numTokens,
                    orders.ExchangeFor.tokenId,
                    orders.ExchangeFor.tokenQuantity
                )
            )
        );
    }

    function setTokenAddress(address _token) external onlyOwner zeroAddress(_token) returns(bool){
        token = IERC20(_token);
        return true;
    }
}