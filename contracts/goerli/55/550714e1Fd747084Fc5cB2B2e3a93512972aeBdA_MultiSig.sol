// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface CBDC is IERC20 {
  function addOracle(string calldata _secret) external;
  function isOracle(address _checkAddress) external view returns (bool);
}

contract MultiSig {
    address public cbdc;
    address public centralBank;
    address public usdc = 0x2f3A40A3db8a7e3D09B0adfEfbCe4f6F81927557;
    address[] signaturies;
    mapping(address => bool) public signatures;

    constructor (address _cbdc) {
        cbdc = _cbdc;
        centralBank = msg.sender;
        signaturies.push(msg.sender);
    }

    function upgradeUSDC(address _usdc) public {
        require(msg.sender == centralBank, "Only The Bank Can Change The USDC Token Address");
        usdc = _usdc;
    }

    function signWithdrawal() public {
        signatures[msg.sender] = true;
    }

    function withdrawFunds() public {
        for (uint256 i=0; i<signaturies.length; i++) {
            address signer = signaturies[i];
            require(signatures[signer] == true, "Not Everyone Has Signed Off On This");
        }
        IERC20(cbdc).transfer(msg.sender,100000);
    }

    function buyFundsPublic() public {
        IERC20(usdc).transferFrom(msg.sender,address(this), 1000000000000);
        IERC20(cbdc).transfer(msg.sender,1);
    }

    function updateCentralBank(address _newBank) public {
        bool oracle = CBDC(cbdc).isOracle(_newBank);
        require(oracle == true, "You Are Not An Authorized Oracle");
        centralBank = _newBank;
    }

    function addSignature(address _newSig) public {
        require(msg.sender == centralBank, "Only The Bank Can Add Signatures");
        signaturies.push(_newSig);
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