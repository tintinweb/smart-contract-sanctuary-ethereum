//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { TokenInterface } from "./interfaces.sol";
import { Stores } from "./stores.sol";

abstract contract Basic is Stores {

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = _amt * (10 ** (18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == ethAddr ? address(this).balance : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == ethAddr ?  18 : buyAddr.decimals();
        sellDec = address(sellAddr) == ethAddr ?  18 : sellAddr.decimals();
    }

    function encodeEvent(string memory eventName, bytes memory eventParam) internal pure returns (bytes memory) {
        return abi.encode(eventName, eventParam);
    }

    function approve(TokenInterface token, address spender, uint256 amount) internal {
        try token.approve(spender, amount) {

        } catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == ethAddr ? TokenInterface(wethAddr) : TokenInterface(buy);
        _sell = sell == ethAddr ? TokenInterface(wethAddr) : TokenInterface(sell);
    }

    function changeEthAddrToWethAddr(address token) internal pure returns(address tokenAddr){
        tokenAddr = token == ethAddr ? wethAddr : token;
    }

    function convertEthToWeth(bool isEth, TokenInterface token, uint amount) internal {
        if(isEth) token.deposit{value: amount}();
    }

    function convertWethToEth(bool isEth, TokenInterface token, uint amount) internal {
       if(isEth) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { MemoryInterface, InstaMapping } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F);

  /**
   * @dev Return InstaDApp Mapping Addresses
   */
  InstaMapping constant internal instaMapping = InstaMapping(0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88);

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Events {
	event LogCompoundImport(
		address indexed user,
		address[] ctokens,
		string[] supplyIds,
		string[] borrowIds,
		uint256[] supplyAmts,
		uint256[] borrowAmts
	);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Basic } from "../common/basic.sol";
import { TokenInterface } from "../common/interfaces.sol";
import { ComptrollerInterface, CompoundMappingInterface, CETHInterface, CTokenInterface } from "./interface.sol";

abstract contract Helpers is Basic {
	/**
	 * @dev Compound CEth
	 */
	CETHInterface internal constant cEth =
		CETHInterface(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

	/**
	 * @dev Compound Comptroller
	 */
	ComptrollerInterface internal constant troller =
		ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

	/**
	 * @dev Compound Mapping
	 */
	CompoundMappingInterface internal constant compMapping =
		CompoundMappingInterface(0xe7a85d0adDB972A4f0A4e57B698B37f171519e88);

	struct ImportData {
		address[] cTokens; // is the list of all tokens the user has interacted with (supply/borrow) -> used to enter markets
		uint256[] borrowAmts;
		uint256[] supplyAmts;
		address[] borrowTokens;
		address[] supplyTokens;
		CTokenInterface[] borrowCtokens;
		CTokenInterface[] supplyCtokens;
		address[] supplyCtokensAddr;
		address[] borrowCtokensAddr;
	}

	struct ImportInputData {
		address userAccount;
		string[] supplyIds;
		string[] borrowIds;
	}

	/**
	 * @dev enter compound market
	 * @param _cotkens array of ctoken addresses to enter compound market
	 */
	function _enterMarkets(address[] memory _cotkens) internal {
		troller.enterMarkets(_cotkens);
	}
}

contract CompoundHelper is Helpers {
	/**
	 * @notice fetch the borrow details of the user
	 * @dev approve the cToken to spend (borrowed amount of) tokens to allow for repaying later
	 * @param _importInputData the struct containing borrowIds of the users borrowed tokens
	 * @param data struct used to store the final data on which the CompoundHelper contract functions operate
	 * @return ImportData the final value of param data
	 */
	function getBorrowAmounts(
		ImportInputData memory _importInputData,
		ImportData memory data
	) internal returns (ImportData memory) {
		if (_importInputData.borrowIds.length > 0) {
			// initialize arrays for borrow data
			uint256 _length = _importInputData.borrowIds.length;
			data.borrowTokens = new address[](_length);
			data.borrowCtokens = new CTokenInterface[](_length);
			data.borrowCtokensAddr = new address[](_length);
			data.borrowAmts = new uint256[](_length);

			// populate the arrays with borrow tokens, cToken addresses and instances, and borrow amounts
			for (uint256 i; i < _length; i++) {
				(address _token, address _cToken) = compMapping.getMapping(
					_importInputData.borrowIds[i]
				);

				require(
					_token != address(0) && _cToken != address(0),
					"ctoken mapping not found"
				);

				data.cTokens[i] = _cToken;

				data.borrowTokens[i] = _token;
				data.borrowCtokens[i] = CTokenInterface(_cToken);
				data.borrowCtokensAddr[i] = _cToken;
				data.borrowAmts[i] = data.borrowCtokens[i].borrowBalanceCurrent(
					_importInputData.userAccount
				);

				// give the resp. cToken address approval to spend tokens
				if (_token != ethAddr && data.borrowAmts[i] > 0) {
					// will be required when repaying the borrow amount on behalf of the user
					TokenInterface(_token).approve(_cToken, data.borrowAmts[i]);
				}
			}
		}
		return data;
	}

	/**
	 * @notice fetch the supply details of the user
	 * @dev only reads data from blockchain hence view
	 * @param _importInputData the struct containing supplyIds of the users supplied tokens
	 * @param data struct used to store the final data on which the CompoundHelper contract functions operate
	 * @return ImportData the final value of param data
	 */
	function getSupplyAmounts(
		ImportInputData memory _importInputData,
		ImportData memory data
	) internal view returns (ImportData memory) {
		// initialize arrays for supply data
		uint256 _length = _importInputData.supplyIds.length;
		data.supplyTokens = new address[](_length);
		data.supplyCtokens = new CTokenInterface[](_length);
		data.supplyCtokensAddr = new address[](_length);
		data.supplyAmts = new uint256[](_length);

		// populate arrays with supply data (supply tokens address, cToken addresses, cToken instances and supply amounts)
		for (uint256 i; i < _length; i++) {
			(address _token, address _cToken) = compMapping.getMapping(
				_importInputData.supplyIds[i]
			);

			require(
				_token != address(0) && _cToken != address(0),
				"ctoken mapping not found"
			);

			uint256 _supplyIndex = (i + _importInputData.borrowIds.length);
			data.cTokens[_supplyIndex] = _cToken;

			data.supplyTokens[i] = _token;
			data.supplyCtokens[i] = CTokenInterface(_cToken);
			data.supplyCtokensAddr[i] = (_cToken);
			data.supplyAmts[i] = data.supplyCtokens[i].balanceOf(
				_importInputData.userAccount
			);
		}
		return data;
	}

	/**
	 * @notice repays the debt taken by user on Compound on its behalf to free its collateral for transfer
	 * @dev uses the cEth contract for ETH repays, otherwise the general cToken interface
	 * @param _userAccount the user address for which debt is to be repayed
	 * @param _cTokenContracts array containing all interfaces to the cToken contracts in which the user has debt positions
	 * @param _borrowAmts array containing the amount borrowed for each token
	 */
	function _repayUserDebt(
		address _userAccount,
		CTokenInterface[] memory _cTokenContracts,
		uint256[] memory _borrowAmts
	) internal {
		for (uint256 i; i < _cTokenContracts.length; i++) {
			if (_borrowAmts[i] > 0) {
				if (address(_cTokenContracts[i]) == address(cEth))
					cEth.repayBorrowBehalf{ value: _borrowAmts[i] }(
						_userAccount
					);
				else
					require(
						_cTokenContracts[i].repayBorrowBehalf(
							_userAccount,
							_borrowAmts[i]
						) == 0,
						"repayOnBehalf-failed"
					);
			}
		}
	}

	/**
	 * @notice used to transfer user's supply position on Compound to AvoSafe
	 * @dev uses the transferFrom token in cToken contracts to transfer positions, requires approval from user first
	 * @param _userAccount address of the user account whose position is to be transferred
	 * @param _cTokenContracts array containing all interfaces to the cToken contracts in which the user has supply positions
	 * @param _amts array containing the amount supplied for each token
	 */
	function _transferTokensToAvoSafe(
		address _userAccount,
		CTokenInterface[] memory _cTokenContracts,
		uint256[] memory _amts
	) internal {
		for (uint256 i; i < _cTokenContracts.length; i++)
			if (_amts[i] > 0)
				require(
					_cTokenContracts[i].transferFrom(
						_userAccount,
						address(this),
						_amts[i]
					),
					"ctoken-transfer-failed-allowance?"
				);
	}

	/**
	 * @notice borrows the user's debt positions from Compound via AvoSafe, so that its debt positions get imported to AvoSafe
	 * @dev actually borrow some extra amount than the original position to cover the flash loan fee
	 * @param _cTokenContracts array containing all interfaces to the cToken contracts in which the user has debt positions
	 * @param _amts array containing the amounts the user had borrowed originally from Compound plus the flash loan fee
	 * @param _flashLoanFees flash loan fee (in percentage and scaled up to 10**2)
	 */
	function _borrowDebtPosition(
		CTokenInterface[] memory _cTokenContracts,
		uint256[] memory _amts,
		uint256[] memory _flashLoanFees
	) internal {
		for (uint256 i; i < _cTokenContracts.length; i++)
			if (_amts[i] > 0)
				require(
					_cTokenContracts[i].borrow(
						(_amts[i] + _flashLoanFees[i])
					) == 0,
					"borrow-failed-collateral?"
				);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface TokenInterface {
	function balanceOf(address) external view returns (uint256);

	function allowance(address, address) external view returns (uint256);

	function approve(address, uint256) external;

	function transfer(address, uint256) external returns (bool);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);
}

interface CTokenInterface {
	function mint(uint256 mintAmount) external returns (uint256);

	function redeem(uint256 redeemTokens) external returns (uint256);

	function borrow(uint256 borrowAmount) external returns (uint256);

	function repayBorrow(uint256 repayAmount) external returns (uint256);

	function repayBorrowBehalf(address borrower, uint256 repayAmount)
		external
		returns (uint256); // For ERC20

	function liquidateBorrow(
		address borrower,
		uint256 repayAmount,
		address cTokenCollateral
	) external returns (uint256);

	function borrowBalanceCurrent(address account) external returns (uint256);

	function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

	function exchangeRateCurrent() external returns (uint256);

	function balanceOf(address owner) external view returns (uint256 balance);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);

	function allowance(address, address) external view returns (uint256);
}

interface CETHInterface {
	function mint() external payable;

	function repayBorrow() external payable;

	function repayBorrowBehalf(address borrower) external payable;

	function liquidateBorrow(address borrower, address cTokenCollateral)
		external
		payable;
}

interface ComptrollerInterface {
	function enterMarkets(address[] calldata cTokens)
		external
		returns (uint256[] memory);

	function exitMarket(address cTokenAddress) external returns (uint256);

	function getAssetsIn(address account)
		external
		view
		returns (address[] memory);

	function getAccountLiquidity(address account)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);
}

interface CompoundMappingInterface {
	function cTokenMapping(string calldata tokenId)
		external
		view
		returns (address);

	function getMapping(string calldata tokenId)
		external
		view
		returns (address, address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Compound-Import.
 * @dev Lending & Borrowing.
 */

import { TokenInterface } from "../common/interfaces.sol";
import { CompoundHelper } from "./helpers.sol";
import { Events } from "./events.sol";

contract CompoundImportConnector is CompoundHelper {
	/**
	 * @notice this function performs the import of user's Compound positions into its AvoSafe
	 * @dev called internally by the importCompound and migrateCompound functions
	 * @param _importInputData the struct containing borrowIds of the users borrowed tokens
	 * @param _flashLoanFees list of flash loan fees
	 */
	function _importCompound(
		ImportInputData memory _importInputData,
		uint256[] memory _flashLoanFees
	) internal returns (string memory _eventName, bytes memory _eventParam) {
		
		require(_importInputData.supplyIds.length > 0, "0-length-not-allowed");

		ImportData memory data;

		uint256 _length = (
			_importInputData.supplyIds.length +
			_importInputData.borrowIds.length
		);
		data.cTokens = new address[](_length);

		// get info about all borrowings and lendings by the user on Compound
		data = getBorrowAmounts(_importInputData, data);
		data = getSupplyAmounts(_importInputData, data);

		_enterMarkets(data.cTokens);

		// pay back user's debt using flash loan funds
		_repayUserDebt(
			_importInputData.userAccount,
			data.borrowCtokens,
			data.borrowAmts
		);

		// transfer user's tokens to AvoSafe
		_transferTokensToAvoSafe(
			_importInputData.userAccount,
			data.supplyCtokens,
			data.supplyAmts
		);

		// borrow the earlier position from Compound with flash loan fee added
		_borrowDebtPosition(
			data.borrowCtokens,
			data.borrowAmts,
			_flashLoanFees
		);

		_eventName = "LogCompoundImport(address,address[],string[],string[],uint256[],uint256[])";
		_eventParam = abi.encode(
			_importInputData.userAccount,
			data.cTokens,
			_importInputData.supplyIds,
			_importInputData.borrowIds,
			data.supplyAmts,
			data.borrowAmts
		);
	}

	/**
	 * @notice import Compound position of the address passed in as userAccount
	 * @dev internally calls _importContract to perform the actual import
	 * @param _userAccount address of user whose position is to be imported to AvoSafe
	 * @param _supplyIds Ids of all tokens the user has supplied to Compound
	 * @param _borrowIds Ids of all token borrowed by the user
	 * @param _flashLoanFees list of flash loan fees
	 */
	function importCompound(
		address _userAccount,
		string[] memory _supplyIds,
		string[] memory _borrowIds,
		uint256[] memory _flashLoanFees
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		ImportInputData memory inputData = ImportInputData({
			userAccount: _userAccount,
			supplyIds: _supplyIds,
			borrowIds: _borrowIds
		});

		(_eventName, _eventParam) = _importCompound(inputData, _flashLoanFees);
	}
}

contract AvoCompoundV2Import is CompoundImportConnector {
	string public constant name = "Compound-v2-Import-v1.0";
}