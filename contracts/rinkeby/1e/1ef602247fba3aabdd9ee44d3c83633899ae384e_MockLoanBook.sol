// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";

import {LiquidityPool} from "../LiquidityPool.sol";
import {Repayer} from "../RepayerInterface.sol";

/// @title Topos Loan Book mock
/// @notice Mock of a Loan Book with Repayer interface for testing

contract MockLoanBook is Repayer {
	//
	// errors
	//

	error InvalidAddress();
	error NotAuthorized(address caller);
	error NotEnoughFunds();

	//
	// events
	//

	event LiquidityPoolChanged(address newValue, address oldValue);
	event RepayableChanged(uint256 newValue, uint256 oldValue);

	//
	// state variables
	//

	address public immutable manager;
	ERC20 public immutable asset;

	LiquidityPool public lp;
	uint256 public repayable;

	modifier notZeroAddress(address addr) {
		if (addr == address(0)) revert InvalidAddress();
		_;
	}

	modifier onlyManager() {
		if (msg.sender != manager) revert NotAuthorized(msg.sender);
		_;
	}

	/// @dev We use the constructor to precompute variables that only change rarely.
	/// @param _manager Address which can adjust parameters of the contract
	/// @param _asset the ERC20 asset contract
	/// @param _lp the Liquidity Pool contract
	constructor(
		address _manager,
		ERC20 _asset,
		LiquidityPool _lp
	) notZeroAddress(_manager) {
		manager = _manager;
		asset = _asset;
		lp = _lp;
	}

	//
	// permissioned functions
	//

	/// @param _lp The new Liquidity Pool contract
	function setLiquidityPoolContract(LiquidityPool _lp) external onlyManager {
		address _newValue = address(_lp);
		address _oldValue = address(lp);
		lp = _lp;
		emit LiquidityPoolChanged(_newValue, _oldValue);
	}

	/// @param _amount The new repayable value
	function setRepayableAmount(uint256 _amount) external {
		if (msg.sender != manager) revert NotAuthorized(msg.sender);
		uint256 _oldValue = repayable;
		repayable = _amount;
		emit RepayableChanged(_amount, _oldValue);
	}

	/// @param _amount the amount to repay
	/// @param _to the address of liquidity provider
	function transferRepayment(address _to, uint256 _amount) external {
		if (msg.sender != address(lp)) revert NotAuthorized(msg.sender);
		if (_amount > repayable) revert NotEnoughFunds();
		if (_to == address(0)) revert InvalidAddress();
		SafeTransferLib.safeTransfer(asset, _to, _amount);
	}

	//
	// public functions
	//

	function getRepayableAmount() external view returns (uint256) {
		uint256 _balance = asset.balanceOf(address(this));
		return repayable > _balance ? _balance : repayable;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {CapitalPool} from "./CapitalPool.sol";
import {TPGToken} from "./TPGToken.sol";
import "./LiquidityPoolInterface.sol";
import "./RepayerInterface.sol";

/// @title Topos Liquidity Pool
contract LiquidityPool is Repayer {
	//
	// constants
	//

	uint16 internal constant BASE_UNIT = 1e4; // 2 decimals

	//
	// errors
	//

	error AddressesListMismatch(address addr);
	error InputNotValid();
	error InsufficientAssets(uint256 needed);
	error InvalidAddress();
	error NotAuthorized(address caller);
	error NotEnoughFunds();

	//
	// events
	//

	event AddressAllowed(address _address);
	event AddressDenied(address _address);
	event CapitalPoolChanged(address newValue, address oldValue);
	event InsuranceRestored(uint256 insurance, uint256 mintedTPGs, uint256 burnedTPGs);
	event RepayersChanged();
	event RiskFactorChanged(uint16 newValue, uint16 oldValue);

	//
	// state variables
	//

	address public immutable manager;
	ERC20 public immutable asset;
	TPGToken public immutable tpg;
	CapitalPool public cp;
	uint256 private repayable;
	uint16 public riskFactor;
	string public name;

	//
	// structs, enums, arrays
	//

	/// @notice struct of an AllowedLPI of LiquidityPoolInterface with properties to couple array and mapping
	struct AllowedLPI {
		LiquidityPoolInterface lpi;
		uint256 listPointer;
		bool allowed;
	}
	/// @notice mapping of the allowed Liquity Pool Interfaces: address => AllowedLPI
	mapping(address => AllowedLPI) public allowedLPI;
	/// @notice indexing array for the allowedLPI mapping
	address[] public addressListLPI;
	/// @notice array for the repayment interfaces
	Repayer[] public repayers;

	modifier notZeroAddress(address addr) {
		if (addr == address(0)) revert InvalidAddress();
		_;
	}

	modifier onlyAllowedLPI() {
		if (allowedLPI[msg.sender].allowed != true) revert NotAuthorized(msg.sender);
		_;
	}

	modifier onlyManager() {
		if (msg.sender != manager) revert NotAuthorized(msg.sender);
		_;
	}

	/// @dev We use the constructor to precompute variables that only change rarely.
	/// @param _manager Address which can adjust parameters of the contract
	/// @param _asset the ERC20 asset contract
	/// @param _tpg the TPG Token contract
	/// @param _cp the Capital Pool contract
	/// @param _name the contract name
	constructor(
		address _manager,
		ERC20 _asset,
		TPGToken _tpg,
		CapitalPool _cp,
		string memory _name
	) notZeroAddress(_manager) {
		manager = _manager;
		asset = _asset;
		tpg = _tpg;
		cp = _cp;
		name = _name;
		/// @dev the first element is dummy so we can start at index 1 because the default of listPointer is 0
		addressListLPI.push(address(0));
	}

	//
	// permissioned functions
	//

	function allowLPI(LiquidityPoolInterface _lpi) external onlyManager {
		address _address = address(_lpi);
		uint256 _index = allowedLPI[_address].listPointer;
		if (_index > 0) {
			if (addressListLPI[_index] != _address) revert AddressesListMismatch(_address);
		} else {
			addressListLPI.push(_address);
			allowedLPI[_address].lpi = _lpi;
			allowedLPI[_address].listPointer = addressListLPI.length - 1;
		}
		allowedLPI[_address].allowed = true;
		emit AddressAllowed(_address);
	}

	function denyLPI(LiquidityPoolInterface _lpi) external onlyManager {
		address _address = address(_lpi);
		uint256 _index = allowedLPI[_address].listPointer;
		if (_index == 0) revert InputNotValid();
		if (addressListLPI[_index] != _address) revert AddressesListMismatch(_address);
		addressListLPI[_index] = addressListLPI[addressListLPI.length - 1];
		addressListLPI.pop();
		allowedLPI[addressListLPI[_index]].listPointer = _index;
		delete allowedLPI[_address];
		emit AddressDenied(_address);
	}

	/// @param _cp The new Capital Pool contract
	function setCapitalPool(CapitalPool _cp) external onlyManager {
		address _newValue = address(_cp);
		address _oldValue = address(cp);
		cp = _cp;
		emit CapitalPoolChanged(_newValue, _oldValue);
	}

	/// @param _repayers The new array of Receivers, max length 127 (TBD whether this limit has to be considerably lowered)
	function setRepayers(Repayer[] calldata _repayers) external onlyManager {
		uint256 _length = _repayers.length;
		if (_length > 0x7F) revert InputNotValid();
		delete repayers;
		for (uint8 _i = 0; _i < _length; _i++) {
			repayers.push(_repayers[_i]);
		}
		emit RepayersChanged();
	}

	/// @param _newValue The new Risk Factor
	function setRiskFactor(uint16 _newValue) external onlyManager {
		if (_newValue > BASE_UNIT) revert InputNotValid();
		uint16 _oldValue = riskFactor;
		riskFactor = _newValue;
		emit RiskFactorChanged(_newValue, _oldValue);
	}

	/// @notice it calulcates the amount of insurance (asset), given a risk factor and amount of the investments
	/// @return insurance_  the needed insurance
	/// @return balanceTPGAsset_ the current value of TPGs in asset
	function calculateInsurance() external view returns (uint256 insurance_, uint256 balanceTPGAsset_) {
		(insurance_, balanceTPGAsset_, ) = _assess();
	}

	/// @notice it calulcates the amount of insurance (asset), given a risk factor and amount of the investments, burning/minting TPG if needed
	function restoreInsurance() external onlyManager {
		uint256 _mintedTPGs;
		uint256 _burnedTPGs;
		(uint256 _insurance, uint256 _balanceTPGAsset, uint256 _spotPrice) = _assess();
		// we check if we have to burn of mint
		if (_balanceTPGAsset > _insurance) {
			// we calulcate the amount of asset we want
			uint256 _exceeded = _balanceTPGAsset - _insurance;
			// we calulcate the amount of TPG we can burn
			_burnedTPGs = FixedPointMathLib.fdiv(_exceeded, _spotPrice, FixedPointMathLib.WAD);
			tpg.approve(address(cp), _burnedTPGs);
			cp.burnTPG(_burnedTPGs, 0);
		} else if (_balanceTPGAsset < _insurance) {
			// we calculate the amount needed asset
			uint256 _needed = _insurance - _balanceTPGAsset;
			// we check it the contract has enough asset for minting
			if (asset.balanceOf(address(this)) < _needed) revert InsufficientAssets(_needed);
			// we calculcate the amount of TPG we need
			_mintedTPGs = FixedPointMathLib.fdiv(_needed, _spotPrice, FixedPointMathLib.WAD);
			asset.approve(address(cp), _needed);
			cp.mintTPG(_needed, 0);
		}
		// we emit the event with the needed insurance and how many TPGs were minted or burned
		emit InsuranceRestored(_insurance, _mintedTPGs, _burnedTPGs);
	}

	/// @notice it handles the repayments of an investment hold in an allowed LiquidityPoolInterface based on the order of the Repayers list
	/// @param _to address of the investor
	/// @param _due amount to be repaid
	/// @param _repayersLPI list of the repayers of the LiquidityPoolInterface
	function repay(
		address _to,
		uint256 _due,
		Repayer[] calldata _repayersLPI
	) external onlyAllowedLPI {
		(uint256 _sub, SharedStructs.AddressAmount[] memory _repayers) = _checkRepayment(_due, _repayersLPI);
		// the subtotal must be exactly the same of the amount due (no partial or over repayment)
		if (_sub != _due) revert NotEnoughFunds();
		// we iterate over the list of possible repayments
		for (uint8 _i = 0; _i < _repayers.length; _i++) {
			// we skip the repayer that can't repay anything at the moment
			if (_repayers[_i].amount == 0) {
				continue;
			}
			// we check it the Repayer is the contract itself (we burn the TPG insurance) or an external Repayer (we command the transfer to the investor)
			if (address(this) == _repayers[_i].addr) {
				_burnTPGsAndTransferAssets(_to, _repayers[_i].amount);
			} else {
				Repayer(_repayers[_i].addr).transferRepayment(_to, _repayers[_i].amount);
			}
		}
	}

	/// @notice it calculates if an investment can be repaid and what each repayers can give based on the order of the Repayers list
	/// @param _due amount to be repaid
	/// @param _repayersLPI list of the repayers of the LiquidityPoolInterface
	/// @return diff_ the difference between the amount due and the possible repayment
	/// @return repayers_ a list of tuples: address of repayer and the amount it can give
	function forecastRepayment(uint256 _due, Repayer[] calldata _repayersLPI)
		external
		view
		returns (uint256 diff_, SharedStructs.AddressAmount[] memory repayers_)
	{
		uint256 _sub;
		(_sub, repayers_) = _checkRepayment(_due, _repayersLPI);
		return ((_due - _sub), repayers_);
	}

	/// @notice it converts the current balance of TPGs in stablecoin value
	function getRepayableAmount() external view returns (uint256) {
		return _balanceTPGsToAssets(cp.spotPrice());
	}

	/// @dev atm this is just a non used function to implement the interface
	function setRepayableAmount(uint256 _amount) external onlyManager {
		repayable = _amount;
	}

	/// @notice it burns part of the insurance and transfer the stablecoins to address
	function transferRepayment(address _to, uint256 _amount) external onlyManager {
		_burnTPGsAndTransferAssets(_to, _amount);
	}

	//
	// internal functions
	//

	/// @notice it calulcates the amount of insurance (asset), given a risk factor and amount of the investments
	/// @return insurance_  the needed insurance
	/// @return balanceTPGAsset_ the current value of TPGs in asset
	/// @return spotPrice_ the current spot price
	function _assess()
		internal
		view
		returns (
			uint256 insurance_,
			uint256 balanceTPGAsset_,
			uint256 spotPrice_
		)
	{
		// we get the current spot price of TPG
		spotPrice_ = cp.spotPrice();
		// we convert the balance of TPG in asset given the spot price
		balanceTPGAsset_ = _balanceTPGsToAssets(spotPrice_);
		// if risk factor is not set no insurance is needed
		if (riskFactor == 0) return (0, balanceTPGAsset_, spotPrice_);
		uint256 _total;
		uint256 _length = addressListLPI.length;
		// looop through Liquidity Pool Interfaces to get the amount of active investments
		// we skip the first element in the list because is a dummy element
		for (uint8 _i = 1; _i < _length; _i++) {
			address _address = addressListLPI[_i];
			// we skip the non allowed ones
			if (allowedLPI[_address].allowed == false) {
				continue;
			}
			_total += allowedLPI[_address].lpi.totalToBePaidValue() - allowedLPI[_address].lpi.totalRepaidValue();
		}
		// if there are no investments there is no need of insurance
		if (_total == 0) return (0, balanceTPGAsset_, spotPrice_);
		// we calculate the insurance as a percentage of the investment by the risk factor
		insurance_ = FixedPointMathLib.fmul(riskFactor, _total, BASE_UNIT);
	}

	/// @notice it converts the TPG current balance in asset value given a spot price
	function _balanceTPGsToAssets(uint256 _spotPrice) internal view returns (uint256) {
		// we get the balance of TPG of this contract
		uint256 _balanceTPG = tpg.balanceOf(address(this));
		// we convert the balance of TPG in asset given the spot price
		return FixedPointMathLib.fmul(_balanceTPG, _spotPrice, FixedPointMathLib.WAD);
	}

	/// @notice burn an amount of TPGs in order to transfer an equivalent amount of asset given a spot price
	function _burnTPGsAndTransferAssets(address _to, uint256 _amount) internal {
		uint256 _spotPrice = cp.spotPrice();
		uint256 _balanceTPGAsset = _balanceTPGsToAssets(_spotPrice);
		if (_amount > _balanceTPGAsset) revert NotEnoughFunds();
		// we calulcate the amount of TPG we can burn
		uint256 _burnedTPGs = FixedPointMathLib.fdiv(_amount, _spotPrice, FixedPointMathLib.WAD);
		tpg.approve(address(cp), _burnedTPGs);
		cp.burnTPG(_burnedTPGs, 0);
		SafeTransferLib.safeTransfer(asset, _to, _amount);
	}

	/// @notice merge an external list of Repayers with its own and it calculates how much they can repay
	/// @return sub_ a subtotal of partial possible repayments
	/// @return subs_ a list of tuples: address of repayer and the amount it can give
	function _checkRepayment(uint256 _due, Repayer[] calldata _repayersLPI)
		internal
		view
		returns (uint256 sub_, SharedStructs.AddressAmount[] memory subs_)
	{
		// we merge the the repayers from the LPI with the one of the contract
		Repayer[] memory _repayers = new Repayer[](repayers.length + _repayersLPI.length);
		uint8 _k = 0;
		for (; _k < _repayersLPI.length; _k++) {
			_repayers[_k] = _repayersLPI[_k];
		}
		uint8 _j = 0;
		while (_j < repayers.length) {
			_repayers[_k++] = repayers[_j++];
		}
		SharedStructs.AddressAmount[] memory _subs = new SharedStructs.AddressAmount[](_repayers.length);

		for (uint8 _i = 0; _i < _repayers.length; _i++) {
			// we check it the Repayer is the contract itself (and we caluclate how much is valued the TPG insurance) or an external Repayer
			uint256 _repayable = address(this) == address(_repayers[_i]) ? _balanceTPGsToAssets(cp.spotPrice()) : _repayers[_i].getRepayableAmount();
			if ((_repayable + sub_) >= _due) {
				// if with this value the investment is fully repaid we just calculate the difference needed from the last repayer and we exit
				uint256 _diff = _due - sub_;
				_subs[_i] = SharedStructs.AddressAmount(address(_repayers[_i]), _diff);
				sub_ += _diff;
				break;
			} else {
				// if not we add to the subtotal the repayment of the current repayer
				_subs[_i] = SharedStructs.AddressAmount(address(_repayers[_i]), _repayable);
				sub_ += _repayable;
			}
		}
		subs_ = _subs;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface Repayer {
	function getRepayableAmount() external view returns (uint256);

	function setRepayableAmount(uint256 _amount) external;

	function transferRepayment(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            // Equivalent to require(y != 0 && (x == 0 || (x * baseUnit) / x == baseUnit))
            if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), baseUnit)))) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := baseUnit
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store baseUnit in z for now.
                    z := baseUnit
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, baseUnit)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, baseUnit)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";

import {BondingSurface} from "./BondingSurface.sol";
import {TPGToken} from "./TPGToken.sol";

/// @title Topos asset pool
/// @notice Pool holding an asset. Assets are deposited in exchange for TPG and in the
/// 				case of malfeasance will be used to cover shortfalls. The capital pool can
/// @custom:invariant asset.balanceOf(capitalPool) > 1
/// @custom:invariant asset.balanceOf(capitalPool) =< 1e36
contract CapitalPool {
	//
	// errors
	//

	error NotAuthorized(address caller);
	error InsufficientMintInput();
	error InsufficientBurnInput();
	error InsufficientTokenOut(uint256 want, uint256 get);
	error SeizeLimit(uint256 have);
	error SeizeTimeout(uint64 target);
	error SeizeAdjustment(uint64 limit);
	error SpreadAdjustment(uint64 spread);
	error BeforeMigrationDelay();
	error Deprecated(address _new);

	//
	// events
	//

	event AssetsSeized(uint256 amt);
	event TPGMinted(address indexed minter, uint256 _in, uint256 _out);
	event TPGBurned(address indexed burner, uint256 _in, uint256 _out, uint256 _spread);

	//
	// state variables
	//

	address public immutable manager;
	ERC20 public immutable asset;

	uint64 public constant MAX_SEIZE = 100; // BPS, 1%
	uint64 public constant MAX_SPREAD = 100; // BPS, 2.5%
	uint64 public constant SEIZE_DELAY = 7 days;
	uint64 public constant MIGRATION_DELAY = 7 days;

	uint256 public constant MIN_RESERVE = 1 ether;

	uint64 public lastSeizeTime;
	uint64 public currentSeize = MAX_SEIZE;
	uint64 public currentSpread = MAX_SPREAD;
	uint64 public migrationDelayEnd;

	address public pendingMigration;

	bool public deprecated = false;

	BondingSurface public immutable surface;
	TPGToken public immutable tpg;
	address public immutable reservePool;

	modifier onlyCoverManager() {
		if (msg.sender != manager) revert NotAuthorized(msg.sender);
		_;
	}

	constructor(
		TPGToken _tpg,
		BondingSurface _bs,
		address _manager,
		address _reserve,
		ERC20 _asset
	) {
		surface = _bs;
		tpg = _tpg;
		reservePool = _reserve;
		asset = _asset;
		manager = _manager;
	}

	/// @notice Mint TPG in exchange for caller supplied tokens.
	/// @param _in Amount of tokens to use for minting
	/// @param _minOut Minimum amount of TPG that should be minted, revert otherwise
	function mintTPG(uint256 _in, uint256 _minOut) external {
		if (_in == 0) revert InsufficientMintInput();
		if (deprecated) revert Deprecated(pendingMigration);

		uint256 capitalAvailable = asset.balanceOf(address(this));
		SafeTransferLib.safeTransferFrom(asset, msg.sender, address(this), _in);

		uint256 out = surface.tokenOut(_in, capitalAvailable);
		if (out < _minOut) revert InsufficientTokenOut(_minOut, out);

		tpg.mint(msg.sender, out);
		emit TPGMinted(msg.sender, _in, out);
	}

	/// @notice Burn TPG in exchange for pool supplied tokens.
	/// @param _in Amount of tokens to use for burning
	/// @param _minOut Minimum amount of tokens that should be returned, before the spread
	///                is taken
	function burnTPG(uint256 _in, uint256 _minOut) external {
		if (_in == 0) revert InsufficientBurnInput();

		uint256 capitalAvailable = asset.balanceOf(address(this));
		tpg.burn(msg.sender, _in);

		uint256 out = surface.tokenIn(_in, capitalAvailable);

		// The asset pool must never be empty.
		if (capitalAvailable - out < MIN_RESERVE) {
			out = capitalAvailable - MIN_RESERVE;
		}

		// calc and collect spread
		uint256 s = spread(out);

		if (out - s < _minOut) revert InsufficientTokenOut(_minOut, out - s);

		SafeTransferLib.safeTransfer(asset, reservePool, s);
		SafeTransferLib.safeTransfer(asset, msg.sender, out - s);
		emit TPGBurned(msg.sender, _in, out, s);
	}

	//
	// view functions
	//

	/// @notice Calculate how many TPG would be minted if depositing `_in` tokens.
	/// @param _in Number of tokens to deposit for minting.
	function getTPGOut(uint256 _in) public view returns (uint256) {
		uint256 capitalAvailable = asset.balanceOf(address(this));
		return surface.tokenOut(_in, capitalAvailable);
	}

	/// @notice Calculate how many Assets would be returned if burning `_in` TPG.
	/// @param _in Number of tokens to deposit for minting.
	function getAssetOut(uint256 _in) public view returns (uint256) {
		uint256 capitalAvailable = asset.balanceOf(address(this));
		uint256 out = surface.tokenIn(_in, capitalAvailable);
		if (capitalAvailable - out < MIN_RESERVE) {
			out = capitalAvailable - MIN_RESERVE;
		}
		uint256 s = spread(out);
		return out - s;
	}

	function spread(uint256 _out) public view returns (uint256) {
		return (_out * currentSpread) / 10000;
	}

	/// @notice Compute how many tokens can be seized based on `currentSeize` and token balance.
	/// @return Maximum number of tokens that can be seized
	function seizable() public view returns (uint256) {
		uint256 bal = asset.balanceOf(address(this));

		return (bal * currentSeize) / 10000;
	}

	/// @notice Compute the spot price based on the current capital available.
	function spotPrice() public view returns (uint256) {
		uint256 bal = asset.balanceOf(address(this));

		return surface.spotPrice(bal);
	}

	//
	// permissioned functions
	//

	/// @notice This function allows the cover manager to seize assets from this pool.
	///         The cover manager is going to be a multisig initially, which puts the
	///         pool at very high perceived rug risk. To lower the risk, the manager can
	///         only withdraw `maxSeize` bps per `maxSeizePeriod` seconds.
	/// @param amt Number of tokens to be removed from the pool
	function seize(uint256 amt) public onlyCoverManager {
		uint256 s = seizable();
		if (amt > s) {
			revert SeizeLimit(s);
		}
		// solhint-disable-next-line not-rely-on-time
		else if (lastSeizeTime + SEIZE_DELAY > block.timestamp) revert SeizeTimeout(lastSeizeTime + SEIZE_DELAY);

		// The asset pool must never be empty.
		if (asset.balanceOf(address(this)) - amt < MIN_RESERVE) {
			amt = asset.balanceOf(address(this)) - MIN_RESERVE;
		}

		// solhint-disable-next-line not-rely-on-time
		lastSeizeTime = uint64(block.timestamp);

		SafeTransferLib.safeTransfer(asset, manager, amt);
		emit AssetsSeized(amt);
	}

	function adjustSeize(uint64 _seize) public onlyCoverManager {
		if (_seize > MAX_SEIZE) revert SeizeAdjustment(_seize);
		currentSeize = _seize;
	}

	function adjustSpread(uint64 _spread) public onlyCoverManager {
		if (_spread > MAX_SPREAD) revert SpreadAdjustment(_spread);
		currentSpread = _spread;
	}

	/// @notice After a delay of `MIGRATION_DELAY` we can migrate to a new pool contract.
	///         The delay should give participants ample time to withdraw funds if they
	///         disagree with the new contract.
	/// @param _new The new capital pool contract.
	function startMigration(address _new) public onlyCoverManager {
		if (deprecated) revert Deprecated(pendingMigration);
		migrationDelayEnd = uint64(block.timestamp) + MIGRATION_DELAY;
		pendingMigration = _new;
	}

	/// @notice This finalizes the migration, transferring the asset to the new address
	///         and setting it as the new minter.
	function migrate() public onlyCoverManager {
		if (block.timestamp < migrationDelayEnd || migrationDelayEnd == 0) revert BeforeMigrationDelay();

		tpg.setMinter(pendingMigration);
		SafeTransferLib.safeTransfer(asset, pendingMigration, asset.balanceOf(address(this)));
		deprecated = true;
	}

	/// @notice The TPG contract requires confirmation from the new minter that they are
	///         ready to accept their new role.
	function acceptMinter() public onlyCoverManager {
		tpg.acceptMinter();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "solmate/tokens/ERC20.sol";

/// @title Topos token
contract TPGToken is ERC20 {
	error UnauthorizedMinter();
	error UnauthorizedPendingMinter();

	address public minter;
	address public pendingMinter;

	constructor() ERC20("Topos Token", "TPG", 18) {
		minter = msg.sender;
	}

	event NewPendingMinter(address _minter);
	event MinterUpdated(address _minter);

	modifier onlyMinter() {
		if (msg.sender != minter) revert UnauthorizedMinter();
		_;
	}

	/// @notice Set a new minter, which will be activated after they call the acceptMinter
	///         function.
	/// @param _new Address of the new minter
	function setMinter(address _new) external onlyMinter {
		pendingMinter = _new;
		emit NewPendingMinter(_new);
	}

	/// @notice Allow a newly appointed minter to accept their new responsibilities.
	function acceptMinter() external {
		if (msg.sender != pendingMinter) revert UnauthorizedPendingMinter();
		minter = pendingMinter;
		emit MinterUpdated(pendingMinter);
	}

	/// @notice TPG does not have a maximum supply and can be minted via a bonding
	///         surface.
	/// @param dst Receiver of minted tokens
	/// @param amt Mint amount
	function mint(address dst, uint256 amt) external onlyMinter {
		_mint(dst, amt);
	}

	/// @notice Burn `amt` tokens
	/// @param amt Burn amount
	function burn(uint256 amt) external {
		_burn(msg.sender, amt);
	}

	/// @notice Burn `amt` tokens belonging to `src`
	/// @param src Address whose tokens will be burnt
	/// @param amt Burn amount
	function burn(address src, uint256 amt) external {
		if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
			allowance[src][msg.sender] -= amt;
		}

		// Will revert if balance < amt
		_burn(src, amt);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./LiquidityPool.sol";
import "./LiquidityProviderWhitelist.sol";
import "./SharedStructs.sol";

interface LiquidityPoolInterface {
	function forecastRepayment(string memory _code) external view returns (uint256 diff_, SharedStructs.AddressAmount[] memory repayers_);

	function getCeiling() external view returns (uint256);

	function getBuffer() external view returns (uint256);

	function getInvestment(string memory _code) external view returns (SharedStructs.Investment memory);

	function getMinimum() external view returns (uint256);

	function getReceiver(uint8 _index) external view returns (SharedStructs.InvestmentReceiver memory);

	function getReceivers() external view returns (SharedStructs.InvestmentReceiver[] memory);

	function invest(uint256 _amount) external;

	function repay(string memory _code) external;

	function resetCeiling() external;

	function setBuffer(uint256 _newValue) external;

	function setCeiling(uint256 _newValue) external;

	function setLiquidityProviderWhitelistContract(LiquidityProviderWhitelist _lpw) external;

	function setLiquidityPoolContract(LiquidityPool _lp) external;

	function setMinimum(uint256 _newValue) external;

	function setReceivers(SharedStructs.InvestmentReceiver[] calldata _receivers) external;

	function totalInvestedValue() external view returns (uint256);

	function totalToBePaidValue() external view returns (uint256);

	function totalRepaidValue() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title Bonding surface formulas
/// @dev
///                        (C_a)^n
/// p = f(C_a, C_r) = B -------------
///                      (C_r)^(n-1)
///
/// TPG price per unit, p. The independent variables in the bonding function are the
/// capital available, C_a, and the capital required, C_r. C_a describes the amount of
/// value stored in the network at any given point in time. C_r  describes the amount
/// of value that is needed to operate the Topos protocol according to market size
/// and conditions, the regulatory requirements, as well as the chosen risk appetite,
/// and allows for considering these three factors in the determination of p
/// Initial:
///   B := 10e-7
///   1 < n <= 2
///   n := 2
///
/// We assume n to be constant. Otherwise we would have to change the burn/mint derivations
/// on update.
contract BondingSurface {
	//
	// errors
	//

	error NotAuthorized(address caller);
	error InputTooLarge();
	error InsufficientTPGSupply();
	error InvalidB();
	error InvalidCapitalRequired();

	//
	// state variables
	//

	address public immutable riskManager;
	uint256 public capitalRequired;

	uint256 public B = 0.000001 ether;

	// (B / C_r)
	uint256 public BCr;

	modifier onlyRiskManager() {
		if (msg.sender != riskManager) revert NotAuthorized(msg.sender);
		_;
	}

	/// @dev We use the constructor to precompute variables that only change rarely.
	/// @param _riskManager Address which can adjust parameters of the bonding surface
	/// @param _cr The initial capital requirement
	constructor(address _riskManager, uint256 _cr) {
		riskManager = _riskManager;

		capitalRequired = _cr;
		updateVariables();
	}

	//
	// view functions
	//

	/// @dev Compute spot price for a given capital available given current capital
	///      requirements
	/// p = f(C_a, C_r) = B * (C_a^2 / C_r)
	///
	/// @param _ca Capital pool to base the spot price on.
	function spotPrice(uint256 _ca) public view returns (uint256) {
		uint256 caSq = FixedPointMathLib.fmul(_ca, _ca, FixedPointMathLib.WAD); // C_a^2
		return FixedPointMathLib.fmul(caSq, BCr, FixedPointMathLib.WAD); // C_a^2 * B / C_r
	}

	/// @dev Compute spot price for a given capital available and capital required
	/// p = f(C_a, C_r) = B * (C_a^2 / C_r)
	///
	/// @param _ca Capital pool to base the spot price on.
	/// @param _cr Capital requirements to base the spot price on.
	function spotPrice(uint256 _ca, uint256 _cr) public view returns (uint256) {
		uint256 caSq = FixedPointMathLib.fmul(_ca, _ca, FixedPointMathLib.WAD); // C_a^2
		uint256 caSqCr = FixedPointMathLib.fdiv(caSq, _cr, FixedPointMathLib.WAD);
		return FixedPointMathLib.fmul(caSqCr, B, FixedPointMathLib.WAD); // C_a^2 * B / C_r
	}

	/// @dev To get the number of tokens we have the following formula:
	///
	///        1          1         1
	/// n = ------- * (------- - -------)
	///      B/C_r      C_a_1     C_a_2
	///
	/// _ca must be > 0
	/// @notice Calculate number of tokens to mint based on `_in` tokens supplied
	///         and `_ca` of capital available.
	/// @param _in Assets added to the pool.
	/// @param _ca Capital available to use for bonding curve mint.
	function tokenOut(uint256 _in, uint256 _ca) public view returns (uint256) {
		// If the input is bigger inverse will give us 0.
		if (_ca > 1e36 || _ca + _in > 1e36) revert InputTooLarge();

		uint256 inv1 = inv(_ca);
		uint256 inv2 = inv(_ca + _in);
		uint256 inner = inv1 - inv2;

		return FixedPointMathLib.fmul(inv(BCr), inner, FixedPointMathLib.WAD);
	}

	/// @dev To get the change in assests when burning tokens
	///
	///        B            1
	/// x = (----- * m + -------)^-1
	///       C_r         C_a_2
	///
	/// m is the token burn amount and C_a_2 is the capitalAvailable before burn
	/// _ca must be > 0
	/// @notice Calculate number of assets to return based on `_out` tokens being burnt,
	///         `_ca` of capital available and `_supply` TPG minted.
	/// @param _out TPG to burn
	/// @param _ca Capital available to use for bonding curve burn.
	function tokenIn(uint256 _out, uint256 _ca) public view returns (uint256) {
		// m * (B / C_r)
		uint256 BCrM = FixedPointMathLib.fmul(BCr, _out, FixedPointMathLib.WAD);
		// 1 / C_a_2
		uint256 ca2inv = inv(_ca);

		return _ca - inv(BCrM + ca2inv);
	}

	//
	// permissioned functions
	//

	function setCapitalRequired(uint256 _newCR) public onlyRiskManager {
		if (_newCR == 0) revert InvalidCapitalRequired();
		capitalRequired = _newCR;
		updateVariables();
	}

	function setB(uint256 _newB) public onlyRiskManager {
		if (_newB == 0) revert InvalidB();
		B = _newB;
		updateVariables();
	}

	//
	// internal functions
	//

	/// @param x 18 decimal fixed point number to inverse. 0 < x <= 1e36
	function inv(uint256 x) internal view returns (uint256 res) {
		// Compute inverse https://github.com/paulrberg/prb-math/blob/86c068e21f9ba229025a77b951bd3c4c4cf103da/contracts/PRBMathUD60x18.sol#L214
		unchecked {
			res = 1e36 / x;
		}
	}

	function updateVariables() internal {
		BCr = FixedPointMathLib.fdiv(B, capitalRequired, FixedPointMathLib.WAD);
		if (BCr > 1e36) revert InputTooLarge();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// @title Topos Investor Whitelist
/// @notice the contract contains in plain and visible the list of addresses that are allowed to make an investment
contract LiquidityProviderWhitelist {
	//
	// errors
	//

	error InvalidAddress();
	error NotAuthorized(address caller);

	//
	// events
	//

	event AllowedAddress(address indexed addr);
	event DeniedAddress(address indexed addr);

	//
	// state variables
	//

	address public immutable manager;
	string public name;

	//
	// structs, enums, arrays
	//

	/// @notice mapping of allowed addresses: address => bool (true = active)
	mapping(address => bool) public allowedAddresses;

	modifier notZeroAddress(address addr) {
		if (addr == address(0)) revert InvalidAddress();
		_;
	}

	modifier onlyManager() {
		if (msg.sender != manager) revert NotAuthorized(msg.sender);
		_;
	}

	/// @dev We use the constructor to precompute variables that only change rarely.
	/// @param _manager Address which can adjust parameters of the contract
	/// @param _name the contract name
	constructor(address _manager, string memory _name) notZeroAddress(_manager) {
		manager = _manager;
		name = _name;
	}

	//
	// permissioned functions
	//

	function allowAddress(address _address) external onlyManager notZeroAddress(_address) {
		allowedAddresses[_address] = true;
		emit AllowedAddress(_address);
	}

	function denyAddress(address _address) external onlyManager notZeroAddress(_address) {
		allowedAddresses[_address] = false;
		emit DeniedAddress(_address);
	}

	//
	// public functions
	//

	function checkAddress(address _address) external view returns (bool) {
		return allowedAddresses[_address];
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Repayer} from "./RepayerInterface.sol";

library SharedStructs {
	/// @notice enum of possible states of an Investment
	enum InvestmentStatus {
		AVAILABLE,
		OK,
		REPAID
	}

	/// @notice general struct of an Investment
	struct Investment {
		uint256 tenure;
		uint256 principal;
		uint256 interestDue;
		uint256 start;
		uint256 end;
		uint256 totalRepaid;
		uint128 timeBetweenInstalments;
		uint32 fixedInterestAtEnd;
		uint16 numberOfInstalment;
		uint16 lastRepaidInstalment;
		uint32 fixedInterestPerInstalment;
		uint32 interestVariabilityCoefficient;
		address investor;
		string code;
		InvestmentStatus status;
	}

	/// @notice struct for investment receiver that holds the percentage for the split investment and must implement the Repayer interface
	struct InvestmentReceiver {
		uint256 percentage;
		Repayer repayer;
	}

	/// @notice tuple with address and amount, a general struct for several use cases e.g. the return of forecastRepayment
	struct AddressAmount {
		address addr;
		uint256 amount;
	}
}