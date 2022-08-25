// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./interfaces/IInfinityPool.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IInfinityToken.sol";
import "./interfaces/ILiquidationProtocol.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/ERC721Validator.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

contract InfinityPool is IERC721Receiver, IInfinityPool, Initializable, ContextUpgradeable, OwnableUpgradeable {

	mapping(uint64=>address) liquidationProtocolAddresses; // mapping of addresses of liquidation protocols
	mapping(uint64=>int64) productVariables;
	mapping(uint=>uint64) priceIndexes; // 13 decimals
	IInfinityToken public poolToken;
	IWETH public weth;
	// ether tokenId = 0

	function version() public pure returns(uint v){
		v = 8;
	}

	function initialize(address _addrPoolToken, address _addrWETH) public initializer{
		_setInfinityToken(_addrPoolToken);
		_setWETH(_addrWETH);
		__Ownable_init();
	}
	function setInfinityToken(address _addrPoolToken) public onlyOwner {
		// require(_addrPoolToken != address(0), "poolToken 0");
		_setInfinityToken(_addrPoolToken);
	}
	function _setInfinityToken(address _addrPoolToken) internal {
		poolToken = IInfinityToken(_addrPoolToken);
	}
	function setWETH(address _addrWETH) public onlyOwner {
		// require(_addrWETH != address(0), "addrWETH 0");
		_setWETH(_addrWETH);
	}
	function _setWETH(address _addrWETH) internal {
		weth = IWETH(_addrWETH);
	}

	function deposit(
		TokenTransfer[] memory tokenTransfers,
		Action[] calldata actions
	) external payable override {
		uint tokenLengthLimit = 1e2; 		// hardcoded token amount limit
		uint actionLengthLimit = 1e2; 	// hardcoded action limit
		require(msg.value>0||tokenTransfers.length>0||actions.length>0,"0-len args");
		require(tokenTransfers.length<tokenLengthLimit,"Token limit");
		require(actions.length<actionLengthLimit,"Action limit");

		TokenTransfer[] memory _tt = new TokenTransfer[](tokenTransfers.length+(msg.value>0?1:0));
	// take tokens
		for(uint i=0;i<tokenTransfers.length;i++){
			uint256 tokenAmount = tokenTransfers[i].amount;
			// TODO check if ether would overflow in iToken
			uint balance = TransferHelper.balanceOf(tokenTransfers[i].token,address(_msgSender()));
			if(ERC721Validator.isERC721(tokenTransfers[i].token)){
				require(ERC721Validator.isERC721Owner(tokenTransfers[i].token,address(_msgSender()),tokenAmount),"Not ERC721 Owner");
				TransferHelper.safeTransferFromERC721(tokenTransfers[i].token,_msgSender(),address(this),tokenAmount);
			}else{
				require(balance>=tokenAmount,"Insufficient balance");
				TransferHelper.safeTransferFrom(tokenTransfers[i].token,_msgSender(),address(this),tokenAmount);
			}
			_tt[i] = tokenTransfers[i];
		}
		// wrap eth
		if(msg.value>0){
			weth.deposit{value:msg.value}();
			// new array 
			_tt[tokenTransfers.length] = TokenTransfer(address(weth),msg.value);
		}
		emit DepositsOrActionsTriggered(
			_msgSender(), _tt, actions
		);
	}

	function requestWithdraw(TokenTransfer[] calldata tokenTransfers) external override{
		require(tokenTransfers.length>0,"0-len args");
		/* only do checkings */
		uint256[] memory _tokenIds = new uint256[](tokenTransfers.length);
		uint256[] memory _tokenAmounts = new uint256[](tokenTransfers.length);
		for(uint i=0;i<tokenTransfers.length;i++){
			_tokenIds[i] = uint256(uint160(tokenTransfers[i].token));
			uint256 tokenAmount = _tokenAmounts[i] = tokenTransfers[i].amount;
			if(ERC721Validator.isERC721(tokenTransfers[i].token)){
				require(poolToken.ifUserTokenExistsERC721(_msgSender(), _tokenIds[i], tokenAmount),"Not ERC721 Owner");
			}else{
				require(poolToken.balanceOf(_msgSender(),uint256(uint160(tokenTransfers[i].token)))>=tokenAmount,"Insufficient Token");
				require(TransferHelper.balanceOf(tokenTransfers[i].token,address(this))>=tokenAmount,"Insufficient pool Token");
			}
		}
		emit WithdrawalRequested(
			_msgSender(), tokenTransfers
		);	
	}

	function action(Action[] calldata actions) external override{
		uint actionLengthLimit = 1e2; 	// hardcoded action limit
		require(actions.length>0,"0-len args");
		require(actions.length<actionLengthLimit,"Action limit");
		emit DepositsOrActionsTriggered(
			_msgSender(), (new TokenTransfer[](0)), actions
		);	
	}

	function balanceOf(address clientAddress, uint tokenId) external view override returns (uint balance){
		balance = poolToken.balanceOf(clientAddress,tokenId);
	}

	function priceIndex(uint256 tokenId) external view returns (uint64 value){
		value = priceIndexes[tokenId];
	}
	function productVariable(uint64 id) external view returns (int64 value){
		value = productVariables[id];
	}

	function serverTransferFunds(address clientAddress, TokenTransfer[] calldata tokenTransfers) onlyOwner external override{
		require(tokenTransfers.length>0,"0-len args");
		/* do checkings again */
		uint256[] memory _tokenIds = new uint256[](tokenTransfers.length);
		uint256[] memory _tokenAmounts = new uint256[](tokenTransfers.length);
		for(uint i=0;i<tokenTransfers.length;i++){
			_tokenIds[i] = uint256(uint160(tokenTransfers[i].token));
			uint256 tokenAmount = _tokenAmounts[i] = tokenTransfers[i].amount;
			if(ERC721Validator.isERC721(tokenTransfers[i].token)){
				require(poolToken.ifUserTokenExistsERC721(clientAddress, _tokenIds[i], tokenAmount),"Not ERC721 Owner");
				TransferHelper.safeApprove(tokenTransfers[i].token,clientAddress,tokenAmount);
				TransferHelper.safeTransferFromERC721(tokenTransfers[i].token,address(this),clientAddress,tokenAmount);
			}else{
				require(poolToken.balanceOf(clientAddress,uint256(uint160(tokenTransfers[i].token)))>=tokenAmount,"Insufficient Token");
				require(TransferHelper.balanceOf(tokenTransfers[i].token,address(this))>=tokenAmount,"Insufficient pool Token");
				TransferHelper.safeApprove(tokenTransfers[i].token,clientAddress,tokenAmount);
				TransferHelper.safeTransfer(tokenTransfers[i].token,clientAddress,tokenAmount);
			}
		}
		poolToken.withdraw(clientAddress,_tokenIds,_tokenAmounts); // update balance
	}
	function serverUpdateBalances(
		address[] calldata clientAddresses, TokenUpdate[][] calldata tokenUpdates,
		PriceIndex[] calldata _priceIndexes
	) onlyOwner external override {
		require(clientAddresses.length>0||tokenUpdates.length>0||_priceIndexes.length>0,"0-len args");
		require(clientAddresses.length==tokenUpdates.length,"args-len Mismatch");
		// TODO require: make sure pool size doesnt change overalld
		for(uint i=0;i<clientAddresses.length;i++){
			poolToken.updateBalance(clientAddresses[i],tokenUpdates[i]);
		}
		if(_priceIndexes.length>0){
			for(uint i=0;i<_priceIndexes.length;i++){
				priceIndexes[_priceIndexes[i].key] = _priceIndexes[i].value;
			}
			emit PriceIndexesUpdated(_priceIndexes);
		}
	}
	function serverUpdateProductVariables(
		ProductVariable[] calldata _productVariables
	) onlyOwner external override {
		require(_productVariables.length>0,"varible length == 0");
		for(uint i=0;i<_productVariables.length;i++){
			productVariables[_productVariables[i].key] = _productVariables[i].value;
		}
		emit ProductVariablesUpdated(_productVariables);
	}

	function registerLiquidationProtocol(
		uint64 protocolId, address protocolAddress
	) onlyOwner external override {
		require(protocolAddress!=address(0x0),"protocol cannot be 0");
		// require(liquidationProtocolAddresses[protocolId]==address(0x0),"protocol ID dupl."); 
		liquidationProtocolAddresses[protocolId] = protocolAddress;
		emit LiquidationProtocolRegistered(protocolAddress);
	}

	function serverLiquidate(
		uint64 protocolId, ILiquidationProtocol.LiquidateParams memory lparams
	) onlyOwner external override {
		address protocolAddress = liquidationProtocolAddresses[protocolId];
		require(protocolAddress!=address(0x0),"protocol incorrect");
		ILiquidationProtocol protocol = ILiquidationProtocol(protocolAddress);
		lparams.amountIn = protocol.getApproveAmount(lparams);
		// for aave: atoken calculation might be ahead of actual balance - amountIn should always be smaller than balance
		// uint256 balance = IERC20(lparams.tokenFrom).balanceOf(address(this));
		// if(lparams.amountIn>balance) lparams.amountIn = balance;
        TransferHelper.safeApprove(lparams.tokenFrom, address(protocolAddress), lparams.amountIn);
        // TransferHelper.safeTransfer(lparams.tokenFrom, address(protocolAddress), lparams.amountIn);
        // console.log("lparams.amountIn");
        // console.log(lparams.amountIn);
		ILiquidationProtocol.LiquidatedAmount[] memory amounts = protocol.swap(lparams);
		// TODO update client wallet?
		emit ServerLiquidateSuccess(lparams.clientAddress,lparams.tokenFrom,lparams.amountIn,amounts);
	}

	// Implementing `onERC721Received` so this contract can receive custody of erc721 tokens
	function onERC721Received( address , address , uint256 , bytes calldata ) external pure override returns (bytes4) {
    return this.onERC721Received.selector;
	}

	function serverLiquidateERC721(
		uint64 protocolId, ILiquidationProtocol.LiquidateParams memory lparams
	) onlyOwner external override {
		address protocolAddress = liquidationProtocolAddresses[protocolId];
		require(protocolAddress!=address(0x0),"protocol incorrect");
		ILiquidationProtocol protocol = ILiquidationProtocol(protocolAddress);
		lparams.amountIn = protocol.getApproveAmount(lparams);
    TransferHelper.safeApprove(lparams.tokenFrom, address(protocolAddress), lparams.amountIn);
		ILiquidationProtocol.LiquidatedAmount[] memory amounts = protocol.swap(lparams);
		// TODO update client wallet?
		emit ServerLiquidateSuccess(lparams.clientAddress,lparams.tokenFrom,lparams.amountIn,amounts);
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../interfaces/ILiquidationProtocol.sol";

interface IInfinityPool {

	/*

	action types
	public static final int SOURCE_WEB = 1;
	public static final int SOURCE_ETHERERUM = 2;
	
	public static final int TYPE_DEPOSIT = 1;
	public static final int TYPE_WITHDRAWL = 2;
	public static final int TYPE_WITHDRAWL_FAST = 3;
	public static final int TYPE_TRANSFER = 4;
	
	public static final int TYPE_BORROW = 10;
	public static final int TYPE_PAYBACK = 11;
	
	public static final int TYPE_CREATE_EXCHANGE_LIQUIDITY_POSITION = 20;
	public static final int TYPE_UPDATE_EXCHANGE_LIQUIDITY_POSITION = 21;
	public static final int TYPE_REMOVE_EXCHANGE_LIQUIDITY_POSITION = 22;
	public static final int TYPE_EXCHANGE = 23;
	public static final int TYPE_EXCHANGE_LARGE_ORDER = 24;

	*/

	struct TokenTransfer {
		address token;
		uint256 amount;
	}
	struct TokenUpdate {
		uint256 tokenId; // might be prepended with wallet type (e.g. interest bearing wallets)
		uint256 amount; // absolute value - should always be unsigned
		uint64 priceIndex;
	}

	struct Action {
		uint256 action;
		uint256[] parameters;
	}

	struct ProductVariable {
		uint64 key;
		int64 value;
	}

	struct PriceIndex {
		uint256 key;
		uint64 value;
	}


	event DepositsOrActionsTriggered(
		address indexed sender,
		TokenTransfer[] transfers, 
		Action[] actions
	);
	event WithdrawalRequested(
		address indexed sender,
		TokenTransfer[] transfers
	);

	event ProductVariablesUpdated(
		ProductVariable[] variables
	);
	event PriceIndexesUpdated(
		PriceIndex[] priceIndexes
	);

	event LiquidationProtocolRegistered(
		address indexed protocolAddress
	);

	event ServerLiquidateSuccess(
		address indexed clientAddress,
		address tokenFrom,
		uint256 amountIn,
		ILiquidationProtocol.LiquidatedAmount[] amounts
	);
	
	function version() external pure returns(uint v);

	function deposit(
		TokenTransfer[] memory tokenTranfers,
		Action[] calldata actions
	) external payable;

	function requestWithdraw(TokenTransfer[] calldata tokenTranfers) external;

	function action(Action[] calldata actions) external;

	function balanceOf(address clientAddress, uint tokenId) external view returns (uint);

	function productVariable(uint64 id) external view returns (int64);

	function priceIndex(uint256 tokenId) external view returns (uint64);

	function serverTransferFunds(address clientAddress, TokenTransfer[] calldata tokenTranfers) external;

	function serverUpdateBalances(
		address[] calldata clientAddresses, TokenUpdate[][] calldata tokenUpdates, 
		PriceIndex[] calldata priceIndexes
	) external;

	function serverUpdateProductVariables(
		ProductVariable[] calldata productVariables
	) external;

	function registerLiquidationProtocol(
		uint64 protocolId, address protocolAddress
	) external;

	function serverLiquidate(
		uint64 protocolId, ILiquidationProtocol.LiquidateParams memory lparams
	) external;

	function serverLiquidateERC721(
		uint64 protocolId, ILiquidationProtocol.LiquidateParams memory lparams
	) external;

	// function serverTransferERC721(address client, address token, uint256 tokenId) external;

	// function bridgeTransfer();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IInfinityPool.sol";

interface IInfinityToken is IERC1155 {

    function setPool(address _poolAddr) external;

    function priceIndexOf(address clientAddress, uint256 tokenId) external returns(uint64);

    function deposit(
    	address clientAddress, 
    	uint[] memory _coinIds, 
    	uint[] memory _amounts
    ) external;

    function withdraw(
    	address clientAddress, 
    	uint[] memory _coinIds, 
    	uint[] memory _amounts
	) external;

    function transfer(
        address from,
        address to,
    	uint[] memory _coinIds, 
        uint[] memory _amounts
    ) external;

    function moveProducts(
        address clientAddress,
    	uint[] memory _mintIds, 
        uint[] memory _mintAmounts,
    	uint[] memory _burnIds, 
        uint[] memory _burnAmounts
    ) external ;

    function updateBalance(
		address clientAddress, IInfinityPool.TokenUpdate[] calldata tokenUpdates
    ) external;

    function ifUserTokenExistsERC721(
        address account,
    	uint tokenAddress, 
    	uint tokenId
    ) external returns(bool exists);
    // function depositERC721(
    // 	address account, 
    // 	uint tokenAddress, 
    // 	uint tokenId
    // ) external;
    // function withdrawERC721(
    // 	address account, 
    // 	uint tokenAddress, 
    // 	uint tokenId
	// ) external;
    // function transferERC721(
    //     address from,
    //     address to,
    // 	uint tokenAddress, 
    //     uint tokenId
    // ) external;

	
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface ILiquidationProtocol {

	struct LiquidateParams {
		address clientAddress;
		address tokenFrom;
		address tokenTo;
		uint256 amountIn; // for ERC721: amountIn is tokenId
		uint24 poolFee;
	}

	struct LiquidatedAmount {
		address token;
		uint256 amount;
	}
	
	function swap(
		LiquidateParams memory lparams
	) external returns (LiquidatedAmount[] memory amounts);
	
	function getApproveAmount(
		LiquidateParams memory lparams
	) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library TransferHelper {
    function safeApprove( address token, address to, uint256 value ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), 'approve failed' );
    }

    function safeTransferFrom( address token, address from, address to, uint256 value ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), 'transferFrom failed' );
    }

    function safeTransfer( address token, address to, uint256 value ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), 'transfer failed' );
    }

    function safeTransferFromERC721( address token, address from, address to, uint256 tokenId ) internal {
        // bytes4(keccak256(bytes('safeTransferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x42842e0e, from, to, tokenId));
        require( success && (data.length == 0 || abi.decode(data, (bool))), 'erc721 safeTransferFrom failed' );
    }

    function balanceOf( address token, address account ) internal returns (uint256 balance){
        // bytes4(keccak256(bytes('balanceOf(address)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x70a08231, account));
        require(success,'balanceOf failed');
        balance = abi.decode(data, (uint256));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.12;

// import "hardhat/console.sol";

library ERC721Validator {

    function isERC721(address token) internal returns(bool b){
        // bytes4(keccak256(bytes("supportsInterface(bytes4)")))
        (bool success,bytes memory data) = token.call(abi.encodeWithSelector(0x01ffc9a7,bytes4(0x80ac58cd))); // ERC721ID
        if(success && data.length > 0 && abi.decode(data, (bool))){
            (success,data) = token.call(abi.encodeWithSelector(0x01ffc9a7,bytes4(0x5b5e139f))); // ERC721MetadataID
            /**
             * DEV no need to check ERC721Enumerable since it's OPTIONAL (only for token to be able to publish its full list of NFTs - see:
             * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md#specification
             */
            // if(success && data.length > 0 && abi.decode(data, (bool))){
                // (success,data) = token.call(abi.encodeWithSelector(0x01ffc9a7,bytes4(0x780e9d63))); // ERC721EnumerableID
                b = success && data.length > 0 && abi.decode(data, (bool));
                // if(b) console.log("isERC721 ERC721EnumerableID");
            // }
        }
        // console.log(token); console.log(b);
    }

    function isERC721Owner(address token, address account, uint256 tokenId) internal returns(bool result){
        // bytes4(keccak256(bytes('ownerOf(uint256)')));
        (, bytes memory data) = token.call(abi.encodeWithSelector(0x6352211e, tokenId));
        address owner = abi.decode(data, (address));
        result = owner==account;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


/**
 * @dev contract of the ERC20 standard as defined in the EIP with extended functions.
 */
abstract contract IERC20Extended is IERC20 {
    function decimals() public virtual view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
interface IERC165 {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}