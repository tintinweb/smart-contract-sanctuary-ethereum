// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ERC165Spec.sol";
import "../interfaces/PriceOracleSpec.sol";

/**
 * @title Land Sale Oracle Implementation
 *
 * @notice Supports the Land Sale with the ETH/ILV conversion required
 *
 * @author Basil Gorin
 */
contract LandSaleOracleMock is LandSaleOracle, ERC165 {
	// initial conversion rate is 1 ETH = 4 ILV
	uint256 public ethOut = 1;
	uint256 public ilvIn = 4;
	uint256 public ethToIlvOverride = type(uint256).max;

	/**
	 * @inheritdoc ERC165
	 */
	function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
		// determine and return the interface support
		return interfaceID == type(LandSaleOracle).interfaceId;
	}

	// updates the conversion rate
	function setRate(uint256 _ethOut, uint256 _ilvIn) public {
		ethOut = _ethOut;
		ilvIn = _ilvIn;
	}

	// overrides the `ethToIlv` completely and forces it to always return the value specified
	function setEthToIlvOverride(uint256 _ethToIlvOverride) public {
		ethToIlvOverride = _ethToIlvOverride;
	}

	/**
	 * @inheritdoc LandSaleOracle
	 */
	function ethToIlv(uint256 _ethOut) public view virtual override returns (uint256 _ilvIn) {
		return ethToIlvOverride < type(uint256).max? ethToIlvOverride: _ethOut * ilvIn / ethOut;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ERC-165 Standard Interface Detection
 *
 * @dev Interface of the ERC165 standard, as defined in the
 *       https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * @dev Implementers can declare support of contract interfaces,
 *      which can then be queried by others.
 *
 * @author Christian Reitwießner, Nick Johnson, Fabian Vogelsteller, Jordi Baylina, Konrad Feldmeier, William Entriken
 */
interface ERC165 {
	/**
	 * @notice Query if a contract implements an interface
	 *
	 * @dev Interface identification is specified in ERC-165.
	 *      This function uses less than 30,000 gas.
	 *
	 * @param interfaceID The interface identifier, as specified in ERC-165
	 * @return `true` if the contract implements `interfaceID` and
	 *      `interfaceID` is not 0xffffffff, `false` otherwise
	 */
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Pair Price Oracle, a.k.a. Pair Oracle
 *
 * @notice Generic interface used to consult on the Uniswap-like token pairs conversion prices;
 *      one pair oracle is used to consult on the exchange rate within a single token pair
 *
 * @notice See also: https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/building-an-oracle
 *
 * @author Basil Gorin
 */
interface PairOracle {
	/**
	 * @notice Updates the oracle with the price values if required, for example
	 *      the cumulative price at the start and end of a period, etc.
	 *
	 * @dev This function is part of the oracle maintenance flow
	 */
	function update() external;

	/**
	 * @notice For a pair of tokens A/B (sell/buy), consults on the amount of token B to be
	 *      bought if the specified amount of token A to be sold
	 *
	 * @dev This function is part of the oracle usage flow
	 *
	 * @param token token A (token to sell) address
	 * @param amountIn amount of token A to sell
	 * @return amountOut amount of token B to be bought
	 */
	function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);
}

/**
 * @title Oracle Registry
 *
 * @notice To make pair oracles more convenient to use, a more generic Oracle Registry
 *        interface is introduced: it stores the addresses of pair price oracles and allows
 *        searching/querying for them
 *
 * @author Basil Gorin
 */
interface OracleRegistry {
	/**
	 * @notice Searches for the Pair Price Oracle for A/B (sell/buy) token pair
	 *
	 * @param tokenA token A (token to sell) address
	 * @param tokenB token B (token to buy) address
	 * @return pairOracle pair price oracle address for A/B token pair
	 */
	function getOracle(address tokenA, address tokenB) external view returns (address pairOracle);
}

/**
 * @title Land Sale Oracle Interface
 *
 * @notice Supports the Land Sale with the ETH/ILV conversion required,
 *       marker interface is required to support ERC165 lookups
 *
 * @author Basil Gorin
 */
interface LandSaleOracle {
	/**
	 * @notice Powers the ETH/ILV Land token price conversion, used when
	 *      selling the land for sILV to determine how much sILV to accept
	 *      instead of the nominated ETH price
	 *
	 * @notice Note that sILV price is considered to be equal to ILV price
	 *
	 * @dev Implementation must guarantee not to return zero, absurdly small
	 *      or big values, it must guarantee the price is up to date with some
	 *      reasonable update interval threshold
	 *
	 * @param ethOut amount of ETH sale contract is expecting to get
	 * @return ilvIn amount of sILV sale contract should accept instead
	 */
	function ethToIlv(uint256 ethOut) external returns (uint256 ilvIn);
}