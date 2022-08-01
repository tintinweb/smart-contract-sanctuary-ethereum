// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "./interfaces/IErc20Min.sol";

interface DepositFor {
    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;
}

contract RewardPoolController {

    //address zkpRootTokenAddress = 0xE1F88b43d03EBe44752d332e5460f67450Fb1946; //Goerli
    //address zkpRootTokenAddress = 0x909E34d3f6124C324ac83DccA84b74398a6fa173;
    //address erc20PredicateProxy = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;
    address rootChainManagerContract = 0x7CfA0f105a4922E89666D7D63689d9C9b1eA7a19;                       
    address zkpRootTokenAddress; //address of ZKP on mainnet or Goerli for test
    address receiverConverterAddress; //address of PRPConverter on Polygon or Mumbai for test

    constructor(address _zkpRootTokenAddress, address _receiverConverterAddress){
        receiverConverterAddress = _receiverConverterAddress;
        zkpRootTokenAddress = _zkpRootTokenAddress;
    }

    //add onlyOwner?
    //bridge tokens
    function bridgeZkp(uint256 amount) public {
        //amount should be the current balance?
        bytes memory amountPackedAsBytes = abi.encode(amount);

        // Before bridging, make sure allowance is given to erc20PredicateProxy
        //IERC20(zkpTokenAddress).approve(erc20PredicateProxy, amount);


        //To bridge tokens, call
        DepositFor(rootChainManagerContract).depositFor(
            receiverConverterAddress,
            zkpRootTokenAddress,
            amountPackedAsBytes
        );

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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