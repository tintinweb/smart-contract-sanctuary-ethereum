// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

import "./helpers/ERC2771Recipient.sol";
import "./interfaces/ISingularityRouter.sol";

interface IDaiPermit {
    function permit(address holder, address spender, uint256 nonce, uint256 expiry,
    bool allowed, uint8 v, bytes32 r, bytes32 s) external ;
}

contract Singularity is Initializable, OwnableUpgradeable, ERC2771Recipient, PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, EIP712Upgradeable {

    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    ISingularityRouter public singularityRouter;

    bytes32 public constant DIRECT_TRANSFER_WITH_EXCHANGE_TYPEHASH = keccak256("directTransferWithExchange(address sender,address paymentAddress,address receiver,uint256 paymentAmount,address paymentAssetAddress,uint256 exchangeAmount,uint256 assetId,address assetAddress,address approver,string nftType,string txId,uint256 nonce)");
    bytes32 constant public SWAP_BRIDGE_TRANSFER_WITH_EXCHANGE_TYPEHASH = keccak256("swapBridgeTransferWithExchange(address sender,address paymentAddress,uint256 swapRouteId,address swapReceiver,address fromTokenAddress,address toTokenAddress,uint256 inAmount,uint256 outAmount,bytes swapData,uint256 bridgeRouteId,address bridgeReceiver,uint256 destChainId,address bridgeTokenAddress,uint256 amount,bytes bridgeData,uint256 exchangeAmount,uint256 assetId,address assetAddress,bytes32 nftType,uint256 s9yFee,string txId,uint256 nonce)");
    bytes32 constant public SWAP_BRIDGE_TRANSFER_TYPEHASH = keccak256("swapBridgeTransfer(address sender,address paymentAddress,SwapRequestData swapRequestData,BridgeRequestData bridgeRequestData,uint256 s9yFee,string txId,uint256 nonce)SwapRequestData(uint256 routeId,address receiver,address fromTokenAddress,address toTokenAddress,uint256 inAmount,uint256 outAmount,bytes data)BridgeRequestData(uint256 routeId,address receiver,uint256 destChainId,address tokenAddress,uint256 amount,bytes data)");
    
    mapping(address => uint256) private userTxNonce;

    struct ExchangeRequestData {
        uint256 exchangeAmount;
        uint256 assetId;
        address assetAddress;
        address approver;
        string nftType;
    }

    struct ApprovalData {
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint256 nonce;
        string approvalType; // NATIVE_APPROVAL, PERMIT
    }

    struct S9YData {
        uint256 s9yFee;
        uint256 subTxId;
        string txId;
        bytes adminSignature;
        bytes data;
    }

    /// @custom:oz-renamed-from swapAllowed
    bool public pausedSwapOrBridging ;
    /// @custom:oz-renamed-from directTransferAllowed
    bool public pausedDirectTransfer;
    /// @custom:oz-renamed-from externalFiatPayAllowed
    bool public pausedExternalFiatPay;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string calldata _name, string calldata _version, address[] calldata _adminAddresses) public initializer {
        __Pausable_init();
        __Ownable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __EIP712_init(_name, _version);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, SUPER_ADMIN_ROLE);

        pausedSwapOrBridging = false ;
        pausedDirectTransfer = false ;
        pausedExternalFiatPay = false ;

        // Granting Access to all Programatic Admin Addresses
        for(uint256 i = 0; i < _adminAddresses.length; i++) {
            _grantRole(ADMIN_ROLE, _adminAddresses[i]);
        }
    }

/*
******************************************Contract Settings Functions****************************************************
*/


    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function addSuperAdmin(address _superAdmin) public onlyOwner {
        _grantRole(SUPER_ADMIN_ROLE, _superAdmin);
    }

    function addAdmin(address _admin) public onlySuperAdmin {
        _grantRole(ADMIN_ROLE, _admin);
    }

    function addPauser(address account) public onlySuperAdmin {
        _grantRole(PAUSER_ROLE, account);
    }

    function removeSuperAdmin(address _superAdmin) public onlyOwner {
        _revokeRole(SUPER_ADMIN_ROLE, _superAdmin);
    }

    function removeAdmin(address _admin) public onlySuperAdmin {
        _revokeRole(ADMIN_ROLE, _admin);
    }

    function removePauser(address _pauser) public onlySuperAdmin {
        _revokeRole(PAUSER_ROLE, _pauser);
    }        

    function pauseSwapOrBridging(bool _pausedswapOrBridging) public onlyPauser() {
        pausedSwapOrBridging= _pausedswapOrBridging;
    }

    function pauseDirectTransfer(bool _pausedDirectTransfer) public onlyPauser {
        pausedDirectTransfer = _pausedDirectTransfer;
    }

    function pauseExternalFiatPay(bool _pausedExternalFiatPay) public onlyPauser {
        pausedExternalFiatPay = _pausedExternalFiatPay;
    }


/*
************************************************************Contract Modifiers***************************************************
*/

    /**
    * @dev overriding the inherited {transferOwnership} function to reflect the admin changes into the {DEFAULT_ADMIN_ROLE}
    */
    
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    

    /**
    * @dev modifier to check super admin rights.
    * contract owner and super admin have super admin rights
    */

    modifier onlySuperAdmin() {
        require(
            hasRole(SUPER_ADMIN_ROLE, _msgSender()) ||
            owner() == _msgSender(),
            "Unauthorized Access");
        _;
    }

    /**
    * @dev modifier to check admin rights.
    * contract owner, super admin and admins have admin rights
    */
    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()) ||
            hasRole(SUPER_ADMIN_ROLE, _msgSender()) ||
            owner() == _msgSender(),
            "Unauthorized Access");
        _;
    }

    /**
    * @dev modifier to check pause rights.
    * contract owner, super admin and pausers's have pause rights
    */
    modifier onlyPauser() {
        require(
            hasRole(PAUSER_ROLE, _msgSender()) ||
            hasRole(SUPER_ADMIN_ROLE, _msgSender()) || 
            owner() == _msgSender(),
            "Unauthorized Access");
        _;
    }

    modifier whenSwapOrBridgingPaused() {
        require(pausedSwapOrBridging, "Swap/Bridging Is Not Disabled");
        _;
    }

    modifier whenSwapOrBridgingNotPaused() {
        require(!pausedSwapOrBridging, "Swap Is Disabled");
        _;
    }

    modifier whenDirectTransferPaused() {
        require(pausedDirectTransfer, "Direct Transfer Is Not Disabled");
        _;
    }

    modifier whenDirectTransferNotPaused() {
        require(!pausedDirectTransfer, "Direct Transfer Is Disabled");
        _;
    }

    modifier whenExternalFiatPayPaused() {
        require(pausedExternalFiatPay, "External Fiat Payement Is Not Disabled");
        _;
    }

    modifier whenExternalFiatPayNotPaused() {
        require(!pausedExternalFiatPay, "External Fiat Payement Is Disabled");
        _;
    }
/*
****************************************** Interface Initilization Functions ****************************************************
*/    

    function setTrustedForwarder(address _newtrustedForwarder) public onlySuperAdmin {
        _setTrustedForwarder(_newtrustedForwarder);
    }

    function setSingularityRouter(address _singularityRouterAddress) public onlySuperAdmin {
        singularityRouter = ISingularityRouter(_singularityRouterAddress);
    }

/*
************************************************************ EIP712, Hashing and Signature Handling ***********************************************
*/

    function _verifyAdmin(bytes32 digest, bytes memory signature) internal view returns (bool) {
        address signer = ECDSAUpgradeable.recover(digest, signature);
        return (hasRole(ADMIN_ROLE, signer));
    }

    function _directTransferWithExchangeDigest(address _sender, address _paymentAddress, address _receiver, uint256 _paymentAmount, address _paymentAssetAddress, ExchangeRequestData calldata _exchangeRequestData, string calldata _txId, uint256 nonce) internal view returns(bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            DIRECT_TRANSFER_WITH_EXCHANGE_TYPEHASH,
            _sender, _paymentAddress, _receiver, _paymentAmount, _paymentAssetAddress, _exchangeRequestData.exchangeAmount, _exchangeRequestData.assetId, _exchangeRequestData.assetAddress, _exchangeRequestData.approver, keccak256(abi.encodePacked(_exchangeRequestData.nftType)), keccak256(abi.encodePacked(_txId)), nonce
        )));
    }


    function _swapBridgeTransferWithExchangeDigest(address _sender, address _paymentAddress, ISingularityRouter.SwapRequestData calldata _swapRequestData, ISingularityRouter.BridgeRequestData calldata _bridgeRequestData,  ExchangeRequestData calldata _exchangeRequestData, S9YData calldata _s9yData, uint256 _nonce) internal view returns(bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            SWAP_BRIDGE_TRANSFER_WITH_EXCHANGE_TYPEHASH,
            _sender, 
            _paymentAddress,
            _swapRequestData,
            _bridgeRequestData,
            _exchangeRequestData.exchangeAmount,
            _exchangeRequestData.assetId, 
            _exchangeRequestData.assetAddress,
            keccak256(abi.encodePacked(_exchangeRequestData.nftType)), 
            _s9yData.s9yFee,
            keccak256(abi.encodePacked(_s9yData.txId)), 
            _nonce
        )));
    }


    function _swapBridgeTransferDigest(address _sender, address _paymentAddress, ISingularityRouter.SwapRequestData calldata _swapRequestData, ISingularityRouter.BridgeRequestData calldata _bridgeRequestData, S9YData calldata _s9yData, uint256 _nonce) internal view returns(bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            SWAP_BRIDGE_TRANSFER_TYPEHASH,
            _sender, 
            _paymentAddress,
            _swapRequestData,
            _bridgeRequestData,
            _s9yData.s9yFee,
            keccak256(abi.encodePacked(_s9yData.txId)), 
            _nonce
        )));
    }

/*
********************************************** Contract Events *********************************************************************
*/    

    event TokenTransferred(address indexed sender, address indexed receiver, uint256 amount, address assetAddress, string transferType, uint256 subTxId, string txId);

    event ExternalFiatTransfer(address indexed sender, address indexed receiver, uint256 _amount, address tokenAddress, string transferType, uint256 subTxId, string txId);
    event FiatExchangeTransferFailure(address indexed sender, address indexed receiver, uint256 amount, address tokenAddress, uint256 subTxId, string txId, string reason);
    
    event TokenIssued(address indexed sender, address indexed receiver, uint256 amount, address tokenAddress, string transferType, uint256 subTxId, string txId);
    event NftIssued(address indexed sender, address indexed receiver, uint256 amount, address nftAddress, uint256 nftId, string nftType, string transferType, uint256 subTxId, string txId);



/*
***************************************************************************** General Functions***********************************************************************
*/

    function getUserCurrentTxNonce(address _userAddress) public view returns(uint256) {
        return userTxNonce[_userAddress];
    }


/*
***************************************************************************** Collect Payment Functions ******************************************************************
*/


    // This function needs prior approval from sender
    function directTokenTransfer(address _sender, address _paymentAddress, address _receiver, uint256 _amount, address _paymentAssetAddress, ApprovalData calldata _approvalData, S9YData calldata _s9yData) public whenNotPaused whenDirectTransferNotPaused nonReentrant {
        require(_msgSender() == _paymentAddress || hasRole(ADMIN_ROLE, _msgSender()), "Sender Mismatch");
        _executeTokenApproval(_paymentAddress, address(this), _paymentAssetAddress, _amount, _approvalData);
        _transferToken(_paymentAddress, _receiver, _paymentAssetAddress, _amount);
        emit TokenTransferred(_paymentAddress, _receiver, _amount, _paymentAssetAddress, "DIRECT_TOKEN_TRANSFER", _s9yData.subTxId, _s9yData.txId);
    }

    function directNativeTransfer(address _sender, address _paymentAddress, address _receiver, uint256 _amount, S9YData calldata _s9yData) public payable whenNotPaused whenDirectTransferNotPaused nonReentrant {
        require(_msgSender() == _paymentAddress || hasRole(ADMIN_ROLE, _msgSender()), "Sender Mismatch");
        require(msg.value == _amount, "Amount not equal to msg.value");
        payable(_receiver).transfer(_amount);
        emit TokenTransferred(_sender, _receiver, _amount, 0xaBcDEf0000000000000000000000000000000000, "DIRECT_NATIVE_TRANSFER", _s9yData.subTxId, _s9yData.txId);
    }

/*
*******************************************************************External OnRamp/Fiat Payment*********************************************************
*/
    function _collectExternalFiatPayment(address _sender, address _receiver, address _assetAddress, uint256 _amount, string calldata _transferType, uint256 _subTxId, string calldata _txId) internal {
        if(keccak256(abi.encode(_transferType)) == keccak256(abi.encode("NATIVE"))) {

            require(msg.value >= _amount, "Amount Miss Match");
            emit ExternalFiatTransfer(_sender, _receiver, _amount, address(0), "FIAT_EXCHANGE_TRANSFER", _subTxId, _txId);

            if(_receiver != address(this)) {
                payable(_receiver).transfer(_amount);
            }

        }else if (keccak256(abi.encode(_transferType)) == keccak256(abi.encode("NON_NATIVE"))) {
           _transferToken(0xCD9474c57fe74937ed7BF030C2caDa67BF009DEc, _receiver, _assetAddress, _amount);
            emit ExternalFiatTransfer(_sender, _receiver, _amount, _assetAddress, "FIAT_EXCHANGE_TRANSFER", _subTxId, _txId);
        }
    }

    function externalFiatPay(address _sender, address _paymentAddress, address _receiver, address _assetAddress, uint256 _amount,
    string calldata _paymentTransferType, S9YData calldata _s9yData) public payable whenNotPaused whenExternalFiatPayNotPaused nonReentrant {
        _collectExternalFiatPayment(_sender, _receiver, _assetAddress, _amount, _paymentTransferType, _s9yData.subTxId, _s9yData.txId);
        emit ExternalFiatTransfer(_sender, _receiver, _amount, _assetAddress, "FIAT_EXCHANGE_TRANSFER", _s9yData.subTxId, _s9yData.txId);
    }

    // function externalFiatPayWithTokenExchange(address _sender, address _paymentAddress, address _receiver, address _assetAddress,
    // uint256 _amount, string calldata _paymentTransferType,
    // ExchangeRequestData calldata _tokenData, S9YData calldata _s9yData) public payable whenNotPaused whenExternalFiatPayNotPaused nonReentrant {
    //     _collectExternalFiatPayment(_sender, _receiver, _assetAddress, _amount, _paymentTransferType, _s9yData.subTxId, _s9yData.txId);
    //     _transferToken(_tokenData.approver, _receiver, _tokenData.assetAddress, _tokenData.exchangeAmount);
    //     emit ExternalFiatTransfer(_sender, _receiver, _amount, _assetAddress, "FIAT_EXCHANGE_TRANSFER_WITH_TOKEN_EXCHANGE", _s9yData.subTxId, _s9yData.txId);
    //     emit TokenIssued(_tokenData.approver, _sender, _tokenData.exchangeAmount, _tokenData.assetAddress, "FIAT_EXCHANGE_TRANSFER_WITH_TOKEN_EXCHANGE", _s9yData.subTxId, _s9yData.txId);
    // }

    // function externalFiatPayWithNftExchange(address _sender, address _paymentAddress, address _receiver, address _assetAddress, uint256 _amount,
    // string calldata _paymentTransferType, ExchangeRequestData calldata _nftData,
    // S9YData calldata _s9yData) public payable whenNotPaused whenExternalFiatPayNotPaused nonReentrant {
    //     _collectExternalFiatPayment(_sender, _receiver, _assetAddress, _amount, _paymentTransferType, _s9yData.subTxId, _s9yData.txId);
    //     _transferNft(_nftData.approver, _receiver, _nftData.nftType, _nftData.assetAddress, _nftData.assetId, _nftData.exchangeAmount, "");
    //     emit ExternalFiatTransfer(_sender, _receiver, _amount, _assetAddress, "FIAT_EXCHANGE_TRANSFER_WITH_NFT_EXCHANGE", _s9yData.subTxId, _s9yData.txId);
    //     emit NftIssued(_nftData.approver, _sender, _nftData.exchangeAmount, _nftData.assetAddress, _nftData.assetId,  _nftData.nftType, "FIAT_EXCHANGE_TRANSFER_WITH_NFT_EXCHANGE", _s9yData.subTxId, _s9yData.txId);
    // }

    function externalFiatPayWithSwapBridge(address _sender, address _paymentAddress, address _assetAddress, uint256 _amount,
    string calldata _paymentTransferType, ISingularityRouter.SwapRequestData calldata _swapRequestData, ISingularityRouter.BridgeRequestData calldata _bridgeRequestData,
    S9YData calldata _s9yData) public payable whenNotPaused whenExternalFiatPayNotPaused nonReentrant {
        _collectExternalFiatPayment(_sender, address(this), _assetAddress, _amount, _paymentTransferType, _s9yData.subTxId, _s9yData.txId);
        emit ExternalFiatTransfer(_sender, address(this), _amount, _assetAddress, "FIAT_EXCHANGE_TRANSFER_WITH_NFT_EXCHANGE", _s9yData.subTxId, _s9yData.txId);
        _executeSwapBridgeRequestInternal(_swapRequestData, _bridgeRequestData, _s9yData);
    }

/*
******************************************* Direct Exchange Functions ************************************************************************************************************
*/

    function directTokenTransferWithTokenExchange(address _sender, address _paymentAddress, address _receiver, uint256 _paymentAmount, address _paymentAssetAddress, ExchangeRequestData calldata _tokenExchangeRequestData,
     ApprovalData calldata _approvalData, uint256 _nonce, S9YData calldata _s9yData) public whenNotPaused whenDirectTransferNotPaused nonReentrant {

        require(_msgSender() == _paymentAddress || hasRole(ADMIN_ROLE, _msgSender()), "Invalid Sender");
        require(getUserCurrentTxNonce(_sender) == _nonce, "Invalid Tx Nonce");
        require(_verifyAdmin(_directTransferWithExchangeDigest(_sender, _paymentAddress, _receiver, _paymentAmount, _paymentAssetAddress, _tokenExchangeRequestData, _s9yData.txId, _nonce), _s9yData.adminSignature), "Admin Signature Invalid");
        
        _incrementUserTxNonce(_sender);

        // Block Scope Execution
        {
            // Transfer of payment from sender to receiver
            _executeTokenApproval(_paymentAddress, address(this), _paymentAssetAddress, _paymentAmount, _approvalData);
            _transferToken(_paymentAddress, _receiver, _paymentAssetAddress, _paymentAmount);
            emit TokenTransferred(_paymentAddress, _receiver, _paymentAmount, _paymentAssetAddress, "DIRECT_TOKEN_TRANSFER_WITH_TOKEN_EXCHANGE", _s9yData.subTxId, _s9yData.txId);
        }
        {   
            // Transfer of tokens from approver to sender
            _transferToken(_tokenExchangeRequestData.approver, _sender, _tokenExchangeRequestData.assetAddress, _tokenExchangeRequestData.exchangeAmount);
            emit TokenIssued(_tokenExchangeRequestData.approver, _sender, _tokenExchangeRequestData.exchangeAmount, _tokenExchangeRequestData.assetAddress, "DIRECT_TOKEN_TRANSFER_WITH_TOKEN_EXCHANGE", _s9yData.subTxId, _s9yData.txId);
        }
    }


    function directNativeTransferWithTokenExchange(address _sender, address _paymentAddress, address _receiver, uint256 _paymentAmount,
    ExchangeRequestData calldata _tokenExchangeRequestData, uint256 _nonce, S9YData calldata _s9yData) public payable whenNotPaused whenDirectTransferNotPaused nonReentrant {
        require(_msgSender() == _paymentAddress || hasRole(ADMIN_ROLE, _msgSender()), "Invalid Sender");
        require(getUserCurrentTxNonce(_sender) == _nonce, "Invalid Tx Nonce");
        require(_verifyAdmin(_directTransferWithExchangeDigest(_sender, _paymentAddress, _receiver, _paymentAmount, address(0), _tokenExchangeRequestData, _s9yData.txId, _nonce), _s9yData.adminSignature), "Admin Signature Invalid");
        require(msg.value == _paymentAmount, "Payment Amount != Paid Value");

        _incrementUserTxNonce(_sender);

        payable(_receiver).transfer(_paymentAmount);
        emit TokenTransferred(_paymentAddress, _receiver, _paymentAmount, 0xaBcDEf0000000000000000000000000000000000 , "DIRECT_NATIVE_TRANSFER_WITH_TOKEN_EXCHANGE", _s9yData.subTxId, _s9yData.txId);

        // Block Scope Execution
        {
            _transferToken(_tokenExchangeRequestData.approver, _sender, _tokenExchangeRequestData.assetAddress, _tokenExchangeRequestData.exchangeAmount);
            emit TokenIssued(_tokenExchangeRequestData.approver, _sender, _tokenExchangeRequestData.exchangeAmount, _tokenExchangeRequestData.assetAddress, "DIRECT_NATIVE_TRANSFER_WITH_TOKEN_EXCHANGE", _s9yData.subTxId, _s9yData.txId);
        }
    }


    function directTokenTransferWithNftExchange(address _sender, address _paymentAddress, address _receiver, uint256 _paymentAmount,
    address _paymentAssetAddress, ExchangeRequestData calldata _nftExchangeRequestData,
    ApprovalData calldata _approvalData, uint256 _nonce, S9YData calldata _s9yData) public whenNotPaused whenDirectTransferNotPaused nonReentrant {
        require(_msgSender() == _paymentAddress || hasRole(ADMIN_ROLE, _msgSender()), "Invalid Sender");
        require(getUserCurrentTxNonce(_sender) == _nonce, "Invalid Tx Nonce");
        require(_verifyAdmin(_directTransferWithExchangeDigest(_sender, _paymentAddress, _receiver, _paymentAmount, _paymentAssetAddress, _nftExchangeRequestData, _s9yData.txId, _nonce), _s9yData.adminSignature), "Admin Signature Invalid");
        
        _incrementUserTxNonce(_sender);

        // Block Scope Execution
        {
            _executeTokenApproval(_paymentAddress, address(this), _paymentAssetAddress, _paymentAmount, _approvalData);
            _transferToken(_paymentAddress, _receiver, _paymentAssetAddress, _paymentAmount);
            emit TokenTransferred(_paymentAddress, _receiver, _paymentAmount, _paymentAssetAddress, "DIRECT_TOKEN_TRANSFER_WITH_NFT_EXCHANGE", _s9yData.subTxId, _s9yData.txId);
        }
        {
            _transferNft(_nftExchangeRequestData.approver, _sender, _nftExchangeRequestData.nftType, _nftExchangeRequestData.assetAddress, _nftExchangeRequestData.assetId, _nftExchangeRequestData.exchangeAmount, "");
            emit NftIssued(_nftExchangeRequestData.approver, _sender, _nftExchangeRequestData.exchangeAmount, _nftExchangeRequestData.assetAddress, _nftExchangeRequestData.assetId,  _nftExchangeRequestData.nftType, "DIRECT_TOKEN_TRANSFER_WITH_NFT_EXCHANGE", _s9yData.subTxId, _s9yData.txId);
        }
    }


    function directNativeTransferWithNftExchange(address _sender, address _paymentAddress, address _receiver, uint256 _paymentAmount,
    ExchangeRequestData calldata _nftExchangeRequestData,
    uint256 _nonce, S9YData calldata _s9yData) public payable whenNotPaused whenDirectTransferNotPaused nonReentrant {
        require(_msgSender() == _paymentAddress || hasRole(ADMIN_ROLE, _msgSender()), "Invalid Sender");
        require(getUserCurrentTxNonce(_sender) == _nonce, "Invalid Tx Nonce");
        require(_verifyAdmin(_directTransferWithExchangeDigest(_sender, _paymentAddress, _receiver, _paymentAmount, address(0), _nftExchangeRequestData, _s9yData.txId, _nonce), _s9yData.adminSignature), "Admin Signature Invalid");
        require(msg.value == _paymentAmount, "Payment Amount != Paid Value");

        _incrementUserTxNonce(_sender);

        payable(_receiver).transfer(_paymentAmount);
        emit TokenTransferred(_paymentAddress, _receiver, _paymentAmount, 0xaBcDEf0000000000000000000000000000000000, "DIRECT_NATIVE_TRANSFER_WITH_NFT_EXCHANGE", _s9yData.subTxId, _s9yData.txId);

        // Block Scope Execution
        {
            _transferNft(_nftExchangeRequestData.approver, _sender, _nftExchangeRequestData.nftType, _nftExchangeRequestData.assetAddress,  _nftExchangeRequestData.assetId, _nftExchangeRequestData.exchangeAmount, "");
            emit NftIssued(_nftExchangeRequestData.approver, _sender, _nftExchangeRequestData.exchangeAmount, _nftExchangeRequestData.assetAddress, _nftExchangeRequestData.assetId,  _nftExchangeRequestData.nftType, "DIRECT_NATIVE_TRANSFER_WITH_NFT_EXCHANGE", _s9yData.subTxId, _s9yData.txId);
            
        }
    }

/*
******************************************* Swap Exchange Functions *******************************************
*/

    function swapTokenTransferWithTokenExchange(address _sender, address _paymentAddress, uint256 _nonce, ISingularityRouter.SwapRequestData calldata _swapRequestData, ISingularityRouter.BridgeRequestData calldata _bridgeRequestData,
    ExchangeRequestData calldata _tokenExchangeRequestData, ApprovalData calldata _approvalData, S9YData calldata _s9yData) public payable whenNotPaused whenSwapOrBridgingNotPaused nonReentrant {
        require(_msgSender() == _paymentAddress || hasRole(ADMIN_ROLE, _msgSender()), "Invalid Sender");
        require(getUserCurrentTxNonce(_sender) == _nonce, "Invalid Tx Nonce");
        require(_verifyAdmin(_swapBridgeTransferWithExchangeDigest(_sender, _paymentAddress, _swapRequestData, _bridgeRequestData, _tokenExchangeRequestData, _s9yData, _nonce), _s9yData.adminSignature), "Admin Signature Invalid");
       
        _incrementUserTxNonce(_sender);

        {
            _executeSwapBridgeRequest(_sender, _paymentAddress, _swapRequestData, _bridgeRequestData, _approvalData, _s9yData);
        }
        
        {
           _transferToken(_tokenExchangeRequestData.approver, _sender, _tokenExchangeRequestData.assetAddress, _tokenExchangeRequestData.exchangeAmount);
           emit TokenIssued(_tokenExchangeRequestData.approver, _sender, _tokenExchangeRequestData.exchangeAmount, _tokenExchangeRequestData.assetAddress, "SWAP_TOKEN_TRANSFER_WITH_TOKEN_EXCHANGE", _s9yData.subTxId, _s9yData.txId);
        }
    }

    function swapTokenTransferWithNftExchange(address _sender, address _paymentAddress, uint256 _nonce, ISingularityRouter.SwapRequestData calldata _swapRequestData, ISingularityRouter.BridgeRequestData calldata _bridgeRequestData,
    ExchangeRequestData calldata _nftExchangeRequestData, ApprovalData calldata _approvalData, S9YData calldata _s9yData) public payable whenNotPaused whenSwapOrBridgingNotPaused nonReentrant {
        require(_msgSender() == _paymentAddress || hasRole(ADMIN_ROLE, _msgSender()), "Invalid Sender");
        require(getUserCurrentTxNonce(_sender) == _nonce, "Invalid Tx Nonce");
        require(_verifyAdmin(_swapBridgeTransferWithExchangeDigest(_sender, _paymentAddress, _swapRequestData, _bridgeRequestData, _nftExchangeRequestData, _s9yData, _nonce), _s9yData.adminSignature), "Admin Signature Invalid");

        _incrementUserTxNonce(_sender);

        {
            _executeSwapBridgeRequest(_sender, _paymentAddress, _swapRequestData, _bridgeRequestData, _approvalData, _s9yData);
        }

        // Block Scope Execution
        {
           _transferNft(_nftExchangeRequestData.approver, _sender, _nftExchangeRequestData.nftType, _nftExchangeRequestData.assetAddress, _nftExchangeRequestData.assetId, _nftExchangeRequestData.exchangeAmount, "");
            emit NftIssued(_nftExchangeRequestData.approver, _sender, _nftExchangeRequestData.exchangeAmount, _nftExchangeRequestData.assetAddress, _nftExchangeRequestData.assetId,  _nftExchangeRequestData.nftType, "SWAP_TOKEN_TRANSFER_WITH_NFT_EXCHANGE", _s9yData.subTxId, _s9yData.txId);
        }
    }


    function swapBridgeTransfer(address _sender, address _paymentAddress, uint256 _nonce, ISingularityRouter.SwapRequestData calldata _swapRequestData, ISingularityRouter.BridgeRequestData calldata _bridgeRequestData,
    ApprovalData calldata _approvalData, S9YData calldata _s9yData) public payable whenNotPaused whenSwapOrBridgingNotPaused nonReentrant {

        require(_msgSender() == _paymentAddress || hasRole(ADMIN_ROLE, _msgSender()), "Invalid Sender");
        require(getUserCurrentTxNonce(_sender) == _nonce, "Invalid Tx Nonce");
        // require(_verifyAdmin(_swapBridgeTransferDigest(_sender, _paymentAddress, _swapRequestData, _bridgeRequestData, _s9yData, _nonce), _s9yData.adminSignature), "Admin Signature Invalid");

        _incrementUserTxNonce(_sender);
        
        _executeSwapBridgeRequest(_sender, _paymentAddress, _swapRequestData, _bridgeRequestData, _approvalData, _s9yData);

    }


    function _executeSwapBridgeRequest (address _sender, address _paymentAddress, ISingularityRouter.SwapRequestData calldata _swapRequestData, ISingularityRouter.BridgeRequestData calldata _bridgeRequestData, 
    ApprovalData calldata _approvalData, S9YData calldata _s9yData) internal {

            uint256 nativeAmount = 0;

            if(_swapRequestData.routeId != 0 ) {
                uint256 totalTakeoutAmount = _swapRequestData.inAmount + _s9yData.s9yFee;

                if(_swapRequestData.fromTokenAddress != singularityRouter.getNativeWrappedCurrencyAddress()){
                    _executeTokenApproval(_paymentAddress, address(this), _swapRequestData.fromTokenAddress, totalTakeoutAmount, _approvalData);
                    _transferToken(_paymentAddress, address(singularityRouter), _swapRequestData.fromTokenAddress, _swapRequestData.inAmount);

                }else {
                    require(msg.value>= totalTakeoutAmount, "insufficient msg.value");
                    nativeAmount = _swapRequestData.inAmount;
                }
            }else if (_bridgeRequestData.routeId != 0) {
                uint256 totalTakeoutAmount = _bridgeRequestData.amount + _s9yData.s9yFee;

                if(_bridgeRequestData.tokenAddress != singularityRouter.getNativeWrappedCurrencyAddress()){
                    _executeTokenApproval(_paymentAddress, address(this), _bridgeRequestData.tokenAddress, totalTakeoutAmount, _approvalData);
                    _transferToken(_paymentAddress, address(singularityRouter), _bridgeRequestData.tokenAddress, _bridgeRequestData.amount);
                }else{
                   require(msg.value>= totalTakeoutAmount, "insufficient msg.value");
                   nativeAmount = _bridgeRequestData.amount;
                }
            } else {
                revert("Invalid Route");
            }

            ISingularityRouter.RouterRequestData memory routerRequestData = ISingularityRouter.RouterRequestData(
                _paymentAddress,
                _swapRequestData,
                _bridgeRequestData
            ); 

            singularityRouter.performSwapBridgeAction{value: nativeAmount}(routerRequestData, _s9yData.subTxId, _s9yData.txId);
    }


    function _executeSwapBridgeRequestInternal (ISingularityRouter.SwapRequestData calldata _swapRequestData, ISingularityRouter.BridgeRequestData calldata _bridgeRequestData, S9YData calldata _s9yData) internal {

            uint256 nativeAmount = 0;

            if(_swapRequestData.routeId != 0 ) {
                uint256 totalTakeoutAmount = _swapRequestData.inAmount + _s9yData.s9yFee;

                if(_swapRequestData.fromTokenAddress != singularityRouter.getNativeWrappedCurrencyAddress()){
                    _transferToken(address(this), address(singularityRouter), _swapRequestData.fromTokenAddress, _swapRequestData.inAmount);

                }else {
                    require(msg.value>= totalTakeoutAmount, "insufficient msg.value");
                    nativeAmount = _swapRequestData.inAmount;
                }
            }else if (_bridgeRequestData.routeId != 0) {
                uint256 totalTakeoutAmount = _bridgeRequestData.amount + _s9yData.s9yFee;

                if(_bridgeRequestData.tokenAddress != singularityRouter.getNativeWrappedCurrencyAddress()){
                    _transferToken(address(this), address(singularityRouter), _bridgeRequestData.tokenAddress, _bridgeRequestData.amount);
                }else{
                   require(msg.value>= totalTakeoutAmount, "insufficient msg.value");
                   nativeAmount = _bridgeRequestData.amount;
                }
            } else {
                revert("Invalid Route");
            }

            ISingularityRouter.RouterRequestData memory routerRequestData = ISingularityRouter.RouterRequestData(
                address(this),
                _swapRequestData,
                _bridgeRequestData
            ); 

            singularityRouter.performSwapBridgeAction{value: nativeAmount}(routerRequestData, _s9yData.subTxId, _s9yData.txId);
    }

/*
****************************** NFT AND TOKEN INTERNAL HELPER FUNCTIONS ******************************************************
*/

    function _transferNft(address _from, address _to, string calldata _nftType, address _nftAddress, uint256 _nftId, uint256 _nftAmount, bytes memory _data) internal {

        if(keccak256(abi.encode(_nftType))== keccak256(abi.encode("ERC721"))){
            IERC721Upgradeable exchangeAsset = IERC721Upgradeable(_nftAddress);
            exchangeAsset.safeTransferFrom(_from, _to, _nftId);
        }else if(keccak256(abi.encode(_nftType))== keccak256(abi.encode("ERC1155"))) {
            IERC1155Upgradeable exchangeAsset = IERC1155Upgradeable(_nftAddress);
            exchangeAsset.safeTransferFrom(_from, _to, _nftId, _nftAmount, _data);
        } else {
            revert("Unsupported NFT Type");
        }
    }

    function _executeTokenApproval(address _owner, address _spender, address _tokenAddress, uint256 _tokenAmount, ApprovalData calldata _approvalData) internal {
        if(keccak256(abi.encode(_approvalData.approvalType))== keccak256(abi.encode("PERMIT"))) {
            IERC20PermitUpgradeable token = IERC20PermitUpgradeable(_tokenAddress);
            token.permit(_owner, _spender, _tokenAmount, _approvalData.deadline, _approvalData.v, _approvalData.r, _approvalData.s);
        }else if(keccak256(abi.encode(_approvalData.approvalType))== keccak256(abi.encode("PERMIT_DAI"))) {
            IDaiPermit token = IDaiPermit(_tokenAddress);
            token.permit(_owner, _spender, _approvalData.nonce, _approvalData.deadline, true, _approvalData.v, _approvalData.r, _approvalData.s); 
        }
    }

    function _giveTokenApproval(address _spender, address _tokenAddress, uint256 _tokenAmount) internal {
        IERC20Upgradeable token = IERC20Upgradeable(_tokenAddress);
        token.approve(_spender, _tokenAmount); // Approving Spender to use tokens from contract
    }

    function _transferToken(address _from, address _to, address _tokenAddress, uint256 _tokenAmount) internal {
        if(_from == address(this)){
            IERC20Upgradeable transferAsset = IERC20Upgradeable(_tokenAddress);
            transferAsset.transfer(_to, _tokenAmount);
        }else {
            IERC20Upgradeable transferAsset = IERC20Upgradeable(_tokenAddress);
            transferAsset.transferFrom(_from, _to, _tokenAmount);
        }
    }

    function _incrementUserTxNonce(address _userAddress) internal {
        userTxNonce[_userAddress]++;
    }


/*
*************************************************************** Asset Issue Functions - CFlow ********************************************************************************
*/

    function issueNft(address _receiver, ExchangeRequestData calldata _nftData, S9YData calldata _s9yData) public whenNotPaused onlyAdmin nonReentrant {
        _transferNft(_nftData.approver, _receiver, _nftData.nftType, _nftData.assetAddress, _nftData.assetId, _nftData.exchangeAmount, "");
        emit NftIssued(_nftData.approver, _receiver, _nftData.exchangeAmount, _nftData.assetAddress, _nftData.assetId,  _nftData.nftType, "COLLECT_PAYMENT_ISSUE_NFT", _s9yData.subTxId, _s9yData.txId);
    }

    function issueToken(address _receiver, ExchangeRequestData calldata _tokenData, S9YData calldata _s9yData) public whenNotPaused onlyAdmin nonReentrant {
        _transferToken(_tokenData.approver, _receiver, _tokenData.assetAddress, _tokenData.exchangeAmount);
        emit TokenIssued(_tokenData.approver, _receiver, _tokenData.exchangeAmount, _tokenData.assetAddress, "COLLECT_PAYMENT_ISSUE_TOKEN", _s9yData.subTxId, _s9yData.txId);
    }


/*
********************************************************************* NFT Marketplace Functions ******************************************************************************** 
*/    


// ToDo: Implement



/*
***************************************** Important Functions - Edit With Care ***********************************************************
*/   
    function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771Recipient) returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override(ContextUpgradeable, ERC2771Recipient) returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
    
   receive() external payable {}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "../interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

import "../helpers/ERC2771Recipient.sol";
import "../helpers/errors.sol";

import "../interfaces/ISwapRouterBase.sol";
import "../interfaces/IBridgeRouterBase.sol";


interface ISingularityRouter  {

    enum RouteType {NONE, SWAP, BRIDGE}

    struct RouteData {
        address routeAddress;
        bool isValid;
        RouteType routeType;
    }

    struct SwapRequestData {
        uint256 routeId;
        address receiver;
        address fromTokenAddress;
        address toTokenAddress;
        uint256 inAmount;
        uint256 outAmount;
        bytes data;
    }

    struct BridgeRequestData {
        uint256 routeId;
        address receiver;
        uint256 destChainId;
        address tokenAddress;
        uint256 amount;
        bytes data;
    }

    struct RouterRequestData {
        address sender;
        SwapRequestData swapRequestData;
        BridgeRequestData bridgeRequestData;
    }


    function getNativeWrappedCurrencyAddress() external view returns (address) ;

    function getRoute(uint256 _routeId) external view returns (address, bool, RouteType) ;

    function getRouteAddress(uint256 _routeId) external view returns (address) ;

    function getRouteValidity(uint256 _routeId) external view returns (bool) ;
    
    function getRouteType(uint256 _routeId) external view returns (RouteType) ;

/*
************************************************************ Swap Bridge Route Functions ***************************************************
*/

    function performSwapBridgeAction(RouterRequestData memory _routerRequestData, uint256 _subTxId, string memory _txId) external payable ;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library SingularityErrors {
    string internal constant INVALID_ROUTE_TYPE = "Invalid Route Type";
    string internal constant ROUTE_ALREADY_EXISTS = "Route Already Exists";
    string internal constant ROUTE_DOES_NOT_EXIST = "Route Does Not Exist";
    string internal constant ADDRESS_0_PROVIDED = "Address 0 Provided";
    string internal constant INVALID_FEE = "Invalid Fee";
    string internal constant  INVALID_AMOUNT_IN = "Invalid  In Amount";
    string internal constant INVALID_AMOUNT_OUT = "Invalid Out Amount";




}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

import "../helpers/ERC2771Recipient.sol";


abstract contract ISwapRouterBase is Initializable, OwnableUpgradeable, ERC2771Recipient, PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable{

    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address public singularityRouterAddress;
    address public nativeWrappedCurrencyAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function ISwapRouterBase_init(address _singularityRouterAddress, address _nativeWrappedCurrencyAddress, address[] calldata _adminAddresses) internal onlyInitializing {
        __Pausable_init();
        __Ownable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        ISwapRouterBase_init_unchained(_singularityRouterAddress, _nativeWrappedCurrencyAddress, _adminAddresses);
    }


    function ISwapRouterBase_init_unchained(address _singularityRouterAddress, address _nativeWrappedCurrencyAddress, address[] calldata _adminAddresses) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, SUPER_ADMIN_ROLE);

        singularityRouterAddress = _singularityRouterAddress;
        nativeWrappedCurrencyAddress = _nativeWrappedCurrencyAddress;

        // Granting Access to all Programatic Admin Addresses
        for(uint256 i = 0; i < _adminAddresses.length; i++) {
            _grantRole(ADMIN_ROLE, _adminAddresses[i]);
        }
    }

/*
******************************************Contract Settings Functions****************************************************
*/

    /**
    * @dev overriding the inherited {transferOwnership} function to reflect the admin changes into the {DEFAULT_ADMIN_ROLE}
    */
    
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    

    /**
    * @dev modifier to check super admin rights.
    * contract owner and super admin have super admin rights
    */

    modifier onlySuperAdmin() {
        require(
            hasRole(SUPER_ADMIN_ROLE, _msgSender()) ||
            owner() == _msgSender(),
            "Unauthorized Access");
        _;
    }

    /**
    * @dev modifier to check admin rights.
    * contract owner, super admin and admins have admin rights
    */
    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()) ||
            hasRole(SUPER_ADMIN_ROLE, _msgSender()) ||
            owner() == _msgSender(),
            "Unauthorized Access");
        _;
    }

    /**
    * @dev modifier to check pause rights.
    * contract owner, super admin and pausers's have pause rights
    */
    modifier onlyPauser() {
        require(
            hasRole(PAUSER_ROLE, _msgSender()) ||
            hasRole(SUPER_ADMIN_ROLE, _msgSender()) || 
            owner() == _msgSender(),
            "Unauthorized Access");
        _;
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function addSuperAdmin(address _superAdmin) public onlyOwner {
        _grantRole(SUPER_ADMIN_ROLE, _superAdmin);
    }

    function addAdmin(address _admin) public onlySuperAdmin {
        _grantRole(ADMIN_ROLE, _admin);
    }

    function addPauser(address account) public onlySuperAdmin {
        _grantRole(PAUSER_ROLE, account);
    }

    function removeSuperAdmin(address _superAdmin) public onlyOwner {
        _revokeRole(SUPER_ADMIN_ROLE, _superAdmin);
    }

    function removeAdmin(address _admin) public onlySuperAdmin {
        _revokeRole(ADMIN_ROLE, _admin);
    }

    function removePauser(address _pauser) public onlySuperAdmin {
        _revokeRole(PAUSER_ROLE, _pauser);
    }        

/*
************************************************************Contract Modifiers***************************************************
*/




/*
************************************************************ Swap Action ***************************************************
*/

    function performSwapAction(address _sender, address _receiver, address _fromTokenAddress, address _toTokenAddress, uint256 _inAmount, uint256 _outAmount, bytes memory _data ) external virtual payable returns (uint256) ;


/*
************************************************************ Rescue Action ***************************************************
*/

        function rescueFunds(
                address token,
                address userAddress,
                uint256 amount
        ) external onlyOwner {
                IERC20Upgradeable(token).transfer(userAddress, amount);
        }

        function rescueEther(address payable userAddress, uint256 amount)
            external
            onlyOwner
        {
            userAddress.transfer(amount);
        }
/*
****************************************** Interface Initilization Functions ****************************************************
*/    

    function setTrustedForwarder(address _newtrustedForwarder) public onlySuperAdmin {
        _setTrustedForwarder(_newtrustedForwarder);
    }

    function setSingularityRouterAddress(address _singularityRouterAddress) public onlySuperAdmin {
        singularityRouterAddress = _singularityRouterAddress;
    }

    function setNativeWrappedCurrencyAddress(address _nativeWrappedCurrencyAddress) public onlySuperAdmin {
        nativeWrappedCurrencyAddress = _nativeWrappedCurrencyAddress;
    }


/*
***************************************** Important Functions - Edit With Care ***********************************************************
*/   
    function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771Recipient) returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override(ContextUpgradeable, ERC2771Recipient) returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
    
   receive() external payable {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";


import "../helpers/ERC2771Recipient.sol";



abstract contract IBridgeRouterBase is Initializable, OwnableUpgradeable, ERC2771Recipient, PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable{

    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address public singularityRouterAddress;
    address public nativeWrappedCurrencyAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function IBridgeRouterBase_init(address _singularityRouterAddress, address _nativeWrappedCurrencyAddress, address[] calldata _adminAddresses) internal onlyInitializing {
        __Pausable_init();
        __Ownable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        IBridgeRouterBase_init_unchained(_singularityRouterAddress, _nativeWrappedCurrencyAddress, _adminAddresses);
    }


    function IBridgeRouterBase_init_unchained(address _singularityRouterAddress, address _nativeWrappedCurrencyAddress, address[] calldata _adminAddresses) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, SUPER_ADMIN_ROLE);

        singularityRouterAddress = _singularityRouterAddress;
        nativeWrappedCurrencyAddress = _nativeWrappedCurrencyAddress;

        // Granting Access to all Programatic Admin Addresses
        for(uint256 i = 0; i < _adminAddresses.length; i++) {
            _grantRole(ADMIN_ROLE, _adminAddresses[i]);
        }
    }

/*
******************************************Contract Settings Functions****************************************************
*/

    /**
    * @dev overriding the inherited {transferOwnership} function to reflect the admin changes into the {DEFAULT_ADMIN_ROLE}
    */
    
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    

    /**
    * @dev modifier to check super admin rights.
    * contract owner and super admin have super admin rights
    */

    modifier onlySuperAdmin() {
        require(
            hasRole(SUPER_ADMIN_ROLE, _msgSender()) ||
            owner() == _msgSender(),
            "Unauthorized Access");
        _;
    }

    /**
    * @dev modifier to check admin rights.
    * contract owner, super admin and admins have admin rights
    */
    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()) ||
            hasRole(SUPER_ADMIN_ROLE, _msgSender()) ||
            owner() == _msgSender(),
            "Unauthorized Access");
        _;
    }

    /**
    * @dev modifier to check pause rights.
    * contract owner, super admin and pausers's have pause rights
    */
    modifier onlyPauser() {
        require(
            hasRole(PAUSER_ROLE, _msgSender()) ||
            hasRole(SUPER_ADMIN_ROLE, _msgSender()) || 
            owner() == _msgSender(),
            "Unauthorized Access");
        _;
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function addSuperAdmin(address _superAdmin) public onlyOwner {
        _grantRole(SUPER_ADMIN_ROLE, _superAdmin);
    }

    function addAdmin(address _admin) public onlySuperAdmin {
        _grantRole(ADMIN_ROLE, _admin);
    }

    function addPauser(address account) public onlySuperAdmin {
        _grantRole(PAUSER_ROLE, account);
    }

    function removeSuperAdmin(address _superAdmin) public onlyOwner {
        _revokeRole(SUPER_ADMIN_ROLE, _superAdmin);
    }

    function removeAdmin(address _admin) public onlySuperAdmin {
        _revokeRole(ADMIN_ROLE, _admin);
    }

    function removePauser(address _pauser) public onlySuperAdmin {
        _revokeRole(PAUSER_ROLE, _pauser);
    }        

/*
************************************************************Contract Modifiers***************************************************
*/




/*
************************************************************ Bridge Action ***************************************************
*/

    function performBridgeAction(
        address _sender,
        address _receiver,
        address _tokenAddress,
        uint256 _destChainId,
        uint256 _amount,
        bytes memory _data
    ) external payable virtual;


/*
************************************************************ Rescue Action ***************************************************
*/

    function rescueFunds(
            address token,
            address userAddress,
            uint256 amount
    ) external onlyOwner {
            IERC20Upgradeable(token).transfer(userAddress, amount);
    }

    function rescueEther(address payable userAddress, uint256 amount)
        external
        onlyOwner
    {
        userAddress.transfer(amount);
    }
/*
****************************************** Interface Initilization Functions ****************************************************
*/    

    function setTrustedForwarder(address _newtrustedForwarder) public onlySuperAdmin {
        _setTrustedForwarder(_newtrustedForwarder);
    }

    function setSingularityRouterAddress(address _singularityRouterAddress) public onlySuperAdmin {
        singularityRouterAddress = _singularityRouterAddress;
    }

    function setNativeWrappedCurrencyAddress(address _nativeWrappedCurrencyAddress) public onlySuperAdmin {
        nativeWrappedCurrencyAddress = _nativeWrappedCurrencyAddress;
    }


/*
***************************************** Important Functions - Edit With Care ***********************************************************
*/   
    function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771Recipient) returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override(ContextUpgradeable, ERC2771Recipient) returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
    
   receive() external payable {}

}