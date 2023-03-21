/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

/**

                                                                                                    
        ((((((((   .(((("/(((       (((((,                 .((((/        /(((((((   *((((((((       
     ,/(((((((((   .(((("//(((/*    (((((((,             (((((((/     ./(((((((((   /((((((((((*    
    ((((((                 ((((**       ((((((.       *((((((       .(((((                  /((((   
    (((/((                 (((((*          .#####   ,##((           ,(/(((                 ./"/"/   
    ((((((                 (((((/             *#####((              .((((/                 .////(   
    ((((((                 (((((*             ,((####(              .(((((                 ./((/(   
    ((((((                 (((((*             ,((((###/             ./((((                 .((((/   
    ((((((                 (((/(*           "//(((((/(#(/           .(###(                 .((((/   
    *(((((                 (((((/          *####...*"/###           .(####                 ./((((   
    (((((/                 ###((/       (####.          (###(       ,((#((                  (((#(   
     "/((######(    ((#######/*,    (((##( .             . *#((((     .,(((((((#(   ,((##((((((*    
        (######(    (#######(       (#(#(*                 .(((((        ((((((##   *(#((##((*      
                                                                                                    

    𝙰 𝚗𝚘𝚗-𝚝𝚛𝚊𝚌𝚎𝚊𝚋𝚕𝚎 𝚙𝚛𝚒𝚟𝚊𝚌𝚢 𝙴𝚁𝙲-𝟸0 𝚝𝚛𝚊𝚗𝚜𝚊𝚌𝚝𝚒𝚘𝚗𝚜 𝚖𝚒𝚡𝚎𝚛 𝚒𝚜 𝚊 𝚍𝚎𝚌𝚎𝚗𝚝𝚛𝚊𝚕𝚒𝚣𝚎𝚍 𝚙𝚕𝚊𝚝𝚏𝚘𝚛𝚖 𝚝𝚑𝚊𝚝 𝚙𝚛𝚘𝚟𝚒𝚍𝚎𝚜 
    𝚜𝚎𝚌𝚞𝚛𝚎 𝚊𝚗𝚍 𝚊𝚗𝚘𝚗𝚢𝚖𝚘𝚞𝚜 𝚝𝚛𝚊𝚗𝚜𝚊𝚌𝚝𝚒𝚘𝚗 𝚖𝚒𝚡𝚒𝚗𝚐. 𝙸𝚝 𝚞𝚜𝚎𝚜 𝚜𝚖𝚊𝚛𝚝 𝚌𝚘𝚗𝚝𝚛𝚊𝚌𝚝 𝚝𝚎𝚌𝚑𝚗𝚘𝚕𝚘𝚐𝚢 𝚝𝚘 𝚙𝚛𝚎𝚜𝚎𝚛𝚟𝚎 𝚝𝚑𝚎 
    𝚙𝚛𝚒𝚟𝚊𝚌𝚢 𝚘𝚏 𝚝𝚑𝚎 𝚜𝚘𝚞𝚛𝚌𝚎 𝚊𝚗𝚍 𝚍𝚎𝚜𝚝𝚒𝚗𝚊𝚝𝚒𝚘𝚗 𝚘𝚏 𝚝𝚛𝚊𝚗𝚜𝚊𝚌𝚝𝚒𝚘𝚗𝚜, 𝚖𝚊𝚔𝚒𝚗𝚐 𝚝𝚑𝚎𝚖 𝚞𝚗𝚝𝚛𝚊𝚌𝚎𝚊𝚋𝚕𝚎. 

    𝙰𝚍𝚍𝚒𝚝𝚒𝚘𝚗𝚊𝚕𝚕𝚢, 𝚒𝚝 𝚞𝚝𝚒𝚕𝚒𝚣𝚎𝚜 𝚊 𝚏𝚕𝚊𝚜𝚑-𝚕𝚘𝚊𝚗 𝚏𝚎𝚊𝚝𝚞𝚛𝚎 𝚝𝚘 𝚐𝚎𝚗𝚎𝚛𝚊𝚝𝚎 𝚏𝚎𝚎𝚜 𝚝𝚑𝚊𝚝 𝚊𝚛𝚎 𝚍𝚒𝚜𝚝𝚛𝚒𝚋𝚞𝚝𝚎𝚍 𝚝𝚘 $0𝚡0 
    𝚝𝚘𝚔𝚎𝚗 𝚑𝚘𝚕𝚍𝚎𝚛𝚜. 𝙸𝚍𝚎𝚊𝚕 𝚏𝚘𝚛 𝚞𝚜𝚎𝚛𝚜 𝚠𝚑𝚘 𝚙𝚕𝚊𝚌𝚎 𝚊 𝚑𝚒𝚐𝚑 𝚟𝚊𝚕𝚞𝚎 𝚘𝚗 𝚙𝚛𝚒𝚟𝚊𝚌𝚢 𝚊𝚗𝚍 𝚜𝚎𝚌𝚞𝚛𝚒𝚝𝚢.

*/



// SPDX-License-Identifier: MIT

// File: interfaces/IOxOPool.sol

pragma solidity ^0.8.5;

interface IOxOPool {
    function initialize(address _token, uint256[4] memory _wei_amounts, address _factory) external;
    function withdraw(
        address payable recipient, uint256 amountToken, uint256 ringIndex,
        uint256 c0, uint256[2] memory keyImage, uint256[] memory s
    ) external;
    function deposit(uint _amount, uint256[2] memory publicKey) external;
    function getBalance() external view returns (uint256);
    function getCurrentRingIndex(uint256 amountToken) external view
        returns (uint256);
    function getRingMaxParticipants() external pure
        returns (uint256);
    function getParticipant(uint packedData) external view returns (uint256);
    function getWParticipant(uint packedData) external view returns (uint256);
    function getRingPackedData(uint packedData) external view returns (uint256, uint256, uint256);
    function getPublicKeys(uint256 amountToken, uint256 index) external view
        returns (bytes32[2][5] memory);
    function getPoolBalance() external view returns (uint256);
}





// File: interfaces/IFlashBorrower.sol

pragma solidity ^0.8.5;

interface FlashBorrower {
	/// @notice Flash loan callback
	/// @param amount The amount of tokens received
	/// @param data Forwarded data from the flash loan request
	/// @dev Called after receiving the requested flash loan, should return tokens + any fees before the end of the transaction
	function onFlashLoan(
		uint256 amount,
		uint256 fee,
		bytes calldata data
	) external;
}





// File: lib/AltBn128.sol

pragma solidity ^0.8.5;

// https://github.com/ethereum/py_ecc/blob/master/py_ecc/bn128/bn128_curve.py

library AltBn128 {    
    // https://github.com/ethereum/py_ecc/blob/master/py_ecc/bn128/bn128_curve.py
    uint256 constant public G1x = uint256(0x01);
    uint256 constant public G1y = uint256(0x02);

    // Number of elements in the field (often called `q`)
    // n = n(u) = 36u^4 + 36u^3 + 18u^2 + 6u + 1
    uint256 constant public N = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    // p = p(u) = 36u^4 + 36u^3 + 24u^2 + 6u + 1
    // Field Order
    uint256 constant public P = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    // (p+1) / 4
    uint256 constant public A = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52;
    

    /* ECC Functions */
    function ecAdd(uint256[2] memory p0, uint256[2] memory p1) public view
        returns (uint256[2] memory retP)
    {
        uint256[4] memory i = [p0[0], p0[1], p1[0], p1[1]];
        
        assembly {
            // call ecadd precompile
            // inputs are: x1, y1, x2, y2
            if iszero(staticcall(not(0), 0x06, i, 0x80, retP, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function ecMul(uint256[2] memory p, uint256 s) public view
        returns (uint256[2] memory retP)
    {
        // With a public key (x, y), this computes p = scalar * (x, y).
        uint256[3] memory i = [p[0], p[1], s];
        
        assembly {
            // call ecmul precompile
            // inputs are: x, y, scalar
            if iszero(staticcall(not(0), 0x07, i, 0x60, retP, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function ecMulG(uint256 s) public view
        returns (uint256[2] memory retP)
    {
        return ecMul([G1x, G1y], s);
    }

    function powmod(uint256 base, uint256 e, uint256 m) public view
        returns (uint256 o)
    {
        // returns pow(base, e) % m
        assembly {
            // define pointer
            let p := mload(0x40)

            // Store data assembly-favouring ways
            mstore(p, 0x20)             // Length of Base
            mstore(add(p, 0x20), 0x20)  // Length of Exponent
            mstore(add(p, 0x40), 0x20)  // Length of Modulus
            mstore(add(p, 0x60), base)  // Base
            mstore(add(p, 0x80), e)     // Exponent
            mstore(add(p, 0xa0), m)     // Modulus

            // call modexp precompile! -- old school gas handling
            let success := staticcall(sub(gas(), 2000), 0x05, p, 0xc0, p, 0x20)

            // gas fiddling
            switch success case 0 {
                revert(0, 0)
            }

            // data
            o := mload(p)
        }
    }

    // Keep everything contained within this lib
    function addmodn(uint256 x, uint256 n) public pure
        returns (uint256)
    {
        return addmod(x, n, N);
    }

    function modn(uint256 x) public pure
        returns (uint256)
    {
        return x % N;
    }

    /*
       Checks if the points x, y exists on alt_bn_128 curve
    */
    function onCurve(uint256 x, uint256 y) public pure
        returns(bool)
    {
        uint256 beta = mulmod(x, x, P);
        beta = mulmod(beta, x, P);
        beta = addmod(beta, 3, P);

        return onCurveBeta(beta, y);
    }

    function onCurveBeta(uint256 beta, uint256 y) public pure
        returns(bool)
    {
        return beta == mulmod(y, y, P);
    }

    /*
    * Calculates point y value given x
    */
    function evalCurve(uint256 x) public view
        returns (uint256, uint256)
    {
        uint256 beta = mulmod(x, x, P);
        beta = mulmod(beta, x, P);
        beta = addmod(beta, 3, P);

        uint256 y = powmod(beta, A, P);

        // require(beta == mulmod(y, y, P), "Invalid x for evalCurve");
        return (beta, y);
    }
}





// File: lib/LSAG.sol

pragma solidity ^0.8.5;

/*
Linkable Spontaneous Anonymous Groups
https://eprint.iacr.org/2004/027.pdf
*/

library LSAG {
    // abi.encodePacked is the "concat" or "serialization"
    // of all supplied arguments into one long bytes value
    // i.e. abi.encodePacked :: [a] -> bytes

    /**
    * Converts an integer to an elliptic curve point
    */
    function intToPoint(uint256 _x) public view
        returns (uint256[2] memory)
    {
        uint256 x = _x;
        uint256 y;
        uint256 beta;

        while (true) {
            (beta, y) = AltBn128.evalCurve(x);

            if (AltBn128.onCurveBeta(beta, y)) {
                return [x, y];
            }

            x = AltBn128.addmodn(x, 1);
        }
    }

    /**
    * Returns an integer representation of the hash
    * of the input
    */
    function H1(bytes memory b) public pure
        returns (uint256)
    {
        return AltBn128.modn(uint256(keccak256(b)));
    }

    /**
    * Returns elliptic curve point of the integer representation
    * of the hash of the input
    */
    function H2(bytes memory b) public view
        returns (uint256[2] memory)
    {
        return intToPoint(H1(b));
    }

    /**
    * Helper function to calculate Z1
    * Avoids stack too deep problem
    */
    function ringCalcZ1(
        uint256[2] memory pubKey,
        uint256 c,
        uint256 s
    ) public view
        returns (uint256[2] memory)
    {
        return AltBn128.ecAdd(
            AltBn128.ecMulG(s),
            AltBn128.ecMul(pubKey, c)
        );
    }

    /**
    * Helper function to calculate Z2
    * Avoids stack too deep problem
    */
    function ringCalcZ2(
        uint256[2] memory keyImage,
        uint256[2] memory h,
        uint256 s,
        uint256 c
    ) public view
        returns (uint256[2] memory)
    {
        return AltBn128.ecAdd(
            AltBn128.ecMul(h, s),
            AltBn128.ecMul(keyImage, c)
        );
    }


    /**
    * Verifies the ring signature
    * Section 4.2 of the paper https://eprint.iacr.org/2004/027.pdf
    */
    function verify(
        bytes memory message,
        uint256 c0,
        uint256[2] memory keyImage,
        uint256[] memory s,
        uint256[2][] memory publicKeys
    ) public view
        returns (bool)
    {
        require(publicKeys.length >= 2, "Signature size too small");
        require(publicKeys.length == s.length, "Signature sizes do not match!");

        uint256 c = c0;
        uint256 i = 0;

        // Step 1
        // Extract out public key bytes
        bytes memory hBytes = "";

        for (i = 0; i < publicKeys.length; i++) {
            hBytes = abi.encodePacked(
                hBytes,
                publicKeys[i]
            );
        }

        uint256[2] memory h = H2(hBytes);

        // Step 2
        uint256[2] memory z_1;
        uint256[2] memory z_2;


        for (i = 0; i < publicKeys.length; i++) {
            z_1 = ringCalcZ1(publicKeys[i], c, s[i]);
            z_2 = ringCalcZ2(keyImage, h, s[i], c);

            if (i != publicKeys.length - 1) {
                c = H1(
                    abi.encodePacked(
                        hBytes,
                        keyImage,
                        message,
                        z_1,
                        z_2
                    )
                );
            }
        }

        return c0 == H1(
            abi.encodePacked(
                hBytes,
                keyImage,
                message,
                z_1,
                z_2
            )
        );
    }
}





// File: .deps/npm/@openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}





// File: .deps/npm/@openzeppelin/contracts/token/ERC20/IERC20.sol

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





// File: .deps/npm/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}





// File: .deps/npm/@openzeppelin/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.5;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}





// File: OxOPool.sol

pragma solidity ^0.8.5;

contract OxOPool {

    // =============================================================
    //                           ERRORS
    // =============================================================
    
    error AlreadyInitialized();
    error NotInitialized();

    // =============================================================
    //                           EVENTS
    // =============================================================
    
    event Deposited(address, uint256 tokenAmount, uint256 ringIndex);
    event Flashloan(FlashBorrower indexed receiver, uint256 amount);
    event Withdrawn(address, uint256 tokenAmount, uint256 ringIndex);

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /// @notice Maximum number of participants in a ring It can be changed to a higher value, 
    /// but it will increase the gas cost.
    /// Note: was reduced to 3 for testing purposes
    uint256 constant MAX_RING_PARTICIPANT = 3;

    /// @notice Minimum number of blocks that needs to be mined before user can forcefully close the ring
    /// NOTE: This is only for testing purposes, in production
    /// this should be set to a higher value
    uint256 constant CLOSE_RING_BLOCK_THRESHOLD = 10;

    /// The number of participants in the ring
    uint256 constant _BITPOS_NUMBER_PARTICIPANTS = 32;

    /// The number of withdrawals in the ring
    uint256 constant _BITPOS_NUMBER_WITHDRAWALS = 48;

    /// The participant value would use 16 bits
    uint256 constant _BITWIDTH_PARTICIPANTS = 16;

    /// The Block value would use 16 bits
    uint256 constant _BITWIDTH_BLOCK_NUM = 32;

    /// Bitmask for `numberOfParticipants`
    uint256 constant _BITMASK_PARTICIPANTS = (1 << _BITWIDTH_PARTICIPANTS) -1;

    /// Bitmask for `blockNumber`
    uint256 constant _BITMASK_BLOCK_NUM = (1 << _BITWIDTH_BLOCK_NUM) -1;


    // =============================================================
    //                           STORAGE
    // =============================================================

    struct Ring {
        /// The total amount deposited in the ring
        uint256 amountDeposited;

        /// Bits Layout:
        /// - [0..32]    `initiatedBlockNumber` 
        /// - [32..48]   `numberOfParticipants`
        /// - [48..64]   `numberOfWithdrawnParticipants`
        uint256 packedRingData; 

        /// The public keys of the participants
        mapping (uint256 => uint256[2]) publicKeys;

        /// The key images from successfully withdrawn participants
        /// NOTE: This is used to prevent double spending
        mapping (uint256 => uint256[2]) keyImages;
        bytes32 ringHash;
    }

    address public token;
    address public factory;

    /// 0.09% fee for flashloans
    uint256 public loanFee = 9;

    uint256[4] allowedAmounts;

    /// tokenAmount => ringIndex
    mapping(uint256 => uint256) public ringsNumber;

    /// tokenAmount => ringIndex => Ring
    mapping (uint256 => mapping(uint256 => Ring)) public rings;

    /// @notice Initialize the vault to use and accept `token`
    /// @param _token The address of the token to use
    function initialize(address _token, uint256[4] memory _wei_amounts, address _factory) public {
        if (token != address(0)) revert AlreadyInitialized();
        token = _token;
        allowedAmounts = _wei_amounts;
        factory = _factory;

        for(uint256 i = 0; i < allowedAmounts.length; ) {
            allowedAmounts[i] = _wei_amounts[i];
            unchecked {
                i++;
            }
        }
    }

    /// @notice Deposit `amount` of `token` into the vault
    /// @param _amount The amount of `token` to deposit
    /// @param _publicKey The public key of the participant
    function deposit(uint _amount, uint256[2] memory _publicKey) public {
        
        /// Confirm amount sent is allowed
        uint256 amountTokenRecieved = amountCheck(_amount);
        OxOFactory factoryContract = OxOFactory(factory);

        if(ERC20(factoryContract.token()).balanceOf(msg.sender) < factoryContract.getTokenFeeDiscountLimit()) {
            uint256 fee = getFeeForAmount(_amount);
            ERC20(token).transferFrom(msg.sender, address(this), _amount+fee);

            /// Transfer the fee to the treasurer
            ERC20(token).transfer(OxOFactory(factory).treasurerAddress(), fee);   
        }else{
            uint256 fee = getDiscountFeeForAmount(_amount);
            ERC20(token).transferFrom(msg.sender, address(this), _amount+fee);

            if(fee > 0) {
                /// Transfer the fee to the treasurer
                ERC20(token).transfer(OxOFactory(factory).treasurerAddress(), fee);  
            }
        }

        if (!AltBn128.onCurve(uint256(_publicKey[0]), uint256(_publicKey[1]))) {
            revert("PK_NOT_ON_CURVE");
        }

        /// Gets the current ring for the amounts
        uint256 ringIndex = ringsNumber[amountTokenRecieved];
        Ring storage ring = rings[amountTokenRecieved][ringIndex];

        (uint wParticipants,
        uint participants, uint blockNum) = getRingPackedData(ring.packedRingData);

        /// Making sure no duplicate public keys are added
        for (uint256 i = 0; i < participants;) {
            if (ring.publicKeys[i][0] == _publicKey[0] &&
                ring.publicKeys[i][1] == _publicKey[1]) {
                revert("PK_ALREADY_IN_RING");
            }

            unchecked {
                i++;
            }
        }

        if (participants == 0) {
            blockNum = block.number - 1;
        }

        ring.publicKeys[participants] = _publicKey;
        ring.amountDeposited += amountTokenRecieved;
        unchecked {
            participants++;
        }

        uint packedData = (wParticipants << _BITWIDTH_PARTICIPANTS) | participants;
        packedData = (packedData << _BITWIDTH_BLOCK_NUM) | blockNum;
        ring.packedRingData = packedData;

        /// If the ring is full, start a new ring
        if (participants >= MAX_RING_PARTICIPANT) {
            ring.ringHash = hashRing(amountTokenRecieved, ringIndex);
            
            /// Add new Ring pool
            ringsNumber[amountTokenRecieved] += 1;
        }

        emit Deposited(msg.sender, amountTokenRecieved, ringIndex);
    }


    /// @notice Withdraw `amount` of `token` from the vault
    /// @param recipient The address to send the withdrawn tokens to
    /// @param amountToken The amount of `token` to withdraw
    /// @param ringIndex The index of the ring to withdraw from
    /// @param keyImage The key image of the participant
    /// @param c0 signature
    /// @param s signature
    function withdraw(
        address payable recipient, uint256 amountToken, uint256 ringIndex,
        uint256 c0, uint256[2] memory keyImage, uint256[] memory s
    ) public
    {
        Ring storage ring = rings[amountToken][ringIndex];

        (uint wParticipants,
        uint participants, uint blockNum) = getRingPackedData(ring.packedRingData);

        if (recipient == address(0)) {
            revert("ZERO_ADDRESS");
        }
        
        if (wParticipants >= MAX_RING_PARTICIPANT) {
            revert("ALL_FUNDS_WITHDRAWN");
        }

        if (ring.ringHash == bytes32(0x00)) {
            revert("RING_NOT_CLOSED");
        }

        uint256[2][] memory publicKeys = new uint256[2][](MAX_RING_PARTICIPANT);

        for (uint256 i = 0; i < MAX_RING_PARTICIPANT;) {
            publicKeys[i] = ring.publicKeys[i];
            unchecked {
                i++;
            }
        }

        /// Attempts to verify ring signature
        bool signatureVerified = LSAG.verify(
            abi.encodePacked(ring.ringHash, recipient), // Convert to bytes
            c0,
            keyImage,
            s,
            publicKeys
        );

        if (!signatureVerified) {
            revert("INVALID_SIGNATURE");
        }

        /// Confirm key image is not already used (no double spends)
        for (uint i = 0; i < wParticipants;) {
            if (ring.keyImages[i][0] == keyImage[0] &&
                ring.keyImages[i][1] == keyImage[1]) {
                revert("USED_SIGNATURE");
            }

            unchecked {
                i++;
            }
        }    

        ring.keyImages[wParticipants] = keyImage;
        unchecked {
            wParticipants++;
        }

        uint packedData = (wParticipants << _BITWIDTH_PARTICIPANTS) | participants;
        packedData = (packedData << _BITWIDTH_BLOCK_NUM) | blockNum;
        ring.packedRingData = packedData;  

        ERC20(token).transfer(recipient, amountToken);

        emit Withdrawn(recipient, amountToken, ringIndex);
    }

    /// @notice Generates a hash of the ring
    /// @param _amountToken The amount of `token` in the ring
    /// @param _ringIndex The index of the ring
    function hashRing(uint256 _amountToken, uint256 _ringIndex) internal view
        returns (bytes32)
    {
        uint256[2][MAX_RING_PARTICIPANT] memory publicKeys;
        uint256 receivedToken = amountCheck(_amountToken);

        Ring storage ring = rings[receivedToken][_ringIndex];

        for (uint8 i = 0; i < MAX_RING_PARTICIPANT;) {
            publicKeys[i] = ring.publicKeys[i];

            unchecked {
                i++;
            }
        }

        (uint participants,, uint blockNum) = getRingPackedData(ring.packedRingData);

        bytes memory b = abi.encodePacked(
            blockhash(block.number - 1),
            blockNum,
            ring.amountDeposited,
            participants,
            publicKeys
        );

        return keccak256(b);
    }

    /// @notice Calculate the fee for a given amount
    /// @param amount The amount to calculate the fee for
    function getFeeForAmount(uint256 amount) public view returns(uint256){
        return (amount * OxOFactory(factory).fee()) / 10_000;
    }

    /// @notice Get the fee for Discount holders
    /// @param amount The amount to calculate the fee for
    function getDiscountFeeForAmount(uint256 amount) public view returns(uint256){
        return (amount * OxOFactory(factory).tokenFee()) / 10_000;
    }

    /// @notice Gets the hash of the ring
    /// @param _amountToken The amount of `token` in the ring
    /// @param _ringIndex The index of the ring
    function getRingHash(uint256 _amountToken, uint256 _ringIndex) public view
        returns (bytes32)
    {
        uint256 receivedToken = amountCheck(_amountToken);
        return rings[receivedToken][_ringIndex].ringHash;
    }

    /// @notice Gets the total amount of `token` in the ring
    function getPoolBalance() public view returns (uint256) {
        return ERC20(token).balanceOf(address(this));
    }

    /// @notice Gets the allowed amounts to deposit for the `token`
    function getAllowedAmounts() public view returns (uint256[4] memory) {
        return allowedAmounts;
    }

    // =============================================================
    //                           FLASH LOAN
    // =============================================================

    /// @notice Request a flash loan
	/// @param receiver The contract that will receive the flash loan
	/// @param amount The amount of tokens you want to borrow
	/// @param data Data to forward to the receiver contract along with your flash loan
	/// @dev Make sure your contract implements the FlashBorrower interface!
	function execute(
		FlashBorrower receiver,
		uint256 amount,
		bytes calldata data
	) public payable {
        uint256 poolBalance = getPoolBalance();

        if(poolBalance < amount) {
            revert("INSUFFICIENT_FUNDS");
        }

        uint256 fee = getLoanFee(amount);

        emit Flashloan(receiver, amount);

		ERC20(token).transfer(address(receiver), amount);
		receiver.onFlashLoan(amount, fee, data);

		if (poolBalance + fee > ERC20(token).balanceOf(address(this))){
            revert("TOKENS_NOT_RETURNED");
        }
	}

    /// @notice Gets the pool percentage from the flash loan
    /// @param _amount The amount of tokens you want to borrow
    function getLoanFee(uint _amount) public returns (uint) {
        return (_amount * OxOFactory(factory).loanFee()) / 10000;
    }

    // =============================================================
    //                           UTILITIES
    // =============================================================

    /// @notice Checks if the amount sent is allowed
    /// @param _amount The amount of token to check
    function amountCheck(uint256 _amount) internal view
        returns (uint256)
    {
        bool allowed = false;
        uint256 _length = allowedAmounts.length;

        for (uint256 i = 0; i < _length;) {
            if (allowedAmounts[i] == _amount) {
                allowed = true;
            }
            if (allowed) {
                break;
            }

            unchecked {
                i++;
            }
        }

        // Revert if token sent isn't in the allowed fixed amounts
        require(allowed, "AMOUNT_NOT_ALLOWED");
        return _amount;
    }

    /// @notice Gets the public keys of the ring
    /// @param amountToken The amount of `token` in the ring
    /// @param ringIndex The index of the ring
    function getPublicKeys(uint256 amountToken, uint256 ringIndex) public view
        returns (bytes32[2][MAX_RING_PARTICIPANT] memory)
    {
        amountCheck(amountToken);

        bytes32[2][MAX_RING_PARTICIPANT] memory publicKeys;

        for (uint i = 0; i < MAX_RING_PARTICIPANT; i++) {
            publicKeys[i][0] = bytes32(rings[amountToken][ringIndex].publicKeys[i][0]);
            publicKeys[i][1] = bytes32(rings[amountToken][ringIndex].publicKeys[i][1]);
        }

        return publicKeys;
    }

    /// @notice Gets the unpacked, packed ring data
    /// @param packedData The packed ring data
    function getRingPackedData(uint packedData) public view returns (uint256, uint256, uint256){
        uint256 p = packedData >> _BITWIDTH_BLOCK_NUM;
        
        return (
            p >> _BITWIDTH_PARTICIPANTS,
            p & _BITMASK_PARTICIPANTS,
            packedData & _BITMASK_BLOCK_NUM
        );
    }

    /// @notice Gets the number of participants that have withdrawn from the ring
    /// @param packedData The packed ring data
    function getWParticipant(uint256 packedData) public view returns (uint256){
        return (packedData >> _BITWIDTH_BLOCK_NUM) >> _BITWIDTH_PARTICIPANTS;
    }

    /// @notice Gets the number of participants in the ring
    /// @param packedData The packed ring data
    function getParticipant(uint256 packedData) public view returns (uint256){
        uint256 p = packedData >> _BITWIDTH_BLOCK_NUM;
        
        return p & _BITMASK_PARTICIPANTS;
    }

    /// @notice Gets the maximum number of participants in any ring
    function getRingMaxParticipants() public pure
        returns (uint256)
    {
        return MAX_RING_PARTICIPANT;
    }

    /// @notice Gets the lates ring index for `amountToken`
    /// @param amountToken The amount of `token` in the ring
    function getCurrentRingIndex(uint256 amountToken) public view
        returns (uint256)
    {
        amountCheck(amountToken);
        return ringsNumber[amountToken];
    }
}

// File: OxOFactory.sol

pragma solidity ^0.8.5;

contract OxOFactory {

    /// Errors
    error PoolExists();
    error ZeroAddress();
    error Forbidden();

    /// Events
    event PoolCreated(address indexed token, address poolAddress);

    address[] public allPools;
    address public managerAddress = 0x0000BA9FF5c97f33Bd62c216A56b3D02aE6Ac4Bb;
    address public treasurerAddress = 0xdf5888F30a4A99BD23913ae002D5aF4DBf0502B4;
    address public token = 0x5a3e6A77ba2f983eC0d371ea3B475F8Bc0811AD5;
    uint256 public tokenFeeDiscountPercent = 100; // 0.1% of total supply  

    uint256 public fee = 50; // 0.5% fee
    uint256 public tokenFee = 25; // 0.25% fee
    uint256 public loanFee = 90; // 0.9% fee
    
    /// token => pool
    mapping(address => address) public pools;
    
    /// @notice Creates a new pool for the given token
    /// @param _token The token to create the pool for
    /// @param _wei_amounts allowed deposit amounts
    /// @return vault The address of the new pool

    function createPool(address _token, uint256[4] calldata _wei_amounts) public onlyManager returns (address vault) {
        if (_token == address(0)) revert ZeroAddress();
        if(pools[_token] != address(0)) revert PoolExists();

        bytes memory bytecode = type(OxOPool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_token));

        assembly {
            vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IOxOPool(vault).initialize(_token, _wei_amounts, address(this));

        pools[_token] = vault;
        allPools.push(vault);

        emit PoolCreated(_token, vault);
    }

    /// @notice Returns the pool address for the given token
    /// @param _token The token to get the pool for
    /// @return The address of the pool
    function getPool(address _token) external view returns (address) {
        return pools[_token];
    }

    /// @notice Returns the address of the pool for the given token
    /// @return The length of all pools
    function allPoolsLength() external view returns (uint) {
        return allPools.length;
    }

    modifier onlyManager() {
        if (msg.sender != managerAddress) revert Forbidden();
        _;
    }

    modifier limitFee(uint256 _fee) {
        require(_fee <= 300, "Fee too high");
        _;
    }

    /// @notice Sets the manager address
    /// @param _managerAddress The new manager address
    function setManager(address _managerAddress) external onlyManager {
        managerAddress = _managerAddress;
    }

    /// @notice Sets the treasurer address
    /// @param _treasurerAddress The new treasurer address
    function setTreasurerAddress(address _treasurerAddress) external onlyManager {
        treasurerAddress = _treasurerAddress;
    }

    /// @notice Sets the token address
    /// @param _token The new token address
    function setToken(address _token) external onlyManager {
        token = _token;
    }

    /// @notice Set the percentage threshold for fee free transactions
    /// @param _value the new percentage threshold
    function setTokenFeeDiscountPercent(uint256 _value) external onlyManager {
        tokenFeeDiscountPercent = _value;
    }

    /// @notice Set token fee
    /// @param _fee the new percentage threshold
    function setTokenFee(uint256 _fee) external onlyManager limitFee(_fee){
        tokenFee = _fee;
    }

    /// @notice Sets the fee
    /// @param _fee The new fee
    function setFee(uint256 _fee) external onlyManager limitFee(_fee){
        fee = _fee;
    }

    /// @notice Sets the loan fee
    /// @param _fee The new fee
    function setLoanFee(uint256 _fee) external onlyManager limitFee(_fee){
        loanFee = _fee;
    }

    function getTokenFeeDiscountLimit() external view returns (uint256) {
        return (ERC20(token).totalSupply() * tokenFeeDiscountPercent) / 100_000;
    }
}